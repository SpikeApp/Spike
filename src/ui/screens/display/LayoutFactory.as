package ui.screens.display
{
	import flash.text.AutoCapitalize;
	import flash.text.SoftKeyboardType;
	import flash.text.engine.LineJustification;
	import flash.text.engine.SpaceJustifier;
	
	import feathers.controls.Button;
	import feathers.controls.Check;
	import feathers.controls.Label;
	import feathers.controls.LayoutGroup;
	import feathers.controls.NumericStepper;
	import feathers.controls.PickerList;
	import feathers.controls.Radio;
	import feathers.controls.TextInput;
	import feathers.controls.ToggleSwitch;
	import feathers.core.ToggleGroup;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.HorizontalLayout;
	import feathers.layout.VerticalAlign;
	import feathers.layout.VerticalLayout;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import starling.display.Image;
	import starling.events.Event;
	import starling.text.TextFormat;
	import starling.textures.Texture;

	public class LayoutFactory
	{
		
		private static const SECTION_HEADER_PADDING:int = 10;
		private static const SECTION_LIST_PADDING:int = 10;
		private static const SECTION_BODY_GAP:int = 5;
		
		public function LayoutFactory() {}
		
		public static function createRadioButton(label:String, group:ToggleGroup, isSelected:Boolean = false):Radio
		{
			var radio:Radio = new Radio();
			radio.label = label;
			radio.isSelected = isSelected;
			radio.toggleGroup = group;
			
			return radio;
		}
		
		//Input Text Fields
		public static function createTextInput(isPassword:Boolean = false, isNumeric: Boolean = false, width:Number = 140, horizontalAlign:String = null, isNumericExtended:Boolean = false, isEmail:Boolean = false, isURL:Boolean = false, capitalizeOnFirstFocus:Boolean = false, autoCorrect:Boolean = false, isNumericExtendedWithNegatives:Boolean = false):TextInput
		{
			var inputField:TextInput = new TextInput();
			inputField.displayAsPassword = isPassword;
			inputField.width = width;
			
			if(horizontalAlign != null)
			{
				var textFormat:TextFormat = new TextFormat( "Roboto", 14, 0xEEEEEE, horizontalAlign, VerticalAlign.TOP );
				inputField.fontStyles = textFormat;
				inputField.promptFontStyles = inputField.fontStyles.clone();
			}
			
			if(isNumeric)
			{
				inputField.restrict = "0-9";
				inputField.textEditorProperties.softKeyboardType = SoftKeyboardType.NUMBER;
			}
			else if (isNumericExtended)
			{
				inputField.restrict = "0-9.,";
				inputField.textEditorProperties.softKeyboardType = SoftKeyboardType.DECIMAL;
				
			}
			else if (isNumericExtendedWithNegatives)
			{
				inputField.restrict = "0-9.,\\-";
				inputField.textEditorProperties.softKeyboardType = SoftKeyboardType.DECIMAL;
				
			}
			else if (isEmail)
			{
				inputField.textEditorProperties.softKeyboardType = SoftKeyboardType.EMAIL;
			}
			else if (isURL)
			{
				inputField.textEditorProperties.softKeyboardType = SoftKeyboardType.URL;
			}
			
			if (capitalizeOnFirstFocus)
			{
				inputField.textEditorProperties.autoCapitalize = AutoCapitalize.SENTENCE;
			}
			
			if (autoCorrect)
			{
				inputField.textEditorProperties.autoCorrect = true;
			}
			
			return inputField;
		}
		
		//Toggle Switches
		public static function createToggleSwitch(enabled:Boolean = false):ToggleSwitch
		{
			var toggleSwitch:ToggleSwitch = new ToggleSwitch();
			toggleSwitch.isSelected = enabled;
			
			return toggleSwitch;
		}
		
		public static function createCheckMark(selected:Boolean = false, label:String = null):Check
		{
			var check:Check = new Check();
			check.isSelected = selected;
			if(label != null) check.label = label;
			
			return check;
		}
		
		//Label for Settings Sections
		public static function createSectionLabel(labelText:String, sublabel:Boolean = false, align:String = HorizontalAlign.LEFT):Label
		{
			var label:Label = new Label();
			label.text = labelText;
			var txtFormat:TextFormat = new TextFormat("Roboto", 16, 0xEEEEEE,HorizontalAlign.LEFT);
			txtFormat.bold = true;
			txtFormat.horizontalAlign = align;
			label.fontStyles = txtFormat;
			if(!sublabel)
				label.paddingTop = SECTION_HEADER_PADDING;
			else
				label.paddingTop = 2 * SECTION_HEADER_PADDING;
			label.paddingBottom = SECTION_BODY_GAP;
			
			return label;
		}
		
		public static function createLabel(labelText:String, horizontalAlign:String = HorizontalAlign.LEFT, verticalAlign:String = VerticalAlign.TOP, fontSize:Number = 14, isBold:Boolean = false, fontColor:Number = Number.NaN):Label
		{
			var label:Label = new Label();
			label.text = labelText;
			var txtFormat:TextFormat = new TextFormat("Roboto", fontSize, 0xEEEEEE,horizontalAlign, verticalAlign);
			txtFormat.bold = isBold;
			if (!isNaN(fontColor))
				txtFormat.color = fontColor;
			label.fontStyles = txtFormat;
			
			if (horizontalAlign == HorizontalAlign.JUSTIFY)
				label.textRendererProperties.textJustifier = new SpaceJustifier( "en", LineJustification.ALL_BUT_MANDATORY_BREAK);
			
			return label;
		}
		
		public static function createContentLabel(labelText:String, width:Number, justifyText:Boolean = true, lastOnScreen:Boolean = false):Label
		{
			var label:Label = new Label();
			label.styleNameList.add( Label.ALTERNATE_STYLE_NAME_DETAIL );
			label.wordWrap = true;
			label.width = width;
			label.text  = labelText;
			
			if(justifyText)
				label.textRendererProperties.textJustifier = new SpaceJustifier( "en", LineJustification.ALL_BUT_MANDATORY_BREAK);
			
			if(lastOnScreen)
				label.paddingBottom = 10;
			
			return label;
		}
		
		//Buttons
		public static function createButton(label:String = "", accent:Boolean = false, icon:Texture = null):Button
		{
			var button:Button = new Button();
			if(accent)
				button.styleNameList.add(BaseMaterialDeepGreyAmberMobileTheme.THEME_STYLE_NAME_BUTTON_ACCENT);
			button.label = label;
			if(icon != null)
				button.defaultIcon = new Image( icon );
			return button;
		}
		
		public static function createPlayButton(eventHandler:Function):Button
		{
			var button:Button = new Button();
			button.styleNameList.add( BaseMaterialDeepGreyAmberMobileTheme.THEME_STYLE_NAME_BUTTON_HEADER_QUIET_ICON_ONLY );
			button.defaultIcon = new Image(MaterialDeepGreyAmberMobileThemeIcons.playOutlineTexture);
			button.addEventListener(Event.TRIGGERED, eventHandler);
			
			return button;
		}
		
		//PickerLists
		public static function createPickerList():PickerList
		{
			var pickerList:PickerList = new PickerList();
			return pickerList;
		}
		
		//Numeric Steppers
		public static function createNumericStepper(minimumValue:Number = 0, maximumValue:Number = 1000, currentValue:Number = 0, step:Number = 1):NumericStepper
		{
			var stepper:NumericStepper = new NumericStepper();
			stepper.minimum = minimumValue;
			stepper.maximum = maximumValue;
			if(!isNaN(currentValue))
				stepper.value = currentValue;
			stepper.step = step;
			return stepper;
		}
		
		//Horizontal LayoutGroups
		public static function createLayoutGroup(orientation:String, horizontalAlign:String = HorizontalAlign.LEFT, verticalAlign:String = VerticalAlign.MIDDLE, gap:Number = 0):LayoutGroup
		{
			var group:LayoutGroup = new LayoutGroup();
			
			if (orientation == "horizontal")
			{
				var horizontalLayout:HorizontalLayout = new HorizontalLayout();
				horizontalLayout.horizontalAlign = horizontalAlign;
				horizontalLayout.verticalAlign = verticalAlign;
				horizontalLayout.gap = gap;
				
				group.layout = horizontalLayout;
			}
			else if (orientation == "vertical")
			{
				var verticalLayout:VerticalLayout = new VerticalLayout();
				verticalLayout.horizontalAlign = horizontalAlign;
				verticalLayout.verticalAlign = verticalAlign;
				verticalLayout.gap = gap;
				
				group.layout = verticalLayout;
			}
			
			return group;
		}
	}
}