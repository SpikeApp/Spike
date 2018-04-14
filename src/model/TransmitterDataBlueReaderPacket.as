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
		
		private var _bluereaderBatteryLevel:Number;
		
		public function get bluereaderBatteryLevel():Number
		{
			return _bluereaderBatteryLevel;
		}
		
		private var _fslBatteryLevel:Number;
		
		public function get fslBatteryLevel():Number
		{
			return _fslBatteryLevel;
		}
		
		/**
		 * sensorAge in minutes 
		 */
		private var _sensorAge:Number;
		
		public function get sensorAge():Number
		{
			return _sensorAge;
		}
		
		
		public function TransmitterDataBlueReaderPacket(rawData:Number, bluereaderBatteryLevel:Number, fslBatteryLevel:Number, sensorAge:Number, timestamp:Number)
		{
			_bgValue = rawData;
			_bluereaderBatteryLevel = bluereaderBatteryLevel;
			_fslBatteryLevel = fslBatteryLevel;
			_timeStamp = timestamp;
			_sensorAge = sensorAge;
		}
	}
}