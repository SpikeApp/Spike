package model
{
	public class TransmitterDataXBridgeDataPacket extends TransmitterData
	{
		private var _rawData:Number;

		public function get rawData():Number
		{
			return _rawData;
		}

		private var _filteredData:Number;

		public function get filteredData():Number
		{
			return _filteredData;
		}

		private var _transmitterBatteryVoltage:Number;

		public function get transmitterBatteryVoltage():Number
		{
			return _transmitterBatteryVoltage;
		}

		private var _bridgeBatteryPercentage:Number;

		public function get bridgeBatteryPercentage():Number
		{
			return _bridgeBatteryPercentage;
		}

		private var _TxID:String;

		public function get TxID():String
		{
			return _TxID;
		}

		
		/**
		 * xbridge data packet<br>
		 * There's no relation with database class, just ust for passing transmitter data from one to another<br>
		 * There's no timestamp, nor uniqueid because this is only to be used temporary to pass the data, reflecting exactly what is received from the transmitter<br>
		 * <br>
		 * txID is the decoded transmitter id 
		 */
		public function TransmitterDataXBridgeDataPacket(rawData:Number, filteredData:Number, transmitterBatteryVoltage:Number, bridgeBatteryPercentage:Number, txID:String) {
			_rawData = rawData;
			_filteredData = filteredData;
			_transmitterBatteryVoltage = transmitterBatteryVoltage;
			_bridgeBatteryPercentage = bridgeBatteryPercentage;
			_TxID = txID;
		}
	}
}