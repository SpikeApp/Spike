package events
{
	import flash.events.Event;

	[Event(name="BgReadingReceived",type="events.FollowerEvent")]
	[Event(name="BgReadingsRemoved",type="events.FollowerEvent")]
	
	public class FollowerEvent extends Event
	{
		/**
		 * on or more bgreading received from NS. Only for Follower<br>
		 */
		public static const BG_READING_RECEIVED:String = "BgReadingReceived";
		/**
		 * readings that were stored in modellocator by nightscoutservice, are removed
		 */
		public static const BG_READINGS_REMOVED:String = "BgReadingsRemoved";
		
		public var data:Array;
		
		public function FollowerEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false, data:Array = null) 
		{
			this.data = data;
			
			super(type, bubbles, cancelable);
		}
	}
}