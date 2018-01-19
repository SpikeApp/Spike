package events
{
	import flash.events.Event;
	
	public class DexcomShareEvent extends Event
	{
		public static const LIST_FOLLOWERS:String = "listFollowers";
		public static const DELETE_FOLLOWER:String = "deleteFollower";
		public static const CREATE_CONTACT:String = "createContact";
		public static const INVITE_FOLLOWER:String = "inviteFollower";
		public static const GET_FOLLOWER_INFO:String = "getFollowerInfo";
		public static const GET_FOLLOWER_ALARMS:String = "getFollowerAlarms";
		public static const CHANGE_FOLLOWER_NAME:String = "changeFollowerName";
		public static const ENABLE_FOLLOWER_SHARING:String = "enableFollowerSharing";
		public static const DISABLE_FOLLOWER_SHARING:String = "disableFollowerSharing";
		public static const CHANGE_FOLLOWER_PERMISSIONS:String = "changeFollowerPermissions";
		
		//Data object to pass through the event.
		public var data:Object;
		
		public function DexcomShareEvent(type:String, data:Object, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			
			//Populate data object
			this.data = data;
		}
		
		public override function clone():Event
		{
			return new DexcomShareEvent(type, data, bubbles, cancelable);
		}
		
		override public function toString():String
		{
			return formatToString("DexcomShareEvent", "type", "bubbles", "cancelable", "eventPhase");
		}
	}
}