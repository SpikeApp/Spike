package events
{
	import flash.events.Event;
	
	import treatments.Treatment;

	public class TreatmentsEvent extends Event
	{
		[Event(name="treatmentAdded",type="events.TreatmentsEvent")]
		[Event(name="treatmentDeleted",type="events.TreatmentsEvent")]
		[Event(name="treatmentUpdated",type="events.TreatmentsEvent")]
		[Event(name="treatmentExternallyModified",type="events.TreatmentsEvent")]
		[Event(name="treatmentExternallyDeleted",type="events.TreatmentsEvent")]
		[Event(name="IOBCOBUpdated",type="events.TreatmentsEvent")]
		[Event(name="newBasalData",type="events.TreatmentsEvent")]
		[Event(name="basalTreatmentAdded",type="events.TreatmentsEvent")]
		[Event(name="basalTreatmentUpdated",type="events.TreatmentsEvent")]
		[Event(name="basalTreatmentDeleted",type="events.TreatmentsEvent")]
		[Event(name="nightscoutBasalProfileImported",type="events.TreatmentsEvent")]
		
		public static const TREATMENT_ADDED:String = "treatmentAdded";
		public static const TREATMENT_DELETED:String = "treatmentDeleted";
		public static const TREATMENT_UPDATED:String = "treatmentUpdated";
		public static const TREATMENT_EXTERNALLY_MODIFIED:String = "treatmentExternallyModified";
		public static const TREATMENT_EXTERNALLY_DELETED:String = "treatmentExternallyDeleted";
		public static const IOB_COB_UPDATED:String = "IOBCOBUpdated";
		public static const NEW_BASAL_DATA:String = "newBasalData";
		public static const BASAL_TREATMENT_ADDED:String = "basalTreatmentAdded";
		public static const BASAL_TREATMENT_UPDATED:String = "basalTreatmentUpdated";
		public static const BASAL_TREATMENT_DELETED:String = "basalTreatmentDeleted";
		public static const NIGHTSCOUT_BASAL_PROFILE_IMPORTED:String = "nightscoutBasalProfileImported";
		
		public var treatment:Treatment;
		
		public function TreatmentsEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false, treatment:Treatment = null) 
		{
			super(type, bubbles, cancelable);
			
			this.treatment = treatment;
		}
	}
}