package utils
{
	import com.adobe.serialization.json.JSON;

	public class SpikeJSON
	{
		public function SpikeJSON()
		{
		}
		
		public static function stringify(object:Object):String
		{
			return com.adobe.serialization.json.JSON.encode(object);
		}
		
		public static function parse(string:String):Object
		{
			return com.adobe.serialization.json.JSON.decode(string, true);
		}
	}
}