package events
{
	import flash.events.Event;

	public class SettingsServiceEvent extends Event
	{
		[Event(name="SettingChanged",type="events.SettingsServiceEvent")]
		
		/**
		 * a setting has changed, data will contain the id (integer) of the setting that changed 
		 */
		public static const SETTING_CHANGED:String = "SettingChanged";
		
		public var data:*;
		
		public function SettingsServiceEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false) {
			super(type, bubbles, cancelable);
		}
	}
}