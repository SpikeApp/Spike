package ui
{
	import com.adobe.touch3D.Touch3D;
	import com.adobe.touch3D.Touch3DEvent;
	import com.distriqt.extension.bluetoothle.BluetoothLE;
	import com.distriqt.extension.bluetoothle.events.PeripheralEvent;
	import com.distriqt.extension.notifications.Notifications;
	import com.freshplanet.ane.AirBackgroundFetch.BackgroundFetch;
	import com.freshplanet.ane.AirBackgroundFetch.BackgroundFetchEvent;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.system.Capabilities;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	
	import spark.formatters.DateTimeFormatter;
	
	import database.BlueToothDevice;
	import database.CommonSettings;
	import database.Database;
	import database.LocalSettings;
	import database.Sensor;
	
	import events.BlueToothServiceEvent;
	import events.DatabaseEvent;
	import events.NotificationServiceEvent;
	import events.SettingsServiceEvent;
	
	import feathers.controls.Alert;
	import feathers.layout.HorizontalAlign;
	
	import model.ModelLocator;
	
	import services.BluetoothService;
	import services.CalibrationService;
	import services.NotificationService;
	import services.TutorialService;
	
	import starling.core.Starling;
	import starling.events.Event;
	
	import ui.popups.AlertManager;
	import ui.screens.Screens;
	
	import utils.Constants;
	import utils.DeviceInfo;
	import utils.Trace;

	[ResourceBundle("transmitterscreen")]
	[ResourceBundle("globaltranslations")]
	[ResourceBundle("sensorscreen")]
	[ResourceBundle("3dtouch")]
	[ResourceBundle("crashreport")]

	public class InterfaceController extends EventDispatcher
	{
		private static var initialStart:Boolean = true;
		private static var _instance:InterfaceController;
		public static var dateFormatterForSensorStartTimeAndDate:DateTimeFormatter;
		public static var peripheralConnected:Boolean = false;
		public static var peripheralConnectionStatusChangeTimestamp:Number;
		
		public function InterfaceController() {}
		
		public static function init():void
		{
			if(_instance == null)
				_instance = new InterfaceController();
			
			if (initialStart) 
			{
				if (DeviceInfo.isDeviceCompatible())
				{
					Trace.init();
					Database.instance.addEventListener(DatabaseEvent.DATABASE_INIT_FINISHED_EVENT,onInitResult);
					Database.instance.addEventListener(DatabaseEvent.ERROR_EVENT,onInitError);
					Database.init();
					initialStart = false;
					CommonSettings.instance.addEventListener(SettingsServiceEvent.SETTING_CHANGED, onSettingsChanged);
					
					dateFormatterForSensorStartTimeAndDate = new DateTimeFormatter();
					dateFormatterForSensorStartTimeAndDate.dateTimePattern = "dd MMM HH:mm";
					dateFormatterForSensorStartTimeAndDate.useUTC = false;
					dateFormatterForSensorStartTimeAndDate.setStyle("locale",Capabilities.language.substr(0,2));
				}
				else
				{
					var txtFormat:TextFormat = new TextFormat();
					txtFormat.size = 24;
					txtFormat.font = "Roboto";
					txtFormat.bold = true;
					txtFormat.align = TextFormatAlign.CENTER;
					
					var incompatibilityMessage:TextField = new TextField();
					incompatibilityMessage.defaultTextFormat = txtFormat;
					incompatibilityMessage.textColor = 0xEEEEEE;
					incompatibilityMessage.width = Constants.appStage.stageWidth;
					incompatibilityMessage.y = (Constants.appStage.stageHeight - incompatibilityMessage.textHeight) / 2;
					incompatibilityMessage.text = ModelLocator.resourceManagerInstance.getString('globaltranslations','incompatible_device_message');
					incompatibilityMessage.selectable = false;
					Constants.appStage.addChild(incompatibilityMessage);
				}
			}
			
			
			function onInitResult(event:DatabaseEvent):void
			{
				Trace.myTrace("interfaceController.as", "Database initialized successfully!");
				//at this moment the database is intialised, but the logs, bgreadings, ... might still be read in the ModelLocator, Modellocator is listening to the same event
				
				//NSLog
				if (ModelLocator.INTERNAL_TESTING)
					LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_NSLOG, "true");
				else
					LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_NSLOG, "false");
				
				Database.instance.removeEventListener(DatabaseEvent.ERROR_EVENT,onInitError);
				BluetoothService.instance.addEventListener(BlueToothServiceEvent.BLUETOOTH_SERVICE_INITIATED, blueToothServiceInitiated);
				
				//3D Touch Management
				setup3DTouch();
			}
			
			function onInitError(event:DatabaseEvent):void
			{	
				Trace.myTrace("interfaceController.as", "Error initializing database!");
			}
		}
		
		private static function onSettingsChanged(event:SettingsServiceEvent):void 
		{
			/* Transmitter Info Alerts */
			if (event.data == CommonSettings.COMMON_SETTING_PERIPHERAL_TYPE) 
			{
				if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PERIPHERAL_TYPE) == "" || CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_MODE) == "Follower")
					return;
				
				if (BlueToothDevice.alwaysScan()) 
				{
					if (BlueToothDevice.isDexcomG5() && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_G5_INFO_SCREEN_SHOWN) == "false" && !TutorialService.isActive) 
					{
						var alertMessageG5:String = ModelLocator.resourceManagerInstance.getString('transmitterscreen','g5_info_screen');
						if (Sensor.getActiveSensor() == null)
							alertMessageG5 += "\n\n" + ModelLocator.resourceManagerInstance.getString('transmitterscreen','sensor_not_started');
							
						var alertG5:Alert = AlertManager.showSimpleAlert
						(
							ModelLocator.resourceManagerInstance.getString('transmitterscreen','alert_info_title'),
							alertMessageG5
						);
						alertG5.height = 400;
						
						CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_G5_INFO_SCREEN_SHOWN,"true");
					} 
					else if (BlueToothDevice.isBluKon() && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BLUKON_INFO_SCREEN_SHOWN) == "false" && !TutorialService.isActive) 
					{
						var alertMessageBlucon:String = ModelLocator.resourceManagerInstance.getString('transmitterscreen','blucon_info_screen');
						if (Sensor.getActiveSensor() == null)
							alertMessageBlucon += "\n\n" + ModelLocator.resourceManagerInstance.getString('transmitterscreen','sensor_not_started');
							
						var alertBlucon:Alert = AlertManager.showSimpleAlert
						(
							ModelLocator.resourceManagerInstance.getString('transmitterscreen','alert_info_title'),
							alertMessageBlucon
						);
						alertBlucon.height = 400;
							
						CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_BLUKON_INFO_SCREEN_SHOWN,"true");
					}
				} 
				else if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_G4_INFO_SCREEN_SHOWN) == "false" && !TutorialService.isActive) 
				{
					if (BlueToothDevice.knowsFSLAge())
					{
						//variables are named miaomiao but this is used for all FSL peripherals, ie all type limitter
						var alertMiaoMiao:Alert = AlertManager.showSimpleAlert
							(
								ModelLocator.resourceManagerInstance.getString('transmitterscreen','alert_info_title'),
								ModelLocator.resourceManagerInstance.getString('transmitterscreen','miaomiao_info_screen')
							);
						alertMiaoMiao.height = 400;
					}
					else
					{
						var alertMessageG4:String = ModelLocator.resourceManagerInstance.getString('transmitterscreen','g4_info_screen');
						if (Sensor.getActiveSensor() == null)
							alertMessageG4 += "\n\n" + ModelLocator.resourceManagerInstance.getString('transmitterscreen','sensor_not_started');
						
						var alertG4:Alert = AlertManager.showSimpleAlert
							(
								ModelLocator.resourceManagerInstance.getString('transmitterscreen','alert_info_title'),
								alertMessageG4
							);
						alertG4.height = 400;
					}
					
					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_G4_INFO_SCREEN_SHOWN,"true");
				}
			}
		}
		
		private static function setup3DTouch():void
		{
			if(Capabilities.cpuArchitecture == "ARM") 
			{
				var touch:Touch3D = new Touch3D();
				if (touch.isSupported() || Constants.deviceModel == DeviceInfo.IPHONE_6_6S_7_8)
				{
					touch.init();
					touch.addEventListener(Touch3DEvent.SHORTCUT_ITEM, itemStatus);
					touch.removeShortcutItem("calibration");
					touch.removeShortcutItem("startsensor");
					touch.removeShortcutItem("stopsensor");
					touch.addShortcutItem("calibration", ModelLocator.resourceManagerInstance.getString('3dtouch','calibration_menu'), "", "UIApplicationShortcutIconTypeAdd");
					touch.addShortcutItem("startsensor", ModelLocator.resourceManagerInstance.getString('3dtouch','start_sensor_menu'), "", "UIApplicationShortcutIconTypeConfirmation");
					touch.addShortcutItem("stopsensor", ModelLocator.resourceManagerInstance.getString('3dtouch','stop_sensor_menu'), "", "UIApplicationShortcutIconTypeProhibit");
				}
			}
		}
		
		private static function itemStatus(e:Touch3DEvent):void
		{
			if (e.itemValue == "calibration")
				Starling.juggler.delayCall(CalibrationService.calibrationOnRequest, 0.4);
			else if (e.itemValue == "stopsensor")
			{
				Starling.juggler.delayCall(stopSensor, 0.4);
				
				function stopSensor():void
				{
					AlertManager.showActionAlert(
						ModelLocator.resourceManagerInstance.getString('sensorscreen','stop_sensor_alert_title'),
						ModelLocator.resourceManagerInstance.getString('sensorscreen','stop_sensor_alert_message'),
						60,
						[
							{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations','cancel_button_label').toUpperCase() },
							{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations','stop_alert_button_label'), triggered: onStopSensorTriggered }
						]
					);
				}
			}
			else if (e.itemValue == "startsensor")
			{
				Starling.juggler.delayCall(startSensor, 0.4);
				
				function startSensor():void
				{
					if (Sensor.getActiveSensor() == null)
						AppInterface.instance.navigator.pushScreen(Screens.SENSOR_START);
					else
					{
						AlertManager.showActionAlert(
							ModelLocator.resourceManagerInstance.getString('sensorscreen','sensor_active_alert_title'),
							ModelLocator.resourceManagerInstance.getString('sensorscreen','sensor_active_alert_message'),
							60,
							[
								{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations','cancel_button_label').toUpperCase() },
								{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations','stop_alert_button_label'), triggered: onStopSensorTriggered }
							]
						);
					}
				}
			}
		}
		
		private static function onStopSensorTriggered(e:starling.events.Event):void
		{
			/* Stop the Sensor */
			Sensor.stopSensor();
			NotificationService.updateBgNotification(null);
			
			/* Navigate to the Start Sensor screen */
			AppInterface.instance.navigator.pushScreen(Screens.SENSOR_START);
		}
		/**
		 * Notification Event Handlers
		 */
		public static function notificationServiceInitiated(e:NotificationServiceEvent):void 
		{
			NotificationService.updateBgNotification(null);
			
			/* Display Initial License Agreement */
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_LICENSE_INFO_ACCEPTED) == "false")
			{
				var licenseAlert:Alert = AlertManager.showActionAlert
					(
						ModelLocator.resourceManagerInstance.getString('globaltranslations', "license_alert_title"),
						ModelLocator.resourceManagerInstance.getString('globaltranslations', "license_alert_message"),
						Number.NaN,
						[
							{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations', "agree_alert_button_label"), triggered: onLicenseAccepted }
						]
					);
				licenseAlert.height = 420;
			}
		}
		
		private static function onLicenseAccepted (e:starling.events.Event):void
		{
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_LICENSE_INFO_ACCEPTED, "true");
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_SELECTION_UNIT_DONE) == "false") 
			{
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_SELECTION_UNIT_DONE,"true");
				
				/* Start Tutorial */
				TutorialService.init();
			} 
		}
		
		/**
		 * Bluetooth Event Handlers
		 */
		private static function blueToothServiceInitiated(be:BlueToothServiceEvent):void 
		{
			BluetoothService.instance.addEventListener(BlueToothServiceEvent.DEVICE_NOT_PAIRED, deviceNotPaired);
			BluetoothService.instance.addEventListener(BlueToothServiceEvent.BLUETOOTH_DEVICE_CONNECTION_COMPLETED, bluetoothDeviceConnectionCompleted);
			BluetoothLE.service.centralManager.addEventListener(PeripheralEvent.DISCONNECT, central_peripheralDisconnectHandler);
			BackgroundFetch.instance.addEventListener(BackgroundFetchEvent.MIAOMIAO_CONNECTED, bluetoothDeviceConnectionCompleted);
			BackgroundFetch.instance.addEventListener(BackgroundFetchEvent.MIAOMIAO_DISCONNECTED, central_peripheralDisconnectHandler);
		}
		
		private static function deviceNotPaired(event:flash.events.Event):void 
		{
			if (BackgroundFetch.appIsInForeground())
				return;
			
			if (BlueToothDevice.isBluKon())
				return; //blukon keeps on trying to connect, there's always a request to pair, no need to give additional comments
			
			AlertManager.showSimpleAlert
			(
				ModelLocator.resourceManagerInstance.getString("transmitterscreen","device_not_paired_alert_title"),
				ModelLocator.resourceManagerInstance.getString("transmitterscreen","device_not_paired_alert_message"),
				240,
				deviceNotPairedAlertClosed
			);
		}
		
		private static function deviceNotPairedAlertClosed(event:starling.events.Event):void 
		{
			Notifications.service.cancel(NotificationService.ID_FOR_DEVICE_NOT_PAIRED);
		}
		
		private static function bluetoothDeviceConnectionCompleted(event:flash.events.Event):void 
		{
			Trace.myTrace("interfaceController.as", "in bluetoothDeviceConnectionCompleted");
			if (!peripheralConnected) 
			{
				Trace.myTrace("interfaceController.as", "in bluetoothDeviceConnectionCompleted, setting peripheralConnected = true");
				peripheralConnected = true;
				peripheralConnectionStatusChangeTimestamp = (new Date()).valueOf();
			}
		}
		
		private static function central_peripheralDisconnectHandler(event:flash.events.Event):void 
		{
			if (peripheralConnected) 
			{
				Trace.myTrace("interfaceController.as", "in central_peripheralDisconnectHandler, setting peripheralConnected = false");
				peripheralConnected = false;
				peripheralConnectionStatusChangeTimestamp = (new Date()).valueOf();
			}
		}
		
		public static function btScanningStopped(event:BlueToothServiceEvent):void 
		{
			BluetoothService.instance.removeEventListener(BlueToothServiceEvent.STOPPED_SCANNING, InterfaceController.btScanningStopped);
			
			if (!BluetoothService.bluetoothPeripheralActive()) 
			{
				AlertManager.showSimpleAlert
				(
					ModelLocator.resourceManagerInstance.getString('transmitterscreen',"scanning_failed_alert_title"),
					ModelLocator.resourceManagerInstance.getString('transmitterscreen',"scanning_failed_message") + (BlueToothDevice.known() ? (" " + ModelLocator.resourceManagerInstance.getString('transmitterscreen',"with_name") + " " + BlueToothDevice.name) + "\n\n" + ModelLocator.resourceManagerInstance.getString('transmitterscreen',"explain_expected_device_name"): ""),
					Number.NaN,
					null,
					HorizontalAlign.CENTER
				);	
			}
		}
		
		public static function userInitiatedBTScanningSucceeded(event:flash.events.Event):void 
		{
			BluetoothLE.service.centralManager.removeEventListener(PeripheralEvent.CONNECT, InterfaceController.userInitiatedBTScanningSucceeded);
			BackgroundFetch.instance.removeEventListener(BackgroundFetchEvent.MIAOMIAO_CONNECTED, InterfaceController.userInitiatedBTScanningSucceeded);
			
			//Vibrate device to warn user that scan was successful
			BackgroundFetch.vibrate();
			
			/*AlertManager.showSimpleAlert
			(
				ModelLocator.resourceManagerInstance.getString('transmitterscreen',"scan_for_device_alert_title"),
				ModelLocator.resourceManagerInstance.getString('transmitterscreen',"connected_to_peripheral_device_id_stored"),
				30
			);*/
		}
		
		/**
		 * Getters & Setters
		 */
		public static function get instance():InterfaceController
		{
			if (_instance == null)
				return new InterfaceController();
			
			return _instance;
		}
	}
}