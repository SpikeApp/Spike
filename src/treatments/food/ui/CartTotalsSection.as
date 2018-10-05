package treatments.food.ui
{
	import feathers.controls.Label;
	import feathers.controls.LayoutGroup;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalAlign;
	import feathers.layout.VerticalLayout;
	
	import ui.screens.display.LayoutFactory;
	
	public class CartTotalsSection extends LayoutGroup
	{
		//Display Objects
		public  var title:Label;
		public var value:Label;
		
		public function CartTotalsSection(width:Number)
		{
			super();
			
			this.width = width;
			
			createLayout();
			createContent();	
		}
		
		private function createLayout():void
		{
			var verticalLayout:VerticalLayout = new VerticalLayout();
			verticalLayout.horizontalAlign = HorizontalAlign.CENTER;
			verticalLayout.verticalAlign = VerticalAlign.TOP;
			verticalLayout.gap = 5;
			verticalLayout.paddingTop = verticalLayout.paddingBottom = 10;
			this.layout = verticalLayout;
		}
		
		private function createContent():void
		{
			title = LayoutFactory.createLabel("", HorizontalAlign.LEFT, VerticalAlign.TOP, 14, true);
			title.wordWrap = true; 
			title.width = width;
			addChild(title);
			
			value = LayoutFactory.createLabel("", HorizontalAlign.LEFT, VerticalAlign.TOP, 14, false);
			value.wordWrap = true;
			value.width = width;
			addChild(value);
		}
		
		override public function dispose():void
		{
			if (title != null)
			{
				title.removeFromParent();
				title.dispose();
				title = null;
			}
			
			if (value != null)
			{
				value.removeFromParent();
				value.dispose();
				value = null;
			}
			
			super.dispose();
		}
	}
}