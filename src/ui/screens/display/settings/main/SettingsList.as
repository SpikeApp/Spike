package ui.screens.display.settings.main
{
	import feathers.controls.List;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.data.ListCollection;
	import feathers.layout.AnchorLayoutData;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.ModelLocator;
	
	import starling.core.Starling;
	import starling.display.Image;
	import starling.events.Event;
	import starling.events.ResizeEvent;
	import starling.textures.Texture;
	
	import ui.AppInterface;
	import ui.screens.Screens;
	
	import utils.Constants;
	
	[ResourceBundle("mainsettingsscreen")]

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
		private var watchIconImage:Image;
		private var appInfoIconImage:Image;
		private var integrationIconImage:Image;
		private var widgetIconImage:Image;
		private var advancedIconImage:Image;
		private var treatmentsIconImage:Image;
		
		public function SettingsList()
		{
			super();
		}
		override protected function initialize():void 
		{
			super.initialize();
			
			Starling.current.stage.addEventListener(starling.events.Event.RESIZE, onStarlingResize);
			
			setupProperties();
			setupContent();
		}
		
		/**
		 * Functionality
		 */
		private function setupProperties():void
		{
			/* Properties */
			clipContent = false;
			isSelectable = true;
			autoHideBackground = true;
			hasElasticEdges = false;
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
		}
		
		private function setupContent():void
		{
			/* Icons */
			chevronIconTexture = MaterialDeepGreyAmberMobileThemeIcons.chevronRightTexture;
			generalIconImage = new Image(chevronIconTexture);
			transmitterIconImage = new Image(chevronIconTexture);
			chartIconImage = new Image(chevronIconTexture);
			widgetIconImage = new Image(chevronIconTexture);
			alarmsIconImage = new Image(chevronIconTexture);
			speechIconImage = new Image(chevronIconTexture);
			shareIconImage = new Image(chevronIconTexture);
			integrationIconImage = new Image(chevronIconTexture);
			watchIconImage = new Image(chevronIconTexture);
			appInfoIconImage = new Image(chevronIconTexture);
			advancedIconImage = new Image(chevronIconTexture);
			treatmentsIconImage = new Image(chevronIconTexture);
			
			/* Data */
			dataProvider = new ListCollection(
				[
					{ screen: Screens.SETTINGS_GENERAL, label: ModelLocator.resourceManagerInstance.getString('mainsettingsscreen','general_settings_title'), accessory: generalIconImage },
					{ screen: Screens.SETTINGS_TRANSMITTER, label: ModelLocator.resourceManagerInstance.getString('mainsettingsscreen','transmitter_settings_title'), accessory: transmitterIconImage },
					{ screen: Screens.SETTINGS_CHART, label: ModelLocator.resourceManagerInstance.getString('mainsettingsscreen','chart_settings_title'), accessory: chartIconImage },
					{ screen: Screens.SETTINGS_TREATMENTS, label: ModelLocator.resourceManagerInstance.getString('mainsettingsscreen','treatments_settings_title'), accessory: treatmentsIconImage },
					{ screen: Screens.SETTINGS_WIDGET, label: ModelLocator.resourceManagerInstance.getString('mainsettingsscreen','widget_settings_title'), accessory: widgetIconImage },
					{ screen: Screens.SETTINGS_ALARMS, label: ModelLocator.resourceManagerInstance.getString('mainsettingsscreen','alarms_settings_title'), accessory: alarmsIconImage },
					{ screen: Screens.SETTINGS_SPEECH, label: ModelLocator.resourceManagerInstance.getString('mainsettingsscreen','speech_settings_title'), accessory: speechIconImage },
					{ screen: Screens.SETTINGS_SHARE, label: ModelLocator.resourceManagerInstance.getString('mainsettingsscreen','share_settings_title'), accessory: shareIconImage },
					{ screen: Screens.SETTINGS_INTEGRATION, label: ModelLocator.resourceManagerInstance.getString('mainsettingsscreen','integration_settings_title'), accessory: integrationIconImage },
					{ screen: Screens.SETTINGS_APPLE_WATCH, label: ModelLocator.resourceManagerInstance.getString('mainsettingsscreen','watch_settings_title'), accessory: watchIconImage },
					{ screen: Screens.SETTINGS_ADVANCED, label: ModelLocator.resourceManagerInstance.getString('mainsettingsscreen','advanced_settings_title'), accessory: advancedIconImage },
					{ screen: Screens.SETTINGS_ABOUT, label: ModelLocator.resourceManagerInstance.getString('mainsettingsscreen','about_settings_title'), accessory: appInfoIconImage }
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
		
		/**
		 * Event Handlers
		 */
		private function onMenuChanged(e:Event):void 
		{
			const screenName:String = selectedItem.screen as String;
			AppInterface.instance.navigator.pushScreen( screenName );
		}
		
		private function onStarlingResize(event:ResizeEvent):void 
		{
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
		}
		
		/**
		 * Utility 
		 */
		override public function dispose():void
		{
			Starling.current.stage.removeEventListener(starling.events.Event.RESIZE, onStarlingResize);
			removeEventListener( Event.CHANGE, onMenuChanged );
			
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
			if(widgetIconImage != null)
			{
				widgetIconImage.dispose();
				widgetIconImage = null;
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
			if(integrationIconImage != null)
			{
				integrationIconImage.dispose();
				integrationIconImage = null;
			}
			if(watchIconImage != null)
			{
				watchIconImage.dispose();
				watchIconImage = null;
			}
			if(appInfoIconImage != null)
			{
				appInfoIconImage.dispose();
				appInfoIconImage = null;
			}
			if(advancedIconImage != null)
			{
				advancedIconImage.dispose();
				advancedIconImage = null;
			}
			if(treatmentsIconImage != null)
			{
				treatmentsIconImage.dispose();
				treatmentsIconImage = null;
			}
			
			super.dispose();
		}
	}
}