package display.settings.chart
{
	import flash.system.System;
	
	import chart.ColorPicker;
	
	import display.LayoutFactory;
	
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
	
	import starling.events.Event;
	
	import utils.Constants;

	public class ColorSettingsList extends List 
	{
		/* Properties */
		private var colorPickers:Array;

		/* Display Objects */
		private var urgentHighColorPicker:ColorPicker;
		private var highColorPicker:ColorPicker;
		private var inRangeColorPicker:ColorPicker;
		private var lowColorPicker:ColorPicker;
		private var urgentLowColorPicker:ColorPicker;
		private var axisColorPicker:ColorPicker;
		private var textColorPicker:ColorPicker;
		private var _parent:PanelScreen
		private var resetColors:Button;
		
		public function ColorSettingsList(parentDisplayObject:PanelScreen)
		{
			super();
			
			this._parent = parentDisplayObject;
			
			//Initialize Objects
			colorPickers = [];
			
			//Set Properties
			clipContent = false;
			isSelectable = false;
			autoHideBackground = true;
			hasElasticEdges = false;
			paddingBottom = 5;
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
			
			//Urgent High Color Picker
			urgentHighColorPicker = new ColorPicker(20, 0xff0000, parentDisplayObject, HorizontalAlign.LEFT, VerticalAlign.BOTTOM);
			urgentHighColorPicker.name = "urgentHighColor";
			urgentHighColorPicker.addEventListener(ColorPicker.CHANGED, onColorChanged);
			urgentHighColorPicker.addEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened);
			urgentHighColorPicker.addEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
			colorPickers.push(urgentHighColorPicker);
			
			//High Color Picker
			highColorPicker = new ColorPicker(20, 0xffff00, parentDisplayObject, HorizontalAlign.LEFT, VerticalAlign.BOTTOM);
			highColorPicker.name = "highColor";
			highColorPicker.addEventListener(ColorPicker.CHANGED, onColorChanged);
			highColorPicker.addEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened);
			highColorPicker.addEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
			colorPickers.push(highColorPicker);
			
			//In Range Color Picker
			inRangeColorPicker = new ColorPicker(20, 0x00ff00, parentDisplayObject, HorizontalAlign.LEFT, VerticalAlign.BOTTOM);
			inRangeColorPicker.name = "inRangeColor";
			inRangeColorPicker.addEventListener(ColorPicker.CHANGED, onColorChanged);
			inRangeColorPicker.addEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened)
			inRangeColorPicker.addEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
			colorPickers.push(inRangeColorPicker);
			
			//Low Color Picker
			lowColorPicker = new ColorPicker(20, 0xffff00, parentDisplayObject, HorizontalAlign.LEFT, VerticalAlign.BOTTOM);
			lowColorPicker.name = "lowColor";
			lowColorPicker.addEventListener(ColorPicker.CHANGED, onColorChanged);
			lowColorPicker.addEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened);
			lowColorPicker.addEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
			colorPickers.push(lowColorPicker);
			
			//Urgent Low Color Picker
			urgentLowColorPicker = new ColorPicker(20, 0xff0000, parentDisplayObject, HorizontalAlign.LEFT, VerticalAlign.TOP);
			urgentLowColorPicker.name = "urgentLowColor";
			urgentLowColorPicker.addEventListener(ColorPicker.CHANGED, onColorChanged);
			urgentLowColorPicker.addEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened);
			urgentLowColorPicker.addEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
			colorPickers.push(urgentLowColorPicker);
			
			//Axis Color Picker
			axisColorPicker = new ColorPicker(20, 0xFFFFFF, parentDisplayObject, HorizontalAlign.LEFT, VerticalAlign.TOP);
			axisColorPicker.name = "axisColor";
			axisColorPicker.addEventListener(ColorPicker.CHANGED, onColorChanged);
			axisColorPicker.addEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened);
			axisColorPicker.addEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
			colorPickers.push(axisColorPicker);
			
			//Text Color Picker
			textColorPicker = new ColorPicker(20, 0xFFFFFF, parentDisplayObject, HorizontalAlign.LEFT, VerticalAlign.TOP);
			textColorPicker.name = "fontColor";
			textColorPicker.addEventListener(ColorPicker.CHANGED, onColorChanged);
			textColorPicker.addEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened);
			textColorPicker.addEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
			colorPickers.push(textColorPicker);
			
			//Color Reset Button
			resetColors = LayoutFactory.createButton("Load Defaults");
			resetColors.addEventListener(Event.TRIGGERED, onResetColor);
			
			//Set Color Settings Item Renderer
			itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "text";
				itemRenderer.accessoryField = "accessory";
				return itemRenderer;
			};
			
			//Set Colors Data
			dataProvider = new ArrayCollection(
				[
					{ text: "Urgent High", accessory: urgentHighColorPicker },
					{ text: "High", accessory: highColorPicker },
					{ text: "In Range", accessory: inRangeColorPicker },
					{ text: "Low", accessory: lowColorPicker },
					{ text: "Urgent Low", accessory: urgentLowColorPicker },
					{ text: "Axis", accessory: axisColorPicker },
					{ text: "Text", accessory: textColorPicker },
					{ text: "", accessory: resetColors },
				]);
		}
		
		override protected function draw():void
		{
			super.draw();
			resetColors.x += 2;
		}
		
		private function onResetColor(e:Event):void
		{
			//Urgent High Color Picker
			urgentHighColorPicker.setColor(0xff0000);
			
			//High Color Picker
			highColorPicker.setColor(0xffff00);
			
			//In Range Color Picker
			inRangeColorPicker.setColor(0x00ff00);
			
			//Low Color Picker
			lowColorPicker.setColor(0xffff00);
			
			//Urgent Low Color Picker
			urgentLowColorPicker.setColor(0xff0000);
			
			//Axis Color Picker
			axisColorPicker.setColor(0xFFFFFF);
			
			//Text Color Picker
			textColorPicker.setColor(0xFFFFFF);
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
			//Update Database and Chart
		}
		
		override public function dispose():void
		{
			if(urgentHighColorPicker != null)
			{
				urgentHighColorPicker.dispose();
				urgentHighColorPicker = null;
			}
			if(highColorPicker != null)
			{
				highColorPicker.dispose();
				highColorPicker = null;
			}
			if(inRangeColorPicker != null)
			{
				inRangeColorPicker.dispose();
				inRangeColorPicker = null;
			}
			if(lowColorPicker != null)
			{
				lowColorPicker.dispose();
				lowColorPicker = null;
			}
			if(urgentLowColorPicker != null)
			{
				urgentLowColorPicker.dispose();
				urgentLowColorPicker = null;
			}
			if(axisColorPicker != null)
			{
				axisColorPicker.dispose();
				axisColorPicker = null;
			}
			if(textColorPicker != null)
			{
				textColorPicker.dispose();
				textColorPicker = null;
			}
			if(resetColors != null)
			{
				resetColors.dispose();
				resetColors = null;
			}
			
			System.pauseForGCIfCollectionImminent(0);
				
			super.dispose();
		}
	}
}