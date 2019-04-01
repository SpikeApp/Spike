package ui.chart
{ 
	import com.distriqt.extension.networkinfo.NetworkInfo;
	import com.spikeapp.spike.airlibrary.SpikeANE;
	
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.system.Capabilities;
	import flash.system.System;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	import flash.utils.clearTimeout;
	import flash.utils.getTimer;
	import flash.utils.setTimeout;
	
	import database.BgReading;
	import database.CGMBlueToothDevice;
	import database.Calibration;
	import database.CommonSettings;
	
	import events.CalibrationServiceEvent;
	import events.PredictionEvent;
	import events.SpikeEvent;
	import events.UserInfoEvent;
	
	import feathers.controls.Button;
	import feathers.controls.Callout;
	import feathers.controls.Check;
	import feathers.controls.DateTimeMode;
	import feathers.controls.DateTimeSpinner;
	import feathers.controls.DragGesture;
	import feathers.controls.Label;
	import feathers.controls.LayoutGroup;
	import feathers.controls.PickerList;
	import feathers.controls.ScrollBarDisplayMode;
	import feathers.controls.ScrollContainer;
	import feathers.controls.ScrollPolicy;
	import feathers.controls.ToggleSwitch;
	import feathers.controls.popups.DropDownPopUpContentManager;
	import feathers.core.FeathersControl;
	import feathers.data.ArrayCollection;
	import feathers.extensions.MaterialDesignSpinner;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.HorizontalLayout;
	import feathers.layout.RelativePosition;
	import feathers.layout.VerticalAlign;
	import feathers.layout.VerticalLayout;
	import feathers.motion.Cover;
	import feathers.motion.Reveal;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.Forecast;
	import model.ModelLocator;
	
	import services.CalibrationService;
	import services.NightscoutService;
	
	import starling.animation.Transitions;
	import starling.animation.Tween;
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.Image;
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.filters.BlurFilter;
	import starling.filters.FilterChain;
	import starling.filters.GlowFilter;
	import starling.utils.Align;
	import starling.utils.SystemUtil;
	
	import treatments.Insulin;
	import treatments.Profile;
	import treatments.ProfileManager;
	import treatments.Treatment;
	import treatments.TreatmentsManager;
	
	import ui.AppInterface;
	import ui.InterfaceController;
	import ui.chart.helpers.GlucoseFactory;
	import ui.chart.layout.GraphLayoutFactory;
	import ui.chart.markers.BGCheckMarker;
	import ui.chart.markers.CarbsMarker;
	import ui.chart.markers.ExerciseMarker;
	import ui.chart.markers.GlucoseMarker;
	import ui.chart.markers.InsulinCartridgeMarker;
	import ui.chart.markers.InsulinMarker;
	import ui.chart.markers.MealMarker;
	import ui.chart.markers.NoteMarker;
	import ui.chart.markers.PumpBatteryMarker;
	import ui.chart.markers.PumpSiteMarker;
	import ui.chart.markers.SensorMarker;
	import ui.chart.pills.ChartComponentPill;
	import ui.chart.pills.ChartInfoPill;
	import ui.chart.pills.ChartTreatmentPill;
	import ui.chart.visualcomponents.COBCurve;
	import ui.chart.visualcomponents.ChartTreatment;
	import ui.chart.visualcomponents.IOBActivityCurve;
	import ui.popups.AlertManager;
	import ui.screens.Screens;
	import ui.screens.display.LayoutFactory;
	import ui.shapes.SpikeLine;
	
	import utils.Constants;
	import utils.DeviceInfo;
	import utils.GlucoseHelper;
	import utils.MathHelper;
	import utils.TimeSpan;
	
	[ResourceBundle("chartscreen")]
	[ResourceBundle("treatments")]
	[ResourceBundle("globaltranslations")]
	
	public class GlucoseChart extends Sprite
	{
		//Constants
		private static const MAIN_CHART:String = "mainChart";
		private static const SCROLLER_CHART:String = "scrollerChart";
		private static var NUM_MINUTES_MISSED_READING_GAP:int = 6;
		public static const TIMELINE_1H:Number = 14;
		public static const TIMELINE_3H:Number = 8;
		public static const TIMELINE_6H:Number = 4;
		public static const TIMELINE_12H:Number = 2;
		public static const TIMELINE_24H:Number = 1;
		
		//Data
		private var _dataSource:Array;
		private var mainChartGlucoseMarkersList:Array;
		private var scrollChartGlucoseMarkersList:Array;
		private var rawGlucoseMarkersList:Array;
		private var mainChartLineList:Array;
		private var rawLineList:Array;
		private var scrollerChartLineList:Array;
		private var lastBGreadingTimeStamp:Number;
		private var firstBGReadingTimeStamp:Number;
		
		//Visual Settings
		private var _graphWidth:Number;
		private var _graphHeight:Number;
		private var timelineRange:int;
		private var _scrollerWidth:Number;
		private var _scrollerHeight:Number;
		private var lowestGlucoseValue:Number = 1000;
		private var highestGlucoseValue:Number = 0;
		private var scaleYFactor:Number;
		private var lineColor:uint = 0xEEEEEE;
		private var chartFontColor:uint = 0xEEEEEE;
		private var axisFontColor:uint = 0xEEEEEE;
		private var oldColor:uint = 0xABABAB;
		private var newColor:uint = 0xEEEEEE;
		private var highUrgentGlucoseMarkerColor:uint;
		private var highGlucoseMarkerColor:uint;
		private var inrangeGlucoseMarkerColor:uint;
		private var lowGlucoseMarkerColor:uint;
		private var lowUrgentGlucoseMarkerColor:uint;
		private var dashLineWidth:int = 3;
		private var dashLineGap:int = 1;
		private var dashLineThickness:int = 1;
		private var yAxisMargin:int = 40;
		private var mainChartGlucoseMarkerRadius:int;
		private var scrollerChartGlucoseMarkerRadius:int = 1;
		private var lineThickness:int = 3;
		private var legendMargin:int = 2.5;
		private var legendSize:int = 10;
		private var legendTextSize:int = 12;
		private var graphDisplayTextSize:int = 20;
		private var glucoseUnit:String = "mg/dL";
		private var handPickerStrokeThickness:int = 1;
		private var chartTopPadding:int = 90;
		private var scrollerTopPadding:int = 5;
		private var _displayLine:Boolean = false;
		private var fakeChartMaskColor:uint = 0x20222a;
		private var glucoseStatusLabelsMargin:int = 5;
		private var retroOutput:String;
		private var userBGFontMultiplier:Number;
		private var userTimeAgoFontMultiplier:Number;
		private var userAxisFontMultiplier:Number;
		private var dateFormat:String;
		private var dummyModeActive:Boolean = false;
		private var handPickerWidth:Number;
		private var glucoseDisplayFont:Number;
		private var deviceFontMultiplier:Number;
		private var timeDisplayFont:Number;
		private var retroDisplayFont:Number;
		private var labelsYPos:Number;
		private var displayTargetLine:Boolean;
		private var displayUrgentHighLine:Boolean;
		private var displayHighLine:Boolean;
		private var displayLowLine:Boolean;
		private var displayUrgentLowLine:Boolean;
		private var targetLineColor:uint;
		private var glucoseLineThickness:Number = 1;
		
		//Display Objects
		private var glucoseTimelineContainer:Sprite;
		private var mainChart:Sprite;
		private var glucoseDelimiter:SpikeLine;
		private var scrollerChart:Sprite;
		private var handPicker:Sprite;
		private var glucoseValueDisplay:Label;
		private var yAxisContainer:Sprite;
		private var mainChartContainer:Sprite;
		private var differenceInMinutesForAllTimestamps:Number;
		private var mainChartMask:Quad;
		private var dummySprite:Sprite;
		private var scrollerBackground:Quad;
		private var handPickerFill:Quad;
		private var handpickerOutline:SpikeLine;
		private var yAxisLine:SpikeLine;
		private var highestGlucoseLineMarker:SpikeLine;
		private var highestGlucoseLegend:Label;
		private var lowestGlucoseLineMarker:SpikeLine;
		private var lowestGlucoseLegend:Label;
		private var highUrgentGlucoseLineMarker:SpikeLine;
		private var highUrgentGlucoseDashedLine:SpikeLine;
		private var highGlucoseLineMarker:SpikeLine;
		private var highGlucoseLegend:Label;
		private var highGlucoseDashedLine:SpikeLine;
		private var lowGlucoseLineMarker:SpikeLine;
		private var lowGlucoseLegend:Label;
		private var lowGlucoseDashedLine:SpikeLine;
		private var lowUrgentGlucoseLineMarker:SpikeLine;
		private var lowUrgentGlucoseLegend:Label;
		private var lowUrgentGlucoseDashedLine:SpikeLine;
		private var targetGlucoseLineMarker:SpikeLine;
		private var targetGlucoseLegend:Label;
		private var targetGlucoseDashedLine:SpikeLine;
		private var yAxis:Sprite;
		private var xRightMask:Quad;
		private var xLeftMask:Quad;
		private var mainChartLine:SpikeLine;
		private var scrollerChartLine:SpikeLine;
		
		//Objects
		private var statusUpdateTimer:Timer;
		
		//Glucose Thresholds
		private var glucoseUrgentHigh:Number;
		private var glucoseHigh:Number;
		private var glucoseLow:Number;
		private var glucoseUrgentLow:Number;
		private var currentUserBGTarget:Number = Number.NaN;
		
		//Movement
		private var scrollMultiplier:Number;
		private var mainChartXFactor:Number;
		private var mainChartYFactor:Number;
		private var displayLatestBGValue:Boolean = true;
		private var selectedGlucoseMarkerIndex:int;
		
		//Display Update Helpers
		private var previousNumberOfMakers:int = 0;
		private var currentNumberOfMakers:int = 0;
		
		//Chart Scale mode
		private var fixedSize:Boolean = false;
		private var maxAxisValue:Number = 400;
		private var minAxisValue:Number = 40;
		private var resizeOutOfBounds:Boolean = true;
		
		//Timeline
		private var timelineFirstRun:Boolean = true;
		private var timelineActive:Boolean = true;
		private var timelineContainer:Sprite;
		private var timelineObjects:Array = [];
		
		//Treatments Variables
		private var treatmentsFirstRun:Boolean = true;
		private var treatmentsActive:Boolean = true;
		private var treatmentsList:Array = [];
		private var treatmentsMap:Dictionary = new Dictionary();
		private var ago:String;
		private var now:String;
		private var yAxisHeight:Number = 0;
		private var allTreatmentsAdded:Boolean = false;
		private var displayTreatmentsOnChart:Boolean = false;
		private var displayCOBEnabled:Boolean = false;
		private var displayIOBEnabled:Boolean = false;
		private var totalIOBTimeoutID:int = -1;
		private var totalCOBTimeoutID:int = -1;
		
		//Treatments Display Objects
		private var treatmentsContainer:Sprite;
		private var treatmentCallout:Callout;
		private var IOBPill:ChartTreatmentPill;
		private var glucoseSlopePill:ChartInfoPill;
		private var glucoseTimeAgoPill:ChartInfoPill;
		private var COBPill:ChartTreatmentPill;
		private var treatmentContainer:LayoutGroup;
		private var treatmentValueLabel:Label;
		private var treatmentTimeSpinner:DateTimeSpinner;
		private var timeSpacer:Sprite;
		private var treatmentNoteLabel:Label;
		private var actionsContainer:LayoutGroup;
		private var moveBtn:Button;
		private var deleteBtn:Button;
		
		//User Info
		private var infoPill:ChartTreatmentPill;
		private var infoContainer:ScrollContainer;
		private var infoCallout:Callout;
		private var basalPill:ChartTreatmentPill;
		private var rawPill:ChartTreatmentPill;
		private var upBatteryPill:ChartTreatmentPill;
		private var openAPSMomentPill:ChartTreatmentPill;
		private var pumpBatteryPill:ChartTreatmentPill;
		private var pumpReservoirPill:ChartTreatmentPill;
		private var userInfoPreloader:MaterialDesignSpinner;
		private var pumpStatusPill:ChartTreatmentPill;
		private var pumpTimePill:ChartTreatmentPill;
		private var cagePill:ChartTreatmentPill;
		private var loopMomentPill:ChartTreatmentPill;
		private var sagePill:ChartTreatmentPill;
		private var sensorNoisePill:ChartTreatmentPill;
		private var iagePill:ChartTreatmentPill;
		private var tBatteryPill:ChartTreatmentPill;
		private var userInfoErrorLabel:Label;
		private var spikeMasterPhoneBatteryPill:ChartTreatmentPill;
		private var spikeMasterTransmitterBatteryPill:ChartTreatmentPill;
		private var bagePill:ChartTreatmentPill;
		private var localBAGEAdded:Boolean = false;
		private var localIAGEAdded:Boolean = false;
		private var localCAGEAdded:Boolean = false;
		private var isDexcomFollower:Boolean = false;
		
		//Absorption curves
		private var insulinCurveCallout:Callout;
		private var iobActivityCurve:IOBActivityCurve;
		private var carbsCurveCallout:Callout;
		private var cobCurve:COBCurve;
		
		//Historial Data
		private var isHistoricalData:Boolean;
		
		//Main Glucose Touch
		private var mainGlucoseTimer:Number = Number.NaN;
		
		//RAW
		private var rawDataContainer:Sprite;
		private var displayRaw:Boolean = false;
		private var rawColor:uint;
		
		//Predictions
		private var predictionsEnabled:Boolean;
		private var predictionsLengthInMinutes:int = 60;
		private var predictionsMainGlucoseDataPoints:Array = [];
		private var predictionsScrollerGlucoseDataPoints:Array = [];
		private var headerProperties:Object;
		private var predictionsColor:uint = 0xEF00E7;
		private var predictionsDelimiter:SpikeLine;
		private var activeGlucoseDelimiter:SpikeLine;
		private var redrawPredictionsTimeoutID:int = -1;
		private var lastPredictionsRedrawTimestamp:Number = 0;
		private var algorithmIOBCOB:String;
		private var latestOpenAPSRequestedCOBTimestamp:Number = 0;
		private var predictedEventualBG:Number = Number.NaN;
		private var predictedBGImpact:Number = Number.NaN;
		private var predictedDeviation:Number = Number.NaN;
		private var predictedCarbImpact:Number = Number.NaN;
		private var predictedTimeUntilHigh:Number = Number.NaN;
		private var predictedTimeUntilLow:Number = Number.NaN;
		private var predictedMinimumBG:Number = Number.NaN;
		private var predictedIOBBG:Number = Number.NaN;
		private var predictedUAMBG:Number = Number.NaN;
		private var predictedCOBBG:Number = Number.NaN;
		private var lastCalibrationTimestamp:Number = 0;
		private var currentTotalIOB:Number = 0;
		private var currentTotalCOB:Number = 0;
		private var predictionsCalloutTimeout:uint = 0;
		private var forceNightscoutPredictionRefresh:Boolean = false;
		private var numDifferentPredictionsDisplayed:uint;
		private var preferredPrediction:String;
		private var predictionPillExplanationEnabled:Boolean = false;
		private var predictionsIncompleteProfile:Boolean = false;
		private var singlePredictionCurve:Boolean = true;
		private var lastPredictionUpdate:Number = Number.NaN;
		private var finalPredictedDuration:Number = Number.NaN;
		private var finalPredictedValue:Number = Number.NaN;
		private var predictionsPill:ChartTreatmentPill;
		private var predictionsContainer:ScrollContainer;
		private var predictionsCallout:Callout;
		private var predictedEventualBGPill:ChartTreatmentPill;
		private var predictedTreatmentsOutcomePill:ChartTreatmentPill;
		private var predictedTreatmentsEffectPill:ChartTreatmentPill;
		private var predictedBgImpactPill:ChartTreatmentPill;
		private var predictedDeviationPill:ChartTreatmentPill;
		private var predictedCarbImpactPill:ChartTreatmentPill;
		private var predictionsEnableSwitch:ToggleSwitch;
		private var predictionsEnablerPill:ChartComponentPill;
		private var glucoseVelocityPill:ChartTreatmentPill;
		private var predictionsIOBCOBCheck:Check;
		private var predictionsIOBCOBPill:ChartComponentPill;
		private var predictionsTimeFramePill:ChartComponentPill;
		private var predictionsLengthPicker:PickerList;
		private var predictedTimeUntilHighPill:ChartTreatmentPill;
		private var predictedTimeUntilLowPill:ChartTreatmentPill;
		private var predictedUAMBGPill:ChartTreatmentPill;
		private var predictedIOBBGPill:ChartTreatmentPill;
		private var predictedMinimumBGPill:ChartTreatmentPill;
		private var predictionsLegendsContainer:LayoutGroup;
		private var cobPredictLegendContainer:LayoutGroup;
		private var cobPredictLegendLabel:Label;
		private var cobPredictLegendColorQuad:Quad;
		private var uamPredictLegendContainer:LayoutGroup;
		private var uamPredictLegendLabel:Label;
		private var uamPredictLegendColorQuad:Quad;
		private var iobPredictLegendContainer:LayoutGroup;
		private var iobPredictLegendLabel:Label;
		private var iobPredictLegendColorQuad:Quad;
		private var iobPredictLegendHitArea:Quad;
		private var uamPredictLegendHitArea:Quad;
		private var cobPredictLegendHitArea:Quad;
		private var predictionExplanationMainContainer:ScrollContainer;
		private var predictionTitleLabel:Label;
		private var predictionExplanationLabel:Label;
		private var predictionExplanationCallout:Callout;
		private var predictedCOBBGPill:ChartTreatmentPill;
		private var incompleteProfileWarningLabel:Label;
		private var predictionsSingleCurveCheck:Check;
		private var predictionsSingleCurvePill:ChartComponentPill;
		private var ztPredictLegendContainer:LayoutGroup;
		private var ztPredictLegendLabel:Label;
		private var ztPredictLegendColorQuad:Quad;
		private var ztPredictLegendHitArea:Quad;
		private var lastPredictionUpdateTimePill:ChartTreatmentPill;
		private var refreshExternalPredictionsButton:Button;
		private var predictionsExternalRefreshPill:ChartComponentPill;
		private var refreshPredictionsIcon:Image;
		private var wikiPredictionsIcon:Image;
		private var wikiPredictionsButton:Button;
		private var wikiPredictionsPill:ChartComponentPill;
		private var predictionDetailMainContainer:LayoutGroup;
		private var predictionDetailBGContainer:LayoutGroup;
		private var predictionDetailBGTitle:Label;
		private var predictionDetailBGBody:Label;
		private var predictionDetailCallout:Callout;
		private var predictionDetailCurveContainer:LayoutGroup;
		private var predictionDetailCurveTitle:Label;
		private var predictionDetailCurveBody:Label;
		private var predictionDetailTimeContainer:LayoutGroup;
		private var predictionDetailTimeTitle:Label;
		private var predictionDetailTimeBody:Label;
		
		//Basals
		private var basalAreasList:Array = [];
		private var basalLinesList:Array = [];
		private var basalLabelsList:Array = [];
		private var tempBasalAreaPropertiesMap:Object;
		private var mdiBasalAreaPropertiesMap:Object;
		private var mdiBasalLabelPropertiesMap:Object;
		private var basalsFirstRun:Boolean = true;
		private var displayBasalsOnChart:Boolean = false;
		private var displayPumpBasals:Boolean = false;
		private var displayMDIBasals:Boolean = false;
		private var basalScaler:Number = 1;
		private var basalsContainer:Sprite;
		private var basalAbsoluteLine:SpikeLine;
		private var basalCallout:Callout;
		private var basalScheduledLine:SpikeLine;
		private var lastTimePumpBasalWasRendered:Number = 0;
		private var lastTimeMDIBasalWasRendered:Number = 0;
		private var tempBasalAreaColor:uint;
		private var basalLineColor:uint;
		private var basalRateLineColor:uint;
		private var basalRenderMode:String;
		private var basalAreaColor:uint;
		private var activeBasalAreaQuad:Quad;
		private var localBasalPillAdded:Boolean = false;
		private var basalAreaSizePercentage:Number = 0.2;
		private var lastNumberOfRenderedBasals:uint = 0;

		public function GlucoseChart(timelineRange:int, chartWidth:Number, chartHeight:Number, dontDisplayIOB:Boolean = false, dontDisplayCOB:Boolean = false, dontDisplayInfoPill:Boolean = false, dontDisplayPredictionsPill:Boolean = false, isHistoricalData:Boolean = false, headerProperties:Object = null)
		{
			//Dexcom Follower
			isDexcomFollower = CGMBlueToothDevice.isDexcomFollower();
			
			//Header
			this.headerProperties = headerProperties;
			
			//Algorithm
			algorithmIOBCOB = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEFAULT_IOB_COB_ALGORITHM);
			
			//Predictions
			predictionsEnabled = dontDisplayPredictionsPill == true ? false : CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_GLUCOSE_PREDICTIONS_ENABLED) == "true";
			if (predictionsEnabled && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_LOOP_OPENAPS_USER_ENABLED) == "true")
			{
				Forecast.instance.addEventListener(PredictionEvent.APS_RETRIEVED, onAPSPredictionRetrieved);
			}
			
			predictionsColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_GLUCOSE_PREDICTIONS_DEFAULT_COLOR));
			singlePredictionCurve = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_GLUCOSE_PREDICTIONS_SINGLE_LINE_ENABLED) == "true";
			
			if (timelineRange == TIMELINE_1H)
				predictionsLengthInMinutes = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_GLUCOSE_PREDICTIONS_MINUTES_FOR_1_HOUR));
			else if (timelineRange == TIMELINE_3H)
				predictionsLengthInMinutes = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_GLUCOSE_PREDICTIONS_MINUTES_FOR_3_HOURS));
			else if (timelineRange == TIMELINE_6H)
				predictionsLengthInMinutes = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_GLUCOSE_PREDICTIONS_MINUTES_FOR_6_HOURS));
			else if (timelineRange == TIMELINE_12H)
				predictionsLengthInMinutes = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_GLUCOSE_PREDICTIONS_MINUTES_FOR_12_HOURS));
			else if (timelineRange == TIMELINE_24H)
				predictionsLengthInMinutes = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_GLUCOSE_PREDICTIONS_MINUTES_FOR_24_HOURS));
			
			//Data
			this.isHistoricalData = isHistoricalData;
			if (CGMBlueToothDevice.isFollower()) NUM_MINUTES_MISSED_READING_GAP = 7;
			
			//Unit
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true") 
				glucoseUnit = "mg/dL";
			else
				glucoseUnit = "mmol/L";
			
			//Raw
			displayRaw = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_DISPLAY_RAW_ON) == "true" && (CGMBlueToothDevice.isDexcomG4() || CGMBlueToothDevice.isDexcomG5() || CGMBlueToothDevice.isDexcomG6()) && !isHistoricalData;
			
			//Thresholds
			displayTargetLine = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_DISPLAY_TARGET_LINE) == "true";
			displayUrgentHighLine = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_DISPLAY_URGENT_HIGH_LINE) == "true";
			displayHighLine = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_DISPLAY_HIGH_LINE) == "true";
			displayLowLine = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_DISPLAY_LOW_LINE) == "true";
			displayUrgentLowLine = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_DISPLAY_URGENT_LOW_LINE) == "true";
			
			glucoseUrgentLow = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_URGENT_LOW_MARK));
			glucoseLow = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_LOW_MARK));
			glucoseHigh = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_HIGH_MARK));
			glucoseUrgentHigh = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_URGENT_HIGH_MARK));
			
			currentUserBGTarget = Number.NaN;
			
			if (displayTargetLine)
			{
				try
				{
					currentUserBGTarget = Number(ProfileManager.getProfileByTime(new Date().valueOf()).targetGlucoseRates);
				} 
				catch(error:Error) {}
			}
			
			//Colors
			lineColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_AXIS_COLOR));
			chartFontColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_FONT_COLOR));
			axisFontColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_AXIS_FONT_COLOR));
			highUrgentGlucoseMarkerColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_URGENT_HIGH_COLOR));
			highGlucoseMarkerColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_HIGH_COLOR));
			inrangeGlucoseMarkerColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_IN_RANGE_COLOR));
			lowGlucoseMarkerColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_LOW_COLOR));
			lowUrgentGlucoseMarkerColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_URGENT_LOW_COLOR)); 
			oldColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_OLD_DATA_COLOR)); 
			rawColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_RAW_COLOR));
			targetLineColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_TARGET_LINE_COLOR));
			tempBasalAreaColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TEMP_BASAL_AREA_COLOR));
			basalAreaColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_ABSOLUTE_BASAL_AREA_COLOR));
			basalLineColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_ABSOLUTE_BASAL_LINE_COLOR));
			basalRateLineColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BASAL_RATE_LINE_COLOR));
			
			//Size
			mainChartGlucoseMarkerRadius = int(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_MARKER_RADIUS));
			userBGFontMultiplier = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_BG_FONT_SIZE));
			userTimeAgoFontMultiplier = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_TIMEAGO_FONT_SIZE));
			userAxisFontMultiplier = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_AXIS_FONT_SIZE));
			yAxisMargin += (legendTextSize * userAxisFontMultiplier) - legendTextSize;
			glucoseLineThickness = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_GLUCOSE_LINE_THICKNESS));
			
			//Scale
			fixedSize = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_SCALE_MODE_DYNAMIC) == "false";
			maxAxisValue = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_MAX_VALUE));
			minAxisValue = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_MIN_VALUE));
			resizeOutOfBounds = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_RESIZE_ON_OUT_OF_BOUNDS) == "true";
			
			//Time Format
			dateFormat = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_DATE_FORMAT);
			
			//Strings
			retroOutput = ModelLocator.resourceManagerInstance.getString('chartscreen','retro_title');
			ago = ModelLocator.resourceManagerInstance.getString('chartscreen','time_ago_suffix');
			now = ModelLocator.resourceManagerInstance.getString('chartscreen','now');
			
			//Treatments
			if (!isDexcomFollower)
			{
				treatmentsActive = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_ENABLED) == "true";
				displayTreatmentsOnChart = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_ON_CHART_ENABLED) == "true";
				displayIOBEnabled = dontDisplayIOB == true ? false : CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_IOB_ENABLED) == "true";
				displayCOBEnabled = dontDisplayCOB == true ? false : CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_COB_ENABLED) == "true";
			}
			else
			{
				dontDisplayInfoPill = true;
			}
			
			//Basals
			displayBasalsOnChart = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SHOW_BASALS_ON_CHART) == "true";
			basalRenderMode = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_USER_TYPE_PUMP_OR_MDI);
			displayPumpBasals = basalRenderMode == "pump" && treatmentsActive && displayTreatmentsOnChart && displayBasalsOnChart;
			displayMDIBasals = basalRenderMode == "mdi" && treatmentsActive && displayTreatmentsOnChart && displayBasalsOnChart;
			basalAreaSizePercentage = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BASALS_AREA_SIZE_PERCENTAGE)) / 100;
			
			//Scroller Marker Radius
			if (Constants.deviceModel == DeviceInfo.IPAD_1_2_3_4_5_AIR1_2_PRO_97 || Constants.deviceModel == DeviceInfo.IPAD_PRO_105 || Constants.deviceModel == DeviceInfo.IPAD_PRO_129)
				scrollerChartGlucoseMarkerRadius = 2;
			
			//Add timeline to display list
			glucoseTimelineContainer = new Sprite();
			addChild(glucoseTimelineContainer);
			
			//Set properties #1
			this.timelineRange = timelineRange;
			this._graphWidth = chartWidth;
			
			//Calculate chartTopPadding
			if (!Constants.isPortrait && userBGFontMultiplier == 1.2)
				userBGFontMultiplier = 1;
			
			if (!Constants.isPortrait && userTimeAgoFontMultiplier == 1.2)
				userTimeAgoFontMultiplier = 1; 
			
			createStatusTextDisplays(dontDisplayInfoPill, dontDisplayPredictionsPill);
			
			var extraPadding:int = 15;
			if (Constants.deviceModel == DeviceInfo.IPHONE_2G_3G_3GS_4_4S_ITOUCH_2_3_4 || !Constants.isPortrait)
				extraPadding = 10;
			
			if (IOBPill != null)
				chartTopPadding = IOBPill.y + IOBPill.height + extraPadding;
			else if (COBPill != null)
				chartTopPadding = COBPill.y + COBPill.height + extraPadding;
			else if (infoPill != null)
				chartTopPadding = infoPill.y + infoPill.height + extraPadding;
			else if (predictionsPill != null)
				chartTopPadding = predictionsPill.y + predictionsPill.height + extraPadding;
			else
			{
				glucoseSlopePill.setValue(" ", " ", 0x20222a);
				chartTopPadding = glucoseSlopePill.y + glucoseSlopePill.height + extraPadding;
			}
			
			if (!Constants.deviceModel != DeviceInfo.IPHONE_2G_3G_3GS_4_4S_ITOUCH_2_3_4) scrollerTopPadding += 2;
			
			//Set properties #2
			this._scrollerWidth = chartWidth;
			this._scrollerHeight = Constants.deviceModel != DeviceInfo.IPHONE_2G_3G_3GS_4_4S_ITOUCH_2_3_4 ? 50 : 35;
			if (DeviceInfo.isTablet()) this._scrollerHeight = 75;
			if (!Constants.isPortrait && (Constants.deviceModel == DeviceInfo.IPHONE_5_5S_5C_SE_ITOUCH_5_6))
				this._scrollerHeight = 35;
			this._graphHeight = chartHeight - chartTopPadding - _scrollerHeight - scrollerTopPadding - (timelineActive ? 10 : 0);
			this.mainChartGlucoseMarkersList = [];
			this.rawGlucoseMarkersList = [];
			this.scrollChartGlucoseMarkersList = [];
			this.mainChartLineList = [];
			this.rawLineList = [];
			this.scrollerChartLineList = [];
			
			//Event Listeners
			CalibrationService.instance.addEventListener(CalibrationServiceEvent.INITIAL_CALIBRATION_EVENT, onCaibrationReceived, false, 0, true);
			CalibrationService.instance.addEventListener(CalibrationServiceEvent.NEW_CALIBRATION_EVENT, onCaibrationReceived, false, 0, true);
			Spike.instance.addEventListener(SpikeEvent.APP_IN_FOREGROUND, onAppInForeground, false, 0, true);
		}
		
		/**
		 * Functionality
		 */
		public function drawGraph():void
		{	
			/**
			 * Main Chart Container
			 */
			mainChartContainer = new Sprite();
			
			/**
			 * Main Chart
			 */
			mainChart = drawChart(MAIN_CHART, _graphWidth - yAxisMargin, _graphHeight, yAxisMargin, mainChartGlucoseMarkerRadius);
			mainChart.x = -mainChart.width + _graphWidth - yAxisMargin;
			if (!predictionsEnabled)
			{
				mainChart.touchable = false;
			}
			else if (predictionsEnabled && predictionsMainGlucoseDataPoints != null && predictionsMainGlucoseDataPoints.length > 0)
			{
				mainChart.x += mainChartGlucoseMarkerRadius;
			}
			mainChartContainer.addChild(mainChart);
			
			/**
			 * Raw Data Container
			 */
			if (displayRaw)
			{
				rawDataContainer = drawChart(MAIN_CHART, _graphWidth - yAxisMargin, _graphHeight, yAxisMargin, mainChartGlucoseMarkerRadius/2, true);
				rawDataContainer.touchable = false;
				rawDataContainer.x = mainChart.x;
				mainChartContainer.addChild(rawDataContainer);
			}
			
			//Add main chart to the display list
			glucoseTimelineContainer.addChild(mainChartContainer);
			
			//Mask (Only show markers before the delimiter)
			mainChartMask = new Quad(yAxisMargin, _graphHeight + (treatmentsActive ? 80 : 0), fakeChartMaskColor);
			mainChartMask.x = _graphWidth - mainChartMask.width;
			mainChartMask.y = treatmentsActive ? -40 : 0;
			mainChartMask.touchable = false;
			mainChartContainer.addChild(mainChartMask);
			
			/**
			 * Status Text Displays
			 */
			//createStatusTextDisplays();
			
			/**
			 * yAxis Line
			 */
			yAxisContainer = drawYAxis();
			yAxisContainer.touchable = false;
			addChild(yAxisContainer);
			
			/**
			 * Treatments
			 */
			if (!isHistoricalData)
				addAllTreatments();
			
			/**
			 * Scroller
			 */
			//Create scroller
			scrollerChart = drawChart(SCROLLER_CHART, _scrollerWidth - (scrollerChartGlucoseMarkerRadius * 2), _scrollerHeight, 0, scrollerChartGlucoseMarkerRadius);
			scrollerChart.touchable = false;
			
			if(!_displayLine)
				scrollerChart.y = _graphHeight + scrollerTopPadding;
			else
				scrollerChart.y = _graphHeight + scrollerTopPadding - 0.1;
			
			if (timelineActive)
				scrollerChart.y += 10;
			
			//Create scroller background
			scrollerBackground = new Quad(_scrollerWidth, _scrollerHeight, 0x282a32);
			scrollerBackground.y = scrollerChart.y;
			scrollerBackground.touchable = false;
			
			//Add scroller and background to the display list
			glucoseTimelineContainer.addChild(scrollerBackground);
			glucoseTimelineContainer.addChild(scrollerChart);
			
			/**
			 * Hand Picker
			 */
			//Create Hand Picker
			handPicker = new Sprite();
			handPickerFill = new Quad(_graphWidth/timelineRange, _scrollerHeight, 0xFFFFFF);
			handPickerFill.alpha = .2;
			handPicker.addChild(handPickerFill);
			handPicker.x = _graphWidth - handPicker.width;
			handPicker.y = scrollerChart.y;
			handPickerWidth = handPicker.width;
			
			//Outline for hand picker
			handpickerOutline = GraphLayoutFactory.createOutline(handPicker.width, handPicker.height, handPickerStrokeThickness);
			handPicker.addChild(handpickerOutline);
			glucoseTimelineContainer.addChild(handPicker);
			
			//Listen to touch events
			if(timelineRange != TIMELINE_24H)
				handPicker.addEventListener(TouchEvent.TOUCH, onHandPickerTouch);
			
			//Define scroll multiplier for scroller vs main graph
			scrollMultiplier = Math.abs(mainChart.x)/handPicker.x;
			
			/**
			 * Display objects coordinates adjustements
			 */
			yAxisContainer.y = chartTopPadding;
			glucoseTimelineContainer.y = chartTopPadding;
			
			/**
			 * Status Timer and Update events
			 */
			if (!isHistoricalData)
			{
				statusUpdateTimer = new Timer(15 * 1000);
				statusUpdateTimer.addEventListener(TimerEvent.TIMER, onUpdateTimerRefresh, false, 0, true);
				statusUpdateTimer.start();
			}
			
			/**
			 * Initial variables
			 */
			if(!dummyModeActive)
			{
				if (mainChartGlucoseMarkersList[mainChartGlucoseMarkersList.length - 1].index != null && mainChartGlucoseMarkersList[mainChartGlucoseMarkersList.length - 1].index != undefined)
					selectedGlucoseMarkerIndex = mainChartGlucoseMarkersList[mainChartGlucoseMarkersList.length - 1].index;
				{
					if (mainChartGlucoseMarkersList != null)
						selectedGlucoseMarkerIndex = mainChartGlucoseMarkersList.length;
					else
						selectedGlucoseMarkerIndex = 0;
				}
			}
			
			displayLatestBGValue = true;
			
			/**
			 * Calculate Display Labels
			 */
			calculateDisplayLabels();
			
			//Timeline
			if (timelineActive)
				drawTimeline();
			
			//Pills
			repositionTreatmentPills();
			
			//iPhone X masks for landscape mode
			if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr && !Constants.isPortrait)
			{
				xRightMask = new Quad(60, scrollerChart.y, fakeChartMaskColor);
				xRightMask.y = chartTopPadding;
				xRightMask.x = _graphWidth;
				addChild(xRightMask);
				
				xLeftMask = new Quad(60, scrollerChart.y, fakeChartMaskColor);
				xLeftMask.y = chartTopPadding;
				xLeftMask.x = -xLeftMask.width;
				addChild(xLeftMask);
			}
			
			//Basals
			if (displayPumpBasals || displayMDIBasals)
			{
				renderBasals();
				
				if (basalsContainer != null)
					basalsContainer.x = mainChart.x;
			}
		}
		
		private function drawChart(chartType:String, chartWidth:Number, chartHeight:Number, chartRightMargin:Number, glucoseMarkerRadius:Number, isRaw:Boolean = false):Sprite
		{
			var chartContainer:Sprite = new Sprite();
			if (!predictionsEnabled)
			{
				chartContainer.touchable = false;
			}
			
			/**
			 * Predictions
			 */
			clearTimeout(redrawPredictionsTimeoutID);
			var predictionsList:Array;
			if (predictionsEnabled)
			{
				//Special case for latest carb treatment
				var lastTreatmentIsCarbs:Boolean = TreatmentsManager.lastTreatmentIsCarb();
				
				predictionsList = fetchPredictions(lastTreatmentIsCarbs)
			}
			else
			{
				predictionsList = [];
			}
			
			if (predictionsEnabled && predictionsList.length == 0 && predictionsMainGlucoseDataPoints.length > 0)
			{
				//Can't get new predictions. Dispose old ones
				disposePredictions();
			}
			
			/**
			 * Calculation of X Axis scale factor
			 */
			//Get first and last timestamp and determine the difference between the two
			if (!dummyModeActive)
			{
				firstBGReadingTimeStamp = Number(_dataSource[0].timestamp);
				
				if (!predictionsEnabled || predictionsList.length == 0)
					lastBGreadingTimeStamp = !isHistoricalData ? (new Date()).valueOf() : Number(_dataSource[_dataSource.length - 1].timestamp);
				else
					lastBGreadingTimeStamp = predictionsList[predictionsList.length - 1].timestamp;
			}
			else
			{
				firstBGReadingTimeStamp = 0;
				lastBGreadingTimeStamp = 0;
			}
			var totalTimestampDifference:Number = lastBGreadingTimeStamp - firstBGReadingTimeStamp;
			
			//Calculate scaleXFactor
			var scaleXFactor:Number;
			if(chartType == MAIN_CHART)
			{
				differenceInMinutesForAllTimestamps = TimeSpan.fromDates(new Date(firstBGReadingTimeStamp), new Date(lastBGreadingTimeStamp)).totalMinutes;
				if (differenceInMinutesForAllTimestamps > TimeSpan.TIME_ONE_DAY_IN_MINUTES)
					differenceInMinutesForAllTimestamps = TimeSpan.TIME_ONE_DAY_IN_MINUTES;
				
				scaleXFactor = 1/(totalTimestampDifference / (chartWidth * (timelineRange / (TimeSpan.TIME_ONE_DAY_IN_MINUTES / differenceInMinutesForAllTimestamps))));
				if(!isRaw) mainChartXFactor = scaleXFactor;
			}
			else if (chartType == SCROLLER_CHART)
			{
				scaleXFactor = 1/(totalTimestampDifference / (chartWidth - chartRightMargin));
			}
			
			/**
			 * Calculation of Y Axis scale factor
			 */
			//First we determine the maximum and minimum glucose values
			var sortDataArray:Array = predictionsList.length == 0 ? _dataSource.concat() : _dataSource.concat().concat(predictionsList);
			sortDataArray.sortOn(["_calculatedValue"], Array.NUMERIC);
			var lowestValue:Number;
			var highestValue:Number;;
			if (!dummyModeActive)
			{
				lowestValue = sortDataArray[0]._calculatedValue as Number;
				highestValue = sortDataArray[sortDataArray.length - 1]._calculatedValue as Number;
				if (!fixedSize)
				{
					lowestGlucoseValue = lowestValue;
					if (lowestGlucoseValue < 40)
						lowestGlucoseValue = 40;
					
					highestGlucoseValue = highestValue;
					if (highestGlucoseValue > 400)
						highestGlucoseValue = 400;
				}
				else
				{
					lowestGlucoseValue = minAxisValue;
					if (resizeOutOfBounds && lowestValue < minAxisValue)
						lowestGlucoseValue = lowestValue;
					
					highestGlucoseValue = maxAxisValue;
					if (resizeOutOfBounds && highestValue > maxAxisValue)
						highestGlucoseValue = highestValue
				}
			}
			else
			{
				lowestGlucoseValue = 40;
				highestGlucoseValue = 300;
			}
			
			//We find the difference so we can know how big the glucose pseudo graph is
			var totalGlucoseDifference:Number = highestGlucoseValue - lowestGlucoseValue;
			//Now we find a multiplier for the y axis so the glucose graph fits entirely with the chart height
			scaleYFactor = (chartHeight - (glucoseMarkerRadius*2))/totalGlucoseDifference;
			
			/**
			 * Internal variables
			 */
			var i:int; //common index for loops
			var previousXCoordinate:Number = 0;
			var previousYCoordinate:Number = 0;
			var previousGlucoseMarker:GlucoseMarker;
			var lastRealGlucoseMarker:GlucoseMarker;
			
			/**
			 * Creation of the line component
			 */
			//Line Chart
			if(_displayLine && !isRaw)
			{
				var line:SpikeLine = new SpikeLine();
				line.touchable = false;
				line.lineStyle(chartType == SCROLLER_CHART && glucoseLineThickness > 1 ? glucoseLineThickness / 2 : glucoseLineThickness, 0xFFFFFF, 1);
				
				if(chartType == MAIN_CHART)
				{
					if (mainChartLine != null) mainChartLine.removeFromParent(true);
					mainChartLine = line;
				}
				else if (chartType == SCROLLER_CHART)
				{
					if (scrollerChartLine != null) scrollerChartLine.removeFromParent(true);
					scrollerChartLine = line;
				}
			}
			
			/**
			 * Creation and placement of the glucose values
			 */
			//Loop through all available data points
			var extraEndLineColor:uint;
			var doublePrevGlucoseReading:BgReading;
			var previousLineX:Number;
			var previousLineY:Number;
			var isPrediction:Boolean
			var index:int;
			var readingsSource:Array;
			var predictionsLength:int = predictionsList.length;
			var realReadingsLength:int = _dataSource.length;
			var dataLength:int = realReadingsLength + predictionsLength;
			
			for(i = 0; i < dataLength; i++)
			{
				isPrediction = i >= realReadingsLength;
				
				if (isPrediction && isRaw)
				{
					//Don't add raw for predictions
					break;
				}
				
				index = !isPrediction ? i : i - realReadingsLength;
				readingsSource = !isPrediction ? _dataSource : predictionsList;
				
				var glucoseReading:BgReading = readingsSource[index];
				
				//Get current glucose value
				var currentGlucoseValue:Number = !isRaw || isPrediction ? Number(glucoseReading._calculatedValue) : GlucoseFactory.getRawGlucose(glucoseReading, glucoseReading.calibration);
				if(currentGlucoseValue < 40)
					currentGlucoseValue = 40;
				else if (currentGlucoseValue > 400)
					currentGlucoseValue = 400;
				
				//Define glucose marker x position
				var glucoseX:Number;
				if(i==0)
					glucoseX = !isRaw ? 0 : glucoseMarkerRadius;
				else
				{
					if (!isPrediction)
					{
						glucoseX = (Number(glucoseReading.timestamp) - Number(_dataSource[i-1].timestamp)) * scaleXFactor;
					}
					else if (isPrediction && index == 0)
					{
						glucoseX = (Number(glucoseReading.timestamp) - Number(_dataSource[_dataSource.length-1].timestamp)) * scaleXFactor;
					}
					else
					{
						glucoseX = (Number(glucoseReading.timestamp) - Number(readingsSource[index-1].timestamp)) * scaleXFactor;
					}
				}
				
				//Define glucose marker y position
				var glucoseY:Number = chartHeight - (glucoseMarkerRadius * 2) - ((currentGlucoseValue - lowestGlucoseValue) * scaleYFactor);
				if (isRaw) glucoseY -= glucoseMarkerRadius;
				//If glucose is a perfect flat line then display it in the middle
				if(totalGlucoseDifference == 0 && !isRaw) 
					glucoseY = (chartHeight - (glucoseMarkerRadius*2)) / 2;
				
				// Create Glucose Marker
				var glucoseMarker:GlucoseMarker;
				if (!isRaw && !isPrediction)
				{
					glucoseMarker = new GlucoseMarker
					(
						{
							x: previousXCoordinate + glucoseX,
							y: glucoseY,
							index: i,
							radius: glucoseMarkerRadius,
							bgReading: glucoseReading,
							previousGlucoseValueFormatted: previousGlucoseMarker != null ? previousGlucoseMarker.glucoseValueFormatted : null,
							previousGlucoseValue: previousGlucoseMarker != null ? previousGlucoseMarker.glucoseValue : null
						}
					);
				}
				else if (isPrediction)
				{
					glucoseMarker = new GlucoseMarker
						(
							{
								x: previousXCoordinate + glucoseX,
								y: glucoseY,
								index: i,
								radius: glucoseMarkerRadius,
								bgReading: glucoseReading,
								glucose: currentGlucoseValue,
								color: glucoseReading.rawData
							},
							false,
							true
						);
				}
				else if (isRaw)
				{
					glucoseMarker = new GlucoseMarker
					(
						{
							x: previousXCoordinate + glucoseX,
							y: glucoseY,
							index: i,
							radius: glucoseMarkerRadius,
							bgReading: glucoseReading,
							raw: currentGlucoseValue,
							rawColor: rawColor
						},
						true
					);
				}
				
				if (!isPrediction)
				{
					glucoseMarker.touchable = false;
				}
				else
				{
					if(chartType == MAIN_CHART)
						glucoseMarker.addEventListener(TouchEvent.TOUCH, onPredictionMarkerTouched);
				}
				
				//Hide glucose marker if it is out of bounds (fixed size chart);
				if (glucoseMarker.glucoseValue < lowestGlucoseValue || glucoseMarker.glucoseValue > highestGlucoseValue)
					glucoseMarker.alpha = 0;
				else
					glucoseMarker.alpha = 1;
				
				//Draw line
				if(_displayLine && !isRaw && glucoseMarker.bgReading != null && glucoseMarker.bgReading._calculatedValue != 0 && (glucoseMarker.bgReading.sensor != null || CGMBlueToothDevice.isFollower() || isPrediction) && glucoseMarker.glucoseValue >= lowestGlucoseValue && glucoseMarker.glucoseValue <= highestGlucoseValue)
				{
					//Define new predictions set
					var newPredictionSet:Boolean = isPrediction && previousGlucoseMarker != null && previousGlucoseMarker.bgReading.uniqueId.length == 3 && glucoseMarker.bgReading.uniqueId.length == 3 && previousGlucoseMarker.bgReading.uniqueId != glucoseMarker.bgReading.uniqueId;
					
					if (!isPrediction && i == realReadingsLength - 1)
					{
						lastRealGlucoseMarker = glucoseMarker;
					}
					
					if(i == 0)
						line.moveTo(glucoseMarker.x, glucoseMarker.y + (glucoseMarker.width / 2));
					else
					{
						var currentLineX:Number;
						var currentLineY:Number;
						
						if((i < dataLength -1 || isPrediction) && i != realReadingsLength - 1)
						{
							currentLineX = glucoseMarker.x + (glucoseMarker.width/2);
							currentLineY = glucoseMarker.y + (glucoseMarker.height/2);
						}
						else if (i == dataLength -1 || i == realReadingsLength - 1)
						{
							currentLineX = glucoseMarker.x + (glucoseMarker.width);
							currentLineY = glucoseMarker.y + (glucoseMarker.height/2);
							if (previousGlucoseMarker != null)
							{
								currentLineY += (glucoseMarker.y - previousGlucoseMarker.y) / 3;
							}
						}
						
						//Style
						line.lineStyle(chartType == SCROLLER_CHART && glucoseLineThickness > 1 ? glucoseLineThickness / 2 : glucoseLineThickness, glucoseMarker.color, 1);
						var currentColor:uint = glucoseMarker.color
						var previousColor:uint;
							
						//Determine if missed readings are bigger than the acceptable gap. If so, the line will be gray;
						if(previousGlucoseMarker != null && glucoseMarker != null)
						{
							var elapsedMinutes:Number = TimeSpan.fromDates(new Date(previousGlucoseMarker.timestamp), new Date(glucoseMarker.timestamp)).minutes;
							if (elapsedMinutes > NUM_MINUTES_MISSED_READING_GAP)
							{
								currentColor = oldColor;
								previousColor = oldColor;
							}
							else
								previousColor = previousGlucoseMarker.color;
						}	
						
						if (newPredictionSet)
						{
							//Add extra line to the beginning
							/*if (lastRealGlucoseMarker != null)
							{
								line.moveTo(lastRealGlucoseMarker.x + lastRealGlucoseMarker.width, lastRealGlucoseMarker.y + (lastRealGlucoseMarker.height / 2));
								line.lineTo(currentLineX, currentLineY, lastRealGlucoseMarker.color, glucoseMarker.color);
							}*/
							
							//Add extra line to the end
							if (previousGlucoseMarker != null)
							{
								if (chartType == MAIN_CHART && isPrediction) previousGlucoseMarker.removeHitArea();
								
								var extraSetPredictionLineX:Number = previousGlucoseMarker.x + previousGlucoseMarker.width;
								var extraSetPredictionLineY:Number = previousGlucoseMarker.y + (previousGlucoseMarker.height / 2);
								extraEndLineColor = previousGlucoseMarker.color;
								doublePrevGlucoseReading = readingsSource[index - 2];
								if (doublePrevGlucoseReading != null)
								{
									extraEndLineColor = doublePrevGlucoseReading.rawData;
								}
								
								//Try to calculate y direction of previous line by fetching 2 previous glucose markers
								var targetGlucoseMarker:GlucoseMarker;
								if(chartType == MAIN_CHART && index - 2 > 0)
								{
									targetGlucoseMarker = predictionsMainGlucoseDataPoints[index - 2];
								}
								else if (chartType == SCROLLER_CHART && index - 2 > 0)
								{
									targetGlucoseMarker = predictionsScrollerGlucoseDataPoints[index - 2];
								}
								
								//Marker found, add y difference
								if (targetGlucoseMarker != null)
								{
									if (chartType == MAIN_CHART && isPrediction) targetGlucoseMarker.removeHitArea();
									
									line.moveTo(extraSetPredictionLineX, extraSetPredictionLineY + ((previousGlucoseMarker.y - targetGlucoseMarker.y) / 3));
									
									if (chartType == MAIN_CHART && isPrediction) targetGlucoseMarker.addHitArea();
								}
								else
								{
									line.moveTo(extraSetPredictionLineX, extraSetPredictionLineY);
								}
								
								line.lineTo(extraSetPredictionLineX - (previousGlucoseMarker.width / 2), extraSetPredictionLineY, extraEndLineColor, extraEndLineColor);
								
								if (chartType == MAIN_CHART && isPrediction) previousGlucoseMarker.addHitArea();
							}
						}
						
						if ((isNaN(previousColor) || isPrediction) && index != 0)
						{
							if (!isPrediction)
							{
								line.lineTo(currentLineX, currentLineY);
							}
							else
							{
								if (previousGlucoseMarker.bgReading.uniqueId == glucoseMarker.bgReading.uniqueId && !newPredictionSet)
								{
									line.lineTo((currentLineX + previousLineX) / 2, (currentLineY + previousLineY) / 2);
								}
							}
						}
						else
						{
							if (!isPrediction && !index == 0)
							{
								line.lineTo(currentLineX, currentLineY, previousColor, currentColor);
							}
						}
						
						line.moveTo(currentLineX, currentLineY);
						
						previousLineX = currentLineX;
						previousLineY = currentLineY;
					}
					//Hide glucose marker
					glucoseMarker.alpha = 0;
				}
				
				//Hide markers without sensor
				if ((glucoseReading.sensor == null && !CGMBlueToothDevice.isFollower() && !isPrediction) || glucoseReading._calculatedValue == 0 || (glucoseReading.rawData == 0 && !CGMBlueToothDevice.isFollower()))
					glucoseMarker.alpha = 0;
			
				//Set variables for next iteration
				if (i < dataLength - 1)
				{
					previousXCoordinate = glucoseMarker.x;
					previousYCoordinate = glucoseMarker.y;
					previousGlucoseMarker = glucoseMarker;
				}
				
				//Add glucose marker to the timeline
				chartContainer.addChild(glucoseMarker);
				
				//Add glucose marker to the displayObjects array for later reference 
				if(chartType == MAIN_CHART)
				{
					if (!isRaw && !isPrediction)
						mainChartGlucoseMarkersList.push(glucoseMarker);
					else if (isRaw && !isPrediction)
						rawGlucoseMarkersList.push(glucoseMarker);
					else if (isPrediction)
						predictionsMainGlucoseDataPoints.push(glucoseMarker);
				}
				else if (chartType == SCROLLER_CHART)
				{
					if (!isPrediction)
						scrollChartGlucoseMarkersList.push(glucoseMarker);
					else
						predictionsScrollerGlucoseDataPoints.push(glucoseMarker);
				}
				
				if (isPrediction && chartType == MAIN_CHART)
				{
					glucoseMarker.addHitArea();
				}
			}
			
			//Predictions line fix
			if (glucoseMarker != null && _displayLine && !isRaw && glucoseMarker.bgReading != null && glucoseMarker.bgReading._calculatedValue != 0 && (glucoseMarker.bgReading.sensor != null || CGMBlueToothDevice.isFollower() || isPrediction) && glucoseMarker.glucoseValue >= lowestGlucoseValue && glucoseMarker.glucoseValue <= highestGlucoseValue && predictionsEnabled && predictionsLength > 0)
			{
				//Add an extra line
				if (chartType == MAIN_CHART && isPrediction) glucoseMarker.removeHitArea();
				
				var extraPredictionLineX:Number = glucoseMarker.x + glucoseMarker.width;
				var extraPredictionLineY:Number = glucoseMarker.y + (glucoseMarker.height / 2);
				extraEndLineColor = previousGlucoseMarker.color;
				doublePrevGlucoseReading = readingsSource[index - 2];
				if (doublePrevGlucoseReading != null)
				{
					extraEndLineColor = doublePrevGlucoseReading.rawData;
				}
				line.moveTo(extraPredictionLineX, extraPredictionLineY + ((glucoseMarker.y - previousGlucoseMarker.y) / 3));
				line.lineTo(extraPredictionLineX - (glucoseMarker.width / 2), extraPredictionLineY, extraEndLineColor, extraEndLineColor);
				
				if (chartType == MAIN_CHART && isPrediction) glucoseMarker.addHitArea();
			}
			
			//Creat dummy marker in case the current timestamp is bigger than the latest bgreading timestamp
			if (!dummyModeActive && !isHistoricalData && !isRaw)
			{
				if (lastBGreadingTimeStamp > Number(_dataSource[_dataSource.length - 1].timestamp) && lastBGreadingTimeStamp - Number(_dataSource[_dataSource.length - 1].timestamp) > (4.5 * 60 * 1000) && chartType == MAIN_CHART)
				{
					dummySprite = new Sprite();
					dummySprite.touchable = false;
					dummySprite.x = (lastBGreadingTimeStamp - firstBGReadingTimeStamp) * scaleXFactor;
					chartContainer.addChild(dummySprite);
				}
			}
			
			//Define scroll multiplier for scroller vs main graph
			if (handPicker != null && chartType == MAIN_CHART && !isRaw)
			{
				if (mainChart.x > 0)
					scrollMultiplier = Math.abs(mainChart.width - (glucoseMarkerRadius * 2))/handPicker.x;
				else
					scrollMultiplier = Math.abs(mainChart.x)/handPicker.x;
			}
			
			//Chart Line
			if(_displayLine && !isRaw)
			{
				//Add line to the display list
				chartContainer.addChild(line);
				
				//Save line references for later use
				if(chartType == MAIN_CHART)
				{
					if (!isRaw)
						mainChartLineList.push(line);
					else
						rawLineList.push(line);
				}
				else if (chartType == SCROLLER_CHART)
					scrollerChartLineList.push(line);
			}
			
			if(chartType == MAIN_CHART && !isRaw)
				mainChartYFactor = scaleYFactor;
			
			//Reporition prediction delimitter
			reporsitionPredictionDelimitter();
			
			return chartContainer;
		}
		
		public function calculateTotalIOB(time:Number):void
		{
			if (dummyModeActive || !treatmentsActive || !displayTreatmentsOnChart || !displayIOBEnabled || isHistoricalData || !SystemUtil.isApplicationActive)
				return;
			
			if (treatmentsActive && TreatmentsManager.treatmentsList != null && TreatmentsManager.treatmentsList.length > 0 && IOBPill != null && mainChartGlucoseMarkersList != null && mainChartGlucoseMarkersList.length > 0)
			{
				currentTotalIOB = TreatmentsManager.getTotalIOB(time).iob;
				IOBPill.setValue(GlucoseFactory.formatIOB(currentTotalIOB));
				SystemUtil.executeWhenApplicationIsActive( repositionTreatmentPills );
			}
			
			if (treatmentsActive && (TreatmentsManager.treatmentsList == null || TreatmentsManager.treatmentsList.length == 0))
			{
				currentTotalIOB = 0;
				IOBPill.setValue(GlucoseFactory.formatIOB(0));
				SystemUtil.executeWhenApplicationIsActive( repositionTreatmentPills );
			}
		}
		
		public function calculateTotalCOB(time:Number, forceNew:Boolean = false):void
		{
			if (dummyModeActive || !treatmentsActive || !displayTreatmentsOnChart || !displayCOBEnabled || isHistoricalData || !SystemUtil.isApplicationActive)
				return;
			
			if (treatmentsActive && TreatmentsManager.treatmentsList != null && TreatmentsManager.treatmentsList.length > 0 && COBPill != null && mainChartGlucoseMarkersList != null && mainChartGlucoseMarkersList.length > 0)
			{
				if (algorithmIOBCOB == "openaps" && !forceNew)
				{
					//Save original time in case we need to revert to it.
					var originalTime:Number = time;
					
					//For OpenAPS we ask for COB of the current selected marker timestamp. In between timestamps give exactly the same COB value and waste CPU cycles
					var relevantMarker:GlucoseMarker;
					if (displayLatestBGValue)
					{
						relevantMarker = mainChartGlucoseMarkersList[mainChartGlucoseMarkersList.length - 1];
						if (relevantMarker != null)
						{
							time = relevantMarker.timestamp;
						}
					}
					else
					{
						relevantMarker = mainChartGlucoseMarkersList[selectedGlucoseMarkerIndex];
						if (relevantMarker != null)
						{
							time = relevantMarker.timestamp;
						}
					}
					
					var now:Number = new Date().valueOf();
					var lastTreatment:Treatment = TreatmentsManager.getLastTreatment();
					var lastBgReading:BgReading = _dataSource[_dataSource.length - 1];
					var forceLatestCOB:Boolean = lastTreatment != null && lastBgReading != null && lastTreatment.carbs > 0 && lastTreatment.timestamp > lastBgReading.timestamp;
					
					if (latestOpenAPSRequestedCOBTimestamp != time || forceLatestCOB)
					{
						if (forceLatestCOB)
						{
							currentTotalCOB = TreatmentsManager.getTotalCOB(originalTime, false, false).cob;
						}
						else
						{
							currentTotalCOB = TreatmentsManager.getTotalCOB(time, displayLatestBGValue || (mainChartGlucoseMarkersList[selectedGlucoseMarkerIndex] != null && time >= mainChartGlucoseMarkersList[selectedGlucoseMarkerIndex].timestamp && now - mainChartGlucoseMarkersList[selectedGlucoseMarkerIndex].timestamp < TimeSpan.TIME_5_MINUTES)).cob;
						}
						
						if (COBPill != null) COBPill.setValue(GlucoseFactory.formatCOB(currentTotalCOB));
						latestOpenAPSRequestedCOBTimestamp = time;
						SystemUtil.executeWhenApplicationIsActive( repositionTreatmentPills );
					}
				}
				else
				{
					currentTotalCOB = TreatmentsManager.getTotalCOB(time).cob;
					if (COBPill != null) COBPill.setValue(GlucoseFactory.formatCOB(currentTotalCOB));
					SystemUtil.executeWhenApplicationIsActive( repositionTreatmentPills );
				}
			}
			
			if (treatmentsActive && (TreatmentsManager.treatmentsList == null || TreatmentsManager.treatmentsList.length == 0))
			{
				currentTotalCOB = 0;
				if (COBPill != null) COBPill.setValue(GlucoseFactory.formatCOB(0));
				SystemUtil.executeWhenApplicationIsActive( repositionTreatmentPills );
			}
		}
		
		private function repositionTreatmentPills():void
		{
			if (predictionsPill != null)
			{
				predictionsPill.x = _graphWidth - predictionsPill.width -glucoseStatusLabelsMargin - 2;
				predictionsPill.visible = true;
			}
			
			if (displayIOBEnabled && IOBPill != null)
			{
				if (predictionsPill != null)
					IOBPill.x = predictionsPill.x - IOBPill.width - 6;
				else
					IOBPill.x = _graphWidth - IOBPill.width -glucoseStatusLabelsMargin - 2;
				
				IOBPill.visible = true;
			}
			
			if (displayCOBEnabled && COBPill != null)
			{
				if (displayIOBEnabled)
					COBPill.x = IOBPill.x - COBPill.width - 6;
				else if (predictionsPill != null)
					COBPill.x = predictionsPill.x - COBPill.width - 6;
				else
					COBPill.x = _graphWidth - COBPill.width -glucoseStatusLabelsMargin - 2;
				
				COBPill.visible = true;
			}
			
			if (infoPill != null)
			{
				if (displayCOBEnabled && COBPill != null)
					infoPill.x = COBPill.x - infoPill.width - 6;
				else if (displayIOBEnabled && IOBPill != null)
					infoPill.x = IOBPill.x - infoPill.width - 6;
				else if (predictionsPill != null)
					infoPill.x = predictionsPill.x - infoPill.width - 6;
				else
					infoPill.x = _graphWidth - infoPill.width -glucoseStatusLabelsMargin - 2;
				
				infoPill.visible = true;
			}
		}
		
		public function addAllTreatments():void
		{
			if (!SystemUtil.isApplicationActive || dummyModeActive || !treatmentsActive || !displayTreatmentsOnChart || isHistoricalData)
				return;
			
			if (TreatmentsManager.treatmentsList != null && TreatmentsManager.treatmentsList.length > 0 && treatmentsActive && !dummyModeActive && !allTreatmentsAdded)
			{
				allTreatmentsAdded = true;
				
				for (var i:int = 0; i < TreatmentsManager.treatmentsList.length; i++) 
				{
					var treatment:Treatment = TreatmentsManager.treatmentsList[i] as Treatment;
					if (treatment != null)
						addTreatment(treatment);
				}
				
				//Update Display Treatments Values
				var now:Number = new Date().valueOf();
				if (displayIOBEnabled)
					calculateTotalIOB(now);
				if (displayCOBEnabled)
					calculateTotalCOB(now);
			}
		}
		
		public function addAllHistoricalTreatments(treatmentsList:Array):void
		{
			if (!SystemUtil.isApplicationActive || dummyModeActive || !treatmentsActive || !displayTreatmentsOnChart)
				return;
			
			if (treatmentsList != null && treatmentsList.length > 0 && treatmentsActive && !dummyModeActive)
			{
				for (var i:int = 0; i < treatmentsList.length; i++) 
				{
					var treatment:Treatment = treatmentsList[i] as Treatment;
					if (treatment != null)
						addTreatment(treatment);
				}
			}
		}
		
		public function updateExternallyModifiedTreatment(treatment:Treatment):void
		{
			if (dummyModeActive || !treatmentsActive || !displayTreatmentsOnChart || isHistoricalData || treatment == null)
				return;
			
			var modifiedTreatment:ChartTreatment = treatmentsMap[treatment.ID] as ChartTreatment;
			if (modifiedTreatment != null)
			{
				//Update the treatment marker
				modifiedTreatment.updateMarker(treatment);
				
				//Reposition all treatments
				manageTreatments();
				
				if (treatment.insulinAmount > 0 || treatment.carbs > 0)
				{
					//Recalculate total IOB and COB
					var timelineTimestamp:Number = getTimelineTimestamp();
					if (displayIOBEnabled && treatment.insulinAmount > 0)
						calculateTotalIOB(timelineTimestamp);
					if (displayCOBEnabled && treatment.carbs > 0)
						calculateTotalCOB(timelineTimestamp);
				}
			}
		}
		
		public function updateExternallyDeletedTreatment(treatment:Treatment):void
		{
			if (!SystemUtil.isApplicationActive || dummyModeActive || !treatmentsActive || !displayTreatmentsOnChart || isHistoricalData)
				return;
			
			if (treatment != null)
			{
				for(var i:int = treatmentsList.length - 1 ; i >= 0; i--)
				{
					var chartTreatment:ChartTreatment = treatmentsList[i];
					if (chartTreatment!= null && chartTreatment.treatment != null && chartTreatment.treatment.ID == treatment.ID)
					{
						//Dispose chart treatment
						chartTreatment.removeFromParent();
						chartTreatment.removeEventListener(TouchEvent.TOUCH, onDisplayTreatmentDetails);
						treatmentsList.removeAt(i);
						chartTreatment.dispose();
						chartTreatment = null;
						treatmentsMap[treatment.ID] = null;
						
						//Recalculate IOB & COB
						var timelineTimestamp:Number = getTimelineTimestamp();
						if (displayIOBEnabled)
							calculateTotalIOB(timelineTimestamp);
						if (displayCOBEnabled)
							calculateTotalCOB(timelineTimestamp);
						break;
					}
				}
			}
		}
		
		private function parseChildTreatments(chartTreatment:ChartTreatment):void
		{
			if (chartTreatment.treatment != null && (chartTreatment.treatment.type == Treatment.TYPE_EXTENDED_COMBO_BOLUS_PARENT || chartTreatment.treatment.type == Treatment.TYPE_EXTENDED_COMBO_MEAL_PARENT))
			{
				var treatment:Treatment = chartTreatment.treatment;
				var childrenIDs:Array = treatment.childTreatments;
				var numberOfBolusChildren:uint = childrenIDs.length;
				chartTreatment.children.length = 0;
				
				for (var i:int = 0; i < numberOfBolusChildren; i++) 
				{
					var bolusChild:ChartTreatment = getTreatmentByID(String(childrenIDs[i]));
					if (bolusChild != null)
					{
						chartTreatment.children.push(bolusChild);
					}
				}
			}
		}
		
		public function renderBasals(basalsSource:Array = null):void
		{
			if (basalRenderMode == "pump")
			{
				renderPumpBasals(basalsSource);
			}
			else if (basalRenderMode == "mdi")
			{
				renderPenBasals(basalsSource);
			}
		}
		
		private function renderPenBasals(basalsSource:Array = null):void
		{
			if (!displayMDIBasals || !SystemUtil.isApplicationActive || firstBGReadingTimeStamp == 0)
			{
				return
			}
			
			var sourceForBasals:Array = basalsSource != null ? basalsSource : TreatmentsManager.basalsList;
			
			//Dispose previous basals
			disposeBasalCallout();
			disposeBasals();
			
			//Setup initial timeline/mask properties
			if (basalsFirstRun && basalsContainer == null)
			{
				basalsFirstRun = false;
				basalsContainer = new Sprite();
				basalsContainer.x = mainChart.x;
				basalsContainer.y = glucoseDelimiter.height;
				mainChartContainer.addChildAt(basalsContainer, 0);
			}
			
			//Validation
			var numberOfBasals:uint = sourceForBasals.length;
			if (numberOfBasals == 0)
			{
				if (mainChart != null)
				{
					//Create and configure line
					basalAbsoluteLine = new SpikeLine();
					basalAbsoluteLine.lineStyle(1.5, basalLineColor);
					basalAbsoluteLine.moveTo(0, 0);
					basalAbsoluteLine.lineTo(predictionsEnabled && predictionsMainGlucoseDataPoints.length > 0 ? mainChart.width + Constants.stageWidth : mainChart.width, 0);
					
					//Add line to display list
					basalsContainer.addChild(basalAbsoluteLine);
					basalLinesList.push(basalAbsoluteLine);
				}
				
				return;
			}
			
			//Clean previous basals
			if (!isHistoricalData)
				TreatmentsManager.cleanUpOldBasals();
			
			//Common variables
			var timer:int = getTimer();
			var now:Number = new Date().valueOf();
			var i:int;
			lastTimeMDIBasalWasRendered = now;
			mdiBasalAreaPropertiesMap = {};
			mdiBasalLabelPropertiesMap = {};
			
			//Data variables
			var fromTime:Number = firstBGReadingTimeStamp != 0 ? firstBGReadingTimeStamp : now - TimeSpan.TIME_24_HOURS;
			var toTime:Number = !displayLatestBGValue && !isHistoricalData ? now + (mainChartGlucoseMarkerRadius/mainChartXFactor) : firstBGReadingTimeStamp + (Math.abs(mainChart.x - (_graphWidth - yAxisMargin - (predictionsEnabled && predictionsDelimiter != null ? glucoseDelimiter.x - predictionsDelimiter.x : 0))) / mainChartXFactor);
			
			var numberOfPredictions:uint = predictionsMainGlucoseDataPoints.length;
			if (predictionsEnabled && numberOfPredictions > 0 && !isHistoricalData)
			{
				var lastPredictionMarker:GlucoseMarker = predictionsMainGlucoseDataPoints[numberOfPredictions - 1];
				if (lastPredictionMarker != null)
				{
					toTime = lastPredictionMarker.bgReading.timestamp + ((mainChartGlucoseMarkerRadius * 2)/mainChartXFactor);
				}
			}
			
			if (isNaN(toTime)) toTime = now;
			var time:Number;
			
			//Sorting
			if (sourceForBasals == null || sourceForBasals.length == 0 || sourceForBasals[numberOfBasals - 1] == null)
			{
				return;
			}
			
			sourceForBasals.sortOn(["basalAbsoluteAmount"], Array.NUMERIC);
			var highestBasalAmount:Number = sourceForBasals[numberOfBasals - 1].basalAbsoluteAmount;
			
			//Misc
			var absoluteBasalDataPointsArray:Array = [];
			var desiredBasalHeight:Number = _graphHeight * basalAreaSizePercentage;
			basalScaler = desiredBasalHeight / highestBasalAmount;
			var prevTempBasalAreaValue:Number = 0;
			var startXTempAreaValue:Number = 0;
			var startYTempAreaValue:Number = 0;
			var prevXAbsoluteValue:Number = Number.NaN;
			var prevYAbsoluteValue:Number = Number.NaN;
			var previousTempBasalAreaProps:Object;
			lastNumberOfRenderedBasals = numberOfBasals;
			
			for (time = toTime; time >= fromTime - TimeSpan.TIME_1_MINUTE; time -= TimeSpan.TIME_1_MINUTE) 
			{
				//Gather Basal Data
				var basalProperties:Object = ProfileManager.getMDIBasalData(time, sourceForBasals);
				
				//Calculate Coordinates (Area & Basal Amount)
				var tempBasalAreaValue:Number = basalProperties.mdiBasalAmount;
				var xTempBasalAreaValue:Number = (time - firstBGReadingTimeStamp) * mainChartXFactor;
				var yTempBasalAreaValue:Number = tempBasalAreaValue * basalScaler;
				
				var tempBasalAmountValue:Number = basalProperties.mdiBasalAmount;
				var xTempBasalAmountValue:Number = xTempBasalAreaValue;
				var yTempBasalAmountValue:Number = tempBasalAmountValue * basalScaler * -1;
				
				if (time < fromTime)
				{
					tempBasalAreaValue = 0;
					xTempBasalAreaValue = -1;
					yTempBasalAreaValue = 0;
					
					tempBasalAmountValue = 0;
					xTempBasalAmountValue = -1;
					yTempBasalAmountValue = 0;
				}
				
				//Save absolute basal line data points
				if (yTempBasalAmountValue != prevYAbsoluteValue)
				{
					if (!isNaN(prevYAbsoluteValue))
					{
						absoluteBasalDataPointsArray.unshift( { x: xTempBasalAmountValue, y: prevYAbsoluteValue } );
					}
					
					absoluteBasalDataPointsArray.unshift( { x: xTempBasalAmountValue, y: yTempBasalAmountValue } );
				}
				
				//Save absolute variables state for next iteration
				prevXAbsoluteValue = xTempBasalAmountValue;
				prevYAbsoluteValue = yTempBasalAmountValue;
				
				//Render temp basal areas
				if (tempBasalAreaValue != prevTempBasalAreaValue)
				{
					if (startXTempAreaValue == 0 && startYTempAreaValue == 0)
					{
						startXTempAreaValue = xTempBasalAreaValue;
						startYTempAreaValue = yTempBasalAreaValue;
					}
					else
					{
						//Translate coordinates
						var endXAreaValue:Number = xTempBasalAreaValue;
						var endYAreaValue:Number = yTempBasalAreaValue;
						
						//Create Quad
						if (startYTempAreaValue != 0)
						{
							var tempBasalAreaWidth:Number = Math.abs(endXAreaValue - startXTempAreaValue);
							
							var tempBasalArea:Quad = new Quad(tempBasalAreaWidth, Math.abs(startYTempAreaValue), tempBasalAreaColor);
							tempBasalArea.x = startXTempAreaValue - tempBasalAreaWidth;
							tempBasalArea.y = -startYTempAreaValue;
							tempBasalArea.addEventListener(TouchEvent.TOUCH, onBasalAreaTouched);
							basalsContainer.addChild(tempBasalArea);
							
							basalAreasList.push(tempBasalArea);
							
							//Label
							if (previousTempBasalAreaProps != null && previousTempBasalAreaProps.basalTreatment != null)
							{
								var selectedBasalTreatment:Treatment = previousTempBasalAreaProps.basalTreatment;
								var selectedBasalInsulin:Insulin = ProfileManager.getInsulin(selectedBasalTreatment.insulinID);
								if (selectedBasalTreatment != null)
								{
									var areaLabelString:String = "";
									
									if (selectedBasalInsulin != null)
									{
										areaLabelString = selectedBasalInsulin.name + " " + "(" + previousTempBasalAreaProps.basalAmount + "U" + " - " + (Math.round(previousTempBasalAreaProps.basalAmount/(selectedBasalTreatment.basalDuration / 60) * 100) / 100) + "U/h" + ")";
									}
									else
									{
										areaLabelString = previousTempBasalAreaProps.basalAmount + "U" + " - " + (Math.round(previousTempBasalAreaProps.basalAmount/(selectedBasalTreatment.basalDuration / 60) * 100) / 100) + "U/h";
									}
									
									var basalLabel:Label = LayoutFactory.createLabel(areaLabelString, HorizontalAlign.CENTER, VerticalAlign.TOP, 10);
									basalLabel.validate();
									
									if (tempBasalAreaWidth < basalLabel.width + 10)
									{
										basalLabel.text = previousTempBasalAreaProps.basalAmount + "U";
										basalLabel.validate();
									}
									
									while (tempBasalArea.height <= basalLabel.height)
									{
										if (basalLabel.fontStyles != null)
										{
											if (basalLabel.fontStyles.size > 6)
											{
												basalLabel.fontStyles.size -= 1;
												basalLabel.validate();
											}
											else
											{
												break;
											}
										}
										else
										{
											break;
										}
									}
									
									if (tempBasalAreaWidth >= basalLabel.width + 10 && tempBasalArea.height > basalLabel.height)
									{
										basalLabel.x = tempBasalArea.x + ((tempBasalAreaWidth - basalLabel.width) / 2);
										basalLabel.y = tempBasalArea.y + ((tempBasalArea.height - basalLabel.height) / 2);
										basalLabel.touchable = false;
										
										basalsContainer.addChild(basalLabel);
										basalLabelsList.push(basalLabel);
										mdiBasalLabelPropertiesMap[tempBasalArea.x] = basalLabel;
									}
									else
									{
										basalLabel.dispose();
										basalLabel = null;
									}
								}
							}
							
							if (previousTempBasalAreaProps != null)
							{
								mdiBasalAreaPropertiesMap[tempBasalArea.x] = previousTempBasalAreaProps;
							}
						}
						
						//Reset
						if (endYAreaValue == 0)
						{
							startXTempAreaValue = 0;
							startYTempAreaValue = 0;
						}
						else
						{
							startXTempAreaValue = endXAreaValue;
							startYTempAreaValue = endYAreaValue;
						}
					}
				}
				
				//Save temp basal areas variables state
				prevTempBasalAreaValue = tempBasalAreaValue;
				
				previousTempBasalAreaProps = {}
				previousTempBasalAreaProps.basalAmount = basalProperties.mdiBasalAmount;
				previousTempBasalAreaProps.basalDuration = basalProperties.mdiBasalDuration;
				previousTempBasalAreaProps.timestamp = basalProperties.mdiBasalTime;
				previousTempBasalAreaProps.basalTreatment = basalProperties.mdiBasalTreatment;
				previousTempBasalAreaProps.hasOverlap = basalProperties.hasOverlap;
				previousTempBasalAreaProps.basalTreatmentsList = basalProperties.mdiBasalTreatmentsList;
			}
			
			//Render absolute basal line
			var numberOfLinePoints:Number = absoluteBasalDataPointsArray.length;
			if (numberOfLinePoints > 0)
			{
				//Create and configure line
				basalAbsoluteLine = new SpikeLine();
				basalAbsoluteLine.lineStyle(1.5, basalLineColor);
				basalAbsoluteLine.moveTo(0, absoluteBasalDataPointsArray[0].y);
				
				//Loop line data points
				var prevAbsoluteLinePoint:Object;
				for (i= 0; i < numberOfLinePoints; i++) 
				{
					//Plot line
					var absoluteLinePoint:Object = absoluteBasalDataPointsArray[i];
					basalAbsoluteLine.lineTo(absoluteLinePoint.x, absoluteLinePoint.y);
					basalAbsoluteLine.moveTo(absoluteLinePoint.x, absoluteLinePoint.y);
					
					prevAbsoluteLinePoint = absoluteLinePoint;
				}
				
				//Close Absolute Line Graphic
				if (prevAbsoluteLinePoint != null)
				{
					basalAbsoluteLine.lineTo(prevAbsoluteLinePoint.x, 0);
				}
				
				//Add line to display list
				basalsContainer.addChild(basalAbsoluteLine);
				basalLinesList.push(basalAbsoluteLine);
			}
		}
		
		private function renderPumpBasals(basalsSource:Array = null):void
		{
			//Validation
			if (!displayPumpBasals || !SystemUtil.isApplicationActive || firstBGReadingTimeStamp == 0)
			{
				return;
			}
			
			var sourceForBasals:Array = basalsSource != null ? basalsSource : TreatmentsManager.basalsList;
			
			//Dispose previous basals
			disposeBasalCallout();
			disposeBasals();
			
			//Setup initial timeline/mask properties
			if (basalsFirstRun && basalsContainer == null)
			{
				basalsFirstRun = false;
				basalsContainer = new Sprite();
				basalsContainer.x = mainChart.x;
				basalsContainer.y = glucoseDelimiter.height;
				mainChartContainer.addChildAt(basalsContainer, 0);
			}
			
			var numberOfBasals:uint = sourceForBasals.length;
			if (ProfileManager.basalRatesList.length == 0 && numberOfBasals == 0)
			{
				if (mainChart != null)
				{
					//Create and configure line
					basalAbsoluteLine = new SpikeLine();
					basalAbsoluteLine.lineStyle(1.5, basalLineColor);
					basalAbsoluteLine.moveTo(0, 0);
					basalAbsoluteLine.lineTo(predictionsEnabled && predictionsMainGlucoseDataPoints.length > 0 ? mainChart.width + Constants.stageWidth : mainChart.width, 0);
					
					//Add line to display list
					basalsContainer.addChild(basalAbsoluteLine);
					basalLinesList.push(basalAbsoluteLine);
				}
				
				return;
			}
			
			//Common variables
			var now:Number = new Date().valueOf();
			var i:int
			lastTimePumpBasalWasRendered = now;
			tempBasalAreaPropertiesMap = {};
			
			//Data variables
			var fromTime:Number = firstBGReadingTimeStamp != 0 ? firstBGReadingTimeStamp : now - TimeSpan.TIME_24_HOURS;
			var toTime:Number = !displayLatestBGValue && !isHistoricalData ? now + (mainChartGlucoseMarkerRadius/mainChartXFactor) : firstBGReadingTimeStamp + (Math.abs(mainChart.x - (_graphWidth - yAxisMargin - (predictionsEnabled && predictionsDelimiter != null ? glucoseDelimiter.x - predictionsDelimiter.x : 0))) / mainChartXFactor);
			
			var numberOfPredictions:uint = predictionsMainGlucoseDataPoints.length;
			if (predictionsEnabled && numberOfPredictions > 0 && !isHistoricalData)
			{
				var lastPredictionMarker:GlucoseMarker = predictionsMainGlucoseDataPoints[numberOfPredictions - 1];
				if (lastPredictionMarker != null)
				{
					toTime = lastPredictionMarker.bgReading.timestamp + ((mainChartGlucoseMarkerRadius * 2)/mainChartXFactor);
				}
			}
			
			if (isNaN(toTime)) toTime = now;
			var suggestedAbsoluteBasalIndex:Number = Number.NaN;
			
			//Scheduled Basals Sorting
			var scheduledBasalRatesPointsList:Array = [];
			var scheduledHighestBasal:Number = 0;
			var numberOfBasalRates:uint = ProfileManager.basalRatesList.length;
			if (numberOfBasalRates > 0)
			{
				ProfileManager.basalRatesList.sortOn(["basalRate"], Array.NUMERIC);
				scheduledHighestBasal = ProfileManager.basalRatesList[numberOfBasalRates - 1].basalRate;
				ProfileManager.basalRatesList.sortOn(["startTime"], Array.CASEINSENSITIVE);
			}
			
			//Temp Basals Sorting
			sourceForBasals.sortOn(["timestamp"], Array.NUMERIC);
			var highestBasalAmount:Number = Math.max(TreatmentsManager.getHighestBasal(Treatment.TYPE_TEMP_BASAL, sourceForBasals, isHistoricalData), scheduledHighestBasal);
			
			//Temp Basal Area Calculation & Plotting
			ProfileManager.totalDeliveredPumpBasalAmount = 0;
			var absoluteBasalDataPointsArray:Array = [];
			var desiredBasalHeight:Number = _graphHeight * basalAreaSizePercentage;
			basalScaler = desiredBasalHeight / highestBasalAmount;
			var prevTempBasalAreaValue:Number = 0;
			var prevAbsoluteBasalAreaValue:Number = 0;
			var startXTempAreaValue:Number = 0;
			var startYTempAreaValue:Number = 0;
			var superStartYTempAreaValue:Number = 0;
			var startXAbsoluteAreaValue:Number = 0;
			var startYAbsoluteAreaValue:Number = 0;
			var previousTempBasalAreaProps:Object;
			var prevXAbsoluteValue:Number = Number.NaN;
			var prevYAbsoluteValue:Number = Number.NaN;
			var prevXScheduledValue:Number = Number.NaN;
			var prevYScheduledValue:Number = Number.NaN;
			var isUserAFollower:Boolean = CGMBlueToothDevice.isFollower() && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FOLLOWER_MODE) == "Nightscout";
			lastNumberOfRenderedBasals = numberOfBasals;
			
			for (var time:Number = toTime; time >= fromTime - TimeSpan.TIME_1_MINUTE; time -= TimeSpan.TIME_1_MINUTE) 
			{
				//Gather Basal Data
				var basalProperties:Object = ProfileManager.getPumpBasalData(time, isUserAFollower, suggestedAbsoluteBasalIndex);
				
				//Calculate Coordinates (Area & Basal Amount)
				var tempBasalAreaValue:Number = basalProperties.tempBasalAreaAmount;
				var xTempBasalAreaValue:Number = (time - firstBGReadingTimeStamp) * mainChartXFactor;
				var yTempBasalAreaValue:Number = tempBasalAreaValue * basalScaler;
				
				var tempBasalAmountValue:Number = basalProperties.tempBasalAmount;
				var xTempBasalAmountValue:Number = xTempBasalAreaValue;
				var yTempBasalAmountValue:Number = tempBasalAmountValue * basalScaler * -1;
				
				if (time < fromTime)
				{
					tempBasalAreaValue = 0;
					xTempBasalAreaValue = -1;
					yTempBasalAreaValue = 0;
					
					tempBasalAmountValue = 0;
					xTempBasalAmountValue = -1;
					yTempBasalAmountValue = 0;
				}
				
				//Save absolute basal line data points
				if (yTempBasalAmountValue != prevYAbsoluteValue)
				{
					if (!isNaN(prevYAbsoluteValue))
					{
						absoluteBasalDataPointsArray.unshift( { x: xTempBasalAmountValue, y: prevYAbsoluteValue } );
					}
					
					absoluteBasalDataPointsArray.unshift( { x: xTempBasalAmountValue, y: yTempBasalAmountValue } );
				}
				
				//Save absolute variables state for next iteration
				prevXAbsoluteValue = xTempBasalAmountValue;
				prevYAbsoluteValue = yTempBasalAmountValue;
				
				//Render temp basal areas
				if (tempBasalAreaValue != prevTempBasalAreaValue)
				{
					if (startXTempAreaValue == 0 && startYTempAreaValue == 0)
					{
						startXTempAreaValue = xTempBasalAreaValue;
						startYTempAreaValue = yTempBasalAreaValue;
					}
					else
					{
						//Translate coordinates
						var endXAreaValue:Number = xTempBasalAreaValue;
						var endYAreaValue:Number = yTempBasalAreaValue;
						
						//Create Quad
						if (startYTempAreaValue != 0)
						{
							var tempBasalAreaWidth:Number = Math.abs(endXAreaValue - startXTempAreaValue);
							
							var tempBasalArea:Quad = new Quad(tempBasalAreaWidth, Math.abs(startYTempAreaValue), tempBasalAreaColor);
							tempBasalArea.x = startXTempAreaValue - tempBasalAreaWidth;
							tempBasalArea.y = -startYTempAreaValue;
							tempBasalArea.addEventListener(TouchEvent.TOUCH, onBasalAreaTouched);
							basalsContainer.addChild(tempBasalArea);
							
							basalAreasList.push(tempBasalArea);
							
							if (previousTempBasalAreaProps != null)
							{
								tempBasalAreaPropertiesMap[tempBasalArea.x] = previousTempBasalAreaProps;
							}
						}
						
						//Reset
						superStartYTempAreaValue = startYTempAreaValue;
						if (endYAreaValue == 0)
						{
							startXTempAreaValue = 0;
							startYTempAreaValue = 0;
						}
						else
						{
							startXTempAreaValue = endXAreaValue;
							startYTempAreaValue = endYAreaValue;
						}
					}
				}
				
				//Save temp basal areas variables state
				prevTempBasalAreaValue = tempBasalAreaValue;
				suggestedAbsoluteBasalIndex = basalProperties.tempBasalIndex;
				
				previousTempBasalAreaProps = {}
				previousTempBasalAreaProps.basalAmount = basalProperties.tempBasalAreaAmount;
				previousTempBasalAreaProps.timestamp = basalProperties.tempBasalTime;
				if (basalProperties.tempBasalTreatment != null && basalProperties.tempBasalTreatment.isBasalRelative == true)
				{
					previousTempBasalAreaProps.basalPercentage = basalProperties.tempBasalTreatment.basalPercentAmount;
				}
				previousTempBasalAreaProps.basalTreatment = basalProperties.tempBasalTreatment;
				
				//Render absolute basal areas
				if (tempBasalAmountValue != prevAbsoluteBasalAreaValue)
				{
					if (startXAbsoluteAreaValue == 0 && startYAbsoluteAreaValue == 0)
					{
						startXAbsoluteAreaValue = xTempBasalAmountValue;
						startYAbsoluteAreaValue = -yTempBasalAmountValue;
					}
					else
					{
						//Translate coordinates
						var endXAbsoluteAreaValue:Number = xTempBasalAmountValue;
						var endYAbsoluteAreaValue:Number = -yTempBasalAmountValue;
						
						//Create Quad
						if (startYAbsoluteAreaValue != 0 && startYAbsoluteAreaValue != superStartYTempAreaValue)
						{
							var tempAbsoluteBasalAreaWidth:Number = Math.abs(endXAbsoluteAreaValue - startXAbsoluteAreaValue);
							
							var tempAbsoluteBasalArea:Quad = new Quad(tempAbsoluteBasalAreaWidth, Math.abs(startYAbsoluteAreaValue), basalAreaColor);
							tempAbsoluteBasalArea.x = startXAbsoluteAreaValue - tempAbsoluteBasalAreaWidth;
							tempAbsoluteBasalArea.y = -startYAbsoluteAreaValue;
							basalsContainer.addChild(tempAbsoluteBasalArea);
							
							basalAreasList.push(tempAbsoluteBasalArea);
						}
						
						//Reset
						if (endYAbsoluteAreaValue == 0)
						{
							startXAbsoluteAreaValue = 0;
							startYAbsoluteAreaValue = 0;
						}
						else
						{
							startXAbsoluteAreaValue = endXAbsoluteAreaValue;
							startYAbsoluteAreaValue = endYAbsoluteAreaValue;
						}
					}
				}
				
				//Save absolute basal areas variables state
				prevAbsoluteBasalAreaValue = tempBasalAmountValue;
				
				//Calculate Schedule Basals Data Points
				if (numberOfBasalRates > 0)
				{
					var scheduledBasalRate:Number = basalProperties.scheduledBasalRate;
					if (!isNaN(scheduledBasalRate))
					{
						//Gather calculation data
						var xScheduledValue:Number = (time - firstBGReadingTimeStamp) * mainChartXFactor;
						var yScheduledValue:Number = scheduledBasalRate * basalScaler * -1;
						
						if (yScheduledValue != prevYScheduledValue)
						{
							if (!isNaN(prevYScheduledValue))
							{
								scheduledBasalRatesPointsList.unshift( { x: xScheduledValue, y: prevYScheduledValue } );
							}
							
							scheduledBasalRatesPointsList.unshift( { x: xScheduledValue, y: yScheduledValue } );
						}
						
						//Save variables state
						prevXScheduledValue = xScheduledValue;
						prevYScheduledValue = yScheduledValue;
					}
				}
			}
			
			//Render absolute basal line
			var numberOfLinePoints:Number = absoluteBasalDataPointsArray.length;
			if (numberOfLinePoints > 0)
			{
				//Create and configure line
				basalAbsoluteLine = new SpikeLine();
				basalAbsoluteLine.lineStyle(1.5, basalLineColor);
				basalAbsoluteLine.moveTo(0, absoluteBasalDataPointsArray[0].y);
				
				//Loop line data points
				var prevAbsoluteLinePoint:Object;
				for (i= 0; i < numberOfLinePoints; i++) 
				{
					//Plot line
					var absoluteLinePoint:Object = absoluteBasalDataPointsArray[i];
					basalAbsoluteLine.lineTo(absoluteLinePoint.x, absoluteLinePoint.y);
					basalAbsoluteLine.moveTo(absoluteLinePoint.x, absoluteLinePoint.y);
					
					prevAbsoluteLinePoint = absoluteLinePoint;
				}
				
				//Close Absolute Line Graphic
				if (prevAbsoluteLinePoint != null)
				{
					basalAbsoluteLine.lineTo(prevAbsoluteLinePoint.x, 0);
				}
				
				//Add line to display list
				basalsContainer.addChild(basalAbsoluteLine);
				basalLinesList.push(basalAbsoluteLine);
			}
			
			//Plot scheduled basals line
			var numberOfScheduledLinePoints:Number = scheduledBasalRatesPointsList.length;
			if (numberOfScheduledLinePoints > 0)
			{
				//Constants
				const lineThickness:uint = 1;
				const sizeOfDash:uint = 2;
				const sizeOfGap:uint = 2;
				
				//Create and configure line
				basalScheduledLine = new SpikeLine();
				basalScheduledLine.lineStyle(lineThickness, basalRateLineColor);
				basalScheduledLine.moveTo(0, scheduledBasalRatesPointsList[0].y);
				
				//Loop line data points
				for (i = -1; i < numberOfScheduledLinePoints - 1; i++) 
				{
					var startPoint:Object = i >= 0 ? scheduledBasalRatesPointsList[i] : { x: 0, y: scheduledBasalRatesPointsList[0].y };
					var endPoint:Object = scheduledBasalRatesPointsList[i+1];
					
					if (startPoint.y == endPoint.y)
					{
						//Horizontal
						var horizontalDashedLineTotalWidth:Number = Math.abs(endPoint.x - startPoint.x - lineThickness);
						var numHorizontalDashedLines:Number = Math.ceil(horizontalDashedLineTotalWidth/(sizeOfDash + sizeOfGap));
						var realSizeOfHorizontalDash:Number = (horizontalDashedLineTotalWidth - ((numHorizontalDashedLines - 1) * sizeOfGap)) / numHorizontalDashedLines;
						var currentHorizontalLineX:Number = startPoint.x;
						
						for (var j:int = 0; j < numHorizontalDashedLines; j++)
						{
							basalScheduledLine.moveTo(currentHorizontalLineX, endPoint.y);
							basalScheduledLine.lineTo(currentHorizontalLineX + realSizeOfHorizontalDash, endPoint.y);
							
							currentHorizontalLineX += realSizeOfHorizontalDash + sizeOfGap;
						}
					}
					else
					{
						//Vertical
						var verticalDashedLineTotalHeight:Number = Math.abs(endPoint.y - startPoint.y);
						var numVerticalDashedLines:Number = Math.ceil(verticalDashedLineTotalHeight/(sizeOfDash + sizeOfGap));
						var realSizeOfVerticalDash:Number = (verticalDashedLineTotalHeight - ((numVerticalDashedLines - 1) * sizeOfGap)) / numVerticalDashedLines;
						var currentVerticalLineY:Number = startPoint.y;
						
						for (var k:int = 0; k <numVerticalDashedLines; k++)
						{
							basalScheduledLine.moveTo(startPoint.x, currentVerticalLineY);
							if (endPoint.y >= startPoint.y)
							{
								basalScheduledLine.lineTo(endPoint.x, currentVerticalLineY + realSizeOfVerticalDash);
								currentVerticalLineY += realSizeOfVerticalDash + sizeOfGap;
							}
							else
							{
								basalScheduledLine.lineTo(endPoint.x, currentVerticalLineY - realSizeOfVerticalDash);
								currentVerticalLineY -= realSizeOfVerticalDash + sizeOfGap;
							}
						}
					}
				}
				
				//Add line to display list
				basalsContainer.addChild(basalScheduledLine);
				basalLinesList.push(basalScheduledLine);
			}
		}
		
		private function onBasalAreaTouched(e:starling.events.TouchEvent):void
		{
			var touch:Touch = e.getTouch(stage);
			if (touch != null && touch.phase == TouchPhase.BEGAN) 
			{
				activeBasalAreaQuad = e.currentTarget as Quad;
				if (activeBasalAreaQuad != null)
				{
					var basalProps:Object = displayPumpBasals ? tempBasalAreaPropertiesMap[activeBasalAreaQuad.x] : mdiBasalAreaPropertiesMap[activeBasalAreaQuad.x];
					if (basalProps != null)
					{
						//Visual Filter
						activeBasalAreaQuad.removeFromParent();
						basalsContainer.addChild(activeBasalAreaQuad);
						activeBasalAreaQuad.filter = new GlowFilter(0xEEEEEE, 2, 4, 1);
						
						//Reposition Basal Label
						if (displayMDIBasals)
						{
							var basalLabel:Label = mdiBasalLabelPropertiesMap[activeBasalAreaQuad.x];
							if (basalLabel != null)
							{
								basalLabel.removeFromParent();
								basalsContainer.addChild(basalLabel);
							}
						}
						
						//Basal Callout
						displayBasalCallout(basalProps, activeBasalAreaQuad);
					}
				}
			}
		}
		
		private function displayBasalCallout(basalProps:Object, origin:Quad):void
		{
			if (!SystemUtil.isApplicationActive || dummyModeActive || !treatmentsActive || !displayTreatmentsOnChart)
				return;
			
			if (basalCallout != null)
			{
				basalCallout.removeFromParent(true);
			}
			
			//Layout Container
			var treatmentLayout:VerticalLayout = new VerticalLayout();
			treatmentLayout.horizontalAlign = HorizontalAlign.CENTER;
			treatmentLayout.gap = 10;
			if (treatmentContainer != null) treatmentContainer.removeFromParent(true);
			treatmentContainer = new LayoutGroup();
			treatmentContainer.layout = treatmentLayout;
			
			//Basal Properties
			var treatmentValue:String = "";
			if (displayPumpBasals)
			{
				treatmentValue = ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_temp_basal') + "\n" + ModelLocator.resourceManagerInstance.getString('treatments','basal_amount_label') + ":" + " " + GlucoseFactory.formatIOB(basalProps.basalAmount) + (basalProps.basalPercentage != null ? " " + "(" + (basalProps.basalPercentage > 0 ? "+" : "") + basalProps.basalPercentage + "%" + ")" : "");
			}
			else if (displayMDIBasals)
			{
				var bTreatment:Treatment;
				var basalInsulin:Insulin;
				
				if (basalProps != null && basalProps.hasOverlap == false)
				{
					bTreatment = basalProps.basalTreatment;
					if (bTreatment != null)
					{
						basalInsulin = ProfileManager.getInsulin(bTreatment.insulinID);
						if (basalInsulin != null)
						{
							treatmentValue = ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_basal') + "\n\n" + ModelLocator.resourceManagerInstance.getString('treatments','treatment_insulin_label') + ":" + " " + basalInsulin.name + "\n" + ModelLocator.resourceManagerInstance.getString('treatments','basal_amount_label') + ":" + " " + GlucoseFactory.formatIOB(basalProps.basalAmount) + "\n" + ModelLocator.resourceManagerInstance.getString('treatments','basal_delivery_rate') + ":" + " " + (Math.round((bTreatment.basalAbsoluteAmount / (bTreatment.basalDuration / 60) * 100)) / 100) + ModelLocator.resourceManagerInstance.getString('treatments','basal_units_per_hour') + "\n" + ModelLocator.resourceManagerInstance.getString('treatments','exercise_duration_label') + ":" + " " + TimeSpan.formatHoursMinutesFromMinutes(basalProps.basalDuration, false);
						}
						else
						{
							treatmentValue = ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_basal') + "\n\n" + ModelLocator.resourceManagerInstance.getString('treatments','basal_amount_label') + ":" + " " + GlucoseFactory.formatIOB(basalProps.basalAmount) + "\n" + ModelLocator.resourceManagerInstance.getString('treatments','basal_delivery_rate') + ":" + " " + (Math.round((bTreatment.basalAbsoluteAmount / (bTreatment.basalDuration / 60) * 100)) / 100) + ModelLocator.resourceManagerInstance.getString('treatments','basal_units_per_hour') + "\n" + ModelLocator.resourceManagerInstance.getString('treatments','exercise_duration_label') + ":" + " " + TimeSpan.formatHoursMinutesFromMinutes(basalProps.basalDuration, false);
						}
					}
					else
					{
						treatmentValue = ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_basal') + "\n\n" + ModelLocator.resourceManagerInstance.getString('treatments','basal_amount_label') + ":" + " " + GlucoseFactory.formatIOB(basalProps.basalAmount) + "\n" + ModelLocator.resourceManagerInstance.getString('treatments','exercise_duration_label') + ":" + " " + TimeSpan.formatHoursMinutesFromMinutes(basalProps.basalDuration, false);
					}
				}
				else if (basalProps != null && basalProps.hasOverlap == true && basalProps.basalTreatmentsList != null)
				{
					var overlappedTreatmentsList:Array = basalProps.basalTreatmentsList;
					var amountsList:Array = [];
					var totalBasalRate:Number = 0;
					var basalRatesStringsList:Array = [];
					
					for (var i:int = 0; i < overlappedTreatmentsList.length; i++) 
					{
						var overlappedTreatment:Treatment = overlappedTreatmentsList[i];
						
						if (overlappedTreatment != null)
						{
							amountsList.push(String(Math.round(overlappedTreatment.basalAbsoluteAmount * 100) / 100) + "U");
							totalBasalRate += overlappedTreatment.basalAbsoluteAmount / (overlappedTreatment.basalDuration / 60);
							basalRatesStringsList.push((Math.round((overlappedTreatment.basalAbsoluteAmount / (overlappedTreatment.basalDuration / 60)) * 100) / 100) + ModelLocator.resourceManagerInstance.getString('treatments','basal_units_per_hour'));
						}
					}
					
					var combinedAmounts:String = amountsList.join(" + ");
					if (combinedAmounts == null) combinedAmounts = "";
					totalBasalRate = Math.round(totalBasalRate * 100) / 100;
					var combinedBasalRates:String = basalRatesStringsList.join(" + ");
					if (combinedBasalRates == null) combinedBasalRates = "";
					
					bTreatment = basalProps.basalTreatment;
					if (bTreatment != null)
					{
						basalInsulin = ProfileManager.getInsulin(bTreatment.insulinID);
						if (basalInsulin != null)
						{
							treatmentValue = ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_basal') + "\n\n" + ModelLocator.resourceManagerInstance.getString('treatments','treatment_insulin_label') + ":" + " " + basalInsulin.name + "\n" + ModelLocator.resourceManagerInstance.getString('treatments','basal_amount_label') + ":" + " " + GlucoseFactory.formatIOB(basalProps.basalAmount) + " " + "(" + combinedAmounts + ")" + "\n" + ModelLocator.resourceManagerInstance.getString('treatments','basal_delivery_rate') + ":" + " " + totalBasalRate + ModelLocator.resourceManagerInstance.getString('treatments','basal_units_per_hour') + " " + "(" + combinedBasalRates + ")" + "\n" + ModelLocator.resourceManagerInstance.getString('treatments','exercise_duration_label') + ":" + " " + TimeSpan.formatHoursMinutesFromMinutes(basalProps.basalDuration, false);
						}
						else
						{
							treatmentValue = ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_basal') + "\n\n" + ModelLocator.resourceManagerInstance.getString('treatments','basal_amount_label') + ":" + " " + GlucoseFactory.formatIOB(basalProps.basalAmount) + " " + "(" + combinedAmounts + ")" + "\n" + ModelLocator.resourceManagerInstance.getString('treatments','basal_delivery_rate') + ":" + " " + totalBasalRate + ModelLocator.resourceManagerInstance.getString('treatments','basal_units_per_hour') + " " + "(" + combinedBasalRates + ")" + "\n" + ModelLocator.resourceManagerInstance.getString('treatments','exercise_duration_label') + ":" + " " + TimeSpan.formatHoursMinutesFromMinutes(basalProps.basalDuration, false);
						}
					}
					else
					{
						treatmentValue = ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_basal') + "\n\n" + ModelLocator.resourceManagerInstance.getString('treatments','basal_amount_label') + ":" + " " + GlucoseFactory.formatIOB(basalProps.basalAmount) + " " + "(" + combinedAmounts + ")" + "\n" + ModelLocator.resourceManagerInstance.getString('treatments','basal_delivery_rate') + ":" + " " + totalBasalRate + ModelLocator.resourceManagerInstance.getString('treatments','basal_units_per_hour') + " " + "(" + combinedBasalRates + ")" + "\n" + ModelLocator.resourceManagerInstance.getString('treatments','exercise_duration_label') + ":" + " " + TimeSpan.formatHoursMinutesFromMinutes(basalProps.basalDuration, false);
					}
				}
			}
			
			var treatmentNotes:String = basalProps.basalTreatment != null ? basalProps.basalTreatment.note : "";
			
			if (treatmentValue != "")
			{
				if (treatmentValueLabel != null) treatmentValueLabel.removeFromParent(true);
				treatmentValueLabel = LayoutFactory.createLabel(treatmentValue, HorizontalAlign.CENTER, VerticalAlign.TOP, 14, true);
				treatmentValueLabel.paddingBottom = 12;
				treatmentContainer.addChild(treatmentValueLabel);
			}
			
			//Treatment Time
			if (treatmentTimeSpinner != null) treatmentTimeSpinner.removeFromParent(true);
			treatmentTimeSpinner = new DateTimeSpinner();
			treatmentTimeSpinner.editingMode = DateTimeMode.TIME;
			treatmentTimeSpinner.locale = Constants.getUserLocale(true);
			treatmentTimeSpinner.value = new Date(basalProps.timestamp);
			treatmentTimeSpinner.height = 30;
			treatmentTimeSpinner.paddingTop = treatmentTimeSpinner.paddingBottom = 0;
			
			if (isHistoricalData) treatmentTimeSpinner.isEnabled = false;
			if (timeSpacer != null) timeSpacer.removeFromParent(true);
			timeSpacer = new Sprite();
			timeSpacer.height = 10;
			treatmentContainer.addChild(treatmentTimeSpinner);
			treatmentContainer.addChild(timeSpacer);
			
			//Notes
			if (treatmentNotes != "")
			{
				if (treatmentNoteLabel != null) treatmentNoteLabel.removeFromParent(true);
				treatmentNoteLabel = LayoutFactory.createLabel(treatmentNotes, HorizontalAlign.CENTER, VerticalAlign.TOP);
				treatmentNoteLabel.wordWrap = true;
				treatmentNoteLabel.maxWidth = 150;
				treatmentContainer.addChild(treatmentNoteLabel);
			}
			
			//Action Buttons
			if (!isHistoricalData)
			{
				if (!CGMBlueToothDevice.isFollower() || (CGMBlueToothDevice.isFollower() && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_URL) != "" && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_API_SECRET) != "" && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FOLLOWER_MODE) == "Nightscout"))
				{
					if (moveBtn != null) moveBtn.removeFromParent(true);
					if (deleteBtn != null) deleteBtn.removeFromParent(true);
					var actionsLayout:HorizontalLayout = new HorizontalLayout();
					actionsLayout.gap = 5;
					if (actionsContainer != null) actionsContainer.removeFromParent(true);
					actionsContainer = new LayoutGroup();
					actionsContainer.layout = actionsLayout;
					
					moveBtn = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('treatments','move_button_label'));
					moveBtn.addEventListener(starling.events.Event.TRIGGERED, onMove);
					actionsContainer.addChild(moveBtn);
					
					deleteBtn = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('treatments','delete_button_label'));
					deleteBtn.addEventListener(starling.events.Event.TRIGGERED, onDelete);
					actionsContainer.addChild(deleteBtn);
					
					treatmentContainer.addChild(actionsContainer);
				}
			}
			
			if (treatmentCallout != null) treatmentCallout.dispose();
			treatmentCallout = Callout.show(treatmentContainer, origin, new <String>[RelativePosition.TOP], true);
			treatmentCallout.addEventListener(starling.events.Event.CLOSE, disposeBasalCallout);
			
			
			function onDelete(e:starling.events.Event):void
			{
				if (basalProps != null && basalProps.basalTreatment != null)
				{
					activeBasalAreaQuad = null;
					TreatmentsManager.deleteTreatment(basalProps.basalTreatment);
				}
				
				if (treatmentCallout != null)
				{
					treatmentCallout.close();
				}
			}
			
			function onMove(e:starling.events.Event):void
			{
				var movedTimestamp:Number = treatmentTimeSpinner.value.valueOf();
				var maxMovedTimestamp:Number = new Date().valueOf();
				
				if(movedTimestamp < firstBGReadingTimeStamp || movedTimestamp > maxMovedTimestamp)
				{
					AlertManager.showSimpleAlert
					(
						ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
						ModelLocator.resourceManagerInstance.getString('treatments','out_of_bounds_treatment')
					);
				}
				else
				{
					if (basalProps != null && basalProps.basalTreatment != null)
					{
						//Update Basal
						activeBasalAreaQuad = null;
						basalProps.basalTreatment.timestamp = movedTimestamp;
						TreatmentsManager.updateTreatment(basalProps.basalTreatment);
					}
					
					if (treatmentCallout != null)
					{
						treatmentCallout.close();
					}
				}
			}
		}
		
		public function addTreatment(treatment:Treatment):void
		{
			if (dummyModeActive || !treatmentsActive || !displayTreatmentsOnChart)
				return;
			
			//Setup initial timeline/mask properties
			if (treatmentsFirstRun && treatmentsContainer == null)
			{
				treatmentsFirstRun = false;
				treatmentsContainer = new Sprite();
				treatmentsContainer.x = mainChart.x;
				treatmentsContainer.y = mainChart.y;
				mainChartContainer.addChild(treatmentsContainer);
				mainChartContainer.addChild(mainChart);
				if (displayRaw) mainChartContainer.addChild(rawDataContainer);
			}
			
			//Validations
			if (treatment == null)
				return;
			
			if (treatmentsMap[treatment.ID] != null)
				return; //Treatment was already added previously
			
			//Common variables
			var chartTreatment:ChartTreatment;
			
			//Check treatment type
			if (treatment.type == Treatment.TYPE_BOLUS || treatment.type == Treatment.TYPE_CORRECTION_BOLUS || treatment.type == Treatment.TYPE_EXTENDED_COMBO_BOLUS_PARENT)
			{
				//Create treatment marker and add it to the chart
				var insulinMarker:InsulinMarker = new InsulinMarker(treatment, timelineRange, false, treatment.type == Treatment.TYPE_EXTENDED_COMBO_BOLUS_PARENT);
				insulinMarker.x = (insulinMarker.treatment.timestamp - firstBGReadingTimeStamp) * mainChartXFactor;
				insulinMarker.y = _graphHeight - (insulinMarker.radius * 1.66) - ((insulinMarker.treatment.glucoseEstimated - lowestGlucoseValue) * mainChartYFactor);
				
				insulinMarker.index = treatmentsList.length;
				treatmentsList.push(insulinMarker);
				treatmentsMap[treatment.ID] = insulinMarker;
				
				//Find and store children
				if (treatment.type == Treatment.TYPE_EXTENDED_COMBO_BOLUS_PARENT)
				{
					parseChildTreatments(insulinMarker);
				}
				
				if (displayIOBEnabled && !isHistoricalData)
				{
					clearTimeout(totalIOBTimeoutID);
					
					totalIOBTimeoutID = setTimeout( function():void 
					{
						calculateTotalIOB(getTimelineTimestamp());
					}, 200 );
					
					if (predictionsEnabled)
					{
						clearTimeout(redrawPredictionsTimeoutID);
						
						redrawPredictionsTimeoutID = setTimeout( function():void 
						{
							redrawPredictions();
						}, 250 );
					}
				}
				
				chartTreatment = insulinMarker;
			}
			else if (treatment.type == Treatment.TYPE_EXTENDED_COMBO_BOLUS_CHILD)
			{
				//Create treatment marker and add it to the chart
				var extendedInsulinChildMarker:InsulinMarker = new InsulinMarker(treatment, timelineRange, true, true);
				extendedInsulinChildMarker.x = (extendedInsulinChildMarker.treatment.timestamp - firstBGReadingTimeStamp) * mainChartXFactor;
				extendedInsulinChildMarker.y = _graphHeight - (extendedInsulinChildMarker.radius * 1.66) - ((extendedInsulinChildMarker.treatment.glucoseEstimated - lowestGlucoseValue) * mainChartYFactor);
				extendedInsulinChildMarker.filter = new FilterChain(new GlowFilter(extendedInsulinChildMarker.strokeColor, 1, 2.2, 1), new BlurFilter(!DeviceInfo.isTablet() ? 5 : 10, !DeviceInfo.isTablet() ? 5 : 10, 1))
				
				extendedInsulinChildMarker.index = treatmentsList.length;
				treatmentsList.push(extendedInsulinChildMarker);
				treatmentsMap[treatment.ID] = extendedInsulinChildMarker;
				
				if (displayIOBEnabled && !isHistoricalData && treatment.timestamp <= new Date().valueOf())
				{
					clearTimeout(totalIOBTimeoutID);
					
					totalIOBTimeoutID = setTimeout( function():void 
					{
						calculateTotalIOB(getTimelineTimestamp());
					}, 200 );
					
					if (predictionsEnabled)
					{
						clearTimeout(redrawPredictionsTimeoutID);
						
						redrawPredictionsTimeoutID = setTimeout( function():void 
						{
							redrawPredictions();
						}, 250 );
					}
				}
				
				chartTreatment = extendedInsulinChildMarker;
			}
			else if (treatment.type == Treatment.TYPE_CARBS_CORRECTION)
			{
				//Create treatment marker and add it to the chart
				var carbsMarker:CarbsMarker = new CarbsMarker(treatment, timelineRange);
				carbsMarker.x = (carbsMarker.treatment.timestamp - firstBGReadingTimeStamp) * mainChartXFactor;
				carbsMarker.y = _graphHeight - (carbsMarker.radius * 1.66) - ((carbsMarker.treatment.glucoseEstimated - lowestGlucoseValue) * mainChartYFactor);
				
				carbsMarker.index = treatmentsList.length;
				treatmentsList.push(carbsMarker);
				treatmentsMap[treatment.ID] = carbsMarker;
				
				if (displayCOBEnabled && !isHistoricalData)
				{
					clearTimeout(totalCOBTimeoutID);
					
					totalCOBTimeoutID = setTimeout( function():void 
					{
						calculateTotalCOB(getTimelineTimestamp(), true);
					}, 200 );
					
					if (predictionsEnabled)
					{
						clearTimeout(redrawPredictionsTimeoutID);
						
						redrawPredictionsTimeoutID = setTimeout( function():void 
						{
							redrawPredictions();
						}, 250 );
					}
				}
				
				chartTreatment = carbsMarker;
			}
			else if (treatment.type == Treatment.TYPE_MEAL_BOLUS || treatment.type == Treatment.TYPE_EXTENDED_COMBO_MEAL_PARENT)
			{
				//Create treatment marker and add it to the chart
				var mealMarker:MealMarker = new MealMarker(treatment, timelineRange, treatment.type == Treatment.TYPE_EXTENDED_COMBO_MEAL_PARENT);
				mealMarker.x = (mealMarker.treatment.timestamp - firstBGReadingTimeStamp) * mainChartXFactor;
				mealMarker.y = _graphHeight - (mealMarker.radius * 1.66) - ((mealMarker.treatment.glucoseEstimated - lowestGlucoseValue) * mainChartYFactor);
				
				mealMarker.index = treatmentsList.length;
				treatmentsList.push(mealMarker);
				treatmentsMap[treatment.ID] = mealMarker;
				
				//Find and store children
				if (treatment.type == Treatment.TYPE_EXTENDED_COMBO_MEAL_PARENT)
				{
					parseChildTreatments(mealMarker);
				}
				
				var timelineTimestamp:Number = getTimelineTimestamp();
				if (displayIOBEnabled && !isHistoricalData)
				{
					clearTimeout(totalIOBTimeoutID);
					
					totalIOBTimeoutID = setTimeout( function():void 
					{
						calculateTotalIOB(timelineTimestamp);
					}, 200 );
				}
				if (displayCOBEnabled && !isHistoricalData)
				{
					clearTimeout(totalCOBTimeoutID);
					
					totalCOBTimeoutID = setTimeout( function():void 
					{
						calculateTotalCOB(timelineTimestamp, true);
					}, 200 );
				}
				
				if (predictionsEnabled)
				{
					clearTimeout(redrawPredictionsTimeoutID);
					
					redrawPredictionsTimeoutID = setTimeout( function():void 
					{
						redrawPredictions();
					}, 250 );
				}
				
				chartTreatment = mealMarker;
			}
			else if (treatment.type == Treatment.TYPE_NOTE)
			{
				//Create treatment marker and add it to the chart
				var noteMarker:NoteMarker = new NoteMarker(treatment, timelineRange);
				
				if (noteMarker.treatment.timestamp <= lastBGreadingTimeStamp)
					noteMarker.x = (((noteMarker.treatment.timestamp - firstBGReadingTimeStamp) * mainChartXFactor) + mainChartGlucoseMarkerRadius) - 5;
				else
					noteMarker.x = (((lastBGreadingTimeStamp - firstBGReadingTimeStamp) * mainChartXFactor) + mainChartGlucoseMarkerRadius) - 10;
				
				noteMarker.y = (_graphHeight - noteMarker.height - (mainChartGlucoseMarkerRadius * 3) - ((noteMarker.treatment.glucoseEstimated - lowestGlucoseValue) * mainChartYFactor) + (mainChartGlucoseMarkerRadius / 2)) + 8;
				
				noteMarker.index = treatmentsList.length;
				treatmentsList.push(noteMarker);
				treatmentsMap[treatment.ID] = noteMarker;
				
				chartTreatment = noteMarker;
			}
			else if (treatment.type == Treatment.TYPE_EXERCISE)
			{
				//Create treatment marker and add it to the chart
				var exerciseMarker:ExerciseMarker = new ExerciseMarker(treatment, timelineRange);
				
				exerciseMarker.x = ((exerciseMarker.treatment.timestamp - firstBGReadingTimeStamp) * mainChartXFactor) - (exerciseMarker.width / 2) + (mainChartGlucoseMarkerRadius / 2);
				exerciseMarker.y = (_graphHeight - exerciseMarker.height - (mainChartGlucoseMarkerRadius * 3) - ((exerciseMarker.treatment.glucoseEstimated - lowestGlucoseValue) * mainChartYFactor) + (mainChartGlucoseMarkerRadius / 2)) + 6;
				
				exerciseMarker.index = treatmentsList.length;
				treatmentsList.push(exerciseMarker);
				treatmentsMap[treatment.ID] = exerciseMarker;
				
				chartTreatment = exerciseMarker;
			}
			else if (treatment.type == Treatment.TYPE_INSULIN_CARTRIDGE_CHANGE)
			{
				//Create treatment marker and add it to the chart
				var insulinCartridgeMarker:InsulinCartridgeMarker = new InsulinCartridgeMarker(treatment, timelineRange);
				
				insulinCartridgeMarker.x = ((insulinCartridgeMarker.treatment.timestamp - firstBGReadingTimeStamp) * mainChartXFactor) - (insulinCartridgeMarker.width / 2) + (mainChartGlucoseMarkerRadius / 2);
				insulinCartridgeMarker.y = (_graphHeight - insulinCartridgeMarker.height - (mainChartGlucoseMarkerRadius * 3) - ((insulinCartridgeMarker.treatment.glucoseEstimated - lowestGlucoseValue) * mainChartYFactor) + (mainChartGlucoseMarkerRadius / 2)) + 3;
				
				insulinCartridgeMarker.index = treatmentsList.length;
				treatmentsList.push(insulinCartridgeMarker);
				treatmentsMap[treatment.ID] = insulinCartridgeMarker;
				
				chartTreatment = insulinCartridgeMarker;
			}
			else if (treatment.type == Treatment.TYPE_PUMP_BATTERY_CHANGE)
			{
				//Create treatment marker and add it to the chart
				var pumpBatteryMarker:PumpBatteryMarker = new PumpBatteryMarker(treatment, timelineRange);
				
				pumpBatteryMarker.x = ((pumpBatteryMarker.treatment.timestamp - firstBGReadingTimeStamp) * mainChartXFactor) - (pumpBatteryMarker.width / 2) + (mainChartGlucoseMarkerRadius / 2);
				pumpBatteryMarker.y = (_graphHeight - pumpBatteryMarker.height - (mainChartGlucoseMarkerRadius * 3) - ((pumpBatteryMarker.treatment.glucoseEstimated - lowestGlucoseValue) * mainChartYFactor) + (mainChartGlucoseMarkerRadius / 2)) + 3;
				
				pumpBatteryMarker.index = treatmentsList.length;
				treatmentsList.push(pumpBatteryMarker);
				treatmentsMap[treatment.ID] = pumpBatteryMarker;
				
				chartTreatment = pumpBatteryMarker;
			}
			else if (treatment.type == Treatment.TYPE_PUMP_SITE_CHANGE)
			{
				//Create treatment marker and add it to the chart
				var pumpSiteMarker:PumpSiteMarker = new PumpSiteMarker(treatment, timelineRange);
				
				pumpSiteMarker.x = ((pumpSiteMarker.treatment.timestamp - firstBGReadingTimeStamp) * mainChartXFactor) - (pumpSiteMarker.width / 2) + (mainChartGlucoseMarkerRadius / 2);
				pumpSiteMarker.y = (_graphHeight - pumpSiteMarker.height - (mainChartGlucoseMarkerRadius * 3) - ((pumpSiteMarker.treatment.glucoseEstimated - lowestGlucoseValue) * mainChartYFactor) + (mainChartGlucoseMarkerRadius / 2)) - 1;
				
				pumpSiteMarker.index = treatmentsList.length;
				treatmentsList.push(pumpSiteMarker);
				treatmentsMap[treatment.ID] = pumpSiteMarker;
				
				chartTreatment = pumpSiteMarker;
			}
			else if (treatment.type == Treatment.TYPE_GLUCOSE_CHECK)
			{
				//Create treatment marker and add it to the chart
				var glucoseCheckMarker:BGCheckMarker = new BGCheckMarker(treatment, timelineRange);
				glucoseCheckMarker.x = (glucoseCheckMarker.treatment.timestamp - firstBGReadingTimeStamp) * mainChartXFactor;
				glucoseCheckMarker.y = _graphHeight - (glucoseCheckMarker.radius * 1.66) - ((glucoseCheckMarker.treatment.glucoseEstimated - lowestGlucoseValue) * mainChartYFactor);
				
				glucoseCheckMarker.index = treatmentsList.length;
				treatmentsList.push(glucoseCheckMarker);
				treatmentsMap[treatment.ID] = glucoseCheckMarker;
				
				chartTreatment = glucoseCheckMarker;
			}
			else if (treatment.type == Treatment.TYPE_SENSOR_START)
			{
				//Create treatment marker and add it to the chart
				var sensorStartMarker:SensorMarker = new SensorMarker(treatment);
				sensorStartMarker.x = (sensorStartMarker.treatment.timestamp - firstBGReadingTimeStamp) * mainChartXFactor;
				sensorStartMarker.y = _graphHeight - (sensorStartMarker.radius * 1.66) - ((sensorStartMarker.treatment.glucoseEstimated - lowestGlucoseValue) * mainChartYFactor);
				
				sensorStartMarker.index = treatmentsList.length;
				treatmentsList.push(sensorStartMarker);
				treatmentsMap[treatment.ID] = sensorStartMarker;
				
				chartTreatment = sensorStartMarker;
			}
			
			if (mainChartMask != null && mainChartContainer != null) //Make mask appear in front of everything except the timeline
			{
				mainChartContainer.addChild(mainChartMask);
				if (timelineContainer != null)
					mainChartContainer.addChild(timelineContainer);
			}
			
			//Reposition out of bounds treatments
			if (chartTreatment != null)
			{
				if (yAxisHeight > 0 && chartTreatment.y + chartTreatment.height > yAxisHeight - 5) //Lower Area
					chartTreatment.labelUp();
				
				if (chartTreatment.y < 0) //Upper Area
					chartTreatment.y = 0;
				
				//Add treatment
				if (chartTreatment.treatment.type != Treatment.TYPE_EXTENDED_COMBO_BOLUS_CHILD)
				{
					chartTreatment.addEventListener(TouchEvent.TOUCH, onDisplayTreatmentDetails);
				}
				chartTreatment.alpha = 0;
				
				if (treatment.type != Treatment.TYPE_EXTENDED_COMBO_BOLUS_CHILD)
				{
					treatmentsContainer.addChild(chartTreatment);
				}
				else
				{
					treatmentsContainer.addChildAt(chartTreatment, 0);
				}
				
				//Fade in treatment
				var popupTween:Tween = new Tween(chartTreatment, 0.5, Transitions.EASE_OUT);
				popupTween.fadeTo(1);
				popupTween.onComplete = function():void
				{
					popupTween = null;
				}
				Starling.juggler.add(popupTween);
			}
		}
		
		private function getTreatmentByID(treatmentID:String):ChartTreatment
		{
			var matchedTreatment:ChartTreatment = null;
			
			if (treatmentID == null || treatmentID == "")
			{
				return matchedTreatment;
			}
			
			for(var i:int = treatmentsList.length - 1 ; i >= 0; i--)
			{
				var chartTreatment:ChartTreatment = treatmentsList[i];
				if (chartTreatment!= null && chartTreatment.treatment != null && chartTreatment.treatment.ID == treatmentID)
				{
					matchedTreatment = chartTreatment;
					break;
				}
			}
			
			return matchedTreatment;
		}
		
		private function onDisplayTreatmentDetails(e:starling.events.TouchEvent):void
		{
			if (!SystemUtil.isApplicationActive || dummyModeActive || !treatmentsActive || !displayTreatmentsOnChart)
				return;
			
			var touch:Touch = e.getTouch(stage);
			
			if(touch != null && touch.phase == TouchPhase.BEGAN) 
			{
				var treatment:ChartTreatment = e.currentTarget as ChartTreatment;
				
				var treatmentLayout:VerticalLayout = new VerticalLayout();
				treatmentLayout.horizontalAlign = HorizontalAlign.CENTER;
				treatmentLayout.gap = 10;
				if (treatmentContainer != null) treatmentContainer.removeFromParent(true);
				treatmentContainer = new LayoutGroup();
				treatmentContainer.layout = treatmentLayout;
				
				//Treatment Value
				var treatmentValue:String = "";
				var treatmentNotes:String = treatmentNotes = treatment.treatment.note;
				var treatmentBG:Number = glucoseUnit == "mg/dL" ? Math.round(treatment.treatment.glucoseEstimated) : Math.round(BgReading.mgdlToMmol(treatment.treatment.glucoseEstimated) * 10) / 10;
				var insulin:Insulin;
				if (treatment.treatment.type == Treatment.TYPE_BOLUS || treatment.treatment.type == Treatment.TYPE_CORRECTION_BOLUS)
				{
					insulin = ProfileManager.getInsulin(treatment.treatment.insulinID);
					treatmentValue = (insulin != null ? insulin.name + "\n" : "") + GlucoseFactory.formatIOB(treatment.treatment.insulinAmount) + "\n\n" + treatmentBG + " " + GlucoseHelper.getGlucoseUnit();
				}
				else if (treatment.treatment.type == Treatment.TYPE_EXTENDED_COMBO_BOLUS_PARENT || treatment.treatment.type == Treatment.TYPE_EXTENDED_COMBO_MEAL_PARENT)
				{
					parseChildTreatments(treatment);
					insulin = ProfileManager.getInsulin(treatment.treatment.insulinID);
					var parentInsulinAmount:Number = treatment.treatment.insulinAmount;
					var overallInsulinAmount:Number = treatment.treatment.getTotalInsulin();
					var childrenInsulinAmount:Number = overallInsulinAmount - parentInsulinAmount;
					var parentSplit:Number = Math.round((parentInsulinAmount * 100) / overallInsulinAmount);
					var childrenSplit:Number = 100 - parentSplit;
					var now:Number = new Date().valueOf();
					var insulinAdded:Number = overallInsulinAmount;
					
					if (treatment.treatment.timestamp > now)
					{
						insulinAdded -= parentInsulinAmount;
					}
					if (treatment.children != null)
					{
						for(var i:int =treatment.children.length - 1 ; i >= 0; i--)
						{
							var child:ChartTreatment = treatment.children[i];
							if (child != null && child.treatment.timestamp > now)
							{
								insulinAdded -= child.treatment.insulinAmount;
							}
						}
					}
					var remainingInsulin:Number = overallInsulinAmount - insulinAdded;
					
					if (treatment.treatment.type == Treatment.TYPE_EXTENDED_COMBO_BOLUS_PARENT)
					{
						treatmentValue = (insulin != null ? insulin.name + "\n" : "") + GlucoseFactory.formatIOB(overallInsulinAmount) + "\n\n" + ModelLocator.resourceManagerInstance.getString('chartscreen','extended_bolus_split_label') + ": " + parentSplit + "%" + ":" +  childrenSplit + "%" + "\n" + ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_duration_label') + ": " + (treatment.treatment.childTreatments.length * 5) + ModelLocator.resourceManagerInstance.getString('chartscreen','minutes_small') + "\n" + ModelLocator.resourceManagerInstance.getString('chartscreen','extneded_bolus_administered_label') + ": " + GlucoseFactory.formatIOB(insulinAdded)+ "\n" + ModelLocator.resourceManagerInstance.getString('chartscreen','extneded_bolus_remaining_label') + ": " + GlucoseFactory.formatIOB(remainingInsulin) + "\n\n" + treatmentBG + " " + GlucoseHelper.getGlucoseUnit();
					}
					else if (treatment.treatment.type == Treatment.TYPE_EXTENDED_COMBO_MEAL_PARENT)
					{
						if (parentInsulinAmount > 0)
						{
							treatmentValue += ModelLocator.resourceManagerInstance.getString('treatments','meal_with_extended_bolus')
								+ "\n" + 
								ModelLocator.resourceManagerInstance.getString('treatments','treatment_insulin_label') + ": " + GlucoseFactory.formatIOB(overallInsulinAmount) 
								+ "\n" + 
								ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_carbs') + ": " + treatment.treatment.carbs + "g" + " (" + TreatmentsManager.getCarbTypeName(treatment.treatment) + ")"
								+ "\n\n" + 
								ModelLocator.resourceManagerInstance.getString('chartscreen','extended_bolus_split_label') + ": " + parentSplit + "%" + ":" +  childrenSplit + "%" 
								+ "\n" + 
								ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_duration_label') + ": " + (treatment.treatment.childTreatments.length * 5) + ModelLocator.resourceManagerInstance.getString('chartscreen','minutes_small')
								+ "\n" + 
								ModelLocator.resourceManagerInstance.getString('chartscreen','extneded_bolus_administered_label') + ": " + GlucoseFactory.formatIOB(insulinAdded)
								+ "\n" + 
								ModelLocator.resourceManagerInstance.getString('chartscreen','extneded_bolus_remaining_label') + ": " + GlucoseFactory.formatIOB(remainingInsulin)
								+ "\n\n" + 
								treatmentBG + " " + GlucoseHelper.getGlucoseUnit();
						}
						else
						{
							treatmentValue += ModelLocator.resourceManagerInstance.getString('treatments','meal_with_extended_bolus')
								+ "\n" + 
								ModelLocator.resourceManagerInstance.getString('treatments','treatment_insulin_label') + ": " + GlucoseFactory.formatIOB(overallInsulinAmount) 
								+ "\n" + 
								ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_carbs') + ": " + treatment.treatment.carbs + "g" + " (" + TreatmentsManager.getCarbTypeName(treatment.treatment) + ")"
								+ "\n\n" + 
								treatmentBG + " " + GlucoseHelper.getGlucoseUnit();
						}
					}
				}
				else if (treatment.treatment.type == Treatment.TYPE_CARBS_CORRECTION)
				{
					treatmentValue = ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_carbs') + ": " + treatment.treatment.carbs + "g" + "\n" + ModelLocator.resourceManagerInstance.getString('treatments','carbs_type_label') + ": " + TreatmentsManager.getCarbTypeName(treatment.treatment) + "\n\n" + treatmentBG + " " + GlucoseHelper.getGlucoseUnit();
				}
				else if (treatment.treatment.type == Treatment.TYPE_MEAL_BOLUS)
				{
					treatmentValue += ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_meal') + "\n" + ModelLocator.resourceManagerInstance.getString('treatments','treatment_insulin_label') + ": " + GlucoseFactory.formatIOB(treatment.treatment.insulinAmount) + "\n" + ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_carbs') + ": " + treatment.treatment.carbs + "g" + " (" + TreatmentsManager.getCarbTypeName(treatment.treatment) + ")" + "\n\n" + treatmentBG + " " + GlucoseHelper.getGlucoseUnit();
				}
				else if (treatment.treatment.type == Treatment.TYPE_NOTE)
				{
					treatmentValue = ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_note') + "\n" + treatmentBG + " " + GlucoseHelper.getGlucoseUnit();
				}
				else if (treatment.treatment.type == Treatment.TYPE_GLUCOSE_CHECK)
				{
					var glucoseValue:Number;
					if (glucoseUnit == "mg/dL")
						glucoseValue = treatment.treatment.glucose;
					else
						glucoseValue = Math.round(((BgReading.mgdlToMmol((treatment.treatment.glucose))) * 10)) / 10; 
					
					treatmentValue = (treatmentNotes != ModelLocator.resourceManagerInstance.getString('treatments','sensor_calibration_note') ? ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_bg_check') : ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_calibration')) + "\n" + glucoseValue + " " + glucoseUnit;
				}
				else if (treatment.treatment.type == Treatment.TYPE_SENSOR_START)
				{
					treatmentValue = ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_sensor_start') + "\n\n" + treatmentBG + " " + GlucoseHelper.getGlucoseUnit();
				}
				else if (treatment.treatment.type == Treatment.TYPE_EXERCISE)
				{
					treatmentValue += ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_exercise') + "\n" + ModelLocator.resourceManagerInstance.getString('treatments','exercise_duration_label') + ": " + treatment.treatment.duration + ModelLocator.resourceManagerInstance.getString('treatments','minutes_small_label') + "\n" + ModelLocator.resourceManagerInstance.getString('treatments','exercise_intensity_label') + ": " + TreatmentsManager.getExerciseTreatmentIntensity(treatment.treatment) + "\n\n" + treatmentBG + " " + GlucoseHelper.getGlucoseUnit();
				}
				else if (treatment.treatment.type == Treatment.TYPE_INSULIN_CARTRIDGE_CHANGE)
				{
					treatmentValue = ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_insulin_cartridge_change') + "\n\n" + treatmentBG + " " + GlucoseHelper.getGlucoseUnit();
				}
				else if (treatment.treatment.type == Treatment.TYPE_PUMP_BATTERY_CHANGE)
				{
					treatmentValue = ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_pump_battery_change') + "\n\n" + treatmentBG + " " + GlucoseHelper.getGlucoseUnit();
				}
				else if (treatment.treatment.type == Treatment.TYPE_PUMP_SITE_CHANGE)
				{
					treatmentValue = ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_pump_site_change') + "\n\n" + treatmentBG + " " + GlucoseHelper.getGlucoseUnit();
				}
				
				if (treatmentValue != "")
				{
					if (treatmentValueLabel != null) treatmentValueLabel.removeFromParent(true);
					treatmentValueLabel = LayoutFactory.createLabel(treatmentValue, HorizontalAlign.CENTER, VerticalAlign.TOP, 14, true);
					treatmentValueLabel.paddingBottom = 12;
					treatmentContainer.addChild(treatmentValueLabel);
				}
				
				//Treatment Time
				if (treatmentTimeSpinner != null) treatmentTimeSpinner.removeFromParent(true);
				treatmentTimeSpinner = new DateTimeSpinner();
				treatmentTimeSpinner.editingMode = DateTimeMode.TIME;
				treatmentTimeSpinner.locale = Constants.getUserLocale(true);
				treatmentTimeSpinner.value = new Date(treatment.treatment.timestamp);
				treatmentTimeSpinner.height = 30;
				treatmentTimeSpinner.paddingTop = treatmentTimeSpinner.paddingBottom = 0;
				
				if (isHistoricalData) treatmentTimeSpinner.isEnabled = false;
				if (timeSpacer != null) timeSpacer.removeFromParent(true);
				timeSpacer = new Sprite();
				timeSpacer.height = 10;
				treatmentContainer.addChild(treatmentTimeSpinner);
				treatmentContainer.addChild(timeSpacer);
				
				if (treatment.treatment.type == Treatment.TYPE_SENSOR_START 
					|| 
					(treatment.treatment.type == Treatment.TYPE_GLUCOSE_CHECK && treatment.treatment.note == ModelLocator.resourceManagerInstance.getString("treatments","sensor_calibration_note"))
				)
				{
					treatmentTimeSpinner.isEnabled = false;
				}
				
				if (treatmentNotes != "" && treatmentNotes != ModelLocator.resourceManagerInstance.getString('treatments','sensor_calibration_note'))
				{
					if (treatmentNoteLabel != null) treatmentNoteLabel.removeFromParent(true);
					treatmentNoteLabel = LayoutFactory.createLabel(treatmentNotes, HorizontalAlign.CENTER, VerticalAlign.TOP);
					treatmentNoteLabel.wordWrap = true;
					treatmentNoteLabel.maxWidth = 150;
					treatmentContainer.addChild(treatmentNoteLabel);
				}
				
				//Action Buttons
				if (!isHistoricalData)
				{
					if (!CGMBlueToothDevice.isFollower() || (CGMBlueToothDevice.isFollower() && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_URL) != "" && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_API_SECRET) != "" && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FOLLOWER_MODE) == "Nightscout"))
					{
						if ((treatment.treatment.type != Treatment.TYPE_SENSOR_START && treatment.treatment.type != Treatment.TYPE_GLUCOSE_CHECK) || (treatment.treatment.type == Treatment.TYPE_GLUCOSE_CHECK && treatment.treatment.note != ModelLocator.resourceManagerInstance.getString("treatments","sensor_calibration_note")))
						{
							if (moveBtn != null) moveBtn.removeFromParent(true);
							if (deleteBtn != null) deleteBtn.removeFromParent(true);
							var actionsLayout:HorizontalLayout = new HorizontalLayout();
							actionsLayout.gap = 5;
							if (actionsContainer != null) actionsContainer.removeFromParent(true);
							actionsContainer = new LayoutGroup();
							actionsContainer.layout = actionsLayout;
								
							moveBtn = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('treatments','move_button_label'));
							moveBtn.addEventListener(starling.events.Event.TRIGGERED, onMove);
							actionsContainer.addChild(moveBtn);
								
							deleteBtn = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('treatments','delete_button_label'));
							deleteBtn.addEventListener(starling.events.Event.TRIGGERED, onDelete);
							actionsContainer.addChild(deleteBtn);
								
							treatmentContainer.addChild(actionsContainer);
						}
					}
				}
				
				if (treatmentCallout != null)
				{
					treatmentCallout.removeEventListeners();
					treatmentCallout.dispose();
				}
				treatmentCallout = Callout.show(treatmentContainer, treatment, null, true);
				
				function onDelete(e:starling.events.Event):void
				{
					treatmentCallout.close(true);
					
					var lastTreatmentIsCarb:Boolean = TreatmentsManager.lastTreatmentIsCarb() || (treatment.treatment != null && treatment.treatment.carbs > 0);
				
					var deleteTreatmentTween:Tween = new Tween(treatment, 0.3, Transitions.EASE_IN_BACK);
					var lastReadingTimestamp:Number;
					if (!predictionsEnabled || predictionsMainGlucoseDataPoints == null || predictionsMainGlucoseDataPoints.length == 0 || predictionsMainGlucoseDataPoints[predictionsMainGlucoseDataPoints.length - 1] == null)
					{
						lastReadingTimestamp = lastBGreadingTimeStamp;
					}
					else if (predictionsEnabled)
					{
						lastReadingTimestamp = predictionsMainGlucoseDataPoints[predictionsMainGlucoseDataPoints.length - 1].timestamp;
					}
					
					var childTreatmentsList:Array = [];
					var allChildrenHidden:Boolean = false;
					
					if (treatment.treatment.type == Treatment.TYPE_EXTENDED_COMBO_BOLUS_PARENT || treatment.treatment.type == Treatment.TYPE_EXTENDED_COMBO_MEAL_PARENT)
					{
						var numberOfChildren:uint = treatment.children.length;
						var deleteDelay:uint = 200;
						
						for (var i:int = 0; i < numberOfChildren; i++) 
						{
							var child:ChartTreatment = treatment.children[i];
							if (child != null)
							{
								deleteDelay += 10;
								
								setTimeout( function(childToDelete:ChartTreatment):void 
								{
									if (!SystemUtil.isApplicationActive || childToDelete == null)
									{
										return;
									}
									
									childToDelete.alpha = 0;
									childTreatmentsList.push(childToDelete);
									
								}, deleteDelay, child);
							}
						}
						
						setTimeout( function():void 
						{
							allChildrenHidden = true;
						}, deleteDelay + 5);
						
						
						setTimeout( function():void 
						{
							allChildrenHidden = true;
							
							if (deleteChildTreatments())
							{
								var timelineStamp:Number = getTimelineTimestamp();
								if (displayIOBEnabled)
									calculateTotalIOB(timelineStamp);
								if (displayCOBEnabled)
									calculateTotalCOB(timelineStamp, lastTreatmentIsCarb);
								
								if (predictionsEnabled)
								{
									forceNightscoutPredictionRefresh = true;
									redrawPredictions();
								}
							}
							
						}, Math.max(deleteDelay + 10, 1500));
					}
					
					function deleteChildTreatments():Boolean
					{
						var childrenDeleted:Boolean = false;
						
						for(var k:int = childTreatmentsList.length - 1 ; k >= 0; k--)
						{
							var child:ChartTreatment = childTreatmentsList.pop();
							
							treatmentsContainer.removeChild(child);
							treatmentsList.removeAt(child.index);
							
							if (child.treatment != null)
							{
								TreatmentsManager.deleteTreatment(child.treatment, false);
							}
							
							child.dispose();
							child = null;
							
							childrenDeleted = true;
						}
						
						return childrenDeleted;
					}
					
					var deleteX:Number = ((lastReadingTimestamp - firstBGReadingTimeStamp) * mainChartXFactor) + treatment.width + 5;
					deleteTreatmentTween.moveTo(deleteX, treatment.y);
					
					deleteTreatmentTween.onComplete = function():void
					{
						var deletionTimeout:uint = 1;
						
						if (treatment.treatment.type == Treatment.TYPE_EXTENDED_COMBO_BOLUS_PARENT || treatment.treatment.type == Treatment.TYPE_EXTENDED_COMBO_MEAL_PARENT)
						{
							deletionTimeout = 200;
						}
						
						setTimeout( function():void 
						{
							SystemUtil.executeWhenApplicationIsActive(treatmentsContainer.removeChild, treatment);
							treatmentsList.removeAt(treatment.index);
							
							var treatmentToDelete:Treatment = treatment.treatment;
							
							TreatmentsManager.deleteTreatment(treatment.treatment);
							
							SystemUtil.executeWhenApplicationIsActive(treatment.dispose);
							if (SystemUtil.isApplicationActive) treatment = null;
							
							if (allChildrenHidden)
							{
								deleteChildTreatments();
							}
							
							var timelineTimestamp:Number = getTimelineTimestamp();
							if (displayIOBEnabled)
								calculateTotalIOB(timelineTimestamp);
							if (displayCOBEnabled)
								calculateTotalCOB(timelineTimestamp, lastTreatmentIsCarb);
							
							if (predictionsEnabled && (treatmentToDelete.type == Treatment.TYPE_BOLUS || treatmentToDelete.type == Treatment.TYPE_CARBS_CORRECTION || treatmentToDelete.type == Treatment.TYPE_CORRECTION_BOLUS || treatmentToDelete.type == Treatment.TYPE_MEAL_BOLUS || treatmentToDelete.type == Treatment.TYPE_EXTENDED_COMBO_BOLUS_PARENT || treatmentToDelete.type == Treatment.TYPE_EXTENDED_COMBO_MEAL_PARENT))
							{
								clearTimeout(redrawPredictionsTimeoutID);
								
								redrawPredictionsTimeoutID = setTimeout( function():void 
								{
									forceNightscoutPredictionRefresh = true;
									redrawPredictions();
								}, 250 );
							}
							
							deleteTreatmentTween = null;
						}, deletionTimeout );
					}
					Starling.juggler.add(deleteTreatmentTween);
				}
				
				function onMove(e:starling.events.Event):void
				{
					var movedTimestamp:Number = treatmentTimeSpinner.value.valueOf();
					var now:Number = new Date().valueOf();
					var maxMovedTimestamp:Number = predictionsEnabled && predictionsMainGlucoseDataPoints.length > 0 ? now + (predictionsLengthInMinutes * 60 * 1000) : now;
					
					if(movedTimestamp < firstBGReadingTimeStamp || movedTimestamp > maxMovedTimestamp)
					{
						AlertManager.showSimpleAlert
						(
							ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
							ModelLocator.resourceManagerInstance.getString('treatments','out_of_bounds_treatment')
						);
					}
					else
					{
						var estimatedGlucoseValue:Number;
						if (treatment.treatment.type != Treatment.TYPE_GLUCOSE_CHECK)
							estimatedGlucoseValue = TreatmentsManager.getEstimatedGlucose(movedTimestamp);
						else
							estimatedGlucoseValue = treatment.treatment.glucoseEstimated;
						
						var originalTreatmmentTimestamp:Number = treatment.treatment.timestamp;
						treatment.treatment.timestamp = movedTimestamp;
						treatment.treatment.glucoseEstimated = estimatedGlucoseValue;
						
						if(treatment.treatment.type == Treatment.TYPE_EXTENDED_COMBO_BOLUS_PARENT || treatment.treatment.type == Treatment.TYPE_EXTENDED_COMBO_MEAL_PARENT)
						{
							var timeDifference:Number = movedTimestamp - originalTreatmmentTimestamp;
							
							var numberOfChildren:uint = treatment.children.length;
							for (var i:int = 0; i < numberOfChildren; i++) 
							{
								var child:ChartTreatment = treatment.children[i];
								if (child != null && child.treatment.type == Treatment.TYPE_EXTENDED_COMBO_BOLUS_CHILD)
								{
									child.treatment.timestamp += timeDifference;
									child.treatment.glucoseEstimated = TreatmentsManager.getEstimatedGlucose(child.treatment.timestamp);
									TreatmentsManager.updateTreatment(child.treatment);
								}
							}
						}
						
						treatmentCallout.close(true);
						
						var forceCOBRefresh:Boolean = treatment.treatment != null && treatment.treatment.carbs > 0;
						
						if (treatment.treatment.type == Treatment.TYPE_BOLUS || treatment.treatment.type == Treatment.TYPE_CORRECTION_BOLUS || treatment.treatment.type == Treatment.TYPE_MEAL_BOLUS || treatment.treatment.type == Treatment.TYPE_EXTENDED_COMBO_BOLUS_PARENT || treatment.treatment.type == Treatment.TYPE_EXTENDED_COMBO_MEAL_PARENT)
						{
							var timelineTimestamp:Number = getTimelineTimestamp();
							
							if (displayIOBEnabled)
							{
								if(treatment.treatment.type == Treatment.TYPE_EXTENDED_COMBO_BOLUS_PARENT || treatment.treatment.type == Treatment.TYPE_EXTENDED_COMBO_MEAL_PARENT)
								{
									setTimeout(calculateTotalIOB, TimeSpan.TIME_2_SECONDS, timelineTimestamp);
								}
								else
								{
									calculateTotalIOB(timelineTimestamp);
								}
							}
							
							if (treatment.treatment.type == Treatment.TYPE_MEAL_BOLUS && displayCOBEnabled)
							{
								if(treatment.treatment.type == Treatment.TYPE_EXTENDED_COMBO_BOLUS_PARENT || treatment.treatment.type == Treatment.TYPE_EXTENDED_COMBO_MEAL_PARENT)
								{
									setTimeout(calculateTotalCOB, TimeSpan.TIME_2_SECONDS, timelineTimestamp, forceCOBRefresh);
								}
								else
								{
									calculateTotalCOB(timelineTimestamp, forceCOBRefresh);
								}
							}
						}
						else if (treatment.treatment.type == Treatment.TYPE_CARBS_CORRECTION && displayCOBEnabled)
						{
							calculateTotalCOB(getTimelineTimestamp(), forceCOBRefresh);
						}
						
						if (predictionsEnabled && (treatment.treatment.type == Treatment.TYPE_BOLUS || treatment.treatment.type == Treatment.TYPE_CARBS_CORRECTION || treatment.treatment.type == Treatment.TYPE_CORRECTION_BOLUS || treatment.treatment.type == Treatment.TYPE_MEAL_BOLUS || treatment.treatment.type == Treatment.TYPE_EXTENDED_COMBO_BOLUS_PARENT || treatment.treatment.type == Treatment.TYPE_EXTENDED_COMBO_MEAL_PARENT))
						{
							clearTimeout(redrawPredictionsTimeoutID);
							
							var predTimeout:uint = 250;
							if(treatment.treatment.type == Treatment.TYPE_EXTENDED_COMBO_BOLUS_PARENT || treatment.treatment.type == Treatment.TYPE_EXTENDED_COMBO_MEAL_PARENT)
							{
								predTimeout = 1500;
							}
							
							redrawPredictionsTimeoutID = setTimeout( function():void 
							{
								forceNightscoutPredictionRefresh = true;
								redrawPredictions();
							}, predTimeout );
						}
						
						//Update database
						TreatmentsManager.updateTreatment(treatment.treatment);
						
						//Reposition Treatments
						manageTreatments(true);
					}
				}
			}
		}
		
		private function manageTreatments(animate:Boolean = false):void
		{
			if (!SystemUtil.isApplicationActive || dummyModeActive || !treatmentsActive || !displayTreatmentsOnChart)
				return;
			
			if (treatmentsContainer == null || !treatmentsActive)
				return;
			
			//Reposition Container
			treatmentsContainer.x = mainChart.x;
			treatmentsContainer.y = mainChart.y;
			
			if (treatmentsList != null && treatmentsList.length > 0)
			{
				//Loop through all treatments
				for(var i:int = treatmentsList.length - 1 ; i >= 0; i--)
				{
					var treatment:ChartTreatment = treatmentsList[i];
					if (treatment.treatment.timestamp < firstBGReadingTimeStamp && treatment.treatment.type != Treatment.TYPE_SENSOR_START && !isHistoricalData)
					{
						//Treatment has expired (>24H). Dispose it
						treatmentsContainer.removeChild(treatment);
						treatmentsList.removeAt(i);
						TreatmentsManager.removeTreatmentFromMemory(treatment.treatment);
						treatment.dispose();
						treatment = null;
					}
					else
					{
						//Treatment is still valid. Reposition it.
						if (
							treatment.treatment.type == Treatment.TYPE_BOLUS 
							|| 
							treatment.treatment.type == Treatment.TYPE_CORRECTION_BOLUS 
							|| 
							treatment.treatment.type == Treatment.TYPE_GLUCOSE_CHECK 
							|| 
							treatment.treatment.type == Treatment.TYPE_SENSOR_START 
							|| 
							treatment.treatment.type == Treatment.TYPE_CARBS_CORRECTION 
							|| 
							treatment.treatment.type == Treatment.TYPE_MEAL_BOLUS
							|| 
							treatment.treatment.type == Treatment.TYPE_EXTENDED_COMBO_BOLUS_CHILD
							|| 
							treatment.treatment.type == Treatment.TYPE_EXTENDED_COMBO_BOLUS_PARENT
							|| 
							treatment.treatment.type == Treatment.TYPE_EXTENDED_COMBO_MEAL_PARENT
						)
						{
							if (treatment.treatment.needsAdjustment)
							{
								//It's a treatment that was added in the future. Now it's the time to calculate it's Y position on the graph
								treatment.treatment.glucoseEstimated = TreatmentsManager.getEstimatedGlucose(treatment.treatment.timestamp);
								
								if (mainChartGlucoseMarkersList != null 
									&& 
									mainChartGlucoseMarkersList.length > 0 
									&& 
									mainChartGlucoseMarkersList[mainChartGlucoseMarkersList.length - 1] != null
									&& 
									(mainChartGlucoseMarkersList[mainChartGlucoseMarkersList.length - 1] as GlucoseMarker).bgReading != null 
									&& 
									treatment.treatment.timestamp <= (mainChartGlucoseMarkersList[mainChartGlucoseMarkersList.length - 1] as GlucoseMarker).bgReading.timestamp
									)
								{
									treatment.treatment.needsAdjustment = false;
									TreatmentsManager.updateTreatment(treatment.treatment, false);
								}
							}
							
							var generalTreatmentX:Number = (treatment.treatment.timestamp - firstBGReadingTimeStamp) * mainChartXFactor;
							var generalTreatmentY:Number = _graphHeight - (treatment.radius * 1.66) - ((treatment.treatment.glucoseEstimated - lowestGlucoseValue) * mainChartYFactor);
							if ((treatment.treatment.type == Treatment.TYPE_MEAL_BOLUS || treatment.treatment.type == Treatment.TYPE_EXTENDED_COMBO_MEAL_PARENT) && generalTreatmentY < -2)
								generalTreatmentY = -2;
							
							if (!animate)
							{
								treatment.x = generalTreatmentX;
								treatment.y = generalTreatmentY;
							}
							else
							{
								var generalTreatmentTween:Tween = new Tween(treatment, 0.8, Transitions.EASE_OUT_BACK);
								generalTreatmentTween.moveTo(generalTreatmentX, generalTreatmentY);
								generalTreatmentTween.onComplete = function():void
								{
									repositionOutOfBounds();
									generalTreatmentTween = null;
								}
								Starling.juggler.add(generalTreatmentTween);
							}
						}
						else if (treatment.treatment.type == Treatment.TYPE_NOTE)
						{
							var noteX:Number;
							if (treatment.treatment.timestamp <= lastBGreadingTimeStamp)
								noteX = (((treatment.treatment.timestamp - firstBGReadingTimeStamp) * mainChartXFactor) + mainChartGlucoseMarkerRadius) - 5;
							else
								noteX = (((lastBGreadingTimeStamp - firstBGReadingTimeStamp) * mainChartXFactor) + mainChartGlucoseMarkerRadius) - 10;
							
							var noteY:Number = (_graphHeight - treatment.height - (mainChartGlucoseMarkerRadius * 3) - ((treatment.treatment.glucoseEstimated - lowestGlucoseValue) * mainChartYFactor) + (mainChartGlucoseMarkerRadius / 2)) + 8;
							
							if (!animate)
							{
								treatment.x = noteX;
								treatment.y = noteY;
							}
							else
							{
								var noteTween:Tween = new Tween(treatment, 0.8, Transitions.EASE_OUT_BACK);
								noteTween.moveTo(noteX, noteY);
								noteTween.onComplete = function():void
								{
									repositionOutOfBounds();
									noteTween = null;
								}
								Starling.juggler.add(noteTween);
							}
						}
						else if (treatment.treatment.type == Treatment.TYPE_EXERCISE || treatment.treatment.type == Treatment.TYPE_INSULIN_CARTRIDGE_CHANGE || treatment.treatment.type == Treatment.TYPE_PUMP_BATTERY_CHANGE || treatment.treatment.type == Treatment.TYPE_PUMP_SITE_CHANGE)
						{
							var iconTreatmentX:Number = ((treatment.treatment.timestamp - firstBGReadingTimeStamp) * mainChartXFactor) - (treatment.width / 2) + (mainChartGlucoseMarkerRadius / 2);
							var iconTreatmentY:Number = (_graphHeight - treatment.height - (mainChartGlucoseMarkerRadius * 3) - ((treatment.treatment.glucoseEstimated - lowestGlucoseValue) * mainChartYFactor) + (mainChartGlucoseMarkerRadius / 2)) + 8;
							if (treatment.treatment.type == Treatment.TYPE_INSULIN_CARTRIDGE_CHANGE || treatment.treatment.type == Treatment.TYPE_PUMP_BATTERY_CHANGE)
							{
								iconTreatmentY -= 5;
							}
							if (treatment.treatment.type == Treatment.TYPE_PUMP_SITE_CHANGE)
							{
								iconTreatmentY -= 9;
							}
							if (treatment.treatment.type == Treatment.TYPE_EXERCISE)
							{
								iconTreatmentY -= 2;
							}
							
							if (!animate)
							{
								treatment.x = iconTreatmentX;
								treatment.y = iconTreatmentY;
							}
							else
							{
								var iconTreatmentTween:Tween = new Tween(treatment, 0.8, Transitions.EASE_OUT_BACK);
								iconTreatmentTween.moveTo(iconTreatmentX, iconTreatmentY);
								iconTreatmentTween.onComplete = function():void
								{
									repositionOutOfBounds();
									iconTreatmentTween = null;
								}
								Starling.juggler.add(iconTreatmentTween);
							}
						}
						
						if (!animate)
						{
							repositionOutOfBounds();
						}
						
						function repositionOutOfBounds():void
						{
							//Reposition out of bounds treatments
							if (treatment != null && !isNaN(treatment.y) && !isNaN(treatment.height) && !isNaN(yAxisHeight))
							{
								if (yAxisHeight > 0 && treatment.y + treatment.height > yAxisHeight - 5) //Lower Area
									treatment.labelUp();
								else
									treatment.labelDown();
								
								if (treatment.y < 0) //Upper Area
									treatment.y = 0;
							}
						}
					}
				}
			}
		}
		
		private function getTimelineTimestamp():Number
		{
			var currentTimelineTimestamp:Number;
			if (displayLatestBGValue)
				currentTimelineTimestamp = new Date().valueOf();
			else
				currentTimelineTimestamp = firstBGReadingTimeStamp + (Math.abs(mainChart.x - (_graphWidth - yAxisMargin - (predictionsEnabled && predictionsDelimiter != null ? glucoseDelimiter.x - predictionsDelimiter.x : 0)) + (mainChartGlucoseMarkerRadius * 2)) / mainChartXFactor);
			
			return currentTimelineTimestamp;
		}
		
		private function drawTimeline():void
		{
			if (!SystemUtil.isApplicationActive)
				return;
			
			//Safeguards
			if (mainChart == null || dummyModeActive || !timelineActive)
				return;
			
			//Setup initial timeline/mask properties
			if (timelineFirstRun && timelineContainer == null)
			{
				timelineContainer = new Sprite();
				timelineContainer.touchable = false;
				mainChartContainer.addChild(timelineContainer);
				timelineFirstRun = false;
			}
			
			//Clean previous objects
			if (timelineObjects != null && timelineObjects.length > 0)
			{
				for (var i:int = 0; i < timelineObjects.length; i++) 
				{
					var displayObject:Sprite = timelineObjects[i] as Sprite;
					if (displayObject != null && timelineContainer != null)
					{
						displayObject.removeFromParent();
						for (var j:int = 0; j < displayObject.numChildren; j++) 
						{
							var child:DisplayObject = displayObject.getChildAt(j);
							if (child != null)
							{
								child.dispose();
								child = null;
							}
						}
						displayObject.dispose();
						displayObject = null;
					}
				}
				timelineObjects.length = 0;
			}
			
			//Safeguards
			if (isNaN(firstBGReadingTimeStamp) || isNaN(lastBGreadingTimeStamp))
				return;
			
			//Resize and position timeline container
			timelineContainer.x = mainChart.x;
			timelineContainer.width = mainChart.width;
			
			//Timeline calculations
			var firstDate:Date = new Date(firstBGReadingTimeStamp);
			var lastDate:Date = new Date(lastBGreadingTimeStamp);
			var initialTimestamp:Number = new Date(firstDate.fullYear, firstDate.month, firstDate.date, firstDate.hours, 0, 0, 0).valueOf();
			var lastTimestamp:Number = lastDate.valueOf();
			
			while (initialTimestamp <= lastTimestamp + TimeSpan.TIME_2_HOURS + (predictionsEnabled ? predictionsLengthInMinutes * TimeSpan.TIME_1_MINUTE : 0)) 
			{	
				//Get marker time
				var markerDate:Date = new Date(initialTimestamp);
				var currentMarkerTimestamp:Number = markerDate.valueOf();
				
				//Define marker position relative to main chart
				var currentX:Number = (currentMarkerTimestamp - firstBGReadingTimeStamp) * mainChartXFactor;
				
				//Visual representation of marker time
				var label:String;
				if (dateFormat.slice(0,2) == "24")
					label = TimeSpan.formatHoursMinutes(markerDate.getHours(), markerDate.getMinutes(), TimeSpan.TIME_FORMAT_24H);
				else
					label = TimeSpan.formatHoursMinutes(markerDate.getHours(), markerDate.getMinutes(), TimeSpan.TIME_FORMAT_12H);
				
				var fontSize:int;
				if (timelineRange == TIMELINE_1H || timelineRange == TIMELINE_3H || timelineRange == TIMELINE_6H)
					fontSize = Constants.deviceModel == DeviceInfo.IPHONE_2G_3G_3GS_4_4S_ITOUCH_2_3_4 || (Constants.deviceModel == DeviceInfo.IPHONE_5_5S_5C_SE_ITOUCH_5_6 && dateFormat.slice(0,2) != "24") ? 11 : 12;
				else
					fontSize = Constants.deviceModel == DeviceInfo.IPHONE_2G_3G_3GS_4_4S_ITOUCH_2_3_4 || (Constants.deviceModel == DeviceInfo.IPHONE_5_5S_5C_SE_ITOUCH_5_6 && dateFormat.slice(0,2) != "24") ? 10 : 11;
				
				var time:Label = LayoutFactory.createLabel(label, HorizontalAlign.CENTER, VerticalAlign.TOP, fontSize, false, axisFontColor);
				time.touchable = false;
				time.validate();
				
				//Add marker to display list
				var timeDisplayContainer:Sprite = new Sprite();
				timeDisplayContainer.touchable = false;
				timeDisplayContainer.addChild(time);
				timeDisplayContainer.x =  currentX - (time.width / 2);
				timeDisplayContainer.y = Constants.deviceModel != DeviceInfo.IPHONE_2G_3G_3GS_4_4S_ITOUCH_2_3_4 && (timelineRange == TIMELINE_1H || timelineRange == TIMELINE_3H || timelineRange == TIMELINE_6H) ? 0.5 : 0;
				timeDisplayContainer.y = Constants.deviceModel == DeviceInfo.IPHONE_5_5S_5C_SE_ITOUCH_5_6 && dateFormat.slice(0,2) != "24" ? 0 : timeDisplayContainer.y;
				if (Constants.deviceModel == DeviceInfo.IPHONE_5_5S_5C_SE_ITOUCH_5_6 && dateFormat.slice(0,2) != "24" ? 0 : timeDisplayContainer.y) {}
				else timeDisplayContainer.y = Constants.deviceModel != DeviceInfo.IPHONE_2G_3G_3GS_4_4S_ITOUCH_2_3_4 && timelineRange != TIMELINE_1H && timelineRange != TIMELINE_3H && timelineRange != TIMELINE_6H ? -1 : timeDisplayContainer.y;
				timelineContainer.addChild(timeDisplayContainer);
				
				//Save marker for later processing/disposing
				timelineObjects.push(timeDisplayContainer);
				
				//Update loop condition
				if (timelineRange == TIMELINE_1H || timelineRange == TIMELINE_3H || timelineRange == TIMELINE_6H)
					initialTimestamp += TimeSpan.TIME_1_HOUR;
				else if (timelineRange == TIMELINE_12H)
					initialTimestamp += TimeSpan.TIME_2_HOURS;
				else if (timelineRange == TIMELINE_24H && dateFormat.slice(0,2) == "24")
					initialTimestamp += TimeSpan.TIME_3_HOURS;
				else if (timelineRange == TIMELINE_24H && dateFormat.slice(0,2) == "12")
					initialTimestamp += TimeSpan.TIME_4_HOURS;
			}
			
			if (scrollerChart != null)
				timelineContainer.y = scrollerChart.y - timelineContainer.height - 1;
		}
		
		private function drawYAxis():Sprite
		{
			//Create Axis Holder
			if (yAxis != null) yAxis.dispose();
			yAxis = new Sprite();
			yAxis.touchable = false;
			
			//Create Axis Main Vertical Line
			if (yAxisLine != null) yAxisLine.dispose();
			yAxisLine = GraphLayoutFactory.createVerticalLine(_graphHeight, lineThickness, lineColor);
			yAxisLine.x = _graphWidth - (yAxisLine.width / 2);
			yAxisLine.y = 0;
			yAxisLine.touchable = false;
			yAxis.addChild(yAxisLine);
			
			/**
			 * Glucose Delimiter
			 */
			if (glucoseDelimiter != null) glucoseDelimiter.dispose();
			glucoseDelimiter = GraphLayoutFactory.createVerticalDashedLine(_graphHeight, dashLineWidth, dashLineGap, dashLineThickness, lineColor);
			glucoseDelimiter.y = 0 - glucoseDelimiter.width;
			glucoseDelimiter.x = _graphWidth - yAxisMargin + glucoseDelimiter.width;
			glucoseDelimiter.touchable = false;
			yAxis.addChild(glucoseDelimiter);
			
			activeGlucoseDelimiter = glucoseDelimiter;
			
			/**
			 * Predictions Delimiter
			 */
			if (predictionsEnabled && predictionsMainGlucoseDataPoints.length > 0 && mainChartGlucoseMarkersList.length > 0)
			{
				if (predictionsDelimiter != null) predictionsDelimiter.removeFromParent(true);
				predictionsDelimiter = GraphLayoutFactory.createVerticalDashedLine(_graphHeight, dashLineWidth, dashLineGap, dashLineThickness, lineColor);
				predictionsDelimiter.y = 0 - predictionsDelimiter.width;
				predictionsDelimiter.x = mainChartGlucoseMarkerRadius + _graphWidth - yAxisMargin + (mainChartGlucoseMarkerRadius * 2) - (mainChart.width - mainChartGlucoseMarkersList[mainChartGlucoseMarkersList.length - 1].x);
				predictionsDelimiter.touchable = false;
				yAxis.addChild(predictionsDelimiter);
				
				activeGlucoseDelimiter = predictionsDelimiter;
			}
			else
			{
				if (predictionsDelimiter != null) predictionsDelimiter.removeFromParent(true);
			}
			
			/**
			 * Highest Glucose
			 */
			//Line Marker
			if (highestGlucoseLineMarker != null) highestGlucoseLineMarker.dispose();
			highestGlucoseLineMarker = GraphLayoutFactory.createHorizontalLine(legendSize, lineThickness, lineColor);
			highestGlucoseLineMarker.x = _graphWidth - legendSize;
			highestGlucoseLineMarker.y = 0 + (highestGlucoseLineMarker.width / 10);
			highestGlucoseLineMarker.touchable = false;
			yAxis.addChild(highestGlucoseLineMarker);
			
			//Legend
			var highestGlucoseAxisValue:Number = highestGlucoseValue;
			if(glucoseUnit != "mg/dL")
				highestGlucoseAxisValue = Math.round(((BgReading.mgdlToMmol((highestGlucoseAxisValue))) * 10)) / 10;
			
			var highestGlucoseOutput:String
			if (glucoseUnit == "mg/dL")
				highestGlucoseOutput = String(Math.round(highestGlucoseAxisValue));
			else
			{
				if ( highestGlucoseAxisValue % 1 == 0)
					highestGlucoseOutput = String(highestGlucoseAxisValue) + ".0";
				else
					highestGlucoseOutput = String(highestGlucoseAxisValue);
			}
			
			if (highestGlucoseLegend != null) highestGlucoseLegend.dispose();
			highestGlucoseLegend = GraphLayoutFactory.createGraphLegend(highestGlucoseOutput, axisFontColor, legendTextSize * userAxisFontMultiplier);
			yAxis.addChild(highestGlucoseLegend);
			if (userAxisFontMultiplier >= 1)
				highestGlucoseLegend.y = (0 - (highestGlucoseLegend.height/3)) / userAxisFontMultiplier;
			else
				highestGlucoseLegend.y = (0 - (highestGlucoseLegend.height/3)) * userAxisFontMultiplier;
			highestGlucoseLegend.x = Math.round(_graphWidth - highestGlucoseLineMarker.width - highestGlucoseLegend.width - legendMargin);
			
			/**
			 * Lowest Glucose
			 */
			//Line Marker
			if (lowestGlucoseLineMarker != null) lowestGlucoseLineMarker.dispose();
			lowestGlucoseLineMarker = GraphLayoutFactory.createHorizontalLine(legendSize, lineThickness, lineColor);
			lowestGlucoseLineMarker.x = _graphWidth - legendSize;
			lowestGlucoseLineMarker.y = _graphHeight - (lineThickness / 2);
			lowestGlucoseLineMarker.touchable = false;
			yAxis.addChild(lowestGlucoseLineMarker);
			
			//Legend
			var lowestGlucoseAxisValue:Number = lowestGlucoseValue;
			if(glucoseUnit != "mg/dL")
				lowestGlucoseAxisValue = Math.round(((BgReading.mgdlToMmol((lowestGlucoseAxisValue))) * 10)) / 10;
			
			var lowestGlucoseOutput:String
			if (glucoseUnit == "mg/dL")
				lowestGlucoseOutput = String(Math.round(lowestGlucoseAxisValue));
			else
			{
				if ( lowestGlucoseAxisValue % 1 == 0)
					lowestGlucoseOutput = String(lowestGlucoseAxisValue) + ".0";
				else
					lowestGlucoseOutput = String(lowestGlucoseAxisValue);
			}
			
			if (lowestGlucoseLegend != null) lowestGlucoseLegend.dispose();
			lowestGlucoseLegend = GraphLayoutFactory.createGraphLegend(lowestGlucoseOutput, axisFontColor, legendTextSize * userAxisFontMultiplier);
			if (userAxisFontMultiplier >= 1)
				lowestGlucoseLegend.y = Math.round(_graphHeight - lowestGlucoseLegend.height + ((lowestGlucoseLegend.height * userAxisFontMultiplier)/6));
			else
				lowestGlucoseLegend.y = Math.round(_graphHeight - lowestGlucoseLegend.height + ((lowestGlucoseLegend.height / userAxisFontMultiplier)/6));
			lowestGlucoseLegend.x = Math.round(_graphWidth - lowestGlucoseLineMarker.width - lowestGlucoseLegend.width - legendMargin);
			yAxis.addChild(lowestGlucoseLegend);
			
			/**
			 * Urgent High Glucose Threshold
			 */
			if(glucoseUrgentHigh > lowestGlucoseValue && glucoseUrgentHigh < highestGlucoseValue && displayUrgentHighLine && !dummyModeActive)
			{
				//Line Marker
				if (highUrgentGlucoseLineMarker != null) highUrgentGlucoseLineMarker.dispose();
				highUrgentGlucoseLineMarker = GraphLayoutFactory.createHorizontalLine(legendSize, lineThickness, lineColor);
				highUrgentGlucoseLineMarker.x = _graphWidth - legendSize;
				highUrgentGlucoseLineMarker.y = _graphHeight - ((glucoseUrgentHigh - lowestGlucoseValue) * scaleYFactor) - lineThickness;
				highUrgentGlucoseLineMarker.touchable = false;
				yAxis.addChild(highUrgentGlucoseLineMarker);
				
				//Legend
				var urgentHighGlucoseAxisValue:Number = glucoseUrgentHigh;
				if(glucoseUnit != "mg/dL")
					urgentHighGlucoseAxisValue = Math.round(((BgReading.mgdlToMmol((urgentHighGlucoseAxisValue))) * 10)) / 10;
				
				var urgentHighGlucoseOutput:String
				if (glucoseUnit == "mg/dL")
					urgentHighGlucoseOutput = String(Math.round(urgentHighGlucoseAxisValue));
				else
				{
					if ( urgentHighGlucoseAxisValue % 1 == 0)
						urgentHighGlucoseOutput = String(urgentHighGlucoseAxisValue) + ".0";
					else
						urgentHighGlucoseOutput = String(urgentHighGlucoseAxisValue);
				}
				
				if (highUrgentGlucoseLegend != null) highUrgentGlucoseLegend.dispose();
				var highUrgentGlucoseLegend:Label = GraphLayoutFactory.createGraphLegend(urgentHighGlucoseOutput, axisFontColor, legendTextSize * userAxisFontMultiplier);
				if (userAxisFontMultiplier >= 1)
					highUrgentGlucoseLegend.y = _graphHeight - ((glucoseUrgentHigh - lowestGlucoseValue) * scaleYFactor) - ((highUrgentGlucoseLegend.height / userAxisFontMultiplier) / 2) - ((highUrgentGlucoseLegend.height / userAxisFontMultiplier) / 8);
				else
					highUrgentGlucoseLegend.y = _graphHeight - ((glucoseUrgentHigh - lowestGlucoseValue) * scaleYFactor) - ((highUrgentGlucoseLegend.height * userAxisFontMultiplier) / 2) - ((highUrgentGlucoseLegend.height * userAxisFontMultiplier) / 8);
				highUrgentGlucoseLegend.y -= lineThickness;
				highUrgentGlucoseLegend.x = Math.round(_graphWidth - highestGlucoseLineMarker.width - highUrgentGlucoseLegend.width - legendMargin);
				yAxis.addChild(highUrgentGlucoseLegend);
				
				//Dashed Line
				if (highUrgentGlucoseDashedLine != null) highUrgentGlucoseDashedLine.dispose();
				highUrgentGlucoseDashedLine = GraphLayoutFactory.createHorizontalDashedLine(_graphWidth, dashLineWidth, dashLineGap, dashLineThickness, lineColor, legendMargin + dashLineWidth + ((legendTextSize * userAxisFontMultiplier) - legendTextSize));
				highUrgentGlucoseDashedLine.y = _graphHeight - ((glucoseUrgentHigh - lowestGlucoseValue) * scaleYFactor) - lineThickness;
				highUrgentGlucoseDashedLine.touchable = false;
				yAxis.addChild(highUrgentGlucoseDashedLine);
			}
			
			/**
			 * High Glucose Threshold
			 */
			if(glucoseHigh > lowestGlucoseValue && glucoseHigh < highestGlucoseValue && displayHighLine)
			{
				//Line Marker
				if (highGlucoseLineMarker != null) highGlucoseLineMarker.dispose();
				highGlucoseLineMarker = GraphLayoutFactory.createHorizontalLine(legendSize, lineThickness, lineColor);
				highGlucoseLineMarker.x = _graphWidth - legendSize;
				highGlucoseLineMarker.y = _graphHeight - ((glucoseHigh - lowestGlucoseValue) * scaleYFactor) - lineThickness;
				highGlucoseLineMarker.touchable = false;
				yAxis.addChild(highGlucoseLineMarker);
				
				//Legend
				var highGlucoseAxisValue:Number = glucoseHigh;
				if(glucoseUnit != "mg/dL")
					highGlucoseAxisValue = Math.round(((BgReading.mgdlToMmol((highGlucoseAxisValue))) * 10)) / 10;
				
				var highGlucoseOutput:String
				if (glucoseUnit == "mg/dL")
					highGlucoseOutput = String(Math.round(highGlucoseAxisValue));
				else
				{
					if ( highGlucoseAxisValue % 1 == 0)
						highGlucoseOutput = String(highGlucoseAxisValue) + ".0";
					else
						highGlucoseOutput = String(highGlucoseAxisValue);
				}
				
				if (highGlucoseLegend != null) highGlucoseLegend.dispose();
				highGlucoseLegend = GraphLayoutFactory.createGraphLegend(highGlucoseOutput, axisFontColor, legendTextSize * userAxisFontMultiplier);
				if (userAxisFontMultiplier >= 1)
					highGlucoseLegend.y = _graphHeight - ((glucoseHigh - lowestGlucoseValue) * scaleYFactor) - ((highGlucoseLegend.height / userAxisFontMultiplier) / 2) - ((highGlucoseLegend.height / userAxisFontMultiplier) / 8);
				else
					highGlucoseLegend.y = _graphHeight - ((glucoseHigh - lowestGlucoseValue) * scaleYFactor) - ((highGlucoseLegend.height * userAxisFontMultiplier) / 2) - ((highGlucoseLegend.height * userAxisFontMultiplier) / 8);
				highGlucoseLegend.y -= lineThickness;
				highGlucoseLegend.x = Math.round(_graphWidth - highestGlucoseLineMarker.width - highGlucoseLegend.width - legendMargin);
				yAxis.addChild(highGlucoseLegend);
				
				//Dashed Line
				if (highGlucoseDashedLine != null) highGlucoseDashedLine.dispose();
				highGlucoseDashedLine = GraphLayoutFactory.createHorizontalDashedLine(_graphWidth, dashLineWidth, dashLineGap, dashLineThickness, lineColor, legendMargin + dashLineWidth + ((legendTextSize * userAxisFontMultiplier) - legendTextSize));
				highGlucoseDashedLine.y = _graphHeight - ((glucoseHigh - lowestGlucoseValue) * scaleYFactor) - lineThickness;
				highGlucoseDashedLine.touchable = false;
				yAxis.addChild(highGlucoseDashedLine);
			}
			
			/**
			 * Low Glucose Threshold
			 */
			if(glucoseLow > lowestGlucoseValue && glucoseLow < highestGlucoseValue && displayLowLine)
			{
				//Line Marker
				if (lowGlucoseLineMarker != null) lowGlucoseLineMarker.dispose();
				lowGlucoseLineMarker = GraphLayoutFactory.createHorizontalLine(legendSize, lineThickness, lineColor);
				lowGlucoseLineMarker.x = _graphWidth - legendSize;
				lowGlucoseLineMarker.y = _graphHeight - ((glucoseLow - lowestGlucoseValue) * scaleYFactor) - lineThickness;
				lowGlucoseLineMarker.touchable = false;
				yAxis.addChild(lowGlucoseLineMarker);
				
				//Legend
				var lowGlucoseAxisValue:Number = glucoseLow;
				if(glucoseUnit != "mg/dL")
					lowGlucoseAxisValue = Math.round(((BgReading.mgdlToMmol((lowGlucoseAxisValue))) * 10)) / 10;
				
				var lowGlucoseOutput:String
				if (glucoseUnit == "mg/dL")
					lowGlucoseOutput = String(Math.round(lowGlucoseAxisValue));
				else
				{
					if ( lowGlucoseAxisValue % 1 == 0)
						lowGlucoseOutput = String(lowGlucoseAxisValue) + ".0";
					else
						lowGlucoseOutput = String(lowGlucoseAxisValue);
				}
				
				if (lowGlucoseLegend != null) lowGlucoseLegend.dispose();
				lowGlucoseLegend = GraphLayoutFactory.createGraphLegend(lowGlucoseOutput, axisFontColor, legendTextSize * userAxisFontMultiplier);
				if (userAxisFontMultiplier >= 1)
					lowGlucoseLegend.y = _graphHeight - ((glucoseLow - lowestGlucoseValue) * scaleYFactor) - ((lowGlucoseLegend.height / userAxisFontMultiplier) / 2) - ((lowGlucoseLegend.height / userAxisFontMultiplier) / 8);
				else
					lowGlucoseLegend.y = _graphHeight - ((glucoseLow - lowestGlucoseValue) * scaleYFactor) - ((lowGlucoseLegend.height * userAxisFontMultiplier) / 2) - ((lowGlucoseLegend.height * userAxisFontMultiplier) / 8);
				lowGlucoseLegend.y -= lineThickness;
				lowGlucoseLegend.x = Math.round(_graphWidth - lowGlucoseLineMarker.width - lowGlucoseLegend.width - legendMargin);
				yAxis.addChild(lowGlucoseLegend);
				
				//Dashed Line
				if (lowGlucoseDashedLine != null) lowGlucoseDashedLine.dispose();
				lowGlucoseDashedLine = GraphLayoutFactory.createHorizontalDashedLine(_graphWidth, dashLineWidth, dashLineGap, dashLineThickness, lineColor, legendMargin + dashLineWidth + ((legendTextSize * userAxisFontMultiplier) - legendTextSize));
				lowGlucoseDashedLine.y = _graphHeight - ((glucoseLow - lowestGlucoseValue) * scaleYFactor) - lineThickness;
				lowGlucoseDashedLine.touchable = false;
				yAxis.addChild(lowGlucoseDashedLine);
			}
			
			/**
			 * Urgent Low Glucose Threshold
			 */
			if(glucoseUrgentLow > lowestGlucoseValue && glucoseUrgentLow < highestGlucoseValue && displayUrgentLowLine && !dummyModeActive)
			{
				//Line Marker
				if (lowUrgentGlucoseLineMarker != null) lowUrgentGlucoseLineMarker.dispose();
				lowUrgentGlucoseLineMarker = GraphLayoutFactory.createHorizontalLine(legendSize, lineThickness, lineColor);
				lowUrgentGlucoseLineMarker.x = _graphWidth - legendSize;
				lowUrgentGlucoseLineMarker.y = _graphHeight - ((glucoseUrgentLow - lowestGlucoseValue) * scaleYFactor) - lineThickness;
				lowUrgentGlucoseLineMarker.touchable = false;
				yAxis.addChild(lowUrgentGlucoseLineMarker);
				
				//Legend
				var urgentLowGlucoseAxisValue:Number = glucoseUrgentLow;
				if(glucoseUnit != "mg/dL")
					urgentLowGlucoseAxisValue = Math.round(((BgReading.mgdlToMmol((urgentLowGlucoseAxisValue))) * 10)) / 10;
				
				var urgentLowGlucoseOutput:String
				if (glucoseUnit == "mg/dL")
					urgentLowGlucoseOutput = String(urgentLowGlucoseAxisValue);
				else
				{
					if ( urgentLowGlucoseAxisValue % 1 == 0)
						urgentLowGlucoseOutput = String(urgentLowGlucoseAxisValue) + ".0";
					else
						urgentLowGlucoseOutput = String(urgentLowGlucoseAxisValue);
				}
				
				if (lowUrgentGlucoseLegend != null) lowUrgentGlucoseLegend.dispose();
				lowUrgentGlucoseLegend = GraphLayoutFactory.createGraphLegend(urgentLowGlucoseOutput, axisFontColor, legendTextSize * userAxisFontMultiplier);
				if (userAxisFontMultiplier >= 1)
					lowUrgentGlucoseLegend.y = _graphHeight - ((glucoseUrgentLow - lowestGlucoseValue) * scaleYFactor) - ((lowUrgentGlucoseLegend.height / userAxisFontMultiplier) / 2) - ((lowUrgentGlucoseLegend.height / userAxisFontMultiplier) / 8);
				else
					lowUrgentGlucoseLegend.y = _graphHeight - ((glucoseUrgentLow - lowestGlucoseValue) * scaleYFactor) - ((lowUrgentGlucoseLegend.height * userAxisFontMultiplier) / 2) - ((lowUrgentGlucoseLegend.height * userAxisFontMultiplier) / 8);
				lowUrgentGlucoseLegend.y -= lineThickness;
				lowUrgentGlucoseLegend.x = Math.round(_graphWidth - lowUrgentGlucoseLineMarker.width - lowUrgentGlucoseLegend.width - legendMargin);
				yAxis.addChild(lowUrgentGlucoseLegend);
				
				//Dashed Line
				if (lowUrgentGlucoseDashedLine != null) lowUrgentGlucoseDashedLine.dispose();
				lowUrgentGlucoseDashedLine = GraphLayoutFactory.createHorizontalDashedLine(_graphWidth, dashLineWidth, dashLineGap, dashLineThickness, lineColor, legendMargin + dashLineWidth + ((legendTextSize * userAxisFontMultiplier) - legendTextSize));
				lowUrgentGlucoseDashedLine.y = _graphHeight - ((glucoseUrgentLow - lowestGlucoseValue) * scaleYFactor) - lineThickness;
				lowUrgentGlucoseDashedLine.touchable = false;
				yAxis.addChild(lowUrgentGlucoseDashedLine);
			}
			
			/**
			 * Target Glucose
			 */
			if(!isNaN(currentUserBGTarget) && displayTargetLine && currentUserBGTarget > lowestGlucoseValue && currentUserBGTarget < highestGlucoseValue && !dummyModeActive)
			{
				//Line Marker
				if (targetGlucoseLineMarker != null) targetGlucoseLineMarker.dispose();
				targetGlucoseLineMarker = GraphLayoutFactory.createHorizontalLine(legendSize, lineThickness, lineColor);
				targetGlucoseLineMarker.x = _graphWidth - legendSize;
				targetGlucoseLineMarker.y = _graphHeight - ((currentUserBGTarget - lowestGlucoseValue) * scaleYFactor) - lineThickness;
				targetGlucoseLineMarker.touchable = false;
				yAxis.addChild(targetGlucoseLineMarker);
				
				//Legend
				var targetGlucoseAxisValue:Number = currentUserBGTarget;
				if(glucoseUnit != "mg/dL")
					targetGlucoseAxisValue = Math.round(((BgReading.mgdlToMmol((currentUserBGTarget))) * 10)) / 10;
				
				var targetGlucoseOutput:String
				if (glucoseUnit == "mg/dL")
					targetGlucoseOutput = String(targetGlucoseAxisValue);
				else
				{
					if ( targetGlucoseAxisValue % 1 == 0)
						targetGlucoseOutput = String(targetGlucoseAxisValue) + ".0";
					else
						targetGlucoseOutput = String(targetGlucoseAxisValue);
				}
				
				if (targetGlucoseLegend != null) targetGlucoseLegend.dispose();
				targetGlucoseLegend = GraphLayoutFactory.createGraphLegend(targetGlucoseOutput, lineColor, legendTextSize * userAxisFontMultiplier);
				if (userAxisFontMultiplier >= 1)
					targetGlucoseLegend.y = _graphHeight - ((currentUserBGTarget - lowestGlucoseValue) * scaleYFactor) - ((targetGlucoseLegend.height / userAxisFontMultiplier) / 2) - ((targetGlucoseLegend.height / userAxisFontMultiplier) / 8);
				else
					targetGlucoseLegend.y = _graphHeight - ((currentUserBGTarget - lowestGlucoseValue) * scaleYFactor) - ((targetGlucoseLegend.height * userAxisFontMultiplier) / 2) - ((targetGlucoseLegend.height * userAxisFontMultiplier) / 8);
				targetGlucoseLegend.y -= lineThickness;
				targetGlucoseLegend.x = Math.round(_graphWidth - targetGlucoseLineMarker.width - targetGlucoseLegend.width - legendMargin);
				yAxis.addChild(targetGlucoseLegend);
				
				//Dashed Line
				if (targetGlucoseDashedLine != null) targetGlucoseDashedLine.dispose();
				targetGlucoseDashedLine = GraphLayoutFactory.createHorizontalDashedLine(_graphWidth, dashLineWidth, dashLineGap, dashLineThickness, targetLineColor, legendMargin + dashLineWidth + ((legendTextSize * userAxisFontMultiplier) - legendTextSize));
				targetGlucoseDashedLine.y = _graphHeight - ((currentUserBGTarget - lowestGlucoseValue) * scaleYFactor) - lineThickness;
				targetGlucoseDashedLine.touchable = false;
				yAxis.addChild(targetGlucoseDashedLine);
			}
			else if (targetGlucoseLineMarker != null)
			{
				targetGlucoseLineMarker.removeFromParent(true);
			}
			
			yAxisHeight = yAxis.height;
			
			return yAxis;
		}
		
		public function addGlucose(BGReadingsList:Array):Boolean
		{
			if(BGReadingsList == null || BGReadingsList.length == 0 || !SystemUtil.isApplicationActive)
				return false;
			
			var latestTimestamp:Number = Number(BGReadingsList[BGReadingsList.length - 1].timestamp);
			var firstTimestamp:Number;
			
			if(_dataSource != null && _dataSource.length >= 1 && mainChartGlucoseMarkersList[0].timestamp != null && !isNaN(mainChartGlucoseMarkersList[0].timestamp))
				firstTimestamp = Number(mainChartGlucoseMarkersList[0].timestamp);
			else
				firstTimestamp = Number.NaN;
			
			if(_dataSource.length >= 1 && !isNaN(firstTimestamp) && latestTimestamp - firstTimestamp > TimeSpan.TIME_24_HOURS + Constants.READING_OFFSET)
			{
				//Array has more than 24h of data. Remove timestamps older than 24H
				var removedMainGlucoseMarker:GlucoseMarker;
				var removedRawGlucoseMarker:GlucoseMarker;
				var removedScrollerGlucoseMarker:GlucoseMarker
				var currentTimestamp:Number = Number((mainChartGlucoseMarkersList[0] as GlucoseMarker).timestamp);
				
				while (latestTimestamp - currentTimestamp > TimeSpan.TIME_24_HOURS + Constants.READING_OFFSET) 
				{
					//Main Chart
					removedMainGlucoseMarker = mainChartGlucoseMarkersList.shift() as GlucoseMarker;
					mainChart.removeChild(removedMainGlucoseMarker);
					removedMainGlucoseMarker.dispose();
					removedMainGlucoseMarker = null;
					
					//Raw container
					if (displayRaw)
					{
						removedRawGlucoseMarker = rawGlucoseMarkersList.shift() as GlucoseMarker;
						removedRawGlucoseMarker.removeFromParent();
						removedRawGlucoseMarker.dispose();
						removedRawGlucoseMarker = null;
					}
					
					//Scroller Chart
					removedScrollerGlucoseMarker = scrollChartGlucoseMarkersList.shift() as GlucoseMarker;
					scrollerChart.removeChild(removedScrollerGlucoseMarker);
					removedScrollerGlucoseMarker.dispose();
					removedScrollerGlucoseMarker = null;
					
					//Data Source
					_dataSource.shift();
					
					//Update loop
					currentTimestamp = Number((mainChartGlucoseMarkersList[0] as GlucoseMarker).timestamp);
				}
				
				if (_dataSource.length > 288 && !CGMBlueToothDevice.isMiaoMiao() && !CGMBlueToothDevice.isFollower() && !predictionsEnabled) // >24H
				{
					var difference:int = _dataSource.length - 288;
					for (var i:int = 0; i < difference; i++) 
					{
						//Data Source
						_dataSource.shift();
						
						//Main Chart
						removedMainGlucoseMarker = mainChartGlucoseMarkersList.shift() as GlucoseMarker;
						mainChart.removeChild(removedMainGlucoseMarker);
						removedMainGlucoseMarker.dispose();
						removedMainGlucoseMarker = null;
						
						//Raw container
						if (displayRaw)
						{
							removedRawGlucoseMarker = rawGlucoseMarkersList.shift() as GlucoseMarker;
							removedRawGlucoseMarker.removeFromParent();
							removedRawGlucoseMarker.dispose();
							removedRawGlucoseMarker = null;
						}
						
						//Scroller Chart
						removedScrollerGlucoseMarker = scrollChartGlucoseMarkersList.shift() as GlucoseMarker;
						scrollerChart.removeChild(removedScrollerGlucoseMarker);
						removedScrollerGlucoseMarker.dispose();
						removedScrollerGlucoseMarker = null;
					}
				}
			}
			
			/* If there are previous lines, dispose them */
			if(_displayLine)
			{
				//Dispose previous lines
				destroyAllLines();
			}
			
			//Destroy Dummy Sprite
			if (dummySprite != null)
			{
				dummySprite.removeFromParent();
				dummySprite.dispose();
				dummySprite = null;
			}
			
			//Add the new readings to the data array
			var readingsLength:int = BGReadingsList.length;
			var latestAvailableTimestamp:Number;
			if (mainChartGlucoseMarkersList.length > 0)
				latestAvailableTimestamp = mainChartGlucoseMarkersList[mainChartGlucoseMarkersList.length - 1].timestamp;
			else
				latestAvailableTimestamp = 0;
			
			var numAddedReadings:int = 0;
			for (i = 0; i < readingsLength; i++) 
			{
				if (BGReadingsList[i].timestamp > latestAvailableTimestamp)
				{
					_dataSource.push(BGReadingsList[i]);
					numAddedReadings += 1;
				}
				//If this condition isn't met we don't add the reading for the following reasons:
				//The sensor has been stopped, lastNoSensor is called, but this returns the last reading with calculated value not 0
				//If a sensor is stopped, the app keeps receiving readings, but bgreading is an older reading
			}
			
			//Deativate DummyMode
			dummyModeActive = false;
			
			//Get previous chart width for later use in case of less than 24H data
			var previousChartWidth:Number = mainChart.width;
			
			//Destroy all previous lines
			if (_displayLine)
				destroyAllLines(true);
			
			//Destroy predictions
			if (predictionsEnabled)
				disposePredictions();
			
			//Redraw main chart, raw data points and scroller chart
			redrawChart(MAIN_CHART, _graphWidth - yAxisMargin, _graphHeight, yAxisMargin, mainChartGlucoseMarkerRadius, numAddedReadings);
			//if (displayRaw) redrawChart(MAIN_CHART, _graphWidth - yAxisMargin, _graphHeight, yAxisMargin, mainChartGlucoseMarkerRadius/2, numAddedReadings, true);
			if (displayRaw)
			{
				hideRaw();
				showRaw();
			}
			redrawChart(SCROLLER_CHART, _scrollerWidth - (scrollerChartGlucoseMarkerRadius * 2), _scrollerHeight, 0, scrollerChartGlucoseMarkerRadius, numAddedReadings);
			
			//Recalculate first and last timestamp
			if(mainChartGlucoseMarkersList != null && mainChartGlucoseMarkersList.length > 0)
			{
				firstTimestamp = Number(mainChartGlucoseMarkersList[0].timestamp);
				latestTimestamp = Number(mainChartGlucoseMarkersList[mainChartGlucoseMarkersList.length - 1].timestamp);
			}
			
			//Adjust Main Chart and Picker Position
			if (_graphWidth - (handPicker.x + handPicker.width) <= _graphWidth / 67)
			{
				//Hand picker is almost at the end of the screen (less or equal than 1.5% of the screen width), probably the user left it there unintentionaly.
				//Let's put the handpicker at the end of the screen and make sure we display the latest glucose value
				handPicker.x = _graphWidth - handPicker.width;
				displayLatestBGValue = true;
			}
			
			if (displayLatestBGValue)
			{
				mainChart.x = -mainChart.width + _graphWidth - yAxisMargin;
				if (predictionsEnabled && predictionsMainGlucoseDataPoints != null && predictionsMainGlucoseDataPoints.length > 0)
				{
					mainChart.x += mainChartGlucoseMarkerRadius;
				}
				selectedGlucoseMarkerIndex = mainChartGlucoseMarkersList[mainChartGlucoseMarkersList.length - 1].index;
			}
			else if (!isNaN(firstTimestamp) && latestTimestamp - firstTimestamp < TimeSpan.TIME_23_HOURS_57_MINUTES)
			{
				mainChart.x -= mainChart.width - previousChartWidth;
				selectedGlucoseMarkerIndex += 1;
			}
			
			if (displayRaw) rawDataContainer.x = mainChart.x;
			
			//Adjust Pcker Position
			if (!displayLatestBGValue && !isNaN(firstTimestamp) && latestTimestamp - firstTimestamp < TimeSpan.TIME_23_HOURS_57_MINUTES && mainChart.x <= 0)
			{
				handPicker.x += (mainChart.width - previousChartWidth) * scrollMultiplier;
				if (handPicker.x > _graphWidth - handPicker.width)
				{
					handPicker.x = _graphWidth - handPicker.width;
					mainChart.x = -mainChart.width + _graphWidth - yAxisMargin;
					if (predictionsEnabled && predictionsMainGlucoseDataPoints != null && predictionsMainGlucoseDataPoints.length > 0)
					{
						mainChart.x += mainChartGlucoseMarkerRadius;
					}
					displayLatestBGValue = true;
					selectedGlucoseMarkerIndex = mainChartGlucoseMarkersList[mainChartGlucoseMarkersList.length - 1].index;
				}
			}
			
			//Define scroll multiplier for scroller vs main graph
			if (mainChart.x > 0)
				scrollMultiplier = Math.abs(mainChart.width - (mainChartGlucoseMarkerRadius * 2))/handPicker.x
			else
			{
				var calculatedScrollMultiplier:Number = Math.abs(mainChart.x)/handPicker.x;
				if (!isNaN(calculatedScrollMultiplier))
					scrollMultiplier = calculatedScrollMultiplier;
			}
			
			//Restart Update timer
			statusUpdateTimer.stop();
			statusUpdateTimer.delay = 60 * 1000; //1 minute
			statusUpdateTimer.start();
			
			//Calculate Display Labels
			currentNumberOfMakers = _dataSource.length;
			calculateDisplayLabels();
			
			drawTimeline();
			addAllTreatments();
			manageTreatments();
			var timelineTimestamp:Number = getTimelineTimestamp();
			if (displayIOBEnabled)
				calculateTotalIOB(timelineTimestamp);
			if (displayCOBEnabled)
				calculateTotalCOB(timelineTimestamp);
			
			//Timeline
			if (timelineActive && timelineContainer != null)
				timelineContainer.x = mainChart.x;
			
			//Treatments
			if (treatmentsActive && treatmentsContainer != null)
				treatmentsContainer.x = mainChart.x;
			
			//Raw
			if (displayRaw && rawDataContainer != null)
				rawDataContainer.x = mainChart.x;
			
			return true;
		}
		
		private function redrawChart(chartType:String, chartWidth:Number, chartHeight:Number, chartRightMargin:Number, glucoseMarkerRadius:Number, numNewReadings:int, isRaw:Boolean = false, forcePredictionsCOBRefresh:Boolean = false, calibratedPredictions:Array = null):void
		{
			if (!SystemUtil.isApplicationActive || dummyModeActive || mainChart == null)
				return;
			
			/**
			 * Predictions
			 */
			if (!isNaN(redrawPredictionsTimeoutID)) clearTimeout(redrawPredictionsTimeoutID);
			
			var predictionsList:Array = [];
			if (predictionsEnabled)
			{
				//Special case for latest carb treatment
				var lastTreatmentIsCarbs:Boolean = TreatmentsManager.lastTreatmentIsCarb();
				
				if (calibratedPredictions != null)
				{
					predictionsList = calibratedPredictions;
				}
				else
				{
					predictionsList = fetchPredictions(lastTreatmentIsCarbs);
				}
			}
			
			//Safeguards
			if (predictionsList == null ) predictionsList = [];
			if (predictionsMainGlucoseDataPoints == null) predictionsMainGlucoseDataPoints = [];
			
			if (predictionsEnabled && predictionsList.length == 0 && predictionsMainGlucoseDataPoints.length > 0)
			{
				//Can't get new predictions. Dispose old ones
				disposePredictions();
			}
			
			/**
			 * Calculation of X Axis scale factor
			 */
			var firstTimeStamp:Number = Number(_dataSource[0].timestamp);
			var lastTimeStamp:Number = !predictionsEnabled || predictionsList.length == 0 ? new Date().valueOf() : predictionsList[predictionsList.length - 1].timestamp;
			var totalTimestampDifference:Number = lastTimeStamp - firstTimeStamp;
			var scaleXFactor:Number;
			
			if(chartType == MAIN_CHART)
			{
				//The following 3 lines of code are meant to scale the main chart correctly in case there's less than 24h of data
				differenceInMinutesForAllTimestamps = TimeSpan.fromDates(new Date(firstTimeStamp), new Date(lastTimeStamp)).totalMinutes;
				if (differenceInMinutesForAllTimestamps > TimeSpan.TIME_ONE_DAY_IN_MINUTES)
					differenceInMinutesForAllTimestamps = TimeSpan.TIME_ONE_DAY_IN_MINUTES;
				
				//scaleXFactor = 1/(totalTimestampDifference / (chartWidth * timelineRange));
				scaleXFactor = 1/(totalTimestampDifference / (chartWidth * (timelineRange / (TimeSpan.TIME_ONE_DAY_IN_MINUTES / differenceInMinutesForAllTimestamps))));
				if (!isRaw) mainChartXFactor = scaleXFactor;
			}
			else if (chartType == SCROLLER_CHART)
				scaleXFactor = 1/(totalTimestampDifference / (chartWidth - chartRightMargin));
			
			/* Update values for update timer */
			firstBGReadingTimeStamp = firstTimeStamp;
			lastBGreadingTimeStamp = new Date().valueOf();
			
			/**
			 * Calculation of Y Axis scale factor
			 */
			//First we determine the maximum and minimum glucose values
			var previousHighestGlucoseValue:Number = highestGlucoseValue;
			var previousLowestGlucoseValue:Number = lowestGlucoseValue;
			
			var sortDataArray:Array = predictionsList.length == 0 ? _dataSource.concat() : _dataSource.concat().concat(predictionsList);
			sortDataArray.sortOn(["_calculatedValue"], Array.NUMERIC);
			
			var lowestValue:Number = sortDataArray[0]._calculatedValue as Number;
			var highestValue:Number = sortDataArray[sortDataArray.length - 1]._calculatedValue as Number;
			
			if (!fixedSize)
			{
				lowestGlucoseValue = lowestValue;
				if (lowestGlucoseValue < 40)
					lowestGlucoseValue = 40;
				
				highestGlucoseValue = highestValue;
				if (highestGlucoseValue > 400)
					highestGlucoseValue = 400;
			}
			else
			{
				lowestGlucoseValue = minAxisValue;
				if (resizeOutOfBounds && lowestValue < minAxisValue)
					lowestGlucoseValue = lowestValue;
				
				highestGlucoseValue = maxAxisValue;
				if (resizeOutOfBounds && highestValue > maxAxisValue)
					highestGlucoseValue = highestValue
			}
			
			//We find the difference so we can know how big the glucose pseudo graph is
			var totalGlucoseDifference:Number = highestGlucoseValue - lowestGlucoseValue;
			//Now we find a multiplier for the y axis so the glucose graph fits entirely with the chart height
			scaleYFactor = (chartHeight - (glucoseMarkerRadius*2))/totalGlucoseDifference;
			
			/**
			 * Internal variables
			 */
			var i:int; //common index for loops
			var previousXCoordinate:Number = 0; //holder for x coordinate of the glucose value to be used by the following one
			var previousGlucoseMarker:GlucoseMarker;
			var lastRealGlucoseMarker:GlucoseMarker;
			
			/**
			 * Creation and placement of the glucose values
			 */
			//Line Chart
			if(_displayLine && !isRaw)
			{
				var line:SpikeLine = new SpikeLine();
				line.touchable = false;
				line.lineStyle(chartType == SCROLLER_CHART && glucoseLineThickness > 1 ? glucoseLineThickness / 2 : glucoseLineThickness, 0xFFFFFF, 1);
				
				if(chartType == MAIN_CHART)
				{
					if (mainChartLine != null) mainChartLine.removeFromParent(true);
					mainChartLine = line;
				}
				else if (chartType == SCROLLER_CHART)
				{
					if (scrollerChartLine != null) scrollerChartLine.removeFromParent(true);
					scrollerChartLine = line;
				}
			}
			
			//Loop through all available data points
			var extraEndLineColor:uint;
			var doublePrevGlucoseReading:BgReading;
			var previousLineX:Number;
			var previousLineY:Number;
			var isPrediction:Boolean
			var index:int;
			var readingsSource:Array;
			var predictionsLength:int = predictionsList.length;
			var realReadingsLength:int = _dataSource.length;
			var dataLength:int = realReadingsLength + predictionsLength;
			
			for(i = 0; i < dataLength; i++)
			{
				isPrediction = i >= realReadingsLength;
				
				if (isPrediction && isRaw)
				{
					//Don't add raw for predictions
					break;
				}
				
				index = !isPrediction ? i : i - realReadingsLength;
				readingsSource = !isPrediction ? _dataSource : predictionsList;
				if (readingsSource == null) continue;
				
				var glucoseReading:BgReading = readingsSource[index];
				if (glucoseReading == null) continue;
				
				var currentGlucoseValue:Number = !isRaw ? Number(glucoseReading._calculatedValue) : GlucoseFactory.getRawGlucose(glucoseReading, glucoseReading.calibration);
				if (currentGlucoseValue < 40)
					currentGlucoseValue = 40;
				else if (currentGlucoseValue > 400)
					currentGlucoseValue = 400;
				
				var glucoseMarker:GlucoseMarker;
				if(i < dataLength - 1 && chartType == MAIN_CHART && !isPrediction)
					glucoseMarker = !isRaw ? mainChartGlucoseMarkersList[i] : rawGlucoseMarkersList[i];
				else if(i < dataLength - 1 && chartType == SCROLLER_CHART)
					glucoseMarker = scrollChartGlucoseMarkersList[i];
				
				//Define glucose marker x position
				var glucoseX:Number;
				if(i==0)
					glucoseX = !isRaw ? 0 : glucoseMarkerRadius;
				else
				{
					var prevReading:BgReading;
					if (!isPrediction)
					{
						prevReading = _dataSource[i-1];
						if (prevReading == null) continue;
						
						glucoseX = (Number(glucoseReading.timestamp) - Number(prevReading._timestamp)) * scaleXFactor;
					}
					else if (isPrediction && index == 0)
					{
						prevReading = _dataSource[_dataSource.length-1];
						if (prevReading == null) continue;
						
						glucoseX = (Number(glucoseReading.timestamp) - Number(prevReading.timestamp)) * scaleXFactor;
					}
					else
					{
						prevReading = readingsSource[index-1];
						if (prevReading == null) continue;
						
						glucoseX = (Number(glucoseReading.timestamp) - Number(prevReading.timestamp)) * scaleXFactor;
					}
				}
				
				//Define glucose marker y position
				var glucoseY:Number = chartHeight - (glucoseMarkerRadius*2) - ((currentGlucoseValue - lowestGlucoseValue) * scaleYFactor);
				if (isRaw) glucoseY -= glucoseMarkerRadius;
				//If glucose is a perfect flat line then display it in the middle
				if(totalGlucoseDifference == 0 && !isRaw) 
					glucoseY = (chartHeight - (glucoseMarkerRadius*2)) / 2;
				
				if(i < realReadingsLength - numNewReadings && !isPrediction && glucoseMarker != null)
				{
					glucoseMarker.x = previousXCoordinate + glucoseX;
					glucoseMarker.y = glucoseY;
					glucoseMarker.index = i;
				}
				else
				{
					if (!isRaw && !isPrediction)
					{
						glucoseMarker = new GlucoseMarker
						(
							{
								x: previousXCoordinate + glucoseX,
								y: glucoseY,
								index: i,
								radius: glucoseMarkerRadius,
								bgReading: glucoseReading,
								previousGlucoseValueFormatted: previousGlucoseMarker != null ? previousGlucoseMarker.glucoseValueFormatted : null,
								previousGlucoseValue: previousGlucoseMarker != null ? previousGlucoseMarker.glucoseValue : null
							}
						);
					}
					else if (isPrediction)
					{
						glucoseMarker = new GlucoseMarker
							(
								{
									x: previousXCoordinate + glucoseX,
									y: glucoseY,
									index: i,
									radius: glucoseMarkerRadius,
									bgReading: glucoseReading,
									glucose: currentGlucoseValue,
									color: glucoseReading.rawData
								},
								false,
								true
							);
					}
					else if (isRaw)
					{
						glucoseMarker = new GlucoseMarker
						(
							{
								x: previousXCoordinate + glucoseX,
								y: glucoseY,
								index: i,
								radius: glucoseMarkerRadius,
								bgReading: glucoseReading,
								raw: currentGlucoseValue,
								rawColor: rawColor
							},
							true
						);
					}
					
					if (glucoseMarker == null)
						continue;
					
					if (!isPrediction)
					{
						glucoseMarker.touchable = false;
					}
					else
					{
						if(chartType == MAIN_CHART)
							glucoseMarker.addEventListener(TouchEvent.TOUCH, onPredictionMarkerTouched);
					}
					
					if(chartType == MAIN_CHART)
					{
						if (!isRaw)
						{
							//Add it to the display list
							mainChart.addChild(glucoseMarker);
							//Save it in the array for later
							if (!isPrediction && mainChartGlucoseMarkersList != null)
								mainChartGlucoseMarkersList.push(glucoseMarker);
							else if (predictionsMainGlucoseDataPoints != null)
								predictionsMainGlucoseDataPoints.push(glucoseMarker);
						}
						else
						{
							//Add it to the display list
							if (rawDataContainer != null)
								rawDataContainer.addChild(glucoseMarker);
							//Save it in the array for later
							if (rawGlucoseMarkersList != null)
								rawGlucoseMarkersList.push(glucoseMarker);
						}
					}
					else if (chartType == SCROLLER_CHART)
					{
						//Add it to the display list
						if (scrollerChart != null)
							scrollerChart.addChild(glucoseMarker);
						//Save it in the array for later
						if (!isPrediction && scrollChartGlucoseMarkersList != null)
							scrollChartGlucoseMarkersList.push(glucoseMarker);
						else if (predictionsScrollerGlucoseDataPoints != null)
							predictionsScrollerGlucoseDataPoints.push(glucoseMarker);
					}
				}
				
				//Hide glucose marker if it is out of bounds (fixed size chart);
				if (glucoseMarker.glucoseValue < lowestGlucoseValue || glucoseMarker.glucoseValue > highestGlucoseValue)
					glucoseMarker.alpha = 0;
				else
					glucoseMarker.alpha = 1;
				
				//Draw line
				if(glucoseMarker != null && _displayLine && !isRaw && glucoseMarker.bgReading != null && glucoseMarker.bgReading != null && glucoseMarker.bgReading._calculatedValue != 0 && (glucoseMarker.bgReading.sensor != null || CGMBlueToothDevice.isFollower() || isPrediction) && glucoseMarker.glucoseValue >= lowestGlucoseValue && glucoseMarker.glucoseValue <= highestGlucoseValue)
				{
					var newPredictionSet:Boolean = isPrediction && previousGlucoseMarker != null && previousGlucoseMarker.bgReading.uniqueId.length == 3 && glucoseMarker.bgReading.uniqueId.length == 3 && previousGlucoseMarker.bgReading.uniqueId != glucoseMarker.bgReading.uniqueId;
					if (!isPrediction && i == realReadingsLength - 1)
					{
						lastRealGlucoseMarker = glucoseMarker;
					}
					
					if(i == 0)
						line.moveTo(glucoseMarker.x, glucoseMarker.y);
					else
					{
						var currentLineX:Number;
						var currentLineY:Number;
						
						if((i < dataLength -1 || isPrediction) && i != realReadingsLength - 1)
						{
							currentLineX = glucoseMarker.x + (glucoseMarker.width/2);
							currentLineY = glucoseMarker.y + (glucoseMarker.height/2);
						}
						else if (i == dataLength -1 || i == realReadingsLength - 1)
						{
							currentLineX = glucoseMarker.x + (glucoseMarker.width);
							currentLineY = glucoseMarker.y + (glucoseMarker.height/2);
							if (previousGlucoseMarker != null)
							{
								currentLineY += (glucoseMarker.y - previousGlucoseMarker.y) / 3;
							}
						}
						
						//Style
						var currentColor:uint = glucoseMarker.color
						var previousColor:uint;
						
						//Determine if missed readings are bigger than the acceptable gap. If so, the line will be gray;
						line.lineStyle(chartType == SCROLLER_CHART && glucoseLineThickness > 1 ? glucoseLineThickness / 2 : glucoseLineThickness, glucoseMarker.color, 1);
						if(i > 0 && previousGlucoseMarker != null)
						{
							var elapsedMinutes:Number = TimeSpan.fromDates(new Date(previousGlucoseMarker.timestamp), new Date(glucoseMarker.timestamp)).minutes;
							if (elapsedMinutes > NUM_MINUTES_MISSED_READING_GAP)
							{
								currentColor = oldColor;
								previousColor = oldColor;
							}
							else
								previousColor = previousGlucoseMarker.color;
						}
						
						if (newPredictionSet)
						{
							//Add extra line to the beginning
							/*if (lastRealGlucoseMarker != null)
							{
								line.moveTo(lastRealGlucoseMarker.x + lastRealGlucoseMarker.width, lastRealGlucoseMarker.y + (lastRealGlucoseMarker.height / 2));
								line.lineTo(currentLineX, currentLineY, lastRealGlucoseMarker.color, glucoseMarker.color);
							}*/
							
							//Add extra line to the end
							if (previousGlucoseMarker != null)
							{
								if (chartType == MAIN_CHART && isPrediction) previousGlucoseMarker.removeHitArea();
								
								var extraSetPredictionLineX:Number = previousGlucoseMarker.x + previousGlucoseMarker.width;
								var extraSetPredictionLineY:Number = previousGlucoseMarker.y + (previousGlucoseMarker.height / 2);
								extraEndLineColor = previousGlucoseMarker.color;
								doublePrevGlucoseReading = readingsSource[index - 2];
								if (doublePrevGlucoseReading != null)
								{
									extraEndLineColor = doublePrevGlucoseReading.rawData;
								}
								
								//Try to calculate y direction of previous line by fetching 2 previous glucose markers
								var targetGlucoseMarker:GlucoseMarker;
								if(chartType == MAIN_CHART && index - 2 > 0)
								{
									targetGlucoseMarker = predictionsMainGlucoseDataPoints[index - 2];
								}
								else if (chartType == SCROLLER_CHART && index - 2 > 0)
								{
									targetGlucoseMarker = predictionsScrollerGlucoseDataPoints[index - 2];
								}
								
								//Marker found, add y difference
								if (targetGlucoseMarker != null)
								{
									if (chartType == MAIN_CHART && isPrediction) targetGlucoseMarker.removeHitArea();
									
									line.moveTo(extraSetPredictionLineX, extraSetPredictionLineY + ((previousGlucoseMarker.y - targetGlucoseMarker.y) / 3));
									
									if (chartType == MAIN_CHART && isPrediction) targetGlucoseMarker.addHitArea();
								}
								else
								{
									line.moveTo(extraSetPredictionLineX, extraSetPredictionLineY);
								}
								
								line.lineTo(extraSetPredictionLineX - (previousGlucoseMarker.width / 2), extraSetPredictionLineY, extraEndLineColor, extraEndLineColor);
								
								if (chartType == MAIN_CHART && isPrediction) previousGlucoseMarker.addHitArea();
							}
						}
						
						if ((isNaN(previousColor) || isPrediction) && index != 0)
						{
							if (!isPrediction)
							{
								line.lineTo(currentLineX, currentLineY);
							}
							else
							{
								if (previousGlucoseMarker != null && previousGlucoseMarker.bgReading != null && glucoseMarker.bgReading != null && previousGlucoseMarker.bgReading.uniqueId == glucoseMarker.bgReading.uniqueId && !newPredictionSet)
								{
									line.lineTo((currentLineX + previousLineX) / 2, (currentLineY + previousLineY) / 2);
								}
							}
						}
						else
						{
							if (!isPrediction && !index == 0)
							{
								line.lineTo(currentLineX, currentLineY, previousColor, currentColor);	
							}
						}
						
						line.moveTo(currentLineX, currentLineY);
						
						previousLineX = currentLineX;
						previousLineY = currentLineY;
					}
					//Hide glucose marker
					glucoseMarker.alpha = 0;
				}
				
				//Hide markers without sensor
				if ((glucoseReading.sensor == null && !CGMBlueToothDevice.isFollower() && !isPrediction) || glucoseReading._calculatedValue == 0 || (glucoseReading.rawData == 0 && !CGMBlueToothDevice.isFollower()))
					glucoseMarker.alpha = 0;
				
				
				//Update variables for next iteration
				previousXCoordinate = previousXCoordinate + glucoseX;
				if (i < dataLength - 1)
					previousGlucoseMarker = glucoseMarker;
					
				if (isPrediction && chartType == MAIN_CHART)
				{
					glucoseMarker.addHitArea();
				}
			}
			
			//Predictions line fix
			if (glucoseMarker != null && previousGlucoseMarker != null && _displayLine && !isRaw && previousGlucoseMarker != null && glucoseMarker.bgReading != null && glucoseMarker.bgReading._calculatedValue != 0 && (glucoseMarker.bgReading.sensor != null || CGMBlueToothDevice.isFollower() || isPrediction) && glucoseMarker.glucoseValue >= lowestGlucoseValue && glucoseMarker.glucoseValue <= highestGlucoseValue && predictionsEnabled && predictionsLength > 0)
			{
				//Add an extra line
				if (chartType == MAIN_CHART && isPrediction) glucoseMarker.removeHitArea();
				
				var extraPredictionLineX:Number = glucoseMarker.x + glucoseMarker.width;
				var extraPredictionLineY:Number = glucoseMarker.y + (glucoseMarker.height / 2);
				extraEndLineColor = previousGlucoseMarker.color;
				doublePrevGlucoseReading = readingsSource[index - 2];
				if (doublePrevGlucoseReading != null)
				{
					extraEndLineColor = doublePrevGlucoseReading.rawData;
				}
				
				line.moveTo(extraPredictionLineX, extraPredictionLineY + ((glucoseMarker.y - previousGlucoseMarker.y) / 3));
				line.lineTo(extraPredictionLineX - (glucoseMarker.width / 2), extraPredictionLineY, extraEndLineColor, extraEndLineColor);
				
				if (chartType == MAIN_CHART && isPrediction) glucoseMarker.addHitArea();
			}
			
			if(chartType == MAIN_CHART && !isRaw)
			{
				//YAxis
				var newBgTarget:Number = Number.NaN;
				if (displayTargetLine)
				{
					try
					{
						var nowProfile:Profile = ProfileManager.getProfileByTime(new Date().valueOf());
						if (nowProfile != null)
						{
							newBgTarget = Number(nowProfile.targetGlucoseRates);
						}
					} 
					catch(error:Error) {}
				}
				
				if((highestGlucoseValue != previousHighestGlucoseValue || lowestGlucoseValue != previousLowestGlucoseValue) || (displayTargetLine && !isNaN(newBgTarget) && newBgTarget != currentUserBGTarget) || (predictionsEnabled && predictionsList.length == 0 && predictionsDelimiter != null))
				{
					//Update BG Target Variable
					currentUserBGTarget = newBgTarget;
					
					//Dispose YAxis
					yAxisContainer.dispose();
					
					//Redraw YAxis
					yAxisContainer.addChild(drawYAxis());
				}
				
				//Update glucose display textfield
				if(displayLatestBGValue && glucoseValueDisplay != null)
				{
					var displayMarker:GlucoseMarker = mainChartGlucoseMarkersList[mainChartGlucoseMarkersList.length - 1];
					
					if (displayMarker != null)
					{
						glucoseValueDisplay.text = displayMarker.glucoseValueFormatted + " " + displayMarker.slopeArrow;
						glucoseValueDisplay.fontStyles.color = displayMarker.color;
					}
				}
			}
			//Chart Line
			if(_displayLine && !isRaw && line != null)
			{	
				//Remove touch events from line
				line.touchable = false;
				
				//Add Line to the display list
				if(chartType == MAIN_CHART)
					mainChart.addChild(line);
				else if(chartType == SCROLLER_CHART)
					scrollerChart.addChild(line);
				
				//Save line references for later use
				if(chartType == MAIN_CHART)
					mainChartLineList.push(line);
				else if (chartType == SCROLLER_CHART)
					scrollerChartLineList.push(line);
			}
			
			if(chartType == MAIN_CHART && !isRaw)
				mainChartYFactor = scaleYFactor;
			
			//Reporition prediction delimitter
			reporsitionPredictionDelimitter();
		}
		
		public function calculateDisplayLabels():void
		{
			if (currentNumberOfMakers == previousNumberOfMakers && !displayLatestBGValue)
				return;
			
			if (glucoseValueDisplay == null || glucoseTimeAgoPill == null || glucoseSlopePill == null || activeGlucoseDelimiter == null)
				return;
			
			if (!SystemUtil.isApplicationActive)
				return;
			
			var timeAgoValue:String;
			
			if (!displayLatestBGValue && !dummyModeActive)
			{
				if (mainChartGlucoseMarkersList == null || mainChartGlucoseMarkersList.length == 0 || selectedGlucoseMarkerIndex == mainChartGlucoseMarkersList.length - 1 || mainChartGlucoseMarkersList[selectedGlucoseMarkerIndex + 1] == null || mainChartGlucoseMarkersList[selectedGlucoseMarkerIndex] == null || mainChartGlucoseMarkersList[0] == null)
					return;
				
				var nextMarker:GlucoseMarker = mainChartGlucoseMarkersList[selectedGlucoseMarkerIndex + 1] as GlucoseMarker;
				var nextTimestamp:Number = nextMarker.timestamp;
				var nextMarkerGlobalX:Number = nextMarker.x + mainChart.x;
				var currentMarker:GlucoseMarker = mainChartGlucoseMarkersList[selectedGlucoseMarkerIndex] as GlucoseMarker;
				var currentMarkerGlobalX:Number = currentMarker.x + mainChart.x;
				var hitTestCurrent:Boolean = currentMarkerGlobalX - currentMarker.width < activeGlucoseDelimiter.x;
				var currentTimestamp:Number = currentMarker.timestamp;
				var timeSpan:TimeSpan = TimeSpan.fromDates(new Date(currentTimestamp), new Date(nextTimestamp));
				var differenceInMinutes:Number = timeSpan.totalMinutes;
				var differenceInSeconds:Number = timeSpan.totalSeconds;
				
				if (mainChartGlucoseMarkersList.length > 1)
				{
					// Get current timeline timestamp
					var firstAvailableTimestamp:Number = (mainChartGlucoseMarkersList[0] as GlucoseMarker).timestamp;
					var currentTimelineTimestamp:Number = firstAvailableTimestamp + (Math.abs(mainChart.x - (_graphWidth - yAxisMargin) + (mainChartGlucoseMarkerRadius * 2)) / mainChartXFactor);
					var previousMaker:GlucoseMarker = null;
					if (selectedGlucoseMarkerIndex > 0 && mainChartGlucoseMarkersList[selectedGlucoseMarkerIndex - 1] != null)
						previousMaker = mainChartGlucoseMarkersList[selectedGlucoseMarkerIndex - 1] as GlucoseMarker;
				}
				
				if (differenceInMinutes <= 16)
				{
					if (hitTestCurrent)
					{
						//Glucose Value Display
						glucoseValueDisplay.text = currentMarker.glucoseOutput + " " + currentMarker.slopeArrow;
						if (differenceInMinutes <= 6)
							glucoseValueDisplay.fontStyles.color = currentMarker.color;
						else
							glucoseValueDisplay.fontStyles.color = oldColor;
						
						//Marker Date Time
						glucoseTimeAgoPill.setValue(currentMarker.timeFormatted, retroOutput, differenceInMinutes <= 6 ? chartFontColor : oldColor);
						
						//Marker Slope
						glucoseSlopePill.setValue(currentMarker.slopeOutput, glucoseUnit, differenceInMinutes <= 6 ? chartFontColor : oldColor);
						
						selectedGlucoseMarkerIndex = currentMarker.index;
					}
					else if (mainChartGlucoseMarkersList.length > 1) /* Extra Actions */
					{
						if (previousMaker != null && currentTimelineTimestamp - previousMaker.timestamp > TimeSpan.TIME_16_MINUTES && !hitTestCurrent)
						{
							glucoseValueDisplay.text = "---";
							glucoseValueDisplay.fontStyles.color = oldColor;
							glucoseSlopePill.setValue("", "", oldColor);
						}
						else if (previousMaker != null && currentTimelineTimestamp - previousMaker.timestamp > TimeSpan.TIME_75_SECONDS && Math.abs(currentMarker.timestamp - currentTimelineTimestamp) > TimeSpan.TIME_5_MINUTES && currentTimelineTimestamp - previousMaker.timestamp <= TimeSpan.TIME_16_MINUTES && !hitTestCurrent)
						{
							glucoseValueDisplay.fontStyles.color = oldColor;
							glucoseSlopePill.setValue(glucoseSlopePill.value, glucoseSlopePill.unit, oldColor);
						}
						
						if (previousMaker != null && currentTimelineTimestamp - previousMaker.timestamp > TimeSpan.TIME_75_SECONDS && Math.abs(currentMarker.timestamp - currentTimelineTimestamp) > TimeSpan.TIME_5_MINUTES && !hitTestCurrent)
						{
							var currentTimelineDate:Date = new Date(currentTimelineTimestamp);
							var currentTimelineHours:Number = currentTimelineDate.hours;
							var currentTimelineMinutes:Number = currentTimelineDate.minutes;
							var currentTimelineOutput:String;
							
							if (dateFormat.slice(0,2) == "24")
								currentTimelineOutput = TimeSpan.formatHoursMinutes(currentTimelineHours, currentTimelineMinutes, TimeSpan.TIME_FORMAT_24H);
							else
								currentTimelineOutput = TimeSpan.formatHoursMinutes(currentTimelineHours, currentTimelineMinutes, TimeSpan.TIME_FORMAT_12H);
							
							glucoseTimeAgoPill.setValue(currentTimelineOutput, retroOutput, oldColor);
						}
					}
				}
				else if (nextMarkerGlobalX < activeGlucoseDelimiter.x && !hitTestCurrent)
				{
					//Glucose Value Display
					glucoseValueDisplay.text = nextMarker.glucoseOutput + " " + nextMarker.slopeArrow;
					glucoseValueDisplay.fontStyles.color = nextMarker.color;
					
					//Marker Date Time
					glucoseTimeAgoPill.setValue(nextMarker.timeFormatted, retroOutput, chartFontColor);
					
					//Marker Slope
					glucoseSlopePill.setValue(nextMarker.slopeOutput, glucoseUnit, chartFontColor);
					
					selectedGlucoseMarkerIndex = nextMarker.index;
				}
				else
				{
					if (!hitTestCurrent)
					{
						//Glucose Value Display
						glucoseValueDisplay.text = "---";
						glucoseValueDisplay.fontStyles.color = oldColor;
						
						//Marker Date Time
						timeAgoValue = TimeSpan.formatHoursMinutesFromSecondsChart(differenceInSeconds, false, false);
						if (timeAgoValue != now)
							glucoseTimeAgoPill.setValue(timeAgoValue, ago, oldColor);
						else
							glucoseTimeAgoPill.setValue("0 min", now, oldColor);
						
						//Marker Slope
						glucoseSlopePill.setValue("???", "", oldColor);
						
						if (selectedGlucoseMarkerIndex > 0)
							selectedGlucoseMarkerIndex -= 1;
					}
				}
				currentNumberOfMakers == previousNumberOfMakers
			}
			else
			{
				if (mainChartGlucoseMarkersList == null || mainChartGlucoseMarkersList.length == 0 || dummyModeActive)
				{
					//Glucose Value Display
					glucoseValueDisplay.text = "---";
					if (dummyModeActive)
						glucoseValueDisplay.fontStyles.color = newColor;
					else
						glucoseValueDisplay.fontStyles.color = oldColor;
					
					//Marker Date Time
					glucoseTimeAgoPill.setValue("", "", oldColor);
					
					//Marker Slope
					glucoseSlopePill.setValue("", "", oldColor)
				}
				else
				{
					//Display Latest Glucose
					var latestMarker:GlucoseMarker = mainChartGlucoseMarkersList[mainChartGlucoseMarkersList.length - 1] as GlucoseMarker;
					var nowTimestamp:Number = (new Date()).valueOf();
					var latestMarkerTimestamp:Number = latestMarker.timestamp;
					var timestampDifference:Number = nowTimestamp - latestMarkerTimestamp;
					var timestampDifferenceInSeconds:Number = timestampDifference / 1000;
					
					if (isHistoricalData)
					{
						//Glucose Value Display
						glucoseValueDisplay.text = latestMarker.glucoseOutput + " " + latestMarker.slopeArrow;
						glucoseValueDisplay.fontStyles.color = latestMarker.color;
						
						//Marker Date Time
						glucoseTimeAgoPill.setValue(latestMarker.timeFormatted, retroOutput, chartFontColor);
						
						//Marker Slope
						glucoseSlopePill.setValue(latestMarker.slopeOutput, glucoseUnit, chartFontColor);
					}
					else if (timestampDifference <= TimeSpan.TIME_16_MINUTES)
					{
						//Glucose Value Display
						glucoseValueDisplay.text = latestMarker.glucoseOutput + " " + latestMarker.slopeArrow;
						if (timestampDifference <= TimeSpan.TIME_6_MINUTES)
							glucoseValueDisplay.fontStyles.color = latestMarker.color;
						else
							glucoseValueDisplay.fontStyles.color = oldColor;
						
						//Marker Date Time
						timeAgoValue = TimeSpan.formatHoursMinutesFromSecondsChart(timestampDifferenceInSeconds, false, false);
						if (timeAgoValue != now)
							glucoseTimeAgoPill.setValue(timeAgoValue, ago, timestampDifference <= TimeSpan.TIME_6_MINUTES ? chartFontColor : oldColor);
						else
							glucoseTimeAgoPill.setValue("0 min", now, timestampDifference <= TimeSpan.TIME_6_MINUTES ? chartFontColor : oldColor);
						
						//Marker Slope
						glucoseSlopePill.setValue(latestMarker.slopeOutput, glucoseUnit, timestampDifference <= TimeSpan.TIME_6_MINUTES ? chartFontColor : oldColor);
					}
					else
					{
						//Glucose Value Display
						glucoseValueDisplay.text = "---";
						glucoseValueDisplay.fontStyles.color = oldColor;
						
						//Marker Date Time
						timeAgoValue = TimeSpan.formatHoursMinutesFromSecondsChart(timestampDifferenceInSeconds, false, false);
						if (timeAgoValue != now)
							glucoseTimeAgoPill.setValue(timeAgoValue, ago, oldColor);
						else
							glucoseTimeAgoPill.setValue("0 min", now, oldColor);
						
						//Marker Slope
						glucoseSlopePill.setValue("", "", oldColor)
					}
				}
			}
			
			currentNumberOfMakers == previousNumberOfMakers
		}
		
		private function createStatusTextDisplays(dontDisplayInfoPill:Boolean = false, dontDisplayPredictionsPill:Boolean = false):void
		{
			/* Calculate Font Sizes */
			deviceFontMultiplier = DeviceInfo.getFontMultipier();
			if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr) 
				glucoseDisplayFont = 54 * deviceFontMultiplier * userBGFontMultiplier;
			else
				glucoseDisplayFont = (!DeviceInfo.isTablet() ? 38 : 48) * deviceFontMultiplier * userBGFontMultiplier;
			
			timeDisplayFont = 15 * deviceFontMultiplier * userTimeAgoFontMultiplier;
			retroDisplayFont = 15 * deviceFontMultiplier * userTimeAgoFontMultiplier;
			if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr)
			{
				timeDisplayFont += 1;
				retroDisplayFont += 1;
			}
			
			/* Calculate Position */
			labelsYPos = 6 * DeviceInfo.getVerticalPaddingMultipier() * userBGFontMultiplier;
			
			//Glucose Value Display
			glucoseValueDisplay = GraphLayoutFactory.createChartStatusText("0", chartFontColor, glucoseDisplayFont, Align.RIGHT, true, 400);
			glucoseValueDisplay.addEventListener(TouchEvent.TOUCH, onMainGlucoseTouch);
			//glucoseValueDisplay.touchable = false;
			glucoseValueDisplay.x = _graphWidth - glucoseValueDisplay.width -glucoseStatusLabelsMargin;
			glucoseValueDisplay.validate();
			var glucoseValueDisplayHeight:Number = glucoseValueDisplay.height;
			glucoseValueDisplay.text = "";
			glucoseValueDisplay.validate();
			addChild(glucoseValueDisplay);
			
			//Glucose Retro Display
			glucoseTimeAgoPill = new ChartInfoPill(retroDisplayFont);
			
			if (!CGMBlueToothDevice.isMiaoMiao())
				glucoseTimeAgoPill.touchable = false;
			else
				glucoseTimeAgoPill.addEventListener(TouchEvent.TOUCH, onRequestMiaoMiaoReading)
			
			glucoseTimeAgoPill.setValue("0", "mg/dL", chartFontColor);
			glucoseTimeAgoPill.x = glucoseStatusLabelsMargin + 4;
			if (Constants.deviceModel == DeviceInfo.IPHONE_2G_3G_3GS_4_4S_ITOUCH_2_3_4)
				glucoseTimeAgoPill.y = labelsYPos;
			else if (Constants.deviceModel == DeviceInfo.IPHONE_5_5S_5C_SE_ITOUCH_5_6)
				glucoseTimeAgoPill.y = labelsYPos - 2;
			else if (Constants.deviceModel == DeviceInfo.IPHONE_6_6S_7_8)
				glucoseTimeAgoPill.y = labelsYPos;
			else if (Constants.deviceModel == DeviceInfo.IPHONE_6PLUS_6SPLUS_7PLUS_8PLUS)
				glucoseTimeAgoPill.y = labelsYPos - 4;
			else if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr)
				glucoseTimeAgoPill.y = labelsYPos - 8;
			else if (Constants.deviceModel == DeviceInfo.IPAD_PRO_129)
				glucoseTimeAgoPill.y = labelsYPos + 5;
			else
				glucoseTimeAgoPill.y = labelsYPos;
			addChild(glucoseTimeAgoPill);
			
			//Glucose Time Display
			glucoseSlopePill = new ChartInfoPill(timeDisplayFont);
			glucoseSlopePill.touchable = false;
			glucoseSlopePill.x = glucoseTimeAgoPill.x;
			glucoseSlopePill.y = glucoseTimeAgoPill.y + glucoseTimeAgoPill.height + 6;
			addChild(glucoseSlopePill);
			
			const pillPadding:int = DeviceInfo.isTablet() ? 16 : 6;
			
			//IOB
			if (treatmentsActive && displayTreatmentsOnChart)
			{
				if (displayIOBEnabled)
				{
					IOBPill = new ChartTreatmentPill(ChartTreatmentPill.TYPE_IOB);
					IOBPill.y = glucoseSlopePill.y + glucoseTimeAgoPill.height + pillPadding;
					IOBPill.x = _graphWidth - IOBPill.width -glucoseStatusLabelsMargin - 2;
					IOBPill.setValue("0.00U");
					
					if (mainChartGlucoseMarkersList == null || mainChartGlucoseMarkersList.length == 0 || dummyModeActive || !treatmentsActive || !displayTreatmentsOnChart || !displayIOBEnabled)
						IOBPill.visible = false;
					
					IOBPill.addEventListener(TouchEvent.TOUCH, onDisplayInsulinCurve);
					
					addChild(IOBPill);
				}
				
				if (displayCOBEnabled)
				{
					COBPill = new ChartTreatmentPill(ChartTreatmentPill.TYPE_COB);
					COBPill.y = glucoseSlopePill.y + glucoseTimeAgoPill.height + pillPadding;
					COBPill.setValue("0.0g");
					
					if (mainChartGlucoseMarkersList == null || mainChartGlucoseMarkersList.length == 0 || dummyModeActive || !treatmentsActive || !displayTreatmentsOnChart || !displayCOBEnabled)
						COBPill.visible = false;
					
					COBPill.addEventListener(TouchEvent.TOUCH, onDisplayCarbsCurve);
					
					addChild(COBPill);
				}
			}
			
			//Info pill
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_INFO_PILL_ON) == "true" && !dontDisplayInfoPill)
			{
				infoPill = new ChartTreatmentPill(" + ");
				infoPill.y = glucoseSlopePill.y + glucoseTimeAgoPill.height + pillPadding;
				infoPill.setValue(ModelLocator.resourceManagerInstance.getString('chartscreen','info_pill_title'));
				infoPill.visible = false;
				infoPill.addEventListener(TouchEvent.TOUCH, onDisplayMoreInfo);
				addChild(infoPill);
			}
			
			//Predictions pill
			if (!dontDisplayPredictionsPill)
			{
				predictionsPill = new ChartTreatmentPill(ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_small_abbreviation_chart_pill_title'), false);
				predictionsPill.y = glucoseSlopePill.y + glucoseTimeAgoPill.height + pillPadding;
				predictionsPill.setValue(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_GLUCOSE_PREDICTIONS_ENABLED) == "true" ? ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available') : ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_off_label'));
				predictionsPill.visible = false;
				predictionsPill.addEventListener(TouchEvent.TOUCH, onDisplayMorePredictions);
				addChild(predictionsPill);
			}
			
			glucoseTimeAgoPill.setValue("", "", chartFontColor);
		}
		
		private function onRequestMiaoMiaoReading(e:TouchEvent):void
		{
			var touch:Touch = e.getTouch(stage);
			if(touch != null && touch.phase == TouchPhase.BEGAN)
			{
				//Request MiaoMiao Reading On-Demand
				if (CGMBlueToothDevice.isMiaoMiao() && CGMBlueToothDevice.known() && InterfaceController.peripheralConnected)
				{
					SpikeANE.sendStartReadingCommmandToMiaoMia();
					SpikeANE.vibrate();
				}
			}
		}
		
		private function onMainGlucoseTouch(e:TouchEvent):void
		{
			var touch:Touch = e.getTouch(stage);
			if(touch != null && touch.phase == TouchPhase.BEGAN)
			{
				mainGlucoseTimer = getTimer();
				addEventListener(starling.events.Event.ENTER_FRAME, onMainGlucoseHold);
			}
			
			if(touch != null && touch.phase == TouchPhase.ENDED)
			{
				mainGlucoseTimer = Number.NaN;
				removeEventListener(starling.events.Event.ENTER_FRAME, onMainGlucoseHold);
			}
		}
		
		private function onMainGlucoseHold(e:starling.events.Event):void
		{
			if (isNaN(mainGlucoseTimer))
				return;
			
			if (getTimer() - mainGlucoseTimer > 1000)
			{
				mainGlucoseTimer = Number.NaN;
				removeEventListener(starling.events.Event.ENTER_FRAME, onMainGlucoseHold);
				
				//Push Chart Settings Screen
				AppInterface.instance.chartSettingsScreenItem.pushTransition = Cover.createCoverUpTransition(0.6, Transitions.EASE_IN_OUT);
				AppInterface.instance.chartSettingsScreenItem.popTransition = Reveal.createRevealDownTransition(0.6, Transitions.EASE_IN_OUT);
				AppInterface.instance.navigator.pushScreen( Screens.SETTINGS_CHART );
			}
		}
		
		/**
		 * Predictions
		 */
		private function fetchPredictions(forceNewIOBCOB:Boolean = false):Array
		{
			//Dispose previous header
			disposePredictionsHeader();
			
			function resetVariables():void
			{
				//Reset all prediction variables
				lastPredictionUpdate = Number.NaN;
				predictedEventualBG = Number.NaN;
				predictedBGImpact = Number.NaN;
				predictedDeviation = Number.NaN;
				predictedCarbImpact = Number.NaN;
				predictedMinimumBG = Number.NaN;
				predictedCOBBG = Number.NaN;
				predictedIOBBG = Number.NaN;
				predictedUAMBG = Number.NaN;
				predictionsIncompleteProfile = false;
				currentReadingValue = Number.NaN;
				
				//Update predictions pill
				if (predictionsPill != null)
				{
					predictionsPill.setValue(ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available'), TimeSpan.formatHoursMinutesFromMinutes(predictionsLengthInMinutes, false));
				}
			}
			
			try
			{
				//Poperties
				var maxNumberOfPredictions:Number = Math.floor(predictionsLengthInMinutes / 5);
				var lastAvailableBgReading:BgReading = _dataSource[_dataSource.length - 1];
				var nowTimestamp:Number = new Date().valueOf();
				var now:Number = lastAvailableBgReading != null ? lastAvailableBgReading.timestamp : nowTimestamp;
				var currentReadingValue:Number = Number.NaN;
				var readingTimestamp:Number = Number.NaN;
				var predicted_calculatedValue:Number = Number.NaN;
				var predictionsFound:Boolean = false;
				var cobPredictionsEnabled:Boolean = false;
				var iobPredictionsEnabled:Boolean = false;
				var uamPredictionsEnabled:Boolean = false;
				var ztPredictionsEnabled:Boolean = false;
				numDifferentPredictionsDisplayed = 0;
				
				var i:int;
				predictedTimeUntilHigh = Number.NaN;
				predictedTimeUntilLow = Number.NaN;
				
				//Colors
				var mainPredictionsColor:uint = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_GLUCOSE_PREDICTIONS_DEFAULT_COLOR));
				var cobPredictionsColor:uint = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_CARBS_MARKER_COLOR));
				var iobPredictionsColor:uint = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_INSULIN_MARKER_COLOR));
				var uamPredictionsColor:uint = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_GLUCOSE_PREDICTIONS_UAM_COLOR));
				var ztPredictionsColor:uint = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_GLUCOSE_PREDICTIONS_ZT_COLOR));
				
				//Prediction's lists
				var finalTotalPredictionsList:Array = [];
				var finalIOBPredictionsList:Array = [];
				var finalCOBPredictionsList:Array = [];
				var finalUAMPredictionsList:Array = [];
				var finalZTPredictionsList:Array = [];
				var unformattedIOBPredictionsList:Array = [];
				var unformattedCOBPredictionsList:Array = [];
				var unformattedUAMPredictionsList:Array = [];
				var unformattedZTPredictionsList:Array = [];
				preferredPrediction = "";
				
				//All Predictions
				var unformattedPredictions:Object = Forecast.predictBGs(predictionsLengthInMinutes, forceNewIOBCOB);
				if (unformattedPredictions == null)
				{
					resetVariables();
					
					//Return empty array
					return finalTotalPredictionsList;
				}
				//Update Useful Properties
				lastPredictionUpdate = unformattedPredictions.lastUpdate != null ? unformattedPredictions.lastUpdate : Number.NaN;
				predictedEventualBG = unformattedPredictions.eventualBG != null ? unformattedPredictions.eventualBG : Number.NaN;
				predictedBGImpact = unformattedPredictions.bgImpact != null ? unformattedPredictions.bgImpact : Number.NaN;
				predictedDeviation = unformattedPredictions.deviation != null ? unformattedPredictions.deviation : Number.NaN;
				predictedCarbImpact = unformattedPredictions.carbImpact != null ? unformattedPredictions.carbImpact : Number.NaN;
				predictedMinimumBG = unformattedPredictions.minPredBG != null ? unformattedPredictions.minPredBG : Number.NaN;
				predictedCOBBG = unformattedPredictions.COBpredBG != null ? unformattedPredictions.COBpredBG : Number.NaN;
				predictedIOBBG = unformattedPredictions.IOBpredBG != null ? unformattedPredictions.IOBpredBG : Number.NaN;
				predictedUAMBG = unformattedPredictions.UAMpredBG != null ? unformattedPredictions.UAMpredBG : Number.NaN;
				predictionsIncompleteProfile = unformattedPredictions.incompleteProfile != null ? unformattedPredictions.incompleteProfile : false;
				currentReadingValue = unformattedPredictions.bg != null ? unformattedPredictions.bg : Number.NaN;
				var currentIOB:Number = unformattedPredictions.IOBValue != null ? unformattedPredictions.IOBValue : Number.NaN;
				var currentCOB:Number = unformattedPredictions.COBValue != null ? unformattedPredictions.COBValue : Number.NaN;
				
				//UAM Predictions
				if (unformattedPredictions.UAM != null)
				{
					unformattedUAMPredictionsList = unformattedPredictions.UAM.concat();
					var excludedUAMPrediction:Number = unformattedUAMPredictionsList.shift(); //Remove first element
					if (isNaN(currentReadingValue)) currentReadingValue = excludedUAMPrediction;
					
					predictionsFound = true;
					uamPredictionsEnabled = true;
					numDifferentPredictionsDisplayed++;
				}
				
				//COB Predictions
				if (unformattedPredictions.COB != null)
				{
					unformattedCOBPredictionsList = unformattedPredictions.COB.concat();
					var excludedCOBPrediction:Number = unformattedCOBPredictionsList.shift(); //Remove first element
					if (isNaN(currentReadingValue)) currentReadingValue = excludedCOBPrediction;
					
					predictionsFound = true;
					cobPredictionsEnabled = true;
					numDifferentPredictionsDisplayed++;
				}
				
				//IOB Predictions
				if (unformattedPredictions.IOB != null)
				{
					unformattedIOBPredictionsList = unformattedPredictions.IOB.concat();
					var excludedIOBPrediction:Number = unformattedIOBPredictionsList.shift(); //Remove first element
					if (isNaN(currentReadingValue)) currentReadingValue = excludedIOBPrediction;
					
					predictionsFound = true;
					iobPredictionsEnabled = true;
					numDifferentPredictionsDisplayed++;
				}
				
				//ZT Predictions
				if (unformattedPredictions.ZT != null)
				{
					unformattedZTPredictionsList = unformattedPredictions.ZT.concat();
					var excludedZTPrediction :Number= unformattedZTPredictionsList.shift(); //Remove first element
					if (isNaN(currentReadingValue)) currentReadingValue = excludedZTPrediction;
					
					predictionsFound = true;
					ztPredictionsEnabled = true;
					numDifferentPredictionsDisplayed++;
				}
				
				preferredPrediction = Forecast.determineDefaultPredictionCurve(unformattedPredictions);
				
				//Validate
				if (!predictionsFound)
				{
					resetVariables();
					
					//If no predictions are available return an empty array
					return finalTotalPredictionsList;
				}
				
				//First glucose thresholds check
				if (currentReadingValue >= glucoseHigh)
				{
					predictedTimeUntilHigh = 0;
				}
				else if (currentReadingValue <= glucoseLow)
				{
					predictedTimeUntilLow = 0;
				}
				
				//Loop through COB predictions (priority #1)
				var startWithCOBColor:Boolean = true;
				var cobPredictionsLength:uint =  unformattedCOBPredictionsList.length;
				for (i = 0; i < cobPredictionsLength; i++) 
				{
					readingTimestamp = now + ((i + 1) * TimeSpan.TIME_5_MINUTES);
					predicted_calculatedValue = unformattedCOBPredictionsList[i];
					
					var cobPredColor:uint;
					if (preferredPrediction == "COB")
					{
						cobPredColor = mainPredictionsColor;
					}
					else
					{
						if (currentIOB > 0 || currentTotalIOB > 0)
						{
							if (startWithCOBColor)
							{
								cobPredColor = cobPredictionsColor;
							}
							else
							{
								cobPredColor = iobPredictionsColor;
							}
							
							startWithCOBColor = !startWithCOBColor;
						}
						else
						{
							cobPredColor = cobPredictionsColor;
						}
					}
					
					var cobPredictionReading:BgReading = new BgReading
						(
							readingTimestamp, //timestamp
							null, //sensor
							null, //calibration
							cobPredColor, //raw data
							Number.NaN, //filtered data
							Number.NaN, //adge adjusted raw data
							false, //calibration flag
							predicted_calculatedValue, //calculated value
							Number.NaN, //filtered calculated value
							Number.NaN, //calculated value slope
							Number.NaN, //a
							Number.NaN, //b
							Number.NaN, //c
							Number.NaN, //ra
							Number.NaN, //rb
							Number.NaN, //rc
							Number.NaN, //raw calculated
							false, //hide slope
							"", //noise
							readingTimestamp, //last modified timestamp
							"COB" //unique id
						);
					
					//Check if high or low thresholds will be reached
					if (predicted_calculatedValue >= glucoseHigh && isNaN(predictedTimeUntilHigh))
					{
						predictedTimeUntilHigh = readingTimestamp - now;
					}
					
					if (predicted_calculatedValue <= glucoseLow && isNaN(predictedTimeUntilLow))
					{
						predictedTimeUntilLow = readingTimestamp - now;
					}
					
					//Add to prediction's list
					finalCOBPredictionsList.push(cobPredictionReading);
				}
				
				//Loop through UAM predictions (priority #2)
				var uamPredictionsLength:uint =  unformattedUAMPredictionsList.length;
				for (i = 0; i < uamPredictionsLength; i++) 
				{
					readingTimestamp = now + ((i + 1) * TimeSpan.TIME_5_MINUTES);
					predicted_calculatedValue = unformattedUAMPredictionsList[i];
					var uamPredictionReading:BgReading = new BgReading
						(
							readingTimestamp, //timestamp
							null, //sensor
							null, //calibration
							preferredPrediction == "UAM" ? mainPredictionsColor : uamPredictionsColor, //raw data
							Number.NaN, //filtered data
							Number.NaN, //adge adjusted raw data
							false, //calibration flag
							predicted_calculatedValue, //calculated value
							Number.NaN, //filtered calculated value
							Number.NaN, //calculated value slope
							Number.NaN, //a
							Number.NaN, //b
							Number.NaN, //c
							Number.NaN, //ra
							Number.NaN, //rb
							Number.NaN, //rc
							Number.NaN, //raw calculated
							false, //hide slope
							"", //noise
							readingTimestamp, //last modified timestamp
							"UAM" //unique id
						);
					
					//Check if high or low thresholds will be reached	
					if (finalCOBPredictionsList.length == 0)
					{
						if (predicted_calculatedValue >= glucoseHigh && isNaN(predictedTimeUntilHigh))
						{
							predictedTimeUntilHigh = readingTimestamp - now;
						}
						
						if (predicted_calculatedValue <= glucoseLow && isNaN(predictedTimeUntilLow))
						{
							predictedTimeUntilLow = readingTimestamp - now;
						}
					}
					
					//Add to prediction's list
					finalUAMPredictionsList.push(uamPredictionReading);
				}
				
				//Loop through IOB predictions (priority #3)
				var iobPredictionsLength:uint =  unformattedIOBPredictionsList.length;
				for (i = 0; i < iobPredictionsLength; i++) 
				{
					readingTimestamp = now + ((i + 1) * TimeSpan.TIME_5_MINUTES);
					predicted_calculatedValue = unformattedIOBPredictionsList[i];
					var iobPredictionReading:BgReading = new BgReading
						(
							readingTimestamp, //timestamp
							null, //sensor
							null, //calibration
							preferredPrediction == "IOB" ? mainPredictionsColor : iobPredictionsColor, //raw data
							Number.NaN, //filtered data
							Number.NaN, //adge adjusted raw data
							false, //calibration flag
							predicted_calculatedValue, //calculated value
							Number.NaN, //filtered calculated value
							Number.NaN, //calculated value slope
							Number.NaN, //a
							Number.NaN, //b
							Number.NaN, //c
							Number.NaN, //ra
							Number.NaN, //rb
							Number.NaN, //rc
							Number.NaN, //raw calculated
							false, //hide slope
							"", //noise
							readingTimestamp, //last modified timestamp
							"IOB" //unique id
						)
					
					//Check if high or low thresholds will be reached
					if (finalCOBPredictionsList.length == 0 && finalUAMPredictionsList.length == 0)
					{
						if (predicted_calculatedValue >= glucoseHigh && isNaN(predictedTimeUntilHigh))
						{
							predictedTimeUntilHigh = readingTimestamp - now;
						}
						
						if (predicted_calculatedValue <= glucoseLow && isNaN(predictedTimeUntilLow))
						{
							predictedTimeUntilLow = readingTimestamp - now;
						}
					}
					
					//Add to prediction's list
					finalIOBPredictionsList.push(iobPredictionReading);
				}
				
				//Loop through ZT predictions (priority #4)
				var ztPredictionsLength:uint =  unformattedZTPredictionsList.length;
				for (i = 0; i < ztPredictionsLength; i++) 
				{
					readingTimestamp = now + ((i + 1) * TimeSpan.TIME_5_MINUTES);
					predicted_calculatedValue = unformattedZTPredictionsList[i];
					var ztPredictionReading:BgReading = new BgReading
						(
							readingTimestamp, //timestamp
							null, //sensor
							null, //calibration
							preferredPrediction == "ZTM" ? mainPredictionsColor : ztPredictionsColor, //raw data
							Number.NaN, //filtered data
							Number.NaN, //adge adjusted raw data
							false, //calibration flag
							predicted_calculatedValue, //calculated value
							Number.NaN, //filtered calculated value
							Number.NaN, //calculated value slope
							Number.NaN, //a
							Number.NaN, //b
							Number.NaN, //c
							Number.NaN, //ra
							Number.NaN, //rb
							Number.NaN, //rc
							Number.NaN, //raw calculated
							false, //hide slope
							"", //noise
							readingTimestamp, //last modified timestamp
							"ZTM" //unique id
						);
					
					//Check if high or low thresholds will be reached
					if (finalIOBPredictionsList.length == 0 && finalCOBPredictionsList.length == 0 && finalUAMPredictionsList.length == 0)
					{
						if (predicted_calculatedValue >= glucoseHigh && isNaN(predictedTimeUntilHigh))
						{
							predictedTimeUntilHigh = readingTimestamp - now;
						}
						
						if (predicted_calculatedValue <= glucoseLow && isNaN(predictedTimeUntilLow))
						{
							predictedTimeUntilLow = readingTimestamp - now;
						}
					}
					
					//Add to prediction's list
					finalZTPredictionsList.push(ztPredictionReading);
				}
				
				//Truncate predictions if needed
				if (finalCOBPredictionsList.length > maxNumberOfPredictions)
				{
					finalCOBPredictionsList = finalCOBPredictionsList.slice(0, maxNumberOfPredictions);
				}
				
				if (finalIOBPredictionsList.length > maxNumberOfPredictions)
				{
					finalIOBPredictionsList = finalIOBPredictionsList.slice(0, maxNumberOfPredictions);
				}
				
				if (finalUAMPredictionsList.length > maxNumberOfPredictions)
				{
					finalUAMPredictionsList = finalUAMPredictionsList.slice(0, maxNumberOfPredictions);
				}
				
				if (finalZTPredictionsList.length > maxNumberOfPredictions)
				{
					finalZTPredictionsList = finalZTPredictionsList.slice(0, maxNumberOfPredictions);
				}
				
				//Update predictions pill
				predictionsPill.isPredictive = true;
				finalPredictedValue = Number.NaN;
				finalPredictedDuration = Number.NaN;
				
				var predictionAvailableDuration:Number = Math.max(finalCOBPredictionsList.length, finalUAMPredictionsList.length, finalZTPredictionsList.length, finalIOBPredictionsList.length) * 5;
				if (isNaN(predictionAvailableDuration))
				{
					predictionAvailableDuration = predictionsLengthInMinutes;
				}
				finalPredictedDuration = predictionAvailableDuration;
				
				if (preferredPrediction == "COB")
				{
					var numCOBPredictions:uint = finalCOBPredictionsList.length;
					var cobPredReading:BgReading = finalCOBPredictionsList[numCOBPredictions - 1];
					
					if (cobPredReading != null && predictionsPill != null)
					{
						finalPredictedValue = cobPredReading._calculatedValue;
						predictionsPill.setValue(glucoseUnit == "mg/dL" ? String(Math.round(finalPredictedValue)) : String(Math.round(BgReading.mgdlToMmol(finalCOBPredictionsList[numCOBPredictions - 1]._calculatedValue * 10)) / 10), TimeSpan.formatHoursMinutesFromMinutes(predictionAvailableDuration, false));
					}
				}
				else if (preferredPrediction == "UAM")
				{
					var numUAMPredictions:uint = finalUAMPredictionsList.length;
					var uamPredReading:BgReading = finalUAMPredictionsList[numUAMPredictions - 1];
					
					if (uamPredReading != null && predictionsPill != null)
					{
						finalPredictedValue = uamPredReading._calculatedValue;
						predictionsPill.setValue(glucoseUnit == "mg/dL" ? String(Math.round(finalPredictedValue)) : String(Math.round(BgReading.mgdlToMmol(finalPredictedValue * 10)) / 10), TimeSpan.formatHoursMinutesFromMinutes(predictionAvailableDuration, false));
					}
				}
				else if (preferredPrediction == "ZTM")
				{
					var numZTPredictions:uint = finalZTPredictionsList.length;
					var ztPredReading:BgReading = finalZTPredictionsList[numZTPredictions - 1];
					
					if (ztPredReading != null && predictionsPill != null)
					{
						finalPredictedValue = ztPredReading._calculatedValue;
						predictionsPill.setValue(glucoseUnit == "mg/dL" ? String(Math.round(finalPredictedValue)) : String(Math.round(BgReading.mgdlToMmol(finalPredictedValue * 10)) / 10), TimeSpan.formatHoursMinutesFromMinutes(predictionAvailableDuration, false));
					}
				}
				else 
				{
					var numIOBPredictions:uint = finalIOBPredictionsList.length;
					var iobPredReading:BgReading = finalIOBPredictionsList[numIOBPredictions - 1];
					
					if (iobPredReading != null && predictionsPill != null)
					{
						finalPredictedValue = iobPredReading._calculatedValue;
						predictionsPill.setValue(glucoseUnit == "mg/dL" ? String(Math.round(finalPredictedValue)) : String(Math.round(BgReading.mgdlToMmol(finalPredictedValue * 10)) / 10), TimeSpan.formatHoursMinutesFromMinutes(predictionAvailableDuration, false));
					}
				}
				
				repositionTreatmentPills();
				
				//Update header
				if (!Forecast.externalLoopAPS)
				{
					if (headerProperties != null && !singlePredictionCurve)
					{
						predictionsLegendsContainer = LayoutFactory.createLayoutGroup("vertical", HorizontalAlign.LEFT, VerticalAlign.TOP, 0);
						(predictionsLegendsContainer.layout as VerticalLayout).paddingLeft = 40;
						
						if (cobPredictionsEnabled)
						{
							//Color
							var cobColor:uint = preferredPrediction == "COB" ? mainPredictionsColor : cobPredictionsColor;
							//Legend Container
							cobPredictLegendContainer = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.LEFT, VerticalAlign.MIDDLE, 5);
							//Label
							cobPredictLegendLabel = LayoutFactory.createLabel(currentIOB > 0 && currentTotalIOB > 0 ? ModelLocator.resourceManagerInstance.getString('treatments','cob_label') + " & " + ModelLocator.resourceManagerInstance.getString('treatments','iob_label') : ModelLocator.resourceManagerInstance.getString('treatments','cob_label'), HorizontalAlign.LEFT, VerticalAlign.TOP, 10 * userAxisFontMultiplier, true);
							cobPredictLegendLabel.touchable = false;
							cobPredictLegendLabel.validate();
							//Color Marker
							cobPredictLegendColorQuad = new Quad(cobPredictLegendLabel.height * 0.6, cobPredictLegendLabel.height * 0.6, cobColor);
							cobPredictLegendColorQuad.touchable = false;
							if ((currentIOB > 0 && currentTotalIOB > 0) && preferredPrediction != "COB")
							{
								cobPredictLegendColorQuad.setVertexColor(0, cobColor);
								cobPredictLegendColorQuad.setVertexColor(1, iobPredictionsColor);
								cobPredictLegendColorQuad.setVertexColor(2, cobColor);
								cobPredictLegendColorQuad.setVertexColor(3, iobPredictionsColor);
							}
							//Add label anc color marker to the container
							cobPredictLegendContainer.addChild(cobPredictLegendColorQuad);
							cobPredictLegendContainer.addChild(cobPredictLegendLabel);
							cobPredictLegendContainer.validate();
							//Hit Area
							cobPredictLegendHitArea = new Quad(cobPredictLegendContainer.width, cobPredictLegendContainer.height, 0xFF0000);
							cobPredictLegendHitArea.alpha = 0;
							cobPredictLegendContainer.addChild(cobPredictLegendHitArea);
							cobPredictLegendContainer.validate();
							cobPredictLegendHitArea.x = cobPredictLegendHitArea.y = 0;
							
							cobPredictLegendContainer.addEventListener(TouchEvent.TOUCH, onCOBPredictionExplanation);
							
							if (preferredPrediction == "COB")
								predictionsLegendsContainer.addChildAt(cobPredictLegendContainer, 0);
							else
								predictionsLegendsContainer.addChild(cobPredictLegendContainer);
							
							if (currentIOB > 0 && currentTotalIOB > 0)
							{
								(predictionsLegendsContainer.layout as VerticalLayout).paddingLeft += 30;
							}
						}
						
						if (uamPredictionsEnabled)
						{
							//Color
							var uamColor:uint = preferredPrediction == "UAM" ? mainPredictionsColor : uamPredictionsColor;
							//Legend Container
							uamPredictLegendContainer = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.LEFT, VerticalAlign.MIDDLE, 5);
							//Label
							uamPredictLegendLabel = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('chartscreen','unannounced_glucose_label'), HorizontalAlign.LEFT, VerticalAlign.TOP, 10 * userAxisFontMultiplier, true);
							uamPredictLegendLabel.touchable = false;
							uamPredictLegendLabel.validate();
							//Color Marker
							uamPredictLegendColorQuad = new Quad(uamPredictLegendLabel.height * 0.6, uamPredictLegendLabel.height * 0.6, uamColor);
							uamPredictLegendColorQuad.touchable = false;
							//Add label anc color marker to the container
							uamPredictLegendContainer.addChild(uamPredictLegendColorQuad);
							uamPredictLegendContainer.addChild(uamPredictLegendLabel);
							uamPredictLegendContainer.validate();
							//Hit Area
							uamPredictLegendHitArea = new Quad(uamPredictLegendContainer.width, uamPredictLegendContainer.height, 0xFF0000);
							uamPredictLegendHitArea.alpha = 0;
							uamPredictLegendContainer.addChild(uamPredictLegendHitArea);
							uamPredictLegendContainer.validate();
							uamPredictLegendHitArea.x = uamPredictLegendHitArea.y = 0;
							
							uamPredictLegendContainer.addEventListener(TouchEvent.TOUCH, onUAMPredictionExplanation);
							
							if (preferredPrediction == "UAM")
								predictionsLegendsContainer.addChildAt(uamPredictLegendContainer, 0);
							else
								predictionsLegendsContainer.addChild(uamPredictLegendContainer);
						}
						
						if (iobPredictionsEnabled)
						{
							//Color
							var iobColor:uint = preferredPrediction == "IOB" ? mainPredictionsColor : iobPredictionsColor;
							//Legend Container
							iobPredictLegendContainer = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.LEFT, VerticalAlign.MIDDLE, 5);
							//Label
							iobPredictLegendLabel = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('treatments','iob_label'), HorizontalAlign.LEFT, VerticalAlign.TOP, 10 * userAxisFontMultiplier, true);
							iobPredictLegendLabel.touchable = false;
							iobPredictLegendLabel.validate();
							//Color Marker
							iobPredictLegendColorQuad = new Quad(iobPredictLegendLabel.height * 0.6, iobPredictLegendLabel.height * 0.6, iobColor);
							iobPredictLegendColorQuad.touchable = false;
							//Add label anc color marker to the container
							iobPredictLegendContainer.addChild(iobPredictLegendColorQuad);
							iobPredictLegendContainer.addChild(iobPredictLegendLabel);
							iobPredictLegendContainer.validate();
							//Hit Area
							iobPredictLegendHitArea = new Quad(iobPredictLegendContainer.width, iobPredictLegendContainer.height, 0xFF0000);
							iobPredictLegendHitArea.alpha = 0;
							iobPredictLegendContainer.addChild(iobPredictLegendHitArea);
							iobPredictLegendContainer.validate();
							iobPredictLegendHitArea.x = iobPredictLegendHitArea.y = 0;
							
							iobPredictLegendContainer.addEventListener(TouchEvent.TOUCH, onIOBPredictionExplanation);
							
							if (preferredPrediction == "IOB")
								predictionsLegendsContainer.addChildAt(iobPredictLegendContainer, 0);
							else
								predictionsLegendsContainer.addChild(iobPredictLegendContainer);
						}
						
						if (ztPredictionsEnabled)
						{
							//Color
							var ztColor:uint = preferredPrediction == "ZTM" ? mainPredictionsColor : ztPredictionsColor;
							//Legend Container
							ztPredictLegendContainer = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.LEFT, VerticalAlign.MIDDLE, 5);
							//Label
							ztPredictLegendLabel = LayoutFactory.createLabel("ZT", HorizontalAlign.LEFT, VerticalAlign.TOP, 10 * userAxisFontMultiplier, true);
							ztPredictLegendLabel.touchable = false;
							ztPredictLegendLabel.validate();
							//Color Marker
							ztPredictLegendColorQuad = new Quad(ztPredictLegendLabel.height * 0.6, ztPredictLegendLabel.height * 0.6, ztColor);
							ztPredictLegendColorQuad.touchable = false;
							//Add label anc color marker to the container
							ztPredictLegendContainer.addChild(ztPredictLegendColorQuad);
							ztPredictLegendContainer.addChild(ztPredictLegendLabel);
							ztPredictLegendContainer.validate();
							//Hit Area
							ztPredictLegendHitArea = new Quad(ztPredictLegendContainer.width, ztPredictLegendContainer.height, 0xFF0000);
							ztPredictLegendHitArea.alpha = 0;
							ztPredictLegendContainer.addChild(ztPredictLegendHitArea);
							ztPredictLegendContainer.validate();
							ztPredictLegendHitArea.x = ztPredictLegendHitArea.y = 0;
							
							ztPredictLegendContainer.addEventListener(TouchEvent.TOUCH, onZTPredictionExplanation);
							
							if (preferredPrediction == "ZTM")
								predictionsLegendsContainer.addChildAt(ztPredictLegendContainer, 0);
							else
								predictionsLegendsContainer.addChild(ztPredictLegendContainer);
						}
						
						//iPhone XR Header Fix
						if (Capabilities.os.indexOf("iPhone11,8") != -1 && predictionsLegendsContainer != null && predictionsLegendsContainer.layout != null) 
						{
							(predictionsLegendsContainer.layout as VerticalLayout).paddingTop += 17;
						}
						
						headerProperties.centerItems = new <DisplayObject>[
							predictionsLegendsContainer
						];
					}
				}
				
				//Join all predictions
				if (!singlePredictionCurve)
				{
					if (preferredPrediction == "COB")
					{
						finalTotalPredictionsList = finalTotalPredictionsList.concat(finalZTPredictionsList);
						finalTotalPredictionsList = finalTotalPredictionsList.concat(finalIOBPredictionsList);
						finalTotalPredictionsList = finalTotalPredictionsList.concat(finalUAMPredictionsList);
						finalTotalPredictionsList = finalTotalPredictionsList.concat(finalCOBPredictionsList);
					}
					else if (preferredPrediction == "UAM")
					{
						finalTotalPredictionsList = finalTotalPredictionsList.concat(finalZTPredictionsList);
						finalTotalPredictionsList = finalTotalPredictionsList.concat(finalIOBPredictionsList);
						finalTotalPredictionsList = finalTotalPredictionsList.concat(finalCOBPredictionsList);
						finalTotalPredictionsList = finalTotalPredictionsList.concat(finalUAMPredictionsList);
					}
					else if (preferredPrediction == "IOB")
					{
						finalTotalPredictionsList = finalTotalPredictionsList.concat(finalZTPredictionsList);
						finalTotalPredictionsList = finalTotalPredictionsList.concat(finalUAMPredictionsList);
						finalTotalPredictionsList = finalTotalPredictionsList.concat(finalCOBPredictionsList);
						finalTotalPredictionsList = finalTotalPredictionsList.concat(finalIOBPredictionsList);
					}
					else if (preferredPrediction == "ZTM")
					{
						finalTotalPredictionsList = finalTotalPredictionsList.concat(finalUAMPredictionsList);
						finalTotalPredictionsList = finalTotalPredictionsList.concat(finalCOBPredictionsList);
						finalTotalPredictionsList = finalTotalPredictionsList.concat(finalIOBPredictionsList);
						finalTotalPredictionsList = finalTotalPredictionsList.concat(finalZTPredictionsList);
					}
				}
				else
				{
					if (preferredPrediction == "COB")
					{
						finalTotalPredictionsList = finalTotalPredictionsList.concat(finalCOBPredictionsList);
					}
					else if (preferredPrediction == "UAM")
					{
						finalTotalPredictionsList = finalTotalPredictionsList.concat(finalUAMPredictionsList);
					}
					else if (preferredPrediction == "IOB")
					{
						finalTotalPredictionsList = finalTotalPredictionsList.concat(finalIOBPredictionsList);
					}
					else if (preferredPrediction == "ZTM")
					{
						finalTotalPredictionsList = finalTotalPredictionsList.concat(finalZTPredictionsList);
					}
				}
				
				return finalTotalPredictionsList;
			} 
			catch(error:Error) 
			{
				resetVariables();
				
				return [];
			}
			
			return [];
		}
		
		private function disposePredictionsExplanations(e:starling.events.Event = null):void
		{
			if (predictionTitleLabel != null)
			{
				predictionTitleLabel.removeFromParent();
				predictionTitleLabel.dispose();
				predictionTitleLabel = null;
			}
			
			if (predictionExplanationLabel != null)
			{
				predictionExplanationLabel.removeFromParent();
				predictionExplanationLabel.dispose();
				predictionExplanationLabel = null;
			}
			
			if (predictionExplanationMainContainer != null)
			{
				predictionExplanationMainContainer.removeFromParent();
				predictionExplanationMainContainer.dispose();
				predictionExplanationMainContainer = null;
			}
			
			if (predictionExplanationCallout != null)
			{
				predictionExplanationCallout.removeEventListener(starling.events.Event.OPEN, onPredictionPillExplanationOpened);
				predictionExplanationCallout.removeEventListener(starling.events.Event.CLOSE, disposePredictionsExplanations);
				predictionExplanationCallout.removeEventListener(TouchEvent.TOUCH, onClosePredictionsExplanation);
				predictionExplanationCallout.removeFromParent();
				predictionExplanationCallout.dispose();
				predictionExplanationCallout = null;
				
				if (predictionsCallout != null)
				{
					predictionsCallout.closeOnTouchBeganOutside = true;
					predictionsCallout.closeOnTouchEndedOutside = true;
				}
			}
			
			if (predictionsCallout != null)
			{
				predictionsCallout.closeOnTouchBeganOutside = true;
				predictionsCallout.closeOnTouchEndedOutside = true;
			}
			
			predictionPillExplanationEnabled = false;
		}
		
		private function onPredictionPillExplanationOpened(e:starling.events.Event = null):void
		{
			if (predictionsCallout != null)
			{
				predictionsCallout.closeOnTouchBeganOutside = false;
				predictionsCallout.closeOnTouchEndedOutside = false;
			}
			
			predictionPillExplanationEnabled = true;
		}
		
		private function displayPredictionPillExplanationCallout(pointOfOrigin:DisplayObject, title:String, body:String):void
		{
			if (pointOfOrigin == null || title == null || body == null)
				return;
				
			//Dimensions #1
			var pointOfOriginGlobalX:Number = pointOfOrigin.localToGlobal(new Point(0, 0)).x;
			var maxWidth:Number = Constants.stageWidth - pointOfOriginGlobalX + pointOfOrigin.width - 10 - 60;
			
			//Main Container
			var predictionExplanationMainLayout:VerticalLayout = new VerticalLayout();
			predictionExplanationMainLayout.gap = 15;
			if (predictionExplanationMainContainer != null) predictionExplanationMainContainer.removeFromParent(true);
			predictionExplanationMainContainer = new ScrollContainer();
			predictionExplanationMainContainer.layout = predictionExplanationMainLayout;
			predictionExplanationMainContainer.horizontalScrollPolicy = ScrollPolicy.OFF;
			
			//Title
			if (predictionTitleLabel != null) predictionTitleLabel.removeFromParent(true);
			predictionTitleLabel = LayoutFactory.createLabel(title, HorizontalAlign.CENTER, VerticalAlign.TOP, 16, true);
			predictionExplanationMainContainer.addChild(predictionTitleLabel);
			
			//Body
			if (predictionExplanationLabel != null) predictionExplanationLabel.removeFromParent(true);
			predictionExplanationLabel = LayoutFactory.createLabel(body, HorizontalAlign.JUSTIFY, VerticalAlign.TOP);
			predictionExplanationLabel.wordWrap = true;
			predictionExplanationLabel.paddingBottom = 10;
			predictionExplanationMainContainer.addChild(predictionExplanationLabel);
			
			//Callout
			if (predictionExplanationCallout != null) 
			{
				predictionExplanationCallout.removeFromParent(true);
				if (predictionsCallout != null)
				{
					predictionsCallout.closeOnTouchBeganOutside = true;
					predictionsCallout.closeOnTouchEndedOutside = true;
				}
			}
			predictionExplanationCallout = Callout.show(predictionExplanationMainContainer, pointOfOrigin, new <String>[RelativePosition.LEFT], false);
			predictionExplanationCallout.closeOnTouchBeganOutside = true;
			predictionExplanationCallout.closeOnTouchEndedOutside = true;
			predictionExplanationCallout.disposeOnSelfClose = true;
			predictionExplanationCallout.validate();
			predictionExplanationCallout.x += pointOfOrigin.width - 10;
			
			var translatedGlobalX:Number = predictionExplanationCallout.x + predictionExplanationCallout.width;
			var maxGlobalWidth:Number = translatedGlobalX - 60;
			
			//Dimensions #2
			predictionExplanationMainContainer.validate();
			
			predictionExplanationMainContainer.maxWidth = maxGlobalWidth;
			predictionExplanationMainContainer.width = maxGlobalWidth;
			
			predictionTitleLabel.maxWidth = maxGlobalWidth;
			predictionTitleLabel.width = maxGlobalWidth;
			
			predictionExplanationLabel.width = maxGlobalWidth;
			predictionExplanationLabel.maxWidth = maxGlobalWidth;
			
			predictionExplanationCallout.validate();
			predictionExplanationCallout.x += pointOfOrigin.width - 10;
			predictionExplanationCallout.addEventListener(starling.events.Event.CLOSE, disposePredictionsExplanations);
			predictionExplanationCallout.addEventListener(starling.events.Event.ADDED, onPredictionPillExplanationOpened);
			
			if (predictionExplanationMainContainer.maxVerticalScrollPosition > 0)
			{
				//Callout is scrollable
				predictionExplanationMainContainer.scrollBarDisplayMode = ScrollBarDisplayMode.FIXED_FLOAT;
				
				predictionExplanationMainLayout.paddingRight = 10;
				predictionExplanationCallout.paddingRight = 10;
				predictionTitleLabel.width -= 10;
				predictionExplanationLabel.width -= 10;
			}
			else
			{
				predictionExplanationCallout.addEventListener(TouchEvent.TOUCH, onClosePredictionsExplanation);
			}
		}
		
		private function onClosePredictionsExplanation(e:TouchEvent):void
		{	
			if (!SystemUtil.isApplicationActive || dummyModeActive)
				return;
			
			var touch:Touch = e.getTouch(stage);
			
			if(touch != null && touch.phase == TouchPhase.ENDED && predictionExplanationCallout != null) 
			{
				predictionExplanationCallout.removeFromParent(true);
				
				predictionsCalloutTimeout = setTimeout( function():void 
				{
					if (predictionExplanationCallout != null)
					{
						predictionsCallout.closeOnTouchBeganOutside = true;
						predictionsCallout.closeOnTouchEndedOutside = true;
					}
				}, 250 );
			}
			
		}
	
		private function displayPredictionLegendExplanationCallout(pointOfOrigin:DisplayObject, title:String, body:String):void
		{
			//Dimensions #1
			var calloutWidth:Number = Constants.stageWidth * 0.8;
			
			//Main Container
			var predictionExplanationMainLayout:VerticalLayout = new VerticalLayout();
			predictionExplanationMainLayout.gap = 15;
			if (predictionExplanationMainContainer != null) predictionExplanationMainContainer.removeFromParent(true);
			predictionExplanationMainContainer = new ScrollContainer();
			predictionExplanationMainContainer.layout = predictionExplanationMainLayout;
			predictionExplanationMainContainer.width = calloutWidth;
			predictionExplanationMainContainer.horizontalScrollPolicy = ScrollPolicy.OFF;
			predictionExplanationMainContainer.scrollBarDisplayMode = ScrollBarDisplayMode.FIXED_FLOAT;
			
			//Title
			if (predictionTitleLabel != null) predictionTitleLabel.removeFromParent(true);
			predictionTitleLabel = LayoutFactory.createLabel(title, HorizontalAlign.CENTER, VerticalAlign.TOP, 16, true);
			predictionTitleLabel.width = calloutWidth;
			predictionExplanationMainContainer.addChild(predictionTitleLabel);
			
			//Body
			if (predictionExplanationLabel != null) predictionExplanationLabel.removeFromParent(true);
			predictionExplanationLabel = LayoutFactory.createLabel(body, HorizontalAlign.JUSTIFY, VerticalAlign.TOP);
			predictionExplanationLabel.wordWrap = true;
			predictionExplanationLabel.width = calloutWidth;
			predictionExplanationMainContainer.addChild(predictionExplanationLabel);
			
			//Dimensions #2
			predictionExplanationMainContainer.validate();
			var predictionsCalloutPointOfOrigin:Number = pointOfOrigin.localToGlobal(new Point(0, 0)).y + pointOfOrigin.height;
			var predictionsContentOriginalHeight:Number = predictionExplanationMainContainer.height + 60;
			var suggestedPredictionsCalloutHeight:Number = Constants.stageHeight - predictionsCalloutPointOfOrigin - 5;
			var finalCalloutHeight:Number = predictionsContentOriginalHeight > suggestedPredictionsCalloutHeight ?  suggestedPredictionsCalloutHeight : predictionsContentOriginalHeight;
			
			//Callout
			if (predictionExplanationCallout != null) 
			{
				predictionExplanationCallout.removeFromParent(true);
				
				if (predictionsCallout != null)
				{
					predictionsCallout.closeOnTouchBeganOutside = true;
					predictionsCallout.closeOnTouchEndedOutside = true;
				}
			}
			predictionExplanationCallout = Callout.show(predictionExplanationMainContainer, pointOfOrigin, new <String>[RelativePosition.BOTTOM], false);
			predictionExplanationCallout.height = finalCalloutHeight;
			predictionExplanationMainContainer.height = finalCalloutHeight - 50;
			predictionExplanationMainContainer.maxHeight = finalCalloutHeight - 50;
			predictionExplanationCallout.closeOnTouchBeganOutside = true;
			predictionExplanationCallout.closeOnTouchEndedOutside = true;
			predictionExplanationCallout.disposeOnSelfClose = true;
			predictionExplanationCallout.validate();
			predictionExplanationCallout.x = (Constants.stageWidth - predictionExplanationCallout.width) / 2;
			predictionExplanationCallout.addEventListener(starling.events.Event.CLOSE, disposePredictionsExplanations);
			
			if (finalCalloutHeight != predictionsContentOriginalHeight)
			{
				predictionExplanationMainLayout.paddingRight = 10;
				predictionExplanationCallout.paddingRight = 10;
				predictionTitleLabel.width -= 10;
				predictionExplanationLabel.width -= 10;
			}
		}
		
		private function onPredictionPillExplanation(e:TouchEvent):void
		{	
			if (!SystemUtil.isApplicationActive || dummyModeActive)
				return;
			
			var touch:Touch = e.getTouch(stage);
			
			if(touch != null && touch.phase == TouchPhase.BEGAN && e.currentTarget != null) 
			{
				if (predictionsEnablerPill != null && (e.currentTarget === predictionsEnablerPill.pillBackground || e.currentTarget === predictionsEnablerPill.titleLabel))
				{
					displayPredictionPillExplanationCallout
					(
						predictionsEnablerPill, 
						ModelLocator.resourceManagerInstance.getString('chartscreen','enable_disable_predictions_pill_explanation_title'),
						ModelLocator.resourceManagerInstance.getString('chartscreen','enable_disable_predictions_pill_explanation_body')
					);
				}
				else if (wikiPredictionsPill != null && (e.currentTarget === wikiPredictionsPill.pillBackground || e.currentTarget === wikiPredictionsPill.titleLabel))
				{
					displayPredictionPillExplanationCallout
					(
						wikiPredictionsPill, 
						ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_wiki_label'),
						ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_wiki_explanation_content')
					);
				}
				else if (predictionsTimeFramePill != null && (e.currentTarget === predictionsTimeFramePill.pillBackground || e.currentTarget === predictionsTimeFramePill.titleLabel))
				{
					displayPredictionPillExplanationCallout
					(
						predictionsTimeFramePill, 
						ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_duration_label'),
						ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_duration_pill_explanation_body')
					);
				}
				else if (predictionsIOBCOBPill != null && (e.currentTarget === predictionsIOBCOBPill.pillBackground || e.currentTarget === predictionsIOBCOBPill.titleLabel))
				{
					displayPredictionPillExplanationCallout
					(
						predictionsIOBCOBPill, 
						ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_include_iob_cob_label'),
						ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_iob_cob_pill_explanation_body')
					
					);
				}
				else if (predictionsSingleCurvePill != null && (e.currentTarget === predictionsSingleCurvePill.pillBackground || e.currentTarget === predictionsSingleCurvePill.titleLabel))
				{
					displayPredictionPillExplanationCallout
					(
						predictionsSingleCurvePill, 
						ModelLocator.resourceManagerInstance.getString('chartscreen','single_prediction_curve_label'),
						ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_single_prediction_curve_pill_explanation_body')
						
					);
				}
				else if (predictionsExternalRefreshPill != null && (e.currentTarget === predictionsExternalRefreshPill.pillBackground || e.currentTarget === predictionsExternalRefreshPill.titleLabel))
				{
					displayPredictionPillExplanationCallout
					(
						predictionsExternalRefreshPill, 
						ModelLocator.resourceManagerInstance.getString('chartscreen','refresh_predictions_button_label'),
						ModelLocator.resourceManagerInstance.getString('chartscreen','refresh_predictions_explanation_label')
						
					);
				}
				else if (e.currentTarget === lastPredictionUpdateTimePill)
				{
					displayPredictionPillExplanationCallout
					(
						lastPredictionUpdateTimePill, 
						ModelLocator.resourceManagerInstance.getString('chartscreen','last_nightscout_prediction_update_label'),
						ModelLocator.resourceManagerInstance.getString('chartscreen','last_nightscout_prediction_update_explanation')
					);
				}
				else if (e.currentTarget === predictedTimeUntilHighPill)
				{
					displayPredictionPillExplanationCallout
					(
						predictedTimeUntilHighPill, 
						ModelLocator.resourceManagerInstance.getString('chartscreen','predicted_time_until_high_label'),
						ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_time_until_high_pill_explanation_body')
					);
				}
				else if (e.currentTarget === predictedTimeUntilLowPill)
				{
					displayPredictionPillExplanationCallout
					(
						predictedTimeUntilLowPill, 
						ModelLocator.resourceManagerInstance.getString('chartscreen','predicted_time_until_low_label'),
						ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_time_until_low_pill_explanation_body')
					);
				}
				else if (e.currentTarget === predictedTreatmentsOutcomePill)
				{
					displayPredictionPillExplanationCallout
					(
						predictedTreatmentsOutcomePill, 
						ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_treatments_outcome'),
						ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_treatments_outcome_pill_explanation_body')
					);
				}
				else if (e.currentTarget === predictedTreatmentsEffectPill)
				{
					displayPredictionPillExplanationCallout
					(
						predictedTreatmentsEffectPill, 
						ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_treatments_effect'),
						ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_treatments_effect_pill_explanation_body')
					);
				}
				else if (e.currentTarget === predictedUAMBGPill)
				{
					displayPredictionPillExplanationCallout
					(
						predictedUAMBGPill, 
						ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_unannounced_glucose_blood_glucose'),
						ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_uag_predicted_bg_pill_explanation_body')
					);
				}
				else if (e.currentTarget === predictedIOBBGPill)
				{
					displayPredictionPillExplanationCallout
					(
						predictedIOBBGPill, 
						ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_iob_blood_glucose'),
						ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_iob_predicted_bg_pill_explanation_body')
					);
				}
				else if (e.currentTarget === predictedCOBBGPill)
				{
					displayPredictionPillExplanationCallout
					(
						predictedCOBBGPill, 
						ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_cob_blood_glucose'),
						ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_cob_predicted_bg_pill_explanation_body')
					);
				}
				else if (e.currentTarget === predictedMinimumBGPill)
				{
					displayPredictionPillExplanationCallout
					(
						predictedMinimumBGPill, 
						ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_minimum_blood_glucose'),
						ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_minimum_predicted_bg_pill_explanation_body')
					);
				}
				else if (e.currentTarget === predictedCarbImpactPill)
				{
					displayPredictionPillExplanationCallout
					(
						predictedCarbImpactPill, 
						ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_carb_impact'),
						ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_carb_impact_pill_explanation_body')
					);
				}
				else if (e.currentTarget === predictedBgImpactPill)
				{
					displayPredictionPillExplanationCallout
					(
						predictedBgImpactPill, 
						ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_blood_glucose_impact'),
						ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_bg_impact_pill_explanation_body')
					);
				}
				else if (e.currentTarget === predictedDeviationPill)
				{
					displayPredictionPillExplanationCallout
					(
						predictedDeviationPill, 
						ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_deviation'),
						ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_deviation_pill_explanation_body')
					);
				}
				else if (e.currentTarget === glucoseVelocityPill)
				{
					displayPredictionPillExplanationCallout
					(
						glucoseVelocityPill, 
						ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_blood_glucose_velocity'),
						ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_bg_velocity_pill_explanation_body')
					);
				}
				else if (e.currentTarget === predictedEventualBGPill)
				{
					displayPredictionPillExplanationCallout
					(
						predictedEventualBGPill, 
						ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_eventual_blood_glucose'),
						ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_eventual_bg_pill_explanation_body')
					);
				}
			}
		}
		
		private function onIOBPredictionExplanation(e:TouchEvent):void
		{	
			if (!SystemUtil.isApplicationActive || dummyModeActive)
				return;
			
			var touch:Touch = e.getTouch(stage);
			
			if(touch != null && touch.phase == TouchPhase.BEGAN) 
			{
				displayPredictionLegendExplanationCallout
				(
					iobPredictLegendContainer, 
					ModelLocator.resourceManagerInstance.getString('chartscreen','IOB_prediction_curve_explanation_title'),
					ModelLocator.resourceManagerInstance.getString('chartscreen','IOB_prediction_curve_explanation_content') + (numDifferentPredictionsDisplayed > 1 && preferredPrediction == "IOB" ? "\n\n" + ModelLocator.resourceManagerInstance.getString('chartscreen','default_prediction_explanation') : "")
				);
			}
		}
		
		private function onUAMPredictionExplanation(e:TouchEvent):void
		{	
			if (!SystemUtil.isApplicationActive || dummyModeActive)
				return;
			
			var touch:Touch = e.getTouch(stage);
			
			if(touch != null && touch.phase == TouchPhase.BEGAN) 
			{
				displayPredictionLegendExplanationCallout
				(
					uamPredictLegendContainer, 
					ModelLocator.resourceManagerInstance.getString('chartscreen','UAG_prediction_curve_explanation_title'),
					ModelLocator.resourceManagerInstance.getString('chartscreen','UAG_prediction_curve_explanation_content') + (numDifferentPredictionsDisplayed > 1 && preferredPrediction == "UAM" ? "\n\n" + ModelLocator.resourceManagerInstance.getString('chartscreen','default_prediction_explanation') : "")
				);
			}
		}
		
		private function onCOBPredictionExplanation(e:TouchEvent):void
		{	
			if (!SystemUtil.isApplicationActive || dummyModeActive)
				return;
			
			var touch:Touch = e.getTouch(stage);
			
			if(touch != null && touch.phase == TouchPhase.BEGAN) 
			{
				displayPredictionLegendExplanationCallout
				(
					cobPredictLegendContainer, 
					ModelLocator.resourceManagerInstance.getString('chartscreen','COB_prediction_curve_explanation_title'),
					ModelLocator.resourceManagerInstance.getString('chartscreen','COB_prediction_curve_explanation_content') + (numDifferentPredictionsDisplayed > 1 && preferredPrediction == "COB" ? "\n\n" + ModelLocator.resourceManagerInstance.getString('chartscreen','default_prediction_explanation') : "")
				);
			}
		}
		
		private function onZTPredictionExplanation(e:TouchEvent):void
		{	
			if (!SystemUtil.isApplicationActive || dummyModeActive)
				return;
			
			var touch:Touch = e.getTouch(stage);
			
			if(touch != null && touch.phase == TouchPhase.BEGAN) 
			{
				displayPredictionLegendExplanationCallout
				(
					ztPredictLegendContainer, 
					ModelLocator.resourceManagerInstance.getString('chartscreen','ZT_prediction_curve_explanation_title'),
					ModelLocator.resourceManagerInstance.getString('chartscreen','ZT_prediction_curve_explanation_content') + (numDifferentPredictionsDisplayed > 1 && preferredPrediction == "ZTM" ? "\n\n" + ModelLocator.resourceManagerInstance.getString('chartscreen','default_prediction_explanation') : "")
				);
			}
		}
		
		private function disposePredictionsHeader():void
		{
			if (cobPredictLegendLabel != null)
			{
				cobPredictLegendLabel.removeFromParent();
				cobPredictLegendLabel.dispose();
				cobPredictLegendLabel = null;
			}
			
			if (cobPredictLegendColorQuad != null)
			{
				cobPredictLegendColorQuad.removeFromParent();
				cobPredictLegendColorQuad.dispose();
				cobPredictLegendColorQuad = null;
			}
			
			if (cobPredictLegendHitArea != null)
			{
				cobPredictLegendHitArea.removeFromParent();
				cobPredictLegendHitArea.dispose();
				cobPredictLegendHitArea = null;
			}
			
			if (cobPredictLegendContainer != null)
			{
				cobPredictLegendContainer.removeEventListener(TouchEvent.TOUCH, onCOBPredictionExplanation);
				cobPredictLegendContainer.removeFromParent();
				cobPredictLegendContainer.dispose();
				cobPredictLegendContainer = null;
			}
			
			if (uamPredictLegendLabel != null)
			{
				uamPredictLegendLabel.removeFromParent();
				uamPredictLegendLabel.dispose();
				uamPredictLegendLabel = null;
			}
			
			if (uamPredictLegendColorQuad != null)
			{
				uamPredictLegendColorQuad.removeFromParent();
				uamPredictLegendColorQuad.dispose();
				uamPredictLegendColorQuad = null;
			}
			
			if (uamPredictLegendHitArea != null)
			{
				uamPredictLegendHitArea.removeFromParent();
				uamPredictLegendHitArea.dispose();
				uamPredictLegendHitArea = null;
			}
			
			if (uamPredictLegendContainer != null)
			{
				uamPredictLegendContainer.removeEventListener(TouchEvent.TOUCH, onUAMPredictionExplanation);
				uamPredictLegendContainer.removeFromParent();
				uamPredictLegendContainer.dispose();
				uamPredictLegendContainer = null;
			}
			
			if (iobPredictLegendLabel != null)
			{
				iobPredictLegendLabel.removeFromParent();
				iobPredictLegendLabel.dispose();
				iobPredictLegendLabel = null;
			}
			
			if (iobPredictLegendColorQuad != null)
			{
				iobPredictLegendColorQuad.removeFromParent();
				iobPredictLegendColorQuad.dispose();
				iobPredictLegendColorQuad = null;
			}
			
			if (iobPredictLegendHitArea != null)
			{
				iobPredictLegendHitArea.removeFromParent();
				iobPredictLegendHitArea.dispose();
				iobPredictLegendHitArea = null;
			}
			
			if (iobPredictLegendContainer != null)
			{
				iobPredictLegendContainer.removeEventListener(TouchEvent.TOUCH, onIOBPredictionExplanation);
				iobPredictLegendContainer.removeFromParent();
				iobPredictLegendContainer.dispose();
				iobPredictLegendContainer = null;
			}
			
			if (ztPredictLegendLabel != null)
			{
				ztPredictLegendLabel.removeFromParent();
				ztPredictLegendLabel.dispose();
				ztPredictLegendLabel = null;
			}
			
			if (ztPredictLegendColorQuad != null)
			{
				ztPredictLegendColorQuad.removeFromParent();
				ztPredictLegendColorQuad.dispose();
				ztPredictLegendColorQuad = null;
			}
			
			if (ztPredictLegendHitArea != null)
			{
				ztPredictLegendHitArea.removeFromParent();
				ztPredictLegendHitArea.dispose();
				ztPredictLegendHitArea = null;
			}
			
			if (ztPredictLegendContainer != null)
			{
				ztPredictLegendContainer.removeEventListener(TouchEvent.TOUCH, onZTPredictionExplanation);
				ztPredictLegendContainer.removeFromParent();
				ztPredictLegendContainer.dispose();
				ztPredictLegendContainer = null;
			}
			
			if (!predictionPillExplanationEnabled)
			{
				if (predictionExplanationLabel != null)
				{
					predictionExplanationLabel.removeFromParent();
					predictionExplanationLabel.dispose();
					predictionExplanationLabel = null;
				}
				
				if (predictionTitleLabel != null)
				{
					predictionTitleLabel.removeFromParent();
					predictionTitleLabel.dispose();
					predictionTitleLabel = null;
				}
				
				if (predictionExplanationMainContainer != null)
				{
					predictionExplanationMainContainer.removeFromParent();
					predictionExplanationMainContainer.dispose();
					predictionExplanationMainContainer = null;
				}
				
				if (predictionExplanationCallout != null)
				{
					predictionExplanationCallout.removeEventListener(starling.events.Event.OPEN, onPredictionPillExplanationOpened);
					predictionExplanationCallout.removeEventListener(starling.events.Event.CLOSE, disposePredictionsExplanations);
					predictionExplanationCallout.removeEventListener(TouchEvent.TOUCH, onClosePredictionsExplanation);
					predictionExplanationCallout.removeFromParent();
					predictionExplanationCallout.dispose();
					predictionExplanationCallout = null;
					
					if (predictionsCallout != null)
					{
						predictionsCallout.closeOnTouchBeganOutside = true;
						predictionsCallout.closeOnTouchEndedOutside = true;
					}
				}
			}
			
			if (predictionsLegendsContainer != null)
			{
				predictionsLegendsContainer.removeFromParent();
				predictionsLegendsContainer.dispose();
				predictionsLegendsContainer = null;
			}
		}
		
		private function redrawPredictions(forceIOBCOBRefresh:Boolean = false, externalAPSRequest:Boolean = false):void
		{
			//First validation
			if (!SystemUtil.isApplicationActive)
				return;
			
			if (!externalAPSRequest && !predictionsEnabled)
			{
				if (!predictionsEnabled || predictionsMainGlucoseDataPoints == null || predictionsMainGlucoseDataPoints.length == 0 || predictionsScrollerGlucoseDataPoints == null || predictionsScrollerGlucoseDataPoints.length == 0 || predictionsDelimiter == null || dummyModeActive || !SystemUtil.isApplicationActive)
				{
					//There's no current predictions drawn on the chart so no need to redraw anything
					return;
				}
			}
			
			//Second validation
			var now:Number = new Date().valueOf();
			if (now - lastPredictionsRedrawTimestamp < 500 && !externalAPSRequest)
			{
				//Already redrawn less then 0.5 seccons ago. No need to redraw again.
				return;
			}
			
			lastPredictionsRedrawTimestamp = now;
			
			//Special case for latest carb treatment
			var lastTreatmentIsCarbs:Boolean = TreatmentsManager.lastTreatmentIsCarb();
			
			//Get new predictions
			var predictionsList:Array = fetchPredictions(lastTreatmentIsCarbs || forceIOBCOBRefresh);
			
			//Third validation
			if (predictionsList == null || predictionsList.length == 0)
			{
				//There's no predictions available
				return;
			}
			
			//Check if lowest or highest glucose value have changed
			var predictionsSorted:Array = predictionsList.concat();
			predictionsSorted.sortOn(["_calculatedValue"], Array.NUMERIC);
			
			if (predictionsSorted[0] == null || predictionsSorted[predictionsSorted.length - 1] == null)
				return;
			
			var predictionLowestValue:Number = predictionsSorted[0]._calculatedValue;
			var predictionHighestValue:Number = predictionsSorted[predictionsSorted.length - 1]._calculatedValue;
			
			var realReadingsSorted:Array = _dataSource.concat();
			realReadingsSorted.sortOn(["_calculatedValue"], Array.NUMERIC);
			
			if (realReadingsSorted[0] == null || realReadingsSorted[realReadingsSorted.length - 1] == null)
				return;
			
			var realReadingsLowestValue:Number = realReadingsSorted[0]._calculatedValue;
			var realReadingsHighestValue:Number = realReadingsSorted[realReadingsSorted.length - 1]._calculatedValue;
			
			if (predictionLowestValue < lowestGlucoseValue || predictionHighestValue > highestGlucoseValue || realReadingsLowestValue > lowestGlucoseValue || realReadingsHighestValue < highestGlucoseValue)
			{
				//Dispose previous predictions
				disposePredictions();
				
				//Redraw main and scroller charts
				redrawChart(MAIN_CHART, _graphWidth - yAxisMargin, _graphHeight, yAxisMargin, mainChartGlucoseMarkerRadius, 0, false, lastTreatmentIsCarbs || forceIOBCOBRefresh);
				redrawChart(SCROLLER_CHART, _scrollerWidth - (scrollerChartGlucoseMarkerRadius * 2), _scrollerHeight, 0, scrollerChartGlucoseMarkerRadius, 0, false, lastTreatmentIsCarbs || forceIOBCOBRefresh);
				
				//Redraw raw markers if needed
				if (displayRaw)
				{
					hideRaw();
					showRaw();
				}
				
				//Adjust Main Chart and Picker Position
				if (displayLatestBGValue && mainChart != null)
				{
					mainChart.x = -mainChart.width + _graphWidth - yAxisMargin;
					if (predictionsEnabled && predictionsMainGlucoseDataPoints != null && predictionsMainGlucoseDataPoints.length > 0)
					{
						mainChart.x += mainChartGlucoseMarkerRadius;
					}
					
					if (mainChartGlucoseMarkersList[mainChartGlucoseMarkersList.length - 1] != null)
					{
						selectedGlucoseMarkerIndex = mainChartGlucoseMarkersList[mainChartGlucoseMarkersList.length - 1].index;
					}
				}
				
				//Redraw timeline
				drawTimeline();
				
				//Reposition delimitter
				reporsitionPredictionDelimitter();
				
				//Reposition treatments
				manageTreatments();
				
				//Timeline
				if (timelineActive && timelineContainer != null && mainChart != null)
					timelineContainer.x = mainChart.x;
				
				//Treatments
				if (treatmentsActive && treatmentsContainer != null && mainChart != null)
					treatmentsContainer.x = mainChart.x;
				
				//Raw
				if (displayRaw && rawDataContainer != null && mainChart != null)
					rawDataContainer.x = mainChart.x;
				
				//Update pedictions in Nightscout
				NightscoutService.uploadPredictions(lastTreatmentIsCarbs || forceIOBCOBRefresh || forceNightscoutPredictionRefresh);
				forceNightscoutPredictionRefresh = false;
				
				return;
			}
			
			//Dispose current predictions 
			disposePredictions();
			
			//Draw Predictions
			drawPredictions(MAIN_CHART, _graphWidth - yAxisMargin, _graphHeight, yAxisMargin, mainChartGlucoseMarkerRadius);
			drawPredictions(SCROLLER_CHART, _scrollerWidth - (scrollerChartGlucoseMarkerRadius * 2), _scrollerHeight, 0, scrollerChartGlucoseMarkerRadius);
			
			if(_displayLine)
			{
				//Destroy previous lines
				destroyAllLines();
				
				//Draw Lines
				drawLine(MAIN_CHART);
				drawLine(SCROLLER_CHART);
			}
			
			//Reposition delimitter
			reporsitionPredictionDelimitter();
			
			//Reposition Treatments
			manageTreatments();
			
			//Update pedictions in Nightscout
			NightscoutService.uploadPredictions(lastTreatmentIsCarbs || forceIOBCOBRefresh || forceNightscoutPredictionRefresh);
			forceNightscoutPredictionRefresh = false;
			
			//Drawing Logic
			function drawPredictions(chartType:String, chartWidth:Number, chartHeight:Number, chartRightMargin:Number, glucoseMarkerRadius:Number):void
			{
				if (dummyModeActive || !SystemUtil.isApplicationActive)
					return;
				
				var chartContainer:Sprite = chartType == MAIN_CHART ? mainChart : scrollerChart;
				if (chartContainer == null) return;
				
				var totalTimestampDifference:Number = lastBGreadingTimeStamp - firstBGReadingTimeStamp;
				var scaleXFactor:Number;
				if(chartType == MAIN_CHART)
				{
					differenceInMinutesForAllTimestamps = TimeSpan.fromDates(new Date(firstBGReadingTimeStamp), new Date(lastBGreadingTimeStamp)).totalMinutes;
					if (differenceInMinutesForAllTimestamps > TimeSpan.TIME_ONE_DAY_IN_MINUTES)
						differenceInMinutesForAllTimestamps = TimeSpan.TIME_ONE_DAY_IN_MINUTES;
					
					scaleXFactor = 1/(totalTimestampDifference / (chartWidth * (timelineRange / (TimeSpan.TIME_ONE_DAY_IN_MINUTES / differenceInMinutesForAllTimestamps))));
				}
				else if (chartType == SCROLLER_CHART)
				{
					scaleXFactor = 1/(totalTimestampDifference / (chartWidth - chartRightMargin));
				}
				
				var scaleYFactor:Number;
				var sortDataArray:Array = _dataSource.concat().concat(predictionsList);
				sortDataArray.sortOn(["_calculatedValue"], Array.NUMERIC);
				var lowestValue:Number;
				var highestValue:Number;;
				if (!dummyModeActive)
				{
					if (sortDataArray[0] == null || sortDataArray[sortDataArray.length - 1] == null)
						return;
					
					lowestValue = sortDataArray[0]._calculatedValue as Number;
					highestValue = sortDataArray[sortDataArray.length - 1]._calculatedValue as Number;
					if (!fixedSize)
					{
						lowestGlucoseValue = lowestValue;
						if (lowestGlucoseValue < 40)
							lowestGlucoseValue = 40;
						
						highestGlucoseValue = highestValue;
						if (highestGlucoseValue > 400)
							highestGlucoseValue = 400;
					}
					else
					{
						lowestGlucoseValue = minAxisValue;
						if (resizeOutOfBounds && lowestValue < minAxisValue)
							lowestGlucoseValue = lowestValue;
						
						highestGlucoseValue = maxAxisValue;
						if (resizeOutOfBounds && highestValue > maxAxisValue)
							highestGlucoseValue = highestValue
					}
				}
				else
				{
					lowestGlucoseValue = 40;
					highestGlucoseValue = 300;
				}
				
				//We find the difference so we can know how big the glucose pseudo graph is
				var totalGlucoseDifference:Number = highestGlucoseValue - lowestGlucoseValue;
				//Now we find a multiplier for the y axis so the glucose graph fits entirely with the chart height
				scaleYFactor = (chartHeight - (glucoseMarkerRadius*2))/totalGlucoseDifference;
				
				if ((chartType == MAIN_CHART && mainChartGlucoseMarkersList[mainChartGlucoseMarkersList.length - 1] == null) || (chartType == SCROLLER_CHART && scrollChartGlucoseMarkersList[scrollChartGlucoseMarkersList.length - 1] == null))
					return
				
				var previousXCoordinate:Number = chartType == MAIN_CHART ? mainChartGlucoseMarkersList[mainChartGlucoseMarkersList.length - 1].x : scrollChartGlucoseMarkersList[scrollChartGlucoseMarkersList.length - 1].x;
				var previousYCoordinate:Number = chartType == MAIN_CHART ? mainChartGlucoseMarkersList[mainChartGlucoseMarkersList.length - 1].y : scrollChartGlucoseMarkersList[scrollChartGlucoseMarkersList.length - 1].y;
				var previousGlucoseMarker:GlucoseMarker;
				
				//Redraw predictions
				var predictionsLength:int = predictionsList.length;
				for (var i:int = 0; i < predictionsLength; i++) 
				{
					var glucoseReading:BgReading = predictionsList[i];
					if (glucoseReading == null) continue;
					
					//Get current glucose value
					var currentGlucoseValue:Number = glucoseReading._calculatedValue;
					if(currentGlucoseValue < 40)
						currentGlucoseValue = 40;
					else if (currentGlucoseValue > 400)
						currentGlucoseValue = 400;
					
					//Define glucose marker x position
					var glucoseX:Number;
					var prevReading:BgReading;
					if(i==0)
					{
						prevReading = _dataSource[_dataSource.length-1];
						if (prevReading == null) continue;
						
						glucoseX = (Number(glucoseReading.timestamp) - Number(prevReading.timestamp)) * scaleXFactor;
					}
					else
					{
						prevReading = predictionsList[i-1];
						if (prevReading == null) continue;
						
						glucoseX = (Number(glucoseReading.timestamp) - Number(prevReading.timestamp)) * scaleXFactor;
					}
					
					//Define glucose marker y position
					var glucoseY:Number = chartHeight - (glucoseMarkerRadius * 2) - ((currentGlucoseValue - lowestGlucoseValue) * scaleYFactor);
					//If glucose is a perfect flat line then display it in the middle
					if(totalGlucoseDifference == 0) 
						glucoseY = (chartHeight - (glucoseMarkerRadius*2)) / 2;
					
					var glucoseMarker:GlucoseMarker = new GlucoseMarker
					(
						{
							x: previousXCoordinate + glucoseX,
							y: glucoseY,
							index: i,
							radius: glucoseMarkerRadius,
							bgReading: glucoseReading,
							glucose: currentGlucoseValue,
							color: glucoseReading.rawData
						},
						false,
						true
					);
					
					if(chartType == MAIN_CHART)
					{
						glucoseMarker.addHitArea();
						glucoseMarker.addEventListener(TouchEvent.TOUCH, onPredictionMarkerTouched);
					}
					else
						glucoseMarker.touchable = false;
					
					//Hide glucose marker if it is out of bounds (fixed size chart);
					if (glucoseMarker.glucoseValue < lowestGlucoseValue || glucoseMarker.glucoseValue > highestGlucoseValue)
						glucoseMarker.alpha = 0;
					else
						glucoseMarker.alpha = 1;
					
					//Set variables for next iteration
					previousXCoordinate = glucoseMarker.x;
					previousYCoordinate = glucoseMarker.y;
					previousGlucoseMarker = glucoseMarker;
					
					//Add glucose marker to the timeline
					if (chartContainer != null)
						chartContainer.addChild(glucoseMarker);
					
					if(chartType == MAIN_CHART && predictionsMainGlucoseDataPoints != null)
					{
						predictionsMainGlucoseDataPoints.push(glucoseMarker);
					}
					else if (chartType == SCROLLER_CHART && predictionsScrollerGlucoseDataPoints != null)
					{
						predictionsScrollerGlucoseDataPoints.push(glucoseMarker);
					}
				}
			}
		}
		
		private function reporsitionPredictionDelimitter():void
		{
			if (predictionsEnabled && yAxis != null && predictionsMainGlucoseDataPoints.length > 0 && mainChartGlucoseMarkersList.length > 0)
			{
				if (predictionsDelimiter == null)
				{
					predictionsDelimiter = GraphLayoutFactory.createVerticalDashedLine(_graphHeight, dashLineWidth, dashLineGap, dashLineThickness, lineColor);
					predictionsDelimiter.y = 0 - predictionsDelimiter.width;
					predictionsDelimiter.touchable = false;
					yAxis.addChild(predictionsDelimiter);
				}
				
				predictionsDelimiter.x = mainChartGlucoseMarkerRadius + _graphWidth - yAxisMargin + (mainChartGlucoseMarkerRadius * 2) - (mainChart.width - mainChartGlucoseMarkersList[mainChartGlucoseMarkersList.length - 1].x);
				activeGlucoseDelimiter = predictionsDelimiter;
				
				//Adjust Main Chart Position
				if (displayLatestBGValue)
				{
					mainChart.x = mainChartGlucoseMarkerRadius + -mainChart.width + _graphWidth - yAxisMargin;
					selectedGlucoseMarkerIndex = mainChartGlucoseMarkersList[mainChartGlucoseMarkersList.length - 1].index;
				}
				
				//Timeline
				if (timelineActive && timelineContainer != null)
					timelineContainer.x = mainChart.x;
				
				//Treatments
				if (treatmentsActive && treatmentsContainer != null)
					treatmentsContainer.x = mainChart.x;
				
				//Raw
				if (displayRaw && rawDataContainer != null)
					rawDataContainer.x = mainChart.x;
			}
			else
			{
				if (predictionsDelimiter != null) predictionsDelimiter.removeFromParent(true);
			}
		}
		
		private function onDisplayMorePredictions(e:starling.events.TouchEvent):void
		{
			if (!SystemUtil.isApplicationActive || dummyModeActive)
				return;
			
			var touch:Touch = e.getTouch(stage);
			
			if(touch != null && touch.phase == TouchPhase.BEGAN) 
			{
				refreshPredictionsCallout()
			}
		}
		
		private function refreshPredictionsCallout():void
		{
			var widestPreditctionPill:Number = 0;
			
			var predictionsLayout:VerticalLayout = new VerticalLayout();
			predictionsLayout.horizontalAlign = HorizontalAlign.CENTER;
			predictionsLayout.gap = 6;
			if (predictionsContainer != null) predictionsContainer.removeFromParent(true);
			predictionsContainer = new ScrollContainer();
			predictionsContainer.layout = predictionsLayout;
			
			if (predictionsCallout != null) predictionsCallout.removeFromParent(true);
			predictionsCallout = Callout.show(predictionsContainer, predictionsPill, null, true);
			predictionsCallout.addEventListener(starling.events.Event.CLOSE, onPredictionsCalloutClosed);
			
			//ON/OFF Toggle
			if (predictionsEnableSwitch != null) predictionsEnableSwitch.removeFromParent(true);
			predictionsEnableSwitch = LayoutFactory.createToggleSwitch(predictionsEnabled);
			predictionsEnableSwitch.addEventListener(starling.events.Event.CHANGE, onPredictionsSwitchChanged);
			if (predictionsEnablerPill != null) predictionsEnablerPill.removeFromParent(true);
			predictionsEnablerPill = new ChartComponentPill(ModelLocator.resourceManagerInstance.getString('globaltranslations','enabled_label'), predictionsEnableSwitch);
			predictionsEnablerPill.pillBackground.addEventListener(TouchEvent.TOUCH, onPredictionPillExplanation);
			predictionsEnablerPill.titleLabel.addEventListener(TouchEvent.TOUCH, onPredictionPillExplanation);
			predictionsContainer.addChild(predictionsEnablerPill);
			
			widestPreditctionPill = Math.max(widestPreditctionPill, predictionsContainer.width);
			
			//Wiki
			if (wikiPredictionsButton != null)
			{
				if (wikiPredictionsIcon != null)
				{
					if (wikiPredictionsIcon.texture != null)
					{
						wikiPredictionsIcon.texture.dispose();
					}
					
					wikiPredictionsIcon.removeFromParent(true);
				}
				
				wikiPredictionsButton.removeEventListener(starling.events.Event.TRIGGERED, onPredictionsWiki);
				wikiPredictionsButton.removeFromParent(true);
			}
			wikiPredictionsIcon = new Image(MaterialDeepGreyAmberMobileThemeIcons.helpOutlineTexture);
			wikiPredictionsButton = new Button();
			wikiPredictionsButton.defaultIcon = wikiPredictionsIcon;
			wikiPredictionsButton.height = 21;
			wikiPredictionsButton.paddingLeft = wikiPredictionsButton.paddingRight = 8;
			wikiPredictionsButton.addEventListener(starling.events.Event.TRIGGERED, onPredictionsWiki);
			
			if (wikiPredictionsPill != null) wikiPredictionsPill.removeFromParent(true);
			wikiPredictionsPill = new ChartComponentPill(ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_wiki_label'), wikiPredictionsButton);
			wikiPredictionsPill.pillBackground.addEventListener(TouchEvent.TOUCH, onPredictionPillExplanation);
			wikiPredictionsPill.titleLabel.addEventListener(TouchEvent.TOUCH, onPredictionPillExplanation);
			predictionsContainer.addChild(wikiPredictionsPill);
			
			widestPreditctionPill = Math.max(widestPreditctionPill, wikiPredictionsPill.width);
			
			if (predictionsEnabled)
			{
				//Duration
				if (predictionsLengthPicker != null) predictionsLengthPicker.removeFromParent(true);
				var currentPredictionsLength:Number;
				var predictionsListSelectedIndex:int;
				predictionsLengthPicker = LayoutFactory.createPickerList();
				predictionsLengthPicker.labelField = "label";
				predictionsLengthPicker.popUpContentManager = new DropDownPopUpContentManager();
				var lengthData:Array = [];
				if (timelineRange == TIMELINE_1H)
				{
					lengthData.push( { label: ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_15_min_duration_label'), id: 15 } );
					lengthData.push( { label: ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_20_min_duration_label'), id: 20 } );
					lengthData.push( { label: ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_25_min_duration_label'), id: 25 } );
					lengthData.push( { label: ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_30_min_duration_label'), id: 30 } );
					
					currentPredictionsLength = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_GLUCOSE_PREDICTIONS_MINUTES_FOR_1_HOUR));
					if (currentPredictionsLength == 15)
						predictionsListSelectedIndex = 0;
					else if (currentPredictionsLength == 20)
						predictionsListSelectedIndex = 1;
					else if (currentPredictionsLength == 25)
						predictionsListSelectedIndex = 2;
					else if (currentPredictionsLength == 30)
						predictionsListSelectedIndex = 3;
				}
				else if (timelineRange == TIMELINE_3H)
				{
					lengthData.push( { label: ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_30_min_duration_label'), id: 30 } );
					lengthData.push( { label: ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_1_hour_duration_label'), id: 60 } );
					lengthData.push( { label: ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_1_hour_30_min_duration_label'), id: 90 } );
					
					currentPredictionsLength = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_GLUCOSE_PREDICTIONS_MINUTES_FOR_3_HOURS));
					if (currentPredictionsLength == 30)
						predictionsListSelectedIndex = 0;
					else if (currentPredictionsLength == 60)
						predictionsListSelectedIndex = 1;
					else if (currentPredictionsLength == 90)
						predictionsListSelectedIndex = 2;
				}
				else if (timelineRange == TIMELINE_6H)
				{
					lengthData.push( { label: ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_30_min_duration_label'), id: 30 } );
					lengthData.push( { label: ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_1_hour_duration_label'), id: 60 } );
					lengthData.push( { label: ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_1_hour_30_min_duration_label'), id: 90 } );
					lengthData.push( { label: ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_2_hours_duration_label'), id: 120 } );
					lengthData.push( { label: ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_2_hour_30_min_duration_label'), id: 150 } );
					lengthData.push( { label: ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_3_hours_duration_label'), id: 180 } );
					
					currentPredictionsLength = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_GLUCOSE_PREDICTIONS_MINUTES_FOR_6_HOURS));
					if (currentPredictionsLength == 30)
						predictionsListSelectedIndex = 0;
					else if (currentPredictionsLength == 60)
						predictionsListSelectedIndex = 1;
					else if (currentPredictionsLength == 90)
						predictionsListSelectedIndex = 2;
					else if (currentPredictionsLength == 120)
						predictionsListSelectedIndex = 3;
					else if (currentPredictionsLength == 150)
						predictionsListSelectedIndex = 4;
					else if (currentPredictionsLength == 180)
						predictionsListSelectedIndex = 5;
				}
				else if (timelineRange == TIMELINE_12H)
				{
					lengthData.push( { label: ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_1_hour_duration_label'), id: 60 } );
					lengthData.push( { label: ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_2_hours_duration_label'), id: 120 } );
					lengthData.push( { label: ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_3_hours_duration_label'), id: 180 } );
					lengthData.push( { label: ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_4_hours_duration_label'), id: 240 } );
					
					currentPredictionsLength = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_GLUCOSE_PREDICTIONS_MINUTES_FOR_12_HOURS));
					if (currentPredictionsLength == 60)
						predictionsListSelectedIndex = 0;
					else if (currentPredictionsLength == 120)
						predictionsListSelectedIndex = 1;
					else if (currentPredictionsLength == 180)
						predictionsListSelectedIndex = 2;
					else if (currentPredictionsLength == 240)
						predictionsListSelectedIndex = 3;
				}
				else if (timelineRange == TIMELINE_24H)
				{
					lengthData.push( { label: ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_1_hour_duration_label'), id: 60 } );
					lengthData.push( { label: ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_2_hours_duration_label'), id: 120 } );
					lengthData.push( { label: ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_3_hours_duration_label'), id: 180 } );
					lengthData.push( { label: ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_4_hours_duration_label'), id: 240 } );
					
					currentPredictionsLength = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_GLUCOSE_PREDICTIONS_MINUTES_FOR_24_HOURS));
					if (currentPredictionsLength == 60)
						predictionsListSelectedIndex = 0;
					else if (currentPredictionsLength == 120)
						predictionsListSelectedIndex = 1;
					else if (currentPredictionsLength == 180)
						predictionsListSelectedIndex = 2;
					else if (currentPredictionsLength == 240)
						predictionsListSelectedIndex = 3;
				}
				
				predictionsLengthPicker.dataProvider = new ArrayCollection(lengthData);
				predictionsLengthPicker.selectedIndex = predictionsListSelectedIndex;
				predictionsLengthPicker.buttonFactory = function():Button
				{
					var button:Button = new Button();
					button.height = 21;
					button.paddingLeft = button.paddingRight = 8;
					
					return button;
				};
				
				predictionsLengthPicker.addEventListener(starling.events.Event.CHANGE, onPredictionsTimeFrameChanged);
				predictionsLengthPicker.addEventListener(starling.events.Event.OPEN, onPredictionsTimeFrameOpened);
				predictionsLengthPicker.addEventListener(starling.events.Event.CLOSE, onPredictionsTimeFrameClosed);
				
				if (predictionsTimeFramePill != null) predictionsTimeFramePill.removeFromParent(true);
				predictionsTimeFramePill = new ChartComponentPill(ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_duration_label'), predictionsLengthPicker, 6, true);
				predictionsTimeFramePill.addEventListener(starling.events.Event.UPDATE, onPredictionTimeFramePillUpdated);
				predictionsTimeFramePill.pillBackground.addEventListener(TouchEvent.TOUCH, onPredictionPillExplanation);
				predictionsTimeFramePill.titleLabel.addEventListener(TouchEvent.TOUCH, onPredictionPillExplanation);
				predictionsContainer.addChild(predictionsTimeFramePill);
				
				widestPreditctionPill = Math.max(widestPreditctionPill, predictionsTimeFramePill.width);
				
				//IOB/COB Toggle
				if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_LOOP_OPENAPS_USER_ENABLED) != "true" && !isDexcomFollower)
				{
					if (predictionsIOBCOBCheck != null) predictionsIOBCOBCheck.removeFromParent(true);
					predictionsIOBCOBCheck = LayoutFactory.createCheckMark(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_GLUCOSE_PREDICTIONS_INCLUDE_IOB_COB) == "true");
					predictionsIOBCOBCheck.paddingTop = predictionsIOBCOBCheck.paddingBottom = 3;
					predictionsIOBCOBCheck.addEventListener(starling.events.Event.CHANGE, onPredictionsIOBCOBChanged);
					if (predictionsIOBCOBPill != null) predictionsIOBCOBPill.removeFromParent(true);
					predictionsIOBCOBPill = new ChartComponentPill(ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_include_iob_cob_label'), predictionsIOBCOBCheck);
					predictionsIOBCOBPill.pillBackground.addEventListener(TouchEvent.TOUCH, onPredictionPillExplanation);
					predictionsIOBCOBPill.titleLabel.addEventListener(TouchEvent.TOUCH, onPredictionPillExplanation);
					predictionsContainer.addChild(predictionsIOBCOBPill);
					
					widestPreditctionPill = Math.max(widestPreditctionPill, predictionsIOBCOBPill.width);
				}
				
				//Single Prediction Curve Toggle
				if (!Forecast.externalLoopAPS)
				{
					if (predictionsSingleCurveCheck != null) predictionsSingleCurveCheck.removeFromParent(true);
					predictionsSingleCurveCheck = LayoutFactory.createCheckMark(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_GLUCOSE_PREDICTIONS_SINGLE_LINE_ENABLED) == "true");
					predictionsSingleCurveCheck.paddingTop = predictionsSingleCurveCheck.paddingBottom = 3;
					predictionsSingleCurveCheck.addEventListener(starling.events.Event.CHANGE, onPredictionsSingleCurveChanged);
					
					if (predictionsSingleCurvePill != null) predictionsSingleCurvePill.removeFromParent(true);
					predictionsSingleCurvePill = new ChartComponentPill(ModelLocator.resourceManagerInstance.getString('chartscreen','single_prediction_curve_label'), predictionsSingleCurveCheck);
					predictionsSingleCurvePill.pillBackground.addEventListener(TouchEvent.TOUCH, onPredictionPillExplanation);
					predictionsSingleCurvePill.titleLabel.addEventListener(TouchEvent.TOUCH, onPredictionPillExplanation);
					predictionsContainer.addChild(predictionsSingleCurvePill);
					
					widestPreditctionPill = Math.max(widestPreditctionPill, predictionsSingleCurvePill.width);
				}
				
				//Loop/OpenAPS Users
				if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_LOOP_OPENAPS_USER_ENABLED) == "true")
				{
					//Add Refresh Button
					if (refreshExternalPredictionsButton != null)
					{
						if (refreshPredictionsIcon != null)
						{
							if (refreshPredictionsIcon.texture != null)
							{
								refreshPredictionsIcon.texture.dispose();
							}
							
							refreshPredictionsIcon.removeFromParent(true);
						}
						
						refreshExternalPredictionsButton.removeEventListener(starling.events.Event.TRIGGERED, onRefreshExternalPredictions);
						refreshExternalPredictionsButton.removeFromParent(true);
					}
					refreshPredictionsIcon = new Image(MaterialDeepGreyAmberMobileThemeIcons.refreshTexture);
					refreshExternalPredictionsButton = new Button();
					refreshExternalPredictionsButton.defaultIcon = refreshPredictionsIcon;
					refreshExternalPredictionsButton.height = 21;
					refreshExternalPredictionsButton.paddingLeft = refreshExternalPredictionsButton.paddingRight = 8;
					refreshExternalPredictionsButton.addEventListener(starling.events.Event.TRIGGERED, onRefreshExternalPredictions);
					
					if (predictionsExternalRefreshPill != null) predictionsExternalRefreshPill.removeFromParent(true);
					predictionsExternalRefreshPill = new ChartComponentPill(ModelLocator.resourceManagerInstance.getString('chartscreen','refresh_predictions_button_label'), refreshExternalPredictionsButton);
					predictionsExternalRefreshPill.pillBackground.addEventListener(TouchEvent.TOUCH, onPredictionPillExplanation);
					predictionsExternalRefreshPill.titleLabel.addEventListener(TouchEvent.TOUCH, onPredictionPillExplanation);
					predictionsContainer.addChild(predictionsExternalRefreshPill);
					
					widestPreditctionPill = Math.max(widestPreditctionPill, predictionsExternalRefreshPill.width);
					
					//Last NS Update
					if (!isNaN(lastPredictionUpdate))
					{
						if (lastPredictionUpdateTimePill != null) lastPredictionUpdateTimePill.removeFromParent(true);
						lastPredictionUpdateTimePill = new ChartTreatmentPill(ModelLocator.resourceManagerInstance.getString('chartscreen','last_nightscout_prediction_update_label'));
						
						var lastUpdateFormated:String = TimeSpan.formatHoursMinutesFromSecondsChart((new Date().valueOf() - lastPredictionUpdate) / 1000, true, true, false);
						//lastUpdateFormated.replace(" ", "");
						if (lastUpdateFormated != ModelLocator.resourceManagerInstance.getString('chartscreen','now'))
						{
							lastUpdateFormated += " " + ModelLocator.resourceManagerInstance.getString('chartscreen','time_ago_suffix');
						}
						
						lastPredictionUpdateTimePill.setValue(lastUpdateFormated);
						lastPredictionUpdateTimePill.addEventListener(TouchEvent.TOUCH, onPredictionPillExplanation);
						predictionsContainer.addChild(lastPredictionUpdateTimePill);
						
						widestPreditctionPill = Math.max(widestPreditctionPill, lastPredictionUpdateTimePill.width);
					}
				}
			
				//Time Until High
				if (!isNaN(predictedTimeUntilHigh) && predictedTimeUntilHigh != 0)
				{
					if (predictedTimeUntilHighPill != null) predictedTimeUntilHighPill.removeFromParent(true);
					predictedTimeUntilHighPill = new ChartTreatmentPill(ModelLocator.resourceManagerInstance.getString('chartscreen','predicted_time_until_high_label'));
					predictedTimeUntilHighPill.setValue("±" + TimeSpan.formatHoursMinutesFromMinutes(predictedTimeUntilHigh / TimeSpan.TIME_1_MINUTE, false));
					predictedTimeUntilHighPill.addEventListener(TouchEvent.TOUCH, onPredictionPillExplanation);
					predictionsContainer.addChild(predictedTimeUntilHighPill);
					
					widestPreditctionPill = Math.max(widestPreditctionPill, predictedTimeUntilHighPill.width);
				}
				
				//Time Until Low
				if (!isNaN(predictedTimeUntilLow) && predictedTimeUntilLow != 0)
				{
					if (predictedTimeUntilLowPill != null) predictedTimeUntilLowPill.removeFromParent(true);
					predictedTimeUntilLowPill = new ChartTreatmentPill(ModelLocator.resourceManagerInstance.getString('chartscreen','predicted_time_until_low_label'));
					predictedTimeUntilLowPill.setValue(TimeSpan.formatHoursMinutesFromMinutes(predictedTimeUntilLow / TimeSpan.TIME_1_MINUTE, false));
					predictedTimeUntilLowPill.addEventListener(TouchEvent.TOUCH, onPredictionPillExplanation);
					predictionsContainer.addChild(predictedTimeUntilLowPill);
					
					widestPreditctionPill = Math.max(widestPreditctionPill, predictedTimeUntilLowPill.width);
				}
				
				//Treatments Outcome
				if (!isDexcomFollower)
				{
					var outcome:Number = Forecast.predictOutcome();
					if (!isNaN(outcome))
					{
						//Outcome
						if (predictedTreatmentsOutcomePill != null) predictedTreatmentsOutcomePill.removeFromParent(true);
						predictedTreatmentsOutcomePill = new ChartTreatmentPill(ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_treatments_outcome'));
						predictedTreatmentsOutcomePill.setValue(String(outcome));
						predictedTreatmentsOutcomePill.addEventListener(TouchEvent.TOUCH, onPredictionPillExplanation);
						predictionsContainer.addChild(predictedTreatmentsOutcomePill);
						
						widestPreditctionPill = Math.max(widestPreditctionPill, predictedTreatmentsOutcomePill.width);
						
						//Effect
						var latestReading:BgReading = BgReading.lastWithCalculatedValue();
						if (latestReading != null)
						{
							var effect:Number = outcome - latestReading._calculatedValue;
							
							if (predictedTreatmentsEffectPill != null) predictedTreatmentsEffectPill.removeFromParent(true);
							predictedTreatmentsEffectPill = new ChartTreatmentPill(ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_treatments_effect'));
							predictedTreatmentsEffectPill.setValue(glucoseUnit == "mg/dL" ? MathHelper.formatNumberToStringWithPrefix(Math.round(effect)) : MathHelper.formatNumberToStringWithPrefix(Math.round(BgReading.mgdlToMmol(effect * 10)) / 10));
							predictedTreatmentsEffectPill.addEventListener(TouchEvent.TOUCH, onPredictionPillExplanation);
							predictionsContainer.addChild(predictedTreatmentsEffectPill);
							
							widestPreditctionPill = Math.max(widestPreditctionPill, predictedTreatmentsEffectPill.width);
						}
					}
				}
				
				//Glucose Velocity
				var glucoseVelocity:Number = GlucoseFactory.getGlucoseVelocity();
				if (!isNaN(glucoseVelocity))
				{
					if (glucoseVelocityPill != null) glucoseVelocityPill.removeFromParent(true);
					glucoseVelocityPill = new ChartTreatmentPill(ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_blood_glucose_velocity'));
					glucoseVelocityPill.setValue(MathHelper.formatNumberToStringWithPrefix(glucoseVelocity));
					glucoseVelocityPill.addEventListener(TouchEvent.TOUCH, onPredictionPillExplanation);
					predictionsContainer.addChild(glucoseVelocityPill);
					
					widestPreditctionPill = Math.max(widestPreditctionPill, glucoseVelocityPill.width);
				}
				
				//Minimum BG
				if (!isNaN(predictedMinimumBG))
				{
					if (predictedMinimumBGPill != null) predictedMinimumBGPill.removeFromParent(true);
					predictedMinimumBGPill = new ChartTreatmentPill(ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_minimum_blood_glucose'));
					predictedMinimumBGPill.setValue(glucoseUnit == "mg/dL" ? String(Math.round(predictedMinimumBG)) : String(Math.round(BgReading.mgdlToMmol(predictedMinimumBG * 10)) / 10));
					predictedMinimumBGPill.addEventListener(TouchEvent.TOUCH, onPredictionPillExplanation);
					predictionsContainer.addChild(predictedMinimumBGPill);
					
					widestPreditctionPill = Math.max(widestPreditctionPill, predictedMinimumBGPill.width);
				}
				
				//UAM BG
				if (!isNaN(predictedUAMBG))
				{
					if (predictedUAMBGPill != null) predictedUAMBGPill.removeFromParent(true);
					predictedUAMBGPill = new ChartTreatmentPill(ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_unannounced_glucose_blood_glucose'));
					predictedUAMBGPill.setValue(glucoseUnit == "mg/dL" ? String(Math.round(predictedUAMBG)) : String(Math.round(BgReading.mgdlToMmol(predictedUAMBG * 10)) / 10));
					predictedUAMBGPill.addEventListener(TouchEvent.TOUCH, onPredictionPillExplanation);
					predictionsContainer.addChild(predictedUAMBGPill);
					
					widestPreditctionPill = Math.max(widestPreditctionPill, predictedUAMBGPill.width);
				}
				
				//COB BG
				if (!isNaN(predictedCOBBG) && !isDexcomFollower)
				{
					if (predictedCOBBGPill != null) predictedCOBBGPill.removeFromParent(true);
					predictedCOBBGPill = new ChartTreatmentPill(ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_cob_blood_glucose'));
					predictedCOBBGPill.setValue(glucoseUnit == "mg/dL" ? String(Math.round(predictedCOBBG)) : String(Math.round(BgReading.mgdlToMmol(predictedCOBBG * 10)) / 10));
					predictedCOBBGPill.addEventListener(TouchEvent.TOUCH, onPredictionPillExplanation);
					predictionsContainer.addChild(predictedCOBBGPill);
					
					widestPreditctionPill = Math.max(widestPreditctionPill, predictedCOBBGPill.width);
				}
				
				//IOB BG
				if (!isNaN(predictedIOBBG))
				{
					if (predictedIOBBGPill != null) predictedIOBBGPill.removeFromParent(true);
					predictedIOBBGPill = new ChartTreatmentPill(ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_iob_blood_glucose'));
					predictedIOBBGPill.setValue(glucoseUnit == "mg/dL" ? String(Math.round(predictedIOBBG)) : String(Math.round(BgReading.mgdlToMmol(predictedIOBBG * 10)) / 10));
					predictedIOBBGPill.addEventListener(TouchEvent.TOUCH, onPredictionPillExplanation);
					predictionsContainer.addChild(predictedIOBBGPill);
					
					widestPreditctionPill = Math.max(widestPreditctionPill, predictedIOBBGPill.width);
				}
				
				//Eventual BG
				if (!isNaN(predictedEventualBG))
				{
					if (predictedEventualBGPill != null) predictedEventualBGPill.removeFromParent(true);
					predictedEventualBGPill = new ChartTreatmentPill(ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_eventual_blood_glucose'));
					predictedEventualBGPill.setValue(glucoseUnit == "mg/dL" ? String(Math.round(predictedEventualBG)) : String(Math.round(BgReading.mgdlToMmol(predictedEventualBG * 10)) / 10));
					predictedEventualBGPill.addEventListener(TouchEvent.TOUCH, onPredictionPillExplanation);
					predictionsContainer.addChild(predictedEventualBGPill);
					
					widestPreditctionPill = Math.max(widestPreditctionPill, predictedEventualBGPill.width);
				}
				
				//Carb Impact
				/*if (!isNaN(predictedCarbImpact))
				{
					if (predictedCarbImpactPill != null) predictedCarbImpactPill.removeFromParent(true);
					predictedCarbImpactPill = new ChartTreatmentPill(ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_carb_impact'));
					predictedCarbImpactPill.setValue(glucoseUnit == "mg/dL" ? MathHelper.formatNumberToStringWithPrefix(Math.round(predictedCarbImpact)) : MathHelper.formatNumberToStringWithPrefix(Math.round(BgReading.mgdlToMmol(predictedCarbImpact * 100)) / 100));
					predictedCarbImpactPill.addEventListener(TouchEvent.TOUCH, onPredictionPillExplanation);
					predictionsContainer.addChild(predictedCarbImpactPill);
					
					widestPreditctionPill = Math.max(widestPreditctionPill, predictedCarbImpactPill.width);
				}*/
				
				//BG Impact
				if (!isNaN(predictedBGImpact))
				{
					if (predictedBgImpactPill != null) predictedBgImpactPill.removeFromParent(true);
					predictedBgImpactPill = new ChartTreatmentPill(ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_blood_glucose_impact'));
					predictedBgImpactPill.setValue(glucoseUnit == "mg/dL" ? MathHelper.formatNumberToStringWithPrefix(Math.round(predictedBGImpact)) : MathHelper.formatNumberToStringWithPrefix(Math.round(BgReading.mgdlToMmol(predictedBGImpact * 100)) / 100));
					predictedBgImpactPill.addEventListener(TouchEvent.TOUCH, onPredictionPillExplanation);
					predictionsContainer.addChild(predictedBgImpactPill);
					
					widestPreditctionPill = Math.max(widestPreditctionPill, predictedBgImpactPill.width);
				}
				
				//Predicted Deviation
				if (!isNaN(predictedDeviation))
				{
					if (predictedDeviationPill != null) predictedDeviationPill.removeFromParent(true);
					predictedDeviationPill = new ChartTreatmentPill(ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_deviation'));
					predictedDeviationPill.setValue(glucoseUnit == "mg/dL" ? MathHelper.formatNumberToStringWithPrefix(Math.round(predictedDeviation)) : MathHelper.formatNumberToStringWithPrefix(Math.round(BgReading.mgdlToMmol(predictedDeviation * 100)) / 100));
					predictedDeviationPill.addEventListener(TouchEvent.TOUCH, onPredictionPillExplanation);
					predictionsContainer.addChild(predictedDeviationPill);
					
					widestPreditctionPill = Math.max(widestPreditctionPill, predictedDeviationPill.width);
				}
				
				//Incomplete profile
				if (predictionsIncompleteProfile && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_LOOP_OPENAPS_USER_ENABLED) != "true" && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_GLUCOSE_PREDICTIONS_INCLUDE_IOB_COB) == "true" && !isDexcomFollower)
				{
					if (incompleteProfileWarningLabel != null) incompleteProfileWarningLabel.removeFromParent(true);
					incompleteProfileWarningLabel = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('chartscreen','incomplete_user_profile'), HorizontalAlign.JUSTIFY, VerticalAlign.TOP, 11, true, 0xFF0000);
					incompleteProfileWarningLabel.width = widestPreditctionPill;
					incompleteProfileWarningLabel.wordWrap = true;
					incompleteProfileWarningLabel.paddingBottom = 8;
					
					predictionsContainer.addChildAt(incompleteProfileWarningLabel, 0);
				}
			}
			
			//Final callout size/position adjustments
			predictionsContainer.validate();
			var predictionsCalloutPointOfOrigin:Number = predictionsPill.localToGlobal(new Point(0, 0)).y + predictionsPill.height;
			var predictionsContentOriginalHeight:Number = predictionsContainer.height + 60;
			var suggestedPredictionsCalloutHeight:Number = Constants.stageHeight - predictionsCalloutPointOfOrigin - 5;
			var finalCalloutHeight:Number = predictionsContentOriginalHeight > suggestedPredictionsCalloutHeight ?  suggestedPredictionsCalloutHeight : predictionsContentOriginalHeight;
			
			predictionsCallout.height = finalCalloutHeight;
			predictionsContainer.height = finalCalloutHeight - 50;
			predictionsContainer.maxHeight = finalCalloutHeight - 50;
		}
		
		private function onRefreshExternalPredictions(e:starling.events.Event):void
		{
			if (predictionsCallout != null)
			{
				predictionsCallout.removeFromParent(true);
			}
			
			NightscoutService.getPropertiesV2Endpoint(true);
		}
		
		private function onPredictionsWiki(e:starling.events.Event):void
		{
			navigateToURL(new URLRequest("https://github.com/SpikeApp/Spike/wiki/Glucose-Predictions"));
		}
		
		private function onPredictionsTimeFrameChanged(e:starling.events.Event):void
		{
			if (predictionsLengthPicker != null && predictionsLengthPicker.selectedItem != null && predictionsLengthPicker.selectedItem.id != null)
			{
				predictionsLengthInMinutes = predictionsLengthPicker.selectedItem.id;
				
				if (timelineRange == TIMELINE_1H)
				{
					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_GLUCOSE_PREDICTIONS_MINUTES_FOR_1_HOUR, String(predictionsLengthInMinutes), true, false);
				}
				else if (timelineRange == TIMELINE_3H)
				{
					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_GLUCOSE_PREDICTIONS_MINUTES_FOR_3_HOURS, String(predictionsLengthInMinutes), true, false);
				}
				else if (timelineRange == TIMELINE_6H)
				{
					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_GLUCOSE_PREDICTIONS_MINUTES_FOR_6_HOURS, String(predictionsLengthInMinutes), true, false);
				}
				else if (timelineRange == TIMELINE_12H)
				{
					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_GLUCOSE_PREDICTIONS_MINUTES_FOR_12_HOURS, String(predictionsLengthInMinutes), true, false);
				}
				else if (timelineRange == TIMELINE_24H)
				{
					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_GLUCOSE_PREDICTIONS_MINUTES_FOR_24_HOURS, String(predictionsLengthInMinutes), true, false);
				}
				
				//Dispose all predictions
				disposePredictions();
				
				//Redraw main and scroller charts
				redrawChart(MAIN_CHART, _graphWidth - yAxisMargin, _graphHeight, yAxisMargin, mainChartGlucoseMarkerRadius, 0);
				redrawChart(SCROLLER_CHART, _scrollerWidth - (scrollerChartGlucoseMarkerRadius * 2), _scrollerHeight, 0, scrollerChartGlucoseMarkerRadius, 0);
				
				//Redraw predictions delimitter
				if (predictionsEnabled && predictionsMainGlucoseDataPoints.length > 0 && mainChartGlucoseMarkersList.length > 0)
				{
					if (predictionsDelimiter != null) predictionsDelimiter.removeFromParent(true);
					predictionsDelimiter = GraphLayoutFactory.createVerticalDashedLine(_graphHeight, dashLineWidth, dashLineGap, dashLineThickness, lineColor);
					predictionsDelimiter.y = 0 - predictionsDelimiter.width;
					predictionsDelimiter.x = mainChartGlucoseMarkerRadius + _graphWidth - yAxisMargin + (mainChartGlucoseMarkerRadius * 2) - (mainChart.width - mainChartGlucoseMarkersList[mainChartGlucoseMarkersList.length - 1].x);
					predictionsDelimiter.touchable = false;
					yAxis.addChild(predictionsDelimiter);
					
					activeGlucoseDelimiter = predictionsDelimiter;
				}
				else
				{
					if (predictionsDelimiter != null) predictionsDelimiter.removeFromParent(true);
				}
				
				//Redraw raw markers if needed
				if (displayRaw)
				{
					hideRaw();
					showRaw();
				}
				
				//Adjust Main Chart and Picker Position
				if (displayLatestBGValue)
				{
					mainChart.x = -mainChart.width + _graphWidth - yAxisMargin;
					if (predictionsEnabled && predictionsMainGlucoseDataPoints != null && predictionsMainGlucoseDataPoints.length > 0)
					{
						mainChart.x += mainChartGlucoseMarkerRadius;
					}
					selectedGlucoseMarkerIndex = mainChartGlucoseMarkersList[mainChartGlucoseMarkersList.length - 1].index;
				}
				
				//Redraw timeline
				drawTimeline();
				
				//Reposition treatments
				manageTreatments();
				
				//Timeline
				if (timelineActive && timelineContainer != null)
					timelineContainer.x = mainChart.x;
				
				//Treatments
				if (treatmentsActive && treatmentsContainer != null)
					treatmentsContainer.x = mainChart.x;
				
				//Raw
				if (displayRaw && rawDataContainer != null)
					rawDataContainer.x = mainChart.x;
				
				//Basals
				if (displayPumpBasals || displayMDIBasals)
				{
					renderBasals();
					
					if (basalsContainer != null)
						basalsContainer.x = mainChart.x;
				}
			}
		}
		
		private function onPredictionTimeFramePillUpdated(e:starling.events.Event):void
		{
			if (predictionsCallout != null && predictionsContainer != null)
			{
				predictionsContainer.validate();
				predictionsCallout.invalidate();
				predictionsCallout.validate();
			}
		}
		
		private function onPredictionsTimeFrameOpened(e:starling.events.Event):void
		{
			if (predictionsCallout != null)
			{
				predictionsCallout.closeOnTouchBeganOutside = false;
				predictionsCallout.closeOnTouchEndedOutside = false;
			}
		}
		
		private function onPredictionsTimeFrameClosed(e:starling.events.Event):void
		{
			if (predictionsCallout != null)
			{
				predictionsCallout.closeOnTouchBeganOutside = true;
				predictionsCallout.closeOnTouchEndedOutside = true;
			}
		}
		
		private function onPredictionsCalloutClosed(e:starling.events.Event):void
		{
			if (predictionsCallout != null) predictionsCallout.dispose();
			
			disposePredictionsPills();
		}
		
		private function onPredictionsIOBCOBChanged(e:starling.events.Event):void
		{
			if (predictionsIOBCOBCheck != null)
			{
				//Save new setting to database
				var predictionsIOBCOBEnabled:Boolean = predictionsIOBCOBCheck.isSelected;
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_GLUCOSE_PREDICTIONS_INCLUDE_IOB_COB, String(predictionsIOBCOBEnabled), true, false);
				
				//Redraw Predictions
				redrawPredictions(true);
			}
		}
		
		private function onPredictionsSingleCurveChanged(e:starling.events.Event):void
		{
			if (predictionsIOBCOBCheck != null)
			{
				//Save new setting to database
				singlePredictionCurve = predictionsSingleCurveCheck.isSelected;
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_GLUCOSE_PREDICTIONS_SINGLE_LINE_ENABLED, String(singlePredictionCurve), true, false);
				
				//Redraw Predictions
				redrawPredictions();
			}
		}
		
		private function onPredictionsSwitchChanged(e:starling.events.Event):void
		{
			//Update internal variables
			predictionsEnabled = predictionsEnableSwitch.isSelected;
			
			//Update Database
			CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_GLUCOSE_PREDICTIONS_ENABLED, String(predictionsEnabled), true, false);
			
			//Redraw the predictions callout
			if (predictionsCallout != null)
				predictionsCallout.close(true);
			
			refreshPredictionsCallout();
			
			//Dispose all predictions
			disposePredictions();
			disposePredictionsHeader();
			
			//Redraw main and scroller chart
			if (!predictionsEnabled)
			{
				//Redraw predictions pill
				predictionsPill.isPredictive = false;
				predictionsPill.setValue(ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_off_label'), ModelLocator.resourceManagerInstance.getString('chartscreen','predictions_small_abbreviation_chart_pill_title'));
				repositionTreatmentPills();
				
				//Dispose predictions chart delimiter
				if (predictionsDelimiter != null)
				{
					predictionsDelimiter.removeFromParent();
					predictionsDelimiter.dispose();
					predictionsDelimiter = null;
					activeGlucoseDelimiter = glucoseDelimiter;
				}
				
				//Reset chart/scroller positions
				if (handPicker != null && mainChart != null)
				{
					handPicker.x = _graphWidth - handPicker.width;
					mainChart.x = -mainChart.width + _graphWidth - yAxisMargin;
					selectedGlucoseMarkerIndex = mainChartGlucoseMarkersList[mainChartGlucoseMarkersList.length - 1].index;
					displayLatestBGValue = true;
					
					calculateDisplayLabels();
				}
				
				//Redraw main chart
				var lastMainGlucoseMarker:GlucoseMarker = mainChartGlucoseMarkersList.pop();
				if (lastMainGlucoseMarker != null)
				{
					lastMainGlucoseMarker.removeFromParent();
					lastMainGlucoseMarker.dispose();
					lastMainGlucoseMarker = null;
				}
				redrawChart(MAIN_CHART, _graphWidth - yAxisMargin, _graphHeight, yAxisMargin, mainChartGlucoseMarkerRadius, 1);
				
				//Redraw scroller chart
				var lastScrollerGlucoseMarker:GlucoseMarker = scrollChartGlucoseMarkersList.pop();
				if (lastScrollerGlucoseMarker != null)
				{
					lastScrollerGlucoseMarker.removeFromParent();
					lastScrollerGlucoseMarker.dispose();
					lastScrollerGlucoseMarker = null;
				}
				redrawChart(SCROLLER_CHART, _scrollerWidth - (scrollerChartGlucoseMarkerRadius * 2), _scrollerHeight, 0, scrollerChartGlucoseMarkerRadius, 1);
			}
			else
			{
				//Adjust predictions pill
				predictionsPill.isPredictive = true;
				
				//Redraw main and scroller charts
				redrawChart(MAIN_CHART, _graphWidth - yAxisMargin, _graphHeight, yAxisMargin, mainChartGlucoseMarkerRadius, 0);
				redrawChart(SCROLLER_CHART, _scrollerWidth - (scrollerChartGlucoseMarkerRadius * 2), _scrollerHeight, 0, scrollerChartGlucoseMarkerRadius, 0);
				
				//Redraw predictions delimitter
				if (predictionsEnabled && predictionsMainGlucoseDataPoints.length > 0 && mainChartGlucoseMarkersList.length > 0)
				{
					if (predictionsDelimiter != null) predictionsDelimiter.removeFromParent(true);
					predictionsDelimiter = GraphLayoutFactory.createVerticalDashedLine(_graphHeight, dashLineWidth, dashLineGap, dashLineThickness, lineColor);
					predictionsDelimiter.y = 0 - predictionsDelimiter.width;
					predictionsDelimiter.x = mainChartGlucoseMarkerRadius + _graphWidth - yAxisMargin + (mainChartGlucoseMarkerRadius * 2) - (mainChart.width - mainChartGlucoseMarkersList[mainChartGlucoseMarkersList.length - 1].x);
					predictionsDelimiter.touchable = false;
					yAxis.addChild(predictionsDelimiter);
					
					activeGlucoseDelimiter = predictionsDelimiter;
				}
				else
				{
					if (predictionsDelimiter != null) predictionsDelimiter.removeFromParent(true);
				}
			}
			
			//Redraw raw markers if needed
			if (displayRaw)
			{
				hideRaw();
				showRaw();
			}
			
			//Adjust Main Chart and Picker Position
			if (displayLatestBGValue)
			{
				mainChart.x = -mainChart.width + _graphWidth - yAxisMargin;
				if (predictionsEnabled && predictionsMainGlucoseDataPoints != null && predictionsMainGlucoseDataPoints.length > 0)
				{
					mainChart.x += mainChartGlucoseMarkerRadius;
				}
				selectedGlucoseMarkerIndex = mainChartGlucoseMarkersList[mainChartGlucoseMarkersList.length - 1].index;
			}
			
			//Redraw timeline
			drawTimeline();
			
			//Reposition treatments
			manageTreatments();
			
			//Timeline
			if (timelineActive && timelineContainer != null)
				timelineContainer.x = mainChart.x;
			
			//Treatments
			if (treatmentsActive && treatmentsContainer != null)
				treatmentsContainer.x = mainChart.x;
			
			//Raw
			if (displayRaw && rawDataContainer != null)
				rawDataContainer.x = mainChart.x;
			
			//Basals
			if (displayPumpBasals || displayMDIBasals)
			{
				renderBasals();
				
				if (basalsContainer != null)
					basalsContainer.x = mainChart.x;
			}
		}
		
		private function onAPSPredictionRetrieved(e:PredictionEvent):void
		{
			if (!SystemUtil.isApplicationActive || dummyModeActive)
				return;
			
			redrawPredictions(false, true);
			
			var now:Number = new Date().valueOf();
			if (displayIOBEnabled)
				calculateTotalIOB(now);
			if (displayCOBEnabled)
				calculateTotalCOB(now);
		}
		
		private function onPredictionMarkerTouched(e:TouchEvent):void
		{
			var targetMarker:GlucoseMarker;
			var touch:Touch = e.getTouch(stage);
			
			if (touch != null && touch.phase == TouchPhase.BEGAN)
			{
				targetMarker = e.currentTarget as GlucoseMarker;
				if (targetMarker != null && targetMarker.bgReading != null)
				{
					targetMarker.filter = new GlowFilter(targetMarker.bgReading.rawData, 7, 2.4, 1);
					
					if (_displayLine)
					{
						targetMarker.x += targetMarker.width / 6;
						targetMarker.alpha = 1;
					}
					
					displayPredictionDetailCallout(targetMarker);
				}
			}
			else if (touch != null && touch.phase == TouchPhase.ENDED)
			{
				targetMarker = e.currentTarget as GlucoseMarker;
				if (targetMarker != null)
				{
					targetMarker.filter = null;
					if (_displayLine)
					{
						targetMarker.alpha = 0;
						targetMarker.x -= targetMarker.width / 6;
					}
					
					disposePredictionDetailCallout();
				}
			}
		}
		
		private function displayPredictionDetailCallout(marker:GlucoseMarker):void
		{
			disposePredictionDetailCallout();
			
			predictionDetailMainContainer = LayoutFactory.createLayoutGroup("vertical", HorizontalAlign.LEFT, VerticalAlign.TOP, 3);
			
			//Curve
			predictionDetailCurveContainer = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.LEFT, VerticalAlign.TOP);
			predictionDetailMainContainer.addChild(predictionDetailCurveContainer);
			
			var curve:String = marker.bgReading.uniqueId;
			if (curve == "UAM")
			{
				curve = "UAG";
			}
			else if (curve == "ZTM")
			{
				curve = "ZT";
			}
			
			predictionDetailCurveTitle = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('chartscreen','curve_label') + ": ", HorizontalAlign.LEFT, VerticalAlign.TOP, 14, true);
			predictionDetailCurveContainer.addChild(predictionDetailCurveTitle);
			predictionDetailCurveBody = LayoutFactory.createLabel(curve, HorizontalAlign.LEFT, VerticalAlign.TOP, 14, false);
			predictionDetailCurveContainer.addChild(predictionDetailCurveBody);
			
			//BG
			predictionDetailBGContainer = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.LEFT, VerticalAlign.TOP);
			predictionDetailMainContainer.addChild(predictionDetailBGContainer);
			
			predictionDetailBGTitle = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('chartscreen','blood_glucose') + ": ", HorizontalAlign.LEFT, VerticalAlign.TOP, 14, true);
			predictionDetailBGContainer.addChild(predictionDetailBGTitle);
			predictionDetailBGBody = LayoutFactory.createLabel(glucoseUnit == "mg/dL" ? String(Math.round(marker.bgReading._calculatedValue)) : String(  Math.round(BgReading.mgdlToMmol(marker.bgReading._calculatedValue) * 10) / 10  ), HorizontalAlign.LEFT, VerticalAlign.TOP, 14, false);
			predictionDetailBGContainer.addChild(predictionDetailBGBody);
			
			//Time
			var dateFormat:String = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_DATE_FORMAT);
			var markerDate:Date = new Date(marker.bgReading.timestamp);
			
			predictionDetailTimeContainer = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.LEFT, VerticalAlign.TOP);
			predictionDetailMainContainer.addChild(predictionDetailTimeContainer);
			
			predictionDetailTimeTitle = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('chartscreen','prediction_time_hours_minutes') + ": ", HorizontalAlign.LEFT, VerticalAlign.TOP, 14, true);
			predictionDetailTimeContainer.addChild(predictionDetailTimeTitle);
			predictionDetailTimeBody = LayoutFactory.createLabel(dateFormat.slice(0,2) == "24" ? TimeSpan.formatHoursMinutes(markerDate.getHours(), markerDate.getMinutes(), TimeSpan.TIME_FORMAT_24H) : TimeSpan.formatHoursMinutes(markerDate.getHours(), markerDate.getMinutes(), TimeSpan.TIME_FORMAT_12H), HorizontalAlign.LEFT, VerticalAlign.TOP, 14, false);
			predictionDetailTimeContainer.addChild(predictionDetailTimeBody);
			
			//Callout
			predictionDetailCallout = Callout.show(predictionDetailMainContainer, marker, new <String>[RelativePosition.TOP]);
			predictionDetailCallout.validate();
			predictionDetailCallout.y += mainChartGlucoseMarkerRadius;
		}
		
		private function disposePredictionDetailCallout():void
		{
			//Curve
			if (predictionDetailCurveTitle != null)
			{
				predictionDetailCurveTitle.removeFromParent(true);
				predictionDetailCurveTitle = null;
			}
			
			if (predictionDetailCurveBody != null)
			{
				predictionDetailCurveBody.removeFromParent(true);
				predictionDetailCurveBody = null;
			}
			
			if (predictionDetailCurveContainer != null)
			{
				predictionDetailCurveContainer.removeFromParent(true);
				predictionDetailCurveContainer = null;
			}
			
			//BG
			if (predictionDetailBGTitle != null)
			{
				predictionDetailBGTitle.removeFromParent(true);
				predictionDetailBGTitle = null;
			}
			
			if (predictionDetailBGBody != null)
			{
				predictionDetailBGBody.removeFromParent(true);
				predictionDetailBGBody = null;
			}
			
			if (predictionDetailBGContainer != null)
			{
				predictionDetailBGContainer.removeFromParent(true);
				predictionDetailBGContainer = null;
			}
			
			//Time
			if (predictionDetailTimeTitle != null)
			{
				predictionDetailTimeTitle.removeFromParent(true);
				predictionDetailTimeTitle = null;
			}
			
			if (predictionDetailTimeBody != null)
			{
				predictionDetailTimeBody.removeFromParent(true);
				predictionDetailTimeBody = null;
			}
			
			if (predictionDetailTimeContainer != null)
			{
				predictionDetailTimeContainer.removeFromParent(true);
				predictionDetailTimeContainer = null;
			}
			
			//Main container
			if (predictionDetailMainContainer != null)
			{
				predictionDetailMainContainer.removeFromParent(true);
				predictionDetailMainContainer = null;
			}
			
			//Callout
			if (predictionDetailCallout != null)
			{
				predictionDetailCallout.removeFromParent(true);
				predictionDetailCallout = null;
			}
		}
		
		private function disposePredictionsPills():void
		{
			if (lastPredictionUpdateTimePill != null)
			{
				lastPredictionUpdateTimePill.removeEventListener(TouchEvent.TOUCH, onPredictionPillExplanation);
				lastPredictionUpdateTimePill.removeFromParent();
				lastPredictionUpdateTimePill.dispose();
				lastPredictionUpdateTimePill = null;
			}
			
			if (predictedEventualBGPill != null)
			{
				predictedEventualBGPill.removeEventListener(TouchEvent.TOUCH, onPredictionPillExplanation);
				predictedEventualBGPill.removeFromParent();
				predictedEventualBGPill.dispose();
				predictedEventualBGPill = null;
			}
			
			if (predictedUAMBGPill != null)
			{
				predictedUAMBGPill.removeEventListener(TouchEvent.TOUCH, onPredictionPillExplanation);
				predictedUAMBGPill.removeFromParent();
				predictedUAMBGPill.dispose();
				predictedUAMBGPill = null;
			}
			
			if (predictedIOBBGPill != null)
			{
				predictedIOBBGPill.removeEventListener(TouchEvent.TOUCH, onPredictionPillExplanation);
				predictedIOBBGPill.removeFromParent();
				predictedIOBBGPill.dispose();
				predictedIOBBGPill = null;
			}
			
			if (predictedCOBBGPill != null)
			{
				predictedCOBBGPill.removeEventListener(TouchEvent.TOUCH, onPredictionPillExplanation);
				predictedCOBBGPill.removeFromParent();
				predictedCOBBGPill.dispose();
				predictedCOBBGPill = null;
			}
			
			if (predictedMinimumBGPill != null)
			{
				predictedMinimumBGPill.removeEventListener(TouchEvent.TOUCH, onPredictionPillExplanation);
				predictedMinimumBGPill.removeFromParent();
				predictedMinimumBGPill.dispose();
				predictedMinimumBGPill = null;
			}
			
			if (predictedTreatmentsOutcomePill != null)
			{
				predictedTreatmentsOutcomePill.removeEventListener(TouchEvent.TOUCH, onPredictionPillExplanation);
				predictedTreatmentsOutcomePill.removeFromParent();
				predictedTreatmentsOutcomePill.dispose();
				predictedTreatmentsOutcomePill = null;
			}
			
			if (predictedTreatmentsEffectPill != null)
			{
				predictedTreatmentsEffectPill.removeEventListener(TouchEvent.TOUCH, onPredictionPillExplanation);
				predictedTreatmentsEffectPill.removeFromParent();
				predictedTreatmentsEffectPill.dispose();
				predictedTreatmentsEffectPill = null;
			}
			
			if (predictedBgImpactPill != null)
			{
				predictedBgImpactPill.removeEventListener(TouchEvent.TOUCH, onPredictionPillExplanation);
				predictedBgImpactPill.removeFromParent();
				predictedBgImpactPill.dispose();
				predictedBgImpactPill = null;
			}
			
			if (predictedDeviationPill != null)
			{
				predictedDeviationPill.removeEventListener(TouchEvent.TOUCH, onPredictionPillExplanation);
				predictedDeviationPill.removeFromParent();
				predictedDeviationPill.dispose();
				predictedDeviationPill = null;
			}
			
			if (glucoseVelocityPill != null)
			{
				glucoseVelocityPill.removeEventListener(TouchEvent.TOUCH, onPredictionPillExplanation);
				glucoseVelocityPill.removeFromParent();
				glucoseVelocityPill.dispose();
				glucoseVelocityPill = null;
			}
			
			if (predictedCarbImpactPill != null)
			{
				predictedCarbImpactPill.removeEventListener(TouchEvent.TOUCH, onPredictionPillExplanation);
				predictedCarbImpactPill.removeFromParent();
				predictedCarbImpactPill.dispose();
				predictedCarbImpactPill = null;
			}
			
			if (predictedTimeUntilHighPill != null)
			{
				predictedTimeUntilHighPill.removeEventListener(TouchEvent.TOUCH, onPredictionPillExplanation);
				predictedTimeUntilHighPill.removeFromParent();
				predictedTimeUntilHighPill.dispose();
				predictedTimeUntilHighPill = null;
			}
			
			if (predictedTimeUntilLowPill != null)
			{
				predictedTimeUntilLowPill.removeEventListener(TouchEvent.TOUCH, onPredictionPillExplanation);
				predictedTimeUntilLowPill.removeFromParent();
				predictedTimeUntilLowPill.dispose();
				predictedTimeUntilLowPill = null;
			}
			
			if (predictionsEnableSwitch != null)
			{
				predictionsEnableSwitch.removeEventListener(starling.events.Event.CHANGE, onPredictionsSwitchChanged);
				predictionsEnableSwitch.removeFromParent();
				predictionsEnableSwitch.dispose();
				predictionsEnableSwitch = null;
			}
			
			if (predictionsEnablerPill != null)
			{
				if (predictionsEnablerPill.pillBackground != null)
				{
					predictionsEnablerPill.pillBackground.removeEventListener(TouchEvent.TOUCH, onPredictionPillExplanation);
				}
				
				if (predictionsEnablerPill.titleLabel != null)
				{
					predictionsEnablerPill.titleLabel.removeEventListener(TouchEvent.TOUCH, onPredictionPillExplanation);
				}
				
				predictionsEnablerPill.removeFromParent();
				predictionsEnablerPill.dispose();
				predictionsEnablerPill = null;
			}
			
			if (wikiPredictionsButton != null)
			{
				if (wikiPredictionsIcon != null)
				{
					if (wikiPredictionsIcon.texture != null)
					{
						wikiPredictionsIcon.texture.dispose();
					}
					
					wikiPredictionsIcon.removeFromParent();
					wikiPredictionsIcon.dispose();
					wikiPredictionsIcon = null;
				}
				
				wikiPredictionsButton.removeEventListener(starling.events.Event.TRIGGERED, onRefreshExternalPredictions);
				wikiPredictionsButton.removeFromParent();
				wikiPredictionsButton.dispose();
				wikiPredictionsButton = null;
			}
			
			if (wikiPredictionsPill != null)
			{
				if (wikiPredictionsPill.pillBackground != null)
				{
					wikiPredictionsPill.pillBackground.removeEventListener(TouchEvent.TOUCH, onPredictionPillExplanation);
				}
				
				if (wikiPredictionsPill.titleLabel != null)
				{
					wikiPredictionsPill.titleLabel.removeEventListener(TouchEvent.TOUCH, onPredictionPillExplanation);
				}
				
				wikiPredictionsPill.removeFromParent();
				wikiPredictionsPill.dispose();
				wikiPredictionsPill = null;
			}
			
			if (predictionsLengthPicker != null)
			{
				predictionsLengthPicker.removeEventListener(starling.events.Event.CHANGE, onPredictionsTimeFrameChanged);
				predictionsLengthPicker.removeEventListener(starling.events.Event.OPEN, onPredictionsTimeFrameOpened);
				predictionsLengthPicker.removeEventListener(starling.events.Event.CLOSE, onPredictionsTimeFrameClosed);
				predictionsLengthPicker.removeEventListeners();
				predictionsLengthPicker.removeFromParent();
				predictionsLengthPicker.dispose();
				predictionsLengthPicker = null;
			}
			
			if (predictionsTimeFramePill != null)
			{
				if (predictionsTimeFramePill.pillBackground != null)
				{
					predictionsTimeFramePill.pillBackground.removeEventListener(TouchEvent.TOUCH, onPredictionPillExplanation);
				}
				
				if (predictionsTimeFramePill.titleLabel != null)
				{
					predictionsTimeFramePill.titleLabel.removeEventListener(TouchEvent.TOUCH, onPredictionPillExplanation);
				}
				
				predictionsTimeFramePill.removeEventListener(starling.events.Event.UPDATE, onPredictionTimeFramePillUpdated);
				predictionsTimeFramePill.removeFromParent();
				predictionsTimeFramePill.dispose();
				predictionsTimeFramePill = null;
			}
			
			if (predictionsIOBCOBCheck != null)
			{
				predictionsIOBCOBCheck.removeEventListener(starling.events.Event.CHANGE, onPredictionsIOBCOBChanged);
				predictionsIOBCOBCheck.removeFromParent();
				predictionsIOBCOBCheck.dispose();
				predictionsIOBCOBCheck = null;
			}
			
			if (predictionsIOBCOBPill != null)
			{
				if (predictionsIOBCOBPill.pillBackground != null)
				{
					predictionsIOBCOBPill.pillBackground.removeEventListener(TouchEvent.TOUCH, onPredictionPillExplanation);
				}
				
				if (predictionsIOBCOBPill.titleLabel != null)
				{
					predictionsIOBCOBPill.titleLabel.removeEventListener(TouchEvent.TOUCH, onPredictionPillExplanation);
				}
				
				predictionsIOBCOBPill.removeFromParent();
				predictionsIOBCOBPill.dispose();
				predictionsIOBCOBPill = null;
			}
			
			if (refreshExternalPredictionsButton != null)
			{
				if (refreshPredictionsIcon != null)
				{
					if (refreshPredictionsIcon.texture != null)
					{
						refreshPredictionsIcon.texture.dispose();
					}
					
					refreshPredictionsIcon.removeFromParent();
					refreshPredictionsIcon.dispose();
					refreshPredictionsIcon = null;
				}
				
				refreshExternalPredictionsButton.removeEventListener(starling.events.Event.TRIGGERED, onRefreshExternalPredictions);
				refreshExternalPredictionsButton.removeFromParent();
				refreshExternalPredictionsButton.dispose();
				refreshExternalPredictionsButton = null;
			}
			
			if (predictionsExternalRefreshPill != null)
			{
				if (predictionsExternalRefreshPill.pillBackground != null)
				{
					predictionsExternalRefreshPill.pillBackground.removeEventListener(TouchEvent.TOUCH, onPredictionPillExplanation);
				}
				
				if (predictionsExternalRefreshPill.titleLabel != null)
				{
					predictionsExternalRefreshPill.titleLabel.removeEventListener(TouchEvent.TOUCH, onPredictionPillExplanation);
				}
				
				predictionsExternalRefreshPill.removeFromParent();
				predictionsExternalRefreshPill.dispose();
				predictionsExternalRefreshPill = null;
			}
			
			if (predictionsSingleCurveCheck != null)
			{
				predictionsSingleCurveCheck.removeEventListener(starling.events.Event.CHANGE, onPredictionsSingleCurveChanged);
				predictionsSingleCurveCheck.removeFromParent();
				predictionsSingleCurveCheck.dispose();
				predictionsSingleCurveCheck = null;
			}
			
			if (predictionsSingleCurvePill != null)
			{
				if (predictionsSingleCurvePill.pillBackground != null)
				{
					predictionsSingleCurvePill.pillBackground.removeEventListener(TouchEvent.TOUCH, onPredictionPillExplanation);
				}
				
				if (predictionsSingleCurvePill.titleLabel != null)
				{
					predictionsSingleCurvePill.titleLabel.removeEventListener(TouchEvent.TOUCH, onPredictionPillExplanation);
				}
				
				predictionsSingleCurvePill.removeFromParent();
				predictionsSingleCurvePill.dispose();
				predictionsSingleCurvePill = null;
			}
			
			if (incompleteProfileWarningLabel != null)
			{
				incompleteProfileWarningLabel.removeFromParent();
				incompleteProfileWarningLabel.dispose();
				incompleteProfileWarningLabel = null;
			}
			
			if (predictionsContainer != null)
			{
				predictionsContainer.removeFromParent();
				predictionsContainer.dispose();
				predictionsContainer = null;
			}
			
			if (predictionsCallout != null)
			{
				predictionsCallout.removeFromParent();
				predictionsCallout.dispose();
				predictionsCallout = null;
			}
			
			clearTimeout(predictionsCalloutTimeout);
		}
		
		private function disposePredictions():void
		{
			disposePredictionDetailCallout();
			
			var i:int;
			var glucoseMarker:GlucoseMarker;
			
			var mainPredictionsLength:int = predictionsMainGlucoseDataPoints.length;
			for (i = 0; i < mainPredictionsLength; i++) 
			{
				glucoseMarker = predictionsMainGlucoseDataPoints[i];
				glucoseMarker.removeEventListener(TouchEvent.TOUCH, onPredictionMarkerTouched);
				glucoseMarker.removeFromParent();
				if (glucoseMarker.filter != null)
					glucoseMarker.filter.dispose();
				glucoseMarker.dispose();
				glucoseMarker = null;
			}
			
			var scrollerPredictionsLength:int = predictionsScrollerGlucoseDataPoints.length;
			for (i = 0; i < scrollerPredictionsLength; i++) 
			{
				glucoseMarker = predictionsScrollerGlucoseDataPoints[i];
				glucoseMarker.removeFromParent();
				if (glucoseMarker.filter != null)
					glucoseMarker.filter.dispose();
				glucoseMarker.dispose();
				glucoseMarker = null;
			}
			
			predictionsMainGlucoseDataPoints.length = 0;
			predictionsScrollerGlucoseDataPoints.length = 0;
		}
		
		/**
		 * Raw Data
		 */
		public function showRaw():void
		{
			displayRaw = true;
			
			if (!SystemUtil.isApplicationActive || dummyModeActive) 
				return;
			
			var chartIndex:int = mainChartContainer.getChildIndex(mainChart);
			if (chartIndex != -1)
			{
				rawDataContainer = drawChart(MAIN_CHART, _graphWidth - yAxisMargin, _graphHeight, yAxisMargin, mainChartGlucoseMarkerRadius/2, true);
				rawDataContainer.touchable = false;
				rawDataContainer.x = mainChart.x;
				mainChartContainer.addChildAt(rawDataContainer, chartIndex + 1);
			}
		}
		
		public function hideRaw():void
		{
			displayRaw = false;
			
			if (!SystemUtil.isApplicationActive || dummyModeActive) 
				return;
			
			if(rawDataContainer != null)
			{
				rawDataContainer.dispose();
				rawDataContainer = null;
			}
		}
		
		public function showLine():void
		{
			if (!SystemUtil.isApplicationActive || dummyModeActive)
				return;
			
			if(_displayLine == false)
			{
				_displayLine = true;
				
				//Destroy previous lines
				destroyAllLines();
				
				//Draw Lines
				drawLine(MAIN_CHART);
				drawLine(SCROLLER_CHART);
			}
		}
		
		public function hideLine():void
		{
			if (!SystemUtil.isApplicationActive || dummyModeActive)
				return;
			
			if(_displayLine == true)
			{
				_displayLine = false;
				
				//Destroy previous lines
				destroyAllLines();
				
				//Hide Lines / Show dots
				disposeLine(MAIN_CHART);
				disposeLine(SCROLLER_CHART);
			}
		}
		
		private function drawLine(chartType:String):void 
		{
			if (!SystemUtil.isApplicationActive)
				return;
			
			var line:SpikeLine = new SpikeLine();
			line.touchable = false;
			
			if(chartType == MAIN_CHART)
			{
				if (mainChartLine != null) mainChartLine.removeFromParent(true);
				mainChartLine = line;
			}
			else if (chartType == SCROLLER_CHART)
			{
				if (scrollerChartLine != null) scrollerChartLine.removeFromParent(true);
				scrollerChartLine = line;
			}
			
			//Define what chart needs line to be drawns
			var sourceList:Array;
			var realReadingsLength:int = 0;
			var numberOfPredictiveReadings:int = 0;
			
			if(chartType == MAIN_CHART)
			{
				sourceList = mainChartGlucoseMarkersList;
				if (predictionsEnabled && predictionsMainGlucoseDataPoints != null && sourceList != null)
				{
					realReadingsLength = sourceList.length;
					
					var predictiveMainReadingsLength:int = predictionsMainGlucoseDataPoints.length;
					if (predictiveMainReadingsLength > 0)
					{
						sourceList = sourceList.concat(predictionsMainGlucoseDataPoints);
						numberOfPredictiveReadings = predictiveMainReadingsLength;
					}
				}
			}
			else if (chartType == SCROLLER_CHART)
			{
				sourceList = scrollChartGlucoseMarkersList;
				if (predictionsEnabled && predictionsScrollerGlucoseDataPoints != null && sourceList != null)
				{
					realReadingsLength = sourceList.length;
					
					var predictiveScrollerReadingsLength:int = predictionsScrollerGlucoseDataPoints.length;
					if (predictiveScrollerReadingsLength > 0)
					{
						sourceList = sourceList.concat(predictionsScrollerGlucoseDataPoints);
						numberOfPredictiveReadings = predictiveScrollerReadingsLength;
					}
				}
			}
			
			if (sourceList == null || sourceList.length == 0)
				return;
			
			//Loop all markers, draw the line from their positions and also hide the markers
			var extraEndLineColor:uint;
			var doublePrevGlucoseMarker:GlucoseMarker;
			var previousLineX:Number;
			var previousLineY:Number;
			var previousGlucoseMarker:GlucoseMarker;
			var lastRealGlucoseMarker:GlucoseMarker;
			var dataLength:int = sourceList.length;
			for (var i:int = 0; i < dataLength; i++) 
			{
				var isPrediction:Boolean = i >= realReadingsLength && predictionsEnabled;
				var index:int = !isPrediction ? i : i - realReadingsLength;
				
				var glucoseMarker:GlucoseMarker = sourceList[i];
				if (glucoseMarker == null || glucoseMarker.bgReading == null || (glucoseMarker.bgReading.sensor == null && !CGMBlueToothDevice.isFollower() && !isPrediction))
					continue;
				
				if (isPrediction && chartType == MAIN_CHART)
				{
					glucoseMarker.removeHitArea();
				}
				
				var newPredictionSet:Boolean = isPrediction && previousGlucoseMarker != null && previousGlucoseMarker.bgReading.uniqueId.length == 3 && glucoseMarker.bgReading.uniqueId.length == 3 && previousGlucoseMarker.bgReading.uniqueId != glucoseMarker.bgReading.uniqueId;
				
				if (!isPrediction && i == realReadingsLength - 1)
				{
					lastRealGlucoseMarker = glucoseMarker;
				}
				
				if(i == 0)
				{
					line.moveTo(glucoseMarker.x, glucoseMarker.y + (glucoseMarker.height/2));
				}
				else
				{
					var currentLineX:Number;
					var currentLineY:Number;
					
					if((i < dataLength -1 || isPrediction) && i != realReadingsLength - 1)
					{
						currentLineX = glucoseMarker.x + (glucoseMarker.width/2);
						currentLineY = glucoseMarker.y + (glucoseMarker.height/2);
					}
					else if (i == dataLength -1 || i == realReadingsLength - 1)
					{
						currentLineX = glucoseMarker.x + (glucoseMarker.width);
						currentLineY = glucoseMarker.y + (glucoseMarker.height/2);
						if (previousGlucoseMarker != null)
						{
							currentLineY += (glucoseMarker.y - previousGlucoseMarker.y) / 3;
						}
					}
					
					//Style
					line.lineStyle(chartType == SCROLLER_CHART && glucoseLineThickness > 1 ? glucoseLineThickness / 2 : glucoseLineThickness, glucoseMarker.color, 1);
					var currentColor:uint = glucoseMarker.color
					var previousColor:uint;
					
					//Determine if missed readings are bigger than the acceptable gap. If so, the line will be gray;
					if (previousGlucoseMarker != null && glucoseMarker != null)
					{
						var elapsedMinutes:Number = TimeSpan.fromDates(new Date(previousGlucoseMarker.timestamp), new Date(glucoseMarker.timestamp)).minutes;
						if (elapsedMinutes > NUM_MINUTES_MISSED_READING_GAP)
						{
							currentColor = oldColor;
							previousColor = oldColor;
						}
						else
							previousColor = previousGlucoseMarker.color;
					}
					
					if (newPredictionSet)
					{
						//Add extra line to the beginning
						/*if (lastRealGlucoseMarker != null)
						{
							line.moveTo(lastRealGlucoseMarker.x + lastRealGlucoseMarker.width, lastRealGlucoseMarker.y + (lastRealGlucoseMarker.height / 2));
							line.lineTo(currentLineX, currentLineY, lastRealGlucoseMarker.color, glucoseMarker.color);
						}*/
						
						//Add extra line to the end
						if (previousGlucoseMarker != null)
						{
							if (chartType == MAIN_CHART && isPrediction) previousGlucoseMarker.removeHitArea();
							
							var extraSetPredictionLineX:Number = previousGlucoseMarker.x + previousGlucoseMarker.width;
							var extraSetPredictionLineY:Number = previousGlucoseMarker.y + (previousGlucoseMarker.height / 2);
							extraEndLineColor = previousGlucoseMarker.color;
							doublePrevGlucoseMarker = sourceList[i - 2];
							if (doublePrevGlucoseMarker != null)
							{
								extraEndLineColor = doublePrevGlucoseMarker.color;
							}
							
							//Try to calculate y direction of previous line by fetching 2 previous glucose markers
							var targetGlucoseMarker:GlucoseMarker;
							if(chartType == MAIN_CHART && index - 2 > 0)
							{
								targetGlucoseMarker = predictionsMainGlucoseDataPoints[index - 2];
							}
							else if (chartType == SCROLLER_CHART && index - 2 > 0)
							{
								targetGlucoseMarker = predictionsScrollerGlucoseDataPoints[index - 2];
							}
							
							//Marker found, add y difference
							if (targetGlucoseMarker != null)
							{
								if (chartType == MAIN_CHART && isPrediction) 
								{
									targetGlucoseMarker.removeHitArea();
								}
								
								line.moveTo(extraSetPredictionLineX, extraSetPredictionLineY + ((previousGlucoseMarker.y - targetGlucoseMarker.y) / 3));
								
								if (chartType == MAIN_CHART && isPrediction) 
								{
									targetGlucoseMarker.addHitArea();
								}
							}
							else
							{
								line.moveTo(extraSetPredictionLineX, extraSetPredictionLineY);
							}
							
							line.lineTo(extraSetPredictionLineX - (previousGlucoseMarker.width / 2), extraSetPredictionLineY, extraEndLineColor, extraEndLineColor);
							
							if (chartType == MAIN_CHART && isPrediction) targetGlucoseMarker.addHitArea();
						}
					}
					
					if ((isNaN(previousColor) || isPrediction) && index != 0)
					{
						if (!isPrediction)
						{
							line.lineTo(currentLineX, currentLineY);
						}
						else
						{
							if (previousGlucoseMarker.bgReading.uniqueId == glucoseMarker.bgReading.uniqueId && !newPredictionSet)
							{
								line.lineTo((currentLineX + previousLineX) / 2, (currentLineY + previousLineY) / 2);
							}
						}
					}
					else
					{
						if (!isPrediction && !index == 0)
						{
							line.lineTo(currentLineX, currentLineY, previousColor, currentColor);
						}
					}
					
					line.moveTo(currentLineX, currentLineY);
					
					previousLineX = currentLineX;
					previousLineY = currentLineY;
				}
				//Hide glucose marker
				glucoseMarker.alpha = 0;
				
				if (i < dataLength - 1)
				{
					previousGlucoseMarker = glucoseMarker;
					if (isPrediction && chartType == MAIN_CHART)
					{
						glucoseMarker.addHitArea();
					}
				}
			}
			
			//Predictions line fix
			if (glucoseMarker != null && previousGlucoseMarker != null && _displayLine && glucoseMarker.bgReading != null && glucoseMarker.bgReading._calculatedValue != 0 && (glucoseMarker.bgReading.sensor != null || CGMBlueToothDevice.isFollower() || isPrediction) && glucoseMarker.glucoseValue >= lowestGlucoseValue && glucoseMarker.glucoseValue <= highestGlucoseValue && predictionsEnabled && numberOfPredictiveReadings > 0)
			{
				//Add an extra line
				var extraPredictionLineX:Number = glucoseMarker.x + glucoseMarker.width;
				var extraPredictionLineY:Number = glucoseMarker.y + (glucoseMarker.height / 2);
				extraEndLineColor = previousGlucoseMarker.color;
				doublePrevGlucoseMarker = sourceList[i - 2];
				if (doublePrevGlucoseMarker != null)
				{
					extraEndLineColor = doublePrevGlucoseMarker.color;
				}
				if (chartType == MAIN_CHART && isPrediction) previousGlucoseMarker.removeHitArea();
				line.moveTo(extraPredictionLineX, extraPredictionLineY + ((glucoseMarker.y - previousGlucoseMarker.y) / 3));
				line.lineTo(extraPredictionLineX - (glucoseMarker.width / 2), extraPredictionLineY, extraEndLineColor, extraEndLineColor);
				if (chartType == MAIN_CHART && isPrediction) previousGlucoseMarker.addHitArea();
			}
			
			if (isPrediction && chartType == MAIN_CHART)
			{
				glucoseMarker.addHitArea();
			}
			
			//Add line to display list
			if(chartType == MAIN_CHART && mainChart != null)
				mainChart.addChild(line);
			else if(chartType == SCROLLER_CHART && scrollerChart != null)
				scrollerChart.addChild(line);
			
			//Save line references for later use
			if(chartType == MAIN_CHART && mainChartLineList != null)
				mainChartLineList.push(line);
			else if (chartType == SCROLLER_CHART && scrollerChartLineList != null)
				scrollerChartLineList.push(line);
		}
		
		private function disposeLine(chartType:String):void
		{
			if (!SystemUtil.isApplicationActive)
				return;
			
			var sourceList:Array;
			if(chartType == MAIN_CHART)
			{
				sourceList = mainChartGlucoseMarkersList;
				
				if (predictionsEnabled && predictionsMainGlucoseDataPoints != null && predictionsMainGlucoseDataPoints.length)
				{
					sourceList = sourceList.concat(predictionsMainGlucoseDataPoints);
				}
			}
			else if (chartType == SCROLLER_CHART)
			{
				sourceList = scrollChartGlucoseMarkersList;
				
				if (predictionsEnabled && predictionsScrollerGlucoseDataPoints != null && predictionsScrollerGlucoseDataPoints.length > 0)
				{
					sourceList = sourceList.concat(predictionsScrollerGlucoseDataPoints);
				}
			}
			
			var isCGMFollower:Boolean = CGMBlueToothDevice.isFollower();
			var dataLength:int = sourceList.length;
			for (var i:int = 0; i < dataLength; i++) 
			{
				var currentMarker:GlucoseMarker = sourceList[i];
				if (currentMarker.bgReading != null && (currentMarker.bgReading.sensor != null || isCGMFollower || predictionsEnabled))
					currentMarker.alpha = 1;
				else
					currentMarker.alpha = 0;
			}
		}
		
		private function destroyAllLines(scrollerIncluded:Boolean = true):void
		{
			if (!SystemUtil.isApplicationActive)
				return;
			
			var i:int = 0
			if(mainChartLineList != null && mainChartLineList.length > 0)
			{
				for (i = 0; i < mainChartLineList.length; i++) 
				{
					var mainLine:DisplayObject = mainChartLineList[i];
					if (mainLine != null)
					{
						mainLine.removeFromParent();
						mainLine.dispose();
						mainLine = null;
					}
				}
				mainChartLineList.length = 0;
			}
			
			if (scrollerIncluded)
			{
				if(scrollerChartLineList != null && scrollerChartLineList.length > 0)
				{
					for (i = 0; i < scrollerChartLineList.length; i++) 
					{
						var scrollerLine:DisplayObject = scrollerChartLineList[i];
						if (scrollerLine != null)
						{
							scrollerLine.removeFromParent();
							scrollerLine.dispose();
							scrollerLine = null;
						}
					}
					scrollerChartLineList.length = 0;
				}
			}
		}
		
		/**
		 * Event Handlers
		 */
		private function onHandPickerTouch (e:TouchEvent):void
		{
			if (handPicker == null || mainChart == null || isNaN(mainChart.width) || isNaN(mainChart.x) || isNaN(handPicker.width) || isNaN(handPicker.x) || glucoseDelimiter == null || isNaN(glucoseDelimiter.x) || mainChartGlucoseMarkersList == null || mainChartGlucoseMarkersList.length == 0)
				return;
			
			//Get touch data
			var touch:Touch = e.getTouch(stage);
			
			/**
			 * UI Menu
			 */
			if(touch != null && touch.phase != null && touch.phase == TouchPhase.ENDED) 
			{
				//Activate menu drag gesture when drag finishes
				AppInterface.instance.drawers.openGesture = DragGesture.EDGE;
			}
			else if(touch != null && touch.phase != null &&  touch.phase == TouchPhase.BEGAN) 
			{	
				//Deactivate menu drag gesture when drag starts
				AppInterface.instance.drawers.openGesture = DragGesture.NONE;
			}
			
			//Dragging
			if(touch != null && touch.phase != null && touch.phase == TouchPhase.MOVED)
			{
				displayLatestBGValue = false;
				previousNumberOfMakers = currentNumberOfMakers;
				
				/**
				 * Hand Picker
				 */
				///Get the mouse location related to the stage
				var p:Point=touch.getMovement(stage);
				
				//Get current picker x position
				var previousHandPickerX:Number = handPicker.x;
				
				//Set picker x position according to drag
				handPicker.x += p.x;
				
				/**
				 * Main Graph
				 */
				//Translate picker x position to main graph
				mainChart.x -= (handPicker.x - previousHandPickerX) * scrollMultiplier;
				
				/**
				 * MOVEMENT CONSTRAINS
				 */
				//Constrain picker and main graoh to screen boundaries
				if(handPicker.x < 0)
				{
					handPicker.x = 0;
					if (mainChart.width > _graphWidth)
						mainChart.x = 0;
					else
						mainChart.x = glucoseDelimiter.x - (2 * mainChartGlucoseMarkerRadius);
				}
				else if(handPicker.x > _graphWidth - handPicker.width)
				{
					handPicker.x = _graphWidth - handPicker.width;
					mainChart.x = -mainChart.width + _graphWidth - yAxisMargin;
					if (predictionsEnabled && predictionsMainGlucoseDataPoints != null && predictionsMainGlucoseDataPoints.length > 0)
					{
						mainChart.x += mainChartGlucoseMarkerRadius;
					}
					displayLatestBGValue = true;
				}
				//else if(handPicker.x > _graphWidth - handPicker.width - 1) //Adjustements for finger drag imprecision
				//displayLatestBGValue = true;
				
				//Timeline
				if (timelineActive && timelineContainer != null)
					timelineContainer.x = mainChart.x;
				
				//Treatments
				if (treatmentsActive && treatmentsContainer != null)
					treatmentsContainer.x = mainChart.x;
				
				//Raw
				if (displayRaw && rawDataContainer != null)
					rawDataContainer.x = mainChart.x;
				
				//Basals
				if (basalsContainer != null)
					basalsContainer.x = mainChart.x;
				
				/**
				 * Dummy Mode
				 */
				if (dummyModeActive)
					return;
				
				/**
				 * RETRO GLUCOSE VALUES AND TIME
				 */
				/* Check if there are missed readings and we're in the future */
				var latestMarker:GlucoseMarker = mainChartGlucoseMarkersList[mainChartGlucoseMarkersList.length - 1];
				if (latestMarker == null)
					return;
				var latestMarkerGlobalX:Number = latestMarker.x + mainChart.x + (latestMarker.width) - activeGlucoseDelimiter.x;
				var futureTimeStamp:Number = latestMarker.timestamp + (Math.abs(latestMarkerGlobalX) / mainChartXFactor);
				var nowTimestamp:Number;
				var isFuture:Boolean = false;
				var timelineTimestamp:Number;
				
				if (latestMarkerGlobalX < 0 - (TimeSpan.TIME_6_MINUTES * mainChartXFactor)) //We are in the future and there are missing readings
				{
					isFuture = true;
					
					if (!displayLatestBGValue)
					{
						var futureDate:Date = new Date(futureTimeStamp);
						var futureHours:Number = futureDate.hours;
						var futureMinutes:Number = futureDate.minutes;
						var futureTimeOutput:String;
						
						if (dateFormat.slice(0,2) == "24")
							futureTimeOutput = TimeSpan.formatHoursMinutes(futureHours, futureMinutes, TimeSpan.TIME_FORMAT_24H);
						else
							futureTimeOutput = TimeSpan.formatHoursMinutes(futureHours, futureMinutes, TimeSpan.TIME_FORMAT_12H);
						
						if (glucoseTimeAgoPill != null)
							glucoseTimeAgoPill.setValue(futureTimeOutput, retroOutput, oldColor);
						if (glucoseValueDisplay != null)
							glucoseValueDisplay.fontStyles.color = oldColor;
					}
					else
					{
						nowTimestamp = (new Date()).valueOf();
						var lastTimestamp:Number = Number(mainChartGlucoseMarkersList[mainChartGlucoseMarkersList.length - 1].timestamp);
						var differenceInSec:Number = (nowTimestamp - lastTimestamp) / 1000;
						/*var timeAgoValue:String = TimeSpan.formatHoursMinutesFromSeconds(differenceInSec);
						if (timeAgoValue != now)
						glucoseTimeAgoPill.setValue(timeAgoValue, ago, chartFontColor);
						else
						glucoseTimeAgoPill.setValue("0m", now, chartFontColor);*/
						
						var timeAgoValue:String = TimeSpan.formatHoursMinutesFromSecondsChart(differenceInSec, false, false);
						if (timeAgoValue != now)
							glucoseTimeAgoPill.setValue(timeAgoValue, ago, chartFontColor);
						else
							glucoseTimeAgoPill.setValue("0 min", now, chartFontColor);
					}
					
					if (glucoseTimeAgoPill != null)
						glucoseTimeAgoPill.setValue(glucoseTimeAgoPill.value, glucoseTimeAgoPill.unit, oldColor);
					
					if (glucoseTimeAgoPill != null)
					{
						glucoseValueDisplay.text = "---";
						glucoseValueDisplay.fontStyles.color = oldColor;
					}
					
					timelineTimestamp = getTimelineTimestamp();
					if (displayIOBEnabled)
						calculateTotalIOB(getTimelineTimestamp());
					if (displayCOBEnabled)
						calculateTotalCOB(getTimelineTimestamp());
					
					return;
				}
				
				//Loop through all glucose markers displayed in the main chart. Looping backwards because it probably saves CPU cycles
				//for(var i:int = mainChartGlucoseMarkersList.length; --i;)
				for (var i:int = mainChartGlucoseMarkersList.length - 1 ; i >= 0; i--)
				{
					//Get Current and Previous Glucose Markers
					var currentMarker:GlucoseMarker = mainChartGlucoseMarkersList[i];
					if (currentMarker == null)
						continue;
					var previousMaker:GlucoseMarker = null;
					if (i > 0 &&  mainChartGlucoseMarkersList[i - 1] != null)
						previousMaker = mainChartGlucoseMarkersList[i - 1];
					
					//Transform local coordinates to global
					var currentMarkerGlobalX:Number = currentMarker.x + mainChart.x + currentMarker.width;
					var previousMarkerGlobalX:Number;
					if (i > 0)
					{
						if (previousMaker != null && mainChart != null)
							previousMarkerGlobalX = previousMaker.x + mainChart.x + previousMaker.width;
						else
							previousMarkerGlobalX = 0;
					}
					else
						previousMarkerGlobalX = 0;
					
					// Get current timeline timestamp
					var firstAvailableTimestamp:Number;
					
					if (mainChartGlucoseMarkersList[0] != null)
						firstAvailableTimestamp= (mainChartGlucoseMarkersList[0] as GlucoseMarker).timestamp;
					else
						continue;
					
					var currentTimelineTimestamp:Number = firstAvailableTimestamp + (Math.abs(mainChart.x - (_graphWidth - yAxisMargin - (predictionsEnabled && predictionsDelimiter != null ? glucoseDelimiter.x - predictionsDelimiter.x : 0)) + (mainChartGlucoseMarkerRadius * 2)) / mainChartXFactor);
					var hitTestCurrent:Boolean = currentMarkerGlobalX - currentMarker.width < activeGlucoseDelimiter.x;
					
					//Check if the current marker is the one selected by the main chart's delimiter line
					if ((i == 0 && currentMarkerGlobalX >= activeGlucoseDelimiter.x) || (currentMarkerGlobalX >= activeGlucoseDelimiter.x && previousMarkerGlobalX < activeGlucoseDelimiter.x))
					{
						if (currentMarker.bgReading != null && (currentMarker.bgReading.sensor != null || CGMBlueToothDevice.isFollower()))
						{
							nowTimestamp = new Date().valueOf();
							var latestTimestamp:Number;
							if (mainChartGlucoseMarkersList[mainChartGlucoseMarkersList.length - 1] != null)
								latestTimestamp = (mainChartGlucoseMarkersList[mainChartGlucoseMarkersList.length - 1] as GlucoseMarker).timestamp;
							else
								continue;
							
							//Display Glucose Value
							if (!displayLatestBGValue)
							{
								glucoseValueDisplay.text = currentMarker.glucoseOutput + " " + currentMarker.slopeArrow;
								glucoseValueDisplay.fontStyles.color = currentMarker.color;
								
								if (mainChartGlucoseMarkersList.length > 1)
								{	
									if (previousMaker != null && currentTimelineTimestamp - previousMaker.timestamp > TimeSpan.TIME_16_MINUTES && !hitTestCurrent)
									{
										glucoseValueDisplay.text = "---";
										glucoseValueDisplay.fontStyles.color = oldColor;	
									}
									else if (previousMaker != null && currentTimelineTimestamp - previousMaker.timestamp > TimeSpan.TIME_75_SECONDS && Math.abs(currentMarker.timestamp - currentTimelineTimestamp) > TimeSpan.TIME_5_MINUTES && currentTimelineTimestamp - previousMaker.timestamp <= TimeSpan.TIME_16_MINUTES && !hitTestCurrent)
									{
										glucoseValueDisplay.fontStyles.color = oldColor;
									}
								}
							}
							
							//Display Slope
							if (!displayLatestBGValue)
							{
								if (glucoseSlopePill != null)
									glucoseSlopePill.setValue(currentMarker.slopeOutput, glucoseUnit, chartFontColor)
								
								if (mainChartGlucoseMarkersList.length > 1)
								{	
									if (previousMaker != null && currentTimelineTimestamp - previousMaker.timestamp > TimeSpan.TIME_16_MINUTES && !hitTestCurrent)
									{
										if (glucoseSlopePill != null)
											glucoseSlopePill.setValue("", "", oldColor)
									}
									else if (previousMaker != null && currentTimelineTimestamp - previousMaker.timestamp > TimeSpan.TIME_75_SECONDS && Math.abs(currentMarker.timestamp - currentTimelineTimestamp) > TimeSpan.TIME_5_MINUTES && currentTimelineTimestamp - previousMaker.timestamp <= TimeSpan.TIME_16_MINUTES && !hitTestCurrent)
									{
										if (glucoseSlopePill != null)
											glucoseSlopePill.setValue(glucoseSlopePill.value, glucoseSlopePill.unit, oldColor)
									}
								}
							}
							
							//Display marker time
							//if (mainChart.x > -mainChart.width + _graphWidth - yAxisMargin) //Display time of BGReading
							if (!displayLatestBGValue) //Display time of BGReading
							{
								if (glucoseTimeAgoPill != null)
									glucoseTimeAgoPill.setValue(currentMarker.timeFormatted, retroOutput, chartFontColor);
								
								if (mainChartGlucoseMarkersList.length > 1)
								{	
									if (previousMaker != null && currentTimelineTimestamp - previousMaker.timestamp > TimeSpan.TIME_75_SECONDS && Math.abs(currentMarker.timestamp - currentTimelineTimestamp) > TimeSpan.TIME_5_MINUTES && !hitTestCurrent)
									{
										var currentTimelineDate:Date = new Date(currentTimelineTimestamp);
										var currentTimelineHours:Number = currentTimelineDate.hours;
										var currentTimelineMinutes:Number = currentTimelineDate.minutes;
										var currentTimelineOutput:String;
										
										if (dateFormat.slice(0,2) == "24")
											currentTimelineOutput = TimeSpan.formatHoursMinutes(currentTimelineHours, currentTimelineMinutes, TimeSpan.TIME_FORMAT_24H);
										else
											currentTimelineOutput = TimeSpan.formatHoursMinutes(currentTimelineHours, currentTimelineMinutes, TimeSpan.TIME_FORMAT_12H);
										
										if (glucoseTimeAgoPill != null)
											glucoseTimeAgoPill.setValue(currentTimelineOutput, retroOutput, oldColor);
									}
								}
							}
							
							//if (mainChart.x > -mainChart.width + _graphWidth - yAxisMargin)
							if (handPicker.x < _graphWidth - handPicker.width)
								selectedGlucoseMarkerIndex = currentMarker.index;
							else
								(mainChartGlucoseMarkersList[mainChartGlucoseMarkersList.length - 1] as GlucoseMarker).index;
							
							if (i == mainChartGlucoseMarkersList.length - 1)
								displayLatestBGValue = true;
							
							//Treatments
							timelineTimestamp = getTimelineTimestamp();
							if (displayLatestBGValue && !isFuture)
								timelineTimestamp = new Date().valueOf();
							
							if (displayIOBEnabled)
								calculateTotalIOB(timelineTimestamp);
							if (displayCOBEnabled)
								calculateTotalCOB(timelineTimestamp);
						}
						
						//We found a mach so we can break the loop to save CPU cycles
						break;
					}
				}
				
				if (displayLatestBGValue && !isFuture)
				{
					calculateDisplayLabels();
					var now:Number = new Date().valueOf();
					if (displayIOBEnabled)
						calculateTotalIOB(now);
					if (displayCOBEnabled)
						calculateTotalCOB(now);
				}
			}
		}
		
		private function onAppInForeground (e:SpikeEvent):void
		{
			if (SystemUtil.isApplicationActive)
			{
				//Common Variables
				var lastAvailableReading:BgReading;
				
				//Update Labels
				calculateDisplayLabels();
				
				//Update IOB/COB
				var timelineTimestamp:Number = getTimelineTimestamp();
				if (displayIOBEnabled)
					calculateTotalIOB(timelineTimestamp);
				if (displayCOBEnabled)
					calculateTotalCOB(timelineTimestamp);
				
				//Fetch predictions (Loop/OpenAPS users only)
				if (predictionsEnabled && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_LOOP_OPENAPS_USER_ENABLED) == "true")
				{
					lastAvailableReading = BgReading.lastWithCalculatedValue();
					if (lastAvailableReading != null && lastAvailableReading.timestamp > Forecast.lastExternalPredictionFetchTimestamp)
					{
						NightscoutService.getPropertiesV2Endpoint();
					}
				}
				
				//Update Basals
				if (displayPumpBasals || displayMDIBasals)
				{
					if (lastAvailableReading == null)
					{
						lastAvailableReading = BgReading.lastWithCalculatedValue();
					}
					
					if ((displayPumpBasals && lastAvailableReading != null && lastAvailableReading._timestamp > lastTimePumpBasalWasRendered)
						||
						(displayMDIBasals && lastAvailableReading != null && lastAvailableReading._timestamp > lastTimeMDIBasalWasRendered)
						||
						(lastNumberOfRenderedBasals != TreatmentsManager.basalsList.length)
					)
					{
						renderBasals();
						
						if (basalsContainer != null)
							basalsContainer.x = mainChart.x;
					}
				}
			}
		}
		
		private function onUpdateTimerRefresh(event:flash.events.Event = null):void
		{
			if (SystemUtil.isApplicationActive)
			{
				calculateDisplayLabels();
				var timelineTimestamp:Number = getTimelineTimestamp();
				if (displayIOBEnabled)
					calculateTotalIOB(timelineTimestamp);
				if (displayCOBEnabled)
					calculateTotalCOB(timelineTimestamp);
			}
		}
		
		private function onCaibrationReceived(e:CalibrationServiceEvent):void
		{
			if (Calibration.allForSensor().length <= 1) //Don't run on first calibration
				return;
			
			if (!SystemUtil.isApplicationActive) //Don't run if Spike is in the background
				return;
			
			//Adjust last glucose marker and display texts
			if (mainChartGlucoseMarkersList != null && mainChartGlucoseMarkersList.length > 0)
			{
				//Get and adjust latest calibration value and chart's lowest and highest glucose values
				var latestCalibrationGlucose:Number = BgReading.lastNoSensor()._calculatedValue;
				
				//Set and adjust latest marker's properties
				var latestMarker:GlucoseMarker = mainChartGlucoseMarkersList[mainChartGlucoseMarkersList.length - 1] as GlucoseMarker;
				var calibrationDifference:Number = latestCalibrationGlucose - latestMarker.glucoseValue;
				latestMarker.newBgReading = BgReading.lastNoSensor();
				var latestGlucoseProperties:Object = GlucoseFactory.getGlucoseOutput(latestCalibrationGlucose);
				latestMarker.glucoseOutput = latestGlucoseProperties.glucoseOutput;
				latestMarker.glucoseValueFormatted = latestGlucoseProperties.glucoseValueFormatted;
				latestMarker.color = GlucoseFactory.getGlucoseColor(latestCalibrationGlucose);
				latestMarker.updateColor();
				
				if (BgReading.lastNoSensor().hideSlope)
					latestMarker.slopeArrow = "\u21C4";
				else
					latestMarker.slopeArrow = BgReading.lastNoSensor().slopeArrow();
				
				if (mainChartGlucoseMarkersList.length > 1)
				{
					var previousMarker:GlucoseMarker = mainChartGlucoseMarkersList[mainChartGlucoseMarkersList.length - 2] as GlucoseMarker;
					latestMarker.slopeOutput = GlucoseFactory.getGlucoseSlope
						(
							previousMarker.glucoseValue,
							previousMarker.glucoseValueFormatted,
							latestCalibrationGlucose,
							latestMarker.glucoseValueFormatted
						);
				}
				
				// Update Display Fields	
				glucoseValueDisplay.text = latestMarker.glucoseOutput + " " + latestMarker.slopeArrow;
				glucoseValueDisplay.fontStyles.color = latestMarker.color;
				glucoseSlopePill.setValue(latestMarker.slopeOutput, glucoseUnit, chartFontColor);
				
				//Predictions logic
				var previousPredictions:Array = null;
				if (predictionsEnabled)
				{
					//Organize previous predictions
					if (predictionsMainGlucoseDataPoints != null && predictionsMainGlucoseDataPoints.length > 0 && !isNaN(calibrationDifference))
					{
						previousPredictions = [];
						
						var numberOfAvailablePredictions:uint = predictionsMainGlucoseDataPoints.length;
						for (var i:int = 0; i < numberOfAvailablePredictions; i++) 
						{
							var predictedGlucoseMarker:GlucoseMarker = predictionsMainGlucoseDataPoints[i];
							if (predictedGlucoseMarker != null)
							{
								var predictedBgReading:BgReading = predictedGlucoseMarker.bgReading;
								if (predictedBgReading != null)
								{
									predictedBgReading._calculatedValue += calibrationDifference;
									if (predictedBgReading._calculatedValue < 40)
									{
										predictedBgReading._calculatedValue = 39;
									}
									
									if (predictedBgReading._calculatedValue > 400)
									{
										predictedBgReading._calculatedValue = 401;
									}
									
									previousPredictions.push(predictedBgReading);
								}
							}
						}
						
						if (previousPredictions.length == 0)
						{
							previousPredictions = null;
						}
						else
						{
							//Update predictions pill
							if (predictionsPill != null && !isNaN(finalPredictedValue) && !isNaN(finalPredictedDuration))
							{
								predictionsPill.setValue(glucoseUnit == "mg/dL" ? String(Math.round(finalPredictedValue + calibrationDifference)) : String(Math.round(BgReading.mgdlToMmol((finalPredictedValue + calibrationDifference) * 10)) / 10), TimeSpan.formatHoursMinutesFromMinutes(finalPredictedDuration, false));
							}
						}
					}
					
					//Dispose previous predictions
					disposePredictions();
				}
				
				//Redraw main chart
				redrawChart(MAIN_CHART, _graphWidth - yAxisMargin, _graphHeight, yAxisMargin, mainChartGlucoseMarkerRadius, 0, false, false, previousPredictions);
				redrawChart(SCROLLER_CHART, _scrollerWidth - (scrollerChartGlucoseMarkerRadius * 2), _scrollerHeight, 0, scrollerChartGlucoseMarkerRadius, 0, false, false, previousPredictions);
				
				//Deativate DummyMode
				dummyModeActive = false;
				
				//Reposition treatments
				manageTreatments();
			}
			
			//Adjust latest raw marker 
			if (displayRaw && rawGlucoseMarkersList != null && rawGlucoseMarkersList.length > 0)
			{
				//Get and adjust latest raw value
				var latestRawGlucose:Number = GlucoseFactory.getRawGlucose(BgReading.lastNoSensor(), Calibration.last());
				
				//Calculate positions
				var rawGlucoseY:Number = _graphHeight - (mainChartGlucoseMarkerRadius*2) - ((latestRawGlucose - lowestGlucoseValue) * scaleYFactor);
				rawGlucoseY -= mainChartGlucoseMarkerRadius / 2;
				
				//Set and adjust latest raw marker's properties
				var latestRawMarker:GlucoseMarker = rawGlucoseMarkersList[mainChartGlucoseMarkersList.length - 1] as GlucoseMarker;
				latestRawMarker.newBgReading = BgReading.lastNoSensor();
				latestRawMarker.newRaw = latestRawGlucose;
				latestRawMarker.y = rawGlucoseY;
				
				//Hide raw glucose marker if it is out of bounds (fixed size chart);
				if (latestRawGlucose < lowestGlucoseValue || latestRawGlucose > highestGlucoseValue)
					latestRawMarker.alpha = 0;
				else
					latestRawMarker.alpha = 1;
			}
			
			//Update pedictions in Nightscout
			//NightscoutService.uploadPredictions(true);
		}
		
		/**
		 * Extra User Info
		 */
		private function onDisplayInsulinCurve(e:starling.events.TouchEvent):void
		{
			if (!SystemUtil.isApplicationActive || dummyModeActive)
				return;
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_LOOP_OPENAPS_USER_ENABLED) == "true")
				return;
			
			var touch:Touch = e.getTouch(stage);
			
			if(touch != null && touch.phase == TouchPhase.BEGAN) 
			{
				//Dispose previous curves
				disposeAbsorptionCurves();
				
				//Validate. If there's no active IOB then don't display curves
				var currentIOB:Number = TreatmentsManager.getTotalIOB(new Date().valueOf()).iob;
				if (currentIOB < 0.01)
					return;
				
				//Generate IOB/Activity Curves
				iobActivityCurve = new IOBActivityCurve();
				iobActivityCurve.validate();
				
				//Create IOB/Activity Callout
				insulinCurveCallout = Callout.show(iobActivityCurve, IOBPill, null, true);
				insulinCurveCallout.paddingLeft += Math.abs(iobActivityCurve.leftPadding) - 5;
				insulinCurveCallout.addEventListener(starling.events.Event.CLOSE, onCurveCalloutClosed);
				Callout.stagePaddingRight = 1;
				
				//Final callout size/position adjustments
				var iobCalloutPointOfOrigin:Number = IOBPill.localToGlobal(new Point(0, 0)).y + IOBPill.height;
				var iobCurveContentOriginalHeight:Number = iobActivityCurve.height + 60;
				var suggestedIOBCurveCalloutHeight:Number = Constants.stageHeight - iobCalloutPointOfOrigin;
				var finalCalloutHeight:Number = iobCurveContentOriginalHeight > suggestedIOBCurveCalloutHeight ?  suggestedIOBCurveCalloutHeight : iobCurveContentOriginalHeight;
				
				insulinCurveCallout.height = finalCalloutHeight;
				iobActivityCurve.height = finalCalloutHeight - 50;
				iobActivityCurve.maxHeight = finalCalloutHeight - 50;
				
				if (finalCalloutHeight != iobCurveContentOriginalHeight)
				{
					(iobActivityCurve.layout as VerticalLayout).paddingRight = 10;
					insulinCurveCallout.paddingRight = 10;
				}
			}
		}
		
		private function onDisplayCarbsCurve(e:starling.events.TouchEvent):void
		{
			if (!SystemUtil.isApplicationActive || dummyModeActive)
				return;
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_LOOP_OPENAPS_USER_ENABLED) == "true")
				return;
			
			var touch:Touch = e.getTouch(stage);
			
			if(touch != null && touch.phase == TouchPhase.BEGAN) 
			{
				//Dispose previous curves
				disposeAbsorptionCurves();
				
				//Validate. If there's no active COB then don't display curves
				var currentCOB:Number = TreatmentsManager.getTotalCOB(new Date().valueOf(), CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEFAULT_IOB_COB_ALGORITHM) == "openaps").cob;
				if (currentCOB <= 0)
					return;
				
				//Generate COB Curve
				cobCurve = new COBCurve();
				cobCurve.validate();
				
				//Create IOB/Activity Callout
				carbsCurveCallout = Callout.show(cobCurve, COBPill, null, true);
				carbsCurveCallout.paddingLeft += Math.abs(cobCurve.leftPadding) - 5;
				carbsCurveCallout.addEventListener(starling.events.Event.CLOSE, onCurveCalloutClosed);
				Callout.stagePaddingRight = 1;
				
				//Final callout size/position adjustments
				var cobCalloutPointOfOrigin:Number = COBPill.localToGlobal(new Point(0, 0)).y + COBPill.height;
				var cobCurveContentOriginalHeight:Number = cobCurve.height + 60;
				var suggestedCOBCurveCalloutHeight:Number = Constants.stageHeight - cobCalloutPointOfOrigin;
				var finalCalloutHeight:Number = cobCurveContentOriginalHeight > suggestedCOBCurveCalloutHeight ?  suggestedCOBCurveCalloutHeight : cobCurveContentOriginalHeight;
				
				carbsCurveCallout.height = finalCalloutHeight;
				cobCurve.height = finalCalloutHeight - 50;
				cobCurve.maxHeight = finalCalloutHeight - 50;
				
				if (finalCalloutHeight != cobCurveContentOriginalHeight)
				{
					(cobCurve.layout as VerticalLayout).paddingRight = 10;
					carbsCurveCallout.paddingRight = 10;
				}
			}
		}
		
		private function onCurveCalloutClosed(e:starling.events.Event):void
		{
			disposeAbsorptionCurves();
		}
		
		private function onDisplayMoreInfo(e:starling.events.TouchEvent):void
		{
			if (!SystemUtil.isApplicationActive || dummyModeActive)
				return;
			
			var touch:Touch = e.getTouch(stage);
			
			if(touch != null && touch.phase == TouchPhase.BEGAN) 
			{
				var infoLayout:VerticalLayout = new VerticalLayout();
				infoLayout.horizontalAlign = HorizontalAlign.CENTER;
				infoLayout.gap = 6;
				if (infoContainer != null) infoContainer.removeFromParent(true);
				infoContainer = new ScrollContainer();
				infoContainer.layout = infoLayout;
				
				localCAGEAdded = false;
				localIAGEAdded = false;
				localBAGEAdded = false;
				localBasalPillAdded = false;
				
				//Raw & Sage for master
				if (!CGMBlueToothDevice.isFollower())
				{
					//Transmitter Battery
					if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TRANSMITTER_BATTERY_ON) == "true")
					{
						var batteryStatus:Object = GlucoseFactory.getTransmitterBattery();
						if (tBatteryPill != null) tBatteryPill.dispose();
						tBatteryPill = new ChartTreatmentPill(CGMBlueToothDevice.getTransmitterName() + " " + ModelLocator.resourceManagerInstance.getString('chartscreen','battery'));
						tBatteryPill.setValue(batteryStatus.level);
						tBatteryPill.colorizeLabel(batteryStatus.color);
						tBatteryPill.touchable = false;
						infoContainer.addChild(tBatteryPill);
					}
					
					//Raw Blood Glucose
					if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_RAW_GLUCOSE_ON) == "true" && !CGMBlueToothDevice.isBlueReader() && !CGMBlueToothDevice.isBluKon() && !CGMBlueToothDevice.isLimitter() && !CGMBlueToothDevice.isMiaoMiao() && !CGMBlueToothDevice.isTransmiter_PL())
					{
						if (rawPill != null) rawPill.dispose();
						rawPill = new ChartTreatmentPill(ModelLocator.resourceManagerInstance.getString('chartscreen','raw_glucose'));
						rawPill.setValue(GlucoseFactory.getRawGlucose() + " " + GlucoseHelper.getGlucoseUnit());
						rawPill.touchable = false;
						infoContainer.addChild(rawPill);
					}
					
					//NOISE
					if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_INFO_PILL_SENSOR_NOISE_ON) == "true")
					{
						var bgReadingsList:Array = BgReading.latest(1, CGMBlueToothDevice.isFollower());
						if (bgReadingsList != null && bgReadingsList.length > 0)
						{
							var latestReading:BgReading = bgReadingsList[0];
							var selectedMarker:GlucoseMarker = mainChartGlucoseMarkersList[selectedGlucoseMarkerIndex];
							if (selectedMarker != null && !displayLatestBGValue && selectedMarker.bgReading != null)
							{
								latestReading = selectedMarker.bgReading;
							}
							
							if (latestReading != null)
							{
								var sensorNoiseString:String = "";
								var sensorNoiseValue:int = latestReading.noiseValue();
								
								if (sensorNoiseValue == 1)
									sensorNoiseString = ModelLocator.resourceManagerInstance.getString('chartscreen','sensor_noise_clean_label');
								else if (sensorNoiseValue == 2)
									sensorNoiseString = ModelLocator.resourceManagerInstance.getString('chartscreen','sensor_noise_light_label');
								else if (sensorNoiseValue == 3)
									sensorNoiseString = ModelLocator.resourceManagerInstance.getString('chartscreen','sensor_noise_medium_label');
								else if (sensorNoiseValue == 4)
									sensorNoiseString = ModelLocator.resourceManagerInstance.getString('chartscreen','sensor_noise_heavy_label');
								else
									sensorNoiseString = ModelLocator.resourceManagerInstance.getString('chartscreen','sensor_noise_clean_label');
								
								if (sensorNoisePill != null) sensorNoisePill.dispose();
								sensorNoisePill = new ChartTreatmentPill(ModelLocator.resourceManagerInstance.getString('chartscreen','sensor_noise_label'));
								sensorNoisePill.setValue(sensorNoiseString);
								sensorNoisePill.touchable = false;
								infoContainer.addChild(sensorNoisePill);
							}
						}
					}
					
					//SAGE
					if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SAGE_ON) == "true")
					{
						if (sagePill != null) sagePill.dispose();
						sagePill = new ChartTreatmentPill(ModelLocator.resourceManagerInstance.getString('chartscreen','sensor_age'));
						sagePill.setValue(GlucoseFactory.getSensorAge());
						sagePill.touchable = false;
						infoContainer.addChild(sagePill);
					}
					
					//CAGE
					if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CAGE_ON) == "true" && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_LAST_PUMP_SITE_CHANGE) != "0")
					{
						if (cagePill != null) cagePill.dispose();
						cagePill = new ChartTreatmentPill(ModelLocator.resourceManagerInstance.getString('chartscreen','canula_age'));
						cagePill.setValue(TimeSpan.getFormattedDateFromTimestamp(Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_LAST_PUMP_SITE_CHANGE))));
						cagePill.touchable = false;
						infoContainer.addChild(cagePill);
						
						localCAGEAdded = true;
					}
					
					//IAGE
					if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_IAGE_ON) == "true" && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_LAST_INSULIN_CARTRIDGE_CHANGE) != "0")
					{
						if (iagePill != null) iagePill.dispose();
						iagePill = new ChartTreatmentPill(ModelLocator.resourceManagerInstance.getString('chartscreen','insulin_age'));
						iagePill.setValue(TimeSpan.getFormattedDateFromTimestamp(Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_LAST_INSULIN_CARTRIDGE_CHANGE))));
						iagePill.touchable = false;
						infoContainer.addChild(iagePill);
						
						localIAGEAdded = true;
					}
					
					//BAGE
					if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BAGE_ON) == "true" && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_LAST_PUMP_BATTERY_CHANGE) != "0")
					{
						if (bagePill != null) bagePill.dispose();
						bagePill = new ChartTreatmentPill(ModelLocator.resourceManagerInstance.getString('chartscreen','battery_age'));
						bagePill.setValue(TimeSpan.getFormattedDateFromTimestamp(Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_LAST_PUMP_BATTERY_CHANGE))));
						bagePill.touchable = false;
						infoContainer.addChild(bagePill);
						
						localBAGEAdded = true;
					}
				}
				
				if (!CGMBlueToothDevice.isFollower() || displayMDIBasals)
				{
					//Basal
					if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BASAL_ON) == "true")
					{
						if (basalPill != null) basalPill.dispose();
						basalPill = new ChartTreatmentPill(ModelLocator.resourceManagerInstance.getString('chartscreen','basal_insulin'));
						basalPill.setValue(GlucoseFactory.getCurrentBasalForPill());
						basalPill.touchable = false;
						infoContainer.addChild(basalPill);
						
						localBasalPillAdded = true;
					}
				}
				
				var infoPillLowerBounds:Number = infoPill.localToGlobal(new Point(0, 0)).y + infoPill.height;
				var availableScreenHeight:Number = Constants.stageHeight - infoPillLowerBounds - 10;
				
				if (infoCallout != null) infoCallout.dispose();
				infoCallout = Callout.show(infoContainer, infoPill, null, true);
				infoCallout.maxHeight = availableScreenHeight;
				infoCallout.addEventListener(starling.events.Event.CLOSE, onMoreInfoCalloutClosed);
				
				if (!NetworkInfo.networkInfo.isReachable())
					return;
				
				//Get user info
				if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BASAL_ON) == "true" ||
					(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_RAW_GLUCOSE_ON) == "true" && CGMBlueToothDevice.isFollower()) ||
					CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_OPENAPS_MOMENT_ON) == "true" ||
					CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PUMP_BATTERY_ON) == "true" ||
					CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PUMP_RESERVOIR_ON) == "true" ||
					CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PUMP_STATUS_ON) == "true" ||
					CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PUMP_TIME_ON) == "true" ||
					CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CAGE_ON) == "true" ||
					(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SAGE_ON) == "true" && CGMBlueToothDevice.isFollower()) ||
					CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_IAGE_ON) == "true" || 
					CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_LOOP_MOMENT_ON) == "true" ||
					CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_UPLOADER_BATTERY_ON) == "true"
					)
				{
					if (NightscoutService.serviceActive || NightscoutService.followerModeEnabled)
					{
						//Preloader
						userInfoPreloader = new MaterialDesignSpinner();
						userInfoPreloader.color = 0x0086FF;
						userInfoPreloader.validate();
						userInfoPreloader.touchable = false;
						infoContainer.addChild(userInfoPreloader);
						
						NightscoutService.instance.addEventListener(UserInfoEvent.USER_INFO_RETRIEVED, onUserInfoRetrieved, false, 0, true);
						NightscoutService.instance.addEventListener(UserInfoEvent.USER_INFO_API_NOT_FOUND, onUserInfoAPINotFound, false, 0, true);
						NightscoutService.instance.addEventListener(UserInfoEvent.USER_INFO_ERROR, onUserInfoError, false, 0, true);
						NightscoutService.getUserInfo();
					}
				}
			}
		}
		
		private function onUserInfoRetrieved(e:UserInfoEvent):void
		{
			NightscoutService.instance.removeEventListener(UserInfoEvent.USER_INFO_RETRIEVED, onUserInfoRetrieved);
			NightscoutService.instance.removeEventListener(UserInfoEvent.USER_INFO_API_NOT_FOUND, onUserInfoAPINotFound);
			NightscoutService.instance.removeEventListener(UserInfoEvent.USER_INFO_ERROR, onUserInfoError);
			
			if (infoContainer == null)
				return;
			
			if (userInfoPreloader != null)
			{
				if (userInfoPreloader.parent != null)
					userInfoPreloader.removeFromParent(true);
				else
				{
					try
					{
						userInfoPreloader.dispose();
					} 
					catch(error:Error) 
					{
						userInfoPreloader = null;
					}
				}
			}
			
			if (CGMBlueToothDevice.isFollower())
			{
				//Spike Master Phone Battery
				if (spikeMasterPhoneBatteryPill != null) spikeMasterPhoneBatteryPill.dispose();
				if (e.userInfo.spikeMasterPhoneBattery != null && e.userInfo.spikeMasterPhoneBattery != "")
				{
					spikeMasterPhoneBatteryPill = new ChartTreatmentPill(ModelLocator.resourceManagerInstance.getString('chartscreen','spike_master_phone_battery'));
					spikeMasterPhoneBatteryPill.setValue(e.userInfo.spikeMasterPhoneBattery);
					
					var masterPhoneBatteryLevel:Number = Number(String(e.userInfo.spikeMasterPhoneBattery).replace("%", ""));
					if (!isNaN(masterPhoneBatteryLevel))
					{
						if (masterPhoneBatteryLevel > 50)
							spikeMasterPhoneBatteryPill.colorizeLabel(0x4bef0a);
						else if (masterPhoneBatteryLevel > 30)
							spikeMasterPhoneBatteryPill.colorizeLabel(0xff671c);
						else
							spikeMasterPhoneBatteryPill.colorizeLabel(0xff1c1c);
					}
					
					spikeMasterPhoneBatteryPill.touchable = false;
					infoContainer.addChild(spikeMasterPhoneBatteryPill);
				}
				
				//Spike Master Transmitter Battery
				if (spikeMasterTransmitterBatteryPill != null) spikeMasterTransmitterBatteryPill.dispose();
				if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TRANSMITTER_BATTERY_ON) == "true" && e.userInfo.spikeMasterTransmitterName != null && e.userInfo.spikeMasterTransmitterName != "" && e.userInfo.spikeMasterTransmitterBattery != null && e.userInfo.spikeMasterTransmitterBattery != "" && e.userInfo.spikeMasterTransmitterBatteryColor != null && e.userInfo.spikeMasterTransmitterBatteryColor != 0)
				{
					spikeMasterTransmitterBatteryPill = new ChartTreatmentPill(ModelLocator.resourceManagerInstance.getString('chartscreen','spike_master_transmitter_battery').replace("{transmitter}", e.userInfo.spikeMasterTransmitterName));
					spikeMasterTransmitterBatteryPill.setValue(e.userInfo.spikeMasterTransmitterBattery);
					spikeMasterTransmitterBatteryPill.colorizeLabel(e.userInfo.spikeMasterTransmitterBatteryColor);
					spikeMasterTransmitterBatteryPill.touchable = false;
					infoContainer.addChild(spikeMasterTransmitterBatteryPill);
				}
				
				//Raw Blood Glucose
				if (rawPill != null) rawPill.dispose();
				if (e.userInfo.raw != null && !isNaN(e.userInfo.raw))
				{
					rawPill = new ChartTreatmentPill(ModelLocator.resourceManagerInstance.getString('chartscreen','raw_glucose'));
					rawPill.setValue(e.userInfo.raw + " " + GlucoseHelper.getGlucoseUnit());
					rawPill.touchable = false;
					infoContainer.addChild(rawPill);
				}
				
				//NOISE
				if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_INFO_PILL_SENSOR_NOISE_ON) == "true")
				{
					var bgReadingsList:Array = BgReading.latest(1, CGMBlueToothDevice.isFollower());
					if (bgReadingsList != null && bgReadingsList.length > 0)
					{
						var latestReading:BgReading = bgReadingsList[0];
						var selectedMarker:GlucoseMarker = mainChartGlucoseMarkersList[selectedGlucoseMarkerIndex];
						if (selectedMarker != null && !displayLatestBGValue && selectedMarker.bgReading != null)
						{
							latestReading = selectedMarker.bgReading;
						}
						
						if (latestReading != null)
						{
							var sensorNoiseString:String = "";
							var sensorNoiseValue:int = latestReading.noiseValue();
							
							if (sensorNoiseValue == 1)
								sensorNoiseString = ModelLocator.resourceManagerInstance.getString('chartscreen','sensor_noise_clean_label');
							else if (sensorNoiseValue == 2)
								sensorNoiseString = ModelLocator.resourceManagerInstance.getString('chartscreen','sensor_noise_light_label');
							else if (sensorNoiseValue == 3)
								sensorNoiseString = ModelLocator.resourceManagerInstance.getString('chartscreen','sensor_noise_medium_label');
							else if (sensorNoiseValue == 4)
								sensorNoiseString = ModelLocator.resourceManagerInstance.getString('chartscreen','sensor_noise_heavy_label');
							else
								sensorNoiseString = ModelLocator.resourceManagerInstance.getString('chartscreen','sensor_noise_clean_label');
							
							if (sensorNoisePill != null) sensorNoisePill.dispose();
							sensorNoisePill = new ChartTreatmentPill(ModelLocator.resourceManagerInstance.getString('chartscreen','sensor_noise_label'));
							sensorNoisePill.setValue(sensorNoiseString);
							sensorNoisePill.touchable = false;
							infoContainer.addChild(sensorNoisePill);
						}
					}
				}
				
				//SAGE
				if (sagePill != null) sagePill.dispose();
				if (e.userInfo.sage != null && e.userInfo.sage != "" && String(e.userInfo.sage).indexOf("n/a") == -1)
				{
					sagePill = new ChartTreatmentPill(ModelLocator.resourceManagerInstance.getString('chartscreen','sensor_age'));
					sagePill.setValue(e.userInfo.sage);
					sagePill.touchable = false;
					infoContainer.addChild(sagePill);
				}
			}
			
			//CAGE
			if (!localCAGEAdded)
			{
				if (cagePill != null) cagePill.dispose();
				if (e.userInfo.cage != null && e.userInfo.cage != "" && String(e.userInfo.cage).indexOf("n/a") == -1)
				{
					cagePill = new ChartTreatmentPill(ModelLocator.resourceManagerInstance.getString('chartscreen','canula_age'));
					cagePill.setValue(e.userInfo.cage);
					cagePill.touchable = false;
					infoContainer.addChild(cagePill);
				}
			}
			
			//IAGE
			if (!localIAGEAdded)
			{
				if (iagePill != null) iagePill.dispose();
				if (e.userInfo.iage != null && e.userInfo.iage != "" && String(e.userInfo.iage).indexOf("n/a") == -1)
				{
					iagePill = new ChartTreatmentPill(ModelLocator.resourceManagerInstance.getString('chartscreen','insulin_age'));
					iagePill.setValue(e.userInfo.iage);
					iagePill.touchable = false;
					infoContainer.addChild(iagePill);
				}
			}
			
			//BAGE
			if (!localBAGEAdded)
			{
				if (bagePill != null) bagePill.dispose();
				if (e.userInfo.bage != null && e.userInfo.bage != "" && String(e.userInfo.bage).indexOf("n/a") == -1)
				{
					bagePill = new ChartTreatmentPill(ModelLocator.resourceManagerInstance.getString('chartscreen','battery_age'));
					bagePill.setValue(e.userInfo.bage);
					bagePill.touchable = false;
					infoContainer.addChild(bagePill);
				}
			}
			
			//Basal Rate
			if (!localBasalPillAdded)
			{
				if (basalPill != null) basalPill.dispose();
				if (e.userInfo.basal != null && e.userInfo.basal != "" && String(e.userInfo.basal).indexOf("n/a") == -1)
				{
					basalPill = new ChartTreatmentPill(ModelLocator.resourceManagerInstance.getString('chartscreen','basal_insulin'));
					basalPill.setValue(e.userInfo.basal);
					basalPill.touchable = false;
					infoContainer.addChild(basalPill);
				}
			}
			else
			{
				if (basalPill != null)
				{
					basalPill.removeFromParent();
					infoContainer.addChild(basalPill);
				}
			}
			
			//Last OpenAPS Moment
			if (openAPSMomentPill != null) openAPSMomentPill.dispose();
			if (e.userInfo.openAPSLastMoment != null && !isNaN(e.userInfo.openAPSLastMoment))
			{
				openAPSMomentPill = new ChartTreatmentPill(ModelLocator.resourceManagerInstance.getString('chartscreen','openaps'));
				openAPSMomentPill.setValue(e.userInfo.openAPSLastMoment + " " + ModelLocator.resourceManagerInstance.getString('chartscreen','minutes_small') + " " + ModelLocator.resourceManagerInstance.getString('chartscreen','time_ago_suffix'));
				openAPSMomentPill.touchable = false;
				infoContainer.addChild(openAPSMomentPill);
			}
			
			//Last Loop Moment
			if (loopMomentPill != null) loopMomentPill.dispose();
			if (e.userInfo.loopLastMoment != null && !isNaN(e.userInfo.loopLastMoment))
			{
				loopMomentPill = new ChartTreatmentPill(ModelLocator.resourceManagerInstance.getString('chartscreen','loop_app'));
				loopMomentPill.setValue(e.userInfo.loopLastMoment + " " + ModelLocator.resourceManagerInstance.getString('chartscreen','minutes_small') + " " + ModelLocator.resourceManagerInstance.getString('chartscreen','time_ago_suffix'));
				loopMomentPill.touchable = false;
				infoContainer.addChild(loopMomentPill);
			}
			
			//Uploader Battery
			if (upBatteryPill != null) upBatteryPill.dispose();
			if (e.userInfo.uploaderBattery != null && e.userInfo.uploaderBattery != "" && e.userInfo.uploaderBattery != "?%" && String(e.userInfo.uploaderBattery).indexOf("n/a") == -1)
			{
				upBatteryPill = new ChartTreatmentPill(ModelLocator.resourceManagerInstance.getString('chartscreen','uploader_battery'));
				upBatteryPill.setValue(e.userInfo.uploaderBattery);
				upBatteryPill.touchable = false;
				infoContainer.addChild(upBatteryPill);
			}
			
			//Pump Reservoir
			if (pumpReservoirPill != null) pumpReservoirPill.dispose();
			if (e.userInfo.pumpReservoir != null && !isNaN(e.userInfo.pumpReservoir))
			{
				pumpReservoirPill = new ChartTreatmentPill(ModelLocator.resourceManagerInstance.getString('chartscreen','pump_reservoir'));
				pumpReservoirPill.setValue(e.userInfo.pumpReservoir + "U");
				pumpReservoirPill.touchable = false;
				infoContainer.addChild(pumpReservoirPill);
			}
			
			//Pump Time
			if (pumpTimePill != null) pumpTimePill.dispose();
			if (e.userInfo.pumpTime != null && !isNaN(e.userInfo.pumpTime))
			{
				pumpTimePill = new ChartTreatmentPill(ModelLocator.resourceManagerInstance.getString('chartscreen','pump_time'));
				pumpTimePill.setValue(e.userInfo.pumpTime + " " + ModelLocator.resourceManagerInstance.getString('chartscreen','minutes_small') + " " + ModelLocator.resourceManagerInstance.getString('chartscreen','time_ago_suffix'));
				pumpTimePill.touchable = false;
				infoContainer.addChild(pumpTimePill);
			}
			
			//Pump Status
			if (pumpStatusPill != null) pumpStatusPill.dispose();
			if (e.userInfo.pumpStatus != null && e.userInfo.pumpStatus != "" && String(e.userInfo.pumpStatus).indexOf("n/a") == -1)
			{
				pumpStatusPill = new ChartTreatmentPill(ModelLocator.resourceManagerInstance.getString('chartscreen','pump_status'));
				pumpStatusPill.setValue(e.userInfo.pumpStatus);
				pumpStatusPill.touchable = false;
				infoContainer.addChild(pumpStatusPill);
			}
			
			//Pump Battery
			if (pumpBatteryPill != null) pumpBatteryPill.dispose();
			if (e.userInfo.pumpBattery != null && e.userInfo.pumpBattery != "" && String(e.userInfo.pumpBattery).indexOf("n/a") == -1)
			{
				pumpBatteryPill = new ChartTreatmentPill(ModelLocator.resourceManagerInstance.getString('chartscreen','pump_battery'));
				pumpBatteryPill.setValue(e.userInfo.pumpBattery);
				pumpBatteryPill.touchable = false;
				infoContainer.addChild(pumpBatteryPill);
			}
			
			infoCallout.invalidate(FeathersControl.INVALIDATION_FLAG_SIZE);
		}
		
		private function onUserInfoAPINotFound(e:UserInfoEvent):void
		{
			NightscoutService.instance.removeEventListener(UserInfoEvent.USER_INFO_RETRIEVED, onUserInfoRetrieved);
			NightscoutService.instance.removeEventListener(UserInfoEvent.USER_INFO_API_NOT_FOUND, onUserInfoAPINotFound);
			NightscoutService.instance.removeEventListener(UserInfoEvent.USER_INFO_ERROR, onUserInfoError);
			
			if (infoContainer == null || infoCallout == null)
				return;
			
			if (userInfoPreloader != null)
			{
				if (userInfoPreloader.parent != null)
					userInfoPreloader.removeFromParent(true);
				else
				{
					try
					{
						userInfoPreloader.dispose();
					} 
					catch(error:Error) 
					{
						userInfoPreloader = null;
					}
				}
			}
			
			//Remove preloader
			if (userInfoErrorLabel != null) userInfoErrorLabel.removeFromParent(true);
			
			//Notify user
			userInfoErrorLabel = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('chartscreen','api_v2_not_found'), HorizontalAlign.CENTER, VerticalAlign.TOP, 14, false, 0xFF0000);
			userInfoErrorLabel.touchable = false;
			infoContainer.addChild(userInfoErrorLabel);
			
			infoCallout.invalidate(FeathersControl.INVALIDATION_FLAG_SIZE);
		}
		
		private function onUserInfoError(e:UserInfoEvent):void
		{
			NightscoutService.instance.removeEventListener(UserInfoEvent.USER_INFO_RETRIEVED, onUserInfoRetrieved);
			NightscoutService.instance.removeEventListener(UserInfoEvent.USER_INFO_API_NOT_FOUND, onUserInfoAPINotFound);
			NightscoutService.instance.removeEventListener(UserInfoEvent.USER_INFO_ERROR, onUserInfoError);
			
			if (infoContainer == null || infoCallout == null)
				return;
			
			if (userInfoPreloader != null)
			{
				if (userInfoPreloader.parent != null)
					userInfoPreloader.removeFromParent(true);
				else
				{
					try
					{
						userInfoPreloader.dispose();
					} 
					catch(error:Error) 
					{
						userInfoPreloader = null;
					}
				}
			}
			
			//Remove preloader
			if (userInfoErrorLabel != null) userInfoErrorLabel.removeFromParent(true);
			
			//Notify user
			userInfoErrorLabel = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('chartscreen','error_getting_user_info'), HorizontalAlign.CENTER, VerticalAlign.TOP, 14, false, 0xFF0000);
			userInfoErrorLabel.touchable = false;
			infoContainer.addChild(userInfoErrorLabel);
			
			infoCallout.invalidate(FeathersControl.INVALIDATION_FLAG_SIZE);
		}
		
		private function onMoreInfoCalloutClosed(e:starling.events.Event):void
		{
			if (infoCallout != null) infoCallout.dispose();
			
			disposeInfoPills();
		}
		
		/**
		 * Utility
		 */
		private function disposeBasalCallout (e:starling.events.Event = null):void
		{
			if (displayPumpBasals && activeBasalAreaQuad != null && basalsContainer != null)
			{
				activeBasalAreaQuad.removeFromParent();
				basalsContainer.addChildAt(activeBasalAreaQuad, 0);
			}
			
			if (treatmentValueLabel != null) 
			{
				treatmentValueLabel.removeFromParent();
				treatmentValueLabel.dispose();
				treatmentValueLabel = null;
			}
			
			if (treatmentTimeSpinner != null) 
			{
				treatmentTimeSpinner.removeFromParent();
				treatmentTimeSpinner.dispose();
				treatmentTimeSpinner = null;
			}
			
			if (timeSpacer != null) 
			{
				timeSpacer.removeFromParent();
				timeSpacer.dispose();
				timeSpacer = null;
			}
			
			if (treatmentContainer != null) 
			{
				treatmentContainer.removeFromParent();
				treatmentContainer.dispose();
				treatmentContainer = null;
			}
			
			if (treatmentNoteLabel != null) 
			{
				treatmentNoteLabel.removeFromParent();
				treatmentNoteLabel.dispose();
				treatmentNoteLabel = null;
			}
			
			if (moveBtn != null) 
			{
				moveBtn.removeFromParent();
				moveBtn.removeEventListeners();
				moveBtn.dispose();
				moveBtn = null;
			}
			
			if (deleteBtn != null) 
			{
				deleteBtn.removeFromParent();
				deleteBtn.removeEventListeners();
				deleteBtn.dispose();
				deleteBtn = null;
			}
			
			if (actionsContainer != null)
			{
				actionsContainer.removeFromParent();
				actionsContainer.dispose();
				actionsContainer = null;
			}
			
			if (treatmentCallout != null) 
			{
				treatmentCallout.removeFromParent();
				treatmentCallout.removeEventListeners();
				treatmentCallout.dispose();
				treatmentCallout = null;
			}
			
			if (activeBasalAreaQuad != null)
			{
				activeBasalAreaQuad.filter = null;
				activeBasalAreaQuad = null;
			}
		}
		
		private function disposeBasals():void
		{
			var i:int;
			
			for (i = basalAreasList.length - 1 ; i >= 0; i--)
			{
				var quad:Quad = basalAreasList[i];
				if (quad != null)
				{
					quad.removeFromParent();
					quad.removeEventListener(TouchEvent.TOUCH, onBasalAreaTouched);
					quad.dispose();
					quad = null;
				}
			}
			basalAreasList.length = 0;
			
			for (i = basalLinesList.length - 1 ; i >= 0; i--)
			{
				var line:SpikeLine = basalLinesList[i];
				if (line != null)
				{
					line.removeFromParent();
					line.dispose();
					line = null;
				}
			}
			basalLinesList.length = 0;
			
			for (i = basalLabelsList.length - 1 ; i >= 0; i--)
			{
				var label:Label = basalLabelsList[i];
				if (label != null)
				{
					label.removeFromParent();
					label.dispose();
					label = null;
				}
			}
			basalLabelsList.length = 0;
		}
		
		private function disposeInfoPills():void
		{
			NightscoutService.instance.removeEventListener(UserInfoEvent.USER_INFO_RETRIEVED, onUserInfoRetrieved);
			NightscoutService.instance.removeEventListener(UserInfoEvent.USER_INFO_API_NOT_FOUND, onUserInfoAPINotFound);
			NightscoutService.instance.removeEventListener(UserInfoEvent.USER_INFO_ERROR, onUserInfoError);
			
			if (tBatteryPill != null)
			{
				tBatteryPill.removeFromParent();
				tBatteryPill.dispose();
				tBatteryPill = null;
			}
			
			if (basalPill != null)
			{
				basalPill.removeFromParent();
				basalPill.dispose();
				basalPill = null;
			}
			
			if (rawPill != null)
			{
				rawPill.removeFromParent();
				rawPill.dispose();
				rawPill = null;
			}
			
			if (upBatteryPill != null)
			{
				upBatteryPill.removeFromParent();
				upBatteryPill.dispose();
				upBatteryPill = null;
			}
			
			if (openAPSMomentPill != null)
			{
				openAPSMomentPill.removeFromParent();
				openAPSMomentPill.dispose();
				openAPSMomentPill = null;
			}
			
			if (pumpBatteryPill != null)
			{
				pumpBatteryPill.removeFromParent();
				pumpBatteryPill.dispose();
				pumpBatteryPill = null;
			}
			
			if (pumpReservoirPill != null)
			{
				pumpReservoirPill.removeFromParent();
				pumpReservoirPill.dispose();
				pumpReservoirPill = null;
			}
			
			try
			{
				if (userInfoPreloader != null && !isNaN(userInfoPreloader.width))
				{
					userInfoPreloader.removeFromParent();
					userInfoPreloader.dispose();
					userInfoPreloader = null;
				}
			} 
			catch(error:Error) {}
			
			if (pumpStatusPill != null)
			{
				pumpStatusPill.removeFromParent();
				pumpStatusPill.dispose();
				pumpStatusPill = null;
			}
			
			if (pumpTimePill != null)
			{
				pumpTimePill.removeFromParent();
				pumpTimePill.dispose();
				pumpTimePill = null;
			}
			
			if (cagePill != null)
			{
				cagePill.removeFromParent();
				cagePill.dispose();
				cagePill = null;
			}
			
			if (sagePill != null)
			{
				sagePill.removeFromParent();
				sagePill.dispose();
				sagePill = null;
			}
			
			if (bagePill != null)
			{
				bagePill.removeFromParent();
				bagePill.dispose();
				bagePill = null;
			}
			
			if (sensorNoisePill != null)
			{
				sensorNoisePill.removeFromParent();
				sensorNoisePill.dispose();
				sensorNoisePill = null;
			}
			
			if (iagePill != null)
			{
				iagePill.removeFromParent();
				iagePill.dispose();
				iagePill = null;
			}
			
			if (loopMomentPill != null)
			{
				loopMomentPill.removeFromParent();
				loopMomentPill.dispose();
				loopMomentPill = null;
			}
			
			if (spikeMasterPhoneBatteryPill != null)
			{
				spikeMasterPhoneBatteryPill.removeFromParent();
				spikeMasterPhoneBatteryPill.dispose();
				spikeMasterPhoneBatteryPill = null;
			}
			
			if (spikeMasterTransmitterBatteryPill != null)
			{
				spikeMasterTransmitterBatteryPill.removeFromParent();
				spikeMasterTransmitterBatteryPill.dispose();
				spikeMasterTransmitterBatteryPill = null;
			}
			
			if (infoContainer != null)
			{
				infoContainer.removeFromParent();
				infoContainer.dispose();
				infoContainer = null;
			}
			
			if (infoCallout != null)
			{
				infoCallout.removeFromParent();
				infoCallout.dispose();
				infoCallout = null;
			}
			
			if (userInfoErrorLabel != null)
			{
				userInfoErrorLabel.removeFromParent();
				userInfoErrorLabel.dispose();
				userInfoErrorLabel = null;
			}
		}
		
		private function disposeAbsorptionCurves():void
		{
			if (iobActivityCurve != null)
			{
				iobActivityCurve.removeFromParent();
				iobActivityCurve.dispose();
				iobActivityCurve = null;
			}
			
			if (cobCurve != null)
			{
				cobCurve.removeFromParent();
				cobCurve.dispose();
				cobCurve = null;
			}
			
			if (carbsCurveCallout != null)
			{
				carbsCurveCallout.removeEventListener(starling.events.Event.CLOSE, onCurveCalloutClosed);
				carbsCurveCallout.removeFromParent();
				carbsCurveCallout.dispose();
				carbsCurveCallout = null;
			}
			
			if (insulinCurveCallout != null)
			{
				insulinCurveCallout.removeEventListener(starling.events.Event.CLOSE, onCurveCalloutClosed);
				insulinCurveCallout.removeFromParent();
				insulinCurveCallout.dispose();
				insulinCurveCallout = null;
			}
		}
		
		override public function dispose():void
		{
			/* Timeouts */
			clearTimeout(redrawPredictionsTimeoutID);
			clearTimeout(totalCOBTimeoutID);
			clearTimeout(totalIOBTimeoutID);
			
			/* Event Listeners */
			CalibrationService.instance.removeEventListener(CalibrationServiceEvent.INITIAL_CALIBRATION_EVENT, onCaibrationReceived);
			CalibrationService.instance.removeEventListener(CalibrationServiceEvent.NEW_CALIBRATION_EVENT, onCaibrationReceived);
			Spike.instance.removeEventListener(SpikeEvent.APP_IN_FOREGROUND, onAppInForeground);
			NightscoutService.instance.removeEventListener(UserInfoEvent.USER_INFO_RETRIEVED, onUserInfoRetrieved);
			if (predictionsEnabled && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_LOOP_OPENAPS_USER_ENABLED) == "true")
			{
				Forecast.instance.removeEventListener(PredictionEvent.APS_RETRIEVED, onAPSPredictionRetrieved);
			}
			
			var i:int;
			
			/* Update Timer */
			if (statusUpdateTimer != null)
			{
				statusUpdateTimer.stop();
				statusUpdateTimer.removeEventListener(TimerEvent.TIMER, onUpdateTimerRefresh);
				statusUpdateTimer = null;
			}
			
			/* Lines */
			destroyAllLines();
			
			/* Glucose Markers */
			if (mainChartGlucoseMarkersList != null)
			{
				var mainDataLength:int = mainChartGlucoseMarkersList.length;
				for (i = 0; i < mainDataLength; i++) 
				{
					var mainGlucoseMarker:GlucoseMarker = mainChartGlucoseMarkersList[i] as GlucoseMarker;
					if (mainGlucoseMarker != null)
					{
						mainGlucoseMarker.removeFromParent();
						mainGlucoseMarker.dispose();
						mainGlucoseMarker = null;
					}
				}
				mainChartGlucoseMarkersList.length = 0;
				mainChartGlucoseMarkersList = null;
			}
			
			if (displayRaw)
			{
				if (rawGlucoseMarkersList != null)
				{
					var rawDataLength:int = rawGlucoseMarkersList.length;
					for (i = 0; i < rawDataLength; i++) 
					{
						var rawGlucoseMarker:GlucoseMarker = rawGlucoseMarkersList[i] as GlucoseMarker;
						if (rawGlucoseMarker != null)
						{
							rawGlucoseMarker.removeFromParent();
							rawGlucoseMarker.dispose();
							rawGlucoseMarker = null;
						}
					}
					rawGlucoseMarkersList.length = 0;
					rawGlucoseMarkersList = null;
				}
			}
			
			if (scrollChartGlucoseMarkersList != null)
			{
				var scrollerDataLength:int = scrollChartGlucoseMarkersList.length;
				for (i = 0; i < scrollerDataLength; i++) 
				{
					var scrollerGlucoseMarker:GlucoseMarker = scrollChartGlucoseMarkersList[i] as GlucoseMarker;
					if (scrollerGlucoseMarker != null)
					{
						scrollerGlucoseMarker.removeFromParent();
						scrollerGlucoseMarker.dispose();
						scrollerGlucoseMarker = null;
					}
				}
				scrollChartGlucoseMarkersList.length = 0;
				scrollChartGlucoseMarkersList = null;
			}
			
			//Basals
			disposeBasalCallout();
			disposeBasals();
			
			//Predictions
			disposePredictions();
			disposePredictionsPills();
			disposePredictionsHeader();
			disposePredictionsExplanations();
			
			//Treatments
			if (deleteBtn != null)
			{
				deleteBtn.removeEventListeners();
				deleteBtn.removeFromParent();
				deleteBtn.dispose();
				deleteBtn = null;
			}
			
			if (moveBtn != null)
			{
				moveBtn.removeEventListeners();
				moveBtn.removeFromParent();
				moveBtn.dispose();
				moveBtn = null;
			}
			
			if (treatmentNoteLabel != null)
			{
				treatmentNoteLabel.removeFromParent();
				treatmentNoteLabel.dispose();
				treatmentNoteLabel = null;
			}
			
			if (timeSpacer != null)
			{
				timeSpacer.removeFromParent();
				timeSpacer.dispose();
				timeSpacer = null;
			}
			
			if (treatmentTimeSpinner != null)
			{
				treatmentTimeSpinner.removeFromParent();
				treatmentTimeSpinner.dispose();
				treatmentTimeSpinner = null;
			}
			
			if (treatmentValueLabel != null)
			{
				treatmentValueLabel.removeFromParent();
				treatmentValueLabel.dispose();
				treatmentValueLabel = null;
			}
			
			if (actionsContainer != null)
			{
				actionsContainer.removeFromParent();
				actionsContainer.dispose();
				actionsContainer = null;
			}
			
			if (treatmentsList != null && treatmentsList.length > 0)
			{
				for (i = 0; i < treatmentsList.length; i++) 
				{
					var chartTreatment:ChartTreatment = treatmentsList[i] as ChartTreatment;
					if (chartTreatment != null)
					{
						chartTreatment.removeEventListener(TouchEvent.TOUCH, onDisplayTreatmentDetails);
						chartTreatment.removeFromParent();
						chartTreatment.dispose();
						chartTreatment = null;
					}
				}
				treatmentsList.length = 0;
				treatmentsList = null;
			}
			
			if (treatmentsMap != null)
				treatmentsMap = null;
			
			if (treatmentCallout != null)
			{
				treatmentCallout.dispose();
				treatmentCallout = null;
			}
			
			if (predictionsPill != null)
			{
				predictionsPill.removeEventListener(TouchEvent.TOUCH, onDisplayMorePredictions);
				predictionsPill.removeFromParent();
				predictionsPill.dispose();
				predictionsPill = null;
			}
			
			if (IOBPill != null)
			{
				IOBPill.removeEventListener(TouchEvent.TOUCH, onDisplayInsulinCurve);
				IOBPill.removeFromParent();
				IOBPill.dispose();
				IOBPill = null;
			}
			
			if (COBPill != null)
			{
				COBPill.removeEventListener(TouchEvent.TOUCH, onDisplayCarbsCurve);
				COBPill.removeFromParent();
				COBPill.dispose();
				COBPill = null;
			}
			
			if (glucoseSlopePill != null)
			{
				glucoseSlopePill.removeFromParent();
				glucoseSlopePill.dispose();
				glucoseSlopePill = null;
			}
			
			if (glucoseTimeAgoPill != null)
			{
				glucoseTimeAgoPill.removeFromParent();
				glucoseTimeAgoPill.dispose();
				glucoseTimeAgoPill = null;
			}
			
			if (treatmentsContainer != null)
			{
				treatmentsContainer.removeFromParent();
				treatmentsContainer.dispose();
				treatmentsContainer = null;
			}
			
			if (treatmentContainer != null)
			{
				treatmentContainer.removeFromParent();
				treatmentContainer.dispose();
				treatmentContainer = null;
			}
			
			/* Chart Display Objects */
			if (timelineObjects != null && timelineObjects.length > 0)
			{
				for (i = 0; i < timelineObjects.length; i++) 
				{
					var displayObject:Sprite = timelineObjects[i] as Sprite;
					if (timelineContainer != null && displayObject != null)
					{
						displayObject.removeFromParent();
						for (var m:int = 0; m < displayObject.numChildren; m++) 
						{
							var child:DisplayObject = displayObject.getChildAt(m);
							if (child != null)
							{
								child.dispose();
								child = null;
							}
						}
						displayObject.dispose();
						displayObject = null;
					}
				}
				timelineObjects.length = 0;
			}
			
			if (timelineContainer != null)
			{
				timelineContainer.removeFromParent();
				timelineContainer.dispose();
				timelineContainer = null;
			}
			
			if (glucoseTimelineContainer != null)
			{
				glucoseTimelineContainer.removeFromParent();
				glucoseTimelineContainer.dispose();
				glucoseTimelineContainer = null;
			}
			
			if (scrollerBackground != null)
			{
				scrollerBackground.dispose();
				scrollerBackground = null;
			}
			
			if (handPickerFill != null)
			{
				handPickerFill.dispose();
				handPickerFill = null;
			}
			
			if (handpickerOutline != null)
			{
				handpickerOutline.dispose();
				handpickerOutline = null;
			}
			
			if (glucoseDelimiter != null)
			{
				glucoseDelimiter.removeFromParent();
				glucoseDelimiter.dispose();
				glucoseDelimiter = null;
			}
			
			if (predictionsDelimiter != null)
			{
				predictionsDelimiter.removeFromParent();
				predictionsDelimiter.dispose();
				predictionsDelimiter = null;
			}
			
			if (handPicker != null)
			{
				handPicker.removeEventListener(TouchEvent.TOUCH, onHandPickerTouch);
				handPicker.removeFromParent();
				handPicker.dispose();
				handPicker = null;
			}
			
			if (glucoseValueDisplay != null)
			{
				glucoseValueDisplay.removeFromParent();
				glucoseValueDisplay.dispose();
				glucoseValueDisplay = null;
			}
			
			if (yAxisLine != null)
			{
				yAxisLine.removeFromParent();
				yAxisLine.dispose();
				yAxisLine = null;
			}
			
			if (highestGlucoseLineMarker != null)
			{
				highestGlucoseLineMarker.removeFromParent();
				highestGlucoseLineMarker.dispose();
				highestGlucoseLineMarker = null;
			}
			
			if (highestGlucoseLegend != null)
			{
				highestGlucoseLegend.removeFromParent();
				highestGlucoseLegend.dispose();
				highestGlucoseLegend = null;
			}
			
			if (lowestGlucoseLineMarker != null)
			{
				lowestGlucoseLineMarker.removeFromParent();
				lowestGlucoseLineMarker.dispose();
				lowestGlucoseLineMarker = null;
			}
			
			if (lowestGlucoseLegend != null)
			{
				lowestGlucoseLegend.removeFromParent();
				lowestGlucoseLegend.dispose();
				lowestGlucoseLegend = null;
			}
			
			if (highUrgentGlucoseLineMarker != null)
			{
				highUrgentGlucoseLineMarker.removeFromParent();
				highUrgentGlucoseLineMarker.dispose();
				highUrgentGlucoseLineMarker = null;
			}
			
			if (highUrgentGlucoseDashedLine != null)
			{
				highUrgentGlucoseDashedLine.removeFromParent();
				highUrgentGlucoseDashedLine.dispose();
				highUrgentGlucoseDashedLine = null;
			}
			
			if (highGlucoseLineMarker != null)
			{
				highGlucoseLineMarker.removeFromParent();
				highGlucoseLineMarker.dispose();
				highGlucoseLineMarker = null;
			}
			
			if (highGlucoseLegend != null)
			{
				highGlucoseLegend.removeFromParent();
				highGlucoseLegend.dispose();
				highGlucoseLegend = null;
			}
			
			if (highGlucoseDashedLine != null)
			{
				highGlucoseDashedLine.removeFromParent();
				highGlucoseDashedLine.dispose();
				highGlucoseDashedLine = null;
			}
			
			if (lowGlucoseLineMarker != null)
			{
				lowGlucoseLineMarker.removeFromParent();
				lowGlucoseLineMarker.dispose();
				lowGlucoseLineMarker = null;
			}
			
			if (lowGlucoseLegend != null)
			{
				lowGlucoseLegend.removeFromParent();
				lowGlucoseLegend.dispose();
				lowGlucoseLegend = null;
			}
			
			if (lowGlucoseDashedLine != null)
			{
				lowGlucoseDashedLine.removeFromParent();
				lowGlucoseDashedLine.dispose();
				lowGlucoseDashedLine = null;
			}
			
			if (lowUrgentGlucoseLineMarker != null)
			{
				lowUrgentGlucoseLineMarker.removeFromParent();
				lowUrgentGlucoseLineMarker.dispose();
				lowUrgentGlucoseLineMarker = null;
			}
			
			if (lowUrgentGlucoseLegend != null)
			{
				lowUrgentGlucoseLegend.removeFromParent();
				lowUrgentGlucoseLegend.dispose();
				lowUrgentGlucoseLegend = null;
			}
			
			if (lowUrgentGlucoseDashedLine != null)
			{
				lowUrgentGlucoseDashedLine.removeFromParent();
				lowUrgentGlucoseDashedLine.dispose();
				lowUrgentGlucoseDashedLine = null;
			}
			
			if (targetGlucoseLineMarker != null)
			{
				targetGlucoseLineMarker.removeFromParent();
				targetGlucoseLineMarker.dispose();
				targetGlucoseLineMarker = null;
			}
			
			if (targetGlucoseLegend != null)
			{
				targetGlucoseLegend.removeFromParent();
				targetGlucoseLegend.dispose();
				targetGlucoseLegend = null;
			}
			
			if (targetGlucoseDashedLine != null)
			{
				targetGlucoseDashedLine.removeFromParent();
				targetGlucoseDashedLine.dispose();
				targetGlucoseDashedLine = null;
			}
			
			if (yAxis != null)
			{
				yAxis.removeFromParent();
				yAxis.dispose();
				yAxis = null;
			}
			
			if (yAxisContainer != null)
			{
				yAxisContainer.removeFromParent();
				yAxisContainer.dispose();
				yAxisContainer = null;
			}
			
			if (mainChartMask != null)
			{
				mainChartMask.dispose();
				mainChartMask = null;
			}
			
			if (dummySprite != null)
			{
				dummySprite.dispose();
				dummySprite = null;
			}
			
			if (mainChart != null)
			{
				mainChart.removeFromParent();
				mainChart.dispose();
				mainChart = null;
			}
			
			if (rawDataContainer != null)
			{
				rawDataContainer.removeFromParent();
				rawDataContainer.dispose();
				rawDataContainer = null;
			}
			
			if (scrollerChart != null)
			{
				scrollerChart.removeFromParent();
				scrollerChart.dispose();
				scrollerChart = null;
			}
			
			if (mainChartContainer != null)
			{
				mainChartContainer.removeFromParent();;
				mainChartContainer.dispose();
				mainChartContainer = null;
			}
			
			if (xRightMask != null)
			{
				xRightMask.removeFromParent();
				xRightMask.dispose();
				xRightMask = null;
			}
			
			if (xLeftMask != null)
			{
				xLeftMask.removeFromParent();
				xLeftMask.dispose();
				xLeftMask = null;
			}
			
			if (mainChartLine != null)
			{
				mainChartLine.removeFromParent();
				mainChartLine.dispose();
				mainChartLine = null;
			}
			
			if (scrollerChartLine != null)
			{
				scrollerChartLine.removeFromParent();
				scrollerChartLine.dispose();
				scrollerChartLine = null;
			}
			
			if (infoPill != null)
			{
				infoPill.removeFromParent();
				infoPill.dispose();
				infoPill = null;
			}
			
			disposeInfoPills();
			disposeAbsorptionCurves();
			
			super.dispose();
			
			System.pauseForGCIfCollectionImminent(0);
		}
		
		/**
		 * Getters & Setters
		 */
		public function get dataSource():Array
		{
			return _dataSource;
		}
		
		public function set dataSource(source:Array):void
		{
			_dataSource = source;
			
			/* Activate Dummy Mode if there's no bgreadings in data source */
			if (_dataSource == null || _dataSource.length == 0)
				dummyModeActive = true;
			else
			{
				if (_dataSource.length > 288 && !isHistoricalData && !CGMBlueToothDevice.isMiaoMiao() && !CGMBlueToothDevice.isFollower()) // >24H
				{
					var difference:int = _dataSource.length - 288;
					for (var i:int = 0; i < difference; i++) 
					{
						_dataSource.shift();
					}
					
				}
				currentNumberOfMakers = _dataSource.length;
				previousNumberOfMakers = currentNumberOfMakers;
			}
		}
		
		public function get scrollerWidth():Number {
			return _scrollerWidth;
		}
		
		public function set scrollerWidth(value:Number):void {
			_scrollerWidth = value;
		}
		
		public function get scrollerHeight():Number {
			return _scrollerHeight;
		}
		
		public function set scrollerHeight(value:Number):void {
			_scrollerHeight = value;
		}
		
		public function get graphWidth():Number {
			return _graphWidth;
		}
		
		public function set graphWidth(value:Number):void {
			_graphWidth = value;
		}
		
		public function get graphHeight():Number {
			return _graphHeight;
		}
		
		public function set graphHeight(value:Number):void {
			_graphHeight = value;
		}
		
		public function set displayLine(value:Boolean):void
		{
			_displayLine = value;
		}
		
		public function getLatestReading():BgReading {
			if (_dataSource.length == 0)
				return null;
			return (_dataSource[_dataSource.length - 1]) as BgReading;
		}
	}
}