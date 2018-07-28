package G5G6Model
{
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	import utils.Trace;

	public class BatteryInfoRxMessage extends TransmitterMessage
	{
		private var opcode:int = 0x23;
		
		public var status:int;
		public var voltagea:int;
		public var voltageb:int;
		public var resist:int;
		public var runtime:int;
		public var temperature:int;
		
		public function BatteryInfoRxMessage(packet:ByteArray) {
			if (packet.length >= 12) {
				byteSequence = new ByteArray();
				byteSequence.endian = Endian.LITTLE_ENDIAN;
				byteSequence.writeBytes(packet);
				byteSequence.position = 0;
				if (byteSequence.readByte() == opcode) {
					//status = byteSequence.readByte();
					status = byteSequence.readByte();
					voltagea = byteSequence.readUnsignedShort();
					voltageb = byteSequence.readUnsignedShort();
					resist = byteSequence.readUnsignedShort();
					runtime = byteSequence.readUnsignedByte();
					temperature = byteSequence.readByte(); // not sure if signed or not, but <0c or >127C seems unlikely! 
				} else {
					myTrace("Invalid opcode for BatteryInfoRxMessage");
				}
				byteSequence.position = 0;
			}
		}
		
		private static function myTrace(log:String):void {
			Trace.myTrace("BatteryInfoRxMessage.as", log);
		}
		
		public function toString():String {
			var returnValue:String = "Status: " + TransmitterStatus.getBatteryLevel(status).toString() + 
				" / VoltageA: " + voltagea + 
				"/ VoltageB: " + voltageb + 
				"/ Resistance: " + resist + 
				"/ Run Time: " + runtime +
				"/ Temperature: " + temperature;
			return returnValue;
		}
		
	}
}