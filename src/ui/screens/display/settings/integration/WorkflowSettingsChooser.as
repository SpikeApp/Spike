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
	
	public class WorkflowSettingsChooser extends SpikeList 
	{
		/* Display Objects */
		private var WorkflowIconImage:Image;
		private var chevronIconTexture:Texture;
		
		public function WorkflowSettingsChooser()
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
			WorkflowIconImage = new Image(chevronIconTexture);
			
			dataProvider = new ListCollection(
				[
					{ screen: Screens.SETTINGS_WORKFLOW, label: ModelLocator.resourceManagerInstance.getString('integrationsettingsscreen','settings_label'), accessory: WorkflowIconImage },
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
			
			if (WorkflowIconImage != null)
			{
				if (WorkflowIconImage.texture != null)
					WorkflowIconImage.texture.dispose();
				WorkflowIconImage.dispose();
				WorkflowIconImage = null;
			}
			
			super.dispose();
		}
	}
}

