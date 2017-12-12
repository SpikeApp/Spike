package display.settings.main
{
	import flash.system.System;
	
	import feathers.controls.List;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.data.ListCollection;
	import feathers.layout.AnchorLayoutData;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import screens.Screens;
	
	import starling.display.Image;
	import starling.events.Event;
	import starling.textures.Texture;
	
	import ui.AppInterface;
	
	import utils.Constants;

	public class SettingsList extends List 
	{
		/* Display Objects */
		private var chevronIconTexture:Texture;
		private var generalIconImage:Image;
		private var transmitterIconImage:Image;
		private var chartIconImage:Image;
		private var alarmsIconImage:Image;
		private var speechIconImage:Image;
		private var shareIconImage:Image;
		private var logginTracingIconImage:Image;
		
		public function SettingsList()
		{
			super();
		}
		override protected function initialize():void 
		{
			super.initialize();
			
			/* Properties */
			clipContent = false;
			isSelectable = true;
			autoHideBackground = true;
			hasElasticEdges = false;
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
			
			/* Icons */
			chevronIconTexture = MaterialDeepGreyAmberMobileThemeIcons.chevronRightTexture;
			generalIconImage = new Image(chevronIconTexture);
			transmitterIconImage = new Image(chevronIconTexture);
			chartIconImage = new Image(chevronIconTexture);
			alarmsIconImage = new Image(chevronIconTexture);
			speechIconImage = new Image(chevronIconTexture);
			shareIconImage = new Image(chevronIconTexture);
			logginTracingIconImage = new Image(chevronIconTexture);
			
			/* Data */
			dataProvider = new ListCollection(
				[
					{ screen: Screens.SETTINGS_GENERAL, label: "General", accessory: generalIconImage },
					{ screen: Screens.SETTINGS_TRANSMITTER, label: "Transmitter", accessory: transmitterIconImage },
					{ screen: Screens.SETTINGS_CHART, label: "Chart", accessory: chartIconImage },
					{ screen: Screens.SETTINGS_ALARMS, label: "Alarms", accessory: alarmsIconImage },
					{ screen: Screens.SETTINGS_SPEECH, label: "Speech", accessory: speechIconImage },
					{ screen: Screens.SETTINGS_SHARE, label: "Share", accessory: shareIconImage },
					{ screen: Screens.SETTINGS_LOGGING_TRACING, label: "Logging & Tracing", accessory: logginTracingIconImage }
				]);
			
			/* Renderer */
			itemRendererFactory = function():IListItemRenderer 
			{
				const item:DefaultListItemRenderer = new DefaultListItemRenderer();
				item.labelField = "label";
				item.accessoryField = "accessory";
				item.isQuickHitAreaEnabled = true;
				return item;
			};
			layoutData = new AnchorLayoutData( 0, 0, 0, 0 );
			addEventListener( Event.CHANGE, onMenuChanged );
		}
		
		private function onMenuChanged(e:Event):void 
		{
			const screenName:String = selectedItem.screen as String;
			AppInterface.instance.navigator.pushScreen( screenName );
		}
		
		override public function dispose():void
		{
			if(chevronIconTexture != null)
			{
				chevronIconTexture.dispose();
				chevronIconTexture = null;
			}
			if(generalIconImage != null)
			{
				generalIconImage.dispose();
				generalIconImage = null;
			}
			if(transmitterIconImage != null)
			{
				transmitterIconImage.dispose();
				transmitterIconImage = null;
			}
			if(chartIconImage != null)
			{
				chartIconImage.dispose();
				chartIconImage = null;
			}
			if(alarmsIconImage != null)
			{
				alarmsIconImage.dispose();
				alarmsIconImage = null;
			}
			if(speechIconImage != null)
			{
				speechIconImage.dispose();
				speechIconImage = null;
			}
			if(shareIconImage != null)
			{
				shareIconImage.dispose();
				shareIconImage = null;
			}
			if(logginTracingIconImage != null)
			{
				logginTracingIconImage.dispose();
				logginTracingIconImage = null;
			}
			
			System.pauseForGCIfCollectionImminent(0);
			
			super.dispose();
		}
	}
}