package ui.screens
{	
	import flash.display.StageOrientation;
	import flash.system.System;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	import database.BgReading;
	import database.CGMBlueToothDevice;
	import database.Calibration;
	import database.CommonSettings;
	
	import events.CalibrationServiceEvent;
	import events.FollowerEvent;
	import events.SpikeEvent;
	import events.TransmitterServiceEvent;
	import events.TreatmentsEvent;
	
	import feathers.controls.Check;
	import feathers.controls.Radio;
	import feathers.controls.ScrollBarDisplayMode;
	import feathers.controls.ScrollPolicy;
	import feathers.core.ToggleGroup;
	import feathers.events.FeathersEventType;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import services.CalibrationService;
	import services.DexcomShareService;
	import services.NightscoutService;
	import services.TransmitterService;
	
	import starling.core.Starling;
	import starling.events.Event;
	import starling.events.ResizeEvent;
	import starling.utils.SystemUtil;
	
	import stats.BasicUserStats;
	
	import treatments.Treatment;
	import treatments.TreatmentsManager;
	
	import ui.AppInterface;
	import ui.chart.DistributionChart;
	import ui.chart.GlucoseChart;
	import ui.chart.layout.GraphLayoutFactory;
	import ui.chart.visualcomponents.PieDistributionSection;
	import ui.screens.display.LayoutFactory;
	import ui.shapes.SpikeLine;
	
	import utils.Constants;
	import utils.DeviceInfo;
	import utils.TimeSpan;
	import utils.Trace;
	
	[ResourceBundle("chartscreen")]
	
	public class ChartScreen extends BaseScreen
	{
		//Objects
		private var chartData:Array;
		private var newReadingsList:Array = [];
		private var newReadingsListFollower:Array = [];
		private var timeRangeGroup:ToggleGroup;
		
		//Visual variables
		private var glucoseChartTopPadding:int = 7;
		private var selectedTimelineRange:Number;
		private var drawLineChart:Boolean;
		private var mainChartHeight:Number;
		private var availableScreenHeight:Number;
		private var chartSettingsLeftRightPadding:int = 10;
		private var chartSettingsTopPadding:int = 10;
		private var delimitterTopPadding:int = 10;
		private var pieTopPadding:int = 15;
		private var pieChartHeight:Number;
		private var displayPieChart:Boolean;
		private var redrawChartTimeoutID:int;
		private var isPortrait:Boolean;
		private var displayRawData:Boolean;
		private var displayRawComponent:Boolean;
		
		//Logical Variables
		private var chartRequiresReload:Boolean = true;
		private var appInBackground:Boolean = false;
		private var queueTimeout:int = -1;
		private var pieChartTreatmentUpdaterTimeout:int = -1;
		
		//Display Objects
		private var glucoseChart:GlucoseChart;
		private var pieChart:DistributionChart;
		private var h24:Radio;
		private var h12:Radio;
		private var h6:Radio;
		private var h3:Radio;
		private var h1:Radio;
		private var displayLines:Check;
		private var delimitter:SpikeLine;
		private var displayRawCheck:Check;
		
		public function ChartScreen() 
		{
			super();
			styleNameList.add( BaseMaterialDeepGreyAmberMobileTheme.THEME_STYLE_NAME_HEADER_WITH_SHADOW );
			styleNameList.add( BaseMaterialDeepGreyAmberMobileTheme.THEME_STYLE_NAME_PANEL_WITHOUT_PADDING );
		}
		
		override protected function initialize():void 
		{
			super.initialize();
			
			//Set Properties From Database
			selectedTimelineRange = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_SELECTED_TIMELINE_RANGE));
			drawLineChart = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_DISPLAY_LINE) == "true";
			displayPieChart = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_DISPLAY_GLUCOSE_DISTRIBUTION) == "true";
			displayRawComponent = CGMBlueToothDevice.isDexcomG4() || CGMBlueToothDevice.isDexcomG5() || CGMBlueToothDevice.isDexcomG6();
			displayRawData = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_DISPLAY_RAW_ON) == "true";
			
			//Event listeners
			addEventListener(FeathersEventType.CREATION_COMPLETE, onCreation);
			Spike.instance.addEventListener(SpikeEvent.APP_IN_BACKGROUND, onAppInBackground);
			Spike.instance.addEventListener(SpikeEvent.APP_IN_FOREGROUND, onAppInForeground);
			TransmitterService.instance.addEventListener(TransmitterServiceEvent.LAST_BGREADING_RECEIVED, onBgReadingReceived);
			NightscoutService.instance.addEventListener(FollowerEvent.BG_READING_RECEIVED, onBgReadingReceivedFollower);
			DexcomShareService.instance.addEventListener(FollowerEvent.BG_READING_RECEIVED, onBgReadingReceivedFollower);
			CalibrationService.instance.addEventListener(CalibrationServiceEvent.INITIAL_CALIBRATION_EVENT, onInitialCalibrationReceived);
			TreatmentsManager.instance.addEventListener(TreatmentsEvent.TREATMENT_ADDED, onTreatmentAdded);
			TreatmentsManager.instance.addEventListener(TreatmentsEvent.TREATMENT_EXTERNALLY_MODIFIED, onTreatmentExternallyModified);
			TreatmentsManager.instance.addEventListener(TreatmentsEvent.TREATMENT_EXTERNALLY_DELETED, onTreatmentExternallyDeleted);
			TreatmentsManager.instance.addEventListener(TreatmentsEvent.TREATMENT_DELETED, onTreatmentDeleted);
			TreatmentsManager.instance.addEventListener(TreatmentsEvent.IOB_COB_UPDATED, onUpdateIOBCOB);
			TreatmentsManager.instance.addEventListener(TreatmentsEvent.NEW_BASAL_DATA, onNewBasalData);
			Starling.current.stage.addEventListener(starling.events.Event.RESIZE, onStarlingResize);
			
			//Scroll Policies
			scrollBarDisplayMode = ScrollBarDisplayMode.NONE;
			horizontalScrollPolicy = ScrollPolicy.OFF;
			verticalScrollPolicy = ScrollPolicy.OFF;
			
			//Reset Transitions
			AppInterface.instance.chartSettingsScreenItem.pushTransition = null;
			AppInterface.instance.chartSettingsScreenItem.popTransition = null;
			
			//Reset Menu
			AppInterface.instance.menu.selectedIndex = Constants.isPortrait ? 1 : 0;
		}
		
		/**
		 * Display Objects Creation and Positioning
		 */
		private function createChart():void
		{	
			//When in landscape mode and device is iPhone X, make the header height same as oher models, we don't need to worry about the extra status bar size
			if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr)
			{
				if (Constants.isPortrait)
				{
					this.header.height = 108;
					this.header.maxHeight = 108;	
				}
				else
				{
					this.header.height = 78;
					this.header.maxHeight = 78;
				}
			}
			
			var availableScreenHeight:Number = Constants.stageHeight - this.header.height;
			Constants.isPortrait ? glucoseChartTopPadding = 7 : glucoseChartTopPadding = 0;
			if (Constants.deviceModel == DeviceInfo.IPHONE_2G_3G_3GS_4_4S_ITOUCH_2_3_4) glucoseChartTopPadding = 0;
			if (glucoseChartTopPadding == 0) availableScreenHeight += 7;
			if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr)
				availableScreenHeight -= 15; //To avoid lower notch
			
			mainChartHeight = availableScreenHeight;
			
			if (Constants.isPortrait || (DeviceInfo.isTablet() && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SHOW_PIE_IN_LANDSCAPE) == "true"))
			{
				//Calculate timeline ranges and display line height
				mainChartHeight -= chartSettingsTopPadding; //Top padding for settings
				mainChartHeight -= calculateChartSettingsSize(); //Height of settings components
				mainChartHeight -= delimitterTopPadding; //Bottom padding for settings
				
				if (displayPieChart)
					mainChartHeight -= calculatePieChartSize();
			}
			
			//Get glucose data;
			chartData = ModelLocator.bgReadings.concat();
			
			//Create and setup glucose chart
			var chartWidth:Number = Constants.stageWidth;
			var chartX:Number = 0;
			if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr && !Constants.isPortrait)
			{
				chartWidth -= 40;
				if (Constants.currentOrientation == StageOrientation.ROTATED_RIGHT)
					chartX = 30;
				else if (Constants.currentOrientation == StageOrientation.ROTATED_LEFT)
					chartX = 10;
			}
			
			glucoseChart = new GlucoseChart(selectedTimelineRange, chartWidth, mainChartHeight, false, false, false, false, false, headerProperties);
			glucoseChart.x = Math.round(chartX);
			glucoseChart.y = Math.round(glucoseChartTopPadding);
			glucoseChart.dataSource = chartData;
			glucoseChart.displayLine = drawLineChart;
			glucoseChart.drawGraph();
			glucoseChart.addAllTreatments();
			var now:Number = new Date().valueOf();
			glucoseChart.calculateTotalIOB( now );
			glucoseChart.calculateTotalCOB( now );
			addChild(glucoseChart);
			
			if (Constants.isPortrait || (DeviceInfo.isTablet() && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SHOW_PIE_IN_LANDSCAPE) == "true"))
			{
				createSettings();
				
				if (displayPieChart)
					createPieChart();
			}
			
			Constants.headerHeight = this.header.maxHeight;
		}
		
		private function redrawChart():void
		{
			if (SystemUtil.isApplicationActive)
			{
				chartData = glucoseChart.dataSource;
				
				//Remove previous chart
				removeChild(glucoseChart);
				glucoseChart.dispose();
				glucoseChart = null;
				
				var chartWidth:Number = Constants.stageWidth;
				var chartX:Number = 0;
				if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr && !Constants.isPortrait)
				{
					chartWidth -= 40;
					if (Constants.currentOrientation == StageOrientation.ROTATED_RIGHT)
						chartX = 30;
					else if (Constants.currentOrientation == StageOrientation.ROTATED_LEFT)
						chartX = 10;
				}
				
				//Create new chart
				glucoseChart = new GlucoseChart(selectedTimelineRange, chartWidth, mainChartHeight, false, false, false, false, false, headerProperties);
				glucoseChart.x = Math.round(chartX);
				glucoseChart.y = Math.round(glucoseChartTopPadding);
				glucoseChart.dataSource = chartData;
				glucoseChart.displayLine = drawLineChart;
				glucoseChart.drawGraph();
				glucoseChart.addAllTreatments();
				var now:Number = new Date().valueOf();
				glucoseChart.calculateTotalIOB( now );
				glucoseChart.calculateTotalCOB( now );
				addChild(glucoseChart);
			}
			else
				SystemUtil.executeWhenApplicationIsActive( redrawChartForTreatmentsAndLine );
		}
		
		private function createSettings():void
		{
			//Position Radio/Check Buttons
			var paddingMultiplier:Number = DeviceInfo.getHorizontalPaddingMultipier();
			
			var spacer:Number = 0;
			if (!displayRawComponent || DeviceInfo.isTablet())
			{
				spacer = chartSettingsLeftRightPadding * paddingMultiplier;
			}
			else
			{
				//Vaidate all components
				h24.validate();
				h12.validate();
				h6.validate();
				h3.validate();
				h1.validate();
				displayLines.validate();
				displayRawCheck.validate();
				
				spacer = (stage.stageWidth - h24.width - h12.width - h6.width - h3.width - h1.width - displayLines.width - displayRawCheck.width - (2 * chartSettingsLeftRightPadding)) / 6;
			}
			
			h24.x = stage.stageWidth - h24.width - chartSettingsLeftRightPadding;
			h24.y = glucoseChart.y + mainChartHeight + chartSettingsTopPadding;
			addChild(h24);
			
			h12.x = h24.x - h12.width - spacer;
			h12.y = h24.y;
			addChild(h12);
			
			h6.x = h12.x - h6.width - spacer;
			h6.y = h24.y;
			addChild(h6);
			
			h3.x = h6.x - h3.width - spacer;
			h3.y = h24.y;
			addChild(h3);
			
			h1.x = h3.x - h1.width - spacer;
			h1.y = h24.y;
			addChild(h1);
			
			displayLines.x = chartSettingsLeftRightPadding;
			displayLines.y = h24.y;
			addChild(displayLines);
			
			if (displayRawComponent)
			{
				displayRawCheck.x = displayLines.x + displayLines.width + spacer;
				displayRawCheck.y = displayLines.y;
				addChild(displayRawCheck);
			}
			
			//Radio Buttons Group
			if (selectedTimelineRange == GlucoseChart.TIMELINE_1H)
				timeRangeGroup.selectedItem = h1;
			else if (selectedTimelineRange == GlucoseChart.TIMELINE_3H)
				timeRangeGroup.selectedItem = h3;
			else if (selectedTimelineRange == GlucoseChart.TIMELINE_6H)
				timeRangeGroup.selectedItem = h6;
			else if (selectedTimelineRange == GlucoseChart.TIMELINE_12H)
				timeRangeGroup.selectedItem = h12;
			else if (selectedTimelineRange == GlucoseChart.TIMELINE_24H)
				timeRangeGroup.selectedItem = h24;
			
			//Add Event Listener For Radios
			timeRangeGroup.addEventListener( Event.CHANGE, onTimeRangeChange );
		}
		
		private function createPieChart():void
		{
			delimitter = GraphLayoutFactory.createHorizontalLine(Constants.stageWidth, 1, 0x282a32);
			delimitter.y = h24.y + h24.height + delimitterTopPadding;
			addChild(delimitter);
			
			pieChart = new DistributionChart((pieChartHeight / 2), chartData);
			pieChart.y = Math.round(delimitter.y + delimitter.height + pieTopPadding);
			pieChart.x = 10;
			addChild(pieChart);
		}
		
		private function redrawChartForTreatmentsAndLine():void
		{
			redrawChartTimeoutID = setTimeout(redrawChart, 1500);
		}
		
		private function processQueue():void
		{
			clearTimeout(queueTimeout);
			
			if(!SystemUtil.isApplicationActive)
			{
				queueTimeout = setTimeout(processQueue, 150); //retry in 150ms
				
				return;
			}
			
			try
			{
				if (appInBackground)
				{
					var queueAddedToChart:Boolean = false;
					var queueAddedToPie:Boolean = false;
					
					appInBackground = false;
					
					if (!CGMBlueToothDevice.isFollower())
					{
						if (newReadingsList != null && newReadingsList.length > 0 && glucoseChart != null)
						{
							if (glucoseChart.addGlucose(newReadingsList))
								queueAddedToChart = true;
							
							if (displayPieChart && pieChart != null)
							{
								if (pieChart.updateStats(pieChart.getPageName()))
									queueAddedToPie = true;
								
								if (pieChart.dummyModeActive || (pieChart.currentPageName != BasicUserStats.PAGE_BG_DISTRIBUTION && new Date().valueOf() - pieChart.lastGlucoseDistributionFetch >= TimeSpan.TIME_1_HOUR))
								{
									pieChart.updateStats(BasicUserStats.PAGE_BG_DISTRIBUTION);
								}
							}
							else
								queueAddedToPie = true;
							
							if (queueAddedToChart && queueAddedToPie)
								newReadingsList.length = 0;
						}
						else
							if (glucoseChart != null)
								glucoseChart.calculateDisplayLabels();
					}
					else
					{
						if (newReadingsListFollower != null && newReadingsListFollower.length > 0 && glucoseChart != null)
						{
							if (glucoseChart.addGlucose(newReadingsListFollower))
								queueAddedToChart = true;
							
							if (displayPieChart && pieChart != null)
							{
								if (pieChart.updateStats(pieChart.getPageName()))
									queueAddedToPie = true;
								
								if (pieChart.dummyModeActive || (pieChart.currentPageName != BasicUserStats.PAGE_BG_DISTRIBUTION && new Date().valueOf() - pieChart.lastGlucoseDistributionFetch >= TimeSpan.TIME_1_HOUR))
								{
									pieChart.updateStats(BasicUserStats.PAGE_BG_DISTRIBUTION);
								}
							}
							else
								queueAddedToPie = true;
							
							if (queueAddedToChart && queueAddedToPie)
								newReadingsListFollower.length = 0;
						}	
						else if (glucoseChart != null)
							glucoseChart.calculateDisplayLabels();
					}
				}
			} 
			catch(error:Error)
			{
				Trace.myTrace("ChartScreen.as", "Error adding queue to chart when app came to the foreground. Error: " + error.message);
				
				queueTimeout = setTimeout(processQueue, 150); //retry in 150ms
			}
		}
		
		/**
		 * Display Objects Size Calculators
		 */
		private function calculateChartSettingsSize():Number
		{
			var chartSettingsHeight:Number = 0;
			
			/* Line Settings */
			displayLines = LayoutFactory.createCheckMark(false, ModelLocator.resourceManagerInstance.getString('chartscreen','check_box_line_title'));
			if (Constants.deviceModel == DeviceInfo.IPHONE_2G_3G_3GS_4_4S_ITOUCH_2_3_4)
				displayLines.scale = 0.8;
			else if (Constants.deviceModel == DeviceInfo.IPAD_1_2_3_4_5_AIR1_2_PRO_97 || Constants.deviceModel == DeviceInfo.IPAD_PRO_105 || Constants.deviceModel == DeviceInfo.IPAD_PRO_129)
				displayLines.scale = 1.4;
			displayLines.isSelected = drawLineChart;
			displayLines.addEventListener( Event.CHANGE, onDisplayLine );
			displayLines.validate();
			
			chartSettingsHeight = displayLines.height;
			
			/* Raw Settings */
			if (displayRawComponent)
			{
				displayRawCheck = LayoutFactory.createCheckMark(displayRawData, ModelLocator.resourceManagerInstance.getString('chartscreen','raw_glucose'));
				if (Constants.deviceModel == DeviceInfo.IPHONE_2G_3G_3GS_4_4S_ITOUCH_2_3_4)
					displayRawCheck.scale = 0.8;
				else if (Constants.deviceModel == DeviceInfo.IPAD_1_2_3_4_5_AIR1_2_PRO_97 || Constants.deviceModel == DeviceInfo.IPAD_PRO_105 || Constants.deviceModel == DeviceInfo.IPAD_PRO_129)
					displayRawCheck.scale = 1.4;
				
				displayRawCheck.validate();
				
				displayRawCheck.addEventListener( Event.CHANGE, onDisplayRaw );
			}
			
			/* Timeline Settings */
			timeRangeGroup = new ToggleGroup();
			
			//Create Radios
			h1 = LayoutFactory.createRadioButton(ModelLocator.resourceManagerInstance.getString('chartscreen','radio_button_1h_title'), timeRangeGroup);
			if (Constants.deviceModel == DeviceInfo.IPHONE_2G_3G_3GS_4_4S_ITOUCH_2_3_4)
				h1.scale = 0.8;
			else if (Constants.deviceModel == DeviceInfo.IPAD_1_2_3_4_5_AIR1_2_PRO_97 || Constants.deviceModel == DeviceInfo.IPAD_PRO_105 || Constants.deviceModel == DeviceInfo.IPAD_PRO_129)
				h1.scale = 1.4;
			h1.validate();
			
			h3 = LayoutFactory.createRadioButton(ModelLocator.resourceManagerInstance.getString('chartscreen','radio_button_3h_title'), timeRangeGroup);
			if (Constants.deviceModel == DeviceInfo.IPHONE_2G_3G_3GS_4_4S_ITOUCH_2_3_4)
				h3.scale = 0.8;
			else if (Constants.deviceModel == DeviceInfo.IPAD_1_2_3_4_5_AIR1_2_PRO_97 || Constants.deviceModel == DeviceInfo.IPAD_PRO_105 || Constants.deviceModel == DeviceInfo.IPAD_PRO_129)
				h3.scale = 1.4;
			h3.validate();
			
			h6 = LayoutFactory.createRadioButton(ModelLocator.resourceManagerInstance.getString('chartscreen','radio_button_6h_title'), timeRangeGroup);
			if (Constants.deviceModel == DeviceInfo.IPHONE_2G_3G_3GS_4_4S_ITOUCH_2_3_4)
				h6.scale = 0.8;
			else if (Constants.deviceModel == DeviceInfo.IPAD_1_2_3_4_5_AIR1_2_PRO_97 || Constants.deviceModel == DeviceInfo.IPAD_PRO_105 || Constants.deviceModel == DeviceInfo.IPAD_PRO_129)
				h6.scale = 1.4;
			h6.validate();
			
			h12 = LayoutFactory.createRadioButton(ModelLocator.resourceManagerInstance.getString('chartscreen','radio_button_12h_title'), timeRangeGroup);
			if (Constants.deviceModel == DeviceInfo.IPHONE_2G_3G_3GS_4_4S_ITOUCH_2_3_4)
				h12.scale = 0.8;
			else if (Constants.deviceModel == DeviceInfo.IPAD_1_2_3_4_5_AIR1_2_PRO_97 || Constants.deviceModel == DeviceInfo.IPAD_PRO_105 || Constants.deviceModel == DeviceInfo.IPAD_PRO_129)
				h12.scale = 1.4;
			h12.validate();
			
			h24 = LayoutFactory.createRadioButton(ModelLocator.resourceManagerInstance.getString('chartscreen','radio_button_24h_title'), timeRangeGroup);
			if (Constants.deviceModel == DeviceInfo.IPHONE_2G_3G_3GS_4_4S_ITOUCH_2_3_4)
				h24.scale = 0.8;
			else if (Constants.deviceModel == DeviceInfo.IPAD_1_2_3_4_5_AIR1_2_PRO_97 || Constants.deviceModel == DeviceInfo.IPAD_PRO_105 || Constants.deviceModel == DeviceInfo.IPAD_PRO_129)
				h24.scale = 1.4;
			h24.validate();
			
			return chartSettingsHeight;
		}
		
		private function calculatePieChartSize():Number
		{
			var pieChartTotalHeight:Number = 0;
			
			if (Constants.deviceModel == DeviceInfo.IPHONE_2G_3G_3GS_4_4S_ITOUCH_2_3_4)
				pieTopPadding = 10;
			
			pieChartTotalHeight += pieTopPadding * 2;
			
			var dummyPieChartStatsSection:PieDistributionSection = new PieDistributionSection(100, 30, 0x000000, 0x000000, 0x000000);
			dummyPieChartStatsSection.title.text = "N/A";
			dummyPieChartStatsSection.title.validate();
			dummyPieChartStatsSection.message.text = "N/A";
			dummyPieChartStatsSection.message.validate();
			
			var sectionMultiplier:Number = 3;
			if (Constants.deviceModel == DeviceInfo.IPHONE_2G_3G_3GS_4_4S_ITOUCH_2_3_4)
				sectionMultiplier = 2.5;
			else if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr)
				sectionMultiplier = 3.1;
			
			pieChartHeight = (sectionMultiplier * dummyPieChartStatsSection.title.height) + (sectionMultiplier * dummyPieChartStatsSection.message.height);
			
			dummyPieChartStatsSection.dispose();
			dummyPieChartStatsSection = null;
			
			pieChartTotalHeight += pieChartHeight;
			
			return pieChartTotalHeight;
		}
		
		/**
		 * Event Handlers
		 */
		private function onCreation(event:Event):void
		{
			createChart();
			redrawChartForTreatmentsAndLine();
		}
		
		private function onBgReadingReceivedFollower(e:FollowerEvent):void
		{
			Trace.myTrace("ChartScreen.as", "on onBgReadingReceivedFollower!");
			
			if (!CGMBlueToothDevice.isFollower())
				Trace.myTrace("ChartScreen.as", "User is not a follower. Ignoring");
			
			try
			{
				var readings:Array = e.data;
				if (readings != null && readings.length > 0)
				{
					if (glucoseChart != null && SystemUtil.isApplicationActive)
					{
						glucoseChart.addGlucose(readings);
						
						if (displayPieChart && pieChart != null)
						{
							if (pieChart.currentPageName == BasicUserStats.PAGE_BG_DISTRIBUTION || pieChart.currentPageName == BasicUserStats.PAGE_VARIABILITY)
							{
								pieChart.updateStats(pieChart.getPageName());
							}
							
							if (pieChart.dummyModeActive || (pieChart.currentPageName != BasicUserStats.PAGE_BG_DISTRIBUTION && new Date().valueOf() - pieChart.lastGlucoseDistributionFetch >= TimeSpan.TIME_1_HOUR))
							{
								pieChart.updateStats(BasicUserStats.PAGE_BG_DISTRIBUTION);
							}
						}
					}
					else
					{
						newReadingsListFollower = newReadingsListFollower.concat(readings);
					}		
				}	
			} 
			catch(error:Error) 
			{
				Trace.myTrace("ChartScreen.as", "Error adding glucose to chart. Error: " + error.message);
			}
		}
		
		private function onBgReadingReceived(event:TransmitterServiceEvent):void
		{
			Trace.myTrace("ChartScreen.as", "in onBgReadingReceived!");
			
			if (CGMBlueToothDevice.isFollower())
			{
				Trace.myTrace("ChartScreen.as", "User is a follower. Ignoring");
				return;
			}
			
			try
			{
				if(Calibration.allForSensor().length < 2)
				{
					Trace.myTrace("ChartScreen.as", "Not enough calibrations. Not adding it to the chart.");
					return;
				}

				var latestAddedReading:BgReading = glucoseChart.getLatestReading();
				var timeStampLatestReading:Number = latestAddedReading == null ? 0 : latestAddedReading.timestamp;
				if (newReadingsList != null && newReadingsList.length > 0) 
					timeStampLatestReading = Math.max(timeStampLatestReading, (newReadingsList[newReadingsList.length - 1] as BgReading).timestamp);
				
				var cntr:int = ModelLocator.bgReadings.length - 1;
				while (cntr > -1) 
				{
					var bgReading:BgReading = ModelLocator.bgReadings[cntr] as BgReading;
					
					if (bgReading != null && bgReading.rawData != 0 && bgReading.calculatedValue != 0) 
					{
						if (bgReading.timestamp > timeStampLatestReading) 
						{
							//Add the reading to the beginning of the Array because we're looping ModelLocator in reverse order
							newReadingsList.push(bgReading); 
							
							if (glucoseChart != null && SystemUtil.isApplicationActive) 
								Trace.myTrace("ChartScreen.as", "Adding reading to the chart: Value: " + bgReading.calculatedValue);
							else
							{
								Trace.myTrace("ChartScreen.as", "Queuing reading to be rendered when Spike is in the foreground: Value: " + bgReading.calculatedValue);
							}
						} 
						else 
							break;
					}
					
					cntr--;
				}
				
				//Sort BgReadings by timestamp to ensure they are processed in the correct order.
				newReadingsList.sortOn(["timestamp"], Array.NUMERIC);
				
				if (SystemUtil.isApplicationActive && newReadingsList != null && newReadingsList.length > 0 && glucoseChart != null)
				{
					//Add readings to the chart and calculate display labels
					glucoseChart.addGlucose(newReadingsList);
					glucoseChart.calculateDisplayLabels();
					
					//Clear queue
					newReadingsList.length = 0;
					
					//Redraw Pie Chart
					if (displayPieChart && pieChart != null)
					{
						if (pieChart.currentPageName == BasicUserStats.PAGE_BG_DISTRIBUTION || pieChart.currentPageName == BasicUserStats.PAGE_VARIABILITY)
						{
							pieChart.updateStats(pieChart.getPageName());
						}
						
						if (pieChart.dummyModeActive || (pieChart.currentPageName != BasicUserStats.PAGE_BG_DISTRIBUTION && new Date().valueOf() - pieChart.lastGlucoseDistributionFetch >= TimeSpan.TIME_1_HOUR))
						{
							pieChart.updateStats(BasicUserStats.PAGE_BG_DISTRIBUTION);
						}
					}
				}
			} 
			catch(error:Error) 
			{
				Trace.myTrace("ChartScreen.as", "Error adding readings to chart. Error: " + error.message)
			}
		}
		
		private function onInitialCalibrationReceived(e:CalibrationServiceEvent):void
		{
			onBgReadingReceived(null);
		}
		
		private function onUpdateIOBCOB(e:TreatmentsEvent):void
		{
			if (glucoseChart == null || !SystemUtil.isApplicationActive)
				return;
			
			Trace.myTrace("ChartScreen.as", "Updating IOB/COB");
			
			var now:Number = new Date().valueOf();
			SystemUtil.executeWhenApplicationIsActive(glucoseChart.calculateTotalIOB, now);
			SystemUtil.executeWhenApplicationIsActive(glucoseChart.calculateTotalCOB, now);
		}
		
		private function onNewBasalData(e:TreatmentsEvent):void
		{
			if (glucoseChart == null || !SystemUtil.isApplicationActive)
				return;
			
			Trace.myTrace("ChartScreen.as", "Updating Basals");
			
			glucoseChart.renderBasals();
			
			if (pieChart != null && pieChart.currentPageName == BasicUserStats.PAGE_TREATMENTS)
			{
				clearTimeout(pieChartTreatmentUpdaterTimeout);
				
				pieChartTreatmentUpdaterTimeout = setTimeout( function():void 
				{
					if (pieChart == null) return;
					SystemUtil.executeWhenApplicationIsActive(pieChart.updateStats, BasicUserStats.PAGE_TREATMENTS);
				}, 1000 );
			}
		}
		
		private function onTreatmentAdded(e:TreatmentsEvent):void
		{
			var treatment:Treatment = e.treatment;
			if (treatment != null && glucoseChart != null)
			{
				Trace.myTrace("ChartScreen.as", "Adding treatment to the chart: Type: " + treatment.type);
				SystemUtil.executeWhenApplicationIsActive(glucoseChart.addTreatment, treatment);
				
				if (SystemUtil.isApplicationActive && pieChart != null && pieChart.currentPageName == BasicUserStats.PAGE_TREATMENTS && (treatment.insulinAmount > 0 || treatment.carbs > 0 || treatment.type == Treatment.TYPE_EXERCISE))
				{
					clearTimeout(pieChartTreatmentUpdaterTimeout);
					
					pieChartTreatmentUpdaterTimeout = setTimeout( function():void 
					{
						if (pieChart == null) return;
						SystemUtil.executeWhenApplicationIsActive(pieChart.updateStats, BasicUserStats.PAGE_TREATMENTS);
					}, 1000 );
				}
			}
		}
		
		private function onTreatmentExternallyModified(e:TreatmentsEvent):void
		{
			var treatment:Treatment = e.treatment;
			if (treatment != null && glucoseChart != null)
			{
				Trace.myTrace("ChartScreen.as", "Sending externally modified treatment to the chart: Type: " + treatment.type);
				SystemUtil.executeWhenApplicationIsActive(glucoseChart.updateExternallyModifiedTreatment, treatment);
				
				if (SystemUtil.isApplicationActive && pieChart != null && pieChart.currentPageName == BasicUserStats.PAGE_TREATMENTS && (treatment.insulinAmount > 0 || treatment.carbs > 0 || treatment.type == Treatment.TYPE_EXERCISE))
				{
					clearTimeout(pieChartTreatmentUpdaterTimeout);
					
					pieChartTreatmentUpdaterTimeout = setTimeout( function():void 
					{
						if (pieChart == null) return;
						SystemUtil.executeWhenApplicationIsActive(pieChart.updateStats, BasicUserStats.PAGE_TREATMENTS);
					}, 1000 );
				}
			}
		}
		
		private function onTreatmentExternallyDeleted(e:TreatmentsEvent):void
		{
			var treatment:Treatment = e.treatment;
			if (treatment != null && glucoseChart != null)
			{
				Trace.myTrace("ChartScreen.as", "Sending externally deleted treatment to the chart: Type: " + treatment.type);
				SystemUtil.executeWhenApplicationIsActive(glucoseChart.updateExternallyDeletedTreatment, treatment);
				
				if (SystemUtil.isApplicationActive && pieChart != null && pieChart.currentPageName == BasicUserStats.PAGE_TREATMENTS && (treatment.insulinAmount > 0 || treatment.carbs > 0 || treatment.type == Treatment.TYPE_EXERCISE))
				{
					clearTimeout(pieChartTreatmentUpdaterTimeout);
					
					pieChartTreatmentUpdaterTimeout = setTimeout( function():void 
					{
						if (pieChart == null) return;
						SystemUtil.executeWhenApplicationIsActive(pieChart.updateStats, BasicUserStats.PAGE_TREATMENTS);
					}, 1000 );
				}
			}
		}
		
		private function onTreatmentDeleted(e:TreatmentsEvent):void
		{
			var treatment:Treatment = e.treatment;
			if (treatment != null && glucoseChart != null)
			{
				if (SystemUtil.isApplicationActive && pieChart != null && pieChart.currentPageName == BasicUserStats.PAGE_TREATMENTS && (treatment.insulinAmount > 0 || treatment.carbs > 0 || treatment.type == Treatment.TYPE_EXERCISE))
				{
					clearTimeout(pieChartTreatmentUpdaterTimeout);
					
					pieChartTreatmentUpdaterTimeout = setTimeout( function():void 
					{
						if (pieChart == null) return;
						SystemUtil.executeWhenApplicationIsActive(pieChart.updateStats, BasicUserStats.PAGE_TREATMENTS);
					}, 1000 );
				}
			}
		}
		
		private function onAppInBackground (e:SpikeEvent):void
		{
			appInBackground = true;
		}
		
		private function onAppInForeground (e:SpikeEvent):void
		{
			SystemUtil.executeWhenApplicationIsActive( processQueue );
		}
		
		private function onTimeRangeChange(event:Event):void
		{
			var group:ToggleGroup = ToggleGroup( event.currentTarget );
			if (group.selectedIndex == 0)
			{
				//1H
				selectedTimelineRange = GlucoseChart.TIMELINE_1H;
				redrawChart();
			}
			else if (group.selectedIndex == 1)
			{
				//3H
				selectedTimelineRange = GlucoseChart.TIMELINE_3H;
				redrawChart();
			}
			else if (group.selectedIndex == 2)
			{
				//6H
				selectedTimelineRange = GlucoseChart.TIMELINE_6H;
				redrawChart();
			}
			else if (group.selectedIndex == 3)
			{
				//12H
				selectedTimelineRange = GlucoseChart.TIMELINE_12H;
				redrawChart();
			}
			else if (group.selectedIndex == 4)
			{
				//24H
				selectedTimelineRange = GlucoseChart.TIMELINE_24H;
				redrawChart();
			}
			
			//Save timerange in database
			if (Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_SELECTED_TIMELINE_RANGE)) != selectedTimelineRange)
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_CHART_SELECTED_TIMELINE_RANGE, String(selectedTimelineRange));
		}
		
		private function onDisplayLine(event:Event):void
		{
			var check:Check = Check( event.currentTarget );
			if(check.isSelected)
			{
				glucoseChart.showLine();
				drawLineChart = true;
			}
			else
			{
				glucoseChart.hideLine();
				drawLineChart = false;
			}
			
			//Save setting to database
			CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_CHART_DISPLAY_LINE, String(drawLineChart));
		}
		
		private function onDisplayRaw(event:Event):void
		{
			var check:Check = Check( event.currentTarget );
			if(check.isSelected)
			{
				glucoseChart.showRaw();
				displayRawData = true;
			}
			else
			{
				glucoseChart.hideRaw()
				displayRawData = false;
			}
			
			//Save setting to database
			CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_CHART_DISPLAY_RAW_ON, String(displayRawData));
		}
		
		private function onStarlingResize(event:ResizeEvent):void 
		{
			SystemUtil.executeWhenApplicationIsActive(disposeDisplayObjects);
			SystemUtil.executeWhenApplicationIsActive(createChart);
		}
		
		override protected function onTransitionInComplete(e:Event):void
		{
			//Swipe to pop functionality
			AppInterface.instance.navigator.isSwipeToPopEnabled = false;
		}
		
		/**
		 * Utility
		 */
		private function disposeDisplayObjects():void
		{
			/* Display Objects */
			if (glucoseChart != null)
			{
				glucoseChart.removeFromParent();
				glucoseChart.dispose();
				glucoseChart = null;
			}
			
			if (pieChart != null)
			{
				pieChart.removeFromParent();
				pieChart.dispose();
				pieChart = null;
			}
			
			if (timeRangeGroup != null)
			{
				timeRangeGroup.removeEventListener( Event.CHANGE, onTimeRangeChange );
				timeRangeGroup = null;
			}
			
			if (h24 != null)
			{
				h24.removeFromParent();
				h24.dispose();
				h24 = null;
			}
			
			if (h12 != null)
			{
				h12.removeFromParent();
				h12.dispose();
				h12 = null;
			}
			
			if (h6 != null)
			{
				h6.removeFromParent();
				h6.dispose();
				h6 = null;
			}
			
			if (h3 != null)
			{
				h3.removeFromParent();
				h3.dispose();
				h3 = null;
			}
			
			if (h1 != null)
			{
				h1.removeFromParent();
				h1.dispose();
				h1 = null;
			}
			
			if (displayLines != null)
			{
				displayLines.removeEventListener( Event.CHANGE, onDisplayLine );
				displayLines.removeFromParent();
				displayLines.dispose();
				displayLines = null;
			}
			
			if (displayRawCheck != null)
			{
				displayRawCheck.removeEventListener( Event.CHANGE, onDisplayRaw );
				displayRawCheck.removeFromParent();
				displayRawCheck.dispose();
				displayRawCheck = null;
			}
			
			if (delimitter != null)
			{
				delimitter.removeFromParent();
				delimitter.dispose();
				delimitter = null;
			}
		}
		
		override public function dispose():void
		{
			/* Timers */
			clearTimeout(redrawChartTimeoutID);
			clearTimeout(pieChartTreatmentUpdaterTimeout);
			clearTimeout(queueTimeout);

			/* Event Listeners */
			Spike.instance.removeEventListener(SpikeEvent.APP_IN_BACKGROUND, onAppInBackground);
			Spike.instance.removeEventListener(SpikeEvent.APP_IN_FOREGROUND, onAppInForeground);
			TransmitterService.instance.removeEventListener(TransmitterServiceEvent.LAST_BGREADING_RECEIVED, onBgReadingReceived);
			CalibrationService.instance.removeEventListener(CalibrationServiceEvent.INITIAL_CALIBRATION_EVENT, onInitialCalibrationReceived);
			NightscoutService.instance.removeEventListener(FollowerEvent.BG_READING_RECEIVED, onBgReadingReceivedFollower);
			DexcomShareService.instance.removeEventListener(FollowerEvent.BG_READING_RECEIVED, onBgReadingReceivedFollower);
			removeEventListener(FeathersEventType.CREATION_COMPLETE, onCreation);
			TreatmentsManager.instance.removeEventListener(TreatmentsEvent.TREATMENT_ADDED, onTreatmentAdded);
			TreatmentsManager.instance.removeEventListener(TreatmentsEvent.TREATMENT_EXTERNALLY_MODIFIED, onTreatmentExternallyModified);
			TreatmentsManager.instance.removeEventListener(TreatmentsEvent.TREATMENT_EXTERNALLY_DELETED, onTreatmentExternallyDeleted);
			TreatmentsManager.instance.addEventListener(TreatmentsEvent.TREATMENT_DELETED, onTreatmentDeleted);
			TreatmentsManager.instance.removeEventListener(TreatmentsEvent.IOB_COB_UPDATED, onUpdateIOBCOB);
			TreatmentsManager.instance.removeEventListener(TreatmentsEvent.NEW_BASAL_DATA, onNewBasalData);
			Starling.current.stage.removeEventListener(starling.events.Event.RESIZE, onStarlingResize);
			
			/* Display Objects */
			SystemUtil.executeWhenApplicationIsActive(disposeDisplayObjects);
			
			/* Objects */
			if (chartData != null)
			{
				chartData.length = 0;
				chartData = null;
			}
			
			if (newReadingsList != null)
			{
				newReadingsList.length = 0;
				newReadingsList = null;
			}
			
			super.dispose();
			
			System.pauseForGCIfCollectionImminent(0);
		}
	}
}