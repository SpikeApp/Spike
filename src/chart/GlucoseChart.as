package chart
{
    
    import flash.geom.Point;
    import flash.system.System;
    
    import databaseclasses.BgReading;
    import databaseclasses.CommonSettings;
    
    import feathers.controls.DragGesture;
    import feathers.controls.Label;
    
    import model.ModelLocator;
    
    import starling.display.Image;
    import starling.display.Quad;
    import starling.display.Shape;
    import starling.display.Sprite;
    import starling.events.Touch;
    import starling.events.TouchEvent;
    import starling.events.TouchPhase;
    import starling.textures.RenderTexture;
    import starling.utils.Align;
    
    import ui.AppInterface;
    
    import utils.DeviceInfo;
	
	[ResourceBundle("chartscreen")]
    
    public class GlucoseChart extends Sprite
    {
        //Constants
        private static const MAIN_CHART:String = "mainChart";
        private static const SCROLLER_CHART:String = "scrollerChart";
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
		private var mainChartLinePictureList:Array;
		private var scrollerChartLineList:Array;
		private var scrollerChartLinePictureList:Array;
        
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
        private var highUrgentGlucoseMarkerColor:uint = 0xff0000;//red
        private var highGlucoseMarkerColor:uint = 0xffff00;//yellow
		private var inrangeGlucoseMarkerColor:uint = 0x00ff00;//green
        private var lowGlucoseMarkerColor:uint = 0xffff00;//yellow
        private var lowUrgentGlucoseMarkerColor:uint = 0xff0000; //red
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
        private var glucoseUnit:String = "mg/dl";
		private var handPickerStrokeThickness:int = 1;
		private var chartTopPadding:int = 50;
		private var scrollerTopPadding:int = 5;
		private var _displayLine:Boolean = false;
		private var fakeChartMaskColor:uint = 0x20222a;
		private var glucoseStatusLabelsMargin:int = 5;
		private var retroOutput:String;
		private var agoSuffix:String;
		private var userBGFontMultiplier:Number;
		private var userTimeAgoFontMultiplier:Number;
		private var userAxisFontMultiplier:Number;
		private var dateFormat:String;
		private var dummyModeActive:Boolean = false;

        //Display Objects
        private var glucoseTimelineContainer:Sprite;
        private var mainChart:Sprite;
        private var glucoseDelimiter:Shape;
        private var scrollerChart:Sprite;
        private var handPicker:Sprite;
        private var glucoseValueDisplay:Label;
        private var glucoseSlopeDisplay:Label;
        private var glucoseTimeAgoDisplay:Label;
		private var yAxisContainer:Sprite;
		private var mainChartContainer:Sprite;
		private var textureList:Array;
        
        //Glucose Thresholds
        private var glucoseUrgentHigh:Number;
        private var glucoseHigh:Number;
        private var glucoseLow:Number;
        private var glucoseUrgentLow:Number;

		//Movement
        private var scrollMultiplier:Number;

        

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
			this.mainChartLinePictureList = [];
			this.scrollerChartLineList = [];
			this.scrollerChartLinePictureList = [];
			this.textureList = [];
			
			//Unit
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true") 
				glucoseUnit = "mg/dl";
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
			
			//Size
			mainChartGlucoseMarkerRadius = int(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_MARKER_RADIUS));
			userBGFontMultiplier = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_BG_FONT_SIZE));
			userTimeAgoFontMultiplier = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_TIMEAGO_FONT_SIZE));
			userAxisFontMultiplier = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_AXIS_FONT_SIZE));
			yAxisMargin += (legendTextSize * userAxisFontMultiplier) - legendTextSize;
			
			//Time Format
			dateFormat = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_DATE_FORMAT);
			
			//Strings
			retroOutput = ModelLocator.resourceManagerInstance.getString('chartscreen','retro_title');
			agoSuffix = ModelLocator.resourceManagerInstance.getString('chartscreen','time_ago_suffix');

            //Add timeline to display list
            glucoseTimelineContainer = new Sprite();
            addChild(glucoseTimelineContainer);
        }
		
        public function drawGraph():void
        {	
			/* Activate Dummy Mode if there's no bgreadings in */
			if (_dataSource.length == 0)
				dummyModeActive = true;
			
			/**
             * Main Chart
             */
            mainChart = drawChart(MAIN_CHART, _graphWidth - yAxisMargin, _graphHeight, yAxisMargin, mainChartGlucoseMarkerRadius);
            mainChart.x = -mainChart.width + _graphWidth - yAxisMargin;
            mainChartContainer = new Sprite(); //TODO: Apply mask
            mainChartContainer.addChild(mainChart);
            //Add main chart to the display list
            glucoseTimelineContainer.addChild(mainChartContainer);
            
            //Mask (Only show markers before the delimiter)
			var mainChartMask:Quad;
			mainChartMask = new Quad(yAxisMargin, _graphHeight, fakeChartMaskColor);
			mainChartMask.x = _graphWidth - mainChartMask.width;
			mainChartContainer.addChild(mainChartMask);

			
			/**
			 * Status Text Displays
			 */
			//Create the displays
			createStatusTextDisplays();
			
			//Set the glucose value display to the latest glucose value available
			var bgValueToDisplay:Number = int((mainChartGlucoseMarkersList[mainChartGlucoseMarkersList.length - 1].glucoseValue) * 10) / 10;
			if (glucoseUnit != "mg/dl") 
				bgValueToDisplay = Math.round(((BgReading.mgdlToMmol((bgValueToDisplay))) * 10)) / 10;
			
			var glucoseValueOutput:String
			if (glucoseUnit == "mg/dl")
				glucoseValueOutput = String(bgValueToDisplay);
			else
			{
				if ( bgValueToDisplay % 1 == 0)
					glucoseValueOutput = String(bgValueToDisplay) + ".0";
				else
					glucoseValueOutput = String(bgValueToDisplay);
			}
			
			glucoseValueDisplay.text = glucoseValueOutput + " " + getArrow(mainChartGlucoseMarkersList[mainChartGlucoseMarkersList.length - 1].glucoseValue - mainChartGlucoseMarkersList[mainChartGlucoseMarkersList.length - 2].glucoseValue);// + " " + glucoseUnits;
			glucoseValueDisplay.invalidate();
			glucoseValueDisplay.validate();
			glucoseValueDisplay.x = _graphWidth - glucoseValueDisplay.width - glucoseStatusLabelsMargin;
			glucoseValueDisplay.fontStyles.color = mainChartGlucoseMarkersList[mainChartGlucoseMarkersList.length - 1].color;
			
			//Set timeago
			var currentTimestamp:Number = (new Date()).valueOf();
			var previousTimestamp:Number = Number(mainChartGlucoseMarkersList[mainChartGlucoseMarkersList.length - 2].timestamp);
			var differenceInSeconds:Number = (currentTimestamp - previousTimestamp) / 1000;
			
			glucoseTimeAgoDisplay.text = convertTime(differenceInSeconds) + " " + agoSuffix;
			
			//Set slope
			var glucoseDifferenceMGDL:Number = int((mainChartGlucoseMarkersList[mainChartGlucoseMarkersList.length - 1].glucoseValue - mainChartGlucoseMarkersList[mainChartGlucoseMarkersList.length - 2].glucoseValue)*10)/10;
			var glucoseDifferenceMMOL:Number = Math.round(((BgReading.mgdlToMmol((glucoseDifferenceMGDL))) * 100)) / 100;
			if(glucoseDifferenceMGDL >= 0)
				if(glucoseUnit == "mg/dl")
					glucoseSlopeDisplay.text = "+ " + String(glucoseDifferenceMGDL) + " " + glucoseUnit;
				else
					glucoseSlopeDisplay.text = "+ " + String(glucoseDifferenceMMOL) + " " + glucoseUnit;
				else
					if(glucoseUnit == "mg/dl")
						glucoseSlopeDisplay.text = "- " + String(Math.abs(glucoseDifferenceMGDL)) + " " + glucoseUnit;
					else
						glucoseSlopeDisplay.text = "- " + String(Math.abs(glucoseDifferenceMMOL)) + " " + glucoseUnit;
			
            /**
             * yAxis Line
             */
            yAxisContainer = drawYAxis();
            addChild(yAxisContainer);
    
            /**
             * Scroller
             */
            //Create scroller
            scrollerChart = drawChart(SCROLLER_CHART, _scrollerWidth - (scrollerChartGlucoseMarkerRadius * 2), _scrollerHeight, 0, scrollerChartGlucoseMarkerRadius);
			if(!_displayLine)
				scrollerChart.y = mainChart.height + scrollerTopPadding;
			else
				scrollerChart.y = mainChart.height + scrollerTopPadding - 0.1;
			//Create scroller background
			var scrollerBackground:Quad = new Quad(scrollerChart.width, scrollerChart.height, 0x282a32);
			scrollerBackground.y = scrollerChart.y;
			//scrollerBackground.alpha = 0.2;
			//Add scroller and background to the display list
			glucoseTimelineContainer.addChild(scrollerBackground);
			glucoseTimelineContainer.addChild(scrollerChart);
    
            /**
             * Hand Picker
             */
            //Create Hand Picker
            handPicker = new Sprite();
            var handPickerFill:Quad = new Quad(_graphWidth/timelineRange, scrollerChart.height, 0xFFFFFF);
            handPicker.addChild(handPickerFill);
            handPicker.x = _graphWidth - handPicker.width;
            handPicker.y = scrollerChart.y;
            handPicker.alpha = .2;
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
        }
		
		private function convertTime(secs:Number):String
		{
			var h:Number=Math.floor(secs/3600);
			var m:Number=Math.floor((secs%3600)/60);
			var s:Number=Math.floor((secs%3600)%60);

			return(h==0?"":(h<10?"0"+h.toString()+"h":h.toString()+"h"))+(m<10?"0"+m.toString():m.toString())+"m";
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
			if(glucoseUnit != "mg/dl")
				highestGlucoseAxisValue = Math.round(((BgReading.mgdlToMmol((highestGlucoseAxisValue))) * 10)) / 10;
			
			var highestGlucoseOutput:String
			if (glucoseUnit == "mg/dl")
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
			if(glucoseUnit != "mg/dl")
				lowestGlucoseAxisValue = Math.round(((BgReading.mgdlToMmol((lowestGlucoseAxisValue))) * 10)) / 10;
			
			var lowestGlucoseOutput:String
			if (glucoseUnit == "mg/dl")
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
			 * Urgent High Glucose (Alarm)
			 */
			if(glucoseUrgentHigh > lowestGlucoseValue && glucoseUrgentHigh < highestGlucoseValue)
			{
				//Line Marker
				var highUrgentGlucoseLineMarker:Shape = GraphLayoutFactory.createHorizontalLine(legendSize, lineThickness, lineColor);
				highUrgentGlucoseLineMarker.x = _graphWidth - legendSize;
				highUrgentGlucoseLineMarker.y = _graphHeight - ((glucoseUrgentHigh - lowestGlucoseValue) * scaleYFactor);
				yAxis.addChild(highUrgentGlucoseLineMarker);
				
				//Legend
				var urgentHighGlucoseAxisValue:Number = glucoseUrgentHigh;
				if(glucoseUnit != "mg/dl")
					urgentHighGlucoseAxisValue = Math.round(((BgReading.mgdlToMmol((urgentHighGlucoseAxisValue))) * 10)) / 10;
				
				var urgentHighGlucoseOutput:String
				if (glucoseUnit == "mg/dl")
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
			 * High Glucose (Alarm)
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
				if(glucoseUnit != "mg/dl")
					highGlucoseAxisValue = Math.round(((BgReading.mgdlToMmol((highGlucoseAxisValue))) * 10)) / 10;
				
				var highGlucoseOutput:String
				if (glucoseUnit == "mg/dl")
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
			 * Low Glucose (Alarm)
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
				if(glucoseUnit != "mg/dl")
					lowGlucoseAxisValue = Math.round(((BgReading.mgdlToMmol((lowGlucoseAxisValue))) * 10)) / 10;
				
				var lowGlucoseOutput:String
				if (glucoseUnit == "mg/dl")
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
			 * Urgent Low Glucose (Alarm)
			 */
			if(glucoseUrgentLow > lowestGlucoseValue && glucoseUrgentLow < highestGlucoseValue)
			{
				//Line Marker
				var lowUrgentGlucoseLineMarker:Shape = GraphLayoutFactory.createHorizontalLine(legendSize, lineThickness, lineColor);
				lowUrgentGlucoseLineMarker.x = _graphWidth - legendSize;
				lowUrgentGlucoseLineMarker.y = _graphHeight - ((glucoseUrgentLow - lowestGlucoseValue) * scaleYFactor);
				yAxis.addChild(lowUrgentGlucoseLineMarker);
				
				//Legend
				var urgentLowGlucoseAxisValue:Number = glucoseUrgentLow;
				if(glucoseUnit != "mg/dl")
					urgentLowGlucoseAxisValue = Math.round(((BgReading.mgdlToMmol((urgentLowGlucoseAxisValue))) * 10)) / 10;
				
				var urgentLowGlucoseOutput:String
				if (glucoseUnit == "mg/dl")
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
        
        private function drawChart(chartType:String, chartWidth:Number, chartHeight:Number, chartRightMargin:Number, glucoseMarkerRadius:Number):Sprite
        {
            var chartContainer:Sprite = new Sprite();
            
            /**
             * Calculation of X Axis scale factor
             */
            var firstTimeStamp:Number = Number(_dataSource[0].timestamp);
            var lastTimeStamp:Number = Number(_dataSource[_dataSource.length - 1].timestamp);
            var totalTimestampDifference:Number = lastTimeStamp - firstTimeStamp;
			var scaleXFactor:Number;
			if(chartType == MAIN_CHART)
				scaleXFactor = 1/(totalTimestampDifference / (chartWidth * timelineRange));
			else if (chartType == SCROLLER_CHART)
				scaleXFactor = 1/(totalTimestampDifference / (chartWidth - chartRightMargin));
    
            /**
             * Calculation of Y Axis scale factor
             */
            //First we determine the maximum and minimum glucose values
            var sortDataArray:Array = _dataSource.concat();
            sortDataArray.sortOn(["calculatedValue"], Array.NUMERIC);
            lowestGlucoseValue = sortDataArray[0].calculatedValue as Number;
            highestGlucoseValue = sortDataArray[sortDataArray.length - 1].calculatedValue as Number;
            //We find the difference so we can know how big the glucose pseudo graph is
            var totalGlucoseDifference:Number = highestGlucoseValue - lowestGlucoseValue;
            //Now we find a multiplier for the y axis so the glucose graph fits entirely with the chart height
            scaleYFactor = (chartHeight - (glucoseMarkerRadius*2))/totalGlucoseDifference;
    
            /**
             * Internal variables
             */
            var i:int; //common index for loops
            var previousXCoordinate:Number = 0; //holder for x coordinate of the glucose value to be used by the following one
			var previousYCoordinate:Number;
    
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
        
                //Define glucose marker x position
                var glucoseX:Number;
                if(i==0)
                    glucoseX = 0;
                else
                    glucoseX = (Number(_dataSource[i].timestamp) - Number(_dataSource[i-1].timestamp)) * scaleXFactor;
        
                //Define glucose marker y position
                var glucoseY:Number = chartHeight - (glucoseMarkerRadius * 2) - ((currentGlucoseValue - lowestGlucoseValue) * scaleYFactor);
				if(totalGlucoseDifference == 0) //If glucose is a perfect flat line then display it in the middle
					glucoseY = (chartHeight - (glucoseMarkerRadius*2)) / 2;
        
                //Define glucose marker color
                var color:int;
                if(currentGlucoseValue >= glucoseUrgentHigh)
                    color = highUrgentGlucoseMarkerColor;
                else if(currentGlucoseValue >= glucoseHigh)
                    color = highGlucoseMarkerColor;
                else if(currentGlucoseValue > glucoseLow && currentGlucoseValue < glucoseHigh)
                    color = inrangeGlucoseMarkerColor;
                else if(currentGlucoseValue <= glucoseLow && currentGlucoseValue > glucoseUrgentLow)
                    color = lowGlucoseMarkerColor;
                else if(currentGlucoseValue <= glucoseUrgentLow)
                    color = lowUrgentGlucoseMarkerColor;
        
                //Create glucose marker
                var glucoseMarker:GlucoseMarker = new GlucoseMarker(glucoseMarkerRadius, color);
                glucoseMarker.x = previousXCoordinate + glucoseX;
                glucoseMarker.y = glucoseY;
                glucoseMarker.timestamp = _dataSource[i].timestamp;
                glucoseMarker.glucoseValue = _dataSource[i].calculatedValue;
        
				//Draw line
				if(_displayLine)
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
						
						line.graphics.lineStyle(1, color, 1);
						line.graphics.lineTo(currentLineX, currentLineY);
						line.graphics.moveTo(currentLineX, currentLineY);
					}
					//Hide glucose marker
					glucoseMarker.alpha = 0;
				}
				
                //Set variables for next iteration
                previousXCoordinate = glucoseMarker.x;
				previousYCoordinate = glucoseMarker.y;
        
                //Add glucose marker to the timeline
                chartContainer.addChild(glucoseMarker);
        
                //Add glucose marker to the displayObjects array for later reference 
                if(chartType == MAIN_CHART)
                    mainChartGlucoseMarkersList.push(glucoseMarker);
				else if (chartType == SCROLLER_CHART)
					scrollChartGlucoseMarkersList.push(glucoseMarker);
            }
			
			//Chart Line
			if(_displayLine)
			{
				//Check if we can create a bitmap representation of the line without exceeding hardware capabilities
				trace("DeviceInfo.getDeviceType()", DeviceInfo.getDeviceType());
				if((line.width < 2048 && DeviceInfo.getDeviceType() != DeviceInfo.IPHONE_X && DeviceInfo.getDeviceType() != DeviceInfo.TABLET))
				{
					//Create a bitmap from the line. This is more memory and CPU efficient
					var lineTexture:RenderTexture = new RenderTexture(chartContainer.width, chartContainer.height);
					lineTexture.draw(line);
					var lineImage:Image = new Image(lineTexture);
					chartContainer.addChild(lineImage);
					
					//Dispose line for memory managemnt
					line.dispose();
					line = null;
					
					//Save texture for later memory cleaning
					textureList.push(lineTexture);
					
					//Save line references for later use
					if(chartType == MAIN_CHART)
					{
						mainChartLinePictureList.push(lineImage);
					}
					else if (chartType == SCROLLER_CHART)
					{
						scrollerChartLinePictureList.push(lineImage);
					}
				}
				else
				{
					//Line size exceeds hardware capabilities to convert it to bitmap.
					chartContainer.addChild(line);
					
					//Save line references for later use
					if(chartType == MAIN_CHART)
					{
						mainChartLineList.push(line);
					}
					else if (chartType == SCROLLER_CHART)
					{
						scrollerChartLineList.push(line);
					}
				}
			}
			
            return chartContainer;
        }
		
		private function createStatusTextDisplays():void
		{
			/* Calculate Font Sizes */
			var deviceFontMultiplier:Number = DeviceInfo.getFontMultipier();
			var glucoseDisplayFont:Number = 38 * deviceFontMultiplier * userBGFontMultiplier;
			var timeDisplayFont:Number = 16 * deviceFontMultiplier * userTimeAgoFontMultiplier;
			var retroDisplayFont:Number = 16 * deviceFontMultiplier * userTimeAgoFontMultiplier;
			
			/* Calculate Position & Padding */
			chartTopPadding *= deviceFontMultiplier;
			if (userBGFontMultiplier >= userTimeAgoFontMultiplier)
				chartTopPadding *= userBGFontMultiplier;
			else
				chartTopPadding *= userTimeAgoFontMultiplier;
			
			var yPos:Number = 3 * DeviceInfo.getVerticalPaddingMultipier() * userBGFontMultiplier;
			
			//Glucose Value Display
			glucoseValueDisplay = GraphLayoutFactory.createChartStatusText("", chartFontColor, glucoseDisplayFont, Align.RIGHT, true, 200);
			glucoseValueDisplay.x = _graphWidth - glucoseValueDisplay.width -glucoseStatusLabelsMargin;
			addChild(glucoseValueDisplay);
			
			//Glucose Retro Display
			glucoseTimeAgoDisplay = GraphLayoutFactory.createChartStatusText("", chartFontColor, retroDisplayFont, Align.LEFT, false);
			glucoseTimeAgoDisplay.x = glucoseStatusLabelsMargin;
			glucoseTimeAgoDisplay.y = yPos;
			addChild(glucoseTimeAgoDisplay);
			glucoseTimeAgoDisplay.text = retroOutput;
			glucoseTimeAgoDisplay.invalidate();
			glucoseTimeAgoDisplay.validate();
			
			//Glucose Time Display
			glucoseSlopeDisplay = GraphLayoutFactory.createChartStatusText("", chartFontColor, timeDisplayFont, Align.CENTER, false);
			glucoseSlopeDisplay.x = glucoseTimeAgoDisplay.x;
			glucoseSlopeDisplay.y = glucoseTimeAgoDisplay.y + glucoseTimeAgoDisplay.height + 2;
			glucoseTimeAgoDisplay.text = "";
			addChild(glucoseSlopeDisplay);
		}
		
		private function onHandPickerTouch (e:TouchEvent):void
		{
			//Get touch data
			var touch:Touch = e.getTouch(stage);
			
			/**
			 * UI Menu
			 */
			if(touch != null && touch.phase == TouchPhase.ENDED) //Activate menu drag gesture when drag finishes
				AppInterface.instance.drawers.openGesture = DragGesture.EDGE;
			else if(touch != null && touch.phase == TouchPhase.BEGAN) //Deactivate menu drag gesture when drag starts
				AppInterface.instance.drawers.openGesture = DragGesture.NONE;
			
			//Dragging
			if(touch != null && touch.phase == TouchPhase.MOVED)
			{
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
					mainChart.x = 0;
				}
				if(handPicker.x > _graphWidth - handPicker.width)
				{
					handPicker.x = _graphWidth - handPicker.width;
					mainChart.x = -mainChart.width + _graphWidth - yAxisMargin;
				}
				
				/**
				 * RETRO GLUCOSE VALUES AND TIME
				 */
				//Loop through all glucose markers displayed in the main chart. Looping backwards because it probably saves CPU cycles
				for(var i:int = mainChartGlucoseMarkersList.length; --i;)
				{
					//No need to work on the first one, it will never reach the main chart delimiter line
					if (i > 0)
					{
						//Get Current and Previous Glucose Markers
						var currentMarker:GlucoseMarker = mainChartGlucoseMarkersList[i];
						var previousMaker:GlucoseMarker = mainChartGlucoseMarkersList[i - 1];
						
						//Transform local coordinates to global
						var currentMarkerGlobalX:Number = currentMarker.x + mainChart.x + (currentMarker.width);
						var previousMarkerGlobalX:Number = previousMaker.x + mainChart.x + (previousMaker.width);
						
						//Check if the current marker is the one selected by the main chart's delimiter line
						var glucoseDifferenceMGDL:Number = int((currentMarker.glucoseValue - previousMaker.glucoseValue)*10)/10;
						var glucoseDifferenceMMOL:Number = Math.round(((BgReading.mgdlToMmol((glucoseDifferenceMGDL))) * 100)) / 100;
						if (currentMarkerGlobalX >= glucoseDelimiter.x && previousMarkerGlobalX < glucoseDelimiter.x)
						{
							var arrow:String = getArrow(glucoseDifferenceMGDL);
							
							var glucoseValue:Number = int((currentMarker.glucoseValue) * 10) / 10;
							if (glucoseUnit != "mg/dl") 
								glucoseValue = Math.round(((BgReading.mgdlToMmol((glucoseValue))) * 10)) / 10;
							
							var glucoseValueOutput:String
							if (glucoseUnit == "mg/dl")
								glucoseValueOutput = String(glucoseValue);
							else
							{
								if ( glucoseValue % 1 == 0)
									glucoseValueOutput = String(glucoseValue) + ".0";
								else
									glucoseValueOutput = String(glucoseValue);
							}
							
							if (glucoseValueDisplay.text != String(glucoseValue))
							{
								glucoseValueDisplay.text = glucoseValueOutput + " " + arrow;
								glucoseValueDisplay.fontStyles.color = currentMarker.color;
								glucoseValueDisplay.invalidate();
								glucoseValueDisplay.validate();
								glucoseValueDisplay.x = _graphWidth - glucoseValueDisplay.width - glucoseStatusLabelsMargin;
							}
							
							//Display Slope
							if(glucoseDifferenceMGDL >= 0)
								if(glucoseUnit == "mg/dl")
									glucoseSlopeDisplay.text = "+ " + String(glucoseDifferenceMGDL) + " " + glucoseUnit;
								else
									glucoseSlopeDisplay.text = "+ " + String(glucoseDifferenceMMOL) + " " + glucoseUnit;
							else
								if(glucoseUnit == "mg/dl")
									glucoseSlopeDisplay.text = "- " + String(Math.abs(glucoseDifferenceMGDL)) + " " + glucoseUnit;
								else
									glucoseSlopeDisplay.text = "- " + String(Math.abs(glucoseDifferenceMMOL)) + " " + glucoseUnit;
							
							//Display marker time (time ago)
							if (mainChart.x > -mainChart.width + _graphWidth - yAxisMargin)
							{
								var markerDate:Date = new Date(currentMarker.timestamp);
								var hours:Number = markerDate.getHours();
								var hoursOutput:String;
								var ampmOutput:String = "";
								
								if (dateFormat.slice(0,2) == "24")
								{
									if (hours < 10)
										hoursOutput = "0" + hours;
									else
										hoursOutput = hours.toString();
								}
								else
								{
									if (hours >= 12)
									{
										if (hours >= 13)
											hours -= 12; //Subtract 12 to the hour value to get 12H date format
										
										hoursOutput = hours.toString();
										
										ampmOutput = "PM";
									}
									else
									{
										hoursOutput = hours.toString();
										
										if (hoursOutput == "0")
											hoursOutput = "12";
										
										ampmOutput = "AM";
									}
								}
								
								var minutes:Number = markerDate.getMinutes();
								var minutesOutput:String;
								if (minutes < 10)
									minutesOutput = "0" + minutes;
								else
									minutesOutput = minutes.toString();
								
								glucoseTimeAgoDisplay.text = retroOutput + " - " + (hoursOutput + ":" + minutesOutput + ampmOutput);
							}
							else
							{
								//Set timeago
								var currentTimestamp:Number = (new Date()).valueOf();
								var previousTimestamp:Number = Number(mainChartGlucoseMarkersList[mainChartGlucoseMarkersList.length - 2].timestamp);
								var differenceInSeconds:Number = (currentTimestamp - previousTimestamp) / 1000;
								glucoseTimeAgoDisplay.text = convertTime(differenceInSeconds) + " " + agoSuffix;
								
							}
							//We found a mach so we can break the loop to save CPU cycles
							break;
						}
					}
				}
			}
		}
		
		private function getArrow(difference:Number):String
		{
			var arrow:String;
			if(difference > 15) //Double Up
				arrow = "\u2191\u2191";
			else if(difference > 10) //Up
				arrow = "\u2191";
			else if(difference > 5) //45 Up
				arrow = "\u2197";
			else if(difference >= -5 && difference <= 5) //Flat
				arrow = "\u2192";
			else if(difference < -5) //45 Down
				arrow = "\u2198";
			else if(difference < -10) //Down
				arrow = "\u2193";
			else if(difference < -15) //Double Down
				arrow = "\u2193\u2193";
			
			return arrow;
		}
		
		public function showLine():void
		{
			if(_displayLine == false)
			{
				_displayLine = true;
				
				//Dispose previous lines
				destroyAllLines();
				
				//Dispose textures
				disposeTextures();
				
				//Draw Lines
				drawLine(MAIN_CHART);
				drawLine(SCROLLER_CHART);
			}
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
			var dataLength:int = sourceList.length;
			for (var i:int = 0; i < dataLength; i++) 
			{
				var glucoseMarker:GlucoseMarker = sourceList[i];
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
					
					line.graphics.lineStyle(1, glucoseMarker.color, 1);
					line.graphics.lineTo(currentLineX, currentLineY);
					line.graphics.moveTo(currentLineX, currentLineY);
				}
				//Hide glucose marker
				glucoseMarker.alpha = 0;
			}
			//Check if we can create a bitmap representation of the line without exceeding hardware capabilities
			if((line.width < 2048 && DeviceInfo.getDeviceType() != DeviceInfo.IPHONE_X && DeviceInfo.getDeviceType() != DeviceInfo.TABLET))
			{
				//Create a bitmap from the line. This is more memory and CPU efficient
				var lineTexture:RenderTexture;
				if(chartType == MAIN_CHART)
					lineTexture = new RenderTexture(mainChart.width, mainChart.height);
				else if (chartType == SCROLLER_CHART)
					lineTexture = new RenderTexture(_scrollerWidth, _scrollerHeight);

				lineTexture.draw(line);
				var lineImage:Image = new Image(lineTexture);
				if(chartType == MAIN_CHART)
					mainChart.addChild(lineImage);
				else if(chartType == SCROLLER_CHART)
					scrollerChart.addChild(lineImage);
				
				//Dispose line for memory managemnt
				line.dispose();
				line = null;
				//Save texture for later memory cleaning
				textureList.push(lineTexture);
				//Save line references for later use
				if(chartType == MAIN_CHART)
					mainChartLinePictureList.push(lineImage);
				else if (chartType == SCROLLER_CHART)
					scrollerChartLinePictureList.push(lineImage);
			}
			else
			{
				//Line size exceeds hardware capabilities to convert it to bitmap.
				if(chartType == MAIN_CHART)
					mainChart.addChild(line);
				else if(chartType == SCROLLER_CHART)
				{
					scrollerChart.addChild(line);
				}
				
				//Save line references for later use
				if(chartType == MAIN_CHART)
					mainChartLineList.push(line);
				else if (chartType == SCROLLER_CHART)
				{
					scrollerChartLineList.push(line);
				}
			}
		}
		
		public function hideLine():void
		{
			if(_displayLine == true)
			{
				_displayLine = false;
				
				//Dispose previous lines
				destroyAllLines();
				
				//Dispose textures
				disposeTextures();
				
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
				currentMarker.alpha = 1;
			}
		}
		
		public function addGlucose(glucoseValue:Number):void
		{
			//var timestampNow:Number = new Date().valueOf();
			var timestampNow:Number = Number(mainChartGlucoseMarkersList[mainChartGlucoseMarkersList.length - 1].timestamp) + (1000 * 60 * 5); //CHEAT: This is last glucose value plus 5 minutes
			var timestampFirst:Number = Number(mainChartGlucoseMarkersList[0].timestamp);
			var dayInTimestamp:Number = (1000 * 60 * 60 * 24) - (1000 * 60 * 5); //CHEAT: This is 1 day minus 5 minutes
			
			if(timestampNow - timestampFirst > dayInTimestamp)
			{
				//Array has more than 24h of data. Remove first glucose marker and object 
				var firstMainGlucoseMarker:GlucoseMarker = mainChartGlucoseMarkersList.shift();
				var firstScrollGlucoseMarker:GlucoseMarker = scrollChartGlucoseMarkersList.shift();
				_dataSource.shift();
				
				//Remove that glucose marker from both the main and the scroller chart
				mainChart.removeChild(firstMainGlucoseMarker);
				firstMainGlucoseMarker.dispose();
				firstMainGlucoseMarker = null;
				scrollerChart.removeChild(firstScrollGlucoseMarker);
				firstScrollGlucoseMarker.dispose();
				firstScrollGlucoseMarker = null;
				
				if(_displayLine)
				{
					//Dispose previous lines
					destroyAllLines();
					//Dispose textures
					disposeTextures();
				}
			}
			
			//Add the new value to the data array
			_dataSource.push({timestamp:timestampNow,calculatedValue:glucoseValue});
			
			//Redraw main chart and scroller chart
			redrawChart(MAIN_CHART, _graphWidth - yAxisMargin, _graphHeight, yAxisMargin, mainChartGlucoseMarkerRadius);
			redrawChart(SCROLLER_CHART, _scrollerWidth - (scrollerChartGlucoseMarkerRadius * 2), _scrollerHeight, 0, scrollerChartGlucoseMarkerRadius);
		}
		
		private function redrawChart(chartType:String, chartWidth:Number, chartHeight:Number, chartRightMargin:Number, glucoseMarkerRadius:Number):void
		{
			/**
			 * Calculation of X Axis scale factor
			 */
			var firstTimeStamp:Number = Number(_dataSource[0].timestamp);
			var lastTimeStamp:Number = Number(_dataSource[_dataSource.length - 1].timestamp);
			var totalTimestampDifference:Number = lastTimeStamp - firstTimeStamp;
			var scaleXFactor:Number;
			if(chartType == MAIN_CHART)
				scaleXFactor = 1/(totalTimestampDifference / (chartWidth * timelineRange));
			else if (chartType == SCROLLER_CHART)
				scaleXFactor = 1/(totalTimestampDifference / (chartWidth - chartRightMargin));
			
			/**
			 * Calculation of Y Axis scale factor
			 */
			//First we determine the maximum and minimum glucose values
			var previousHighestGlucoseValue:Number = highestGlucoseValue;
			var previousLowestGlucoseValue:Number = lowestGlucoseValue;
			var sortDataArray:Array = _dataSource.concat();
			sortDataArray.sortOn(["calculatedValue"], Array.NUMERIC);
			lowestGlucoseValue = sortDataArray[0].calculatedValue as Number;
			highestGlucoseValue = sortDataArray[sortDataArray.length - 1].calculatedValue as Number;
			//We find the difference so we can know how big the glucose pseudo graph is
			var totalGlucoseDifference:Number = highestGlucoseValue - lowestGlucoseValue;
			//Now we find a multiplier for the y axis so the glucose graph fits entirely with the chart height
			scaleYFactor = (chartHeight - (glucoseMarkerRadius*2))/totalGlucoseDifference;
			
			/**
			 * Internal variables
			 */
			var i:int; //common index for loops
			var previousXCoordinate:Number = 0; //holder for x coordinate of the glucose value to be used by the following one
			
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
				var glucoseMarker:GlucoseMarker;
				if(i < dataLength - 1 && chartType == MAIN_CHART)
					glucoseMarker = mainChartGlucoseMarkersList[i]
				else if(i < dataLength - 1 && chartType == SCROLLER_CHART)
					glucoseMarker = scrollChartGlucoseMarkersList[i];
				
				var color:int = glucoseMarker.color;
				
				//Define glucose marker x position
				var glucoseX:Number;
				if(i==0)
					glucoseX = 0;
				else
					glucoseX = (Number(_dataSource[i].timestamp) - Number(_dataSource[i-1].timestamp)) * scaleXFactor;
				
				//Define glucose marker y position
				var glucoseY:Number = chartHeight - (glucoseMarkerRadius*2) - ((currentGlucoseValue - lowestGlucoseValue) * scaleYFactor);
				if(totalGlucoseDifference == 0) //If glucose is a perfect flat line then display it in the middle
					glucoseY = (chartHeight - (glucoseMarkerRadius*2)) / 2;
				
				if(i < dataLength - 1)
				{
					if (chartType == MAIN_CHART)
					{
						//Reposition
						glucoseMarker.x = previousXCoordinate + glucoseX;
						glucoseMarker.y = glucoseY;
					}
					else if (chartType == SCROLLER_CHART)
					{
						//Reposition
						glucoseMarker.x = previousXCoordinate + glucoseX;
						glucoseMarker.y = glucoseY;
					}
				}
				else
				{
					//Create
					//Define glucose marker color
					if(currentGlucoseValue >= glucoseUrgentHigh)
						color = highUrgentGlucoseMarkerColor;
					else if(currentGlucoseValue >= glucoseHigh)
						color = highGlucoseMarkerColor;
					else if(currentGlucoseValue > glucoseLow && currentGlucoseValue < glucoseHigh)
						color = inrangeGlucoseMarkerColor;
					else if(currentGlucoseValue <= glucoseLow && currentGlucoseValue > glucoseUrgentLow)
						color = lowGlucoseMarkerColor;
					else if(currentGlucoseValue <= glucoseUrgentLow)
						color = lowUrgentGlucoseMarkerColor;
					
					//Create glucose marker
					glucoseMarker = new GlucoseMarker(glucoseMarkerRadius, color);
					glucoseMarker.x = previousXCoordinate + glucoseX;
					glucoseMarker.y = glucoseY;
					glucoseMarker.timestamp = _dataSource[i].timestamp;
					glucoseMarker.glucoseValue = _dataSource[i].calculatedValue;
					
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
				
				
				//Draw line
				if(_displayLine)
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
						
						line.graphics.lineStyle(1, color, 1);
						line.graphics.lineTo(currentLineX, currentLineY);
						line.graphics.moveTo(currentLineX, currentLineY);
					}
					//Hide glucose marker
					glucoseMarker.alpha = 0;
				}
				//Update variables for next iteration
				previousXCoordinate = previousXCoordinate + glucoseX;
			}
			
			if(chartType == MAIN_CHART)
			{
				//YAxis
				if(highestGlucoseValue != previousHighestGlucoseValue || lowestGlucoseValue != previousLowestGlucoseValue)
				{
					//Dispose YAxis
					yAxisContainer.dispose();
					//yAxisContainer = null;
					
					//Redraw YAxis
					yAxisContainer.addChild(drawYAxis());
				}
				
				//Update glucose display textfield
				if(handPicker.x == _graphWidth - handPicker.width)
				{
					glucoseValueDisplay.text = String(int((mainChartGlucoseMarkersList[mainChartGlucoseMarkersList.length - 1].glucoseValue) * 10) / 10);// + " " + glucoseUnits;
					glucoseValueDisplay.fontStyles.color = mainChartGlucoseMarkersList[mainChartGlucoseMarkersList.length - 1].color;
					//glucoseValueDisplay.x = _graphWidth - glucoseValueDisplay.width -glucoseStatusLabelsMargin;
				}
			}
			//Chart Line
			if(_displayLine)
			{
				//Check if we can create a bitmap representation of the line without exceeding hardware capabilities
				if((line.width < 2048 && DeviceInfo.getDeviceType() != DeviceInfo.IPHONE_X && DeviceInfo.getDeviceType() != DeviceInfo.TABLET))
				{
					//Create a bitmap from the line. This is more memory and CPU efficient
					var lineTexture:RenderTexture;
					if(chartType == MAIN_CHART)
						lineTexture = new RenderTexture(mainChart.width, mainChart.height);
					else if (chartType == SCROLLER_CHART)
						lineTexture = new RenderTexture(scrollerChart.width, scrollerChart.height);
					lineTexture.draw(line);
					var lineImage:Image = new Image(lineTexture);
					if(chartType == MAIN_CHART)
						mainChart.addChild(lineImage);
					else if(chartType == SCROLLER_CHART)
						scrollerChart.addChild(lineImage);
					
					//Dispose line for memory managemnt
					line.dispose();
					line = null;
					
					//Save texture for later memory cleaning
					textureList.push(lineTexture);
					
					//Save line references for later use
					if(chartType == MAIN_CHART)
						mainChartLinePictureList.push(lineImage);
					else if (chartType == SCROLLER_CHART)
						scrollerChartLinePictureList.push(lineImage);
				}
				else
				{
					//Line size exceeds hardware capabilities to convert it to bitmap.
					if(chartType == MAIN_CHART)
						mainChart.addChild(line);
					else if(chartType == SCROLLER_CHART)
						scrollerChart.addChild(line);
					
					//Save line references for later use
					if(chartType == MAIN_CHART)
					{
						mainChartLineList.push(line);
					}
					else if (chartType == SCROLLER_CHART)
					{
						scrollerChartLineList.push(line);
					}
				}
			}
		}
		
		private function destroyAllLines():void
		{
			var i:int = 0
			if(mainChartLineList != null && mainChartLineList.length > 0)
			{
				for (i = 0; i < mainChartLineList.length; i++) 
				{
					try
					{
						mainChart.removeChild(mainChartLineList[i]);
						mainChartLineList[i].dispose();
						mainChartLineList[i] = null;
					} 
					catch(error:Error) {}
				}
				mainChartLineList.length = 0;
			}
			if(mainChartLinePictureList != null && mainChartLinePictureList.length > 0)
			{
				for (i = 0; i < mainChartLinePictureList.length; i++) 
				{
					try
					{
						mainChart.removeChild(mainChartLinePictureList[i]);
						mainChartLinePictureList[i].dispose();
						mainChartLinePictureList[i] = null;
					} 
					catch(error:Error) {}
				}
				mainChartLinePictureList.lenght = 0;
			}
			if(scrollerChartLineList != null && scrollerChartLineList.length > 0)
			{
				for (i = 0; i < scrollerChartLineList.length; i++) 
				{
					try
					{
						scrollerChart.removeChild(scrollerChartLineList[i]);
						scrollerChartLineList[i].dispose();
						scrollerChartLineList[i] = null;
					} 
					catch(error:Error) {}
				}
				scrollerChartLineList.length = 0;
			}
			if(scrollerChartLinePictureList != null && scrollerChartLinePictureList.length > 0)
			{
				for (i = 0; i < scrollerChartLinePictureList.length; i++) 
				{
					try
					{
						scrollerChart.removeChild(scrollerChartLinePictureList[i]);
						scrollerChartLinePictureList[i].dispose();
						scrollerChartLinePictureList[i] = null;
					} 
					catch(error:Error) {}
				}
				scrollerChartLinePictureList.length = 0;
			}
		}
		
		public function disposeTextures():void
		{
			for (var i:int = 0; i < textureList.length; i++) 
			{
				(textureList[i] as RenderTexture).dispose();
				System.pauseForGCIfCollectionImminent(0);
			}
			
		}
		
		override public function dispose():void
		{
			disposeTextures();
			super.dispose();
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