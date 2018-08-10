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
	import feathers.controls.ScrollBar;
	import feathers.controls.ScrollBarDisplayMode;
	import feathers.controls.ScrollContainer;
	import feathers.controls.ScrollPolicy;
	import feathers.controls.TextInput;
	import feathers.controls.popups.DropDownPopUpContentManager;
	import feathers.data.ArrayCollection;
	import feathers.layout.BaseLinearLayout;
	import feathers.layout.BaseTiledLayout;
	import feathers.layout.Direction;
	import feathers.layout.FlowLayout;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.HorizontalLayout;
	import feathers.layout.RelativePosition;
	import feathers.layout.TiledColumnsLayout;
	import feathers.layout.TiledRowsLayout;
	import feathers.layout.VerticalAlign;
	import feathers.layout.VerticalLayout;
	
	import model.ModelLocator;
	
	import starling.animation.Transitions;
	import starling.animation.Tween;
	import starling.core.Starling;
	import starling.display.Quad;
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
		/* Constants */
		private static const TIME_11_MINUTES:int = 11 * 60 * 1000;
		
		/* Properties */
		private static var initialStart:Boolean = true;
		private static var contentWidth:Number = 270;
		private static var yPos:Number = 0;
		private static var calculationTimeout:uint = 0;
		private static var currentIOB:Number = 0;
		private static var currentCOB:Number = 0;
		private static var currentBG:Number = 0;
		
		/* Objects */
		private static var currentProfile:Profile;
		private static var latestBgReading:BgReading;
		
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
		private static var bwOtherCorrectionAmountStepper:NumericStepper;
		private static var bwIOBLabelContainer:LayoutGroup;
		private static var bwIOBCheck:Check;
		private static var bwCOBLabelContainer:LayoutGroup;
		private static var bwCOBCheck:Check;
		private static var bwNotes:TextInput;
		private static var bwWizardScrollContainer:ScrollContainer;
		private static var bwSuggestionLabel:Label;
		private static var missedSettingsContainer:LayoutGroup;
		private static var missedSettingsTitle:Label;
		private static var missedSettingsLabel:Label;
		private static var missedSettingsActionsContainer:LayoutGroup;
		private static var missedSettingsCancelButton:Button;
		private static var missedSettingsConfigureButton:Button;
		private static var bolusWizardConfigureCallout:Callout;
		private static var bwSicknessContainer:LayoutGroup;
		private static var bwSicknessLabelContainer:LayoutGroup;
		private static var bwSicknessCheck:Check;
		private static var bwSicknessLabel:Label;
		private static var bwSicknessAmountStepper:NumericStepper;
		private static var bwSicknessAmountContainer:LayoutGroup;
		private static var bwSicknessAmountLabel:Label;
		private static var bwExerciseContainer:LayoutGroup;
		private static var bwExerciseLabelContainer:LayoutGroup;
		private static var bwExerciseCheck:Check;
		private static var bwExerciseLabel:Label;
		private static var bwExerciseSettingsContainer:LayoutGroup;
		private static var bwExerciseTimeLabel:Label;
		private static var bwExerciseTimeContainer:LayoutGroup;
		private static var bwExerciseTimePicker:PickerList;
		private static var bwExerciseIntensityContainer:LayoutGroup;
		private static var bwExerciseIntensityLabel:Label;
		private static var bwExerciseIntensityPicker:PickerList;
		private static var bwExerciseDurationContainer:LayoutGroup;
		private static var bwExerciseDurationLabel:Label;
		private static var bwExerciseDurationPicker:PickerList;
		private static var bwExerciseAmountLabel:Label;
		private static var bwExerciseAmountContainer:LayoutGroup;
		private static var bwExerciseAmountStepper:NumericStepper;
		private static var bwOtherCorrectionLabelContainer:LayoutGroup;
		private static var bwOtherCorrectionCheck:Check;
		private static var bwOtherCorrectionAmountContainer:LayoutGroup;
		private static var bwOtherCorrectionAmountLabel:Label;
		private static var bwTrendContainer:LayoutGroup;
		private static var bwTrendLabelContainer:LayoutGroup;
		private static var bwTrendCheck:Check;
		private static var bwTrendLabel:Label;
		private static var bwCurrentTrendLabel:Label;
		private static var bwFoodsContainer:LayoutGroup;

		private static var bwFoodsLabel:Label;

		private static var bwFoodLoaderButton:Button;

		private static var bwTotalScrollContainer:ScrollContainer;
		
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
			
			disableEventListeners();
			populateComponents();
			enableEventListeners();
			performCalculations();
			displayCallout();
		}		
		
		private static function createDisplayObjects():void
		{
			//Total Content Layout
			var bwTotalScrollLayout:TiledRowsLayout = new TiledRowsLayout();
			bwTotalScrollLayout.paging = Direction.HORIZONTAL;
			bwTotalScrollLayout.tileHorizontalAlign = HorizontalAlign.LEFT;
			bwTotalScrollLayout.tileVerticalAlign = VerticalAlign.TOP;
			bwTotalScrollLayout.horizontalAlign = HorizontalAlign.LEFT;
			bwTotalScrollLayout.verticalAlign = VerticalAlign.TOP;
			bwTotalScrollLayout.useSquareTiles = false;
			
			//Total Container
			bwTotalScrollContainer = new ScrollContainer();
			bwTotalScrollContainer.layout = bwTotalScrollLayout;
			bwTotalScrollContainer.horizontalScrollPolicy = ScrollPolicy.OFF;
			
			//Wizard Scroll Container
			var bwWizardScrollContainerLayout:VerticalLayout = new VerticalLayout();
			bwWizardScrollContainerLayout.paddingRight = 10;
			
			bwWizardScrollContainer = new ScrollContainer();
			bwWizardScrollContainer.layout = bwWizardScrollContainerLayout;
			bwWizardScrollContainer.scrollBarDisplayMode = ScrollBarDisplayMode.FIXED_FLOAT;
			bwWizardScrollContainer.verticalScrollBarProperties.paddingLeft = 10;
			bwTotalScrollContainer.addChild(bwWizardScrollContainer);
			
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
			bwGlucoseLabelContainer.addChild(bwGlucoseCheck);
			
			bwGlucoseLabel = LayoutFactory.createLabel("");
			bwGlucoseLabelContainer.addChild(bwGlucoseLabel);
			
			bwGlucoseStepper = LayoutFactory.createNumericStepper(0, 0, 0, 1);
			bwGlucoseStepper.validate();
			bwCurrentGlucoseContainer.addChild(bwGlucoseStepper);
			
			bwMainContainer.addChild(bwCurrentGlucoseContainer);
			
			//Carbs
			bwCarbsContainer = LayoutFactory.createLayoutGroup("horizontal");
			bwCarbsContainer.width = contentWidth;
			
			bwCarbsLabelContainer = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.LEFT, VerticalAlign.MIDDLE, 5);
			bwCarbsContainer.addChild(bwCarbsLabelContainer);
			
			bwCarbsCheck = LayoutFactory.createCheckMark(true);
			bwCarbsLabelContainer.addChild(bwCarbsCheck);
			
			bwCarbsLabel = LayoutFactory.createLabel("");
			bwCarbsLabelContainer.addChild(bwCarbsLabel);
			
			bwCarbsStepper = LayoutFactory.createNumericStepper(0, 500, 0, 0.5);
			bwCarbsStepper.validate();
			bwCarbsContainer.addChild(bwCarbsStepper);
			
			bwMainContainer.addChild(bwCarbsContainer);
			
			//Foods
			bwFoodsContainer = LayoutFactory.createLayoutGroup("horizontal");
			bwFoodsContainer.width = contentWidth;
			bwMainContainer.addChild(bwFoodsContainer);
			
			bwFoodsLabel = LayoutFactory.createLabel("");
			bwFoodsLabel.paddingLeft = 25;
			bwFoodsContainer.addChild(bwFoodsLabel);
			
			bwFoodLoaderButton = LayoutFactory.createButton("");
			bwFoodLoaderButton.addEventListener(Event.TRIGGERED, onShowFoodSearcher);
			bwFoodsContainer.addChild(bwFoodLoaderButton);
			
			//Carbs Offset
			bwCarbsOffsetContainer = LayoutFactory.createLayoutGroup("horizontal");
			bwCarbsOffsetContainer.width = contentWidth;
			bwMainContainer.addChild(bwCarbsOffsetContainer);
			
			bwCarbsOffsetLabel = LayoutFactory.createLabel("");
			bwCarbsOffsetLabel.paddingLeft = 25;
			bwCarbsOffsetContainer.addChild(bwCarbsOffsetLabel);
			
			bwCarbsOffsetStepper = LayoutFactory.createNumericStepper(-300, 300, 0, 5);
			bwCarbsOffsetStepper.validate();
			bwCarbsOffsetContainer.addChild(bwCarbsOffsetStepper);
			
			//Carb Type
			bwCarbTypeContainer = LayoutFactory.createLayoutGroup("horizontal");
			bwMainContainer.addChild(bwCarbTypeContainer);
			
			bwCarbTypeLabel = LayoutFactory.createLabel("");
			bwCarbTypeLabel.paddingLeft = 25;
			bwCarbTypeContainer.addChild(bwCarbTypeLabel);
			
			bwCarbTypePicker = LayoutFactory.createPickerList();
			bwCarbTypePicker.labelField = "label";
			bwCarbTypePicker.popUpContentManager = new DropDownPopUpContentManager();
			bwCarbTypePicker.addEventListener(Event.CHANGE, onCarbTypeChanged);
			
			bwCarbTypeContainer.addChild(bwCarbTypePicker);
			bwCarbTypePicker.validate();
			
			//Trend
			bwTrendContainer = LayoutFactory.createLayoutGroup("horizontal");
			bwTrendContainer.width = contentWidth;
			bwMainContainer.addChild(bwTrendContainer);
			
			bwTrendLabelContainer = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.LEFT, VerticalAlign.MIDDLE, 5);
			bwTrendContainer.addChild(bwTrendLabelContainer);
			
			bwTrendCheck = LayoutFactory.createCheckMark(true);
			bwTrendContainer.addChild(bwTrendCheck);
			
			bwTrendLabel = LayoutFactory.createLabel("");
			bwTrendContainer.addChild(bwTrendLabel);
			
			bwCurrentTrendLabel = LayoutFactory.createLabel("");
			bwTrendContainer.addChild(bwCurrentTrendLabel);
			
			//Current IOB
			bwIOBContainer = LayoutFactory.createLayoutGroup("horizontal");
			bwIOBContainer.width = contentWidth;
			bwMainContainer.addChild(bwIOBContainer);
			
			bwIOBLabelContainer = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.LEFT, VerticalAlign.MIDDLE, 5);
			bwIOBContainer.addChild(bwIOBLabelContainer);
			
			bwIOBCheck = LayoutFactory.createCheckMark(false);
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
			bwCOBLabelContainer.addChild(bwCOBCheck);
			
			bwCOBLabel = LayoutFactory.createLabel("");
			bwCOBLabelContainer.addChild(bwCOBLabel);
			
			bwCurrentCOBLabel = LayoutFactory.createLabel("");
			bwCOBContainer.addChild(bwCurrentCOBLabel);
			
			//Exercise Adjustment
			bwExerciseContainer = LayoutFactory.createLayoutGroup("vertical");
			bwExerciseContainer.width = contentWidth;
			bwMainContainer.addChild(bwExerciseContainer);
			
			bwExerciseLabelContainer = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.LEFT, VerticalAlign.MIDDLE, 5);
			bwExerciseContainer.addChild(bwExerciseLabelContainer);
			
			bwExerciseCheck = LayoutFactory.createCheckMark(false);
			bwExerciseLabelContainer.addChild(bwExerciseCheck);
			
			bwExerciseLabel = LayoutFactory.createLabel("");
			bwExerciseLabelContainer.addChild(bwExerciseLabel);
			
			bwExerciseSettingsContainer = LayoutFactory.createLayoutGroup("vertical", HorizontalAlign.LEFT, VerticalAlign.MIDDLE, 5);
			bwExerciseSettingsContainer.width = contentWidth;
			
			bwExerciseTimeContainer = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.LEFT, VerticalAlign.MIDDLE, 5);
			bwExerciseTimeContainer.width = contentWidth;
			bwExerciseSettingsContainer.addChild(bwExerciseTimeContainer);
			
			bwExerciseTimeLabel = LayoutFactory.createLabel("");
			bwExerciseTimeLabel.paddingLeft = 25;
			bwExerciseTimeContainer.addChild(bwExerciseTimeLabel);
			
			bwExerciseTimePicker = LayoutFactory.createPickerList();
			bwExerciseTimePicker.labelField = "label";
			bwExerciseTimePicker.popUpContentManager = new DropDownPopUpContentManager();
			bwExerciseTimeContainer.addChild(bwExerciseTimePicker);
			bwExerciseTimePicker.validate();
			
			bwExerciseIntensityContainer = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.LEFT, VerticalAlign.MIDDLE, 5);
			bwExerciseIntensityContainer.width = contentWidth;
			bwExerciseSettingsContainer.addChild(bwExerciseIntensityContainer);
			
			bwExerciseIntensityLabel = LayoutFactory.createLabel("");
			bwExerciseIntensityLabel.paddingLeft = 25;
			bwExerciseIntensityContainer.addChild(bwExerciseIntensityLabel);
			
			bwExerciseIntensityPicker = LayoutFactory.createPickerList();
			bwExerciseIntensityPicker.labelField = "label";
			bwExerciseIntensityPicker.popUpContentManager = new DropDownPopUpContentManager();
			bwExerciseIntensityContainer.addChild(bwExerciseIntensityPicker);
			
			bwExerciseDurationContainer = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.LEFT, VerticalAlign.MIDDLE, 5);
			bwExerciseDurationContainer.width = contentWidth;
			bwExerciseSettingsContainer.addChild(bwExerciseDurationContainer);
			
			bwExerciseDurationLabel = LayoutFactory.createLabel("");
			bwExerciseDurationLabel.paddingLeft = 25;
			bwExerciseDurationContainer.addChild(bwExerciseDurationLabel);
			
			bwExerciseDurationPicker = LayoutFactory.createPickerList();
			bwExerciseDurationPicker.labelField = "label";
			var bwExerciseDurationPopup:DropDownPopUpContentManager = new DropDownPopUpContentManager();
			bwExerciseDurationPopup.primaryDirection = RelativePosition.TOP;
			bwExerciseDurationPicker.popUpContentManager = bwExerciseDurationPopup;
			bwExerciseDurationContainer.addChild(bwExerciseDurationPicker);
			
			bwExerciseAmountContainer = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.LEFT, VerticalAlign.MIDDLE, 5);
			bwExerciseAmountContainer.width = contentWidth;
			bwExerciseSettingsContainer.addChild(bwExerciseAmountContainer);
			
			bwExerciseAmountLabel = LayoutFactory.createLabel("");
			bwExerciseAmountLabel.paddingLeft = 25;
			bwExerciseAmountContainer.addChild(bwExerciseAmountLabel);
			
			bwExerciseAmountStepper = LayoutFactory.createNumericStepper(0, 100, 0, 1);
			bwExerciseAmountStepper.validate();
			bwExerciseAmountContainer.addChild(bwExerciseAmountStepper);
			
			//Sickness Adjustment
			bwSicknessContainer = LayoutFactory.createLayoutGroup("vertical");
			bwSicknessContainer.width = contentWidth;
			bwMainContainer.addChild(bwSicknessContainer);
			
			bwSicknessLabelContainer = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.LEFT, VerticalAlign.MIDDLE, 5);
			bwSicknessContainer.addChild(bwSicknessLabelContainer);
			
			bwSicknessCheck = LayoutFactory.createCheckMark(false);
			bwSicknessLabelContainer.addChild(bwSicknessCheck);
			
			bwSicknessLabel = LayoutFactory.createLabel("");
			bwSicknessLabelContainer.addChild(bwSicknessLabel);
			
			bwSicknessAmountContainer = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.LEFT, VerticalAlign.MIDDLE, 5);
			bwSicknessAmountContainer.width = contentWidth;
			
			bwSicknessAmountLabel = LayoutFactory.createLabel("");
			bwSicknessAmountLabel.paddingLeft = 25;
			bwSicknessAmountContainer.addChild(bwSicknessAmountLabel);
			
			bwSicknessAmountStepper = LayoutFactory.createNumericStepper(0, 100, 0, 1);
			bwSicknessAmountStepper.validate();
			bwSicknessAmountContainer.addChild(bwSicknessAmountStepper);
			
			//Other Correction
			bwOtherCorrectionContainer = LayoutFactory.createLayoutGroup("vertical");
			bwOtherCorrectionContainer.width = contentWidth;
			bwMainContainer.addChild(bwOtherCorrectionContainer);
			
			bwOtherCorrectionLabelContainer = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.LEFT, VerticalAlign.MIDDLE, 5);
			bwOtherCorrectionContainer.addChild(bwOtherCorrectionLabelContainer);
			
			bwOtherCorrectionCheck = LayoutFactory.createCheckMark(false);
			bwOtherCorrectionLabelContainer.addChild(bwOtherCorrectionCheck);
			
			bwOtherCorrectionLabel = LayoutFactory.createLabel("");
			bwOtherCorrectionLabelContainer.addChild(bwOtherCorrectionLabel);
			
			bwOtherCorrectionAmountContainer = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.LEFT, VerticalAlign.MIDDLE, 5);
			bwOtherCorrectionAmountContainer.width = contentWidth;
			
			bwOtherCorrectionAmountLabel = LayoutFactory.createLabel("");
			bwOtherCorrectionAmountLabel.paddingLeft = 25;
			bwOtherCorrectionAmountContainer.addChild(bwOtherCorrectionAmountLabel);
			
			bwOtherCorrectionAmountStepper = LayoutFactory.createNumericStepper(0, 100, 0, 0.05);
			bwOtherCorrectionAmountStepper.validate();
			bwOtherCorrectionAmountContainer.addChild(bwOtherCorrectionAmountStepper);
			
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
			bolusWizardActionContainer.addChild(bolusWizardCancelButton);
			
			bolusWizardAddButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('globaltranslations','add_button_label').toUpperCase());
			bolusWizardActionContainer.addChild(bolusWizardAddButton);
			
			bwMainContainer.addChild(bolusWizardActionContainer);
			
			//Final Adjustments
			bwWizardScrollContainer.addChild(bwMainContainer);
			
			//Food Searcher
			var quad:Quad = new Quad(200, 100, 0xFF0000);
			bwTotalScrollContainer.addChild(quad);
		}
		
		private static function populateComponents():void
		{
			//Title
			bwTitle.text = "Bolus Wizard";
			
			//Current Glucose
			bwGlucoseLabel.text = "Blood Glucose";
			bwGlucoseCheck.isSelected = true;
			bwGlucoseStepper.minimum = 0;
			bwGlucoseStepper.maximum = 400;
			latestBgReading = BgReading.lastWithCalculatedValue();
			if (latestBgReading != null && new Date().valueOf() - latestBgReading.timestamp <= TIME_11_MINUTES) //Only use BG readings less than 11 minutes ago.
			{
				currentBG = Math.round(latestBgReading.calculatedValue);
			}
			else
			{
				bwGlucoseCheck.isSelected = false
				currentBG = 0;
			}
			
			bwGlucoseStepper.value = currentBG;
			bwGlucoseStepper.step = 1;
			bwCurrentGlucoseContainer.validate();
			bwGlucoseStepper.x = contentWidth - bwGlucoseStepper.width + 12;
			
			//Carbs
			bwCarbsCheck.isSelected = true;
			bwCarbsLabel.text = "Carbs";
			bwCarbsStepper.value = 0;
			bwCarbsContainer.validate();
			bwCarbsStepper.x = contentWidth - bwCarbsStepper.width + 12;
			bwFoodsLabel.text = "Foods";
			bwFoodLoaderButton.label = "Load Foods";
			bwFoodLoaderButton.validate();
			bwFoodsContainer.validate();
			bwFoodLoaderButton.x = contentWidth - bwFoodLoaderButton.width;
			bwCarbsOffsetLabel.text = "Carbs Offset (Min)";
			bwCarbsOffsetStepper.value = 0;
			bwCarbsOffsetContainer.validate();
			bwCarbsOffsetStepper.x = contentWidth - bwCarbsOffsetStepper.width + 12;
			bwCarbTypeLabel.text = "Carb Type";
			bwCarbTypePicker.dataProvider = new ArrayCollection
			(
				[
					ModelLocator.resourceManagerInstance.getString('treatments','carbs_fast_label'),
					ModelLocator.resourceManagerInstance.getString('treatments','carbs_medium_label'),
					ModelLocator.resourceManagerInstance.getString('treatments','carbs_slow_label')
				]
			);
			
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
			
			//Current Trend
			var currentTrendArrow:String = latestBgReading != null ? latestBgReading.slopeArrow() : "";
			bwTrendCheck.isSelected = latestBgReading != null ? true : false;
			bwTrendLabel.text = "Trend" + " " + currentTrendArrow;
			var currentTrendCorrection:Number = 0;
			var currentTrendCorrectionUnit:String = "U";
			if (currentTrendArrow != "")
			{
				if (currentTrendArrow == "\u2197")
				{
					currentTrendCorrection = currentProfile.trend45Up;
					currentTrendCorrectionUnit = "U";
				}
				else if (currentTrendArrow == "\u2191")
				{
					currentTrendCorrection = currentProfile.trend90Up;
					currentTrendCorrectionUnit = "U";
				}
				else if (currentTrendArrow == "\u2191\u2191")
				{
					currentTrendCorrection = currentProfile.trendDoubleUp;
					currentTrendCorrectionUnit = "U";
				}
				else if (currentTrendArrow == "\u2198")
				{
					currentTrendCorrection = currentProfile.trend45Down;
					currentTrendCorrectionUnit = "g";
				}
				else if (currentTrendArrow == "\u2193")
				{
					currentTrendCorrection = currentProfile.trend90Down;
					currentTrendCorrectionUnit = "g";
				}
				else if (currentTrendArrow == "\u2193\u2193")
				{
					currentTrendCorrection = currentProfile.trendDoubleDown;
					currentTrendCorrectionUnit = "g";
				}
			}
			
			if (currentTrendCorrection == 0) bwTrendCheck.isSelected = false;
			bwCurrentTrendLabel.text = currentTrendCorrection + currentTrendCorrectionUnit;
			bwCurrentTrendLabel.validate();
			bwTrendContainer.validate();
			bwCurrentTrendLabel.x = contentWidth - bwCurrentTrendLabel.width;
			bwTrendLabel.x = bwTrendCheck.x + bwTrendCheck.width + 5;
			
			//Current IOB
			bwIOBCheck.isSelected = false;
			bwIOBLabel.text = "IOB";
			currentIOB = TreatmentsManager.getTotalIOB(new Date().valueOf());
			bwCurrentIOBLabel.text = GlucoseFactory.formatIOB(currentIOB);
			bwCurrentIOBLabel.validate();
			bwIOBContainer.validate();
			bwCurrentIOBLabel.x = contentWidth - bwCurrentIOBLabel.width;
			
			//Current COB
			bwCOBCheck.isSelected = false;
			bwCOBLabel.text = "COB";
			currentCOB = TreatmentsManager.getTotalCOB(new Date().valueOf());
			bwCurrentCOBLabel.text = GlucoseFactory.formatCOB(currentCOB);
			bwCurrentCOBLabel.validate();
			bwCOBContainer.validate();
			bwCurrentCOBLabel.x = contentWidth - bwCurrentCOBLabel.width;
			
			//Exercise Adjustment
			bwExerciseCheck.isSelected = false;
			bwExerciseLabel.text = "Exercise Adjustment";
			
			//Time
			bwExerciseTimeLabel.text = "Time";
			bwExerciseTimePicker.dataProvider = new ArrayCollection
			(
				[
					{ label: "Before Exercise" },	
					{ label: "After Exercise" }	
				]
			);
			bwExerciseTimePicker.selectedIndex = 0;
			bwExerciseTimePicker.validate();
			bwExerciseTimePicker.x = contentWidth - bwExerciseTimePicker.width;
			
			//Intensity
			bwExerciseIntensityLabel.text = "Intensity";
			bwExerciseIntensityPicker.dataProvider = new ArrayCollection
			(
				[
					{ label: "Low" },	
					{ label: "Moderate" },	
					{ label: "High" }	
				]
			);
			bwExerciseIntensityPicker.selectedIndex = 0;
			bwExerciseIntensityPicker.validate();
			bwExerciseIntensityPicker.x = contentWidth - bwExerciseIntensityPicker.width;
			
			//Duration
			bwExerciseDurationLabel.text = "Duration";
			bwExerciseDurationPicker.dataProvider = new ArrayCollection
			(
				[
					{ label: "15 min" },	
					{ label: "30 min" },	
					{ label: "45 min" },	
					{ label: "60 min" },	
					{ label: "90 min" },	
					{ label: "120 min" },	
					{ label: "180 min" }	
				]
			);
			bwExerciseDurationPicker.selectedIndex = 0;
			bwExerciseDurationPicker.validate();
			bwExerciseDurationPicker.x = contentWidth - bwExerciseDurationPicker.width;
			
			//bwSicknessContainer.validate();
			//Amount
			bwExerciseAmountLabel.text = "Reduction (%)";
			bwExerciseAmountStepper.x = contentWidth - bwExerciseAmountStepper.width + 12;
			
			//Sickness Adjustment
			bwSicknessLabel.text = "Sickness Adjustment";
			bwSicknessAmountLabel.text = "Increase (%)";
			bwSicknessCheck.isSelected = false;
			bwSicknessAmountStepper.value = 0;
			bwSicknessContainer.validate();
			bwSicknessAmountStepper.x = contentWidth - bwSicknessAmountStepper.width + 12;
			
			//Other Correction
			bwOtherCorrectionLabel.text = "Extra Correction";
			bwOtherCorrectionAmountLabel.text = "Amount (U)";
			bwOtherCorrectionCheck.isSelected = false;
			bwOtherCorrectionAmountStepper.value = 0;
			bwOtherCorrectionContainer.validate();
			bwOtherCorrectionAmountStepper.x = contentWidth - bwOtherCorrectionAmountStepper.width + 12;
			
			bwSuggestionLabel.text = "";
			
			//Components Show/Hide
			showHideCarbExtras();
			showHideExerciseAdjustment();
			showHideSicknessAdjustment();
			showHideOtherCorrection();
			
			//Reset Callout Vertical Scroll
			bwWizardScrollContainer.verticalScrollPosition = 0;
		}
		
		private static function enableEventListeners():void
		{
			bwGlucoseCheck.addEventListener(Event.CHANGE, performCalculations);
			bwGlucoseStepper.addEventListener(Event.CHANGE, delayCalculations);
			bwCarbsCheck.addEventListener(Event.CHANGE, showHideCarbExtras);
			bwCarbsStepper.addEventListener(Event.CHANGE, delayCalculations);
			bwExerciseCheck.addEventListener(Event.CHANGE, showHideExerciseAdjustment);
			bwExerciseTimePicker.addEventListener(Event.CHANGE, onExerciseTimeChanged);
			bwExerciseIntensityPicker.addEventListener(Event.CHANGE, onExerciseIntensityChanged);
			bwExerciseDurationPicker.addEventListener(Event.CHANGE, onExerciseDurationChanged);
			bwExerciseAmountStepper.addEventListener(Event.CHANGE, delayCalculations);
			bwSicknessCheck.addEventListener(Event.CHANGE, showHideSicknessAdjustment);
			bwSicknessAmountStepper.addEventListener(Event.CHANGE, delayCalculations);
			bwOtherCorrectionCheck.addEventListener(Event.CHANGE, showHideOtherCorrection);
			bwOtherCorrectionAmountStepper.addEventListener(Event.CHANGE, delayCalculations);
			bwIOBCheck.addEventListener(Event.CHANGE, performCalculations);
			bwCOBCheck.addEventListener(Event.CHANGE, performCalculations);
			bolusWizardCancelButton.addEventListener(Event.TRIGGERED, closeCallout);
			bolusWizardAddButton.addEventListener(Event.TRIGGERED, addBolusWizardTreatment);
			
		}
		
		private static function disableEventListeners():void
		{
			bwGlucoseCheck.removeEventListener(Event.CHANGE, performCalculations);
			bwGlucoseStepper.removeEventListener(Event.CHANGE, delayCalculations);
			bwCarbsCheck.removeEventListener(Event.CHANGE, showHideCarbExtras);
			bwCarbsStepper.removeEventListener(Event.CHANGE, delayCalculations);
			bwExerciseCheck.removeEventListener(Event.CHANGE, showHideExerciseAdjustment);
			bwExerciseTimePicker.removeEventListener(Event.CHANGE, onExerciseTimeChanged);
			bwExerciseIntensityPicker.removeEventListener(Event.CHANGE, onExerciseIntensityChanged);
			bwExerciseDurationPicker.removeEventListener(Event.CHANGE, onExerciseDurationChanged);
			bwExerciseAmountStepper.removeEventListener(Event.CHANGE, delayCalculations);
			bwSicknessCheck.removeEventListener(Event.CHANGE, showHideSicknessAdjustment);
			bwSicknessAmountStepper.removeEventListener(Event.CHANGE, delayCalculations);
			bwOtherCorrectionCheck.removeEventListener(Event.CHANGE, showHideOtherCorrection);
			bwOtherCorrectionAmountStepper.removeEventListener(Event.CHANGE, delayCalculations);
			bwIOBCheck.removeEventListener(Event.CHANGE, performCalculations);
			bwCOBCheck.removeEventListener(Event.CHANGE, performCalculations);
			bolusWizardCancelButton.removeEventListener(Event.TRIGGERED, closeCallout);
			bolusWizardAddButton.removeEventListener(Event.TRIGGERED, addBolusWizardTreatment);
		}
		
		private static function displayCallout():void
		{
			if (bolusWizardCallout != null) bolusWizardCallout.dispose();
			bolusWizardCallout = Callout.show(bwTotalScrollContainer, calloutPositionHelper);
			bolusWizardCallout.disposeContent = false;
			bolusWizardCallout.paddingBottom = 15;
			bolusWizardCallout.closeOnTouchBeganOutside = false;
			bolusWizardCallout.closeOnTouchEndedOutside = false;
			bolusWizardCallout.height = Constants.stageHeight - yPos - 10;
			bolusWizardCallout.validate();
			bwWizardScrollContainer.height = bolusWizardCallout.height - yPos + 10;
			bwWizardScrollContainer.maxHeight = bolusWizardCallout.height - yPos + 10;
			bwWizardScrollContainer.validate();
			bwTotalScrollContainer.height = bwWizardScrollContainer.height;
			bwTotalScrollContainer.maxHeight = bwWizardScrollContainer.maxHeight;
			bwTotalScrollContainer.validate();
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
			//Validation
			if (currentProfile == null || currentProfile.insulinSensitivityFactors == "" || currentProfile.insulinToCarbRatios == "" || currentProfile.targetGlucoseRates == "")
			{
				//We don't have enough profile data. Show missed profile data callout and abort!
				closeCallout(null);
				displayMissedSettingsCallout();
				
				return;
			}
			
			//var targetBGLow:Number = 70; //CHANGE ON FINAL
			//var targetBGHigh:Number = 140; //CHANGE ON FINAL
			
			var targetBGLow:Number = Number(currentProfile.targetGlucoseRates) - 10;
			var targetBGHigh:Number = Number(currentProfile.targetGlucoseRates) + 10;
			
			var isf:Number = Number(currentProfile.insulinSensitivityFactors);
			var ic:Number = Number(currentProfile.insulinToCarbRatios);
			var insulincob:Number = 0;
			var bg:Number = 0;
			var insulinbg:Number = 0;
			var bgdiff:Number = 0;
			var insulincarbs:Number = 0;
			var carbs:Number = 0;
			var extraCorrections:Number = bwOtherCorrectionAmountStepper.value;
			var iob:Number = 0;
			var cob:Number = 0;
			var carbsneeded:Number = 0;
			var total:Number = 0;
			var insulin:Number = 0;
			var roundingcorrection:Number = 0;
			
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
				
				if (bg !== 0)
				{
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
			if (bwIOBCheck.isEnabled) 
			{
				total = insulinbg + insulincarbs + insulincob - currentIOB + extraCorrections;
			}
			
			insulin = roundTo(total, 0.05);
			insulin = Math.round(insulin * 100) / 100;
			roundingcorrection = insulin - total;
			
			// Carbs needed if too much IOB
			if (insulin < 0) 
			{
				carbsneeded = Math.ceil(-total * ic);
			}
			
			var preAdjustmentInsulin:Number = insulin;
			
			//Exercise Adjustment
			if (insulin > 0 && bwExerciseCheck.isSelected)
			{
				preAdjustmentInsulin -= insulin * (bwExerciseAmountStepper.value / 100);
				preAdjustmentInsulin = roundTo(preAdjustmentInsulin, 0.05);
				preAdjustmentInsulin = Math.round(preAdjustmentInsulin * 100) / 100;
			}
			
			// Sickness Adjustment
			if (insulin > 0 && bwSicknessCheck.isSelected)
			{
				preAdjustmentInsulin += insulin * (bwSicknessAmountStepper.value / 100);
				preAdjustmentInsulin = roundTo(preAdjustmentInsulin, 0.05);
				preAdjustmentInsulin = Math.round(preAdjustmentInsulin * 100) / 100;
			}
			
			insulin = preAdjustmentInsulin;
			
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
				bwSuggestionLabel.text = "Projected outcome: " + outcome + "\n" + "Blood glucose in target (" + currentProfile.targetGlucoseRates + ") or within 10mg/dL difference.";
			}
			else if (record.insulin < 0) 
			{
				bwSuggestionLabel.text = "Carbs needed: " + record.carbsneeded + "g" + "\n" + "Insulin equivalent: " + record.insulin + "U"; 
			}
			else
			{
				bwSuggestionLabel.text = "Insulin needed: " + record.insulin + "U";
			}
		}
		
		private static function onShowFoodSearcher(e:Event):void
		{
			if (bwWizardScrollContainer != null)
			{
				bwTotalScrollContainer.scrollToPageIndex( 1, bwTotalScrollContainer.verticalPageIndex );
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
		
		private static function onCarbTypeChanged(e:Event):void
		{
			bwCarbTypePicker.validate();
			bwCarbTypeContainer.validate();
			bwCarbTypePicker.x = contentWidth - bwCarbTypePicker.width + 1;
		}
		
		private static function showHideCarbExtras(e:Event = null):void
		{
			if (!bwCarbsCheck.isSelected)
			{
				bwFoodsContainer.removeFromParent();
				bwCarbsOffsetContainer.removeFromParent();
				bwCarbTypeContainer.removeFromParent()
			}
			else
			{
				bwMainContainer.addChildAt(bwFoodsContainer, 3);
				bwMainContainer.addChildAt(bwCarbsOffsetContainer, 4);
				bwMainContainer.addChildAt(bwCarbTypeContainer, 5);
			}
			
			performCalculations();
		}
		
		private static function showHideExerciseAdjustment(e:Event = null):void
		{
			if (bwExerciseCheck.isSelected)
			{
				var childIndex:int = bwExerciseContainer.getChildIndex(bwExerciseLabelContainer);
				if (childIndex != -1)
				{
					bwExerciseContainer.addChildAt(bwExerciseSettingsContainer, childIndex + 1);
					bwExerciseSettingsContainer.validate();
					bwExerciseTimePicker.x = contentWidth - bwExerciseTimePicker.width;
					bwExerciseIntensityPicker.x = contentWidth - bwExerciseIntensityPicker.width;
					bwExerciseDurationPicker.x = contentWidth - bwExerciseDurationPicker.width;
					bwExerciseAmountStepper.x = contentWidth - bwExerciseAmountStepper.width + 12;
				}
			}
			else
				bwExerciseSettingsContainer.removeFromParent();
			
			performCalculations();
		}
		
		private static function calculateExerciseReduction():void
		{
			if (bwExerciseIntensityPicker.selectedIndex == 0 && bwExerciseDurationPicker.selectedIndex == 0)
			{
				bwExerciseAmountStepper.value = 0;
			}
			else if (bwExerciseIntensityPicker.selectedIndex == 0 && bwExerciseDurationPicker.selectedIndex == 1)
			{
				bwExerciseAmountStepper.value = 0;
			}
			else if (bwExerciseIntensityPicker.selectedIndex == 0 && bwExerciseDurationPicker.selectedIndex == 2)
			{
				if (bwExerciseTimePicker.selectedIndex == 0)
				{
					bwExerciseAmountStepper.value = 10;
				}
				else if (bwExerciseTimePicker.selectedIndex == 1)
				{
					bwExerciseAmountStepper.value = 0;
				}
			}
			else if (bwExerciseIntensityPicker.selectedIndex == 0 && bwExerciseDurationPicker.selectedIndex == 3)
			{
				if (bwExerciseTimePicker.selectedIndex == 0)
				{
					bwExerciseAmountStepper.value = 15;
				}
				else if (bwExerciseTimePicker.selectedIndex == 1)
				{
					bwExerciseAmountStepper.value = 0;
				}
			}
			else if (bwExerciseIntensityPicker.selectedIndex == 0 && bwExerciseDurationPicker.selectedIndex == 4)
			{
				if (bwExerciseTimePicker.selectedIndex == 0)
				{
					bwExerciseAmountStepper.value = 20;
				}
				else if (bwExerciseTimePicker.selectedIndex == 1)
				{
					bwExerciseAmountStepper.value = 7;
				}
			}
			else if (bwExerciseIntensityPicker.selectedIndex == 0 && bwExerciseDurationPicker.selectedIndex == 5)
			{
				if (bwExerciseTimePicker.selectedIndex == 0)
				{
					bwExerciseAmountStepper.value = 30;
				}
				else if (bwExerciseTimePicker.selectedIndex == 1)
				{
					bwExerciseAmountStepper.value = 10;
				}
			}
			else if (bwExerciseIntensityPicker.selectedIndex == 0 && bwExerciseDurationPicker.selectedIndex == 6)
			{
				if (bwExerciseTimePicker.selectedIndex == 0)
				{
					bwExerciseAmountStepper.value = 45;
				}
				else if (bwExerciseTimePicker.selectedIndex == 1)
				{
					bwExerciseAmountStepper.value = 15;
				}
			}
			else if (bwExerciseIntensityPicker.selectedIndex == 1 && bwExerciseDurationPicker.selectedIndex == 0)
			{
				if (bwExerciseTimePicker.selectedIndex == 0)
				{
					bwExerciseAmountStepper.value = 5;
				}
				else if (bwExerciseTimePicker.selectedIndex == 1)
				{
					bwExerciseAmountStepper.value = 0;
				}
			}
			else if (bwExerciseIntensityPicker.selectedIndex == 1 && bwExerciseDurationPicker.selectedIndex == 1)
			{
				if (bwExerciseTimePicker.selectedIndex == 0)
				{
					bwExerciseAmountStepper.value = 15;
				}
				else if (bwExerciseTimePicker.selectedIndex == 1)
				{
					bwExerciseAmountStepper.value = 10;
				}
			}
			else if (bwExerciseIntensityPicker.selectedIndex == 1 && bwExerciseDurationPicker.selectedIndex == 2)
			{
				if (bwExerciseTimePicker.selectedIndex == 0)
				{
					bwExerciseAmountStepper.value = 20;
				}
				else if (bwExerciseTimePicker.selectedIndex == 1)
				{
					bwExerciseAmountStepper.value = 15;
				}
			}
			else if (bwExerciseIntensityPicker.selectedIndex == 1 && bwExerciseDurationPicker.selectedIndex == 3)
			{
				if (bwExerciseTimePicker.selectedIndex == 0)
				{
					bwExerciseAmountStepper.value = 30;
				}
				else if (bwExerciseTimePicker.selectedIndex == 1)
				{
					bwExerciseAmountStepper.value = 20;
				}
			}
			else if (bwExerciseIntensityPicker.selectedIndex == 1 && bwExerciseDurationPicker.selectedIndex == 4)
			{
				if (bwExerciseTimePicker.selectedIndex == 0)
				{
					bwExerciseAmountStepper.value = 40;
				}
				else if (bwExerciseTimePicker.selectedIndex == 1)
				{
					bwExerciseAmountStepper.value = 25;
				}
			}
			else if (bwExerciseIntensityPicker.selectedIndex == 1 && bwExerciseDurationPicker.selectedIndex == 5)
			{
				if (bwExerciseTimePicker.selectedIndex == 0)
				{
					bwExerciseAmountStepper.value = 55;
				}
				else if (bwExerciseTimePicker.selectedIndex == 1)
				{
					bwExerciseAmountStepper.value = 25;
				}
			}
			else if (bwExerciseIntensityPicker.selectedIndex == 1 && bwExerciseDurationPicker.selectedIndex == 6)
			{
				if (bwExerciseTimePicker.selectedIndex == 0)
				{
					bwExerciseAmountStepper.value = 75;
				}
				else if (bwExerciseTimePicker.selectedIndex == 1)
				{
					bwExerciseAmountStepper.value = 30;
				}
			}
			else if (bwExerciseIntensityPicker.selectedIndex == 2 && bwExerciseDurationPicker.selectedIndex == 0)
			{
				if (bwExerciseTimePicker.selectedIndex == 0)
				{
					bwExerciseAmountStepper.value = 10;
				}
				else if (bwExerciseTimePicker.selectedIndex == 1)
				{
					bwExerciseAmountStepper.value = 0;
				}
			}
			else if (bwExerciseIntensityPicker.selectedIndex == 2 && bwExerciseDurationPicker.selectedIndex == 1)
			{
				if (bwExerciseTimePicker.selectedIndex == 0)
				{
					bwExerciseAmountStepper.value = 20;
				}
				else if (bwExerciseTimePicker.selectedIndex == 1)
				{
					bwExerciseAmountStepper.value = 20;
				}
			}
			else if (bwExerciseIntensityPicker.selectedIndex == 2 && bwExerciseDurationPicker.selectedIndex == 2)
			{
				if (bwExerciseTimePicker.selectedIndex == 0)
				{
					bwExerciseAmountStepper.value = 30;
				}
				else if (bwExerciseTimePicker.selectedIndex == 1)
				{
					bwExerciseAmountStepper.value = 30;
				}
			}
			else if (bwExerciseIntensityPicker.selectedIndex == 2 && bwExerciseDurationPicker.selectedIndex == 3)
			{
				if (bwExerciseTimePicker.selectedIndex == 0)
				{
					bwExerciseAmountStepper.value = 45;
				}
				else if (bwExerciseTimePicker.selectedIndex == 1)
				{
					bwExerciseAmountStepper.value = 40;
				}
			}
			else if (bwExerciseIntensityPicker.selectedIndex == 2 && bwExerciseDurationPicker.selectedIndex == 4)
			{
				if (bwExerciseTimePicker.selectedIndex == 0)
				{
					bwExerciseAmountStepper.value = 60;
				}
				else if (bwExerciseTimePicker.selectedIndex == 1)
				{
					bwExerciseAmountStepper.value = 45;
				}
			}
			else if (bwExerciseIntensityPicker.selectedIndex == 2 && bwExerciseDurationPicker.selectedIndex == 5)
			{
				if (bwExerciseTimePicker.selectedIndex == 0)
				{
					bwExerciseAmountStepper.value = 75;
				}
				else if (bwExerciseTimePicker.selectedIndex == 1)
				{
					bwExerciseAmountStepper.value = 50;
				}
			}
			else if (bwExerciseIntensityPicker.selectedIndex == 2 && bwExerciseDurationPicker.selectedIndex == 6)
			{
				if (bwExerciseTimePicker.selectedIndex == 0)
				{
					bwExerciseAmountStepper.value = 85;
				}
				else if (bwExerciseTimePicker.selectedIndex == 1)
				{
					bwExerciseAmountStepper.value = 60;
				}
			}
		}
		
		private static function onExerciseTimeChanged(e:Event):void
		{
			bwExerciseTimePicker.validate();
			bwExerciseTimeContainer.validate();
			bwExerciseTimePicker.x = contentWidth - bwExerciseTimePicker.width;
			
			calculateExerciseReduction();
			performCalculations();
		}
		
		private static function onExerciseIntensityChanged(e:Event):void
		{
			bwExerciseIntensityPicker.validate();
			bwExerciseIntensityContainer.validate();
			bwExerciseIntensityPicker.x = contentWidth - bwExerciseIntensityPicker.width;
			
			calculateExerciseReduction();
			performCalculations();
		}
		
		private static function onExerciseDurationChanged(e:Event):void
		{
			bwExerciseDurationPicker.validate();
			bwExerciseDurationContainer.validate();
			bwExerciseDurationPicker.x = contentWidth - bwExerciseDurationPicker.width;
			
			calculateExerciseReduction();
			performCalculations();
		}
		
		private static function showHideSicknessAdjustment(e:Event = null):void
		{
			if (bwSicknessCheck.isSelected)
			{
				var childIndex:int = bwSicknessContainer.getChildIndex(bwSicknessLabelContainer);
				if (childIndex != -1)
				{
					bwSicknessContainer.addChildAt(bwSicknessAmountContainer, childIndex + 1);
					bwSicknessAmountContainer.validate();
					bwSicknessAmountStepper.x = contentWidth - bwSicknessAmountStepper.width + 12;
				}
			}
			else
				bwSicknessAmountContainer.removeFromParent();
			
			performCalculations();
		}
		
		private static function showHideOtherCorrection(e:Event = null):void
		{
			if (bwOtherCorrectionCheck.isSelected)
			{
				var childIndex:int = bwOtherCorrectionContainer.getChildIndex(bwOtherCorrectionLabelContainer);
				if (childIndex != -1)
				{
					bwOtherCorrectionContainer.addChildAt(bwOtherCorrectionAmountContainer, childIndex + 1);
					bwOtherCorrectionAmountContainer.validate();
					bwOtherCorrectionAmountStepper.x = contentWidth - bwOtherCorrectionAmountStepper.width + 12;
				}
			}
			else
				bwOtherCorrectionAmountContainer.removeFromParent();
			
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