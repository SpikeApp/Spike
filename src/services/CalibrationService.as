package services
{
	import com.distriqt.extension.notifications.Notifications;
	import com.distriqt.extension.notifications.builders.NotificationBuilder;
	import com.distriqt.extension.notifications.events.NotificationEvent;
	import com.spikeapp.spike.airlibrary.SpikeANE;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.setTimeout;
	
	import database.BgReading;
	import database.CGMBlueToothDevice;
	import database.Calibration;
	import database.CommonSettings;
	import database.LocalSettings;
	import database.Sensor;
	
	import events.BlueToothServiceEvent;
	import events.CalibrationServiceEvent;
	import events.NotificationServiceEvent;
	import events.SettingsServiceEvent;
	import events.SpikeEvent;
	import events.TransmitterServiceEvent;
	
	import feathers.controls.Alert;
	import feathers.controls.TextInput;
	import feathers.core.PopUpManager;
	import feathers.layout.HorizontalAlign;
	
	import model.ModelLocator;
	
	import services.bluetooth.CGMBluetoothService;
	
	import starling.core.Starling;
	import starling.events.Event;
	import starling.utils.SystemUtil;
	
	import ui.popups.AlertManager;
	import ui.screens.display.LayoutFactory;
	
	import utils.BadgeBuilder;
	import utils.Constants;
	import utils.GlucoseHelper;
	import utils.TimeSpan;
	import utils.Trace;
	
	[ResourceBundle("calibrationservice")]
	[ResourceBundle("globaltranslations")]
	
	/**
	 * listens for bgreadings, at each bgreading user is asked to enter bg value<br>
	 * after two bgreadings, calibration.initialcalibration will be called and then this service will stop. 
	 */
	public class CalibrationService extends EventDispatcher
	{
		private static const MAXIMUM_WAIT_FOR_CALIBRATION_IN_SECONDS:int = 240; //4 minutes
		
		private static var _instance:CalibrationService = new CalibrationService();
		/**
		 * if notification launched for requesting initial calibration, this value will be true<br>
		 *
		 */
		private static var initialCalibrationRequested:Boolean;
		
		//Logic Properties
		private static var initialCalibrationActive:Boolean = false;
		public static var optimalCalibrationScheduled:Boolean = false;
		
		//Data properties
		private static var userCalibrationValue:String = "";
		
		//Display Objects
		private static var calibrationTextInput:TextInput;

		public static function get instance():CalibrationService {
			return _instance;
		}
		
		public function CalibrationService() {
			if (_instance != null) {
				throw new Error("CalibrationService class constructor can not be used");	
			}
		}
		
		public static function init():void {
			myTrace("init");
			
			Spike.instance.addEventListener(SpikeEvent.APP_HALTED, onHaltExecution);
			TransmitterService.instance.addEventListener(TransmitterServiceEvent.LAST_BGREADING_RECEIVED, bgReadingReceived);
			NotificationService.instance.addEventListener(NotificationServiceEvent.NOTIFICATION_EVENT, notificationReceived);
			NotificationService.instance.addEventListener(NotificationServiceEvent.NOTIFICATION_SELECTED_EVENT, notificationReceived);
			CommonSettings.instance.addEventListener(SettingsServiceEvent.SETTING_CHANGED, commonSettingChanged);
			CGMBluetoothService.instance.addEventListener(BlueToothServiceEvent.SENSOR_CHANGED_DETECTED, receivedSensorChanged);
			Spike.instance.addEventListener(SpikeEvent.APP_IN_FOREGROUND, appInForeGround);
			
			optimalCalibrationScheduled = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_OPTIMAL_CALIBRATION_ON_DEMAND_NOTIFIER_ON) == "true";
			if (optimalCalibrationScheduled)
				AlarmService.userRequestedSuboptimalCalibrationNotification = true;
			
			myTrace("finished init");
		}
		
		public static function appInForeGround(event:flash.events.Event = null):void {
			myTrace("in appInForeGround");
			if (initialCalibrationRequested) {
				myTrace("in appInForeGround, app has fired a notification for initialcalibration, but app was opened before notification was received - or appInForeGround is triggered faster than the notification event");
				initialCalibrationRequested = false;
				if (!initialCalibrationActive)
					requestInitialCalibration();
				Notifications.service.cancel(NotificationService.ID_FOR_REQUEST_CALIBRATION);
			}
		}
		
		private static function notificationReceived(event:NotificationServiceEvent):void {
			myTrace("in notificationReceived");
			if (event != null) {//not sure why checking, this would mean NotificationService received a null object, shouldn't happen
				var notificationEvent:NotificationEvent = event.data as NotificationEvent;
				if (notificationEvent.id == NotificationService.ID_FOR_REQUEST_CALIBRATION && initialCalibrationRequested && !initialCalibrationActive) {
					myTrace("in notificationReceived with ID_FOR_REQUEST_CALIBRATION && initialCalibrationRequested = true");
					initialCalibrationRequested = false;
					requestInitialCalibration();
				} else {
					if (notificationEvent.id == NotificationService.ID_FOR_CALIBRATION_REQUEST_ALERT)
						calibrationOnRequest();
					else
						myTrace("in notificationReceived with id = " + notificationEvent.id + ", and initialCalibrationRequested = " + initialCalibrationRequested);
				}
			}
		}
		
		/**
		 * opens dialogview to request calibration 
		 */
		private static function requestInitialCalibration():void 
		{
			myTrace("in requestInitialCalibration");
			
			if (Calibration.allForSensor().length >= 2)
				return;
			
			var latestReadings:Array = BgReading.latestBySize(2);
			if (latestReadings.length < 2) {
				myTrace("in requestInitialCalibration but latestReadings.length < 0, returning");
				return;
			}
			
			var latestReading:BgReading = (latestReadings[0]) as BgReading;
			if ((new Date()).valueOf() - latestReading.timestamp > MAXIMUM_WAIT_FOR_CALIBRATION_IN_SECONDS * 1000) 
			{
				myTrace("in requestInitialCalibration, but latest reading was more than MAXIMUM_WAIT_FOR_CALIBRATION_IN_SECONDS");
				myTrace("app was opened via notification, opening warning dialog");
				
				AlertManager.showSimpleAlert
				(
					ModelLocator.resourceManagerInstance.getString("calibrationservice","enter_calibration_title"),
					ModelLocator.resourceManagerInstance.getString("calibrationservice","latest_reading_is_too_old"),
					60
				);
				
				return;
			}
			
			/* Create and Style Calibration Text Input */
			calibrationTextInput = LayoutFactory.createTextInput(false, false, 170, HorizontalAlign.CENTER, true);
			calibrationTextInput.addEventListener(starling.events.Event.CHANGE, onCalibrationValueChanged);
			calibrationTextInput.maxChars = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true" ? 3 : 4;
			
			/* Create and Style Popup Window */
			var calibrationPopup:Alert = AlertManager.showActionAlert
			(
				ModelLocator.resourceManagerInstance.getString("calibrationservice","enter_initial_calibration_title"),
				"",
				MAXIMUM_WAIT_FOR_CALIBRATION_IN_SECONDS,
				[
					{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations','cancel_button_label').toUpperCase() },
					{ label: ModelLocator.resourceManagerInstance.getString('calibrationservice','calibration_add_button_title'), triggered: initialCalibrationValueEntered }
				],
				HorizontalAlign.JUSTIFY,
				calibrationTextInput
			);
			calibrationPopup.validate();
			calibrationTextInput.width = calibrationPopup.width - 20;
			calibrationPopup.gap = 0;
			calibrationPopup.headerProperties.maxHeight = 30;
			calibrationPopup.buttonGroupProperties.paddingTop = -10;
			calibrationPopup.buttonGroupProperties.gap = 10;
			calibrationPopup.buttonGroupProperties.horizontalAlign = HorizontalAlign.CENTER;
			calibrationTextInput.setFocus();
		}
		
		private static function bgReadingReceived(be:TransmitterServiceEvent):void {
			myTrace("in bgReadingReceived");

			var latestReadings:Array = BgReading.latestBySize(2);
			if (latestReadings.length < 2) {
				myTrace("in bgReadingReceived but latestReadings.length <2");
				return;
			}
			
			var latestReading:BgReading = (latestReadings[0]) as BgReading;
			if ((new Date()).valueOf() - latestReading.timestamp > MAXIMUM_WAIT_FOR_CALIBRATION_IN_SECONDS * 1000) 
			{
				//this can happen for example in case of blucon, if historical data is read which contains readings > 2 minutes old
				myTrace("in bgReadingReceived, reading is more than " + MAXIMUM_WAIT_FOR_CALIBRATION_IN_SECONDS + " seconds old, no further processing");
				return;
			}
			
			if (Sensor.getActiveSensor() == null) {
				myTrace("bgReadingReceived, but sensor is null, returning");
				return;
			}
			
			initialCalibrationActive = false;
			
			var warmupTimeInMs:int = 0;
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_REMOVE_SENSOR_WARMUP_ENABLED) != "true")
				warmupTimeInMs = CGMBlueToothDevice.isTypeLimitter() ? TimeSpan.TIME_1_HOUR : TimeSpan.TIME_2_HOURS;
			
			//if there's already more than two calibrations, then there's no need anymore to request initial calibration
			if (Calibration.allForSensor().length < 2) 
			{
				myTrace("Calibration.allForSensor().length < 2");
				
				if ((new Date()).valueOf() - Sensor.getActiveSensor().startedAt < warmupTimeInMs) 
				{
					myTrace("CalibrationService : bgreading received but sensor age < " + warmupTimeInMs + " milliseconds, so ignoring");
				} 
				else 
				{
					//launch a notification
					//don't do it via the notificationservice, this could result in the notification being cleared but not recreated (NotificationService.updateAllNotifications)
					//the notification doesn't need to open any action, the dialog is create when the user opens the notification, or if the app is in the foreground, as soon as the notification is build. 
					//Only do this if be!= null, because if be == null, then it means this function was called after having entered an invalid number in the dialog, so user is using the app, no need for a notification
					if (be != null) 
					{
						myTrace("Launching notification ID_FOR_REQUEST_CALIBRATION");
						
						Notifications.service.notify(
							new NotificationBuilder()
							.setCount(BadgeBuilder.getAppBadge())
							.setId(NotificationService.ID_FOR_REQUEST_CALIBRATION)
							.setAlert(ModelLocator.resourceManagerInstance.getString("calibrationservice","enter_initial_calibration_title"))
							.setTitle(ModelLocator.resourceManagerInstance.getString("calibrationservice","enter_initial_calibration_title"))
							.setBody(ModelLocator.resourceManagerInstance.getString("calibrationservice","enter_initial_calibration_notification_body"))
							.enableVibration(true)
							.enableLights(true)
							.build());
						
						initialCalibrationRequested = true;
					} 
					
					if (!initialCalibrationActive)
					{
						myTrace("opening dialog to request calibration");
						
						SystemUtil.executeWhenApplicationIsActive( function():void 
						{
							try
							{
								PopUpManager.removeAllPopUps(true);
							} 
							catch(error:Error) {}
							
							/* Create and Style Calibration Text Input */
							calibrationTextInput = LayoutFactory.createTextInput(false, false, 170, HorizontalAlign.CENTER, true);
							calibrationTextInput.addEventListener(starling.events.Event.CHANGE, onCalibrationValueChanged);
							calibrationTextInput.maxChars = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true" ? 3 : 4;
							
							/* Create and Style Popup Window */
							var calibrationPopup:Alert = AlertManager.showActionAlert
							(
								ModelLocator.resourceManagerInstance.getString("calibrationservice","enter_initial_calibration_title"),
								"",
								MAXIMUM_WAIT_FOR_CALIBRATION_IN_SECONDS,
								[
									{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations','cancel_button_label').toUpperCase() },
									{ label: ModelLocator.resourceManagerInstance.getString('calibrationservice','calibration_add_button_title'), triggered: initialCalibrationValueEntered }
								],
								HorizontalAlign.JUSTIFY,
								calibrationTextInput
							);
							calibrationPopup.validate();
							calibrationTextInput.width = calibrationPopup.width - 20;
							calibrationPopup.gap = 0;
							calibrationPopup.headerProperties.maxHeight = 30;
							calibrationPopup.buttonGroupProperties.paddingTop = -10;
							calibrationPopup.buttonGroupProperties.gap = 10;
							calibrationPopup.buttonGroupProperties.horizontalAlign = HorizontalAlign.CENTER;
							calibrationTextInput.setFocus();
							calibrationPopup.addEventListener(starling.events.Event.CLOSE, onInitialCalibrationClosed);
						});
						initialCalibrationActive = true;
					}
				}
			}
			else if (optimalCalibrationScheduled && GlucoseHelper.isOptimalConditionToCalibrate())
			{
				if (!SystemUtil.isApplicationActive)
				{
					//Send a notification to the user notifying that optimal calibration conditions have been met
					var notificationBuilder:NotificationBuilder = new NotificationBuilder()
						.setCount(BadgeBuilder.getAppBadge())
						.setId(NotificationService.ID_FOR_CALIBRATION_REQUEST_ALERT)
						.setAlert(ModelLocator.resourceManagerInstance.getString('calibrationservice','optimal_calibration_request_notification_title'))
						.setTitle(ModelLocator.resourceManagerInstance.getString('calibrationservice','optimal_calibration_request_notification_title'))
						.setBody(ModelLocator.resourceManagerInstance.getString('calibrationservice','optimal_calibration_request_notification_body'))
						.enableLights(true)
						.setSound("default")
						.setCategory(NotificationService.ID_FOR_ALERT_CALIBRATION_REQUEST_CATEGORY);
					Notifications.service.notify(notificationBuilder.build());
				}
				
				SpikeANE.vibrate();
				
				if (SystemUtil.isApplicationActive)
				{
					//Show popup notifying that optimal calibration conditions have been met
					SystemUtil.executeWhenApplicationIsActive( function():void 
					{
						var optimalAlert:Alert = AlertManager.showSimpleAlert
						(
							ModelLocator.resourceManagerInstance.getString('calibrationservice','optimal_calibration_request_notification_title'),
							ModelLocator.resourceManagerInstance.getString('calibrationservice','optimal_calibration_request_notification_body')
						);
						optimalAlert.addEventListener(starling.events.Event.CLOSE, onOptimalCalibrationAcknowledged);
						
						function onOptimalCalibrationAcknowledged(e:starling.events.Event = null):void
						{
							calibrationOnRequest();
						}
					});
				}
				
				AlarmService.userRequestedSuboptimalCalibrationNotification = false;
				
				//Notify Nightscout
				NightscoutService.uploadOptimalCalibrationNotification();
				
				setTimeout( function():void {
					optimalCalibrationScheduled = false;
					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_OPTIMAL_CALIBRATION_ON_DEMAND_NOTIFIER_ON, String(optimalCalibrationScheduled), true, false);
				}, 5000 );
			}
		}
		
		private static function onInitialCalibrationClosed(e:starling.events.Event):void
		{
			initialCalibrationActive = false;
		}
		
		private static function initialCalibrationValueEntered(e:starling.events.Event = null):void 
		{
			initialCalibrationActive = false;
			
			if (!SystemUtil.isApplicationActive)
				return;
			
			if (calibrationTextInput != null)
			{
				calibrationTextInput.removeEventListeners();
				calibrationTextInput.removeFromParent();
				calibrationTextInput.dispose();
				calibrationTextInput = null;
			}
			
			var latestReadings:Array = BgReading.latestBySize(2);
			if (latestReadings.length < 2) {
				myTrace("in initialCalibrationValueEntered but latestReadings.length < 2, looks like an error");
				return;
			}
			
			myTrace("in intialCalibrationValueEntered");
			
			var asNumber:Number = Number(userCalibrationValue.replace(",","."));
			
			if (isNaN(asNumber) || userCalibrationValue == "") 
			{
				myTrace("in intialCalibrationValueEntered, user gave non numeric value, opening alert and requesting new value");
				
				//reset user value
				userCalibrationValue = "";
				
				//add the warning message
				AlertManager.showSimpleAlert
				(
					ModelLocator.resourceManagerInstance.getString("calibrationservice","invalid_value"),
					ModelLocator.resourceManagerInstance.getString("calibrationservice","value_should_be_numeric")
				);
				
				//and ask again a value
				bgReadingReceived(null);
			} 
			else 
			{
				if (asNumber >= 30 && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) != "true")
				{
					//User is on mmol/L but inserted a calibration in mg/dL. Let's do a conversion.
					asNumber = asNumber * BgReading.MGDL_TO_MMOLL;
				}
				
				if (asNumber < 30 && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true")
				{
					//User is on mg/dL but inserted a calibration in mmol/L. Let's do a conversion.
					asNumber = asNumber * BgReading.MMOLL_TO_MGDL;
				}
				
				if(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) != "true") 
				{
					asNumber = asNumber * BgReading.MMOLL_TO_MGDL; 	
				}
				
				myTrace("in intialCalibrationValueEntered, starting Calibration.initialCalibration");
				var now:Number = new Date().valueOf();
				Calibration.initialCalibration(asNumber, now - TimeSpan.TIME_5_MINUTES, now, CGMBlueToothDevice.isMiaoMiao() ? 36 : 5);
				
				//Apply Fix if calibrated value has a difference > 10mg/dL of the one inserted by the user
				var lastBgReading:BgReading = (BgReading.latest(1))[0] as BgReading;
				var fixCounter:uint = 0;
				
				while(fixCounter < 10 && lastBgReading != null && Math.abs(lastBgReading._calculatedValue - asNumber) > 10)
				{
					myTrace("Applying initial calibration fix #" + (fixCounter + 1) + ". Difference from calibrated value is " + Math.abs(lastBgReading._calculatedValue - asNumber));
					
					//Re-apply initial calibration
					Calibration.clearLastCalibration();
					var newcalibration:Calibration = Calibration.create(asNumber).saveToDatabaseSynchronous();
					
					//Update conditional variavles
					lastBgReading = (BgReading.latest(1))[0] as BgReading;
					fixCounter += 1;
				}
				
				AlarmService.canUploadCalibrationToNightscout = true;
				AlarmService.userWarnedOfSuboptimalCalibration = false;
				userCalibrationValue = "";
				
				var calibrationServiceEvent:CalibrationServiceEvent = new CalibrationServiceEvent(CalibrationServiceEvent.INITIAL_CALIBRATION_EVENT);
				_instance.dispatchEvent(calibrationServiceEvent);
			}
		}
		
		/**
		 * will create an alertdialog to ask for a calibration 
		 */
		private static function initialCalibrate():void 
		{
			myTrace("initialCalibrate");
			
			/* Create and Style Calibration Text Input */
			calibrationTextInput = LayoutFactory.createTextInput(false, false, 135, HorizontalAlign.CENTER, true);
			calibrationTextInput.addEventListener(starling.events.Event.CHANGE, onCalibrationValueChanged);
			calibrationTextInput.maxChars = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true" ? 3 : 4;
			
			/* Create and Style Popup Window */
			var calibrationPopup:Alert = AlertManager.showActionAlert
				(
					ModelLocator.resourceManagerInstance.getString("calibrationservice","calibration_alert_title"),
					"",
					60,
					[
						{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations','cancel_button_label').toUpperCase() },
						{ label: ModelLocator.resourceManagerInstance.getString('calibrationservice','calibration_add_button_title'), triggered: calibrationValueEntered }
					],
					HorizontalAlign.JUSTIFY,
					calibrationTextInput
				);
			calibrationPopup.validate();
			calibrationTextInput.width = calibrationPopup.width - 20;
			calibrationPopup.gap = 0;
			calibrationPopup.headerProperties.maxHeight = 30;
			calibrationPopup.buttonGroupProperties.paddingTop = -10;
			calibrationPopup.buttonGroupProperties.gap = 10;
			calibrationPopup.buttonGroupProperties.horizontalAlign = HorizontalAlign.CENTER;
			calibrationTextInput.setFocus();
		}
		
		/**
		 * if override = true, then a check will be done if there was a calibration in the last 60 minutes and if so the last calibration will be overriden<br>
		 * if override = false, then there's no calibration override, no matter the timing of the last calibration<br>
		 * <br>
		 * if addSnoozeOption = true, then an action will be added to the dialog which allows snoozing, the snoozeFunction should be non null and is called when the user choses that action
		 */
		public static function calibrationOnRequest(override:Boolean = true, addSnoozeOption:Boolean = false, snoozeFunction:Function = null):void 
		{
			myTrace(" in calibrationOnRequest");
			
			//start with removing any calibration request notification that might be there
			Notifications.service.cancel(NotificationService.ID_FOR_REQUEST_CALIBRATION);
			Notifications.service.cancel(NotificationService.ID_FOR_CALIBRATION_REQUEST_ALERT);
			
			//check if there's 2 readings the last 30 minutes
			var latestBGReadings:Array = BgReading.last30Minutes();
			if (latestBGReadings == null) return;
			var last2calibrations:Array = Calibration.latest(2);
			if (last2calibrations == null || last2calibrations.length == 0) return;
			
			if (BgReading.last30Minutes().length < 2) 
			{
				myTrace(" in calibrationOnRequest, BgReading.last30Minutes().length < 2");
				
				if (!SystemUtil.isApplicationActive)
					return;
				
				AlertManager.showSimpleAlert
				(
					ModelLocator.resourceManagerInstance.getString("calibrationservice","enter_calibration_title"),
					ModelLocator.resourceManagerInstance.getString("calibrationservice","can_not_calibrate_right_now")
				);
			} 
			else //check if it's an override calibration
			{ 
				if (!SystemUtil.isApplicationActive)
					return;
				
				/* Create and Style Calibration Text Input */
				calibrationTextInput = LayoutFactory.createTextInput(false, false, 135, HorizontalAlign.CENTER, true);
				calibrationTextInput.addEventListener(starling.events.Event.CHANGE, onCalibrationValueChanged);
				calibrationTextInput.maxChars = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true" ? 3 : 4;
				
				if (((new Date()).valueOf() - (Calibration.latest(2)[0] as Calibration).timestamp < (1000 * 60 * 60)) && override) 
				{
					AlertManager.showActionAlert
					(
						ModelLocator.resourceManagerInstance.getString("calibrationservice","enter_calibration_title_with_override"),
						ModelLocator.resourceManagerInstance.getString("calibrationservice","enter_bg_value_with_override"),
						60,
						[
							{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations','cancel_button_label').toUpperCase() },
							{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations','ok_alert_button_label'), triggered: onAcceptedCalibrateWithOverride }
						]
					);
					
					function onAcceptedCalibrateWithOverride():void
					{
						if (!SystemUtil.isApplicationActive)
							return;
						
						/* Create and Style Popup Window */
						var calibrationPopup:Alert = AlertManager.showActionAlert
						(
							ModelLocator.resourceManagerInstance.getString('calibrationservice','calibration_alert_title'),
							"",
							Number.NaN,
							[
								{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations','cancel_button_label').toUpperCase() },
								{ label: ModelLocator.resourceManagerInstance.getString('calibrationservice','calibration_add_button_title'), triggered: calibrationDialogClosedWithOverride }
							],
							HorizontalAlign.JUSTIFY,
							calibrationTextInput
						);
						calibrationPopup.validate();
						calibrationTextInput.width = calibrationPopup.width - 20;
						calibrationPopup.gap = 0;
						calibrationPopup.headerProperties.maxHeight = 30;
						calibrationPopup.buttonGroupProperties.paddingTop = -10;
						calibrationPopup.buttonGroupProperties.gap = 10;
						calibrationPopup.buttonGroupProperties.horizontalAlign = HorizontalAlign.CENTER;
						calibrationTextInput.setFocus();
					}
					
					function calibrationDialogClosedWithOverride():void 
					{
						if (!SystemUtil.isApplicationActive)
							return;
						
						if (calibrationTextInput != null)
						{
							calibrationTextInput.removeEventListeners();
							calibrationTextInput.removeFromParent();
							calibrationTextInput.dispose();
							calibrationTextInput = null;
						}
						
						var asNumber:Number = Number(userCalibrationValue.replace(",","."));
						if (isNaN(asNumber) || userCalibrationValue == "") 
						{
							userCalibrationValue = "";
							
							if (!SystemUtil.isApplicationActive)
								return;
							
							AlertManager.showSimpleAlert
							(
								ModelLocator.resourceManagerInstance.getString("calibrationservice","enter_calibration_title"),
								ModelLocator.resourceManagerInstance.getString("calibrationservice","value_should_be_numeric"),
								Number.NaN,
								onAskNewCalibration
							);
							
							function onAskNewCalibration():void
							{
								//and ask again a value
								calibrationOnRequest(override);
							}
						} 
						else 
						{
							if (asNumber >= 30 && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) != "true")
							{
								//User is on mmol/L but inserted a calibration in mg/dL. Let's do a conversion.
								asNumber = asNumber * BgReading.MGDL_TO_MMOLL;
							}
							
							if (asNumber < 30 && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true")
							{
								//User is on mg/dL but inserted a calibration in mmol/L. Let's do a conversion.
								asNumber = asNumber * BgReading.MMOLL_TO_MGDL;
							}
							
							if(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) != "true")
								asNumber = asNumber * BgReading.MMOLL_TO_MGDL; 	
							
							Calibration.clearLastCalibration();
							var newcalibration:Calibration = Calibration.create(asNumber).saveToDatabaseSynchronous();
							
							AlarmService.canUploadCalibrationToNightscout = true;
							AlarmService.userWarnedOfSuboptimalCalibration = false;
							userCalibrationValue = "";
							
							var calibrationServiceEvent:CalibrationServiceEvent = new CalibrationServiceEvent(CalibrationServiceEvent.NEW_CALIBRATION_EVENT);
							_instance.dispatchEvent(calibrationServiceEvent);
							
							myTrace("calibration override, new one = created : " + newcalibration.print("   "));
						}
					}
				}
				else if (!GlucoseHelper.isOptimalConditionToCalibrate()) //Check for optimal calibration conditions
				{
					if (!SystemUtil.isApplicationActive)
						return;
					
					var suboptimalCalibrationAlert:Alert = AlertManager.showActionAlert
					(
						ModelLocator.resourceManagerInstance.getString("calibrationservice","enter_calibration_title_sub_optimal"),
						ModelLocator.resourceManagerInstance.getString("calibrationservice","enter_bg_value_sub_optimal").replace("{max_bg_difference}", CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true" ? "3mg/dL" : "0.16mmol/L").replace("{high_threshold}", CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true" ? CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_HIGH_MARK) + "-" + (Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_HIGH_MARK)) + Math.round(Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_HIGH_MARK)) * 0.25)) : Math.round(((BgReading.mgdlToMmol((Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_HIGH_MARK))))) * 10)) / 10 + "-" + ((Math.round(((BgReading.mgdlToMmol((Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_HIGH_MARK))))) * 10)) / 10) + (Math.round(((BgReading.mgdlToMmol((Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_HIGH_MARK)) * 0.25))) * 10)) / 10))).replace("{low_threshold}", CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true" ? CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_LOW_MARK) : String(Math.round(((BgReading.mgdlToMmol((Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_LOW_MARK))))) * 10)) / 10)),
						60,
						[
							{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations','cancel_button_label').toUpperCase() },
							{ label: ModelLocator.resourceManagerInstance.getString("calibrationservice","notify_optimal_conditions_button_label"), triggered: onScheduleOptimalCalibration },
							{ label: ModelLocator.resourceManagerInstance.getString("calibrationservice","proceed_button_label"), triggered: onAcceptedCalibrateWithSuboptimal }
						]
					);
					suboptimalCalibrationAlert.minWidth = Constants.stageWidth - 20;
					suboptimalCalibrationAlert.width = Constants.stageWidth - 20;
					
					function onScheduleOptimalCalibration():void
					{
						optimalCalibrationScheduled = true;
						CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_OPTIMAL_CALIBRATION_ON_DEMAND_NOTIFIER_ON, String(optimalCalibrationScheduled), true, false);
						
						AlarmService.userRequestedSuboptimalCalibrationNotification = true;
					}
					
					function onAcceptedCalibrateWithSuboptimal():void
					{
						if (!SystemUtil.isApplicationActive)
							return;
						
						/* Create and Style Popup Window */
						var calibrationPopup:Alert = AlertManager.showActionAlert
							(
								ModelLocator.resourceManagerInstance.getString('calibrationservice','calibration_alert_title'),
								"",
								Number.NaN,
								[
									{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations','cancel_button_label').toUpperCase() },
									{ label: ModelLocator.resourceManagerInstance.getString('calibrationservice','calibration_add_button_title'), triggered: calibrationDialogClosedWithSuboptimal }
								],
								HorizontalAlign.JUSTIFY,
								calibrationTextInput
							);
						calibrationPopup.validate();
						calibrationTextInput.width = calibrationPopup.width - 20;
						calibrationPopup.gap = 0;
						calibrationPopup.headerProperties.maxHeight = 30;
						calibrationPopup.buttonGroupProperties.paddingTop = -10;
						calibrationPopup.buttonGroupProperties.gap = 10;
						calibrationPopup.buttonGroupProperties.horizontalAlign = HorizontalAlign.CENTER;
						calibrationTextInput.setFocus();
					}
					
					function calibrationDialogClosedWithSuboptimal():void 
					{
						if (!SystemUtil.isApplicationActive)
							return;
						
						if (calibrationTextInput != null)
						{
							calibrationTextInput.removeEventListeners();
							calibrationTextInput.removeFromParent();
							calibrationTextInput.dispose();
							calibrationTextInput = null;
						}
						
						var asNumber:Number = Number(userCalibrationValue.replace(",","."));
						if (isNaN(asNumber) || userCalibrationValue == "") 
						{
							userCalibrationValue = "";
							
							AlertManager.showSimpleAlert
								(
									ModelLocator.resourceManagerInstance.getString("calibrationservice","enter_calibration_title"),
									ModelLocator.resourceManagerInstance.getString("calibrationservice","value_should_be_numeric"),
									Number.NaN,
									onAskNewCalibration
								);
							
							function onAskNewCalibration():void
							{
								//and ask again a value
								calibrationOnRequest(override);
							}
						} 
						else 
						{
							if (asNumber >= 30 && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) != "true")
							{
								//User is on mmol/L but inserted a calibration in mg/dL. Let's do a conversion.
								asNumber = asNumber * BgReading.MGDL_TO_MMOLL;
							}
							
							if (asNumber < 30 && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true")
							{
								//User is on mg/dL but inserted a calibration in mmol/L. Let's do a conversion.
								asNumber = asNumber * BgReading.MMOLL_TO_MGDL;
							}
							
							if(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) != "true")
								asNumber = asNumber * BgReading.MMOLL_TO_MGDL; 	
							
							Calibration.clearLastCalibration();
							var newcalibration:Calibration = Calibration.create(asNumber).saveToDatabaseSynchronous();
							
							AlarmService.canUploadCalibrationToNightscout = true;
							AlarmService.userWarnedOfSuboptimalCalibration = false;
							userCalibrationValue = "";
							
							var calibrationServiceEvent:CalibrationServiceEvent = new CalibrationServiceEvent(CalibrationServiceEvent.NEW_CALIBRATION_EVENT);
							_instance.dispatchEvent(calibrationServiceEvent);
							
							myTrace("calibration suboptimal, new one = created : " + newcalibration.print("   "));
						}
					}
				}
				else 
				{
					if (!SystemUtil.isApplicationActive)
						return;
					
					var alertButtonsList:Array = [];
					alertButtonsList.push({ label: ModelLocator.resourceManagerInstance.getString('globaltranslations','cancel_button_label').toUpperCase() });
					if (addSnoozeOption)
					{
						alertButtonsList.push({ label: ModelLocator.resourceManagerInstance.getString("notificationservice","snooze_for_snoozin_alarm_in_notification_screen").toUpperCase(), triggered: calibrationDialogClosedWithSnooze });
						calibrationTextInput.width = 210;
					}
					alertButtonsList.push({ label: ModelLocator.resourceManagerInstance.getString('calibrationservice','calibration_add_button_title'), triggered: calibrationDialogClosedWithoutOverride });
					
					var calibrationPopup:Alert = AlertManager.showActionAlert
					(
						ModelLocator.resourceManagerInstance.getString('calibrationservice','calibration_alert_title'),
						"",
						Number.NaN,
						alertButtonsList,
						HorizontalAlign.JUSTIFY,
						calibrationTextInput
					);
					
					calibrationPopup.validate();
					calibrationTextInput.width = calibrationPopup.width - 20;
					calibrationPopup.gap = 0;
					calibrationPopup.headerProperties.maxHeight = 30;
					calibrationPopup.buttonGroupProperties.paddingTop = -10;
					calibrationPopup.buttonGroupProperties.gap = 10;
					calibrationPopup.buttonGroupProperties.horizontalAlign = HorizontalAlign.CENTER;
					calibrationTextInput.setFocus();
					
					function calibrationDialogClosedWithoutOverride():void 
					{
						if (!SystemUtil.isApplicationActive)
							return;
						
						if (calibrationTextInput != null)
						{
							calibrationTextInput.removeEventListeners();
							calibrationTextInput.removeFromParent();
							calibrationTextInput.dispose();
							calibrationTextInput = null;
						}
						
						var asNumber:Number = Number(userCalibrationValue.replace(",","."));
						if (isNaN(asNumber) || userCalibrationValue == "") 
						{
							userCalibrationValue = "";
							
							if (!SystemUtil.isApplicationActive)
								return;
							
							AlertManager.showSimpleAlert
							(
								ModelLocator.resourceManagerInstance.getString("calibrationservice","enter_calibration_title"),
								ModelLocator.resourceManagerInstance.getString("calibrationservice","value_should_be_numeric"),
								Number.NaN,
								onAskNewCalibration
							);
							
							function onAskNewCalibration():void
							{
								//and ask again a value
								calibrationOnRequest(override);
							}
						} 
						else 
						{
							if (asNumber >= 30 && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) != "true")
							{
								//User is on mmol/L but inserted a calibration in mg/dL. Let's do a conversion.
								asNumber = asNumber * BgReading.MGDL_TO_MMOLL;
							}
							
							if (asNumber < 30 && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true")
							{
								//User is on mg/dL but inserted a calibration in mmol/L. Let's do a conversion.
								asNumber = asNumber * BgReading.MMOLL_TO_MGDL;
							}
							
							if(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) != "true")
								asNumber = asNumber * BgReading.MMOLL_TO_MGDL; 	
							
							var newcalibration:Calibration = Calibration.create(asNumber).saveToDatabaseSynchronous();
							
							AlarmService.canUploadCalibrationToNightscout = true;
							AlarmService.userWarnedOfSuboptimalCalibration = false;
							userCalibrationValue = "";
							
							_instance.dispatchEvent(new CalibrationServiceEvent(CalibrationServiceEvent.NEW_CALIBRATION_EVENT));
							
							myTrace("Calibration created : " + newcalibration.print("   "));
						}
					}
					
					function calibrationDialogClosedWithSnooze():void
					{
						myTrace("in calibrationOnRequest, subfunction calibrationDialogClosedWithSnooze");
						
						Starling.juggler.delayCall(snoozeFunction, 0.3);
					}
				}
			}
		}
		
		private static function calibrationValueEntered():void 
		{
			if (!SystemUtil.isApplicationActive)
				return;
			
			if (calibrationTextInput != null)
			{
				calibrationTextInput.removeEventListeners();
				calibrationTextInput.removeFromParent();
				calibrationTextInput.dispose();
				calibrationTextInput = null;
			}
			
			var asNumber:Number = Number(userCalibrationValue.replace(",","."));
			if (isNaN(asNumber) || userCalibrationValue == "") 
			{
				userCalibrationValue = "";
				
				//add the warning message
				AlertManager.showSimpleAlert
				(
					ModelLocator.resourceManagerInstance.getString("calibrationservice","invalid_value"),
					ModelLocator.resourceManagerInstance.getString("calibrationservice","value_should_be_numeric")
				);
				
				//and ask again a value
				initialCalibrate();
			} 
			else 
			{
				if (asNumber >= 30 && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) != "true")
				{
					//User is on mmol/L but inserted a calibration in mg/dL. Let's do a conversion.
					asNumber = asNumber * BgReading.MGDL_TO_MMOLL;
				}
				
				if (asNumber < 30 && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true")
				{
					//User is on mg/dL but inserted a calibration in mmol/L. Let's do a conversion.
					asNumber = asNumber * BgReading.MMOLL_TO_MGDL;
				}
				
				if(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) != "true") 
					asNumber = asNumber * BgReading.MMOLL_TO_MGDL; 	
				
				var calibration:Calibration = Calibration.create(asNumber).saveToDatabaseSynchronous();
				myTrace("Calibration created : " + calibration.print("   "));
				
				AlarmService.canUploadCalibrationToNightscout = true;
				AlarmService.userWarnedOfSuboptimalCalibration = false;
				userCalibrationValue = "";
			}
		}
		
		private static function commonSettingChanged(event:SettingsServiceEvent):void {
			if (event.data == CommonSettings.COMMON_SETTING_FSL_SENSOR_AGE) {
				var currentSensorAgeInMinutes:int = new Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FSL_SENSOR_AGE));
				if (currentSensorAgeInMinutes > 14.5 * 24 * 60 && CGMBlueToothDevice.knowsFSLAge()) {
					myTrace("in commonSettingChanged, sensorage more than 14.5 * 24 * 60 minutes, no further processing. Stop sensor if sensor is active");
					if (Sensor.getActiveSensor() != null) {
						//start sensor without user intervention 
						Sensor.stopSensor();
						giveSensorWarning("libre_14_dot_5_days_warning");
					}
				} else if (currentSensorAgeInMinutes > 14 * 24 * 60 && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_LIBRE_SENSOR_14DAYS_WARNING_GIVEN) == "false" && CGMBlueToothDevice.knowsFSLAge()) {
					myTrace("in commonSettingChanged, sensorage more than 14 * 24 * 60 minutes, give warning that sensor will expiry in half a day ");
					if (Sensor.getActiveSensor() != null) {
						giveSensorWarning("libre_14days_warning");
						CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_LIBRE_SENSOR_14DAYS_WARNING_GIVEN,"true");
					}
				}
				if (currentSensorAgeInMinutes > 0 && Sensor.getActiveSensor() == null && !CGMBlueToothDevice.isMiaoMiao() && CGMBlueToothDevice.knowsFSLAge() && currentSensorAgeInMinutes < 14 * 24 * 60) {
					//not doing this for miaomiao because sensorstart for miaomiao is already handled in LibreAlarmReceiver
					myTrace("in commonSettingChanged, sensorage changed to smaller value, starting sensor");
					Sensor.startSensor(((new Date()).valueOf() - currentSensorAgeInMinutes * 60 * 1000));
				}
			}
		}
		
		private static function giveSensorWarning(warning:String):void {
			if (SystemUtil.isApplicationActive) {
				AlertManager.showSimpleAlert
					(
						ModelLocator.resourceManagerInstance.getString("transmitterservice","warning"),
						ModelLocator.resourceManagerInstance.getString("transmitterservice",warning)
					);
			} else {
				var notificationBuilder:NotificationBuilder = new NotificationBuilder()
					.setId(NotificationService.ID_FOR_LIBRE_SENSOR_14DAYS)
					.setAlert(ModelLocator.resourceManagerInstance.getString("transmitterservice","warning"))
					.setTitle(ModelLocator.resourceManagerInstance.getString("transmitterservice","warning"))
					.setBody(ModelLocator.resourceManagerInstance.getString("transmitterservice",warning))
					.enableVibration(false)
					.setSound("");
				Notifications.service.notify(notificationBuilder.build());
			}
		}
		
		private static function receivedSensorChanged(be:BlueToothServiceEvent):void {
			if (Sensor.getActiveSensor() != null && CGMBlueToothDevice.knowsFSLAge()) {
				myTrace("in receivedSensorChanged, Stopping the sensor"); 
				Sensor.stopSensor();
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_FSL_SENSOR_AGE, "0");
				giveSensorWarning("new_fsl_sensor_detected");
			}
		}
		
		public static function dispatchCalibrationEvent():void {
			var calibrationServiceEvent:CalibrationServiceEvent = new CalibrationServiceEvent(CalibrationServiceEvent.NEW_CALIBRATION_EVENT);
			_instance.dispatchEvent(calibrationServiceEvent);
		}

		private static function myTrace(log:String):void {
			Trace.myTrace("CalibrationService.as", log);
		}
		
		/**
		 * Stores in memory the calibration value inserted by the user. This method resolves some weird Feathers bug
		 */
		private static function onCalibrationValueChanged(e:starling.events.Event):void
		{
			var textInput:TextInput = e.currentTarget as TextInput;
			if (textInput != null && textInput.text != null)
			{
				userCalibrationValue = textInput.text; 
			}
		}
		
		/**
		 * Stops the service entirely. Useful for database restores
		 */
		private static function onHaltExecution(e:SpikeEvent):void
		{
			myTrace("Stopping service...");
			
			stopService();
		}
		
		private static function stopService():void
		{
			TransmitterService.instance.removeEventListener(TransmitterServiceEvent.LAST_BGREADING_RECEIVED, bgReadingReceived);
			NotificationService.instance.removeEventListener(NotificationServiceEvent.NOTIFICATION_EVENT, notificationReceived);
			NotificationService.instance.removeEventListener(NotificationServiceEvent.NOTIFICATION_SELECTED_EVENT, notificationReceived);
			CommonSettings.instance.removeEventListener(SettingsServiceEvent.SETTING_CHANGED, commonSettingChanged);
			CGMBluetoothService.instance.removeEventListener(BlueToothServiceEvent.SENSOR_CHANGED_DETECTED, receivedSensorChanged);
			Spike.instance.removeEventListener(SpikeEvent.APP_IN_FOREGROUND, appInForeGround);
			
			myTrace("Service stopped!");
		}
	}
}