package ui.screens.display.settings.chart
{
	import database.CommonSettings;
	
	import feathers.controls.List;
	import feathers.controls.NumericStepper;
	import feathers.controls.Slider;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.data.ArrayCollection;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import starling.core.Starling;
	import starling.events.Event;
	import starling.events.ResizeEvent;
	
	import ui.screens.display.LayoutFactory;
	
	import utils.Constants;
	import utils.DeviceInfo;
	
	[ResourceBundle("chartsettingsscreen")]

	public class SizeSettingsList extends List 
	{
		/* Display Objects */
		private var glucoseMarkerRadius:NumericStepper;
		private var glucoseDisplayFontSize:Slider;
		private var timeAgoDisplayFontSize:Slider;
		private var axisFontSize:Slider;
		
		/* Properties */
		public var needsSave:Boolean = false;
		private var glucoseMarkerRadiusValue:Number;
		private var glucoseFontSizeValue:Number;
		private var timeAgoFontSizeValue:Number;
		private var axisFontSizeValue:Number;
		
		public function SizeSettingsList()
		{
			super();
			
			Starling.current.stage.addEventListener(starling.events.Event.RESIZE, onStarlingResize);
			
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
			/* Controls */
			glucoseMarkerRadius = LayoutFactory.createNumericStepper(1, 5, 3);
			glucoseMarkerRadius.validate();
			
			glucoseDisplayFontSize = new Slider();
			glucoseDisplayFontSize.minimum = 0;
			glucoseDisplayFontSize.maximum = 100;
			glucoseDisplayFontSize.value = 50;
			glucoseDisplayFontSize.step = 50;
			glucoseDisplayFontSize.width = Constants.deviceModel != DeviceInfo.IPHONE_X ? glucoseMarkerRadius.width : 100;
			if (!Constants.isPortrait)
				glucoseDisplayFontSize.width += 100;
			glucoseDisplayFontSize.pivotX = 10;
			
			timeAgoDisplayFontSize = new Slider();
			timeAgoDisplayFontSize.minimum = 0;
			timeAgoDisplayFontSize.maximum = 100;
			timeAgoDisplayFontSize.value = 50;
			timeAgoDisplayFontSize.step = 50;
			timeAgoDisplayFontSize.width = Constants.deviceModel != DeviceInfo.IPHONE_X ? glucoseMarkerRadius.width : 100;
			if (!Constants.isPortrait)
				timeAgoDisplayFontSize.width += 100;
			timeAgoDisplayFontSize.pivotX = 10;
			
			axisFontSize = new Slider();
			axisFontSize.minimum = 0;
			axisFontSize.maximum = 100;
			axisFontSize.value = 50;
			axisFontSize.step = 50;
			axisFontSize.width = Constants.deviceModel != DeviceInfo.IPHONE_X ? glucoseMarkerRadius.width : 100;
			if (!Constants.isPortrait)
				axisFontSize.width += 100;
			axisFontSize.pivotX = 10;
			
			//Set Size Settings Item Renderer
			itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "text";
				itemRenderer.accessoryField = "accessory";
				itemRenderer.paddingRight = 0;
				return itemRenderer;
			};
			
			//Set Colors Data
			dataProvider = new ArrayCollection(
				[
					{ text: ModelLocator.resourceManagerInstance.getString('chartsettingsscreen','glucose_marker_radius'), accessory: glucoseMarkerRadius },
					{ text: ModelLocator.resourceManagerInstance.getString('chartsettingsscreen','glucose_font_size'), accessory: glucoseDisplayFontSize },
					{ text: ModelLocator.resourceManagerInstance.getString('chartsettingsscreen','time_ago_font_size'), accessory: timeAgoDisplayFontSize },
					{ text: ModelLocator.resourceManagerInstance.getString('chartsettingsscreen','axis_font_size'), accessory: axisFontSize }
				]);
		}
		
		private function setupInitialState():void
		{
			/* Get Sizes From Database */
			glucoseMarkerRadiusValue = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_MARKER_RADIUS));
			glucoseFontSizeValue = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_BG_FONT_SIZE));
			timeAgoFontSizeValue = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_TIMEAGO_FONT_SIZE));
			axisFontSizeValue = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_AXIS_FONT_SIZE));
			
			/* Set Control's Sizes */
			glucoseMarkerRadius.value = glucoseMarkerRadiusValue;
			
			if (glucoseFontSizeValue == 0.8)
				glucoseDisplayFontSize.value = 0;
			else if (glucoseFontSizeValue == 1)
				glucoseDisplayFontSize.value = 50;
			else if (glucoseFontSizeValue == 1.2)
				glucoseDisplayFontSize.value = 100;
			
			if (timeAgoFontSizeValue == 0.8)
				timeAgoDisplayFontSize.value = 0;
			else if (timeAgoFontSizeValue == 1)
				timeAgoDisplayFontSize.value = 50;
			else if (timeAgoFontSizeValue == 1.2)
				timeAgoDisplayFontSize.value = 100;
			
			if (axisFontSizeValue == 0.8)
				axisFontSize.value = 0;
			else if (axisFontSizeValue == 1)
				axisFontSize.value = 50;
			else if (axisFontSizeValue == 1.2)
				axisFontSize.value = 100;
			
			/* Set Event Listeners */
			glucoseMarkerRadius.addEventListener(Event.CHANGE, onSizeChange);
			glucoseDisplayFontSize.addEventListener(Event.CHANGE, onSizeChange);
			timeAgoDisplayFontSize.addEventListener(Event.CHANGE, onSizeChange);
			axisFontSize.addEventListener(Event.CHANGE, onSizeChange);
		}
		
		public function save():void
		{
			if (Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_MARKER_RADIUS)) != glucoseMarkerRadiusValue)
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_CHART_MARKER_RADIUS, String(glucoseMarkerRadiusValue));
					
			if (Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_BG_FONT_SIZE)) != glucoseFontSizeValue)
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_CHART_BG_FONT_SIZE, String(glucoseFontSizeValue));
			
			if (Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_TIMEAGO_FONT_SIZE)) != timeAgoFontSizeValue)
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_CHART_TIMEAGO_FONT_SIZE, String(timeAgoFontSizeValue));
			
			if (Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_AXIS_FONT_SIZE)) != axisFontSizeValue)
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_CHART_AXIS_FONT_SIZE, String(axisFontSizeValue));
			
			needsSave = false;
		}
		
		/**
		 * Event Handlers
		 */
		private function onSizeChange(e:Event):void
		{
			if (glucoseMarkerRadius.value != glucoseMarkerRadiusValue)
				glucoseMarkerRadiusValue = glucoseMarkerRadius.value;
			
			if (glucoseDisplayFontSize.value == 0)
				glucoseFontSizeValue = 0.8;
			else if (glucoseDisplayFontSize.value == 50)
				glucoseFontSizeValue = 1;
			else if (glucoseDisplayFontSize.value == 100)
				glucoseFontSizeValue = 1.2;
			
			if (timeAgoDisplayFontSize.value == 0)
				timeAgoFontSizeValue = 0.8;
			else if (timeAgoDisplayFontSize.value == 50)
				timeAgoFontSizeValue = 1;
			else if (timeAgoDisplayFontSize.value == 100)
				timeAgoFontSizeValue = 1.2;
			
			if (axisFontSize.value == 0)
				axisFontSizeValue = 0.8;
			else if (axisFontSize.value == 50)
				axisFontSizeValue = 1;
			else if (axisFontSize.value == 100)
				axisFontSizeValue = 1.2;
			
			needsSave = true;
		}
		
		private function onStarlingResize(event:ResizeEvent):void 
		{
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
			
			if (glucoseMarkerRadius != null)
			{
				if (glucoseDisplayFontSize != null)
				{
					glucoseDisplayFontSize.width = Constants.deviceModel != DeviceInfo.IPHONE_X ? glucoseMarkerRadius.width : 100;
					if (!Constants.isPortrait)
						glucoseDisplayFontSize.width += 100;
				}
				
				if (timeAgoDisplayFontSize != null)
				{
					timeAgoDisplayFontSize.width = Constants.deviceModel != DeviceInfo.IPHONE_X ? glucoseMarkerRadius.width : 100;
					if (!Constants.isPortrait)
						timeAgoDisplayFontSize.width += 100;
				}
				
				if (axisFontSize != null)
				{
					axisFontSize.width = Constants.deviceModel != DeviceInfo.IPHONE_X ? glucoseMarkerRadius.width : 100;
					if (!Constants.isPortrait)
						axisFontSize.width += 100;
				}
			}
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			Starling.current.stage.removeEventListener(starling.events.Event.RESIZE, onStarlingResize);
			
			if (glucoseMarkerRadius != null)
			{
				glucoseMarkerRadius.removeEventListener(Event.CHANGE, onSizeChange);
				glucoseMarkerRadius.dispose();
				glucoseMarkerRadius = null;
			}
			
			if(glucoseDisplayFontSize != null)
			{
				glucoseDisplayFontSize.removeEventListener(Event.CHANGE, onSizeChange);
				glucoseDisplayFontSize.dispose();
				glucoseDisplayFontSize = null;
			}
			
			if(timeAgoDisplayFontSize != null)
			{
				timeAgoDisplayFontSize.removeEventListener(Event.CHANGE, onSizeChange);
				timeAgoDisplayFontSize.dispose();
				timeAgoDisplayFontSize = null;
			}
			
			if(axisFontSize != null)
			{
				axisFontSize.removeEventListener(Event.CHANGE, onSizeChange);
				axisFontSize.dispose();
				axisFontSize = null;
			}
			
			super.dispose();
		}
	}
}