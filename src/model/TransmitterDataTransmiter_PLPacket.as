package model
{
	public class TransmitterDataTransmiter_PLPacket extends TransmitterData
	{
		private var _bgValue:Number;
		
		public function get bgValue():Number
		{
			return _bgValue;
		}
		
		private var _timeStamp:Number;
		
		public function get timeStamp():Number
		{
			return _timeStamp;
		}
		
		private var _bridgeBatteryLevel:Number;
		
		public function get bridgeBatteryLevel():Number
		{
			return _bridgeBatteryLevel;
		}
		
		/**
		 * sensor age in minutes 
		 */
		private var _sensorAge:Number;
		
		public function get sensorAge():Number
		{
			return _sensorAge;
		}
		
		public function TransmitterDataTransmiter_PLPacket(rawData:Number, bridgeBatteryLevel:Number, sensorAge:Number, timestamp:Number)
		{
			_bgValue = rawData;
			_bridgeBatteryLevel = bridgeBatteryLevel;
			_timeStamp = timestamp;
			_sensorAge = sensorAge;
		}
	}
}