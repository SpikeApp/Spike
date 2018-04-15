package treatments
{
	public class Profile
	{
		/* Properties */
		public var ID:String;
		public var time:String;
		public var name:String;
		public var insulinToCarbRatios:String;
		public var insulinSensitivityFactors:String;
		public var carbsAbsorptionRate:Number;
		public var basalRates:String;
		public var targetGlucoseRates:String;
		public var timestamp:Number;
		
		public function Profile(id:String, time:String, name:String, insulinToCarbRatios:String, insulinSensitivityFactors:String, carbsAbsorptionRate:Number, basalRates:String, targetGlucoseRates:String, timestamp:Number)
		{
			this.ID = id;
			this.time = time;
			this.name = name;
			this.insulinToCarbRatios = insulinToCarbRatios;
			this.insulinSensitivityFactors = insulinSensitivityFactors;
			this.carbsAbsorptionRate = carbsAbsorptionRate;
			this.basalRates = basalRates;
			this.targetGlucoseRates = targetGlucoseRates;
			this.timestamp = timestamp;
		}
	}
}