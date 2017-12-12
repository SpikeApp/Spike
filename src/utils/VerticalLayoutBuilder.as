package utils 
{
	
	import feathers.layout.VerticalLayout;
	
	public class VerticalLayoutBuilder 
	{
		
		private var layout:VerticalLayout;
		
		public function VerticalLayoutBuilder() 
		{
			layout = new VerticalLayout();
		}
		
		public function setGap( gap:Number ):VerticalLayoutBuilder 
		{
			layout.gap = gap;
			return this;
		}
		
		public function setFirstGap( gap:Number ):VerticalLayoutBuilder 
		{
			layout.firstGap = gap;
			return this;
		}
		
		public function setLastGap( gap:Number ):VerticalLayoutBuilder 
		{
			layout.lastGap = gap;
			return this;
		}
		
		public function setPadding( padding:Number ):VerticalLayoutBuilder 
		{
			layout.padding = padding;
			return this;
		}
		
		public function setHorizontalAlign( align:String ):VerticalLayoutBuilder 
		{
			layout.horizontalAlign = align;
			return this;
		}
		
		public function setVerticalAlign( align:String ):VerticalLayoutBuilder 
		{
			layout.verticalAlign = align;
			return this;
		}
		
		public function build():VerticalLayout 
		{
			return layout;
		}	
	}
}
