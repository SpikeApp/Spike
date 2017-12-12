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