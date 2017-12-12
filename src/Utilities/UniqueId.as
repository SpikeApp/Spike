/**
 Copyright (C) 2016  Johan Degraeve
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/gpl.txt>.
 
 */
package Utilities
{
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	import mx.utils.StringUtil;

	public class UniqueId
	{
		private static var ALPHA_CHAR_CODES:Array = ["0","1","2","3","4","5","6","7","8","9","a","b","c","d","e","f"];
		private static var hexArray:Array = ["0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F"];
		
		public function UniqueId()
		{
		}
		
		/**
		 * creates an event id of 24 chars, compliant with the way Nightscout expects it
		 */
		public static function createEventId():String {
			var eventId:Array = new Array(24);
			var date:String = (new Date()).valueOf().toString();
			for (var i:int = 0; i < date.length; i++) {
				eventId[i] = date.charAt(i);
			}
			for (; i < eventId.length;i++) {
				eventId[i] = ALPHA_CHAR_CODES[Math.floor(Math.random() *  16)];
			}
			var returnValue:String = "";
			for (i = 0; i < eventId.length; i++)
				returnValue += eventId[i];
			return returnValue;
		}
		
		/**
		 * creates random string of digits only, length 
		 */
		public static function createNonce(length:int):String {
			var nonce:Array = new Array(length);
			for (var i:int = 0; i < length; i++) {
				nonce[i] = ALPHA_CHAR_CODES[Math.floor(Math.random() *  10)];
			}
			var returnValue:String = "";
			for (i = 0; i < nonce.length; i++)
			returnValue += nonce[i];
			return returnValue;
		}
		
		public static function createRandomByteArray(length:int):ByteArray {
			var byteArray:ByteArray = new ByteArray();
			for (var i:int = 0; i < length; i++) {
				byteArray.writeByte(Math.floor(Math.random() *  256));
			}
			return byteArray;
		}
		
		public static function bytesToHex(bytes:ByteArray):String {
			if (bytes == null) return "<empty>";
			var hexChars:Array = new Array(bytes.length * 2);
			for (var j:int = 0; j < bytes.length; j++) {
				var v:int = bytes[j] & 0xFF;
				hexChars[j * 2] = hexArray[v >>> 4];
				hexChars[j * 2 + 1] = hexArray[v & 0x0F];
			}
			var returnValue:String = "";
			for (var cntr:int = 0; cntr < hexChars.length; cntr++) {
				returnValue += hexChars[cntr];
			}
			return returnValue;
		}
		
		public static function hexStringToByteArray(str:String) :ByteArray {
				str = StringUtil.trim(str.toUpperCase());
				if (str.length == 0) return null;
				var len:int = str.length;
				var data:ByteArray = new ByteArray();
				for (var i:int = 0; i < len; i += 2) {
					data.writeByte(parseInt(str.substring(i, i + 2), 16));
					//data[i / 2] = (byte) ((Character.digit(str.charAt(i), 16) << 4) + Character.digit(str.charAt(i + 1), 16));
				}
				return data;
		}
		
		public static function calculate(b:int):ByteArray {
			var crcShort:int = 0;
			crcShort = ((crcShort >>> 8) | (crcShort << 8)) & 0xffff;
			crcShort ^= (b & 0xff);
			crcShort ^= ((crcShort & 0xff) >> 4);
			crcShort ^= (crcShort << 12) & 0xffff;
			crcShort ^= ((crcShort & 0xFF) << 5) & 0xffff;
			crcShort &= 0xffff;
			var returnValue:ByteArray = new ByteArray();
			returnValue.writeByte(crcShort & 0xff);
			returnValue.writeByte((crcShort >> 8) & 0xff);
			return returnValue;
		}
		
		public static function byteArrayToString(value:ByteArray):String {
			if (value == null)
				return "[]";
			if (value.length == 0) {
				return "[]";
			}
			var returnValue:String;
			var copyOfValue:ByteArray = new ByteArray();
			copyOfValue.endian = Endian.LITTLE_ENDIAN;
			copyOfValue.writeBytes(value);
			//value.readBytes(copyOfValue);
			returnValue = '[';
			for (var i:int = 0; i < copyOfValue.length; i++) {
				returnValue += copyOfValue[i];
				if (i < copyOfValue.length - 1) {
					returnValue += ", ";
				}
			}
			returnValue += ']';
			return returnValue;
		}
	}
}