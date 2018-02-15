package treatments
{
	

	public class Treatment
	{
		/* Public Constants */
		public static const TYPE_MEAL_BOLUS:String = "mealBolus";
		public static const TYPE_CORRECTION_BOLUS:String = "correctionBolus";
		public static const TYPE_CARBS_CORRECTION:String = "carbCorrection";
		public static const TYPE_GLUCOSE_CHECK:String = "glucoseCheck";
		
		/* Internal Constants */
		public static const INSULIN_PEAK:uint = 75;
		
		/* Properties */
		public var type:String;
		public var insulin:Number;
		public var dia:Number;
		public var carbs:Number;
		public var glucose:Number;
		public var note:String;
		public var timestamp:Number;
		private var insulinScaleFactor:Number;
		
		public function Treatment(type:String, insulin:Number = 0, dia:Number = 0, carbs:Number = 0, glucose:Number, note:String = "", timestamp:Number = new Date().valueOf())
		{
			this.type = type;
			this.insulin = insulin;
			this.dia = dia;
			this.carbs = carbs;
			this.glucose = glucose;
			this.note = note;
			this.timestamp = timestamp;
			this.insulinScaleFactor = 3 / dia;
		}
		
		public function calculateIOB():Number
		{
			if (insulin = 0)
				return 0;
			
			var now:Number = new Date().valueOf();
			var minAgo:Number = insulinScaleFactor * (now - timestamp) / 1000 / 60;
			var iob:Number;
			
			if (minAgo < INSULIN_PEAK) 
			{
				var x1:Number = minAgo / 5 + 1;
				iob = insulin * (1 - 0.001852 * x1 * x1 + 0.001852 * x1);
			} else if (minAgo < 180) 
			{
				var x2:Number = (minAgo - 75) / 5;
				iob = insulin * (0.001323 * x2 * x2 - 0.054233 * x2 + 0.55556);
			}
			
			if (iob < 0.001) iob = 0;
			
			return iob;
		}
	}
}