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
	}
}