package utils
{
	public class MathHelper
	{
		public function MathHelper()
		{
		}
		
		public static function formatNumberToString (value:Number):String
		{
			var output:String;
			
			if (value < 10)
				output = "0" + value;
			else
				output = String(value);
			
			return output;
		}
		
		public static function formatNightscoutFollowerSlope(value:Number):String
		{
			var output:String;
			
			if (value >= 0)
				output = "+ " + String(value);
			else
				output = "- " + String(Math.abs(value));
			
			return output;
		}
		
		public static function formatNumberToStringWithPrefix(value:Number):String
		{
			var output:String = "";
			
			if (value >= 0)
				output = "+" + value;
			else
				output = String(value);
			
			return output;
		}
	}
}