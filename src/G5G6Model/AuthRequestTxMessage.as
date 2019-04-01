package G5G6Model
{
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	import utils.UniqueId;

	public class AuthRequestTxMessage extends TransmitterMessage
	{
		private var opcode:int = 0x1;
		public var singleUseToken:ByteArray;
		private var endByte:int = 0x2;
		
		public function AuthRequestTxMessage(token_size:int) {
			var uuidBytes:ByteArray = UniqueId.createRandomByteArray(16);
			singleUseToken = new ByteArray();
			singleUseToken.endian = Endian.LITTLE_ENDIAN;
			singleUseToken.writeBytes(uuidBytes, 0, token_size);
			singleUseToken.position = 0;
			
			// Create the byteSequence.
			byteSequence = new ByteArray();
			byteSequence.endian = Endian.LITTLE_ENDIAN;
			byteSequence.writeByte(opcode);
			byteSequence.writeBytes(singleUseToken);
			byteSequence.writeByte(endByte);
			byteSequence.position = 0;
		}
	}
}