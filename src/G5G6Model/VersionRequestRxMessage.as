package G5G6Model
{
	import flash.utils.ByteArray;
	import flash.utils.Endian;

	public class VersionRequestRxMessage extends TransmitterMessage
	{
		public var opcode:int = 0x4B;
		
		public var status:int = 0;
		public var firmware_version_string:String = "";
		public var bluetooth_firmware_version_string:String = "";
		public var hardwarev:int = 0;
		public var other_firmware_version:String = "";
		public var asic:int = 0;
		
		public function VersionRequestRxMessage(data:ByteArray)
		{
			if (data != null && data.length >= 18) {
				data.position = 0;
				data.endian = Endian.LITTLE_ENDIAN;
				if (data.readByte() == opcode) {
					status = data.readUnsignedByte();
					firmware_version_string = dottedStringFromData(data, 4);
					bluetooth_firmware_version_string = dottedStringFromData(data, 4);
					hardwarev = data.readUnsignedByte();
					other_firmware_version = dottedStringFromData(data, 3);
					asic = getUnsignedShort(data);
				}
			}
		}
		
		private static function getUnsignedShort(data:ByteArray):int {
			return ((data.readByte() & 0xff) + ((data.readByte() & 0xff) << 8));
		}
		
		private static function dottedStringFromData(data:ByteArray, length:int):String {
			var sb:String = "";
			for (var cntr:int = 0; cntr < length;cntr++) {
				if (sb.length > 0) sb += ".";
				sb += data.readUnsignedByte();
			}
			return sb.toString();
		}
	}
}