package treatments
{
	import mx.utils.ObjectUtil;
	
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
		public static const TYPE_SENSOR_START:String = "sensorStart";
		
		/* Internal Constants */
		private static const INSULIN_PEAK:uint = 75;
		
		/* Properties */
		public var type:String;
		public var insulinAmount:Number;
		public var insulinID:String = "";
		private var _dia:Number = 3;
		public var carbs:Number;
		public var glucose:Number;
		public var glucoseEstimated:Number;
		public var note:String;
		public var timestamp:Number;
		public var ID:String;
		private var insulinScaleFactor:Number;
		
		public function Treatment(type:String, timestamp:Number, insulin:Number = 0, insulinID:String = "", carbs:Number = 0, glucose:Number = 100, glucoseEstimated:Number = 100, note:String = "", treatmentID:String = null)
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
			this.ID = treatmentID == null ? UniqueId.createEventId() : treatmentID;
		}
		
		public function calculateIOB(time:Number):Number
		{
			if (insulinAmount == 0 || time < timestamp) //If it's not an insulin treatment or requested time is before treatment time
				return 0;
			
			var minAgo:Number = insulinScaleFactor * (time - timestamp) / 1000 / 60;
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
			
			if (iob < 0.001 || isNaN(iob)) iob = 0;
			
			return iob;
		}
		
		private function COBxDrip(lastDecayedBy:Number, time:Number):CobCalc
		{
			var delay:int = 20; // minutes till carbs start decaying
			var delayms:Number = delay * 60 * 1000;
			
			if (carbs > 0)
			{
				var thisCobCalc:CobCalc = new CobCalc();
				thisCobCalc.carbTime = this.timestamp;
				
				// no previous carb treatment? Set to our start time
				if (lastDecayedBy == 0) 
				{
					lastDecayedBy = thisCobCalc.carbTime;
				}
				
				var carbs_hr:Number = 30; //30g per hour
				var carbs_min:Number = carbs_hr / 60;
				var carbs_ms:Number = carbs_min / (60 * 1000);
				
				thisCobCalc.decayedBy = thisCobCalc.carbTime; // initially set to start time for this treatment
				
				var minutesleft:Number = (lastDecayedBy - thisCobCalc.carbTime) / 1000 / 60;
				var how_long_till_carbs_start_ms:Number = (lastDecayedBy - thisCobCalc.carbTime);
				thisCobCalc.decayedBy += (Math.max(delay, minutesleft) + carbs / carbs_min) * 60 * 1000;
				
				if (delay > minutesleft) 
				{
					thisCobCalc.initialCarbs = carbs;
				} 
				else 
				{
					thisCobCalc.initialCarbs = carbs + minutesleft * carbs_min;
				}
				
				var startDecay:Number = thisCobCalc.carbTime + (delay * 60 * 1000);
				
				if (time < lastDecayedBy || time > startDecay) 
				{
					thisCobCalc.isDecaying = 1;
				} 
				else 
				{
					thisCobCalc.isDecaying = 0;
				}
				
				
				return thisCobCalc;
			} 
			else 
			{
				return null;
			}
		}
		
		public function calculateCOB(lastDecayedBy:Number, time:Number):CobCalc
		{
			var absorptionRate:int = ProfileManager.getCarbAbsorptionRate();
			var delay:int = 20;
			var isDecaying:int = 0;
			
			if (carbs > 0)
			{
				var thisCobCalc:CobCalc = new CobCalc();
				thisCobCalc.carbTime = this.timestamp;
				
				var carbs_hr:Number = absorptionRate;
				var carbs_min:Number = carbs_hr / 60;
				
				thisCobCalc.decayedBy = thisCobCalc.carbTime;
				
				var minutesleft:Number = (lastDecayedBy - thisCobCalc.carbTime) / 1000 / 60;
				
				thisCobCalc.decayedBy += (Math.max(delay, minutesleft) + carbs / carbs_min) * 60 * 1000;
				
				
				if (delay > minutesleft) {
					thisCobCalc.initialCarbs = carbs;
				}
				else 
				{
					thisCobCalc.initialCarbs = carbs + minutesleft * carbs_min;
				}
				
				var startDecay:Number = thisCobCalc.carbTime;
				startDecay += (thisCobCalc.carbTime + delay) * 60 * 1000
				
				if (time < lastDecayedBy || time > startDecay) 
				{
					thisCobCalc.isDecaying = 1;
				}
				else 
				{
					thisCobCalc.isDecaying = 0;
				}
				
				return thisCobCalc;
			}
			else 
			{
				return null;
			}
		}

		/**
		 * Getters & Setters
		 */
		public function get dia():Number
		{
			return _dia;
		}

		public function set dia(value:Number):void
		{
			_dia = value;
			this.insulinScaleFactor = 3 / _dia;
		}

	}
}