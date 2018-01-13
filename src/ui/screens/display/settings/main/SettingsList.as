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
	
	import starling.display.Image;
	import starling.events.Event;
	import starling.textures.Texture;
	
	import ui.AppInterface;
	import ui.screens.Screens;
	
	import utilities.Constants;
	
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
		private var bugReportIconImage:Image;
		private var appInfoIconImage:Image;
		
		public function SettingsList()
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
			alarmsIconImage = new Image(chevronIconTexture);
			speechIconImage = new Image(chevronIconTexture);
			shareIconImage = new Image(chevronIconTexture);
			bugReportIconImage = new Image(chevronIconTexture);
			appInfoIconImage = new Image(chevronIconTexture);
			
			/* Data */
			dataProvider = new ListCollection(
				[
					{ screen: Screens.SETTINGS_GENERAL, label: ModelLocator.resourceManagerInstance.getString('mainsettingsscreen','general_settings_title'), accessory: generalIconImage },
					{ screen: Screens.SETTINGS_TRANSMITTER, label: ModelLocator.resourceManagerInstance.getString('mainsettingsscreen','transmitter_settings_title'), accessory: transmitterIconImage },
					{ screen: Screens.SETTINGS_CHART, label: ModelLocator.resourceManagerInstance.getString('mainsettingsscreen','chart_settings_title'), accessory: chartIconImage },
					{ screen: Screens.SETTINGS_ALARMS, label: ModelLocator.resourceManagerInstance.getString('mainsettingsscreen','alarms_settings_title'), accessory: alarmsIconImage },
					{ screen: Screens.SETTINGS_SPEECH, label: ModelLocator.resourceManagerInstance.getString('mainsettingsscreen','speech_settings_title'), accessory: speechIconImage },
					{ screen: Screens.SETTINGS_SHARE, label: ModelLocator.resourceManagerInstance.getString('mainsettingsscreen','share_settings_title'), accessory: shareIconImage },
					{ screen: Screens.SETTINGS_BUG_REPORT, label: ModelLocator.resourceManagerInstance.getString('mainsettingsscreen','bug_report_settings_title'), accessory: bugReportIconImage },
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
		
		/**
		 * Utility 
		 */
		override public function dispose():void
		{
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
			if(bugReportIconImage != null)
			{
				bugReportIconImage.dispose();
				bugReportIconImage = null;
			}
			if(appInfoIconImage != null)
			{
				appInfoIconImage.dispose();
				appInfoIconImage = null;
			}
			
			super.dispose();
		}
	}
}