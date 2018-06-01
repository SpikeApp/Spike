package com.spikeapp.spike.airlibrary
{
	import flash.events.Event;
	import flash.system.Capabilities;
	
	import spark.formatters.DateTimeFormatter;
	
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
	[Event(name="stoppedScanningMiaoMiaoBecauseConnected",type="events.SpikeANEEVent")]
	
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
		public static const MIAOMIAO_STOPPED_SCANNING_BECAUSE_CONNECTED:String = "stoppedScanningMiaoMiaoBecauseConnected";

		
		private static var dateFormatter:DateTimeFormatter;
		public var data:Object;
		public var timeStamp:Number;
		public function SpikeANEEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			timeStamp = (new Date()).valueOf();
		}
	
		public function getTimeStampAsString(): String {
			if (dateFormatter == null) {
				dateFormatter = new DateTimeFormatter();
				dateFormatter.dateTimePattern = "MM dd HH:mm:ss";
				dateFormatter.useUTC = false;
				dateFormatter.setStyle("locale",Capabilities.language.substr(0,2));
			}
			
			var date:Date = new Date();
			var milliSeconds:String = date.milliseconds.toString();
			if (milliSeconds.length < 3)
				milliSeconds = "0" + milliSeconds;
			if (milliSeconds.length < 3)
				milliSeconds = "0" + milliSeconds;
			
			var returnValue:String = dateFormatter.format(date) + " " + milliSeconds + " ";
			return returnValue;
		}
	}
}


