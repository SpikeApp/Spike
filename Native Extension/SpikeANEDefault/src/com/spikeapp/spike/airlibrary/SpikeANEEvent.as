package com.spikeapp.spike.airlibrary
{
	import flash.events.Event;
	
	[Event(name="phoneMuted",type="events.SpikeANEEVent")]
	[Event(name="phoneNotMuted",type="events.SpikeANEEVent")]
	[Event(name="miaoMiaoDeviceAddress",type="events.SpikeANEEVent")]
	[Event(name="miaoMiaoDataPacketReceived",type="events.SpikeANEEVent")]
	[Event(name="SensorChangedMessageReceivedFromMiaoMiao",type="events.SpikeANEEVent")]
	[Event(name="SensorNotDetectedMessageReceived",type="events.SpikeANEEVent")]
	[Event(name="miaoMiaoChangeTimeIntervalChangedFailure",type="events.SpikeANEEVent")]
	[Event(name="miaoMiaoChangeTimeIntervalChangedSuccess",type="events.SpikeANEEVent")]
	[Event(name="miaoMiaoConnected",type="events.SpikeANEEVent")]
	[Event(name="miaoMiaoDisconnected",type="events.SpikeANEEVent")]
	[Event(name="didRecieveInitialUpdateValueForCharacteristic",type="events.SpikeANEEVent")]
	[Event(name="G5DataPacketReceived",type="events.SpikeANEEVent")]
	[Event(name="G5DeviceAddress",type="events.SpikeANEEVent")]
	[Event(name="G5Disconnected",type="events.SpikeANEEVent")]
	[Event(name="G5Connected",type="events.SpikeANEEVent")]
	[Event(name="G5DeviceNotPaired",type="events.SpikeANEEVent")]
	
	public class SpikeANEEvent extends Event
	{
		public static const PHONE_MUTED:String = "phoneMuted";
		public static const PHONE_NOT_MUTED:String = "phoneNotMuted";
		public static const MIAO_MIAO_NEW_MAC:String = "miaoMiaoDeviceAddress";
		public static const MIAO_MIAO_DATA_PACKET_RECEIVED:String = "miaoMiaoDataPacketReceived";
		/**
		 * MiaoMiao has send code 32, sensor change detected
		 */
		public static const SENSOR_CHANGED_MESSAGE_RECEIVED_FROM_MIAOMIAO:String = "SensorChangedMessageReceivedFromMiaoMiao";
		/**
		 * MiaoMiao has send code 34, sensor not found
		 */
		public static const SENSOR_NOT_DETECTED_MESSAGE_RECEIVED_FROM_MIAOMIAO:String = "SensorNotDetectedMessageReceived";
		public static const MIAOMIAO_TIME_INTERVAL_CHANGED_FAILURE:String = "miaoMiaoChangeTimeIntervalChangedFailure";
		public static const MIAOMIAO_TIME_INTERVAL_CHANGED_SUCCESS:String = "miaoMiaoChangeTimeIntervalChangedSuccess";
		public static const MIAOMIAO_CONNECTED:String = "miaoMiaoConnected";
		public static const MIAOMIAO_DISCONNECTED:String = "miaoMiaoDisconnected";
		public static const MIAOMIAO_INITIAL_UPDATE_CHARACTERISTIC_RECEIVED:String = "didRecieveInitialUpdateValueForCharacteristic";

		//G5
		public static const G5_DATA_PACKET_RECEIVED:String = "G5DataPacketReceived";
		public static const G5_NEW_MAC:String = "G5DeviceAddress";
		public static const G5_DISCONNECTED:String = "G5Disconnected";
		public static const G5_CONNECTED:String = "G5Connected";
		public static const G5_DEVICE_NOT_PAIRED:String = "G5DeviceNotPaired";

		public var data:Object;
		public function SpikeANEEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}


