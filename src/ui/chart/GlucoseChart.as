package ui.chart
{ 
	import com.distriqt.extension.networkinfo.NetworkInfo;
	import com.spikeapp.spike.airlibrary.SpikeANE;
	
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.system.System;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	
	import database.BgReading;
	import database.CGMBlueToothDevice;
	import database.Calibration;
	import database.CommonSettings;
	
	import events.CalibrationServiceEvent;
	import events.SpikeEvent;
	import events.UserInfoEvent;
	
	import feathers.controls.Button;
	import feathers.controls.Callout;
	import feathers.controls.DateTimeMode;
	import feathers.controls.DateTimeSpinner;
	import feathers.controls.DragGesture;
	import feathers.controls.Label;
	import feathers.controls.LayoutGroup;
	import feathers.controls.ScrollContainer;
	import feathers.core.FeathersControl;
	import feathers.extensions.MaterialDesignSpinner;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.HorizontalLayout;
	import feathers.layout.VerticalAlign;
	import feathers.layout.VerticalLayout;
	import feathers.motion.Cover;
	import feathers.motion.Reveal;
	
	import model.ModelLocator;
	
	import services.CalibrationService;
	import services.NightscoutService;
	
	import starling.animation.Transitions;
	import starling.animation.Tween;
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.utils.Align;
	import starling.utils.SystemUtil;
	
	import treatments.Insulin;
	import treatments.ProfileManager;
	import treatments.Treatment;
	import treatments.TreatmentsManager;
	
	import ui.AppInterface;
	import ui.InterfaceController;
	import ui.popups.AlertManager;
	import ui.screens.Screens;
	import ui.screens.display.LayoutFactory;
	import ui.shapes.SpikeLine;
	
	import utils.Constants;
	import utils.DeviceInfo;
	import utils.GlucoseHelper;
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
		private var displayTreatmentsOnChart:Boolean;
		private var displayCOBEnabled:Boolean;
		private var displayIOBEnabled:Boolean;
		
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
		private var outcomePill:ChartTreatmentPill;
		private var effectPill:ChartTreatmentPill;
		private var openAPSMomentPill:ChartTreatmentPill;
		private var pumpBatteryPill:ChartTreatmentPill;
		private var pumpReservoirPill:ChartTreatmentPill;
		private var userInfoPreloader:MaterialDesignSpinner;
		private var pumpStatusPill:ChartTreatmentPill;
		private var pumpTimePill:ChartTreatmentPill;
		private var cagePill:ChartTreatmentPill;
		private var loopMomentPill:ChartTreatmentPill;
		private var sagePill:ChartTreatmentPill;
		private var iagePill:ChartTreatmentPill;
		private var tBatteryPill:ChartTreatmentPill;
		private var userInfoErrorLabel:Label;
		private var spikeMasterPhoneBatteryPill:ChartTreatmentPill;
		private var spikeMasterTransmitterBatteryPill:ChartTreatmentPill;
		
		//Absorption curves
		private var absorptionGraph:LayoutGroup;
		private var curve:SpikeLine;
		private var yAxisCurve:SpikeLine;
		private var xAxisCurve:SpikeLine;
		private var firstCurveLabel:Label;
		private var nowCurveLabel:Label;
		private var nowCurveMarker:SpikeLine;
		private var lastCurveLabel:Label;
		private var highestCurveLabel:Label;
		private var middleCurveLabel:Label;
		private var lowestCurveLabel:Label;
		private var carbsCurve:LayoutGroup;
		private var carbsCurveCallout:Callout;
		private var insulinCurve:LayoutGroup;
		private var insulinCurveCallout:Callout;
		
		//Historial Data
		private var isHistoricalData:Boolean;
		
		//Main Glucose Touch
		private var mainGlucoseTimer:Number = Number.NaN;
		
		//RAW
		private var rawDataContainer:Sprite;
		private var displayRaw:Boolean = false;
		private var rawColor:uint;
		
		public function GlucoseChart(timelineRange:int, chartWidth:Number, chartHeight:Number, dontDisplayIOB:Boolean = false, dontDisplayCOB:Boolean = false, dontDisplayInfoPill:Boolean = false, isHistoricalData:Boolean = false)
		{
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
			
			//Threshold
			glucoseUrgentLow = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_URGENT_LOW_MARK));
			glucoseLow = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_LOW_MARK));
			glucoseHigh = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_HIGH_MARK));
			glucoseUrgentHigh = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_URGENT_HIGH_MARK));
			
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
			
			//Size
			mainChartGlucoseMarkerRadius = int(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_MARKER_RADIUS));
			userBGFontMultiplier = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_BG_FONT_SIZE));
			userTimeAgoFontMultiplier = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_TIMEAGO_FONT_SIZE));
			userAxisFontMultiplier = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_AXIS_FONT_SIZE));
			yAxisMargin += (legendTextSize * userAxisFontMultiplier) - legendTextSize;
			
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
			treatmentsActive = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_ENABLED) == "true";
			displayTreatmentsOnChart = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_ON_CHART_ENABLED) == "true";
			displayIOBEnabled = dontDisplayIOB == true ? false : CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_IOB_ENABLED) == "true";
			displayCOBEnabled = dontDisplayCOB == true ? false : CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_COB_ENABLED) == "true";
			
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
			
			createStatusTextDisplays(dontDisplayInfoPill);
			
			var extraPadding:int = 15;
			if (Constants.deviceModel == DeviceInfo.IPHONE_2G_3G_3GS_4_4S_ITOUCH_2_3_4 || !Constants.isPortrait)
				extraPadding = 10;
			
			if (IOBPill != null)
				chartTopPadding = IOBPill.y + IOBPill.height + extraPadding;
			else if (COBPill != null)
				chartTopPadding = COBPill.y + COBPill.height + extraPadding;
			else if (infoPill != null)
				chartTopPadding = infoPill.y + infoPill.height + extraPadding;
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
			mainChart.touchable = false;
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
			if (Constants.deviceModel == DeviceInfo.IPHONE_X && !Constants.isPortrait)
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
		}
		
		private function drawChart(chartType:String, chartWidth:Number, chartHeight:Number, chartRightMargin:Number, glucoseMarkerRadius:Number, isRaw:Boolean = false):Sprite
		{
			var chartContainer:Sprite = new Sprite();
			chartContainer.touchable = false;
			
			/**
			 * Calculation of X Axis scale factor
			 */
			//Get first and last timestamp and determine the difference between the two
			if (!dummyModeActive)
			{
				firstBGReadingTimeStamp = Number(_dataSource[0].timestamp);
				lastBGreadingTimeStamp = !isHistoricalData ? (new Date()).valueOf() : Number(_dataSource[_dataSource.length - 1].timestamp);
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
			var sortDataArray:Array = _dataSource.concat();
			sortDataArray.sortOn(["calculatedValue"], Array.NUMERIC);
			var lowestValue:Number;
			var highestValue:Number;;
			if (!dummyModeActive)
			{
				lowestValue = sortDataArray[0].calculatedValue as Number;
				highestValue = sortDataArray[sortDataArray.length - 1].calculatedValue as Number;
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
			
			/**
			 * Creation of the line component
			 */
			//Line Chart
			if(_displayLine && !isRaw)
			{
				var line:SpikeLine = new SpikeLine();
				line.touchable = false;
				line.lineStyle(1, 0xFFFFFF, 1);
				
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
			 * RAW Properties
			 */
			if (isRaw) var lastCalibration:Calibration = Calibration.last();
			
			/**
			 * Creation and placement of the glucose values
			 */
			//Loop through all available data points
			var dataLength:int = _dataSource.length;
			for(i = 0; i < dataLength; i++)
			{
				//Get current glucose value
				var currentGlucoseValue:Number = !isRaw ? Number(_dataSource[i].calculatedValue) : GlucoseFactory.getRawGlucose(_dataSource[i], lastCalibration);
				if(currentGlucoseValue < 40)
					currentGlucoseValue = 40;
				else if (currentGlucoseValue > 400)
					currentGlucoseValue = 400;
				
				//Define glucose marker x position
				var glucoseX:Number;
				if(i==0)
					glucoseX = !isRaw ? 0 : glucoseMarkerRadius;
				else
					glucoseX = (Number(_dataSource[i].timestamp) - Number(_dataSource[i-1].timestamp)) * scaleXFactor;
				
				//Define glucose marker y position
				var glucoseY:Number = chartHeight - (glucoseMarkerRadius * 2) - ((currentGlucoseValue - lowestGlucoseValue) * scaleYFactor);
				if (isRaw) glucoseY -= glucoseMarkerRadius;
				//If glucose is a perfect flat line then display it in the middle
				if(totalGlucoseDifference == 0 && !isRaw) 
					glucoseY = (chartHeight - (glucoseMarkerRadius*2)) / 2;
				
				// Create Glucose Marker
				var glucoseMarker:GlucoseMarker;
				if (!isRaw)
				{
					glucoseMarker = new GlucoseMarker
					(
						{
							x: previousXCoordinate + glucoseX,
							y: glucoseY,
							index: i,
							radius: glucoseMarkerRadius,
							bgReading: _dataSource[i],
							previousGlucoseValueFormatted: previousGlucoseMarker != null ? previousGlucoseMarker.glucoseValueFormatted : null,
							previousGlucoseValue: previousGlucoseMarker != null ? previousGlucoseMarker.glucoseValue : null
						}
					);
				}
				else
				{
					glucoseMarker = new GlucoseMarker
					(
						{
							x: previousXCoordinate + glucoseX,
							y: glucoseY,
							index: i,
							radius: glucoseMarkerRadius,
							bgReading: _dataSource[i],
							raw: currentGlucoseValue,
							rawColor: rawColor
						},
						true
					);
				}
				glucoseMarker.touchable = false;
				
				//Hide glucose marker if it is out of bounds (fixed size chart);
				if (glucoseMarker.glucoseValue < lowestGlucoseValue || glucoseMarker.glucoseValue > highestGlucoseValue)
					glucoseMarker.alpha = 0;
				else
					glucoseMarker.alpha = 1;
				
				//Draw line
				if(_displayLine && !isRaw && glucoseMarker.bgReading != null && glucoseMarker.bgReading.calculatedValue != 0 && (glucoseMarker.bgReading.sensor != null || CGMBlueToothDevice.isFollower()) && glucoseMarker.glucoseValue >= lowestGlucoseValue && glucoseMarker.glucoseValue <= highestGlucoseValue)
				{
					if(i == 0)
						line.moveTo(glucoseMarker.x, glucoseMarker.y + (glucoseMarker.width / 2));
					else
					{
						var currentLineX:Number;
						var currentLineY:Number;
						
						if(i < dataLength -1)
						{
							currentLineX = glucoseMarker.x + (glucoseMarker.width/2);
							currentLineY = glucoseMarker.y + (glucoseMarker.height/2);
						}
						else if (i == dataLength -1)
						{
							currentLineX = glucoseMarker.x + (glucoseMarker.width);
							currentLineY = glucoseMarker.y + (glucoseMarker.height/2);
						}
						
						//Style
						line.lineStyle(1, glucoseMarker.color, 1);
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
						
						if (isNaN(previousColor))
							line.lineTo(currentLineX, currentLineY);
						else
							line.lineTo(currentLineX, currentLineY, previousColor, currentColor);
												
						line.moveTo(currentLineX, currentLineY);
					}
					//Hide glucose marker
					glucoseMarker.alpha = 0;
				}
				
				//Hide markers without sensor
				var glucoseReading:BgReading = _dataSource[i] as BgReading;
				if ((glucoseReading.sensor == null && !CGMBlueToothDevice.isFollower()) || glucoseReading.calculatedValue == 0 || (glucoseReading.rawData == 0 && !CGMBlueToothDevice.isFollower()))
					glucoseMarker.alpha = 0;
			
				//Set variables for next iteration
				previousXCoordinate = glucoseMarker.x;
				previousYCoordinate = glucoseMarker.y;
				previousGlucoseMarker = glucoseMarker;
				
				//Add glucose marker to the timeline
				chartContainer.addChild(glucoseMarker);
				
				//Add glucose marker to the displayObjects array for later reference 
				if(chartType == MAIN_CHART)
				{
					if (!isRaw)
						mainChartGlucoseMarkersList.push(glucoseMarker);
					else
						rawGlucoseMarkersList.push(glucoseMarker);
				}
				else if (chartType == SCROLLER_CHART)
					scrollChartGlucoseMarkersList.push(glucoseMarker);
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
			
			return chartContainer;
		}
		
		public function calculateTotalIOB(time:Number):void
		{
			if (dummyModeActive || !treatmentsActive || !displayTreatmentsOnChart || !displayIOBEnabled || isHistoricalData)
				return;
			
			if (treatmentsActive && TreatmentsManager.treatmentsList != null && TreatmentsManager.treatmentsList.length > 0 && IOBPill != null && mainChartGlucoseMarkersList != null && mainChartGlucoseMarkersList.length > 0)
			{
				IOBPill.setValue(GlucoseFactory.formatIOB(TreatmentsManager.getTotalIOB(time)));
				SystemUtil.executeWhenApplicationIsActive( repositionTreatmentPills );
			}
			
			if (treatmentsActive && (TreatmentsManager.treatmentsList == null || TreatmentsManager.treatmentsList.length == 0))
			{
				IOBPill.setValue(GlucoseFactory.formatIOB(0));
				SystemUtil.executeWhenApplicationIsActive( repositionTreatmentPills );
			}
		}
		
		public function calculateTotalCOB(time:Number):void
		{
			if (dummyModeActive || !treatmentsActive || !displayTreatmentsOnChart || !displayCOBEnabled || isHistoricalData)
				return;
			
			if (treatmentsActive && TreatmentsManager.treatmentsList != null && TreatmentsManager.treatmentsList.length > 0 && COBPill != null && mainChartGlucoseMarkersList != null && mainChartGlucoseMarkersList.length > 0)
			{
				COBPill.setValue(GlucoseFactory.formatCOB(TreatmentsManager.getTotalCOB(time)));
				SystemUtil.executeWhenApplicationIsActive( repositionTreatmentPills );
			}
			
			if (treatmentsActive && (TreatmentsManager.treatmentsList == null || TreatmentsManager.treatmentsList.length == 0))
			{
				COBPill.setValue(GlucoseFactory.formatCOB(0));
				SystemUtil.executeWhenApplicationIsActive( repositionTreatmentPills );
			}
		}
		
		private function repositionTreatmentPills():void
		{
			if (displayIOBEnabled && IOBPill != null)
			{
				IOBPill.x = _graphWidth - IOBPill.width -glucoseStatusLabelsMargin - 2;
				IOBPill.visible = true;
			}
			
			if (displayCOBEnabled && COBPill != null)
			{
				if (displayIOBEnabled)
					COBPill.x = IOBPill.x - COBPill.width - 6;
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
			if (dummyModeActive || !treatmentsActive || !displayTreatmentsOnChart || !isHistoricalData)
				return;
			
			var modifiedTreatment:ChartTreatment = treatmentsMap[treatment.ID] as ChartTreatment;
			if (modifiedTreatment != null)
			{
				//Update the treatment marker
				modifiedTreatment.updateMarker(treatment);
				
				//Reposition all treatments
				manageTreatments();
				
				//Recalculate total IOB and COB
				var timelineTimestamp:Number = getTimelineTimestamp();
				if (displayIOBEnabled)
					calculateTotalIOB(timelineTimestamp);
				if (displayCOBEnabled)
					calculateTotalCOB(timelineTimestamp);
			}
		}
		
		public function updateExternallyDeletedTreatment(treatment:Treatment):void
		{
			if (!SystemUtil.isApplicationActive || dummyModeActive || !treatmentsActive || !displayTreatmentsOnChart || !isHistoricalData)
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
			if (treatment.type == Treatment.TYPE_BOLUS || treatment.type == Treatment.TYPE_CORRECTION_BOLUS)
			{
				//Create treatment marker and add it to the chart
				var insulinMarker:InsulinMarker = new InsulinMarker(treatment, timelineRange);
				insulinMarker.x = (insulinMarker.treatment.timestamp - firstBGReadingTimeStamp) * mainChartXFactor;
				insulinMarker.y = _graphHeight - (insulinMarker.radius * 1.66) - ((insulinMarker.treatment.glucoseEstimated - lowestGlucoseValue) * mainChartYFactor);
				
				insulinMarker.index = treatmentsList.length;
				treatmentsList.push(insulinMarker);
				treatmentsMap[treatment.ID] = insulinMarker;
				
				if (displayIOBEnabled && !isHistoricalData)
					calculateTotalIOB(getTimelineTimestamp());
				
				chartTreatment = insulinMarker;
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
					calculateTotalCOB(getTimelineTimestamp());
				
				chartTreatment = carbsMarker;
			}
			else if (treatment.type == Treatment.TYPE_MEAL_BOLUS)
			{
				//Create treatment marker and add it to the chart
				var mealMarker:MealMarker = new MealMarker(treatment, timelineRange);
				mealMarker.x = (mealMarker.treatment.timestamp - firstBGReadingTimeStamp) * mainChartXFactor;
				mealMarker.y = _graphHeight - (mealMarker.radius * 1.66) - ((mealMarker.treatment.glucoseEstimated - lowestGlucoseValue) * mainChartYFactor);
				
				mealMarker.index = treatmentsList.length;
				treatmentsList.push(mealMarker);
				treatmentsMap[treatment.ID] = mealMarker;
				
				var timelineTimestamp:Number = getTimelineTimestamp();
				if (displayIOBEnabled && !isHistoricalData)
					calculateTotalIOB(timelineTimestamp);
				if (displayCOBEnabled && !isHistoricalData)
					calculateTotalCOB(timelineTimestamp);
				
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
			if (yAxisHeight > 0 && chartTreatment.y + chartTreatment.height > yAxisHeight - 5) //Lower Area
				chartTreatment.labelUp();
			
			if (chartTreatment.y < 0) //Upper Area
				chartTreatment.y = 0;
			
			//Add treatment
			chartTreatment.addEventListener(TouchEvent.TOUCH, onDisplayTreatmentDetails);
			chartTreatment.alpha = 0;
			treatmentsContainer.addChild(chartTreatment);
			
			//Fade in treatment
			var popupTween:Tween = new Tween(chartTreatment, 0.5, Transitions.EASE_OUT);
			popupTween.fadeTo(1);
			popupTween.onComplete = function():void
			{
				popupTween = null;
			}
			Starling.juggler.add(popupTween);
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
				if (treatment.treatment.type == Treatment.TYPE_BOLUS || treatment.treatment.type == Treatment.TYPE_CORRECTION_BOLUS)
				{
					var insulin:Insulin = ProfileManager.getInsulin(treatment.treatment.insulinID);
					treatmentValue = (insulin != null ? insulin.name + "\n" : "") + GlucoseFactory.formatIOB(treatment.treatment.insulinAmount);
				}
				else if (treatment.treatment.type == Treatment.TYPE_CARBS_CORRECTION)
				{
					treatmentValue = ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_carbs') + ": " + treatment.treatment.carbs + "g" + "\n" + ModelLocator.resourceManagerInstance.getString('treatments','carbs_type_label') + ": " + TreatmentsManager.getCarbTypeName(treatment.treatment);
				}
				else if (treatment.treatment.type == Treatment.TYPE_MEAL_BOLUS)
				{
					treatmentValue += ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_meal') + "\n" + ModelLocator.resourceManagerInstance.getString('treatments','treatment_insulin_label') + ": " + GlucoseFactory.formatIOB(treatment.treatment.insulinAmount) + "\n" + ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_carbs') + ": " + treatment.treatment.carbs + "g" + "\n" + ModelLocator.resourceManagerInstance.getString('treatments','carbs_type_label') + ": " + TreatmentsManager.getCarbTypeName(treatment.treatment);
				}
				else if (treatment.treatment.type == Treatment.TYPE_NOTE)
				{
					treatmentValue = ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_note');
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
					treatmentValue = ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_sensor_start');
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
				if (treatment.treatment.type == Treatment.TYPE_GLUCOSE_CHECK && treatment.treatment.note == ModelLocator.resourceManagerInstance.getString("treatments","sensor_calibration_note"))
					treatmentTimeSpinner.isEnabled = false;
				if (isHistoricalData) treatmentTimeSpinner.isEnabled = false;
				if (timeSpacer != null) timeSpacer.removeFromParent(true);
				timeSpacer = new Sprite();
				timeSpacer.height = 10;
				treatmentContainer.addChild(treatmentTimeSpinner);
				treatmentContainer.addChild(timeSpacer);
				
				if (treatment.treatment.type == Treatment.TYPE_SENSOR_START || (treatment.treatment.type == Treatment.TYPE_GLUCOSE_CHECK && treatment.treatment.note == ModelLocator.resourceManagerInstance.getString("treatments","sensor_calibration_note")))
					treatmentTimeSpinner.isEnabled = false;
				
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
						if (treatment.treatment.type != Treatment.TYPE_GLUCOSE_CHECK || treatment.treatment.note != ModelLocator.resourceManagerInstance.getString("treatments","sensor_calibration_note"))
						{
							if (moveBtn != null) moveBtn.removeFromParent(true);
							if (deleteBtn != null) deleteBtn.removeFromParent(true);
							var actionsLayout:HorizontalLayout = new HorizontalLayout();
							actionsLayout.gap = 5;
							if (actionsContainer != null) actionsContainer.removeFromParent(true);
							actionsContainer = new LayoutGroup();
							actionsContainer.layout = actionsLayout;
							
							if (treatment.treatment.type != Treatment.TYPE_SENSOR_START)
							{
								moveBtn = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('treatments','move_button_label'));
								moveBtn.addEventListener(starling.events.Event.TRIGGERED, onMove);
								actionsContainer.addChild(moveBtn);
							}
							
							deleteBtn = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('treatments','delete_button_label'));
							deleteBtn.addEventListener(starling.events.Event.TRIGGERED, onDelete);
							actionsContainer.addChild(deleteBtn);
							
							treatmentContainer.addChild(actionsContainer);
						}
					}
				}
				
				if (treatmentCallout != null) treatmentCallout.dispose();
				treatmentCallout = Callout.show(treatmentContainer, treatment, null, true);
				
				function onDelete(e:starling.events.Event):void
				{
					treatmentCallout.close(true);
					
					var deleteTreatmentTween:Tween = new Tween(treatment, 0.3, Transitions.EASE_IN_BACK);
					var deleteX:Number = ((lastBGreadingTimeStamp - firstBGReadingTimeStamp) * mainChartXFactor) + treatment.width + 5;
					deleteTreatmentTween.moveTo(deleteX, treatment.y);
					deleteTreatmentTween.onComplete = function():void
					{
						treatmentsContainer.removeChild(treatment);
						treatmentsList.removeAt(treatment.index);
						
						TreatmentsManager.deleteTreatment(treatment.treatment);
						
						treatment.dispose();
						treatment = null;
						
						var timelineTimestamp:Number = getTimelineTimestamp();
						if (displayIOBEnabled)
							calculateTotalIOB(timelineTimestamp);
						if (displayCOBEnabled)
							calculateTotalCOB(timelineTimestamp);
						
						deleteTreatmentTween = null;
					}
					Starling.juggler.add(deleteTreatmentTween);
				}
				
				function onMove(e:starling.events.Event):void
				{
					var movedTimestamp:Number = treatmentTimeSpinner.value.valueOf();
					
					if(movedTimestamp < firstBGReadingTimeStamp || movedTimestamp > new Date().valueOf())
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
						treatment.treatment.timestamp = movedTimestamp;
						treatment.treatment.glucoseEstimated = estimatedGlucoseValue;
						manageTreatments(true);
						
						treatmentCallout.close(true);
						
						if (treatment.treatment.type == Treatment.TYPE_BOLUS || treatment.treatment.type == Treatment.TYPE_CORRECTION_BOLUS || treatment.treatment.type == Treatment.TYPE_MEAL_BOLUS)
						{
							if (displayIOBEnabled)
								calculateTotalIOB(getTimelineTimestamp());
							if (treatment.treatment.type == Treatment.TYPE_MEAL_BOLUS && displayCOBEnabled)
								calculateTotalCOB(getTimelineTimestamp());
						}
						else if (treatment.treatment.type == Treatment.TYPE_CARBS_CORRECTION && displayCOBEnabled)
							calculateTotalCOB(getTimelineTimestamp());
						
						//Update database
						TreatmentsManager.updateTreatment(treatment.treatment);
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
						if (treatment.treatment.type == Treatment.TYPE_BOLUS || treatment.treatment.type == Treatment.TYPE_CORRECTION_BOLUS || treatment.treatment.type == Treatment.TYPE_GLUCOSE_CHECK || treatment.treatment.type == Treatment.TYPE_SENSOR_START || treatment.treatment.type == Treatment.TYPE_CARBS_CORRECTION || treatment.treatment.type == Treatment.TYPE_MEAL_BOLUS)
						{
							if (treatment.treatment.type == Treatment.TYPE_MEAL_BOLUS && treatment.treatment.needsAdjustment && mainChartGlucoseMarkersList != null && mainChartGlucoseMarkersList.length > 0 && mainChartGlucoseMarkersList[mainChartGlucoseMarkersList.length - 1] != null && (mainChartGlucoseMarkersList[mainChartGlucoseMarkersList.length - 1] as GlucoseMarker).bgReading != null && treatment.treatment.timestamp <= (mainChartGlucoseMarkersList[mainChartGlucoseMarkersList.length - 1] as GlucoseMarker).bgReading.timestamp)
							{
								//It's a treatment that was added in the future. Now it's the time to calculate it's Y position on the graph
								treatment.treatment.needsAdjustment = false;
								treatment.treatment.glucoseEstimated = TreatmentsManager.getEstimatedGlucose(treatment.treatment.timestamp);
								TreatmentsManager.updateTreatment(treatment.treatment, false);
							}
							
							var generalTreatmentX:Number = (treatment.treatment.timestamp - firstBGReadingTimeStamp) * mainChartXFactor;
							var generalTreatmentY:Number = _graphHeight - (treatment.radius * 1.66) - ((treatment.treatment.glucoseEstimated - lowestGlucoseValue) * mainChartYFactor);
							if (treatment.treatment.type == Treatment.TYPE_MEAL_BOLUS && generalTreatmentY < -2)
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
				currentTimelineTimestamp = firstBGReadingTimeStamp + (Math.abs(mainChart.x - (_graphWidth - yAxisMargin) + (mainChartGlucoseMarkerRadius * 2)) / mainChartXFactor);
			
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
			
			while (initialTimestamp <= lastTimestamp + TimeSpan.TIME_1_HOUR) 
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
			if(glucoseUrgentHigh > lowestGlucoseValue && glucoseUrgentHigh < highestGlucoseValue && !dummyModeActive)
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
			if(glucoseHigh > lowestGlucoseValue && glucoseHigh < highestGlucoseValue)
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
			if(glucoseLow > lowestGlucoseValue && glucoseLow < highestGlucoseValue)
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
			if(glucoseUrgentLow > lowestGlucoseValue && glucoseUrgentLow < highestGlucoseValue && !dummyModeActive)
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
				
				if (_dataSource.length > 288 && !CGMBlueToothDevice.isMiaoMiao() && !CGMBlueToothDevice.isFollower()) // >24H
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
					displayLatestBGValue = true;
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
			
			return true;
		}
		
		private function redrawChart(chartType:String, chartWidth:Number, chartHeight:Number, chartRightMargin:Number, glucoseMarkerRadius:Number, numNewReadings:int, isRaw:Boolean = false):void
		{
			if (!SystemUtil.isApplicationActive)
				return;
			
			/**
			 * Calculation of X Axis scale factor
			 */
			var firstTimeStamp:Number = Number(_dataSource[0].timestamp);
			var lastTimeStamp:Number = (new Date()).valueOf();
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
			lastBGreadingTimeStamp = lastTimeStamp;
			
			/**
			 * Calculation of Y Axis scale factor
			 */
			//First we determine the maximum and minimum glucose values
			var previousHighestGlucoseValue:Number = highestGlucoseValue;
			var previousLowestGlucoseValue:Number = lowestGlucoseValue;
			
			var sortDataArray:Array = _dataSource.concat();
			sortDataArray.sortOn(["calculatedValue"], Array.NUMERIC);
			
			var lowestValue:Number = sortDataArray[0].calculatedValue as Number;
			var highestValue:Number = sortDataArray[sortDataArray.length - 1].calculatedValue as Number;
			
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
			
			/**
			 * Creation and placement of the glucose values
			 */
			//Line Chart
			if(_displayLine && !isRaw)
			{
				var line:SpikeLine = new SpikeLine();
				line.touchable = false;
				line.lineStyle(1, 0xFFFFFF, 1);
				
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
			
			//Raw
			if (isRaw) var lastCalibration:Calibration = Calibration.last();
			
			//Loop through all available data points
			var dataLength:int = _dataSource.length;
			for(i = 0; i < dataLength; i++)
			{
				var currentGlucoseValue:Number = !isRaw ? Number(_dataSource[i].calculatedValue) : GlucoseFactory.getRawGlucose(_dataSource[i], lastCalibration);
				if (currentGlucoseValue < 40)
					currentGlucoseValue = 40;
				else if (currentGlucoseValue > 400)
					currentGlucoseValue = 400;
				
				var glucoseMarker:GlucoseMarker;
				if(i < dataLength - 1 && chartType == MAIN_CHART)
					glucoseMarker = !isRaw ? mainChartGlucoseMarkersList[i] : rawGlucoseMarkersList[i];
				else if(i < dataLength - 1 && chartType == SCROLLER_CHART)
					glucoseMarker = scrollChartGlucoseMarkersList[i];
				
				//Define glucose marker x position
				var glucoseX:Number;
				if(i==0)
					glucoseX = !isRaw ? 0 : glucoseMarkerRadius;
				else
					glucoseX = (Number(_dataSource[i].timestamp) - Number(_dataSource[i-1].timestamp)) * scaleXFactor;
				
				//Define glucose marker y position
				var glucoseY:Number = chartHeight - (glucoseMarkerRadius*2) - ((currentGlucoseValue - lowestGlucoseValue) * scaleYFactor);
				if (isRaw) glucoseY -= glucoseMarkerRadius;
				//If glucose is a perfect flat line then display it in the middle
				if(totalGlucoseDifference == 0 && !isRaw) 
					glucoseY = (chartHeight - (glucoseMarkerRadius*2)) / 2;
				
				if(i < dataLength - numNewReadings)
				{
					glucoseMarker.x = previousXCoordinate + glucoseX;
					glucoseMarker.y = glucoseY;
					glucoseMarker.index = i;
				}
				else
				{
					if (!isRaw)
					{
						glucoseMarker = new GlucoseMarker
						(
							{
								x: previousXCoordinate + glucoseX,
								y: glucoseY,
								index: i,
								radius: glucoseMarkerRadius,
								bgReading: _dataSource[i],
								previousGlucoseValueFormatted: previousGlucoseMarker != null ? previousGlucoseMarker.glucoseValueFormatted : null,
								previousGlucoseValue: previousGlucoseMarker != null ? previousGlucoseMarker.glucoseValue : null
							}
						);
					}
					else
					{
						glucoseMarker = new GlucoseMarker
						(
							{
								x: previousXCoordinate + glucoseX,
								y: glucoseY,
								index: i,
								radius: glucoseMarkerRadius,
								bgReading: _dataSource[i],
								raw: currentGlucoseValue,
								rawColor: rawColor
							},
							true
						);
					}
					glucoseMarker.touchable = false;
					
					if(chartType == MAIN_CHART)
					{
						if (!isRaw)
						{
							//Add it to the display list
							mainChart.addChild(glucoseMarker);
							//Save it in the array for later
							mainChartGlucoseMarkersList.push(glucoseMarker);
						}
						else
						{
							//Add it to the display list
							rawDataContainer.addChild(glucoseMarker);
							//Save it in the array for later
							rawGlucoseMarkersList.push(glucoseMarker);
						}
					}
					else if (chartType == SCROLLER_CHART)
					{
						//Add it to the display list
						scrollerChart.addChild(glucoseMarker);
						//Save it in the array for later
						scrollChartGlucoseMarkersList.push(glucoseMarker);
					}
				}
				
				//Hide glucose marker if it is out of bounds (fixed size chart);
				if (glucoseMarker.glucoseValue < lowestGlucoseValue || glucoseMarker.glucoseValue > highestGlucoseValue)
					glucoseMarker.alpha = 0;
				else
					glucoseMarker.alpha = 1;
				
				//Draw line
				if(_displayLine && !isRaw && glucoseMarker.bgReading != null && glucoseMarker.bgReading.calculatedValue != 0 && (glucoseMarker.bgReading.sensor != null || CGMBlueToothDevice.isFollower()) && glucoseMarker.glucoseValue >= lowestGlucoseValue && glucoseMarker.glucoseValue <= highestGlucoseValue)
				{
					if(i == 0)
						line.moveTo(glucoseMarker.x, glucoseMarker.y);
					else
					{
						var currentLineX:Number;
						var currentLineY:Number;
						
						if(i < dataLength -1)
						{
							currentLineX = glucoseMarker.x + (glucoseMarker.width/2);
							currentLineY = glucoseMarker.y + (glucoseMarker.height/2);
						}
						else if (i == dataLength -1)
						{
							currentLineX = glucoseMarker.x + (glucoseMarker.width);
							currentLineY = glucoseMarker.y + (glucoseMarker.height/2);
						}
						
						//Style
						line.lineStyle(1, glucoseMarker.color, 1);
						var currentColor:uint = glucoseMarker.color
						var previousColor:uint;
						
						//Determine if missed readings are bigger than the acceptable gap. If so, the line will be gray;
						line.lineStyle(1, glucoseMarker.color, 1);
						if(i > 0)
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
						
						if (isNaN(previousColor))
							line.lineTo(currentLineX, currentLineY);
						else
							line.lineTo(currentLineX, currentLineY, previousColor, currentColor);
						
						line.moveTo(currentLineX, currentLineY);
					}
					//Hide glucose marker
					glucoseMarker.alpha = 0;
				}
				
				//Hide markers without sensor
				var glucoseReading:BgReading = _dataSource[i] as BgReading;
				if ((glucoseReading.sensor == null && !CGMBlueToothDevice.isFollower()) || glucoseReading.calculatedValue == 0 || (glucoseReading.rawData == 0 && !CGMBlueToothDevice.isFollower()))
					glucoseMarker.alpha = 0;
				
				
				//Update variables for next iteration
				previousXCoordinate = previousXCoordinate + glucoseX;
				previousGlucoseMarker = glucoseMarker;
			}
			
			if(chartType == MAIN_CHART && !isRaw)
			{
				//YAxis
				if(highestGlucoseValue != previousHighestGlucoseValue || lowestGlucoseValue != previousLowestGlucoseValue)
				{
					//Dispose YAxis
					yAxisContainer.dispose();
					
					//Redraw YAxis
					yAxisContainer.addChild(drawYAxis());
				}
				
				//Update glucose display textfield
				if(displayLatestBGValue)
				{
					glucoseValueDisplay.text = mainChartGlucoseMarkersList[mainChartGlucoseMarkersList.length - 1].glucoseValueFormatted + " " + mainChartGlucoseMarkersList[mainChartGlucoseMarkersList.length - 1].slopeArrow;
					glucoseValueDisplay.fontStyles.color = mainChartGlucoseMarkersList[mainChartGlucoseMarkersList.length - 1].color;
				}
			}
			//Chart Line
			if(_displayLine && !isRaw)
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
			if(chartType == MAIN_CHART)
				sourceList = mainChartGlucoseMarkersList;
			else if (chartType == SCROLLER_CHART)
				sourceList = scrollChartGlucoseMarkersList;
			
			if (sourceList == null || sourceList.length == 0)
				return;
			
			//Loop all markers, draw the line from their positions and also hide the markers
			var previousGlucoseMarker:GlucoseMarker;
			var dataLength:int = sourceList.length;
			for (var i:int = 0; i < dataLength; i++) 
			{
				var glucoseMarker:GlucoseMarker = sourceList[i];
				if (glucoseMarker == null || glucoseMarker.bgReading == null || (glucoseMarker.bgReading.sensor == null && !CGMBlueToothDevice.isFollower()))
					continue;
				
				var glucoseDifference:Number = highestGlucoseValue - lowestGlucoseValue;
				
				if(i == 0)
				{
					line.moveTo(glucoseMarker.x, glucoseMarker.y + (glucoseMarker.height/2));
				}
				else
				{
					var currentLineX:Number;
					var currentLineY:Number;
					
					if(i < dataLength -1)
					{
						currentLineX = glucoseMarker.x + (glucoseMarker.width/2);
						currentLineY = glucoseMarker.y + (glucoseMarker.height/2);
					}
					else if (i == dataLength -1)
					{
						currentLineX = glucoseMarker.x + (glucoseMarker.width);
						currentLineY = glucoseMarker.y + (glucoseMarker.height/2);
					}
					
					//Style
					line.lineStyle(1, glucoseMarker.color, 1);
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
					
					if (isNaN(previousColor))
						line.lineTo(currentLineX, currentLineY);
					else
						line.lineTo(currentLineX, currentLineY, previousColor, currentColor);
					
					line.moveTo(currentLineX, currentLineY);
				}
				//Hide glucose marker
				glucoseMarker.alpha = 0;
				previousGlucoseMarker = glucoseMarker;
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
		
		public function calculateDisplayLabels():void
		{
			if (currentNumberOfMakers == previousNumberOfMakers && !displayLatestBGValue)
				return;
			
			if (glucoseValueDisplay == null || glucoseTimeAgoPill == null || glucoseSlopePill == null || glucoseDelimiter == null)
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
				var hitTestCurrent:Boolean = currentMarkerGlobalX - currentMarker.width < glucoseDelimiter.x;
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
				else if (nextMarkerGlobalX < glucoseDelimiter.x && !hitTestCurrent)
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
		
		private function createStatusTextDisplays(dontDisplayInfoPill:Boolean = false):void
		{
			/* Calculate Font Sizes */
			deviceFontMultiplier = DeviceInfo.getFontMultipier();
			if (Constants.deviceModel == DeviceInfo.IPHONE_X) 
				glucoseDisplayFont = 54 * deviceFontMultiplier * userBGFontMultiplier;
			else
				glucoseDisplayFont = (!DeviceInfo.isTablet() ? 38 : 48) * deviceFontMultiplier * userBGFontMultiplier;
			
			timeDisplayFont = 15 * deviceFontMultiplier * userTimeAgoFontMultiplier;
			retroDisplayFont = 15 * deviceFontMultiplier * userTimeAgoFontMultiplier;
			if (Constants.deviceModel == DeviceInfo.IPHONE_X)
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
			else if (Constants.deviceModel == DeviceInfo.IPHONE_X)
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
					//IOBPill.y += ((1.2/userTimeAgoFontMultiplier) - 1) * (Constants.deviceModel != DeviceInfo.IPAD_PRO_105 && Constants.deviceModel != DeviceInfo.IPAD_PRO_129 && Constants.deviceModel != DeviceInfo.IPAD_1_2_3_4_5_AIR1_2_PRO_97 ? 18 : 65);
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
					//COBPill.y += ((1.2/userTimeAgoFontMultiplier) - 1) * (Constants.deviceModel != DeviceInfo.IPAD_PRO_105 && Constants.deviceModel != DeviceInfo.IPAD_PRO_129 && Constants.deviceModel != DeviceInfo.IPAD_1_2_3_4_5_AIR1_2_PRO_97 ? 18 : 65);
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
				infoPill.setValue("info");
				infoPill.visible = false;
				infoPill.addEventListener(TouchEvent.TOUCH, onDisplayMoreInfo);
				addChild(infoPill);
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
		
		private function disposeLine(chartType:String):void
		{
			if (!SystemUtil.isApplicationActive)
				return;
			
			var sourceList:Array;
			if(chartType == MAIN_CHART)
				sourceList = mainChartGlucoseMarkersList;
			else if (chartType == SCROLLER_CHART)
				sourceList = scrollChartGlucoseMarkersList;
			
			var dataLength:int = sourceList.length;
			for (var i:int = 0; i < dataLength; i++) 
			{
				var currentMarker:GlucoseMarker = sourceList[i];
				if (currentMarker.bgReading != null && (currentMarker.bgReading.sensor != null || CGMBlueToothDevice.isFollower()))
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
				var latestMarkerGlobalX:Number = latestMarker.x + mainChart.x + (latestMarker.width) - glucoseDelimiter.x;
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
				for(var i:int = mainChartGlucoseMarkersList.length - 1 ; i >= 0; i--)
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
					var currentTimelineTimestamp:Number = firstAvailableTimestamp + (Math.abs(mainChart.x - (_graphWidth - yAxisMargin) + (mainChartGlucoseMarkerRadius * 2)) / mainChartXFactor);
					var hitTestCurrent:Boolean = currentMarkerGlobalX - currentMarker.width < glucoseDelimiter.x;
					
					//Check if the current marker is the one selected by the main chart's delimiter line
					if ((i == 0 && currentMarkerGlobalX >= glucoseDelimiter.x) || (currentMarkerGlobalX >= glucoseDelimiter.x && previousMarkerGlobalX < glucoseDelimiter.x))
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
		
		private function onAppInForeground (e:SpikeEvent):void
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
			
			//Adjust last glucose marker and display texts
			if (mainChartGlucoseMarkersList != null && mainChartGlucoseMarkersList.length > 0)
			{
				//Get and adjust latest calibration value and chart's lowest and highest glucose values
				var latestCalibrationGlucose:Number = BgReading.lastNoSensor().calculatedValue;
				
				if (latestCalibrationGlucose < 40)
					latestCalibrationGlucose = 40;
				else if (latestCalibrationGlucose > 400)
					latestCalibrationGlucose = 400;
				
				if (!fixedSize) //Dynamic Chart
				{
					if (latestCalibrationGlucose < lowestGlucoseValue)
						lowestGlucoseValue = latestCalibrationGlucose;
					else if (latestCalibrationGlucose > highestGlucoseValue)
						highestGlucoseValue = latestCalibrationGlucose;
				}
				else //Fixed Sized Chart
				{
					lowestGlucoseValue = minAxisValue;
					if (resizeOutOfBounds && latestCalibrationGlucose < minAxisValue)
						lowestGlucoseValue = latestCalibrationGlucose;
					
					highestGlucoseValue = maxAxisValue;
					if (resizeOutOfBounds && latestCalibrationGlucose > maxAxisValue)
						highestGlucoseValue = latestCalibrationGlucose
				}
				
				//Calculate positions
				var totalGlucoseDifference:Number = highestGlucoseValue - lowestGlucoseValue;
				scaleYFactor = (_graphHeight - (mainChartGlucoseMarkerRadius*2))/totalGlucoseDifference;
				var glucoseY:Number = _graphHeight - (mainChartGlucoseMarkerRadius*2) - ((latestCalibrationGlucose - lowestGlucoseValue) * scaleYFactor);
				
				//Set and adjust latest marker's properties
				var latestMarker:GlucoseMarker = mainChartGlucoseMarkersList[mainChartGlucoseMarkersList.length - 1] as GlucoseMarker;
				latestMarker.newBgReading = BgReading.lastNoSensor();
				latestMarker.y = glucoseY;
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
				
				//Hide glucose marker if it is out of bounds (fixed size chart);
				if (latestMarker.glucoseValue < lowestGlucoseValue || latestMarker.glucoseValue > highestGlucoseValue)
					latestMarker.alpha = 0;
				else
					latestMarker.alpha = 1;
				
				//Redraw Line if needed
				if(_displayLine && latestMarker.glucoseValue >= lowestGlucoseValue && latestMarker.glucoseValue <= highestGlucoseValue)
				{
					//Dispose previous lines
					destroyAllLines(false);
					
					var line:SpikeLine = new SpikeLine();
					line.lineStyle(1, 0xFFFFFF, 1);
					
					if (mainChartLine != null) mainChartLine.removeFromParent(true);
					mainChartLine = line;
					
					var markerLength:int = mainChartGlucoseMarkersList.length;
					var previousGlucoseMarker:GlucoseMarker;
					
					//Redraw Line
					for (var i:int = 0; i < markerLength; i++) 
					{
						var glucoseMarker:GlucoseMarker = mainChartGlucoseMarkersList[i] as GlucoseMarker;
						
						if(i == 0)
							line.moveTo(glucoseMarker.x, glucoseMarker.y);
						else
						{
							var currentLineX:Number;
							var currentLineY:Number;
							
							if(i < markerLength -1)
							{
								currentLineX = glucoseMarker.x + (glucoseMarker.width/2);
								currentLineY = glucoseMarker.y + (glucoseMarker.height/2);
							}
							else if (i == markerLength -1)
							{
								currentLineX = glucoseMarker.x + (glucoseMarker.width);
								currentLineY = glucoseMarker.y + (glucoseMarker.height);
							}
							
							//Style
							line.lineStyle(1, glucoseMarker.color, 1);
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
							
							if (isNaN(previousColor))
								line.lineTo(currentLineX, currentLineY);
							else
								line.lineTo(currentLineX, currentLineY, previousColor, currentColor);
							
							line.moveTo(currentLineX, currentLineY);
						}
						//Hide glucose marker
						glucoseMarker.alpha = 0;
						previousGlucoseMarker = glucoseMarker;
					}
					
					//Remove touch events from line
					line.touchable = false;
					
					mainChart.addChild(line);
					mainChartLineList.push(line);
				}
				
				// Update Display Fields	
				glucoseValueDisplay.text = latestMarker.glucoseOutput + " " + latestMarker.slopeArrow;
				glucoseValueDisplay.fontStyles.color = latestMarker.color;
				glucoseSlopePill.setValue(latestMarker.slopeOutput, glucoseUnit, chartFontColor);
				
				//Deativate DummyMode
				dummyModeActive = false;
				
				//Dispose YAxis
				yAxisContainer.dispose();
				
				//Redraw YAxis
				yAxisContainer.addChild(drawYAxis());
				
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
				latestRawMarker.y = glucoseY;
				
				//Hide raw glucose marker if it is out of bounds (fixed size chart);
				if (latestRawGlucose < lowestGlucoseValue || latestRawGlucose > highestGlucoseValue)
					latestRawMarker.alpha = 0;
				else
					latestRawMarker.alpha = 1;
			}
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
			
			if (TreatmentsManager.getTotalIOB(new Date().valueOf()) <= 0)
				return;
			
			var touch:Touch = e.getTouch(stage);
			
			if(touch != null && touch.phase == TouchPhase.BEGAN) 
			{
				disposeAbsorptionCurves();
				
				var graphData:Object = getAbsorptionCurve("insulin");
				if (insulinCurve != null) insulinCurve.removeFromParent(true);
				insulinCurve = graphData.graph;
				
				if (insulinCurveCallout != null) insulinCurveCallout.removeFromParent(true);
				insulinCurveCallout = Callout.show(insulinCurve, IOBPill, null, true);
				insulinCurveCallout.paddingLeft += graphData.padding - 5;
				insulinCurveCallout.addEventListener(starling.events.Event.CLOSE, onCurveCalloutClosed);
				Callout.stagePaddingRight = 1;
				
				graphData = null;
			}
		}
		
		private function onDisplayCarbsCurve(e:starling.events.TouchEvent):void
		{
			if (!SystemUtil.isApplicationActive || dummyModeActive)
				return;
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_LOOP_OPENAPS_USER_ENABLED) == "true")
				return;
			
			if (TreatmentsManager.getTotalCOB(new Date().valueOf()) <= 0)
				return;
			
			var touch:Touch = e.getTouch(stage);
			
			if(touch != null && touch.phase == TouchPhase.BEGAN) 
			{
				disposeAbsorptionCurves();
				
				var graphData:Object = getAbsorptionCurve("carbs");
				if (carbsCurve != null) carbsCurve.removeFromParent(true);
				carbsCurve = graphData.graph;
				
				if (carbsCurveCallout != null) carbsCurveCallout.removeFromParent(true);
				carbsCurveCallout = Callout.show(carbsCurve, COBPill, null, true);
				carbsCurveCallout.paddingLeft += graphData.padding - 5;
				carbsCurveCallout.addEventListener(starling.events.Event.CLOSE, onCurveCalloutClosed);
				Callout.stagePaddingRight = 1;
				
				graphData = null;
			}
		}
		
		private function onCurveCalloutClosed(e:starling.events.Event):void
		{
			disposeAbsorptionCurves();
		}
		
		private function getAbsorptionCurve(type:String):Object
		{
			//Graphics container
			if (absorptionGraph != null) absorptionGraph.removeFromParent(true);
			absorptionGraph = new LayoutGroup();
			absorptionGraph.touchable = false;
			
			//Data points
			var info:Object = type == "insulin" ? TreatmentsManager.getTotalActiveInsulin() : TreatmentsManager.getTotalActiveCarbs();
			var totalTreatmentsData:Number = type == "insulin" ? info.insulin : info.carbs;
			var firstTreatmentTimestamp:Number = info.timestamp;
			var dataPoints:Array = new Array();
			var pointInTime:Number = firstTreatmentTimestamp;
			var dataPoint:Number = type == "insulin" ? TreatmentsManager.getTotalIOB(pointInTime) : TreatmentsManager.getTotalCOB(pointInTime);
			dataPoints.push( { timestamp: pointInTime, dataPoint: dataPoint } );
			
			while (dataPoint >= 0)
			{
				pointInTime += TimeSpan.TIME_2_MINUTES_30_SECONDS;
				dataPoint = type == "insulin" ? TreatmentsManager.getTotalIOB(pointInTime) : TreatmentsManager.getTotalCOB(pointInTime);
				dataPoints.push( { timestamp: pointInTime, dataPoint: dataPoint } );
				
				if (dataPoint == 0)
					break;
			}
			
			//Calculators
			var leftPadding:Number = 0;
			var firstTimestamp:Number = dataPoints[0].timestamp;
			var lastTimestamp:Number = dataPoints[dataPoints.length - 1].timestamp;
			var totalTimestampDifference:Number = lastTimestamp - firstTimestamp;
			var sortedData:Array = dataPoints.concat();
			sortedData.sortOn(["dataPoint"], Array.NUMERIC);
			var highestDataPoint:Number = sortedData[sortedData.length -1].dataPoint;
			var lowestDataPoint:Number = sortedData[0].dataPoint;
			var totalDataDifference:Number = highestDataPoint - lowestDataPoint;
			
			//YAXIS LABELS
			//Highest value
			if (highestCurveLabel != null) highestCurveLabel.removeFromParent(true);
			highestCurveLabel = LayoutFactory.createLabel(String(highestDataPoint) + (type == "insulin" ? "U" : "g"), HorizontalAlign.RIGHT, VerticalAlign.TOP, 12, false, axisFontColor);
			highestCurveLabel.touchable = false;
			highestCurveLabel.validate();
			highestCurveLabel.x = -highestCurveLabel.width - 7;
			highestCurveLabel.y = -highestCurveLabel.height / 4.5;
			absorptionGraph.addChild(highestCurveLabel);
			if (highestCurveLabel.x < leftPadding) leftPadding = highestCurveLabel.x;
			
			//Middle value
			var middleValue:Number = Math.round((highestDataPoint / 2) * 100) / 100;
			if (middleCurveLabel != null) middleCurveLabel.removeFromParent(true);
			middleCurveLabel = LayoutFactory.createLabel(String(middleValue) + (type == "insulin" ? "U" : "g"), HorizontalAlign.RIGHT, VerticalAlign.TOP, 12, false, axisFontColor);
			middleCurveLabel.touchable = false;
			middleCurveLabel.validate();
			middleCurveLabel.x = -middleCurveLabel.width - 7;
			absorptionGraph.addChild(middleCurveLabel);
			if (middleCurveLabel.x < leftPadding) leftPadding = middleCurveLabel.x;
			
			//Lowest value
			if (lowestCurveLabel != null) lowestCurveLabel.removeFromParent(true);
			lowestCurveLabel = LayoutFactory.createLabel("0" + (type == "insulin" ? "U" : "g"), HorizontalAlign.RIGHT, VerticalAlign.TOP, 12, false, axisFontColor);
			lowestCurveLabel.touchable = false;
			lowestCurveLabel.validate();
			lowestCurveLabel.x = -lowestCurveLabel.width - 7;
			absorptionGraph.addChild(lowestCurveLabel);
			if (lowestCurveLabel.x < leftPadding) leftPadding = lowestCurveLabel.x;
			
			//Absorption Curve 
			var graphWidth:Number = Constants.isPortrait ? Constants.stageWidth - Math.abs(leftPadding) - 35 : Constants.stageHeight - Math.abs(leftPadding) - 35;
			var graphHeight:Number = graphWidth / 3;
			var scaleXFactor:Number = 1 / (totalTimestampDifference / graphWidth);
			var scaleYFactor:Number = graphHeight / totalDataDifference;
			
			middleCurveLabel.y = (graphHeight / 2) - (middleCurveLabel.height / 2);
			lowestCurveLabel.y = graphHeight - lowestCurveLabel.height + (lowestCurveLabel.height / 4.5);
			
			if (curve != null) curve.removeFromParent(true);
			curve = new SpikeLine();
			curve.touchable = false;
			curve.lineStyle(1.5, type == "insulin" ? uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_INSULIN_MARKER_COLOR)) : uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_CARBS_MARKER_COLOR)));
			var previousXCoordinate:Number = 0;
			
			var dataLength:int = dataPoints.length;
			for(var i:int = 0; i < dataLength; i++)
			{
				var currentDataPointValue:Number = dataPoints[i].dataPoint;
				
				//Define data point x position
				var dataX:Number;
				if(i==0) dataX = 0;
				else dataX = (Number(dataPoints[i].timestamp) - Number(dataPoints[i-1].timestamp)) * scaleXFactor;
				
				dataX = previousXCoordinate + dataX;
				
				//Define glucose marker y position
				var dataY:Number = graphHeight - ((currentDataPointValue - lowestDataPoint) * scaleYFactor);
				
				if (i == 0)
					curve.moveTo(dataX, dataY);
				else
				{
					curve.lineTo(dataX, dataY);
					curve.moveTo(dataX, dataY);
				}
				
				previousXCoordinate = dataX;
			}
			
			absorptionGraph.addChild(curve);
			
			//Draw Axis
			if (yAxisCurve != null) yAxisCurve.removeFromParent(true);
			yAxisCurve = GraphLayoutFactory.createVerticalLine(graphHeight, 1.5, lineColor);
			yAxisCurve.touchable = false;
			absorptionGraph.addChild(yAxisCurve);
			
			if (xAxisCurve != null) xAxisCurve.removeFromParent(true);
			xAxisCurve = GraphLayoutFactory.createHorizontalLine(graphWidth, 1.5, lineColor);
			xAxisCurve.touchable = false;
			xAxisCurve.y = yAxisCurve.y + yAxisCurve.height;
			absorptionGraph.addChild(xAxisCurve);
			
			//Draw X Labels
			var dateFormat:String = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_DATE_FORMAT);
			
			//First Timestamo
			var firstDate:Date = new Date(firstTreatmentTimestamp);
			var timeFormatted:String = "";
			if (dateFormat.slice(0,2) == "24")
				timeFormatted = TimeSpan.formatHoursMinutes(firstDate.getHours(), firstDate.getMinutes(), TimeSpan.TIME_FORMAT_24H);
			else
				timeFormatted = TimeSpan.formatHoursMinutes(firstDate.getHours(), firstDate.getMinutes(), TimeSpan.TIME_FORMAT_12H);
			
			if (firstCurveLabel != null) firstCurveLabel.removeFromParent(true);
			firstCurveLabel = LayoutFactory.createLabel(timeFormatted, HorizontalAlign.LEFT, VerticalAlign.TOP, 12, false, axisFontColor);
			firstCurveLabel.touchable = false;
			firstCurveLabel.validate();
			firstCurveLabel.x = 0;
			firstCurveLabel.y = xAxisCurve.y + xAxisCurve.height + 4;
			absorptionGraph.addChild(firstCurveLabel);
			var firstLabelBounds:Rectangle = firstCurveLabel.bounds;
			
			//Now
			var now:Number = new Date().valueOf();
			
			if (nowCurveLabel != null) nowCurveLabel.removeFromParent(true);
			nowCurveLabel = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('chartscreen','now').toUpperCase(), HorizontalAlign.LEFT, VerticalAlign.TOP, 12, false, axisFontColor);
			nowCurveLabel.touchable = false;
			nowCurveLabel.validate();
			nowCurveLabel.x = ((now - firstTreatmentTimestamp) * scaleXFactor) - (nowCurveLabel.width / 2);
			nowCurveLabel.y = xAxisCurve.y + xAxisCurve.height + 4;
			absorptionGraph.addChild(nowCurveLabel);
			
			if (nowCurveMarker != null) nowCurveMarker.removeFromParent(true);
			nowCurveMarker = GraphLayoutFactory.createVerticalDashedLine(graphHeight, 2, 1, 1, lineColor);
			nowCurveMarker.touchable = false;
			nowCurveMarker.x = ((now - firstTreatmentTimestamp) * scaleXFactor);
			nowCurveMarker.y = 0;
			absorptionGraph.addChild(nowCurveMarker);
			
			var nowLabelBounds:Rectangle = nowCurveLabel.bounds;
			
			if (nowLabelBounds.intersects(firstLabelBounds))
			{
				nowCurveLabel.removeFromParent(true);
				nowCurveLabel = null;
			}
			
			//Last timestamp
			var lastDate:Date = new Date(lastTimestamp);
			var lastTimeFormatted:String = "";
			if (dateFormat.slice(0,2) == "24")
				lastTimeFormatted = TimeSpan.formatHoursMinutes(lastDate.getHours(), lastDate.getMinutes(), TimeSpan.TIME_FORMAT_24H);
			else
				lastTimeFormatted = TimeSpan.formatHoursMinutes(lastDate.getHours(), lastDate.getMinutes(), TimeSpan.TIME_FORMAT_12H);
			
			if (lastCurveLabel != null) lastCurveLabel.removeFromParent(true);
			lastCurveLabel = LayoutFactory.createLabel(lastTimeFormatted, HorizontalAlign.LEFT, VerticalAlign.TOP, 12, false, axisFontColor);
			lastCurveLabel.touchable = false;
			lastCurveLabel.validate();
			lastCurveLabel.x = xAxisCurve.width - lastCurveLabel.width;
			lastCurveLabel.y = xAxisCurve.y + xAxisCurve.height + 4;
			absorptionGraph.addChild(lastCurveLabel);
			
			if (nowCurveLabel != null)
			{
				var latestLabelBounds:Rectangle = lastCurveLabel.bounds;
				if (latestLabelBounds.intersects(nowLabelBounds))
					nowCurveLabel.removeFromParent(true);
			}
			
			//Dispose unneded data
			info = null;
			if (dataPoints != null)
			{
				dataPoints.length = 0;
				dataPoints = null;
			}
			if (sortedData != null)
			{
				sortedData.length = 0;
				sortedData = null;
			}
			
			return { graph: absorptionGraph, padding: Math.abs(leftPadding) };
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
					
					//SAGE
					if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SAGE_ON) == "true")
					{
						if (sagePill != null) sagePill.dispose();
						sagePill = new ChartTreatmentPill(ModelLocator.resourceManagerInstance.getString('chartscreen','sensor_age'));
						sagePill.setValue(GlucoseFactory.getSensorAge());
						sagePill.touchable = false;
						infoContainer.addChild(sagePill);
					}
				}
				
				var infoPillLowerBounds:Number = infoPill.localToGlobal(new Point(0, 0)).y + infoPill.height;
				var availableScreenHeight:Number = Constants.stageHeight - infoPillLowerBounds;
				
				if (infoCallout != null) infoCallout.dispose();
				infoCallout = Callout.show(infoContainer, infoPill, null, true);
				infoCallout.maxHeight = availableScreenHeight;
				infoCallout.addEventListener(starling.events.Event.CLOSE, onMoreInfoCalloutClosed);
				
				if (!NetworkInfo.networkInfo.isReachable())
					return;
				
				//Get user info
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
			if (cagePill != null) cagePill.dispose();
			if (e.userInfo.cage != null && e.userInfo.cage != "" && String(e.userInfo.cage).indexOf("n/a") == -1)
			{
				cagePill = new ChartTreatmentPill(ModelLocator.resourceManagerInstance.getString('chartscreen','canula_age'));
				cagePill.setValue(e.userInfo.cage);
				cagePill.touchable = false;
				infoContainer.addChild(cagePill);
			}
			
			//IAGE
			if (iagePill != null) iagePill.dispose();
			if (e.userInfo.iage != null && e.userInfo.iage != "" && String(e.userInfo.iage).indexOf("n/a") == -1)
			{
				iagePill = new ChartTreatmentPill(ModelLocator.resourceManagerInstance.getString('chartscreen','insulin_age'));
				iagePill.setValue(e.userInfo.iage);
				iagePill.touchable = false;
				infoContainer.addChild(iagePill);
			}
			
			//Blood Glucose Outcome
			if (outcomePill != null) outcomePill.dispose();
			if (e.userInfo.outcome != null && !isNaN(e.userInfo.outcome))
			{
				outcomePill = new ChartTreatmentPill(ModelLocator.resourceManagerInstance.getString('chartscreen','glucose_outcome'));
				outcomePill.setValue(e.userInfo.outcome + " " + GlucoseHelper.getGlucoseUnit());
				outcomePill.touchable = false;
				infoContainer.addChild(outcomePill);
			}
			
			//Blood Glucose Effect
			if (effectPill != null) effectPill.dispose();
			if (e.userInfo.effect != null && !isNaN(e.userInfo.effect))
			{
				effectPill = new ChartTreatmentPill(ModelLocator.resourceManagerInstance.getString('chartscreen','glucose_effect'));
				effectPill.setValue(e.userInfo.effect + " " + GlucoseHelper.getGlucoseUnit());
				effectPill.touchable = false;
				infoContainer.addChild(effectPill);
			}
			
			//Basal Rate
			if (basalPill != null) basalPill.dispose();
			if (e.userInfo.basal != null && e.userInfo.basal != "" && String(e.userInfo.basal).indexOf("n/a") == -1)
			{
				basalPill = new ChartTreatmentPill(ModelLocator.resourceManagerInstance.getString('chartscreen','basal_insulin'));
				basalPill.setValue(e.userInfo.basal);
				basalPill.touchable = false;
				infoContainer.addChild(basalPill);
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
			
			if (outcomePill != null)
			{
				outcomePill.removeFromParent();
				outcomePill.dispose();
				outcomePill = null;
			}
			
			if (effectPill != null)
			{
				effectPill.removeFromParent();
				effectPill.dispose();
				effectPill = null;
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
			if (lowestCurveLabel != null)
			{
				lowestCurveLabel.removeFromParent();
				lowestCurveLabel.dispose();
				lowestCurveLabel = null;
			}
			
			if (middleCurveLabel != null)
			{
				middleCurveLabel.removeFromParent();
				middleCurveLabel.dispose();
				middleCurveLabel = null;
			}
			
			if (highestCurveLabel != null)
			{
				highestCurveLabel.removeFromParent();
				highestCurveLabel.dispose();
				highestCurveLabel = null;
			}
			
			if (lastCurveLabel != null)
			{
				lastCurveLabel.removeFromParent();
				lastCurveLabel.dispose();
				lastCurveLabel = null;
			}
			
			if (nowCurveMarker != null)
			{
				nowCurveMarker.removeFromParent();
				nowCurveMarker.dispose();
				nowCurveMarker = null;
			}
			
			if (nowCurveLabel != null)
			{
				nowCurveLabel.removeFromParent();
				nowCurveLabel.dispose();
				nowCurveLabel = null;
			}
			
			if (firstCurveLabel != null)
			{
				firstCurveLabel.removeFromParent();
				firstCurveLabel.dispose();
				firstCurveLabel = null;
			}
			
			if (xAxisCurve != null)
			{
				xAxisCurve.removeFromParent();
				xAxisCurve.dispose();
				xAxisCurve = null;
			}
			
			if (yAxisCurve != null)
			{
				yAxisCurve.removeFromParent();
				yAxisCurve.dispose();
				yAxisCurve = null;
			}
			
			if (curve != null)
			{
				curve.removeFromParent();
				curve.dispose();
				curve = null;
			}
			
			if (absorptionGraph != null)
			{
				absorptionGraph.removeFromParent();
				absorptionGraph.dispose();
				absorptionGraph = null;
			}
			
			if (carbsCurve != null)
			{
				carbsCurve.removeFromParent();
				carbsCurve.dispose();
				carbsCurve = null;
			}
			
			if (insulinCurve != null)
			{
				insulinCurve.removeFromParent();
				insulinCurve.dispose();
				insulinCurve = null;
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
			/* Event Listeners */
			CalibrationService.instance.removeEventListener(CalibrationServiceEvent.INITIAL_CALIBRATION_EVENT, onCaibrationReceived);
			CalibrationService.instance.removeEventListener(CalibrationServiceEvent.NEW_CALIBRATION_EVENT, onCaibrationReceived);
			Spike.instance.removeEventListener(SpikeEvent.APP_IN_FOREGROUND, onAppInForeground);
			NightscoutService.instance.removeEventListener(UserInfoEvent.USER_INFO_RETRIEVED, onUserInfoRetrieved);
			
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