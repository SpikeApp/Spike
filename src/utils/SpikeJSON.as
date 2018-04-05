package utils
{
	import com.adobe.serialization.json.JSON;

	public class SpikeJSON
	{
		/**
		 * Alternative to default AS3 JSON package that doesn't seem to crash when system is low on resources
		 */
		public function SpikeJSON() {}
		
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