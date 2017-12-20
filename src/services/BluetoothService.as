/**
 Copyright (C) 2016  Johan Degraeve
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/gpl.txt>.
 
 */
package services
{
	import com.distriqt.extension.bluetoothle.AuthorisationStatus;
	import com.distriqt.extension.bluetoothle.BluetoothLE;
	import com.distriqt.extension.bluetoothle.BluetoothLEState;
	import com.distriqt.extension.bluetoothle.events.BluetoothLEEvent;
	import com.distriqt.extension.bluetoothle.events.CharacteristicEvent;
	import com.distriqt.extension.bluetoothle.events.PeripheralEvent;
	import com.distriqt.extension.bluetoothle.objects.Characteristic;
	import com.distriqt.extension.bluetoothle.objects.Peripheral;
	import com.distriqt.extension.dialog.Dialog;
	import com.distriqt.extension.dialog.DialogView;
	import com.distriqt.extension.dialog.builders.AlertBuilder;
	import com.distriqt.extension.dialog.events.DialogViewEvent;
	import com.distriqt.extension.dialog.objects.DialogAction;
	import com.distriqt.extension.message.Message;
	import com.freshplanet.ane.AirBackgroundFetch.BackgroundFetch;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.utils.Timer;
	
	import mx.collections.ArrayCollection;
	
	import G5Model.AuthChallengeRxMessage;
	import G5Model.AuthChallengeTxMessage;
	import G5Model.AuthRequestTxMessage;
	import G5Model.AuthStatusRxMessage;
	import G5Model.BatteryInfoRxMessage;
	import G5Model.BatteryInfoTxMessage;
	import G5Model.SensorRxMessage;
	import G5Model.SensorTxMessage;
	import G5Model.TransmitterStatus;
	
	import Utilities.Trace;
	import Utilities.UniqueId;
	
	import avmplus.FLASH10_FLAGS;
	
	import databaseclasses.BgReading;
	import databaseclasses.BlueToothDevice;
	import databaseclasses.CommonSettings;
	import databaseclasses.LocalSettings;
	
	import distriqtkey.DistriqtKey;
	
	import events.BlueToothServiceEvent;
	import events.SettingsServiceEvent;
	
	import model.ModelLocator;
	import model.TransmitterDataBluKonPacket;
	import model.TransmitterDataBlueReaderBatteryPacket;
	import model.TransmitterDataBlueReaderPacket;
	import model.TransmitterDataG5Packet;
	import model.TransmitterDataXBridgeBeaconPacket;
	import model.TransmitterDataXBridgeDataPacket;
	import model.TransmitterDataXdripDataPacket;
	
	import views.SettingsView;
	
	/**
	 * all functionality related to bluetooth connectivity<br>
	 * init function must be called once immediately at start of the application<br>
	 * <br>
	 * to get info about connectivity status, new transmitter data ... check BluetoothServiceEvent  create listeners for the events<br>
	 * BluetoothService itself is not doing anything with the data received from the bluetoothdevice, also not checking the transmit id, it just passes the information via 
	 * dispatching<br>
	 */
	public class BluetoothService extends EventDispatcher
	{
		[ResourceBundle("bluetoothservice")]
		[ResourceBundle("settingsview")]
		
		private static var _instance:BluetoothService = new BluetoothService();
		
		public static function get instance():BluetoothService
		{
			return _instance;
		}
		
		private static var _activeBluetoothPeripheral:Peripheral;
		
		private static var initialStart:Boolean = true;
		
		private static const MAX_SCAN_TIME_IN_SECONDS:int = 320;
		private static var discoverServiceOrCharacteristicTimer:Timer;
		private static const DISCOVER_SERVICES_OR_CHARACTERISTICS_RETRY_TIME_IN_SECONDS:int = 1;
		private static const MAX_RETRY_DISCOVER_SERVICES_OR_CHARACTERISTICS:int = 5;
		private static var amountOfDiscoverServicesOrCharacteristicsAttempt:int = 0;
		
		private static var awaitingConnect:Boolean = false;
		
		private static const srcNameTable:Array = [ '0', '1', '2', '3', '4', '5', '6', '7',
			'8', '9', 'A', 'B', 'C', 'D', 'E', 'F',
			'G', 'H', 'J', 'K', 'L', 'M', 'N', 'P',
			'Q', 'R', 'S', 'T', 'U', 'W', 'X', 'Y' ];
		
		public static const HM_10_SERVICE_G4:String = "0000ffe0-0000-1000-8000-00805f9b34fb"; 
		public static const HM_10_SERVICE_G5:String = "F8083532-849E-531C-C594-30F1F86A4EA5"; 
		public static const HM_10_SERVICE_BLUKON:String = "436A62C0-082E-4CE8-A08B-01D81F195B24"; 
		public static const HM_RX_TX_G4:String = "0000ffe1-0000-1000-8000-00805f9b34fb";
		public static const G5_Communication_Characteristic_UUID:String = "F8083533-849E-531C-C594-30F1F86A4EA5";
		public static const G5_Control_Characteristic_UUID:String = "F8083534-849E-531C-C594-30F1F86A4EA5";
		public static const G5_Authentication_Characteristic_UUID:String = "F8083535-849E-531C-C594-30F1F86A4EA5";
		public static const BC_desiredTransmitCharacteristicUUID:String = "436AA6E9-082E-4CE8-A08B-01D81F195B24";
		public static const BC_desiredReceiveCharacteristicUUID:String = "436A0C82-082E-4CE8-A08B-01D81F195B24";
		public static const BlueReader_SERVICE:String = "6e400001-b5a3-f393-e0a9-e50e24dcca9e";
		public static const BlueReader_TX_Characteristic_UUID:String = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E";
		public static const BlueReader_RX_Characteristic_UUID:String = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E";

		private static const uuids_G4_Service:Vector.<String> = new <String>[HM_10_SERVICE_G4];
		private static const uuids_G5_Service:Vector.<String> = new <String>["F8083532-849E-531C-C594-30F1F86A4EA5"];
		private static const uuids_BLUKON_Service:Vector.<String> = new <String>["436A62C0-082E-4CE8-A08B-01D81F195B24"];
		private static const uuids_BlueReader_Service:Vector.<String> = new <String>[BlueReader_SERVICE];
		private static const uuids_Bluereader_Advertisement:Vector.<String> = new <String>[""];//00001530-1212-EFDE-1523-785FEABCD123", "7905F431-B5CE-4E99-A40F-4B1E122D00D0"];
			
		private static const uuids_G5_Advertisement:Vector.<String> = new <String>["0000FEBC-0000-1000-8000-00805F9B34FB"];
		private static const uuids_G4_Characteristics:Vector.<String> = new <String>[HM_RX_TX_G4];
		private static const uuids_G5_Characteristics:Vector.<String> = new <String>[G5_Authentication_Characteristic_UUID, G5_Communication_Characteristic_UUID, G5_Control_Characteristic_UUID];
		private static const uuids_BLUKON_Characteristics:Vector.<String> = new <String>[BC_desiredReceiveCharacteristicUUID, BC_desiredTransmitCharacteristicUUID];
		private static const uuids_BlueReader_Characteristics:Vector.<String> = new <String>[BlueReader_TX_Characteristic_UUID, BlueReader_RX_Characteristic_UUID];
			
		private static var connectionAttemptTimeStamp:Number;
		private static const maxTimeBetweenConnectAttemptAndConnectSuccess:Number = 3;
		private static var waitingForPeripheralCharacteristicsDiscovered:Boolean = false;
		private static var waitingForServicesDiscovered:Boolean = false;
		
		private static var authRequest:AuthRequestTxMessage = null;
		private static var authStatus:AuthStatusRxMessage = null;
		private static var discoveryTimeStamp:Number;
		
		public static const BATTERY_READ_PERIOD_MS:Number = 1000 * 60 * 60 * 12; // how often to poll battery data (12 hours)
		
		private static var timeStampOfLastG5Reading:Number = 0;
		
		private static var timeStampOfLastWarningUnknownG4Command:Number = 0;
		//list of packet types seen in logs for xdrips from xdripkit.co.uk
		private static var listOfSeenInvalidPacketTypes:Array = [49, 50, 51, 52, 53, 54, 55, 56, 57, 84];

		private static var timeStampOfLastDeviceNotPairedForBlukon:Number = 0;
		/**
		 * for blukon protocol
		 */
		private static var nowGlucoseOffset:int = 0;
		
		/**
		 * used for intial scan G4, but also other peripherals that broadcast themselves continuously, like bluereader
		 */
		private static var G4ScanTimer:Timer;
		
		private static var peripheralConnected:Boolean = false;
		
		private static var blukonCurrentCommand:String="";
		
		private static var m_getNowGlucoseDataIndexCommand:Boolean = false;
		private static var m_gotOneTimeUnknownCmd:Boolean = false;
		private static var GET_SENSOR_AGE_DELAY_IN_SECONDS:int =  3 * 3600;
		private static var BLUKON_GETSENSORAGE_TIMER:String = "blukon-getSensorAge-timer";
		private static var m_getNowGlucoseDataCommand:Boolean = false;// to be sure we wait for a GlucoseData Block and not using another block
		private static var m_timeLastBg:Number = 0;
		private static var m_persistentTimeLastBg:Number;
		private static var m_blockNumber:int = 0;
		private static var m_full_data:ByteArray = new ByteArray();
		private static var FSLSensorAGe:Number;
		private static var unsupportedPacketType:int = 0;

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
		
		private static var _G4characteristic:Characteristic;
		
		private static function get G4characteristic():Characteristic
		{
			return _G4characteristic;
		}
		
		private static function set G4characteristic(value:Characteristic):void
		{
			_G4characteristic = value;
		}
		
		private static var G5AuthenticationCharacteristic:Characteristic;
		
		private static var G5CommunicationCharacteristic:Characteristic;
		
		private static var G5ControlCharacteristic:Characteristic;
		
		private static var BC_desiredTransmitCharacteristic:Characteristic;

		private static var BC_desiredReceiveCharacteristic:Characteristic;
		
		private static var BlueReader_RX_Characteristic:Characteristic;
		
		private static var BlueReader_TX_Characteristic:Characteristic;
		
		//blukon global vars for backfill processing
		private static var m_currentTrendIndex:int;
		private static var m_currentBlockNumber:String = "";
		private static var m_currentOffset:int = 0;
		private static var m_minutesDiffToLastReading:int = 0;
		private static var m_minutesBack:int;
		private static var m_getOlderReading:Boolean = false;

		public function BluetoothService()
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
			
			peripheralConnected = false;
			
			CommonSettings.instance.addEventListener(SettingsServiceEvent.SETTING_CHANGED, settingChanged);
			
			//blukon
			m_gotOneTimeUnknownCmd = false;
			m_getNowGlucoseDataCommand = false;
			m_getNowGlucoseDataIndexCommand = false;
			m_getOlderReading = false;
			m_blockNumber = 0;
			if (BlueToothDevice.isBluKon()) {
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_BLUKON_BATTERY_LEVEL, "0");
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_FSL_SENSOR_AGE, "0");
			}
			
			BluetoothLE.init(DistriqtKey.distriqtKey);
			if (BluetoothLE.isSupported) {
				myTrace("passing bluetoothservice.issupported");
				myTrace("authorisation status = " + BluetoothLE.service.authorisationStatus());
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
						BluetoothLE.service.centralManager.addEventListener(PeripheralEvent.DISCOVERED, central_peripheralDiscoveredHandler);
						BluetoothLE.service.centralManager.addEventListener(PeripheralEvent.CONNECT, central_peripheralConnectHandler );
						BluetoothLE.service.centralManager.addEventListener(PeripheralEvent.CONNECT_FAIL, central_peripheralDisconnectHandler );
						BluetoothLE.service.centralManager.addEventListener(PeripheralEvent.DISCONNECT, central_peripheralDisconnectHandler );
						BluetoothLE.service.addEventListener(BluetoothLEEvent.STATE_CHANGED, bluetoothStateChangedHandler);
						
						var blueToothServiceEvent:BlueToothServiceEvent = new BlueToothServiceEvent(BlueToothServiceEvent.BLUETOOTH_SERVICE_INITIATED);
						_instance.dispatchEvent(blueToothServiceEvent);
						
						switch (BluetoothLE.service.centralManager.state)
						{
							case BluetoothLEState.STATE_ON:	
								// We can use the Bluetooth LE functions
								bluetoothStatusIsOn();
								myTrace("bluetooth is switched on")
								break;
							case BluetoothLEState.STATE_OFF:
								myTrace("bluetooth is switched off")
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
		
		private static function settingChanged(event:SettingsServiceEvent):void {
			if (event.data == CommonSettings.COMMON_SETTING_PERIPHERAL_TYPE) {
				myTrace("in settingChanged, event.data = COMMON_SETTING_PERIPHERAL_TYPE, calling stopscanning");
				if (G4ScanTimer != null) {
					if (G4ScanTimer.running) {
						G4ScanTimer.stop();
					}
					G4ScanTimer = null;
				}
				stopScanning(null);//need to stop scanning because device type has changed, means also the UUID to scan for
				if (BlueToothDevice.alwaysScan() && BlueToothDevice.transmitterIdKnown()) {
					if (BluetoothLE.service.centralManager.state == BluetoothLEState.STATE_ON) {
						startScanning();
					}
				} else {
				}
			} else if (event.data == CommonSettings.COMMON_SETTING_TRANSMITTER_ID) {
				myTrace("in settingChanged, event.data = COMMON_SETTING_TRANSMITTER_ID, calling BlueToothDevice.forgetbluetoothdevice");
				BlueToothDevice.forgetBlueToothDevice();
				if (BlueToothDevice.transmitterIdKnown() && BlueToothDevice.alwaysScan()) {
					if (BluetoothLE.service.centralManager.state == BluetoothLEState.STATE_ON) {
						myTrace("in settingChanged, event.data = COMMON_SETTING_TRANSMITTER_ID, restart scanning");
						startScanning();
					} else {
						myTrace("in settingChanged, event.data = COMMON_SETTING_TRANSMITTER_ID, restart scanning needed but bluetooth is not on");
					}
				} else {
					myTrace("in settingChanged, event.data = COMMON_SETTING_TRANSMITTER_ID but transmitter id not known or alwaysscan is false");
				}
			}
		}
		
		private static function treatNewBlueToothStatus(newStatus:String):void {
			switch (BluetoothLE.service.centralManager.state)
			{
				case BluetoothLEState.STATE_ON:	
					myTrace("bluetooth is switched on")
					// We can use the Bluetooth LE functions
					bluetoothStatusIsOn();
					break;
				case BluetoothLEState.STATE_OFF:
					myTrace("bluetooth is switched off")
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
		
		private static function bluetoothStateChangedHandler(event:BluetoothLEEvent):void
		{
			treatNewBlueToothStatus(BluetoothLE.service.centralManager.state);					
		}
		
		private static function bluetoothStatusIsOn():void {
			if (activeBluetoothPeripheral != null && !(BlueToothDevice.alwaysScan())) {//do we ever pass here, activebluetoothperipheral is set to null after disconnect
				awaitingConnect = true;
				connectionAttemptTimeStamp = (new Date()).valueOf();
				BluetoothLE.service.centralManager.connect(activeBluetoothPeripheral);
				myTrace("Trying to connect to known device.");
			} else if (activeBluetoothPeripheral != null && BlueToothDevice.isBluKon()) {
				awaitingConnect = true;
				connectionAttemptTimeStamp = (new Date()).valueOf();
				BluetoothLE.service.centralManager.connect(activeBluetoothPeripheral);
				myTrace("Trying to connect to blukon.");
			} else if (activeBluetoothPeripheral != null && BlueToothDevice.isBlueReader()) {
				awaitingConnect = true;
				connectionAttemptTimeStamp = (new Date()).valueOf();
				BluetoothLE.service.centralManager.connect(activeBluetoothPeripheral);
				myTrace("Trying to connect to bluereader.");
			} else if (BlueToothDevice.known() || (BlueToothDevice.alwaysScan() && BlueToothDevice.transmitterIdKnown())) {
				myTrace("call startScanning");
				startScanning();
			} else {
				myTrace("in bluetootbluetoothStatusIsOn but not restarting scan because it's not an alwaysScan peripheral or no device known");
			}
		}
		
		public static function startScanning(initialG4Scan:Boolean = false):void {
			if (!BluetoothLE.service.centralManager.isScanning) {
				if (!BluetoothLE.service.centralManager.scanForPeripherals(
					BlueToothDevice.isBluKon() ? uuids_BLUKON_Service : 
					(BlueToothDevice.isDexcomG5() ? uuids_G5_Advertisement:
					(BlueToothDevice.isBlueReader() ? uuids_Bluereader_Advertisement :uuids_G4_Service))))
				{
					myTrace("failed to start scanning for peripherals");
					return;
				} else {
					myTrace("started scanning for peripherals, peripheraltype = " + CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PERIPHERAL_TYPE));
					if (initialG4Scan) {
						myTrace("it's a G4 scan, starting scanTimer");
						G4ScanTimer = new Timer(MAX_SCAN_TIME_IN_SECONDS * 1000, 1);
						G4ScanTimer.addEventListener(TimerEvent.TIMER, stopScanning);
						G4ScanTimer.start();
					}
				}
			} else {
				myTrace("in startscanning but already scanning");
			}
		}
		
		private static function stopScanning(event:Event):void {
			myTrace("in stopScanning");
			if (BluetoothLE.service.centralManager.isScanning) {
				myTrace("in stopScanning, is scanning, call stopScan");
				BluetoothLE.service.centralManager.stopScan();
				_instance.dispatchEvent(new BlueToothServiceEvent(BlueToothServiceEvent.STOPPED_SCANNING));
			}
		}
		
		private static function central_peripheralDiscoveredHandler(event:PeripheralEvent):void {
			myTrace("in central_peripheralDiscoveredHandler, stop scanning");
			BluetoothLE.service.centralManager.stopScan();

			discoveryTimeStamp = (new Date()).valueOf();
			if (awaitingConnect && !(BlueToothDevice.alwaysScan())) {
				myTrace("in central_peripheralDiscoveredHandler but already awaiting connect, ignoring this one. peripheral name = " + event.peripheral.name);
				myTrace("restart scan");
				startRescan(null);
				return;
			} else {
				myTrace("passing in central_peripheralDiscoveredHandler. Peripheral name = " + event.peripheral.name);
			}
			
			if (BlueToothDevice.isDexcomG5()) {
				if ((new Date()).valueOf() - timeStampOfLastG5Reading < 60 * 1000) {
					myTrace("G5 but last reading was less than 1 minute ago, ignoring this peripheral discovery");
					myTrace("restart scan");
					startRescan(null);
					return;
				}
			}
			
			if (BlueToothDevice.isBluKon()) {
				if (peripheralConnected) {
					myTrace("in central_peripheralDiscoveredHandler, blukon, already connected. Ignoring this device (it could be another one) and not restarting scanning");
					return;
				}
			}
			
			// event.peripheral will contain a Peripheral object with information about the Peripheral
			var expectedDeviceName:String;
			if (BlueToothDevice.isDexcomG5()) {
				expectedDeviceName = "DEXCOM" + CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TRANSMITTER_ID).substring(4,6);
				myTrace("expected g5 device name = " + expectedDeviceName);
			} else if (BlueToothDevice.isBluKon()) {
				expectedDeviceName = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TRANSMITTER_ID).toUpperCase();
				if (expectedDeviceName.toUpperCase().indexOf("BLU") < 0) {
					while (expectedDeviceName.length < 5) {
						expectedDeviceName = "0" + expectedDeviceName;
					}
					expectedDeviceName = "BLU" + expectedDeviceName;
				}
				myTrace("expected blukon device name = " + expectedDeviceName);
			}
			
			if (
				(!(BlueToothDevice.alwaysScan()) &&
					(
						(event.peripheral.name as String).toUpperCase().indexOf("DRIP") > -1 
						|| (event.peripheral.name as String).toUpperCase().indexOf("BRIDGE") > -1 
						|| (event.peripheral.name as String).toUpperCase().indexOf("LIMITIX") > -1
						|| (event.peripheral.name as String).toUpperCase().indexOf("LIMITTER") > -1
						|| (event.peripheral.name as String).toUpperCase().indexOf("BLUEREADER") > -1
						|| (event.peripheral.name as String).toUpperCase().indexOf("DINANTRONICS") > -1
					)
				) 
				||
				(BlueToothDevice.isDexcomG5() &&
					(
						(event.peripheral.name as String).toUpperCase().indexOf(expectedDeviceName) > -1
					)
				)
				||
				(BlueToothDevice.isBluKon() &&
					(
						(event.peripheral.name as String).toUpperCase().indexOf(expectedDeviceName) > -1
					)
				)
			) {
				myTrace("Found peripheral with name" + " = " + event.peripheral.name);
				
				if (BlueToothDevice.address != "") {
					if (BlueToothDevice.address != event.peripheral.uuid) {
						//a bluetooth device address is already stored, but it's not the one for which peripheraldiscoveredhandler is called
						//so we ignore it
						myTrace("UUID of found peripheral does not match with name of the UUID stored in the database - will ignore this xdrip/xbridge/LimiTTer/Dexcom.");
						//BluetoothLE.service.centralManager.stopScan();
						return;
					}
				} else {
					//we store also this device, as of now, all future connect attempts will be only to this one, until the user choses "forget device"
					BlueToothDevice.address = event.peripheral.uuid;
					BlueToothDevice.name = event.peripheral.name;
					myTrace("Device details will be stored in database. Future attempts will only use this device to connect to.");
				}
				
				awaitingConnect = true;
				connectionAttemptTimeStamp = (new Date()).valueOf();
				BluetoothLE.service.centralManager.connect(event.peripheral);
				
			} else {
				myTrace("doesn't seem to be a device we are interested in, name : " + event.peripheral.name + " - restart scan");
				startRescan(null);
			}
		}
		
		private static function central_peripheralConnectHandler(event:PeripheralEvent):void {
			myTrace("in central_peripheralConnectHandler, setting peripheralConnected = true");
			peripheralConnected = true;
			
			if (BlueToothDevice.isBluKon()) {
				if (BluetoothLE.service.centralManager.isScanning) {
					//this may happen because for blukon, after disconnect, we start scanning and also try to reconnect
					myTrace("in central_peripheralConnectHandler, blukon and scanning. Stop scanning");
					BluetoothLE.service.centralManager.stopScan();
				}
			}
			
			if (BlueToothDevice.isDexcomG5()) {
				if ((new Date()).valueOf() - timeStampOfLastG5Reading < 60 * 1000) {
					myTrace("G5 but last reading was less than 1 minute ago, disconnecting");
					if (!BluetoothLE.service.centralManager.disconnect(activeBluetoothPeripheral)) {
						myTrace("doDisconnectMessageG5 failed");
					}
					return;
				}
			}
			
			if (G4ScanTimer != null) {
				if (G4ScanTimer.running) {
					myTrace("in central_peripheralConnectHandler, stopping scanTimer");
					G4ScanTimer.stop();
				}
				G4ScanTimer = null;
			}

			if (!awaitingConnect && !BlueToothDevice.isBluKon()) {
				myTrace("in central_peripheralConnectHandler but awaitingConnect = false, will disconnect");
				//activeBluetoothPeripheral = null;
				BluetoothLE.service.centralManager.disconnect(event.peripheral);
				return;
			} 
			
			awaitingConnect = false;
			if (!BlueToothDevice.alwaysScan()) {
				if ((new Date()).valueOf() - connectionAttemptTimeStamp > maxTimeBetweenConnectAttemptAndConnectSuccess * 1000) { //not waiting more than 3 seconds between device discovery and connection success
					myTrace("passing in central_peripheralConnectHandler but time between connect attempt and connect success is more than " + maxTimeBetweenConnectAttemptAndConnectSuccess + " seconds. Will disconnect");
					BluetoothLE.service.centralManager.disconnect(event.peripheral);
					return;
				} 
			}
			
			if (BlueToothDevice.isBlueReader() || BlueToothDevice.isBluKon()) {
				_instance.dispatchEvent(new BlueToothServiceEvent(BlueToothServiceEvent.BLUETOOTH_DEVICE_CONNECTION_COMPLETED));
			}
			
			myTrace("connected to peripheral");
			if (activeBluetoothPeripheral == null)
				activeBluetoothPeripheral = event.peripheral;
			
			if (BlueToothDevice.isBluKon() || BlueToothDevice.isBlueReader())
				activeBluetoothPeripheral = event.peripheral;

			if (BlueToothDevice.isBluKon()) {
				myTrace("it's a blukon, setting state to BLUKON_COMMAND_initialState " + "");
				blukonCurrentCommand = "";
			}
			
			discoverServices();
		}
		
		private static function discoverServices(event:Event = null):void {
			waitingForServicesDiscovered = false;
			if (activeBluetoothPeripheral == null)//rare case, user might have done forget xdrip while waiting for rettempt
				return;
			
			if (discoverServiceOrCharacteristicTimer != null) {
				discoverServiceOrCharacteristicTimer.stop();
				discoverServiceOrCharacteristicTimer = null;
			}
			
			if (!peripheralConnected) {
				myTrace("discoverservices,  but peripheralConnected = false, returning");
				amountOfDiscoverServicesOrCharacteristicsAttempt = 0;
				return;
			}
			
			if (amountOfDiscoverServicesOrCharacteristicsAttempt < MAX_RETRY_DISCOVER_SERVICES_OR_CHARACTERISTICS) {
				amountOfDiscoverServicesOrCharacteristicsAttempt++;
				myTrace("discoverservices attempt " + amountOfDiscoverServicesOrCharacteristicsAttempt);
				
				waitingForServicesDiscovered = true;
				activeBluetoothPeripheral.discoverServices(
					BlueToothDevice.isBluKon() ? uuids_BLUKON_Service : 
					(BlueToothDevice.isDexcomG5() ? uuids_G5_Service:
					(BlueToothDevice.isBlueReader() ? uuids_BlueReader_Service:
					uuids_G4_Service)));
				if (!BlueToothDevice.isBluKon()) {
					discoverServiceOrCharacteristicTimer = new Timer(DISCOVER_SERVICES_OR_CHARACTERISTICS_RETRY_TIME_IN_SECONDS * 1000, 1);
					discoverServiceOrCharacteristicTimer.addEventListener(TimerEvent.TIMER, discoverServices);
					discoverServiceOrCharacteristicTimer.start();
				}
			} else {
				myTrace("Maximum amount of attempts for discover bluetooth services reached.")
				amountOfDiscoverServicesOrCharacteristicsAttempt = 0;
				
				//i just happens that retrying doesn't help anymore
				//so disconnecting and rescanning seems the only solution ?
				
				//disconnect will cause central_peripheralDisconnectHandler to be called (although not sure because setting activeBluetoothPeripheral to null, i would expect that removes also the eventlisteners
				//central_peripheralDisconnectHandler will see that activeBluetoothPeripheral == null and so 
				var temp:Peripheral = activeBluetoothPeripheral;
				activeBluetoothPeripheral = null;
				BluetoothLE.service.centralManager.disconnect(temp);
				
				myTrace("will_re_scan_for_device");
				
				if ((BluetoothLE.service.centralManager.state == BluetoothLEState.STATE_ON)) {
					bluetoothStatusIsOn();
				}
			}
		}
		
		private static function central_peripheralDisconnectHandler(event:Event = null):void {
			myTrace('Disconnected from device or attempt to reconnect failed');
			if (BlueToothDevice.isBluKon()) {
				myTrace('it is a blukon');
				myTrace('setting peripheralConnected = false');
				peripheralConnected = false;
				awaitingConnect = false;
				//try to reconnect and also restart scanning, to cover reconnect issue. Because maybe the transmitter starts re-advertising
				tryReconnect();
				startScanning();
			} else if (BlueToothDevice.isBlueReader()) {
				myTrace('it is a bluereader');
				myTrace('setting peripheralConnected = false');
				peripheralConnected = false;
				awaitingConnect = false;
				tryReconnect();
			} else {
				myTrace('setting peripheralConnected = false');
				peripheralConnected = false;
				awaitingConnect = false;
				forgetActiveBluetoothPeripheral();
				startRescan(null);
			}
		}
		
		private static function tryReconnect(event:Event = null):void {
			if ((BluetoothLE.service.centralManager.state == BluetoothLEState.STATE_ON)) {
				bluetoothStatusIsOn();
			} else {
				//no need to further retry, a reconnect will be done as soon as bluetooth is switched on
			}
		}
		
		private static function peripheral_discoverServicesHandler(event:PeripheralEvent):void {
			if (!waitingForServicesDiscovered && !(BlueToothDevice.alwaysScan())) {
				myTrace("in peripheral_discoverServicesHandler but not waitingForServicesDiscovered and not alwaysscan device, ignoring");
				return;
			} else if (waitingForServicesDiscovered && !(BlueToothDevice.alwaysScan())) {
				myTrace("in peripheral_discoverServicesHandler and waitingForServicesDiscovered and not alwyasscan device");
			} else 
				myTrace("in peripheral_discoverServicesHandler and alwaysscan device");
			waitingForServicesDiscovered = false;
			
			if (discoverServiceOrCharacteristicTimer != null) {
				discoverServiceOrCharacteristicTimer.stop();
				discoverServiceOrCharacteristicTimer = null;
			}
			myTrace("Bluetooth peripheral services discovered.");
			amountOfDiscoverServicesOrCharacteristicsAttempt = 0;
			
			if (event.peripheral.services.length > 0)
			{
				discoverCharacteristics();
			} else {
				myTrace("event.peripheral.services.length == 0, not calling discoverCharacteristics");
			}
		}
		
		private static function discoverCharacteristics(event:Event = null):void {
			if (activeBluetoothPeripheral == null)//rare case, user might have done forget xdrip while waiting to reattempt
				return;
			
			if (discoverServiceOrCharacteristicTimer != null) {
				discoverServiceOrCharacteristicTimer.stop();
				discoverServiceOrCharacteristicTimer = null;
			}
			
			if (!peripheralConnected) {
				myTrace("discoverCharacteristics,  but peripheralConnected = false, returning");
				amountOfDiscoverServicesOrCharacteristicsAttempt = 0;
				return;
			}
			
			if (amountOfDiscoverServicesOrCharacteristicsAttempt < MAX_RETRY_DISCOVER_SERVICES_OR_CHARACTERISTICS
				&&
				activeBluetoothPeripheral.services.length > 0) {
				amountOfDiscoverServicesOrCharacteristicsAttempt++;
				var message:String = 'launching_discovercharacteristics_attempt_amount' + " " + amountOfDiscoverServicesOrCharacteristicsAttempt;
				myTrace(message);
				
				//find the index of the service that has uuid = the one used by xdrip/xbridge or Dexcom
				var index:int;
				if (BlueToothDevice.isDexcomG5()) {
					for each (var o:Object in activeBluetoothPeripheral.services) {
						if (HM_10_SERVICE_G5.indexOf((o.uuid as String).toUpperCase()) > -1) {
							break;
						}
						index++;
					}
				} else if (BlueToothDevice.isBluKon()) {
					for each (var o:Object in activeBluetoothPeripheral.services) {
						if (HM_10_SERVICE_BLUKON.toUpperCase().indexOf((o.uuid as String).toUpperCase()) > -1) {
							break;
						}
						index++;
					}
				} else if (BlueToothDevice.isDexcomG4()) {
					for each (var o:Object in activeBluetoothPeripheral.services) {
						if (HM_10_SERVICE_G4.indexOf(o.uuid as String) > -1) {
							break;
						}
						index++;
					}
				} else if (BlueToothDevice.isBlueReader()) {
					for each (var o:Object in activeBluetoothPeripheral.services) {
						if (BlueReader_SERVICE.toUpperCase().indexOf((o.uuid as String).toUpperCase()) > -1) {
							break;
						}
						index++;
					}
				}
				
				waitingForPeripheralCharacteristicsDiscovered = true;
				activeBluetoothPeripheral.discoverCharacteristics(activeBluetoothPeripheral.services[index], 
					BlueToothDevice.isBluKon() ? uuids_BLUKON_Characteristics : 
					(BlueToothDevice.isDexcomG5() ? uuids_G5_Characteristics:
					(BlueToothDevice.isBlueReader() ? uuids_BlueReader_Characteristics:
					uuids_G4_Characteristics)));
				discoverServiceOrCharacteristicTimer = new Timer(DISCOVER_SERVICES_OR_CHARACTERISTICS_RETRY_TIME_IN_SECONDS * 1000, 1);
				discoverServiceOrCharacteristicTimer.addEventListener(TimerEvent.TIMER, discoverCharacteristics);
				discoverServiceOrCharacteristicTimer.start();
			} else {
				tryReconnect();
			}
		}
		
		private static function peripheral_discoverCharacteristicsHandler(event:PeripheralEvent):void {
			myTrace("in peripheral_discoverCharacteristicsHandler");
			if (!waitingForPeripheralCharacteristicsDiscovered && !BlueToothDevice.isBluKon()) {
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
			
			//find the index of the service that has uuid = the one used by xdrip/xbridge
			var servicesIndex:int = 0;
			var G4CharacteristicsIndex:int = 0;
			var G5AuthenticationCharacteristicsIndex:int = 0;
			var G5CommunicationCharacteristicsIndex:int = 0;
			var G5ControlCharacteristicsIndex:int = 0;
			var BC_desiredReceiveCharacteristicIndex:int = 0;
			var BC_desiredTransmitCharacteristicIndex:int = 0;
			var BlueReader_Rx_CharacteristicIndex:int = 0;
			var BlueReader_Tx_CharacteristicIndex:int = 0;
			
			var o:Object;
			if (BlueToothDevice.isDexcomG5()) {
				for each (o in activeBluetoothPeripheral.services) {
					if (HM_10_SERVICE_G5.indexOf((o.uuid as String).toUpperCase()) > -1) {
						break;
					}
					servicesIndex++;
				}
				for each (o in activeBluetoothPeripheral.services[servicesIndex].characteristics) {
					if (G5_Authentication_Characteristic_UUID.indexOf((o.uuid as String).toUpperCase()) > -1) {
						break;
					}
					G5AuthenticationCharacteristicsIndex++;
				}
				for each (o in activeBluetoothPeripheral.services[servicesIndex].characteristics) {
					if (G5_Communication_Characteristic_UUID.indexOf((o.uuid as String).toUpperCase()) > -1) {
						break;
					}
					G5CommunicationCharacteristicsIndex++;
				}
				for each (o in activeBluetoothPeripheral.services[servicesIndex].characteristics) {
					if (G5_Control_Characteristic_UUID.indexOf((o.uuid as String).toUpperCase()) > -1) {
						break;
					}
					G5ControlCharacteristicsIndex++;
				}
				G5AuthenticationCharacteristic = event.peripheral.services[servicesIndex].characteristics[G5AuthenticationCharacteristicsIndex];
				G5CommunicationCharacteristic = event.peripheral.services[servicesIndex].characteristics[G5CommunicationCharacteristicsIndex];
				G5ControlCharacteristic = event.peripheral.services[servicesIndex].characteristics[G5ControlCharacteristicsIndex];
				myTrace("subscribing to G5AuthenticationCharacteristic");
				
				if (!activeBluetoothPeripheral.subscribeToCharacteristic(G5AuthenticationCharacteristic))
				{
					myTrace("Subscribe to characteristic failed due to invalid adapter state.");
				}
			} else if (BlueToothDevice.isBluKon()) {
				myTrace("looping through services to find service " + HM_10_SERVICE_BLUKON);
				for each (o in activeBluetoothPeripheral.services) {
					if (HM_10_SERVICE_BLUKON.indexOf((o.uuid as String).toUpperCase()) > -1) {
						myTrace("found service " + HM_10_SERVICE_BLUKON + ", index = " + servicesIndex);
						break;
					}
					servicesIndex++;
				}
				myTrace("looping through service to find BC_desiredReceiveCharacteristicUUID");
				for each (o in activeBluetoothPeripheral.services[servicesIndex].characteristics) {
					if (BC_desiredReceiveCharacteristicUUID.indexOf((o.uuid as String).toUpperCase()) > -1) {
						myTrace("found service " + BC_desiredReceiveCharacteristicUUID + ", index = " + BC_desiredReceiveCharacteristicIndex);
						break;
					}
					BC_desiredReceiveCharacteristicIndex++;
				}
				myTrace("looping through service to find BC_desiredTransmitCharacteristicUUID");
				for each (o in activeBluetoothPeripheral.services[servicesIndex].characteristics) {
					if (BC_desiredTransmitCharacteristicUUID.indexOf((o.uuid as String).toUpperCase()) > -1) {
						myTrace("found service " + BC_desiredTransmitCharacteristicUUID + ", index = " + BC_desiredTransmitCharacteristicIndex);
						break;
					}
					BC_desiredTransmitCharacteristicIndex++;
				}
				BC_desiredReceiveCharacteristic = event.peripheral.services[servicesIndex].characteristics[BC_desiredReceiveCharacteristicIndex];
				BC_desiredTransmitCharacteristic = event.peripheral.services[servicesIndex].characteristics[BC_desiredTransmitCharacteristicIndex];
				myTrace("subscribing to BC_desiredReceiveCharacteristic");
				
				if (!activeBluetoothPeripheral.subscribeToCharacteristic(BC_desiredReceiveCharacteristic))
				{
					myTrace("Subscribe to characteristic failed due to invalid adapter state.");
				}
			} else if (BlueToothDevice.isDexcomG4()) {
				for each (o in activeBluetoothPeripheral.services) {
					if (HM_10_SERVICE_G4.indexOf(o.uuid as String) > -1) {
						myTrace("peripheral_discoverCharacteristicsHandler, found service " + HM_10_SERVICE_G4);
						break;
					}
					servicesIndex++;
				}
				for each (o in activeBluetoothPeripheral.services[servicesIndex].characteristics) {
					if (HM_RX_TX_G4.indexOf(o.uuid as String) > -1) {
						myTrace("peripheral_discoverCharacteristicsHandler, found characteristic " + HM_RX_TX_G4);
						break;
					}
					G4CharacteristicsIndex++;
				}
				G4characteristic = event.peripheral.services[servicesIndex].characteristics[G4CharacteristicsIndex];
				myTrace("subscribing to G4characteristic");
				if (!activeBluetoothPeripheral.subscribeToCharacteristic(G4characteristic))
				{
					myTrace("Subscribe to characteristic failed due to invalid adapter state.");
				}
			} else if (BlueToothDevice.isBlueReader()) {
				myTrace("in peripheral_discoverCharacteristicsHandler, handling bluereader, search for servicesIndex");
				for each (o in activeBluetoothPeripheral.services) {
					if (uuids_BlueReader_Service.indexOf(o.uuid as String) > -1) {
						break;
					}
					servicesIndex++;
				}
				myTrace("in peripheral_discoverCharacteristicsHandler handling bluereader, servicesIndex = " + servicesIndex);

				myTrace("trying to find BlueReader_RX_Characteristic_UUID");
				for each (o in activeBluetoothPeripheral.services[servicesIndex].characteristics) {
					if (BlueReader_RX_Characteristic_UUID.toUpperCase().indexOf((o.uuid as String).toUpperCase()) > -1) {
						myTrace("found BlueReader_RX_Characteristic_UUID");
						break;
					}
					BlueReader_Rx_CharacteristicIndex++;
				}
				BlueReader_RX_Characteristic = event.peripheral.services[servicesIndex].characteristics[BlueReader_Rx_CharacteristicIndex];

				myTrace("trying to find BlueReader_TX_Characteristic_UUID");
				for each (o in activeBluetoothPeripheral.services[servicesIndex].characteristics) {
					if (BlueReader_TX_Characteristic_UUID.toUpperCase().indexOf((o.uuid as String).toUpperCase()) > -1) {
						myTrace("found BlueReader_TX_Characteristic_UUID");
						break;
					}
					BlueReader_Tx_CharacteristicIndex++;
				}
				BlueReader_TX_Characteristic = event.peripheral.services[servicesIndex].characteristics[BlueReader_Tx_CharacteristicIndex];

				myTrace("subscribing to BlueReader_RX_Characteristic");
				if (!activeBluetoothPeripheral.subscribeToCharacteristic(BlueReader_RX_Characteristic))
				{
					myTrace("Subscribe to BlueReader_RX_Characteristic failed due to invalid adapter state.");
				}
			}
		}
		
		public static function writeG4Characteristic(value:ByteArray):void {
			if (!activeBluetoothPeripheral.writeValueForCharacteristic(G4characteristic, value)) {
				myTrace("ackG4CharacteristicUpdate writeValueForCharacteristic failed");
			}
		}
		
		public static function writeBlueReaderCharacteristic(value:ByteArray):void {
			if (!activeBluetoothPeripheral.writeValueForCharacteristic(BlueReader_TX_Characteristic, value)) {
				myTrace("writeBlueReacherCharacteristic writeValueForCharacteristic failed");
			}
		}
		
		private static function peripheral_characteristic_updatedHandler(event:CharacteristicEvent):void {
			myTrace("peripheral_characteristic_updatedHandler characteristic uuid = " + getCharacteristicName(event.characteristic.uuid) +
				" with byte 0 = " + event.characteristic.value[0] + " decimal.");
			
			var blueToothServiceEvent:BlueToothServiceEvent = new BlueToothServiceEvent(BlueToothServiceEvent.CHARACTERISTIC_UPDATE);
			_instance.dispatchEvent(blueToothServiceEvent);
			
			//now start reading the values
			var value:ByteArray = event.characteristic.value;
			var packetlength:int = value.readUnsignedByte();
			if (packetlength == 0) {
				myTrace("data packet received from transmitter with length 0");
			} else {
				value.position = 0;
				value.endian = Endian.LITTLE_ENDIAN;
				myTrace("data packet received from transmitter : " + Utilities.UniqueId.bytesToHex(value));
				value.position = 0;
				if (BlueToothDevice.isDexcomG5()) {
					processG5TransmitterData(value, event.characteristic);
				} else if (BlueToothDevice.isBluKon()) {
					processBLUKONTransmitterData(value);
				} else if (BlueToothDevice.isDexcomG4()) {
					processG4TransmitterData(value);
				} else if (BlueToothDevice.isBlueReader()) {
					processBlueReaderTransmitterData(value);
				} else {
					myTrace("in peripheral_characteristic_updatedHandler, device type not known");
				}
			}
		}
		
		private static function peripheral_characteristic_writeHandler(event:CharacteristicEvent):void {
			myTrace("peripheral_characteristic_writeHandler " + getCharacteristicName(event.characteristic.uuid));
			if (BlueToothDevice.isDexcomG4()) {
				_instance.dispatchEvent(new BlueToothServiceEvent(BlueToothServiceEvent.BLUETOOTH_DEVICE_CONNECTION_COMPLETED));
			}
		}
		
		private static function peripheral_characteristic_writeErrorHandler(event:CharacteristicEvent):void {
			myTrace("peripheral_characteristic_writeErrorHandler"  + getCharacteristicName(event.characteristic.uuid));
			if (event.error != null)
				myTrace("event.error = " + event.error);
			myTrace("event.errorCode = " + event.errorCode); 
		}
		
		private static function peripheral_characteristic_errorHandler(event:CharacteristicEvent):void {
			myTrace("peripheral_characteristic_errorHandler"  + getCharacteristicName(event.characteristic.uuid));
		}
		
		private static function peripheral_characteristic_subscribeHandler(event:CharacteristicEvent):void {
			myTrace("peripheral_characteristic_subscribeHandler success: " + getCharacteristicName(event.characteristic.uuid));
			if (BlueToothDevice.isDexcomG5()) {
				if (event.characteristic.uuid.toUpperCase() == G5_Control_Characteristic_UUID.toUpperCase()) {
					getSensorData();
				} else {
					fullAuthenticateG5();
				}
			} else if (BlueToothDevice.isBluKon()) {
				if (event.characteristic.uuid.toUpperCase() == BC_desiredReceiveCharacteristicUUID.toUpperCase()) {
				}
			} else if (!BlueToothDevice.alwaysScan()) {
				_instance.dispatchEvent(new BlueToothServiceEvent(BlueToothServiceEvent.BLUETOOTH_DEVICE_CONNECTION_COMPLETED));
			}
		}
		
		private static function peripheral_characteristic_subscribeErrorHandler(event:CharacteristicEvent):void {
			myTrace("peripheral_characteristic_subscribeErrorHandler: " + getCharacteristicName(event.characteristic.uuid));
			myTrace("event.error = " + event.error);
			myTrace("event.errorcode  = " + event.errorCode);
			if ((new Date()).valueOf() - timeStampOfLastDeviceNotPairedForBlukon > 4.75 * 60 * 1000) {
				if (BlueToothDevice.isBluKon()) {
					if (event.characteristic.uuid.toUpperCase() == BC_desiredReceiveCharacteristicUUID.toUpperCase()
						&&
						event.errorCode == 15 
					) {
						myTrace("blukon not bonded, dispatching DEVICE_NOT_PAIRED event");
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
		 * Disconnects the active bluetooth peripheral if any and sets it to null(otherwise returns without doing anything)<br>
		 */
		public static function forgetActiveBluetoothPeripheral():void {
			myTrace("in forgetActiveBluetoothPeripheral");
			if (activeBluetoothPeripheral == null)
				return;
			
			BluetoothLE.service.centralManager.disconnect(activeBluetoothPeripheral);
			activeBluetoothPeripheral = null;
			myTrace("bluetooth device forgotten");
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
		
		private static function processG5TransmitterData(buffer:ByteArray, characteristic:Characteristic):void {
			myTrace("in processG5TransmitterData");
			buffer.endian = Endian.LITTLE_ENDIAN;
			var code:int = buffer.readByte();
			switch (code) {
				case 5:
					authStatus = new AuthStatusRxMessage(buffer);
					myTrace("AuthStatusRxMessage created = " + UniqueId.byteArrayToString(authStatus.byteSequence));
					if (!authStatus.bonded) {
						myTrace("not bonded, dispatching DEVICE_NOT_PAIRED event");
						var blueToothServiceEvent:BlueToothServiceEvent = new BlueToothServiceEvent(BlueToothServiceEvent.DEVICE_NOT_PAIRED);
						_instance.dispatchEvent(blueToothServiceEvent);
					}
					myTrace("Subscribing to G5ControlCharacteristic");
					if (!activeBluetoothPeripheral.subscribeToCharacteristic(G5ControlCharacteristic))
					{
						myTrace("Subscribe to characteristic failed due to invalid adapter state.");
					}
					break;
				case 3:
					buffer.position = 0;
					var authChallenge:AuthChallengeRxMessage = new AuthChallengeRxMessage(buffer);
					if (authRequest == null) {
						authRequest = new AuthRequestTxMessage(getTokenSize());
					}
					var key:ByteArray = cryptKey();
					var challengeHash:ByteArray = calculateHash(authChallenge.challenge);
					if (challengeHash != null) {
						var authChallengeTx:AuthChallengeTxMessage = new AuthChallengeTxMessage(challengeHash);
						if (!activeBluetoothPeripheral.writeValueForCharacteristic(characteristic, authChallengeTx.byteSequence)) {
							myTrace("processG5TransmitterData case 3 writeValueForCharacteristic failed");
						}
					} else {
						myTrace("challengehash == null");
					}
					break;
				case 47:
					var sensorRx:SensorRxMessage = new SensorRxMessage(buffer);
					var sensor_battery_level:Number = 0;
					if (sensorRx.transmitterStatus.toString() == TransmitterStatus.BRICKED) {
						sensor_battery_level = 206; //will give message "EMPTY"
					} else if (sensorRx.transmitterStatus.toString() == TransmitterStatus.LOW) {
						sensor_battery_level = 209; //will give message "LOW"
					} else {
						sensor_battery_level = 216; //no message, just system status "OK"
					}
					
					if ((new Date()).valueOf() - new Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_G5_BATTERY_FROM_MARKER)) > BluetoothService.BATTERY_READ_PERIOD_MS) {
						doBatteryInfoRequestMessage(characteristic);
					} else {
						doDisconnectMessageG5(characteristic);
					}
					
					timeStampOfLastG5Reading = (new Date()).valueOf();
					var blueToothServiceEvent:BlueToothServiceEvent = new BlueToothServiceEvent(BlueToothServiceEvent.TRANSMITTER_DATA);
					blueToothServiceEvent.data = new TransmitterDataG5Packet(sensorRx.unfiltered, sensorRx.filtered, sensor_battery_level, sensorRx.timestamp, sensorRx.transmitterStatus);
					_instance.dispatchEvent(blueToothServiceEvent);
					break;
				case 35:
					buffer.position = 0;
					if (!setStoredBatteryBytesG5(buffer)) {
						myTrace("Could not save out battery data!");
					}
					doDisconnectMessageG5(characteristic);
					break;
				case 75:
					doDisconnectMessageG5(characteristic);
					break;
				default:
					myTrace("processG5TransmitterData unknown code received : " + code);
					break;
			}
		}
		
		public static function setStoredBatteryBytesG5(data:ByteArray):Boolean {
			myTrace("Store: BatteryRX dbg: " + UniqueId.bytesToHex((data)));
			if (data.length < 10) {
				myTrace("Store: BatteryRX dbg, data.length < 10, no further processing");
				return false;
			}
			var batteryInfoRxMessage:BatteryInfoRxMessage = new BatteryInfoRxMessage(data);
			myTrace("Saving battery data: " + batteryInfoRxMessage.toString());
			CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_G5_BATTERY_MARKER, UniqueId.bytesToHex(data));
			CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_G5_RESIST, new Number(batteryInfoRxMessage.resist).toString());
			CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_G5_RUNTIME, new Number(batteryInfoRxMessage.runtime).toString());
			CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_G5_TEMPERATURE, new Number(batteryInfoRxMessage.temperature).toString());
			CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_G5_VOLTAGEA, new Number(batteryInfoRxMessage.voltagea).toString());
			CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_G5_VOLTAGEB, new Number(batteryInfoRxMessage.voltageb).toString());
			return true;
		}
		
		private static function doDisconnectMessageG5(characteristic:Characteristic):void {
			myTrace("in doDisconnectMessageG5");
			if (activeBluetoothPeripheral != null) {
				if (!BluetoothLE.service.centralManager.disconnect(activeBluetoothPeripheral)) {
					myTrace("doDisconnectMessageG5 failed");
				}
			}
			forgetActiveBluetoothPeripheral();
			myTrace("doDisconnectMessageG5 finished");
		}
		
		private static function doBatteryInfoRequestMessage(characteristic:Characteristic):void {
			myTrace("doBatteryInfoRequestMessage");
			var batteryInfoTxMessage:BatteryInfoTxMessage =  new BatteryInfoTxMessage();
			if (!activeBluetoothPeripheral.writeValueForCharacteristic(characteristic, batteryInfoTxMessage.byteSequence)) {
				myTrace("doBatteryInfoRequestMessage writeValueForCharacteristic failed");
			}
		}
		
		public static function calculateHash(data:ByteArray):ByteArray {
			if (data.length != 8) {
				myTrace("Data length should be exactly 8.");
				return null;
			}
			var key:ByteArray = cryptKey();
			if (key == null)
				return null;
			var doubleData:ByteArray = new ByteArray();
			doubleData.writeBytes(data);
			doubleData.writeBytes(data);
			var aesBytes:ByteArray = BackgroundFetch.AESEncryptWithKey(key, doubleData);
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
			var strRecCmd:String = Utilities.UniqueId.bytesToHex(buffer).toLowerCase();
			buffer.position = 0;
			var blueToothServiceEvent:BlueToothServiceEvent  = null;
			var gotLowBat:Boolean = false;
			
			////////code copied form xdripplus, commit e429b3db0bcd059cd8bb517bf15cabe705436ed2
			var cmdFound:int = 0;
			
			//BluKon code by gregorybel
			myTrace("in processBLUKONTransmitterData, BluKon data: " + strRecCmd);
			
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
					
					//This command will be asked only one time after first connect and never again
					if (!m_gotOneTimeUnknownCmd) {
						blukonCurrentCommand = "010d0b00";
						myTrace("in processBLUKONTransmitterData, getUnknownCmd1: " + blukonCurrentCommand);
					} else {
						if ((new Date()).valueOf() - new Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TIME_STAMP_LAST_SENSOR_AGE_CHECK_IN_MS)) > GET_SENSOR_AGE_DELAY_IN_SECONDS * 1000) {
							// do something only once every 4 hours
							blukonCurrentCommand = "010d0e0127";
							myTrace("in processBLUKONTransmitterData, getSensorAge");
						} else {
							if (true) {
								myTrace("in processBLUKONTransmitterData, getHistoricData (1)");
								blukonCurrentCommand = "010d0f02002b";
								m_blockNumber = 0;
							} else {
								blukonCurrentCommand = "010d0e0103"; 
								m_getNowGlucoseDataIndexCommand = true;//to avoid issue when gotNowDataIndex cmd could be same as getNowGlucoseData (case block=3)
								myTrace("in processBLUKONTransmitterData, getNowGlucoseDataIndexCommand");
							}
						}
					}
					
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

				m_gotOneTimeUnknownCmd = false;
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
				
				//decodeSerialNumber(buffer);
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
				
				//try asking each time m_gotOneTimeUnknownCmd = true;
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
				
				// calculate time delta to last valid BG reading
				var bgReadings:ArrayCollection = BgReading.latest(1);
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
					var delayedTrendIndex:int = m_currentTrendIndex;
					// ensure to have min 3 mins distance to last reading to avoid doible draws (even if they are distict)
					if ( m_minutesBack > 17 ) {
						m_minutesBack = 15;
					} else if ( m_minutesBack > 12 ) {
						m_minutesBack = 10;
					} else if ( m_minutesBack > 7 ) {
						m_minutesBack = 5;
					}
					myTrace("in processBLUKONTransmitterData, read " + m_minutesBack + " mins old trend data");
					for ( var i:int = 0 ; i < m_minutesBack ; i++ ) {
						if ( --delayedTrendIndex < 0)
							delayedTrendIndex = 15;
					}
					var delayedBlockNumber:String = blockNumberForNowGlucoseDataDelayed(delayedTrendIndex);
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
					var delayedTrendIndex:int = m_currentTrendIndex;
					for ( var i:int = 0 ; i < m_minutesBack ; i++ ) {
						if ( --delayedTrendIndex < 0)
							delayedTrendIndex = 15;
					}
					var delayedBlockNumber:String = blockNumberForNowGlucoseDataDelayed(delayedTrendIndex);
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
			myTrace("in processBlukonTransmitterData, recieved historic data, m_block_number = " + m_blockNumber);
			// We are looking for 43 blocks of 8 bytes.
			// The bluekon will send them as 21 blocks of 16 bytes, and the last one of 8 bytes. 
			// The packet will look like "0x8b 0xdf 0xblocknumber 0x02 DATA" (so data starts at place 4)
			if(m_blockNumber > 42) {
				myTrace("in processBlukonTransmitterData, recieved historic data, but block number is too big " + m_blockNumber);
				return;
			}
			
			var len:int = buffer.length - 4;
			buffer.position = 2;
			var buffer_at_2:int = buffer.readByte();
			myTrace("in processBlukonTransmitterData, len = " + len +" " + len + " blocknum " + buffer_at_2);
			
			if(buffer_at_2 != m_blockNumber) {
				myTrace("in processBlukonTransmitterData, We have recieved a bad block number buffer[2] = " + buffer_at_2 + " m_blockNumber = " + m_blockNumber);
				return;
			}
			if(8 * m_blockNumber + len > m_full_data.length) {
				myTrace("in processBlukonTransmitterData, We have recieved too much data  m_blockNumber = " + m_blockNumber + " len = " + len + 
					" m_full_data.length = " + m_full_data.length);        	
				return;
			}
			
			buffer.position = 4;
			buffer.readBytes(m_full_data, 8 * m_blockNumber, len);
			m_blockNumber += len / 8;
			
			if(m_blockNumber >= 43) {
				blukonCurrentCommand = "010c0e00";
				myTrace("in processBlukonTransmitterData, Send sleep cmd");
				myTrace("in processBlukonTransmitterData, Full data that was recieved is " + Utilities.UniqueId.bytesToHex(m_full_data));
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
			
			myTrace("in blockNumberForNowGlucoseData, nowGlucoseOffset = " + nowGlucoseOffset);
			
			var nowGlucoseDataAsHexString:String = nowGlucoseIndex3.toString(16);
			myTrace("in blockNumberForNowGlucoseData, nowGlucoseDataAsHexString =  " + nowGlucoseDataAsHexString);
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
		

		private static function getGlucose(rawGlucose:Number):Number {
			//LIBRE_MULTIPLIER
			return (rawGlucose * 117.64705);
		}
		
		public static function nowGetGlucoseValue(input:ByteArray):Number {
			input.position = 3 + nowGlucoseOffset;
			var curGluc:Number;
			var rawGlucose:Number;
			
			// grep 2 bytes with BG data from input bytearray, mask out 12 LSB bits and rescale for xDrip+
			//rawGlucose = (input[3+m_nowGlucoseOffset+1]&0x0F)*16 + input[3+m_nowGlucoseOffset];
			var value1:int = input.readByte();
			var value2:int = input.readByte();
			rawGlucose = ((value2 & 0x0F)<<8) | (value1 & 0xFF);
			myTrace("in nowGetGlucoseValue rawGlucose=" + rawGlucose);
			
			// rescale
			curGluc = getGlucose(rawGlucose);
			
			return(curGluc);
		}
		


		
		/**
		 * sends the command to  BC_desiredTransmitCharacteristic and also assigns blukonCurrentCommand to command
		 */
		private static function sendCommand(command:String):void {
			if (!activeBluetoothPeripheral.writeValueForCharacteristic(BC_desiredTransmitCharacteristic, Utilities.UniqueId.hexStringToByteArray(command))) {
				myTrace("send " + command + " failed");
			} else {
				myTrace("send " + command + " succesfull");
			}
		}
		
		public static function processBlueReaderTransmitterData(buffer:ByteArray):void {
			buffer.position = 0;
			buffer.endian = Endian.LITTLE_ENDIAN;
			myTrace("in processBlueReaderTransmitterData data packet received from transmitter : " + Utilities.UniqueId.bytesToHex(buffer));

			buffer.position = 0;
			var bufferAsString:String = buffer.readUTFBytes(buffer.length);
			myTrace("in processBlueReaderTransmitterData buffer as string =  " + bufferAsString);
			if (buffer.length >= 7) {
				if (bufferAsString.toUpperCase().indexOf("BATTERY") > -1) {
					var blueToothServiceEvent:BlueToothServiceEvent = new BlueToothServiceEvent(BlueToothServiceEvent.TRANSMITTER_DATA);
					blueToothServiceEvent.data = new TransmitterDataBlueReaderBatteryPacket();
					_instance.dispatchEvent(blueToothServiceEvent);
					return;
				}
			}
			
			myTrace("in processBlueReaderTransmitterData, it's not a battery message, continue processing");
			var bufferAsStringSplitted:Array = bufferAsString.split(/\s/);
			var raw_data:Number = new Number(bufferAsStringSplitted[0]);
			var filtered_data:Number = new Number(bufferAsStringSplitted[0]);

			if (isNaN(raw_data)) {
				myTrace("in processBlueReaderTransmitterData, data doesn't start with an Integer, no further processing");
				return;
			}
			myTrace("in processBlueReaderTransmitterData, raw_data = " + raw_data.toString())
			
			var sensor_battery_level:Number; 
			var bridge_battery_level:Number;
			if (bufferAsStringSplitted.length > 1) {
				sensor_battery_level = new Number(bufferAsStringSplitted[1]);
				myTrace("in processBlueReaderTransmitterData, sensor_battery_level = " + sensor_battery_level.toString());
				if (bufferAsStringSplitted.length > 2) {
					bridge_battery_level = new Number(bufferAsStringSplitted[2]);
					myTrace("in processBlueReaderTransmitterData, fsl_battery_level = " + bridge_battery_level.toString());
					if (bufferAsStringSplitted.length > 3) {
						FSLSensorAGe = new Number(bufferAsStringSplitted[3]);
						myTrace("in processBlueReaderTransmitterData, sensorAge = " + FSLSensorAGe.toString());
					}
				}
			}
			myTrace("in processBlueReaderTransmitterData, dispatching transmitter data");
			var blueToothServiceEvent:BlueToothServiceEvent = new BlueToothServiceEvent(BlueToothServiceEvent.TRANSMITTER_DATA);
			blueToothServiceEvent.data = new TransmitterDataBlueReaderPacket(raw_data, sensor_battery_level, bridge_battery_level, FSLSensorAGe, (new Date()).valueOf());
			_instance.dispatchEvent(blueToothServiceEvent);
			FSLSensorAGe = Number.NaN;
		}
		
		private static function processG4TransmitterData(buffer:ByteArray):void {
			myTrace("in processG4TransmitterData");
			buffer.endian = Endian.LITTLE_ENDIAN;
			var packetLength:int = buffer.readUnsignedByte();
			var packetType:int = buffer.readUnsignedByte();//0 = data packet, 1 =  TXID packet, 0xF1 (241 if read as unsigned int) = Beacon packet
			var txID:Number;
			var xBridgeProtocolLevel:Number
			switch (packetType) {
				case 0:
					//data packet
					var rawData:Number = buffer.readInt();
					var filteredData:Number = buffer.readInt();
					var transmitterBatteryVoltage:Number = buffer.readUnsignedByte();
					
					//following only if the name of the device contains "bridge", if it' doesnt contain bridge, then it's an xdrip (old) and doesn't have those bytes' +
					//or if packetlenth == 17, why ? because it could be a drip with xbridge software but still with a name xdrip, because it was originally an xdrip that was later on overwritten by the xbridge software, in that case the name will still by xdrip and not xbridge
					if (BlueToothDevice.isXBridge() || packetLength == 17) {
						var bridgeBatteryPercentage:Number = buffer.readUnsignedByte();
						txID = buffer.readInt();
						xBridgeProtocolLevel = buffer.readUnsignedByte();
						
						var blueToothServiceEvent:BlueToothServiceEvent = new BlueToothServiceEvent(BlueToothServiceEvent.TRANSMITTER_DATA);
						blueToothServiceEvent.data = new TransmitterDataXBridgeDataPacket(rawData, filteredData, transmitterBatteryVoltage, bridgeBatteryPercentage, decodeTxID(txID));
						_instance.dispatchEvent(blueToothServiceEvent);
					} else {
						var blueToothServiceEvent:BlueToothServiceEvent = new BlueToothServiceEvent(BlueToothServiceEvent.TRANSMITTER_DATA);
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
					
					var blueToothServiceEvent:BlueToothServiceEvent = new BlueToothServiceEvent(BlueToothServiceEvent.TRANSMITTER_DATA);
					blueToothServiceEvent.data = new TransmitterDataXBridgeBeaconPacket(decodeTxID(txID));
					_instance.dispatchEvent(blueToothServiceEvent);
					
					xBridgeProtocolLevel = buffer.readUnsignedByte();//not needed for the moment
					break;
				default:
					myTrace("processG4TransmitterData unknown packetType received : " + packetType);
					warnUnknownG4PacketType(packetType);
			}
		}
		
		public static function warnUnknownG4PacketType(packetType:int):void {
			if (BackgroundFetch.appIsInBackground()) {
				return;
			}
			if ((new Date()).valueOf() - new Number(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_TIMESTAMP_SINCE_LAST_INFO_UKNOWN_PACKET_TYPE)) < 30 * 60 * 1000)
				return;
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_DONTASKAGAIN_ABOUT_UNKNOWN_PACKET_TYPE) ==  "true") {
				return;
			}
			if (listOfSeenInvalidPacketTypes.indexOf(packetType) > -1) {
				unsupportedPacketType = packetType;
				var alert:DialogView = Dialog.service.create(
					new AlertBuilder()
					.setTitle("xDrip Alert")
					.setMessage(ModelLocator.resourceManagerInstance.getString('bluetoothservice', "unknownpackettypeinfo"))
					.addOption(ModelLocator.resourceManagerInstance.getString('bluetoothservice', "sendemail"), DialogAction.STYLE_POSITIVE, 0)
					.addOption(ModelLocator.resourceManagerInstance.getString('bluetoothservice', "notnow"), DialogAction.STYLE_POSITIVE, 2)
					.addOption(ModelLocator.resourceManagerInstance.getString('bluetoothservice', "dontaskagain"), DialogAction.STYLE_POSITIVE, 3)
					.addOption(ModelLocator.resourceManagerInstance.getString("general","cancel"), DialogAction.STYLE_CANCEL, 1)
					.build()
				);
				alert.addEventListener(DialogViewEvent.CLOSED, sendemail);
				DialogService.addDialog(alert);
			}
		}
		
		private static function sendemail(ev:DialogViewEvent):void {
			if (ev != null) {
				if (ev.index == 1) {
					return;
				} else if (ev.index == 2) {
					LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_TIMESTAMP_SINCE_LAST_INFO_UKNOWN_PACKET_TYPE, (new Date()).valueOf().toString());
					return;
				} else if (ev.index == 3) {
					LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_DONTASKAGAIN_ABOUT_UNKNOWN_PACKET_TYPE, "true");
					return;
				}
			}
			
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_TIMESTAMP_SINCE_LAST_INFO_UKNOWN_PACKET_TYPE, (new Date()).valueOf().toString());
			var body:String = "Hi,\n\nRequest for support wxl. Unsupported packetType =  " + unsupportedPacketType + ".\n\nregards.";
			Message.service.sendMailWithOptions("Request for supported wxl", body, "xdrip@proximus.be","","",null,false);
		}

		
		private static function myTrace(log:String):void {
			Trace.myTrace("BluetoothService.as", log);
		}
		
		/**
		 * returns true if activeBluetoothPeripheral != null
		 */
		public static function bluetoothPeripheralActive():Boolean {
			return activeBluetoothPeripheral != null;
		}
		
		public static function fullAuthenticateG5():void {
			myTrace("in fullAuthenticateG5");
			if (G5AuthenticationCharacteristic != null) {
				sendAuthRequestTxMessage(G5AuthenticationCharacteristic);
			} else {
				myTrace("fullAuthenticate: authCharacteristic is NULL!");
			}
		}
		
		private static function sendAuthRequestTxMessage(characteristic:Characteristic):void {
			authRequest = new AuthRequestTxMessage(getTokenSize());
			
			if (!activeBluetoothPeripheral.writeValueForCharacteristic(characteristic, authRequest.byteSequence)) {
				myTrace("sendAuthRequestTxMessage writeValueForCharacteristic failed");
			}
		}
		
		private static function getTokenSize():Number {
			return 8;
		}
		
		public static function getSensorData():void {
			myTrace("getSensorData");
			var sensorTx:SensorTxMessage = new SensorTxMessage();
			if (!activeBluetoothPeripheral.writeValueForCharacteristic(G5ControlCharacteristic, sensorTx.byteSequence)) {
				myTrace("getSensorData writeValueForCharacteristic G5CommunicationCharacteristic failed");
			}
		}
		
		/**
		 * to be called when performfetch is received, this will actually start the rescan 
		 */
		public static function startRescan(event:Event):void {
			if (!(BluetoothLE.service.centralManager.state == BluetoothLEState.STATE_ON)) {
				myTrace("In rescanAtPerformFetch but bluetooth is not on");
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
		
		public static function getCharacteristicName(uuid:String):String {
			if (uuid.toUpperCase() == G5_Communication_Characteristic_UUID.toUpperCase()) {
				return "G5_Communication_Characteristic_UUID";
			} else if (uuid.toUpperCase() == G5_Authentication_Characteristic_UUID.toUpperCase()) {
				return "G5_Authentication_Characteristic_UUID";
			} else if (uuid.toUpperCase() == G5_Control_Characteristic_UUID.toUpperCase()) {
				return "G5_Control_Characteristic_UUID";
			} else if (uuid.toUpperCase() == BC_desiredTransmitCharacteristicUUID.toUpperCase()) {
				return "BC_desiredTransmitCharacteristicUUID";
			} else if (uuid.toUpperCase() == BC_desiredReceiveCharacteristicUUID.toUpperCase()) {
				return "BC_desiredReceiveCharacteristicUUID";
			} else if (uuid.toUpperCase() == BlueReader_RX_Characteristic_UUID.toUpperCase()) {
				return "BlueReader_RX_Characteristic_UUID";
			} else if (uuid.toUpperCase() == BlueReader_TX_Characteristic_UUID.toUpperCase()) {
				return "BlueReader_TX_Characteristic_UUID";
			} else if (uuid.toUpperCase() == HM_RX_TX_G4.toUpperCase()) {
				return "HM_RX_TX_G4";
			} 
			return uuid + ", unknown characteristic uuid";
		}
		
		private static function isSensorReady(sensorStatusByte:int):Boolean {
			if (!ModelLocator.IS_PRODUCTION)
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
				case 3:
					sensorStatusString = "ready";
					ret = true;
					break;
				case 4:
					sensorStatusString = "expired";
					ret = true;
					break;
				case 5:
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
				DialogService.openSimpleDialog(ModelLocator.resourceManagerInstance.getString("settingsview","warning"),
					ModelLocator.resourceManagerInstance.getString("bluetoothservice","cantusesensor") + " " + sensorStatusString,
					60);
			}
			return ret;
		}
		

	}
}