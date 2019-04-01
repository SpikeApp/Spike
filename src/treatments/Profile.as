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
		public var trendCorrections:String;
		public var timestamp:Number;
		public var trend45Up:Number = 0;
		public var trend90Up:Number = 0;
		public var trendDoubleUp:Number = 0;
		public var trend45Down:Number = 0;
		public var trend90Down:Number = 0;
		public var trendDoubleDown:Number = 0;
		public var insulinCurve:String = "";
		public var useCustomInsulinPeakTime:Boolean = false;
		public var insulinPeakTime:Number = Number.NaN;
		
		public function Profile(id:String, time:String, name:String, insulinToCarbRatios:String, insulinSensitivityFactors:String, carbsAbsorptionRate:Number, basalRates:String, targetGlucoseRates:String, trendCorrections:String, timestamp:Number)
		{
			this.ID = id;
			this.time = time;
			this.name = name;
			this.insulinToCarbRatios = insulinToCarbRatios;
			this.insulinSensitivityFactors = insulinSensitivityFactors;
			this.carbsAbsorptionRate = carbsAbsorptionRate;
			this.basalRates = basalRates;
			this.targetGlucoseRates = targetGlucoseRates;
			this.trendCorrections = trendCorrections;
			this.timestamp = timestamp;
			
			parseTrends();
		}
		
		public function parseTrends():void
		{
			if (trendCorrections != null && trendCorrections != "")
			{
				var trendsList:Array = trendCorrections.split("|");
				var trendsObject:Object = {};
				
				for (var i:int = 0; i < trendsList.length; i++) 
				{
					var record:String = trendsList[i];
					var recordList:Array = record.split(":");
					trendsObject[recordList[0]] = recordList[1];
				}
				
				if (trendsObject["up45"]) trend45Up = Number(trendsObject["up45"]);
				if (trendsObject["up90"]) trend90Up = Number(trendsObject["up90"]);
				if (trendsObject["upDouble"]) trendDoubleUp = Number(trendsObject["upDouble"]);
				if (trendsObject["down45"]) trend45Down = Number(trendsObject["down45"]);
				if (trendsObject["down90"]) trend90Down = Number(trendsObject["down90"]);
				if (trendsObject["downDouble"]) trendDoubleDown = Number(trendsObject["downDouble"]);
				
				trendsList.length = 0;
				trendsList = null;
				trendsObject = null;
			}
		}
	}
}