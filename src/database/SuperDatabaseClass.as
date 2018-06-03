package database
{
	import utils.UniqueId;

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
				_uniqueId = utils.UniqueId.createEventId();
			else
				_uniqueId = uniqueId;
		}
		
		protected function resetLastModifiedTimeStamp():void {
			_lastModifiedTimestamp = (new Date()).valueOf();
		}
	}
}