package G5G6Model
{
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	import utils.Trace;
	import utils.UniqueId;

	public class VersionRequestTxMessage extends TransmitterMessage
	{
		private var opcode:int = 0x4A;
		private var crc:ByteArray = UniqueId.calculate(opcode);

		public function VersionRequestTxMessage()
		{
			byteSequence = new ByteArray();
			byteSequence.endian = Endian.LITTLE_ENDIAN;
			byteSequence.writeByte(opcode);
			byteSequence.writeBytes(crc);
			byteSequence.position = 0;
		}
	}
}