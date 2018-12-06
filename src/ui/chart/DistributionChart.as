package ui.chart
{	
	import com.spikeapp.spike.airlibrary.SpikeANE;
	
	import flash.desktop.NativeApplication;
	import flash.desktop.SystemIdleMode;
	import flash.system.System;
	import flash.utils.getTimer;
	
	import database.BgReading;
	import database.CommonSettings;
	
	import feathers.motion.Cover;
	import feathers.motion.Reveal;
	
	import model.ModelLocator;
	
	import starling.animation.Transitions;
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.utils.SystemUtil;
	
	import stats.BasicUserStats;
	import stats.StatsManager;
	
	import ui.AppInterface;
	import ui.screens.Screens;
	import ui.shapes.SpikeNGon;
	
	import utils.Constants;
	import ui.chart.visualcomponents.PieDistributionSection;
	
	[ResourceBundle("chartscreen")]
	
	public class DistributionChart extends Sprite
	{
		//Variables and Objects
		private var nGons:Array;
		private var _dataSource:Array;
		private var pieRadius:Number;
		private var highTreshold:Number;
		private var lowTreshold:Number;
		private var pieTimer:Number;
		private var fromTime:Number = Number.NaN;
		private var untilTime:Number = Number.NaN;
		
		//Display Variables
		private var numSides:int = 150;
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
		private var piePadding:int = 4;
		
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
		private var pieBackground:Quad;
		private var lowNGonSpike:SpikeNGon;
		private var inRangeNGonSpike:SpikeNGon;
		private var highNGonSpike:SpikeNGon;
		private var innerNGonSpike:SpikeNGon;
		private var middleNGonSpike:SpikeNGon;
		private var outterNGonSpike:SpikeNGon;
		private var statsHitArea:Quad;
		
		[ResourceBundle("globaltranslations")]
		
		public function DistributionChart(pieSize:Number, dataSource:Array, fromTime:Number = Number.NaN, untilTime:Number = Number.NaN)
		{
			this.pieSize = pieSize;
			this.pieRadius = pieSize - piePadding;
			this._dataSource = dataSource;
			this.fromTime = fromTime;
			this.untilTime = untilTime;
			
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
			statsContainer.touchable = false;
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
			pieBackground = new Quad((pieSize * 2) + (10 - sectionsGap), pieSize * 2, sectionColor);
			pieBackground.touchable = false;
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
			lowSection.touchable = false;
			lowSection.title.text = lowOutput + " (<=" + lowThresholdOutput + ")";
			statsContainer.addChild(lowSection);
			
			/* IN RANGE */
			inRangeSection = new PieDistributionSection(sectionWidth, sectionHeight, sectionColor, fontColor, inRangeColor);
			inRangeSection.touchable = false;
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
			highSection.touchable = false;
			highSection.x = inRangeSection.x + inRangeSection.width + sectionsGap;
			highSection.title.text = highOutput + " (>=" + highThresholdOutput + ")";;
			statsContainer.addChild(highSection);
			
			/* AVG GLUCOSE */
			avgGlucoseSection = new PieDistributionSection(sectionWidth, sectionHeight, sectionColor, fontColor);
			avgGlucoseSection.touchable = false;
			avgGlucoseSection.y = lowSection.y + sectionHeight + sectionsGap;
			avgGlucoseSection.title.text = avgGlucoseOutput;
			statsContainer.addChild(avgGlucoseSection);
			
			/* A1C */
			estA1CSection = new PieDistributionSection(sectionWidth, sectionHeight, sectionColor, fontColor);
			estA1CSection.touchable = false;
			estA1CSection.x = avgGlucoseSection.x + avgGlucoseSection.width + sectionsGap;;
			estA1CSection.y = avgGlucoseSection.y;
			estA1CSection.title.text = A1COutput;
			statsContainer.addChild(estA1CSection);
			
			/* NUM READINGS */
			numReadingsSection = new PieDistributionSection(sectionWidth, sectionHeight, sectionColor, fontColor);
			numReadingsSection.touchable = false;
			numReadingsSection.x = estA1CSection.x + estA1CSection.width + sectionsGap;;
			numReadingsSection.y = avgGlucoseSection.y;
			numReadingsSection.title.text = readingsOutput;
			statsContainer.addChild(numReadingsSection);
			
			/* STATS HIT AREA */
			statsHitArea = new Quad(statsContainer.width, statsContainer.height, 0xFF0000);
			statsHitArea.x = statsContainer.x;
			statsHitArea.y = statsContainer.y;
			statsHitArea.alpha = 0;
			statsHitArea.addEventListener(TouchEvent.TOUCH, onStatsTouch);
			addChild(statsHitArea);
		}
		
		public function drawChart():Boolean
		{	
			if (_dataSource != null && _dataSource.length > 0)
				dummyModeActive = false;
			
			if (!SystemUtil.isApplicationActive)
				return false;
			
			var userStats:BasicUserStats = StatsManager.getBasicUserStats(fromTime, untilTime);
			
			//If there's no good readings then activate dummy mode.
			if (userStats.numReadingsDay == 0)
				dummyModeActive = true;
			
			//Angles
			var highAngle:Number = (userStats.percentageHigh * 360) / 100;
			var inRangeAngle:Number = (userStats.percentageInRange * 360) / 100;
			var lowAngle:Number = (userStats.percentageLow * 360) / 100;
			
			if (pieGraphicContainer != null)
				pieGraphicContainer.removeFromParent(true);
			
			pieGraphicContainer = new Sprite();
			
			//LOW PORTION
			if (!dummyModeActive)
			{
				if (lowNGonSpike != null) lowNGonSpike.removeFromParent(true);
				lowNGonSpike = new SpikeNGon(pieRadius, numSides, 0, lowAngle, lowColor);
				lowNGonSpike.x = lowNGonSpike.y = pieRadius;
				nGons.push(lowNGonSpike);
				pieGraphicContainer.addChild(lowNGonSpike);
			}
			//Legend
			lowSection.message.text = !dummyModeActive ? userStats.percentageLowRounded + "%" : ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available');
			
			//IN RANGE PORTION
			//Graphics
			if (!dummyModeActive)
			{
				if (inRangeNGonSpike != null) inRangeNGonSpike.removeFromParent(true);
				inRangeNGonSpike = new SpikeNGon(pieRadius, numSides, lowAngle, lowAngle + inRangeAngle, inRangeColor);
				inRangeNGonSpike.x = inRangeNGonSpike.y = pieRadius;
				nGons.push(inRangeNGonSpike);
				pieGraphicContainer.addChild(inRangeNGonSpike);
			}
			//Legend
			inRangeSection.message.text = !dummyModeActive ? userStats.percentageInRangeRounded + "%" : ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available');
			
			//HIGH PORTION
			//Graphics
			if (!dummyModeActive)
			{
				if (highNGonSpike != null) highNGonSpike.removeFromParent(true);
				highNGonSpike = new SpikeNGon(pieRadius, numSides, lowAngle + inRangeAngle, lowAngle + inRangeAngle + highAngle, highColor);
				highNGonSpike.x = highNGonSpike.y = pieRadius;
				nGons.push(highNGonSpike);
				pieGraphicContainer.addChild(highNGonSpike);
			}
			//Legend
			highSection.message.text = !dummyModeActive ? userStats.percentageHighRounded + "%" : ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available');
			
			//DUMMY NGON
			if (dummyModeActive)
			{
				if (outterNGonSpike != null) outterNGonSpike.removeFromParent(true);
				outterNGonSpike = new SpikeNGon(pieRadius, numSides, 0, 360, highColor);
				outterNGonSpike.x = outterNGonSpike.y = pieRadius;
				nGons.push(outterNGonSpike);
				pieGraphicContainer.addChild(outterNGonSpike);
				
				if (middleNGonSpike != null) middleNGonSpike.removeFromParent(true);
				middleNGonSpike = new SpikeNGon((pieRadius / 3) * 2, numSides, 0, 360, inRangeColor);
				middleNGonSpike.x = middleNGonSpike.y = pieRadius;
				nGons.push(middleNGonSpike);
				pieGraphicContainer.addChild(middleNGonSpike);
				
				if (innerNGonSpike != null) innerNGonSpike.removeFromParent(true);
				innerNGonSpike = new SpikeNGon(pieRadius / 3, numSides, 0, 360, lowColor);
				innerNGonSpike.x = innerNGonSpike.y = pieRadius;
				nGons.push(innerNGonSpike);
				pieGraphicContainer.addChild(innerNGonSpike);
			}
			
			//Add pie to display list
			pieContainer.addChild(pieGraphicContainer);
			
			//Average glucose
			var averageGlucoseValueOutput:String
			if (glucoseUnit == "mg/dL")
				averageGlucoseValueOutput = String(userStats.averageGlucose);
			else
			{
				if ( userStats.averageGlucose % 1 == 0)
					averageGlucoseValueOutput = String(userStats.averageGlucose) + ".0";
				else
					averageGlucoseValueOutput = String(userStats.averageGlucose);
			}
			
			//Populate Stats
			numReadingsSection.message.text = !dummyModeActive ? userStats.numReadingsDay + " (" + userStats.captureRate + "%)" : ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available');
			avgGlucoseSection.message.text = !dummyModeActive ? averageGlucoseValueOutput + " " + glucoseUnit : ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available');
			estA1CSection.message.text = !dummyModeActive ? userStats.a1c + (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PIE_CHART_A1C_IFCC_ON) != "true" ? "%" : " mmol/mol") : ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available');
			
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
					
					//Push Fullscreen View
					AppInterface.instance.navigator.pushScreen( Screens.FULLSCREEN_GLUCOSE );
				}
				else if (Constants.noLockEnabled)
				{
					Constants.noLockEnabled = false;
					
					//Deactivate Keep Awake
					NativeApplication.nativeApplication.systemIdleMode = SystemIdleMode.NORMAL;
				}
				
				//Vibrate Device
				SpikeANE.vibrate();
			}
		}
		
		private function onStatsTouch (e:TouchEvent):void
		{
			var touch:Touch = e.getTouch(stage);
			if(touch != null && touch.phase == TouchPhase.BEGAN)
			{
				pieTimer = getTimer();
				addEventListener(Event.ENTER_FRAME, onStatsHold);
			}
			
			if(touch != null && touch.phase == TouchPhase.ENDED)
			{
				pieTimer = Number.NaN;
				removeEventListener(Event.ENTER_FRAME, onStatsHold);
			}
		}
		
		private function onStatsHold(e:Event):void
		{
			if (isNaN(pieTimer))
				return;
			
			if (getTimer() - pieTimer > 1000)
			{
				pieTimer = Number.NaN;
				removeEventListener(Event.ENTER_FRAME, onStatsHold);
				
				//Push Chart Settings Screen
				AppInterface.instance.chartSettingsScreenItem.pushTransition = Cover.createCoverUpTransition(0.6, Transitions.EASE_IN_OUT);
				AppInterface.instance.chartSettingsScreenItem.popTransition = Reveal.createRevealDownTransition(0.6, Transitions.EASE_IN_OUT);
				AppInterface.instance.navigator.pushScreen( Screens.SETTINGS_CHART );
			}
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{	
			//Event Listeners
			removeEventListener(Event.ENTER_FRAME, onPieHold);
			
		
			/* Dispose Display Objects */
			for (var i:int = 0; i < nGons.length; i++) 
			{
				var nGon:SpikeNGon = nGons[i] as SpikeNGon;
				if (nGon != null)
				{
					nGon.removeFromParent();
					nGon.dispose();
					nGon = null;
				}
			}
			nGons.length = 0;
			nGons = null
			
			if (lowNGonSpike != null)
			{
				lowNGonSpike.removeFromParent();
				lowNGonSpike.dispose();
				lowNGonSpike = null;
			}
			
			if (inRangeNGonSpike != null)
			{
				inRangeNGonSpike.removeFromParent();
				inRangeNGonSpike.dispose();
				inRangeNGonSpike = null;
			}
			
			if (highNGonSpike != null)
			{
				highNGonSpike.removeFromParent();
				highNGonSpike.dispose();
				highNGonSpike = null;
			}
			
			if (innerNGonSpike != null)
			{
				innerNGonSpike.removeFromParent();
				innerNGonSpike.dispose();
				innerNGonSpike = null;
			}
			
			if (middleNGonSpike != null)
			{
				middleNGonSpike.removeFromParent();
				middleNGonSpike.dispose();
				middleNGonSpike = null;
			}
			
			if (outterNGonSpike != null)
			{
				outterNGonSpike.removeFromParent();
				outterNGonSpike.dispose();
				outterNGonSpike = null;
			}
			
			if (lowSection != null)
			{
				lowSection.removeFromParent();
				lowSection.dispose();
				lowSection = null;
			}
			
			if (inRangeSection != null)
			{
				inRangeSection.removeFromParent();
				inRangeSection.dispose();
				inRangeSection = null;
			}
			
			if (highSection != null)
			{
				highSection.removeFromParent();
				highSection.dispose();
				highSection = null;
			}
			
			if (avgGlucoseSection != null)
			{
				avgGlucoseSection.removeFromParent();
				avgGlucoseSection.dispose();
				avgGlucoseSection = null;
			}
			
			if (estA1CSection != null)
			{
				estA1CSection.removeFromParent();
				estA1CSection.dispose();
				estA1CSection = null;
			}
			
			if (numReadingsSection != null)
			{
				numReadingsSection.removeFromParent();
				numReadingsSection.dispose();
				numReadingsSection = null;
			}
			
			if (pieBackground != null)
			{
				pieBackground.removeFromParent();
				pieBackground.dispose();
				pieBackground = null;
			}
			
			if (statsContainer != null)
			{
				statsContainer.removeFromParent();
				statsContainer.dispose();
				statsContainer = null;
			}
			
			if (pieContainer != null)
			{
				pieContainer.removeEventListener(TouchEvent.TOUCH, onPieTouch);
				pieContainer.removeFromParent();
				pieContainer.dispose();
				pieContainer = null;
			}
			
			if (pieGraphicContainer != null)
			{
				pieGraphicContainer.removeFromParent();
				pieGraphicContainer.dispose();
				pieGraphicContainer = null;
			}
			
			if (statsHitArea != null)
			{
				statsHitArea.addEventListener(TouchEvent.TOUCH, onStatsTouch);
				statsHitArea.removeFromParent();
				statsHitArea.dispose();
				statsHitArea = null;
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