package treatments.food.ui
{
	import feathers.controls.Label;
	import feathers.controls.LayoutGroup;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalAlign;
	import feathers.layout.VerticalLayout;
	
	import starling.display.DisplayObject;
	
	import ui.screens.display.LayoutFactory;
	
	public class NutritionFactsSectionWithAction extends LayoutGroup
	{
		//Display Objects
		public var title:Label;
		
		public function NutritionFactsSectionWithAction(width:Number)
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
			this.layout = verticalLayout;
		}
		
		private function createContent():void
		{
			title = LayoutFactory.createLabel("", HorizontalAlign.CENTER, VerticalAlign.TOP, 14, true);
			title.width = width;
			title.maxWidth = width;
			title.wordWrap = true;
			
			addChild(title);
		}
		
		public function setComponent(component:DisplayObject):void
		{
			addChild(component);
		}
		
		override public function dispose():void
		{
			if (title != null)
			{
				title.removeFromParent();
				title.dispose();
				title = null;
			}
			
			super.dispose();
		}
	}
}