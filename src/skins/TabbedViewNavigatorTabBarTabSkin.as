package skins
{
	import flash.display.GradientType;
	import flash.geom.Matrix;
	
	import spark.skins.mobile.supportClasses.ButtonBarButtonSkinBase;

	public class TabbedViewNavigatorTabBarTabSkin extends ButtonBarButtonSkinBase
	{
		
		static private var tabBackGroundColors:Array;
		static private var matrix:Matrix;

		
		public function TabbedViewNavigatorTabBarTabSkin()
		{
		}
		
		override protected function drawBackground(unscaledWidth:Number, unscaledHeight:Number):void
		{
			var isSelected:Boolean = currentState.indexOf("Selected") >= 0;
			
			if (tabBackGroundColors == null) {
				tabBackGroundColors = [] ;
				tabBackGroundColors[0] = styleManager.getStyleDeclaration(".tabbartabbuttoncolor").getStyle("colorbottom");/* gradient will be applied from bottom to top, this is the bottom color*/
				tabBackGroundColors[1] = styleManager.getStyleDeclaration(".tabbartabbuttoncolor").getStyle("colortop");
				matrix = new Matrix();
				matrix.createGradientBox(unscaledWidth, unscaledHeight, 1.57, 0, 0);
				}
			
			//only if the tab is selected, then we'll have the gradient backup
			if (isSelected)
				graphics.beginGradientFill(GradientType.LINEAR, tabBackGroundColors, [100,100],[0,255],matrix);
			else 
				graphics.beginFill(0,1);
			
			graphics.drawRect(0, 0, unscaledWidth, unscaledHeight);
			graphics.endFill();
		}
	}
}