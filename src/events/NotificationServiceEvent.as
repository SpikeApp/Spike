package events
{
	import flash.events.Event;
	
	public class NotificationServiceEvent extends Event
	{
		[Event(name="NotificationSelectedEvent",type="events.NotificationServiceEvent")]
		[Event(name="NotificationActionEvent",type="events.NotificationServiceEvent")]
		[Event(name="NotificationEvent",type="events.NotificationServiceEvent")]
		[Event(name="NotificationServiceInitiatedEvent",type="events.NotificationServiceEvent")]
		
		/**
		 * Event to inform about a notifiation event.<br>
		 * This event is dispatched when the app receives a notification<br>
		 * This type of event should only happen if the app is in the foreground<br>
		 * <br>
		 * data will be the notification ie an object of type NotificationEvent
		 */
		public static const NOTIFICATION_EVENT:String = "NotificationEvent";
		
		/**
		 * Event to inform that the user selected a notifiation.<br>
		 * This event is dispatched when the user selected a notification<br>
		 * This type of event should normally only happen if the app is in the background, because, if a notification
		 * is fired while the app is in the foreground, it only pops up for a second, user doesn't have chance to select it.
		 * <br>
		 * data will be the notification ie an object of type NotificationEvent
		 */
		public static const NOTIFICATION_SELECTED_EVENT:String = "NotificationSelectedEvent";
		
		/**
		 * Event to inform that the user selected an action in a notification.<br>
		 * <br>
		 * data will be the notification ie an object of type NotificationEvent
		 */
		public static const NOTIFICATION_ACTION_EVENT:String = "NotificationActionEvent";
		
		/**
		 * event to inform that the notificationservice is initiated successfully, ie authorised by user.<br>
		 */
		public static const NOTIFICATION_SERVICE_INITIATED_EVENT:String = "NotificationServiceInitiatedEvent";
		
		public var data:*;
		
		public function NotificationServiceEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}