package ui
{
	import com.adobe.touch3D.Touch3D;
	import com.adobe.touch3D.Touch3DEvent;
	import com.distriqt.extension.bluetoothle.BluetoothLE;
	import com.distriqt.extension.bluetoothle.events.PeripheralEvent;
	
	import flash.events.EventDispatcher;
	import flash.system.Capabilities;
	
	import spark.formatters.DateTimeFormatter;
	
	import Utilities.Trace;
	
	import databaseclasses.BlueToothDevice;
	import databaseclasses.Database;
	import databaseclasses.LocalSettings;
	import databaseclasses.Sensor;
	
	import events.BlueToothServiceEvent;
	import events.DatabaseEvent;
	import events.NotificationServiceEvent;
	
	import feathers.controls.Alert;
	import feathers.layout.HorizontalAlign;
	
	import model.ModelLocator;
	
	import screens.Screens;
	
	import services.BluetoothService;
	import services.CalibrationService;
	import services.NotificationService;
	import services.TutorialService;
	
	import starling.events.Event;
	
	import utils.AlertManager;
	
	[ResourceBundle("transmitterscreen")]
	[ResourceBundle("globalsettings")]
	[ResourceBundle("sensorscreen")]

	public class InterfaceController extends EventDispatcher
	{
		private static var initialStart:Boolean = true;
		private static var _instance:InterfaceController;
		public static var peripheralConnected:Boolean = false;
		public static var peripheralConnectionStatusChangeTimestamp:Number;
		public static var dateFormatterForSensorStartTimeAndDate:DateTimeFormatter;
		
		public function InterfaceController() {}
		
		public static function init():void
		{
			if(_instance == null)
				_instance = new InterfaceController();
			
			if (initialStart) {
				Trace.init();
				Database.instance.addEventListener(DatabaseEvent.DATABASE_INIT_FINISHED_EVENT,onInitResult);
				Database.instance.addEventListener(DatabaseEvent.ERROR_EVENT,onInitError);
				//need to know when modellocator is populated, then we can also update display
				Database.instance.addEventListener(DatabaseEvent.BGREADING_RETRIEVAL_EVENT, bgReadingReceivedFromDatabase);
				Database.init();
				initialStart = false;
				
				dateFormatterForSensorStartTimeAndDate = new DateTimeFormatter();
				dateFormatterForSensorStartTimeAndDate.dateTimePattern = "dd MMM HH:mm";
				dateFormatterForSensorStartTimeAndDate.useUTC = false;
				dateFormatterForSensorStartTimeAndDate.setStyle("locale",Capabilities.language.substr(0,2));
			}
			
			
			function onInitResult(event:DatabaseEvent):void
			{
				trace("Interface Controller : Database initialized successfully!");
				//at this moment the database is intialised, but the logs, bgreadings, ... might still be read in the ModelLocator, Modellocator is listening to the same event
				
				BluetoothService.instance.addEventListener(BlueToothServiceEvent.BLUETOOTH_SERVICE_INITIATED, blueToothServiceInitiated);
				
				/*CalibrationService.instance.addEventListener(CalibrationServiceEvent.INITIAL_CALIBRATION_EVENT, initialCalibrationEventReceived);
				CalibrationService.instance.addEventListener(CalibrationServiceEvent.NEW_CALIBRATION_EVENT, newCalibrationEventReceived);*/
				
				setup3DTouch();
			}
			
			function onInitError(event:DatabaseEvent):void
			{	
				trace("Interface Controller : Error initializing database!");
			}
			
			function bgReadingReceivedFromDatabase(de:DatabaseEvent):void {
				if (de.data != null)
				{
					if (de.data is String) {
						if (de.data as String == Database.END_OF_RESULT) {
							_instance.dispatchEvent(new DatabaseEvent(DatabaseEvent.BGREADING_RETRIEVAL_EVENT))
						}
					}
				}
			}
		}
		
		private static function setup3DTouch():void
		{
			if(Capabilities.cpuArchitecture == "ARM") {
				var touch:Touch3D = new Touch3D();
				touch.init()
				touch.addEventListener(Touch3DEvent.SHORTCUT_ITEM, itemStatus);
				touch.removeShortcutItem("calibration");
				touch.removeShortcutItem("startsensor");
				touch.removeShortcutItem("stopsensor");
				touch.addShortcutItem("calibration","Enter Calibration","","UIApplicationShortcutIconTypeAdd");
				touch.addShortcutItem("startsensor","Start Sensor","","UIApplicationShortcutIconTypeConfirmation");
				touch.addShortcutItem("stopsensor","Stop Sensor","","UIApplicationShortcutIconTypeProhibit");
			}
		}
		
		private static function itemStatus(e:Touch3DEvent):void
		{
			if (e.itemValue == "calibration")
				CalibrationService.calibrationOnRequest();
			else if (e.itemValue == "stopsensor")
			{
				AlertManager.showActionAlert(
					ModelLocator.resourceManagerInstance.getString('sensorscreen','stop_sensor_alert_title'),
					ModelLocator.resourceManagerInstance.getString('sensorscreen','stop_sensor_alert_message'),
					60,
					[
						{ label: ModelLocator.resourceManagerInstance.getString('sensorscreen','cancel_alert_button_label') },
						{ label: ModelLocator.resourceManagerInstance.getString('sensorscreen','stop_alert_button_label'), triggered: onStopSensorTriggered }
					]
				);
			}
			else if (e.itemValue == "startsensor")
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
							{ label: ModelLocator.resourceManagerInstance.getString('sensorscreen','cancel_alert_button_label') },
							{ label: ModelLocator.resourceManagerInstance.getString('sensorscreen','stop_alert_button_label'), triggered: onStopSensorTriggered }
						]
					);
				}
			}
		}
		
		private static function onStopSensorTriggered(e:Event):void
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
						ModelLocator.resourceManagerInstance.getString('globalsettings', "license_alert_title"),
						ModelLocator.resourceManagerInstance.getString('globalsettings', "license_alert_message"),
						Number.NaN,
						[
							{ label: ModelLocator.resourceManagerInstance.getString('globalsettings', "agree_alert_button_label"), triggered: onLicenseAccepted }
						]
					);
				licenseAlert.height = 420;
			}
		}
		
		private static function onLicenseAccepted (e:Event):void
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
			BluetoothService.instance.addEventListener(BlueToothServiceEvent.BLUETOOTH_DEVICE_CONNECTION_COMPLETED, bluetoothDeviceConnectionCompleted);
			BluetoothLE.service.centralManager.addEventListener(PeripheralEvent.DISCONNECT, central_peripheralDisconnectHandler);
		}
		
		private static function bluetoothDeviceConnectionCompleted(event:BlueToothServiceEvent):void 
		{
			Trace.myTrace("interfaceController.as", "in bluetoothDeviceConnectionCompleted");
			if (!peripheralConnected) 
			{
				Trace.myTrace("interfaceController.as", "in bluetoothDeviceConnectionCompleted, setting peripheralConnected = true");
				peripheralConnected = true;
				peripheralConnectionStatusChangeTimestamp = (new Date()).valueOf();
			}
		}
		
		private static function central_peripheralDisconnectHandler(event:PeripheralEvent):void 
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
					ModelLocator.resourceManagerInstance.getString('transmitterscreen',"scanning_failed_message") + (BlueToothDevice.known() ? (" " + ModelLocator.resourceManagerInstance.getString('homeview',"with_name") + " " + BlueToothDevice.name) + "\n\n" + ModelLocator.resourceManagerInstance.getString('homeview',"explain_expected_device_name"): ""),
					Number.NaN,
					null,
					HorizontalAlign.CENTER
				);	
			}
		}
		
		public static function userInitiatedBTScanningSucceeded(event:PeripheralEvent):void 
		{
			BluetoothLE.service.centralManager.removeEventListener(PeripheralEvent.CONNECT, InterfaceController.userInitiatedBTScanningSucceeded);
			
			AlertManager.showSimpleAlert
			(
				ModelLocator.resourceManagerInstance.getString('transmitterscreen',"scan_for_device_alert_title"),
				ModelLocator.resourceManagerInstance.getString('transmitterscreen',"connected_to_peripheral_device_id_stored"),
				30
			);
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