package events
{
	import flash.events.Event;

	[Event(name="BGReadingEvent",type="events.TransmitterServiceEvent")]
	[Event(name="LastBGReadingEvent",type="events.TransmitterServiceEvent")]
	
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
		 * BGREADING_EVENT must be dispatched when there's still additional bgreading events expected. This occurs for example in case of MiaoMiao, while processing the data
		 * there will be multiple bgreadings and so multiple BGREADING_EVENTs dispatched. The last one should be LAST_BGREADING_EVENT<br>
		 */
		public static const BGREADING_EVENT:String = "BGReadingEvent";
		/**
		 * event to inform that there's a new bgreading available<br>
		 * event is dispatched when bgreading is stored in the Modellocator and also in the databaase.<br>
		 * There's no data attached to it.<br>
		 * <br>
		 * LAST_BGREADING_EVENT is the last if there's a series of bgreading events expected.<br>
		 * <br>
		 * see also  BGREADING_EVENT
		 */
		public static const LAST_BGREADING_EVENT:String = "LastBGReadingEvent";
		
		public var data:*;

		public function TransmitterServiceEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}