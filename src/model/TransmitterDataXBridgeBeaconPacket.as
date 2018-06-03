package model
{
	public class TransmitterDataXBridgeBeaconPacket extends TransmitterData
	{
		private var _TxID:String;

		public function get TxID():String
		{
			return _TxID;
		}

		
		/**
		 * xbridge beacon packet <br>
		 * There's no relation with database class, just ust for passing transmitter data from one to another<br>
		 * There's no timestamp, nor uniqueid because this is only to be used temporary to pass the data, reflecting exactly what is received from the transmitter<br>
		 * <br>
		 * txID is the decoded transmitter id 
		 */
		public function TransmitterDataXBridgeBeaconPacket(txID:String) {
			{
				_TxID = txID;
			}
		}
	}
}