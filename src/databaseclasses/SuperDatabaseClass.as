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
package databaseclasses
{
	import Utilities.UniqueId;

	/**
	 * class that holds and does generic attributes and methods for all classes that will do google sync etc. <br>
	 * lastmodifiedtimestamp is to allow syncing, this is not a generic timestamp to be used for other purposes
	 */
	public class SuperDatabaseClass
	{
		protected var _lastModifiedTimestamp:Number;

		public function get lastModifiedTimestamp():Number
		{
			return _lastModifiedTimestamp;
		}

		protected var _uniqueId:String;

		public function get uniqueId():String
		{
			return _uniqueId;
		}
		
		/**
		 * if uniqueID is null than a new id is assigned<br>
		 * if lastmodifiedtimestamp is Number.NaN then current time is assigned<br> 
		 */
		public function SuperDatabaseClass(uniqueId:String, lastmodifiedtimestamp:Number)
		{
			if (isNaN(lastmodifiedtimestamp))
				_lastModifiedTimestamp = (new Date()).valueOf();
			else
				_lastModifiedTimestamp = lastmodifiedtimestamp;
				
			if (uniqueId == null)
				_uniqueId = Utilities.UniqueId.createEventId();
			else
				_uniqueId = uniqueId;
		}
		
		protected function resetLastModifiedTimeStamp():void {
			_lastModifiedTimestamp = (new Date()).valueOf();
		}
	}
}