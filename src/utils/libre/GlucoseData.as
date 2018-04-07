/**
 code ported from xdripplus 
 */
package utils.libre
{
	import spark.collections.Sort;
	import spark.collections.SortField;

	public class GlucoseData
	{
		private static var _dataSortField:SortField;
		private static var _dataSort:Sort;

		public var realDate:Number = 0;
		public var sensorId:String;
		public var sensorTime:Number;
		public var glucoseLevel:int = -1;
		public var glucoseLevelRaw:int = -1;
		//public var phoneDatabaseId:Number = 0;

		public function GlucoseData() {}
		
		/**
		 * sort ascending realDate
		 */
		public static function get dataSort():Sort
		{
			if (_dataSortField == null)
				init_dataSort();
			return _dataSort;
		}

		public static function createGlucoseData( glucoseLevelRaw:int,  timestamp:Number):GlucoseData {
			var returnValue:GlucoseData = new GlucoseData;
			returnValue.glucoseLevelRaw = glucoseLevelRaw;
			returnValue.realDate = timestamp;
			return returnValue;
		}
		
		private static function init_dataSort():void {
			_dataSortField = new SortField();
			_dataSortField.name = "realDate";
			_dataSortField.numeric = true;
			_dataSortField.descending = false;
			_dataSort = new Sort();
			_dataSort.fields=[_dataSortField];
		}
		
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