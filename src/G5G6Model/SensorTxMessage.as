package G5G6Model
{
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	import utils.Trace;
	import utils.UniqueId;

	public class SensorTxMessage extends TransmitterMessage
	{
		private var opcode:int = 0x2e;
		private var crc:ByteArray = UniqueId.calculate(opcode);
		
		public function SensorTxMessage() {
			byteSequence = new ByteArray();
			byteSequence.endian = Endian.LITTLE_ENDIAN;
			byteSequence.writeByte(opcode);
			byteSequence.writeBytes(crc);
			byteSequence.position = 0;
			myTrace("SensorTx dbg: " + UniqueId.bytesToHex(byteSequence));
		}
		
		private static function myTrace(log:String):void {
			Trace.myTrace("SensorTxMessage.as", log);
		}
	}
}