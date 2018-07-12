package ui.screens.display.settings.chart
{
	import com.adobe.utils.StringUtil;
	
	import database.BgReading;
	import database.CommonSettings;
	
	import feathers.controls.Check;
	import feathers.controls.NumericStepper;
	import feathers.controls.PickerList;
	import feathers.controls.popups.DropDownPopUpContentManager;
	import feathers.data.ArrayCollection;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import starling.events.Event;
	
	import ui.screens.display.LayoutFactory;
	import ui.screens.display.SpikeList;
	
	import utils.Constants;
	
	[ResourceBundle("chartsettingsscreen")]

	public class ModeSettingsList extends SpikeList 
	{
		/* Display Objects */
		private var scaleFormatPicker:PickerList;
		private var chartMaxValueStepper:NumericStepper;
		private var chartMinValueStepper:NumericStepper;
		private var resizeBoundsMark:Check;
		
		/* Properties */
		public var needsSave:Boolean = false;
		private var scaleFormatIsDynamic:Boolean;
		private var currentScaleFormatIndex:int;
		private var chartMinValue:Number;
		private var chartMaxValue:Number;
		private var resizeOutOfBounds:Boolean;
		private var glucoseUnits:String;
		
		public function ModeSettingsList()
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
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true")
				glucoseUnits = "mgdl";
			else
				glucoseUnits = "mmol";
			scaleFormatIsDynamic = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_SCALE_MODE_DYNAMIC) == "true";
			resizeOutOfBounds = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_RESIZE_ON_OUT_OF_BOUNDS) == "true";
			
			chartMaxValue = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_MAX_VALUE));
			if (glucoseUnits != "mgdl")
				chartMaxValue = Math.round(((BgReading.mgdlToMmol((chartMaxValue))) * 10)) / 10;
			
			chartMinValue = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_MIN_VALUE));
			if (glucoseUnits != "mgdl")
				chartMinValue = Math.round(((BgReading.mgdlToMmol((chartMinValue))) * 10)) / 10;
		}
		
		private function setupContent():void
		{
			/* Controls */
			scaleFormatPicker = LayoutFactory.createPickerList();
			
			/* Set ScaleFormatPicker Data */
			var scaleFormatLabelsList:Array = ModelLocator.resourceManagerInstance.getString('chartsettingsscreen','chart_modes').split(",");
			var scaleFormatList:ArrayCollection = new ArrayCollection();
			for (var i:int = 0; i < scaleFormatLabelsList.length; i++) 
			{
				scaleFormatList.push({label: StringUtil.trim(scaleFormatLabelsList[i]), id: i});
			}
			if(scaleFormatIsDynamic)
				currentScaleFormatIndex = 0;
			else
				currentScaleFormatIndex = 1;
			scaleFormatLabelsList.length = 0;
			scaleFormatLabelsList = null;
			scaleFormatPicker.labelField = "label";
			scaleFormatPicker.popUpContentManager = new DropDownPopUpContentManager();
			scaleFormatPicker.dataProvider = scaleFormatList;
			scaleFormatPicker.selectedIndex = currentScaleFormatIndex;
			scaleFormatPicker.addEventListener(Event.CHANGE, onScaleFormatChange);
			
			/* Value Numeric Steppers */
			var maxConstrain:Number;
			glucoseUnits == "mgdl" ? maxConstrain = 800 : maxConstrain = Math.round(((BgReading.mgdlToMmol((800))) * 10)) / 10;
			chartMaxValueStepper = LayoutFactory.createNumericStepper(0, maxConstrain, chartMaxValue);
			if (glucoseUnits != "mgdl")
				chartMaxValueStepper.step = 0.1;
			chartMaxValueStepper.addEventListener(Event.CHANGE, onSettingsChanged);
			
			chartMinValueStepper = LayoutFactory.createNumericStepper(0, maxConstrain, chartMinValue);
			if (glucoseUnits != "mgdl")
				chartMinValueStepper.step = 0.1;
			chartMinValueStepper.addEventListener(Event.CHANGE, onSettingsChanged);
			
			/* Resize Bounds Checkmark */
			resizeBoundsMark = LayoutFactory.createCheckMark(resizeOutOfBounds);
			resizeBoundsMark.pivotX = 6;
			resizeBoundsMark.addEventListener(Event.CHANGE, onSettingsChanged);
			
			/* Set Item Renderer */
			refreshContent();
		}
		
		private function refreshContent():void
		{
			var content:Array = [];
			content.push( { label: ModelLocator.resourceManagerInstance.getString('chartsettingsscreen','chart_mode'), accessory: scaleFormatPicker } );
			if (!scaleFormatIsDynamic)
			{
				content.push( { label: ModelLocator.resourceManagerInstance.getString('chartsettingsscreen','chart_max_value'), accessory: chartMaxValueStepper } );
				content.push( { label: ModelLocator.resourceManagerInstance.getString('chartsettingsscreen','chart_min_value'), accessory: chartMinValueStepper } );
				content.push( { label: ModelLocator.resourceManagerInstance.getString('chartsettingsscreen','chart_resize_out_of_bounds'), accessory: resizeBoundsMark } );
			}
			
			dataProvider = new ArrayCollection(content);
		}
		
		public function save():void
		{
			//Scale Mode
			var isDynamicValueToSave:String;
			if (scaleFormatIsDynamic) isDynamicValueToSave = "true";
			else isDynamicValueToSave = "false";
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_SCALE_MODE_DYNAMIC) != isDynamicValueToSave)
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_CHART_SCALE_MODE_DYNAMIC, isDynamicValueToSave);
			
			//Max Value
			var maxValueToSave:String;
			if (glucoseUnits == "mgdl")
				maxValueToSave = String(chartMaxValue);
			else
				maxValueToSave = String(Math.round(BgReading.mmolToMgdl(chartMaxValue)));
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_MAX_VALUE) != String(maxValueToSave))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_CHART_MAX_VALUE, String(maxValueToSave));
			
			//Min Value
			var minValueToSave:String;
			if (glucoseUnits == "mgdl")
				minValueToSave = String(chartMinValue);
			else
				minValueToSave = String(Math.round(BgReading.mmolToMgdl(chartMinValue)));
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_MIN_VALUE) != String(minValueToSave))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_CHART_MIN_VALUE, String(minValueToSave));
			
			//Resize Out Of Bounds
			var resizeValueToSave:String;
			if (resizeOutOfBounds) resizeValueToSave = "true";
			else resizeValueToSave = "false";
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_RESIZE_ON_OUT_OF_BOUNDS) != resizeValueToSave)
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_CHART_RESIZE_ON_OUT_OF_BOUNDS, resizeValueToSave);
			
			needsSave = false;
		}
		
		/**
		 * Event Listeners
		 */
		private function onScaleFormatChange(e:Event):void
		{
			//Update internal variables
			scaleFormatIsDynamic = scaleFormatPicker.selectedIndex == 0;
			needsSave = true;
			
			//Refresh screen content
			refreshContent();
		}
		
		private function onSettingsChanged(e:Event):void
		{
			chartMaxValue = chartMaxValueStepper.value;
			chartMinValue = chartMinValueStepper.value;
			resizeOutOfBounds = resizeBoundsMark.isSelected;
			needsSave = true;
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			if (scaleFormatPicker != null)
			{
				scaleFormatPicker.removeEventListener(Event.CHANGE, onScaleFormatChange);
				scaleFormatPicker.dispose();
				scaleFormatPicker = null;
			}
			
			if (chartMaxValueStepper != null)
			{
				chartMaxValueStepper.dispose();
				chartMaxValueStepper = null;
			}
			
			if (chartMinValueStepper != null)
			{
				chartMinValueStepper.dispose();
				chartMinValueStepper = null;
			}
			
			if (resizeBoundsMark != null)
			{
				resizeBoundsMark.dispose();
				resizeBoundsMark = null;
			}
			
			super.dispose();
		}
	}
}