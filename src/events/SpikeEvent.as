package events
{
	import flash.events.Event;

	public class SpikeEvent extends Event
	{
		[Event(name="AppInForeGroundEvent",type="events.SpikeEvent")]
		[Event(name="AppInBackGroundEvent",type="events.SpikeEvent")]
		[Event(name="texturesInitialized",type="events.SpikeEvent")]
		[Event(name="appHalted",type="events.SpikeEvent")]
		
		/**
		 * event to inform that app has moved to foreground/Background<br>
		 */
		public static const APP_IN_FOREGROUND:String = "AppInForeGroundEvent";
		public static const APP_IN_BACKGROUND:String = "AppInBackGroundEvent";
		public static const TEXTURES_INITIALIZED:String = "texturesInitialized";
		public static const APP_HALTED:String = "appHalted";
		
		public function SpikeEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}