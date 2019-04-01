package model
{
	import G5G6Model.TransmitterStatus;

	public class TransmitterDataG5G6Packet extends TransmitterData
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
		
		private var _timeStamp:Number;

		public function get timeStamp():Number
		{
			return _timeStamp;
		}

		private var _transmitterStatus:TransmitterStatus
		
		public function get transmitterStatus():TransmitterStatus
		{
			return _transmitterStatus;
		}

		/**
		 * G5 data packet<br>
		 * There's no relation with database class, just ust for passing transmitter data from one to another<br>
		 */
		public function TransmitterDataG5G6Packet(rawData:Number, filteredData:Number, timeStamp:Number, transmitter:TransmitterStatus) {
			_rawData = rawData;
			_filteredData = filteredData;
			_timeStamp = timeStamp;
			_transmitterStatus = transmitterStatus;
		}
	}
}