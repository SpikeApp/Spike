package events
{
	import flash.events.Event;

	[Event(name="LoadRequestResult",type="events.BackGroundFetchServiceEvent")]
	[Event(name="LoadRequestERror",type="events.BackGroundFetchServiceEvent")]


	public class BackGroundFetchServiceEvent extends Event
	{
		/**
		 * load request was successful, data.information contains the result
		 */
		public static const LOAD_REQUEST_RESULT:String = "LoadRequestResult";
		
		/**
		 * load request was successful, data.information contains the error
		 */
		public static const LOAD_REQUEST_ERROR:String = "LoadRequestERror";

		public var data:*;

		public function BackGroundFetchServiceEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}