package treatments
{
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
		public static const INSULIN_PEAK:uint = 75;
		
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
		
		public function Treatment(type:String, timestamp:Number, insulin:Number = 0, insulinID:String = "", carbs:Number = 0, glucose:Number = 100, glucoseEstimated:Number = 100, note:String = "")
		{
			this.type = type;
			this.insulinAmount = insulin;
			if (insulinID != "")
				this.dia = ProfileManager.getInsulin(insulinID).dia;
			this.insulinID = insulinID;
			this.carbs = carbs;
			this.glucose = glucose;
			this.glucoseEstimated = glucoseEstimated;
			this.note = note;
			this.timestamp = timestamp;
			this.insulinScaleFactor = 3 / dia;
			this.ID = UniqueId.createEventId();
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
	}
}