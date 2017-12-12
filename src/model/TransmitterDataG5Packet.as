/**
 Copyright (C) 2016  Johan Degraeve
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/gpl.txt>.
 
 */
package model
{
	import G5Model.TransmitterStatus;

	public class TransmitterDataG5Packet extends TransmitterData
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
		public function TransmitterDataG5Packet(rawData:Number, filteredData:Number, transmitterBatteryVoltage:Number, timeStamp:Number, transmitter:TransmitterStatus) {
			_rawData = rawData;
			_filteredData = filteredData;
			_transmitterBatteryVoltage = transmitterBatteryVoltage;
			_timeStamp = timeStamp;
			_transmitterStatus = transmitterStatus;
		}
	}
}