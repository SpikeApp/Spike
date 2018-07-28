package G5G6Model
{
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import utils.Trace;
	import utils.UniqueId;

	public class KeepAliveTxMessage extends TransmitterMessage
	{
		public static const opcode:int = 0x6;
		private var time:Number;
		
		public function KeepAliveTxMessage(time:Number)
		{
			this.time = time;
			byteSequence = new ByteArray();
			byteSequence.endian = Endian.LITTLE_ENDIAN;
			byteSequence.writeByte(opcode);
			byteSequence.writeByte(time);
			byteSequence.position = 0;
			myTrace("New KeepAliveRequestTxMessage: " + UniqueId.bytesToHex(byteSequence));
		}
		
		private static function myTrace(log:String):void {
			Trace.myTrace("KeepAliveTxMessage.as", log);
		}
	}
}