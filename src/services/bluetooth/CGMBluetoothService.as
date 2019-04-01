package services.bluetooth
{
	import com.distriqt.extension.bluetoothle.AuthorisationStatus;
	import com.distriqt.extension.bluetoothle.BluetoothLE;
	import com.distriqt.extension.bluetoothle.BluetoothLEState;
	import com.distriqt.extension.bluetoothle.events.BluetoothLEEvent;
	import com.distriqt.extension.bluetoothle.events.CharacteristicEvent;
	import com.distriqt.extension.bluetoothle.events.PeripheralEvent;
	import com.distriqt.extension.bluetoothle.objects.Characteristic;
	import com.distriqt.extension.bluetoothle.objects.Peripheral;
	import com.distriqt.extension.notifications.Notifications;
	import com.distriqt.extension.notifications.builders.NotificationBuilder;
	import com.distriqt.extension.notifications.events.NotificationEvent;
	import com.spikeapp.spike.airlibrary.SpikeANE;
	import com.spikeapp.spike.airlibrary.SpikeANEEvent;
	
	import flash.desktop.NativeApplication;
	import flash.desktop.SystemIdleMode;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.system.Capabilities;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.utils.Timer;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	import G5G6Model.AuthChallengeRxMessage;
	import G5G6Model.AuthChallengeTxMessage;
	import G5G6Model.AuthRequestTxMessage;
	import G5G6Model.AuthStatusRxMessage;
	import G5G6Model.BatteryInfoRxMessage;
	import G5G6Model.BatteryInfoTxMessage;
	import G5G6Model.ResetTxMessage;
	import G5G6Model.SensorRxMessage;
	import G5G6Model.SensorTxMessage;
	import G5G6Model.VersionRequestTxMessage;
	
	import database.BgReading;
	import database.CGMBlueToothDevice;
	import database.CommonSettings;
	import database.LocalSettings;
	
	import distriqtkey.DistriqtKey;
	
	import events.BlueToothServiceEvent;
	import events.NotificationServiceEvent;
	import events.SettingsServiceEvent;
	import events.SpikeEvent;
	
	import feathers.controls.Alert;
	
	import model.ModelLocator;
	import model.Tomato;
	import model.TransmitterDataBluKonPacket;
	import model.TransmitterDataBlueReaderBatteryPacket;
	import model.TransmitterDataBlueReaderPacket;
	import model.TransmitterDataG5G6Packet;
	import model.TransmitterDataTransmiter_PLPacket;
	import model.TransmitterDataXBridgeBeaconPacket;
	import model.TransmitterDataXBridgeDataPacket;
	import model.TransmitterDataXBridgeRDataPacket;
	import model.TransmitterDataXdripDataPacket;
	
	import services.NotificationService;
	
	import starling.events.Event;
	import starling.utils.SystemUtil;
	
	import ui.InterfaceController;
	import ui.popups.AlertManager;
	import ui.popups.EmailFileSender;
	
	import utils.BadgeBuilder;
	import utils.Trace;
	import utils.UniqueId;
	import utils.libre.LibreAlarmReceiver;
	
	/**
	 * all functionality related to bluetooth connectivity<br>
	 * Only for CGM transmitters.
	 */
	public class CGMBluetoothService extends EventDispatcher
	{
		[ResourceBundle("globaltranslations")]
		[ResourceBundle("bluetoothservice")]
		[ResourceBundle("transmitterservice")]
		[ResourceBundle("wixelsender")]
		
		private static var _instance:CGMBluetoothService = new CGMBluetoothService();
		public static function get instance():CGMBluetoothService
		{
			return _instance;
		}
		private static var initialStart:Boolean = true;
		
		//needed for en- decoding G4 transmitter id
		private static const srcNameTable:Array = [ '0', '1', '2', '3', '4', '5', '6', '7',
			'8', '9', 'A', 'B', 'C', 'D', 'E', 'F',
			'G', 'H', 'J', 'K', 'L', 'M', 'N', 'P',
			'Q', 'R', 'S', 'T', 'U', 'W', 'X', 'Y' ];

		
		//All UUD's used in bluetooth communication for different peripheral types
		//xdrip UUID's
		private static const G4_Service_UUID:String = "0000FFE0-0000-1000-8000-00805F9B34FB"; 
		private static const G4_RX_Characteristic_UUID:String = "0000FFE1-0000-1000-8000-00805F9B34Fb";
		private static const G4_TX_Characteristic_UUID:String = G4_RX_Characteristic_UUID;
		private static const G4_Advertisement_UUID:String = G4_Service_UUID;
		private static const G4_Characteristics_UUID_Vector:Vector.<String> = new <String>[G4_RX_Characteristic_UUID];
		
		//G5 & G6 UUID's
		private static const G5_G6_Service_UUID:String = "F8083532-849E-531C-C594-30F1F86A4EA5"; 
		//private static const G5_Communication_Characteristic_UUID:String = "F8083533-849E-531C-C594-30F1F86A4EA5";//not used for the moment
		private static const G5_G6_Control_Characteristic_UUID:String = "F8083534-849E-531C-C594-30F1F86A4EA5";
		private static const G5_G6_Authentication_Characteristic_UUID:String = "F8083535-849E-531C-C594-30F1F86A4EA5";
		private static const G5_G6_Advertisement_UUID:String = "0000FEBC-0000-1000-8000-00805F9B34FB";
		private static const G5_G6_Characteristics_UUID_Vector:Vector.<String> = new <String>[G5_G6_Authentication_Characteristic_UUID, G5_G6_Control_Characteristic_UUID];
		
		//Blucon UUID's
		private static const Blucon_Service_UUID:String = "436A62C0-082E-4CE8-A08B-01D81F195B24"; 
		private static const Blucon_RX_Characteristic_UUID:String = "436A0C82-082E-4CE8-A08B-01D81F195B24";
		private static const Blucon_TX_Characteristic_UUID:String = "436AA6E9-082E-4CE8-A08B-01D81F195B24";
		private static const Blucon_Advertisement_UUID:String = Blucon_Service_UUID;
		private static const Blucon_Characteristics_UUID_Vector:Vector.<String> = new <String>[Blucon_RX_Characteristic_UUID, Blucon_TX_Characteristic_UUID];
		
		//Bluereader UUID's
		private static const BlueReader_Service_UUID:String = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E";
		private static const BlueReader_RX_Characteristic_UUID:String = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E";
		private static const BlueReader_TX_Characteristic_UUID:String = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E";
		private static const BlueReader_Advertisement_UUID:String = "";
		private static const BlueReader_Characteristics_UUID_Vector:Vector.<String> = new <String>[BlueReader_TX_Characteristic_UUID, BlueReader_RX_Characteristic_UUID];
		
		//Transmiter PL UUID's
		private static const Transmiter_PL_Service_UUID:String = "C97433F0-BE8F-4DC8-B6F0-5343E6100EB4";
		private static const Transmiter_PL_RX_Characteristic_UUID:String = "C97433F1-BE8F-4DC8-B6F0-5343E6100EB4";
		private static const Transmiter_PL_TX_Characteristic_UUID:String = "C97433F2-BE8F-4DC8-B6F0-5343E6100EB4";
		private static const Transmiter_PL_Advertisement_UUID:String = Transmiter_PL_Service_UUID;
		private static const Transmiter_PL_Characteristics_UUID_Vector:Vector.<String> = new <String>[Transmiter_PL_RX_Characteristic_UUID, Transmiter_PL_TX_Characteristic_UUID];
		
		//xbridger uses the same uuid's as xdrip except for TX Characteristic
		private static const xBridgeR_Service_UUID:String = "0000FFE0-0000-1000-8000-00805F9B34FB"; 
		private static const xBridgeR_RX_Characteristic_UUID:String = "0000FFE1-0000-1000-8000-00805F9B34FB";
		private static const xBridgeR_TX_Characteristic_UUID:String = "0000FFE2-0000-1000-8000-00805F9B34FB";
		private static const xBridgeR_Advertisement_UUID:String = xBridgeR_Service_UUID;
		private static const xBridgeR_Characteristics_UUID_Vector:Vector.<String> = new <String>[xBridgeR_RX_Characteristic_UUID];
		
		//Following variables with get value which is dependent on peripheral type
		/**
		 * the service_UUID to use for the selected devicetype 
		 */
		private static var service_UUID:String = "";
		/**
		 * advertisement uuid vector for the selectecd devicetype
		 */
		private static var advertisement_UUID_Vector:Vector.<String>;
		/**
		 * chararacteristics uuid to use for the selected devicetype
		 */
		private static var characteristics_UUID_Vector:Vector.<String>;
		/**
		 * Receive characteristic UUID for the selectecd devicetype
		 */
		private static var RX_Characteristic_UUID:String;
		/**
		 * Transmit characteristic UUID for the selectecd devicetype
		 */
		private static var TX_Characteristic_UUID:String;
		/**
		 * service UUID vector for the selectecd devicetype
		 */
		private static var service_UUID_Vector:Vector.<String>;

		/**
		 * the read characteristic to be used for all types of peripheral. For G5 this is used as authentication characteristics
		 */
		private static var readCharacteristic:Characteristic;
		
		/**
		 * the write characteristic to be used for all types of peripheral. For G5 this is used as control characteristics 
		 */
		private static var writeCharacteristic:Characteristic;
		
		//generic global variables needed for bluetooth communications
		private static var connectionAttemptTimeStamp:Number;
		private static const maxTimeBetweenConnectAttemptAndConnectSuccess:Number = 3;
		private static var waitingForPeripheralCharacteristicsDiscovered:Boolean = false;
		private static var waitingForServicesDiscovered:Boolean = false;
		private static var discoveryTimeStamp:Number;
		private static var _activeBluetoothPeripheral:Peripheral;
		private static const MAX_SCAN_TIME_IN_SECONDS:int = 320;
		private static var discoverServiceOrCharacteristicTimer:Timer;//sometimes discover services just doesn't give anything, mainly with xdrip/xbridge this happened
		private static const DISCOVER_SERVICES_OR_CHARACTERISTICS_RETRY_TIME_IN_SECONDS:int = 1;
		private static const MAX_RETRY_DISCOVER_SERVICES_OR_CHARACTERISTICS:int = 5;
		private static var amountOfDiscoverServicesOrCharacteristicsAttempt:int = 0;
		private static var awaitingConnect:Boolean = false;
		private static var scanTimer:Timer;//only for peripheral types of type not always scan
		private static var peripheralUUID:String = "";

		/**
		 * is the peripheral connected or not, not applicable to MiaoMiao which is handled by BackgroundFetch ANE 
		 */
		private static var peripheralConnected:Boolean = true;
		
		//Dexcom G5 & G6 variables
		private static var timeStampOfLastG5G6Reading:Number = 0;
		private static const G5_G6_BATTERY_READ_PERIOD_MS:Number = 1000 * 60 * 60 * 12; // how often to poll battery data (12 hours)
		private static var authRequest:AuthRequestTxMessage = null;
		private static var authStatus:AuthStatusRxMessage = null;
		private static var awaitingAuthStatusRxMessage:Boolean = false;//used for G5/G6, to detect situations where other app is connecting to G5/G6
		private static var timeStampOfLastInfoAboutOtherApp:Number = 0;//used for G5/G6, to detect situations where other app is connecting to G5/G6
		/**
		 * If user has other app running that connects to the same G5/G6 transmitter, this will not work<br>
		 * The app is trying to detect this situation, to avoid complaints<br>
		 * However the detection mechanism sometimes thinks there's another app trying to connect althought this is not the case<br>
		 * Therefore the amount of notifications will be reduced, this setting counts the number
		 */
		private static var MAX_WARNINGS_OTHER_APP_CONNECTING_TO_G5_G6:int = 5;
		private static var G5_G6_RECONNECT_TIME_IN_SECONDS:int = 15;
		/**
		 * If true, G5_G6_Reset will be sent next time the G5/G6 connects<br>
		 * After sending reset, the variable is reset to false;<br>
		 * Use G5_G6RequestReset to set to true
		 */
		private static var G5_G6_RESET_REQUESTED:Boolean = false;
		private static var G5G6ResetTimeStamp:Number =0 ;
		private static var useSpikeANEForG5G6:Boolean = true;
				
		//Transmiter_PL variables
		private static var timeStampSinceLastSensorAgeUpdate_Transmiter_PL:Number = 0;
		private static var previousSensorAgeValue_Transmiter_PL:Number = 0;

		//Blucon variables
		private static var m_getNowGlucoseDataIndexCommand:Boolean = false;
		private static var m_currentTrendIndex:int;
		private static var m_currentBlockNumber:String = "";
		private static var m_currentOffset:int = 0;
		private static var m_minutesDiffToLastReading:int = 0;
		private static var m_minutesBack:int;
		private static var m_getOlderReading:Boolean = false;
		private static var m_getNowGlucoseDataCommand:Boolean = false;// to be sure we wait for a GlucoseData Block and not using another block
		private static var m_persistentTimeLastBg:Number;
		private static var m_blockNumber:int = 0;
		private static var m_full_data:ByteArray = new ByteArray();
		private static var nowGlucoseOffset:int = 0;
		private static var timeStampOfLastDeviceNotPairedForBlukon:Number = 0;
		private static var blukonCurrentCommand:String="";
		private static var GET_SENSOR_AGE_DELAY_IN_SECONDS:int =  1 * 3600;
		private static var FSLSensorAGe:Number;
		private static var startedMonitoringAndRangingBeaconsInRegion:Boolean = false;//only for Blucon
						
		//MiaoMiao variables
		public static var _amountOfConsecutiveSensorNotDetectedForMiaoMiao:int = 0;
		/**
		 * if miaomiao, this is the amount of times a sensorNotDetected was received consecutively without receiving a full data packet
		 */
		public static function get amountOfConsecutiveSensorNotDetectedForMiaoMiao():int
		{
			return _amountOfConsecutiveSensorNotDetectedForMiaoMiao;
		}
		
		private static function set activeBluetoothPeripheral(value:Peripheral):void
		{
			if (value == _activeBluetoothPeripheral)
				return;
			
			_activeBluetoothPeripheral = value;
			
			if (_activeBluetoothPeripheral != null) {
				_activeBluetoothPeripheral.addEventListener(PeripheralEvent.DISCOVER_SERVICES, peripheral_discoverServicesHandler );
				_activeBluetoothPeripheral.addEventListener(PeripheralEvent.DISCOVER_CHARACTERISTICS, peripheral_discoverCharacteristicsHandler );
				_activeBluetoothPeripheral.addEventListener(CharacteristicEvent.UPDATE, peripheral_characteristic_updatedHandler);
				_activeBluetoothPeripheral.addEventListener(CharacteristicEvent.UPDATE_ERROR, peripheral_characteristic_errorHandler);
				_activeBluetoothPeripheral.addEventListener(CharacteristicEvent.SUBSCRIBE, peripheral_characteristic_subscribeHandler);
				_activeBluetoothPeripheral.addEventListener(CharacteristicEvent.SUBSCRIBE_ERROR, peripheral_characteristic_subscribeErrorHandler);
				_activeBluetoothPeripheral.addEventListener(CharacteristicEvent.UNSUBSCRIBE, peripheral_characteristic_unsubscribeHandler);
				_activeBluetoothPeripheral.addEventListener(CharacteristicEvent.WRITE_SUCCESS, peripheral_characteristic_writeHandler);
				_activeBluetoothPeripheral.addEventListener(CharacteristicEvent.WRITE_ERROR, peripheral_characteristic_writeErrorHandler);
			}
		}
		
		private static function get activeBluetoothPeripheral():Peripheral {
			return _activeBluetoothPeripheral;
		}
		
		public function CGMBluetoothService()
		{
			if (_instance != null) {
				throw new Error("BluetoothService class constructor can not be used");	
			}
		}
		
		/**
		 * start all bluetooth related activity : scanning, connecting, start listening ...<br>
		 * Also intializes BlueToothDevice with values retrieved from Database. 
		 */
		public static function init():void {
			if (!initialStart)
				return;
			else
				initialStart = false;
			
			//Check if database was previously resetted. 
			if (SpikeANE.getDatabaseResetStatus() == true)
			{
				myTrace("Database was previously restored. Forgetting current Bluetooth device...");
				
				//Update the reset flag to false so it doesn't run again on the next Spike boot
				SpikeANE.setDatabaseResetStatus(false);
				
				//Forget current Bluetooth device 
				CGMBlueToothDevice.forgetBlueToothDevice();
				
				//Start automatic scanning after 5 seconds
				var autoScanTimeout:uint = setTimeout( function():void 
				{
					clearTimeout(autoScanTimeout);
					if (BluetoothLE.service.centralManager.state == BluetoothLEState.STATE_ON && !CGMBluetoothService.bluetoothPeripheralActive() && !CGMBlueToothDevice.alwaysScan())
					{
						myTrace("Starting automatic scan after database restore...");
						NativeApplication.nativeApplication.systemIdleMode = SystemIdleMode.KEEP_AWAKE;
						CGMBluetoothService.instance.addEventListener(BlueToothServiceEvent.STOPPED_SCANNING, InterfaceController.btScanningStopped, false, 0, true);
						CGMBluetoothService.startScanning(true);
					}
				}, 5000 );
			}
			
			peripheralConnected = false;
			
			//Define G5/G6 ANE Method
			useSpikeANEForG5G6 = Capabilities.os.indexOf("OS 8") == -1 ? true : false;
			
			Spike.instance.addEventListener(SpikeEvent.APP_HALTED, onHaltExecution);
			CommonSettings.instance.addEventListener(SettingsServiceEvent.SETTING_CHANGED, commonSettingChanged);
			NotificationService.instance.addEventListener(NotificationServiceEvent.NOTIFICATION_EVENT, notificationReceived);
			NotificationService.instance.addEventListener(NotificationServiceEvent.NOTIFICATION_SELECTED_EVENT, notificationReceived);

			//blukon
			m_getNowGlucoseDataCommand = false;
			m_getNowGlucoseDataIndexCommand = false;
			m_getOlderReading = false;
			m_blockNumber = 0;
			CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_BLUKON_BATTERY_LEVEL, "0");
			CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_TIME_STAMP_LAST_SENSOR_AGE_CHECK_IN_MS, "0");
			
			//Miaomiao
			CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_MIAOMIAO_BATTERY_LEVEL, "0");
			
			if (CGMBlueToothDevice.isMiaoMiao()) {
				SpikeANE.startScanDeviceMiaoMiao();
				if (CGMBlueToothDevice.known()) {
					SpikeANE.setMiaoMiaoMac(CGMBlueToothDevice.address);
				}
			} else if ((CGMBlueToothDevice.isDexcomG5() || CGMBlueToothDevice.isDexcomG6()) && useSpikeANEForG5G6) {
				SpikeANE.startScanDeviceG5();
				if (CGMBlueToothDevice.known()) {
					SpikeANE.setG5Mac(CGMBlueToothDevice.address);
				}
				SpikeANE.setTransmitterIdG5(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TRANSMITTER_ID), cryptKey());
			}
			
			setPeripheralUUIDs();
			
			BluetoothLE.init(!ModelLocator.IS_IPAD ? DistriqtKey.distriqtKey : DistriqtKey.distriqtKeyIpad);
			if (BluetoothLE.isSupported) {
				switch (BluetoothLE.service.authorisationStatus()) {
					case AuthorisationStatus.SHOULD_EXPLAIN:
						BluetoothLE.service.requestAuthorisation();
						break;
					case AuthorisationStatus.DENIED:
					case AuthorisationStatus.RESTRICTED:
					case AuthorisationStatus.UNKNOWN:
						break;
					
					case AuthorisationStatus.NOT_DETERMINED:
					case AuthorisationStatus.AUTHORISED:				
						if (CGMBlueToothDevice.isMiaoMiao()) {
							addMiaoMiaoEventListeners();
						} else if ((CGMBlueToothDevice.isDexcomG5() || CGMBlueToothDevice.isDexcomG6()) && useSpikeANEForG5G6) {
							addG5G6EventListeners();
						} else {
							addBluetoothLEEventListeners();
						}
						
						var blueToothServiceEvent:BlueToothServiceEvent = new BlueToothServiceEvent(BlueToothServiceEvent.BLUETOOTH_SERVICE_INITIATED);
						_instance.dispatchEvent(blueToothServiceEvent);
						
						switch (BluetoothLE.service.centralManager.state)
						{
							case BluetoothLEState.STATE_ON:	
								// We can use the Bluetooth LE functions
								bluetoothStatusIsOn();
								myTrace("in init, bluetooth is switched on")
								break;
							case BluetoothLEState.STATE_OFF:
								myTrace("in init, bluetooth is switched off")
								break;
							case BluetoothLEState.STATE_RESETTING:	
								break;
							case BluetoothLEState.STATE_UNAUTHORISED:
								break;
							case BluetoothLEState.STATE_UNSUPPORTED:
								break;
							case BluetoothLEState.STATE_UNKNOWN:
								break;
						}
				}
				
			} else {
				myTrace("Unfortunately your Device does not support Bluetooth Low Energy");
			}
		}
		
		private static function notificationReceived(event:NotificationServiceEvent):void {
			if (event != null) {
				var notificationEvent:NotificationEvent = event.data as NotificationEvent;
				if (notificationEvent.id == NotificationService.ID_FOR_OTHER_G5_APP) {
					var otherAppTitle:String = "";
					var otherAppBody:String = "";
					
					if (CGMBlueToothDevice.isDexcomG5())
					{
						otherAppTitle = ModelLocator.resourceManagerInstance.getString("bluetoothservice","other_G5_app");
						otherAppBody = ModelLocator.resourceManagerInstance.getString("bluetoothservice","other_G5_app_info");
					}
					else if (CGMBlueToothDevice.isDexcomG6())
					{
						otherAppTitle = ModelLocator.resourceManagerInstance.getString("bluetoothservice","other_G5_app").replace("G5", "G6");
						otherAppBody = ModelLocator.resourceManagerInstance.getString("bluetoothservice","other_G5_app_info").replace("G5", "G6");
					}
					
					AlertManager.showSimpleAlert
					(
						otherAppTitle,
						otherAppBody
					);
				} else if (notificationEvent.id == NotificationService.ID_FOR_DEAD_OR_EXPIRED_SENSOR_TRANSMITTER_PL) {
					AlertManager.showSimpleAlert
						(
						ModelLocator.resourceManagerInstance.getString("globaltranslations","warning_alert_title"),
						ModelLocator.resourceManagerInstance.getString("bluetoothservice","dead_or_expired_sensor")
					);
				}
				else if (notificationEvent.id == NotificationService.ID_FOR_SENSOR_NOT_DETECTED_MIAOMIAO) {
					AlertManager.showSimpleAlert
					(
						ModelLocator.resourceManagerInstance.getString("globaltranslations","warning_alert_title"),
						ModelLocator.resourceManagerInstance.getString("bluetoothservice","sensor_not_detected_miaomiao")
					);
				} 
			}
		}
		
		private static function commonSettingChanged(event:SettingsServiceEvent):void {
			if (event.data == CommonSettings.COMMON_SETTING_PERIPHERAL_TYPE) {
				myTrace("in commonSettingChanged, event.data = COMMON_SETTING_PERIPHERAL_TYPE");
				
				//set transmitter id in spike ane, doesn't matter if it's a G5/G6 or not , or if the transmitter id is just an empty string or whatever
				SpikeANE.setTransmitterIdG5(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TRANSMITTER_ID), cryptKey());

				//new peripheraltype, all bluetoothe uuid's need to get  new values
				setPeripheralUUIDs();
				
				if (scanTimer != null) {
					if (scanTimer.running) {
						scanTimer.stop();
					}
					scanTimer = null;
				}
				
				stopScanning(null);//need to stop scanning because device type has changed, means also the UUID to scan for
				if (!CGMBlueToothDevice.isFollower()) {
					if (CGMBlueToothDevice.alwaysScan() && CGMBlueToothDevice.transmitterIdKnown()) {
						if (BluetoothLE.service.centralManager.state == BluetoothLEState.STATE_ON) {
							startScanning();
						}
					} else {
					}
				}
				
				CGMBlueToothDevice.forgetBlueToothDevice();
				SpikeANE.forgetG5Peripheral();
				SpikeANE.forgetMiaoMiaoPeripheral();
				
				if (CGMBlueToothDevice.isMiaoMiao()) {
					SpikeANE.startScanDeviceMiaoMiao();
					addMiaoMiaoEventListeners();
				} else if ((CGMBlueToothDevice.isDexcomG5() || CGMBlueToothDevice.isDexcomG6()) && useSpikeANEForG5G6) {
					addG5G6EventListeners();
				} else {
					addBluetoothLEEventListeners();
				}
				
			} else if (event.data == CommonSettings.COMMON_SETTING_TRANSMITTER_ID) {
				myTrace("in commonSettingChanged, event.data = COMMON_SETTING_TRANSMITTER_ID, calling BlueToothDevice.forgetbluetoothdevice");

				//set transmitter id in spike ane, doesn't matter if it's a G5/G6 or not , or if the transmitter id is just an empty string or whatever
				SpikeANE.setTransmitterIdG5(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TRANSMITTER_ID), cryptKey());

				CGMBlueToothDevice.forgetBlueToothDevice();
				SpikeANE.forgetG5Peripheral();
				SpikeANE.forgetMiaoMiaoPeripheral();
				if (CGMBlueToothDevice.transmitterIdKnown() && CGMBlueToothDevice.alwaysScan()) {
					if (BluetoothLE.service.centralManager.state == BluetoothLEState.STATE_ON) {
						myTrace("in commonSettingChanged, event.data = COMMON_SETTING_TRANSMITTER_ID, restart scanning");
						startScanning();
					} else {
						myTrace("in commonSettingChanged, event.data = COMMON_SETTING_TRANSMITTER_ID, restart scanning needed but bluetooth is not on");
					}
				} else {
					myTrace("in commonSettingChanged, event.data = COMMON_SETTING_TRANSMITTER_ID but transmitter id not known or alwaysscan is false");
				}
			} else if (event.data == CommonSettings.COMMON_SETTING_CURRENT_SENSOR) {
				if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CURRENT_SENSOR) == "0") {
					myTrace("in commonSettingChanged, setting timeStampSinceLastSensorAgeUpdate_Transmiter_PL and previousSensorAgeValue_Transmiter_PL to 0");
					timeStampSinceLastSensorAgeUpdate_Transmiter_PL = 0;
					previousSensorAgeValue_Transmiter_PL = 0;
				}
			}
		}
		
		private static function bluetoothStateChangedHandler(event:BluetoothLEEvent):void
		{
			switch (BluetoothLE.service.centralManager.state)
			{
				case BluetoothLEState.STATE_ON:	
					myTrace("in bluetoothStateChangedHandler, bluetooth is switched on")
					// We can use the Bluetooth LE functions
					bluetoothStatusIsOn();
					break;
				case BluetoothLEState.STATE_OFF:
					myTrace("in bluetoothStateChangedHandler, bluetooth is switched off")
					break;//does the device automatically change to connected ? 
				case BluetoothLEState.STATE_RESETTING:	
					break;
				case BluetoothLEState.STATE_UNAUTHORISED:	
					break;
				case BluetoothLEState.STATE_UNSUPPORTED:	
					break;
				case BluetoothLEState.STATE_UNKNOWN:
					break;
			}
		}
		
		private static function bluetoothStatusIsOn():void {
			if (activeBluetoothPeripheral != null && !(CGMBlueToothDevice.alwaysScan())) {//do we ever pass here, activebluetoothperipheral is set to null after disconnect
				awaitingConnect = true;
				connectionAttemptTimeStamp = (new Date()).valueOf();
				BluetoothLE.service.centralManager.connect(activeBluetoothPeripheral);
				myTrace("in bluetoothStatusIsOn, Trying to connect to known device.");
			} else if (activeBluetoothPeripheral != null && (CGMBlueToothDevice.isBlueReader() || CGMBlueToothDevice.isDexcomG5() || CGMBlueToothDevice.isDexcomG6() || CGMBlueToothDevice.isBluKon() || CGMBlueToothDevice.isDexcomG4())) {
				awaitingConnect = true;
				connectionAttemptTimeStamp = (new Date()).valueOf();
				BluetoothLE.service.centralManager.connect(activeBluetoothPeripheral);
				myTrace("in bluetoothStatusIsOn, Trying to connect.");
			} else if (CGMBlueToothDevice.isMiaoMiao()) {
				if (CGMBlueToothDevice.known()) {
					myTrace("in bluetoothStatusIsOn, isMiaoMiao");
					SpikeANE.setMiaoMiaoMac(CGMBlueToothDevice.address);
					startScanning();
				}
				myTrace("in bluetoothStatusIsOn, device is miaomiao - DO WE NEED TO DEVELOP ANYTHING HERE ?.");
			} else if (CGMBlueToothDevice.known() || (CGMBlueToothDevice.alwaysScan() && CGMBlueToothDevice.transmitterIdKnown())) {
				myTrace("bluetoothStatusIsOn, call startScanning");
				startScanning();
			} else {
				myTrace("in bluetootbluetoothStatusIsOn; but not restarting scan");
			}
		}
		
		public static function startScanning(itsNotAnAlwaysScanDevice:Boolean = false):void {
			if (CGMBlueToothDevice.isFollower()) {
				myTrace("in startScanning but follower, not starting scan");
				return;
			}
			
			if (CGMBlueToothDevice.isMiaoMiao()) {
				myTrace("in startScanning, is miaomiao");
				SpikeANE.startScanningForMiaoMiao();
				return;
			}
			
			if ((CGMBlueToothDevice.isDexcomG5() || CGMBlueToothDevice.isDexcomG6()) && useSpikeANEForG5G6) {
				myTrace("in startScanning, is dexcomG5 and useSpikeANEForG5 =  true");
				SpikeANE.startScanDeviceG5();
				SpikeANE.startScanningForG5();
				return;
			}

			if (!BluetoothLE.service.centralManager.isScanning) {
				if (advertisement_UUID_Vector != null) {
					if (!BluetoothLE.service.centralManager.scanForPeripherals(advertisement_UUID_Vector))
					{
						myTrace("in startScanning, failed to start scanning for peripherals");
						return;
					} else {
						myTrace("in startScanning, started scanning for peripherals");
						if (itsNotAnAlwaysScanDevice) {
							myTrace("in startScanning, it's a device which does not require always scanning, start the scan timer");
							scanTimer = new Timer(MAX_SCAN_TIME_IN_SECONDS * 1000, 1);
							scanTimer.addEventListener(TimerEvent.TIMER, stopScanning);
							scanTimer.start();
						}
						if (CGMBlueToothDevice.isBluKon()) {
							startMonitoringAndRangingBeaconsInRegion(Blucon_Advertisement_UUID);
						}
					}
				} else {
					myTrace("in startscanning but advertisement_UUID_Vector == null");
				}
			} else {
				myTrace("in startscanning but already scanning");
			}
		}
		
		public static function stopScanning(event:flash.events.Event):void {
			myTrace("in stopScanning");
			
			//Stop scanning for both miaomiao and for the ANE
			//Not sure here which one is scanning
			
			//stop scanning the miaomiao & G5/G6 (if G5/G6 via ANE) - doesn't matter if it's scanning or not
			SpikeANE.stopScanningMiaoMiao();
			SpikeANE.stopScanningG5();
			
			//stop scanning the ANE
			if (BluetoothLE.service.centralManager.isScanning) {
				myTrace("in stopScanning, is scanning, call stopScan");
				BluetoothLE.service.centralManager.stopScan();
				if (CGMBlueToothDevice.isBluKon()) {
					stopMonitoringAndRangingBeaconsInRegion(Blucon_Advertisement_UUID);
				}
				_instance.dispatchEvent(new BlueToothServiceEvent(BlueToothServiceEvent.STOPPED_SCANNING));
			}
		}
		
		private static function central_peripheralDiscoveredHandler(event:PeripheralEvent):void {
			myTrace("in central_peripheralDiscoveredHandler, stop scanning. Device name = " + event.peripheral.name + ", Device address = " + event.peripheral.uuid);
			BluetoothLE.service.centralManager.stopScan();
			if (CGMBlueToothDevice.isBluKon()) {
				stopMonitoringAndRangingBeaconsInRegion(Blucon_Advertisement_UUID);
			}

			discoveryTimeStamp = (new Date()).valueOf();
			if (awaitingConnect && !(CGMBlueToothDevice.alwaysScan())) {
				myTrace("in central_peripheralDiscoveredHandler, but already awaiting connect, restart scan");
				startRescan(null);
				return;
			}
			
			if ((CGMBlueToothDevice.isDexcomG5() || CGMBlueToothDevice.isDexcomG6()) && useSpikeANEForG5G6) {
				myTrace("in central_peripheralDiscoveredHandler, G5/G6, but using SpikeANE, ignore");
				return;
			}
			
			if (CGMBlueToothDevice.isDexcomG5() || CGMBlueToothDevice.isDexcomG6()) {
				if ((new Date()).valueOf() - timeStampOfLastG5G6Reading < 60 * 1000) {
					myTrace("in central_peripheralDiscoveredHandler, G5/G6 but last reading was less than 1 minute ago, ignoring this peripheral discovery. restart scan");
					startRescan(null);
					return;
				}
			}
			
			if (CGMBlueToothDevice.isBluKon()) {
				if (peripheralConnected) {
					myTrace("in central_peripheralDiscoveredHandler, blukon, already connected. Ignoring this device (it could be another one) and not restarting scanning");
					return;
				}
			}
			
			//event.peripheral contains a Peripheral object with information about the Peripheral
			//only for DexcomG5 and Blucon we look at the device name. For the others we don't care about the device name
			var expectedPeripheralName:String = expectedPeripheralName();
			
			if (
				!(CGMBlueToothDevice.alwaysScan()) //if always scan peripheral, we don't look at the name of the peripheral
				||
				((CGMBlueToothDevice.isDexcomG5() || CGMBlueToothDevice.isDexcomG6()) &&
					(
						(event.peripheral.name as String).toUpperCase().indexOf(expectedPeripheralName) > -1
					)
				)
				||
				(CGMBlueToothDevice.isBluKon() &&
					(
						(event.peripheral.name as String).toUpperCase().indexOf(expectedPeripheralName) > -1
					)
				)
			) {
				if (CGMBlueToothDevice.address != "") {
					//if (CGMBlueToothDevice.address.toUpperCase() != event.peripheral.uuid.toUpperCase()) {
					if (CGMBlueToothDevice.address.toUpperCase().indexOf(event.peripheral.uuid.toUpperCase()) == -1) {
						myTrace("in central_peripheralDiscoveredHandler, UUID of found peripheral does not match with name of the UUID stored in the database - will ignore this peripheral.");
						startRescan(null);
						return;
					}
				} else {
					//we store also this peripheral, as of now, all future connect attempts will be only to this one, until the user choses "forget device"
					CGMBlueToothDevice.address = event.peripheral.uuid;
					CGMBlueToothDevice.name = event.peripheral.name;
					myTrace("in central_peripheralDiscoveredHandler, Device details will be stored in database. Future attempts will only use this device to connect to.");
				}
				myTrace("in central_peripheralDiscoveredHandler, try to connect");
				awaitingConnect = true;
				connectionAttemptTimeStamp = (new Date()).valueOf();
				peripheralUUID = event.peripheral.uuid;
				BluetoothLE.service.centralManager.connect(event.peripheral);
			} else {
				myTrace("in central_peripheralDiscoveredHandler, doesn't seem to be a device we are interested in. Restart scan");
				startRescan(null);
			}
		}
		
		private static function central_peripheralConnectHandler(event:PeripheralEvent):void {
			if (event.peripheral.uuid != peripheralUUID) {
				myTrace("in central_peripheralConnectHandler, but event.peripheral.uuid != peripheralUUID, ignoring");
				return;
			}
			myTrace("in central_peripheralConnectHandler");
			peripheralConnected = true;
			
			blukonCurrentCommand = "";
			
			if (CGMBlueToothDevice.isDexcomG5() || CGMBlueToothDevice.isDexcomG6()) {
				if ((new Date()).valueOf() - timeStampOfLastG5G6Reading < 15 * 1000) {
					myTrace("in central_peripheralConnectHandler, G5/G6 but last reading was less than 15 seconds ago, no further action. Let G5/G6 do the disconnect");
					return;
				}
			}
			
			if (CGMBlueToothDevice.isBluKon()) {
				if (BluetoothLE.service.centralManager.isScanning) {
					//this may happen because for blukon, after disconnect, we start scanning and also try to reconnect
					myTrace("in central_peripheralConnectHandler, blukon and scanning. Stop scanning");
					BluetoothLE.service.centralManager.stopScan();
					if (CGMBlueToothDevice.isBluKon()) {
						stopMonitoringAndRangingBeaconsInRegion(Blucon_Advertisement_UUID);
					}
				}
			}
			
			if (scanTimer != null) {
				if (scanTimer.running) {
					myTrace("in central_peripheralConnectHandler, stopping scanTimer");
					scanTimer.stop();
				}
				scanTimer = null;
			}

			if (!awaitingConnect && !CGMBlueToothDevice.isBluKon()) {
				myTrace("in central_peripheralConnectHandler but awaitingConnect = false, will disconnect");
				BluetoothLE.service.centralManager.disconnect(event.peripheral);
				return;
			} 
			
			awaitingConnect = false;
			if (!CGMBlueToothDevice.alwaysScan() && !CGMBlueToothDevice.isMiaoMiao()) {//should never be miaomiao ?
				if ((new Date()).valueOf() - connectionAttemptTimeStamp > maxTimeBetweenConnectAttemptAndConnectSuccess * 1000) { //not waiting more than 3 seconds between device discovery and connection success
					myTrace("in central_peripheralConnectHandler but time between connect attempt and connect success is more than " + maxTimeBetweenConnectAttemptAndConnectSuccess + " seconds. Will disconnect");
					BluetoothLE.service.centralManager.disconnect(event.peripheral);
					return;
				} 
			}
			
			if (CGMBlueToothDevice.isBlueReader() || CGMBlueToothDevice.isBluKon()) {
				_instance.dispatchEvent(new BlueToothServiceEvent(BlueToothServiceEvent.BLUETOOTH_DEVICE_CONNECTION_COMPLETED));
			}
			
			myTrace("in central_peripheralConnectHandler, connected to peripheral");
			if (activeBluetoothPeripheral == null)
				activeBluetoothPeripheral = event.peripheral;
			
			if (CGMBlueToothDevice.isBluKon() || CGMBlueToothDevice.isBlueReader() || CGMBlueToothDevice.isDexcomG5() || CGMBlueToothDevice.isDexcomG6() || CGMBlueToothDevice.isDexcomG4())
				activeBluetoothPeripheral = event.peripheral;

			discoverServices();
		}
		
		private static function discoverServices(event:flash.events.Event = null):void {
			myTrace("in discoverServices");
			waitingForServicesDiscovered = false;
			if (activeBluetoothPeripheral == null)//rare case, user might have done forget xdrip while waiting for reattempt
				return;
			
			if (discoverServiceOrCharacteristicTimer != null) {
				discoverServiceOrCharacteristicTimer.stop();
				discoverServiceOrCharacteristicTimer = null;
			}
			
			if (!peripheralConnected) {
				myTrace("in discoverservices,  but peripheralConnected = false, returning");
				amountOfDiscoverServicesOrCharacteristicsAttempt = 0;
				return;
			}
			
			if (amountOfDiscoverServicesOrCharacteristicsAttempt < MAX_RETRY_DISCOVER_SERVICES_OR_CHARACTERISTICS) {
				amountOfDiscoverServicesOrCharacteristicsAttempt++;
				myTrace("in discoverservices, attempt " + amountOfDiscoverServicesOrCharacteristicsAttempt);
				
				waitingForServicesDiscovered = true;
				activeBluetoothPeripheral.discoverServices(service_UUID_Vector);
				if (!CGMBlueToothDevice.isBluKon()) {
					discoverServiceOrCharacteristicTimer = new Timer(DISCOVER_SERVICES_OR_CHARACTERISTICS_RETRY_TIME_IN_SECONDS * 1000, 1);
					discoverServiceOrCharacteristicTimer.addEventListener(TimerEvent.TIMER, discoverServices);
					discoverServiceOrCharacteristicTimer.start();
				}
			} else {
				myTrace("in discoverServices, Maximum amount of attempts for discover bluetooth services reached.")
				amountOfDiscoverServicesOrCharacteristicsAttempt = 0;
				
				//i just happens that retrying doesn't help anymore
				//so disconnecting and rescanning seems the only solution ?
				
				//disconnect will cause central_peripheralDisconnectHandler to be called (although not sure because setting activeBluetoothPeripheral to null, i would expect that removes also the eventlisteners
				//central_peripheralDisconnectHandler will see that activeBluetoothPeripheral == null and so 
				var temp:Peripheral = activeBluetoothPeripheral;
				activeBluetoothPeripheral = null;
				BluetoothLE.service.centralManager.disconnect(temp);
				
				myTrace("in discoverServices, will_re_scan_for_device");
				if ((BluetoothLE.service.centralManager.state == BluetoothLEState.STATE_ON)) {
					bluetoothStatusIsOn();
				}
			}
		}
		
		private static function central_peripheralDisconnectHandler(event:PeripheralEvent = null):void {
			if (event != null) {
				if (event.peripheral.uuid != peripheralUUID && peripheralUUID != "") {
					myTrace("in central_peripheralDisconnectHandler, but event.peripheral.uuid != peripheralUUID && peripheralUUID != \"\" ignoring");
					return;
				}
			}

			myTrace('in central_peripheralDisconnectHandler');
			
			amountOfDiscoverServicesOrCharacteristicsAttempt = 0;
			
			if ((CGMBlueToothDevice.isDexcomG5() || CGMBlueToothDevice.isDexcomG6()) && awaitingAuthStatusRxMessage) {
				myTrace('in central_peripheralDisconnectHandler, Dexcom G5/G6 and awaitingAuthStatusRxMessage, seems another app is trying to connecto to the G5/G6');
				awaitingAuthStatusRxMessage = false;
				if (new Number(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_AMOUNT_OF_WARNINGS_OTHER_APP)) < MAX_WARNINGS_OTHER_APP_CONNECTING_TO_G5_G6) {
					if ((new Date()).valueOf() - timeStampOfLastInfoAboutOtherApp > 1 * 3600 * 1000) {//not repeating the warning every 5 minutes, only once per hour
						myTrace('in central_peripheralDisconnectHandler, giving warning to the user');
						timeStampOfLastInfoAboutOtherApp = (new Date()).valueOf();
						var otherAppTitle:String = "";
						var otherAppBody:String = "";
						
						if (CGMBlueToothDevice.isDexcomG5())
						{
							otherAppTitle = ModelLocator.resourceManagerInstance.getString("bluetoothservice","other_G5_app");
							otherAppBody = ModelLocator.resourceManagerInstance.getString("bluetoothservice","other_G5_app_info");
						}
						else if (CGMBlueToothDevice.isDexcomG6())
						{
							otherAppTitle = ModelLocator.resourceManagerInstance.getString("bluetoothservice","other_G5_app").replace("G5", "G6");
							otherAppBody = ModelLocator.resourceManagerInstance.getString("bluetoothservice","other_G5_app_info").replace("G5", "G6");
						}
						
						if (SpikeANE.appIsInForeground()) {
							AlertManager.showSimpleAlert
								(
									otherAppTitle,
									otherAppBody
								);
							SpikeANE.vibrate();
						} else {
							var notificationBuilderG5OtherAppRunningInfo:NotificationBuilder = new NotificationBuilder()
								.setCount(BadgeBuilder.getAppBadge())
								.setId(NotificationService.ID_FOR_OTHER_G5_APP)
								.setAlert(otherAppTitle)
								.setTitle(otherAppTitle)
								.setBody(otherAppBody)
								.enableVibration(true)
							Notifications.service.notify(notificationBuilderG5OtherAppRunningInfo.build());
						}
						LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_AMOUNT_OF_WARNINGS_OTHER_APP, (new Number(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_AMOUNT_OF_WARNINGS_OTHER_APP)) + 1).toString());
						myTrace("in central_peripheralDisconnectHandler, increased LocalSettings.LOCAL_SETTING_AMOUNT_OF_WARNINGS_OTHER_APP, new value = " + LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_AMOUNT_OF_WARNINGS_OTHER_APP));
					}
				} else {
					myTrace("in central_peripheralDisconnectHandler, maximum number of other app warnings reached, value = " + LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_AMOUNT_OF_WARNINGS_OTHER_APP));
				}
			}
			
			if (CGMBlueToothDevice.isBluKon()) {
				peripheralConnected = false;
				awaitingConnect = false;
				//try to reconnect and also restart scanning, to cover reconnect issue. Because maybe the transmitter starts re-advertising
				tryReconnect();
				startScanning();
			} else if (CGMBlueToothDevice.isBlueReader()) {
				peripheralConnected = false;
				awaitingConnect = false;
				tryReconnect();
			}  else if (CGMBlueToothDevice.isDexcomG4()) {
				peripheralConnected = false;
				awaitingConnect = false;
				tryReconnect();
			} else if (CGMBlueToothDevice.isDexcomG5() || CGMBlueToothDevice.isDexcomG6()) {
				peripheralConnected = false;
				awaitingConnect = false;
				tryReconnect();
			} else {
				peripheralConnected = false;
				awaitingConnect = false;
				forgetActiveBluetoothPeripheral();
				startRescan(null);
			}
		}
		
		private static function tryReconnect(event:flash.events.Event = null):void {
			if ((BluetoothLE.service.centralManager.state == BluetoothLEState.STATE_ON)) {
				bluetoothStatusIsOn();
			} else {
				//no need to further retry, a reconnect will be done as soon as bluetooth is switched on
			}
		}
		
		private static function peripheral_discoverServicesHandler(event:PeripheralEvent):void {
			if (event.peripheral.uuid != peripheralUUID) {
				myTrace("in peripheral_discoverServicesHandler, but event.peripheral.uuid != peripheralUUID, ignoring");
				return;
			}

			if (!waitingForServicesDiscovered && !(CGMBlueToothDevice.alwaysScan())) {
				myTrace("in peripheral_discoverServicesHandler but not waitingForServicesDiscovered and not alwaysscan device, ignoring");
				return;
			}
			myTrace("in peripheral_discoverServicesHandler");
			waitingForServicesDiscovered = false;
			
			if (discoverServiceOrCharacteristicTimer != null) {
				discoverServiceOrCharacteristicTimer.stop();
				discoverServiceOrCharacteristicTimer = null;
			}
			amountOfDiscoverServicesOrCharacteristicsAttempt = 0;
			
			if (CGMBlueToothDevice.isDexcomG5() || CGMBlueToothDevice.isDexcomG6()) {
				awaitingAuthStatusRxMessage = false;	
			}
			
			if (event.peripheral.services.length > 0) {
				myTrace("in peripheral_discoverServicesHandler, call discoverCharacteristics");
				discoverCharacteristics();
			} else {
				myTrace("in peripheral_discoverServicesHandler, event.peripheral.services.length == 0, not calling discoverCharacteristics");
			}
		}
		
		private static function discoverCharacteristics(event:flash.events.Event = null):void {
			if (activeBluetoothPeripheral == null)//rare case, user might have done forget xdrip while waiting to reattempt
				return;
			
			if (discoverServiceOrCharacteristicTimer != null) {
				discoverServiceOrCharacteristicTimer.stop();
				discoverServiceOrCharacteristicTimer = null;
			}
			
			if (!peripheralConnected) {
				myTrace("in discoverCharacteristics, but peripheralConnected = false, returning");
				amountOfDiscoverServicesOrCharacteristicsAttempt = 0;
				return;
			}
			
			if (amountOfDiscoverServicesOrCharacteristicsAttempt < MAX_RETRY_DISCOVER_SERVICES_OR_CHARACTERISTICS
				&&
				activeBluetoothPeripheral.services.length > 0) {
				amountOfDiscoverServicesOrCharacteristicsAttempt++;
				myTrace('in discoverCharacteristics, launching_discovercharacteristics_attempt_amount' + " " + amountOfDiscoverServicesOrCharacteristicsAttempt);
				
				var index:int;
				var o:Object;
				for each (o in activeBluetoothPeripheral.services) {
					if (service_UUID.indexOf((o.uuid as String).toUpperCase()) > -1) {
						break;
					}
					index++;
				}
				waitingForPeripheralCharacteristicsDiscovered = true;
				activeBluetoothPeripheral.discoverCharacteristics(activeBluetoothPeripheral.services[index], characteristics_UUID_Vector);
				discoverServiceOrCharacteristicTimer = new Timer(DISCOVER_SERVICES_OR_CHARACTERISTICS_RETRY_TIME_IN_SECONDS * 1000, 1);
				discoverServiceOrCharacteristicTimer.addEventListener(TimerEvent.TIMER, discoverCharacteristics);
				discoverServiceOrCharacteristicTimer.start();
			} else {
				myTrace('in discoverCharacteristics, call tryReconnect');
				tryReconnect();
			}
		}
		
		private static function peripheral_discoverCharacteristicsHandler(event:PeripheralEvent):void {
			if (event.peripheral.uuid != peripheralUUID) {
				myTrace("in peripheral_discoverCharacteristicsHandler, but event.peripheral.uuid != peripheralUUID, ignoring");
				return;
			}

			myTrace("in peripheral_discoverCharacteristicsHandler");
			if (!waitingForPeripheralCharacteristicsDiscovered && !CGMBlueToothDevice.isBluKon()) {
				myTrace("in peripheral_discoverCharacteristicsHandler but not waitingForPeripheralCharacteristicsDiscovered");
				return;
			}
			waitingForPeripheralCharacteristicsDiscovered = false;
			if (discoverServiceOrCharacteristicTimer != null) {
				discoverServiceOrCharacteristicTimer.stop();
				discoverServiceOrCharacteristicTimer = null;
			}
			myTrace("Bluetooth peripheral characteristics discovered");
			amountOfDiscoverServicesOrCharacteristicsAttempt = 0;
			
			//used to loop through services
			var servicesIndex:int = 0;
			
			//used to loop through characteristics
			var Read_CharacteristicsIndex:int = 0;
			var Write_CharacteristicsIndex:int = 0;
			
			//only needed for G5/G6
			awaitingAuthStatusRxMessage = false;
			
			var o:Object;
			
			for each (o in activeBluetoothPeripheral.services) {
				if (service_UUID.indexOf((o.uuid as String).toUpperCase()) > -1) {
					break;
				}
				servicesIndex++;
			}
			for each (o in activeBluetoothPeripheral.services[servicesIndex].characteristics) {
				if (RX_Characteristic_UUID.indexOf((o.uuid as String).toUpperCase()) > -1) {
					break;
				}
				Read_CharacteristicsIndex++;
			}
			for each (o in activeBluetoothPeripheral.services[servicesIndex].characteristics) {
				if (TX_Characteristic_UUID.indexOf((o.uuid as String).toUpperCase()) > -1) {
					break;
				}
				Write_CharacteristicsIndex++;
			}
			readCharacteristic = event.peripheral.services[servicesIndex].characteristics[Read_CharacteristicsIndex];
			writeCharacteristic = event.peripheral.services[servicesIndex].characteristics[Write_CharacteristicsIndex];
			myTrace("subscribing to ReadCharacteristic");
			
			if (!activeBluetoothPeripheral.subscribeToCharacteristic(readCharacteristic))
			{
				myTrace("Subscribe to characteristic failed due to invalid adapter state.");
			}
		}
		
		public static function writeToCharacteristic(value:ByteArray):void {
			if (!activeBluetoothPeripheral.writeValueForCharacteristic(writeCharacteristic, value)) {
				myTrace("ackG4CharacteristicUpdate writeValueForCharacteristic failed");
			}
		}
		
		private static function peripheral_characteristic_updatedHandler(event:CharacteristicEvent):void {
			if (event.peripheral.uuid != peripheralUUID) {
				myTrace("in peripheral_characteristic_updatedHandler, but event.peripheral.uuid != peripheralUUID, ignoring");
				return;
			}

			myTrace("in peripheral_characteristic_updatedHandler characteristic uuid = " + getCharacteristicName(event.characteristic.uuid) +
				" with byte 0 = " + event.characteristic.value[0] + " decimal.");
			
			var blueToothServiceEvent:BlueToothServiceEvent = new BlueToothServiceEvent(BlueToothServiceEvent.CHARACTERISTIC_UPDATE);
			_instance.dispatchEvent(blueToothServiceEvent);
			
			//now start reading the values
			var value:ByteArray = event.characteristic.value;
			var packetlength:int = value.readUnsignedByte();
			if (packetlength == 0) {
				myTrace("in peripheral_characteristic_updatedHandler, data packet received from transmitter with length 0, no further processing");
			} else {
				value.position = 0;
				value.endian = Endian.LITTLE_ENDIAN;
				myTrace("in peripheral_characteristic_updatedHandler, data packet received from transmitter : " + utils.UniqueId.bytesToHex(value));
				value.position = 0;
				if (CGMBlueToothDevice.isDexcomG5() || CGMBlueToothDevice.isDexcomG6()) {
					processG5G6TransmitterData(value, event.characteristic);
				} else if (CGMBlueToothDevice.isBluKon()) {
					processBLUKONTransmitterData(value);
				} else if (CGMBlueToothDevice.isDexcomG4() || CGMBlueToothDevice.isxBridgeR()) {
					processG4TransmitterData(value);
				} else if (CGMBlueToothDevice.isBlueReader()) {
					processBlueReaderTransmitterData(value);
				} else if (CGMBlueToothDevice.isTransmiter_PL()) {
					processTRANSMITER_PLTransmitterData(value);
				} else {
					myTrace("in peripheral_characteristic_updatedHandler, device type not known");
				}
			}
		}
		
		private static function peripheral_characteristic_writeHandler(event:CharacteristicEvent):void {
			if (event.peripheral.uuid != peripheralUUID) {
				myTrace("in peripheral_characteristic_writeHandler, but event.peripheral.uuid != peripheralUUID, ignoring");
				return;
			}

			myTrace("in peripheral_characteristic_writeHandler " + getCharacteristicName(event.characteristic.uuid));
			if (CGMBlueToothDevice.isDexcomG4() || CGMBlueToothDevice.isxBridgeR()) {
				_instance.dispatchEvent(new BlueToothServiceEvent(BlueToothServiceEvent.BLUETOOTH_DEVICE_CONNECTION_COMPLETED));
			} else if ((CGMBlueToothDevice.isDexcomG5() || CGMBlueToothDevice.isDexcomG6()) && event.characteristic.uuid.toUpperCase() == G5_G6_Authentication_Characteristic_UUID.toUpperCase()) {
				awaitingAuthStatusRxMessage = true;
			}
		}
		
		private static function peripheral_characteristic_writeErrorHandler(event:CharacteristicEvent):void {
			myTrace("in peripheral_characteristic_writeErrorHandler"  + getCharacteristicName(event.characteristic.uuid));
			if (event.error != null)
				myTrace("event.error = " + event.error);
			myTrace("event.errorCode = " + event.errorCode); 
		}
		
		private static function peripheral_characteristic_errorHandler(event:CharacteristicEvent):void {
			myTrace("in peripheral_characteristic_errorHandler"  + getCharacteristicName(event.characteristic.uuid));
		}
		
		private static function peripheral_characteristic_subscribeHandler(event:CharacteristicEvent):void {
			if (event.peripheral.uuid != peripheralUUID) {
				myTrace("in peripheral_characteristic_subscribeHandler, but event.peripheral.uuid != peripheralUUID, ignoring");
				return;
			}

			myTrace("in peripheral_characteristic_subscribeHandler success: " + getCharacteristicName(event.characteristic.uuid));
			if (CGMBlueToothDevice.isDexcomG5() || CGMBlueToothDevice.isDexcomG6()) {
				if (event.characteristic.uuid.toUpperCase() == G5_G6_Control_Characteristic_UUID.toUpperCase()) {
					if (G5_G6_RESET_REQUESTED) {
						doG5G6Reset();
						G5_G6_RESET_REQUESTED = false;
					} else {
						getSensorData();
					}
				} else {
					fullAuthenticateG5G6();
				}
			}
			if (!CGMBlueToothDevice.alwaysScan()) {
				_instance.dispatchEvent(new BlueToothServiceEvent(BlueToothServiceEvent.BLUETOOTH_DEVICE_CONNECTION_COMPLETED));
			}
		}
		
		private static function peripheral_characteristic_subscribeErrorHandler(event:CharacteristicEvent):void {
			if (event.peripheral.uuid != peripheralUUID) {
				myTrace("in peripheral_characteristic_subscribeErrorHandler, but event.peripheral.uuid != peripheralUUID, ignoring");
				return;
			}

			myTrace("in peripheral_characteristic_subscribeErrorHandler: " + getCharacteristicName(event.characteristic.uuid));
			myTrace("in peripheral_characteristic_subscribeErrorHandler, event.error = " + event.error);
			myTrace("in peripheral_characteristic_subscribeErrorHandler, event.errorcode  = " + event.errorCode);
			if ((new Date()).valueOf() - timeStampOfLastDeviceNotPairedForBlukon > 4.75 * 60 * 1000) {
				if (CGMBlueToothDevice.isBluKon()) {
					if (event.characteristic.uuid.toUpperCase() == Blucon_RX_Characteristic_UUID.toUpperCase()
						&&
						event.errorCode == 15 
					) {
						myTrace("in peripheral_characteristic_subscribeErrorHandler, blukon not paired, dispatching DEVICE_NOT_PAIRED event");
						var blueToothServiceEvent:BlueToothServiceEvent = new BlueToothServiceEvent(BlueToothServiceEvent.DEVICE_NOT_PAIRED);
						_instance.dispatchEvent(blueToothServiceEvent);
						timeStampOfLastDeviceNotPairedForBlukon = (new Date()).valueOf();
					}
				}
			}
		}
		
		private static function peripheral_characteristic_unsubscribeHandler(event:CharacteristicEvent):void {
			myTrace("peripheral_characteristic_unsubscribeHandler: " + event.characteristic.uuid);	
		}
		
		/**
		 * Disconnects the active bluetooth peripheral if any and sets it to null (otherwise returns without doing anything)<br>
		 * address only for miaomiao because the cancelMiaoMiaoConnection method needs that mac, otherwise it will not forget the device
		 */
		public static function forgetActiveBluetoothPeripheral(address:String = ""):void {
			if (CGMBlueToothDevice.isMiaoMiao()) {
				myTrace("in forgetActiveBluetoothPeripheral miaomiao device");
				SpikeANE.cancelMiaoMiaoConnection(address);
				SpikeANE.resetMiaoMiaoMac();
				SpikeANE.forgetMiaoMiaoPeripheral();
			} if (CGMBlueToothDevice.isDexcomG5() || CGMBlueToothDevice.isDexcomG6()) {
				myTrace("in forgetActiveBluetoothPeripheral G5/G6 device");
				SpikeANE.cancelG5Connection(address);
				SpikeANE.resetG5Mac();
				SpikeANE.forgetG5Peripheral();
			} else {
				myTrace("in forgetActiveBluetoothPeripheral");
				writeCharacteristic = null;
				readCharacteristic = null;
				if (activeBluetoothPeripheral == null)
					return;
				
				BluetoothLE.service.centralManager.disconnect(activeBluetoothPeripheral);
				activeBluetoothPeripheral = null;
				myTrace("bluetooth device forgotten");
				peripheralUUID = "";
			}
		}
		
		/**
		 * encode transmitter id as explained in xBridge2.pdf 
		 */
		public static function encodeTxID(TxID:String):Number {
			var returnValue:Number = 0;
			var tmpSrc:String = TxID.toUpperCase();
			returnValue |= getSrcValue(tmpSrc.charAt(0)) << 20;
			returnValue |= getSrcValue(tmpSrc.charAt(1)) << 15;
			returnValue |= getSrcValue(tmpSrc.charAt(2)) << 10;
			returnValue |= getSrcValue(tmpSrc.charAt(3)) << 5;
			returnValue |= getSrcValue(tmpSrc.charAt(4));
			return returnValue;
		}
		
		private static function decodeTxID(TxID:Number):String {
			var returnValue:String = "";
			returnValue += srcNameTable[(TxID >> 20) & 0x1F];
			returnValue += srcNameTable[(TxID >> 15) & 0x1F];
			returnValue += srcNameTable[(TxID >> 10) & 0x1F];
			returnValue += srcNameTable[(TxID >> 5) & 0x1F];
			returnValue += srcNameTable[(TxID >> 0) & 0x1F];
			return returnValue;
		}
		
		private static function getSrcValue(ch:String):int {
			var i:int = 0;
			for (i = 0; i < srcNameTable.length; i++) {
				if (srcNameTable[i] == ch) break;
			}
			return i;
		}
		
		private static function processG5G6TransmitterData(buffer:ByteArray, characteristic:Characteristic):void {
			myTrace("in processG5G6TransmitterData");
			awaitingAuthStatusRxMessage = false;
			buffer.endian = Endian.LITTLE_ENDIAN;
			var code:int = buffer.readByte();
			switch (code) {
				case 5:
					var blueToothServiceEvent:BlueToothServiceEvent;
					authStatus = new AuthStatusRxMessage(buffer);
					myTrace("in processG5TransmitterData, AuthStatusRxMessage created = " + UniqueId.byteArrayToString(authStatus.byteSequence));
					if (!authStatus.bonded) {
						myTrace("in processG5G6TransmitterData, not paired, dispatching DEVICE_NOT_PAIRED event");
						blueToothServiceEvent = new BlueToothServiceEvent(BlueToothServiceEvent.DEVICE_NOT_PAIRED);
						_instance.dispatchEvent(blueToothServiceEvent);
					}
					
					myTrace("in processG5TransmitterData, Subscribing to WriteCharacteristic");
					if (!activeBluetoothPeripheral.subscribeToCharacteristic(writeCharacteristic))
					{
						myTrace("in processG5TransmitterData, Subscribe to characteristic failed due to invalid adapter state.");
					}
					break;
				case 3:
					buffer.position = 0;
					//myTrace("buffer = " + utils.UniqueId.bytesToHex(buffer));
					buffer.position = 0;
					var authChallenge:AuthChallengeRxMessage = new AuthChallengeRxMessage(buffer);
					if (authRequest == null) {
						authRequest = new AuthRequestTxMessage(getTokenSize());
					}
					var challengeHash:ByteArray = calculateHash(authChallenge.challenge);
					if (challengeHash != null) {
						var authChallengeTx:AuthChallengeTxMessage = new AuthChallengeTxMessage(challengeHash);
						if (!activeBluetoothPeripheral.writeValueForCharacteristic(characteristic, authChallengeTx.byteSequence)) {
							myTrace("in processG5G6TransmitterData case 3 writeValueForCharacteristic failed");
						}
					} else {
						myTrace("in processG5G6TransmitterData, challengehash == null");
					}
					break;
				case 47://0x2f
					var sensorRx:SensorRxMessage = new SensorRxMessage(buffer);
					
					if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_G5_G6_VERSION_INFO) == "") {
						myTrace("in processG5G6TransmitterData, firmare version unknown, will request it");
						doG5G6FirmwareVersionRequestMessage(characteristic);
					} else {
						if ((new Date()).valueOf() - new Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_G5_G6_BATTERY_FROM_MARKER)) > CGMBluetoothService.G5_G6_BATTERY_READ_PERIOD_MS) {
							doBatteryInfoRequestMessage(characteristic);
						} else {
							doDisconnectMessageG5G6(characteristic);
						}
					}
					
					//if G5G6Reset was done less than 5 minutes ago, then ignore the reading
					if ((new Date()).valueOf() - timeStampOfLastG5G6Reading < 5 * 60 * 1000) {
						myTrace("in processG5TransmitterData, resettimestamp was less than 5 minutes ago, ignoring this reading");
					}else {
						//SPIKE: Save Sensor RX Timestmp for transmitter runtime display
						if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_G5_G6_SENSOR_RX_TIMESTAMP) != String(sensorRx.timestamp))
							CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_G5_G6_SENSOR_RX_TIMESTAMP, String(sensorRx.timestamp));
						
						timeStampOfLastG5G6Reading = (new Date()).valueOf();
						blueToothServiceEvent = new BlueToothServiceEvent(BlueToothServiceEvent.TRANSMITTER_DATA);
						blueToothServiceEvent.data = new TransmitterDataG5G6Packet(sensorRx.unfiltered, sensorRx.filtered, sensorRx.timestamp, sensorRx.transmitterStatus);
						_instance.dispatchEvent(blueToothServiceEvent);
					}
					break;
				case 35:
					buffer.position = 0;
					if (!setStoredBatteryBytesG5G6(buffer)) {
						myTrace("in processG5G6TransmitterData , Could not save out battery data!");
					}
					doDisconnectMessageG5G6(characteristic);
					break;
				case 67:
					//G5/G6 reset acknowledge
					if ((new Date()).valueOf() - G5G6ResetTimeStamp > 2 * 1000) {
						myTrace(" in processG5TransmitterData, received G5/G6 Reset message, but more than 2 seconds ago since reset was sent, ignoring");
					} else {
						if (buffer.length !== 4) {
							myTrace(" in processG5G6TransmitterData, received G5/G6 Reset message, but length != 4, ignoring");
						} else {
							var resetDoneBody:String = "";
							
							if (CGMBlueToothDevice.isDexcomG5())
								resetDoneBody = ModelLocator.resourceManagerInstance.getString("bluetoothservice","g5_reset_done");
							else if (CGMBlueToothDevice.isDexcomG6())
								resetDoneBody = ModelLocator.resourceManagerInstance.getString("bluetoothservice","g5_reset_done").replace("G5", "G6");
							
							if (SpikeANE.appIsInForeground()) 
							{
								AlertManager.showSimpleAlert
									(
										ModelLocator.resourceManagerInstance.getString("globaltranslations","info_alert_title"),
										resetDoneBody
									);
								SpikeANE.vibrate();
							} else {
								var notificationBuilder:NotificationBuilder = new NotificationBuilder()
									.setId(NotificationService.ID_FOR_G5_RESET_DONE)
									.setAlert(ModelLocator.resourceManagerInstance.getString("globaltranslations","info_alert_title"))
									.setTitle(ModelLocator.resourceManagerInstance.getString("globaltranslations","info_alert_title"))
									.setBody(resetDoneBody)
									.enableVibration(true)
								Notifications.service.notify(notificationBuilder.build());
							}
						}
					}
					break;
				case 75://0x4B
					//Version request response message received
					//store the complete buffer as string in the settings
					myTrace("in processG5G6TransmitterData, received version info, storing info and disconnecting");
					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_G5_G6_VERSION_INFO, UniqueId.bytesToHex(buffer));
					doDisconnectMessageG5G6(characteristic);
					break;
				default:
					myTrace("in processG5G6TransmitterData unknown code received : " + code);
					break;
			}
		}
		
		public static function setStoredBatteryBytesG5G6(data:ByteArray):Boolean {
			if (data.length < 10) {
				myTrace("in setStoredBatteryBytesG5G6, Store: BatteryRX dbg, data.length < 10, no further processing");
				return false;
			}
			var batteryInfoRxMessage:BatteryInfoRxMessage = new BatteryInfoRxMessage(data);
			myTrace("in setStoredBatteryBytesG5G6, Saving battery data: " + batteryInfoRxMessage.toString());
			CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_G5_G6_BATTERY_MARKER, UniqueId.bytesToHex(data));
			CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_G5_G6_RESIST, new Number(batteryInfoRxMessage.resist).toString());
			CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_G5_G6_RUNTIME, new Number(batteryInfoRxMessage.runtime).toString());
			CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_G5_G6_TEMPERATURE, new Number(batteryInfoRxMessage.temperature).toString());
			CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_G5_G6_VOLTAGEA, new Number(batteryInfoRxMessage.voltagea).toString());
			CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_G5_G6_VOLTAGEB, new Number(batteryInfoRxMessage.voltageb).toString());
			
			//Save timestamp to database so we don't constantly request new battery info.
			CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_G5_G6_BATTERY_FROM_MARKER, new Date().valueOf().toString());
			
			return true;
		}
		
		private static function doDisconnectMessageG5G6(characteristic:Characteristic):void {
			myTrace("in doDisconnectMessageG5G6");
			if (activeBluetoothPeripheral != null) {
				if (!BluetoothLE.service.centralManager.disconnect(activeBluetoothPeripheral)) {
					myTrace("in doDisconnectMessageG5G6, failed");
				}
			}
			myTrace("in doDisconnectMessageG5G6, finished");
		}
		
		private static function doBatteryInfoRequestMessage(characteristic:Characteristic):void {
			myTrace("in doBatteryInfoRequestMessage");
			var batteryInfoTxMessage:BatteryInfoTxMessage =  new BatteryInfoTxMessage();
			if (!activeBluetoothPeripheral.writeValueForCharacteristic(characteristic, batteryInfoTxMessage.byteSequence)) {
				myTrace("in doBatteryInfoRequestMessage writeValueForCharacteristic failed");
			}
		}
		
		private static function doG5G6FirmwareVersionRequestMessage(characteristic:Characteristic):void {
			myTrace("in doG5G6FirmwareVersionRequestMessage");
			var firmWareVersionTxMessage:VersionRequestTxMessage =  new VersionRequestTxMessage();
			if (!activeBluetoothPeripheral.writeValueForCharacteristic(characteristic, firmWareVersionTxMessage.byteSequence)) {
				myTrace("in doG5G6FirmwareVersionRequestMessage writeValueForCharacteristic failed");
			}
		}
		
		public static function calculateHash(data:ByteArray):ByteArray {
			if (data.length != 8) {
				myTrace("in calculateHash, Data length should be exactly 8.");
				return null;
			}
			var key:ByteArray = cryptKey();
			if (key == null)
				return null;
			var doubleData:ByteArray = new ByteArray();
			doubleData.writeBytes(data);
			doubleData.writeBytes(data);
			var aesBytes:ByteArray = SpikeANE.AESEncryptWithKey(key, doubleData);
			var returnValue:ByteArray = new ByteArray();
			returnValue.writeBytes(aesBytes, 0, 8);
			return returnValue;
		}
		
		public static function cryptKey():ByteArray {
			var transmitterId:String = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TRANSMITTER_ID);
			var returnValue:ByteArray =  new ByteArray();
			returnValue.writeMultiByte("00" + transmitterId + "00" + transmitterId,"iso-8859-1");
			return returnValue;
		}
		
		private static function processBLUKONTransmitterData(buffer:ByteArray):void {
			myTrace("in processBLUKONTransmitterData with blukonCurrentcomand = " + blukonCurrentCommand);
			if (buffer == null) {
				myTrace("in processBLUKONTransmitterData, null buffer passed to decodeBlukonPacket");
				return;
			}
			buffer.position = 0;
			buffer.endian = Endian.LITTLE_ENDIAN;
			var strRecCmd:String = utils.UniqueId.bytesToHex(buffer).toLowerCase();
			buffer.position = 0;
			var blueToothServiceEvent:BlueToothServiceEvent  = null;
			var gotLowBat:Boolean = false;
			
			var cmdFound:int = 0;
			
			if (strRecCmd == "cb010000") {
				myTrace("in processBLUKONTransmitterData, Reset currentCommand");
				blukonCurrentCommand = "";
				cmdFound = 1;
			}
			
			// BlukonACKRespons will come in two different situations
			// 1) after we have sent an ackwakeup command
			// 2) after we have a sleep command
			if (strRecCmd.indexOf("8b0a00") == 0) {
				cmdFound = 1;
				myTrace("in processBLUKONTransmitterData, Got ACK");
				
				if (blukonCurrentCommand.indexOf("810a00") == 0) {//ACK sent
					//ack received
					blukonCurrentCommand = "010d0b00";
					myTrace("in processBLUKONTransmitterData, getUnknownCmd1: " + blukonCurrentCommand);
					
				} else {
					myTrace("in processBLUKONTransmitterData, Got sleep ack, resetting initialstate!");
					blukonCurrentCommand = "";
				}
			}
			
			if (strRecCmd.indexOf("8b1a02") == 0) {
				cmdFound = 1;
				myTrace("in processBLUKONTransmitterData, Got NACK on cmd=" + blukonCurrentCommand + " with error=" + strRecCmd.substring(6));
				
				if (strRecCmd.indexOf("8b1a020014") == 0) {
					myTrace("in processBLUKONTransmitterData, Timeout: please wait 5min or push button to restart!");
				}
				
				if (strRecCmd.indexOf("8b1a02000f") == 0) {
					myTrace("in processBLUKONTransmitterData, Libre sensor has been removed!");
				}
				
				if (strRecCmd.indexOf("8b1a020011") == 0) {
					myTrace("in processBLUKONTransmitterData, Patch read error.. please check the connectivity and re-initiate... or maybe battery is low?, dispatching GLUCOSE_PATCH_READ_ERROR event");
					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_BLUKON_BATTERY_LEVEL, "1");
					gotLowBat = true;
					blueToothServiceEvent = new BlueToothServiceEvent(BlueToothServiceEvent.GLUCOSE_PATCH_READ_ERROR);
					_instance.dispatchEvent(blueToothServiceEvent);
				}

				m_getNowGlucoseDataCommand = false;
				m_getNowGlucoseDataIndexCommand = false;
				blukonCurrentCommand = "";
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_TIME_STAMP_LAST_SENSOR_AGE_CHECK_IN_MS, "0");// set to 0  to force timer to be set back
			}
			
			if (blukonCurrentCommand == "" && strRecCmd == "cb010000") {
				cmdFound = 1;
				myTrace("in processBLUKONTransmitterData, wakeup received");
				
				blukonCurrentCommand = "010d0900";
				myTrace("in processBLUKONTransmitterData, getPatchInfo");
				
			} else if (blukonCurrentCommand.indexOf("010d0900") == 0 /*getPatchInfo*/ && strRecCmd.indexOf("8bd9") == 0) {
				cmdFound = 1;
				myTrace("in processBLUKONTransmitterData, Patch Info received");
				
				buffer.position = 17;
				if (isSensorReady(buffer.readByte())) {
					blukonCurrentCommand = "810a00";
					myTrace("in processBLUKONTransmitterData, Send ACK");
				} else {
					blukonCurrentCommand = "";
					myTrace("in processBLUKONTransmitterData, Sensor is not ready, stop!");
				}
			} else if (blukonCurrentCommand.indexOf("010d0b00") == 0 /*getUnknownCmd1*/ && strRecCmd.indexOf("8bdb") == 0) {
				cmdFound = 1;
				myTrace("in processBLUKONTransmitterData, gotUnknownCmd1 (010d0b00): "+strRecCmd);
				
				if (!strRecCmd.indexOf("8bdb0101041711") == 0) {
					myTrace("in processBLUKONTransmitterData, gotUnknownCmd1 (010d0b00): "+strRecCmd);
				}
				
				blukonCurrentCommand = "010d0a00";
				myTrace("in processBLUKONTransmitterData, getUnknownCmd2 "+ blukonCurrentCommand);
				
			} else if (blukonCurrentCommand.indexOf("010d0a00") == 0 /*getUnknownCmd2*/ && strRecCmd.indexOf("8bda") == 0) {
				cmdFound = 1;
				myTrace("in processBLUKONTransmitterData, gotUnknownCmd2 (010d0a00): "+strRecCmd);
				
				if (strRecCmd != "8bdaaa") {
					myTrace("in processBLUKONTransmitterData, gotUnknownCmd2 (010d0a00): "+strRecCmd);
				}
				if (strRecCmd == "8bda02") {
					myTrace("in processBLUKONTransmitterData, gotUnknownCmd2: is maybe battery low????");
					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_BLUKON_BATTERY_LEVEL, "5");
					gotLowBat = true;
				}
				
				if ((new Date()).valueOf() - new Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TIME_STAMP_LAST_SENSOR_AGE_CHECK_IN_MS)) > GET_SENSOR_AGE_DELAY_IN_SECONDS * 1000) {
					blukonCurrentCommand = "010d0e0127";
					myTrace("in processBLUKONTransmitterData, getSensorAge");
				} else {
					if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BLUKON_EXTERNAL_ALGORITHM) == "true") {
						myTrace("in processBLUKONTransmitterData, getHistoricData (2)");
						blukonCurrentCommand = "010d0f02002b";
						m_blockNumber = 0;
					} else {
						blukonCurrentCommand = "010d0e0103";
						m_getNowGlucoseDataIndexCommand = true;//to avoid issue when gotNowDataIndex cmd could be same as getNowGlucoseData (case block=3)
						myTrace("in processBLUKONTransmitterData, getNowGlucoseDataIndexCommand");
					}
				}
			} else if (blukonCurrentCommand.indexOf("010d0e0127") == 0 /*getSensorAge*/ && strRecCmd.indexOf("8bde") == 0) {
				cmdFound = 1;
				myTrace("in processBLUKONTransmitterData, SensorAge received");
				
				buffer.position = 0;
				FSLSensorAGe = sensorAge(buffer);
				
				if ((FSLSensorAGe > 0) && (FSLSensorAGe < 200000)) {
					if (FSLSensorAGe < new Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FSL_SENSOR_AGE))) {
						myTrace("in processBLUKONTransmitterData, new sensor detected");
						var event:BlueToothServiceEvent = new BlueToothServiceEvent(BlueToothServiceEvent.SENSOR_CHANGED_DETECTED);
						_instance.dispatchEvent(event);
					}
				} else {
					myTrace("in processBLUKONTransmitterData, setting sensor age to Number.NAN");
					FSLSensorAGe = Number.NaN;
				}
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_TIME_STAMP_LAST_SENSOR_AGE_CHECK_IN_MS, (new Date()).valueOf().toString());
				if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BLUKON_EXTERNAL_ALGORITHM) == "true") {
					myTrace("in processBLUKONTransmitterData, getHistoricData (3)");
					blukonCurrentCommand = "010d0f02002b";
					m_blockNumber = 0;
				} else {
					blukonCurrentCommand = "010d0e0103";
					m_getNowGlucoseDataIndexCommand = true;//to avoid issue when gotNowDataIndex cmd could be same as getNowGlucoseData (case block=3)
					myTrace("in processBLUKONTransmitterData, getNowGlucoseDataIndexCommand");
				}
			} else if (blukonCurrentCommand.indexOf("010d0e0103") == 0 /*getNowDataIndex*/ && m_getNowGlucoseDataIndexCommand && strRecCmd.indexOf("8bde") == 0) {
				cmdFound = 1;
				myTrace("in processBLUKONTransmitterData, gotNowDataIndex");
				
				var delayedTrendIndex:int;
				var i:int;
				var delayedBlockNumber:String;
				// calculate time delta to last valid BG reading
				var bgReadings:Array = BgReading.latest(1);
				if (bgReadings.length > 0) {
					var bgReading:BgReading = (BgReading.latest(1))[0]  as BgReading;
					m_persistentTimeLastBg = bgReading.timestamp;
				} else {
					m_persistentTimeLastBg = 0;
				}
				m_minutesDiffToLastReading = ((((new Date()).valueOf() - m_persistentTimeLastBg)/1000)+30)/60;
				myTrace("in processBLUKONTransmitterData, m_minutesDiffToLastReading=" + m_minutesDiffToLastReading + ", last reading: " + (new Date(m_persistentTimeLastBg)).toString());
				
				// check time range for valid backfilling
				if ( (m_minutesDiffToLastReading > 7) && (m_minutesDiffToLastReading < (8*60))  ) {
					myTrace("in processBLUKONTransmitterData, start backfilling");
					m_getOlderReading = true;
				} else {
					m_getOlderReading = false;
				}
				// get index to current BG reading
				m_currentBlockNumber = blockNumberForNowGlucoseData(buffer);
				m_currentOffset = nowGlucoseOffset;
				// time diff must be > 5,5 min and less than the complete trend buffer
				if ( !m_getOlderReading ) {
					blukonCurrentCommand = "010d0e010" + m_currentBlockNumber;//getNowGlucoseData
					nowGlucoseOffset = m_currentOffset;
					myTrace("in processBLUKONTransmitterData, getNowGlucoseData");
				}
				else {
					m_minutesBack = m_minutesDiffToLastReading;
					delayedTrendIndex = m_currentTrendIndex;
					// ensure to have min 3 mins distance to last reading to avoid doible draws (even if they are distict)
					if ( m_minutesBack > 17 ) {
						m_minutesBack = 15;
					} else if ( m_minutesBack > 12 ) {
						m_minutesBack = 10;
					} else if ( m_minutesBack > 7 ) {
						m_minutesBack = 5;
					}
					myTrace("in processBLUKONTransmitterData, read " + m_minutesBack + " mins old trend data");
					for ( i = 0 ; i < m_minutesBack ; i++ ) {
						if ( --delayedTrendIndex < 0)
							delayedTrendIndex = 15;
					}
					delayedBlockNumber = blockNumberForNowGlucoseDataDelayed(delayedTrendIndex);
					blukonCurrentCommand = "010d0e010" + delayedBlockNumber;//getNowGlucoseData
					myTrace("in processBLUKONTransmitterData, getNowGlucoseData backfilling");
				}
				m_getNowGlucoseDataIndexCommand = false;
				m_getNowGlucoseDataCommand = true;
			} else if (blukonCurrentCommand.indexOf("010d0e01") == 0 /*getNowGlucoseData*/ && m_getNowGlucoseDataCommand && strRecCmd.indexOf("8bde") == 0) {
				cmdFound = 1;
				var currentGlucose:Number = nowGetGlucoseValue(buffer);
				myTrace("in processBLUKONTransmitterData, *****************got getNowGlucoseData = " + currentGlucose);
				
				if (!m_getOlderReading) {
					blueToothServiceEvent = new BlueToothServiceEvent(BlueToothServiceEvent.TRANSMITTER_DATA);
					blueToothServiceEvent.data = new TransmitterDataBluKonPacket(currentGlucose, 0, 0, FSLSensorAGe, (new Date()).valueOf());
					FSLSensorAGe = Number.NaN;
					
					blukonCurrentCommand = "010c0e00";
					myTrace("in processBLUKONTransmitterData, Send sleep cmd");
					m_getNowGlucoseDataCommand = false;
				} else {
					myTrace("in processBLUKONTransmitterData, bf: processNewTransmitterData with delayed timestamp of " + m_minutesBack + " min");
					blueToothServiceEvent = new BlueToothServiceEvent(BlueToothServiceEvent.TRANSMITTER_DATA);
					blueToothServiceEvent.data = new TransmitterDataBluKonPacket(currentGlucose, 0, 0, 0 /*battery level force to 0 as unknown*/, (new Date()).valueOf() - (m_minutesBack*60*1000));
					m_minutesBack -= 5;
					if ( m_minutesBack < 5 ) {
						m_getOlderReading = false;
					}
					myTrace("in processBLUKONTransmitterData,bf: calculate next trend buffer with " + m_minutesBack + " min timestamp");
					delayedTrendIndex = m_currentTrendIndex;
					for ( i = 0 ; i < m_minutesBack ; i++ ) {
						if ( --delayedTrendIndex < 0)
							delayedTrendIndex = 15;
					}
					delayedBlockNumber = blockNumberForNowGlucoseDataDelayed(delayedTrendIndex);
					blukonCurrentCommand = "010d0e010" + delayedBlockNumber;//getNowGlucoseData
					myTrace("in processBLUKONTransmitterData, bf: read next block: " + blukonCurrentCommand);
				}
			} else if ((blukonCurrentCommand.indexOf("010d0f02002b") == 0 || (blukonCurrentCommand == "" && m_blockNumber > 0)) && strRecCmd.indexOf("8bdf") == 0) {
				cmdFound = 1;
				buffer.position = 0;
				handlegetHistoricDataResponse(buffer);
			} else if (strRecCmd.indexOf("cb020000") == 0) {
				cmdFound = 1;
				myTrace("in processBLUKONTransmitterData, is bridge battery low????!");
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_BLUKON_BATTERY_LEVEL, "3");
				gotLowBat = true;
			} else if (strRecCmd.indexOf("cbdb0000") == 0) {
				cmdFound = 1;
				myTrace("in processBLUKONTransmitterData, is bridge battery really low????!");
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_BLUKON_BATTERY_LEVEL, "2");
				gotLowBat = true;
			} 
			
			if (!gotLowBat) {
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_BLUKON_BATTERY_LEVEL, "100");
			}	
			
			
			if (blukonCurrentCommand.length > 0 && cmdFound == 1) {
				myTrace("in processBLUKONTransmitterData, Sending reply: " + blukonCurrentCommand);
				sendCommand(blukonCurrentCommand);
			} else {
				if (cmdFound == 0) {
					myTrace("in processBLUKONTransmitterData, ************COMMAND NOT FOUND! -> " + strRecCmd + " on currentCmd=" + blukonCurrentCommand);
					blukonCurrentCommand = "";
				}
			}
			
			if (blueToothServiceEvent != null) {
				myTrace("in processBlukonTransmitterData, dispatching transmitter data");
				_instance.dispatchEvent(blueToothServiceEvent);
			}
		}
		
		private static function handlegetHistoricDataResponse(buffer:ByteArray):void {
			myTrace("in handlegetHistoricDataResponse, recieved historic data, m_block_number = " + m_blockNumber);
			// We are looking for 43 blocks of 8 bytes.
			// The bluekon will send them as 21 blocks of 16 bytes, and the last one of 8 bytes. 
			// The packet will look like "0x8b 0xdf 0xblocknumber 0x02 DATA" (so data starts at place 4)
			if(m_blockNumber > 42) {
				myTrace("in handlegetHistoricDataResponse, recieved historic data, but block number is too big " + m_blockNumber);
				return;
			}
			
			var len:int = buffer.length - 4;
			buffer.position = 2;
			var buffer_at_2:int = buffer.readByte();
			myTrace("in handlegetHistoricDataResponse, len = " + len +" " + len + " blocknum " + buffer_at_2);
			
			if(buffer_at_2 != m_blockNumber) {
				myTrace("in handlegetHistoricDataResponse, We have recieved a bad block number buffer[2] = " + buffer_at_2 + " m_blockNumber = " + m_blockNumber);
				return;
			}
			if(8 * m_blockNumber + len > m_full_data.length) {
				myTrace("in handlegetHistoricDataResponse, We have recieved too much data  m_blockNumber = " + m_blockNumber + " len = " + len + 
					" m_full_data.length = " + m_full_data.length);        	
				return;
			}
			
			buffer.position = 4;
			buffer.readBytes(m_full_data, 8 * m_blockNumber, len);
			m_blockNumber += len / 8;
			
			if(m_blockNumber >= 43) {
				blukonCurrentCommand = "010c0e00";
				myTrace("in handlegetHistoricDataResponse, Send sleep cmd");
				myTrace("in handlegetHistoricDataResponse, Full data that was recieved is " + utils.UniqueId.bytesToHex(m_full_data));
			} else {
				blukonCurrentCommand = "";
			}
		}
		
		private static function sensorAge(input:ByteArray):int {
			input.position = 3 + 4;
			var value3plus4:int = input.readByte();
			input.position = 3 + 5;
			var value3plus5:int = input.readByte();

			var returnValue:int = ((value3plus5 & 0xFF) << 8) | (value3plus4 & 0xFF);
			myTrace("in sensorAge, sensorAge = " + returnValue);
			
			return returnValue;
		}
		
		private static function blockNumberForNowGlucoseData(input:ByteArray):String {
			input.position = 5;
			var nowGlucoseIndex2:int = 0;
			var nowGlucoseIndex3:int = 0;
			
			nowGlucoseIndex2 = input.readByte();
			
			// caculate byte position in sensor body
			nowGlucoseIndex2 = (nowGlucoseIndex2 * 6) + 4;
			
			// decrement index to get the index where the last valid BG reading is stored
			nowGlucoseIndex2 -= 6;
			// adjust round robin
			if ( nowGlucoseIndex2 < 4 )
				nowGlucoseIndex2 = nowGlucoseIndex2 + 96;
			
			// calculate the absolute block number which correspond to trend index
			nowGlucoseIndex3 = 3 + (nowGlucoseIndex2/8);
			
			// calculate offset of the 2 bytes in the block
			nowGlucoseOffset = nowGlucoseIndex2 % 8;
			
			var nowGlucoseDataAsHexString:String = nowGlucoseIndex3.toString(16);
			return nowGlucoseDataAsHexString;
		}
		
		private static function blockNumberForNowGlucoseDataDelayed(delayedIndex:int):String
		{
			var i:int;
			var ngi2:int;
			var ngi3:int;
			
			// calculate byte offset in libre FRAM
			ngi2 = (delayedIndex * 6) + 4;
			
			ngi2 -= 6;
			if (ngi2 < 4)
				ngi2 = ngi2 + 96;
			
			// calculate the block number where to get the BG reading
			ngi3 = 3 + (ngi2/8);
			
			// calculate the offset in the block
			nowGlucoseOffset = ngi2 % 8;
			myTrace("in blockNumberForNowGlucoseDataDelayed, ++++++++backfillingTrendData: index " + delayedIndex + ", block " + ngi3.toString(16) + ", offset " + nowGlucoseOffset);
			
			return(ngi3.toString(16));
		}
		
		public static function nowGetGlucoseValue(input:ByteArray):Number {
			input.position = 3 + nowGlucoseOffset;
			var curGluc:Number;
			var rawGlucose:Number;
			
			// grep 2 bytes with BG data from input bytearray, mask out 12 LSB bits and rescale for xDrip+
			//xdripplus code : rawGlucose = ((input[3 + m_nowGlucoseOffset + 1] & 0x1F)) << 8) | (input[3 + m_nowGlucoseOffset] & 0xFF);
			var value1:int = input.readByte();
			var value2:int = input.readByte();
			rawGlucose = ((value2 & 0x1F)<<8) | (value1 & 0xFF);
			myTrace("in nowGetGlucoseValue rawGlucose=" + rawGlucose);
			
			// rescale
			curGluc = LibreAlarmReceiver.getGlucose(rawGlucose);
			
			return(curGluc);
		}
		
		/**
		 * sends the command to  WriteCharacteristic and also assigns blukonCurrentCommand to command
		 */
		private static function sendCommand(command:String):void {
			if (!activeBluetoothPeripheral.writeValueForCharacteristic(writeCharacteristic, utils.UniqueId.hexStringToByteArray(command))) {
				myTrace("send " + command + " failed");
			} else {
				myTrace("send " + command + " succesfull");
			}
		}
		
		public static function processTRANSMITER_PLTransmitterData(buffer:ByteArray):void {
			buffer.endian = Endian.LITTLE_ENDIAN;
			
			buffer.position = 0;
			var bufferAsString:String = buffer.readUTFBytes(buffer.length);
			myTrace("in processTRANSMITER_PLTransmitterData buffer as string =  " + bufferAsString);
			var bufferAsStringSplitted:Array = bufferAsString.split(/\s/);
			if (bufferAsStringSplitted.length > 1) {
				if (bufferAsStringSplitted[0] == "000999") {
					if (bufferAsStringSplitted[1] == "0001") {
						myTrace("in processTRANSMITER_PLTransmitterData, error code 0001, to low voltage for nfc reading");
						if (SpikeANE.appIsInForeground()) {
							AlertManager.showSimpleAlert
							(
								"Error",
								"Voltage is too low for NFC reading.",
								4 * 60 + 30
							);
						} 					
					} else if (bufferAsStringSplitted[1] == "0002") {
						myTrace("in processTRANSMITER_PLTransmitterData, error code 0002, please check position of device. Is it fixed on sensor ? ");
						if (SpikeANE.appIsInForeground()) {
							AlertManager.showSimpleAlert
								(
									"Error",
									"Please check your Transmiter PL. Is it correctly fixed to the sensor?",
									4 * 60 + 30
								);
						} 					
					} else {
						myTrace("in processTRANSMITER_PLTransmitterData, Error code = " + bufferAsStringSplitted[1] + ", call the service man");
						if (SpikeANE.appIsInForeground()) {
							AlertManager.showSimpleAlert
								(
									"Error",
									"Error code = " + bufferAsStringSplitted[1] + ". Contact manufacturer support.",
									4 * 60 + 30
								);
						} 					
					}
					return;
				}
			}
			if (bufferAsStringSplitted.length < 4) {
				myTrace("in processTRANSMITER_PLTransmitterData. Response has less than 4 elements, no further processing");
				return;
			}
			var raw_data:Number = new Number(bufferAsStringSplitted[0]);
			if (isNaN(raw_data)) {
				myTrace("in processTRANSMITER_PLTransmitterData, data doesn't start with an Integer, no further processing");
				return;
			}
			var bridge_battery_level:Number = new Number(bufferAsStringSplitted[2]);
			
			var sensorAge:Number = (new Number(bufferAsStringSplitted[3])) * 10;
			//see https://github.com/JohanDegraeve/iosxdripreader/issues/42
			if (previousSensorAgeValue_Transmiter_PL != 0) {
				if (previousSensorAgeValue_Transmiter_PL <= sensorAge) {
					myTrace("in processTRANSMITER_PLTransmitterData, previousSensorAgeValue_Transmiter_PL = " + previousSensorAgeValue_Transmiter_PL + ", sensorAge = " + sensorAge);
					if ((new Date()).valueOf() - timeStampSinceLastSensorAgeUpdate_Transmiter_PL > 10 * 60 * 1000) {
						myTrace("in processTRANSMITER_PLTransmitterData, timeStampSinceLastSensorAgeUpdate_Transmiter_PL = " + new Date(timeStampSinceLastSensorAgeUpdate_Transmiter_PL).toLocaleString());
						LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_TRANSMITER_PL_AMOUNT_OF_INVALID_SENSOR_AGE_VALUES, 
							(new Number(new Number(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_TRANSMITER_PL_AMOUNT_OF_INVALID_SENSOR_AGE_VALUES))) + 1).toString());
						if (new Number(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_TRANSMITER_PL_AMOUNT_OF_INVALID_SENSOR_AGE_VALUES)) >= 5) {
							myTrace("in processTRANSMITER_PLTransmitterData, LocalSettings.LOCAL_SETTING_TRANSMITER_PL_AMOUNT_OF_INVALID_SENSOR_AGE_VALUES = " + LocalSettings.LOCAL_SETTING_TRANSMITER_PL_AMOUNT_OF_INVALID_SENSOR_AGE_VALUES);
							if (SpikeANE.appIsInForeground()) 
							{
								AlertManager.showSimpleAlert
								(
									ModelLocator.resourceManagerInstance.getString("globaltranslations","warning_alert_title"),
									ModelLocator.resourceManagerInstance.getString("bluetoothservice","dead_or_expired_sensor")
								);
								SpikeANE.vibrate();
							} else {
								var notificationBuilder:NotificationBuilder = new NotificationBuilder()
										.setId(NotificationService.ID_FOR_DEAD_OR_EXPIRED_SENSOR_TRANSMITTER_PL)
										.setAlert(ModelLocator.resourceManagerInstance.getString("globaltranslations","warning_alert_title"))
										.setTitle(ModelLocator.resourceManagerInstance.getString("globaltranslations","warning_alert_title"))
										.setBody(ModelLocator.resourceManagerInstance.getString("bluetoothservice","dead_or_expired_sensor"))
										.enableVibration(true)
								Notifications.service.notify(notificationBuilder.build());
							}
						}
					}
				} else {
					timeStampSinceLastSensorAgeUpdate_Transmiter_PL = (new Date()).valueOf();
					LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_TRANSMITER_PL_AMOUNT_OF_INVALID_SENSOR_AGE_VALUES, "0");
				}
			}
			previousSensorAgeValue_Transmiter_PL = sensorAge;

			if (sensorAge < new Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FSL_SENSOR_AGE))) {
				myTrace("in processTRANSMITER_PLTransmitterData, new sensor detected");
				var event:BlueToothServiceEvent = new BlueToothServiceEvent(BlueToothServiceEvent.SENSOR_CHANGED_DETECTED);
				_instance.dispatchEvent(event);
			}

			myTrace("in processTRANSMITER_PLTransmitterData, dispatching transmitter data");
			var blueToothServiceEvent:BlueToothServiceEvent = new BlueToothServiceEvent(BlueToothServiceEvent.TRANSMITTER_DATA);
			blueToothServiceEvent.data = new TransmitterDataTransmiter_PLPacket(raw_data, bridge_battery_level, sensorAge, (new Date()).valueOf());
			_instance.dispatchEvent(blueToothServiceEvent);
		}
		
		public static function processBlueReaderTransmitterData(buffer:ByteArray):void {
			buffer.position = 0;
			buffer.endian = Endian.LITTLE_ENDIAN;
			myTrace("in processBlueReaderTransmitterData data packet received from transmitter : " + utils.UniqueId.bytesToHex(buffer));

			buffer.position = 0;
			var bufferAsString:String = buffer.readUTFBytes(buffer.length);
			var blueToothServiceEvent:BlueToothServiceEvent;
			myTrace("in processBlueReaderTransmitterData buffer as string =  " + bufferAsString);
			if (buffer.length >= 7) {
				if (bufferAsString.toUpperCase().indexOf("BATTERY") > -1) {
					blueToothServiceEvent = new BlueToothServiceEvent(BlueToothServiceEvent.TRANSMITTER_DATA);
					blueToothServiceEvent.data = new TransmitterDataBlueReaderBatteryPacket();
					_instance.dispatchEvent(blueToothServiceEvent);
					return;
				}
			}
			
			myTrace("in processBlueReaderTransmitterData, it's not a battery message, continue processing");
			var bufferAsStringSplitted:Array = bufferAsString.split(/\s/);
			var raw_data:Number = new Number(bufferAsStringSplitted[0]);

			if (isNaN(raw_data)) {
				myTrace("in processBlueReaderTransmitterData, data doesn't start with an Integer, no further processing");
				return;
			}
			myTrace("in processBlueReaderTransmitterData, raw_data = " + raw_data.toString())
			
			var blueReaderBatteryLevel:Number = Number.NaN; 
			var fslBatteryLevel:Number = Number.NaN;
			var sensorAge:Number = Number.NaN;
			if (bufferAsStringSplitted.length > 1) {
				blueReaderBatteryLevel = new Number(bufferAsStringSplitted[1]);
				myTrace("in processBlueReaderTransmitterData, blueReaderBatteryLevel = " + blueReaderBatteryLevel.toString());
				if (bufferAsStringSplitted.length > 2) {
					fslBatteryLevel = new Number(bufferAsStringSplitted[2]);
					myTrace("in processBlueReaderTransmitterData, fslBatteryLevel = " + fslBatteryLevel.toString());
					if (bufferAsStringSplitted.length > 3) {
						sensorAge = new Number(bufferAsStringSplitted[3]);
						myTrace("in processBlueReaderTransmitterData, sensorAge = " + sensorAge.toString());
					}
				}
			}
			myTrace("in processBlueReaderTransmitterData, dispatching transmitter data with blueReaderBatteryLevel = " + blueReaderBatteryLevel + ", fslBatteryLevel = " + fslBatteryLevel);
			blueToothServiceEvent = new BlueToothServiceEvent(BlueToothServiceEvent.TRANSMITTER_DATA);
			blueToothServiceEvent.data = new TransmitterDataBlueReaderPacket(raw_data, blueReaderBatteryLevel, fslBatteryLevel, sensorAge, (new Date()).valueOf());
			_instance.dispatchEvent(blueToothServiceEvent);
		}
		
		private static function processG4TransmitterData(buffer:ByteArray):void {
			myTrace("in processG4TransmitterData");
			buffer.endian = Endian.LITTLE_ENDIAN;
			var packetLength:int = buffer.readUnsignedByte();
			var packetType:int = buffer.readUnsignedByte();//0 = data packet, 1 =  TXID packet, 0xF1 (241 if read as unsigned int) = Beacon packet
			var txID:Number;
			var xBridgeProtocolLevel:Number;
			var blueToothServiceEvent:BlueToothServiceEvent;
			var bridgeBatteryPercentage:Number;
			var rawData:Number;
			var transmitterBatteryVoltage:Number;
			switch (packetType) {
				case 0:
					//data packet
					rawData = buffer.readInt();
					var filteredData:Number = buffer.readInt();
					transmitterBatteryVoltage = buffer.readUnsignedByte();
					
					if (packetLength == 21) {//0x15 xbridge with protocol that has also the timestamp, example xbridger
						//could also be for dexbridgewixel, however not yet tested for that
						bridgeBatteryPercentage = buffer.readUnsignedByte();
						txID = buffer.readInt();
						var timestamp:Number = ((new Date()).valueOf() - buffer.readInt());
						//xBridgeProtocolLevel = buffer.readUnsignedByte();
						myTrace("in processG4TransmitterData, with bridgeBatteryPercentage = " + bridgeBatteryPercentage + ", txID = " + decodeTxID(txID) + ", timestamp = " + utils.DateTimeUtilities.createNSFormattedDateAndTime(new Date(timestamp)));
						
						blueToothServiceEvent = new BlueToothServiceEvent(BlueToothServiceEvent.TRANSMITTER_DATA);
						blueToothServiceEvent.data = new TransmitterDataXBridgeRDataPacket(rawData, filteredData, transmitterBatteryVoltage, bridgeBatteryPercentage, decodeTxID(txID), timestamp);
						_instance.dispatchEvent(blueToothServiceEvent);
					} else if (packetLength == 17) {//0x11 xbridge
						//following only if the name of the device contains "bridge", if it' doesnt contain bridge, then it's an xdrip (old) and doesn't have those bytes' +
						//or if packetlenth == 17, why ? because it could be a drip with xbridge software but still with a name xdrip, because it was originally an xdrip that was later on overwritten by the xbridge software, in that case the name will still by xdrip and not xbridge
						bridgeBatteryPercentage = buffer.readUnsignedByte();
						txID = buffer.readInt();
						xBridgeProtocolLevel = buffer.readUnsignedByte();
						
						blueToothServiceEvent = new BlueToothServiceEvent(BlueToothServiceEvent.TRANSMITTER_DATA);
						blueToothServiceEvent.data = new TransmitterDataXBridgeDataPacket(rawData, filteredData, transmitterBatteryVoltage, bridgeBatteryPercentage, decodeTxID(txID));
						_instance.dispatchEvent(blueToothServiceEvent);
					} else {
						blueToothServiceEvent = new BlueToothServiceEvent(BlueToothServiceEvent.TRANSMITTER_DATA);
						blueToothServiceEvent.data = new TransmitterDataXdripDataPacket(rawData, filteredData, transmitterBatteryVoltage);
						_instance.dispatchEvent(blueToothServiceEvent);
					}
					
					break;
				case 1://will actually never happen, this is a packet type for the other direction , ie from App to xbridge
					//TXID packet
					txID = buffer.readInt();
					break;
				case 241:
					//Beacon packet
					txID = buffer.readInt();
					
					blueToothServiceEvent = new BlueToothServiceEvent(BlueToothServiceEvent.TRANSMITTER_DATA);
					blueToothServiceEvent.data = new TransmitterDataXBridgeBeaconPacket(decodeTxID(txID));
					_instance.dispatchEvent(blueToothServiceEvent);
					
					xBridgeProtocolLevel = buffer.readUnsignedByte();//not needed for the moment
					break;
				default:
					myTrace("in processG4TransmitterData, unknown packet type, looks like an xdrip with old wxl code which starts with the raw_data encoded.");
					//Supports for example xdrip delivered by xdripkit.co.uk
					//Expected format is \"raw_data transmitter_battery_level bridge_battery_level with bridge_battery_level always 0" 
					//Example 123632.218.0
					//Those packets don't start with a fixed packet length and packet type, as they start with representation of an Integer
					buffer.position = 0;
					var bufferAsString:String = buffer.readUTFBytes(buffer.length);
					var bufferAsStringSplitted:Array = bufferAsString.split(/\s/);
					rawData = new Number(bufferAsStringSplitted[0]);
					
					if (isNaN(rawData)) {
						myTrace("in processG4TransmitterData, data doesn't start with an Integer, no further processing");
						return;
					}
					myTrace("in processG4TransmitterData, raw_data = " + rawData.toString())
					
					transmitterBatteryVoltage = Number.NaN; 
					if (bufferAsStringSplitted.length > 1) {
						transmitterBatteryVoltage = new Number(bufferAsStringSplitted[1]);
						myTrace("in processG4TransmitterData, transmitterBatteryVoltage = " + transmitterBatteryVoltage.toString());
					}
					myTrace("in processG4TransmitterData, dispatching transmitter data with transmitterBatteryVoltage = " + transmitterBatteryVoltage);
					blueToothServiceEvent = new BlueToothServiceEvent(BlueToothServiceEvent.TRANSMITTER_DATA);
					blueToothServiceEvent.data = new TransmitterDataXdripDataPacket(rawData, rawData, transmitterBatteryVoltage);
					_instance.dispatchEvent(blueToothServiceEvent);
					warnOldWxlCodeUsed(packetType);
			}
		}
		
		public static function warnOldWxlCodeUsed(packetType:int):void {
			if (SpikeANE.appIsInBackground()) {
				return;
			}
			
			//give the info no more than once every 24 hours
			if ((new Date()).valueOf() - new Number(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_TIMESTAMP_SINCE_LAST_WARNING_OLD_WXL_CODE_USED)) < 24 * 60 * 60 * 1000)
				return;
			
			//check if user has chosen not to receive this warning again
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_DONTASKAGAIN_ABOUT_OLD_WXL_CODE_USED) ==  "true") {
				return;
			}
			
			var alert:Alert = AlertManager.showActionAlert
				(
					ModelLocator.resourceManagerInstance.getString('transmitterservice', "warning"),
					ModelLocator.resourceManagerInstance.getString('bluetoothservice', "oldwxlused"),
					Number.NaN,
					[
						{ label: ModelLocator.resourceManagerInstance.getString("globaltranslations","cancel_button_label").toUpperCase() },
						{ label: ModelLocator.resourceManagerInstance.getString('bluetoothservice', "dontaskagain") },
						{ label: ModelLocator.resourceManagerInstance.getString('bluetoothservice', "notnow") },
						{ label: ModelLocator.resourceManagerInstance.getString('bluetoothservice', "sendemail") }
					]
				)
			alert.height = 320;
			alert.buttonGroupProperties.gap = -5;
			alert.width = 310;
			alert.addEventListener( starling.events.Event.CLOSE, sendemail );
		}
		
		private static function sendemail(e:starling.events.Event, data:Object):void {
			if (data != null) {
				if (data.label == ModelLocator.resourceManagerInstance.getString("globaltranslations","cancel_button_label").toUpperCase()) {
					return;
				} else if (data.label == ModelLocator.resourceManagerInstance.getString('bluetoothservice', "notnow")) {
					LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_TIMESTAMP_SINCE_LAST_WARNING_OLD_WXL_CODE_USED, (new Date()).valueOf().toString());
					return;
				} else if (data.label == ModelLocator.resourceManagerInstance.getString('bluetoothservice', "dontaskagain")) {
					LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_DONTASKAGAIN_ABOUT_OLD_WXL_CODE_USED, "true");
					return;
				}
			}
			
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_TIMESTAMP_SINCE_LAST_WARNING_OLD_WXL_CODE_USED, (new Date()).valueOf().toString());
			
			//Send Wixel File
			EmailFileSender.sendFile
			(
				ModelLocator.resourceManagerInstance.getString('wixelsender',"email_subject"),
				ModelLocator.resourceManagerInstance.getString('wixelsender',"email_body"),
				"xBridge2.zip",
				File.applicationDirectory.resolvePath("assets/files/xBridge2.zip"),
				"application/zip",
				ModelLocator.resourceManagerInstance.getString('wixelsender','wixel_file_sent_successfully'),
				ModelLocator.resourceManagerInstance.getString('wixelsender','wixel_file_not_sent'),
				ModelLocator.resourceManagerInstance.getString('wixelsender','wixel_file_not_found')
			);
		}
		
		private static function myTrace(log:String):void {
			Trace.myTrace("CGMBluetoothService.as", log);
		}
		
		/**
		 * returns true if activeBluetoothPeripheral != null
		 */
		public static function bluetoothPeripheralActive():Boolean {
			return activeBluetoothPeripheral != null;
		}
		
		public static function fullAuthenticateG5G6():void {
			myTrace("in fullAuthenticateG5G6");
			if (readCharacteristic != null) {
				sendAuthRequestTxMessage(readCharacteristic);
				awaitingAuthStatusRxMessage = true;
			} else {
				myTrace("fullAuthenticate: authCharacteristic is NULL!");
			}
		}
		
		private static function sendAuthRequestTxMessage(characteristic:Characteristic):void {
			authRequest = new AuthRequestTxMessage(getTokenSize());
			//myTrace("sendAuthRequestTxMessage authRequest = " + utils.UniqueId.bytesToHex(authRequest.byteSequence));
			if (!activeBluetoothPeripheral.writeValueForCharacteristic(characteristic, authRequest.byteSequence)) {
				myTrace("sendAuthRequestTxMessage writeValueForCharacteristic failed");
			}
		}
		
		private static function getTokenSize():Number {
			return 8;
		}
		
		private static function getSensorData():void {
			myTrace("in getSensorData");
			var sensorTx:SensorTxMessage = new SensorTxMessage();
			if (!activeBluetoothPeripheral.writeValueForCharacteristic(writeCharacteristic, sensorTx.byteSequence)) {
				myTrace("getSensorData writeValueForCharacteristic G5CommunicationCharacteristic failed");
			}
		}
		
		private static function doG5G6Reset():void {
			myTrace("in doG5G6Reset");
			var resetTx:ResetTxMessage = new ResetTxMessage();
			if (!activeBluetoothPeripheral.writeValueForCharacteristic(writeCharacteristic, resetTx.byteSequence)) {
				myTrace("doG5G6Reset writeValueForCharacteristic G5CommunicationCharacteristic failed");
			}
			CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_G5_G6_BATTERY_FROM_MARKER, "0");
			G5G6ResetTimeStamp = (new Date()).valueOf();
		}
		
		private static function startRescan(event:flash.events.Event):void {
			if (!(BluetoothLE.service.centralManager.state == BluetoothLEState.STATE_ON)) {
				myTrace("In startRescan but bluetooth is not on");
				return;
			}
			
			if (peripheralConnected) {
				myTrace("In startRescan but connected so returning");
				return;
			}
			
			if (!BluetoothLE.service.centralManager.isScanning) {
				myTrace("in startRescan calling bluetoothStatusIsOn");
				bluetoothStatusIsOn();
			} else {
				myTrace("in startRescan but already scanning, so returning");
				return;
			}
		}
		
		private static function getCharacteristicName(uuid:String):String {
			if (uuid.toUpperCase() == G5_G6_Authentication_Characteristic_UUID.toUpperCase()) {
				return "G5_G6_Authentication_Characteristic_UUID";
			} else if (uuid.toUpperCase() == G5_G6_Control_Characteristic_UUID.toUpperCase()) {
				return "G5_G6_Control_Characteristic_UUID";
			} else if (uuid.toUpperCase() == Blucon_TX_Characteristic_UUID.toUpperCase()) {
				return "Blucon_TX_Characteristic_UUID";
			} else if (uuid.toUpperCase() == Blucon_RX_Characteristic_UUID.toUpperCase()) {
				return "Blucon_RX_Characteristic_UUID";
			} else if (uuid.toUpperCase() == Transmiter_PL_RX_Characteristic_UUID.toUpperCase()) {
				return "Transmiter_PL_RX_Characteristics_UUID";
			} else if (uuid.toUpperCase() == Transmiter_PL_TX_Characteristic_UUID.toUpperCase()) {
				return "Transmiter_PL_TX_Characteristics_UUID";
			} else if (G4_RX_Characteristic_UUID.toUpperCase().indexOf(uuid.toUpperCase()) > -1) {
				return "G4_RX_Characteristic_UUID";
			} else if (uuid.toUpperCase() == BlueReader_RX_Characteristic_UUID.toUpperCase()) {
				return "BlueReader_RX_Characteristic_UUID";
			} else if (uuid.toUpperCase() == BlueReader_TX_Characteristic_UUID.toUpperCase()) {
				return "BlueReader_TX_Characteristic_UUID";
			} 
			return uuid + ", unknown characteristic uuid";
		}
		
		private static function isSensorReady(sensorStatusByte:int):Boolean {
			if (!ModelLocator.INTERNAL_TESTING)
				return true;
			
			var sensorStatusString:String = "";
			var ret:Boolean = false;
			
			switch (sensorStatusByte) {
				case 1:
					sensorStatusString = "not yet started";
					break;
				case 2:
					sensorStatusString = "starting";
					ret = true;
					break;
				case 3:       // status for 14 days and 12 h of normal operation, abbott reader quits after 14 days
					sensorStatusString = "ready";
					ret = true;
					break;
				case 4:       // status of the following 12 h, sensor delivers last BG reading constantly
					sensorStatusString = "expired";
					//ret = true;
					break;
				case 5:		  // sensor stops operation after 15d after start
					sensorStatusString = "shutdown";
					//to use dead sensors for test
					//ret = true
					break;
				case 6:
					sensorStatusString = "in failure";
					break;
				default:
					sensorStatusString = "in an unknown state";
					break;
			}
			
			myTrace("in isSensorReady, sensor status is: " + sensorStatusString);
			
			if (!ret) {
				AlertManager.showSimpleAlert
					(
						ModelLocator.resourceManagerInstance.getString("globaltranslations","warning_alert_title"),
						ModelLocator.resourceManagerInstance.getString("bluetoothservice","cantusesensor") + " " + sensorStatusString,
						60
					);
			}
			return ret;
		}
		
		//not sure if this is needed
		//while trying to find a stable solution for blukon, this is being added. It's supposed to increase the iOS scanning frequency
		private static function startMonitoringAndRangingBeaconsInRegion(uuid:String):void {
			if (!startedMonitoringAndRangingBeaconsInRegion) {
				SpikeANE.startMonitoringAndRangingBeaconsInRegion(uuid);
				startedMonitoringAndRangingBeaconsInRegion = true;
			}
		}
		
		private static function stopMonitoringAndRangingBeaconsInRegion(uuid:String):void {
			if (startedMonitoringAndRangingBeaconsInRegion) {
				SpikeANE.stopMonitoringAndRangingBeaconsInRegion(uuid);
				startedMonitoringAndRangingBeaconsInRegion = false;
			}
		}
		
		private static function addBluetoothLEEventListeners():void {
			BluetoothLE.service.centralManager.addEventListener(PeripheralEvent.DISCOVERED, central_peripheralDiscoveredHandler);
			BluetoothLE.service.centralManager.addEventListener(PeripheralEvent.CONNECT, central_peripheralConnectHandler );
			BluetoothLE.service.centralManager.addEventListener(PeripheralEvent.CONNECT_FAIL, central_peripheralDisconnectHandler );
			BluetoothLE.service.centralManager.addEventListener(PeripheralEvent.DISCONNECT, central_peripheralDisconnectHandler );
			BluetoothLE.service.addEventListener(BluetoothLEEvent.STATE_CHANGED, bluetoothStateChangedHandler);
		}
		
		private static function removeBluetoothLEEventListeners():void {
			BluetoothLE.service.centralManager.removeEventListener(PeripheralEvent.DISCOVERED, central_peripheralDiscoveredHandler);
			BluetoothLE.service.centralManager.removeEventListener(PeripheralEvent.CONNECT, central_peripheralConnectHandler );
			BluetoothLE.service.centralManager.removeEventListener(PeripheralEvent.CONNECT_FAIL, central_peripheralDisconnectHandler );
			BluetoothLE.service.centralManager.removeEventListener(PeripheralEvent.DISCONNECT, central_peripheralDisconnectHandler );
			BluetoothLE.service.removeEventListener(BluetoothLEEvent.STATE_CHANGED, bluetoothStateChangedHandler);
		}
		
		private static function addMiaoMiaoEventListeners():void {
			SpikeANE.instance.addEventListener(SpikeANEEvent.MIAO_MIAO_NEW_MAC, receivedMiaoMiaoDeviceAddress);
			SpikeANE.instance.addEventListener(SpikeANEEvent.MIAO_MIAO_DATA_PACKET_RECEIVED, receivedMiaoMiaoDataPacket);
			SpikeANE.instance.addEventListener(SpikeANEEvent.SENSOR_NOT_DETECTED_MESSAGE_RECEIVED_FROM_MIAOMIAO, receivedSensorNotDetectedFromMiaoMiao);
			SpikeANE.instance.addEventListener(SpikeANEEvent.SENSOR_CHANGED_MESSAGE_RECEIVED_FROM_MIAOMIAO, receivedSensorChangedFromMiaoMiao);
		}
		
		private static function removeMiaoMiaoEventListeners():void {
			SpikeANE.instance.removeEventListener(SpikeANEEvent.MIAO_MIAO_NEW_MAC, receivedMiaoMiaoDeviceAddress);
			SpikeANE.instance.removeEventListener(SpikeANEEvent.MIAO_MIAO_DATA_PACKET_RECEIVED, receivedMiaoMiaoDataPacket);
			SpikeANE.instance.removeEventListener(SpikeANEEvent.SENSOR_NOT_DETECTED_MESSAGE_RECEIVED_FROM_MIAOMIAO, receivedSensorNotDetectedFromMiaoMiao);
			SpikeANE.instance.removeEventListener(SpikeANEEvent.SENSOR_CHANGED_MESSAGE_RECEIVED_FROM_MIAOMIAO, receivedSensorChangedFromMiaoMiao);
		}
		
		private static function addG5G6EventListeners():void {
			SpikeANE.instance.addEventListener(SpikeANEEvent.G5_NEW_MAC, receivedG5G6DeviceAddress);
			SpikeANE.instance.addEventListener(SpikeANEEvent.G5_DATA_PACKET_RECEIVED, receivedG5G6DataPacket);
			SpikeANE.instance.addEventListener(SpikeANEEvent.G5_DEVICE_NOT_PAIRED, G5G6DeviceNotPaired);
		}
		
		private static function removeG5G6EventListeners():void {
			SpikeANE.instance.removeEventListener(SpikeANEEvent.G5_NEW_MAC, receivedG5G6DeviceAddress);
			SpikeANE.instance.removeEventListener(SpikeANEEvent.G5_DATA_PACKET_RECEIVED, receivedG5G6DataPacket);
			SpikeANE.instance.removeEventListener(SpikeANEEvent.G5_DEVICE_NOT_PAIRED, G5G6DeviceNotPaired);
		}
		
		private static function receivedSensorChangedFromMiaoMiao(event:flash.events.Event):void {
			myTrace("in receivedSensorChangedFromMiaoMiao");
			Tomato.receivedSensorChangedFromMiaoMiao();
		}
		
		private static function receivedSensorNotDetectedFromMiaoMiao(event:flash.events.Event):void {
			myTrace("in receivedSensorNotDetectedFromMiaoMiao received sensor not detected");
			var notificationBuilder:NotificationBuilder = new NotificationBuilder()
				.setId(NotificationService.ID_FOR_SENSOR_NOT_DETECTED_MIAOMIAO)
				.setAlert(ModelLocator.resourceManagerInstance.getString("globaltranslations","warning_alert_title"))
				.setTitle(ModelLocator.resourceManagerInstance.getString("globaltranslations","warning_alert_title"))
				.setBody(ModelLocator.resourceManagerInstance.getString("bluetoothservice","sensor_not_detected_miaomiao"))
				.enableVibration(false)
				.setSound("");
			Notifications.service.notify(notificationBuilder.build());
			_amountOfConsecutiveSensorNotDetectedForMiaoMiao++;
		}
		
		private static function receivedMiaoMiaoDeviceAddress(event:SpikeANEEvent):void {
			if (!CGMBlueToothDevice.isMiaoMiao()) {
				myTrace("in receivedMiaoMiaoDeviceAddress but not miaomiao device, not processing");
			} else {
				CGMBlueToothDevice.address = event.data.MAC;
				CGMBlueToothDevice.name = "MIAOMIAO";
			}
		}
		
		//
		private static function receivedG5G6DeviceAddress(event:SpikeANEEvent):void {
			if (!CGMBlueToothDevice.isDexcomG5() && !CGMBlueToothDevice.isDexcomG6()) {
				myTrace("in receivedG5DeviceAddress but not G5/G6 device, not processing");
			} else {
				CGMBlueToothDevice.address = event.data.MAC;
				CGMBlueToothDevice.name = expectedPeripheralName();
			}
		}
				
		private static function receivedMiaoMiaoDataPacket(event:SpikeANEEvent):void {
			Notifications.service.cancel(NotificationService.ID_FOR_SENSOR_NOT_DETECTED_MIAOMIAO);
			_amountOfConsecutiveSensorNotDetectedForMiaoMiao = 0;
			if (!CGMBlueToothDevice.isMiaoMiao()) {
				myTrace("in receivedMiaoMiaoDataPacket but not miaomiao device, not processing");
			} else {
				Tomato.decodeTomatoPacket(utils.UniqueId.hexStringToByteArray(event.data.packet as String));
			}
		}
		
		private static function G5G6DeviceNotPaired(event:SpikeANEEvent):void {
			myTrace("in G5G6DeviceNotPaired, not paired, dispatching DEVICE_NOT_PAIRED event");
			var blueToothServiceEvent:BlueToothServiceEvent = new BlueToothServiceEvent(BlueToothServiceEvent.DEVICE_NOT_PAIRED);
			_instance.dispatchEvent(blueToothServiceEvent);
		}
		
		private static function receivedG5G6DataPacket(event:SpikeANEEvent):void {
			myTrace("in receivedG5G6DataPacket");
			var buffer:ByteArray = utils.UniqueId.hexStringToByteArray(event.data.packet as String); 
			buffer.endian = Endian.LITTLE_ENDIAN;
			buffer.position = 0;
			var code:int = buffer.readByte();
			switch (code) {
				case 47://0x2f
					var sensorRx:SensorRxMessage = new SensorRxMessage(buffer);
					
					if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_G5_G6_VERSION_INFO) == "") {
						myTrace("in receivedG5G6DataPacket, firmare version unknown, will request it");
						SpikeANE.doG5FirmwareVersionRequest();
					} else {
						if ((new Date()).valueOf() - new Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_G5_G6_BATTERY_FROM_MARKER)) > CGMBluetoothService.G5_G6_BATTERY_READ_PERIOD_MS) {
							SpikeANE.doG5BatteryInfoRequest();
						} else {
							SpikeANE.disconnectG5();
						}
					}
					
					if ((new Date()).valueOf() - G5G6ResetTimeStamp < 5 * 60 * 1000) {
						myTrace("in receivedG5G6DataPacket, G5G6ResetTimeStamp was less than 5 minutes ago, ignoring this reading");
					}  if ((new Date()).valueOf() - timeStampOfLastG5G6Reading < (5 * 60 * 1000 - 30 * 1000)) {
						myTrace("in receivedG5G6DataPacket, previous reading was less than 5 minutes ago, ignoring this reading");
					} else {
						//SPIKE: Save Sensor RX Timestmp for transmitter runtime display
						if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_G5_G6_SENSOR_RX_TIMESTAMP) != String(sensorRx.timestamp))
							CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_G5_G6_SENSOR_RX_TIMESTAMP, String(sensorRx.timestamp));
						
						timeStampOfLastG5G6Reading = (new Date()).valueOf();
						var blueToothServiceEvent:BlueToothServiceEvent = new BlueToothServiceEvent(BlueToothServiceEvent.TRANSMITTER_DATA);
						blueToothServiceEvent.data = new TransmitterDataG5G6Packet(sensorRx.unfiltered, sensorRx.filtered, sensorRx.timestamp, sensorRx.transmitterStatus);
						_instance.dispatchEvent(blueToothServiceEvent);
					}
					break;
				case 67:
					//G5/G6 reset acknowledge
					if (buffer.length !== 4) {
						myTrace(" in receivedG5G6DataPacket, received G5/G6 Reset message, but length != 4, ignoring");
					} else {
						var resetDoneBody:String = "";
						if (CGMBlueToothDevice.isDexcomG5())
						{
							resetDoneBody = ModelLocator.resourceManagerInstance.getString("bluetoothservice","g5_reset_done");
						}
						else if (CGMBlueToothDevice.isDexcomG5())
						{
							resetDoneBody = ModelLocator.resourceManagerInstance.getString("bluetoothservice","g5_reset_done").replace("G5", "G6");
						}
						
						if (SpikeANE.appIsInForeground()) 
						{
							AlertManager.showSimpleAlert
								(
									ModelLocator.resourceManagerInstance.getString("globaltranslations","info_alert_title"),
									resetDoneBody
								);
							SpikeANE.vibrate();
						} else {
							var notificationBuilder:NotificationBuilder = new NotificationBuilder()
								.setId(NotificationService.ID_FOR_G5_RESET_DONE)
								.setAlert(ModelLocator.resourceManagerInstance.getString("globaltranslations","info_alert_title"))
								.setTitle(ModelLocator.resourceManagerInstance.getString("globaltranslations","info_alert_title"))
								.setBody(resetDoneBody)
								.enableVibration(true)
							Notifications.service.notify(notificationBuilder.build());
						}
					}
					break;
				case 35:
					buffer.position = 0;
					if (!setStoredBatteryBytesG5G6(buffer)) {
						myTrace("in receivedG5G6DataPacket , Could not save out battery data!");
					}
					break;
				case 75://0x4B
					//Version request response message received
					//store the complete buffer as string in the settings
					myTrace("in receivedG5G6DataPacket, received version info, storing info and disconnecting");
					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_G5_G6_VERSION_INFO, UniqueId.bytesToHex(buffer));
					break;
				default:
					myTrace("in receivedG5G6DataPacket unknown code received : " + code);
					break;
			}
		}
		
		private static function expectedPeripheralName():String {
			var expectedPeripheralName:String = "";
			if (CGMBlueToothDevice.isDexcomG5() || CGMBlueToothDevice.isDexcomG6()) {
				expectedPeripheralName = "DEXCOM" + CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TRANSMITTER_ID).substring(4,6);
				myTrace("in expectedPeripheralName, expected G5/G6 peripheral name = " + expectedPeripheralName);
			} else if (CGMBlueToothDevice.isBluKon()) {
				expectedPeripheralName = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TRANSMITTER_ID).toUpperCase();
				if (expectedPeripheralName.toUpperCase().indexOf("BLU") < 0) {
					while (expectedPeripheralName.length < 5) {
						expectedPeripheralName = "0" + expectedPeripheralName;
					}
					expectedPeripheralName = "BLU" + expectedPeripheralName;
				}
				myTrace("in expectedPeripheralName, expected blukon peripheral name = " + expectedPeripheralName);
			}
			return expectedPeripheralName;
		}
		/**
		 * sets  G5_G6_RESET_REQUESTED to true<br>
		 * this will initiate a G5/G6 reset next time the G5/G6 connects
		 */
		public static function G5G6_RequestReset():void {
			G5_G6_RESET_REQUESTED = true;
			SpikeANE.setG5Reset(true);
		}
		
		private static function setPeripheralUUIDs():void {
			if (CGMBlueToothDevice.isDexcomG4()) {
				service_UUID = G4_Service_UUID;
				advertisement_UUID_Vector = new <String>[G4_Advertisement_UUID];
				characteristics_UUID_Vector = G4_Characteristics_UUID_Vector;
				RX_Characteristic_UUID = G4_RX_Characteristic_UUID;
				TX_Characteristic_UUID = G4_TX_Characteristic_UUID;
			} else if (CGMBlueToothDevice.isDexcomG5() || CGMBlueToothDevice.isDexcomG6()) {
				service_UUID = G5_G6_Service_UUID;
				advertisement_UUID_Vector = new <String>[G5_G6_Advertisement_UUID];
				characteristics_UUID_Vector = G5_G6_Characteristics_UUID_Vector;
				RX_Characteristic_UUID = G5_G6_Authentication_Characteristic_UUID;
				TX_Characteristic_UUID = G5_G6_Control_Characteristic_UUID;
			} else if (CGMBlueToothDevice.isBlueReader()) {
				service_UUID = BlueReader_Service_UUID;
				advertisement_UUID_Vector = new <String>[BlueReader_Advertisement_UUID];
				characteristics_UUID_Vector = BlueReader_Characteristics_UUID_Vector;
				RX_Characteristic_UUID = BlueReader_RX_Characteristic_UUID;
				TX_Characteristic_UUID = BlueReader_TX_Characteristic_UUID;
			} else if (CGMBlueToothDevice.isBluKon()) {
				service_UUID = Blucon_Service_UUID;
				advertisement_UUID_Vector = new <String>[Blucon_Advertisement_UUID];
				characteristics_UUID_Vector = Blucon_Characteristics_UUID_Vector;
				RX_Characteristic_UUID = Blucon_RX_Characteristic_UUID;
				TX_Characteristic_UUID = Blucon_TX_Characteristic_UUID;
			} else if (CGMBlueToothDevice.isTransmiter_PL()) {
				service_UUID = Transmiter_PL_Service_UUID;
				advertisement_UUID_Vector = new <String>[Transmiter_PL_Advertisement_UUID];
				characteristics_UUID_Vector = Transmiter_PL_Characteristics_UUID_Vector;
				RX_Characteristic_UUID = Transmiter_PL_RX_Characteristic_UUID;
				TX_Characteristic_UUID = Transmiter_PL_TX_Characteristic_UUID;
			} else if (CGMBlueToothDevice.isxBridgeR()) {
				service_UUID = xBridgeR_Service_UUID;
				advertisement_UUID_Vector = new <String>[xBridgeR_Advertisement_UUID];
				characteristics_UUID_Vector = xBridgeR_Characteristics_UUID_Vector;
				RX_Characteristic_UUID = xBridgeR_RX_Characteristic_UUID;
				TX_Characteristic_UUID = xBridgeR_TX_Characteristic_UUID;
			} else {
				service_UUID = "";
				advertisement_UUID_Vector = null;
				characteristics_UUID_Vector = xBridgeR_Characteristics_UUID_Vector;
				RX_Characteristic_UUID = "";
				TX_Characteristic_UUID = "";
				
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
			CommonSettings.instance.removeEventListener(SettingsServiceEvent.SETTING_CHANGED, commonSettingChanged);
			NotificationService.instance.removeEventListener(NotificationServiceEvent.NOTIFICATION_EVENT, notificationReceived);
			NotificationService.instance.removeEventListener(NotificationServiceEvent.NOTIFICATION_SELECTED_EVENT, notificationReceived);
			
			if (CGMBlueToothDevice.isMiaoMiao()) {
				removeMiaoMiaoEventListeners();
			} else if ((CGMBlueToothDevice.isDexcomG5() || CGMBlueToothDevice.isDexcomG6()) && useSpikeANEForG5G6) {
				removeG5G6EventListeners();
			} else {
				removeBluetoothLEEventListeners();
			}
			
			if (_activeBluetoothPeripheral != null) {
				_activeBluetoothPeripheral.removeEventListener(PeripheralEvent.DISCOVER_SERVICES, peripheral_discoverServicesHandler );
				_activeBluetoothPeripheral.removeEventListener(PeripheralEvent.DISCOVER_CHARACTERISTICS, peripheral_discoverCharacteristicsHandler );
				_activeBluetoothPeripheral.removeEventListener(CharacteristicEvent.UPDATE, peripheral_characteristic_updatedHandler);
				_activeBluetoothPeripheral.removeEventListener(CharacteristicEvent.UPDATE_ERROR, peripheral_characteristic_errorHandler);
				_activeBluetoothPeripheral.removeEventListener(CharacteristicEvent.SUBSCRIBE, peripheral_characteristic_subscribeHandler);
				_activeBluetoothPeripheral.removeEventListener(CharacteristicEvent.SUBSCRIBE_ERROR, peripheral_characteristic_subscribeErrorHandler);
				_activeBluetoothPeripheral.removeEventListener(CharacteristicEvent.UNSUBSCRIBE, peripheral_characteristic_unsubscribeHandler);
				_activeBluetoothPeripheral.removeEventListener(CharacteristicEvent.WRITE_SUCCESS, peripheral_characteristic_writeHandler);
				_activeBluetoothPeripheral.removeEventListener(CharacteristicEvent.WRITE_ERROR, peripheral_characteristic_writeErrorHandler);
			}
			
			if (scanTimer != null && scanTimer.running)
			{
				scanTimer.removeEventListener(TimerEvent.TIMER, stopScanning);
				scanTimer.stop();
			}
			
			if (discoverServiceOrCharacteristicTimer != null && discoverServiceOrCharacteristicTimer.running)
			{
				discoverServiceOrCharacteristicTimer.addEventListener(TimerEvent.TIMER, discoverServices);
				discoverServiceOrCharacteristicTimer.addEventListener(TimerEvent.TIMER, discoverCharacteristics);
				discoverServiceOrCharacteristicTimer.stop();
			}
			
			myTrace("Service stopped!");
		}
	}
}