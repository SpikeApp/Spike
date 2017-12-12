package display.settings.speech
{
	import flash.system.System;
	
	import display.LayoutFactory;
	
	import feathers.controls.List;
	import feathers.controls.NumericStepper;
	import feathers.controls.PickerList;
	import feathers.controls.ToggleSwitch;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.data.ArrayCollection;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import starling.events.Event;
	
	import utils.Constants;

	public class SpeechSettingsList extends List 
	{
		/* Display Objects */
		private var speechToggle:ToggleSwitch;
		private var trendToggle:ToggleSwitch;
		private var deltaToggle:ToggleSwitch;
		private var speechInterval:NumericStepper;
		private var languagePicker:PickerList;
		
		public function SpeechSettingsList()
		{
			super();
		}
		override protected function initialize():void 
		{
			super.initialize();
			
			//Set Properties
			clipContent = false;
			isSelectable = false;
			autoHideBackground = true;
			hasElasticEdges = false;
			paddingBottom = 5;
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
			
			//On/Off Toggle
			speechToggle = LayoutFactory.createToggleSwitch(false);
			speechToggle.addEventListener( Event.CHANGE, onSpeechOnOff );
			
			//Trend Toggle
			trendToggle = LayoutFactory.createToggleSwitch(false);
			
			//Delta Toggle
			deltaToggle = LayoutFactory.createToggleSwitch(false);
			
			//Interval
			speechInterval = LayoutFactory.createNumericStepper(1, 1000, 1);
			
			//Language Picker
			languagePicker = LayoutFactory.createPickerList();
			var languagePickerList:ArrayCollection = new ArrayCollection(
				[
					{ label: "Dutch (Belgium)" },
					{ label: "Dutch (Netherlands)" },
					{ label: "English (Australia)" },
					{ label: "English (Ireland)" },
					{ label: "English (South Africa)" },
					{ label: "English (UK)" },
					{ label: "English (US)" },
					{ label: "French (Canada)" },
					{ label: "French (France)" },
					{ label: "Polish (Poland)" },
					{ label: "Portuguese (Brazil)" },
					{ label: "Portuguese (Portugal)" },
					{ label: "Russian (Russia)" },
					{ label: "Spanish (Mexico)" },
					{ label: "Spanish (Spain)" },
				]);
			languagePicker.labelField = "label";
			languagePicker.dataProvider = languagePickerList;
			languagePicker.itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "label";
				return itemRenderer;
			}
			
			//Set Item Renderer
			itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "label";
				itemRenderer.accessoryField = "accessory";
				return itemRenderer;
			};
			
			//Define Speech Settings Data
			reloadSpeechSettings(speechToggle.isSelected);
		}
		
		private function onSpeechOnOff(event:Event):void
		{
			var toggle:ToggleSwitch = ToggleSwitch( event.currentTarget );
			
			if(toggle.isSelected)
				reloadSpeechSettings(true);
			else
				reloadSpeechSettings(false);
		}
		
		private function reloadSpeechSettings(fullDisplay:Boolean):void
		{
			if(fullDisplay)
			{
				dataProvider = new ArrayCollection(
					[
						{ label: "Speak BG Readings", accessory: speechToggle },
						{ label: "Speak BG Trend", accessory: trendToggle },
						{ label: "Speak BG Delta", accessory: deltaToggle },
						{ label: "Interval", accessory: speechInterval },
						{ label: "Language", accessory: languagePicker },
					]);
			}
			else
			{
				dataProvider = new ArrayCollection(
					[
						{ label: "Enabled", accessory: speechToggle },
					]);
			}
		}
		
		override public function dispose():void
		{
			if(speechToggle != null)
			{
				speechToggle.dispose();
				speechToggle = null;
			}
			if(trendToggle != null)
			{
				trendToggle.dispose();
				trendToggle = null;
			}
			if(deltaToggle != null)
			{
				deltaToggle.dispose();
				deltaToggle = null;
			}
			if(speechInterval != null)
			{
				speechInterval.dispose();
				speechInterval = null;
			}
			if(languagePicker != null)
			{
				languagePicker.dispose();
				languagePicker = null;
			}
			
			System.pauseForGCIfCollectionImminent(0);
			
			super.dispose();
		}
	}
}