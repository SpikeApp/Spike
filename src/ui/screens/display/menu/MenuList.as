package ui.screens.display.menu 
{
	import flash.display.StageOrientation;
	
	import database.CGMBlueToothDevice;
	import database.CommonSettings;
	
	import events.ScreenEvent;
	
	import feathers.controls.Label;
	import feathers.controls.LayoutGroup;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.data.ListCollection;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.HorizontalLayout;
	import feathers.layout.VerticalAlign;
	import feathers.layout.VerticalLayout;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.ModelLocator;
	
	import starling.display.Image;
	import starling.events.Event;
	import starling.events.ResizeEvent;
	import starling.textures.Texture;
	import starling.utils.SystemUtil;
	
	import ui.AppInterface;
	import ui.screens.Screens;
	import ui.screens.display.SpikeList;
	
	import utils.Constants;
	import utils.DeviceInfo;
	
	[ResourceBundle("mainmenu")]
	
	public class MenuList extends SpikeList 
	{
		/* Textures */
		private var graphIconTexture:Texture;
		private var sensorIconTexture:Texture;
		private var transmitterIconTexture:Texture;
		private var settingsIconTexture:Texture;
		private var bugReportIconTexture:Texture;
		private var disclaimerIconTexture:Texture;
		private var helpIconTexture:Texture;
		private var donateIconTexture:Texture;
		private var historyIconTexture:Texture;
		private var spikeLogoIconTexture:Texture;
		private var logoImage:Image;
		private var logoContainer:LayoutGroup;
		private var previousSelectedIndex:int;
		private var initialStart:Boolean = true;
		private var maxTempWidth:Number = 0;
		private var lastCalculatedWidth:Number = 0;

		public function MenuList() 
		{
			super();
		}
		
		override protected function initialize():void 
		{
			super.initialize();
			
			setupProperties();
			setupContent();	
		}
		
		/**
		 * Functionality
		 */
		private function setupProperties():void
		{
			width = Constants.stageWidth >> 2;
			width += 85;
			hasElasticEdges = false;
			clipContent = false;
			
			selectedIndex = Constants.isPortrait ? 1 : 0;
			previousSelectedIndex = selectedIndex;
			
			setTopPadding();
		}
		
		private function setupContent():void
		{
			graphIconTexture = MaterialDeepGreyAmberMobileThemeIcons.timelineTexture;
			sensorIconTexture = MaterialDeepGreyAmberMobileThemeIcons.sensorTexture;
			transmitterIconTexture = MaterialDeepGreyAmberMobileThemeIcons.bluetoothTexture;
			settingsIconTexture = MaterialDeepGreyAmberMobileThemeIcons.settingsTexture;
			bugReportIconTexture = MaterialDeepGreyAmberMobileThemeIcons.bugReportTexture;
			disclaimerIconTexture = MaterialDeepGreyAmberMobileThemeIcons.disclaimerTexture;
			helpIconTexture = MaterialDeepGreyAmberMobileThemeIcons.spikeHelpTexture;
			donateIconTexture = MaterialDeepGreyAmberMobileThemeIcons.donateTexture;
			historyIconTexture = MaterialDeepGreyAmberMobileThemeIcons.historyTexture;
			spikeLogoIconTexture = MaterialDeepGreyAmberMobileThemeIcons.spikeLogoColorTexture;
			
			var logoContainerLayout:HorizontalLayout = new HorizontalLayout();
			logoContainerLayout.horizontalAlign = HorizontalAlign.CENTER;
			logoContainerLayout.verticalAlign = VerticalAlign.MIDDLE;
			logoContainerLayout.paddingBottom = logoContainerLayout.paddingTop = 20;
			logoContainer = new LayoutGroup();
			logoContainer.layout = logoContainerLayout;
			logoContainer.width = width;
			
			logoImage = new Image(spikeLogoIconTexture);
			logoContainer.addChild(logoImage);
			logoContainer.validate();
			
			refreshContent();
			
			(layout as VerticalLayout).hasVariableItemDimensions = true;
			
			addEventListener( Event.CHANGE, onMenuChanged );
		}
		
		public function refreshContent():void
		{
			maxTempWidth = 0;
			setupRenderFactory();
			
			var menuItems:Array = [];
			if (Constants.isPortrait) menuItems.push( { label: "", accessory: logoContainer, selectable: false, index: menuItems.length } );
			menuItems.push( { screen: Screens.GLUCOSE_CHART, label: ModelLocator.resourceManagerInstance.getString('mainmenu','graph_menu_item'), icon: graphIconTexture, selectable: true, index: menuItems.length } );
			if (!CGMBlueToothDevice.isFollower())
			{
				menuItems.push( { screen: Screens.SENSOR_STATUS, label: ModelLocator.resourceManagerInstance.getString('mainmenu','sensor_menu_item'), icon: sensorIconTexture, selectable: true, index: menuItems.length } );
				menuItems.push( { screen: Screens.TRANSMITTER, label: ModelLocator.resourceManagerInstance.getString('mainmenu','transmitter_menu_item'), icon: transmitterIconTexture, selectable: true, index: menuItems.length } );
			}
			menuItems.push( { screen: Screens.SETTINGS_MAIN, label: ModelLocator.resourceManagerInstance.getString('mainmenu','settings_menu_item'), icon: settingsIconTexture, selectable: true, index: menuItems.length } );
			if (!CGMBlueToothDevice.isFollower())
				menuItems.push( { screen: Screens.HISTORY, label: ModelLocator.resourceManagerInstance.getString('mainmenu','history_menu_item'), icon: historyIconTexture, selectable: true, index: menuItems.length } );
			menuItems.push( { screen: Screens.HELP, label: ModelLocator.resourceManagerInstance.getString('mainmenu','help_menu_item'), icon: helpIconTexture, selectable: true, index: menuItems.length } );
			menuItems.push( { screen: Screens.SETTINGS_BUG_REPORT, label: ModelLocator.resourceManagerInstance.getString('mainmenu','bug_report_menu_item'), icon: bugReportIconTexture, selectable: true, index: menuItems.length } );
			menuItems.push( { screen: Screens.DISCLAIMER, label: ModelLocator.resourceManagerInstance.getString('mainmenu','disclaimer_menu_item'), icon: disclaimerIconTexture, selectable: true, index: menuItems.length } );
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PERIPHERAL_TYPE) != "")
				menuItems.push( { screen: Screens.DONATE, label: ModelLocator.resourceManagerInstance.getString('mainmenu','donate_menu_item'), icon: donateIconTexture, selectable: true, index: menuItems.length } );
			
			dataProvider = new ListCollection(menuItems);
			
			removeEventListener( Event.CHANGE, onMenuChanged );
			selectedIndex = previousSelectedIndex;
			addEventListener( Event.CHANGE, onMenuChanged );
		}
		
		private function setTopPadding():void
		{
			if (Constants.isPortrait)
			{
				if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr)
					paddingTop = 33;
				else
					paddingTop = 1;
			}
			else
			{
				if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr)
					paddingTop = 12;
				else
					paddingTop = 20;
			}
		}
		
		/**
		 * Event Listeners
		 */
		private function onMenuChanged():void 
		{
			if (selectedItem == null || (selectedItem != null && selectedItem.screen == null) ) return;
			
			if(AppInterface.instance.drawers.isLeftDrawerOpen)
			{
				previousSelectedIndex = selectedIndex;
				
				//Notify special screens like the chart settings screen that a new sceen is about to enter
				dispatchEventWith( ScreenEvent.BEGIN_SWITCH);
				
				//Notify navigator of the new screen to be switch to
				const screenName:String = selectedItem.screen as String;
				dispatchEventWith( ScreenEvent.SWITCH, false, { screen: screenName } );
			}
		}	
		
		override protected function setupRenderFactory():void
		{
			/* List Item Renderer */
			maxTempWidth = 0;
			
			itemRendererFactory = function():IListItemRenderer 
			{
				const item:DefaultListItemRenderer = new DefaultListItemRenderer();
				item.labelField = "label";
				item.iconSourceField = "icon";
				item.selectableField = "selectable";
				item.itemHasSelectable = true;
				item.accessoryLabelProperties.wordWrap = true;
				item.defaultLabelProperties.wordWrap = true;
				item..labelFunction = function( item:Object ):String
				{
					var tempLabel:Label = new Label();
					tempLabel.text = item.label;
					tempLabel.validate();
					if (tempLabel.width > maxTempWidth) maxTempWidth = tempLabel.width;
					
					return item.label;
				};
				
				if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr && !Constants.isPortrait && Constants.currentOrientation == StageOrientation.ROTATED_RIGHT)
					item.paddingLeft = 40;
				return item;
			};
		}
		
		override protected function onStarlingResize(event:ResizeEvent):void 
		{
			if (!initialStart)
			{
				removeEventListener( Event.CHANGE, onMenuChanged );
				
				if (selectedItem != null && selectedItem.index != null)
				{
					selectedIndex = !Constants.isPortrait ? selectedItem.index - 1 : selectedItem.index + 1;
				}
				else
				{
					selectedIndex = !Constants.isPortrait ? previousSelectedIndex - 1 : previousSelectedIndex + 1;
				}
				
				previousSelectedIndex = selectedIndex;
				
				addEventListener( Event.CHANGE, onMenuChanged );
			}
			else
				initialStart = false;
			
			SystemUtil.executeWhenApplicationIsActive(setupRenderFactory);
			SystemUtil.executeWhenApplicationIsActive(setTopPadding);
			SystemUtil.executeWhenApplicationIsActive(refreshContent);
		}
		
		/**
		 * Utility
		 */
		override protected function draw():void
		{
			if (Constants.isPortrait || Constants.deviceModel != DeviceInfo.IPHONE_X_Xs_XsMax_Xr || (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr && Constants.currentOrientation != StageOrientation.ROTATED_RIGHT))
			{
				if (maxTempWidth != 0 && maxTempWidth > 100)
				{
					width = maxTempWidth + 85;
					lastCalculatedWidth = width;
					if (logoContainer != null) 
					{
						logoContainer.width = width;
						logoImage.x = (width / 2) - 5;
					}
				}
			}
			else if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr && !Constants.isPortrait && Constants.currentOrientation == StageOrientation.ROTATED_RIGHT)
			{
				if (lastCalculatedWidth == 0) maxTempWidth + 85;
				if (lastCalculatedWidth + 45 > 100)
					width = lastCalculatedWidth + 45;
			}
			
			AppInterface.instance.drawers.invalidate();
			
			super.draw();
		}
		
		override public function dispose():void
		{
			removeEventListener( Event.CHANGE, onMenuChanged );
			
			if(graphIconTexture != null)
			{
				graphIconTexture.dispose();
				graphIconTexture = null;
			}
			
			if(sensorIconTexture != null)
			{
				sensorIconTexture.dispose();
				sensorIconTexture = null;
			}
			
			if(transmitterIconTexture != null)
			{
				transmitterIconTexture.dispose();
				transmitterIconTexture = null;
			}
			
			if(settingsIconTexture != null)
			{
				settingsIconTexture.dispose();
				settingsIconTexture = null;
			}
			
			if(bugReportIconTexture != null)
			{
				bugReportIconTexture.dispose();
				bugReportIconTexture = null;
			}
			
			if(disclaimerIconTexture != null)
			{
				disclaimerIconTexture.dispose();
				disclaimerIconTexture = null;
			}
			
			if(helpIconTexture != null)
			{
				helpIconTexture.dispose();
				helpIconTexture = null;
			}
			
			if(donateIconTexture != null)
			{
				donateIconTexture.dispose();
				donateIconTexture = null;
			}
			
			if(historyIconTexture != null)
			{
				historyIconTexture.dispose();
				historyIconTexture = null;
			}
			
			if(spikeLogoIconTexture != null)
			{
				spikeLogoIconTexture.dispose();
				spikeLogoIconTexture = null;
			}
			
			if(logoImage != null)
			{
				logoImage.removeFromParent();
				if (logoImage.texture != null)
					logoImage.texture.dispose();
				logoImage.dispose();
				logoImage = null;
			}
			
			if(logoContainer != null)
			{
				logoContainer.dispose();
				logoContainer = null;
			}
			
			super.dispose();
		}
	}
}
