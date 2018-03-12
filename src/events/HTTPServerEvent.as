package events
{
	import flash.events.Event;

	public class HTTPServerEvent extends Event
	{
		[Event(name="serverOffline",type="events.HTTPServerEvent")]
		
		public static const SERVER_OFFLINE:String = "serverOffline";
		
		public var data:*;
		
		public function HTTPServerEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false, data:* = null) 
		{
			super(type, bubbles, cancelable);
			
			this.data = data;
		}
	}
}