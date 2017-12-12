package display.settings.general
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

	public class NotificationSettingsList extends List 
	{
		/* Display Objects */
		private var notificationsToggle:ToggleSwitch;
		
		public function NotificationSettingsList()
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
			
			//Notifications On/Off Toggle
			notificationsToggle = LayoutFactory.createToggleSwitch(false);
			
			//Define Notifications Settings Data
			var settingsData:ArrayCollection = new ArrayCollection(
				[
					{ text: "Enabled", accessory: notificationsToggle },
				]);
			dataProvider = settingsData;
			
			//Set Item Renderer
			itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "text";
				itemRenderer.accessoryField = "accessory";
				return itemRenderer;
			};
		}
		
		override public function dispose():void
		{
			if(notificationsToggle != null)
			{
				notificationsToggle.dispose();
				notificationsToggle = null;
			}
			
			System.pauseForGCIfCollectionImminent(0);
			
			super.dispose();
		}
	}
}