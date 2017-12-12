package events
{
	public class IosXdripReaderEvent extends GenericEvent
	{
		[Event(name="AppInForeGroundEvent",type="events.IosXdripReaderEvent")]
		
		/**
		 * event to inform that app has moved to foreground<br>
		 */
		public static const APP_IN_FOREGROUND:String = "AppInForeGroundEvent";
		
		public function IosXdripReaderEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}