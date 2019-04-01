package stats
{
	public class BasicUserStats
	{
		public static const PAGE_ALL:String = "all";
		public static const PAGE_BG_DISTRIBUTION:String = "bgDistribution";
		public static const PAGE_VARIABILITY:String = "variability";
		public static const PAGE_TREATMENTS:String = "treatments";
		
		public var averageGlucose:Number = Number.NaN;
		public var numReadingsDay:Number = Number.NaN;
		public var numReadingsTotal:Number = Number.NaN;
		public var numReadingsLow:Number = Number.NaN;
		public var numReadingsInRange:Number = Number.NaN;
		public var numReadingsHigh:Number = Number.NaN;
		public var percentageLow:Number = Number.NaN;
		public var percentageLowRounded:Number = Number.NaN;
		public var percentageInRange:Number = Number.NaN;
		public var percentageInRangeRounded:Number = Number.NaN;
		public var percentageHigh:Number = Number.NaN;
		public var percentageHighRounded:Number = Number.NaN;
		public var a1c:Number = Number.NaN;
		public var captureRate:Number = Number.NaN;
		public var standardDeviation:Number = Number.NaN;
		public var coefficientOfVariation:Number = Number.NaN;
		public var gvi:Number = Number.NaN;
		public var pgs:Number = Number.NaN;
		public var hourlyChange:Number = Number.NaN;
		public var fluctuation5:Number = Number.NaN;
		public var fluctuation10:Number = Number.NaN;
		public var carbs:Number = Number.NaN;
		public var bolus:Number = Number.NaN;
		public var basal:Number = Number.NaN;
		public var basalRates:Number = Number.NaN;
		public var exercise:Number = Number.NaN;
		public var page:String = "";
		
		public function BasicUserStats(page:String) 
		{
			this.page = page;
		}
	}
}