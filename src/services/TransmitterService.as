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
	import com.distriqt.extension.dialog.Dialog;
	import com.distriqt.extension.dialog.DialogView;
	import com.distriqt.extension.dialog.builders.AlertBuilder;
	import com.distriqt.extension.dialog.events.DialogViewEvent;
	import com.distriqt.extension.dialog.objects.DialogAction;
	import com.distriqt.extension.notifications.Notifications;
	import com.distriqt.extension.notifications.builders.NotificationBuilder;
	import com.distriqt.extension.notifications.events.NotificationEvent;
	
	import flash.events.EventDispatcher;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	import Utilities.Trace;
	
	import databaseclasses.BgReading;
	import databaseclasses.CommonSettings;
	import databaseclasses.Sensor;
	
	import events.BlueToothServiceEvent;
	import events.NotificationServiceEvent;
	import events.TransmitterServiceEvent;
	
	import model.ModelLocator;
	import model.TransmitterDataBluKonPacket;
	import model.TransmitterDataBlueReaderBatteryPacket;
	import model.TransmitterDataBlueReaderPacket;
	import model.TransmitterDataG5Packet;
	import model.TransmitterDataXBridgeBeaconPacket;
	import model.TransmitterDataXBridgeDataPacket;
	import model.TransmitterDataXdripDataPacket;
	
	/**
	 * transmitter service handles all transmitterdata received from BlueToothService<br>
	 * It will handle TransmitterData .. packets (see children of TransmitterData class), create bgreadings ..<br>
	 * If no sensor active then no bgreading will be created<br>
	 * init must be called to start the service
	 */
	public class TransmitterService extends EventDispatcher
	{
		[ResourceBundle("transmitterservice")]
		
		private static var _instance:TransmitterService = new TransmitterService();
		
		public static function get instance():TransmitterService
		{
			return _instance;
		}
		
		private static var initialStart:Boolean = true;
		/**
		 * timestamp of last received packet, in ms 
		 */
		private static var lastPacketTime:Number = 0;
		
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
		}
		
		private static function transmitterDataReceived(be:BlueToothServiceEvent):void {
			if (be.data == null)
				return;//should never be null actually
			else {
				if (be.data is TransmitterDataXBridgeBeaconPacket) {
					if (((new Date()).valueOf() - lastPacketTime) < 60000) {
						myTrace("in transmitterDataReceived , is TransmitterDataXBridgeBeaconPacket but lastPacketTime < 60 seconds ago, ignoring");
					} else {
						lastPacketTime = (new Date()).valueOf();
						var transmitterDataBeaconPacket:TransmitterDataXBridgeBeaconPacket = be.data as TransmitterDataXBridgeBeaconPacket;
						if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TRANSMITTER_ID) == "00000" 
							&&
							transmitterDataBeaconPacket.TxID == "00000") {
							
							Notifications.service.cancel(NotificationService.ID_FOR_ENTER_TRANSMITTER_ID);
							Notifications.service.notify(
								new NotificationBuilder()
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
							myTrace("storing transmitter id received from bluetooth device = " + transmitterDataBeaconPacket.TxID);
							var transmitterServiceEvent:TransmitterServiceEvent = new TransmitterServiceEvent(TransmitterServiceEvent.TRANSMITTER_SERVICE_INFORMATION_EVENT);
							transmitterServiceEvent.data = new Object();
							transmitterServiceEvent.data.information = "storing transmitter id received from bluetooth device = " + transmitterDataBeaconPacket.TxID;
							_instance.dispatchEvent(transmitterServiceEvent);
							CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_TRANSMITTER_ID, transmitterDataBeaconPacket.TxID.toUpperCase());
							var value:ByteArray = new ByteArray();
							value.writeByte(0x02);
							value.writeByte(0xF0);
							BluetoothService.writeG4Characteristic(value);
						} else if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TRANSMITTER_ID) != "00000" 
							&&
							transmitterDataBeaconPacket.TxID != CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TRANSMITTER_ID)) {
							var value:ByteArray = new ByteArray();
							value.endian = Endian.LITTLE_ENDIAN;
							value.writeByte(0x06);
							value.writeByte(0x01);
							value.writeInt((BluetoothService.encodeTxID(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TRANSMITTER_ID))));
							myTrace("calling BluetoothService.ackCharacteristicUpdate");
							BluetoothService.writeG4Characteristic(value);
						} else {
							var value:ByteArray = new ByteArray();
							value.writeByte(0x02);
							value.writeByte(0xF0);
							BluetoothService.writeG4Characteristic(value);
						}
					}
				} else if (be.data is TransmitterDataXBridgeDataPacket) {
					var transmitterDataXBridgeDataPacket:TransmitterDataXBridgeDataPacket = be.data as TransmitterDataXBridgeDataPacket;
					if (((new Date()).valueOf() - lastPacketTime) < 60000) {
						myTrace("in transmitterDataReceived , is TransmitterDataXBridgeDataPacket but lastPacketTime < 60 seconds ago, ignoring");
					} else {
						lastPacketTime = (new Date()).valueOf();
						if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TRANSMITTER_ID) == "00000" 
							&&
							transmitterDataXBridgeDataPacket.TxID != "00000") {
							myTrace("storing transmitter id received from bluetooth device = " + transmitterDataXBridgeDataPacket.TxID);
							var transmitterServiceEvent:TransmitterServiceEvent = new TransmitterServiceEvent(TransmitterServiceEvent.TRANSMITTER_SERVICE_INFORMATION_EVENT);
							transmitterServiceEvent.data = new Object();
							transmitterServiceEvent.data.information = "storing transmitter id received from bluetooth device = " + transmitterDataXBridgeDataPacket.TxID;
							_instance.dispatchEvent(transmitterServiceEvent);
							CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_TRANSMITTER_ID, transmitterDataXBridgeDataPacket.TxID.toUpperCase());
							var value:ByteArray = new ByteArray();
							value.writeByte(0x02);
							value.writeByte(0xF0);
							BluetoothService.writeG4Characteristic(value);
						} else if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TRANSMITTER_ID) != "00000" 
							&&
							transmitterDataXBridgeDataPacket.TxID != CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TRANSMITTER_ID)) {
							var value:ByteArray = new ByteArray();
							value.endian = Endian.LITTLE_ENDIAN;
							value.writeByte(0x06);
							value.writeByte(0x01);
							value.writeInt((BluetoothService.encodeTxID(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TRANSMITTER_ID))));
							myTrace("calling BluetoothService.ackCharacteristicUpdate");
							BluetoothService.writeG4Characteristic(value);
						} else {
							var value:ByteArray = new ByteArray();
							value.writeByte(0x02);
							value.writeByte(0xF0);
							BluetoothService.writeG4Characteristic(value);
						}						
						//store the transmitter battery level in the common settings (to be synchronized)
						CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_G4_TRANSMITTER_BATTERY_VOLTAGE,transmitterDataXBridgeDataPacket.transmitterBatteryVoltage.toString());
						
						//store the bridge battery level in the common settings (to be synchronized)
						CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_BRIDGE_BATTERY_PERCENTAGE,transmitterDataXBridgeDataPacket.bridgeBatteryPercentage.toString());
						if (Sensor.getActiveSensor() != null) {
							Sensor.getActiveSensor().latestBatteryLevel = transmitterDataXBridgeDataPacket.transmitterBatteryVoltage;
							//create and save bgreading
							BgReading.
								create(transmitterDataXBridgeDataPacket.rawData, transmitterDataXBridgeDataPacket.filteredData)
								.saveToDatabaseSynchronous();
							
							//dispatch the event that there's new data
							var transmitterServiceEvent:TransmitterServiceEvent = new TransmitterServiceEvent(TransmitterServiceEvent.BGREADING_EVENT);
							_instance.dispatchEvent(transmitterServiceEvent);
						} else {
							//TODO inform that bgreading is received but sensor not started ?
						}
					}
					
				} else if (be.data is TransmitterDataXdripDataPacket) {
					var transmitterDataXdripDataPacket:TransmitterDataXdripDataPacket = be.data as TransmitterDataXdripDataPacket;
					if (((new Date()).valueOf() - lastPacketTime) < 60000) {
						myTrace("in transmitterDataReceived , is TransmitterDataXdripDataPacket but lastPacketTime < 60 seconds ago, ignoring");
					} else {//it's an xdrip, with old software, 
						lastPacketTime = (new Date()).valueOf();
						
						//store as bridge battery level value 0 in the common settings (to be synchronized)
						CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_BRIDGE_BATTERY_PERCENTAGE, "0");
						
						//store the transmitter battery level in the common settings (to be synchronized)
						CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_G4_TRANSMITTER_BATTERY_VOLTAGE, transmitterDataXdripDataPacket.transmitterBatteryVoltage.toString());
						if (Sensor.getActiveSensor() != null)
							Sensor.getActiveSensor().latestBatteryLevel = transmitterDataXdripDataPacket.transmitterBatteryVoltage;
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
					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_BRIDGE_BATTERY_PERCENTAGE, "0");
					
					//store the transmitter battery level in the common settings (to be synchronized)
					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_G4_TRANSMITTER_BATTERY_VOLTAGE, transmitterDataG5Packet.transmitterBatteryVoltage.toString());
					if (Sensor.getActiveSensor() != null)
						Sensor.getActiveSensor().latestBatteryLevel = transmitterDataG5Packet.transmitterBatteryVoltage;
					//create and save bgreading
					BgReading.
						create(transmitterDataG5Packet.rawData, transmitterDataG5Packet.filteredData)
						.saveToDatabaseSynchronous();
					
					//dispatch the event that there's new data
					transmitterServiceEvent = new TransmitterServiceEvent(TransmitterServiceEvent.BGREADING_EVENT);
					_instance.dispatchEvent(transmitterServiceEvent);
				} else if (be.data is TransmitterDataBlueReaderPacket) {
					var transmitterDataBlueReaderPacket:TransmitterDataBlueReaderPacket = be.data as TransmitterDataBlueReaderPacket;
					if (!isNaN(transmitterDataBlueReaderPacket.bridgeBatteryLevel)) {
						CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_BLUEREADER_BATTERY_LEVEL, transmitterDataBlueReaderPacket.bridgeBatteryLevel.toString());
					}
					if (!isNaN(transmitterDataBlueReaderPacket.sensorBatteryLevel)) {
						CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_FSL_SENSOR_BATTERY_LEVEL, transmitterDataBlueReaderPacket.sensorBatteryLevel.toString());
					}
					if (!isNaN(transmitterDataBlueReaderPacket.sensorAge)) {
						CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_FSL_SENSOR_AGE, transmitterDataBlueReaderPacket.sensorAge.toString());
					}
					BgReading.
						create(transmitterDataBlueReaderPacket.bgValue, transmitterDataBlueReaderPacket.bgValue)
						.saveToDatabaseSynchronous();
					
					//dispatch the event that there's new data
					transmitterServiceEvent = new TransmitterServiceEvent(TransmitterServiceEvent.BGREADING_EVENT);
					_instance.dispatchEvent(transmitterServiceEvent);
				} else if (be.data is TransmitterDataBlueReaderBatteryPacket) {
					myTrace("in transmitterDataReceived, is TransmitterDataBlueReaderBatteryPacket");
					var lastBgRading:BgReading = BgReading.lastNoSensor();
					if (lastBgRading != null) {
						if (lastBgRading.timestamp + ((4*60 + 15) * 1000) >= (new Date()).valueOf()) {
							myTrace("in transmitterDataReceived,  is TransmitterDataBlueReaderBatteryPacket, but lastbgReading less than 255 seconds old, ignoring");
							return;
						}
					}
					BluetoothService.writeBlueReaderCharacteristic(Utilities.UniqueId.hexStringToByteArray("6C"));
				} else if (be.data is TransmitterDataBluKonPacket) {
					var lastBgRading:BgReading = BgReading.lastNoSensor();
					if (lastBgRading != null) {
						if (lastBgRading.timestamp + ((4*60 + 15) * 1000) >= (new Date()).valueOf()) {
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
					var alert:DialogView = Dialog.service.create(
						new AlertBuilder()
						.setTitle(ModelLocator.resourceManagerInstance.getString("transmitterservice","enter_transmitter_id_dialog_title"))
						.setMessage(ModelLocator.resourceManagerInstance.getString("transmitterservice","enter_transmitter_id"))
						.addTextField(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TRANSMITTER_ID), "00000")
						.addOption("Ok", DialogAction.STYLE_POSITIVE, 0)
						.addOption(ModelLocator.resourceManagerInstance.getString("general","cancel"), DialogAction.STYLE_CANCEL, 1)
						.build()
					);
					alert.addEventListener(DialogViewEvent.CLOSED, transmitterIdEntered);
					DialogService.addDialog(alert, 58);
				}
			}		
		}
		
		private static function transmitterIdEntered(event:DialogViewEvent):void {
			if (event.index == 1) {
				return;
			}
			if ((event.values[0] as String).length != 5) {
				DialogService.openSimpleDialog(ModelLocator.resourceManagerInstance.getString("transmitterservice","enter_transmitter_id_dialog_title"),
					ModelLocator.resourceManagerInstance.getString("transmitterservice","transmitter_id_should_be_five_chars"));
			} else {
				var value:ByteArray = new ByteArray();
				value.endian = Endian.LITTLE_ENDIAN;
				value.writeByte(0x06);
				value.writeByte(0x01);
				value.writeInt(BluetoothService.encodeTxID(event.values[0] as String));
				myTrace("calling BluetoothService.ackCharacteristicUpdate");
				BluetoothService.writeG4Characteristic(value);
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_TRANSMITTER_ID, (event.values[0] as String).toUpperCase());
			}
		}
		
		private static function myTrace(log:String):void {
			Trace.myTrace("TransmitterService.as", log);
		}
	}
}