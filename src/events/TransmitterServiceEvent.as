package events
{
	import flash.events.Event;

	[Event(name="BGReadingEvent",type="events.TransmitterServiceEvent")]
	
	/**
	 * used by transmitter service to notify on all kinds of events : information messages, etc.. <br>
	 */
	
	public class TransmitterServiceEvent extends Event
	{
		/**
		 * event to inform that there's a new bgreading available<br>
		 * event is dispatched when bgreading is stored in the Modellocator and also in the databaase.<br>
		 * There's no data attached to it.
		 */
		public static const BGREADING_EVENT:String = "BGReadingEvent";
		
		public var data:*;

		public function TransmitterServiceEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}