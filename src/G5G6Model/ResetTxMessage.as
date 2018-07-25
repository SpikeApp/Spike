package G5G6Model
{
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	import utils.UniqueId;

	public class ResetTxMessage extends TransmitterMessage
	{
		public var opcode:int = 0x42;
		public var crc:ByteArray = UniqueId.calculate(opcode);

		public function ResetTxMessage()
		{
			byteSequence = new ByteArray();
			byteSequence.endian = Endian.LITTLE_ENDIAN;
			byteSequence.writeByte(opcode);
			byteSequence.writeBytes(crc);
			byteSequence.position = 0;
		}
	}
}