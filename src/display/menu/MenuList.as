package display.menu 
{
	import flash.system.System;
	
	import events.ScreenEvent;
	
	import feathers.controls.List;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.data.ListCollection;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import screens.Screens;
	
	import starling.events.Event;
	import starling.textures.Texture;
	
	import ui.AppInterface;
	
	import utils.Constants;
	
	public class MenuList extends List 
	{
		/* Textures */
		private var graphIconTexture:Texture;
		private var sensorIconTexture:Texture;
		private var transmitterIconTexture:Texture;
		private var settingsIconTexture:Texture;
		private var disclaimerIconTexture:Texture;

		public function MenuList() 
		{
			super();
		}
		
		override protected function initialize():void 
		{
			super.initialize();
			
			paddingTop = 20; //Status Bar Size
			minWidth = Constants.stageWidth >> 2;
			minWidth += 85;
			hasElasticEdges = false;
			clipContent = false;
			
			graphIconTexture = MaterialDeepGreyAmberMobileThemeIcons.timelineTexture;
			sensorIconTexture = MaterialDeepGreyAmberMobileThemeIcons.sensorTexture;
			transmitterIconTexture = MaterialDeepGreyAmberMobileThemeIcons.bluetoothTexture;
			settingsIconTexture = MaterialDeepGreyAmberMobileThemeIcons.settingsTexture;
			disclaimerIconTexture = MaterialDeepGreyAmberMobileThemeIcons.disclaimerTexture;
			
			dataProvider = new ListCollection(
				[
					{ screen: Screens.GLUCOSE_CHART, label: "Graph", icon: graphIconTexture },
					{ screen: Screens.SENSOR_STATUS, label: "Sensor", icon: sensorIconTexture },
					{ screen: Screens.TRANSMITTER, label: "Transmitter", icon: transmitterIconTexture },
					{ screen: Screens.SETTINGS_MAIN, label: "Settings", icon: settingsIconTexture },
					{ screen: Screens.DISCLAIMER, label: "Disclaimer", icon: disclaimerIconTexture }
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
			
			if(disclaimerIconTexture != null)
			{
				disclaimerIconTexture.dispose();
				disclaimerIconTexture = null;
			}
			
			System.pauseForGCIfCollectionImminent(0);
			
			super.dispose();
		}
	}
}
