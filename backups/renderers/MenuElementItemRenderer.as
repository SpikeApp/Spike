/**
 Copyright (C) 2013  hippoandfriends
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/gpl.txt>.
 
 */
package renderers
{
	import spark.components.LabelItemRenderer;
	
	
	/**
	 * 
	 * itemrenderer for menu item for example in home screen or settings screen
	 * 
	 */
	public class MenuElementItemRenderer extends LabelItemRenderer
	{
		public function MenuElementItemRenderer()
		{
			//TODO: implement function
			super();
		}
		
		/**
		 * @private
		 *
		 * Override this setter to respond to data changes
		 */
		override public function set data(value:Object):void
		{
			super.data = value;
			// the data has changed.  push these changes down in to the 
			// subcomponents here    		
		} 
		
		/**
		 * @private
		 * 
		 * Override this method to create children for your item renderer 
		 */	
		override protected function createChildren():void
		{
			super.createChildren();
			// create any additional children for your item renderer here
		}
		
		/**
		 * @private
		 * 
		 * Override this method to change how the item renderer 
		 * sizes itself. For performance reasons, do not call 
		 * super.measure() unless you need to.
		 */ 
		override protected function measure():void
		{
			super.measure();
			// measure all the subcomponents here and set measuredWidth, measuredHeight, 
			// measuredMinWidth, and measuredMinHeight      		
		}
		
		/**
		 * @private
		 * 
		 * Override this method to change how the background is drawn for 
		 * item renderer.  For performance reasons, do not call 
		 * super.drawBackground() if you do not need to.
		 */
		override protected function drawBackground(unscaledWidth:Number, 
												   unscaledHeight:Number):void
		{
			//super.drawBackground(unscaledWidth, unscaledHeight);
			// do any drawing for the background of the item renderer here   
			if(itemIndex % 2 == 0) {
				graphics.beginFill(styleManager.getStyleDeclaration(".listAlternatingColors").getStyle("color1"),1);
			} else {
				graphics.beginFill(styleManager.getStyleDeclaration(".listAlternatingColors").getStyle("color2"),1);
			}
			graphics.drawRect(0, 0, unscaledWidth, unscaledHeight);
			graphics.endFill();
				
		}
		
		/**
		 * @private
		 *  
		 * Override this method to change how the background is drawn for this 
		 * item renderer. For performance reasons, do not call 
		 * super.layoutContents() if you do not need to.
		 */
		override protected function layoutContents(unscaledWidth:Number, 
												   unscaledHeight:Number):void
		{
			super.layoutContents(unscaledWidth, unscaledHeight);
			// layout all the subcomponents here      		
		}
		
	}
}