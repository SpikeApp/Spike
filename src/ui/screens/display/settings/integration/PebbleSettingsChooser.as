package ui.screens.display.settings.integration
{
	import feathers.data.ListCollection;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.ModelLocator;
	
	import starling.display.Image;
	import starling.events.Event;
	import starling.textures.Texture;
	
	import ui.AppInterface;
	import ui.screens.Screens;
	import ui.screens.display.SpikeList;
	
	import utils.Constants;
	
	[ResourceBundle("integrationsettingsscreen")]
	
	public class PebbleSettingsChooser extends SpikeList 
	{
		/* Display Objects */
		private var pebbleIconImage:Image;
		private var chevronIconTexture:Texture;
		
		public function PebbleSettingsChooser()
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
			//Set Properties
			clipContent = false;
			autoHideBackground = true;
			hasElasticEdges = false;
			paddingBottom = 5;
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
		}
		
		private function setupContent():void
		{
			chevronIconTexture = MaterialDeepGreyAmberMobileThemeIcons.chevronRightTexture;
			pebbleIconImage = new Image(chevronIconTexture);
			
			dataProvider = new ListCollection(
				[
					{ screen: Screens.SETTINGS_PEBBLE, label: ModelLocator.resourceManagerInstance.getString('integrationsettingsscreen','settings_label'), accessory: pebbleIconImage },
				]);
			
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
			if (chevronIconTexture != null)
			{
				chevronIconTexture.dispose();
				chevronIconTexture = null;
			}
			
			if (pebbleIconImage != null)
			{
				if (pebbleIconImage.texture != null)
					pebbleIconImage.texture.dispose();
				pebbleIconImage.dispose();
				pebbleIconImage = null;
			}
			
			super.dispose();
		}
	}
}

