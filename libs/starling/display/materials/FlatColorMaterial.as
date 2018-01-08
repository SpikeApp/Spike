package starling.display.materials
{
	import starling.display.shaders.IShader;
	
	public class FlatColorMaterial extends StandardMaterial
	{
		public function FlatColorMaterial(color:uint = 0xFFFFFF)
		{
			this.color = color;
		}
	}
}