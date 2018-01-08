package starling.display.materials
{
	import flash.display3D.Context3D;
	import flash.display3D.Program3D;
	import flash.utils.Dictionary;
	
	import starling.display.shaders.IShader;

	internal class Program3DCache
	{
		// The number of Program3D instances the cache will allow to sit
		// unreferenced before flushing unused instances.
		// Having this buffer avoids the (common) situation where a Program3D
		// gets created/destroyed each frame in-line with draw/clear() calls
		// to the graphics API. Which is expensive to say the least.
		private static const LAZY_CACHE_SIZE			:uint = 8;
		
		private static var uid							:int = 0;
		private static var uidByShaderTable				:Dictionary = new Dictionary(true);
		private static var programByUIDTable			:Object = {};
		private static var uidByProgramTable			:Dictionary = new Dictionary(false);
		private static var numReferencesByProgramTable	:Dictionary = new Dictionary();
		private static var cacheSize					:uint;		// The number of Program3D instances stored in this cache.
		
		public static function getProgram3D( context:Context3D, vertexShader:IShader, fragmentShader:IShader ):Program3D
		{
			var vertexShaderUID:int = uidByShaderTable[vertexShader];
			if ( vertexShaderUID == 0 )
			{
				vertexShaderUID = uidByShaderTable[vertexShader] = ++uid;
			}
			
			var fragmentShaderUID:int = uidByShaderTable[fragmentShader];
			if ( fragmentShaderUID == 0 )
			{
				fragmentShaderUID = uidByShaderTable[fragmentShader] = ++uid;
			}
			
			var program3DUID:String = vertexShaderUID + "_" + fragmentShaderUID;
			
			var program3D:Program3D = programByUIDTable[program3DUID];
			if ( program3D == null )
			{
				program3D = programByUIDTable[program3DUID] = context.createProgram();
				uidByProgramTable[program3D] = program3DUID;
				program3D.upload( vertexShader.opCode, fragmentShader.opCode );
				numReferencesByProgramTable[program3D] = 0;
				cacheSize++;
			}
			
			numReferencesByProgramTable[program3D]++;
			
			if ( cacheSize > LAZY_CACHE_SIZE )
			{
				flush();
			}
			
			return program3D;
		}
		
		public static function releaseProgram3D( program3D:Program3D, forceFlush:Boolean = false ):void
		{
			if ( !numReferencesByProgramTable[program3D] )
			{
				throw( new Error( "Program3D is not in cache" ) );
				return;
			}
	
			numReferencesByProgramTable[program3D]--;
			if ( forceFlush )
				flush();
		}
		
		/**
		 * This is called when the number of cached programs exceeds LAZY_CACHE_SIZE.
		 * Kicks out a single Program3D's with zero references.
		 */
		private static function flush():void
		{
			for ( var uid:String in programByUIDTable )
			{
				var program3D:Program3D = programByUIDTable[uid];
				var numReferences:int = numReferencesByProgramTable[program3D];
				if ( numReferences > 0 )
				{
					continue;
				}
				
				program3D.dispose();
				delete numReferencesByProgramTable[program3D];
				var program3DUID:String = uidByProgramTable[program3D];
				delete programByUIDTable[program3DUID];
				delete uidByProgramTable[program3D];
				cacheSize--;
				return;
			}
		}
	}
}