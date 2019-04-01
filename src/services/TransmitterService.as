package services
{
	import com.distriqt.extension.notifications.Notifications;
	import com.distriqt.extension.notifications.builders.NotificationBuilder;
	import com.distriqt.extension.notifications.events.NotificationEvent;
	import com.spikeapp.spike.airlibrary.SpikeANE;
	
	import flash.events.EventDispatcher;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	import database.BgReading;
	import database.CGMBlueToothDevice;
	import database.CommonSettings;
	import database.Sensor;
	
	import events.BlueToothServiceEvent;
	import events.NotificationServiceEvent;
	import events.SpikeEvent;
	import events.TransmitterServiceEvent;
	
	import feathers.controls.Alert;
	import feathers.controls.TextInput;
	import feathers.layout.HorizontalAlign;
	
	import model.ModelLocator;
	import model.TransmitterDataBluKonPacket;
	import model.TransmitterDataBlueReaderBatteryPacket;
	import model.TransmitterDataBlueReaderPacket;
	import model.TransmitterDataG5G6Packet;
	import model.TransmitterDataTransmiter_PLPacket;
	import model.TransmitterDataXBridgeBeaconPacket;
	import model.TransmitterDataXBridgeDataPacket;
	import model.TransmitterDataXBridgeRDataPacket;
	import model.TransmitterDataXdripDataPacket;
	
	import services.bluetooth.CGMBluetoothService;
	
	import starling.events.Event;
	
	import ui.popups.AlertManager;
	import ui.screens.display.LayoutFactory;
	
	import utils.BadgeBuilder;
	import utils.Trace;
	
	/**
	 * transmitter service handles all transmitterdata received from BlueToothService<br>
	 * It will handle TransmitterData .. packets (see children of TransmitterData class), create bgreadings ..<br>
	 * If no sensor active then no bgreading will be created<br>
	 * init must be called to start the service
	 */
	public class TransmitterService extends EventDispatcher
	{
		[ResourceBundle("transmitterservice")]
		[ResourceBundle("transmitterscreen")]
		[ResourceBundle("globaltranslations")]
		
		private static var _instance:TransmitterService = new TransmitterService();
		
		public static function get instance():TransmitterService
		{
			return _instance;
		}
		
		private static var initialStart:Boolean = true;
		/**
		 * timestamp of last received xdrip packet, in ms. Not for xbridge.
		 */
		private static var lastxDripPacketTime:Number = 0;
		
		private static var timeStampSinceLastG5G6BadlyPlacedBatteriesInfo:Number = 0;

		private static var transmitterIDTextInput:TextInput;
		
		public function TransmitterService()
		{
			if (_instance != null) {
				throw new Error("TransmitterService class  constructor can not be used");	
			}
		}
		
		public static function init():void {
			if (!initialStart)
				return;
			else
				initialStart = false;
			
			Spike.instance.addEventListener(SpikeEvent.APP_HALTED, onHaltExecution);
			CGMBluetoothService.instance.addEventListener(BlueToothServiceEvent.TRANSMITTER_DATA, transmitterDataReceived);
			NotificationService.instance.addEventListener(NotificationServiceEvent.NOTIFICATION_EVENT, notificationReceived);
			NotificationService.instance.addEventListener(NotificationServiceEvent.NOTIFICATION_SELECTED_EVENT, notificationReceived);
		}
		
		public static function dispatchBgReadingReceivedEvent():void {
			_instance.dispatchEvent(new TransmitterServiceEvent(TransmitterServiceEvent.BGREADING_RECEIVED));
		}
		
		public static function dispatchLastBgReadingReceivedEvent():void {
			_instance.dispatchEvent(new TransmitterServiceEvent(TransmitterServiceEvent.LAST_BGREADING_RECEIVED));
		}
		
		private static function transmitterDataReceived(be:BlueToothServiceEvent):void {
			
			var value:ByteArray;
			var transmitterServiceEvent:TransmitterServiceEvent;
			var notificationBuilderG5G6BatteryInfo:NotificationBuilder;
			var lastBgReading:BgReading;
			
			if (be.data == null)
				return;//should never be null actually
			else {
				if (be.data is TransmitterDataXBridgeBeaconPacket) {
					myTrace("in transmitterDataReceived, received TransmitterDataXBridgeBeaconPacket");
					var transmitterDataBeaconPacket:TransmitterDataXBridgeBeaconPacket = be.data as TransmitterDataXBridgeBeaconPacket;
					if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TRANSMITTER_ID) == "00000" 
						&&
						transmitterDataBeaconPacket.TxID == "00000") {
						myTrace("in transmitterDataReceived, no transmitter id stored in xbridge and no transmitter id set in app, requesting transmitter id to user");
						Notifications.service.cancel(NotificationService.ID_FOR_ENTER_TRANSMITTER_ID);
						Notifications.service.notify(
							new NotificationBuilder()
							.setCount(BadgeBuilder.getAppBadge())
							.setId(NotificationService.ID_FOR_ENTER_TRANSMITTER_ID)
							.setAlert(ModelLocator.resourceManagerInstance.getString("transmitterservice","enter_transmitter_id_dialog_title"))
							.setTitle(ModelLocator.resourceManagerInstance.getString("transmitterservice","enter_transmitter_id"))
							.setBody(" ")
							.enableVibration(true)
							.enableLights(true)
							.build());
					} else if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TRANSMITTER_ID) == "00000" 
						&&
						transmitterDataBeaconPacket.TxID != "00000") {
						myTrace("storing transmitter id received from xbridge = " + transmitterDataBeaconPacket.TxID);
						CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_TRANSMITTER_ID, transmitterDataBeaconPacket.TxID.toUpperCase());
						value = new ByteArray();
						value.writeByte(0x02);
						value.writeByte(0xF0);
						CGMBluetoothService.writeToCharacteristic(value);
					} else if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TRANSMITTER_ID) != "00000" 
						&&
						transmitterDataBeaconPacket.TxID != CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TRANSMITTER_ID)) {
						value = new ByteArray();
						value.endian = Endian.LITTLE_ENDIAN;
						value.writeByte(0x06);
						value.writeByte(0x01);
						value.writeInt((CGMBluetoothService.encodeTxID(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TRANSMITTER_ID))));
						myTrace("calling BluetoothService.ackCharacteristicUpdate");
						CGMBluetoothService.writeToCharacteristic(value);
					} else {
						value = new ByteArray();
						value.writeByte(0x02);
						value.writeByte(0xF0);
						CGMBluetoothService.writeToCharacteristic(value);
					}
				} else if ((be.data is TransmitterDataXBridgeDataPacket) || (be.data is TransmitterDataXBridgeRDataPacket)) {
					var transmitterDataXBridgeDataPacket:TransmitterDataXBridgeDataPacket;
					if (be.data is TransmitterDataXBridgeDataPacket)
						transmitterDataXBridgeDataPacket = be.data as TransmitterDataXBridgeDataPacket;
					else 
						transmitterDataXBridgeDataPacket = be.data as TransmitterDataXBridgeRDataPacket;
					
					if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TRANSMITTER_ID) == "00000" 
						&&
						transmitterDataXBridgeDataPacket.TxID != "00000") {
						myTrace("storing transmitter id received from bluetooth device = " + transmitterDataXBridgeDataPacket.TxID);
						CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_TRANSMITTER_ID, transmitterDataXBridgeDataPacket.TxID.toUpperCase());
						value = new ByteArray();
						value.writeByte(0x02);
						value.writeByte(0xF0);
						CGMBluetoothService.writeToCharacteristic(value);
					} else if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TRANSMITTER_ID) != "00000" 
						&&
						transmitterDataXBridgeDataPacket.TxID != CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TRANSMITTER_ID)) {
						value = new ByteArray();
						value.endian = Endian.LITTLE_ENDIAN;
						value.writeByte(0x06);
						value.writeByte(0x01);
						value.writeInt((CGMBluetoothService.encodeTxID(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TRANSMITTER_ID))));
						myTrace("calling BluetoothService.ackCharacteristicUpdate");
						CGMBluetoothService.writeToCharacteristic(value);
					} else {
						value = new ByteArray();
						value.writeByte(0x02);
						value.writeByte(0xF0);
						CGMBluetoothService.writeToCharacteristic(value);
					}						

					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_BRIDGE_BATTERY_PERCENTAGE,transmitterDataXBridgeDataPacket.bridgeBatteryPercentage.toString());
					var readingTimeStamp:Number = (new Date()).valueOf();
					if (transmitterDataXBridgeDataPacket is TransmitterDataXBridgeRDataPacket) {
						readingTimeStamp = (transmitterDataXBridgeDataPacket as TransmitterDataXBridgeRDataPacket).timestamp;
					}
					BgReading.
						create(transmitterDataXBridgeDataPacket.rawData, transmitterDataXBridgeDataPacket.filteredData, readingTimeStamp)
						.saveToDatabaseSynchronous();
					
					transmitterServiceEvent = new TransmitterServiceEvent(TransmitterServiceEvent.BGREADING_RECEIVED);
					_instance.dispatchEvent(transmitterServiceEvent);
					transmitterServiceEvent = new TransmitterServiceEvent(TransmitterServiceEvent.LAST_BGREADING_RECEIVED);
					_instance.dispatchEvent(transmitterServiceEvent);

					if (CGMBlueToothDevice.isDexcomG4()) {
						CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_G4_TRANSMITTER_BATTERY_VOLTAGE,transmitterDataXBridgeDataPacket.transmitterBatteryVoltage.toString());
					}
				} else if (be.data is TransmitterDataXdripDataPacket) {
					var transmitterDataXdripDataPacket:TransmitterDataXdripDataPacket = be.data as TransmitterDataXdripDataPacket;
					if (((new Date()).valueOf() - lastxDripPacketTime) < 60000) {
						myTrace("in transmitterDataReceived , is TransmitterDataXdripDataPacket but lastPacketTime < 60 seconds ago, ignoring");
					} else {//it's an xdrip, with old software, 
						lastxDripPacketTime = (new Date()).valueOf();
						
						//store as bridge battery level value 0 in the common settings (to be synchronized)
						CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_BRIDGE_BATTERY_PERCENTAGE, "0");
						
						//store the transmitter battery level in the common settings (to be synchronized)
						CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_G4_TRANSMITTER_BATTERY_VOLTAGE, transmitterDataXdripDataPacket.transmitterBatteryVoltage.toString());
						//create and save bgreading
						BgReading.
							create(transmitterDataXdripDataPacket.rawData, transmitterDataXdripDataPacket.filteredData)
							.saveToDatabaseSynchronous();
						
						//dispatch the event that there's new data
						transmitterServiceEvent = new TransmitterServiceEvent(TransmitterServiceEvent.BGREADING_RECEIVED);
						_instance.dispatchEvent(transmitterServiceEvent);
						transmitterServiceEvent = new TransmitterServiceEvent(TransmitterServiceEvent.LAST_BGREADING_RECEIVED);
						_instance.dispatchEvent(transmitterServiceEvent);
					}
				} else if (be.data is TransmitterDataG5G6Packet) {
					var transmitterDataG5G6Packet:TransmitterDataG5G6Packet = be.data as TransmitterDataG5G6Packet;
					var badPlacedBatteriesTitle:String = "";
					var badPlacedBatteriesBody:String = "";
					
					//check special values filtered and unfiltered to detect dead battery
					if (transmitterDataG5G6Packet.filteredData == 2096896 && CGMBlueToothDevice.isDexcomG5()) {
						myTrace("in transmitterDataReceived, filteredData = 2096896, this indicates a dead G5 battery, no further processing");
						if (SpikeANE.appIsInForeground()) {
							AlertManager.showSimpleAlert
							(
								ModelLocator.resourceManagerInstance.getString("transmitterservice","dead_g5_battery"),
								ModelLocator.resourceManagerInstance.getString("transmitterservice","dead_g5_battery_info")
							);
							SpikeANE.vibrate();
						} else {
							var body1:String = ModelLocator.resourceManagerInstance.getString("transmitterservice","dead_g5_battery_info");
							if (body1 == null || body1 == "")
							{
								body1 = " ";
							}
							
							notificationBuilderG5G6BatteryInfo = new NotificationBuilder()
								.setCount(BadgeBuilder.getAppBadge())
								.setId(NotificationService.ID_FOR_DEAD_G5_BATTERY_INFO)
								.setAlert(ModelLocator.resourceManagerInstance.getString("transmitterservice","dead_g5_battery"))
								.setTitle(ModelLocator.resourceManagerInstance.getString("transmitterservice","dead_g5_battery"))
								.setBody(body1)
								.enableVibration(true)
							Notifications.service.notify(notificationBuilderG5G6BatteryInfo.build());
						}
					} else if ((transmitterDataG5G6Packet.rawData == 0 || transmitterDataG5G6Packet.filteredData == 0) && transmitterDataG5G6Packet.timeStamp != 0) {
						myTrace("in transmitterDataReceived, rawdata = 0, this may be caused by refurbished G5/G6 with badly placed batteries, or badly placed transmitter");
						if ((new Date()).valueOf() - timeStampSinceLastG5G6BadlyPlacedBatteriesInfo > 1 * 3600 * 1000 && Sensor.getActiveSensor() != null) {
							timeStampSinceLastG5G6BadlyPlacedBatteriesInfo = (new Date()).valueOf();
							if (SpikeANE.appIsInForeground()) {
								if (CGMBlueToothDevice.isDexcomG5())
								{
									badPlacedBatteriesTitle = ModelLocator.resourceManagerInstance.getString("transmitterservice","bad_placed_g5_transmitter");
									badPlacedBatteriesBody = ModelLocator.resourceManagerInstance.getString("transmitterservice","bad_placed_g5_transmitter_info");
								}
								else if (CGMBlueToothDevice.isDexcomG6())
								{
									badPlacedBatteriesTitle = ModelLocator.resourceManagerInstance.getString("transmitterservice","bad_placed_g5_transmitter").replace("G5", "G6");
									badPlacedBatteriesBody = ModelLocator.resourceManagerInstance.getString("transmitterservice","bad_placed_g5_transmitter_info").replace("G5", "G6");
								}
								
								AlertManager.showActionAlert
								(
									badPlacedBatteriesTitle,
									badPlacedBatteriesBody,
									Number.NaN,
									[
										{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations','no_uppercase') },
										{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations','yes_uppercase'), triggered: onResetTransmitter }
									]
								);
								
								function onResetTransmitter(e:Event):void
								{
									CGMBluetoothService.G5G6_RequestReset();
									
									AlertManager.showSimpleAlert
									(
										ModelLocator.resourceManagerInstance.getString('globaltranslations','info_alert_title'),
										ModelLocator.resourceManagerInstance.getString('transmitterscreen','reset_g5_confirmation_message')
									);
								}
								
								SpikeANE.vibrate();
							} else {
								if (CGMBlueToothDevice.isDexcomG5())
								{
									badPlacedBatteriesTitle = ModelLocator.resourceManagerInstance.getString("transmitterservice","bad_placed_g5_transmitter");
									badPlacedBatteriesBody = ModelLocator.resourceManagerInstance.getString("transmitterservice","bad_placed_g5_transmitter_info");
								}
								else if (CGMBlueToothDevice.isDexcomG6())
								{
									badPlacedBatteriesTitle = ModelLocator.resourceManagerInstance.getString("transmitterservice","bad_placed_g5_transmitter").replace("G5", "G6");
									badPlacedBatteriesBody = ModelLocator.resourceManagerInstance.getString("transmitterservice","bad_placed_g5_transmitter_info").replace("G5", "G6");
								}
								
								if (badPlacedBatteriesBody == null || badPlacedBatteriesBody == "")
								{
									badPlacedBatteriesBody = " ";
								}
								
								notificationBuilderG5G6BatteryInfo = new NotificationBuilder()
									.setCount(BadgeBuilder.getAppBadge())
									.setId(NotificationService.ID_FOR_BAD_PLACED_G5_G6_INFO)
									.setAlert(badPlacedBatteriesTitle)
									.setTitle(badPlacedBatteriesTitle)
									.setBody(badPlacedBatteriesBody)
									.enableVibration(true)
								Notifications.service.notify(notificationBuilderG5G6BatteryInfo.build());
							}
						} 
					} else {
						//create and save bgreading
						BgReading.
							create(transmitterDataG5G6Packet.rawData, transmitterDataG5G6Packet.filteredData)
							.saveToDatabaseSynchronous();
						
						//dispatch the event that there's new data
						transmitterServiceEvent = new TransmitterServiceEvent(TransmitterServiceEvent.BGREADING_RECEIVED);
						_instance.dispatchEvent(transmitterServiceEvent);
						transmitterServiceEvent = new TransmitterServiceEvent(TransmitterServiceEvent.LAST_BGREADING_RECEIVED);
						_instance.dispatchEvent(transmitterServiceEvent);
					}
				} else if (be.data is TransmitterDataTransmiter_PLPacket) {
					var transmitterDataTransmiter_PLPacket:TransmitterDataTransmiter_PLPacket = be.data as TransmitterDataTransmiter_PLPacket;
					if (!isNaN(transmitterDataTransmiter_PLPacket.bridgeBatteryLevel)) {
						CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_BLUEREADER_BATTERY_LEVEL, transmitterDataTransmiter_PLPacket.bridgeBatteryLevel.toString());
					}
					if (!isNaN(transmitterDataTransmiter_PLPacket.sensorAge)) {
						CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_FSL_SENSOR_AGE, transmitterDataTransmiter_PLPacket.sensorAge.toString());
					}
					BgReading.
						create(transmitterDataTransmiter_PLPacket.bgValue, transmitterDataTransmiter_PLPacket.bgValue)
						.saveToDatabaseSynchronous();
					
					//dispatch the event that there's new data
					transmitterServiceEvent = new TransmitterServiceEvent(TransmitterServiceEvent.BGREADING_RECEIVED);
					_instance.dispatchEvent(transmitterServiceEvent);
					transmitterServiceEvent = new TransmitterServiceEvent(TransmitterServiceEvent.LAST_BGREADING_RECEIVED);
					_instance.dispatchEvent(transmitterServiceEvent);
				} else if (be.data is TransmitterDataBlueReaderPacket) {
					myTrace("in transmitterDataReceived, is TransmitterDataBlueReaderPacket");
					var transmitterDataBlueReaderPacket:TransmitterDataBlueReaderPacket = be.data as TransmitterDataBlueReaderPacket;
					if (!isNaN(transmitterDataBlueReaderPacket.bluereaderBatteryLevel)) {
						CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_BLUEREADER_BATTERY_LEVEL, (getBlueReaderBatteryLevel(transmitterDataBlueReaderPacket.bluereaderBatteryLevel)).toString());
						myTrace("in transmitterDataReceived, setting COMMON_SETTING_BLUEREADER_BATTERY_LEVEL to " + CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BLUEREADER_BATTERY_LEVEL));
					}
					if (!isNaN(transmitterDataBlueReaderPacket.fslBatteryLevel)) {
						CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_FSL_SENSOR_BATTERY_LEVEL, transmitterDataBlueReaderPacket.fslBatteryLevel.toString());
						myTrace("in transmitterDataReceived, setting COMMON_SETTING_FSL_SENSOR_BATTERY_LEVEL to " + CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FSL_SENSOR_BATTERY_LEVEL));
					}
					if (!isNaN(transmitterDataBlueReaderPacket.sensorAge)) {
						CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_FSL_SENSOR_AGE, transmitterDataBlueReaderPacket.sensorAge.toString());
						myTrace("in transmitterDataReceived, setting COMMON_SETTING_FSL_SENSOR_AGE to " + CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FSL_SENSOR_AGE));
					}
					BgReading.
						create(transmitterDataBlueReaderPacket.bgValue, transmitterDataBlueReaderPacket.bgValue)
						.saveToDatabaseSynchronous();
					
					//dispatch the event that there's new data
					transmitterServiceEvent = new TransmitterServiceEvent(TransmitterServiceEvent.BGREADING_RECEIVED);
					_instance.dispatchEvent(transmitterServiceEvent);
					transmitterServiceEvent = new TransmitterServiceEvent(TransmitterServiceEvent.LAST_BGREADING_RECEIVED);
					_instance.dispatchEvent(transmitterServiceEvent);
				} else if (be.data is TransmitterDataBlueReaderBatteryPacket) {
					myTrace("in transmitterDataReceived, is TransmitterDataBlueReaderBatteryPacket");
					lastBgReading = BgReading.lastNoSensor();
					if (lastBgReading == null || lastBgReading.timestamp + 4 * 60 * 1000 < (new Date()).valueOf()) {
						myTrace("in transmitterDataReceived, is TransmitterDataBlueReaderBatteryPacket, sending 6C");
						CGMBluetoothService.writeToCharacteristic(utils.UniqueId.hexStringToByteArray("6C"));
					}
				} else if (be.data is TransmitterDataBluKonPacket) {
					lastBgReading = BgReading.lastNoSensor();
					if (lastBgReading != null) {
						if (lastBgReading.timestamp + ((4*60 + 15) * 1000) >= (new Date()).valueOf()) {
							myTrace("in transmitterDataReceived,  is TransmitterDataBluConPacket, but lastbgReading less than 255 seconds old, ignoring");
							return;
						}
					}
					var transmitterDataBluKonPacket:TransmitterDataBluKonPacket = be.data as TransmitterDataBluKonPacket;
					if (!isNaN(transmitterDataBluKonPacket.bridgeBatteryLevel)) {
						CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_BLUKON_BATTERY_LEVEL, transmitterDataBluKonPacket.bridgeBatteryLevel.toString());
					}
					if (!isNaN(transmitterDataBluKonPacket.sensorBatteryLevel)) {
						CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_FSL_SENSOR_BATTERY_LEVEL, transmitterDataBluKonPacket.sensorBatteryLevel.toString());
					}
					if (!isNaN(transmitterDataBluKonPacket.sensorAge)) {
						CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_FSL_SENSOR_AGE, transmitterDataBluKonPacket.sensorAge.toString());
					}
					BgReading.
						create(transmitterDataBluKonPacket.bgvalue, transmitterDataBluKonPacket.bgvalue, transmitterDataBluKonPacket.timeStamp)
						.saveToDatabaseSynchronous();
					
					//dispatch the event that there's new data
					transmitterServiceEvent = new TransmitterServiceEvent(TransmitterServiceEvent.BGREADING_RECEIVED);
					_instance.dispatchEvent(transmitterServiceEvent);
					//can we dispatch this event from CGMBluetoothService when last reading is dispatched in branch "if (!m_getOlderReading)"
					transmitterServiceEvent = new TransmitterServiceEvent(TransmitterServiceEvent.LAST_BGREADING_RECEIVED);
					_instance.dispatchEvent(transmitterServiceEvent);
				} 
			}
		}
		
		private static function notificationReceived(event:NotificationServiceEvent):void {
			if (event != null) {//not sure why checking, this would mean NotificationService received a null object, shouldn't happen
				var notificationEvent:NotificationEvent = event.data as NotificationEvent;
				if (notificationEvent.id == NotificationService.ID_FOR_ENTER_TRANSMITTER_ID) {
					transmitterIDTextInput = LayoutFactory.createTextInput(false, false, 180, HorizontalAlign.RIGHT);
					transmitterIDTextInput.maxChars = 5;
					transmitterIDTextInput.paddingRight = 10;
					var transmitterIDPopup:Alert = AlertManager.showActionAlert
						(
							ModelLocator.resourceManagerInstance.getString("transmitterservice","enter_transmitter_id_alert_title"),
							"",
							58,
							[
								{ label: ModelLocator.resourceManagerInstance.getString("globaltranslations","cancel_button_label").toUpperCase() },
								{ label: ModelLocator.resourceManagerInstance.getString("globaltranslations","ok_alert_button_label"), triggered: transmitterIdEntered }
							],
							HorizontalAlign.JUSTIFY,
							transmitterIDTextInput
						);
					transmitterIDPopup.gap = 0;
					transmitterIDPopup.headerProperties.maxHeight = 30;
					transmitterIDPopup.buttonGroupProperties.paddingTop = -10;
					transmitterIDTextInput.setFocus();
				} else if (notificationEvent.id == NotificationService.ID_FOR_DEAD_G5_BATTERY_INFO) {
					AlertManager.showSimpleAlert
					(
						ModelLocator.resourceManagerInstance.getString("transmitterservice","dead_g5_battery"),
						ModelLocator.resourceManagerInstance.getString("transmitterservice","dead_g5_battery_info")
					);
				} else if (notificationEvent.id == NotificationService.ID_FOR_BAD_PLACED_G5_G6_INFO) {
					var badPlacedBatteriesTitle:String = "";
					var badPlacedBatteriesBody:String = "";
					
					if (CGMBlueToothDevice.isDexcomG5())
					{
						badPlacedBatteriesTitle = ModelLocator.resourceManagerInstance.getString("transmitterservice","bad_placed_g5_transmitter");
						badPlacedBatteriesBody = ModelLocator.resourceManagerInstance.getString("transmitterservice","bad_placed_g5_transmitter_info");
					}
					else if (CGMBlueToothDevice.isDexcomG6())
					{
						badPlacedBatteriesTitle = ModelLocator.resourceManagerInstance.getString("transmitterservice","bad_placed_g5_transmitter").replace("G5", "G6");
						badPlacedBatteriesBody = ModelLocator.resourceManagerInstance.getString("transmitterservice","bad_placed_g5_transmitter_info").replace("G5", "G6");
					}
					
					AlertManager.showSimpleAlert
					(
						badPlacedBatteriesTitle,
						badPlacedBatteriesBody
					);
				} 
			}		
		}
		
		private static function transmitterIdEntered(event:Event):void {
			if (transmitterIDTextInput.text.length != 5) 
			{
				AlertManager.showSimpleAlert
				(
					ModelLocator.resourceManagerInstance.getString("transmitterservice","enter_transmitter_id_dialog_title"),
					ModelLocator.resourceManagerInstance.getString("transmitterservice","transmitter_id_should_be_five_chars").replace("{max}", "5")
				);
			}  else {
				var value:ByteArray = new ByteArray();
				value.endian = Endian.LITTLE_ENDIAN;
				value.writeByte(0x06);
				value.writeByte(0x01);
				value.writeInt(CGMBluetoothService.encodeTxID(transmitterIDTextInput.text));
				myTrace("calling BluetoothService.ackCharacteristicUpdate");
				CGMBluetoothService.writeToCharacteristic(value);
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_TRANSMITTER_ID, transmitterIDTextInput.text.toUpperCase());
			}
		}
		
		private static function getBlueReaderBatteryLevel(transmitterDataBatteryLevel:Number):Number {
			myTrace("in getBlueReaderBatteryLevel, transmitterDataBatteryLevel = "+ transmitterDataBatteryLevel);
			var blueReaderFullBattery:Number = new Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BLUEREADER_FULL_BATTERY));
			if(blueReaderFullBattery <3000 ) {
				blueReaderFullBattery = 4100;
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_BLUEREADER_FULL_BATTERY, blueReaderFullBattery.toString());
			}
			
			if (transmitterDataBatteryLevel > blueReaderFullBattery) {
				blueReaderFullBattery = transmitterDataBatteryLevel;
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_BLUEREADER_FULL_BATTERY, blueReaderFullBattery.toString());
			}
			myTrace("in getBlueReaderBatteryLevel, returnValue = "+ ((transmitterDataBatteryLevel - 3300) * 100 / (blueReaderFullBattery-3300)).toString());
			return Math.round(((transmitterDataBatteryLevel - 3300) * 100 / (blueReaderFullBattery-3300)));
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
			CGMBluetoothService.instance.removeEventListener(BlueToothServiceEvent.TRANSMITTER_DATA, transmitterDataReceived);
			NotificationService.instance.removeEventListener(NotificationServiceEvent.NOTIFICATION_EVENT, notificationReceived);
			NotificationService.instance.removeEventListener(NotificationServiceEvent.NOTIFICATION_SELECTED_EVENT, notificationReceived);
			
			myTrace("Service stopped!");
		}
		
		private static function myTrace(log:String):void {
			Trace.myTrace("TransmitterService.as", log);
		}
	}
}