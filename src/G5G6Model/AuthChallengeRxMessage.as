package G5G6Model
{
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	public class AuthChallengeRxMessage extends TransmitterMessage
	{
		public var opcode:int = 0x3;
		public var tokenHash:ByteArray;
		public var challenge:ByteArray;
		
		public function AuthChallengeRxMessage(data:ByteArray) {
			if (data.length >= 17) {
				if (data.readByte() == opcode) {
					tokenHash = new ByteArray();
					tokenHash.endian = Endian.LITTLE_ENDIAN;
					challenge = new ByteArray();
					challenge.endian = Endian.LITTLE_ENDIAN;
					data.readBytes(tokenHash, 0, 8);//Arrays.copyOfRange(data, 1, 9);
					data.readBytes(challenge, 0, 8);//Arrays.copyOfRange(data, 9, 17);
				}
			}
		}
	}
}