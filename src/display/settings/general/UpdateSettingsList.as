package display.settings.general
{
	import flash.system.System;
	
	import display.LayoutFactory;
	
	import feathers.controls.List;
	import feathers.controls.NumericStepper;
	import feathers.controls.ToggleSwitch;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.data.ArrayCollection;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import starling.events.Event;
	
	import utils.Constants;

	public class UpdateSettingsList extends List 
	{
		/* Display Objects */
		private var updatesToggle:ToggleSwitch;
		private var userGroup:NumericStepper;
		
		public function UpdateSettingsList()
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
			
			///Notifications On/Off Toggle
			updatesToggle = LayoutFactory.createToggleSwitch(false);
			updatesToggle.addEventListener( Event.CHANGE, onUpdatesOnOff );
			
			//User Group Text Numeric Inpu
			userGroup = LayoutFactory.createNumericStepper(0, 20, 0);
			
			//Define Notifications Settings Data
			dataProvider = new ArrayCollection(
				[
					{ label: "Enabled", accessory: updatesToggle },
					{ label: "User Group", accessory: userGroup },
				]);
			
			//Set Item Renderer
			itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "label";
				itemRenderer.accessoryField = "accessory";
				return itemRenderer;
			};
			
			//Set Update Settings Data
			reloadUpdateSettings(updatesToggle.isSelected);
		}
		
		private function onUpdatesOnOff(event:Event):void
		{
			var toggle:ToggleSwitch = ToggleSwitch( event.currentTarget );
			
			if(toggle.isSelected)
				reloadUpdateSettings(true);
			else
				reloadUpdateSettings(false);
		}
		
		private function reloadUpdateSettings(fullDisplay:Boolean):void
		{
			if(fullDisplay)
			{
				dataProvider = new ArrayCollection(
					[
						{ label: "Enabled", accessory: updatesToggle },
						{ label: "User Group", accessory: userGroup },
					]);
			}
			else
			{
				dataProvider = new ArrayCollection(
					[
						{ label: "Enabled", accessory: updatesToggle },
					]);
			}
		}
		
		override public function dispose():void
		{
			if(updatesToggle != null)
			{
				updatesToggle.dispose();
				updatesToggle = null;
			}
			if(userGroup != null)
			{
				userGroup.dispose();
				userGroup = null;
			}
			
			System.pauseForGCIfCollectionImminent(0);
			
			super.dispose();
		}
	}
}