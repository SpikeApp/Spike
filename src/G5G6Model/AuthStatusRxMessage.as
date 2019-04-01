package G5G6Model
{
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	import utils.Trace;

	public class AuthStatusRxMessage extends TransmitterMessage
	{
		private var opcode:int = 0x5;
		public var authenticated:Boolean;
		public var bonded:Boolean;
		
		public function AuthStatusRxMessage(packet:ByteArray) {
			if (packet.length >= 3) {
				if (packet[0] == opcode) {
					byteSequence = new ByteArray();
					byteSequence.endian = Endian.LITTLE_ENDIAN;
					packet.readBytes(byteSequence);
					byteSequence.position = 0;
					authenticated = byteSequence.readUnsignedByte() != 0;
					bonded = byteSequence.readUnsignedByte() != 2;
					myTrace("AuthRequestRxMessage:  authenticated:" + authenticated + "  bonded:" + bonded);
					byteSequence.position = 0;
				}
			}
		}
		
		private static function myTrace(log:String):void {
			Trace.myTrace("AuthStatusRxMessage.as", log);
		}
	}
}