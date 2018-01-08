package starling.display.shaders.vertex
{
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.utils.getTimer;
	
	import starling.display.shaders.AbstractShader;
	
	public class AnimateUVVertexShader extends AbstractShader
	{
		public var uSpeed	:Number = 1;
		public var vSpeed	:Number = 1;
		
		public function AnimateUVVertexShader( uSpeed:Number = 1, vSpeed:Number = 1 )
		{
			this.uSpeed = uSpeed;
			this.vSpeed = vSpeed;
			
			var agal:String =
				"m44 op, va0, vc0 \n" +			// Apply matrix
				"mov v0, va1 \n" +				// Copy color to v0
				"sub vt0, va2, vc4 \n" +
				"mov v1, vt0 \n"				
			
			compileAGAL( Context3DProgramType.VERTEX, agal );
		}
		
		override public function setConstants( context:Context3D, firstRegister:int ):void
		{
			var phase:Number = getTimer()/1000;
			var uOffset:Number = phase * uSpeed;
			var vOffset:Number = phase * vSpeed;
			
			context.setProgramConstantsFromVector( Context3DProgramType.VERTEX, firstRegister, Vector.<Number>([ uOffset, vOffset, 0, 0 ]) );
		}
	}
}