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
package databaseclasses
{
	import Utilities.Trace;
	
	import services.BluetoothService;
	
	public class BlueToothDevice extends SuperDatabaseClass
	{
		public static const DEFAULT_BLUETOOTH_DEVICE_ID:String = "1465501584186cb0d5f60b3c";
		private static var _instance:BlueToothDevice = new BlueToothDevice(DEFAULT_BLUETOOTH_DEVICE_ID, Number.NaN);//note that while calling Database.getbluetoothdevice, all attributes will be overwritten by the values stored in the database
		
		/**
		 * in case we need attributes of the superclass (like uniqueid), then we need to get an instance of this class
		 */
		public static function get instance():BlueToothDevice
		{
			return _instance;
		}
		
		private static var _name:String;
		
		/**
		 * name of the device, empty string means not yet assigned to a bluetooth peripheral<br>
		 * return value will never be null, although the stored value may be null
		 */
		public static function get name():String
		{
			return _name == null ? "":_name;
		}
		
		/**
		 * sets the name, also update in database will be done
		 */
		public static function set name(value:String):void
		{
			if (value == _name)
				return;
			
			_name = value;
			if (_name == null)
				_name = "";

			Database.updateBlueToothDeviceSynchronous(_address, _name, (new Date()).valueOf());
		}
		
		private static var _address:String;
		
		/**
		 * address of the device, empty string means not yet assigned to a bluetooth peripheral<br>
		 * return value will never be null (although actual stored value may still be null)
		 */
		public static function get address():String
		{
			return _address == null ? "":_address;
		}
		
		/**
		 * sets the address, also update in database will be done
		 */
		public static function set address(value:String):void
		{
			if (value == _address)
				return;
			
			_address = value;
			if (_address == null)
				_address = "";
			Database.updateBlueToothDeviceSynchronous(_address, _name, (new Date()).valueOf());

		}
		
		public function set lastModifiedTimestamp(lastmodifiedtimestamp:Number):void
		{
			_lastModifiedTimestamp = lastmodifiedtimestamp;
		}
		
		public function BlueToothDevice(bluetoothdeviceid:String, lastmodifiedtimestamp:Number)
		{	
			super(bluetoothdeviceid, lastmodifiedtimestamp);
			if (_instance != null) {
				throw new Error("BlueToothDevice class  constructor can not be used");	
			}
		}
		
		/**
		 * sets address and name of bluetoothdevice to empty string, ie there's no device known anymore<br>
		 * also updates database and calls bluetoothservce.forgetdevice
		 */
		public static function forgetBlueToothDevice():void {
			myTrace("in forgetBlueToothDevice");
			_address = "";
			_name = "";
			Database.updateBlueToothDeviceSynchronous("", "", (new Date()).valueOf());
			BluetoothService.forgetActiveBluetoothPeripheral();
		}
		
		/**
		 * is a bluetoothdevice known or not<br>
		 * It will look at the address and if it's different from "" then returns true 
		 */
		public static function known():Boolean {
			if (_address == null)
				return false;
			return (_address != "");
		}
		
		public static function setLastModifiedTimestamp(newtimestamp:Number):void {
			instance.lastModifiedTimestamp = newtimestamp;
		}
		
		/**
		 * True for xdrip or xbridge connecting to Dexcom G4
		 */
		public static function isDexcomG4():Boolean {
			return (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PERIPHERAL_TYPE).toUpperCase() == "G4");
		}
		
		public static function isDexcomG5():Boolean {
			return (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PERIPHERAL_TYPE).toUpperCase() == "G5");
		}
		
		public static function isBlueReader():Boolean {
			return (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PERIPHERAL_TYPE).toUpperCase() == "BLUEREADER");
		}
		
		public static function isBluKon():Boolean {
			return (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PERIPHERAL_TYPE).toUpperCase() == "BLUKON" ||
				CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PERIPHERAL_TYPE).toUpperCase() == "BLUCON");
		}
		
		public static function isLimitter():Boolean {
			return (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PERIPHERAL_TYPE).toUpperCase() == "LIMITTER");
		}

		/**
		 * for type BlueReader, Limitter, BluKon, ie devices that transmit FSL sensor data<br>
		 * important for calibration
		 *  
		 */
		public static function isTypeLimitter():Boolean {
			return (isBlueReader() || isBluKon() || isLimitter());
		}
		
		/**
		 * if true, then scanning can start as soon as transmitter id is chosen. For the moment this is only the case for Dexcom G5 and Blukon<br>
		 * For others like xdrip, bluereader, etc... scanning can only start if user initiates it 
		 */
		public static function alwaysScan():Boolean {
			return (isDexcomG5() || isBluKon()); 
		}

		/**
		 * if name contains BRIDGE (case insensitive) then returns true<br>
		 * otherwise false<br><br>
		 * THIS DOES NOT NECESSARILY MEAN THAT IT DOES NOT HAVE THE XBRIDGE SOFTWARE, IT MIGHT BE AN XDRIP THAT IS LATER ON UPGRADED TO XBRIDGE<BR>
		 * To be really sure if it's an 
		 */
		public static function isXBridge():Boolean {
			return _name.toUpperCase().indexOf("BRIDGE") > -1;
		}
		
		public static function needsTransmitterId():Boolean {
			return (isDexcomG5() || isDexcomG4() || isBluKon());
		}
		
		public static function transmitterIdKnown():Boolean {
			return (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TRANSMITTER_ID) != "00000");
		}
		
		public static function deviceType():String {
			if (isDexcomG4()) 
				return "G4";
			if (isDexcomG5())
				return "G5";
			if (isBlueReader())
				return "BlueReader";
			if (isBluKon())
				return "BluKon";
			if (isLimitter())
				return "Limitter";
			return "unknown";
		}

		private static function myTrace(log:String):void {
			Trace.myTrace("BlueToothDevice.as", log);
		}
		
	}
}