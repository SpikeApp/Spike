package utils 
{
	
	import feathers.layout.HorizontalLayout;
	
	public class HorizontalLayoutBuilder 
	{
		
		private var mLayout:HorizontalLayout;
		
		public function HorizontalLayoutBuilder() 
		{
			mLayout = new HorizontalLayout();
		}
		
		public function setGap( gap:Number ):HorizontalLayoutBuilder 
		{
			mLayout.gap = gap;
			return this;
		}
		
		public function setFirstGap( gap:Number ):HorizontalLayoutBuilder 
		{
			mLayout.firstGap = gap;
			return this;
		}
		
		public function setLastGap( gap:Number ):HorizontalLayoutBuilder 
		{
			mLayout.lastGap = gap;
			return this;
		}
		
		public function setPadding( padding:Number ):HorizontalLayoutBuilder 
		{
			mLayout.padding = padding;
			return this;
		}
		
		public function setHorizontalAlign( align:String ):HorizontalLayoutBuilder 
		{
			mLayout.horizontalAlign = align;
			return this;
		}
		
		public function setVerticalAlign( align:String ):HorizontalLayoutBuilder 
		{
			mLayout.verticalAlign = align;
			return this;
		}
		
		public function build():HorizontalLayout 
		{
			return mLayout;
		}	
	}
}
