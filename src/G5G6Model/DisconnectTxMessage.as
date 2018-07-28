package G5G6Model
{
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	public class DisconnectTxMessage extends TransmitterMessage
	{
		private var opcode:int = 0x09;
		
		public function DisconnectTxMessage() {
			byteSequence = new ByteArray();
			byteSequence.endian = Endian.LITTLE_ENDIAN;
			byteSequence.writeByte(opcode);
			byteSequence.position = 0;
		}	
	}
}