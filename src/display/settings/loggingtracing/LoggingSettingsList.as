package display.settings.loggingtracing
{
	import flash.system.System;
	
	import display.LayoutFactory;
	
	import feathers.controls.List;
	import feathers.controls.ToggleSwitch;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.data.ArrayCollection;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import utils.Constants;

	public class LoggingSettingsList extends List 
	{
		/* Display Objects */
		private var nsLogToggle:ToggleSwitch;
		
		public function LoggingSettingsList()
		{
			super();
		}
		override protected function initialize():void 
		{
			super.initialize();
			
			//Set Properties
			clipContent = false;
			isSelectable = false;
			autoHideBackground = true;
			hasElasticEdges = false;
			paddingBottom = 5;
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
			
			//On/Off Toggle
			nsLogToggle = LayoutFactory.createToggleSwitch(false);
			
			//Define NSLog Settings Data
			dataProvider = new ArrayCollection(
				[
					{ label: "Enabled", accessory: nsLogToggle },
				]);
			
			//Set Item Renderer
			itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "label";
				itemRenderer.accessoryField = "accessory";
				return itemRenderer;
			};
		}
		
		override public function dispose():void
		{
			if(nsLogToggle != null)
			{
				nsLogToggle.dispose();
				nsLogToggle = null;
			}
			
			System.pauseForGCIfCollectionImminent(0);
			
			super.dispose();
		}
	}
}