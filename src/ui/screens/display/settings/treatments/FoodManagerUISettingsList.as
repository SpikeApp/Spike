package ui.screens.display.settings.treatments
{
	import database.CommonSettings;
	
	import feathers.controls.Check;
	import feathers.controls.PickerList;
	import feathers.controls.popups.DropDownPopUpContentManager;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.data.ArrayCollection;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import starling.events.Event;
	
	import ui.screens.display.LayoutFactory;
	import ui.screens.display.SpikeList;
	
	import utils.Constants;
	
	[ResourceBundle("foodmanager")]
	
	public class FoodManagerUISettingsList extends SpikeList 
	{
		/* Display Objects */
		private var defaultScreenPicker:PickerList;
		private var searchAsITypeCheck:Check;
		private var importFoodsAsNoteCheck:Check;
		
		/* Properties */
		public var needsSave:Boolean;
		private var defaultScreenValue:String;
		private var searchAsITypeValue:Boolean;
		private var importFoodsAsNote:Boolean;
		
		public function FoodManagerUISettingsList()
		{
			super(true);
			
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
			defaultScreenValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FOOD_MANAGER_DEFAULT_SCREEN);
			searchAsITypeValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FOOD_MANAGER_SEARCH_AS_I_TYPE) == "true";
			importFoodsAsNote = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FOOD_MANAGER_IMPORT_FOODS_AS_NOTE) == "true";
		}
		
		private function setupContent():void
		{	
			//Default Screen
			defaultScreenPicker = LayoutFactory.createPickerList();
			
			var defaultScreenValuesList:ArrayCollection = new ArrayCollection();
			defaultScreenValuesList.push( { label: ModelLocator.resourceManagerInstance.getString('foodmanager','favourites_label'), value: "favorites" } );
			defaultScreenValuesList.push( { label: ModelLocator.resourceManagerInstance.getString('foodmanager','recipes_label'), value: "recipes" } );
			defaultScreenValuesList.push( { label: "FatSecret", value: "fatsecret" } );
			defaultScreenValuesList.push( { label: "Open Food Facts", value: "openfoodfacts" } );
			defaultScreenValuesList.push( { label: "USDA", value: "usda" } );
			
			defaultScreenPicker.popUpContentManager = new DropDownPopUpContentManager();
			defaultScreenPicker.dataProvider = defaultScreenValuesList;
			
			if (defaultScreenValue == "favorites")
				defaultScreenPicker.selectedIndex = 0;
			else if (defaultScreenValue == "recipes")
				defaultScreenPicker.selectedIndex = 1;
			else if (defaultScreenValue == "fatsecret")
				defaultScreenPicker.selectedIndex = 2;
			else if (defaultScreenValue == "openfoodfacts")
				defaultScreenPicker.selectedIndex = 3;
			else if (defaultScreenValue == "usda")
				defaultScreenPicker.selectedIndex = 4;
				
			defaultScreenPicker.itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "label";
				itemRenderer.paddingRight = itemRenderer.paddingLeft = 15;
				return itemRenderer;
			}
			defaultScreenPicker.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Search As I Type
			searchAsITypeCheck = LayoutFactory.createCheckMark(searchAsITypeValue);
			searchAsITypeCheck.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Import Foods As Note
			importFoodsAsNoteCheck = LayoutFactory.createCheckMark(importFoodsAsNote);
			importFoodsAsNoteCheck.addEventListener(Event.CHANGE, onSettingsChanged);

			//Set screen content
			var data:Array = [];
			
			data.push( { label: ModelLocator.resourceManagerInstance.getString('foodmanager','default_database_label'), accessory: defaultScreenPicker } );
			data.push( { label: ModelLocator.resourceManagerInstance.getString('foodmanager','search_as_i_type_label'), accessory: searchAsITypeCheck } );
			data.push( { label: ModelLocator.resourceManagerInstance.getString('foodmanager','import_foods_as_note_label'), accessory: importFoodsAsNoteCheck } );
			
			dataProvider = new ArrayCollection(data);
		}
		
		public function save():void
		{
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FOOD_MANAGER_DEFAULT_SCREEN) != defaultScreenValue)
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_FOOD_MANAGER_DEFAULT_SCREEN, defaultScreenValue, true, false);
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FOOD_MANAGER_SEARCH_AS_I_TYPE) != String(searchAsITypeValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_FOOD_MANAGER_SEARCH_AS_I_TYPE, String(searchAsITypeValue), true, false);
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FOOD_MANAGER_IMPORT_FOODS_AS_NOTE) != String(importFoodsAsNote))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_FOOD_MANAGER_IMPORT_FOODS_AS_NOTE, String(importFoodsAsNote), true, false);
			
			needsSave = false;
		}
		
		/**
		 * Event Listeners
		 */
		private function onSettingsChanged(e:Event):void
		{
			defaultScreenValue = defaultScreenPicker.selectedItem.value;
			searchAsITypeValue = searchAsITypeCheck.isSelected;
			importFoodsAsNote = importFoodsAsNoteCheck.isSelected;
			
			needsSave = true;
		}
		
		/**
		 * Utility
		 */	
		override public function dispose():void
		{
			if (defaultScreenPicker != null)
			{
				defaultScreenPicker.removeEventListener(Event.CHANGE, onSettingsChanged);
				defaultScreenPicker.removeFromParent();
				defaultScreenPicker.dispose();
				defaultScreenPicker = null;
			}
			
			if (searchAsITypeCheck != null)
			{
				searchAsITypeCheck.removeEventListener(Event.CHANGE, onSettingsChanged);
				searchAsITypeCheck.removeFromParent();
				searchAsITypeCheck.dispose();
				searchAsITypeCheck = null;
			}
			
			if (importFoodsAsNoteCheck != null)
			{
				importFoodsAsNoteCheck.removeEventListener(Event.CHANGE, onSettingsChanged);
				importFoodsAsNoteCheck.removeFromParent();
				importFoodsAsNoteCheck.dispose();
				importFoodsAsNoteCheck = null;
			}
			
			super.dispose();
		}
	}
}