package display.settings.transmitter
{
	import flash.system.System;
	
	import databaseclasses.CommonSettings;
	
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
	
	import model.ModelLocator;
	
	import starling.events.Event;
	
	import utils.Constants;
	
	[ResourceBundle("transmittersettingsscreen")]
	[ResourceBundle("globalsettings")]

	public class TransmitterSettingsList extends List 
	{
		/* Display Objects */
		private var transmitterID:TextInput;
		private var transmitterType:PickerList;
		
		/* Properties */
		public var needsSave:Boolean = false;
		private var transmitterTypeValue:String;
		private var transmitterIDValue:String;
		private var currentTransmitterIndex:int;
		
		public function TransmitterSettingsList()
		{
			super();
		}
		override protected function initialize():void 
		{
			super.initialize();
			
			setupProperties();
			setupContent();
			setupInitialState();
		}
		
		/**
		 * Functionality
		 */
		private function setupProperties():void
		{
			//Set Properties
			clipContent = false;
			isSelectable = false;
			autoHideBackground = true;
			hasElasticEdges = false;
			paddingBottom = 5;
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
		}
		
		private function setupContent():void
		{
			//Transmitter Type Picker List
			transmitterType = LayoutFactory.createPickerList();
			var transitterNamesList:Array = ModelLocator.resourceManagerInstance.getString('transmittersettingsscreen','transmitter_type_list').split(",");
			var transmitterTypeList:ArrayCollection = new ArrayCollection();
			for (var i:int = 0; i < transitterNamesList.length; i++) 
			{
				transmitterTypeList.push({label: transitterNamesList[i], id: i});
				if(transitterNamesList[i] == CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PERIPHERAL_TYPE))
					currentTransmitterIndex = i;
			}
			transitterNamesList.length = 0;
			transitterNamesList = null;
			transmitterType.labelField = "label";
			transmitterType.dataProvider = transmitterTypeList;
			transmitterType.itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "label";
				return itemRenderer;
			}
			
			//Transmitter ID
			transmitterID = LayoutFactory.createTextInput(false, false, 100, HorizontalAlign.RIGHT);
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
					{ label: ModelLocator.resourceManagerInstance.getString('transmittersettingsscreen','transmitter_type_settings_title'), accessory: transmitterType },
					{ label: ModelLocator.resourceManagerInstance.getString('transmittersettingsscreen','transmitter_id_settings_title'), accessory: transmitterID },
				]);
		}
		
		private function setupInitialState():void
		{
			/* Get Values From Database */
			transmitterIDValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TRANSMITTER_ID);
			transmitterTypeValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PERIPHERAL_TYPE);
			
			/* Set Conrol's Values */
			transmitterID.text = transmitterIDValue;
			
			if(transmitterTypeValue == "")
			{
				transmitterType.prompt = ModelLocator.resourceManagerInstance.getString('globalsettings','picker_select');
				transmitterType.selectedIndex = -1;
			}
			else transmitterType.selectedIndex = currentTransmitterIndex;
			
			/* Set Event Listeners */
			transmitterType.addEventListener(Event.CHANGE, onTransmitterTypeChange);
			transmitterID.addEventListener(Event.CHANGE, onTransmitterIDChange);
		}
		
		private function onTransmitterTypeChange(e:Event):void
		{
			transmitterTypeValue = transmitterType.selectedItem.label;
			
			needsSave = true;
		}
		
		private function onTransmitterIDChange(e:Event):void
		{
			transmitterIDValue = transmitterID.text;
			
			needsSave = true;
		}
		
		public function save():void
		{
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TRANSMITTER_ID) != transmitterIDValue)
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_TRANSMITTER_ID, transmitterIDValue);
			
			if(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PERIPHERAL_TYPE) != transmitterTypeValue)
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_PERIPHERAL_TYPE, transmitterTypeValue);
			
			needsSave = false;
		}
		
		/**
		 * Event Handlers
		 */
		private function onTextInputEnter(event:Event):void
		{
			//Clear focus to dismiss the keyboard
			transmitterID.clearFocus();
		}
		
		/**
		 * Utility
		 */
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