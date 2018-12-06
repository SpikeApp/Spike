package ui.screens.display.settings.treatments
{
	import database.CommonSettings;
	
	import feathers.controls.Button;
	import feathers.controls.Check;
	import feathers.controls.PanelScreen;
	import feathers.controls.ScrollPolicy;
	import feathers.data.ArrayCollection;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalAlign;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import starling.events.Event;
	
	import ui.chart.visualcomponents.ColorPicker;
	import ui.screens.display.LayoutFactory;
	import ui.screens.display.SpikeList;
	
	import utils.Constants;
	
	[ResourceBundle("chartsettingsscreen")]
	[ResourceBundle("chartscreen")]

	public class BolusWizardUISettingsList extends SpikeList 
	{
		/* Display Objects */
		private var suggestionsColorPicker:ColorPicker;
		private var _parent:PanelScreen
		private var resetColors:Button;
		private var suggestionsOnTopCheck:Check;
		private var noSpaceBetweenSuggestionsCheck:Check;
		
		/* Properties */
		public var needsSave:Boolean = false;
		private var colorPickers:Array;
		private var suggestionsColorValue:uint;
		private var suggestionsOnTopValue:Boolean;
		private var noSpaceBetweenSuggestionsValue:Boolean;
		
		public function BolusWizardUISettingsList(parentDisplayObject:PanelScreen)
		{
			super(true);
			
			this._parent = parentDisplayObject;
			
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
			suggestionsColorValue = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BOLUS_WIZARD_SUGGESTION_LABEL_COLOR));
			suggestionsOnTopValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BOLUS_WIZARD_SUGGESTION_COMPONENTS_ON_TOP) == "true";
			noSpaceBetweenSuggestionsValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BOLUS_WIZARD_NO_SPACE_BETWEEN_SUGGESTIONS) == "true";
		}
		
		private function setupContent():void
		{
			//Urgent High Color Picker
			suggestionsColorPicker = new ColorPicker(20, suggestionsColorValue, _parent, HorizontalAlign.LEFT, VerticalAlign.BOTTOM);
			suggestionsColorPicker.name = "suggestionsColor";
			suggestionsColorPicker.addEventListener(ColorPicker.CHANGED, onColorChanged);
			suggestionsColorPicker.addEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened);
			suggestionsColorPicker.addEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
			colorPickers.push(suggestionsColorPicker);
			
			//Suggestions On Top
			suggestionsOnTopCheck = LayoutFactory.createCheckMark(suggestionsOnTopValue);
			suggestionsOnTopCheck.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Suggestions On Top
			noSpaceBetweenSuggestionsCheck = LayoutFactory.createCheckMark(noSpaceBetweenSuggestionsValue);
			noSpaceBetweenSuggestionsCheck.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Color Reset Button
			resetColors = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('chartsettingsscreen','load_default_colors'));
			resetColors.addEventListener(Event.TRIGGERED, onResetColor);
			
			//Set Colors Data
			var data:Array = [];
			data.push( { label: ModelLocator.resourceManagerInstance.getString('treatments','suggestions_font_color_label'), accessory: suggestionsColorPicker } );
			data.push( { label: ModelLocator.resourceManagerInstance.getString('treatments','suggestions_at_the_top_label'), accessory: suggestionsOnTopCheck } );
			data.push( { label: ModelLocator.resourceManagerInstance.getString('treatments','no_suggestions_spaces_label'), accessory: noSpaceBetweenSuggestionsCheck } );
			data.push( { label: "", accessory: resetColors } );
			
			dataProvider = new ArrayCollection(data);
		}
		
		public function save():void
		{
			if(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BOLUS_WIZARD_SUGGESTION_LABEL_COLOR) != String(suggestionsColorValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_BOLUS_WIZARD_SUGGESTION_LABEL_COLOR, String(suggestionsColorValue), true, false);
			
			if(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BOLUS_WIZARD_SUGGESTION_COMPONENTS_ON_TOP) != String(suggestionsOnTopValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_BOLUS_WIZARD_SUGGESTION_COMPONENTS_ON_TOP, String(suggestionsOnTopValue), true, false);
			
			if(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BOLUS_WIZARD_NO_SPACE_BETWEEN_SUGGESTIONS) != String(noSpaceBetweenSuggestionsValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_BOLUS_WIZARD_NO_SPACE_BETWEEN_SUGGESTIONS, String(noSpaceBetweenSuggestionsValue), true, false);
			
			needsSave = false;
		}
		
		/**
		 * Event Listeners
		 */
		private function onResetColor(e:Event):void
		{
			//Urgent High Color Picker
			suggestionsColorPicker.setColor(0xFF0000);
			suggestionsColorValue = 0xFF0000;
			
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
			
			if(currentTargetName == "suggestionsColor")
			{
				if(suggestionsColorPicker.value != suggestionsColorValue)
				{
					suggestionsColorValue = suggestionsColorPicker.value;
					needsSave = true;
				}
			}
		}
		
		private function onSettingsChanged(e:Event):void
		{
			suggestionsOnTopValue = suggestionsOnTopCheck.isSelected;
			noSpaceBetweenSuggestionsValue = noSpaceBetweenSuggestionsCheck.isSelected;
			
			needsSave = true;
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
			if(suggestionsColorPicker != null)
			{
				suggestionsColorPicker.removeEventListener(ColorPicker.CHANGED, onColorChanged);
				suggestionsColorPicker.removeEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened);
				suggestionsColorPicker.removeEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
				suggestionsColorPicker.dispose();
				suggestionsColorPicker = null;
			}
			
			if(resetColors != null)
			{
				resetColors.removeEventListener(Event.TRIGGERED, onResetColor);
				resetColors.dispose();
				resetColors = null;
			}
			
			if (suggestionsOnTopCheck != null)
			{
				suggestionsOnTopCheck.removeFromParent();
				suggestionsOnTopCheck.removeEventListener(Event.CHANGE, onSettingsChanged);
				suggestionsOnTopCheck.dispose();
				suggestionsOnTopCheck = null;
			}
			
			if (noSpaceBetweenSuggestionsCheck != null)
			{
				noSpaceBetweenSuggestionsCheck.removeFromParent();
				noSpaceBetweenSuggestionsCheck.removeEventListener(Event.CHANGE, onSettingsChanged);
				noSpaceBetweenSuggestionsCheck.dispose();
				noSpaceBetweenSuggestionsCheck = null;
			}
			
			super.dispose();
		}
	}
}