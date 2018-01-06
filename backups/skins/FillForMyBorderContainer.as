/**
 Copyright (C) 2017  Johan Degraeve
 
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
package skins
{
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import mx.graphics.IFill;
	
	public class FillForMyBorderContainer implements IFill
	{
		static private var tabBackGroundColors:Array;
		static private var matrix:Matrix;

		public function FillForMyBorderContainer()
		{
		}
		
		public function begin(target:Graphics, targetBounds:Rectangle, targetOrigin:Point):void
		{
			if (tabBackGroundColors == null) {
				tabBackGroundColors = [] ;
				tabBackGroundColors[0] = '0x3B6999';/* gradient will be applied from bottom to top, this is the bottom color*/
				tabBackGroundColors[1] = '0x7EA6CD';
				matrix = new Matrix();
				matrix.createGradientBox(targetBounds.width, targetBounds.height, 1.57, 0, 0);
			}
			
			//only if the tab is selected, then we'll have the gradient backup
			target.beginGradientFill(GradientType.LINEAR, tabBackGroundColors, [0.95,0.95],[0,255],matrix);
			
			//target.drawRect(0, 0, targetBounds.width, targetBounds.height);
			target.drawRoundRectComplex(0,0,targetBounds.width,targetBounds.height,10,10,10,10);
				
			target.endFill();
		}
		
		public function end(target:Graphics):void
		{
		}
	}
}