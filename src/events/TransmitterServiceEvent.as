package events
{
	import flash.events.Event;

	[Event(name="BGReadingReceived",type="events.TransmitterServiceEvent")]
	[Event(name="LastBGReadingReceived",type="events.TransmitterServiceEvent")]
	
	/**
	 * used by transmitter service to notify on all kinds of events : information messages, etc.. <br>
	 */
	
	public class TransmitterServiceEvent extends Event
	{
		/**
		 * event to inform that there's a new bgreading available<br>
		 * event is dispatched when bgreading is stored in the Modellocator and also in the databaase.<br>
		 * There's no data attached to it.<br>
		 * <br>
		 */
		public static const BGREADING_RECEIVED:String = "BGReadingReceived";
		/**
		 * event to inform that the last BGReading has been received<br>
		 * Usually, for most transmitters, this event will be dispatched right after BGREADING_RECEIVED has been dispatched.<br>
		 * But some transmitters (MiaoMiao, Blucon), can send multiple Bgreadings, 
		 * in that case LAST_BGREADING_RECEIVED is only dispatched after having dispatched the final BGREADING_RECEIVED 
		 */
		public static const LAST_BGREADING_RECEIVED:String = "LastBGReadingReceived";
		
		public var data:*;

		public function TransmitterServiceEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}