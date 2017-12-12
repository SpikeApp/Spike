package model
{
	public class TransmitterDataBlueReaderPacket extends TransmitterData
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

		private var _sensorBatteryLevel:Number;

		public function get sensorBatteryLevel():Number
		{
			return _sensorBatteryLevel;
		}
		
		private var _bridgeBatteryLevel:Number;

		public function get bridgeBatteryLevel():Number
		{
			return _bridgeBatteryLevel;
		}
		
		private var _sensorAge:Number;

		public function get sensorAge():Number
		{
			return _sensorAge;
		}
		
		
		/**
		 * sensorAge in minutes 
		 */
		public function TransmitterDataBlueReaderPacket(rawData:Number, sensorBatteryLevel:Number, bridgeBatteryLevel:Number, sensorAge:Number, timestamp:Number)
		{
			_bgValue = rawData;
			_sensorBatteryLevel = sensorBatteryLevel;
			_bridgeBatteryLevel = bridgeBatteryLevel;
			_timeStamp = timestamp;
			_sensorAge = sensorAge;
		}
	}
}