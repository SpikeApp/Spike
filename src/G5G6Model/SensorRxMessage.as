package G5G6Model
{
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	import database.CGMBlueToothDevice;
	
	import utils.Trace;

	public class SensorRxMessage extends TransmitterMessage
	{
		private var opcode:int = 0x2f;
		public var timestamp:Number;
		public var unfiltered:Number;
		public var filtered:Number;
		public var transmitterStatus:TransmitterStatus;
		
		private function scale(unscaled:int) {
			myTrace("SensorRX dbg: unscaled = " + unscaled);
			
			if (CGMBlueToothDevice.isDexcomG5())
			{
				return unscaled;
			}
			else
			{
				if (G5G6VersionInfo.getG5G6VersionInfo().firmware_version_string.indexOf("1") == 0)
				{
					// G6v1
					return unscaled * 34;
				}
				else
				{
					// G6v2
					return (unscaled - 1151395987) / 113432;
				}
			}
		}
		
		public function SensorRxMessage(packet:ByteArray) {
			if (packet.length >= 14) {
				byteSequence = new ByteArray();
				byteSequence.endian = Endian.LITTLE_ENDIAN;
				byteSequence.writeBytes(packet);
				byteSequence.position = 0;
				if (byteSequence.readByte() == opcode) {
					
					transmitterStatus = TransmitterStatus.getBatteryLevel(byteSequence.readByte());
					timestamp = byteSequence.readInt();
					unfiltered = scale(byteSequence.readInt());
					filtered = scale(byteSequence.readInt());
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