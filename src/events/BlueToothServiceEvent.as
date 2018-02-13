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
package events
{
	import flash.events.Event;

	[Event(name="ResultEvent",type="events.BlueToothServiceEvent")]
	[Event(name="ErrorEvent",type="events.BlueToothServiceEvent")]
	[Event(name="BluetoothStatusChangedEvent",type="events.BlueToothServiceEvent")]
	[Event(name="BluetoothServiceInformation",type="events.BlueToothServiceEvent")]
	[Event(name="TransmitterData",type="events.BlueToothServiceEvent")]
	[Event(name="BluetoothServiceInitiated",type="events.BlueToothServiceEvent")]
	[Event(name="StoppedScanning",type="events.BlueToothServiceEvent")]
	[Event(name="DeviceNotPaired",type="events.BlueToothServiceEvent")]
	[Event(name="CharacteristicUpdate",type="events.BlueToothServiceEvent")]
	[Event(name="glucosePatchReadError",type="events.BlueToothServiceEvent")]

	/**
	 * used by bluetoothservice to notify on all kinds of events : information messages like bluetooth state change, bluetooth state change,
	 * result received from transmitter, etc.. <br>
	 * to get info about connectivity status, new transmitter data ... create listeners for the events<br>
	 */
	public class BlueToothServiceEvent extends Event
	{
		/**
		 * generic event to inform about the result of an event, specifically for case where a dispatcher has been supplied by the client 
		 */
		public static const RESULT_EVENT:String = "ResultEvent";
		/**
		 * generic event to inform about the error that happened, specifically for case where a dispatcher has been supplied by the client 
		 */
		public static const ERROR_EVENT:String = "ErrorEvent";
		/**
		 * To pass status information, this is just text that can be shown to the user to display progress info<br>
		 * data.information will be a string with this info. 
		 */
		public static const BLUETOOTH_SERVICE_INFORMATION_EVENT:String = "BluetoothServiceInformation";
		/**
		 * To inform that scanning is programmatically stopped after timer expiry
		 */
		public static const STOPPED_SCANNING:String = "StoppedScanning";
		/**
		 * to inform that g5 transmitter is not paired 
		 */
		public static const DEVICE_NOT_PAIRED:String = "DeviceNotPaired";
		public static const CHARACTERISTIC_UPDATE:String = "CharacteristicUpdate";
		/**
		 * for BLUKON 
		 */
		public static const GLUCOSE_PATCH_READ_ERROR:String = "glucosePatchReadError";
		
		/**
		 * To pass transmitter data<br>
		 * data will be an instance of TransmitterData. The type of subclass determines the type of transmitter data<br>
		 * The bluetoothservice will not reply to the device and not ack any message<br>
		 * This is the responsibility of the service that processes the transmitter data (ie TransmitterService)
		 */
		public static const TRANSMITTER_DATA:String = "Transmitterdata";
		/**
		 * will be dispatches as soon as blue tooth service is initiated and distriqt classes can be used 
		 */
		public static const BLUETOOTH_SERVICE_INITIATED:String = "BluetoothServiceInitiated";
	
		/**
		 * Dispatched when successfully subscribed to characteristics - this is the final step in the process of connecting to a device<br> 
		 */
		public static const BLUETOOTH_DEVICE_CONNECTION_COMPLETED:String = "BluetoothDeviceConnectionCompleted";

		public var data:*;

		public function BlueToothServiceEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false) {
			super(type, bubbles, cancelable);
		}
	}
}