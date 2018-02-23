package ui.screens
{
	import flash.system.System;
	
	import database.BgReading;
	import database.BlueToothDevice;
	import database.Calibration;
	import database.CommonSettings;
	
	import events.FollowerEvent;
	import events.SpikeEvent;
	import events.TransmitterServiceEvent;
	
	import feathers.controls.Check;
	import feathers.controls.Radio;
	import feathers.controls.ScrollBarDisplayMode;
	import feathers.controls.ScrollPolicy;
	import feathers.controls.TextInput;
	import feathers.core.ToggleGroup;
	import feathers.events.FeathersEventType;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import services.NightscoutService;
	import services.TransmitterService;
	
	import starling.core.Starling;
	import starling.display.Shape;
	import starling.events.Event;
	
	import ui.chart.DistributionChart;
	import ui.chart.GlucoseChart;
	import ui.chart.GraphLayoutFactory;
	import ui.screens.display.LayoutFactory;
	
	import utils.Constants;
	import utils.DeviceInfo;
	import utils.Trace;
	
	[ResourceBundle("chartscreen")]

	public class ChartScreen extends BaseScreen
	{
		//Objects
		private var chartData:Array;
		private var newReadingsList:Array = [];
		
		//Visual variables
		private var glucoseChartTopPadding:int = 7;
		private var selectedTimelineRange:Number;
		private var drawLineChart:Boolean;
		private var mainChartHeight:Number;
		private var scrollChartHeight:Number;
		private var availableScreenHeight:Number;
		private var chartSettingsLeftRightPadding:int = 10;
		private var chartSettingsTopPadding:int = 10;
		private var delimitterTopPadding:int = 10;
		private var displayPieChart:Boolean;
		
		//Logical Variables
		private var chartRequiresReload:Boolean = true;
		private var appInBackground:Boolean = false;
		
		//Display Objects
		private var glucoseChart:GlucoseChart;
		private var pieChart:DistributionChart;
		private var glucoseAmount:TextInput;
		private var h24:Radio;
		private var h12:Radio;
		private var h6:Radio;
		private var h3:Radio;
		private var h1:Radio;
		private var displayLines:Check;
		
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
			
			//Event listeners
			addEventListener(FeathersEventType.CREATION_COMPLETE, onCreation);
			Spike.instance.addEventListener(SpikeEvent.APP_IN_BACKGROUND, onAppInBackground, false, 0, true);
			Spike.instance.addEventListener(SpikeEvent.APP_IN_FOREGROUND, onAppInForeground, false, 0, true);
			TransmitterService.instance.addEventListener(TransmitterServiceEvent.BGREADING_EVENT, onBgReadingReceived, false, 0, true);
			NightscoutService.instance.addEventListener(FollowerEvent.BG_READING_RECEIVED, onBgReadingReceivedFollower, false, 0, true);
			
			//Scroll Policies
			scrollBarDisplayMode = ScrollBarDisplayMode.NONE;
			horizontalScrollPolicy = ScrollPolicy.OFF;
			verticalScrollPolicy = ScrollPolicy.OFF;
		}
		
		/**
		 * Functionality
		 */
		private function setGlucoseChart():void
		{
			availableScreenHeight = Constants.stageHeight - this.header.height;
			scrollChartHeight = availableScreenHeight / 10; //10% of available screen size
			
			if (displayPieChart)
				if (DeviceInfo.getDeviceType() == DeviceInfo.IPHONE_2G_3G_3GS_4_4S_ITOUCH_2_3_4)
					mainChartHeight = availableScreenHeight * 0.39; //39% of available screen size
				else if (DeviceInfo.getDeviceType() == DeviceInfo.IPHONE_5_5S_5C_SE_ITOUCH_5_6)
					mainChartHeight = availableScreenHeight * 0.5; //50% of available screen size
				else if (DeviceInfo.getDeviceType() == DeviceInfo.IPHONE_6_6S_7_8 || DeviceInfo.getDeviceType() == DeviceInfo.IPHONE_6PLUS_6SPLUS_7PLUS_8PLUS)
					mainChartHeight = availableScreenHeight * 0.51; //51% of available screen size
				else if (DeviceInfo.getDeviceType() == DeviceInfo.IPHONE_X)
					mainChartHeight = availableScreenHeight * 0.55; //55% of available screen size
				else if (DeviceInfo.getDeviceType() == DeviceInfo.IPAD_1_2_3_4_5_AIR1_2_PRO_97)
					mainChartHeight = availableScreenHeight * 0.615; //61.5% of available screen size
				else if (DeviceInfo.getDeviceType() == DeviceInfo.IPAD_PRO_105)
					mainChartHeight = availableScreenHeight * 0.62; //62% of available screen size
				else if (DeviceInfo.getDeviceType() == DeviceInfo.IPAD_PRO_129)
					mainChartHeight = availableScreenHeight * 0.66; //66% of available screen size
				else if (DeviceInfo.getDeviceType() == DeviceInfo.IPAD_MINI_1_2_3_4)
					mainChartHeight = availableScreenHeight * 0.52; //52% of available screen size
				else
					mainChartHeight = availableScreenHeight * 0.5; //50% of available screen size
			else
				mainChartHeight = calculateChartHeight();
			
			//CHART
			//Get glucose data;
			chartData = ModelLocator.bgReadings.concat();
			
			//Create and setup glucose chart
			//3h
			glucoseChart = new GlucoseChart(selectedTimelineRange, stage.stageWidth, mainChartHeight, stage.stageWidth, scrollChartHeight);
			glucoseChart.y = Math.round(glucoseChartTopPadding);
			glucoseChart.dataSource = chartData;
			glucoseChart.displayLine = drawLineChart;
			glucoseChart.drawGraph();
			addChild(glucoseChart);
			
			//Prevents Starling Line Mask Bug
			if(drawLineChart)
			{
				Starling.juggler.delayCall(redrawChart, 0.001);
				chartRequiresReload = false;
			}
		}
		
		private function setChartSettings():void
		{
			/* Line Settings */
			displayLines = LayoutFactory.createCheckMark(false, ModelLocator.resourceManagerInstance.getString('chartscreen','check_box_line_title'));
			if (DeviceInfo.getDeviceType() == DeviceInfo.IPHONE_X)
				displayLines.scale = 0.8;
			displayLines.isSelected = drawLineChart;
			displayLines.addEventListener( Event.CHANGE, onDisplayLine );
			addChild( displayLines );
			
			/* Timeline Settings */
			var timeRangeGroup:ToggleGroup = new ToggleGroup();
			
			//Create Radios
			h1 = LayoutFactory.createRadioButton(ModelLocator.resourceManagerInstance.getString('chartscreen','radio_button_1h_title'), timeRangeGroup);
			if (DeviceInfo.getDeviceType() == DeviceInfo.IPHONE_X)
				h1.scale = 0.8;
			addChild( h1 );
			h3 = LayoutFactory.createRadioButton(ModelLocator.resourceManagerInstance.getString('chartscreen','radio_button_3h_title'), timeRangeGroup);
			if (DeviceInfo.getDeviceType() == DeviceInfo.IPHONE_X)
				h3.scale = 0.8;
			addChild( h3 );
			h6 = LayoutFactory.createRadioButton(ModelLocator.resourceManagerInstance.getString('chartscreen','radio_button_6h_title'), timeRangeGroup);
			if (DeviceInfo.getDeviceType() == DeviceInfo.IPHONE_X)
				h6.scale = 0.8;
			addChild( h6 );
			h12 = LayoutFactory.createRadioButton(ModelLocator.resourceManagerInstance.getString('chartscreen','radio_button_12h_title'), timeRangeGroup);
			if (DeviceInfo.getDeviceType() == DeviceInfo.IPHONE_X)
				h12.scale = 0.8;
			addChild( h12 );
			h24 = LayoutFactory.createRadioButton(ModelLocator.resourceManagerInstance.getString('chartscreen','radio_button_24h_title'), timeRangeGroup);
			if (DeviceInfo.getDeviceType() == DeviceInfo.IPHONE_X)
				h24.scale = 0.8;
			h24.addEventListener(FeathersEventType.CREATION_COMPLETE, onRadioCreation);
			addChild( h24 );
			
			//Calculate selected radio
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
		
		private function redrawChart():void
		{
			//var previousData:Array = glucoseChart.dataSource.concat();
			chartData = glucoseChart.dataSource;
			
			//Remove previous chart
			removeChild(glucoseChart);
			glucoseChart.dispose();
			glucoseChart = null;
			
			//Create new chart
			glucoseChart = new GlucoseChart(selectedTimelineRange, stage.stageWidth, mainChartHeight, stage.stageWidth, scrollChartHeight);
			//glucoseChart.dataSource = previousData.concat();
			glucoseChart.dataSource = chartData;
			glucoseChart.displayLine = drawLineChart;
			glucoseChart.drawGraph();
			glucoseChart.y = glucoseChartTopPadding;
			addChild(glucoseChart);
			
			//previousData.length = 0;
			//previousData = null;
		}
		
		private function calculateChartHeight():Number
		{
			//Calculate Multipliers
			var userGlucoseFontMultiplier:Number = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_BG_FONT_SIZE));
			var userTimeAgoFontMultiplier:Number = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_TIMEAGO_FONT_SIZE));
			var higherMultiplier:Number;
			if (userGlucoseFontMultiplier >= userTimeAgoFontMultiplier)
				higherMultiplier = userGlucoseFontMultiplier;
			else
				higherMultiplier = userTimeAgoFontMultiplier;
			
			//Chart Top Margin
			var topMargin:int = Math.round(glucoseChartTopPadding);
			
			//Main Chart Internal Top Padding
			var chartDisplayMargin:Number = 50 * higherMultiplier;
			
			//Scroller Internal Top Padding
			var scrollerTopPadding:int = 5;
			
			//Settings (Radio Buttons Height)
			var settingsHeight:int = 20;
			
			//Calculate Device Specific Adjustment
			var deviceAdjustement:Number;
			if (DeviceInfo.getDeviceType() == DeviceInfo.IPHONE_2G_3G_3GS_4_4S_ITOUCH_2_3_4)
				deviceAdjustement = 0;
			else if (DeviceInfo.getDeviceType() == DeviceInfo.IPHONE_5_5S_5C_SE_ITOUCH_5_6)
				deviceAdjustement = 6 * higherMultiplier;
			else if (DeviceInfo.getDeviceType() == DeviceInfo.IPHONE_6_6S_7_8)
				deviceAdjustement = 12 * higherMultiplier;
			else if (DeviceInfo.getDeviceType() == DeviceInfo.IPHONE_6PLUS_6SPLUS_7PLUS_8PLUS)
				deviceAdjustement = 20 * higherMultiplier;
			else if (DeviceInfo.getDeviceType() == DeviceInfo.IPHONE_X)
				deviceAdjustement = 35 * higherMultiplier;
			
			//Return Calculated Chart Height
			return availableScreenHeight - topMargin - chartDisplayMargin - scrollerTopPadding - scrollChartHeight - chartSettingsTopPadding - settingsHeight - deviceAdjustement;
		}
		
		/**
		 * Event Handlers
		 */
		private function onBgReadingReceivedFollower(e:FollowerEvent):void
		{
			Trace.myTrace("ChartScreen.as", "on onBgReadingReceivedFollower!");
			
			if (!BlueToothDevice.isFollower())
				Trace.myTrace("ChartScreen.as", "User is not a follower. Ignoring");
				
			var readings:Array = e.data;
			if (readings != null && readings.length > 0)
			{
				glucoseChart.addGlucose(readings);
				if (displayPieChart)
					pieChart.drawChart()
			}	
		}
		
		private function onBgReadingReceived(event:TransmitterServiceEvent):void
		{
			Trace.myTrace("ChartScreen.as", "on onBgReadingReceived!");
			
			if (BlueToothDevice.isFollower())
				Trace.myTrace("ChartScreen.as", "User is a follower. Ignoring");
			
			var reading:BgReading = BgReading.lastNoSensor();
			
			if(reading == null || Calibration.allForSensor().length < 2)
			{
				Trace.myTrace("ChartScreen.as", "Bad Reading or not enough calibrations. Not adding it to the chart.");
				return;
			}
			
			if (!appInBackground && glucoseChart != null)
			{
				Trace.myTrace("ChartScreen.as", "Adding reading to the chart: Value: " + reading.calculatedValue);
				glucoseChart.addGlucose([reading]);
				if (displayPieChart)
					pieChart.drawChart();
			}
			else
			{
				Trace.myTrace("ChartScreen.as", "Adding reading to the queue. Will be rendered when the app is in the foreground. Reading: " + reading.calculatedValue);
				newReadingsList.push(reading);
			}
		}
		
		private function onAppInBackground (e:SpikeEvent):void
		{
			appInBackground = true;
		}
		
		private function onAppInForeground (e:SpikeEvent):void
		{
			if (appInBackground)
			{
				appInBackground = false;
				
				if (newReadingsList != null && newReadingsList.length > 0)
				{
					glucoseChart.addGlucose(newReadingsList);
					
					if (displayPieChart)
						pieChart.drawChart();
					
					newReadingsList.length = 0;
				}
				else
					glucoseChart.calculateDisplayLabels();
			}
		}
		
		private function onCreation(event:Event):void
		{
			setGlucoseChart();
			setChartSettings();
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
		
		private function onRadioCreation(event:Event):void
		{
			//Position Radio Buttons
			var paddingMultiplier:Number = DeviceInfo.getHorizontalPaddingMultipier();
			
			h24.x = stage.stageWidth - h24.width - chartSettingsLeftRightPadding;
			h24.y = glucoseChart.y + glucoseChart.height + chartSettingsTopPadding;
			
			h12.x = h24.x - h12.width - (chartSettingsLeftRightPadding * paddingMultiplier);
			h12.y = h24.y;
			
			h6.x = h12.x - h6.width - (chartSettingsLeftRightPadding * paddingMultiplier);
			h6.y = h24.y;
			
			h3.x = h6.x - h3.width - (chartSettingsLeftRightPadding * paddingMultiplier);
			h3.y = h24.y;
			
			h1.x = h3.x - h1.width - (chartSettingsLeftRightPadding * paddingMultiplier);
			h1.y = h24.y;
			
			displayLines.x = chartSettingsLeftRightPadding;
			displayLines.y = h24.y;
			
			//Add 24H Glucose distributon to the screen
			if (displayPieChart)
			{
				var delimitter:Shape = GraphLayoutFactory.createHorizontalLine(Constants.stageWidth, 1, 0x282a32);
				delimitter.y = h24.y + h24.height + delimitterTopPadding;
				addChild(delimitter);
				
				var lastAvailableSpace:Number = availableScreenHeight - glucoseChartTopPadding - glucoseChart.height - chartSettingsTopPadding - h24.height - delimitterTopPadding - delimitter.height;
				var pieHeight:Number = (lastAvailableSpace * 0.8) / 2; //80% of availables space
				var pieTopPadding:Number = Math.round((lastAvailableSpace * 0.3) / 2);
				
				//Pie Chart
				//pieChart = new DistributionChart(pieHeight, glucoseChart.dataSource);
				pieChart = new DistributionChart(pieHeight, chartData);
				pieChart.y = Math.round(h24.y + h24.height + delimitterTopPadding + delimitter.height + pieTopPadding);
				pieChart.x = 10;
				addChild(pieChart);
			}
		}
		
		private function onDisplayLine(event:Event):void
		{
			var check:Check = Check( event.currentTarget );
			if(check.isSelected)
			{
				glucoseChart.showLine();
				drawLineChart = true;
				if(chartRequiresReload)
				{
					chartRequiresReload = false;
					redrawChart();
				}
			}
			else
			{
				glucoseChart.hideLine();
				drawLineChart = false;
			}
			
			//Save setting to database
			if (drawLineChart)
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_CHART_DISPLAY_LINE, "true");
			else
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_CHART_DISPLAY_LINE, "false");
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			/* Event Listeners */
			Spike.instance.removeEventListener(SpikeEvent.APP_IN_BACKGROUND, onAppInBackground);
			Spike.instance.removeEventListener(SpikeEvent.APP_IN_FOREGROUND, onAppInForeground);
			TransmitterService.instance.removeEventListener(TransmitterServiceEvent.BGREADING_EVENT, onBgReadingReceived);
			removeEventListener(FeathersEventType.CREATION_COMPLETE, onCreation);
			
			/* Objects */
			chartData.length = 0;
			chartData = null;
			newReadingsList.length = 0;
			newReadingsList = null;
			
			/* Display Objects */
			if (glucoseChart != null)
			{
				removeChild(glucoseChart);
				glucoseChart.dispose();
				glucoseChart = null;
			}
			
			if (pieChart != null)
			{
				removeChild(pieChart);
				pieChart.dispose();
				pieChart = null;
			}
			
			if (h24 != null)
			{
				h24.removeEventListener(FeathersEventType.CREATION_COMPLETE, onRadioCreation);
				removeChild(h24);
				h24.dispose();
				h24 = null;
			}
			
			if (h12 != null)
			{
				removeChild(h12);
				h12.dispose();
				h12 = null;
			}
			
			if (h6 != null)
			{
				removeChild(h6);
				h6.dispose();
				h6 = null;
			}
			
			if (h3 != null)
			{
				removeChild(h3);
				h3.dispose();
				h3 = null;
			}
			
			if (h1 != null)
			{
				removeChild(h1);
				h1.dispose();
				h1 = null;
			}
			
			if (displayLines != null)
			{
				displayLines.removeEventListener( Event.CHANGE, onDisplayLine );
				removeChild(displayLines);
				displayLines.dispose();
				displayLines = null;
			}
			
			super.dispose();
			
			System.pauseForGCIfCollectionImminent(0);
		}
	}
}