package events
{
	import flash.events.Event;

	public class PredictionEvent extends Event
	{
		[Event(name="apsPredictionRetreived",type="events.PredictionEvent")]
		
		public static const APS_RETRIEVED:String = "apsPredictionRetreived";
		
		public function PredictionEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false) 
		{
			super(type, bubbles, cancelable);
		}
	}
}