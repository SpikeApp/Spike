package treatments
{
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	import mx.utils.ObjectUtil;
	
	import database.BgReading;
	
	import feathers.controls.Button;
	import feathers.controls.Callout;
	import feathers.controls.Check;
	import feathers.controls.Label;
	import feathers.controls.LayoutGroup;
	import feathers.controls.NumericStepper;
	import feathers.controls.PickerList;
	import feathers.controls.ScrollBarDisplayMode;
	import feathers.controls.ScrollContainer;
	import feathers.controls.TextInput;
	import feathers.controls.popups.DropDownPopUpContentManager;
	import feathers.data.ArrayCollection;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.HorizontalLayout;
	import feathers.layout.VerticalAlign;
	import feathers.layout.VerticalLayout;
	
	import model.ModelLocator;
	
	import starling.animation.Transitions;
	import starling.animation.Tween;
	import starling.core.Starling;
	import starling.display.Sprite;
	import starling.events.Event;
	
	import ui.AppInterface;
	import ui.chart.GlucoseFactory;
	import ui.screens.Screens;
	import ui.screens.display.LayoutFactory;
	
	import utils.Constants;
	import utils.DeviceInfo;

	public class BolusWizard
	{
		/* Properties */
		private static var initialStart:Boolean = true;
		private static var contentWidth:Number = 270;
		private static var yPos:Number = 0;
		private static var calculationTimeout:uint = 0;
		
		/* Objects */
		private static var currentProfile:Profile;
		
		/* Display Objects */
		private static var calloutPositionHelper:Sprite;
		private static var bwMainContainer:LayoutGroup;
		private static var bwCurrentGlucoseContainer:LayoutGroup;
		private static var bwGlucoseLabel:Label;
		private static var bwGlucoseStepper:NumericStepper;
		private static var bolusWizardCallout:Callout;
		private static var bwTitle:Label;
		private static var bolusWizardActionContainer:LayoutGroup;
		private static var bolusWizardCancelButton:Button;
		private static var bolusWizardAddButton:Button;
		private static var bwGlucoseLabelContainer:LayoutGroup;
		private static var bwGlucoseCheck:Check;
		private static var bwIOBContainer:LayoutGroup;
		private static var bwIOBLabel:Label;
		private static var bwCurrentIOBLabel:Label;
		private static var bwCOBContainer:LayoutGroup;
		private static var bwCOBLabel:Label;
		private static var bwCurrentCOBLabel:Label;
		private static var bwCarbsContainer:LayoutGroup;
		private static var bwCarbsLabelContainer:LayoutGroup;
		private static var bwCarbsCheck:Check;
		private static var bwCarbsLabel:Label;
		private static var bwCarbsStepper:NumericStepper;
		private static var bwCarbTypeLabel:Label;
		private static var bwCarbsOffsetContainer:LayoutGroup;
		private static var bwCarbsOffsetLabel:Label;
		private static var bwCarbsOffsetStepper:NumericStepper;
		private static var bwCarbTypeContainer:LayoutGroup;
		private static var bwCarbTypePicker:PickerList;
		private static var bwOtherCorrectionContainer:LayoutGroup;
		private static var bwOtherCorrectionLabel:Label;
		private static var bwOtherCorrectionStepper:NumericStepper;
		private static var bwIOBLabelContainer:LayoutGroup;
		private static var bwIOBCheck:Check;
		private static var bwCOBLabelContainer:LayoutGroup;
		private static var bwCOBCheck:Check;
		private static var bwNotes:TextInput;
		private static var bwScrollContainer:ScrollContainer;
		private static var bwSuggestionLabel:Label;
		private static var missedSettingsContainer:LayoutGroup;
		private static var missedSettingsTitle:Label;
		private static var missedSettingsLabel:Label;
		private static var missedSettingsActionsContainer:LayoutGroup;
		private static var missedSettingsCancelButton:Button;
		private static var missedSettingsConfigureButton:Button;
		private static var bolusWizardConfigureCallout:Callout;
		
		
		
		
		////
		
		private static var currentIOB:Number = 0;
		private static var currentCOB:Number = 0;
		private static var currentBG:Number = 0;
		
		public function BolusWizard()
		{
			throw new Error("BolusWizard is not meant to be instantiated!");
		}
		
		public static function display():void
		{
			currentProfile = ProfileManager.getProfileByTime(new Date().valueOf());
			
			if (currentProfile == null || currentProfile.insulinSensitivityFactors == "" || currentProfile.insulinToCarbRatios == "" || currentProfile.targetGlucoseRates == "")
			{
				displayMissedSettingsCallout();
				return;
			}
			
			if (initialStart)
			{
				createDisplayObjects();
				setCalloutPositionHelper();
				initialStart = false;
			}
			
			populateComponents();
			performCalculations();
			displayCallout();
		}		
		
		private static function createDisplayObjects():void
		{
			//Scroll Container
			bwScrollContainer = new ScrollContainer();
			bwScrollContainer.layout = new VerticalLayout();
			bwScrollContainer.scrollBarDisplayMode = ScrollBarDisplayMode.FIXED_FLOAT;
			bwScrollContainer.verticalScrollBarProperties.paddingRight = -10;
			
			//Display Container
			bwMainContainer = LayoutFactory.createLayoutGroup("vertical", HorizontalAlign.LEFT, null, 10);
			bwMainContainer.width = contentWidth;
			
			//Title
			bwTitle = LayoutFactory.createLabel("", HorizontalAlign.CENTER, VerticalAlign.TOP, 18, true);
			bwTitle.width = contentWidth;
			bwMainContainer.addChild(bwTitle);
			
			//Current Glucose
			bwCurrentGlucoseContainer = LayoutFactory.createLayoutGroup("horizontal");
			bwCurrentGlucoseContainer.width = contentWidth;
			
			bwGlucoseLabelContainer = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.LEFT, VerticalAlign.MIDDLE, 5);
			bwCurrentGlucoseContainer.addChild(bwGlucoseLabelContainer);
			
			bwGlucoseCheck = LayoutFactory.createCheckMark(true);
			bwGlucoseCheck.addEventListener(Event.CHANGE, performCalculations);
			bwGlucoseLabelContainer.addChild(bwGlucoseCheck);
			
			bwGlucoseLabel = LayoutFactory.createLabel("");
			bwGlucoseLabelContainer.addChild(bwGlucoseLabel);
			
			bwGlucoseStepper = LayoutFactory.createNumericStepper(0, 0, 0, 1);
			bwGlucoseStepper.addEventListener(Event.CHANGE, delayCalculations);
			bwGlucoseStepper.validate();
			bwCurrentGlucoseContainer.addChild(bwGlucoseStepper);
			
			bwMainContainer.addChild(bwCurrentGlucoseContainer);
			
			//Carbs
			bwCarbsContainer = LayoutFactory.createLayoutGroup("horizontal");
			bwCarbsContainer.width = contentWidth;
			
			bwCarbsLabelContainer = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.LEFT, VerticalAlign.MIDDLE, 5);
			bwCarbsContainer.addChild(bwCarbsLabelContainer);
			
			bwCarbsCheck = LayoutFactory.createCheckMark(true);
			bwCarbsCheck.addEventListener(Event.CHANGE, showHideCarbExtras);
			bwCarbsLabelContainer.addChild(bwCarbsCheck);
			
			bwCarbsLabel = LayoutFactory.createLabel("");
			bwCarbsLabelContainer.addChild(bwCarbsLabel);
			
			bwCarbsStepper = LayoutFactory.createNumericStepper(0, 500, 0, 0.5);
			bwCarbsStepper.addEventListener(Event.CHANGE, delayCalculations);
			bwCarbsStepper.validate();
			bwCarbsContainer.addChild(bwCarbsStepper);
			
			bwMainContainer.addChild(bwCarbsContainer);
			
			//Carbs Offset
			bwCarbsOffsetContainer = LayoutFactory.createLayoutGroup("horizontal");
			bwCarbsOffsetContainer.width = contentWidth;
			bwMainContainer.addChild(bwCarbsOffsetContainer);
			
			bwCarbsOffsetLabel = LayoutFactory.createLabel("");
			bwCarbsOffsetContainer.addChild(bwCarbsOffsetLabel);
			
			bwCarbsOffsetStepper = LayoutFactory.createNumericStepper(-300, 300, 0, 5);
			bwCarbsOffsetStepper.validate();
			bwCarbsOffsetContainer.addChild(bwCarbsOffsetStepper);
			
			//Carb Type
			bwCarbTypeContainer = LayoutFactory.createLayoutGroup("horizontal");
			bwMainContainer.addChild(bwCarbTypeContainer);
			
			bwCarbTypeLabel = LayoutFactory.createLabel("");
			bwCarbTypeContainer.addChild(bwCarbTypeLabel);
			
			bwCarbTypePicker = LayoutFactory.createPickerList();
			bwCarbTypePicker.labelField = "label";
			bwCarbTypePicker.popUpContentManager = new DropDownPopUpContentManager();
			bwCarbTypePicker.dataProvider = new ArrayCollection
			(
				[
					ModelLocator.resourceManagerInstance.getString('treatments','carbs_fast_label'),
					ModelLocator.resourceManagerInstance.getString('treatments','carbs_medium_label'),
					ModelLocator.resourceManagerInstance.getString('treatments','carbs_slow_label')
				]
			);
			bwCarbTypePicker.addEventListener(Event.CHANGE, repositonCarbTypePicker);
			
			bwCarbTypeContainer.addChild(bwCarbTypePicker);
			bwCarbTypePicker.validate();
			
			//Other Correction
			bwOtherCorrectionContainer = LayoutFactory.createLayoutGroup("horizontal");
			bwOtherCorrectionContainer.width = contentWidth;
			bwMainContainer.addChild(bwOtherCorrectionContainer);
			
			bwOtherCorrectionLabel = LayoutFactory.createLabel("");
			bwOtherCorrectionContainer.addChild(bwOtherCorrectionLabel);
			
			bwOtherCorrectionStepper = LayoutFactory.createNumericStepper(0, 100, 0, 0.1);
			bwOtherCorrectionStepper.addEventListener(Event.CHANGE, delayCalculations);
			bwOtherCorrectionStepper.validate();
			bwOtherCorrectionContainer.addChild(bwOtherCorrectionStepper);
			
			//Current IOB
			bwIOBContainer = LayoutFactory.createLayoutGroup("horizontal");
			bwIOBContainer.width = contentWidth;
			bwMainContainer.addChild(bwIOBContainer);
			
			bwIOBLabelContainer = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.LEFT, VerticalAlign.MIDDLE, 5);
			bwIOBContainer.addChild(bwIOBLabelContainer);
			
			bwIOBCheck = LayoutFactory.createCheckMark(false);
			bwIOBCheck.addEventListener(Event.CHANGE, performCalculations);
			bwIOBLabelContainer.addChild(bwIOBCheck);
			
			bwIOBLabel = LayoutFactory.createLabel("");
			bwIOBLabelContainer.addChild(bwIOBLabel);
			
			bwCurrentIOBLabel = LayoutFactory.createLabel("");
			bwIOBContainer.addChild(bwCurrentIOBLabel);
			
			//Current COB
			bwCOBContainer = LayoutFactory.createLayoutGroup("horizontal");
			bwCOBContainer.width = contentWidth;
			bwMainContainer.addChild(bwCOBContainer);
			
			bwCOBLabelContainer = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.LEFT, VerticalAlign.MIDDLE, 5);
			bwCOBContainer.addChild(bwCOBLabelContainer);
			
			bwCOBCheck = LayoutFactory.createCheckMark(false);
			bwCOBCheck.addEventListener(Event.CHANGE, performCalculations);
			bwCOBLabelContainer.addChild(bwCOBCheck);
			
			bwCOBLabel = LayoutFactory.createLabel("");
			bwCOBLabelContainer.addChild(bwCOBLabel);
			
			bwCurrentCOBLabel = LayoutFactory.createLabel("");
			bwCOBContainer.addChild(bwCurrentCOBLabel);
			
			//Notes
			bwNotes = LayoutFactory.createTextInput(false, false, contentWidth, HorizontalAlign.CENTER, false, false, false, true, true);
			bwNotes.prompt = ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_note');
			bwNotes.maxChars = 50;
			bwMainContainer.addChild(bwNotes);
			
			//Wizard Suggestion
			bwSuggestionLabel = LayoutFactory.createLabel("", HorizontalAlign.CENTER, VerticalAlign.TOP, 14, true, 0xFF0000);
			bwSuggestionLabel.wordWrap = true;
			bwSuggestionLabel.paddingTop = bwSuggestionLabel.paddingBottom = 10;
			bwSuggestionLabel.width = contentWidth;
			bwMainContainer.addChild(bwSuggestionLabel);
			
			//Action Buttons
			var bolusWizardActionLayout:HorizontalLayout = new HorizontalLayout();
			bolusWizardActionLayout.horizontalAlign = HorizontalAlign.CENTER;
			bolusWizardActionLayout.gap = 5;
			
			bolusWizardActionContainer = new LayoutGroup();
			bolusWizardActionContainer.width = contentWidth;
			bolusWizardActionContainer.layout = bolusWizardActionLayout;
			bwMainContainer.addChild(bolusWizardActionContainer);
			
			bolusWizardCancelButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('globaltranslations','cancel_button_label').toUpperCase());
			bolusWizardCancelButton.addEventListener(Event.TRIGGERED, closeCallout);
			bolusWizardActionContainer.addChild(bolusWizardCancelButton);
			
			bolusWizardAddButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('globaltranslations','add_button_label').toUpperCase());
			bolusWizardAddButton.addEventListener(Event.TRIGGERED, addBolusWizardTreatment);
			bolusWizardActionContainer.addChild(bolusWizardAddButton);
			
			bwMainContainer.addChild(bolusWizardActionContainer);
			
			//Dinal Adjustments
			bwScrollContainer.addChild(bwMainContainer);
		}
		
		private static function populateComponents():void
		{
			bwTitle.text = "Bolus Wizard";
			
			bwGlucoseLabel.text = "Blood Glucose";
			bwGlucoseCheck.isSelected = true;
			bwGlucoseStepper.minimum = 0;
			bwGlucoseStepper.maximum = 400;
			currentBG = Math.round((ModelLocator.bgReadings[ModelLocator.bgReadings.length - 1] as BgReading).calculatedValue);
			bwGlucoseStepper.value = currentBG;
			bwGlucoseStepper.step = 1;
			bwCurrentGlucoseContainer.validate();
			bwGlucoseStepper.x = contentWidth - bwGlucoseStepper.width + 12;
			
			bwCarbsCheck.isSelected = true;
			bwCarbsLabel.text = "Carbs";
			bwCarbsStepper.value = 0;
			bwCarbsContainer.validate();
			bwCarbsStepper.x = contentWidth - bwCarbsStepper.width + 12;
			bwCarbsOffsetLabel.text = "Carbs Offset (Min)";
			bwCarbsOffsetStepper.value = 0;
			bwCarbsOffsetContainer.validate();
			bwCarbsOffsetStepper.x = contentWidth - bwCarbsOffsetStepper.width + 12;
			bwCarbTypeLabel.text = "Carb Type";
			
			var defaultCarbType:String = ProfileManager.getDefaultTimeAbsortionCarbType();
			if (defaultCarbType == "fast")
				bwCarbTypePicker.selectedIndex = 0;
			else if (defaultCarbType == "medium")
				bwCarbTypePicker.selectedIndex = 1;
			else if (defaultCarbType == "slow")
				bwCarbTypePicker.selectedIndex = 2;
			else
				bwCarbTypePicker.selectedIndex = 2;
			
			bwCarbTypeContainer.validate();
			bwCarbTypePicker.x = contentWidth - bwCarbTypePicker.width + 1;
			
			bwOtherCorrectionLabel.text = "Extra Correction";
			bwOtherCorrectionStepper.value = 0;
			bwOtherCorrectionContainer.validate();
			bwOtherCorrectionStepper.x = contentWidth - bwOtherCorrectionStepper.width + 12;
			
			bwIOBCheck.isSelected = false;
			bwIOBLabel.text = "IOB";
			currentIOB = TreatmentsManager.getTotalIOB(new Date().valueOf());
			bwCurrentIOBLabel.text = GlucoseFactory.formatIOB(currentIOB);
			bwCurrentIOBLabel.validate();
			bwIOBContainer.validate();
			bwCurrentIOBLabel.x = contentWidth - bwCurrentIOBLabel.width;
			
			bwCOBCheck.isSelected = false;
			bwCOBLabel.text = "COB";
			currentCOB = TreatmentsManager.getTotalCOB(new Date().valueOf());
			bwCurrentCOBLabel.text = GlucoseFactory.formatCOB(currentCOB);
			bwCurrentCOBLabel.validate();
			bwCOBContainer.validate();
			bwCurrentCOBLabel.x = contentWidth - bwCurrentCOBLabel.width;
			
			bwSuggestionLabel.text = "";
			
			bwScrollContainer.verticalScrollPosition = 0;
		}
		
		private static function displayCallout():void
		{
			if (bolusWizardCallout != null) bolusWizardCallout.dispose();
			bolusWizardCallout = Callout.show(bwScrollContainer, calloutPositionHelper);
			bolusWizardCallout.disposeContent = false;
			bolusWizardCallout.paddingBottom = 15;
			bolusWizardCallout.closeOnTouchBeganOutside = false;
			bolusWizardCallout.closeOnTouchEndedOutside = false;
			bolusWizardCallout.height = Constants.stageHeight - yPos - 10;
			bolusWizardCallout.validate();
			bwScrollContainer.height = bolusWizardCallout.height - yPos - 35;
			bwScrollContainer.maxHeight = bolusWizardCallout.height - yPos - 35;
			bwScrollContainer.validate();
		}
		
		private static function displayMissedSettingsCallout():void
		{
			if (missedSettingsContainer != null) missedSettingsContainer.removeFromParent(true);
			missedSettingsContainer = LayoutFactory.createLayoutGroup("vertical", HorizontalAlign.CENTER, VerticalAlign.MIDDLE, 10);
			missedSettingsContainer.width = contentWidth;
			
			if (missedSettingsTitle != null) missedSettingsTitle.removeFromParent(true);
			missedSettingsTitle = LayoutFactory.createLabel("Bolus Wizard", HorizontalAlign.CENTER, VerticalAlign.TOP, 18, true);
			missedSettingsTitle.width = contentWidth;
			missedSettingsContainer.addChild(missedSettingsTitle);
			
			if (missedSettingsLabel != null) missedSettingsLabel.removeFromParent(true);
			missedSettingsLabel = LayoutFactory.createLabel("Profile not configured!", HorizontalAlign.CENTER);
			missedSettingsLabel.width = contentWidth;
			missedSettingsContainer.addChild(missedSettingsLabel);
			
			if (missedSettingsActionsContainer != null) missedSettingsActionsContainer.removeFromParent(true);
			missedSettingsActionsContainer = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.CENTER, VerticalAlign.MIDDLE, 5);
			missedSettingsActionsContainer.width = contentWidth;
			missedSettingsContainer.addChild(missedSettingsActionsContainer);
			
			missedSettingsCancelButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('globaltranslations','cancel_button_label').toUpperCase());
			missedSettingsCancelButton.addEventListener(Event.TRIGGERED, onCloseConfigureCallout);
			missedSettingsActionsContainer.addChild(missedSettingsCancelButton);
			
			missedSettingsConfigureButton = LayoutFactory.createButton("CONFIGURE");
			missedSettingsConfigureButton.addEventListener(Event.TRIGGERED, onPerformConfiguration);
			missedSettingsActionsContainer.addChild(missedSettingsConfigureButton);
			
			setCalloutPositionHelper();
			
			if (bolusWizardConfigureCallout != null) bolusWizardConfigureCallout.dispose();
			bolusWizardConfigureCallout = Callout.show(missedSettingsContainer, calloutPositionHelper);
			bolusWizardConfigureCallout.paddingBottom = 15;
			bolusWizardConfigureCallout.closeOnTouchBeganOutside = false;
			bolusWizardConfigureCallout.closeOnTouchEndedOutside = false;
		}
		
		private static function setCalloutPositionHelper():void
		{
			if (calloutPositionHelper != null) calloutPositionHelper.removeFromParent(true);
			calloutPositionHelper = new Sprite();
			
			if (!isNaN(Constants.headerHeight))
				yPos = Constants.headerHeight - 10;
			else
			{
				if (Constants.deviceModel != DeviceInfo.IPHONE_X)
					yPos = 68;
				else
					yPos = Constants.isPortrait ? 98 : 68;
			}
			
			calloutPositionHelper.y = yPos;
			calloutPositionHelper.x = Constants.stageWidth / 2;
			Starling.current.stage.addChild(calloutPositionHelper);
		}
		
		private static function roundTo (x:Number, step:Number):Number
		{
			if (x) return Math.round(x / step) * step;
			
			return 0;
		}
		
		/**
		 * Event Listeners
		 */
		private static function performCalculations(e:Event = null):void
		{
			trace("Bolus Wizard Calculations");
			
			//Validation
			if (currentProfile == null || currentProfile.insulinSensitivityFactors == "" || currentProfile.insulinToCarbRatios == "" || currentProfile.targetGlucoseRates == "")
			{
				//We don't have enough profile data. Abort!
				return;
			}
			
			var targetBGLow:Number = 70; //CHANGE ON FINAL
			var targetBGHigh:Number = 140; //CHANGE ON FINAL
			var isf:Number = Number(currentProfile.insulinSensitivityFactors);
			var ic:Number = Number(currentProfile.insulinToCarbRatios);
			var insulincob:Number = 0;
			var bg:Number = 0;
			var insulinbg:Number = 0;
			var bgdiff:Number = 0;
			var insulincarbs:Number = 0;
			var carbs:Number = 0;
			var extraCorrections:Number = bwOtherCorrectionStepper.value;
			var iob:Number = 0;
			var cob:Number = 0;
			
			// Load IOB;
			if (bwIOBCheck.isSelected) {
				iob = currentIOB;
			}
			
			// Load COB
			if (bwCOBCheck.isSelected) {
				cob = currentCOB;
				insulincob = roundTo(cob / ic, 0.01);
			}
			
			// Load BG
			if (bwGlucoseCheck.isSelected)
			{
				bg = bwGlucoseStepper.value;
				if (isNaN(bg))
				{
					bg = 0;
				}
				
				if (bg <= targetBGLow)
				{
					bgdiff = bg - targetBGLow;
				}
				else if (bg >= targetBGHigh)
				{
					bgdiff = bg - targetBGHigh;
				}
				
				bgdiff = roundTo(bgdiff, 0.1);
				
				if (bg !== 0){
					insulinbg = roundTo(bgdiff / isf, 0.01);
				}
			}
			
			// Load Carbs
			if (bwCarbsCheck.isSelected)
			{
				carbs = bwCarbsStepper.value;
				if (isNaN(carbs))
				{
					carbs = 0;
				}
				
				insulincarbs = roundTo(carbs / ic, 0.01);
			}
			
			//Total & rounding
			var total:Number = 0;
			if (bwIOBCheck.isEnabled) 
			{
				total = insulinbg + insulincarbs + insulincob - currentIOB + extraCorrections;
			}
			
			var insulin:Number = roundTo(total, 0.05);
			insulin = Math.round(insulin * 100) / 100;
			var roundingcorrection:Number = insulin - total;
			
			// Carbs needed if too much iob
			var carbsneeded:Number = 0;
			if (insulin < 0) 
			{
				carbsneeded = Math.ceil(-total * ic);
			}
			
			//Debug
			var record:Object = {};
			record.targetBGLow = targetBGLow;
			record.targetBGHigh = targetBGHigh;
			record.isf = isf;
			record.ic = ic;
			record.iob = iob;
			record.cob = cob;
			record.insulincob = insulincob;
			record.bg = bg;
			record.insulinbg = insulinbg;
			record.bgdiff = bgdiff;
			record.carbs = carbs;
			record.insulincarbs = insulincarbs;
			record.othercorrection = extraCorrections;
			record.insulin = insulin;
			record.roundingcorrection = roundingcorrection;
			record.carbsneeded = carbsneeded;
			
			trace("DEBUG:\n", ObjectUtil.toString(record));
			
			var outcome:Number = record.bg - record.iob * isf;
			
			if (record.othercorrection === 0 && record.carbs === 0 && record.cob === 0 && record.bg > 0 && outcome > targetBGLow && outcome < targetBGHigh) 
			{
				bwSuggestionLabel.text = "Projected outcome: " + outcome + "\n" + "Blood glucose within target.";
			}
			else if (record.insulin < 0) 
			{
				bwSuggestionLabel.text = "Projected outcome: " + outcome + "\n" + "Carbs needed: " + record.carbsneeded + "g" + "\n" + "Insulin equivalent: " + record.insulin + "U"; 
			}
			else
			{
				bwSuggestionLabel.text = "Projected outcome: " + outcome + "\n" + "Insulin needed: " + record.insulin + "U";
			}
		}
		
		private static function onCloseConfigureCallout(e:Event):void
		{
			if (bolusWizardConfigureCallout != null)
				bolusWizardConfigureCallout.close(true);
		}
		
		private static function onPerformConfiguration(e:Event):void
		{
			AppInterface.instance.navigator.pushScreen( Screens.SETTINGS_PROFILE );
			
			var popupTween:Tween=new Tween(bolusWizardConfigureCallout, 0.3, Transitions.LINEAR);
			popupTween.fadeTo(0);
			popupTween.onComplete = function():void
			{
				bolusWizardConfigureCallout.removeFromParent(true);
			}
			Starling.juggler.add(popupTween);
		}
		
		private static function delayCalculations(e:Event = null):void
		{
			clearTimeout(calculationTimeout);
			calculationTimeout = setTimeout(performCalculations, 100);
		}
		
		private static function repositonCarbTypePicker(e:Event):void
		{
			bwCarbTypePicker.validate();
			bwCarbTypeContainer.validate();
			bwCarbTypePicker.x = contentWidth - bwCarbTypePicker.width + 1;
		}
		
		private static function showHideCarbExtras(e:Event):void
		{
			if (!bwCarbsCheck.isSelected)
			{
				bwCarbsOffsetContainer.removeFromParent();
				bwCarbTypeContainer.removeFromParent()
			}
			else
			{
				bwMainContainer.addChildAt(bwCarbsOffsetContainer, 3);
				bwMainContainer.addChildAt(bwCarbTypeContainer, 4);
			}
			
			performCalculations();
		}
		
		private static function closeCallout(e:Event):void
		{
			if (bolusWizardCallout != null)
			{
				bolusWizardCallout.close(false);
				clearTimeout(calculationTimeout);
			}
		}
		
		private static function addBolusWizardTreatment(e:Event):void
		{
			
		}
	}
}