package screens
{
	import chart.GlucoseChart;
	import chart.GraphLayoutFactory;
	import chart.PieChart;
	
	import databaseclasses.BgReading;
	import databaseclasses.Calibration;
	import databaseclasses.CommonSettings;
	import databaseclasses.Sensor;
	
	import display.LayoutFactory;
	
	import events.IosXdripReaderEvent;
	import events.TransmitterServiceEvent;
	
	import feathers.controls.Button;
	import feathers.controls.Check;
	import feathers.controls.Radio;
	import feathers.controls.ScrollBarDisplayMode;
	import feathers.controls.ScrollPolicy;
	import feathers.controls.TextInput;
	import feathers.core.ToggleGroup;
	import feathers.events.FeathersEventType;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import services.TransmitterService;
	
	import starling.core.Starling;
	import starling.display.Shape;
	import starling.events.Event;
	
	import utils.Constants;
	import utils.DeviceInfo;
	import utils.TimeSpan;
	
	[ResourceBundle("chartscreen")]

	public class ChartScreen extends BaseScreen
	{
		//Objects
		private var chartData:Array;
		
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
		
		//Display Objects
		private var glucoseChart:GlucoseChart;
		private var pieChart:PieChart;
		private var glucoseAmount:TextInput;
		private var h24:Radio;
		private var h12:Radio;
		private var h6:Radio;
		private var h3:Radio;
		private var h1:Radio;
		private var displayLines:Check;
		
		
		//Test
		private var testReading:BgReading;

		private var appInBackground:Boolean = false;
		private var newReadingsList:Array = [];

		private var now:Number;

		private var minutes:Number = 0;
		
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
			displayPieChart = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_DISPLAY_PIE_CHART) == "true";
			
			//Event listeners
			this.addEventListener(FeathersEventType.CREATION_COMPLETE, onCreation);
			iOSDrip.instance.addEventListener(IosXdripReaderEvent.APP_IN_BACKGROUND, onAppInBackground);
			iOSDrip.instance.addEventListener(IosXdripReaderEvent.APP_IN_FOREGROUND, onAppInForeground);
			TransmitterService.instance.addEventListener(TransmitterServiceEvent.BGREADING_EVENT, onBgReadingReceived);
			
			//Scroll Policies
			this.scrollBarDisplayMode = ScrollBarDisplayMode.NONE;
			this.horizontalScrollPolicy = ScrollPolicy.OFF;
			this.verticalScrollPolicy = ScrollPolicy.OFF;
			
			
		}
		
		private function onBgReadingReceived(event:TransmitterServiceEvent):void
		{
			if(BgReading.lastNoSensor() == null)
				return;
			
			if (!appInBackground && glucoseChart != null)
			{
				glucoseChart.addGlucose([BgReading.lastNoSensor()]);
				if (displayPieChart)
					pieChart.drawChart();
			}
			else
				newReadingsList.push(BgReading.lastNoSensor());
		}
		
		private function onAppInBackground (e:IosXdripReaderEvent):void
		{
			appInBackground = true;
		}
		
		private function onAppInForeground (e:IosXdripReaderEvent):void
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
			}
		}
		
		private function onCreation(event:Event):void
		{
			setGlucoseChart();
			setChartSettings();
			
			/**
			 * DEBUG
			 */
			setDebugObjects();
		}
		
		private function setDebugObjects():void
		{
			var addGlucoseBTN:Button = LayoutFactory.createButton("ADD");
			addGlucoseBTN.y = 150;
			addGlucoseBTN.x = 20;
			//addChild(addGlucoseBTN);
			addGlucoseBTN.addEventListener(Event.TRIGGERED, onAddGlucose);
			
			function onAddGlucose():void
			{
				var latestBGReading:BgReading = BgReading.lastNoSensor();
				var testBGReading:BgReading;
				if (latestBGReading != null)
				{
					testBGReading = new BgReading
					(
						new Date().valueOf(),
						latestBGReading.sensor,
						latestBGReading.calibration,
						latestBGReading.rawData,
						latestBGReading.filteredData,
						latestBGReading.ageAdjustedRawValue,
						latestBGReading.calibrationFlag,
						(Math.random() * 40) + 60,
						latestBGReading.filteredCalculatedValue,
						latestBGReading.calculatedValueSlope,
						latestBGReading.a,
						latestBGReading.b,
						latestBGReading.c,
						latestBGReading.ra,
						latestBGReading.rb,
						latestBGReading.rb,
						latestBGReading.rawCalculated,
						latestBGReading.hideSlope,
						latestBGReading.noise,
						latestBGReading.lastModifiedTimestamp,
						String(Math.random() * 10)
					);
				}
				else
				{
					var sensor:Sensor = new Sensor(1232,1234, 232, "123", 1234);
					var testDateDate:Date = TimeSpan.fromMinutes(minutes).add(new Date());
					minutes += 5;
					testBGReading = new BgReading
					(
						(new Date()).valueOf(),
						sensor,
						new Calibration(323, 32, sensor, 66, 66, 66, 1, 1, 2324, 1, 1, 1, 1, 66, false, false, 23, 323, 323, 323, 323, 323, 323, 323, 32424, "3542352"),
						66,
						66,
						66,
						false,
						(Math.random() * 40) + 60,
						66,
						1,
						2,
						2,
						2,
						2,
						2,
						66,
						32,
						false,
						"1",
						22424,
						"wffw"
					);
				};
					
				glucoseChart.addGlucose([testBGReading]);
			}
		}
		
		/**
		 * Functionality
		 */
		private function setGlucoseChart():void
		{
			
			availableScreenHeight = Constants.stageHeight - this.header.height;
			scrollChartHeight = availableScreenHeight / 10; //10% of available screen size
			if (displayPieChart)
				mainChartHeight = availableScreenHeight / 2; //50% of available screen size
			else
			{
				mainChartHeight = calculateChartHeight();
			}
			
			//CHART
			//Get glucose data;
			chartData = ModelLocator.bgReadings.toArray();
			
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
			displayLines.isSelected = drawLineChart;
			displayLines.addEventListener( Event.CHANGE, onDisplayLine );
			addChild( displayLines );
			
			/* Timeline Settings */
			var timeRangeGroup:ToggleGroup = new ToggleGroup();
			
			//Create Radios
			h1 = LayoutFactory.createRadioButton(ModelLocator.resourceManagerInstance.getString('chartscreen','radio_button_1h_title'), timeRangeGroup);
			addChild( h1 );
			h3 = LayoutFactory.createRadioButton(ModelLocator.resourceManagerInstance.getString('chartscreen','radio_button_3h_title'), timeRangeGroup);
			addChild( h3 );
			h6 = LayoutFactory.createRadioButton(ModelLocator.resourceManagerInstance.getString('chartscreen','radio_button_6h_title'), timeRangeGroup);
			addChild( h6 );
			h12 = LayoutFactory.createRadioButton(ModelLocator.resourceManagerInstance.getString('chartscreen','radio_button_12h_title'), timeRangeGroup);
			addChild( h12 );
			h24 = LayoutFactory.createRadioButton(ModelLocator.resourceManagerInstance.getString('chartscreen','radio_button_24h_title'), timeRangeGroup);
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
		
		/**
		 * Event Handlers
		 */
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
			
			if (displayPieChart)
			{
				var delimitter:Shape = GraphLayoutFactory.createHorizontalLine(Constants.stageWidth, 1, 0x282a32);
				delimitter.y = h24.y + h24.height + delimitterTopPadding;
				addChild(delimitter);
				
				var lastAvailableSpace:Number = availableScreenHeight - glucoseChartTopPadding - glucoseChart.height - chartSettingsTopPadding - h24.height - delimitterTopPadding - delimitter.height;
				var pieHeight:Number = (lastAvailableSpace * 0.8) / 2; //80% of availables space
				var pieTopPadding:Number = Math.round((lastAvailableSpace * 0.3) / 2);
				
				//Pie Chart
				pieChart = new PieChart(pieHeight, glucoseChart.dataSource);
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
		public function redrawChart():void
		{
			var previousData:Array = glucoseChart.dataSource.concat();
			
			//Remove previous chart
			removeChild(glucoseChart);
			glucoseChart.dispose();
			glucoseChart = null;
			
			//Create new chart
			glucoseChart = new GlucoseChart(selectedTimelineRange, stage.stageWidth, mainChartHeight, stage.stageWidth, scrollChartHeight);
			glucoseChart.dataSource = previousData.concat();
			glucoseChart.displayLine = drawLineChart;
			glucoseChart.drawGraph();
			glucoseChart.y = glucoseChartTopPadding;
			addChild(glucoseChart);
			
			previousData.length = 0;
			previousData = null;
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
			if (DeviceInfo.getDeviceType() == DeviceInfo.IPHONE_4_4S)
				deviceAdjustement = 0;
			else if (DeviceInfo.getDeviceType() == DeviceInfo.IPHONE_5_5S_5C_SE)
				deviceAdjustement = 6 * higherMultiplier;
			else if (DeviceInfo.getDeviceType() == DeviceInfo.IPHONE_6_6S_7_8)
				deviceAdjustement = 12 * higherMultiplier;
			else if (DeviceInfo.getDeviceType() == DeviceInfo.IPHONE_6PLUS_6SPLUS_7PLUS_8PLUS)
				deviceAdjustement = 20 * higherMultiplier;
			else if (DeviceInfo.getDeviceType() == DeviceInfo.IPHONE_X || DeviceInfo.getDeviceType() == DeviceInfo.TABLET)
				deviceAdjustement = 35 * higherMultiplier;
			
			//Return Calculated Chart Height
			return availableScreenHeight - topMargin - chartDisplayMargin - scrollerTopPadding - scrollChartHeight - chartSettingsTopPadding - settingsHeight - deviceAdjustement;
		}
	}
}