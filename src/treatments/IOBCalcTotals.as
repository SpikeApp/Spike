package treatments
{
	public class IOBCalcTotals
	{
		public var iob:Number;
		public var activity:Number;
		public var bolusiob:Number;
		public var bolusinsulin:Number;
		public var time:Number;
		public var lastBolusTime:Number;
		public var lastTemp:Number;
		public var firstInsulinTime:Number;
		
		public function IOBCalcTotals(time:Number, activity:Number, iob:Number, bolusiob:Number, bolusinsulin:Number, firstInsulinTime:Number)
		{
			this.time = time;
			this.activity = activity;
			this.iob = iob;
			this.bolusiob = bolusiob;
			this.bolusinsulin = bolusinsulin;
			this.firstInsulinTime = firstInsulinTime;
		}
	}
}