package ui.screens.display.settings.general
{
	import database.CommonSettings;
	
	import feathers.controls.Label;
	import feathers.controls.List;
	import feathers.controls.NumericStepper;
	import feathers.controls.PickerList;
	import feathers.controls.TextInput;
	import feathers.controls.popups.DropDownPopUpContentManager;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.data.ArrayCollection;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalLayout;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import starling.core.Starling;
	import starling.events.Event;
	import starling.events.ResizeEvent;
	
	import ui.AppInterface;
	import ui.screens.display.LayoutFactory;
	
	import utils.Constants;
	
	[ResourceBundle("generalsettingsscreen")]

	public class DataCollectionSettingsList extends List 
	{
		/* Display Objects */
		private var collectionModePicker:PickerList;
		private var nightscoutURLInput:TextInput;
		private var nightscoutOffsetStepper:NumericStepper;
		private var nightscoutAPISecretTextInput:TextInput;
		private var nightscoutAPIDescription:Label;
		
		/* Properties */
		public var needsSave:Boolean = false;
		private var collectionMode:String;		
		private var followNSURL:String;
		private var nightscoutOffset:Number;
		private var nightscoutAPISecretValue:String;
		
		public function DataCollectionSettingsList()
		{
			super();
			
			Starling.current.stage.addEventListener(starling.events.Event.RESIZE, onStarlingResize);
			
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
			nightscoutOffset = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_OFFSET));
			nightscoutAPISecretValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_API_SECRET);
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
			nightscoutURLInput.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Nightscout Offset Stepper
			nightscoutOffsetStepper = LayoutFactory.createNumericStepper(-10000, 10000, nightscoutOffset, 5); 
			nightscoutOffsetStepper.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//API Secret
			nightscoutAPISecretTextInput = LayoutFactory.createTextInput(true, false, 140, HorizontalAlign.RIGHT);
			nightscoutAPISecretTextInput.text = nightscoutAPISecretValue;
			nightscoutAPISecretTextInput.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//API Secret Description
			nightscoutAPIDescription = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','api_secret_description'), HorizontalAlign.JUSTIFY);
			nightscoutAPIDescription.wordWrap = true;
			nightscoutAPIDescription.width = width;
			nightscoutAPIDescription.paddingTop = nightscoutAPIDescription.paddingBottom = 10;
			
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
			{
				data.push( { text: ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','follower_ns_url'), accessory: nightscoutURLInput } );
				data.push( { text: ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','time_offset'), accessory: nightscoutOffsetStepper } );
				data.push( { text: ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','api_secret'), accessory: nightscoutAPISecretTextInput } );
				data.push( { text:"", accessory: nightscoutAPIDescription } );
			}
			
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
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_OFFSET) != String(nightscoutOffset))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_OFFSET, String(nightscoutOffset));
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_API_SECRET) != String(nightscoutAPISecretValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_API_SECRET, String(nightscoutAPISecretValue));
			
			//Refresh main menu. Menu items are different for hosts and followers
			AppInterface.instance.menu.refreshContent();
			
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
		
		private function onSettingsChanged(e:Event):void
		{
			followNSURL = nightscoutURLInput.text.replace(" ", "");
			nightscoutOffset = nightscoutOffsetStepper.value;
			nightscoutAPISecretValue = nightscoutAPISecretTextInput.text.replace(" ", "");
			
			needsSave = true;
		}
		
		/**
		 * Utility
		 */
		override protected function draw():void
		{
			if ((layout as VerticalLayout) != null)
				(layout as VerticalLayout).hasVariableItemDimensions = true;
			
			super.draw();
		}
		
		private function onStarlingResize(event:ResizeEvent):void 
		{
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
		}
		
		override public function dispose():void
		{
			Starling.current.stage.removeEventListener(starling.events.Event.RESIZE, onStarlingResize);
			
			if (collectionModePicker != null)
			{
				collectionModePicker.removeEventListener(Event.CHANGE, onCollectionModeChanged);
				collectionModePicker.dispose();
				collectionModePicker = null;
			}
			
			if (nightscoutURLInput != null)
			{
				nightscoutURLInput.removeEventListener(Event.CHANGE, onSettingsChanged);
				nightscoutURLInput.dispose();
				nightscoutURLInput = null;
			}
			
			if (nightscoutOffsetStepper != null)
			{
				nightscoutOffsetStepper.removeEventListener(Event.CHANGE, onSettingsChanged);
				nightscoutOffsetStepper.dispose();
				nightscoutOffsetStepper = null;
			}
			
			if (nightscoutAPISecretTextInput != null)
			{
				nightscoutAPISecretTextInput.removeEventListener(Event.CHANGE, onSettingsChanged);
				nightscoutAPISecretTextInput.dispose();
				nightscoutAPISecretTextInput = null;
			}
			
			if (nightscoutAPIDescription != null)
			{
				nightscoutAPIDescription.dispose();
				nightscoutAPIDescription = null;
			}
			
			super.dispose();
		}
	}
}