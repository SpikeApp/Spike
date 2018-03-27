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
			trace("Spike JSON stringify called");
			return com.adobe.serialization.json.JSON.encode(object);
		}
		
		public static function parse(string:String):*
		{
			trace("Spike JSON parse called");
			com.adobe.serialization.json.JSON.decode(string);
		}
	}
}