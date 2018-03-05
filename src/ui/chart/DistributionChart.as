package ui.chart
{	
	import com.freshplanet.ane.AirBackgroundFetch.BackgroundFetch;
	
	import flash.desktop.NativeApplication;
	import flash.desktop.SystemIdleMode;
	import flash.system.System;
	import flash.utils.getTimer;
	
	import database.BgReading;
	import database.CommonSettings;
	
	import model.ModelLocator;
	
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.display.graphics.NGon;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	
	import utils.Constants;
	
	[ResourceBundle("chartscreen")]
	
	public class DistributionChart extends Sprite
	{
		//Constants
		private static const TIME_24H:int = 24 * 60 * 60 * 1000;
		private static const TIME_30SEC:int = 30 * 1000;
		
		//Variables and Objects
		private var nGons:Array;
		private var _dataSource:Array;
		private var pieRadius:Number;
		private var highTreshold:Number;
		private var lowTreshold:Number;
		private var averageGlucose:Number;
		private var A1C:Number;
		private var pieTimer:Number;
		
		//Display Variables
		private var numSides:int = 200;
		private var lowColor:uint = 0xff0000;//red
		private var inRangeColor:uint = 0x00ff00;//green
		private var highColor:uint = 0xffff00;//yellow
		private var dummyColor:uint = 0xEEEEEE;
		private var fontColor:uint = 0xEEEEEE;
		private var lowOutput:String;
		private var highOutput:String;
		private var inRangeOutput:String;
		private var readingsOutput:String;
		private var avgGlucoseOutput:String;
		private var A1COutput:String;
		private var glucoseUnit:String
		private var dummyModeActive:Boolean = false;
		private var pieSize:Number;
		
		//Display Objects
		private var pieContainer:Sprite;
		private var statsContainer:Sprite;
		private var pieGraphicContainer:Sprite;
		private var lowSection:PieDistributionSection;
		private var inRangeSection:PieDistributionSection;
		private var highSection:PieDistributionSection;
		private var avgGlucoseSection:PieDistributionSection;
		private var estA1CSection:PieDistributionSection;
		private var numReadingsSection:PieDistributionSection;
		private var piePadding:int = 4;
		
		[ResourceBundle("globaltranslations")]
		
		public function DistributionChart(pieSize:Number, dataSource:Array)
		{
			this.pieSize = pieSize;
			this.pieRadius = pieSize - piePadding;
			this._dataSource = dataSource;
			
			setupInitialState();
			setupProperties();
			createStats();
			drawChart();
		}
		
		/**
		 * Functionality
		 */
		private function setupInitialState():void
		{
			//Set Glucose Unit
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true") 
				glucoseUnit = "mg/dL";
			else
				glucoseUnit = "mmol/L";
			
			//Set Thersholds
			lowTreshold = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_LOW_MARK));;
			highTreshold = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_HIGH_MARK));
			
			//Set Colors
			lowColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PIE_CHART_LOW_COLOR));
			inRangeColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PIE_CHART_IN_RANGE_COLOR));
			highColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PIE_CHART_HIGH_COLOR));
			fontColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_PIE_CHART_FONT_COLOR));
			
			//Set Strings
			lowOutput = ModelLocator.resourceManagerInstance.getString('chartscreen','low_title');
			highOutput = ModelLocator.resourceManagerInstance.getString('chartscreen','high_title');
			inRangeOutput = ModelLocator.resourceManagerInstance.getString('chartscreen','in_range_title');
			readingsOutput = ModelLocator.resourceManagerInstance.getString('chartscreen','readings_title');
			avgGlucoseOutput = ModelLocator.resourceManagerInstance.getString('chartscreen','average_glucose_title');
			A1COutput = ModelLocator.resourceManagerInstance.getString('chartscreen','a1c_title');
		}
		
		private function setupProperties():void
		{
			/* Instantiate Objects */
			nGons = [];
			pieContainer = new Sprite();
			pieContainer.x = piePadding * 2;
			pieContainer.y = piePadding;
			pieContainer.addEventListener(TouchEvent.TOUCH, onPieTouch);
			addChild(pieContainer);
			statsContainer = new Sprite();
			addChild(statsContainer);
			
			/* Activate Dummy Mode if there's no bgreadings in data source */
			if (_dataSource == null || _dataSource.length == 0)
				dummyModeActive = true;
		}
		
		private function createStats():void
		{
			statsContainer.x = (2 * pieSize) + 10;
			
			var totalAvailableWidth:Number = Constants.stageWidth - statsContainer.x - 20;
			var sectionsGap:int = 1;
			var sectionWidth:Number = (totalAvailableWidth - (2 * sectionsGap)) / 3;
			var sectionHeight:Number = pieSize - (sectionsGap/2);
			var sectionColor:uint = 0x282a32; 
			
			/* PIE BACKGROUND */
			var pieBackground:Quad = new Quad((pieSize * 2) + (10 - sectionsGap), pieSize * 2, sectionColor);
			addChildAt(pieBackground, 0);
			
			/* LOW */
			var lowThresholdValue:Number = lowTreshold;
			if(glucoseUnit != "mg/dL")
				lowThresholdValue = Math.round(((BgReading.mgdlToMmol((lowThresholdValue))) * 10)) / 10;
			
			var lowThresholdOutput:String
			if (glucoseUnit == "mg/dL")
				lowThresholdOutput = String(Math.round(lowThresholdValue));
			else
			{
				if ( lowThresholdValue % 1 == 0)
					lowThresholdOutput = String(lowThresholdValue) + ".0";
				else
					lowThresholdOutput = String(lowThresholdValue);
			}
			
			lowSection = new PieDistributionSection(sectionWidth, sectionHeight, sectionColor, fontColor, lowColor);
			lowSection.title.text = lowOutput + " (<=" + lowThresholdOutput + ")";
			statsContainer.addChild(lowSection);
			
			/* IN RANGE */
			inRangeSection = new PieDistributionSection(sectionWidth, sectionHeight, sectionColor, fontColor, inRangeColor);
			inRangeSection.x = lowSection.x + lowSection.width + sectionsGap;
			inRangeSection.title.text = inRangeOutput;
			statsContainer.addChild(inRangeSection);
			
			/* HIGH */
			var highThresholdValue:Number = highTreshold;
			if(glucoseUnit != "mg/dL")
				highThresholdValue = Math.round(((BgReading.mgdlToMmol((highThresholdValue))) * 10)) / 10;
			
			var highThresholdOutput:String
			if (glucoseUnit == "mg/dL")
				highThresholdOutput = String(Math.round(highThresholdValue));
			else
			{
				if ( highThresholdValue % 1 == 0)
					highThresholdOutput = String(highThresholdValue) + ".0";
				else
					highThresholdOutput = String(highThresholdValue);
			}
			highSection = new PieDistributionSection(sectionWidth, sectionHeight, sectionColor, fontColor, highColor);
			highSection.x = inRangeSection.x + inRangeSection.width + sectionsGap;
			highSection.title.text = highOutput + " (>=" + highThresholdOutput + ")";;
			statsContainer.addChild(highSection);
			
			/* AVG GLUCOSE */
			avgGlucoseSection = new PieDistributionSection(sectionWidth, sectionHeight, sectionColor, fontColor);
			avgGlucoseSection.y = lowSection.y + sectionHeight + sectionsGap;
			avgGlucoseSection.title.text = avgGlucoseOutput;
			statsContainer.addChild(avgGlucoseSection);
			
			/* A1C */
			estA1CSection = new PieDistributionSection(sectionWidth, sectionHeight, sectionColor, fontColor);
			estA1CSection.x = avgGlucoseSection.x + avgGlucoseSection.width + sectionsGap;;
			estA1CSection.y = avgGlucoseSection.y;
			estA1CSection.title.text = A1COutput;
			statsContainer.addChild(estA1CSection);
			
			/* NUM READINGS */
			numReadingsSection = new PieDistributionSection(sectionWidth, sectionHeight, sectionColor, fontColor);
			numReadingsSection.x = estA1CSection.x + estA1CSection.width + sectionsGap;;
			numReadingsSection.y = avgGlucoseSection.y;
			numReadingsSection.title.text = readingsOutput;
			statsContainer.addChild(numReadingsSection);
		}
		
		public function drawChart():Boolean
		{	
			if (_dataSource != null && _dataSource.length > 0)
				dummyModeActive = false;
			
			if (!BackgroundFetch.appIsInForeground())
				return false;
			
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
			var realReadingsNumber:int = 0;
			var totalGlucose:Number = 0;
			
			/**
			 * GLUCOSE DISTRIBUTION CALCULATION
			 */
			var glucoseValue:Number;
			var i:int;
			var nowTimestamp:Number = (new Date()).valueOf();
			for (i = 0; i < dataLength; i++) 
			{
				if (nowTimestamp - _dataSource[i].timestamp > TIME_24H - TIME_30SEC)
					continue;
				
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
				
				realReadingsNumber++;
			}
			
			//Glucose Distribution Percentages
			percentageHigh = (high * 100) / dataLength;
			percentageHighRounded = (( percentageHigh * 10 + 0.5)  >> 0) / 10;
			
			percentageInRange = (inRange * 100) / dataLength;
			percentageInRangeRounded = (( percentageInRange * 10 + 0.5)  >> 0) / 10;
			
			var preLow:Number = Math.round((low * 100) / dataLength) * 10 / 10;
			if ( preLow != 0 && !isNaN(preLow))
			{
				percentageLow = 100 - percentageInRange - percentageHigh;
				percentageLowRounded = Math.round ((100 - percentageInRangeRounded - percentageHighRounded) * 10) / 10;
			}
			else
			{
				percentageLow = 0;
				percentageLowRounded = 0;
			}
			
			//Angles
			highAngle = (percentageHigh * 360) / 100;
			inRangeAngle = (percentageInRange * 360) / 100;
			lowAngle = (percentageLow * 360) / 100;
			
			/**
			 * GRAPH DRAWING
			 */
			
			if (pieGraphicContainer != null)
				pieContainer.removeChild(pieGraphicContainer);
			
			pieGraphicContainer = new Sprite();
			
			//LOW PORTION
			if (!dummyModeActive)
			{
				var lowNGon:NGon = new NGon(pieRadius, numSides, 0, 0, lowAngle);
				lowNGon.color = lowColor;
				lowNGon.x = lowNGon.y = pieRadius;
				nGons.push(lowNGon);
				pieGraphicContainer.addChild(lowNGon);
			}
			//Legend
			lowSection.message.text = !dummyModeActive ? percentageLowRounded + "%" : ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available');
				
			
			//IN RANGE PORTION
			//Graphics
			if (!dummyModeActive)
			{
				var inRangeNGon:NGon = new NGon(pieRadius, numSides, 0, lowAngle, lowAngle + inRangeAngle);
				inRangeNGon.color = inRangeColor;
				inRangeNGon.x = inRangeNGon.y = pieRadius;
				nGons.push(inRangeNGon);
				pieGraphicContainer.addChild(inRangeNGon);
			}
			//Legend
			inRangeSection.message.text = !dummyModeActive ? percentageInRangeRounded + "%" : ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available');
			
			//HIGH PORTION
			//Graphics
			if (!dummyModeActive)
			{
				var highNGon:NGon = new NGon(pieRadius, numSides, 0, lowAngle + inRangeAngle, lowAngle + inRangeAngle + highAngle);
				highNGon.color = highColor;
				highNGon.x = highNGon.y = pieRadius;
				nGons.push(highNGon);
				pieGraphicContainer.addChild(highNGon);
			}
			//Legend
			highSection.message.text = !dummyModeActive ? percentageHighRounded + "%" : ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available');
			
			//DUMMY NGON
			if (dummyModeActive)
			{
				var innerNGon:NGon = new NGon(pieRadius, numSides, 0, 0, 360);
				innerNGon.color = lowColor;
				innerNGon.x = innerNGon.y = pieRadius;
				nGons.push(innerNGon);
				pieGraphicContainer.addChild(innerNGon);
				
				var middleNGon:NGon = new NGon(pieRadius, numSides, pieRadius/3, 0, 360);
				middleNGon.color = inRangeColor;
				middleNGon.x = middleNGon.y = pieRadius;
				nGons.push(middleNGon);
				pieGraphicContainer.addChild(middleNGon);
				
				var outterNGon:NGon = new NGon(pieRadius, numSides, (pieRadius/3) * 2, 0, 360);
				outterNGon.color = highColor;
				outterNGon.x = outterNGon.y = pieRadius;
				nGons.push(outterNGon);
				pieGraphicContainer.addChild(outterNGon);
			}
			
			/* Create Pie Texture & Image */
			pieContainer.addChild(pieGraphicContainer);
			
			//Calculate Average Glucose & A1C
			averageGlucose = (( (totalGlucose / dataLength) * 10 + 0.5)  >> 0) / 10;
			var averageGlucoseValue:Number = averageGlucose;
			if (glucoseUnit != "mg/dL")
				averageGlucoseValue = Math.round(((BgReading.mgdlToMmol((averageGlucoseValue))) * 10)) / 10;
			
			var averageGlucoseValueOutput:String
			if (glucoseUnit == "mg/dL")
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
			var percentageReadings:Number = ((((realReadingsNumber * 100) / 288) * 10 + 0.5)  >> 0) / 10;
			
			//Populate Stats
			numReadingsSection.message.text = !dummyModeActive ? realReadingsNumber + " (" + percentageReadings + "%)" : ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available');
			avgGlucoseSection.message.text = !dummyModeActive ? averageGlucoseValueOutput + " " + glucoseUnit : ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available');
			estA1CSection.message.text = !dummyModeActive ? A1C + "%" : ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available');
			
			return true;
		}
		
		/**
		 * Event Listeners
		 */
		private function onPieTouch (e:TouchEvent):void
		{
			var touch:Touch = e.getTouch(stage);
			if(touch != null && touch.phase == TouchPhase.BEGAN)
			{
				pieTimer = getTimer();
				addEventListener(Event.ENTER_FRAME, onPieHold);
			}
			
			if(touch != null && touch.phase == TouchPhase.ENDED)
			{
				pieTimer = Number.NaN;
				removeEventListener(Event.ENTER_FRAME, onPieHold);
			}
		}
		
		private function onPieHold(e:Event):void
		{
			if (isNaN(pieTimer))
				return;
			
			if (getTimer() - pieTimer > 1000)
			{
				pieTimer = Number.NaN;
				removeEventListener(Event.ENTER_FRAME, onPieHold);
				
				if (!Constants.noLockEnabled)
				{
					Constants.noLockEnabled = true;
					
					//Activate Keep Awake
					NativeApplication.nativeApplication.systemIdleMode = SystemIdleMode.KEEP_AWAKE;
				}
				else if (Constants.noLockEnabled)
				{
					Constants.noLockEnabled = false;
					
					//Deactivate Keep Awake
					NativeApplication.nativeApplication.systemIdleMode = SystemIdleMode.NORMAL;
				}
				
				//Vibrate Device
				BackgroundFetch.vibrate();
			}
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{	
			/* Dispose Display Objects */
			
			if (lowSection != null)
			{
				statsContainer.removeChild(lowSection);
				lowSection.dispose();
				lowSection = null;
			}
			
			if (inRangeSection != null)
			{
				statsContainer.removeChild(inRangeSection);
				inRangeSection.dispose();
				inRangeSection = null;
			}
			
			if (highSection != null)
			{
				statsContainer.removeChild(highSection);
				highSection.dispose();
				highSection = null;
			}
			
			if (avgGlucoseSection != null)
			{
				statsContainer.removeChild(avgGlucoseSection);
				avgGlucoseSection.dispose();
				avgGlucoseSection = null;
			}
			
			if (estA1CSection != null)
			{
				statsContainer.removeChild(estA1CSection);
				estA1CSection.dispose();
				estA1CSection = null;
			}
			
			if (numReadingsSection != null)
			{
				statsContainer.removeChild(numReadingsSection);
				numReadingsSection.dispose();
				numReadingsSection = null;
			}
			
			if (statsContainer != null)
			{
				removeChild(statsContainer);
				statsContainer.dispose();
				statsContainer = null;
			}
			
			if (pieContainer != null)
			{
				removeChild(pieContainer);
				pieContainer.dispose();
				pieContainer = null;
			}
			
			if (pieGraphicContainer != null)
			{
				pieGraphicContainer.dispose();
				pieGraphicContainer = null;
			}
			
			System.pauseForGCIfCollectionImminent(0);
			
			super.dispose();
		}
		
		/**
		 * Getters & Setters
		 */
		public function set dataSource(value:Array):void
		{
			_dataSource = value;
		}
	}
}