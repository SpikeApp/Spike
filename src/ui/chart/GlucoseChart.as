package ui.chart
{ 
	import com.freshplanet.ane.AirBackgroundFetch.BackgroundFetch;
	
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.system.System;
	import flash.utils.Timer;
	
	import database.BgReading;
	import database.BlueToothDevice;
	import database.Calibration;
	import database.CommonSettings;
	
	import events.CalibrationServiceEvent;
	import events.SpikeEvent;
	
	import feathers.controls.Button;
	import feathers.controls.Callout;
	import feathers.controls.DateTimeMode;
	import feathers.controls.DateTimeSpinner;
	import feathers.controls.DragGesture;
	import feathers.controls.Label;
	import feathers.controls.LayoutGroup;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.HorizontalLayout;
	import feathers.layout.VerticalAlign;
	import feathers.layout.VerticalLayout;
	
	import model.ModelLocator;
	
	import services.CalibrationService;
	
	import starling.display.Quad;
	import starling.display.Shape;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.utils.Align;
	
	import treatments.Insulin;
	import treatments.ProfileManager;
	import treatments.Treatment;
	import treatments.TreatmentsManager;
	
	import ui.AppInterface;
	import ui.popups.AlertManager;
	import ui.screens.display.LayoutFactory;
	
	import utils.Constants;
	import utils.DeviceInfo;
	import utils.TimeSpan;
	
	[ResourceBundle("chartscreen")]
	
	public class GlucoseChart extends Sprite
	{
		//Constants
		private static const MAIN_CHART:String = "mainChart";
		private static const SCROLLER_CHART:String = "scrollerChart";
		private static const ONE_DAY_IN_MINUTES:Number = 24 * 60;
		private static const NUM_MINUTES_MISSED_READING_GAP:int = 6;
		private static const TIME_75_SECONDS:int = 75 * 1000;
		private static const TIME_5_MINUTES:int = 5 * 60 * 1000;
		private static const TIME_6_MINUTES:int = 6 * 60 * 1000;
		private static const TIME_16_MINUTES:int = 16 * 60 * 1000;
		private static const TIME_1_HOUR:int = 60 * 60 * 1000;
		private static const TIME_2_HOURS:int = 2 * 60 * 60 * 1000;
		private static const TIME_3_HOURS:int = 3 * 60 * 60 * 1000;
		private static const TIME_4_HOURS:int = 4 * 60 * 60 * 1000;
		private static const TIME_24_HOURS:int = 24 * 60 * 60 * 1000;
		private static const TIME_23_HOURS_57_MINUTES:int = TIME_24_HOURS - (3 * 60 * 1000);
		public static const TIMELINE_1H:Number = 14;
		public static const TIMELINE_3H:Number = 8;
		public static const TIMELINE_6H:Number = 4;
		public static const TIMELINE_12H:Number = 2;
		public static const TIMELINE_24H:Number = 1;
		
		//Data
		private var _dataSource:Array;
		private var mainChartGlucoseMarkersList:Array;
		private var scrollChartGlucoseMarkersList:Array;
		private var mainChartLineList:Array;
		private var scrollerChartLineList:Array;
		private var lastBGreadingTimeStamp:Number;
		private var firstBGReadingTimeStamp:Number;
		
		//Visual Settings
		private var _graphWidth:Number;
		private var _graphHeight:Number;
		private var timelineRange:int;
		private var _scrollerWidth:Number;
		private var _scrollerHeight:Number;
		private var lowestGlucoseValue:Number;
		private var highestGlucoseValue:Number;
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
		private var legendMargin:int = 5;
		private var legendSize:int = 10;
		private var legendTextSize:int = 12;
		private var graphDisplayTextSize:int = 20;
		private var glucoseUnit:String = "mg/dL";
		private var handPickerStrokeThickness:int = 1;
		private var chartTopPadding:int = 84;
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
		
		//Display Objects
		private var glucoseTimelineContainer:Sprite;
		private var mainChart:Sprite;
		private var glucoseDelimiter:Shape;
		private var scrollerChart:Sprite;
		private var handPicker:Sprite;
		private var glucoseValueDisplay:Label;
		private var yAxisContainer:Sprite;
		private var mainChartContainer:Sprite;
		private var differenceInMinutesForAllTimestamps:Number;
		private var mainChartMask:Quad;
		
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
		
		//Treatments
		private var treatmentsFirstRun:Boolean = true;
		private var treatmentsActive:Boolean = true;
		private var treatmentsContainer:Sprite;
		private var treatmenstsList:Array = [];
		private var treatmentCallout:Callout;
		private var IOBPill:ChartTreatmentPill;

		private var glucoseSlopePill:ChartInfoPill;

		private var glucoseTimeAgoPill:ChartInfoPill;

		private var ago:String;

		private var now:String;
		
		public function GlucoseChart(timelineRange:int, chartWidth:Number, chartHeight:Number, scrollerWidth:Number, scrollerHeight:Number)
		{
			//Set properties
			this.timelineRange = timelineRange;
			this._graphWidth = chartWidth;
			this._graphHeight = chartHeight;
			this._scrollerWidth = scrollerWidth;
			this._scrollerHeight = scrollerHeight;
			this.mainChartGlucoseMarkersList = [];
			this.scrollChartGlucoseMarkersList = [];
			this.mainChartLineList = [];
			this.scrollerChartLineList = [];
			
			//Unit
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true") 
				glucoseUnit = "mg/dL";
			else
				glucoseUnit = "mmol/L";
			
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
			
			//Add timeline to display list
			glucoseTimelineContainer = new Sprite();
			addChild(glucoseTimelineContainer);
			
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
			 * Main Chart
			 */
			mainChart = drawChart(MAIN_CHART, _graphWidth - yAxisMargin, _graphHeight, yAxisMargin, mainChartGlucoseMarkerRadius);
			mainChart.x = -mainChart.width + _graphWidth - yAxisMargin;
			mainChartContainer = new Sprite();
			mainChartContainer.addChild(mainChart);
			
			//Add main chart to the display list
			glucoseTimelineContainer.addChild(mainChartContainer);
			
			//Mask (Only show markers before the delimiter)
			mainChartMask = new Quad(yAxisMargin, _graphHeight, fakeChartMaskColor);
			mainChartMask.x = _graphWidth - mainChartMask.width;
			mainChartContainer.addChild(mainChartMask);
			
			/**
			 * Status Text Displays
			 */
			createStatusTextDisplays();
			
			/**
			 * yAxis Line
			 */
			yAxisContainer = drawYAxis();
			addChild(yAxisContainer);
			
			/**
			 * Add Treatments
			 */
			if (TreatmentsManager.treatmentsList != null && TreatmentsManager.treatmentsList.length > 0 && treatmentsActive)
			{
				for (var i:int = 0; i < TreatmentsManager.treatmentsList.length; i++) 
				{
					var treatment:Treatment = TreatmentsManager.treatmentsList[i] as Treatment;
					if (treatment != null)
						addTreatment(treatment);
				}
				
				//Update Display Treatments Values
				calculateTotalIOB();
			}
			
			/**
			 * Scroller
			 */
			//Create scroller
			scrollerChart = drawChart(SCROLLER_CHART, _scrollerWidth - (scrollerChartGlucoseMarkerRadius * 2), _scrollerHeight, 0, scrollerChartGlucoseMarkerRadius);
			
			if(!_displayLine)
				scrollerChart.y = _graphHeight + scrollerTopPadding;
			else
				scrollerChart.y = _graphHeight + scrollerTopPadding - 0.1;
			
			if (timelineActive)
				scrollerChart.y += 10;
			
			//Create scroller background
			var scrollerBackground:Quad = new Quad(_scrollerWidth, _scrollerHeight, 0x282a32);
			scrollerBackground.y = scrollerChart.y;
			
			//Add scroller and background to the display list
			glucoseTimelineContainer.addChild(scrollerBackground);
			glucoseTimelineContainer.addChild(scrollerChart);
			
			/**
			 * Hand Picker
			 */
			//Create Hand Picker
			handPicker = new Sprite();
			var handPickerFill:Quad = new Quad(_graphWidth/timelineRange, _scrollerHeight, 0xFFFFFF);
			handPicker.addChild(handPickerFill);
			handPicker.x = _graphWidth - handPicker.width;
			handPicker.y = scrollerChart.y;
			handPicker.alpha = .2;
			handPickerWidth = handPicker.width;
			
			//Outline for hand picker
			var handpickerOutline:Shape = GraphLayoutFactory.createOutline(handPicker.width, handPicker.height, handPickerStrokeThickness);
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
			statusUpdateTimer = new Timer(15 * 1000);
			statusUpdateTimer.addEventListener(TimerEvent.TIMER, onUpdateTimerRefresh, false, 0, true);
			statusUpdateTimer.start();
			
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
		}
		
		private function drawChart(chartType:String, chartWidth:Number, chartHeight:Number, chartRightMargin:Number, glucoseMarkerRadius:Number):Sprite
		{
			var chartContainer:Sprite = new Sprite();
			
			/**
			 * Calculation of X Axis scale factor
			 */
			//Get first and last timestamp and determine the difference between the two
			if (!dummyModeActive)
			{
				firstBGReadingTimeStamp = Number(_dataSource[0].timestamp);
				lastBGreadingTimeStamp = (new Date()).valueOf();
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
				if (differenceInMinutesForAllTimestamps > ONE_DAY_IN_MINUTES)
					differenceInMinutesForAllTimestamps = ONE_DAY_IN_MINUTES;
				
				scaleXFactor = 1/(totalTimestampDifference / (chartWidth * (timelineRange / (ONE_DAY_IN_MINUTES / differenceInMinutesForAllTimestamps))));
				mainChartXFactor = scaleXFactor;
			}
			else if (chartType == SCROLLER_CHART)
				scaleXFactor = 1/(totalTimestampDifference / (chartWidth - chartRightMargin));
			
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
			if(_displayLine)
			{
				var line:Shape = new Shape();
				line.graphics.lineStyle(1, 0xFFFFFF, 1);
			}
			
			/**
			 * Creation and placement of the glucose values
			 */
			//Loop through all available data points
			var dataLength:int = _dataSource.length;
			for(i = 0; i < dataLength; i++)
			{
				//Get current glucose value
				var currentGlucoseValue:Number = Number(_dataSource[i].calculatedValue);
				if(currentGlucoseValue < 40)
					currentGlucoseValue = 40;
				else if (currentGlucoseValue > 400)
					currentGlucoseValue = 400;
				
				//Define glucose marker x position
				var glucoseX:Number;
				if(i==0)
					glucoseX = 0;
				else
					glucoseX = (Number(_dataSource[i].timestamp) - Number(_dataSource[i-1].timestamp)) * scaleXFactor;
				
				//Define glucose marker y position
				var glucoseY:Number = chartHeight - (glucoseMarkerRadius * 2) - ((currentGlucoseValue - lowestGlucoseValue) * scaleYFactor);
				//If glucose is a perfect flat line then display it in the middle
				if(totalGlucoseDifference == 0) 
					glucoseY = (chartHeight - (glucoseMarkerRadius*2)) / 2;
				
				// Create Glucose Marker
				var glucoseMarker:GlucoseMarker = new GlucoseMarker
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
				
				//Hide glucose marker if it is out of bounds (fixed size chart);
				if (glucoseMarker.glucoseValue < lowestGlucoseValue || glucoseMarker.glucoseValue > highestGlucoseValue)
					glucoseMarker.alpha = 0;
				else
					glucoseMarker.alpha = 1;
				
				//Draw line
				if(_displayLine && glucoseMarker.bgReading != null && (glucoseMarker.bgReading.sensor != null || BlueToothDevice.isFollower()) && glucoseMarker.glucoseValue >= lowestGlucoseValue && glucoseMarker.glucoseValue <= highestGlucoseValue)
				{
					if(i == 0)
						line.graphics.moveTo(glucoseMarker.x, glucoseMarker.y);
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
							currentLineY = glucoseMarker.y + (glucoseMarker.height);
						}
						
						//Determine if missed readings are bigger than the acceptable gap. If so, the line will be gray;
						line.graphics.lineStyle(1, glucoseMarker.color, 1);
						if(i > 0)
						{
							var elapsedMinutes:Number = TimeSpan.fromDates(new Date(previousGlucoseMarker.timestamp), new Date(glucoseMarker.timestamp)).minutes;
							if (elapsedMinutes > NUM_MINUTES_MISSED_READING_GAP)
								line.graphics.lineStyle(1, oldColor, 1);
						}	
						
						line.graphics.lineTo(currentLineX, currentLineY);
						line.graphics.moveTo(currentLineX, currentLineY);
					}
					//Hide glucose marker
					glucoseMarker.alpha = 0;
				}
				
				//Hide markers without sensor
				var glucoseReading:BgReading = _dataSource[i] as BgReading;
				if (glucoseReading.sensor == null && !BlueToothDevice.isFollower())
					glucoseMarker.alpha = 0;
				
				//Set variables for next iteration
				previousXCoordinate = glucoseMarker.x;
				previousYCoordinate = glucoseMarker.y;
				previousGlucoseMarker = glucoseMarker;
				
				//Add glucose marker to the timeline
				chartContainer.addChild(glucoseMarker);
				
				//Add glucose marker to the displayObjects array for later reference 
				if(chartType == MAIN_CHART)
					mainChartGlucoseMarkersList.push(glucoseMarker);
				else if (chartType == SCROLLER_CHART)
					scrollChartGlucoseMarkersList.push(glucoseMarker);
			}
			
			//Creat dummy marker in case the current timestamp is bigger than the latest bgreading timestamp
			if (!dummyModeActive)
			{
				if (lastBGreadingTimeStamp > Number(_dataSource[_dataSource.length - 1].timestamp) && lastBGreadingTimeStamp - Number(_dataSource[_dataSource.length - 1].timestamp) > (4.5 * 60 * 1000) && chartType == MAIN_CHART)
				{
					var dummy:Sprite = new Sprite();
					dummy.x = (lastBGreadingTimeStamp - firstBGReadingTimeStamp) * scaleXFactor;
					chartContainer.addChild(dummy);
				}
			}
			
			//Define scroll multiplier for scroller vs main graph
			if (handPicker != null && chartType == MAIN_CHART)
			{
				if (mainChart.x > 0)
					scrollMultiplier = Math.abs(mainChart.width - (glucoseMarkerRadius * 2))/handPicker.x;
				else
					scrollMultiplier = Math.abs(mainChart.x)/handPicker.x;
			}
			
			//Chart Line
			if(_displayLine)
			{
				//Add line to the display list
				chartContainer.addChild(line);
				
				//Save line references for later use
				if(chartType == MAIN_CHART)
					mainChartLineList.push(line);
				else if (chartType == SCROLLER_CHART)
					scrollerChartLineList.push(line);
			}
			
			if(chartType == MAIN_CHART)
				mainChartYFactor = scaleYFactor;
			
			return chartContainer;
		}
		
		public function calculateTotalIOB():void
		{
			if (!BackgroundFetch.appIsInForeground() || !Constants.appInForeground || dummyModeActive)
				return;
			
			if (treatmentsActive && TreatmentsManager.treatmentsList != null && TreatmentsManager.treatmentsList.length > 0 && IOBPill != null && mainChartGlucoseMarkersList != null && mainChartGlucoseMarkersList.length > 0)
			{
				IOBPill.setValue(TreatmentsManager.getTotalIOB() + "U");
				IOBPill.x = _graphWidth - IOBPill.width -glucoseStatusLabelsMargin - 2;
				IOBPill.visible = true;
			}
			
			if (treatmentsActive && (TreatmentsManager.treatmentsList == null || TreatmentsManager.treatmentsList.length == 0))
			{
				IOBPill.setValue("0U");
				IOBPill.x = _graphWidth - IOBPill.width -glucoseStatusLabelsMargin - 2;
				IOBPill.visible = true;
			}
		}
		
		public function addTreatment(treatment:Treatment):void
		{
			//Setup initial timeline/mask properties
			if (treatmentsFirstRun && treatmentsContainer == null)
			{
				treatmentsContainer = new Sprite();
				treatmentsContainer.x = mainChart.x;
				treatmentsContainer.y = mainChart.y;
				mainChartContainer.addChild(treatmentsContainer);
				treatmentsFirstRun = false;
			}
			
			//Check treatment type
			if (treatment.type == Treatment.TYPE_BOLUS || treatment.type == Treatment.TYPE_CORRECTION_BOLUS)
			{
				//Create treatment marker and add it to the chart
				var insulinMarker:InsulinMarker = new InsulinMarker(treatment);
				insulinMarker.x = (insulinMarker.treatment.timestamp - firstBGReadingTimeStamp) * mainChartXFactor;
				insulinMarker.y = _graphHeight - (insulinMarker.radius * 1.66) - ((insulinMarker.treatment.glucoseEstimated - lowestGlucoseValue) * mainChartYFactor);
				insulinMarker.addEventListener(TouchEvent.TOUCH, onDisplayTreatmentDetails);
				treatmentsContainer.addChild(insulinMarker);
				
				insulinMarker.index = treatmenstsList.length;
				treatmenstsList.push(insulinMarker);
				
				calculateTotalIOB();
			}
			else if (treatment.type == Treatment.TYPE_NOTE)
			{
				//Create treatment marker and add it to the chart
				var noteMarker:NoteMarker = new NoteMarker(treatment);
				noteMarker.x = ((noteMarker.treatment.timestamp - firstBGReadingTimeStamp) * mainChartXFactor) + mainChartGlucoseMarkerRadius;
				noteMarker.y = _graphHeight - noteMarker.height - ((noteMarker.treatment.glucoseEstimated - lowestGlucoseValue) * mainChartYFactor) - (mainChartGlucoseMarkerRadius * 3);
				noteMarker.addEventListener(TouchEvent.TOUCH, onDisplayTreatmentDetails);
				treatmentsContainer.addChild(noteMarker);
				
				noteMarker.index = treatmenstsList.length;
				treatmenstsList.push(noteMarker);
			}
			else if (treatment.type == Treatment.TYPE_GLUCOSE_CHECK)
			{
				//Create treatment marker and add it to the chart
				var glucoseCheckMarker:BGCheckMarker = new BGCheckMarker(treatment);
				glucoseCheckMarker.x = (glucoseCheckMarker.treatment.timestamp - firstBGReadingTimeStamp) * mainChartXFactor;
				glucoseCheckMarker.y = _graphHeight - (glucoseCheckMarker.radius * 1.66) - ((glucoseCheckMarker.treatment.glucoseEstimated - lowestGlucoseValue) * mainChartYFactor);
				glucoseCheckMarker.addEventListener(TouchEvent.TOUCH, onDisplayTreatmentDetails);
				treatmentsContainer.addChild(glucoseCheckMarker);
				
				glucoseCheckMarker.index = treatmenstsList.length;
				treatmenstsList.push(glucoseCheckMarker);
			}
			
			if (mainChartMask != null && mainChartContainer != null)
				mainChartContainer.addChild(mainChartMask);
		}
		
		private function onDisplayTreatmentDetails(e:starling.events.TouchEvent):void
		{
			var touch:Touch = e.getTouch(stage);
			
			if(touch != null && touch.phase == TouchPhase.BEGAN) 
			{
				var treatment:ChartTreatment = e.currentTarget as ChartTreatment;
				
				var treatmentLayout:VerticalLayout = new VerticalLayout();
				treatmentLayout.horizontalAlign = HorizontalAlign.CENTER;
				treatmentLayout.gap = 10;
				var treatmentContainer:LayoutGroup = new LayoutGroup();
				treatmentContainer.layout = treatmentLayout;
				
				//Treatment Value
				var treatmentValue:String = "";
				var treatmentNotes:String = treatmentNotes = treatment.treatment.note;
				if (treatment.treatment.type == Treatment.TYPE_BOLUS || treatment.treatment.type == Treatment.TYPE_CORRECTION_BOLUS)
				{
					var insulin:Insulin = ProfileManager.getInsulin(treatment.treatment.insulinID);
					treatmentValue = (insulin != null ? insulin.name + "\n" : "") + treatment.treatment.insulinAmount + " U";
				}
				else if (treatment.treatment.type == Treatment.TYPE_NOTE)
				{
					treatmentValue = "Note";
				}
				else if (treatment.treatment.type == Treatment.TYPE_GLUCOSE_CHECK)
				{
					var glucoseValue:Number;
					if (glucoseUnit == "mg/dL")
						glucoseValue = treatment.treatment.glucose;
					else
						glucoseValue = Math.round(((BgReading.mgdlToMmol((treatment.treatment.glucose))) * 10)) / 10; 
					
					treatmentValue = "BG Check\n" + glucoseValue + " " + glucoseUnit;
				}
				
				if (treatmentValue != "")
				{
					var value:Label = LayoutFactory.createLabel(treatmentValue, HorizontalAlign.CENTER, VerticalAlign.TOP, 14, true);
					value.paddingBottom = 12;
					treatmentContainer.addChild(value);
				}
				
				//Treatment Time
				var time:DateTimeSpinner = new DateTimeSpinner();
				time.editingMode = DateTimeMode.TIME;
				time.value = new Date(treatment.treatment.timestamp);
				time.height = 30;
				time.paddingTop = time.paddingBottom = 0;
				var timeSpacer:Sprite = new Sprite();
				timeSpacer.height = 10;
				treatmentContainer.addChild(time);
				treatmentContainer.addChild(timeSpacer);
				
				if (treatmentNotes != "")
				{
					var notes:Label = LayoutFactory.createLabel(treatmentNotes, HorizontalAlign.CENTER, VerticalAlign.TOP);
					notes.wordWrap = true;
					notes.maxWidth = 150;
					treatmentContainer.addChild(notes);
				}
				
				//Action Buttons
				var actionsLayout:HorizontalLayout = new HorizontalLayout();
				actionsLayout.gap = 5;
				var actionsContainer:LayoutGroup = new LayoutGroup();
				actionsContainer.layout = actionsLayout;
				
				var moveBtn:Button = LayoutFactory.createButton("Move");
				moveBtn.addEventListener(starling.events.Event.TRIGGERED, onMove);
				actionsContainer.addChild(moveBtn);
				var deleteBtn:Button = LayoutFactory.createButton("Delete");
				deleteBtn.addEventListener(starling.events.Event.TRIGGERED, onDelete);
				actionsContainer.addChild(deleteBtn);
				treatmentContainer.addChild(actionsContainer);
				
				treatmentCallout = Callout.show(treatmentContainer, treatment, null, true);
				
				function onDelete(e:starling.events.Event):void
				{
					treatmentsContainer.removeChild(treatment);
					treatmenstsList.removeAt(treatment.index);
					
					treatmentCallout.close(true);
					
					TreatmentsManager.deleteTreatment(treatment.treatment);
					
					treatment.dispose();
					treatment = null;
					
					calculateTotalIOB();
				}
				
				function onMove(e:starling.events.Event):void
				{
					var movedTimestamp:Number = time.value.valueOf();
					
					if(movedTimestamp < firstBGReadingTimeStamp || movedTimestamp > lastBGreadingTimeStamp)
					{
						AlertManager.showSimpleAlert
						(
							"Warning",
							"Selected time is outside of your first or last reading in the chart! Please choose a different time."
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
						manageTreatments();
						
						treatmentCallout.close(true);
						
						if (treatment.treatment.type == Treatment.TYPE_BOLUS || treatment.treatment.type == Treatment.TYPE_CORRECTION_BOLUS || treatment.treatment.type == Treatment.TYPE_MEAL_BOLUS)
							calculateTotalIOB();
						
						//Update database
						TreatmentsManager.updateTreatment(treatment.treatment);
					}
				}
			}
		}
		
		private function manageTreatments():void
		{
			if (treatmentsContainer == null || !treatmentsActive)
				return;
			
			//Reposition Container
			treatmentsContainer.x = mainChart.x;
			treatmentsContainer.y = mainChart.y;
			
			if (treatmenstsList != null && treatmenstsList.length > 0)
			{
				//Loop through all treatments
				for(var i:int = treatmenstsList.length - 1 ; i >= 0; i--)
				{
					var treatment:ChartTreatment = treatmenstsList[i];
					if (treatment.treatment.timestamp < firstBGReadingTimeStamp)
					{
						//Treatment has expired (>24H). Discart it
						treatmentsContainer.removeChild(treatment);
						treatmenstsList.removeAt(i);
						treatment.dispose();
						treatment = null;
					}
					else
					{
						//Treatment is still valid. Reposition it.
						if (treatment.treatment.type == Treatment.TYPE_BOLUS || treatment.treatment.type == Treatment.TYPE_CORRECTION_BOLUS || treatment.treatment.type == Treatment.TYPE_GLUCOSE_CHECK)
						{
							treatment.x = (treatment.treatment.timestamp - firstBGReadingTimeStamp) * mainChartXFactor;
							treatment.y = _graphHeight - (treatment.radius * 1.66) - ((treatment.treatment.glucoseEstimated - lowestGlucoseValue) * mainChartYFactor);
						}
						else if (treatment.treatment.type == Treatment.TYPE_NOTE)
						{
							treatment.x = ((treatment.treatment.timestamp - firstBGReadingTimeStamp) * mainChartXFactor) + mainChartGlucoseMarkerRadius;
							treatment.y = _graphHeight - treatment.height - (mainChartGlucoseMarkerRadius * 3) - ((treatment.treatment.glucoseEstimated - lowestGlucoseValue) * mainChartYFactor) + (mainChartGlucoseMarkerRadius / 2);
						}
					}
				}
			}
		}
		
		private function drawTimeline():void
		{
			//Safeguards
			if (mainChart == null || dummyModeActive || !timelineActive)
				return;
			
			//Setup initial timeline/mask properties
			if (timelineFirstRun && timelineContainer == null)
			{
				timelineContainer = new Sprite();
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
						timelineContainer.removeChild(displayObject);
						displayObject.dispose();
						displayObject.removeChildren()
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
			
			while (initialTimestamp <= lastTimestamp + TIME_1_HOUR) 
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
					fontSize = 11;
				else
					fontSize = 10;
				
				var time:Label = LayoutFactory.createLabel(label, HorizontalAlign.CENTER, VerticalAlign.TOP, fontSize, false, axisFontColor);
				time.validate();
				
				//Add marker to display list
				var timeDisplayContainer:Sprite = new Sprite();
				timeDisplayContainer.addChild(time);
				timeDisplayContainer.x =  currentX - (time.width / 2);
				timelineContainer.addChild(timeDisplayContainer);
				
				//Save marker for later processing/disposing
				timelineObjects.push(timeDisplayContainer);
				
				//Update loop condition
				if (timelineRange == TIMELINE_1H || timelineRange == TIMELINE_3H || timelineRange == TIMELINE_6H)
					initialTimestamp += TIME_1_HOUR;
				else if (timelineRange == TIMELINE_12H)
					initialTimestamp += TIME_2_HOURS;
				else if (timelineRange == TIMELINE_24H && dateFormat.slice(0,2) == "24")
					initialTimestamp += TIME_3_HOURS;
				else if (timelineRange == TIMELINE_24H && dateFormat.slice(0,2) == "12")
					initialTimestamp += TIME_4_HOURS;
			}
			
			if (scrollerChart != null)
				timelineContainer.y = scrollerChart.y - timelineContainer.height - 1;
		}
		
		private function drawYAxis():Sprite
		{
			//Create Axis Holder
			var yAxis:Sprite = new Sprite();
			
			//Create Axis Main Vertical Line
			var yAxisLine:Shape = GraphLayoutFactory.createVerticalLine(_graphHeight, lineThickness, lineColor);
			yAxisLine.x = _graphWidth - (lineThickness/2);
			yAxisLine.y = 0;
			yAxis.addChild(yAxisLine);
			
			/**
			 * Glucose Delimiter
			 */
			glucoseDelimiter = GraphLayoutFactory.createVerticalDashedLine(_graphHeight, dashLineWidth, dashLineGap, dashLineThickness, lineColor);
			glucoseDelimiter.y = 0;
			glucoseDelimiter.x = _graphWidth - yAxisMargin;
			yAxis.addChild(glucoseDelimiter);
			
			/**
			 * Highest Glucose
			 */
			//Line Marker
			var highestGlucoseLineMarker:Shape = GraphLayoutFactory.createHorizontalLine(legendSize, lineThickness, lineColor);
			highestGlucoseLineMarker.x = _graphWidth - legendSize;
			highestGlucoseLineMarker.y = lineThickness/2;
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
			
			var highestGlucoseLegend:Label = GraphLayoutFactory.createGraphLegend(highestGlucoseOutput, axisFontColor, legendTextSize * userAxisFontMultiplier);
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
			var lowestGlucoseLineMarker:Shape = GraphLayoutFactory.createHorizontalLine(legendSize, lineThickness, lineColor);
			lowestGlucoseLineMarker.x = _graphWidth - legendSize;
			lowestGlucoseLineMarker.y = _graphHeight - (lineThickness/2);
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
			
			var lowestGlucoseLegend:Label = GraphLayoutFactory.createGraphLegend(lowestGlucoseOutput, axisFontColor, legendTextSize * userAxisFontMultiplier);
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
				var highUrgentGlucoseLineMarker:Shape = GraphLayoutFactory.createHorizontalLine(legendSize, lineThickness, lineColor);
				highUrgentGlucoseLineMarker.x = _graphWidth - legendSize;
				highUrgentGlucoseLineMarker.y = _graphHeight - ((glucoseUrgentHigh - lowestGlucoseValue) * scaleYFactor);
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
				
				var highUrgentGlucoseLegend:Label = GraphLayoutFactory.createGraphLegend(urgentHighGlucoseOutput, axisFontColor, legendTextSize * userAxisFontMultiplier);
				if (userAxisFontMultiplier >= 1)
					highUrgentGlucoseLegend.y = _graphHeight - ((glucoseUrgentHigh - lowestGlucoseValue) * scaleYFactor) - ((highUrgentGlucoseLegend.height / userAxisFontMultiplier) / 2) - ((highUrgentGlucoseLegend.height / userAxisFontMultiplier) / 15);
				else
					highUrgentGlucoseLegend.y = _graphHeight - ((glucoseUrgentHigh - lowestGlucoseValue) * scaleYFactor) - ((highUrgentGlucoseLegend.height * userAxisFontMultiplier) / 2) - ((highUrgentGlucoseLegend.height * userAxisFontMultiplier) / 15);
				highUrgentGlucoseLegend.x = Math.round(_graphWidth - highestGlucoseLineMarker.width - highUrgentGlucoseLegend.width - legendMargin);
				yAxis.addChild(highUrgentGlucoseLegend);
				
				//Dashed Line
				var highUrgentGlucoseDashedLine:Shape = GraphLayoutFactory.createHorizontalDashedLine(_graphWidth, dashLineWidth, dashLineGap, dashLineThickness, lineColor, legendMargin + dashLineWidth + ((legendTextSize * userAxisFontMultiplier) - legendTextSize));
				highUrgentGlucoseDashedLine.y = _graphHeight - ((glucoseUrgentHigh - lowestGlucoseValue) * scaleYFactor);
				yAxis.addChild(highUrgentGlucoseDashedLine);
			}
			
			/**
			 * High Glucose Threshold
			 */
			if(glucoseHigh > lowestGlucoseValue && glucoseHigh < highestGlucoseValue)
			{
				//Line Marker
				var highGlucoseLineMarker:Shape = GraphLayoutFactory.createHorizontalLine(legendSize, lineThickness, lineColor);
				highGlucoseLineMarker.x = _graphWidth - legendSize;
				highGlucoseLineMarker.y = _graphHeight - ((glucoseHigh - lowestGlucoseValue) * scaleYFactor);
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
				
				var highGlucoseLegend:Label = GraphLayoutFactory.createGraphLegend(highGlucoseOutput, axisFontColor, legendTextSize * userAxisFontMultiplier);
				if (userAxisFontMultiplier >= 1)
					highGlucoseLegend.y = _graphHeight - ((glucoseHigh - lowestGlucoseValue) * scaleYFactor) - ((highGlucoseLegend.height / userAxisFontMultiplier) / 2) - ((highGlucoseLegend.height / userAxisFontMultiplier) / 15);
				else
					highGlucoseLegend.y = _graphHeight - ((glucoseHigh - lowestGlucoseValue) * scaleYFactor) - ((highGlucoseLegend.height * userAxisFontMultiplier) / 2) - ((highGlucoseLegend.height * userAxisFontMultiplier) / 15);
				highGlucoseLegend.x = Math.round(_graphWidth - highestGlucoseLineMarker.width - highGlucoseLegend.width - legendMargin);
				yAxis.addChild(highGlucoseLegend);
				
				//Dashed Line
				var highGlucoseDashedLine:Shape = GraphLayoutFactory.createHorizontalDashedLine(_graphWidth, dashLineWidth, dashLineGap, dashLineThickness, lineColor, legendMargin + dashLineWidth + ((legendTextSize * userAxisFontMultiplier) - legendTextSize));
				highGlucoseDashedLine.y = _graphHeight - ((glucoseHigh - lowestGlucoseValue) * scaleYFactor);
				yAxis.addChild(highGlucoseDashedLine);
			}
			
			/**
			 * Low Glucose Threshold
			 */
			if(glucoseLow > lowestGlucoseValue && glucoseLow < highestGlucoseValue)
			{
				//Line Marker
				var lowGlucoseLineMarker:Shape = GraphLayoutFactory.createHorizontalLine(legendSize, lineThickness, lineColor);
				lowGlucoseLineMarker.x = _graphWidth - legendSize;
				lowGlucoseLineMarker.y = _graphHeight - ((glucoseLow - lowestGlucoseValue) * scaleYFactor);
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
				
				var lowGlucoseLegend:Label = GraphLayoutFactory.createGraphLegend(lowGlucoseOutput, axisFontColor, legendTextSize * userAxisFontMultiplier);
				if (userAxisFontMultiplier >= 1)
					lowGlucoseLegend.y = _graphHeight - ((glucoseLow - lowestGlucoseValue) * scaleYFactor) - ((lowGlucoseLegend.height / userAxisFontMultiplier) / 2) - ((lowGlucoseLegend.height / userAxisFontMultiplier) / 15);
				else
					lowGlucoseLegend.y = _graphHeight - ((glucoseLow - lowestGlucoseValue) * scaleYFactor) - ((lowGlucoseLegend.height * userAxisFontMultiplier) / 2) - ((lowGlucoseLegend.height * userAxisFontMultiplier) / 15);
				lowGlucoseLegend.x = Math.round(_graphWidth - lowGlucoseLineMarker.width - lowGlucoseLegend.width - legendMargin);
				yAxis.addChild(lowGlucoseLegend);
				
				//Dashed Line
				var lowGlucoseDashedLine:Shape = GraphLayoutFactory.createHorizontalDashedLine(_graphWidth, dashLineWidth, dashLineGap, dashLineThickness, lineColor, legendMargin + dashLineWidth + ((legendTextSize * userAxisFontMultiplier) - legendTextSize));
				lowGlucoseDashedLine.y = _graphHeight - ((glucoseLow - lowestGlucoseValue) * scaleYFactor);
				yAxis.addChild(lowGlucoseDashedLine);
			}
			
			/**
			 * Urgent Low Glucose Threshold
			 */
			if(glucoseUrgentLow > lowestGlucoseValue && glucoseUrgentLow < highestGlucoseValue && !dummyModeActive)
			{
				//Line Marker
				var lowUrgentGlucoseLineMarker:Shape = GraphLayoutFactory.createHorizontalLine(legendSize, lineThickness, lineColor);
				lowUrgentGlucoseLineMarker.x = _graphWidth - legendSize;
				lowUrgentGlucoseLineMarker.y = _graphHeight - ((glucoseUrgentLow - lowestGlucoseValue) * scaleYFactor);
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
				
				var lowUrgentGlucoseLegend:Label = GraphLayoutFactory.createGraphLegend(urgentLowGlucoseOutput, axisFontColor, legendTextSize * userAxisFontMultiplier);
				if (userAxisFontMultiplier >= 1)
					lowUrgentGlucoseLegend.y = _graphHeight - ((glucoseUrgentLow - lowestGlucoseValue) * scaleYFactor) - ((lowUrgentGlucoseLegend.height / userAxisFontMultiplier) / 2) - ((lowUrgentGlucoseLegend.height / userAxisFontMultiplier) / 15);
				else
					lowUrgentGlucoseLegend.y = _graphHeight - ((glucoseUrgentLow - lowestGlucoseValue) * scaleYFactor) - ((lowUrgentGlucoseLegend.height * userAxisFontMultiplier) / 2) - ((lowUrgentGlucoseLegend.height * userAxisFontMultiplier) / 15);
				lowUrgentGlucoseLegend.x = Math.round(_graphWidth - lowUrgentGlucoseLineMarker.width - lowUrgentGlucoseLegend.width - legendMargin);
				yAxis.addChild(lowUrgentGlucoseLegend);
				
				//Dashed Line
				var lowUrgentGlucoseDashedLine:Shape = GraphLayoutFactory.createHorizontalDashedLine(_graphWidth, dashLineWidth, dashLineGap, dashLineThickness, lineColor, legendMargin + dashLineWidth + ((legendTextSize * userAxisFontMultiplier) - legendTextSize));
				lowUrgentGlucoseDashedLine.y = _graphHeight - ((glucoseUrgentLow - lowestGlucoseValue) * scaleYFactor);
				yAxis.addChild(lowUrgentGlucoseDashedLine);
			}
			
			return yAxis;
		}
		
		public function addGlucose(BGReadingsList:Array):Boolean
		{
			if(BGReadingsList == null || BGReadingsList.length == 0 || !BackgroundFetch.appIsInForeground())
				return false;
			
			var latestTimestamp:Number = Number(BGReadingsList[BGReadingsList.length - 1].timestamp);
			var firstTimestamp:Number;
			
			if(_dataSource != null && _dataSource.length >= 1 && mainChartGlucoseMarkersList[0].timestamp != null && !isNaN(mainChartGlucoseMarkersList[0].timestamp))
				firstTimestamp = Number(mainChartGlucoseMarkersList[0].timestamp);
			else
				firstTimestamp = Number.NaN;
			
			if(_dataSource.length >= 1 && !isNaN(firstTimestamp) && latestTimestamp - firstTimestamp > TIME_24_HOURS + Constants.READING_OFFSET)
			{
				//Array has more than 24h of data. Remove timestamps older than 24H
				var removedMainGlucoseMarker:GlucoseMarker;
				var removedScrollerGlucoseMarker:GlucoseMarker
				var currentTimestamp:Number = Number((mainChartGlucoseMarkersList[0] as GlucoseMarker).timestamp);
				
				while (latestTimestamp - currentTimestamp > TIME_24_HOURS + Constants.READING_OFFSET) 
				{
					//Main Chart
					removedMainGlucoseMarker = mainChartGlucoseMarkersList.shift() as GlucoseMarker;
					mainChart.removeChild(removedMainGlucoseMarker);
					removedMainGlucoseMarker.dispose();
					removedMainGlucoseMarker = null;
					
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
				
				if (_dataSource.length > 288) // >24H
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
			
			//Redraw main chart and scroller chart
			redrawChart(MAIN_CHART, _graphWidth - yAxisMargin, _graphHeight, yAxisMargin, mainChartGlucoseMarkerRadius, numAddedReadings);
			redrawChart(SCROLLER_CHART, _scrollerWidth - (scrollerChartGlucoseMarkerRadius * 2), _scrollerHeight, 0, scrollerChartGlucoseMarkerRadius, numAddedReadings);
			
			//Recalculate first and last timestamp
			
			if(mainChartGlucoseMarkersList != null && mainChartGlucoseMarkersList.length > 0)
			{
				firstTimestamp = Number(mainChartGlucoseMarkersList[0].timestamp);
				latestTimestamp = Number(mainChartGlucoseMarkersList[mainChartGlucoseMarkersList.length - 1].timestamp);
			}
			
			//Adjust Main Chart amd Picker Position
			if (displayLatestBGValue)
			{
				mainChart.x = -mainChart.width + _graphWidth - yAxisMargin;
				selectedGlucoseMarkerIndex = mainChartGlucoseMarkersList[mainChartGlucoseMarkersList.length - 1].index;
			}
			else if (!isNaN(firstTimestamp) && latestTimestamp - firstTimestamp < TIME_23_HOURS_57_MINUTES)
			{
				mainChart.x -= mainChart.width - previousChartWidth;
				selectedGlucoseMarkerIndex += 1;
			}
			
			//Adjust Pcker Position
			if (!displayLatestBGValue && !isNaN(firstTimestamp) && latestTimestamp - firstTimestamp < TIME_23_HOURS_57_MINUTES && mainChart.x <= 0)
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
			manageTreatments();
			calculateTotalIOB();
			
			return true;
		}
		
		private function redrawChart(chartType:String, chartWidth:Number, chartHeight:Number, chartRightMargin:Number, glucoseMarkerRadius:Number, numNewReadings:int):void
		{
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
				if (differenceInMinutesForAllTimestamps > ONE_DAY_IN_MINUTES)
					differenceInMinutesForAllTimestamps = ONE_DAY_IN_MINUTES;
				
				//scaleXFactor = 1/(totalTimestampDifference / (chartWidth * timelineRange));
				scaleXFactor = 1/(totalTimestampDifference / (chartWidth * (timelineRange / (ONE_DAY_IN_MINUTES / differenceInMinutesForAllTimestamps))));
				mainChartXFactor = scaleXFactor;
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
			if(_displayLine)
			{
				var line:Shape = new Shape();
				line.graphics.lineStyle(1, 0xFFFFFF, 1);
			}
			
			//Loop through all available data points
			var dataLength:int = _dataSource.length;
			for(i = 0; i < dataLength; i++)
			{
				var currentGlucoseValue:Number = Number(_dataSource[i].calculatedValue);
				if (currentGlucoseValue < 40)
					currentGlucoseValue = 40;
				else if (currentGlucoseValue > 400)
					currentGlucoseValue = 400;
				
				var glucoseMarker:GlucoseMarker;
				if(i < dataLength - 1 && chartType == MAIN_CHART)
					glucoseMarker = mainChartGlucoseMarkersList[i]
				else if(i < dataLength - 1 && chartType == SCROLLER_CHART)
					glucoseMarker = scrollChartGlucoseMarkersList[i];
				
				//Define glucose marker x position
				var glucoseX:Number;
				if(i==0)
					glucoseX = 0;
				else
					glucoseX = (Number(_dataSource[i].timestamp) - Number(_dataSource[i-1].timestamp)) * scaleXFactor;
				
				//Define glucose marker y position
				var glucoseY:Number = chartHeight - (glucoseMarkerRadius*2) - ((currentGlucoseValue - lowestGlucoseValue) * scaleYFactor);
				//If glucose is a perfect flat line then display it in the middle
				if(totalGlucoseDifference == 0) 
					glucoseY = (chartHeight - (glucoseMarkerRadius*2)) / 2;
				
				if(i < dataLength - numNewReadings)
				{
					glucoseMarker.x = previousXCoordinate + glucoseX;
					glucoseMarker.y = glucoseY;
					glucoseMarker.index = i;
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
								previousGlucoseValueFormatted: previousGlucoseMarker != null ? previousGlucoseMarker.glucoseValueFormatted : null,
								previousGlucoseValue: previousGlucoseMarker != null ? previousGlucoseMarker.glucoseValue : null
							}
						);
					
					if(chartType == MAIN_CHART)
					{
						//Add it to the display list
						mainChart.addChild(glucoseMarker);
						//Save it in the array for later
						mainChartGlucoseMarkersList.push(glucoseMarker);
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
				if(_displayLine && glucoseMarker.bgReading != null && (glucoseMarker.bgReading.sensor != null || BlueToothDevice.isFollower()) && glucoseMarker.glucoseValue >= lowestGlucoseValue && glucoseMarker.glucoseValue <= highestGlucoseValue)
				{
					if(i == 0)
						line.graphics.moveTo(glucoseMarker.x, glucoseMarker.y);
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
							currentLineY = glucoseMarker.y + (glucoseMarker.height);
						}
						
						//Determine if missed readings are bigger than the acceptable gap. If so, the line will be gray;
						line.graphics.lineStyle(1, glucoseMarker.color, 1);
						if(i > 0)
						{
							var elapsedMinutes:Number = TimeSpan.fromDates(new Date(previousGlucoseMarker.timestamp), new Date(glucoseMarker.timestamp)).minutes;
							if (elapsedMinutes > NUM_MINUTES_MISSED_READING_GAP)
								line.graphics.lineStyle(1, oldColor, 1);
						}
						
						line.graphics.lineTo(currentLineX, currentLineY);
						line.graphics.moveTo(currentLineX, currentLineY);
					}
					//Hide glucose marker
					glucoseMarker.alpha = 0;
				}
				
				//Hide markers without sensor
				var glucoseReading:BgReading = _dataSource[i] as BgReading;
				if (glucoseReading.sensor == null && !BlueToothDevice.isFollower())
					glucoseMarker.alpha = 0;
				
				
				//Update variables for next iteration
				previousXCoordinate = previousXCoordinate + glucoseX;
				previousGlucoseMarker = glucoseMarker;
			}
			
			if(chartType == MAIN_CHART)
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
			if(_displayLine)
			{
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
			
			if(chartType == MAIN_CHART)
				mainChartYFactor = scaleYFactor;
		}
		
		private function drawLine(chartType:String):void 
		{
			//Line container
			var line:Shape = new Shape();
			
			//Define what chart needs line to be drawns
			var sourceList:Array;
			if(chartType == MAIN_CHART)
				sourceList = mainChartGlucoseMarkersList;
			else if (chartType == SCROLLER_CHART)
				sourceList = scrollChartGlucoseMarkersList;
			
			//Loop all markers, draw the line from their positions and also hide the markers
			var previousGlucoseMarker:GlucoseMarker;
			var dataLength:int = sourceList.length;
			for (var i:int = 0; i < dataLength; i++) 
			{
				var glucoseMarker:GlucoseMarker = sourceList[i];
				if (glucoseMarker.bgReading == null || (glucoseMarker.bgReading.sensor == null && !BlueToothDevice.isFollower()))
					continue;
				
				var glucoseDifference:Number = highestGlucoseValue - lowestGlucoseValue;
				
				if(i == 0)
				{
					if (glucoseDifference > 0)
						line.graphics.moveTo(glucoseMarker.x, glucoseMarker.y);
					else
						line.graphics.moveTo(glucoseMarker.x, glucoseMarker.y + (glucoseMarker.height/2));
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
						if (glucoseDifference > 0)
							currentLineY = glucoseMarker.y + (glucoseMarker.height);
						else
							currentLineY = glucoseMarker.y + (glucoseMarker.height/2);
					}
					
					//Determine if missed readings are bigger than the acceptable gap. If so, the line will be gray;
					line.graphics.lineStyle(1, glucoseMarker.color, 1);
					if(i > 0)
					{
						var elapsedMinutes:Number = TimeSpan.fromDates(new Date(previousGlucoseMarker.timestamp), new Date(glucoseMarker.timestamp)).minutes;
						if (elapsedMinutes > NUM_MINUTES_MISSED_READING_GAP)
							line.graphics.lineStyle(1, oldColor, 1);
					}	
					
					line.graphics.lineTo(currentLineX, currentLineY);
					line.graphics.moveTo(currentLineX, currentLineY);
				}
				//Hide glucose marker
				glucoseMarker.alpha = 0;
				previousGlucoseMarker = glucoseMarker;
			}
			
			//Add line to display list
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
		
		public function calculateDisplayLabels():void
		{
			if (currentNumberOfMakers == previousNumberOfMakers && !displayLatestBGValue)
				return;
			
			var timeAgoValue:String;
			
			if (!displayLatestBGValue && !dummyModeActive)
			{
				if (mainChartGlucoseMarkersList == null || mainChartGlucoseMarkersList.length == 0 || selectedGlucoseMarkerIndex == mainChartGlucoseMarkersList.length - 1)
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
					if (selectedGlucoseMarkerIndex > 0)
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
						glucoseTimeAgoPill.setValue(currentMarker.timeFormatted, retroOutput, differenceInMinutes <= 6 ? newColor : oldColor);
						
						//Marker Slope
						glucoseSlopePill.setValue(currentMarker.slopeOutput, glucoseUnit, differenceInMinutes <= 6 ? newColor : oldColor);
						
						selectedGlucoseMarkerIndex = currentMarker.index;
					}
					else if (mainChartGlucoseMarkersList.length > 1) /* Extra Actions */
					{
						if (previousMaker != null && currentTimelineTimestamp - previousMaker.timestamp > TIME_16_MINUTES && !hitTestCurrent)
						{
							glucoseValueDisplay.text = "---";
							glucoseValueDisplay.fontStyles.color = oldColor;
							glucoseSlopePill.setValue("", "", oldColor);
						}
						else if (previousMaker != null && currentTimelineTimestamp - previousMaker.timestamp > TIME_75_SECONDS && Math.abs(currentMarker.timestamp - currentTimelineTimestamp) > TIME_5_MINUTES && currentTimelineTimestamp - previousMaker.timestamp <= TIME_16_MINUTES && !hitTestCurrent)
						{
							glucoseValueDisplay.fontStyles.color = oldColor;
							glucoseSlopePill.setValue(glucoseSlopePill.value, glucoseSlopePill.unit, oldColor);
						}
						
						if (previousMaker != null && currentTimelineTimestamp - previousMaker.timestamp > TIME_75_SECONDS && Math.abs(currentMarker.timestamp - currentTimelineTimestamp) > TIME_5_MINUTES && !hitTestCurrent)
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
					glucoseTimeAgoPill.setValue(nextMarker.timeFormatted, retroOutput, newColor);
					
					//Marker Slope
					glucoseSlopePill.setValue(nextMarker.slopeOutput, glucoseUnit, newColor);
					
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
						timeAgoValue = TimeSpan.formatHoursMinutesFromSeconds(differenceInSeconds);
						if (timeAgoValue != now)
							glucoseTimeAgoPill.setValue(timeAgoValue, ago, oldColor);
						else
							glucoseTimeAgoPill.setValue("0m", now, oldColor);
						
						//Marker Slope
						glucoseSlopePill.setValue(ModelLocator.resourceManagerInstance.getString('chartscreen','slope_unknown'), "", oldColor);
						
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
					
					if (timestampDifference <= TIME_16_MINUTES)
					{
						//Glucose Value Display
						glucoseValueDisplay.text = latestMarker.glucoseOutput + " " + latestMarker.slopeArrow;
						if (timestampDifference <= TIME_6_MINUTES)
							glucoseValueDisplay.fontStyles.color = latestMarker.color;
						else
							glucoseValueDisplay.fontStyles.color = oldColor;
						
						//Marker Date Time
						timeAgoValue = TimeSpan.formatHoursMinutesFromSeconds(timestampDifferenceInSeconds);
						if (timeAgoValue != now)
							glucoseTimeAgoPill.setValue(timeAgoValue, ago, timestampDifference <= TIME_6_MINUTES ? newColor : oldColor);
						else
							glucoseTimeAgoPill.setValue("0m", now, timestampDifference <= TIME_6_MINUTES ? newColor : oldColor);
						
						//Marker Slope
						glucoseSlopePill.setValue(latestMarker.slopeOutput, glucoseUnit, timestampDifference <= TIME_6_MINUTES ? newColor : oldColor);
					}
					else
					{
						//Glucose Value Display
						glucoseValueDisplay.text = "---";
						glucoseValueDisplay.fontStyles.color = oldColor;
						
						//Marker Date Time
						timeAgoValue = TimeSpan.formatHoursMinutesFromSeconds(timestampDifferenceInSeconds);
						if (timeAgoValue != now)
							glucoseTimeAgoPill.setValue(timeAgoValue, ago, oldColor);
						else
							glucoseTimeAgoPill.setValue("0m", now, oldColor);
						
						//Marker Slope
						glucoseSlopePill.setValue("", "", oldColor)
					}
				}
			}
			
			currentNumberOfMakers == previousNumberOfMakers
		}
		
		private function createStatusTextDisplays():void
		{
			/* Calculate Font Sizes */
			var deviceFontMultiplier:Number = DeviceInfo.getFontMultipier();
			glucoseDisplayFont = 44 * deviceFontMultiplier * userBGFontMultiplier;
			var timeDisplayFont:Number = 13 * deviceFontMultiplier * userTimeAgoFontMultiplier;
			var retroDisplayFont:Number = 13 * deviceFontMultiplier * userTimeAgoFontMultiplier;
			
			/* Calculate Position & Padding */
			chartTopPadding *= deviceFontMultiplier;
			if (userBGFontMultiplier >= userTimeAgoFontMultiplier)
				chartTopPadding *= userBGFontMultiplier;
			else
				chartTopPadding *= userTimeAgoFontMultiplier;
			
			var yPos:Number = 6 * DeviceInfo.getVerticalPaddingMultipier() * userBGFontMultiplier;
			
			//Glucose Value Display
			glucoseValueDisplay = GraphLayoutFactory.createChartStatusText("0", chartFontColor, glucoseDisplayFont, Align.RIGHT, true, 400);
			glucoseValueDisplay.x = _graphWidth - glucoseValueDisplay.width -glucoseStatusLabelsMargin;
			glucoseValueDisplay.validate();
			glucoseValueDisplay.text = "";
			addChild(glucoseValueDisplay);
			
			//Glucose Retro Display
			glucoseTimeAgoPill = new ChartInfoPill(retroDisplayFont);
			glucoseTimeAgoPill.setValue("0", "mg/dL", newColor);
			glucoseTimeAgoPill.x = glucoseStatusLabelsMargin + 4;
			glucoseTimeAgoPill.y = yPos;
			addChild(glucoseTimeAgoPill);
			
			//Glucose Time Display
			glucoseSlopePill = new ChartInfoPill(timeDisplayFont);
			glucoseSlopePill.x = glucoseTimeAgoPill.x;
			glucoseSlopePill.y = glucoseTimeAgoPill.y + glucoseTimeAgoPill.height + 6;
			glucoseTimeAgoPill.setValue("", "", newColor);
			addChild(glucoseSlopePill);
			
			//IOB
			IOBPill = new ChartTreatmentPill(ChartTreatmentPill.TYPE_IOB);
			IOBPill.y = glucoseValueDisplay.y + glucoseValueDisplay.height + 6;
			IOBPill.x = _graphWidth - IOBPill.width -glucoseStatusLabelsMargin - 2;
			
			if (mainChartGlucoseMarkersList == null || mainChartGlucoseMarkersList.length == 0 || dummyModeActive)
				IOBPill.visible = false;
			
			addChild(IOBPill);
		}
		
		public function showLine():void
		{
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
			var sourceList:Array;
			if(chartType == MAIN_CHART)
				sourceList = mainChartGlucoseMarkersList;
			else if (chartType == SCROLLER_CHART)
				sourceList = scrollChartGlucoseMarkersList;
			
			var dataLength:int = sourceList.length;
			for (var i:int = 0; i < dataLength; i++) 
			{
				var currentMarker:GlucoseMarker = sourceList[i];
				if (currentMarker.bgReading != null && (currentMarker.bgReading.sensor != null || BlueToothDevice.isFollower()))
					currentMarker.alpha = 1;
				else
					currentMarker.alpha = 0;
			}
		}
		
		private function destroyAllLines(scrollerIncluded:Boolean = true):void
		{
			var i:int = 0
			if(mainChartLineList != null && mainChartLineList.length > 0)
			{
				for (i = 0; i < mainChartLineList.length; i++) 
				{
					if (mainChartLineList[i] != null)
					{
						mainChart.removeChild(mainChartLineList[i]);
						mainChartLineList[i].dispose();
						mainChartLineList[i] = null;
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
						if (scrollerChartLineList[i] != null)
						{
							scrollerChart.removeChild(scrollerChartLineList[i]);
							scrollerChartLineList[i].dispose();
							scrollerChartLineList[i] = null;
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
			//Get touch data
			var touch:Touch = e.getTouch(stage);
			
			/**
			 * UI Menu
			 */
			if(touch != null && touch.phase == TouchPhase.ENDED) 
			{
				//Activate menu drag gesture when drag finishes
				AppInterface.instance.drawers.openGesture = DragGesture.EDGE;
			}
			else if(touch != null && touch.phase == TouchPhase.BEGAN) 
			{	
				//Deactivate menu drag gesture when drag starts
				AppInterface.instance.drawers.openGesture = DragGesture.NONE;
			}
			
			//Dragging
			if(touch != null && touch.phase == TouchPhase.MOVED)
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
				var latestMarkerGlobalX:Number = latestMarker.x + mainChart.x + (latestMarker.width) - glucoseDelimiter.x;
				var futureTimeStamp:Number = latestMarker.timestamp + (Math.abs(latestMarkerGlobalX) / mainChartXFactor);
				var nowTimestamp:Number;
				var isFuture:Boolean = false;
				
				if (latestMarkerGlobalX < 0 - (TIME_6_MINUTES * mainChartXFactor)) //We are in the future and there are missing readings
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
						
						glucoseTimeAgoPill.setValue(futureTimeOutput, retroOutput, oldColor);
						glucoseValueDisplay.fontStyles.color = oldColor;
					}
					else
					{
						nowTimestamp = (new Date()).valueOf();
						var lastTimestamp:Number = Number(mainChartGlucoseMarkersList[mainChartGlucoseMarkersList.length - 1].timestamp);
						var differenceInSec:Number = (nowTimestamp - lastTimestamp) / 1000;
						var timeAgoValue:String = TimeSpan.formatHoursMinutesFromSeconds(differenceInSec);
						if (timeAgoValue != now)
							glucoseTimeAgoPill.setValue(timeAgoValue, ago, newColor);
						else
							glucoseTimeAgoPill.setValue("0m", now, newColor);
					}
					
					glucoseTimeAgoPill.setValue(glucoseTimeAgoPill.value, glucoseTimeAgoPill.unit, oldColor);
					
					glucoseValueDisplay.text = "---";
					glucoseValueDisplay.fontStyles.color = oldColor;
					
					return;
				}
				
				//Loop through all glucose markers displayed in the main chart. Looping backwards because it probably saves CPU cycles
				//for(var i:int = mainChartGlucoseMarkersList.length; --i;)
				for(var i:int = mainChartGlucoseMarkersList.length - 1 ; i >= 0; i--)
				{
					//Get Current and Previous Glucose Markers
					var currentMarker:GlucoseMarker = mainChartGlucoseMarkersList[i];
					var previousMaker:GlucoseMarker = null;
					if (i > 0)
						previousMaker = mainChartGlucoseMarkersList[i - 1];
					
					//Transform local coordinates to global
					var currentMarkerGlobalX:Number = currentMarker.x + mainChart.x + currentMarker.width;
					var previousMarkerGlobalX:Number;
					if (i > 0)
						previousMarkerGlobalX = previousMaker.x + mainChart.x + previousMaker.width;
					else
						previousMarkerGlobalX  = 0;
					
					// Get current timeline timestamp
					var firstAvailableTimestamp:Number = (mainChartGlucoseMarkersList[0] as GlucoseMarker).timestamp;
					var currentTimelineTimestamp:Number = firstAvailableTimestamp + (Math.abs(mainChart.x - (_graphWidth - yAxisMargin) + (mainChartGlucoseMarkerRadius * 2)) / mainChartXFactor);
					var hitTestCurrent:Boolean = currentMarkerGlobalX - currentMarker.width < glucoseDelimiter.x;
					
					//Check if the current marker is the one selected by the main chart's delimiter line
					if ((i == 0 && currentMarkerGlobalX >= glucoseDelimiter.x) || (currentMarkerGlobalX >= glucoseDelimiter.x && previousMarkerGlobalX < glucoseDelimiter.x))
					{
						if (currentMarker.bgReading != null && (currentMarker.bgReading.sensor != null || BlueToothDevice.isFollower()))
						{
							nowTimestamp = new Date().valueOf();
							var latestTimestamp:Number = (mainChartGlucoseMarkersList[mainChartGlucoseMarkersList.length - 1] as GlucoseMarker).timestamp;
							
							//Display Glucose Value
							if (!displayLatestBGValue)
							{
								glucoseValueDisplay.text = currentMarker.glucoseOutput + " " + currentMarker.slopeArrow;
								glucoseValueDisplay.fontStyles.color = currentMarker.color;
								
								if (mainChartGlucoseMarkersList.length > 1)
								{	
									if (previousMaker != null && currentTimelineTimestamp - previousMaker.timestamp > TIME_16_MINUTES && !hitTestCurrent)
									{
										glucoseValueDisplay.text = "---";
										glucoseValueDisplay.fontStyles.color = oldColor;	
									}
									else if (previousMaker != null && currentTimelineTimestamp - previousMaker.timestamp > TIME_75_SECONDS && Math.abs(currentMarker.timestamp - currentTimelineTimestamp) > TIME_5_MINUTES && currentTimelineTimestamp - previousMaker.timestamp <= TIME_16_MINUTES && !hitTestCurrent)
									{
										glucoseValueDisplay.fontStyles.color = oldColor;
									}
								}
							}
							
							//Display Slope
							if (!displayLatestBGValue)
							{
								glucoseSlopePill.setValue(currentMarker.slopeOutput, glucoseUnit, newColor)
								
								if (mainChartGlucoseMarkersList.length > 1)
								{	
									if (previousMaker != null && currentTimelineTimestamp - previousMaker.timestamp > TIME_16_MINUTES && !hitTestCurrent)
									{
										glucoseSlopePill.setValue("", "", oldColor)
									}
									else if (previousMaker != null && currentTimelineTimestamp - previousMaker.timestamp > TIME_75_SECONDS && Math.abs(currentMarker.timestamp - currentTimelineTimestamp) > TIME_5_MINUTES && currentTimelineTimestamp - previousMaker.timestamp <= TIME_16_MINUTES && !hitTestCurrent)
									{
										glucoseSlopePill.setValue(glucoseSlopePill.value, glucoseSlopePill.unit, oldColor)
									}
								}
							}
							
							//Display marker time
							//if (mainChart.x > -mainChart.width + _graphWidth - yAxisMargin) //Display time of BGReading
							if (!displayLatestBGValue) //Display time of BGReading
							{
								glucoseTimeAgoPill.setValue(currentMarker.timeFormatted, retroOutput, newColor);
								
								if (mainChartGlucoseMarkersList.length > 1)
								{	
									if (previousMaker != null && currentTimelineTimestamp - previousMaker.timestamp > TIME_75_SECONDS && Math.abs(currentMarker.timestamp - currentTimelineTimestamp) > TIME_5_MINUTES && !hitTestCurrent)
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
							
							//if (mainChart.x > -mainChart.width + _graphWidth - yAxisMargin)
							if (handPicker.x < _graphWidth - handPicker.width)
								selectedGlucoseMarkerIndex = currentMarker.index;
							else
								(mainChartGlucoseMarkersList[mainChartGlucoseMarkersList.length - 1] as GlucoseMarker).index;
							
							if (i == mainChartGlucoseMarkersList.length - 1)
								displayLatestBGValue = true;
						}
						
						//We found a mach so we can break the loop to save CPU cycles
						break;
					}
				}
			}
			
			if (displayLatestBGValue && !isFuture)
				calculateDisplayLabels();
		}
		
		private function onAppInForeground (e:SpikeEvent):void
		{
			calculateDisplayLabels();
		}
		
		private function onUpdateTimerRefresh(event:flash.events.Event = null):void
		{
			if (BackgroundFetch.appIsInForeground())
			{
				calculateDisplayLabels();
				calculateTotalIOB();
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
				
				var previousLowestGlucoseValue:Number = lowestGlucoseValue;
				var previousHighestGlucoseValue:Number = highestGlucoseValue;
				
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
				
				//Redraw YAxis if needed
				if(highestGlucoseValue != previousHighestGlucoseValue || lowestGlucoseValue != previousLowestGlucoseValue)
				{
					//Dispose YAxis
					yAxisContainer.dispose();
					
					//Redraw YAxis
					yAxisContainer.addChild(drawYAxis());
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
					
					var line:Shape = new Shape();
					line.graphics.lineStyle(1, 0xFFFFFF, 1);
					
					var markerLength:int = mainChartGlucoseMarkersList.length;
					var previousGlucoseMarker:GlucoseMarker;
					
					//Redraw Line
					for (var i:int = 0; i < markerLength; i++) 
					{
						var glucoseMarker:GlucoseMarker = mainChartGlucoseMarkersList[i] as GlucoseMarker;
						
						if(i == 0)
							line.graphics.moveTo(glucoseMarker.x, glucoseMarker.y);
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
							
							//Determine if missed readings are bigger than the acceptable gap. If so, the line will be gray;
							line.graphics.lineStyle(1, glucoseMarker.color, 1);
							if(i > 0)
							{
								var elapsedMinutes:Number = TimeSpan.fromDates(new Date(previousGlucoseMarker.timestamp), new Date(glucoseMarker.timestamp)).minutes;
								if (elapsedMinutes > NUM_MINUTES_MISSED_READING_GAP)
									line.graphics.lineStyle(1, oldColor, 1);
							}
							
							line.graphics.lineTo(currentLineX, currentLineY);
							line.graphics.moveTo(currentLineX, currentLineY);
						}
						//Hide glucose marker
						glucoseMarker.alpha = 0;
						previousGlucoseMarker = glucoseMarker;
					}
					
					mainChart.addChild(line);
					mainChartLineList.push(line);
				}
				
				// Update Display Fields	
				glucoseValueDisplay.text = latestMarker.glucoseOutput + " " + latestMarker.slopeArrow;
				glucoseValueDisplay.fontStyles.color = latestMarker.color;
				glucoseSlopePill.setValue(latestMarker.slopeOutput, glucoseUnit, newColor);
				
				//Deativate DummyMode
				dummyModeActive = false;
			}
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			/* Event Listeners */
			CalibrationService.instance.removeEventListener(CalibrationServiceEvent.INITIAL_CALIBRATION_EVENT, onCaibrationReceived);
			CalibrationService.instance.removeEventListener(CalibrationServiceEvent.NEW_CALIBRATION_EVENT, onCaibrationReceived);
			handPicker.removeEventListener(TouchEvent.TOUCH, onHandPickerTouch);
			Spike.instance.removeEventListener(SpikeEvent.APP_IN_FOREGROUND, onAppInForeground);
			
			/* Update Timer */
			statusUpdateTimer.stop();
			statusUpdateTimer.removeEventListener(TimerEvent.TIMER, onUpdateTimerRefresh);
			statusUpdateTimer = null;
			
			/* Lines */
			destroyAllLines();
			
			/* Glucose Markers */
			var i:int;
			var mainDataLength:int = mainChartGlucoseMarkersList.length;
			for (i = 0; i < mainDataLength; i++) 
			{
				var mainGlucoseMarker:GlucoseMarker = mainChartGlucoseMarkersList[i] as GlucoseMarker;
				mainGlucoseMarker.dispose();
				mainGlucoseMarker = null;
			}
			mainChartGlucoseMarkersList.length = 0;
			mainChartGlucoseMarkersList = null;
			
			var scrollerDataLength:int = scrollChartGlucoseMarkersList.length;
			for (i = 0; i < scrollerDataLength; i++) 
			{
				var scrollerGlucoseMarker:GlucoseMarker = scrollChartGlucoseMarkersList[i] as GlucoseMarker;
				scrollerGlucoseMarker.dispose();
				scrollerGlucoseMarker = null;
			}
			scrollChartGlucoseMarkersList.length = 0;
			scrollChartGlucoseMarkersList = null;
			
			/* Chart Display Objects */
			removeChild(glucoseTimelineContainer);
			glucoseTimelineContainer != null
			glucoseTimelineContainer.dispose();
			glucoseTimelineContainer = null;
			
			removeChild(mainChart);
			mainChart.dispose();
			mainChart = null;
			
			removeChild(glucoseDelimiter);
			glucoseDelimiter.dispose();
			glucoseDelimiter = null;
			
			removeChild(scrollerChart);
			scrollerChart.dispose();
			scrollerChart = null;
			
			removeChild(handPicker);
			handPicker.dispose();
			handPicker = null;
			
			removeChild(glucoseValueDisplay);
			glucoseValueDisplay.dispose();
			glucoseValueDisplay = null;
			
			removeChild(yAxisContainer);
			yAxisContainer.dispose();
			yAxisContainer = null;
			
			removeChild(mainChartContainer);
			mainChartContainer.dispose();
			mainChartContainer = null;
			
			//Timeline
			if (timelineObjects != null && timelineObjects.length > 0)
			{
				for (i = 0; i < timelineObjects.length; i++) 
				{
					var displayObject:Sprite = timelineObjects[i] as Sprite;
					if (timelineContainer != null && displayObject != null)
					{
						timelineContainer.removeChild(displayObject);
						displayObject.dispose();
						displayObject.removeChildren()
						displayObject = null;
					}
				}
				timelineObjects.length = 0;
			}
			
			if (timelineContainer != null)
			{
				timelineContainer.dispose();
				timelineContainer = null;
			}
			
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
				if (_dataSource.length > 288) // >24H
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
	}
}