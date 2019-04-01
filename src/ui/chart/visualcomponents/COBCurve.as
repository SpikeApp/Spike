package ui.chart.visualcomponents
{
	import flash.geom.Rectangle;
	
	import database.BgReading;
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
	
	public class COBCurve extends ScrollContainer
	{
		//Properties
		public var leftPadding:Number = 0;
		
		//Display Objects
		private var mainContainer:LayoutGroup;
		private var COBContainer:Sprite;
		private var cobGraphTitle:Label;
		private var highestCurveLabel:Label;
		private var middleCurveLabel:Label;
		private var lowestCurveLabel:Label;
		private var COBLineCurve:SpikeLine;
		private var yAxisLine:SpikeLine;
		private var xAxisLine:SpikeLine;
		private var firstCurveLabel:Label;
		private var nowCurveLabel:Label;
		private var nowCOBValueLabel:Label;
		private var nowCurveMarker:SpikeLine;
		private var lastCurveLabel:Label;
		private var cobAxisLegend:Label;
		private var oref0ExplanationLegend:Label;
		
		public function COBCurve()
		{
			var algorithm:String = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEFAULT_IOB_COB_ALGORITHM);
			
			if (algorithm == "nightscout")
			{
				plotNightscoutCOB();
			}
			else if (algorithm == "openaps")
			{
				plotOpenAPSCOB();
			}
		}
		
		private function plotNightscoutCOB():void
		{
			//Container properties
			mainContainer = LayoutFactory.createLayoutGroup("vertical", HorizontalAlign.LEFT, VerticalAlign.TOP, 10);
			mainContainer.touchable = false;
			addChild(mainContainer);
			
			horizontalScrollPolicy = ScrollPolicy.OFF;
			scrollBarDisplayMode = ScrollBarDisplayMode.FIXED_FLOAT;
			verticalScrollBarProperties.paddingLeft = 10;
			layout = new VerticalLayout();
			
			COBContainer = new Sprite();
			
			//Title
			cobGraphTitle = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('chartscreen','cob_curve_title_label'), HorizontalAlign.CENTER, VerticalAlign.TOP, 14, true);
			
			//Properties
			var axisFontColor:uint = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_AXIS_FONT_COLOR));
			var lineColor:uint = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_AXIS_COLOR));
			
			
			//Data
			var initialCOB:Object = TreatmentsManager.getTotalCOB(new Date().valueOf());
			var currentCOB:Number = initialCOB.cob;
			
			//Data points
			var totalTreatmentsData:Number = initialCOB.carbs;
			var firstTreatmentTimestamp:Number = initialCOB.firstCarbTime;
			var dataPoints:Array = [];
			var pointInTime:Number = firstTreatmentTimestamp;
			var dataPoint:Number = TreatmentsManager.getTotalCOB(pointInTime).cob;
			dataPoints.push( { timestamp: pointInTime, dataPoint: dataPoint } );
			
			while (dataPoint >= 0)
			{
				pointInTime += TimeSpan.TIME_1_MINUTE;
				dataPoint = TreatmentsManager.getTotalCOB(pointInTime).cob;
				dataPoints.push( { timestamp: pointInTime, dataPoint: dataPoint } );
					
				if (dataPoint == 0)
					break;
			}

			//Calculators
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
			highestCurveLabel = LayoutFactory.createLabel(String(highestDataPoint) + "g", HorizontalAlign.RIGHT, VerticalAlign.TOP, 12, false, axisFontColor);
			highestCurveLabel.touchable = false;
			highestCurveLabel.validate();
			highestCurveLabel.x = -highestCurveLabel.width - 7;
			highestCurveLabel.y = -highestCurveLabel.height / 4.5;
			COBContainer.addChild(highestCurveLabel);
			if (highestCurveLabel.x < leftPadding) leftPadding = highestCurveLabel.x;
			
			//Middle value
			var middleValue:Number = Math.round((highestDataPoint / 2) * 100) / 100;
			middleCurveLabel = LayoutFactory.createLabel(String(middleValue) + "g", HorizontalAlign.RIGHT, VerticalAlign.TOP, 12, false, axisFontColor);
			middleCurveLabel.touchable = false;
			middleCurveLabel.validate();
			middleCurveLabel.x = -middleCurveLabel.width - 7;
			COBContainer.addChild(middleCurveLabel);
			if (middleCurveLabel.x < leftPadding) leftPadding = middleCurveLabel.x;
			
			//Lowest value
			lowestCurveLabel = LayoutFactory.createLabel("0" + "g", HorizontalAlign.RIGHT, VerticalAlign.TOP, 12, false, axisFontColor);
			lowestCurveLabel.touchable = false;
			lowestCurveLabel.validate();
			lowestCurveLabel.x = -lowestCurveLabel.width - 7;
			COBContainer.addChild(lowestCurveLabel);
			if (lowestCurveLabel.x < leftPadding) leftPadding = lowestCurveLabel.x;
			
			//Absorption Curve 
			var graphWidth:Number = Constants.isPortrait ? Constants.stageWidth - Math.abs(leftPadding) - 40 : Constants.stageHeight - Math.abs(leftPadding) - 40;
			var graphHeight:Number = graphWidth / 3;
			var scaleXFactor:Number = 1 / (totalTimestampDifference / graphWidth);
			var scaleYFactor:Number = graphHeight / totalDataDifference;
			
			middleCurveLabel.y = (graphHeight / 2) - (middleCurveLabel.height / 2);
			lowestCurveLabel.y = graphHeight - lowestCurveLabel.height + (lowestCurveLabel.height / 4.5);
			
			COBLineCurve = new SpikeLine();
			COBLineCurve.touchable = false;
			COBLineCurve.lineStyle(1.5, uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_CARBS_MARKER_COLOR)));
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
					COBLineCurve.moveTo(dataX, dataY);
				else
				{
					COBLineCurve.lineTo(dataX, dataY);
					COBLineCurve.moveTo(dataX, dataY);
				}
				
				previousXCoordinate = dataX;
			}
			
			COBContainer.addChild(COBLineCurve);
			
			//Draw Axis
			yAxisLine = GraphLayoutFactory.createVerticalLine(graphHeight, 1.5, lineColor);
			yAxisLine.touchable = false;
			COBContainer.addChild(yAxisLine);
			
			xAxisLine = GraphLayoutFactory.createHorizontalLine(graphWidth, 1.5, lineColor);
			xAxisLine.touchable = false;
			xAxisLine.y = yAxisLine.y + yAxisLine.height;
			COBContainer.addChild(xAxisLine);
			
			//Draw X Labels
			var dateFormat:String = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_DATE_FORMAT);
			
			//First Timestamo
			var firstDate:Date = new Date(firstTreatmentTimestamp);
			var timeFormatted:String = "";
			if (dateFormat.slice(0,2) == "24")
				timeFormatted = TimeSpan.formatHoursMinutes(firstDate.getHours(), firstDate.getMinutes(), TimeSpan.TIME_FORMAT_24H);
			else
				timeFormatted = TimeSpan.formatHoursMinutes(firstDate.getHours(), firstDate.getMinutes(), TimeSpan.TIME_FORMAT_12H);
			
			firstCurveLabel = LayoutFactory.createLabel(timeFormatted, HorizontalAlign.LEFT, VerticalAlign.TOP, 12, false, axisFontColor);
			firstCurveLabel.touchable = false;
			firstCurveLabel.validate();
			firstCurveLabel.x = 0;
			firstCurveLabel.y = xAxisLine.y + xAxisLine.height + 4;
			COBContainer.addChild(firstCurveLabel);
			var firstLabelBounds:Rectangle = firstCurveLabel.bounds;
			
			//Now
			var now:Number = new Date().valueOf();
			
			nowCurveLabel = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('chartscreen','now').toUpperCase(), HorizontalAlign.LEFT, VerticalAlign.TOP, 12, false, axisFontColor);
			nowCurveLabel.touchable = false;
			nowCurveLabel.validate();
			nowCurveLabel.x = ((now - firstTreatmentTimestamp) * scaleXFactor) - (nowCurveLabel.width / 2);
			nowCurveLabel.y = xAxisLine.y + xAxisLine.height + 4;
			COBContainer.addChild(nowCurveLabel);
			
			nowCOBValueLabel = LayoutFactory.createLabel(currentCOB.toFixed(1) + "g", HorizontalAlign.LEFT, VerticalAlign.TOP, 8, false, axisFontColor);
			nowCOBValueLabel.touchable = false;
			nowCOBValueLabel.validate();
			nowCOBValueLabel.x = ((now - firstTreatmentTimestamp) * scaleXFactor) - (nowCOBValueLabel.width / 2);
			nowCOBValueLabel.y = 0 - nowCOBValueLabel.height - 3;
			COBContainer.addChild(nowCOBValueLabel);
			
			nowCurveMarker = GraphLayoutFactory.createVerticalDashedLine(graphHeight, 2, 1, 1, lineColor);
			nowCurveMarker.touchable = false;
			nowCurveMarker.x = ((now - firstTreatmentTimestamp) * scaleXFactor);
			nowCurveMarker.y = 0;
			COBContainer.addChild(nowCurveMarker);
			
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
			
			lastCurveLabel = LayoutFactory.createLabel(lastTimeFormatted, HorizontalAlign.LEFT, VerticalAlign.TOP, 12, false, axisFontColor);
			lastCurveLabel.touchable = false;
			lastCurveLabel.validate();
			lastCurveLabel.x = xAxisLine.width - lastCurveLabel.width;
			lastCurveLabel.y = xAxisLine.y + xAxisLine.height + 4;
			COBContainer.addChild(lastCurveLabel);
			
			if (nowCurveLabel != null)
			{
				var latestLabelBounds:Rectangle = lastCurveLabel.bounds;
				if (latestLabelBounds.intersects(nowLabelBounds))
					nowCurveLabel.removeFromParent(true);
			}
			
			//Dispose unneded data
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
			
			//Graph Legends
			cobAxisLegend = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('chartscreen','cob_curve_chart_legend_label'), HorizontalAlign.CENTER, VerticalAlign.TOP, 8, false, axisFontColor);
			cobAxisLegend.wordWrap = true;
			cobAxisLegend.paddingTop = -5;
			cobAxisLegend.paddingBottom += 18;
			
			//Add Objects to Display List
			mainContainer.addChild(cobGraphTitle);
			mainContainer.addChild(cobAxisLegend);
			mainContainer.addChild(COBContainer);
			
			//Final Layout Adjustments
			cobGraphTitle.width = graphWidth + Math.abs(leftPadding);
			cobAxisLegend.width = graphWidth + Math.abs(leftPadding);
			
			paddingLeft = leftPadding;
			
			mainContainer.validate();
			COBContainer.x += Math.abs(leftPadding);
		}
		
		private function plotOpenAPSCOB():void
		{
			//Container properties
			mainContainer = LayoutFactory.createLayoutGroup("vertical", HorizontalAlign.LEFT, VerticalAlign.TOP, 10);
			mainContainer.touchable = false;
			addChild(mainContainer);
			
			horizontalScrollPolicy = ScrollPolicy.OFF;
			scrollBarDisplayMode = ScrollBarDisplayMode.FIXED_FLOAT;
			verticalScrollBarProperties.paddingLeft = 10;
			layout = new VerticalLayout();
			
			COBContainer = new Sprite();
			
			//Title
			cobGraphTitle = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('chartscreen','cob_curve_title_label'), HorizontalAlign.CENTER, VerticalAlign.TOP, 14, true);
			
			//Properties
			var axisFontColor:uint = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_AXIS_FONT_COLOR));
			var lineColor:uint = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_AXIS_COLOR));
			
			//Data
			var initialCOB:Object = TreatmentsManager.getTotalCOB(new Date().valueOf());
			var currentCOB:Number = initialCOB.cob;
			
			//Data points
			var totalTreatmentsData:Number = initialCOB.carbs;
			var firstTreatmentTimestamp:Number = initialCOB.firstCarbTime;
			var dataPoints:Array = [];
			var pointInTime:Number = firstTreatmentTimestamp;
			var pointInTimeBgReadingID:Number = Number.NaN;
			
			for (var j:int = ModelLocator.bgReadings.length - 1 ; j >= 0; j--)
			{
				var bgReading:BgReading = ModelLocator.bgReadings[j];
				if(bgReading != null && bgReading._timestamp <= pointInTime)
				{
					pointInTimeBgReadingID = j;
					break;
				}
			}
			
			var dataPoint:Number = TreatmentsManager.getTotalCOB(pointInTime).cob;
			dataPoints.push( { timestamp: pointInTime, dataPoint: dataPoint } );
			
			var maxReadingID:uint = ModelLocator.bgReadings.length - 1;
			while (pointInTimeBgReadingID < maxReadingID)
			{
				pointInTimeBgReadingID += 1;
					
				var cobReading:BgReading = ModelLocator.bgReadings[pointInTimeBgReadingID];
				if (cobReading == null)
				{
					continue;
				}
					
				pointInTime = cobReading._timestamp;
					
				dataPoint = TreatmentsManager.getTotalCOB(pointInTime).cob;
				dataPoints.push( { timestamp: pointInTime, dataPoint: dataPoint } );
					
				if (pointInTimeBgReadingID >= maxReadingID)
					break;
			}
			
			//Calculators
			var firstTimestamp:Number = dataPoints[0].timestamp;
			var lastTimestamp:Number = dataPoints[dataPoints.length - 1].timestamp;
			var totalTimestampDifference:Number = lastTimestamp - firstTimestamp;
			var sortedData:Array = dataPoints.concat();
			sortedData.sortOn(["dataPoint"], Array.NUMERIC);
			var highestDataPoint:Number = sortedData[sortedData.length -1].dataPoint;
			var lowestDataPoint:Number = 0;
			var totalDataDifference:Number = highestDataPoint - lowestDataPoint;
			
			//YAXIS LABELS
			//Highest value
			highestCurveLabel = LayoutFactory.createLabel(String(highestDataPoint) + "g", HorizontalAlign.RIGHT, VerticalAlign.TOP, 12, false, axisFontColor);
			highestCurveLabel.touchable = false;
			highestCurveLabel.validate();
			highestCurveLabel.x = -highestCurveLabel.width - 7;
			highestCurveLabel.y = -highestCurveLabel.height / 4.5;
			COBContainer.addChild(highestCurveLabel);
			if (highestCurveLabel.x < leftPadding) leftPadding = highestCurveLabel.x;
			
			//Middle value
			var middleValue:Number = Math.round((highestDataPoint / 2) * 100) / 100;
			middleCurveLabel = LayoutFactory.createLabel(String(middleValue) + "g", HorizontalAlign.RIGHT, VerticalAlign.TOP, 12, false, axisFontColor);
			middleCurveLabel.touchable = false;
			middleCurveLabel.validate();
			middleCurveLabel.x = -middleCurveLabel.width - 7;
			COBContainer.addChild(middleCurveLabel);
			if (middleCurveLabel.x < leftPadding) leftPadding = middleCurveLabel.x;
			
			//Lowest value
			lowestCurveLabel = LayoutFactory.createLabel("0" + "g", HorizontalAlign.RIGHT, VerticalAlign.TOP, 12, false, axisFontColor);
			lowestCurveLabel.touchable = false;
			lowestCurveLabel.validate();
			lowestCurveLabel.x = -lowestCurveLabel.width - 7;
			COBContainer.addChild(lowestCurveLabel);
			if (lowestCurveLabel.x < leftPadding) leftPadding = lowestCurveLabel.x;
			
			//Absorption Curve 
			var graphWidth:Number = Constants.isPortrait ? Constants.stageWidth - Math.abs(leftPadding) - 40 : Constants.stageHeight - Math.abs(leftPadding) - 40;
			var graphHeight:Number = graphWidth / 3;
			var scaleXFactor:Number = 1 / (totalTimestampDifference / graphWidth);
			var scaleYFactor:Number = graphHeight / totalDataDifference;
			
			middleCurveLabel.y = (graphHeight / 2) - (middleCurveLabel.height / 2);
			lowestCurveLabel.y = graphHeight - lowestCurveLabel.height + (lowestCurveLabel.height / 4.5);
			
			COBLineCurve = new SpikeLine();
			COBLineCurve.touchable = false;
			COBLineCurve.lineStyle(1.5, uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_CARBS_MARKER_COLOR)));
			var previousXCoordinate:Number = 0;
			var dataX:Number = 0;
			var dataY:Number = 0;
			
			var dataLength:int = dataPoints.length;
			for(var i:int = 0; i < dataLength; i++)
			{
				var currentDataPointValue:Number = dataPoints[i].dataPoint;
				
				//Define data point x position
				if(i==0) dataX = 0;
				else dataX = (Number(dataPoints[i].timestamp) - Number(dataPoints[i-1].timestamp)) * scaleXFactor;
				
				dataX = previousXCoordinate + dataX;
				
				//Define glucose marker y position
				dataY = graphHeight - ((currentDataPointValue - lowestDataPoint) * scaleYFactor);
				
				if (i == 0)
					COBLineCurve.moveTo(dataX, dataY);
				else
				{
					COBLineCurve.lineTo(dataX, dataY);
					COBLineCurve.moveTo(dataX, dataY);
				}
				
				previousXCoordinate = dataX;
			}
			
			COBContainer.addChild(COBLineCurve);
			
			//Draw Axis
			yAxisLine = GraphLayoutFactory.createVerticalLine(graphHeight, 1.5, lineColor);
			yAxisLine.touchable = false;
			COBContainer.addChild(yAxisLine);
			
			xAxisLine = GraphLayoutFactory.createHorizontalLine(graphWidth, 1.5, lineColor);
			xAxisLine.touchable = false;
			xAxisLine.y = yAxisLine.y + yAxisLine.height;
			COBContainer.addChild(xAxisLine);
			
			//Draw X Labels
			var dateFormat:String = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_DATE_FORMAT);
			
			//First Timestamo
			var firstDate:Date = new Date(firstTreatmentTimestamp);
			var timeFormatted:String = "";
			if (dateFormat.slice(0,2) == "24")
				timeFormatted = TimeSpan.formatHoursMinutes(firstDate.getHours(), firstDate.getMinutes(), TimeSpan.TIME_FORMAT_24H);
			else
				timeFormatted = TimeSpan.formatHoursMinutes(firstDate.getHours(), firstDate.getMinutes(), TimeSpan.TIME_FORMAT_12H);
			
			firstCurveLabel = LayoutFactory.createLabel(timeFormatted, HorizontalAlign.LEFT, VerticalAlign.TOP, 12, false, axisFontColor);
			firstCurveLabel.touchable = false;
			firstCurveLabel.validate();
			firstCurveLabel.x = 0;
			firstCurveLabel.y = xAxisLine.y + xAxisLine.height + 4;
			COBContainer.addChild(firstCurveLabel);
			var firstLabelBounds:Rectangle = firstCurveLabel.bounds;
			
			//Last timestamp
			var lastDate:Date = new Date(lastTimestamp);
			var lastTimeFormatted:String = "";
			if (dateFormat.slice(0,2) == "24")
				lastTimeFormatted = TimeSpan.formatHoursMinutes(lastDate.getHours(), lastDate.getMinutes(), TimeSpan.TIME_FORMAT_24H);
			else
				lastTimeFormatted = TimeSpan.formatHoursMinutes(lastDate.getHours(), lastDate.getMinutes(), TimeSpan.TIME_FORMAT_12H);
			
			lastCurveLabel = LayoutFactory.createLabel(lastTimeFormatted, HorizontalAlign.LEFT, VerticalAlign.TOP, 12, false, axisFontColor);
			lastCurveLabel.touchable = false;
			lastCurveLabel.validate();
			lastCurveLabel.x = xAxisLine.width - lastCurveLabel.width;
			lastCurveLabel.y = xAxisLine.y + xAxisLine.height + 4;
			COBContainer.addChild(lastCurveLabel);
			
			//Draw now
			nowCurveMarker = GraphLayoutFactory.createVerticalDashedLine(graphHeight, 2, 1, 1, lineColor);
			nowCurveMarker.touchable = false;
			nowCurveMarker.x = dataX - (nowCurveMarker.width / 2);
			nowCurveMarker.y = 1;
			COBContainer.addChild(nowCurveMarker);
			
			nowCOBValueLabel = LayoutFactory.createLabel(currentCOB.toFixed(1) + "g" + " " + "(" +  Number((currentCOB * 100) / highestDataPoint).toFixed(1) +"%)", HorizontalAlign.LEFT, VerticalAlign.TOP, 8, false, axisFontColor);
			nowCOBValueLabel.touchable = false;
			nowCOBValueLabel.validate();
			nowCOBValueLabel.x = dataX - nowCOBValueLabel.width;
			nowCOBValueLabel.y = 0 - nowCOBValueLabel.height - 2;
			COBContainer.addChild(nowCOBValueLabel);
			
			var elapsedTime:String = TimeSpan.formatHoursMinutesFromMinutes((lastTimestamp - firstTreatmentTimestamp) / TimeSpan.TIME_1_MINUTE, false);
			nowCurveLabel = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('chartscreen','elapsed_time_label') + ": " + elapsedTime, HorizontalAlign.LEFT, VerticalAlign.TOP, 12, false, axisFontColor);
			nowCurveLabel.touchable = false;
			nowCurveLabel.validate();
			nowCurveLabel.x = (dataX / 2) - (nowCurveLabel.width / 2);
			nowCurveLabel.y = xAxisLine.y + xAxisLine.height + 4;
			COBContainer.addChild(nowCurveLabel);
			
			//Dispose unneded data
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
			
			//Graph Legends
			cobAxisLegend = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('chartscreen','cob_curve_chart_legend_label'), HorizontalAlign.CENTER, VerticalAlign.TOP, 8, false, axisFontColor);
			cobAxisLegend.wordWrap = true;
			cobAxisLegend.paddingTop = -5;
			cobAxisLegend.paddingBottom += 18;
			
			oref0ExplanationLegend = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('chartscreen','oref0_algorithm_cob_curve_explanation'), HorizontalAlign.JUSTIFY, VerticalAlign.TOP, 8, false, axisFontColor);
			oref0ExplanationLegend.wordWrap = true;
			
			//Add Objects to Display List
			mainContainer.addChild(cobGraphTitle);
			mainContainer.addChild(cobAxisLegend);
			mainContainer.addChild(COBContainer);
			mainContainer.addChild(oref0ExplanationLegend);
			
			//Final Layout Adjustments
			cobGraphTitle.width = graphWidth + Math.abs(leftPadding);
			cobAxisLegend.width = graphWidth + Math.abs(leftPadding);
			oref0ExplanationLegend.width = graphWidth + Math.abs(leftPadding);
			
			paddingLeft = leftPadding;
			
			mainContainer.validate();
			COBContainer.x += Math.abs(leftPadding);
		}
		
		override public function dispose():void
		{
			if (cobAxisLegend != null)
			{
				cobAxisLegend.removeFromParent();
				cobAxisLegend.dispose();
				cobAxisLegend = null;
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
			
			if (nowCOBValueLabel != null)
			{
				nowCOBValueLabel.removeFromParent();
				nowCOBValueLabel.dispose();
				nowCOBValueLabel = null;
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
			
			if (xAxisLine != null)
			{
				xAxisLine.removeFromParent();
				xAxisLine.dispose();
				xAxisLine = null;
			}
			
			if (yAxisLine != null)
			{
				yAxisLine.removeFromParent();
				yAxisLine.dispose();
				yAxisLine = null;
			}
			
			if (COBLineCurve != null)
			{
				COBLineCurve.removeFromParent();
				COBLineCurve.dispose();
				COBLineCurve = null;
			}
			
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
			
			if (oref0ExplanationLegend != null)
			{
				oref0ExplanationLegend.removeFromParent();
				oref0ExplanationLegend.dispose();
				oref0ExplanationLegend = null;
			}
			
			if (cobGraphTitle != null)
			{
				cobGraphTitle.removeFromParent();
				cobGraphTitle.dispose();
				cobGraphTitle = null;
			}
			
			if (COBContainer != null)
			{
				COBContainer.removeFromParent();
				COBContainer.dispose();
				COBContainer = null;
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