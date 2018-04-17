package model
{
	public class TransmitterDataXBridgeRDataPacket extends TransmitterDataXBridgeDataPacket
	{
		private var _timestamp:Number;

		public function get timestamp():Number
		{
			return _timestamp;
		}

		public function TransmitterDataXBridgeRDataPacket(rawData:Number, filteredData:Number, transmitterBatteryVoltage:Number, bridgeBatteryPercentage:Number, txID:String, timestamp:Number)
		{
			super(rawData,filteredData, transmitterBatteryVoltage, bridgeBatteryPercentage, txID);
			this._timestamp = timestamp;
		}
	}
}