package display.settings.share
{
	import flash.system.System;
	
	import display.LayoutFactory;
	
	import feathers.controls.Button;
	import feathers.controls.List;
	import feathers.controls.PickerList;
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

	public class DexcomSettingsList extends List 
	{
		/* Display Objects */
		private var dsUsername:TextInput;
		private var dsPassword:TextInput;
		private var dsLogin:Button;
		private var dsServer:PickerList;
		private var dsToggle:ToggleSwitch;
		
		public function DexcomSettingsList()
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
			dsToggle = LayoutFactory.createToggleSwitch(false);
			dsToggle.addEventListener( Event.CHANGE, onDexcomShareOnOff );
			
			//Username
			dsUsername = LayoutFactory.createTextInput(false, false, 140, HorizontalAlign.RIGHT);
			dsUsername.addEventListener( FeathersEventType.ENTER, onTextInputEnter );
			
			//Password
			dsPassword = LayoutFactory.createTextInput(true, false, 140, HorizontalAlign.RIGHT);
			dsPassword.addEventListener( FeathersEventType.ENTER, onTextInputEnter );
			
			//Server
			dsServer = LayoutFactory.createPickerList();
			var dsServerList:ArrayCollection = new ArrayCollection(
				[
					{ label: "US" },
					{ label: "Europe" },
				]);
			dsServer.labelField = "label";
			dsServer.dataProvider = dsServerList;
			dsServer.itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "label";
				return itemRenderer;
			}
			
			//Login
			dsLogin = LayoutFactory.createButton("Login");
			dsLogin.addEventListener( Event.TRIGGERED, onDexcomShareLogin );
			
			//Set Item Renderer
			itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "label";
				itemRenderer.accessoryField = "accessory";
				return itemRenderer;
			};
			
			//Define Dexcom Share Settings Data
			reloadDexcomShareSettings(dsToggle.isSelected);
		}
		
		private function onTextInputEnter(event:Event):void
		{
			//Clear focus to dismiss the keyboard
			dsUsername.clearFocus();
			dsPassword.clearFocus();
		}
		
		private function onDexcomShareOnOff(event:Event):void
		{
			var toggle:ToggleSwitch = ToggleSwitch( event.currentTarget );
			
			if(toggle.isSelected)
				reloadDexcomShareSettings(true);
			else
				reloadDexcomShareSettings(false);
		}
		
		private function reloadDexcomShareSettings(fullDisplay:Boolean):void
		{
			if(fullDisplay)
			{
				dataProvider = new ArrayCollection(
					[
						{ label: "Enabled", accessory: dsToggle },
						{ label: "Username", accessory: dsUsername },
						{ label: "Password", accessory: dsPassword },
						{ label: "Server", accessory: dsServer },
						{ label: "", accessory: dsLogin }
					]);
			}
			else
			{
				dataProvider = new ArrayCollection(
					[
						{ label: "Enabled", accessory: dsToggle }
					]);
			}
		}
		
		private function onDexcomShareLogin(event:Event):void
		{
			//Test Dexcom Share Login
		}
		
		override public function dispose():void
		{
			if(dsUsername != null)
			{
				dsUsername.dispose();
				dsUsername = null;
			}
			if(dsPassword != null)
			{
				dsPassword.dispose();
				dsPassword = null;
			}
			if(dsLogin != null)
			{
				dsLogin.dispose();
				dsLogin = null;
			}
			if(dsServer != null)
			{
				dsServer.dispose();
				dsServer = null;
			}
			if(dsToggle != null)
			{
				dsToggle.dispose();
				dsToggle = null;
			}
			
			System.pauseForGCIfCollectionImminent(0);
			
			super.dispose();
		}
	}
}