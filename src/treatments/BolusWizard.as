package treatments
{
	import com.adobe.utils.StringUtil;
	import com.distriqt.extension.notifications.Notifications;
	import com.distriqt.extension.notifications.builders.NotificationBuilder;
	import com.spikeapp.spike.airlibrary.SpikeANE;
	
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	import mx.utils.ObjectUtil;
	
	import database.BgReading;
	import database.CGMBlueToothDevice;
	import database.CommonSettings;
	import database.Database;
	import database.LocalSettings;
	
	import events.FollowerEvent;
	import events.TransmitterServiceEvent;
	import events.TreatmentsEvent;
	
	import feathers.controls.Button;
	import feathers.controls.Callout;
	import feathers.controls.Check;
	import feathers.controls.DateTimeSpinner;
	import feathers.controls.Label;
	import feathers.controls.LayoutGroup;
	import feathers.controls.NumericStepper;
	import feathers.controls.PickerList;
	import feathers.controls.ScrollBarDisplayMode;
	import feathers.controls.ScrollContainer;
	import feathers.controls.ScrollPolicy;
	import feathers.controls.TextInput;
	import feathers.controls.popups.DropDownPopUpContentManager;
	import feathers.controls.popups.VerticalCenteredPopUpContentManager;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.data.ArrayCollection;
	import feathers.layout.Direction;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.HorizontalLayout;
	import feathers.layout.RelativePosition;
	import feathers.layout.TiledRowsLayout;
	import feathers.layout.VerticalAlign;
	import feathers.layout.VerticalLayout;
	
	import model.ModelLocator;
	
	import services.NightscoutService;
	import services.NotificationService;
	import services.TransmitterService;
	
	import starling.animation.Transitions;
	import starling.animation.Tween;
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.events.Event;
	
	import treatments.food.Food;
	import treatments.food.ui.FoodManager;
	
	import ui.AppInterface;
	import ui.chart.GlucoseFactory;
	import ui.popups.AlertManager;
	import ui.screens.Screens;
	import ui.screens.display.LayoutFactory;
	import ui.screens.display.settings.alarms.AlertCustomizerList;
	
	import utils.Constants;
	import utils.DeviceInfo;
	import utils.GlucoseHelper;
	import utils.TimeSpan;
	import utils.Trace;

	public class BolusWizard
	{
		/* Constants */
		private static const TIME_11_MINUTES:int = 11 * 60 * 1000;
		
		/* Properties */
		private static var initialStart:Boolean = true;
		private static var canAddInsulin:Boolean = false;
		private static var bgIsWithinTarget:Boolean = false;
		private static var contentWidth:Number = 270;
		private static var yPos:Number = 0;
		private static var calculationTimeout:uint = 0;
		private static var currentIOB:Number = 0;
		private static var currentCOB:Number = 0;
		private static var currentBG:Number = 0;
		private static var suggestedCarbs:Number = 0;
		private static var suggestedInsulin:Number = 0;
		private static var currentTrendCorrection:Number;
		private static var currentTrendCorrectionUnit:String;
		private static var bwExtendedBolusSoundAccessoriesList:Array;
		private static var insulinPrecision:Number;
		private static var carbsPrecision:Number;
		private static var isMgDl:Boolean;
		
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
		private static var bwFoodManager:FoodManager;
		private static var bwInsulinTypeContainer:LayoutGroup;
		private static var bwInsulinTypeLabel:Label;
		private static var bwInsulinTypePicker:PickerList;
		private static var createInsulinButton:Button;
		private static var bwExtendedBolusReminderContainer:LayoutGroup;
		private static var bwExtendedBolusReminderLabelContainer:LayoutGroup;
		private static var bwExtendedBolusReminderCheck:Check;
		private static var bwExtendedBolusReminderLabel:Label;
		private static var bwExtendedBolusReminderDateTimeContainer:LayoutGroup;
		private static var bwExtendedBolusReminderDateTimeSpinner:DateTimeSpinner;
		private static var bwExtendedBolusSoundListContainer:LayoutGroup;
		private static var bwExtendedBolusSoundList:PickerList;
		private static var bwFinalCalculationsContainer:LayoutGroup;
		private static var bwFinalCalculatedInsulinContainer:LayoutGroup;
		private static var bwFinalCalculatedInsulinLabel:Label;
		private static var bwFinalCalculatedInsulinStepper:NumericStepper;
		private static var bwFinalCalculatedCarbsContainer:LayoutGroup;
		private static var bwFinalCalculatedCarbsLabel:Label;
		private static var bwFinalCalculatedCarbsStepper:NumericStepper;
		private static var finalCalculationsLabel:Label;
		
		public function BolusWizard()
		{
			throw new Error("BolusWizard is not meant to be instantiated!");
		}
		
		public static function display():void
		{
			contentWidth = Constants.isPortrait ? Constants.stageWidth - 50 : Constants.stageHeight - 50;
			
			currentProfile = ProfileManager.getProfileByTime(new Date().valueOf());
			
			if (currentProfile == null || currentProfile.insulinSensitivityFactors == "" || currentProfile.insulinToCarbRatios == "" || currentProfile.targetGlucoseRates == "")
			{
				displayMissedSettingsCallout();
				return;
			}
			
			//Components & Data
			getInitialSettings();
			createDisplayObjects();
			updateCriticalData();
			setCalloutPositionHelper();
			displayCallout();
			setGlobalEventListeners();
		}		
		
		private static function setGlobalEventListeners():void
		{
			TransmitterService.instance.addEventListener(TransmitterServiceEvent.LAST_BGREADING_RECEIVED, onBgReadingReceivedMaster);
			NightscoutService.instance.addEventListener(FollowerEvent.BG_READING_RECEIVED, onBgReadingReceivedFollower);
		}
		
		private static function getInitialSettings():void
		{
			isMgDl = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true";
			insulinPrecision = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BOLUS_WIZARD_INSULIN_PRECISION));
			carbsPrecision = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BOLUS_WIZARD_CARBS_PRECISION));
		}
		
		private static function createDisplayObjects():void
		{
			//Variables
			var i:int;
			
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
			bwTotalScrollContainer.snapToPages = true;
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
			bwTitle = LayoutFactory.createLabel("Bolus Wizard", HorizontalAlign.CENTER, VerticalAlign.TOP, 18, true);
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
			
			bwGlucoseLabel = LayoutFactory.createLabel("Blood Glucose");
			bwGlucoseLabelContainer.addChild(bwGlucoseLabel);
			
			bwGlucoseStepper = LayoutFactory.createNumericStepper(isMgDl ? 40 : Math.round(BgReading.mgdlToMmol(40) * 10) / 10, isMgDl ? 400 : Math.round(BgReading.mgdlToMmol(400) * 10) / 10, 0, isMgDl ? 1 : 0.1);
			bwGlucoseStepper.addEventListener(Event.CHANGE, delayCalculations);
			bwGlucoseStepper.validate();
			bwCurrentGlucoseContainer.addChild(bwGlucoseStepper);
			
			bwCurrentGlucoseContainer.validate();
			bwGlucoseStepper.x = contentWidth - bwGlucoseStepper.width + 12;
			
			bwMainContainer.addChild(bwCurrentGlucoseContainer);
			
			//Carbs
			bwCarbsContainer = LayoutFactory.createLayoutGroup("horizontal");
			bwCarbsContainer.width = contentWidth;
			
			bwCarbsLabelContainer = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.LEFT, VerticalAlign.MIDDLE, 5);
			bwCarbsContainer.addChild(bwCarbsLabelContainer);
			
			bwCarbsCheck = LayoutFactory.createCheckMark(true);
			bwCarbsCheck.addEventListener(Event.CHANGE, onShowHideCarbExtras);
			bwCarbsLabelContainer.addChild(bwCarbsCheck);
			
			bwCarbsLabel = LayoutFactory.createLabel("Carbs");
			bwCarbsLabelContainer.addChild(bwCarbsLabel);
			
			bwCarbsStepper = LayoutFactory.createNumericStepper(0, 500, 0, 0.5);
			bwCarbsStepper.addEventListener(Event.CHANGE, delayCalculations);
			bwCarbsStepper.validate();
			bwCarbsContainer.addChild(bwCarbsStepper);
			
			bwCarbsLabel.validate();
			bwCarbsStepper.validate();
			bwCarbsLabelContainer.validate();
			bwCarbsContainer.validate();
			bwCarbsStepper.x = contentWidth - bwCarbsStepper.width + 12;
			
			bwMainContainer.addChild(bwCarbsContainer);
			
			//Foods
			bwFoodsContainer = LayoutFactory.createLayoutGroup("horizontal");
			bwFoodsContainer.width = contentWidth;
			bwMainContainer.addChild(bwFoodsContainer);
			
			bwFoodsLabel = LayoutFactory.createLabel("Foods");
			bwFoodsLabel.paddingLeft = 25;
			bwFoodsContainer.addChild(bwFoodsLabel);
			
			bwFoodLoaderButton = LayoutFactory.createButton("Load Foods");
			bwFoodLoaderButton.addEventListener(Event.TRIGGERED, onShowFoodManager);
			bwFoodsContainer.addChild(bwFoodLoaderButton);
			
			bwFoodsLabel.validate();
			bwFoodLoaderButton.validate();
			bwFoodsContainer.validate();
			bwFoodLoaderButton.x = contentWidth - bwFoodLoaderButton.width;
			
			//Carbs Offset
			bwCarbsOffsetContainer = LayoutFactory.createLayoutGroup("horizontal");
			bwCarbsOffsetContainer.width = contentWidth;
			bwMainContainer.addChild(bwCarbsOffsetContainer);
			
			bwCarbsOffsetLabel = LayoutFactory.createLabel("Carbs Offset (Min)");
			bwCarbsOffsetLabel.paddingLeft = 25;
			bwCarbsOffsetContainer.addChild(bwCarbsOffsetLabel);
			
			bwCarbsOffsetStepper = LayoutFactory.createNumericStepper(-300, 300, 0, 5);
			bwCarbsOffsetStepper.validate();
			bwCarbsOffsetContainer.addChild(bwCarbsOffsetStepper);
			
			bwCarbsOffsetContainer.validate();
			bwCarbsOffsetStepper.x = contentWidth - bwCarbsOffsetStepper.width + 12;
			
			//Carb Type
			bwCarbTypeContainer = LayoutFactory.createLayoutGroup("horizontal");
			bwMainContainer.addChild(bwCarbTypeContainer);
			
			bwCarbTypeLabel = LayoutFactory.createLabel("Carb Type");
			bwCarbTypeLabel.paddingLeft = 25;
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
			
			var defaultCarbType:String = ProfileManager.getDefaultTimeAbsortionCarbType();
			if (defaultCarbType == "fast")
				bwCarbTypePicker.selectedIndex = 0;
			else if (defaultCarbType == "medium")
				bwCarbTypePicker.selectedIndex = 1;
			else if (defaultCarbType == "slow")
				bwCarbTypePicker.selectedIndex = 2;
			else
				bwCarbTypePicker.selectedIndex = 2;
			
			bwCarbTypePicker.addEventListener(Event.CHANGE, onCarbTypeChanged);
			
			bwCarbTypeContainer.addChild(bwCarbTypePicker);
			
			bwCarbTypePicker.validate();
			bwCarbTypeContainer.validate();
			bwCarbTypePicker.x = contentWidth - bwCarbTypePicker.width + 1;
			
			//Insulin Type
			bwInsulinTypeContainer = LayoutFactory.createLayoutGroup("horizontal");
			bwMainContainer.addChild(bwInsulinTypeContainer);
			
			bwInsulinTypeLabel = LayoutFactory.createLabel("Insulin Type");
			bwInsulinTypeContainer.addChild(bwInsulinTypeLabel);
			
			bwInsulinTypePicker = LayoutFactory.createPickerList();
			bwInsulinTypePicker.labelField = "label";
			bwInsulinTypePicker.popUpContentManager = new DropDownPopUpContentManager();
			bwInsulinTypeContainer.addChild(bwInsulinTypePicker);
			
			var askForInsulinConfiguration:Boolean = true;
			if (ProfileManager.insulinsList != null && ProfileManager.insulinsList.length > 0)
			{
				var insulinDataProvider:ArrayCollection = new ArrayCollection();
				var userInsulins:Array = sortInsulinsByDefault(ProfileManager.insulinsList.concat());
				var numInsulins:int = userInsulins.length
				for (i = 0; i < numInsulins; i++) 
				{
					var insulin:Insulin = userInsulins[i];
					if (insulin.name.indexOf("Nightscout") == -1 && !insulin.isHidden)
					{
						insulinDataProvider.push( { label:insulin.name, id: insulin.ID } );
						askForInsulinConfiguration = false;
					}
				}
				bwInsulinTypePicker.dataProvider = insulinDataProvider;
				bwInsulinTypePicker.popUpContentManager = new DropDownPopUpContentManager();
				bwInsulinTypePicker.itemRendererFactory = function():IListItemRenderer
				{
					var renderer:DefaultListItemRenderer = new DefaultListItemRenderer();
					renderer.paddingRight = renderer.paddingLeft = 15;
					return renderer;
				};
			}
			
			if (askForInsulinConfiguration)
			{
				if (createInsulinButton != null)
				{
					createInsulinButton.removeEventListeners();
					createInsulinButton.removeFromParent(true);
				}
				createInsulinButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('treatments','configure_insulins_button_label'));
				createInsulinButton.addEventListener(Event.TRIGGERED, onConfigureInsulins);
				bwInsulinTypeContainer.removeChild(bwInsulinTypePicker);
				bwInsulinTypeContainer.addChild(createInsulinButton);
				createInsulinButton.validate();
				bwInsulinTypeContainer.validate();
				createInsulinButton.x = contentWidth - createInsulinButton.width + 1;
				
				canAddInsulin = false;
				
				function onConfigureInsulins(e:Event):void
				{
					if (createInsulinButton != null) createInsulinButton.removeEventListener(Event.TRIGGERED, onConfigureInsulins);
					
					AppInterface.instance.navigator.pushScreen( Screens.SETTINGS_PROFILE );
					
					var popupTween:Tween=new Tween(bolusWizardCallout, 0.3, Transitions.LINEAR);
					popupTween.fadeTo(0);
					popupTween.onComplete = function():void
					{
						onCloseCallout(null);
					}
					Starling.juggler.add(popupTween);
				}
			}
			else
			{
				canAddInsulin = true;
				
				if (bwInsulinTypePicker.parent == null)
				{
					if (createInsulinButton != null)
					{
						createInsulinButton.removeEventListeners();
						createInsulinButton.removeFromParent(true);
						createInsulinButton = null;
					}
					
					bwInsulinTypeContainer.addChild(bwInsulinTypePicker);
				}
				
				bwInsulinTypePicker.validate();
				bwInsulinTypeContainer.validate();
				bwInsulinTypePicker.x = contentWidth - bwInsulinTypePicker.width + 1;
			}
			
			//Trend
			bwTrendContainer = LayoutFactory.createLayoutGroup("horizontal");
			bwTrendContainer.width = contentWidth;
			bwMainContainer.addChild(bwTrendContainer);
			
			bwTrendLabelContainer = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.LEFT, VerticalAlign.MIDDLE, 5);
			bwTrendContainer.addChild(bwTrendLabelContainer);
			
			bwTrendCheck = LayoutFactory.createCheckMark(false);
			bwTrendCheck.addEventListener(Event.CHANGE, performCalculations);
			bwTrendContainer.addChild(bwTrendCheck);
			
			var currentTrendArrow:String = latestBgReading != null ? latestBgReading.slopeArrow() : "";
			bwTrendLabel = LayoutFactory.createLabel("Trend" + " " + currentTrendArrow);
			bwTrendContainer.addChild(bwTrendLabel);
			
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
			
			bwCurrentTrendLabel = LayoutFactory.createLabel(currentTrendCorrection + currentTrendCorrectionUnit);
			bwTrendContainer.addChild(bwCurrentTrendLabel);
			
			bwCurrentTrendLabel.validate();
			bwTrendContainer.validate();
			bwCurrentTrendLabel.x = contentWidth - bwCurrentTrendLabel.width;
			bwTrendLabel.x = bwTrendCheck.x + bwTrendCheck.width + 5;
			
			//Current IOB
			bwIOBContainer = LayoutFactory.createLayoutGroup("horizontal");
			bwIOBContainer.width = contentWidth;
			bwMainContainer.addChild(bwIOBContainer);
			
			bwIOBLabelContainer = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.LEFT, VerticalAlign.MIDDLE, 5);
			bwIOBContainer.addChild(bwIOBLabelContainer);
			
			bwIOBCheck = LayoutFactory.createCheckMark(false);
			bwIOBCheck.addEventListener(Event.CHANGE, performCalculations);
			bwIOBLabelContainer.addChild(bwIOBCheck);
			
			bwIOBLabel = LayoutFactory.createLabel("IOB");
			bwIOBLabelContainer.addChild(bwIOBLabel);
			
			currentIOB = TreatmentsManager.getTotalIOB(new Date().valueOf());
			bwCurrentIOBLabel = LayoutFactory.createLabel(GlucoseFactory.formatIOB(currentIOB));
			bwIOBContainer.addChild(bwCurrentIOBLabel);
			
			bwCurrentIOBLabel.validate();
			bwIOBContainer.validate();
			bwCurrentIOBLabel.x = contentWidth - bwCurrentIOBLabel.width;
			
			//Current COB
			bwCOBContainer = LayoutFactory.createLayoutGroup("horizontal");
			bwCOBContainer.width = contentWidth;
			bwMainContainer.addChild(bwCOBContainer);
			
			bwCOBLabelContainer = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.LEFT, VerticalAlign.MIDDLE, 5);
			bwCOBContainer.addChild(bwCOBLabelContainer);
			
			bwCOBCheck = LayoutFactory.createCheckMark(false);
			bwCOBCheck.addEventListener(Event.CHANGE, performCalculations);
			bwCOBLabelContainer.addChild(bwCOBCheck);
			
			bwCOBLabel = LayoutFactory.createLabel("COB");
			bwCOBLabelContainer.addChild(bwCOBLabel);
			
			currentCOB = TreatmentsManager.getTotalCOB(new Date().valueOf());
			bwCurrentCOBLabel = LayoutFactory.createLabel(GlucoseFactory.formatCOB(currentCOB));
			bwCOBContainer.addChild(bwCurrentCOBLabel);
			
			bwCurrentCOBLabel.validate();
			bwCOBContainer.validate();
			bwCurrentCOBLabel.x = contentWidth - bwCurrentCOBLabel.width;
			
			//Exercise Adjustment
			bwExerciseContainer = LayoutFactory.createLayoutGroup("vertical");
			bwExerciseContainer.width = contentWidth;
			bwMainContainer.addChild(bwExerciseContainer);
			
			bwExerciseLabelContainer = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.LEFT, VerticalAlign.MIDDLE, 5);
			bwExerciseContainer.addChild(bwExerciseLabelContainer);
			
			bwExerciseCheck = LayoutFactory.createCheckMark(false);
			bwExerciseCheck.addEventListener(Event.CHANGE, onShowHideExerciseAdjustment);
			bwExerciseLabelContainer.addChild(bwExerciseCheck);
			
			bwExerciseLabel = LayoutFactory.createLabel("Exercise Adjustment");
			bwExerciseLabelContainer.addChild(bwExerciseLabel);
			
			bwExerciseSettingsContainer = LayoutFactory.createLayoutGroup("vertical", HorizontalAlign.LEFT, VerticalAlign.MIDDLE, 5);
			bwExerciseSettingsContainer.width = contentWidth;
			
			bwExerciseTimeContainer = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.LEFT, VerticalAlign.MIDDLE, 5);
			bwExerciseTimeContainer.width = contentWidth;
			bwExerciseSettingsContainer.addChild(bwExerciseTimeContainer);
			
			bwExerciseTimeLabel = LayoutFactory.createLabel("Time");
			bwExerciseTimeLabel.paddingLeft = 25;
			bwExerciseTimeContainer.addChild(bwExerciseTimeLabel);
			
			bwExerciseTimePicker = LayoutFactory.createPickerList();
			bwExerciseTimePicker.labelField = "label";
			bwExerciseTimePicker.popUpContentManager = new DropDownPopUpContentManager();
			bwExerciseTimePicker.dataProvider = new ArrayCollection
				(
					[
						{ label: "Before Exercise" },	
						{ label: "After Exercise" }	
					]
				);
			bwExerciseTimePicker.selectedIndex = 0;
			bwExerciseTimePicker.addEventListener(Event.CHANGE, onExerciseTimeChanged);
			bwExerciseTimeContainer.addChild(bwExerciseTimePicker);
			bwExerciseTimePicker.validate();
			bwExerciseTimePicker.x = contentWidth - bwExerciseTimePicker.width;
			
			bwExerciseIntensityContainer = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.LEFT, VerticalAlign.MIDDLE, 5);
			bwExerciseIntensityContainer.width = contentWidth;
			bwExerciseSettingsContainer.addChild(bwExerciseIntensityContainer);
			
			bwExerciseIntensityLabel = LayoutFactory.createLabel("Intensity");
			bwExerciseIntensityLabel.paddingLeft = 25;
			bwExerciseIntensityContainer.addChild(bwExerciseIntensityLabel);
			
			bwExerciseIntensityPicker = LayoutFactory.createPickerList();
			bwExerciseIntensityPicker.labelField = "label";
			bwExerciseIntensityPicker.popUpContentManager = new DropDownPopUpContentManager();
			bwExerciseIntensityPicker.dataProvider = new ArrayCollection
				(
					[
						{ label: "Low" },	
						{ label: "Moderate" },	
						{ label: "High" }	
					]
				);
			bwExerciseIntensityPicker.selectedIndex = 0;
			bwExerciseIntensityPicker.addEventListener(Event.CHANGE, onExerciseIntensityChanged);
			bwExerciseIntensityContainer.addChild(bwExerciseIntensityPicker);
			bwExerciseIntensityPicker.validate();
			bwExerciseIntensityPicker.x = contentWidth - bwExerciseIntensityPicker.width;
			
			bwExerciseDurationContainer = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.LEFT, VerticalAlign.MIDDLE, 5);
			bwExerciseDurationContainer.width = contentWidth;
			bwExerciseSettingsContainer.addChild(bwExerciseDurationContainer);
			
			bwExerciseDurationLabel = LayoutFactory.createLabel("Duration");
			bwExerciseDurationLabel.paddingLeft = 25;
			bwExerciseDurationContainer.addChild(bwExerciseDurationLabel);
			
			bwExerciseDurationPicker = LayoutFactory.createPickerList();
			bwExerciseDurationPicker.labelField = "label";
			var bwExerciseDurationPopup:DropDownPopUpContentManager = new DropDownPopUpContentManager();
			bwExerciseDurationPopup.primaryDirection = RelativePosition.TOP;
			bwExerciseDurationPicker.popUpContentManager = bwExerciseDurationPopup;
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
			bwExerciseDurationPicker.addEventListener(Event.CHANGE, onExerciseDurationChanged);
			bwExerciseDurationContainer.addChild(bwExerciseDurationPicker);
			bwExerciseDurationPicker.validate();
			bwExerciseDurationPicker.x = contentWidth - bwExerciseDurationPicker.width;
			
			bwExerciseAmountContainer = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.LEFT, VerticalAlign.MIDDLE, 5);
			bwExerciseAmountContainer.width = contentWidth;
			bwExerciseSettingsContainer.addChild(bwExerciseAmountContainer);
			
			bwExerciseAmountLabel = LayoutFactory.createLabel("Reduction (%)");
			bwExerciseAmountLabel.paddingLeft = 25;
			bwExerciseAmountContainer.addChild(bwExerciseAmountLabel);
			
			bwExerciseAmountStepper = LayoutFactory.createNumericStepper(0, 100, 0, 1);
			bwExerciseAmountStepper.addEventListener(Event.CHANGE, delayCalculations);
			bwExerciseAmountStepper.validate();
			bwExerciseAmountContainer.addChild(bwExerciseAmountStepper);
			bwExerciseAmountStepper.x = contentWidth - bwExerciseAmountStepper.width + 12;
			
			//Sickness Adjustment
			bwSicknessContainer = LayoutFactory.createLayoutGroup("vertical");
			bwSicknessContainer.width = contentWidth;
			bwMainContainer.addChild(bwSicknessContainer);
			
			bwSicknessLabelContainer = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.LEFT, VerticalAlign.MIDDLE, 5);
			bwSicknessContainer.addChild(bwSicknessLabelContainer);
			
			bwSicknessCheck = LayoutFactory.createCheckMark(false);
			bwSicknessCheck.addEventListener(Event.CHANGE, onShowHideSicknessAdjustment);
			bwSicknessLabelContainer.addChild(bwSicknessCheck);
			
			bwSicknessLabel = LayoutFactory.createLabel("Sickness Adjustment");
			bwSicknessLabelContainer.addChild(bwSicknessLabel);
			
			bwSicknessAmountContainer = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.LEFT, VerticalAlign.MIDDLE, 5);
			bwSicknessAmountContainer.width = contentWidth;
			
			bwSicknessAmountLabel = LayoutFactory.createLabel("Increase (%)");
			bwSicknessAmountLabel.paddingLeft = 25;
			bwSicknessAmountContainer.addChild(bwSicknessAmountLabel);
			
			bwSicknessAmountStepper = LayoutFactory.createNumericStepper(0, 100, 0, 1);
			bwSicknessAmountStepper.addEventListener(Event.CHANGE, delayCalculations);
			bwSicknessAmountStepper.validate();
			bwSicknessAmountContainer.addChild(bwSicknessAmountStepper);
			
			bwSicknessContainer.validate();
			bwSicknessAmountStepper.x = contentWidth - bwSicknessAmountStepper.width + 12;
			
			//Other Correction
			bwOtherCorrectionContainer = LayoutFactory.createLayoutGroup("vertical");
			bwOtherCorrectionContainer.width = contentWidth;
			bwMainContainer.addChild(bwOtherCorrectionContainer);
			
			bwOtherCorrectionLabelContainer = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.LEFT, VerticalAlign.MIDDLE, 5);
			bwOtherCorrectionContainer.addChild(bwOtherCorrectionLabelContainer);
			
			bwOtherCorrectionCheck = LayoutFactory.createCheckMark(false);
			bwOtherCorrectionCheck.addEventListener(Event.CHANGE, onShowHideOtherCorrection);
			bwOtherCorrectionCheck.addEventListener(Event.CHANGE, performCalculations);
			bwOtherCorrectionLabelContainer.addChild(bwOtherCorrectionCheck);
			
			bwOtherCorrectionLabel = LayoutFactory.createLabel("Extra Correction");
			bwOtherCorrectionLabelContainer.addChild(bwOtherCorrectionLabel);
			
			bwOtherCorrectionAmountContainer = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.LEFT, VerticalAlign.MIDDLE, 5);
			bwOtherCorrectionAmountContainer.width = contentWidth;
			
			bwOtherCorrectionAmountLabel = LayoutFactory.createLabel("Amount (U)");
			bwOtherCorrectionAmountLabel.paddingLeft = 25;
			bwOtherCorrectionAmountContainer.addChild(bwOtherCorrectionAmountLabel);
			
			bwOtherCorrectionAmountStepper = LayoutFactory.createNumericStepper(0, 100, 0, insulinPrecision);
			bwOtherCorrectionAmountStepper.addEventListener(Event.CHANGE, delayCalculations);
			bwOtherCorrectionAmountStepper.validate();
			bwOtherCorrectionAmountContainer.addChild(bwOtherCorrectionAmountStepper);
			
			bwOtherCorrectionContainer.validate();
			bwOtherCorrectionAmountStepper.x = contentWidth - bwOtherCorrectionAmountStepper.width + 12;
			
			//Extended Bolus Reminder
			bwExtendedBolusReminderContainer = LayoutFactory.createLayoutGroup("vertical");
			bwExtendedBolusReminderContainer.width = contentWidth;
			bwMainContainer.addChild(bwExtendedBolusReminderContainer);
			
			bwExtendedBolusReminderLabelContainer = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.LEFT, VerticalAlign.MIDDLE, 5);
			bwExtendedBolusReminderContainer.addChild(bwExtendedBolusReminderLabelContainer);
			
			bwExtendedBolusReminderCheck = LayoutFactory.createCheckMark(false);
			bwExtendedBolusReminderCheck.addEventListener(Event.CHANGE, onShowHideExtendedBolusReminder);
			bwExtendedBolusReminderLabelContainer.addChild(bwExtendedBolusReminderCheck);
			
			bwExtendedBolusReminderLabel = LayoutFactory.createLabel("Extended Bolus Reminder");
			bwExtendedBolusReminderLabelContainer.addChild(bwExtendedBolusReminderLabel);
			
			//Extended Bolus Reminder Date/Time Spinner
			bwExtendedBolusReminderDateTimeContainer = LayoutFactory.createLayoutGroup("vertical", HorizontalAlign.CENTER, VerticalAlign.MIDDLE, 5);
			bwExtendedBolusReminderDateTimeContainer.width = contentWidth;
			(bwExtendedBolusReminderDateTimeContainer.layout as VerticalLayout).paddingTop = 25;
			
			bwExtendedBolusReminderDateTimeSpinner = new DateTimeSpinner();
			bwExtendedBolusReminderDateTimeSpinner.locale = Constants.getUserLocale(true);
			bwExtendedBolusReminderDateTimeSpinner.height = 30;
			bwExtendedBolusReminderDateTimeContainer.addChild(bwExtendedBolusReminderDateTimeSpinner);
			
			//Extended Bolus Sound Selector
			bwExtendedBolusSoundListContainer = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.CENTER);
			bwExtendedBolusSoundListContainer.width = contentWidth;
			(bwExtendedBolusSoundListContainer.layout as HorizontalLayout).paddingTop = 20;
			(bwExtendedBolusSoundListContainer.layout as HorizontalLayout).paddingBottom = 5;
			bwExtendedBolusReminderDateTimeContainer.addChild(bwExtendedBolusSoundListContainer);
			
			bwExtendedBolusSoundList = LayoutFactory.createPickerList();
			var soundListPopUp:VerticalCenteredPopUpContentManager = new VerticalCenteredPopUpContentManager();
			soundListPopUp.margin = 25;
			bwExtendedBolusSoundList.popUpContentManager = soundListPopUp;
			bwExtendedBolusSoundList.maxWidth = contentWidth - 50;
			bwExtendedBolusSoundList.addEventListener(Event.CLOSE, onSoundListClose);
			
			var soundLabelsList:Array = AlertCustomizerList.ALERT_NAMES_LIST.split(",");
			soundLabelsList.insertAt(1, "Default iOS");
			var soundFilesList:Array = AlertCustomizerList.ALERT_SOUNDS_LIST.split(",");
			soundFilesList[0] = "";
			soundFilesList.insertAt(1, "default");
			var soundListProvider:ArrayCollection = new ArrayCollection();
			bwExtendedBolusSoundAccessoriesList = [];
			var selectedSoundFileIndex:int = 0;
			
			var soundListLength:uint = soundLabelsList.length;
			for (i = 0; i < soundListLength; i++) 
			{
				/* Set Label */
				var labelValue:String = StringUtil.trim(soundLabelsList[i]);
				
				/* Set Accessory */
				var accessoryValue:DisplayObject;
				if (StringUtil.trim(soundFilesList[i]) == "" || StringUtil.trim(soundFilesList[i]) == "default")
					accessoryValue = new Sprite();
				else
				{
					accessoryValue = LayoutFactory.createPlayButton(onPlaySound);
					accessoryValue.pivotX = -15;
				}
				
				bwExtendedBolusSoundAccessoriesList.push(accessoryValue);
				
				/* Set Sound File */
				var soundFileValue:String;
				if (StringUtil.trim(soundFilesList[i]) != "" && StringUtil.trim(soundFilesList[i]) != "default")
					soundFileValue = "../assets/sounds/" + StringUtil.trim(soundFilesList[i]);
				else
					soundFileValue = StringUtil.trim(soundFilesList[i]);
				
				soundListProvider.push( { label: labelValue, accessory: accessoryValue, soundFile: soundFileValue } );
				
				if (soundFileValue == CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BOLUS_WIZARD_DEFAULT_EXTENDED_BOLUS_SOUND))
					selectedSoundFileIndex = i
			}
			
			bwExtendedBolusSoundList.dataProvider = soundListProvider;
			bwExtendedBolusSoundList.itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "label";
				itemRenderer.accessoryField = "accessory";
				itemRenderer.accessoryOffsetX = -20;
				itemRenderer.labelOffsetX = 20;
				
				return itemRenderer;
			};
			bwExtendedBolusSoundList.selectedIndex = selectedSoundFileIndex;
			
			bwExtendedBolusSoundListContainer.addChild(bwExtendedBolusSoundList);
			
			//Notes
			bwNotes = LayoutFactory.createTextInput(false, false, contentWidth, HorizontalAlign.CENTER, false, false, false, true, true);
			bwNotes.prompt = ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_note');
			bwMainContainer.addChild(bwNotes);
			
			//Final Calculations Label
			finalCalculationsLabel = LayoutFactory.createLabel("Final Calculations", HorizontalAlign.CENTER, VerticalAlign.TOP, 14, true);
			finalCalculationsLabel.width = contentWidth;
			finalCalculationsLabel.paddingTop = 15;
			finalCalculationsLabel.paddingBottom = 5;
			bwMainContainer.addChild(finalCalculationsLabel);
			
			//Wizard Suggestion
			bwSuggestionLabel = LayoutFactory.createLabel("", HorizontalAlign.CENTER, VerticalAlign.TOP, 12, true, 0xFF0000);
			bwSuggestionLabel.wordWrap = true;
			bwSuggestionLabel.width = contentWidth;
			bwMainContainer.addChild(bwSuggestionLabel);
			
			//Final Calculated Insulin and Carbs
			bwFinalCalculationsContainer = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.CENTER, VerticalAlign.MIDDLE, 10);
			(bwFinalCalculationsContainer.layout as HorizontalLayout).paddingBottom = 10;
			(bwFinalCalculationsContainer.layout as HorizontalLayout).paddingTop = 5;
			bwFinalCalculationsContainer.width = contentWidth;
			
			bwFinalCalculatedInsulinContainer = LayoutFactory.createLayoutGroup("vertical", HorizontalAlign.CENTER, VerticalAlign.MIDDLE, 5);
			bwFinalCalculationsContainer.addChild(bwFinalCalculatedInsulinContainer);
			
			bwFinalCalculatedInsulinLabel = LayoutFactory.createLabel("Insulin", HorizontalAlign.CENTER);
			bwFinalCalculatedInsulinContainer.addChild(bwFinalCalculatedInsulinLabel);
			
			bwFinalCalculatedInsulinStepper = LayoutFactory.createNumericStepper(0, 200, 0, insulinPrecision);
			bwFinalCalculatedInsulinStepper.addEventListener(Event.CHANGE, onFinalTreatmentChanged);
			bwFinalCalculatedInsulinContainer.addChild(bwFinalCalculatedInsulinStepper);
			
			bwFinalCalculatedCarbsContainer = LayoutFactory.createLayoutGroup("vertical", HorizontalAlign.CENTER, VerticalAlign.MIDDLE, 5);
			bwFinalCalculationsContainer.addChild(bwFinalCalculatedCarbsContainer);
			
			bwFinalCalculatedCarbsLabel = LayoutFactory.createLabel("Carbs", HorizontalAlign.CENTER);
			bwFinalCalculatedCarbsContainer.addChild(bwFinalCalculatedCarbsLabel);
			
			bwFinalCalculatedCarbsStepper = LayoutFactory.createNumericStepper(0, 1000, 0, carbsPrecision);
			bwFinalCalculatedCarbsStepper.addEventListener(Event.CHANGE, onFinalTreatmentChanged);
			bwFinalCalculatedCarbsContainer.addChild(bwFinalCalculatedCarbsStepper);
			
			bwMainContainer.addChild(bwFinalCalculationsContainer);
			
			//Action Buttons
			var bolusWizardActionLayout:HorizontalLayout = new HorizontalLayout();
			bolusWizardActionLayout.horizontalAlign = HorizontalAlign.CENTER;
			bolusWizardActionLayout.gap = 5;
			
			bolusWizardActionContainer = new LayoutGroup();
			bolusWizardActionContainer.width = contentWidth;
			bolusWizardActionContainer.layout = bolusWizardActionLayout;
			bwMainContainer.addChild(bolusWizardActionContainer);
			
			bolusWizardCancelButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('globaltranslations','cancel_button_label').toUpperCase());
			bolusWizardCancelButton.addEventListener(Event.TRIGGERED, onCloseCallout);
			bolusWizardActionContainer.addChild(bolusWizardCancelButton);
			
			bolusWizardAddButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('globaltranslations','add_button_label').toUpperCase());
			bolusWizardAddButton.addEventListener(Event.TRIGGERED, onAddBolusWizardTreatment);
			bolusWizardActionContainer.addChild(bolusWizardAddButton);
			
			bwMainContainer.addChild(bolusWizardActionContainer);
			
			//Final Adjustments
			bwWizardScrollContainer.addChild(bwMainContainer);
			
			//Components Show/Hide
			onShowHideCarbExtras();
			onShowHideExerciseAdjustment();
			onShowHideSicknessAdjustment();
			onShowHideOtherCorrection();
			onShowHideExtendedBolusReminder();
		}
		
		private static function onPlaySound(e:Event):void
		{
			var selectedItemData:Object = DefaultListItemRenderer(Button(e.currentTarget).parent).data;
			var soundFile:String = selectedItemData.soundFile;
			if(soundFile != "" && soundFile != "default" && soundFile != "no_sound")
				SpikeANE.playSound(soundFile);
		}
		
		private static function onSoundListClose():void
		{
			SpikeANE.stopPlayingSound();
		}
		
		private static function sortInsulinsByDefault(insulins:Array):Array
		{
			insulins.sortOn(["name"], Array.CASEINSENSITIVE);
			
			for (var i:int = 0; i < insulins.length; i++) 
			{
				var insulin:Insulin = insulins[i];
				if (insulin.isDefault)
				{
					//Remove it from the array
					insulins.removeAt(i);
					
					//Add it to the beginning
					insulins.unshift(insulin);
					
					break;
				}
			}
			
			return insulins;
		}
		
		private static function updateCriticalData():void
		{
			var now:Number = new Date().valueOf();
			
			//Current Glucose
			latestBgReading = BgReading.lastWithCalculatedValue();
			if (latestBgReading != null && now - latestBgReading.timestamp <= TIME_11_MINUTES) //Only use BG readings less than 11 minutes ago.
			{
				currentBG = Math.round(latestBgReading.calculatedValue);
			}
			else
			{
				bwGlucoseCheck.isSelected = false
				currentBG = 0;
			}
			
			bwGlucoseStepper.value = isMgDl ? currentBG : Math.round(BgReading.mgdlToMmol(currentBG) * 100) / 100;
			bwCurrentGlucoseContainer.validate();
			bwGlucoseStepper.x = contentWidth - bwGlucoseStepper.width + 12;
			
			//Current Trend
			var currentTrendArrow:String = latestBgReading != null ? latestBgReading.slopeArrow() : "";
			//bwTrendCheck.isSelected = latestBgReading != null ? true : false;
			bwTrendLabel.text = "Trend" + " " + currentTrendArrow;
			currentTrendCorrection = 0;
			currentTrendCorrectionUnit = "U";
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
			
			//if (currentTrendCorrection == 0) bwTrendCheck.isSelected = false;
			bwCurrentTrendLabel.text = currentTrendCorrection + currentTrendCorrectionUnit;
			bwTrendLabel.validate();
			bwCurrentTrendLabel.validate();
			bwTrendContainer.validate();
			bwCurrentTrendLabel.x = contentWidth - bwCurrentTrendLabel.width;
			bwTrendLabel.x = bwTrendCheck.x + bwTrendCheck.width + 5;
			
			//Current IOB
			currentIOB = TreatmentsManager.getTotalIOB(now);
			bwCurrentIOBLabel.text = GlucoseFactory.formatIOB(currentIOB);
			bwCurrentIOBLabel.validate();
			bwIOBContainer.validate();
			bwCurrentIOBLabel.x = contentWidth - bwCurrentIOBLabel.width;
			bwIOBCheck.isSelected = currentIOB > 0;
			
			//Current COB
			currentCOB = TreatmentsManager.getTotalCOB(now);
			bwCurrentCOBLabel.text = GlucoseFactory.formatCOB(currentCOB);
			bwCurrentCOBLabel.validate();
			bwCOBContainer.validate();
			bwCurrentCOBLabel.x = contentWidth - bwCurrentCOBLabel.width;
			bwCOBCheck.isSelected = currentCOB > 0;
			
			//Calculations
			performCalculations();
		}
		
		private static function onFinalTreatmentChanged(e:Event):void
		{
			bolusWizardAddButton.isEnabled = bwFinalCalculatedInsulinStepper.value != 0 || bwFinalCalculatedCarbsStepper.value != 0 ? true : false;
		}
		
		private static function displayCallout():void
		{
			bwSuggestionLabel.validate();
			bwMainContainer.validate();
			var contentOriginalHeight:Number = bwMainContainer.height + 60;
			var suggestedCalloutHeight:Number = Constants.stageHeight - yPos - 10;
			var finalCalloutHeight:Number = contentOriginalHeight > suggestedCalloutHeight ?  suggestedCalloutHeight : contentOriginalHeight;
			
			if (bolusWizardCallout != null) bolusWizardCallout.dispose();
			bolusWizardCallout = Callout.show(bwTotalScrollContainer, calloutPositionHelper);
			bolusWizardCallout.disposeContent = false;
			bolusWizardCallout.paddingBottom = 15;
			bolusWizardCallout.paddingRight = 10;
			bolusWizardCallout.closeOnTouchBeganOutside = false;
			bolusWizardCallout.closeOnTouchEndedOutside = false;
			bolusWizardCallout.height = finalCalloutHeight;
			bolusWizardCallout.validate();
			bwWizardScrollContainer.height = finalCalloutHeight - 60;
			bwWizardScrollContainer.maxHeight = finalCalloutHeight - 60;
			bwTotalScrollContainer.height = finalCalloutHeight - 60;
			bwTotalScrollContainer.maxHeight = finalCalloutHeight - 60;
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
				if (Constants.deviceModel != DeviceInfo.IPHONE_X_Xs_XsMax_Xr)
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
				onCloseCallout(null);
				displayMissedSettingsCallout();
				
				return;
			}
			
			//var targetBG:Number = isMgDl ? Number(currentProfile.targetGlucoseRates) : Math.round(BgReading.mmolToMgdl(Number(currentProfile.targetGlucoseRates)));
			var targetBG:Number = Number(currentProfile.targetGlucoseRates);
			var targetBGLow:Number = targetBG;
			var targetBGHigh:Number = targetBG;
			var acceptedMargin:Number = 10;
			
			//var isf:Number = isMgDl ? Number(currentProfile.insulinSensitivityFactors) : Math.round(BgReading.mmolToMgdl(Number(currentProfile.insulinSensitivityFactors)));
			var isf:Number = Number(currentProfile.insulinSensitivityFactors);
			var ic:Number = Number(currentProfile.insulinToCarbRatios);
			var bg:Number = 0;
			var insulinbg:Number = 0;
			var bgdiff:Number = 0;
			var insulincarbs:Number = 0;
			var carbs:Number = 0;
			var extraCorrections:Number = bwOtherCorrectionCheck.isSelected ? bwOtherCorrectionAmountStepper.value : 0;
			var iob:Number = 0;
			var cob:Number = 0;
			var insulincob:Number = 0;
			var carbsneeded:Number = 0;
			var total:Number = 0;
			var insulin:Number = 0;
			var roundingcorrection:Number = 0;
			
			// Load IOB;
			if (bwIOBCheck.isSelected) 
			{
				iob = currentIOB;
			}
			
			// Load COB
			if (bwCOBCheck.isSelected) {
				cob = currentCOB;
				insulincob = roundTo(cob / ic, insulinPrecision);
			}
			
			// Load BG
			if (bwGlucoseCheck.isSelected)
			{
				bg = isMgDl ? bwGlucoseStepper.value : Math.round(BgReading.mmolToMgdl(bwGlucoseStepper.value));
				
				if (isNaN(bg))
				{
					bg = 0;
				}
				
				if (bg < targetBGLow)
				{
					bgdiff = bg - targetBGLow;
				}
				else if (bg > targetBGHigh)
				{
					bgdiff = bg - targetBGHigh;
				}
				
				bgdiff = roundTo(bgdiff, 0.1);
				
				if (bg !== 0)
				{
					insulinbg = roundTo(bgdiff / isf, insulinPrecision);
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
				
				insulincarbs = roundTo(carbs / ic, insulinPrecision);
			}
			
			//Total & rounding
			//if (bwIOBCheck.isSelected) 
			//{
				total = insulinbg + insulincarbs + insulincob - iob + extraCorrections;
			//}
			
			insulin = roundTo(total, insulinPrecision);
			insulin = Math.round(insulin * 100) / 100;
			roundingcorrection = insulin - total;
			
			// Carbs needed if too much IOB
			if (insulin < 0) 
			{
				//carbsneeded = Math.ceil(-total * ic);
				carbsneeded = roundTo(-total * ic, carbsPrecision);
			}
			
			//Trend
			if (currentTrendCorrection != 0 && bwTrendCheck.isSelected)
			{
				if (currentTrendCorrectionUnit == "U")
				{
					insulin += currentTrendCorrection;
				}
				else if (currentTrendCorrectionUnit == "g")
				{
					carbsneeded += currentTrendCorrection;
					carbsneeded = roundTo(carbsneeded, carbsPrecision);
					
					//Recalculate insulin
					insulin -= roundTo(currentTrendCorrection / ic, insulinPrecision);
					insulin = Math.round(insulin * 100) / 100;
					roundingcorrection = insulin - total;
				}
			}
			
			//Exercise Adjustment
			var preAdjustmentInsulin:Number = insulin;
			
			if (insulin > 0 && bwExerciseCheck.isSelected)
			{
				preAdjustmentInsulin -= insulin * (bwExerciseAmountStepper.value / 100);
				preAdjustmentInsulin = roundTo(preAdjustmentInsulin, insulinPrecision);
				preAdjustmentInsulin = Math.round(preAdjustmentInsulin * 100) / 100;
			}
			
			// Sickness Adjustment
			if (insulin > 0 && bwSicknessCheck.isSelected)
			{
				preAdjustmentInsulin += insulin * (bwSicknessAmountStepper.value / 100);
				preAdjustmentInsulin = roundTo(preAdjustmentInsulin, insulinPrecision);
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
			
			var outcome:Number = record.bg - record.iob * isf;
			
			trace(ObjectUtil.toString(record));
			
			var isInTarget:Boolean = record.othercorrection === 0 && record.carbs === 0 && record.cob === 0 && record.bg > 0 && Math.abs(outcome - targetBG) <= acceptedMargin;
			
			if (isInTarget) 
			{
				bgIsWithinTarget = true;
				
				if (bolusWizardAddButton != null)
					bolusWizardAddButton.isEnabled = false;
				
				bwSuggestionLabel.text = "Projected outcome: " + (isMgDl ? Math.round(outcome) : Math.round(BgReading.mgdlToMmol(outcome) * 10) / 10);
				if (outcome == targetBG)
					bwSuggestionLabel.text += "\n" + "Blood glucose in target (" + (isMgDl ? currentProfile.targetGlucoseRates : Math.round(BgReading.mgdlToMmol(Number(currentProfile.targetGlucoseRates)) * 10) / 10) + ")";
				else
					bwSuggestionLabel.text += "\n" + "Blood glucose in target (" + (isMgDl ? currentProfile.targetGlucoseRates : Math.round(BgReading.mgdlToMmol(Number(currentProfile.targetGlucoseRates)) * 10) / 10) + ")" + " or within " + (isMgDl ? 10 : Math.round(BgReading.mgdlToMmol(10) * 100) / 100) + " " + GlucoseHelper.getGlucoseUnit() + " difference";
			}
			else if (record.insulin < 0) 
			{
				bgIsWithinTarget = false;
				
				if (bolusWizardAddButton != null)
					bolusWizardAddButton.isEnabled = true;
				
				suggestedCarbs = Number(record.carbsneeded);
				suggestedInsulin = 0;
				
				var insulinToCoverCarbs:Number = (record.carbsneeded / isf) + (record.carbs / isf);
				var bgImpact:Number = insulinToCoverCarbs * isf;
				var outcomeWithCarbsTreatment:Number = outcome + bgImpact;
				
				bwSuggestionLabel.text = "Outcome without extra treatments: " + (isMgDl ? Math.round(outcome) : Math.round(BgReading.mgdlToMmol(outcome) * 10) / 10);
				bwSuggestionLabel.text += "\n" + "Outcome with calculated treatment: " + (isMgDl ? Math.round(outcomeWithCarbsTreatment) : Math.round(BgReading.mgdlToMmol(outcomeWithCarbsTreatment) * 10) / 10);
				bwSuggestionLabel.text += "\n" + "Carbs needed: " + record.carbsneeded + "g";
				bwSuggestionLabel.text += "\n" + "Insulin equivalent: " + record.insulin + "U"; 
			}
			else
			{
				bgIsWithinTarget = false;
				
				if (bolusWizardAddButton != null)
					bolusWizardAddButton.isEnabled = true;
				
				suggestedCarbs = 0;
				suggestedInsulin = Number(record.insulin);
				
				//Calculate outcome
				var outcomeWithInsulinTreatment:Number = outcome - (Number(record.insulin) * isf) + (Number(record.insulincarbs / isf));
				
				if (record.carbs > 0)
				{
					var insulinToCoverExtraCarbs:Number = (record.carbs / isf);
					var bgImpactWithExtraCarbs:Number = insulinToCoverExtraCarbs * isf;
					outcomeWithInsulinTreatment += bgImpactWithExtraCarbs;
				}
				
				//Update Suggestion Label
				bwSuggestionLabel.text = "Outcome without extra treatments: " + (isMgDl ? Math.round(outcome) : Math.round(BgReading.mgdlToMmol(outcome) * 10) / 10);
				bwSuggestionLabel.text += "\n" + "Outcome with calculated treatment: " + (isMgDl ? Math.round(outcomeWithInsulinTreatment) : Math.round(BgReading.mgdlToMmol(outcomeWithInsulinTreatment) * 10) / 10);
				bwSuggestionLabel.text += "\n" + "Insulin needed: " + record.insulin + "U";
			}
			
			//Update Final Calculation Components
			if (!isInTarget)
			{
				bwFinalCalculatedInsulinStepper.value = record.insulin + (currentTrendCorrection != 0 && bwTrendCheck.isSelected && currentTrendCorrectionUnit == "U" ? currentTrendCorrection : 0);
				bwFinalCalculatedCarbsStepper.value = record.carbs + record.carbsneeded;
			}
			else
			{
				bwFinalCalculatedInsulinStepper.value = 0;
				bwFinalCalculatedCarbsStepper.value = 0;
			}
			
			//Components validation
			validateCarbOffset();
		}
		
		private static function validateCarbOffset():void
		{
			if ((suggestedInsulin > 0 && bwCarbsStepper.value > 0) || (suggestedCarbs > 0 && bwOtherCorrectionAmountStepper.value > 0))
			{
				//Meal Treatment
				bwCarbsOffsetStepper.isEnabled = true;
			}
			else
			{
				bwCarbsOffsetStepper.isEnabled = false;
			}
		}
		
		/**
		 * Event Listeners
		 */
		private static function onBgReadingReceivedMaster(e:TransmitterServiceEvent):void
		{
			updateCriticalData();
		}
		
		private static function onBgReadingReceivedFollower(e:FollowerEvent):void
		{
			updateCriticalData();
		}
		
		private static function onShowFoodManager(e:Event):void
		{
			if (bwWizardScrollContainer != null)
			{
				if (bwFoodManager == null)
				{
					bwFoodManager = new FoodManager(contentWidth, bolusWizardCallout.height - bolusWizardCallout.paddingTop - bolusWizardCallout.paddingBottom - 15);
					bwFoodManager.addEventListener(Event.COMPLETE, onFoodManagerCompleted);
					bwTotalScrollContainer.addChild(bwFoodManager);
				}
				
				bwTotalScrollContainer.scrollToPageIndex( 1, bwTotalScrollContainer.verticalPageIndex );
			}
		}
		
		private static function onFoodManagerCompleted(e:Event):void
		{
			if (bwWizardScrollContainer != null)
			{
				//Calculate all food carbs the user has added to the food manager
				var totalCarbs:Number = 0;
				var foodsList:Array = bwFoodManager.cartList;
				var addedFoods:int = 0;
				var addedFoodNames:Array = [];
				
				for (var i:int = 0; i < foodsList.length; i++) 
				{
					var food:Food = foodsList[i].food;
					if (food == null) 
						continue;
					
					var quantity:Number = foodsList[i].quantity;
					if (isNaN(quantity)) 
						continue;
					
					var carbs:Number = food.carbs;
					if (isNaN(carbs)) 
						continue;
					
					var fiber:Number = food.fiber;
					var substractFiber:Boolean = foodsList[i].substractFiber;
					if (substractFiber && !isNaN(fiber))
						carbs -= fiber;
					
					var finalCarbs:Number = (quantity / food.servingSize) * carbs;
					if (!isNaN(finalCarbs))
					{
						totalCarbs += finalCarbs;
						addedFoods += 1;
						addedFoodNames.push(quantity + food.servingUnit + " " + food.name);
					}
				}
				
				//Populate the carbs numeric stepper with all carbs from the food manager
				bwCarbsStepper.value = totalCarbs;
				
				//Update foods label
				if (addedFoods > 0)
				{
					bwFoodsLabel.text = "Foods" + " " + "(" + addedFoods + ")";
					bwFoodsLabel.validate();
					bwFoodLoaderButton.validate();
					bwFoodsContainer.validate();
					bwFoodLoaderButton.x = contentWidth - bwFoodLoaderButton.width;
					bwNotes.text = addedFoodNames.join(", ");
				}
				
				//Update critical data
				updateCriticalData();
				
				//Scroll to the Bolus Wizard screen
				bwTotalScrollContainer.scrollToPageIndex( 0, bwTotalScrollContainer.verticalPageIndex );
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
		
		private static function onShowHideCarbExtras(e:Event = null):void
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
		
		private static function onShowHideExerciseAdjustment(e:Event = null):void
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
		
		private static function onShowHideSicknessAdjustment(e:Event = null):void
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
		
		private static function onShowHideOtherCorrection(e:Event = null):void
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
		
		private static function onShowHideExtendedBolusReminder(e:Event = null):void
		{
			if (bwExtendedBolusReminderCheck.isSelected)
			{
				var childIndex:int = bwExtendedBolusReminderContainer.getChildIndex(bwExtendedBolusReminderLabelContainer);
				if (childIndex != -1)
				{
					bwExtendedBolusReminderContainer.addChildAt(bwExtendedBolusReminderDateTimeContainer, childIndex + 1);
					
					bwExtendedBolusReminderDateTimeSpinner.minimum = new Date(new Date().valueOf() + TimeSpan.TIME_5_MINUTES);;
					bwExtendedBolusReminderDateTimeSpinner.value = new Date(new Date().valueOf() + TimeSpan.TIME_1_HOUR);;
					
					bwExtendedBolusReminderDateTimeSpinner.validate();
					bwExtendedBolusReminderDateTimeContainer.validate();
				}
			}
			else
				bwExtendedBolusReminderDateTimeContainer.removeFromParent();
			
			performCalculations();
		}
		
		private static function onAddBolusWizardTreatment(e:Event):void
		{
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_BOLUS_WIZARD_DISCLAIMER_ACCEPTED) != "true")
			{
				AlertManager.showActionAlert
					(
						"Disclaimer",
						"Bolus Wizard disclaimer message!",
						Number.NaN,
						[
							{ label: "Cancel" },
							{ label: "I Accept", triggered: disclaimerAccepted }
						],
						HorizontalAlign.JUSTIFY
					);
			}
			else
				addTreatment();
			
			function addTreatment():void
			{
				var now:Number = new Date().valueOf();
				var carbDelayMinutes:Number = 20;
				var treatment:Treatment;
				
				if (bwFinalCalculatedInsulinStepper.value > 0 && bwFinalCalculatedCarbsStepper.value > 0)
				{
					//Meal Treatment
					if (!canAddInsulin)
					{
						displayInsulinRequiredAlert();
						return;
					}
					
					//Carb absorption delay
					if (bwCarbTypePicker.selectedIndex == 0)
						carbDelayMinutes = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CARB_FAST_ABSORTION_TIME));
					else if (bwCarbTypePicker.selectedIndex == 1)
						carbDelayMinutes = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CARB_MEDIUM_ABSORTION_TIME));
					else if (bwCarbTypePicker.selectedIndex == 2)
						carbDelayMinutes = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CARB_SLOW_ABSORTION_TIME));
					
					if (bwCarbsOffsetStepper.value == 0)
					{
						treatment = new Treatment
							(
								Treatment.TYPE_MEAL_BOLUS,
								now,
								bwFinalCalculatedInsulinStepper.value,
								bwInsulinTypePicker.selectedItem.id,
								bwFinalCalculatedCarbsStepper.value,
								0,
								TreatmentsManager.getEstimatedGlucose(now),
								bwNotes.text,
								null,
								carbDelayMinutes
							);
						
						//Add to list
						TreatmentsManager.treatmentsList.push(treatment);
						TreatmentsManager.treatmentsMap[treatment.ID] = treatment;
						
						Trace.myTrace("BolusWizard.as", "Added treatment to Spike. Type: " + treatment.type);
						
						//Notify listeners
						TreatmentsManager.instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.TREATMENT_ADDED, false, false, treatment));
						
						//Insert in DB
						if (!CGMBlueToothDevice.isFollower() || ModelLocator.INTERNAL_TESTING)
							Database.insertTreatmentSynchronous(treatment);
						
						//Upload to Nightscout
						NightscoutService.uploadTreatment(treatment);
					}
					else
					{
						//Insulin portion
						var treatmentInsulin:Treatment = new Treatment
							(
								Treatment.TYPE_MEAL_BOLUS,
								now,
								bwFinalCalculatedInsulinStepper.value,
								bwInsulinTypePicker.selectedItem.id,
								0,
								0,
								TreatmentsManager.getEstimatedGlucose(now),
								bwNotes.text
							);
						
						//Add to list
						TreatmentsManager.treatmentsList.push(treatmentInsulin);
						TreatmentsManager.treatmentsMap[treatmentInsulin.ID] = treatmentInsulin;
						
						Trace.myTrace("BolusWizard.as", "Added treatment to Spike. Type: " + treatmentInsulin.type);
						
						//Carb portion
						var carbTime:Number = now + (bwCarbsOffsetStepper.value * 60 * 1000);
						var treatmentCarbs:Treatment = new Treatment
							(
								Treatment.TYPE_MEAL_BOLUS,
								carbTime,
								0,
								bwInsulinTypePicker.selectedItem.id,
								bwFinalCalculatedCarbsStepper.value,
								0,
								TreatmentsManager.getEstimatedGlucose(carbTime <= now ? carbTime : now),
								bwNotes.text,
								null,
								carbDelayMinutes
							);
						if (carbTime > now) treatmentCarbs.needsAdjustment = true;
						
						//Add to list
						TreatmentsManager.treatmentsList.push(treatmentCarbs);
						TreatmentsManager.treatmentsMap[treatmentCarbs.ID] = treatmentCarbs;
						
						Trace.myTrace("BolusWizard.as", "Added treatment to Spike. Type: " + treatmentCarbs.type);
						
						//Notify listeners
						TreatmentsManager.instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.TREATMENT_ADDED, false, false, treatmentInsulin));
						TreatmentsManager.instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.TREATMENT_ADDED, false, false, treatmentCarbs));
						
						//Insert in DB
						if (!CGMBlueToothDevice.isFollower() || ModelLocator.INTERNAL_TESTING)
						{
							Database.insertTreatmentSynchronous(treatmentInsulin);
							Database.insertTreatmentSynchronous(treatmentCarbs);
						}
						
						//Upload to Nightscout
						NightscoutService.uploadTreatment(treatmentInsulin);
						NightscoutService.uploadTreatment(treatmentCarbs);
					}
				}
				else if (suggestedInsulin > 0 && suggestedCarbs <= 0 && bwCarbsStepper.value <= 0)
				{
					//Bolus Treatment
					if (!canAddInsulin)
					{
						displayInsulinRequiredAlert();
						return;
					}
					
					treatment = new Treatment
						(
							Treatment.TYPE_BOLUS,
							now,
							bwFinalCalculatedInsulinStepper.value,
							bwInsulinTypePicker.selectedItem.id,
							0,
							0,
							TreatmentsManager.getEstimatedGlucose(now),
							bwNotes.text
						);
					
					//Add to list
					TreatmentsManager.treatmentsList.push(treatment);
					TreatmentsManager.treatmentsMap[treatment.ID] = treatment;
					
					Trace.myTrace("BolusWizard.as", "Added treatment to Spike. Type: " + treatment.type);
					
					//Notify listeners
					TreatmentsManager.instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.TREATMENT_ADDED, false, false, treatment));
					
					//Insert in DB
					if (!CGMBlueToothDevice.isFollower() || ModelLocator.INTERNAL_TESTING)
						Database.insertTreatmentSynchronous(treatment);
					
					//Upload to Nightscout
					NightscoutService.uploadTreatment(treatment);
				}
				else if (suggestedCarbs > 0 && bwOtherCorrectionAmountStepper.value <= 0)
				{
					//Carb treatment
					if (bwCarbTypePicker.selectedIndex == 0)
						carbDelayMinutes = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CARB_FAST_ABSORTION_TIME));
					else if (bwCarbTypePicker.selectedIndex == 1)
						carbDelayMinutes = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CARB_MEDIUM_ABSORTION_TIME));
					else if (bwCarbTypePicker.selectedIndex == 2)
						carbDelayMinutes = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CARB_SLOW_ABSORTION_TIME));
					
					treatment = new Treatment
						(
							Treatment.TYPE_CARBS_CORRECTION,
							now,
							0,
							"",
							bwFinalCalculatedCarbsStepper.value,
							0,
							TreatmentsManager.getEstimatedGlucose(now),
							bwNotes.text,
							null,
							carbDelayMinutes
						);
					
					//Add to list
					TreatmentsManager.treatmentsList.push(treatment);
					TreatmentsManager.treatmentsMap[treatment.ID] = treatment;
					
					Trace.myTrace("BolusWizard.as", "Added treatment to Spike. Type: " + treatment.type);
					
					//Notify listeners
					TreatmentsManager.instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.TREATMENT_ADDED, false, false, treatment));
					
					//Insert in DB
					if (!CGMBlueToothDevice.isFollower() || ModelLocator.INTERNAL_TESTING)
						Database.insertTreatmentSynchronous(treatment);
					
					//Upload to Nightscout
					NightscoutService.uploadTreatment(treatment);
				}
				
				//Extended Bolus Reminder
				if (bwExtendedBolusReminderCheck.isSelected)
				{
					var delayInSeconds:int = int(TimeSpan.fromDates(new Date(), bwExtendedBolusReminderDateTimeSpinner.value).totalSeconds);
					
					//Validation
					if (delayInSeconds < 0) //User selected to be reminder on a date/time in the past
						return;
					
					var soundFile:String = String(bwExtendedBolusSoundList.selectedItem.soundFile);
					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_BOLUS_WIZARD_DEFAULT_EXTENDED_BOLUS_SOUND, soundFile, true, false);
					
					Trace.myTrace("BolusWizard.as", "Added new extended bolus notification that will fire at: " + new Date(new Date().valueOf() + (delayInSeconds * 1000)).toString());
					
					var notificationBuilder:NotificationBuilder = new NotificationBuilder()
						.setId(NotificationService.ID_FOR_EXTENDED_BOLUS_ALERT)
						.setAlert("Extended Bolus Reminder")
						.setTitle("Extended Bolus Reminder")
						.setBody("This is a reminder for your extended bolus.")
						.enableVibration(true)
						.enableLights(true)
						.setSound(soundFile)
						.setDelay(delayInSeconds);
					
					Notifications.service.notify(notificationBuilder.build());
				}
				
				onCloseCallout(null);
			}
			
			function disclaimerAccepted():void
			{
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_BOLUS_WIZARD_DISCLAIMER_ACCEPTED, "true", true, false);
				
				addTreatment();
			}
			
			function displayInsulinRequiredAlert():void
			{
				AlertManager.showSimpleAlert
					(
						"Warning",
						"In order to add treatments you first need to configure your insulins. To do so, please press the Configure Insulins button."
					);
			}
		}
		
		private static function onCloseCallout(e:Event):void
		{
			clearTimeout(calculationTimeout);
			
			disposeComponents();
		}
		
		private static function disposeComponents():void
		{
			TransmitterService.instance.removeEventListener(TransmitterServiceEvent.LAST_BGREADING_RECEIVED, onBgReadingReceivedMaster);
			NightscoutService.instance.removeEventListener(FollowerEvent.BG_READING_RECEIVED, onBgReadingReceivedFollower);
			
			if (bolusWizardCallout != null)
			{
				bolusWizardCallout.close();
			}
			
			if(bwExtendedBolusSoundAccessoriesList != null && bwExtendedBolusSoundAccessoriesList.length > 0)
			{
				var length:int = bwExtendedBolusSoundAccessoriesList.length;
				for (var i:int = 0; i < length; i++) 
				{
					var btn:Button = bwExtendedBolusSoundAccessoriesList[i] as Button;
					if (btn != null)
					{
						btn.removeEventListener(Event.TRIGGERED, onPlaySound);
						btn.removeFromParent();
						if (btn.defaultIcon != null)
						{
							(btn.defaultIcon as Image).texture.dispose();
							btn.defaultIcon.dispose();
						}
						btn.dispose();
						btn = null;
					}
				}
				bwExtendedBolusSoundAccessoriesList.length = 0;
				bwExtendedBolusSoundAccessoriesList = null;
			}
			
			if (bwFoodManager != null)
			{
				bwFoodManager.removeEventListener(Event.COMPLETE, onFoodManagerCompleted);
				bwFoodManager.removeFromParent();
				bwFoodManager.dispose()
				bwFoodManager = null;
			}
			
			if (calloutPositionHelper != null)
			{
				calloutPositionHelper.removeFromParent();
				calloutPositionHelper.dispose();
				calloutPositionHelper = null;
			}
			
			if (bwGlucoseLabel != null)
			{
				bwGlucoseLabel.removeFromParent();
				bwGlucoseLabel.dispose();
				bwGlucoseLabel = null;
			}
			
			if (bwGlucoseStepper != null)
			{
				bwGlucoseStepper.removeEventListener(Event.CHANGE, delayCalculations);
				bwGlucoseStepper.removeFromParent();
				bwGlucoseStepper.dispose();
				bwGlucoseStepper = null;
			}
			
			if (bwTitle != null)
			{
				bwTitle.removeFromParent();
				bwTitle.dispose();
				bwTitle = null;
			}
			
			if (bolusWizardCancelButton != null)
			{
				bolusWizardCancelButton.removeEventListener(Event.TRIGGERED, onCloseCallout);
				bolusWizardCancelButton.removeFromParent();
				bolusWizardCancelButton.dispose();
				bolusWizardCancelButton = null;
			}
			
			if (bolusWizardAddButton != null)
			{
				bolusWizardAddButton.removeEventListener(Event.TRIGGERED, onAddBolusWizardTreatment);
				bolusWizardAddButton.removeFromParent();
				bolusWizardAddButton.dispose();
				bolusWizardAddButton = null;
			}
			
			if (bwGlucoseCheck != null)
			{
				bwGlucoseCheck.removeEventListener(Event.CHANGE, performCalculations);
				bwGlucoseCheck.removeFromParent();
				bwGlucoseCheck.dispose();
				bwGlucoseCheck = null;
			}
			
			if (bwIOBLabel != null)
			{
				bwIOBLabel.removeFromParent();
				bwIOBLabel.dispose();
				bwIOBLabel = null;
			}
			
			if (bwCurrentIOBLabel != null)
			{
				bwCurrentIOBLabel.removeFromParent();
				bwCurrentIOBLabel.dispose();
				bwCurrentIOBLabel = null;
			}
			
			if (bwCOBLabel != null)
			{
				bwCOBLabel.removeFromParent();
				bwCOBLabel.dispose();
				bwCOBLabel = null;
			}
			
			if (bwCurrentCOBLabel != null)
			{
				bwCurrentCOBLabel.removeFromParent();
				bwCurrentCOBLabel.dispose();
				bwCurrentCOBLabel = null;
			}
			
			if (bwCarbsCheck != null)
			{
				bwCarbsCheck.removeEventListener(Event.CHANGE, onShowHideCarbExtras);
				bwCarbsCheck.removeFromParent();
				bwCarbsCheck.dispose();
				bwCarbsCheck = null;
			}
			
			if (bwCarbsLabel != null)
			{
				bwCarbsLabel.removeFromParent();
				bwCarbsLabel.dispose();
				bwCarbsLabel = null;
			}
			
			if (bwCarbsStepper != null)
			{
				bwCarbsStepper.removeEventListener(Event.CHANGE, delayCalculations);
				bwCarbsStepper.removeFromParent();
				bwCarbsStepper.dispose();
				bwCarbsStepper = null;
			}
		
			if (bwCarbTypeLabel != null)
			{
				bwCarbTypeLabel.removeFromParent();
				bwCarbTypeLabel.dispose();
				bwCarbTypeLabel = null;
			}
			
			if (bwCarbsOffsetLabel != null)
			{
				bwCarbsOffsetLabel.removeFromParent();
				bwCarbsOffsetLabel.dispose();
				bwCarbsOffsetLabel = null;
			}
			
			if (bwCarbsOffsetStepper != null)
			{
				bwCarbsOffsetStepper.removeFromParent();
				bwCarbsOffsetStepper.dispose();
				bwCarbsOffsetStepper = null;
			}
			
			if (bwCarbTypePicker != null)
			{
				bwCarbTypePicker.removeEventListener(Event.CHANGE, onCarbTypeChanged);
				bwCarbTypePicker.removeFromParent();
				bwCarbTypePicker.dispose();
				bwCarbTypePicker = null;
			}
			
			if (bwOtherCorrectionLabel != null)
			{
				bwOtherCorrectionLabel.removeFromParent();
				bwOtherCorrectionLabel.dispose();
				bwOtherCorrectionLabel = null;
			}
			
			if (bwOtherCorrectionAmountStepper != null)
			{
				bwOtherCorrectionAmountStepper.removeEventListener(Event.CHANGE, delayCalculations);
				bwOtherCorrectionAmountStepper.removeFromParent();
				bwOtherCorrectionAmountStepper.dispose();
				bwOtherCorrectionAmountStepper = null;
			}
			
			if (bwIOBCheck != null)
			{
				bwIOBCheck.removeEventListener(Event.CHANGE, performCalculations);
				bwIOBCheck.removeFromParent();
				bwIOBCheck.dispose();
				bwIOBCheck = null;
			}
			
			if (bwCOBCheck != null)
			{
				bwCOBCheck.removeEventListener(Event.CHANGE, performCalculations);
				bwCOBCheck.removeFromParent();
				bwCOBCheck.dispose();
				bwCOBCheck = null;
			}
			
			if (bwNotes != null)
			{
				bwNotes.removeFromParent();
				bwNotes.dispose();
				bwNotes = null;
			}
			
			if (bwSuggestionLabel != null)
			{
				bwSuggestionLabel.removeFromParent();
				bwSuggestionLabel.dispose();
				bwSuggestionLabel = null;
			}
			
			if (missedSettingsTitle != null)
			{
				missedSettingsTitle.removeFromParent();
				missedSettingsTitle.dispose();
				missedSettingsTitle = null;
			}
			
			if (missedSettingsLabel != null)
			{
				missedSettingsLabel.removeFromParent();
				missedSettingsLabel.dispose();
				missedSettingsLabel = null;
			}
			
			if (missedSettingsCancelButton != null)
			{
				missedSettingsCancelButton.removeEventListener(Event.TRIGGERED, onCloseConfigureCallout);
				missedSettingsCancelButton.removeFromParent();
				missedSettingsCancelButton.dispose();
				missedSettingsCancelButton = null;
			}
			
			if (missedSettingsConfigureButton != null)
			{
				missedSettingsConfigureButton.removeEventListener(Event.TRIGGERED, onPerformConfiguration);
				missedSettingsConfigureButton.removeFromParent();
				missedSettingsConfigureButton.dispose();
				missedSettingsConfigureButton = null;
			}
			
			if (bwSicknessCheck != null)
			{
				bwSicknessCheck.removeEventListener(Event.CHANGE, onShowHideSicknessAdjustment);
				bwSicknessCheck.removeFromParent();
				bwSicknessCheck.dispose();
				bwSicknessCheck = null;
			}
			
			if (bwSicknessLabel != null)
			{
				bwSicknessLabel.removeFromParent();
				bwSicknessLabel.dispose();
				bwSicknessLabel = null;
			}
			
			if (bwSicknessAmountStepper != null)
			{
				bwSicknessAmountStepper.removeEventListener(Event.CHANGE, delayCalculations);
				bwSicknessAmountStepper.removeFromParent();
				bwSicknessAmountStepper.dispose();
				bwSicknessAmountStepper = null;
			}
			
			if (bwSicknessAmountLabel != null)
			{
				bwSicknessAmountLabel.removeFromParent();
				bwSicknessAmountLabel.dispose();
				bwSicknessAmountLabel = null;
			}
			
			if (bwExerciseCheck != null)
			{
				bwExerciseCheck.removeEventListener(Event.CHANGE, onShowHideExerciseAdjustment);
				bwExerciseCheck.removeFromParent();
				bwExerciseCheck.dispose();
				bwExerciseCheck = null;
			}
			
			if (bwExerciseLabel != null)
			{
				bwExerciseLabel.removeFromParent();
				bwExerciseLabel.dispose();
				bwExerciseLabel = null;
			}
			
			if (bwExerciseTimeLabel != null)
			{
				bwExerciseTimeLabel.removeFromParent();
				bwExerciseTimeLabel.dispose();
				bwExerciseTimeLabel = null;
			}
			
			if (bwExerciseTimePicker != null)
			{
				bwExerciseTimePicker.removeEventListener(Event.CHANGE, onExerciseTimeChanged);
				bwExerciseTimePicker.removeFromParent();
				bwExerciseTimePicker.dispose();
				bwExerciseTimePicker = null;
			}
			
			if (bwExerciseIntensityLabel != null)
			{
				bwExerciseIntensityLabel.removeFromParent();
				bwExerciseIntensityLabel.dispose();
				bwExerciseIntensityLabel = null;
			}
			
			if (bwExerciseIntensityPicker != null)
			{
				bwExerciseIntensityPicker.removeEventListener(Event.CHANGE, onExerciseIntensityChanged);
				bwExerciseIntensityPicker.removeFromParent();
				bwExerciseIntensityPicker.dispose();
				bwExerciseIntensityPicker = null;
			}
			
			if (bwExerciseDurationLabel != null)
			{
				bwExerciseDurationLabel.removeFromParent();
				bwExerciseDurationLabel.dispose();
				bwExerciseDurationLabel = null;
			}
			
			if (bwExerciseDurationPicker != null)
			{
				bwExerciseDurationPicker.removeEventListener(Event.CHANGE, onExerciseDurationChanged);
				bwExerciseDurationPicker.removeFromParent();
				bwExerciseDurationPicker.dispose();
				bwExerciseDurationPicker = null;
			}
			
			if (bwExerciseAmountLabel != null)
			{
				bwExerciseAmountLabel.removeFromParent();
				bwExerciseAmountLabel.dispose();
				bwExerciseAmountLabel = null;
			}
			
			if (bwExerciseAmountStepper != null)
			{
				bwExerciseAmountStepper.removeEventListener(Event.CHANGE, delayCalculations);
				bwExerciseAmountStepper.removeFromParent();
				bwExerciseAmountStepper.dispose();
				bwExerciseAmountStepper = null;
			}
			
			if (bwOtherCorrectionCheck != null)
			{
				bwOtherCorrectionCheck.removeEventListener(Event.CHANGE, onShowHideOtherCorrection);
				bwOtherCorrectionCheck.removeEventListener(Event.CHANGE, performCalculations);
				bwOtherCorrectionCheck.removeFromParent();
				bwOtherCorrectionCheck.dispose();
				bwOtherCorrectionCheck = null;
			}
			
			if (bwOtherCorrectionAmountLabel != null)
			{
				bwOtherCorrectionAmountLabel.removeFromParent();
				bwOtherCorrectionAmountLabel.dispose();
				bwOtherCorrectionAmountLabel = null;
			}
			
			if (bwTrendCheck != null)
			{
				bwTrendCheck.removeEventListener(Event.CHANGE, performCalculations);
				bwTrendCheck.removeFromParent();
				bwTrendCheck.dispose();
				bwTrendCheck = null;
			}
			
			if (bwTrendLabel != null)
			{
				bwTrendLabel.removeFromParent();
				bwTrendLabel.dispose();
				bwTrendLabel = null;
			}
			
			if (bwCurrentTrendLabel != null)
			{
				bwCurrentTrendLabel.removeFromParent();
				bwCurrentTrendLabel.dispose();
				bwCurrentTrendLabel = null;
			}
			
			if (bwFoodsLabel != null)
			{
				bwFoodsLabel.removeFromParent();
				bwFoodsLabel.dispose();
				bwFoodsLabel = null;
			}
			
			if (bwFoodLoaderButton != null)
			{
				bwFoodLoaderButton.removeEventListener(Event.TRIGGERED, onShowFoodManager);
				bwFoodLoaderButton.removeFromParent();
				bwFoodLoaderButton.dispose();
				bwFoodLoaderButton = null;
			}
			
			if (bwFoodManager != null)
			{
				bwFoodManager.removeFromParent();
				bwFoodManager.dispose();
				bwFoodManager = null;
			}
			
			if (bwInsulinTypeLabel != null)
			{
				bwInsulinTypeLabel.removeFromParent();
				bwInsulinTypeLabel.dispose();
				bwInsulinTypeLabel = null;
			}
			
			if (bwInsulinTypePicker != null)
			{
				bwInsulinTypePicker.removeFromParent();
				bwInsulinTypePicker.dispose();
				bwInsulinTypePicker = null;
			}
			
			if (createInsulinButton != null)
			{
				createInsulinButton.removeEventListeners();
				createInsulinButton.removeFromParent();
				createInsulinButton.dispose();
				createInsulinButton = null;
			}
			
			if (bwExtendedBolusReminderCheck != null)
			{
				bwExtendedBolusReminderCheck.removeEventListener(Event.CHANGE, onShowHideExtendedBolusReminder);
				bwExtendedBolusReminderCheck.removeFromParent();
				bwExtendedBolusReminderCheck.dispose();
				bwExtendedBolusReminderCheck = null;
			}
			
			if (bwExtendedBolusReminderLabel != null)
			{
				bwExtendedBolusReminderLabel.removeFromParent();
				bwExtendedBolusReminderLabel.dispose();
				bwExtendedBolusReminderLabel = null;
			}
			
			if (bwExtendedBolusReminderDateTimeSpinner != null)
			{
				bwExtendedBolusReminderDateTimeSpinner.removeFromParent();
				bwExtendedBolusReminderDateTimeSpinner.dispose();
				bwExtendedBolusReminderDateTimeSpinner = null;
			}
			
			if (bwExtendedBolusSoundList != null)
			{
				bwExtendedBolusSoundList.removeEventListener(Event.CLOSE, onSoundListClose);
				bwExtendedBolusSoundList.removeFromParent();
				bwExtendedBolusSoundList.dispose();
				bwExtendedBolusSoundList = null;
			}
			
			if (bwFinalCalculatedInsulinLabel != null)
			{
				bwFinalCalculatedInsulinLabel.removeFromParent();
				bwFinalCalculatedInsulinLabel.dispose();
				bwFinalCalculatedInsulinLabel = null;
			}
			
			if (bwFinalCalculatedInsulinStepper != null)
			{
				bwFinalCalculatedInsulinStepper.removeEventListener(Event.CHANGE, onFinalTreatmentChanged);
				bwFinalCalculatedInsulinStepper.removeFromParent();
				bwFinalCalculatedInsulinStepper.dispose();
				bwFinalCalculatedInsulinStepper = null;
			}
			
			if (bwFinalCalculatedCarbsLabel != null)
			{
				bwFinalCalculatedCarbsLabel.removeFromParent();
				bwFinalCalculatedCarbsLabel.dispose();
				bwFinalCalculatedCarbsLabel = null;
			}
			
			if (bwFinalCalculatedCarbsStepper != null)
			{
				bwFinalCalculatedCarbsStepper.removeEventListener(Event.CHANGE, onFinalTreatmentChanged);
				bwFinalCalculatedCarbsStepper.removeFromParent();
				bwFinalCalculatedCarbsStepper.dispose();
				bwFinalCalculatedCarbsStepper = null;
			}
			
			if (finalCalculationsLabel != null)
			{
				finalCalculationsLabel.removeFromParent();
				finalCalculationsLabel.dispose();
				finalCalculationsLabel = null;
			}
			
			if (missedSettingsActionsContainer != null)
			{
				missedSettingsActionsContainer.removeFromParent();
				missedSettingsActionsContainer.dispose();
				missedSettingsActionsContainer = null;
			}
			
			if (missedSettingsContainer != null)
			{
				missedSettingsContainer.removeFromParent();
				missedSettingsContainer.dispose();
				missedSettingsContainer = null;
			}
			
			if (bolusWizardActionContainer != null)
			{
				bolusWizardActionContainer.removeFromParent();
				bolusWizardActionContainer.dispose();
				bolusWizardActionContainer = null;
			}
			
			if (bolusWizardConfigureCallout != null)
			{
				bolusWizardConfigureCallout.removeFromParent();
				bolusWizardConfigureCallout.disposeContent = true;
				bolusWizardConfigureCallout.dispose();
				bolusWizardConfigureCallout = null;
			}
			
			if (bwFinalCalculatedCarbsContainer != null)
			{
				bwFinalCalculatedCarbsContainer.removeFromParent();
				bwFinalCalculatedCarbsContainer.dispose();
				bwFinalCalculatedCarbsContainer = null;
			}
			
			if (bwFinalCalculatedInsulinContainer != null)
			{
				bwFinalCalculatedInsulinContainer.removeFromParent();
				bwFinalCalculatedInsulinContainer.dispose();
				bwFinalCalculatedInsulinContainer = null;
			}
			
			if (bwFinalCalculationsContainer != null)
			{
				bwFinalCalculationsContainer.removeFromParent();
				bwFinalCalculationsContainer.dispose();
				bwFinalCalculationsContainer = null;
			}
			
			if (bwExtendedBolusSoundListContainer != null)
			{
				bwExtendedBolusSoundListContainer.removeFromParent();
				bwExtendedBolusSoundListContainer.dispose();
				bwExtendedBolusSoundListContainer = null;
			}
			
			if (bwExtendedBolusReminderDateTimeContainer != null)
			{
				bwExtendedBolusReminderDateTimeContainer.removeFromParent();
				bwExtendedBolusReminderDateTimeContainer.dispose();
				bwExtendedBolusReminderDateTimeContainer = null;
			}
			
			if (bwExtendedBolusReminderLabelContainer != null)
			{
				bwExtendedBolusReminderLabelContainer.removeFromParent();
				bwExtendedBolusReminderLabelContainer.dispose();
				bwExtendedBolusReminderLabelContainer = null;
			}
			
			if (bwExtendedBolusReminderContainer != null)
			{
				bwExtendedBolusReminderContainer.removeFromParent();
				bwExtendedBolusReminderContainer.dispose();
				bwExtendedBolusReminderContainer = null;
			}
			
			if (bwOtherCorrectionAmountContainer != null)
			{
				bwOtherCorrectionAmountContainer.removeFromParent();
				bwOtherCorrectionAmountContainer.dispose();
				bwOtherCorrectionAmountContainer = null;
			}
			
			if (bwOtherCorrectionLabelContainer != null)
			{
				bwOtherCorrectionLabelContainer.removeFromParent();
				bwOtherCorrectionLabelContainer.dispose();
				bwOtherCorrectionLabelContainer = null;
			}
			
			if (bwOtherCorrectionContainer != null)
			{
				bwOtherCorrectionContainer.removeFromParent();
				bwOtherCorrectionContainer.dispose();
				bwOtherCorrectionContainer = null;
			}
			
			if (bwSicknessAmountContainer != null)
			{
				bwSicknessAmountContainer.removeFromParent();
				bwSicknessAmountContainer.dispose();
				bwSicknessAmountContainer = null;
			}
			
			if (bwSicknessLabelContainer != null)
			{
				bwSicknessLabelContainer.removeFromParent();
				bwSicknessLabelContainer.dispose();
				bwSicknessLabelContainer = null;
			}
			
			if (bwSicknessContainer != null)
			{
				bwSicknessContainer.removeFromParent();
				bwSicknessContainer.dispose();
				bwSicknessContainer = null;
			}
			
			if (bwExerciseAmountContainer != null)
			{
				bwExerciseAmountContainer.removeFromParent();
				bwExerciseAmountContainer.dispose();
				bwExerciseAmountContainer = null;
			}
			
			if (bwExerciseDurationContainer != null)
			{
				bwExerciseDurationContainer.removeFromParent();
				bwExerciseDurationContainer.dispose();
				bwExerciseDurationContainer = null;
			}
			
			if (bwExerciseIntensityContainer != null)
			{
				bwExerciseIntensityContainer.removeFromParent();
				bwExerciseIntensityContainer.dispose();
				bwExerciseIntensityContainer = null;
			}
			
			if (bwExerciseTimeContainer != null)
			{
				bwExerciseTimeContainer.removeFromParent();
				bwExerciseTimeContainer.dispose();
				bwExerciseTimeContainer = null;
			}
			
			if (bwExerciseSettingsContainer != null)
			{
				bwExerciseSettingsContainer.removeFromParent();
				bwExerciseSettingsContainer.dispose();
				bwExerciseSettingsContainer = null;
			}
			
			if (bwExerciseLabelContainer != null)
			{
				bwExerciseLabelContainer.removeFromParent();
				bwExerciseLabelContainer.dispose();
				bwExerciseLabelContainer = null;
			}
			
			if (bwExerciseContainer != null)
			{
				bwExerciseContainer.removeFromParent();
				bwExerciseContainer.dispose();
				bwExerciseContainer = null;
			}
			
			if (bwCOBLabelContainer != null)
			{
				bwCOBLabelContainer.removeFromParent();
				bwCOBLabelContainer.dispose();
				bwCOBLabelContainer = null;
			}
			
			if (bwCOBContainer != null)
			{
				bwCOBContainer.removeFromParent();
				bwCOBContainer.dispose();
				bwCOBContainer = null;
			}
			
			if (bwIOBLabelContainer != null)
			{
				bwIOBLabelContainer.removeFromParent();
				bwIOBLabelContainer.dispose();
				bwIOBLabelContainer = null;
			}
			
			if (bwIOBContainer != null)
			{
				bwIOBContainer.removeFromParent();
				bwIOBContainer.dispose();
				bwIOBContainer = null;
			}
			
			if (bwTrendLabelContainer != null)
			{
				bwTrendLabelContainer.removeFromParent();
				bwTrendLabelContainer.dispose();
				bwTrendLabelContainer = null;
			}
			
			if (bwTrendContainer != null)
			{
				bwTrendContainer.removeFromParent();
				bwTrendContainer.dispose();
				bwTrendContainer = null;
			}
			
			if (bwInsulinTypeContainer != null)
			{
				bwInsulinTypeContainer.removeFromParent();
				bwInsulinTypeContainer.dispose();
				bwInsulinTypeContainer = null;
			}
			
			if (bwCarbTypeContainer != null)
			{
				bwCarbTypeContainer.removeFromParent();
				bwCarbTypeContainer.dispose();
				bwCarbTypeContainer = null;
			}
			
			if (bwCarbsOffsetContainer != null)
			{
				bwCarbsOffsetContainer.removeFromParent();
				bwCarbsOffsetContainer.dispose();
				bwCarbsOffsetContainer = null;
			}
			
			if (bwFoodsContainer != null)
			{
				bwFoodsContainer.removeFromParent();
				bwFoodsContainer.dispose();
				bwFoodsContainer = null;
			}
			
			if (bwCarbsLabelContainer != null)
			{
				bwCarbsLabelContainer.removeFromParent();
				bwCarbsLabelContainer.dispose();
				bwCarbsLabelContainer = null;
			}
			
			if (bwCarbsContainer != null)
			{
				bwCarbsContainer.removeFromParent();
				bwCarbsContainer.dispose();
				bwCarbsContainer = null;
			}
			
			if (bwGlucoseLabelContainer != null)
			{
				bwGlucoseLabelContainer.removeFromParent();
				bwGlucoseLabelContainer.dispose();
				bwGlucoseLabelContainer = null;
			}
			
			if (bwCurrentGlucoseContainer != null)
			{
				bwCurrentGlucoseContainer.removeFromParent();
				bwCurrentGlucoseContainer.dispose();
				bwCurrentGlucoseContainer = null;
			}
			
			if (bwMainContainer != null)
			{
				bwMainContainer.removeFromParent();
				bwMainContainer.dispose();
				bwMainContainer = null;
			}
			
			if (bwWizardScrollContainer != null)
			{
				bwWizardScrollContainer.removeFromParent();
				bwWizardScrollContainer.dispose();
				bwWizardScrollContainer = null;
			}
			
			if (bwTotalScrollContainer != null)
			{
				bwTotalScrollContainer.removeFromParent();
				bwTotalScrollContainer.dispose();
				bwTotalScrollContainer = null;
			}
			
			if (bolusWizardCallout != null)
			{
				bolusWizardCallout.disposeContent = true;
				bolusWizardCallout.disposeOnSelfClose = true;
				bolusWizardCallout.dispose();
				bolusWizardCallout = null;
			}
		}
	}
}