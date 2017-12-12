package G5Model
{
	import flash.utils.ByteArray;
	
	import Utilities.UniqueId;

	public class BatteryInfoTxMessage extends TransmitterMessage
	{
		private var opcode:int = 0x22;
		private var crc:ByteArray = UniqueId.calculate(opcode);
		
		public function BatteryInfoTxMessage() {
			byteSequence = new ByteArray();
			byteSequence.writeByte(opcode);
			byteSequence.writeBytes(crc);
			byteSequence.position = 0;
		}
	}
}