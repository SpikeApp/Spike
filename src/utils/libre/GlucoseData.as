/**
 code ported from xdripplus 
 */
package utils.libre
{
	public class GlucoseData
	{
		public var realDate:Number = 0;
		public var sensorId:String;
		public var sensorTime:Number;
		public var glucoseLevel:int = -1;
		public var glucoseLevelRaw:int = -1;
		//public var phoneDatabaseId:Number = 0;

		public function GlucoseData() {}

		/**
		 * if glucoseLevelParam == 0, then GlucoseData.glucoseLevel is used
		 */
		public function glucose(glucoseLevelParam:int, mmol:Boolean):String {
			if (glucoseLevelParam == 0)
				glucoseLevelParam = glucoseLevel;
			if (mmol) {
				return (Math.round(glucoseLevelParam/18 * 10)).toString();
			} else {
				return (new Number(glucoseLevelParam)).toString();				
			}
		}
	}
}