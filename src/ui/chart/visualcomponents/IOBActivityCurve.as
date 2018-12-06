package ui.chart.visualcomponents
{
	import flash.geom.Rectangle;
	
	import database.CommonSettings;
	
	import feathers.controls.Label;
	import feathers.controls.LayoutGroup;
	import feathers.controls.ScrollBarDisplayMode;
	import feathers.controls.ScrollContainer;
	import feathers.controls.ScrollPolicy;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalAlign;
	import feathers.layout.VerticalLayout;
	
	import model.ModelLocator;
	
	import starling.display.Sprite;
	
	import treatments.TreatmentsManager;
	
	import ui.screens.display.LayoutFactory;
	import ui.shapes.SpikeLine;
	
	import utils.Constants;
	import utils.TimeSpan;
	import ui.chart.layout.GraphLayoutFactory;
	
	[ResourceBundle("chartscreen")]
	
	public class IOBActivityCurve extends ScrollContainer
	{
		//Properties
		public var leftPadding:Number = 0;

		//Display Objects
		private var mainContainer:LayoutGroup;
		private var IOBContainer:Sprite;
		private var activityContainer:Sprite;
		private var iobGraphTitle:Label;
		private var activityGraphTitle:Label;
		private var highestIOBCurveLabel:Label;
		private var highestActivityCurveLabel:Label;
		private var middleIOBCurveLabel:Label;
		private var middleActivityCurveLabel:Label;
		private var lowestIOBCurveLabel:Label;
		private var lowestActivityCurveLabel:Label;
		private var IOBCurve:SpikeLine;
		private var activityCurve:SpikeLine;
		private var yIOBAxisLine:SpikeLine;
		private var xIOBAxisLine:SpikeLine;
		private var yActivityAxisLine:SpikeLine;
		private var xActivityAxisLine:SpikeLine;
		private var firstIOBTimeLabel:Label;
		private var firstActivityTimeLabel:Label;
		private var nowIOBTimeLabel:Label;
		private var nowIOBValueLabel:Label;
		private var nowIOBTimeMarker:SpikeLine;
		private var nowActivityTimeLabel:Label;
		private var nowActivityValueLabel:Label;
		private var nowActivityTimeMarker:SpikeLine;
		private var lastIOBTimeLabel:Label;
		private var lastActivityTimeLabel:Label;
		private var iobAxisLegend:Label;
		private var activityAxisLegend:Label;
		
		public function IOBActivityCurve()
		{
			//Container properties
			mainContainer = LayoutFactory.createLayoutGroup("vertical", HorizontalAlign.LEFT, VerticalAlign.TOP, 10);
			mainContainer.touchable = false;
			addChild(mainContainer);
			
			horizontalScrollPolicy = ScrollPolicy.OFF;
			scrollBarDisplayMode = ScrollBarDisplayMode.FIXED_FLOAT;
			verticalScrollBarProperties.paddingLeft = 10;
			layout = new VerticalLayout();
			
			IOBContainer = new Sprite();
			activityContainer = new Sprite();
			
			//Titles
			iobGraphTitle = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('chartscreen','iob_curve_title_label'), HorizontalAlign.CENTER, VerticalAlign.TOP, 14, true);
			activityGraphTitle = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('chartscreen','insulin_activity_curve_title_label'), HorizontalAlign.CENTER, VerticalAlign.TOP, 14, true);
			
			//Properties
			var axisFontColor:uint = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_AXIS_FONT_COLOR));
			var lineColor:uint = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_AXIS_COLOR));
			
			//Data
			var initialIOBAndActivity:Object = TreatmentsManager.getTotalIOB(new Date().valueOf());
			var currentIOB:Number = initialIOBAndActivity.iob;
			var currentActivity:Number = initialIOBAndActivity.activityForecast;
			
			//Data points
			var totalTreatmentsData:Number = initialIOBAndActivity.bolusinsulin;
			var firstTreatmentTimestamp:Number = initialIOBAndActivity.firstInsulinTime;
			var IOBDataPoints:Array = [];
			var activityDataPoints:Array = [];
			var pointInTime:Number = firstTreatmentTimestamp;
			var pointInTimeData:Object = TreatmentsManager.getTotalIOB(pointInTime);
			var IOBDataPoint:Number = pointInTimeData.iob;
			var activityDataPoint:Number = pointInTimeData.activityForecast;
			IOBDataPoints.push( { timestamp: pointInTime, dataPoint: IOBDataPoint } );
			activityDataPoints.push( { timestamp: pointInTime, dataPoint: activityDataPoint } );
			
			while (IOBDataPoint >= 0 || activityDataPoint >= 0)
			{
				pointInTime += TimeSpan.TIME_1_MINUTE;
				pointInTimeData = TreatmentsManager.getTotalIOB(pointInTime);
				IOBDataPoint = pointInTimeData.iob;
				activityDataPoint = pointInTimeData.activityForecast;
				IOBDataPoints.push( { timestamp: pointInTime, dataPoint: IOBDataPoint } );
				activityDataPoints.push( { timestamp: pointInTime, dataPoint: activityDataPoint } );
				
				if (IOBDataPoint <= 0 && activityDataPoint <= 0)
					break;
			}
			
			//Calculators
			var leftPaddingIOB:Number = 0;
			var leftPaddingActivity:Number = 0;
			
			leftPadding
			
			var firstTimestamp:Number = IOBDataPoints[0].timestamp;
			var lastTimestamp:Number = IOBDataPoints[IOBDataPoints.length - 1].timestamp;
			var totalTimestampDifference:Number = lastTimestamp - firstTimestamp;
			
			var sortedIOBData:Array = IOBDataPoints.concat();
			sortedIOBData.sortOn(["dataPoint"], Array.NUMERIC);
			var highestIOBDataPoint:Number = sortedIOBData[sortedIOBData.length -1].dataPoint;
			var lowestIOBDataPoint:Number = sortedIOBData[0].dataPoint;
			var totalIOBDataDifference:Number = highestIOBDataPoint - lowestIOBDataPoint;
			
			var sortedActivityData:Array = activityDataPoints.concat();
			sortedActivityData.sortOn(["dataPoint"], Array.NUMERIC);
			var highestActivityDataPoint:Number = sortedActivityData[sortedActivityData.length -1].dataPoint;
			var lowestActivityDataPoint:Number = sortedActivityData[0].dataPoint;
			var totalActivityDataDifference:Number = highestActivityDataPoint - lowestActivityDataPoint;
			
			//YAXIS LABELS
			//Highest IOB value
			highestIOBCurveLabel = LayoutFactory.createLabel(String(Math.round(highestIOBDataPoint * 1000) / 1000) + "U", HorizontalAlign.RIGHT, VerticalAlign.TOP, 12, false, axisFontColor);
			highestIOBCurveLabel.touchable = false;
			highestIOBCurveLabel.validate();
			highestIOBCurveLabel.x = -highestIOBCurveLabel.width - 7;
			highestIOBCurveLabel.y = -highestIOBCurveLabel.height / 4.5;
			IOBContainer.addChild(highestIOBCurveLabel);
			if (highestIOBCurveLabel.x < leftPaddingIOB) leftPaddingIOB = highestIOBCurveLabel.x;
			
			highestActivityCurveLabel = LayoutFactory.createLabel(String(Math.round(highestActivityDataPoint * 1000) / 1000) + "U", HorizontalAlign.RIGHT, VerticalAlign.TOP, 12, false, axisFontColor);
			highestActivityCurveLabel.touchable = false;
			highestActivityCurveLabel.validate();
			highestActivityCurveLabel.x = -highestActivityCurveLabel.width - 7;
			highestActivityCurveLabel.y = -highestActivityCurveLabel.height / 4.5;
			activityContainer.addChild(highestActivityCurveLabel);
			if (highestActivityCurveLabel.x < leftPaddingActivity) leftPaddingActivity = highestActivityCurveLabel.x;
			
			//Middle value
			var middleIOBValue:Number = Math.round((highestIOBDataPoint / 2) * 100) / 100;
			middleIOBCurveLabel = LayoutFactory.createLabel(String(middleIOBValue) + "U", HorizontalAlign.RIGHT, VerticalAlign.TOP, 12, false, axisFontColor);
			middleIOBCurveLabel.touchable = false;
			middleIOBCurveLabel.validate();
			middleIOBCurveLabel.x = -middleIOBCurveLabel.width - 7;
			IOBContainer.addChild(middleIOBCurveLabel);
			if (middleIOBCurveLabel.x < leftPaddingIOB) leftPaddingIOB = middleIOBCurveLabel.x;
			
			var middleActivityValue:Number = highestActivityDataPoint / 2;
			middleActivityCurveLabel = LayoutFactory.createLabel(String(Math.round(middleActivityValue * 1000) / 1000) + "U", HorizontalAlign.RIGHT, VerticalAlign.TOP, 12, false, axisFontColor);
			middleActivityCurveLabel.touchable = false;
			middleActivityCurveLabel.validate();
			middleActivityCurveLabel.x = -middleActivityCurveLabel.width - 7;
			activityContainer.addChild(middleActivityCurveLabel);
			if (middleActivityCurveLabel.x < leftPaddingActivity) leftPaddingActivity = middleActivityCurveLabel.x;
			
			//Lowest value
			lowestIOBCurveLabel = LayoutFactory.createLabel("0" + "U", HorizontalAlign.RIGHT, VerticalAlign.TOP, 12, false, axisFontColor);
			lowestIOBCurveLabel.touchable = false;
			lowestIOBCurveLabel.validate();
			lowestIOBCurveLabel.x = -lowestIOBCurveLabel.width - 7;
			IOBContainer.addChild(lowestIOBCurveLabel);
			if (lowestIOBCurveLabel.x < leftPaddingIOB) leftPaddingIOB = lowestIOBCurveLabel.x;
			
			lowestActivityCurveLabel = LayoutFactory.createLabel("0" + "U", HorizontalAlign.RIGHT, VerticalAlign.TOP, 12, false, axisFontColor);
			lowestActivityCurveLabel.touchable = false;
			lowestActivityCurveLabel.validate();
			lowestActivityCurveLabel.x = -lowestActivityCurveLabel.width - 7;
			activityContainer.addChild(lowestActivityCurveLabel);
			if (lowestActivityCurveLabel.x < leftPaddingActivity) leftPaddingActivity = lowestActivityCurveLabel.x;
			
			//Determine Left Padding
			leftPadding = Math.min(leftPaddingActivity, leftPaddingIOB);
			
			//Curves 
			var graphWidth:Number = Constants.isPortrait ? Constants.stageWidth - Math.abs(leftPadding) - 35 : Constants.stageHeight - Math.abs(leftPadding) - 35;
			var graphHeight:Number = graphWidth / 3;
			var scaleXFactor:Number = 1 / (totalTimestampDifference / graphWidth);
			var i:int;
			
			//IOB
			var scaleIOBYFactor:Number = graphHeight / totalIOBDataDifference;
			
			middleIOBCurveLabel.y = (graphHeight / 2) - (middleIOBCurveLabel.height / 2);
			lowestIOBCurveLabel.y = graphHeight - lowestIOBCurveLabel.height + (lowestIOBCurveLabel.height / 4.5);
			
			IOBCurve = new SpikeLine();
			IOBCurve.touchable = false;
			IOBCurve.lineStyle(1.5, uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_INSULIN_MARKER_COLOR)));
			var previousIOBXCoordinate:Number = 0;
			
			var IOBdataLength:int = IOBDataPoints.length;
			for(i = 0; i < IOBdataLength; i++)
			{
				var currentIOBDataPointValue:Number = IOBDataPoints[i].dataPoint;
				
				//Define data point x position
				var IOBDataX:Number;
				if(i==0) IOBDataX = 0;
				else IOBDataX = (Number(IOBDataPoints[i].timestamp) - Number(IOBDataPoints[i-1].timestamp)) * scaleXFactor;
				
				IOBDataX = previousIOBXCoordinate + IOBDataX;
				
				//Define glucose marker y position
				var IOBDataY:Number = graphHeight - ((currentIOBDataPointValue - lowestIOBDataPoint) * scaleIOBYFactor);
				
				if (i == 0)
					IOBCurve.moveTo(IOBDataX, IOBDataY);
				else
				{
					IOBCurve.lineTo(IOBDataX, IOBDataY);
					IOBCurve.moveTo(IOBDataX, IOBDataY);
				}
				
				previousIOBXCoordinate = IOBDataX;
			}
			
			IOBContainer.addChild(IOBCurve);
			
			//Activity
			var scaleActivityYFactor:Number = graphHeight / totalActivityDataDifference;
			
			middleActivityCurveLabel.y = (graphHeight / 2) - (middleActivityCurveLabel.height / 2);
			lowestActivityCurveLabel.y = graphHeight - lowestActivityCurveLabel.height + (lowestActivityCurveLabel.height / 4.5);
			
			activityCurve = new SpikeLine();
			activityCurve.touchable = false;
			activityCurve.lineStyle(1.5, uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_INSULIN_MARKER_COLOR)));
			var previousActivityXCoordinate:Number = 0;
			
			var activitydataLength:int = activityDataPoints.length;
			for(i = 0; i < activitydataLength; i++)
			{
				var currentActivityDataPointValue:Number = activityDataPoints[i].dataPoint;
				
				//Define data point x position
				var activityDataX:Number;
				if(i==0) activityDataX = 0;
				else activityDataX = (Number(activityDataPoints[i].timestamp) - Number(activityDataPoints[i-1].timestamp)) * scaleXFactor;
				
				activityDataX = previousActivityXCoordinate + activityDataX;
				
				//Define glucose marker y position
				var activityDataY:Number = graphHeight - ((currentActivityDataPointValue - lowestActivityDataPoint) * scaleActivityYFactor);
				
				if (i == 0)
					activityCurve.moveTo(activityDataX, activityDataY);
				else
				{
					activityCurve.lineTo(activityDataX, activityDataY);
					activityCurve.moveTo(activityDataX, activityDataY);
				}
				
				previousActivityXCoordinate = activityDataX;
			}
			
			activityContainer.addChild(activityCurve);
			
			//Draw Axis
			//IOB
			yIOBAxisLine = GraphLayoutFactory.createVerticalLine(graphHeight, 1.5, lineColor);
			yIOBAxisLine.touchable = false;
			IOBContainer.addChild(yIOBAxisLine);
			
			xIOBAxisLine = GraphLayoutFactory.createHorizontalLine(graphWidth, 1.5, lineColor);
			xIOBAxisLine.touchable = false;
			xIOBAxisLine.y = yIOBAxisLine.y + yIOBAxisLine.height;
			IOBContainer.addChild(xIOBAxisLine);
			
			//Activity
			yActivityAxisLine = GraphLayoutFactory.createVerticalLine(graphHeight, 1.5, lineColor);
			yActivityAxisLine.touchable = false;
			activityContainer.addChild(yActivityAxisLine);
			
			xActivityAxisLine = GraphLayoutFactory.createHorizontalLine(graphWidth, 1.5, lineColor);
			xActivityAxisLine.touchable = false;
			xActivityAxisLine.y = yActivityAxisLine.y + yActivityAxisLine.height;
			activityContainer.addChild(xActivityAxisLine);
			
			//Draw X Labels
			var dateFormat:String = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_DATE_FORMAT);
			
			//First Timestamo
			var firstDate:Date = new Date(firstTreatmentTimestamp);
			var timeFormatted:String = "";
			if (dateFormat.slice(0,2) == "24")
				timeFormatted = TimeSpan.formatHoursMinutes(firstDate.getHours(), firstDate.getMinutes(), TimeSpan.TIME_FORMAT_24H);
			else
				timeFormatted = TimeSpan.formatHoursMinutes(firstDate.getHours(), firstDate.getMinutes(), TimeSpan.TIME_FORMAT_12H);
			
			firstIOBTimeLabel = LayoutFactory.createLabel(timeFormatted, HorizontalAlign.LEFT, VerticalAlign.TOP, 12, false, axisFontColor);
			firstIOBTimeLabel.touchable = false;
			firstIOBTimeLabel.validate();
			firstIOBTimeLabel.x = 0;
			firstIOBTimeLabel.y = xIOBAxisLine.y + xIOBAxisLine.height + 4;
			IOBContainer.addChild(firstIOBTimeLabel);
			var firstIOBTimeLabelBounds:Rectangle = firstIOBTimeLabel.bounds;
			
			firstActivityTimeLabel = LayoutFactory.createLabel(timeFormatted, HorizontalAlign.LEFT, VerticalAlign.TOP, 12, false, axisFontColor);
			firstActivityTimeLabel.touchable = false;
			firstActivityTimeLabel.validate();
			firstActivityTimeLabel.x = 0;
			firstActivityTimeLabel.y = xActivityAxisLine.y + xActivityAxisLine.height + 4;
			activityContainer.addChild(firstActivityTimeLabel);
			var firstActivityTimeLabelBounds:Rectangle = firstActivityTimeLabel.bounds;
			
			//Now
			var now:Number = new Date().valueOf();
			
			nowIOBTimeLabel = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('chartscreen','now').toUpperCase(), HorizontalAlign.LEFT, VerticalAlign.TOP, 12, false, axisFontColor);
			nowIOBTimeLabel.touchable = false;
			nowIOBTimeLabel.validate();
			nowIOBTimeLabel.x = ((now - firstTreatmentTimestamp) * scaleXFactor) - (nowIOBTimeLabel.width / 2);
			nowIOBTimeLabel.y = xIOBAxisLine.y + xIOBAxisLine.height + 4;
			IOBContainer.addChild(nowIOBTimeLabel);
			
			nowIOBValueLabel = LayoutFactory.createLabel(String(Math.round(currentIOB * 100) / 100) + "U", HorizontalAlign.LEFT, VerticalAlign.TOP, 9, false, axisFontColor);
			nowIOBValueLabel.touchable = false;
			nowIOBValueLabel.validate();
			nowIOBValueLabel.x = ((now - firstTreatmentTimestamp) * scaleXFactor) - (nowIOBValueLabel.width / 2);
			nowIOBValueLabel.y = 0 - nowIOBValueLabel.height - 3;
			IOBContainer.addChild(nowIOBValueLabel);
			
			nowIOBTimeMarker = GraphLayoutFactory.createVerticalDashedLine(graphHeight, 2, 1, 1, lineColor);
			nowIOBTimeMarker.touchable = false;
			nowIOBTimeMarker.x = ((now - firstTreatmentTimestamp) * scaleXFactor);
			nowIOBTimeMarker.y = 0;
			IOBContainer.addChild(nowIOBTimeMarker);
			
			var nowIOBTimeBounds:Rectangle = nowIOBTimeLabel.bounds;
			
			if (nowIOBTimeBounds.intersects(firstIOBTimeLabelBounds))
			{
				nowIOBTimeLabel.removeFromParent(true);
				nowIOBTimeLabel = null;
			}
			
			nowActivityTimeLabel = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('chartscreen','now').toUpperCase(), HorizontalAlign.LEFT, VerticalAlign.TOP, 12, false, axisFontColor);
			nowActivityTimeLabel.touchable = false;
			nowActivityTimeLabel.validate();
			nowActivityTimeLabel.x = ((now - firstTreatmentTimestamp) * scaleXFactor) - (nowActivityTimeLabel.width / 2);
			nowActivityTimeLabel.y = xActivityAxisLine.y + xActivityAxisLine.height + 4;
			activityContainer.addChild(nowActivityTimeLabel);
			
			nowActivityValueLabel = LayoutFactory.createLabel(String(Math.round(currentActivity * 1000) / 1000) + "U", HorizontalAlign.LEFT, VerticalAlign.TOP, 9, false, axisFontColor);
			nowActivityValueLabel.touchable = false;
			nowActivityValueLabel.validate();
			nowActivityValueLabel.x = ((now - firstTreatmentTimestamp) * scaleXFactor) - (nowActivityValueLabel.width / 2);
			nowActivityValueLabel.y = 0 - nowActivityValueLabel.height - 3;
			activityContainer.addChild(nowActivityValueLabel);
			
			nowActivityTimeMarker = GraphLayoutFactory.createVerticalDashedLine(graphHeight, 2, 1, 1, lineColor);
			nowActivityTimeMarker.touchable = false;
			nowActivityTimeMarker.x = ((now - firstTreatmentTimestamp) * scaleXFactor);
			nowActivityTimeMarker.y = 0;
			activityContainer.addChild(nowActivityTimeMarker);
			
			var nowActivityTimeBounds:Rectangle = nowActivityTimeLabel.bounds;
			
			if (nowActivityTimeBounds.intersects(firstActivityTimeLabelBounds))
			{
				nowActivityTimeLabel.removeFromParent(true);
				nowActivityTimeLabel = null;
			}
			
			//Last timestamp
			var lastDate:Date = new Date(lastTimestamp);
			var lastTimeFormatted:String = "";
			if (dateFormat.slice(0,2) == "24")
				lastTimeFormatted = TimeSpan.formatHoursMinutes(lastDate.getHours(), lastDate.getMinutes(), TimeSpan.TIME_FORMAT_24H);
			else
				lastTimeFormatted = TimeSpan.formatHoursMinutes(lastDate.getHours(), lastDate.getMinutes(), TimeSpan.TIME_FORMAT_12H);
			
			lastIOBTimeLabel = LayoutFactory.createLabel(lastTimeFormatted, HorizontalAlign.LEFT, VerticalAlign.TOP, 12, false, axisFontColor);
			lastIOBTimeLabel.touchable = false;
			lastIOBTimeLabel.validate();
			lastIOBTimeLabel.x = xIOBAxisLine.width - lastIOBTimeLabel.width;
			lastIOBTimeLabel.y = xIOBAxisLine.y + xIOBAxisLine.height + 4;
			IOBContainer.addChild(lastIOBTimeLabel);
			
			if (nowIOBTimeLabel != null)
			{
				var latestIOBLabelBounds:Rectangle = lastIOBTimeLabel.bounds;
				if (latestIOBLabelBounds.intersects(nowIOBTimeBounds))
					nowIOBTimeLabel.removeFromParent(true);
			}
			
			lastActivityTimeLabel = LayoutFactory.createLabel(lastTimeFormatted, HorizontalAlign.LEFT, VerticalAlign.TOP, 12, false, axisFontColor);
			lastActivityTimeLabel.touchable = false;
			lastActivityTimeLabel.validate();
			lastActivityTimeLabel.x = xActivityAxisLine.width - lastActivityTimeLabel.width;
			lastActivityTimeLabel.y = xActivityAxisLine.y + xActivityAxisLine.height + 4;
			activityContainer.addChild(lastActivityTimeLabel);
			
			if (nowActivityTimeLabel != null)
			{
				var latestActivityLabelBounds:Rectangle = lastActivityTimeLabel.bounds;
				if (latestActivityLabelBounds.intersects(nowActivityTimeBounds))
					nowActivityTimeLabel.removeFromParent(true);
			}
			
			//Dispose unneded data
			if (IOBDataPoints != null)
			{
				IOBDataPoints.length = 0;
				IOBDataPoints = null;
			}
			
			if (sortedIOBData != null)
			{
				sortedIOBData.length = 0;
				sortedIOBData = null;
			}
			
			if (activityDataPoints != null)
			{
				activityDataPoints.length = 0;
				activityDataPoints = null;
			}
			
			if (sortedActivityData != null)
			{
				sortedActivityData.length = 0;
				sortedActivityData = null;
			}
			
			//Graph Legends
			iobAxisLegend = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('chartscreen','iob_curve_chart_legend_label'), HorizontalAlign.CENTER, VerticalAlign.TOP, 9, false, axisFontColor);
			iobAxisLegend.wordWrap = true;
			iobAxisLegend.paddingTop = -5;
			iobAxisLegend.paddingBottom += 19;
			
			activityAxisLegend = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('chartscreen','insulin_activity_curve_chart_legend_label'), HorizontalAlign.CENTER, VerticalAlign.TOP, 9, false, axisFontColor);
			activityAxisLegend.wordWrap = true;
			activityAxisLegend.paddingTop = -5;
			activityAxisLegend.paddingBottom += 19;
			
			//Add Objects to Display List
			mainContainer.addChild(iobGraphTitle);
			mainContainer.addChild(iobAxisLegend);
			mainContainer.addChild(IOBContainer);
			mainContainer.addChild(activityGraphTitle);
			mainContainer.addChild(activityAxisLegend);
			mainContainer.addChild(activityContainer);
			
			//Final Layout Adjustments
			iobGraphTitle.width = graphWidth + Math.abs(leftPadding);
			iobAxisLegend.width = graphWidth + Math.abs(leftPadding);
			activityGraphTitle.width = graphWidth + Math.abs(leftPadding);
			activityAxisLegend.width = graphWidth + Math.abs(leftPadding);
			
			paddingLeft = leftPadding;
			
			mainContainer.validate();
			IOBContainer.x += Math.abs(leftPaddingIOB);
			activityContainer.x += Math.abs(leftPaddingActivity);
			
			var absoluteLeftPaddingIOB:Number = Math.abs(leftPaddingIOB);
			var absoluteLeftPaddingActivity:Number = Math.abs(leftPaddingActivity);
			
			if (absoluteLeftPaddingActivity > absoluteLeftPaddingIOB)
			{
				IOBContainer.x += (absoluteLeftPaddingActivity - absoluteLeftPaddingIOB) / 2;
			}
			else if (absoluteLeftPaddingIOB > absoluteLeftPaddingActivity)
			{
				activityContainer.x += (absoluteLeftPaddingIOB - absoluteLeftPaddingActivity) / 2;
			}
		}
		
		override public function dispose():void
		{
			if (activityAxisLegend != null)
			{
				activityAxisLegend.removeFromParent();
				activityAxisLegend.dispose();
				activityAxisLegend = null;
			}
			
			if (iobAxisLegend != null)
			{
				iobAxisLegend.removeFromParent();
				iobAxisLegend.dispose();
				iobAxisLegend = null;
			}
			
			if (lastActivityTimeLabel != null)
			{
				lastActivityTimeLabel.removeFromParent();
				lastActivityTimeLabel.dispose();
				lastActivityTimeLabel = null;
			}
			
			if (lastIOBTimeLabel != null)
			{
				lastIOBTimeLabel.removeFromParent();
				lastIOBTimeLabel.dispose();
				lastIOBTimeLabel = null;
			}
			
			if (nowActivityTimeMarker != null)
			{
				nowActivityTimeMarker.removeFromParent();
				nowActivityTimeMarker.dispose();
				nowActivityTimeMarker = null;
			}
			
			if (nowActivityValueLabel != null)
			{
				nowActivityValueLabel.removeFromParent();
				nowActivityValueLabel.dispose();
				nowActivityValueLabel = null;
			}
			
			if (nowActivityTimeLabel != null)
			{
				nowActivityTimeLabel.removeFromParent();
				nowActivityTimeLabel.dispose();
				nowActivityTimeLabel = null;
			}
			
			if (nowIOBTimeMarker != null)
			{
				nowIOBTimeMarker.removeFromParent();
				nowIOBTimeMarker.dispose();
				nowIOBTimeMarker = null;
			}
			
			if (nowIOBValueLabel != null)
			{
				nowIOBValueLabel.removeFromParent();
				nowIOBValueLabel.dispose();
				nowIOBValueLabel = null;
			}
			
			if (nowIOBTimeLabel != null)
			{
				nowIOBTimeLabel.removeFromParent();
				nowIOBTimeLabel.dispose();
				nowIOBTimeLabel = null;
			}
			
			if (firstActivityTimeLabel != null)
			{
				firstActivityTimeLabel.removeFromParent();
				firstActivityTimeLabel.dispose();
				firstActivityTimeLabel = null;
			}
			
			if (firstIOBTimeLabel != null)
			{
				firstIOBTimeLabel.removeFromParent();
				firstIOBTimeLabel.dispose();
				firstIOBTimeLabel = null;
			}
			
			if (xActivityAxisLine != null)
			{
				xActivityAxisLine.removeFromParent();
				xActivityAxisLine.dispose();
				xActivityAxisLine = null;
			}
			
			if (xIOBAxisLine != null)
			{
				xIOBAxisLine.removeFromParent();
				xIOBAxisLine.dispose();
				xIOBAxisLine = null;
			}
			
			if (yIOBAxisLine != null)
			{
				yIOBAxisLine.removeFromParent();
				yIOBAxisLine.dispose();
				yIOBAxisLine = null;
			}
			
			if (activityCurve != null)
			{
				activityCurve.removeFromParent();
				activityCurve.dispose();
				activityCurve = null;
			}
			
			if (IOBCurve != null)
			{
				IOBCurve.removeFromParent();
				IOBCurve.dispose();
				IOBCurve = null;
			}
			
			if (lowestActivityCurveLabel != null)
			{
				lowestActivityCurveLabel.removeFromParent();
				lowestActivityCurveLabel.dispose();
				lowestActivityCurveLabel = null;
			}
			
			if (lowestIOBCurveLabel != null)
			{
				lowestIOBCurveLabel.removeFromParent();
				lowestIOBCurveLabel.dispose();
				lowestIOBCurveLabel = null;
			}
			
			if (middleActivityCurveLabel != null)
			{
				middleActivityCurveLabel.removeFromParent();
				middleActivityCurveLabel.dispose();
				middleActivityCurveLabel = null;
			}
			
			if (middleIOBCurveLabel != null)
			{
				middleIOBCurveLabel.removeFromParent();
				middleIOBCurveLabel.dispose();
				middleIOBCurveLabel = null;
			}
			
			if (highestActivityCurveLabel != null)
			{
				highestActivityCurveLabel.removeFromParent();
				highestActivityCurveLabel.dispose();
				highestActivityCurveLabel = null;
			}
			
			if (highestIOBCurveLabel != null)
			{
				highestIOBCurveLabel.removeFromParent();
				highestIOBCurveLabel.dispose();
				highestIOBCurveLabel = null;
			}
			
			if (activityGraphTitle != null)
			{
				activityGraphTitle.removeFromParent();
				activityGraphTitle.dispose();
				activityGraphTitle = null;
			}
			
			if (iobGraphTitle != null)
			{
				iobGraphTitle.removeFromParent();
				iobGraphTitle.dispose();
				iobGraphTitle = null;
			}
			
			if (activityContainer != null)
			{
				activityContainer.removeFromParent();
				activityContainer.dispose();
				activityContainer = null;
			}
			
			if (IOBContainer != null)
			{
				IOBContainer.removeFromParent();
				IOBContainer.dispose();
				IOBContainer = null;
			}
			
			if (mainContainer != null)
			{
				mainContainer.removeFromParent();
				mainContainer.dispose();
				mainContainer = null;
			}
			
			super.dispose();
		}
	}
}