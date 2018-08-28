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
	
	public class IFTTTSettingsChooser extends SpikeList 
	{
		/* Display Objects */
		private var IFTTTIconImage:Image;
		private var chevronIconTexture:Texture;
		
		public function IFTTTSettingsChooser()
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
			IFTTTIconImage = new Image(chevronIconTexture);
			
			dataProvider = new ListCollection(
				[
					{ screen: Screens.SETTINGS_IFTTT, label: ModelLocator.resourceManagerInstance.getString('integrationsettingsscreen','settings_label'), accessory: IFTTTIconImage },
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
			
			if (IFTTTIconImage != null)
			{
				if (IFTTTIconImage.texture != null)
					IFTTTIconImage.texture.dispose();
				IFTTTIconImage.dispose();
				IFTTTIconImage = null;
			}
			
			super.dispose();
		}
	}
}

