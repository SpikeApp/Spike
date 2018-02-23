package ui.screens.display.settings.general
{
	import database.CommonSettings;
	
	import feathers.controls.List;
	import feathers.controls.PickerList;
	import feathers.controls.TextInput;
	import feathers.controls.popups.DropDownPopUpContentManager;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.data.ArrayCollection;
	import feathers.layout.HorizontalAlign;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import starling.events.Event;
	
	import ui.screens.display.LayoutFactory;
	
	import utils.Constants;
	
	[ResourceBundle("generalsettingsscreen")]

	public class DataCollectionSettingsList extends List 
	{
		/* Display Objects */
		private var collectionModePicker:PickerList;
		private var nightscoutURLInput:TextInput;
		
		/* Properties */
		public var needsSave:Boolean = false;
		private var collectionMode:String;		
		private var followNSURL:String;
		
		public function DataCollectionSettingsList()
		{
			super();
			
			setupProperties();
			setupInitialContent();	
			setupContent();
		}
		
		/**
		 * Functionality
		 */
		private function setupProperties():void
		{
			/* Set Properties */
			clipContent = false;
			isSelectable = false;
			autoHideBackground = true;
			hasElasticEdges = false;
			paddingBottom = 5;
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
		}
		
		private function setupInitialContent():void
		{
			/* Get Values From Database */
			collectionMode = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_MODE);
			followNSURL = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_URL);
		}
		
		private function setupContent():void
		{
			//Collection Picker List
			collectionModePicker = LayoutFactory.createPickerList();
			
			/* Set DateFormatPicker Data */
			var collectionModesLabelsList:Array = ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','collection_list').split(",");
			var collectionModestList:ArrayCollection = new ArrayCollection();
			for (var i:int = 0; i < collectionModesLabelsList.length; i++) 
			{
				collectionModestList.push({label: collectionModesLabelsList[i], id: i});
			}
			collectionModesLabelsList.length = 0;
			collectionModesLabelsList = null;
			collectionModePicker.labelField = "label";
			collectionModePicker.popUpContentManager = new DropDownPopUpContentManager();
			collectionModePicker.dataProvider = collectionModestList;
			var selectedModeIndex:int;
			if (collectionMode == "Host")
				selectedModeIndex = 0;
			else if (collectionMode == "Follower")
				selectedModeIndex = 1;
			collectionModePicker.selectedIndex = selectedModeIndex;
			collectionModePicker.addEventListener(Event.CHANGE, onCollectionModeChanged);
			
			//Nightscout URL
			nightscoutURLInput = LayoutFactory.createTextInput(false, false, 140, HorizontalAlign.RIGHT);
			nightscoutURLInput.fontStyles.size = 10;
			nightscoutURLInput.text = followNSURL;
			nightscoutURLInput.addEventListener(Event.CHANGE, onNSURLChanged);
			
			/* Set Item Renderer */
			itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "text";
				itemRenderer.accessoryField = "accessory";
				itemRenderer.paddingRight = 0;
				return itemRenderer;
			};
			
			refreshContent();
		}
		
		private function refreshContent():void
		{
			var data:Array = [];
			data.push( { text: ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','mode_label'), accessory: collectionModePicker } );
			if (collectionMode == "Follower")
				data.push( { text: ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','follower_ns_url'), accessory: nightscoutURLInput } );
			
			dataProvider = new ArrayCollection(data);
		}
		
		public function save():void
		{
			//Update Database
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_MODE) != collectionMode)
			{
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_MODE, collectionMode);
				if (collectionMode == "Follower")
					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_PERIPHERAL_TYPE, "Follow");
				else if (collectionMode == "Host")
					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_PERIPHERAL_TYPE, "");
			}
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_URL) != followNSURL)
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_URL, followNSURL);
			
			needsSave = false;
		}
		
		/**
		 * Event Listeners
		 */
		private function onCollectionModeChanged(e:Event):void
		{
			//Update internal variables
			if (collectionModePicker.selectedIndex == 0)
				collectionMode = "Host";
			else if (collectionModePicker.selectedIndex == 1)
				collectionMode = "Follower";
			
			needsSave = true;
			
			refreshContent();
		}
		
		private function onNSURLChanged(e:Event):void
		{
			followNSURL = nightscoutURLInput.text.replace(" ", "");
			
			needsSave = true;
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			if (collectionModePicker != null)
			{
				collectionModePicker.removeEventListener(Event.CHANGE, onCollectionModeChanged);
				collectionModePicker.dispose();
				collectionModePicker = null;
			}
			
			if (nightscoutURLInput != null)
			{
				nightscoutURLInput.removeEventListener(Event.CHANGE, onNSURLChanged);
				nightscoutURLInput.dispose();
				nightscoutURLInput = null;
			}
			
			super.dispose();
		}
	}
}