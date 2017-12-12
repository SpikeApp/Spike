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
	import mx.graphics.IFill;
	
	import spark.components.BorderContainer;
	
	public class MyBorderContainer extends BorderContainer
	{
		static private var iFill:IFill;

		public function MyBorderContainer()
		{
			super();
		}
		
		override public function get backgroundFill():IFill {
			if (!iFill) {
				iFill = new FillForMyBorderContainer();
			}
			return iFill;
		}
		
	}
}