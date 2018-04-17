package ui.chart
{
	import flash.errors.IllegalOperationError;
	
	import database.BgReading;
	import database.BlueToothDevice;
	import database.CommonSettings;
	
	import model.ModelLocator;
	
	[ResourceBundle("chartscreen")]

	public class GlucoseFactory
	{
		public function GlucoseFactory()
		{
			throw new IllegalOperationError("GlucoseFactory class is not meant to be instantiated!");
		}
		
		public static function getGlucoseOutput(glucoseValue:Number):Object
		{
			var glucoseUnit:String;
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true") 
				glucoseUnit = "mg/dL";
			else
				glucoseUnit = "mmol/L";
			
			var glucoseOutput:String;
			var glucoseValueFormatted:Number;
			if (glucoseValue > 40 && glucoseValue < 400)
			{
				if (glucoseUnit == "mg/dL")
				{
					if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_ROUND_MGDL_ON) != "true")
						glucoseValueFormatted = Math.round(glucoseValue * 10) / 10;
					else
						glucoseValueFormatted = Math.round(glucoseValue);
					glucoseOutput = String( glucoseValueFormatted );
				}
				else
				{
					glucoseValueFormatted = Math.round(BgReading.mgdlToMmol(glucoseValue) * 10) / 10;
					
					if ( glucoseValueFormatted % 1 == 0)
						glucoseOutput = String(glucoseValueFormatted) + ".0";
					else
						glucoseOutput = String(glucoseValueFormatted);
				}
			}
			else
			{
				if (glucoseUnit == "mg/dL")
				{
					if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_ROUND_MGDL_ON) != "true")
						glucoseValueFormatted = Math.round(glucoseValue * 10) / 10;
					else
						glucoseValueFormatted = Math.round(glucoseValue);
				}
				else
					glucoseValueFormatted = Math.round(BgReading.mgdlToMmol(glucoseValue) * 10) / 10;
				
				if (glucoseValue >= 400)
					glucoseOutput = ModelLocator.resourceManagerInstance.getString('chartscreen','glucose_high');
				else if (glucoseValue <= 40 && glucoseValue > 12)
					glucoseOutput = ModelLocator.resourceManagerInstance.getString('chartscreen','glucose_low');
				else
				{
					switch(glucoseValue) {
						case 0:
							glucoseOutput = "??0";
							break;
						case 1:
							glucoseOutput = "?SN";
							break;
						case 2:
							glucoseOutput = "??2";
							break;
						case 3:
							glucoseOutput = "?NA";
							break;
						case 5:
							glucoseOutput = "?NC";
							break;
						case 6:
							glucoseOutput = "?CD";
							break;
						case 9:
							glucoseOutput = "?AD";
							break;
						case 12:
							glucoseOutput = "?RF";
							break;
						default:
							glucoseOutput = "???";
							break;
					}
				}
			}
			
			return {glucoseOutput: glucoseOutput, glucoseValueFormatted: glucoseValueFormatted};
		}
		
		public static function getGlucoseSlope(previousGlucoseValue:Number, previousGlucoseValueFormatted:Number, glucoseValue:Number, glucoseValueFormatted:Number):String
		{
			var glucoseUnit:String;
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true") 
				glucoseUnit = "mg/dL";
			else
				glucoseUnit = "mmol/L";
			
			var slopeOutput:String;
			var glucoseDifference:Number;
			
			if (glucoseUnit == "mg/dL")
				glucoseDifference = Math.round((glucoseValueFormatted - previousGlucoseValueFormatted) * 10) / 10;
			else
			{
				glucoseDifference = Math.round(((Math.round(BgReading.mgdlToMmol(glucoseValue) * 100) / 100) - (Math.round(BgReading.mgdlToMmol(previousGlucoseValue) * 100) / 100)) * 100) / 100;
				
			}
				
			if((glucoseUnit == "mg/dL" && Math.abs(glucoseDifference) > 100) || (glucoseUnit == "mmol/L" && Math.abs(glucoseDifference) > 5.5))
				slopeOutput = ModelLocator.resourceManagerInstance.getString('chartscreen','slope_error');
			else
			{
				var glucoseDifferenceOutput:String;
				
				if (glucoseDifference >= 0)
				{
					glucoseDifferenceOutput = String(glucoseDifference);
						
					if ( glucoseDifference % 1 == 0 && (!BlueToothDevice.isFollower() && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FOLLOWER_MODE) != "Nightscout"))
						glucoseDifferenceOutput += ".0";
						
					slopeOutput = "+ " + glucoseDifferenceOutput;
				}
				else
				{
					glucoseDifferenceOutput = String(Math.abs(glucoseDifference));
						
					if ( glucoseDifference % 1 == 0 && (!BlueToothDevice.isFollower() && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FOLLOWER_MODE) != "Nightscout"))
						glucoseDifferenceOutput += ".0";
						
					slopeOutput = "- " + glucoseDifferenceOutput;
				}
			}
			
			return slopeOutput;
		}
		
		public static function getGlucoseColor(glucoseValue:Number):uint
		{
			//Colors
			var highUrgentGlucoseMarkerColor:uint = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_URGENT_HIGH_COLOR));
			var highGlucoseMarkerColor:uint = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_HIGH_COLOR));
			var inrangeGlucoseMarkerColor:uint = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_IN_RANGE_COLOR));
			var lowGlucoseMarkerColor:uint = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_LOW_COLOR));
			var lowUrgentGlucoseMarkerColor:uint = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_URGENT_LOW_COLOR));
			
			//Threshold
			var glucoseUrgentLow:Number = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_URGENT_LOW_MARK));
			var glucoseLow:Number = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_LOW_MARK));
			var glucoseHigh:Number = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_HIGH_MARK));
			var glucoseUrgentHigh:Number = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_URGENT_HIGH_MARK));
			
			var color:uint;
			if(glucoseValue >= glucoseUrgentHigh)
				color = highUrgentGlucoseMarkerColor;
			else if(glucoseValue >= glucoseHigh)
				color = highGlucoseMarkerColor;
			else if(glucoseValue > glucoseLow && glucoseValue < glucoseHigh)
				color = inrangeGlucoseMarkerColor;
			else if(glucoseValue <= glucoseLow && glucoseValue > glucoseUrgentLow)
				color = lowGlucoseMarkerColor;
			else if(glucoseValue <= glucoseUrgentLow)
				color = lowUrgentGlucoseMarkerColor;
			
			return color;
		}
		
		public static function formatIOB(IOBValue:Number):String
		{
			var value:String = String(IOBValue);
			var valueLength:int = value.length;
			var decimalPosition:int = -1;
			if (value.indexOf(".") != -1)
				decimalPosition = value.indexOf(".");
			if (value.indexOf(",") != -1)
				decimalPosition = value.indexOf(",");
			
			if (decimalPosition != -1 && decimalPosition == valueLength - 2)
				value = value + "0";
			else if (decimalPosition == -1 && valueLength == 1 && IOBValue != 0)
				value = value + ".00";
			else if (IOBValue == 0)
				value = "0.00";
			
			value += "U";
			
			return value;
		}
		public static function formatCOB(COBValue:Number):String
		{
			var value:String = String(COBValue);
			var valueLength:int = value.length;
			var decimalPosition:int = -1;
			if (value.indexOf(".") != -1)
				decimalPosition = value.indexOf(".");
			if (value.indexOf(",") != -1)
				decimalPosition = value.indexOf(",");
			
			if (decimalPosition == -1 && COBValue != 0)
				value = value + ".0";
			else if (COBValue == 0)
				value = "0.0";
			
			value += "g";
			
			return value;
		}
	}
}