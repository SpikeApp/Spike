package utils
{
	import com.hurlant.crypto.symmetric.AESKey;
	import com.hurlant.crypto.symmetric.BlowFishKey;
	import com.hurlant.crypto.symmetric.DESKey;
	import com.hurlant.util.Base64;
	import com.hurlant.util.Hex;
	
	import flash.utils.ByteArray;

	public class Cryptography
	{
		public static function encryptStringLight(key:String, content:String):String
		{
			if (content == "")
				return "";
			
			var keyBytes:ByteArray = Hex.toArray(key);
			var contentBytes:ByteArray = Hex.toArray(Hex.fromString(content));
			
			var blowFish:BlowFishKey = new BlowFishKey(keyBytes);
			blowFish.encrypt(contentBytes);
			contentBytes.compress();
			
			return Base64.encodeByteArray(contentBytes);
		}
		
		public static function encryptStringStrong(key:String, content:String):String
		{
			if (content == "")
				return "";
			
			var keyBytes:ByteArray = Hex.toArray(key);
			var contentBytes:ByteArray = Hex.toArray(Hex.fromString(content));
			
			var aes:AESKey = new AESKey(keyBytes);
			aes.encrypt( contentBytes );
			contentBytes.compress();
			
			return Base64.encodeByteArray(contentBytes);
		}
		
		public static function decryptStringLight(key:String, content:String):String
		{
			if (content == "")
				return "";
			
			var keyBytes:ByteArray = Hex.toArray(key);
			var contentBytes:ByteArray = Base64.decodeToByteArray(content);
			contentBytes.uncompress();
			
			var blowFish:BlowFishKey = new BlowFishKey(keyBytes);
			blowFish.decrypt(contentBytes);
			
			return contentBytes.toString();
		}
		
		public static function decryptStringStrong(key:String, content:String):String
		{
			if (content == "")
				return "";
			
			var keyBytes:ByteArray = Hex.toArray(key);
			var contentBytes:ByteArray = Base64.decodeToByteArray(content);
			contentBytes.uncompress();
			
			var aes:AESKey = new AESKey(keyBytes);
			aes.decrypt( contentBytes );
			
			return contentBytes.toString();
		}
	}
}