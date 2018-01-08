package starling.display.materials
{
	import starling.display.shaders.IShader;
	import starling.display.shaders.fragment.TextureFragmentShader;
	import starling.display.shaders.fragment.TextureVertexColorFragmentShader;
	import starling.display.shaders.fragment.VertexColorFragmentShader;
	import starling.display.shaders.vertex.StandardVertexShader;
	import starling.textures.Texture;
	
	public class TextureMaterial extends StandardMaterial
	{
		public function TextureMaterial(texture:Texture, color:uint = 0xFFFFFF)
		{
			super(new StandardVertexShader(), new TextureVertexColorFragmentShader());
			textures[0] = texture;
			this.color = color;
		}
	}
}