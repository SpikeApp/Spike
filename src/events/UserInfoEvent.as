package events
{
	import flash.events.Event;

	public class UserInfoEvent extends Event
	{
		[Event(name="userInfoRetreived",type="events.UserInfoEvent")]
		[Event(name="userInfoAPINotFound",type="events.UserInfoEvent")]
		[Event(name="userInfoError",type="events.UserInfoEvent")]
		
		public static const USER_INFO_RETRIEVED:String = "userInfoRetreived";
		public static const USER_INFO_API_NOT_FOUND:String = "userInfoAPINotFound";
		public static const USER_INFO_ERROR:String = "userInfoError";
		
		public var userInfo:Object;
		
		public function UserInfoEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false, userInfo:Object = null) 
		{
			super(type, bubbles, cancelable);
			
			this.userInfo = userInfo;
		}
	}
}