package ui.screens.display.settings.widget
{
	import database.CommonSettings;
	
	import feathers.controls.Button;
	import feathers.controls.Label;
	import feathers.controls.LayoutGroup;
	import feathers.controls.PanelScreen;
	import feathers.controls.ScrollPolicy;
	import feathers.controls.Slider;
	import feathers.data.ArrayCollection;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalAlign;
	import feathers.layout.VerticalLayout;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import starling.events.Event;
	import starling.events.ResizeEvent;
	
	import ui.chart.visualcomponents.ColorPicker;
	import ui.screens.display.LayoutFactory;
	import ui.screens.display.SpikeList;
	
	import utils.Constants;
	import utils.DeviceInfo;
	
	[ResourceBundle("widgetsettingsscreen")]

	public class ColorSettingsList extends SpikeList 
	{
		/* Display Objects */
		private var urgentHighColorPicker:ColorPicker;
		private var highColorPicker:ColorPicker;
		private var inRangeColorPicker:ColorPicker;
		private var lowColorPicker:ColorPicker;
		private var urgentLowColorPicker:ColorPicker;
		private var glucoseMarkerColorPicker:ColorPicker;
		private var axisColorPicker:ColorPicker;
		private var displayFontColorPicker:ColorPicker;
		private var axisFontColorPicker:ColorPicker;
		private var mainLineColorPicker:ColorPicker;
		private var _parent:PanelScreen
		private var resetColors:Button;
		private var copyColors:Button;
		private var gridLinesColorPicker:ColorPicker;
		private var backgroundColorPicker:ColorPicker;
		private var backgroundOpacitySlider:Slider;
		private var opacityContainer:LayoutGroup;
		private var backgroundOpacityLabel:Label;
		private var oldDataColorPicker:ColorPicker;
		
		/* Properties */
		public var needsSave:Boolean = false;
		private var colorPickers:Array;
		private var urgentHighColorValue:uint;
		private var highColorValue:uint;
		private var inRangeColorValue:uint;
		private var lowColorValue:uint;
		private var urgentLowColorValue:uint;
		private var axisColorValue:uint;
		private var mainLineColorValue:uint;
		private var displayLabelsColorValue:uint;
		private var axisFontColorValue:uint;
		private var glucoseMarkerColorValue:uint;
		private var backgroundColorValue:uint;
		private var backgroundOpacityValue:uint;
		private var gridLinesColorValue:uint;
		private var oldDataColorValue:uint;
		
		public function ColorSettingsList(parentDisplayObject:PanelScreen)
		{
			super();
			
			this._parent = parentDisplayObject;
			
			setupProperties();
			stupInitialContent();
			setupContent();
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
			
			//Initialize Objects
			colorPickers = [];
		}
		
		private function stupInitialContent():void
		{
			/* Get Colors From Database */
			urgentHighColorValue = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_URGENT_HIGH_COLOR));
			highColorValue = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_HIGH_COLOR));
			inRangeColorValue = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_IN_RANGE_COLOR));
			lowColorValue = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_LOW_COLOR));
			urgentLowColorValue = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_URGENT_LOW_COLOR));
			displayLabelsColorValue = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_DISPLAY_LABELS_COLOR));
			glucoseMarkerColorValue = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_GLUCOSE_MARKER_COLOR));
			axisColorValue = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_AXIS_COLOR));
			axisFontColorValue = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_AXIS_FONT_COLOR));
			gridLinesColorValue = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_GRID_LINES_COLOR));
			mainLineColorValue = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_MAIN_LINE_COLOR));
			backgroundColorValue = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_BACKGROUND_COLOR));
			backgroundOpacityValue = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_BACKGROUND_OPACITY));
			oldDataColorValue = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_OLD_DATA_COLOR));
		}
		
		private function setupContent():void
		{
			//Urgent High Color Picker
			urgentHighColorPicker = new ColorPicker(20, urgentHighColorValue, _parent, HorizontalAlign.LEFT, VerticalAlign.BOTTOM);
			urgentHighColorPicker.name = "urgentHighColor";
			urgentHighColorPicker.pivotX = 3;
			urgentHighColorPicker.addEventListener(ColorPicker.CHANGED, onColorChanged);
			urgentHighColorPicker.addEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened);
			urgentHighColorPicker.addEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
			colorPickers.push(urgentHighColorPicker);
			
			//High Color Picker
			highColorPicker = new ColorPicker(20, highColorValue, _parent, HorizontalAlign.LEFT, VerticalAlign.BOTTOM);
			highColorPicker.name = "highColor";
			highColorPicker.pivotX = 3;
			highColorPicker.addEventListener(ColorPicker.CHANGED, onColorChanged);
			highColorPicker.addEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened);
			highColorPicker.addEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
			colorPickers.push(highColorPicker);
			
			//In Range Color Picker
			inRangeColorPicker = new ColorPicker(20, inRangeColorValue, _parent, HorizontalAlign.LEFT, VerticalAlign.BOTTOM);
			inRangeColorPicker.name = "inRangeColor";
			inRangeColorPicker.pivotX = 3;
			inRangeColorPicker.addEventListener(ColorPicker.CHANGED, onColorChanged);
			inRangeColorPicker.addEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened)
			inRangeColorPicker.addEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
			colorPickers.push(inRangeColorPicker);
			
			//Low Color Picker
			lowColorPicker = new ColorPicker(20, lowColorValue, _parent, HorizontalAlign.LEFT, VerticalAlign.BOTTOM);
			lowColorPicker.name = "lowColor";
			lowColorPicker.pivotX = 3;
			lowColorPicker.addEventListener(ColorPicker.CHANGED, onColorChanged);
			lowColorPicker.addEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened);
			lowColorPicker.addEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
			colorPickers.push(lowColorPicker);
			
			//Urgent Low Color Picker
			urgentLowColorPicker = new ColorPicker(20, urgentLowColorValue, _parent, HorizontalAlign.LEFT, VerticalAlign.TOP);
			urgentLowColorPicker.name = "urgentLowColor";
			urgentLowColorPicker.pivotX = 3;
			urgentLowColorPicker.addEventListener(ColorPicker.CHANGED, onColorChanged);
			urgentLowColorPicker.addEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened);
			urgentLowColorPicker.addEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
			colorPickers.push(urgentLowColorPicker);
			
			//Old Data Color Picker
			oldDataColorPicker = new ColorPicker(20, oldDataColorValue, _parent, HorizontalAlign.LEFT, VerticalAlign.TOP);
			oldDataColorPicker.name = "oldDataColor";
			oldDataColorPicker.pivotX = 3;
			oldDataColorPicker.addEventListener(ColorPicker.CHANGED, onColorChanged);
			oldDataColorPicker.addEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened);
			oldDataColorPicker.addEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
			colorPickers.push(oldDataColorPicker);
			
			//Display Font Color Picker
			displayFontColorPicker = new ColorPicker(20, displayLabelsColorValue, _parent, HorizontalAlign.LEFT, VerticalAlign.TOP);
			displayFontColorPicker.name = "displayFontColor";
			displayFontColorPicker.pivotX = 3;
			displayFontColorPicker.addEventListener(ColorPicker.CHANGED, onColorChanged);
			displayFontColorPicker.addEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened);
			displayFontColorPicker.addEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
			colorPickers.push(displayFontColorPicker);
			
			//Glucose Marker Color Picker
			glucoseMarkerColorPicker = new ColorPicker(20, glucoseMarkerColorValue, _parent, HorizontalAlign.LEFT, VerticalAlign.TOP);
			glucoseMarkerColorPicker.name = "glucoseMarkerColor";
			glucoseMarkerColorPicker.pivotX = 3;
			glucoseMarkerColorPicker.addEventListener(ColorPicker.CHANGED, onColorChanged);
			glucoseMarkerColorPicker.addEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened);
			glucoseMarkerColorPicker.addEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
			colorPickers.push(glucoseMarkerColorPicker);
			
			//Axis Color Picker
			axisColorPicker = new ColorPicker(20, axisColorValue, _parent, HorizontalAlign.LEFT, VerticalAlign.TOP);
			axisColorPicker.name = "axisColor";
			axisColorPicker.pivotX = 3;
			axisColorPicker.addEventListener(ColorPicker.CHANGED, onColorChanged);
			axisColorPicker.addEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened);
			axisColorPicker.addEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
			colorPickers.push(axisColorPicker);
			
			//Axis Font Color Picker
			axisFontColorPicker = new ColorPicker(20, axisFontColorValue, _parent, HorizontalAlign.LEFT, VerticalAlign.TOP);
			axisFontColorPicker.name = "axisFontColor";
			axisFontColorPicker.pivotX = 3;
			axisFontColorPicker.addEventListener(ColorPicker.CHANGED, onColorChanged);
			axisFontColorPicker.addEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened);
			axisFontColorPicker.addEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
			colorPickers.push(axisFontColorPicker);
			
			//Grid Lines Color Picker
			gridLinesColorPicker = new ColorPicker(20, gridLinesColorValue, _parent, HorizontalAlign.LEFT, VerticalAlign.TOP);
			gridLinesColorPicker.name = "gridLinesColor";
			gridLinesColorPicker.pivotX = 3;
			gridLinesColorPicker.addEventListener(ColorPicker.CHANGED, onColorChanged);
			gridLinesColorPicker.addEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened);
			gridLinesColorPicker.addEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
			colorPickers.push(gridLinesColorPicker);
			
			//Main line Color Picker
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) != "true")
			{
				mainLineColorPicker = new ColorPicker(20, mainLineColorValue, _parent, HorizontalAlign.LEFT, VerticalAlign.TOP);
				mainLineColorPicker.name = "mainLineColor";
				mainLineColorPicker.pivotX = 3;
				mainLineColorPicker.addEventListener(ColorPicker.CHANGED, onColorChanged);
				mainLineColorPicker.addEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened);
				mainLineColorPicker.addEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
				colorPickers.push(mainLineColorPicker);
			}
			
			//Background Color Picker
			backgroundColorPicker = new ColorPicker(20, backgroundColorValue, _parent, HorizontalAlign.LEFT, VerticalAlign.TOP);
			backgroundColorPicker.name = "backgroundColor";
			backgroundColorPicker.pivotX = 3;
			backgroundColorPicker.addEventListener(ColorPicker.CHANGED, onColorChanged);
			backgroundColorPicker.addEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened);
			backgroundColorPicker.addEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
			colorPickers.push(backgroundColorPicker);
			
			//Background Opacity Container
			var opacityLayout:VerticalLayout = new VerticalLayout();
			opacityLayout.horizontalAlign = HorizontalAlign.CENTER;
			opacityContainer = new LayoutGroup();
			opacityContainer.layout = opacityLayout;
			opacityContainer.pivotX = 10;
			
			//Background Opacity Slider
			backgroundOpacitySlider = new Slider();
			backgroundOpacitySlider.width = Constants.isPortrait ? 110 : 210;
			backgroundOpacitySlider.minimum = 0;
			backgroundOpacitySlider.maximum = 100;
			backgroundOpacitySlider.step = 1;
			backgroundOpacitySlider.page = 10;
			backgroundOpacitySlider.value = backgroundOpacityValue;
			backgroundOpacitySlider.addEventListener(Event.CHANGE, onBackgroundOpacityUpdated);
			opacityContainer.addChild(backgroundOpacitySlider);
			
			//Background Opacity Label
			backgroundOpacityLabel = LayoutFactory.createLabel(String(backgroundOpacityValue), HorizontalAlign.CENTER);
			opacityContainer.addChild(backgroundOpacityLabel);
			
			//Color Reset Button
			resetColors = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('widgetsettingsscreen','load_default_colors'));
			resetColors.addEventListener(Event.TRIGGERED, onResetColor);
			
			//Color Copy Button
			copyColors = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('widgetsettingsscreen','copy_main_chart_colors'));
			copyColors.addEventListener(Event.TRIGGERED, onCopyColor);
			
			//Set Colors Data
			var dataList:Array = [];
			dataList.push({ label: ModelLocator.resourceManagerInstance.getString('widgetsettingsscreen','urgent_high_title'), accessory: urgentHighColorPicker });
			dataList.push({ label: ModelLocator.resourceManagerInstance.getString('widgetsettingsscreen','high_title'), accessory: highColorPicker });
			dataList.push({ label: ModelLocator.resourceManagerInstance.getString('widgetsettingsscreen','in_range_title'), accessory: inRangeColorPicker });
			dataList.push({ label: ModelLocator.resourceManagerInstance.getString('widgetsettingsscreen','low_title'), accessory: lowColorPicker });
			dataList.push({ label: ModelLocator.resourceManagerInstance.getString('widgetsettingsscreen','urgent_low_title'), accessory: urgentLowColorPicker });
			dataList.push({ label: ModelLocator.resourceManagerInstance.getString('widgetsettingsscreen','old_data_title'), accessory: oldDataColorPicker });
			dataList.push({ label: ModelLocator.resourceManagerInstance.getString('widgetsettingsscreen','display_font_title'), accessory: displayFontColorPicker });
			dataList.push({ label: ModelLocator.resourceManagerInstance.getString('widgetsettingsscreen','axis_title'), accessory: axisColorPicker });
			dataList.push({ label: ModelLocator.resourceManagerInstance.getString('widgetsettingsscreen','axis_font_title'), accessory: axisFontColorPicker });
			dataList.push({ label: ModelLocator.resourceManagerInstance.getString('widgetsettingsscreen','glucose_marker_title'), accessory: glucoseMarkerColorPicker });
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) != "true")
				dataList.push({ label: ModelLocator.resourceManagerInstance.getString('widgetsettingsscreen','main_line'), accessory: mainLineColorPicker });
			dataList.push({ label: ModelLocator.resourceManagerInstance.getString('widgetsettingsscreen','grid_lines'), accessory: gridLinesColorPicker });
			dataList.push({ label: ModelLocator.resourceManagerInstance.getString('widgetsettingsscreen','background'), accessory: backgroundColorPicker });
			dataList.push({ label: Constants.deviceModel != DeviceInfo.IPHONE_X_Xs_XsMax_Xr ? ModelLocator.resourceManagerInstance.getString('widgetsettingsscreen','background_opacity') : ModelLocator.resourceManagerInstance.getString('widgetsettingsscreen','background_opacity_x'), accessory: opacityContainer });
			dataList.push({ label: "", accessory: resetColors });
			dataList.push({ label: "", accessory: copyColors });
			
			dataProvider = new ArrayCollection(dataList);
		}
		
		public function save():void
		{
			if (!needsSave)
				return;
			
			if(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_URGENT_HIGH_COLOR) != String(urgentHighColorValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_URGENT_HIGH_COLOR, String(urgentHighColorValue));
			
			if(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_HIGH_COLOR) != String(highColorValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_HIGH_COLOR, String(highColorValue));
			
			if(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_IN_RANGE_COLOR) != String(inRangeColorValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_IN_RANGE_COLOR, String(inRangeColorValue));
			
			if(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_LOW_COLOR) != String(lowColorValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_LOW_COLOR, String(lowColorValue));
			
			if(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_URGENT_LOW_COLOR) != String(urgentLowColorValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_URGENT_LOW_COLOR, String(urgentLowColorValue));
			
			if(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_OLD_DATA_COLOR) != String(oldDataColorValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_OLD_DATA_COLOR, String(oldDataColorValue));
			
			if(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_DISPLAY_LABELS_COLOR) != String(displayLabelsColorValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_DISPLAY_LABELS_COLOR, String(displayLabelsColorValue));
			
			if(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_GLUCOSE_MARKER_COLOR) != String(glucoseMarkerColorValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_GLUCOSE_MARKER_COLOR, String(glucoseMarkerColorValue));
			
			if(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_AXIS_COLOR) != String(axisColorValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_AXIS_COLOR, String(axisColorValue));
			
			if(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_AXIS_FONT_COLOR) != String(axisFontColorValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_AXIS_FONT_COLOR, String(axisFontColorValue));
			
			if(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_GRID_LINES_COLOR) != String(gridLinesColorValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_GRID_LINES_COLOR, String(gridLinesColorValue));
			
			if(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_MAIN_LINE_COLOR) != String(mainLineColorValue && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) != "true"))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_MAIN_LINE_COLOR, String(mainLineColorValue));
			
			if(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_BACKGROUND_COLOR) != String(backgroundColorValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_BACKGROUND_COLOR, String(backgroundColorValue));
			
			if(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_BACKGROUND_OPACITY) != String(backgroundOpacityValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_BACKGROUND_OPACITY, String(backgroundOpacityValue));
			
			needsSave = false;
		}
		
		/**
		 * Event Listeners
		 */
		private function onBackgroundOpacityUpdated(e:Event):void
		{
			backgroundOpacityLabel.text = String(backgroundOpacitySlider.value);
			backgroundOpacityValue = backgroundOpacitySlider.value;
			
			needsSave = true;
			
			save();
		}
		
		private function onResetColor(e:Event):void
		{
			//Urgent High Color Picker
			urgentHighColorPicker.setColor(0xFF0000);
			urgentHighColorValue = 0xFF0000;
			
			//High Color Picker
			highColorPicker.setColor(0xFFFF00);
			highColorValue = 0xFFFF00;
			
			//In Range Color Picker
			inRangeColorPicker.setColor(0x00FF00);
			inRangeColorValue = 0x00FF00;
			
			//Low Color Picker
			lowColorPicker.setColor(0xFFFF00);
			lowColorValue = 0xFFFF00;
			
			//Urgent Low Color Picker
			urgentLowColorPicker.setColor(0xFF0000);
			urgentLowColorValue = 0xFF0000;
			
			//Urgent Low Color Picker
			oldDataColorPicker.setColor(0xABABAB);
			oldDataColorValue = 0xABABAB;
			
			//Display Labels Color
			displayFontColorPicker.setColor(0xFFFFFF);
			displayLabelsColorValue = 0xFFFFFF;
			
			//Glucose Markers Color
			glucoseMarkerColorPicker.setColor(0xFFFFFF);
			glucoseMarkerColorValue = 0xFFFFFF;
			
			//Axis Color Picker
			axisColorPicker.setColor(0xFFFFFF);
			axisColorValue = 0xFFFFFF;
			
			//Axis Font Color Picker
			axisFontColorPicker.setColor(0xFFFFFF);
			axisFontColorValue = 0xFFFFFF;
			
			//Grid Lines Color Picker
			gridLinesColorPicker.setColor(0xFFFFFF);
			gridLinesColorValue = 0xFFFFFF;
			
			//Main Line Color Picker
			if(mainLineColorPicker != null)
			{
				mainLineColorPicker.setColor(0xFFFFFF);
				mainLineColorValue = 0xFFFFFF;
			}
			
			//Background Color Picker
			backgroundColorPicker.setColor(0x000000);
			backgroundColorValue = 0x000000;
			
			//Background Opacity
			backgroundOpacitySlider.value = 70;
			backgroundOpacityValue = 70;
			
			needsSave = true;
			
			save();
		}
		
		private function onCopyColor(e:Event):void
		{
			//Urgent High Color Picker
			urgentHighColorValue = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_URGENT_HIGH_COLOR));
			urgentHighColorPicker.setColor(urgentHighColorValue);
			
			//High Color Picker
			highColorValue = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_HIGH_COLOR));
			highColorPicker.setColor(highColorValue);
			
			//In Range Color Picker
			inRangeColorValue = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_IN_RANGE_COLOR));
			inRangeColorPicker.setColor(inRangeColorValue);
			
			//Low Color Picker
			lowColorValue = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_LOW_COLOR));
			lowColorPicker.setColor(lowColorValue);
			
			//Urgent Low Color Picker
			urgentLowColorValue = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_URGENT_LOW_COLOR));
			urgentLowColorPicker.setColor(urgentLowColorValue);
			
			//Old Data Color Picker
			oldDataColorValue = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_OLD_DATA_COLOR));
			oldDataColorPicker.setColor(oldDataColorValue);
			
			//Display Labels Color
			displayLabelsColorValue = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_FONT_COLOR));
			displayFontColorPicker.setColor(displayLabelsColorValue);
			
			//Axis Color Picker
			axisColorValue = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_AXIS_COLOR));
			axisColorPicker.setColor(axisColorValue);
			
			//Axis Font Color Picker
			axisFontColorValue = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_AXIS_FONT_COLOR));
			axisFontColorPicker.setColor(axisFontColorValue);
			
			needsSave = true;
			
			save();
		}
		
		private function onColorPaletteOpened(e:Event):void
		{
			var triggerName:String = e.data.name;
			for (var i:int = 0; i < colorPickers.length; i++) 
			{
				var currentName:String = colorPickers[i].name;
				if(currentName != triggerName)
					(colorPickers[i] as ColorPicker).palette.visible = false;
			}
			_parent.verticalScrollPolicy = ScrollPolicy.OFF;
		}
		
		private function onColorPaletteClosed(e:Event):void
		{
			_parent.verticalScrollPolicy = ScrollPolicy.ON;
		}
		
		private function onColorChanged(e:Event):void
		{
			var currentTargetName:String = (e.currentTarget as ColorPicker).name;
			
			if(currentTargetName == "urgentHighColor")
			{
				if(urgentHighColorPicker.value != urgentHighColorValue)
				{
					urgentHighColorValue = urgentHighColorPicker.value;
					needsSave = true;
					save();
				}
			}
			else if(currentTargetName == "highColor")
			{
				if(highColorPicker.value != highColorValue)
				{
					highColorValue = highColorPicker.value;
					needsSave = true;
					save();
				}
			}
			else if(currentTargetName == "inRangeColor")
			{
				if(inRangeColorPicker.value != inRangeColorValue)
				{
					inRangeColorValue = inRangeColorPicker.value;
					needsSave = true;
					save();
				}
			}
			else if(currentTargetName == "lowColor")
			{
				if(lowColorPicker.value != lowColorValue)
				{
					lowColorValue = lowColorPicker.value;
					needsSave = true;
					save();
				}
			}
			else if(currentTargetName == "urgentLowColor")
			{
				if(urgentLowColorPicker.value != urgentLowColorValue)
				{
					urgentLowColorValue = urgentLowColorPicker.value;
					needsSave = true;
					save();
				}
			}
			else if(currentTargetName == "oldDataColor")
			{
				if(oldDataColorPicker.value != oldDataColorValue)
				{
					oldDataColorValue = oldDataColorPicker.value;
					needsSave = true;
					save();
				}
			}
			else if(currentTargetName == "displayFontColor")
			{
				if(displayFontColorPicker.value != displayLabelsColorValue)
				{
					displayLabelsColorValue = displayFontColorPicker.value;
					needsSave = true;
					save();
				}
			}
			else if(currentTargetName == "glucoseMarkerColor")
			{
				if(glucoseMarkerColorPicker.value != glucoseMarkerColorValue)
				{
					glucoseMarkerColorValue = glucoseMarkerColorPicker.value;
					needsSave = true;
					save();
				}
			}
			else if(currentTargetName == "axisColor")
			{
				if(axisColorPicker.value != axisColorValue)
				{
					axisColorValue = axisColorPicker.value;
					needsSave = true;
					save();
				}
			}
			else if(currentTargetName == "axisFontColor")
			{
				if(axisFontColorPicker.value != axisFontColorValue)
				{
					axisFontColorValue = axisFontColorPicker.value;
					needsSave = true;
					save();
				}
			}
			else if(currentTargetName == "gridLinesColor")
			{
				if(gridLinesColorPicker.value != gridLinesColorValue)
				{
					gridLinesColorValue = gridLinesColorPicker.value;
					needsSave = true;
					save();
				}
			}
			else if(currentTargetName == "mainLineColor")
			{
				if(mainLineColorPicker.value != mainLineColorValue)
				{
					mainLineColorValue = mainLineColorPicker.value;
					needsSave = true;
					save();
				}
			}
			else if(currentTargetName == "backgroundColor")
			{
				if(backgroundColorPicker.value != backgroundColorValue)
				{
					backgroundColorValue = backgroundColorPicker.value;
					needsSave = true;
					save();
				}
			}
		}
		
		override protected function onStarlingResize(event:ResizeEvent):void 
		{
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
			
			if (backgroundOpacitySlider != null)
				backgroundOpacitySlider.width = Constants.isPortrait ? 110 : 210;
			
			setupRenderFactory();
		}
		
		/**
		 * Utility
		 */
		override protected function draw():void
		{
			super.draw();
			resetColors.x += 2;
			copyColors.x += 2;
		}
		
		override public function dispose():void
		{
			if(urgentHighColorPicker != null)
			{
				urgentHighColorPicker.removeEventListener(ColorPicker.CHANGED, onColorChanged);
				urgentHighColorPicker.removeEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened);
				urgentHighColorPicker.removeEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
				urgentHighColorPicker.dispose();
				urgentHighColorPicker = null;
			}
			
			if(highColorPicker != null)
			{
				highColorPicker.removeEventListener(ColorPicker.CHANGED, onColorChanged);
				highColorPicker.removeEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened);
				highColorPicker.removeEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
				highColorPicker.dispose();
				highColorPicker = null;
			}
			
			if(inRangeColorPicker != null)
			{
				inRangeColorPicker.removeEventListener(ColorPicker.CHANGED, onColorChanged);
				inRangeColorPicker.removeEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened)
				inRangeColorPicker.removeEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
				inRangeColorPicker.dispose();
				inRangeColorPicker = null;
			}
			
			if(lowColorPicker != null)
			{
				lowColorPicker.removeEventListener(ColorPicker.CHANGED, onColorChanged);
				lowColorPicker.removeEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened);
				lowColorPicker.removeEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
				lowColorPicker.dispose();
				lowColorPicker = null;
			}
			
			if(urgentLowColorPicker != null)
			{
				urgentLowColorPicker.removeEventListener(ColorPicker.CHANGED, onColorChanged);
				urgentLowColorPicker.removeEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened);
				urgentLowColorPicker.removeEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
				urgentLowColorPicker.dispose();
				urgentLowColorPicker = null;
			}
			
			if(oldDataColorPicker != null)
			{
				oldDataColorPicker.removeEventListener(ColorPicker.CHANGED, onColorChanged);
				oldDataColorPicker.removeEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened);
				oldDataColorPicker.removeEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
				oldDataColorPicker.dispose();
				oldDataColorPicker = null;
			}
			
			if(glucoseMarkerColorPicker != null)
			{
				glucoseMarkerColorPicker.removeEventListener(ColorPicker.CHANGED, onColorChanged);
				glucoseMarkerColorPicker.removeEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened);
				glucoseMarkerColorPicker.removeEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
				glucoseMarkerColorPicker.dispose();
				glucoseMarkerColorPicker = null;
			}
			
			if(axisColorPicker != null)
			{
				axisColorPicker.removeEventListener(ColorPicker.CHANGED, onColorChanged);
				axisColorPicker.removeEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened);
				axisColorPicker.removeEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
				axisColorPicker.dispose();
				axisColorPicker = null;
			}
			
			if(displayFontColorPicker != null)
			{
				displayFontColorPicker.removeEventListener(ColorPicker.CHANGED, onColorChanged);
				displayFontColorPicker.removeEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened);
				displayFontColorPicker.removeEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
				displayFontColorPicker.dispose();
				displayFontColorPicker = null;
			}
			
			if(axisFontColorPicker != null)
			{
				axisFontColorPicker.removeEventListener(ColorPicker.CHANGED, onColorChanged);
				axisFontColorPicker.removeEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened);
				axisFontColorPicker.removeEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
				axisFontColorPicker.dispose();
				axisFontColorPicker = null;
			}
			
			if(gridLinesColorPicker != null)
			{
				gridLinesColorPicker.removeEventListener(ColorPicker.CHANGED, onColorChanged);
				gridLinesColorPicker.removeEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened);
				gridLinesColorPicker.removeEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
				gridLinesColorPicker.dispose();
				gridLinesColorPicker = null;
			}
			
			if(mainLineColorPicker != null)
			{
				mainLineColorPicker.removeEventListener(ColorPicker.CHANGED, onColorChanged);
				mainLineColorPicker.removeEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened);
				mainLineColorPicker.removeEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
				mainLineColorPicker.dispose();
				mainLineColorPicker = null;
			}
			
			if(backgroundColorPicker != null)
			{
				backgroundColorPicker.removeEventListener(ColorPicker.CHANGED, onColorChanged);
				backgroundColorPicker.removeEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened);
				backgroundColorPicker.removeEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
				backgroundColorPicker.dispose();
				backgroundColorPicker = null;
			}
			
			if(resetColors != null)
			{
				resetColors.removeEventListener(Event.TRIGGERED, onResetColor);
				resetColors.dispose();
				resetColors = null;
			}
			
			if(copyColors != null)
			{
				copyColors.removeEventListener(Event.TRIGGERED, onCopyColor);
				copyColors.dispose();
				copyColors = null;
			}
			
			if(backgroundOpacitySlider != null)
			{
				opacityContainer.removeChild(backgroundOpacitySlider);
				backgroundOpacitySlider.removeEventListener(Event.CHANGE, onBackgroundOpacityUpdated);
				backgroundOpacitySlider.dispose();
				backgroundOpacitySlider = null;
			}
			
			if(backgroundOpacityLabel != null)
			{
				opacityContainer.removeChild(backgroundOpacityLabel);
				backgroundOpacityLabel.dispose();
				backgroundOpacityLabel = null;
			}
			
			if(opacityContainer != null)
			{
				opacityContainer.dispose();
				opacityContainer = null;
			}
			
			super.dispose();
		}
	}
}