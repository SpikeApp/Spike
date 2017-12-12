package display.settings.share
{
	import flash.system.System;
	
	import display.LayoutFactory;
	
	import feathers.controls.Button;
	import feathers.controls.List;
	import feathers.controls.TextInput;
	import feathers.controls.ToggleSwitch;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.data.ArrayCollection;
	import feathers.events.FeathersEventType;
	import feathers.layout.HorizontalAlign;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import starling.events.Event;
	
	import utils.Constants;

	public class NightscoutSettingsList extends List 
	{
		/* Display Objects */
		private var nsToggle:ToggleSwitch;
		private var nsURL:TextInput;
		private var nsAPISecret:TextInput;
		private var nsLogin:Button;
		
		public function NightscoutSettingsList()
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
			nsToggle = LayoutFactory.createToggleSwitch(false);
			nsToggle.addEventListener( Event.CHANGE, onNightscoutOnOff );
			
			//URL
			nsURL = LayoutFactory.createTextInput(false, false, 140, HorizontalAlign.RIGHT);
			nsURL.addEventListener( FeathersEventType.ENTER, onTextInputEnter );
			
			//API Secret
			nsAPISecret = LayoutFactory.createTextInput(true, false, 140, HorizontalAlign.RIGHT);
			nsAPISecret.addEventListener( FeathersEventType.ENTER, onTextInputEnter );
			
			//Login
			nsLogin = LayoutFactory.createButton("Login");
			nsLogin.addEventListener(Event.TRIGGERED, onNightscoutLogin);
			
			//Set Item Renderer
			itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "label";
				itemRenderer.accessoryField = "accessory";
				return itemRenderer;
			};
			
			//Define Nightscout Settings Data
			reloadNightscoutSettings(nsToggle.isSelected);
		}
		
		private function onNightscoutOnOff(event:Event):void
		{
			var toggle:ToggleSwitch = ToggleSwitch( event.currentTarget );
			
			if(toggle.isSelected)
				reloadNightscoutSettings(true);
			else
				reloadNightscoutSettings(false);
		}
		
		private function reloadNightscoutSettings(fullDisplay:Boolean):void
		{
			if(fullDisplay)
			{
				dataProvider = new ArrayCollection(
					[
						{ label: "Enabled", accessory: nsToggle },
						{ label: "URL", accessory: nsURL },
						{ label: "API Secret", accessory: nsAPISecret },
						{ label: "", accessory: nsLogin },
					]);
			}
			else
			{
				dataProvider = new ArrayCollection(
					[
						{ label: "Enabled", accessory: nsToggle },
					]);
			}
		}
		
		private function onTextInputEnter(event:Event):void
		{
			//Clear focus to dismiss the keyboard
			nsURL.clearFocus();
			nsAPISecret.clearFocus();
		}
		
		private function onNightscoutLogin(event:Event):void
		{
			//Test Dexcom Share Login
		}
		
		override public function dispose():void
		{
			if(nsToggle != null)
			{
				nsToggle.dispose();
				nsToggle = null;
			}
			if(nsURL != null)
			{
				nsURL.dispose();
				nsURL = null;
			}
			if(nsAPISecret != null)
			{
				nsAPISecret.dispose();
				nsAPISecret = null;
			}
			if(nsLogin != null)
			{
				nsLogin.dispose();
				nsLogin = null;
			}
			
			System.pauseForGCIfCollectionImminent(0);
			
			super.dispose();
		}
	}
}