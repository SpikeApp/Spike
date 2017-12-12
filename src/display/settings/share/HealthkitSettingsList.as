package display.settings.share
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

	public class HealthkitSettingsList extends List 
	{
		/* Display Objects */
		private var hkToggle:ToggleSwitch;
		
		public function HealthkitSettingsList()
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
			
			//Healthkit On/Off Toggle
			hkToggle = LayoutFactory.createToggleSwitch(false);
			
			//Define HealthKit Settings Data
			dataProvider = new ArrayCollection(
				[
					{ label: "Enabled", accessory: hkToggle },
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
			if(hkToggle != null)
			{
				hkToggle.dispose();
				hkToggle = null;
			}
			
			System.pauseForGCIfCollectionImminent(0);
			
			super.dispose();
		}
	}
}