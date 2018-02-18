package ui.screens.display.menu 
{
	import events.ScreenEvent;
	
	import feathers.controls.List;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.data.ListCollection;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.ModelLocator;
	
	import starling.events.Event;
	import starling.textures.Texture;
	
	import ui.AppInterface;
	import ui.screens.Screens;
	
	import utils.Constants;
	import utils.DeviceInfo;
	
	[ResourceBundle("mainmenu")]
	
	public class MenuList extends List 
	{
		/* Textures */
		private var graphIconTexture:Texture;
		private var sensorIconTexture:Texture;
		private var transmitterIconTexture:Texture;
		private var settingsIconTexture:Texture;
		private var bugReportIconTexture:Texture;
		private var disclaimerIconTexture:Texture;

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
			if (DeviceInfo.getDeviceType() != DeviceInfo.IPHONE_X)
				paddingTop = 20; //Statusbar Size
			else
				paddingTop = 50; //Statusbar Size
			minWidth = Constants.stageWidth >> 2;
			minWidth += 85;
			hasElasticEdges = false;
			clipContent = false;
		}
		
		private function setupContent():void
		{
			graphIconTexture = MaterialDeepGreyAmberMobileThemeIcons.timelineTexture;
			sensorIconTexture = MaterialDeepGreyAmberMobileThemeIcons.sensorTexture;
			transmitterIconTexture = MaterialDeepGreyAmberMobileThemeIcons.bluetoothTexture;
			settingsIconTexture = MaterialDeepGreyAmberMobileThemeIcons.settingsTexture;
			bugReportIconTexture = MaterialDeepGreyAmberMobileThemeIcons.bugReportTexture;
			disclaimerIconTexture = MaterialDeepGreyAmberMobileThemeIcons.disclaimerTexture;
			
			dataProvider = new ListCollection(
				[
					{ screen: Screens.GLUCOSE_CHART, label: ModelLocator.resourceManagerInstance.getString('mainmenu','graph_menu_item'), icon: graphIconTexture },
					{ screen: Screens.SENSOR_STATUS, label: ModelLocator.resourceManagerInstance.getString('mainmenu','sensor_menu_item'), icon: sensorIconTexture },
					{ screen: Screens.TRANSMITTER, label: ModelLocator.resourceManagerInstance.getString('mainmenu','transmitter_menu_item'), icon: transmitterIconTexture },
					{ screen: Screens.SETTINGS_MAIN, label: ModelLocator.resourceManagerInstance.getString('mainmenu','settings_menu_item'), icon: settingsIconTexture },
					{ screen: Screens.SETTINGS_BUG_REPORT, label: ModelLocator.resourceManagerInstance.getString('mainmenu','bug_report_menu_item'), icon: bugReportIconTexture },
					{ screen: Screens.DISCLAIMER, label: ModelLocator.resourceManagerInstance.getString('mainmenu','disclaimer_menu_item'), icon: disclaimerIconTexture }
				]);
			selectedIndex = 0;
			
			itemRendererFactory = function():IListItemRenderer 
			{
				const item:DefaultListItemRenderer = new DefaultListItemRenderer();
				item.labelField = "label";
				item.iconSourceField = "icon";
				return item;
			};
			
			addEventListener( Event.CHANGE, onMenuChanged );
		}
		
		/**
		 * Event Listeners
		 */
		private function onMenuChanged():void 
		{
			if(AppInterface.instance.drawers.isLeftDrawerOpen)
			{
				//Notify special screens like the chart settings screen that a new sceen is about to enter
				dispatchEventWith( ScreenEvent.BEGIN_SWITCH);
				
				//Notify navigator of the new screen to be switch to
				const screenName:String = selectedItem.screen as String;
				dispatchEventWith( ScreenEvent.SWITCH, false, { screen: screenName } );
			}
		}	
		
		/**
		 * Utility
		 */
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
			
			super.dispose();
		}
	}
}
