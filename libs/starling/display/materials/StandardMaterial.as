package starling.display.materials
{
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.Program3D;
	import flash.display3D.VertexBuffer3D;
	import flash.geom.Matrix3D;
	
	import starling.display.shaders.IShader;
	import starling.display.shaders.fragment.VertexColorFragmentShader;
	import starling.display.shaders.vertex.StandardVertexShader;
	import starling.textures.Texture;

	public class StandardMaterial implements IMaterial
	{
		private var program	:Program3D;
		
		private var _vertexShader	:IShader;
		private var _fragmentShader	:IShader;
		private var _alpha			:Number = 1;
		private var _color			:uint;
		private var colorVector		:Vector.<Number>;
		private var _textures		:Vector.<Texture>;
		
		public function StandardMaterial( vertexShader:IShader = null, fragmentShader:IShader = null )
		{
			this.vertexShader = vertexShader || new StandardVertexShader();
			this.fragmentShader = fragmentShader || new VertexColorFragmentShader();
			textures = new Vector.<Texture>();
			colorVector = new Vector.<Number>();
			color = 0xFFFFFF;
		}
		
		public function dispose():void
		{
			if ( program )
			{
				Program3DCache.releaseProgram3D(program);
				program = null;
			}
			textures = new Vector.<Texture>();
		}
		
		public function restoreOnLostContext():void
		{
			if ( program )
			{
				Program3DCache.releaseProgram3D(program, true);
				program = null;
			}
		}
		
		public function set textures( value:Vector.<Texture> ):void
		{
			_textures = value;
		}
		
		public function get textures():Vector.<Texture>
		{
			return _textures;
		}
		
		public function set vertexShader( value:IShader ):void
		{
			_vertexShader = value;
			if ( program )
			{
				Program3DCache.releaseProgram3D(program);
				program = null;
			}
		}
		
		public function get vertexShader():IShader
		{
			return _vertexShader;
		}
		
		public function set fragmentShader( value:IShader ):void
		{
			_fragmentShader = value;
			if ( program )
			{
				Program3DCache.releaseProgram3D(program);
				program = null;
			}
		}
		
		public function get fragmentShader():IShader
		{
			return _fragmentShader;
		}
		
		
		public function get alpha():Number
		{
			return _alpha;
		}
		
		public function set alpha(value:Number):void
		{
			_alpha = value;
		}
		
		public function get color():uint
		{
			return _color;
		}
		
		public function set color(value:uint):void
		{
			_color = value;
			colorVector[0] = (_color >> 16) / 255;
			colorVector[1] = ((_color & 0x00FF00) >> 8) / 255;
			colorVector[2] = (_color & 0x0000FF) / 255;
		}

		
		public function drawTriangles( context:Context3D, matrix:Matrix3D, vertexBuffer:VertexBuffer3D, indexBuffer:IndexBuffer3D, alpha:Number = 1, numTriangles:int = -1 ):void
		{
			context.setVertexBufferAt( 0, vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3 );
			context.setVertexBufferAt( 1, vertexBuffer, 3, Context3DVertexBufferFormat.FLOAT_4 );
			context.setVertexBufferAt( 2, vertexBuffer, 7, Context3DVertexBufferFormat.FLOAT_2 );
			
			if ( program == null && _vertexShader && _fragmentShader )
			{
				program = Program3DCache.getProgram3D(context, _vertexShader, _fragmentShader);
			}
			context.setProgram(program);
			
			for ( var i:int = 0; i < 8; i++ )
			{
				context.setTextureAt( i, i < _textures.length ? _textures[i].base : null );
			}
			
			context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, matrix, true);
			_vertexShader.setConstants(context, 4);
			colorVector[3] = _alpha*alpha;	// Multiply display obect's alpha by material alpha.
			context.setProgramConstantsFromVector( Context3DProgramType.FRAGMENT, 0, colorVector );
			_fragmentShader.setConstants(context, 1);
			
			context.drawTriangles(indexBuffer, 0, numTriangles);
		}
	}
}