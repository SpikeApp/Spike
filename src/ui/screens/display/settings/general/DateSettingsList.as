package ui.screens.display.settings.general
{
	import com.adobe.utils.StringUtil;
	
	import database.CommonSettings;
	
	import feathers.controls.PickerList;
	import feathers.controls.popups.DropDownPopUpContentManager;
	import feathers.data.ArrayCollection;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import starling.events.Event;
	
	import ui.screens.display.LayoutFactory;
	import ui.screens.display.SpikeList;
	
	import utils.Constants;
	
	[ResourceBundle("generalsettingsscreen")]

	public class DateSettingsList extends SpikeList 
	{
		/* Display Objects */
		private var dateFormatPicker:PickerList;
		
		/* Properties */
		public var needsSave:Boolean = false;
		private var dateFormatValue:String;
		private var currentDateFormatIndex:int;
		
		public function DateSettingsList()
		{
			super(true);
			
			setupProperties();
			setupContent();
			setupInitialState();
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
		
		private function setupContent():void
		{
			/* Controls */
			dateFormatPicker = LayoutFactory.createPickerList();
			
			/* Set DateFormatPicker Data */
			var dateFormatLabelsList:Array = ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','chart_date_formats_desc').split(",");
			var dateFormatList:ArrayCollection = new ArrayCollection();
			for (var i:int = 0; i < dateFormatLabelsList.length; i++) 
			{
				dateFormatList.push({label: StringUtil.trim(dateFormatLabelsList[i]), id: i});
				if(StringUtil.trim(dateFormatLabelsList[i]) == CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_DATE_FORMAT))
					currentDateFormatIndex = i;
			}
			dateFormatLabelsList.length = 0;
			dateFormatLabelsList = null;
			dateFormatPicker.labelField = "label";
			dateFormatPicker.popUpContentManager = new DropDownPopUpContentManager();
			dateFormatPicker.dataProvider = dateFormatList;
			
			/* Set Date Settings Content */
			dataProvider = new ArrayCollection(
			[
				{ label: ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','chart_date_format_label'), accessory: dateFormatPicker }
			]);
		}
		
		private function setupInitialState():void
		{
			/* Get Values From Database */
			dateFormatValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_DATE_FORMAT);
			
			/* Set Initial Control State */
			dateFormatPicker.selectedIndex = currentDateFormatIndex;
			
			/* Set Event Listeners */
			dateFormatPicker.addEventListener(Event.CHANGE, onDateFormatChange);
		}
		
		public function save():void
		{
			//Update Database
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_DATE_FORMAT) != dateFormatValue)
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_CHART_DATE_FORMAT, dateFormatValue);
			
			needsSave = false;
		}
		
		/**
		 * Event Listeners
		 */
		private function onDateFormatChange(e:Event):void
		{
			//Update internal variables
			dateFormatValue = dateFormatPicker.selectedItem.label;
			needsSave = true;
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			if (dateFormatPicker != null)
			{
				dateFormatPicker.removeEventListener(Event.CHANGE, onDateFormatChange);
				dateFormatPicker.dispose();
				dateFormatPicker = null;
			}
			
			super.dispose();
		}
	}
}