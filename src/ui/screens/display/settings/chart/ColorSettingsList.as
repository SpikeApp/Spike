package ui.screens.display.settings.chart
{
	import database.CommonSettings;
	
	import feathers.controls.Button;
	import feathers.controls.List;
	import feathers.controls.PanelScreen;
	import feathers.controls.ScrollPolicy;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.data.ArrayCollection;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalAlign;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import starling.core.Starling;
	import starling.events.Event;
	import starling.events.ResizeEvent;
	
	import ui.chart.ColorPicker;
	import ui.screens.display.LayoutFactory;
	
	import utils.Constants;
	
	[ResourceBundle("chartsettingsscreen")]

	public class ColorSettingsList extends List 
	{
		/* Display Objects */
		private var urgentHighColorPicker:ColorPicker;
		private var highColorPicker:ColorPicker;
		private var inRangeColorPicker:ColorPicker;
		private var lowColorPicker:ColorPicker;
		private var urgentLowColorPicker:ColorPicker;
		private var axisColorPicker:ColorPicker;
		private var chartFontColorPicker:ColorPicker;
		private var axisFontColorPicker:ColorPicker;
		private var pieChartFontColorPicker:ColorPicker;
		private var oldDataColorPicker:ColorPicker;
		private var _parent:PanelScreen
		private var resetColors:Button;
		private var pieHighColorPicker:ColorPicker;
		private var pieInRangeColorPicker:ColorPicker;
		private var pieLowColorPicker:ColorPicker;
		
		/* Properties */
		public var needsSave:Boolean = false;
		private var colorPickers:Array;
		private var urgentHighColorValue:uint;
		private var highColorValue:uint;
		private var inRangeColorValue:uint;
		private var lowColorValue:uint;
		private var urgentLowColorValue:uint;
		private var axisColorValue:uint;
		private var chartFontColorValue:uint;
		private var axisFontColorValue:uint;
		private var pieChartFontColorValue:uint;
		private var oldDataColorValue:uint;
		private var pieHighColorValue:uint;
		private var pieInRangeColorValue:uint;
		private var pieLowColorValue:uint;
		
		public function ColorSettingsList(parentDisplayObject:PanelScreen)
		{
			super();
			
			this._parent = parentDisplayObject;
			
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
		
		private function setupInitialContent():void
		{
			/* Get Colors From Database */
			urgentHighColorValue = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_URGENT_HIGH_COLOR));
			highColorValue = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_HIGH_COLOR));
			inRangeColorValue = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_IN_RANGE_COLOR));
			lowColorValue = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_LOW_COLOR));
			urgentLowColorValue = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_URGENT_LOW_COLOR));
			oldDataColorValue = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_OLD_DATA_COLOR));
			axisColorValue = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_AXIS_COLOR));
			chartFontColorValue = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_FONT_COLOR));
			axisFontColorValue = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_AXIS_FONT_COLOR));
			pieChartFontColorValue = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_PIE_CHART_FONT_COLOR));
			pieHighColorValue = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PIE_CHART_HIGH_COLOR));
			pieInRangeColorValue = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PIE_CHART_IN_RANGE_COLOR));
			pieLowColorValue = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PIE_CHART_LOW_COLOR));
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
			
			//Pie Chart Hight Color Picker
			pieHighColorPicker = new ColorPicker(20, pieHighColorValue, _parent, HorizontalAlign.LEFT, VerticalAlign.TOP);
			pieHighColorPicker.name = "pieHighColor";
			pieHighColorPicker.pivotX = 3;
			pieHighColorPicker.addEventListener(ColorPicker.CHANGED, onColorChanged);
			pieHighColorPicker.addEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened);
			pieHighColorPicker.addEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
			colorPickers.push(pieHighColorPicker);
			
			//Pie Chart In Range Color Picker
			pieInRangeColorPicker = new ColorPicker(20, pieInRangeColorValue, _parent, HorizontalAlign.LEFT, VerticalAlign.TOP);
			pieInRangeColorPicker.name = "pieInRangeColor";
			pieInRangeColorPicker.pivotX = 3;
			pieInRangeColorPicker.addEventListener(ColorPicker.CHANGED, onColorChanged);
			pieInRangeColorPicker.addEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened);
			pieInRangeColorPicker.addEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
			colorPickers.push(pieInRangeColorPicker);
			
			//Pie Chart Low Color Picker
			pieLowColorPicker = new ColorPicker(20, pieLowColorValue, _parent, HorizontalAlign.LEFT, VerticalAlign.TOP);
			pieLowColorPicker.name = "pieLowColor";
			pieLowColorPicker.pivotX = 3;
			pieLowColorPicker.addEventListener(ColorPicker.CHANGED, onColorChanged);
			pieLowColorPicker.addEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened);
			pieLowColorPicker.addEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
			colorPickers.push(pieLowColorPicker);
			
			//Old Data Color Picker
			oldDataColorPicker = new ColorPicker(20, oldDataColorValue, _parent, HorizontalAlign.LEFT, VerticalAlign.TOP);
			oldDataColorPicker.name = "oldDataColor";
			oldDataColorPicker.pivotX = 3;
			oldDataColorPicker.addEventListener(ColorPicker.CHANGED, onColorChanged);
			oldDataColorPicker.addEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened);
			oldDataColorPicker.addEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
			colorPickers.push(oldDataColorPicker);
			
			//Axis Color Picker
			axisColorPicker = new ColorPicker(20, axisColorValue, _parent, HorizontalAlign.LEFT, VerticalAlign.TOP);
			axisColorPicker.name = "axisColor";
			axisColorPicker.pivotX = 3;
			axisColorPicker.addEventListener(ColorPicker.CHANGED, onColorChanged);
			axisColorPicker.addEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened);
			axisColorPicker.addEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
			colorPickers.push(axisColorPicker);
			
			//Chart Font Color Picker
			chartFontColorPicker = new ColorPicker(20, chartFontColorValue, _parent, HorizontalAlign.LEFT, VerticalAlign.TOP);
			chartFontColorPicker.name = "chartFontColor";
			chartFontColorPicker.pivotX = 3;
			chartFontColorPicker.addEventListener(ColorPicker.CHANGED, onColorChanged);
			chartFontColorPicker.addEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened);
			chartFontColorPicker.addEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
			colorPickers.push(chartFontColorPicker);
			
			//Axis Font Color Picker
			axisFontColorPicker = new ColorPicker(20, axisFontColorValue, _parent, HorizontalAlign.LEFT, VerticalAlign.TOP);
			axisFontColorPicker.name = "axisFontColor";
			axisFontColorPicker.pivotX = 3;
			axisFontColorPicker.addEventListener(ColorPicker.CHANGED, onColorChanged);
			axisFontColorPicker.addEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened);
			axisFontColorPicker.addEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
			colorPickers.push(axisFontColorPicker);
			
			//Pie Chart Font Color Picker
			pieChartFontColorPicker = new ColorPicker(20, pieChartFontColorValue, _parent, HorizontalAlign.LEFT, VerticalAlign.TOP);
			pieChartFontColorPicker.name = "pieChartFontColor";
			pieChartFontColorPicker.pivotX = 3;
			pieChartFontColorPicker.addEventListener(ColorPicker.CHANGED, onColorChanged);
			pieChartFontColorPicker.addEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened);
			pieChartFontColorPicker.addEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
			colorPickers.push(pieChartFontColorPicker);
			
			//Color Reset Button
			resetColors = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('chartsettingsscreen','load_default_colors'));
			resetColors.addEventListener(Event.TRIGGERED, onResetColor);
			
			//Set Color Settings Item Renderer
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
					{ text: ModelLocator.resourceManagerInstance.getString('chartsettingsscreen','urgent_high_title'), accessory: urgentHighColorPicker },
					{ text: ModelLocator.resourceManagerInstance.getString('chartsettingsscreen','high_title'), accessory: highColorPicker },
					{ text: ModelLocator.resourceManagerInstance.getString('chartsettingsscreen','in_range_title'), accessory: inRangeColorPicker },
					{ text: ModelLocator.resourceManagerInstance.getString('chartsettingsscreen','low_title'), accessory: lowColorPicker },
					{ text: ModelLocator.resourceManagerInstance.getString('chartsettingsscreen','urgent_low_title'), accessory: urgentLowColorPicker },
					{ text: ModelLocator.resourceManagerInstance.getString('chartsettingsscreen','pie_high_color_title'), accessory: pieHighColorPicker },
					{ text: ModelLocator.resourceManagerInstance.getString('chartsettingsscreen','pie_in_range_color_title'), accessory: pieInRangeColorPicker },
					{ text: ModelLocator.resourceManagerInstance.getString('chartsettingsscreen','pie_low_color_title'), accessory: pieLowColorPicker },
					{ text: ModelLocator.resourceManagerInstance.getString('chartsettingsscreen','old_data_title'), accessory: oldDataColorPicker },
					{ text: ModelLocator.resourceManagerInstance.getString('chartsettingsscreen','axis_title'), accessory: axisColorPicker },
					{ text: ModelLocator.resourceManagerInstance.getString('chartsettingsscreen','chart_font_title'), accessory: chartFontColorPicker },
					{ text: ModelLocator.resourceManagerInstance.getString('chartsettingsscreen','axis_font_title'), accessory: axisFontColorPicker },
					{ text: ModelLocator.resourceManagerInstance.getString('chartsettingsscreen','pie_chart_font_title'), accessory: pieChartFontColorPicker },
					{ text: "", accessory: resetColors },
				]);
		}
		
		public function save():void
		{
			if(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_URGENT_HIGH_COLOR) != String(urgentHighColorValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_CHART_URGENT_HIGH_COLOR, String(urgentHighColorValue));
			
			if(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_HIGH_COLOR) != String(highColorValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_CHART_HIGH_COLOR, String(highColorValue));
			
			if(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_IN_RANGE_COLOR) != String(inRangeColorValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_CHART_IN_RANGE_COLOR, String(inRangeColorValue));
			
			if(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_LOW_COLOR) != String(lowColorValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_CHART_LOW_COLOR, String(lowColorValue));
			
			if(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_URGENT_LOW_COLOR) != String(urgentLowColorValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_CHART_URGENT_LOW_COLOR, String(urgentLowColorValue));
			
			if(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_OLD_DATA_COLOR) != String(oldDataColorValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_CHART_OLD_DATA_COLOR, String(oldDataColorValue));
			
			if(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_AXIS_COLOR) != String(axisColorValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_CHART_AXIS_COLOR, String(axisColorValue));
			
			if(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_FONT_COLOR) != String(chartFontColorValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_CHART_FONT_COLOR, String(chartFontColorValue));
			
			if(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_AXIS_FONT_COLOR) != String(axisFontColorValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_CHART_AXIS_FONT_COLOR, String(axisFontColorValue));
			
			if(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_PIE_CHART_FONT_COLOR) != String(pieChartFontColorValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_CHART_PIE_CHART_FONT_COLOR, String(pieChartFontColorValue));
			
			if(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PIE_CHART_HIGH_COLOR) != String(pieHighColorValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_PIE_CHART_HIGH_COLOR, String(pieHighColorValue));
			
			if(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PIE_CHART_IN_RANGE_COLOR) != String(pieInRangeColorValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_PIE_CHART_IN_RANGE_COLOR, String(pieInRangeColorValue));
			
			if(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PIE_CHART_LOW_COLOR) != String(pieLowColorValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_PIE_CHART_LOW_COLOR, String(pieLowColorValue));
			
			needsSave = false;
		}
		
		/**
		 * Event Listeners
		 */
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
			
			//Pie High Color Picker
			pieHighColorPicker.setColor(0xFFFF00);
			pieHighColorValue = 0xFFFF00;
			
			//Pie In Range Color Picker
			pieInRangeColorPicker.setColor(0x00FF00);
			pieInRangeColorValue = 0x00FF00;
			
			//Pie Low Color Picker
			pieLowColorPicker.setColor(0xFF0000);
			pieLowColorValue = 0xFF0000;
			
			//Old Data Color Picker
			oldDataColorPicker.setColor(0xABABAB);
			oldDataColorValue = 0xABABAB;
			
			//Axis Color Picker
			axisColorPicker.setColor(0xEEEEEE);
			axisColorValue = 0xEEEEEE;
			
			//Chart Font Color Picker
			chartFontColorPicker.setColor(0xEEEEEE);
			chartFontColorValue = 0xEEEEEE;
			
			//Axis Font Color Picker
			axisFontColorPicker.setColor(0xEEEEEE);
			axisFontColorValue = 0xEEEEEE;
			
			//Pie Chart Font Color Picker
			pieChartFontColorPicker.setColor(0xEEEEEE);
			pieChartFontColorValue = 0xEEEEEE;
			
			needsSave = true;
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
				}
			}
			else if(currentTargetName == "highColor")
			{
				if(highColorPicker.value != highColorValue)
				{
					highColorValue = highColorPicker.value;
					needsSave = true;
				}
			}
			else if(currentTargetName == "inRangeColor")
			{
				if(inRangeColorPicker.value != inRangeColorValue)
				{
					inRangeColorValue = inRangeColorPicker.value;
					needsSave = true;
				}
			}
			else if(currentTargetName == "lowColor")
			{
				if(lowColorPicker.value != lowColorValue)
				{
					lowColorValue = lowColorPicker.value;
					needsSave = true;
				}
			}
			else if(currentTargetName == "urgentLowColor")
			{
				if(urgentLowColorPicker.value != urgentLowColorValue)
				{
					urgentLowColorValue = urgentLowColorPicker.value;
					needsSave = true;
				}
			}
			else if(currentTargetName == "pieHighColor")
			{
				if(pieHighColorPicker.value != pieHighColorValue)
				{
					pieHighColorValue = pieHighColorPicker.value;
					needsSave = true;
				}
			}
			else if(currentTargetName == "pieInRangeColor")
			{
				if(pieInRangeColorPicker.value != pieInRangeColorValue)
				{
					pieInRangeColorValue = pieInRangeColorPicker.value;
					needsSave = true;
				}
			}
			else if(currentTargetName == "pieLowColor")
			{
				if(pieLowColorPicker.value != pieLowColorValue)
				{
					pieLowColorValue = pieLowColorPicker.value;
					needsSave = true;
				}
			}
			else if(currentTargetName == "oldDataColor")
			{
				if(oldDataColorPicker.value != oldDataColorValue)
				{
					oldDataColorValue = oldDataColorPicker.value;
					needsSave = true;
				}
			}
			else if(currentTargetName == "axisColor")
			{
				if(axisColorPicker.value != axisColorValue)
				{
					axisColorValue = axisColorPicker.value;
					needsSave = true;
				}
			}
			else if(currentTargetName == "chartFontColor")
			{
				if(chartFontColorPicker.value != chartFontColorValue)
				{
					chartFontColorValue = chartFontColorPicker.value;
					needsSave = true;
				}
			}
			else if(currentTargetName == "axisFontColor")
			{
				if(axisFontColorPicker.value != axisFontColorValue)
				{
					axisFontColorValue = axisFontColorPicker.value;
					needsSave = true;
				}
			}
			else if(currentTargetName == "pieChartFontColor")
			{
				if(pieChartFontColorPicker.value != pieChartFontColorValue)
				{
					pieChartFontColorValue = pieChartFontColorPicker.value;
					needsSave = true;
				}
			}
		}
		
		private function onStarlingResize(event:ResizeEvent):void 
		{
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
		}
		
		/**
		 * Utility
		 */
		override protected function draw():void
		{
			super.draw();
			resetColors.x += 2;
		}
		
		override public function dispose():void
		{
			Starling.current.stage.removeEventListener(starling.events.Event.RESIZE, onStarlingResize);
			
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
			
			if(pieHighColorPicker != null)
			{
				pieHighColorPicker.removeEventListener(ColorPicker.CHANGED, onColorChanged);
				pieHighColorPicker.removeEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened);
				pieHighColorPicker.removeEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
				pieHighColorPicker.dispose();
				pieHighColorPicker = null;
			}
			
			if(pieInRangeColorPicker != null)
			{
				pieInRangeColorPicker.removeEventListener(ColorPicker.CHANGED, onColorChanged);
				pieInRangeColorPicker.removeEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened);
				pieInRangeColorPicker.removeEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
				pieInRangeColorPicker.dispose();
				pieInRangeColorPicker = null;
			}
			
			if(pieLowColorPicker != null)
			{
				pieLowColorPicker.removeEventListener(ColorPicker.CHANGED, onColorChanged);
				pieLowColorPicker.removeEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened);
				pieLowColorPicker.removeEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
				pieLowColorPicker.dispose();
				pieLowColorPicker = null;
			}
			
			if(oldDataColorPicker != null)
			{
				oldDataColorPicker.removeEventListener(ColorPicker.CHANGED, onColorChanged);
				oldDataColorPicker.removeEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened);
				oldDataColorPicker.removeEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
				oldDataColorPicker.dispose();
				oldDataColorPicker = null;
			}
			
			if(axisColorPicker != null)
			{
				axisColorPicker.removeEventListener(ColorPicker.CHANGED, onColorChanged);
				axisColorPicker.removeEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened);
				axisColorPicker.removeEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
				axisColorPicker.dispose();
				axisColorPicker = null;
			}
			
			if(chartFontColorPicker != null)
			{
				chartFontColorPicker.removeEventListener(ColorPicker.CHANGED, onColorChanged);
				chartFontColorPicker.removeEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened);
				chartFontColorPicker.removeEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
				chartFontColorPicker.dispose();
				chartFontColorPicker = null;
			}
			
			if(axisFontColorPicker != null)
			{
				axisFontColorPicker.removeEventListener(ColorPicker.CHANGED, onColorChanged);
				axisFontColorPicker.removeEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened);
				axisFontColorPicker.removeEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
				axisFontColorPicker.dispose();
				axisFontColorPicker = null;
			}
			
			if(pieChartFontColorPicker != null)
			{
				pieChartFontColorPicker.removeEventListener(ColorPicker.CHANGED, onColorChanged);
				pieChartFontColorPicker.removeEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened);
				pieChartFontColorPicker.removeEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
				pieChartFontColorPicker.dispose();
				pieChartFontColorPicker = null;
			}
			
			if(resetColors != null)
			{
				resetColors.removeEventListener(Event.TRIGGERED, onResetColor);
				resetColors.dispose();
				resetColors = null;
			}
			
			super.dispose();
		}
	}
}