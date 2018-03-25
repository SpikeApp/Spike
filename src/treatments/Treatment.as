package treatments
{
	import flash.utils.setInterval;
	
	import utils.UniqueId;

	public class Treatment
	{
		/* Public Constants */
		public static const TYPE_MEAL_BOLUS:String = "mealBolus";
		public static const TYPE_BOLUS:String = "bolus";
		public static const TYPE_CORRECTION_BOLUS:String = "correctionBolus";
		public static const TYPE_CARBS_CORRECTION:String = "carbCorrection";
		public static const TYPE_GLUCOSE_CHECK:String = "glucoseCheck";
		public static const TYPE_NOTE:String = "note";
		
		/* Internal Constants */
		private static const INSULIN_PEAK:uint = 75;
		
		/* Properties */
		public var type:String;
		public var insulinAmount:Number;
		public var insulinID:String = "";
		public var dia:Number = 3;
		public var carbs:Number;
		public var glucose:Number;
		public var glucoseEstimated:Number;
		public var note:String;
		public var timestamp:Number;
		public var ID:String;
		private var insulinScaleFactor:Number;
		
		private var decayedBy:Number = 0;
		private var lastDecayedBy:Number = 0;
		private var initialCarbs:Number;
		private var isDecaying:Number;
		
		public function Treatment(type:String, timestamp:Number, insulin:Number = 0, insulinID:String = "", carbs:Number = 0, glucose:Number = 100, glucoseEstimated:Number = 100, note:String = "")
		{
			this.type = type;
			this.insulinAmount = insulin;
			if (insulinID != "")
			{
				var insulinMatch:Insulin = ProfileManager.getInsulin(insulinID);
				if (insulinMatch != null && !isNaN(insulinMatch.dia))
					this.dia = insulinMatch.dia;
			}
			this.insulinID = insulinID;
			this.carbs = carbs;
			this.glucose = glucose;
			this.glucoseEstimated = glucoseEstimated;
			this.note = note;
			this.timestamp = timestamp;
			this.insulinScaleFactor = 3 / dia;
			this.ID = UniqueId.createEventId();
			
			setInterval(calculateCOB, 5000);
		}
		
		public function calculateIOB():Number
		{
			if (insulinAmount == 0)
				return 0;
			
			var now:Number = new Date().valueOf();
			var minAgo:Number = insulinScaleFactor * (now - timestamp) / 1000 / 60;
			var iob:Number;
			
			if (minAgo < INSULIN_PEAK) 
			{
				var x1:Number = minAgo / 5 + 1;
				iob = insulinAmount * (1 - 0.001852 * x1 * x1 + 0.001852 * x1);
			} else if (minAgo < 180) 
			{
				var x2:Number = (minAgo - 75) / 5;
				iob = insulinAmount * (0.001323 * x2 * x2 - 0.054233 * x2 + 0.55556);
			}
			
			if (iob < 0.001) iob = 0;
			
			return iob;
		}
		
		public function calculateCOB():void
		{
			var cob:Number = 0;
			
			var time:Number = new Date().valueOf();
			
			var delay:Number = 20; //minutes till carbs start decaying
			var delayms:Number = delay * 60 * 1000;
			
			if (!isNaN(carbs) && carbs > 0)
			{
				var carbTime:Number = this.timestamp;
				
				// no previous carb treatment? Set to our start time
				if (lastDecayedBy == 0) 
				{
					lastDecayedBy = carbTime;
				}
				
				var carbs_hr:Number = 30; //30g per hour
				var carbs_min:Number = carbs_hr / 60;
				var carbs_ms:Number = carbs_min / (60 * 1000);
				
				decayedBy = carbTime; // initially set to start time for this treatment
				
				var minutesleft:Number = (lastDecayedBy - carbTime) / 1000 / 60;
				var how_long_till_carbs_start_ms:Number = (lastDecayedBy - carbTime);
				decayedBy += (Math.max(delay, minutesleft) + carbs / carbs_min) * 60 * 1000;
				
				if (delay > minutesleft) 
					initialCarbs = carbs;
				else 
					initialCarbs = carbs + minutesleft * carbs_min;
				
				var startDecay:Number = carbTime + (delay * 60 * 1000);
				
				if (time < lastDecayedBy || time > startDecay) 
					isDecaying = 1;
				else
					isDecaying = 0;
				
				
				////
				var decaysin_hr:Number = (decayedBy - time) / 1000 / 60 / 60;
				
				var totalCOB:Number = Math.min(carbs, decaysin_hr * 30); //30g per hour
				
				////
				
				trace("startDecay", startDecay);
				trace("initialCarbs", initialCarbs);
				trace("decayedBy", decayedBy);
				trace("lastDecayedBy", lastDecayedBy);
				trace("decaysin_hr", decaysin_hr);
				trace("totalCOB", totalCOB);
				
				
				
				lastDecayedBy = decayedBy;
			}
			
			
			//return cob;
			
			/*double delay = 20; // minutes till carbs start decaying
			
			double delayms = delay * 60 * 1000;
			if (treatment.carbs > 0) {
				
				CobCalc thisCobCalc = new CobCalc();
				thisCobCalc.carbTime = treatment.timestamp;
				
				// no previous carb treatment? Set to our start time
				if (lastDecayedBy == 0) {
					lastDecayedBy = thisCobCalc.carbTime;
				}
				
				double carbs_hr = Profile.getCarbAbsorptionRate(time);
				double carbs_min = carbs_hr / 60;
				double carbs_ms = carbs_min / (60 * 1000);
				
				thisCobCalc.decayedBy = thisCobCalc.carbTime; // initially set to start time for this treatment
				
				double minutesleft = (lastDecayedBy - thisCobCalc.carbTime) / 1000 / 60;
				double how_long_till_carbs_start_ms = (lastDecayedBy - thisCobCalc.carbTime);
				thisCobCalc.decayedBy += (Math.max(delay, minutesleft) + treatment.carbs / carbs_min) * 60 * 1000;
				
				if (delay > minutesleft) {
					thisCobCalc.initialCarbs = treatment.carbs;
				} else {
					thisCobCalc.initialCarbs = treatment.carbs + minutesleft * carbs_min;
				}
				double startDecay = thisCobCalc.carbTime + (delay * 60 * 1000);
				
				if (time < lastDecayedBy || time > startDecay) {
					thisCobCalc.isDecaying = 1;
				} else {
					thisCobCalc.isDecaying = 0;
				}
				return thisCobCalc;
				
			} else {
				return null;
			}*/
		}
	}
}