package G5Model
{
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import Utilities.Trace;

	public class SensorRxMessage extends TransmitterMessage
	{
		private var opcode:int = 0x2f;
		public var timestamp:Number;
		public var unfiltered:Number;
		public var filtered:Number;
		public var transmitterStatus:TransmitterStatus;
		
		public function SensorRxMessage(packet:ByteArray) {
			if (packet.length >= 14) {
				byteSequence = new ByteArray();
				byteSequence.endian = Endian.LITTLE_ENDIAN;
				byteSequence.writeBytes(packet);
				byteSequence.position = 0;
				if (byteSequence.readByte() == opcode) {
					
					transmitterStatus = TransmitterStatus.getBatteryLevel(byteSequence.readByte());
					timestamp = byteSequence.readInt();
					unfiltered = byteSequence.readInt();
					filtered = byteSequence.readInt();
					myTrace("SensorRX dbg: timestamp = " + timestamp + ", unfiltered = " + unfiltered + ", filtered = " + filtered + ", transmitterStatus = " + transmitterStatus.toString());
				}
				byteSequence.position = 0;
			} else {
				myTrace("SensorRX packet.length < 14");
			}
		}
		
		private static function myTrace(log:String):void {
			Trace.myTrace("SensorRxMessage.as", log);
		}
	}
}