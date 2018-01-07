package events
{
	
	public class DeepSleepServiceEvent extends GenericEvent
	{
		[Event(name="DeepSleepServiceTimerEvent",type="events.DeepSleepServiceEvent")]
		
		public static const DEEP_SLEEP_SERVICE_TIMER_EVENT:String = "DeepSleepServiceTimerEvent";
		
		public var data:*;
		
		public function DeepSleepServiceEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}