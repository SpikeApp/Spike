package model
{
	public class TransmitterDataBluKonPacket extends TransmitterData
	{
		private var _bgValue:Number;
		
		public function get bgvalue():Number
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
		
		
		public function TransmitterDataBluKonPacket(rawData:Number, sensorBatteryLevel:Number, bridgeBatteryLevel:Number, sensorAge:Number, timestamp:Number)
		{
			_bgValue = rawData;
			_sensorBatteryLevel = sensorBatteryLevel;
			_bridgeBatteryLevel = bridgeBatteryLevel;
			_timeStamp = timestamp;
			_sensorAge = sensorAge;
		}
	}
}