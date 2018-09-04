package model
{
	public class TransmitterDataSweetReaderPacket extends TransmitterData
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
		
		private var _sweetReaderBatteryLevel:Number;
		
		public function get sweetReaderBatteryLevel():Number
		{
			return _sweetReaderBatteryLevel;
		}
		
		/**
		 * sensorAge in minutes 
		 */
		private var _sensorAge:Number;
		
		public function get sensorAge():Number
		{
			return _sensorAge;
		}
		
		
		public function TransmitterDataSweetReaderPacket(rawData:Number, transmitterBatteryLevel:Number, sensorAge:Number, timestamp:Number)
		{
			_bgValue = rawData;
			_sweetReaderBatteryLevel = transmitterBatteryLevel;
			_timeStamp = timestamp;
			_sensorAge = sensorAge;
		}

	}
}