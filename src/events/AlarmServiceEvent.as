package events
{
	import flash.events.Event;

	public class AlarmServiceEvent extends Event
	{
		[Event(name="urgentHighGlucoseTriggered",type="events.AlarmServiceEvent")]
		[Event(name="urgentHighGlucoseSnoozed",type="events.AlarmServiceEvent")]
		[Event(name="highGlucoseTriggered",type="events.AlarmServiceEvent")]
		[Event(name="highGlucoseSnoozed",type="events.AlarmServiceEvent")]
		[Event(name="lowGlucoseTriggered",type="events.AlarmServiceEvent")]
		[Event(name="lowGlucoseSnoozed",type="events.AlarmServiceEvent")]
		[Event(name="urgentLowGlucoseTriggered",type="events.AlarmServiceEvent")]
		[Event(name="urgentLowGlucoseSnoozed",type="events.AlarmServiceEvent")]
		[Event(name="missedReadingsTriggered",type="events.AlarmServiceEvent")]
		[Event(name="missedReadingsSnoozed",type="events.AlarmServiceEvent")]
		[Event(name="calibrationTriggered",type="events.AlarmServiceEvent")]
		[Event(name="calibrationSnoozed",type="events.AlarmServiceEvent")]
		[Event(name="phoneMutedTriggered",type="events.AlarmServiceEvent")]
		[Event(name="phoneMutedSnoozed",type="events.AlarmServiceEvent")]
		[Event(name="transmitterLowBatteryTriggered",type="events.AlarmServiceEvent")]
		[Event(name="transmitterLowBatterySnoozed",type="events.AlarmServiceEvent")]
		
		public static const URGENT_HIGH_GLUCOSE_TRIGGERED:String = "urgentHighGlucoseTriggered";
		public static const URGENT_HIGH_GLUCOSE_SNOOZED:String = "urgentHighGlucoseSnoozed";
		public static const HIGH_GLUCOSE_TRIGGERED:String = "highGlucoseTriggered";
		public static const HIGH_GLUCOSE_SNOOZED:String = "highGlucoseSnoozed";
		public static const LOW_GLUCOSE_TRIGGERED:String = "lowGlucoseTriggered";
		public static const LOW_GLUCOSE_SNOOZED:String = "lowGlucoseSnoozed";
		public static const URGENT_LOW_GLUCOSE_TRIGGERED:String = "urgentLowGlucoseTriggered";
		public static const URGENT_LOW_GLUCOSE_SNOOZED:String = "urgentLowGlucoseSnoozed";
		public static const MISSED_READINGS_TRIGGERED:String = "missedReadingsTriggered";
		public static const MISSED_READINGS_SNOOZED:String = "missedReadingsSnoozed";
		public static const CALIBRATION_TRIGGERED:String = "calibrationTriggered";
		public static const CALIBRATION_SNOOZED:String = "calibrationSnoozed";
		public static const PHONE_MUTED_TRIGGERED:String = "phoneMutedTriggered";
		public static const PHONE_MUTED_SNOOZED:String = "phoneMutedSnoozed";
		public static const TRANSMITTER_LOW_BATTERY_TRIGGERED:String = "transmitterLowBatteryTriggered";
		public static const TRANSMITTER_LOW_BATTERY_SNOOZED:String = "transmitterLowBatterySnoozed";
		
		public var data:*;
		
		public function AlarmServiceEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false, data:* = null) 
		{
			super(type, bubbles, cancelable);
			
			this.data = data;
		}
	}
}