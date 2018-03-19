package events
{
	import flash.events.Event;
	
	import treatments.Treatment;

	public class TreatmentsEvent extends Event
	{
		[Event(name="treatmentAdded",type="events.TreatmentsEvent")]
		
		public static const TREATMENT_ADDED:String = "treatmentAdded";
		
		public var treatment:Treatment;
		
		public function TreatmentsEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false, treatment:Treatment = null) 
		{
			super(type, bubbles, cancelable);
			
			this.treatment = treatment;
		}
	}
}