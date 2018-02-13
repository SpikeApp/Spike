package events
{
	import flash.events.Event;

	[Event(name="InitialCalibrationEvent",type="events.CalibrationServiceEvent")]
	[Event(name="NewCalibrationEvent",type="events.CalibrationServiceEvent")]
	
	public class CalibrationServiceEvent extends Event
	{
		/**
		 * event to inform that initial calibration is done
		 */
		public static const INITIAL_CALIBRATION_EVENT:String = "InitialCalibrationEvent";
		/**
		 * event to inform that there's a new calibration done (could also be an override of a previous calibration)
		 */
		public static const NEW_CALIBRATION_EVENT:String = "NewCalibrationEvent";

		public var data:*;
		/**
		 * timestamp that the event was generated
		 */
		public var timestamp:Number;
		
		public function CalibrationServiceEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}

	}
}