package treatments
{
	public class CobCalcTotals
	{
		public var time:Number;
		public var cob:Number;
		public var carbs:Number;
		public var lastCarbTime:Number;
		public var carbsAbsorbed:Number;
		public var currentDeviation:Number;
		public var maxDeviation:Number;
		public var minDeviation:Number;
		public var slopeFromMaxDeviation:Number;
		public var slopeFromMinDeviation:Number;
		
		public function CobCalcTotals(time:Number, 
									  cob:Number, 
									  carbs:Number = Number.NaN, 
									  lastCarbTime:Number = Number.NaN, 
									  carbsAbsorbed:Number = Number.NaN, 
									  currentDeviation:Number = Number.NaN, 
									  maxDeviation:Number = Number.NaN, 
									  minDeviation:Number = Number.NaN, 
									  slopeFromMaxDeviation:Number = Number.NaN, 
									  slopeFromMinDeviation:Number = Number.NaN
		)
		{
			this.time = time;
			this.cob = cob;
			this.carbs = carbs;
			this.lastCarbTime = lastCarbTime;
			this.carbsAbsorbed = carbsAbsorbed;
			this.currentDeviation = currentDeviation;
			this.maxDeviation = maxDeviation;
			this.minDeviation = minDeviation;
			this.slopeFromMaxDeviation = slopeFromMaxDeviation;
			this.slopeFromMinDeviation = slopeFromMinDeviation;
		}
	}
}