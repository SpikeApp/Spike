package utils
{
	import database.BgReading;
	import database.CGMBlueToothDevice;
	import database.CommonSettings;
	
	import model.ModelLocator;
	
	[ResourceBundle("generalsettingsscreen")]
	
	public class BgGraphBuilder
	{
		public static const MAX_SLOPE_MINUTES:int = 21;
		
		public function BgGraphBuilder()
		{
		}
		
		/**
		 * unitIsMgDl = true if unit as set by user is mgdl<br>
		 * value in mgdl<br>
		 */
		public static function unitizedString(value:Number, unitIsMgDl:Boolean):String {
			var returnValue:String;
			if (value >= 400) {
				returnValue = "HIGH";
			} else if (value >= 40) {
				if(unitIsMgDl) {
					returnValue = Math.round(value).toString();
				} else {
					returnValue = ((Math.round(value * BgReading.MGDL_TO_MMOLL * 10))/10).toString();
				}
			} else if (value > 12) {
				returnValue = "LOW";
			} else {
				switch(value) {
					case 0:
						returnValue = "??0";
						break;
					case 1:
						returnValue = "?SN";
						break;
					case 2:
						returnValue = "??2";
						break;
					case 3:
						returnValue = "?NA";
						break;
					case 5:
						returnValue = "?NC";
						break;
					case 6:
						returnValue = "?CD";
						break;
					case 9:
						returnValue = "?AD";
						break;
					case 12:
						returnValue = "?RF";
						break;
					default:
						returnValue = "???";
						break;
				}
			}
			return returnValue;
		}
		
		public static function unitizedDeltaString(showUnit:Boolean,highGranularity:Boolean):String {
			
			var last2:Array = BgReading.latest(2, CGMBlueToothDevice.isFollower());
			if(last2.length < 2 || (last2[0] as BgReading).timestamp - (last2[1] as BgReading).timestamp > MAX_SLOPE_MINUTES * 60 * 1000) {
				// don't show delta if there are not enough values or the values are more than 20 mintes apart
				return "???";
			}
			
			var value:Number = BgReading.currentSlope(CGMBlueToothDevice.isFollower()) * 5 * 60 * 1000;
			if(Math.abs(value) > 100){
				// a delta > 100 will not happen with real BG values -> problematic sensor data
				return "ERR";
			}

			value = unitized(value);
			
			var valueAsString:String = "";
			if (highGranularity) {
				if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) != "true") {
					valueAsString = ((Math.round(value * 100))/100).toString();
				} else {
					valueAsString = ((Math.round(value * 10))/10).toString();	
				}
			} else {
				if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) != "true") {
					valueAsString = ((Math.round(value * 10))/10).toString();
				} else {
					valueAsString = (Math.round(value)).toString();
				}
			}
			
			var delta_sign:String = "";
			if (value > 0) { delta_sign = "+"; }
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true") {
				return delta_sign + valueAsString + (showUnit ? (" " + ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','mgdl')):"");
			} else {
				return delta_sign + valueAsString + (showUnit ? (" " + ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','mmol')):"");
			}
		}
		
		public static function unitized(value:Number):Number {
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true") {
				return value;
			} else {
				return value * BgReading.MGDL_TO_MMOLL;
			}
			return Number.NaN;
		}
	}
}