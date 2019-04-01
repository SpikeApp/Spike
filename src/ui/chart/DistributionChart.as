package ui.chart
{	
	import com.spikeapp.spike.airlibrary.SpikeANE;
	
	import flash.desktop.NativeApplication;
	import flash.desktop.SystemIdleMode;
	import flash.geom.Point;
	import flash.system.System;
	import flash.utils.getTimer;
	import flash.utils.setTimeout;
	
	import database.BgReading;
	import database.CGMBlueToothDevice;
	import database.CommonSettings;
	
	import feathers.motion.Cover;
	import feathers.motion.Reveal;
	
	import model.ModelLocator;
	
	import starling.animation.Transitions;
	import starling.animation.Tween;
	import starling.core.Starling;
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.utils.SystemUtil;
	
	import stats.BasicUserStats;
	import stats.StatsManager;
	
	import treatments.ProfileManager;
	
	import ui.AppInterface;
	import ui.chart.helpers.GlucoseFactory;
	import ui.chart.visualcomponents.PieDistributionSection;
	import ui.screens.Screens;
	import ui.shapes.SpikeNGon;
	
	import utils.Constants;
	import utils.GlucoseHelper;
	import utils.TimeSpan;
	
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
		private var _currentPageNumber:Number;
		private var _currentPageName:String;
		public var lastGlucoseDistributionFetch:Number = 0;
		public var pieChartDrawn:Boolean = false;
		
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
		private var stdDeviationOutput:String;
		private var gviOutput:String;
		private var pgsOutput:String;
		private var meanChangeOutput:String;
		private var timeInFluctuation5Output:String;
		private var timeInFluctuation10Output:String;
		private var bolusOutput:String;
		private var carbsOutput:String;
		private var exerciseOutput:String;
		private var glucoseUnit:String
		public var dummyModeActive:Boolean = false;
		private var pieSize:Number;
		private var piePadding:int = 4;
		private var firstPageX:Number;
		private var thirdPageX:Number;
		private var statsWidth:Number;
		private var secondPageX:Number;
		
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
		private var pieLeftSection:Quad;
		private var pieRightSection:Quad;
		private var statsRightSection:Quad;
		private var timeFluctuation5Section:PieDistributionSection;
		private var stDeviationSection:PieDistributionSection;
		private var timeFluctuation10Section:PieDistributionSection;
		private var gviSection:PieDistributionSection;
		private var pgsSection:PieDistributionSection;
		private var meanHourlyChangeSection:PieDistributionSection;
		private var carbsSection:PieDistributionSection;
		private var bolusSection:PieDistributionSection;
		private var exerciseSection:PieDistributionSection;
		private var basalAmountSection:PieDistributionSection;
		private var basalRateSection:PieDistributionSection;
		private var deliveredBasalSection:PieDistributionSection;

		private var userType:String;

		private var basalAmountOutput:String;

		private var basalRateOutput:String;

		private var deliveredBasalOutput:String;

		[ResourceBundle("globaltranslations")]
		[ResourceBundle("chartscreen")]
		[ResourceBundle("treatments")]
		
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
			updateStats();
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
			
			//User Type
			userType = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_USER_TYPE_PUMP_OR_MDI);
			
			//Set Strings
			lowOutput = ModelLocator.resourceManagerInstance.getString('chartscreen','low_title');
			highOutput = ModelLocator.resourceManagerInstance.getString('chartscreen','high_title');
			inRangeOutput = ModelLocator.resourceManagerInstance.getString('chartscreen','in_range_title');
			readingsOutput = ModelLocator.resourceManagerInstance.getString('chartscreen','readings_title');
			avgGlucoseOutput = ModelLocator.resourceManagerInstance.getString('chartscreen','average_glucose_title');
			A1COutput = ModelLocator.resourceManagerInstance.getString('chartscreen','a1c_title');
			stdDeviationOutput = ModelLocator.resourceManagerInstance.getString('chartscreen','standard_deviation_label');
			gviOutput = ModelLocator.resourceManagerInstance.getString('chartscreen','glycemic_variavility_index_label');
			pgsOutput = ModelLocator.resourceManagerInstance.getString('chartscreen','patient_glycemic_status_label');
			meanChangeOutput = ModelLocator.resourceManagerInstance.getString('chartscreen','mean_change_label');
			timeInFluctuation5Output = glucoseUnit == "mg/dL" ? ">" + "5" + GlucoseHelper.getGlucoseUnit() + "/" + "5" +  ModelLocator.resourceManagerInstance.getString('chartscreen','minutes_small_abbreviation_label') :  "> " + "0.28" + "/" + "5" +  ModelLocator.resourceManagerInstance.getString('chartscreen','minutes_small_abbreviation_label');
			timeInFluctuation10Output = glucoseUnit == "mg/dL" ? ">" + "10" + GlucoseHelper.getGlucoseUnit() + "/" + "5" +  ModelLocator.resourceManagerInstance.getString('chartscreen','minutes_small_abbreviation_label') :  "> " + "0.56" + "/" + "5" +  ModelLocator.resourceManagerInstance.getString('chartscreen','minutes_small_abbreviation_label');
			bolusOutput = ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_bolus');
			carbsOutput = ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_carbs');
			exerciseOutput = ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_exercise');
			basalAmountOutput = userType == "mdi" ? ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_basal') : ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_temp_basal');
			basalRateOutput = ModelLocator.resourceManagerInstance.getString('treatments','basal_rate');
			deliveredBasalOutput = ModelLocator.resourceManagerInstance.getString('treatments','delivered_basal');
		}
		
		private function setupProperties():void
		{
			/* Instantiate Objects */
			nGons = [];
			
			statsContainer = new Sprite();
			statsContainer.touchable = false;
			addChild(statsContainer);
			
			pieContainer = new Sprite();
			pieContainer.x = piePadding * 2;
			pieContainer.y = piePadding;
			pieContainer.addEventListener(TouchEvent.TOUCH, onPieTouch);
			addChild(pieContainer);
			
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
			
			statsWidth = (3 * sectionWidth) + (3 * sectionsGap);
			firstPageX = statsContainer.x;
			secondPageX = firstPageX - statsWidth;
			thirdPageX = firstPageX - (2 * statsWidth);
			if (CGMBlueToothDevice.isDexcomFollower() || CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_ENABLED) != "true")
			{
				thirdPageX = secondPageX;
			}
			
			/* PIE BACKGROUND */
			pieBackground = new Quad((pieSize * 2) + (10 - sectionsGap), pieSize * 2, sectionColor);
			pieBackground.touchable = false;
			addChildAt(pieBackground, 1);
			
			/* PIE LEFT SECTION */
			pieLeftSection = new Quad(20, pieSize * 2, 0x20222a);
			pieLeftSection.x = -20;
			pieLeftSection.touchable = false;
			addChild(pieLeftSection);
			
			/* PIE RIGHT SECTION */
			pieRightSection = new Quad(sectionsGap, pieSize * 2, 0x20222a);
			pieRightSection.x = pieBackground.x + pieBackground.width;
			pieRightSection.touchable = false;
			addChild(pieRightSection);
			
			/* STATS RIGHT SECTION */
			statsRightSection = new Quad(20, pieSize * 2, 0x20222a);
			statsRightSection.x = statsContainer.x + (3 * sectionWidth) + (3 * sectionsGap);
			statsRightSection.touchable = false;
			addChild(statsRightSection);
			
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
			
			/* ST Deviation */
			stDeviationSection = new PieDistributionSection(sectionWidth, sectionHeight, sectionColor, fontColor);
			stDeviationSection.touchable = false;
			stDeviationSection.x = highSection.x + highSection.width + sectionsGap;
			stDeviationSection.title.text = stdDeviationOutput;
			statsContainer.addChild(stDeviationSection);
			
			/* GVI */
			gviSection = new PieDistributionSection(sectionWidth, sectionHeight, sectionColor, fontColor);
			gviSection.touchable = false;
			gviSection.x = stDeviationSection.x + stDeviationSection.width + sectionsGap;
			gviSection.title.text = gviOutput;
			statsContainer.addChild(gviSection);
			
			/* PGS */
			pgsSection = new PieDistributionSection(sectionWidth, sectionHeight, sectionColor, fontColor);
			pgsSection.touchable = false;
			pgsSection.x = gviSection.x + gviSection.width + sectionsGap;
			pgsSection.title.text = pgsOutput;
			statsContainer.addChild(pgsSection);
			
			/* Mean Hourly Change */
			meanHourlyChangeSection = new PieDistributionSection(sectionWidth, sectionHeight, sectionColor, fontColor);
			meanHourlyChangeSection.touchable = false;
			meanHourlyChangeSection.x = numReadingsSection.x + numReadingsSection.width + sectionsGap;
			meanHourlyChangeSection.y = numReadingsSection.y;
			meanHourlyChangeSection.title.text = meanChangeOutput;
			statsContainer.addChild(meanHourlyChangeSection);
			
			/* Time Fluctuation 5 */
			timeFluctuation5Section = new PieDistributionSection(sectionWidth, sectionHeight, sectionColor, fontColor);
			timeFluctuation5Section.touchable = false;
			timeFluctuation5Section.x = meanHourlyChangeSection.x + meanHourlyChangeSection.width + sectionsGap;
			timeFluctuation5Section.y = meanHourlyChangeSection.y;
			timeFluctuation5Section.title.text = timeInFluctuation5Output;
			statsContainer.addChild(timeFluctuation5Section);
			
			/* Time Fluctuation 10 */
			timeFluctuation10Section = new PieDistributionSection(sectionWidth, sectionHeight, sectionColor, fontColor);
			timeFluctuation10Section.touchable = false;
			timeFluctuation10Section.x = timeFluctuation5Section.x + timeFluctuation5Section.width + sectionsGap;
			timeFluctuation10Section.y = timeFluctuation5Section.y;
			timeFluctuation10Section.title.text = timeInFluctuation10Output;
			statsContainer.addChild(timeFluctuation10Section);
			
			/* Carbs */
			carbsSection = new PieDistributionSection(sectionWidth, sectionHeight, sectionColor, fontColor);
			carbsSection.touchable = false;
			carbsSection.x = timeFluctuation10Section.x + timeFluctuation10Section.width + sectionsGap;
			carbsSection.title.text = carbsOutput;
			statsContainer.addChild(carbsSection);
			
			/* Bolus */
			bolusSection = new PieDistributionSection(sectionWidth, sectionHeight, sectionColor, fontColor);
			bolusSection.touchable = false;
			bolusSection.x = carbsSection.x + carbsSection.width + sectionsGap;
			bolusSection.title.text = bolusOutput;
			statsContainer.addChild(bolusSection);
			
			/* Exercise */
			exerciseSection = new PieDistributionSection(sectionWidth, sectionHeight, sectionColor, fontColor);
			exerciseSection.touchable = false;
			exerciseSection.x = bolusSection.x + bolusSection.width + sectionsGap;
			exerciseSection.title.text = exerciseOutput;
			statsContainer.addChild(exerciseSection);
			
			/* Basal Amount */
			basalAmountSection = new PieDistributionSection(sectionWidth, sectionHeight, sectionColor, fontColor);
			basalAmountSection.touchable = false;
			basalAmountSection.x = timeFluctuation10Section.x + timeFluctuation10Section.width + sectionsGap;
			basalAmountSection.y = meanHourlyChangeSection.y;
			basalAmountSection.title.text = basalAmountOutput;
			statsContainer.addChild(basalAmountSection);
			
			/* EDaily Basal Rate */
			basalRateSection = new PieDistributionSection(sectionWidth, sectionHeight, sectionColor, fontColor);
			basalRateSection.touchable = false;
			basalRateSection.x = basalAmountSection.x + basalAmountSection.width + sectionsGap;
			basalRateSection.y = basalAmountSection.y;
			basalRateSection.title.text = userType == "pump" ? basalRateOutput : "";
			statsContainer.addChild(basalRateSection);
			
			/* Empty */
			deliveredBasalSection = new PieDistributionSection(sectionWidth, sectionHeight, sectionColor, fontColor);
			deliveredBasalSection.touchable = false;
			deliveredBasalSection.x = basalRateSection.x + basalRateSection.width + sectionsGap;
			deliveredBasalSection.y = basalRateSection.y;
			deliveredBasalSection.title.text = userType == "pump" ? deliveredBasalOutput : "";
			statsContainer.addChild(deliveredBasalSection);
			
			/* STATS HIT AREA */
			statsHitArea = new Quad(statsContainer.width, statsContainer.height, 0xFF0000);
			statsHitArea.x = statsContainer.x;
			statsHitArea.y = statsContainer.y;
			statsHitArea.alpha = 0;
			statsHitArea.addEventListener(TouchEvent.TOUCH, onStatsTouch);
			addChild(statsHitArea);
			
			/* Select Default Page */
			if (currentPageNumber == 1)
			{
				statsContainer.x = firstPageX;
			}
			else if (currentPageNumber == 2)
			{
				statsContainer.x = secondPageX;
			}
			else if (currentPageNumber == 3)
			{
				statsContainer.x = thirdPageX;
			}
		}
		
		public function updateStats(page:String = "all"):Boolean
		{	
			if (_dataSource != null && _dataSource.length > 0)
				dummyModeActive = false;
			else
				dummyModeActive = true;
			
			if (!SystemUtil.isApplicationActive)
				return false;
			
			if (page == BasicUserStats.PAGE_ALL || page == BasicUserStats.PAGE_BG_DISTRIBUTION)
			{
				lastGlucoseDistributionFetch = new Date().valueOf();
			}
			
			var userStats:BasicUserStats = StatsManager.getBasicUserStats(fromTime, untilTime, page);
			if (userStats == null)
			{
				return false;
			}
			
			if ((isNaN(userStats.percentageHigh) || isNaN(userStats.percentageInRange) || isNaN(userStats.percentageLow)) && (userStats.page == BasicUserStats.PAGE_ALL || userStats.page == BasicUserStats.PAGE_BG_DISTRIBUTION))
			{
				dummyModeActive = true;
			}
			
			if (userStats.page == BasicUserStats.PAGE_ALL || userStats.page == BasicUserStats.PAGE_BG_DISTRIBUTION)
			{
				//If there's no good readings then activate dummy mode.
				if (isNaN(userStats.numReadingsDay) || userStats.numReadingsDay == 0)
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
					
					pieChartDrawn = true;
				}
				//Legend
				if (lowSection != null)
				{
					lowSection.message.text = !dummyModeActive ? userStats.percentageLowRounded + "%" : ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available');
				}
					
				//IN RANGE PORTION
				//Graphics
				if (!dummyModeActive)
				{
					if (inRangeNGonSpike != null) inRangeNGonSpike.removeFromParent(true);
					inRangeNGonSpike = new SpikeNGon(pieRadius, numSides, lowAngle, lowAngle + inRangeAngle, inRangeColor);
					inRangeNGonSpike.x = inRangeNGonSpike.y = pieRadius;
					nGons.push(inRangeNGonSpike);
					pieGraphicContainer.addChild(inRangeNGonSpike);
					
					pieChartDrawn = true;
				}
				//Legend
				if (inRangeSection != null)
				{
					inRangeSection.message.text = !dummyModeActive ? userStats.percentageInRangeRounded + "%" : ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available');
				}
					
				//HIGH PORTION
				//Graphics
				if (!dummyModeActive)
				{
					if (highNGonSpike != null) highNGonSpike.removeFromParent(true);
					highNGonSpike = new SpikeNGon(pieRadius, numSides, lowAngle + inRangeAngle, lowAngle + inRangeAngle + highAngle, highColor);
					highNGonSpike.x = highNGonSpike.y = pieRadius;
					nGons.push(highNGonSpike);
					pieGraphicContainer.addChild(highNGonSpike);
					
					pieChartDrawn = true;
				}
				//Legend
				if (highSection != null)
				{
					highSection.message.text = !dummyModeActive ? userStats.percentageHighRounded + "%" : ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available');
				}
			}
			
			//DUMMY NGON
			if (dummyModeActive && nGons != null)
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
				
				pieChartDrawn = false;
			}
			
			//Add pie to display list
			if (pieContainer != null && pieGraphicContainer != null)
				pieContainer.addChild(pieGraphicContainer);
			
			if (userStats.page == BasicUserStats.PAGE_ALL || userStats.page == BasicUserStats.PAGE_BG_DISTRIBUTION)
			{
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
				if (numReadingsSection != null) numReadingsSection.message.text = !dummyModeActive && !isNaN(userStats.numReadingsDay) ? userStats.numReadingsDay + " (" + userStats.captureRate + "%)" : ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available');
				if (avgGlucoseSection != null) avgGlucoseSection.message.text = !dummyModeActive ? averageGlucoseValueOutput + " " + glucoseUnit : ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available');
				if (estA1CSection != null) estA1CSection.message.text = !dummyModeActive && !isNaN(userStats.a1c) ? userStats.a1c + (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PIE_CHART_A1C_IFCC_ON) != "true" ? "%" : " mmol/mol") : ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available');
			}
			
			if (userStats.page == BasicUserStats.PAGE_ALL || userStats.page == BasicUserStats.PAGE_VARIABILITY)
			{
				if (stDeviationSection != null) stDeviationSection.message.text = !dummyModeActive && !isNaN(userStats.standardDeviation) ? userStats.standardDeviation + " " + glucoseUnit : ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available');
				if (gviSection != null) gviSection.message.text = !dummyModeActive && !isNaN(userStats.gvi) ? userStats.gvi + " " + "(" + getGVIGrade(userStats.gvi) + ")" + (userStats.gvi <= 1.2 ? " " + "(" + ModelLocator.resourceManagerInstance.getString('chartscreen','non_diabetic_small') + ")" : "") : ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available');
				if (pgsSection != null) pgsSection.message.text = !dummyModeActive && !isNaN(userStats.pgs) ? userStats.pgs + " " + "(" + getPGSGrade(userStats.pgs) + ")" + (userStats.pgs <= 35 ? " " + "(" + ModelLocator.resourceManagerInstance.getString('chartscreen','non_diabetic_small') + ")" : "") : ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available');
				if (meanHourlyChangeSection != null) meanHourlyChangeSection.message.text = !dummyModeActive && !isNaN(userStats.hourlyChange) ? userStats.hourlyChange + " " + glucoseUnit + "/" + ModelLocator.resourceManagerInstance.getString('chartscreen','hours_small_abbreviation_label') : ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available');
				if (timeFluctuation5Section != null) timeFluctuation5Section.message.text = !dummyModeActive && !isNaN(userStats.fluctuation5) ? userStats.fluctuation5 + "%" : ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available');
				if (timeFluctuation10Section != null) timeFluctuation10Section.message.text = !dummyModeActive && !isNaN(userStats.fluctuation10) ? userStats.fluctuation10 + "%" : ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available');
			}
			
			if (userStats.page == BasicUserStats.PAGE_ALL || userStats.page == BasicUserStats.PAGE_TREATMENTS)
			{
				if (carbsSection != null) carbsSection.message.text = !dummyModeActive && !isNaN(userStats.carbs) ? GlucoseFactory.formatCOB(userStats.carbs) : ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available');
				if (bolusSection != null) bolusSection.message.text = !dummyModeActive && !isNaN(userStats.bolus) ? GlucoseFactory.formatIOB(userStats.bolus) : ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available');
				if (exerciseSection != null) exerciseSection.message.text = !dummyModeActive && !isNaN(userStats.exercise) ? TimeSpan.formatHoursMinutesFromMinutes(userStats.exercise, true, userStats.exercise != 0) : ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available');
				if (basalAmountSection != null) basalAmountSection.message.text = !dummyModeActive && !isNaN(userStats.basal) ? GlucoseFactory.formatIOB(userStats.basal) : ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available');
				if (userType == "pump" && basalRateSection != null) basalRateSection.message.text = !dummyModeActive && !isNaN(userStats.basalRates) ? GlucoseFactory.formatIOB(userStats.basalRates) : ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available');
				if (userType == "pump" && deliveredBasalSection != null) deliveredBasalSection.message.text = !dummyModeActive && !isNaN(ProfileManager.totalDeliveredPumpBasalAmount) ? GlucoseFactory.formatIOB(ProfileManager.totalDeliveredPumpBasalAmount) : ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available');
			}
			
			if (page != BasicUserStats.PAGE_ALL && page != BasicUserStats.PAGE_BG_DISTRIBUTION && !pieChartDrawn)
			{
				setTimeout( function():void 
				{
					SystemUtil.executeWhenApplicationIsActive(updateStats, BasicUserStats.PAGE_BG_DISTRIBUTION);
				}, 1000 );
			}
			
			return true;
		}
		
		private function getGVIGrade(gvi:Number):String
		{
			var gviGrade:String = "";
			
			if (gvi < 1.1)
			{
				gviGrade = "A+";
			}
			else if (gvi < 1.2)
			{
				gviGrade = "A";
			}
			else if (gvi < 1.25)
			{
				gviGrade = "A-";
			}
			else if (gvi < 1.3)
			{
				gviGrade = "B+";
			}
			else if (gvi < 1.35)
			{
				gviGrade = "B";
			}
			else if (gvi < 1.4)
			{
				gviGrade = "B-";
			}
			else if (gvi < 1.45)
			{
				gviGrade = "C+";
			}
			else if (gvi < 1.5)
			{
				gviGrade = "C";
			}
			else if (gvi < 1.55)
			{
				gviGrade = "C-";
			}
			else if (gvi < 1.6)
			{
				gviGrade = "D+";
			}
			else if (gvi < 1.65)
			{
				gviGrade = "D";
			}
			else if (gvi < 1.7)
			{
				gviGrade = "D-";
			}
			else if (gvi < 1.75)
			{
				gviGrade = "E+";
			}
			else if (gvi < 1.8)
			{
				gviGrade = "E";
			}
			else if (gvi < 1.85)
			{
				gviGrade = "E-";
			}
			else if (gvi < 1.9)
			{
				gviGrade = "F+";
			}
			else if (gvi < 1.95)
			{
				gviGrade = "F";
			}
			else
			{
				gviGrade = "F-";
			}
			
			return gviGrade;
		}
		
		private function getPGSGrade(pgs:Number):String
		{
			var pgsGrade:String = "";
			
			if (pgs < 25)
			{
				pgsGrade = "A+";
			}
			else if (pgs <= 35)
			{
				pgsGrade = "A";
			}
			else if (pgs < 45)
			{
				pgsGrade = "A-";
			}
			else if (pgs < 60)
			{
				pgsGrade = "B+";
			}
			else if (pgs < 85)
			{
				pgsGrade = "B";
			}
			else if (pgs <= 100)
			{
				pgsGrade = "B-";
			}
			else if (pgs < 110)
			{
				pgsGrade = "C+";
			}
			else if (pgs < 115)
			{
				pgsGrade = "C";
			}
			else if (pgs < 120)
			{
				pgsGrade = "C-";
			}
			else if (pgs < 125)
			{
				pgsGrade = "D+";
			}
			else if (pgs < 130)
			{
				pgsGrade = "D";
			}
			else if (pgs < 135)
			{
				pgsGrade = "D-";
			}
			else if (pgs < 140)
			{
				pgsGrade = "E+";
			}
			else if (pgs < 145)
			{
				pgsGrade = "E";
			}
			else if (pgs < 150)
			{
				pgsGrade = "E-";
			}
			else if (pgs < 155)
			{
				pgsGrade = "F+";
			}
			else if (pgs < 160)
			{
				pgsGrade = "F";
			}
			else
			{
				pgsGrade = "F-";
			}
			
			return pgsGrade;
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
				
				//Nudge stats x position if needed
				if (statsContainer.x != firstPageX || statsContainer.x != thirdPageX)
				{
					var targetX:Number;
					
					if 
					(
						Math.abs(firstPageX - statsContainer.x) <= Math.abs(statsContainer.x - thirdPageX)
						&&
						Math.abs(firstPageX - statsContainer.x) <= Math.abs(statsContainer.x - secondPageX)
					)
					{
						targetX = firstPageX;
						currentPageNumber = 1;
					}
					else if 
						(
							Math.abs(secondPageX - statsContainer.x) <= Math.abs(statsContainer.x - thirdPageX)
							&&
							Math.abs(secondPageX - statsContainer.x) <= Math.abs(statsContainer.x - firstPageX)
						)
					{
						targetX = secondPageX;
						currentPageNumber = 2;
					}
					else
					{
						targetX = thirdPageX;
						currentPageNumber = 3;
					}
					
					var statsTween:Tween = new Tween(statsContainer, 0.4, Transitions.EASE_IN_OUT);
					statsTween.moveTo(targetX, statsContainer.y);
					statsTween.onComplete = function():void
					{
						updateStats(getPageName());
						statsTween.onComplete = null;
						statsTween = null;
					}
					Starling.juggler.add(statsTween);
				}
			}
			
			if(touch != null && touch.phase == TouchPhase.MOVED)
			{
				//Remove settings timer
				pieTimer = Number.NaN;
				removeEventListener(Event.ENTER_FRAME, onStatsHold);
				
				///Get the mouse location related to the stage
				var p:Point = touch.getMovement(stage);
				
				//Get current stats x position
				var previousStatsX:Number = statsContainer.x;
				
				//Set stats x position according to drag
				statsContainer.x += p.x;
				
				//Constrains
				if (statsContainer.x > firstPageX)
				{
					statsContainer.x = firstPageX;
				}
				else if (statsContainer.x < thirdPageX)
				{
					statsContainer.x = thirdPageX;
				}
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
			
			if (timeFluctuation5Section != null)
			{
				timeFluctuation5Section.removeFromParent();
				timeFluctuation5Section.dispose();
				timeFluctuation5Section = null;
			}
			
			if (stDeviationSection != null)
			{
				stDeviationSection.removeFromParent();
				stDeviationSection.dispose();
				stDeviationSection = null;
			}
			
			if (timeFluctuation10Section != null)
			{
				timeFluctuation10Section.removeFromParent();
				timeFluctuation10Section.dispose();
				timeFluctuation10Section = null;
			}
			
			if (gviSection != null)
			{
				gviSection.removeFromParent();
				gviSection.dispose();
				gviSection = null;
			}
			
			if (pgsSection != null)
			{
				pgsSection.removeFromParent();
				pgsSection.dispose();
				pgsSection = null;
			}
			
			if (meanHourlyChangeSection != null)
			{
				meanHourlyChangeSection.removeFromParent();
				meanHourlyChangeSection.dispose();
				meanHourlyChangeSection = null;
			}
			
			if (carbsSection != null)
			{
				carbsSection.removeFromParent();
				carbsSection.dispose();
				carbsSection = null;
			}
			
			if (bolusSection != null)
			{
				bolusSection.removeFromParent();
				bolusSection.dispose();
				bolusSection = null;
			}
			
			if (exerciseSection != null)
			{
				exerciseSection.removeFromParent();
				exerciseSection.dispose();
				exerciseSection = null;
			}
			
			if (basalAmountSection != null)
			{
				basalAmountSection.removeFromParent();
				basalAmountSection.dispose();
				basalAmountSection = null;
			}
			
			if (basalRateSection != null)
			{
				basalRateSection.removeFromParent();
				basalRateSection.dispose();
				basalRateSection = null;
			}
			
			if (deliveredBasalSection != null)
			{
				deliveredBasalSection.removeFromParent();
				deliveredBasalSection.dispose();
				deliveredBasalSection = null;
			}
			
			if (statsRightSection != null)
			{
				statsRightSection.removeFromParent();
				statsRightSection.dispose();
				statsRightSection = null;
			}
			
			if (pieRightSection != null)
			{
				pieRightSection.removeFromParent();
				pieRightSection.dispose();
				pieRightSection = null;
			}
			
			if (pieLeftSection != null)
			{
				pieLeftSection.removeFromParent();
				pieLeftSection.dispose();
				pieLeftSection = null;
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

		public function get currentPageNumber():Number
		{
			_currentPageNumber = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PIE_CHART_ACTIVE_PAGE));
			
			setPageName();
			
			return _currentPageNumber;
		}

		public function set currentPageNumber(value:Number):void
		{
			CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_PIE_CHART_ACTIVE_PAGE, String(value), true, false);
			
			_currentPageNumber = value;
			
			setPageName();
		}

		public function get currentPageName():String
		{
			return _currentPageName;
		}
		
		private function setPageName():void
		{
			if (_currentPageNumber == 1)
				_currentPageName = BasicUserStats.PAGE_BG_DISTRIBUTION;
			else if (_currentPageNumber == 2)
				_currentPageName = BasicUserStats.PAGE_VARIABILITY;
			else if (_currentPageNumber == 3)
				_currentPageName = BasicUserStats.PAGE_TREATMENTS;
		}
		
		public function getPageName():String
		{
			var name:String = BasicUserStats.PAGE_ALL;
			
			if (_currentPageNumber == 1)
				return BasicUserStats.PAGE_BG_DISTRIBUTION;
			else if (_currentPageNumber == 2)
				return BasicUserStats.PAGE_VARIABILITY;
			else if (_currentPageNumber == 3)
				return BasicUserStats.PAGE_TREATMENTS;
			else
				return BasicUserStats.PAGE_ALL;
		}
	}
}