package ui.shapes
{
	import flash.display.BitmapData;
	
	import starling.display.DisplayObject;
	import starling.display.Image;
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.textures.Texture;

	public class SpikeDisplayObject extends Sprite
	{
		public var container:Sprite;
		public var background:Quad;
		public var shape:DisplayObject;
		public var bitmapData:BitmapData;
		public var texture:Texture;
		public var image:Image;
		
		public function SpikeDisplayObject(container:Sprite, background:Quad, shape:DisplayObject, bitmapData:BitmapData, texture:Texture, image:Image)
		{
			this.container = container;
			this.background = background;
			this.shape = shape;
			this.bitmapData = bitmapData;
			this.texture = texture;
			this.image = image;
			
			addChild(image);
		}
		
		override public function dispose():void
		{
			if (background != null)
			{
				background.removeFromParent();
				background.dispose();
				background = null;
			}
			
			if (shape != null)
			{
				shape.removeFromParent();
				shape.dispose();
				shape = null;
			}
			
			if (container != null)
			{
				container.removeFromParent();
				container.dispose();
				container = null;
			}
			
			if (image != null)
			{
				image.removeFromParent();
				image.dispose();
				image = null;
			}
			
			if (texture != null)
			{
				texture.dispose();
				texture = null;
			}
			
			if (bitmapData != null)
			{
				bitmapData.dispose();
				bitmapData = null;
			}
			
			super.dispose();
		}
	}
}