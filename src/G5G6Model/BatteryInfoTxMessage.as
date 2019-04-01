package G5G6Model
{
	import flash.utils.ByteArray;
	
	import utils.Trace;
	import utils.UniqueId;

	public class BatteryInfoTxMessage extends TransmitterMessage
	{
		private var opcode:int = 0x22;
		private var crc:ByteArray = UniqueId.calculate(opcode);
		
		public function BatteryInfoTxMessage() {
			byteSequence = new ByteArray();
			byteSequence.writeByte(opcode);
			byteSequence.writeBytes(crc);
			Trace.myTrace("BatteryInfoTxMessage.as", "BatteryInfoTx" + UniqueId.bytesToHex(byteSequence));
			byteSequence.position = 0;
		}
	}
}