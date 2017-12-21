package chart
{	
	import databaseclasses.BgReading;
	import databaseclasses.CommonSettings;
	
	import feathers.controls.Label;
	import feathers.controls.LayoutGroup;
	import feathers.events.FeathersEventType;
	import feathers.layout.HorizontalLayout;
	import feathers.layout.VerticalAlign;
	
	import model.ModelLocator;
	
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.display.graphics.NGon;
	import starling.events.Event;
	
	import utils.DeviceInfo;
	
	[ResourceBundle("chartscreen")]
	
	public class PieChart extends Sprite
	{
		//Variables and Objects
		private var nGons:Array;
		private var _dataSource:Array;
		private var pieRadius:Number;
		private var highTreshold:Number;
		private var lowTreshold:Number;
		private var averageGlucose:Number;
		private var A1C:Number;
		
		//Display Variables
		private var numSides:int = 200;
		private var lowColor:uint = 0xff0000;//red
		private var inRangeColor:uint = 0x00ff00;//green
		private var highColor:uint = 0xffff00;//yellow
		private var dummyColor:uint = 0xEEEEEE;
		private var fontColor:uint = 0xEEEEEE;
		private var legendGap:Number;
		private var legendQuadSize:Number;
		private var pieHeight:Number;
		private var lowOutput:String;
		private var highOutput:String;
		private var inRangeOutput:String;
		private var readingsOutput:String;
		private var avgGlucoseOutput:String;
		private var A1COutput:String;
		private var glucoseUnit:String
		private var dummyModeActive:Boolean = false;
		
		//Display Objects
		private var pieContainer:Sprite;
		private var lowLegend:Label;
		private var inRangeLegend:Label;
		private var highLegend:Label;
		private var numberOfReadingsLabel:Label;
		private var averageGlucoseLabel:Label;
		private var A1CLabel:Label;
		private var lowLayoutGroup:LayoutGroup;
		private var inRangeLayoutGroup:LayoutGroup;
		private var highLayoutGroup:LayoutGroup;
		private var legendsContainer:Sprite;
		private var lowQuad:Quad;
		private var inRangeQuad:Quad;
		private var highQuad:Quad;
		
		public function PieChart(pieRadius:Number, dataSource:Array)
		{
			this.pieRadius = pieRadius;
			this._dataSource = dataSource;
			nGons = [];
			
			//Set Glucose Unit
			//Unit
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true") 
				glucoseUnit = "mg/dl";
			else
				glucoseUnit = "mmol/L";
			
			//Set Thersholds
			lowTreshold = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_LOW_MARK));;
			highTreshold = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_HIGH_MARK));
			
			//Set Colors
			lowColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_URGENT_LOW_COLOR));
			inRangeColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_IN_RANGE_COLOR));
			highColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_HIGH_COLOR));
			fontColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_PIE_CHART_FONT_COLOR));
			
			//Set Strings
			lowOutput = ModelLocator.resourceManagerInstance.getString('chartscreen','low_title');
			highOutput = ModelLocator.resourceManagerInstance.getString('chartscreen','high_title');
			inRangeOutput = ModelLocator.resourceManagerInstance.getString('chartscreen','in_range_title');
			readingsOutput = ModelLocator.resourceManagerInstance.getString('chartscreen','readings_title');
			avgGlucoseOutput = ModelLocator.resourceManagerInstance.getString('chartscreen','average_glucose_title');
			A1COutput = ModelLocator.resourceManagerInstance.getString('chartscreen','a1c_title');
			
			/* Activate Dummy Mode if there's no bgreadings in data source */
			if (_dataSource == null || _dataSource.length == 0)
				dummyModeActive = true;
			
			//Create pie container
			pieContainer = new Sprite();
			addChild(pieContainer);
			
			//Create legends container
			legendsContainer = new Sprite();
			addChild(legendsContainer);
			
			//Draw legends
			createLegends();
		}
		
		private function createLegends():void
		{
			/**
			 * LAYOUT CALCULATIONS
			 */
			pieHeight = 2 * pieRadius;
			legendGap = pieHeight / 6;
			if (DeviceInfo.getDeviceType() == DeviceInfo.IPHONE_4_4S)
				legendQuadSize = (pieHeight - (2 * legendGap)) / 3;
			else
				legendQuadSize = (pieHeight - (2 * legendGap)) / 4;
			
			/**
			 * LOW
			 */
			//Layout
			lowLayoutGroup = new LayoutGroup();
			var lowVerticalLayout:HorizontalLayout = new HorizontalLayout();
			lowVerticalLayout.verticalAlign = VerticalAlign.MIDDLE;
			lowLayoutGroup.layout = lowVerticalLayout;
			legendsContainer.addChild(lowLayoutGroup);
			//Quad
			lowQuad = new Quad(legendQuadSize, legendQuadSize, lowColor);
			lowLayoutGroup.addChild(lowQuad);
			//Legend
			lowLegend = GraphLayoutFactory.createPieLegend(fontColor);
			lowLayoutGroup.addChild(lowLegend);
			
			/**
			 * IN RANGE
			 */
			//Layout
			inRangeLayoutGroup = new LayoutGroup();
			var inRangeVerticalLayout:HorizontalLayout = new HorizontalLayout();
			inRangeVerticalLayout.verticalAlign = VerticalAlign.MIDDLE;
			inRangeLayoutGroup.layout = inRangeVerticalLayout;
			legendsContainer.addChild(inRangeLayoutGroup);
			//Quad
			inRangeQuad = new Quad(legendQuadSize, legendQuadSize, inRangeColor);
			inRangeLayoutGroup.addChild(inRangeQuad);
			//Legend
			inRangeLegend = GraphLayoutFactory.createPieLegend(fontColor);
			inRangeLayoutGroup.addChild(inRangeLegend);
			
			/**
			 * HIGH
			 */
			//Layout
			highLayoutGroup = new LayoutGroup();
			var highVerticalLayout:HorizontalLayout = new HorizontalLayout();
			highVerticalLayout.verticalAlign = VerticalAlign.MIDDLE;
			highLayoutGroup.layout = inRangeVerticalLayout;
			legendsContainer.addChild(highLayoutGroup);
			//Quad
			highQuad = new Quad(legendQuadSize, legendQuadSize, highColor);
			highLayoutGroup.addChild(highQuad);
			//Legend
			highLegend = GraphLayoutFactory.createPieLegend(fontColor);
			highLayoutGroup.addChild(highLegend);
			
			/**
			 * STATS
			 */
			//Number of Readings
			numberOfReadingsLabel = GraphLayoutFactory.createPieLegend(fontColor);
			lowLayoutGroup.addChild(numberOfReadingsLabel);
			//Average Blood Glucose
			averageGlucoseLabel = GraphLayoutFactory.createPieLegend(fontColor);
			inRangeLayoutGroup.addChild(averageGlucoseLabel);
			//A1C
			A1CLabel = GraphLayoutFactory.createPieLegend(fontColor);
			highLayoutGroup.addChild(A1CLabel);
			//On Legend Creation
			highLayoutGroup.addEventListener(feathers.events.FeathersEventType.CREATION_COMPLETE, drawChart);
		}
		
		private function drawChart(event:Event = null):void
		{
			/**
			 * VARIABLES
			 */
			var high:int = 0;
			var percentageHigh:Number;
			var percentageHighRounded:Number;
			var highAngle:Number;
			var inRange:int = 0;
			var percentageInRange:Number;
			var percentageInRangeRounded:Number
			var inRangeAngle:Number
			var low:int = 0;
			var percentageLow:Number;
			var percentageLowRounded:Number;
			var lowAngle:Number
			var dataLength:int = _dataSource.length;
			var totalGlucose:Number = 0;
			
			/**
			 * GLUCOSE DISTRIBUTION CALCULATION
			 */
			var glucoseValue:Number;
			var i:int;
			for (i = 0; i < dataLength; i++) 
			{
				glucoseValue = Number(_dataSource[i].calculatedValue);
				if(glucoseValue >= highTreshold)
				{
					high += 1;
				}
				else if (glucoseValue > lowTreshold && glucoseValue < highTreshold)
				{
					inRange += 1;
				}
				else if (glucoseValue <= lowTreshold)
				{
					low += 1;
				}
				totalGlucose += glucoseValue;
			}
			
			//Glucose Distribution Percentages
			percentageHigh = (high * 100) / dataLength;
			percentageHighRounded = (( percentageHigh * 10 + 0.5)  >> 0) / 10;
			percentageInRange = (inRange * 100) / dataLength;
			percentageInRangeRounded = (( percentageInRange * 10 + 0.5)  >> 0) / 10;
			percentageLow = (low * 100) / dataLength;
			percentageLowRounded = (( percentageLow * 10 + 0.5)  >> 0) / 10;
			
			//Angles
			highAngle = (percentageHigh * 360) / 100;
			inRangeAngle = (percentageInRange * 360) / 100;
			lowAngle = (percentageLow * 360) / 100;
			
			/**
			 * GRAPH DRAWING
			 */
			//Remove previous Ngons
			for (i = 0; i < nGons.length; i++) 
			{
				var currentNGon:NGon = nGons[i];
				pieContainer.removeChild(currentNGon);
				currentNGon.dispose();
				currentNGon = null;
			}
			nGons.length = 0;
			
			//LOW PORTION
			//Graphics
			if (!dummyModeActive)
			{
				var lowNGon:NGon = new NGon(pieRadius, numSides, 0, 0, lowAngle);
				lowNGon.color = lowColor;
				lowNGon.x = lowNGon.y = pieRadius;
				nGons.push(lowNGon);
				pieContainer.addChild(lowNGon);
			}
			//Legend
			var lowThresholdValue:Number = lowTreshold;
			if(glucoseUnit != "mg/dl")
				lowThresholdValue = Math.round(((BgReading.mgdlToMmol((lowThresholdValue))) * 10)) / 10;
			
			var lowThresholdOutput:String
			if (glucoseUnit == "mg/dl")
				lowThresholdOutput = String(Math.round(lowThresholdValue));
			else
			{
				if ( lowThresholdValue % 1 == 0)
					lowThresholdOutput = String(lowThresholdValue) + ".0";
				else
					lowThresholdOutput = String(lowThresholdValue);
			}
			lowLegend.text = lowOutput + " (<=" + lowThresholdOutput + "): " + percentageLowRounded + "%";
			
			//IN RANGE PORTION
			//Graphics
			if (!dummyModeActive)
			{
				var inRangeNGon:NGon = new NGon(pieRadius, numSides, 0, lowAngle, lowAngle + inRangeAngle);
				inRangeNGon.color = inRangeColor;
				inRangeNGon.x = inRangeNGon.y = pieRadius;
				nGons.push(inRangeNGon);
				pieContainer.addChild(inRangeNGon);
			}
			//Legend
			inRangeLegend.text = inRangeOutput + ": " + percentageInRangeRounded + "%";
			
			//HIGH PORTION
			//Graphics
			if (!dummyModeActive)
			{
				var highNGon:NGon = new NGon(pieRadius, numSides, 0, lowAngle + inRangeAngle, lowAngle + inRangeAngle + highAngle);
				highNGon.color = highColor;
				highNGon.x = highNGon.y = pieRadius;
				nGons.push(highNGon);
				pieContainer.addChild(highNGon);
			}
			//Legend
			var highThresholdValue:Number = highTreshold;
			if(glucoseUnit != "mg/dl")
				highThresholdValue = Math.round(((BgReading.mgdlToMmol((highThresholdValue))) * 10)) / 10;
			
			var highThresholdOutput:String
			if (glucoseUnit == "mg/dl")
				highThresholdOutput = String(Math.round(highThresholdValue));
			else
			{
				if ( highThresholdValue % 1 == 0)
					highThresholdOutput = String(highThresholdValue) + ".0";
				else
					highThresholdOutput = String(highThresholdValue);
			}
			highLegend.text = highOutput + " (>=" + highThresholdOutput + "): " + percentageHighRounded + "%";
			
			//DUMMY NGON
			if (dummyModeActive)
			{
				var innerNGon:NGon = new NGon(pieRadius, numSides, 0, 0, 360);
				innerNGon.color = lowColor;
				innerNGon.x = innerNGon.y = pieRadius;
				nGons.push(innerNGon);
				pieContainer.addChild(innerNGon);
				
				var middleNGon:NGon = new NGon(pieRadius, numSides, pieRadius/3, 0, 360);
				middleNGon.color = inRangeColor;
				middleNGon.x = middleNGon.y = pieRadius;
				nGons.push(middleNGon);
				pieContainer.addChild(middleNGon);
				
				var outterNGon:NGon = new NGon(pieRadius, numSides, (pieRadius/3) * 2, 0, 360);
				outterNGon.color = highColor;
				outterNGon.x = outterNGon.y = pieRadius;
				nGons.push(outterNGon);
				pieContainer.addChild(outterNGon);
			}
			
			//Calculate Average Glucose & A1C
			averageGlucose = (( (totalGlucose / dataLength) * 10 + 0.5)  >> 0) / 10;
			var averageGlucoseValue:Number = averageGlucose;
			if (glucoseUnit != "mg/dl")
				averageGlucoseValue = Math.round(((BgReading.mgdlToMmol((averageGlucoseValue))) * 10)) / 10;
			
			var averageGlucoseValueOutput:String
			if (glucoseUnit == "mg/dl")
				averageGlucoseValueOutput = String(averageGlucoseValue);
			else
			{
				if ( averageGlucoseValue % 1 == 0)
					averageGlucoseValueOutput = String(averageGlucoseValue) + ".0";
				else
					averageGlucoseValueOutput = String(averageGlucoseValue);
			}
			
			if (!dummyModeActive)
				A1C = (( ((46.7 + averageGlucose) / 28.7) * 10 + 0.5)  >> 0) / 10;
			else
				A1C = 0;
			
			//Calculate readings percentage
			var percentageReadings:Number = (( ((dataLength * 100) / 288) * 10 + 0.5)  >> 0) / 10;
			
			//Populate Stats
			numberOfReadingsLabel.text = readingsOutput + ": " + dataLength + " (" + percentageReadings + "%)";
			averageGlucoseLabel.text = avgGlucoseOutput + ": " + averageGlucoseValueOutput + " " + glucoseUnit;
			A1CLabel.text = A1COutput + ": " + A1C + "%";
			
			//Position Stats
			positionStats();
		}	
		
		public function addGlucose(glucoseValue:Number):void
		{
			//var timestampNow:Number = new Date().valueOf();
			var timestampNow:Number = Number(_dataSource[_dataSource.length - 1].timestamp) + (1000 * 60 * 5); //CHEAT: This is last glucose value plus 5 minutes
			var timestampFirst:Number = Number(_dataSource[0].timestamp);
			var dayInTimestamp:Number = (1000 * 60 * 60 * 24) - (1000 * 60 * 5); //CHEAT: This is 1 day minus 5 minutes
			
			if(timestampNow - timestampFirst > dayInTimestamp)
			{
				//More than 24h of data. Remove first entry
				_dataSource.shift();
			}
			
			//Add new value to dataSource
			_dataSource.push({timestamp: timestampNow, calculatedValue: glucoseValue});
			
			//Redraw chart
			drawChart();
		}
		
		private function positionStats():void
		{
			/**
			 * STATS REPOSITION
			 */
			//Validate/Invalidate Layout groups for proper position calculation
			lowLayoutGroup.invalidate();
			lowLayoutGroup.validate();
			inRangeLayoutGroup.invalidate();
			inRangeLayoutGroup.validate();
			highLayoutGroup.invalidate();
			highLayoutGroup.validate();
			
			//Position Low Group
			lowLayoutGroup.x = (2 * pieRadius) + 5;
			lowLayoutGroup.y = 0;
			lowLegend.x += 5;
			
			//Position In Range Group
			inRangeLayoutGroup.x = (2 * pieRadius) + 5;
			inRangeLayoutGroup.y = lowLayoutGroup.y + lowLayoutGroup.height + legendGap/2;
			inRangeLegend.x += 5;
			
			//Position High Group
			highLayoutGroup.x = (2 * pieRadius) + 5;
			highLayoutGroup.y = inRangeLayoutGroup.y + inRangeLayoutGroup.height + legendGap/2;
			highLegend.x += 5;
			
			//Position Glucose Distribution Labels
			var graphMargin:int = 10;
			var localCoordinate:Number = inRangeLegend.x + inRangeLegend.width + inRangeLayoutGroup.x;
			var globalCoordinate:Number = stage.stageWidth - localCoordinate;
			var incrementX:Number = globalCoordinate - averageGlucoseLabel.width - (1.5*graphMargin);
			averageGlucoseLabel.x += incrementX;
			numberOfReadingsLabel.x = averageGlucoseLabel.x;
			A1CLabel.x = averageGlucoseLabel.x;
			
			//Position labels container
			legendsContainer.y = (pieHeight - ((highLayoutGroup.y + highLayoutGroup.height) - lowLayoutGroup.y)) / 2;
		}
		
		public function set dataSource(value:Array):void
		{
			_dataSource = value;
		}

	}
}