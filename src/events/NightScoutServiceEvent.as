package events
{
	import flash.events.Event;

	[Event(name="BgReadingReceived",type="events.NightScoutServiceEvent")]
	[Event(name="BgReadingsRemoved",type="events.NightScoutServiceEvent")]
	
	public class NightScoutServiceEvent extends Event
	{
		/**
		 * on or more bgreading received from NS. Only for Follower<br>
		 */
		public static const NIGHTSCOUT_SERVICE_BG_READING_RECEIVED:String = "BgReadingReceived";
		/**
		 * readings that were stored in modellocator by nightscoutservice, are removed
		 */
		public static const NIGHTSCOUT_SERVICE_BG_READINGS_REMOVED:String = "BgReadingsRemoved";
		
		public var data:*;
		
		public function NightScoutServiceEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false) {
			super(type, bubbles, cancelable);
		}
	}
}