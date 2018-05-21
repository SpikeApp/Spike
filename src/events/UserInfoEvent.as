package events
{
	import flash.events.Event;

	public class UserInfoEvent extends Event
	{
		[Event(name="userInfoRetreived",type="events.UserInfoEvent")]
		
		public static const USER_INFO_RETRIEVED:String = "userInfoRetreived";
		
		public var userInfo:Object;
		
		public function UserInfoEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false, userInfo:Object = null) 
		{
			super(type, bubbles, cancelable);
			
			this.userInfo = userInfo;
		}
	}
}