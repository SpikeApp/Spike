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
	import com.distriqt.extension.notifications.Notifications;
	import com.distriqt.extension.notifications.builders.NotificationBuilder;
	import com.distriqt.extension.notifications.events.NotificationEvent;
	import com.freshplanet.ane.AirBackgroundFetch.BackgroundFetch;
	
	import flash.events.EventDispatcher;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	import database.BgReading;
	import database.BlueToothDevice;
	import database.CommonSettings;
	import database.Sensor;
	
	import events.BlueToothServiceEvent;
	import events.NotificationServiceEvent;
	import events.TransmitterServiceEvent;
	
	import feathers.controls.Alert;
	import feathers.controls.TextInput;
	import feathers.layout.HorizontalAlign;
	
	import model.ModelLocator;
	import model.TransmitterDataBluKonPacket;
	import model.TransmitterDataBlueReaderBatteryPacket;
	import model.TransmitterDataBlueReaderPacket;
	import model.TransmitterDataG5Packet;
	import model.TransmitterDataTransmiter_PLPacket;
	import model.TransmitterDataXBridgeBeaconPacket;
	import model.TransmitterDataXBridgeDataPacket;
	import model.TransmitterDataXBridgeRDataPacket;
	import model.TransmitterDataXdripDataPacket;
	
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
		
		private static var timeStampSinceLastG5BadlyPlacedBatteriesInfo:Number = 0;

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
			
			BluetoothService.instance.addEventListener(BlueToothServiceEvent.TRANSMITTER_DATA, transmitterDataReceived);
			NotificationService.instance.addEventListener(NotificationServiceEvent.NOTIFICATION_EVENT, notificationReceived);
			NotificationService.instance.addEventListener(NotificationServiceEvent.NOTIFICATION_SELECTED_EVENT, notificationReceived);
		}
		
		public static function dispatchBgReadingEvent():void {
			_instance.dispatchEvent(new TransmitterServiceEvent(TransmitterServiceEvent.BGREADING_EVENT));
		}
		
		private static function transmitterDataReceived(be:BlueToothServiceEvent):void {
			
			var value:ByteArray;
			var transmitterServiceEvent:TransmitterServiceEvent;
			var notificationBuilderG5BatteryInfo:NotificationBuilder;
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
						BluetoothService.writeToCharacteristic(value);
					} else if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TRANSMITTER_ID) != "00000" 
						&&
						transmitterDataBeaconPacket.TxID != CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TRANSMITTER_ID)) {
						value = new ByteArray();
						value.endian = Endian.LITTLE_ENDIAN;
						value.writeByte(0x06);
						value.writeByte(0x01);
						value.writeInt((BluetoothService.encodeTxID(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TRANSMITTER_ID))));
						myTrace("calling BluetoothService.ackCharacteristicUpdate");
						BluetoothService.writeToCharacteristic(value);
					} else {
						value = new ByteArray();
						value.writeByte(0x02);
						value.writeByte(0xF0);
						BluetoothService.writeToCharacteristic(value);
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
						BluetoothService.writeToCharacteristic(value);
					} else if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TRANSMITTER_ID) != "00000" 
						&&
						transmitterDataXBridgeDataPacket.TxID != CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TRANSMITTER_ID)) {
						value = new ByteArray();
						value.endian = Endian.LITTLE_ENDIAN;
						value.writeByte(0x06);
						value.writeByte(0x01);
						value.writeInt((BluetoothService.encodeTxID(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TRANSMITTER_ID))));
						myTrace("calling BluetoothService.ackCharacteristicUpdate");
						BluetoothService.writeToCharacteristic(value);
					} else {
						value = new ByteArray();
						value.writeByte(0x02);
						value.writeByte(0xF0);
						BluetoothService.writeToCharacteristic(value);
					}						

					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_BRIDGE_BATTERY_PERCENTAGE,transmitterDataXBridgeDataPacket.bridgeBatteryPercentage.toString());
					var readingTimeStamp:Number = (new Date()).valueOf();
					if (transmitterDataXBridgeDataPacket is TransmitterDataXBridgeRDataPacket) {
						readingTimeStamp = (transmitterDataXBridgeDataPacket as TransmitterDataXBridgeRDataPacket).timestamp;
					}
					BgReading.
						create(transmitterDataXBridgeDataPacket.rawData, transmitterDataXBridgeDataPacket.filteredData, readingTimeStamp)
						.saveToDatabaseSynchronous();
					
					transmitterServiceEvent = new TransmitterServiceEvent(TransmitterServiceEvent.BGREADING_EVENT);
					_instance.dispatchEvent(transmitterServiceEvent);

					if (BlueToothDevice.isDexcomG4()) {
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
						transmitterServiceEvent = new TransmitterServiceEvent(TransmitterServiceEvent.BGREADING_EVENT);
						_instance.dispatchEvent(transmitterServiceEvent);
					}
				} else if (be.data is TransmitterDataG5Packet) {
					var transmitterDataG5Packet:TransmitterDataG5Packet = be.data as TransmitterDataG5Packet;
					
					//check special values filtered and unfiltered to detect dead battery
					if (transmitterDataG5Packet.filteredData == 2096896) {
						myTrace("in transmitterDataReceived, filteredData = 2096896, this indicates a dead G5 battery, no further processing");
						if (BackgroundFetch.appIsInForeground()) {
							AlertManager.showSimpleAlert
							(
								ModelLocator.resourceManagerInstance.getString("transmitterservice","dead_g5_battery"),
								ModelLocator.resourceManagerInstance.getString("transmitterservice","dead_g5_battery_info")
							);
							BackgroundFetch.vibrate();
						} else {
							notificationBuilderG5BatteryInfo = new NotificationBuilder()
								.setCount(BadgeBuilder.getAppBadge())
								.setId(NotificationService.ID_FOR_DEAD_G5_BATTERY_INFO)
								.setAlert(ModelLocator.resourceManagerInstance.getString("transmitterservice","dead_g5_battery"))
								.setTitle(ModelLocator.resourceManagerInstance.getString("transmitterservice","dead_g5_battery"))
								.setBody(ModelLocator.resourceManagerInstance.getString("transmitterservice","dead_g5_battery_info"))
								.enableVibration(true)
							Notifications.service.notify(notificationBuilderG5BatteryInfo.build());
						}
					} else if ((transmitterDataG5Packet.rawData == 0 || transmitterDataG5Packet.filteredData == 0) && transmitterDataG5Packet.timeStamp != 0) {
						myTrace("in transmitterDataReceived, rawdata = 0, this may be caused by refurbished G5 with badly placed batteries, or badly placed transmitter");
						if ((new Date()).valueOf() - timeStampSinceLastG5BadlyPlacedBatteriesInfo > 1 * 3600 * 1000 && Sensor.getActiveSensor() != null) {
							timeStampSinceLastG5BadlyPlacedBatteriesInfo = (new Date()).valueOf();
							if (BackgroundFetch.appIsInForeground()) {
								AlertManager.showActionAlert
								(
									ModelLocator.resourceManagerInstance.getString("transmitterservice","bad_placed_g5_transmitter"),
									ModelLocator.resourceManagerInstance.getString("transmitterservice","bad_placed_g5_transmitter_info"),
									Number.NaN,
									[
										{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations','no_uppercase') },
										{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations','yes_uppercase'), triggered: onResetTransmitter }
									]
								);
								
								function onResetTransmitter(e:Event):void
								{
									BluetoothService.G5_RequestReset();
									
									AlertManager.showSimpleAlert
									(
										ModelLocator.resourceManagerInstance.getString('globaltranslations','info_alert_title'),
										ModelLocator.resourceManagerInstance.getString('transmitterscreen','reset_g5_confirmation_message')
									);
								}
								
								BackgroundFetch.vibrate();
							} else {
								notificationBuilderG5BatteryInfo = new NotificationBuilder()
									.setCount(BadgeBuilder.getAppBadge())
									.setId(NotificationService.ID_FOR_BAD_PLACED_G5_INFO)
									.setAlert(ModelLocator.resourceManagerInstance.getString("transmitterservice","bad_placed_g5_transmitter"))
									.setTitle(ModelLocator.resourceManagerInstance.getString("transmitterservice","bad_placed_g5_transmitter"))
									.setBody(ModelLocator.resourceManagerInstance.getString("transmitterservice","bad_placed_g5_transmitter_info"))
									.enableVibration(true)
								Notifications.service.notify(notificationBuilderG5BatteryInfo.build());
							}
						} 
					} else {
						//create and save bgreading
						BgReading.
							create(transmitterDataG5Packet.rawData, transmitterDataG5Packet.filteredData)
							.saveToDatabaseSynchronous();
						
						//dispatch the event that there's new data
						transmitterServiceEvent = new TransmitterServiceEvent(TransmitterServiceEvent.BGREADING_EVENT);
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
					transmitterServiceEvent = new TransmitterServiceEvent(TransmitterServiceEvent.BGREADING_EVENT);
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
					transmitterServiceEvent = new TransmitterServiceEvent(TransmitterServiceEvent.BGREADING_EVENT);
					_instance.dispatchEvent(transmitterServiceEvent);
				} else if (be.data is TransmitterDataBlueReaderBatteryPacket) {
					myTrace("in transmitterDataReceived, is TransmitterDataBlueReaderBatteryPacket");
					lastBgReading = BgReading.lastNoSensor();
					if (lastBgReading == null || lastBgReading.timestamp + 4 * 60 * 1000 < (new Date()).valueOf()) {
						myTrace("in transmitterDataReceived, is TransmitterDataBlueReaderBatteryPacket, sending 6C");
						BluetoothService.writeToCharacteristic(utils.UniqueId.hexStringToByteArray("6C"));
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
					transmitterServiceEvent = new TransmitterServiceEvent(TransmitterServiceEvent.BGREADING_EVENT);
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
				} else if (notificationEvent.id == NotificationService.ID_FOR_BAD_PLACED_G5_INFO) {
					AlertManager.showSimpleAlert
					(
						ModelLocator.resourceManagerInstance.getString("transmitterservice","bad_placed_g5_transmitter"),
						ModelLocator.resourceManagerInstance.getString("transmitterservice","bad_placed_g5_transmitter_info")
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
					ModelLocator.resourceManagerInstance.getString("transmitterservice","transmitter_id_should_be_five_chars")
				);
			}  else {
				var value:ByteArray = new ByteArray();
				value.endian = Endian.LITTLE_ENDIAN;
				value.writeByte(0x06);
				value.writeByte(0x01);
				value.writeInt(BluetoothService.encodeTxID(transmitterIDTextInput.text));
				myTrace("calling BluetoothService.ackCharacteristicUpdate");
				BluetoothService.writeToCharacteristic(value);
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
		
		private static function myTrace(log:String):void {
			Trace.myTrace("TransmitterService.as", log);
		}
	}
}