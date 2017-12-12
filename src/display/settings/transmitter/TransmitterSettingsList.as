package display.settings.transmitter
{
	import flash.system.System;
	
	import display.LayoutFactory;
	
	import feathers.controls.List;
	import feathers.controls.PickerList;
	import feathers.controls.TextInput;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.data.ArrayCollection;
	import feathers.events.FeathersEventType;
	import feathers.layout.HorizontalAlign;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import starling.events.Event;
	
	import utils.Constants;

	public class TransmitterSettingsList extends List 
	{
		/* Display Objects */
		private var transmitterID:TextInput;
		private var transmitterType:PickerList;
		
		public function TransmitterSettingsList()
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
			
			//Transmitter Type Picker List
			transmitterType = LayoutFactory.createPickerList();
			var transmitterTypeList:ArrayCollection = new ArrayCollection(
				[
					{ label: "Blucon" },
					{ label: "BlueReader" },
					{ label: "G4" },
					{ label: "G5" },
					{ label: "Limitter" }
				]);
			transmitterType.labelField = "label";
			transmitterType.dataProvider = transmitterTypeList;
			transmitterType.itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "label";
				return itemRenderer;
			}
				
			//Transmitter ID
			transmitterID = LayoutFactory.createTextInput(false, false, 140, HorizontalAlign.RIGHT);
			transmitterID.addEventListener( FeathersEventType.ENTER, onTextInputEnter );
				
			//Set Item Renderer
			itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "label";
				itemRenderer.accessoryField = "accessory";
				return itemRenderer;
			};
			
			//Set Data Provider
			dataProvider = new ArrayCollection(
				[
					{ label: "Transmitter Type", accessory: transmitterType },
					{ label: "Transmitter ID", accessory: transmitterID },
				]);
		}
		
		private function onTextInputEnter(event:Event):void
		{
			//Clear focus to dismiss the keyboard
			transmitterID.clearFocus();
		}
		
		override public function dispose():void
		{
			if(transmitterID != null)
			{
				transmitterID.dispose();
				transmitterID = null;
			}
			if(transmitterType != null)
			{
				transmitterType.dispose();
				transmitterType = null;
			}
			
			System.pauseForGCIfCollectionImminent(0);
			
			super.dispose();
		}
	}
}