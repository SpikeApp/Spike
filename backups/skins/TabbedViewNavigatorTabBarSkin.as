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
/**
 * attempt to have a tabbarbutton with gradient background
 * based on 
*/
package skins
{
	import spark.components.ButtonBarButton;
	import spark.components.DataGroup;
	import spark.skins.mobile.ButtonBarSkin;
	import spark.skins.mobile.supportClasses.ButtonBarButtonClassFactory;
	import spark.skins.mobile.supportClasses.TabbedViewNavigatorTabBarHorizontalLayout;
	
	public class TabbedViewNavigatorTabBarSkin extends ButtonBarSkin
	{
		public function TabbedViewNavigatorTabBarSkin()
		{
			super();
		}
		
		override protected function createChildren():void
		{
			if (!firstButton)
			{
				firstButton = new ButtonBarButtonClassFactory(ButtonBarButton);
				firstButton.skinClass = skins.TabbedViewNavigatorTabBarTabSkin
			}
			
			if (!lastButton)
			{
				lastButton = new ButtonBarButtonClassFactory(ButtonBarButton);
				lastButton.skinClass = skins.TabbedViewNavigatorTabBarTabSkin;
			}
			
			if (!middleButton)
			{
				middleButton = new ButtonBarButtonClassFactory(ButtonBarButton);
				middleButton.skinClass = skins.TabbedViewNavigatorTabBarTabSkin;
			}
			
			if (!dataGroup)
			{
				// TabbedViewNavigatorButtonBarHorizontalLayout for even percent layout
				var tabLayout:TabbedViewNavigatorTabBarHorizontalLayout = 
					new TabbedViewNavigatorTabBarHorizontalLayout();
				tabLayout.useVirtualLayout = false;
				
				dataGroup = new DataGroup();
				dataGroup.layout = tabLayout;
				addChild(dataGroup);
			}
		}
		
	}
}