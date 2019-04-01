package G5G6Model
{
	import flash.utils.ByteArray;
	import flash.utils.Endian;

	public class AuthChallengeTxMessage extends TransmitterMessage
	{
		
		public var opcode:int = 0x4;
		public var challengeHash:ByteArray;
		
		public function AuthChallengeTxMessage(challenge:ByteArray) {
			challengeHash = new ByteArray();
			challenge.endian = Endian.LITTLE_ENDIAN;
			challengeHash.writeBytes(challenge);
			challenge.readBytes(challengeHash);
			challenge.position = 0;
			byteSequence = new ByteArray();//ByteBuffer.allocate(9);
			byteSequence.endian = Endian.LITTLE_ENDIAN;
			byteSequence.writeByte(opcode);//data.put(opcode);
			byteSequence.writeBytes(challengeHash);//data.put(challengeHash);
			byteSequence.position = 0;
		}		
		
	}
}