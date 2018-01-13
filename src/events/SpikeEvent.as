package events
{
	public class SpikeEvent extends GenericEvent
	{
		[Event(name="AppInForeGroundEvent",type="events.SpikeEvent")]
		[Event(name="AppInBackGroundEvent",type="events.SpikeEvent")]
		
		/**
		 * event to inform that app has moved to foreground<br>
		 */
		public static const APP_IN_FOREGROUND:String = "AppInForeGroundEvent";
		public static const APP_IN_BACKGROUND:String = "AppInBackGroundEvent";
		
		public function SpikeEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}