package ui.screens
{
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.system.System;
	import flash.utils.Timer;
	
	import database.BgReading;
	import database.BlueToothDevice;
	import database.CommonSettings;
	
	import events.FollowerEvent;
	import events.TransmitterServiceEvent;
	
	import feathers.controls.Label;
	import feathers.controls.LayoutGroup;
	import feathers.layout.AnchorLayout;
	import feathers.layout.AnchorLayoutData;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalAlign;
	import feathers.layout.VerticalLayout;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.ModelLocator;
	
	import services.NightscoutService;
	import services.TransmitterService;
	
	import starling.display.DisplayObject;
	import starling.utils.Align;
	
	import ui.AppInterface;
	import ui.chart.GlucoseFactory;
	import ui.chart.GraphLayoutFactory;
	import ui.screens.display.LayoutFactory;
	
	import utils.Constants;
	import utils.DeviceInfo;
	import utils.TimeSpan;
	
	[ResourceBundle("fullscreenglucosescreen")]

	public class FullScreenGlucoseScreen extends BaseSubScreen
	{
		/* Constants */
		private const TIME_6_MINUTES:int = 6 * 60 * 1000;
		private const TIME_16_MINUTES:int = 16 * 60 * 1000;
		
		/* Display Objects */
		private var glucoseDisplay:Label;
		private var slopeArrowDisplay:Label;
		private var timeAgoDisplay:Label;
		private var slopeDisplay:Label;
		private var container:LayoutGroup;

		/* Properties */
		private var oldColor:uint = 0xababab;
		private var newColor:uint = 0xEEEEEE;
		private var glucoseFontSize:Number;
		private var infoFontSize:Number;
		private var deltaFontSize:Number;
		private var glucoseList:Array;
		private var latestGlucoseValue:Number;
		private var latestGlucoseOutput:String;
		private var latestGlucoseTimestamp:Number = 0;
		private var latestGlucoseColor:uint;
		private var latestGlucoseSlopeArrow:String;
		private var previousGlucoseValue:Number;
		private var previousGlucoseTimestamp:Number = 0;
		private var glucoseUnit:String;
		private var updateTimer:Timer;
		private var latestGlucoseSlopeOutput:String;
		private var userBGFontMultiplier:Number;
		private var userTimeAgoFontMultiplier:Number;
		private var timeAgoOutput:String;
		private var timeAgoColor:uint;
		private var latestSlopeInfoColor:uint;
		private var latestSlopeArrowColor:uint;
		private var nowTimestamp:Number;
		private var latestGlucoseProperties:Object;
		private var latestGlucoseValueFormatted:Number;
		private var previousGlucoseValueFormatted:Number;
		
		public function FullScreenGlucoseScreen() 
		{
			super();
			styleNameList.add( BaseMaterialDeepGreyAmberMobileTheme.THEME_STYLE_NAME_HEADER_WITH_SHADOW );
			styleNameList.add( BaseMaterialDeepGreyAmberMobileTheme.THEME_STYLE_NAME_PANEL_WITHOUT_PADDING );
		}
		
		override protected function initialize():void 
		{
			super.initialize();
			
			setupHeader();
			setupLayout();
			setupInitialContent();
			setupContent();
			setupEventListeners();
			adjustMainMenu();
		}
		
		/**
		 * Functionality
		 */
		private function setupHeader():void
		{
			/* Set Header Title */
			title = ModelLocator.resourceManagerInstance.getString('fullscreenglucosescreen','screen_title');
			
			/* Set Header Icon */
			icon = getScreenIcon(MaterialDeepGreyAmberMobileThemeIcons.fullscreenTexture);
			iconContainer = new <DisplayObject>[icon];
			headerProperties.rightItems = iconContainer;
		}
		
		private function setupInitialContent():void
		{			
			//Glucose Unit
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true") 
				glucoseUnit = "mg/dl";
			else
				glucoseUnit = "mmol/L";
			
			//Font Size
			userBGFontMultiplier = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_BG_FONT_SIZE));
			userTimeAgoFontMultiplier = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_TIMEAGO_FONT_SIZE));
		
			//Latest 2 BgReadings
			glucoseList = BgReading.latest(2, BlueToothDevice.isFollower()).reverse();
			
			//Calculate Values
			calculateValues();
		}
		
		
		private function setupContent():void
		{
			/* Determine Font Sizes */
			calculateFontSize();
			
			/* Glucose Display Label */
			glucoseDisplay = LayoutFactory.createLabel(latestGlucoseOutput, HorizontalAlign.CENTER, VerticalAlign.MIDDLE, glucoseFontSize, true);
			glucoseDisplay.fontStyles.color = latestGlucoseColor;
			container.addChild(glucoseDisplay);
			
			/* TimeAgo Display Label */
			timeAgoDisplay = GraphLayoutFactory.createChartStatusText(timeAgoOutput, timeAgoColor, infoFontSize, Align.LEFT, false, 300);
			timeAgoDisplay.y = 10;
			timeAgoDisplay.x = 10;
			timeAgoDisplay.validate();
			addChild(timeAgoDisplay);
			
			/* Slope Display Label */
			slopeDisplay = GraphLayoutFactory.createChartStatusText(latestGlucoseSlopeOutput, latestSlopeInfoColor, infoFontSize, Align.LEFT, false, 300);
			slopeDisplay.x = timeAgoDisplay.x;
			slopeDisplay.y = timeAgoDisplay.y + timeAgoDisplay.height + 3;
			addChild(slopeDisplay);
			
			/* Slope Arrow Display Label */
			slopeArrowDisplay = GraphLayoutFactory.createChartStatusText(latestGlucoseSlopeArrow, latestSlopeArrowColor, deltaFontSize, Align.RIGHT, true, 300);
			slopeArrowDisplay.validate();
			slopeArrowDisplay.y = 10;
			slopeArrowDisplay.x = Constants.stageWidth - slopeArrowDisplay.width - 10;
			addChild(slopeArrowDisplay);
			
			/* Setup Timer */
			updateTimer = new Timer(15 * 1000);
			updateTimer.addEventListener(TimerEvent.TIMER, onUpdateTimer, false, 0, true);
			updateTimer.start();
		}
		
		private function setupEventListeners():void
		{
			TransmitterService.instance.addEventListener(TransmitterServiceEvent.BGREADING_EVENT, onBgReadingReceived, false, 0, true);
			NightscoutService.instance.addEventListener(FollowerEvent.BG_READING_RECEIVED, onBgReadingReceived, false, 0, true);
		}
		
		private function updateInfo():void
		{
			/* Determine Font Sizes */
			calculateFontSize();
			
			/* Glucose Display Label */
			glucoseDisplay.text = latestGlucoseOutput;
			glucoseDisplay.fontStyles.color = latestGlucoseColor;
			glucoseDisplay.fontStyles.size = glucoseFontSize;
			
			/* TimeAgo Display Label */
			timeAgoDisplay.text = timeAgoOutput;
			timeAgoDisplay.fontStyles.color = timeAgoColor;
			
			/* Slope Display Label */
			slopeDisplay.text = latestGlucoseSlopeOutput;
			slopeDisplay.fontStyles.color = latestSlopeInfoColor;
			
			/* Slope Arrow Display Label */
			slopeArrowDisplay.text = latestGlucoseSlopeArrow;
			slopeArrowDisplay.fontStyles.color = newColor;
		}
		
		private function calculateValues():void
		{
			nowTimestamp = new Date().valueOf();
			
			//Populate Internal Variables
			if (glucoseList == null || glucoseList.length == 0)
			{
				//NO BGREADINGS AVAILABLE
				latestGlucoseOutput = "---";
				latestGlucoseColor = oldColor;
				latestGlucoseSlopeArrow = "";
				latestSlopeArrowColor = oldColor;
				latestGlucoseSlopeOutput = "";
				latestSlopeInfoColor = oldColor;
				timeAgoOutput = "";
				timeAgoColor = oldColor
				
			}
			else if (glucoseList == null || glucoseList.length == 1)
			{
				//Timestamp
				latestGlucoseTimestamp = glucoseList[0].timestamp;
				
				
				//BG Value
				latestGlucoseValue = glucoseList[1].calculatedValue;
				
				if (latestGlucoseValue < 40) latestGlucoseValue = 40;
				else if (latestGlucoseValue > 400) latestGlucoseValue = 400;
				
				if (nowTimestamp - latestGlucoseTimestamp <= TIME_16_MINUTES)
				{
					latestGlucoseProperties = GlucoseFactory.getGlucoseOutput(latestGlucoseValue);
					latestGlucoseOutput = latestGlucoseProperties.glucoseOutput;
					latestGlucoseValueFormatted = latestGlucoseProperties.glucoseValueFormatted;
					if (nowTimestamp - latestGlucoseTimestamp < TIME_6_MINUTES)
						latestGlucoseColor = GlucoseFactory.getGlucoseColor(latestGlucoseValue);
					else
						latestGlucoseColor = oldColor;
				}
				else 
				{
					latestGlucoseOutput = "---";
					latestGlucoseColor = oldColor;
				}
				
				//Slope
				latestGlucoseSlopeArrow = "";
				latestSlopeArrowColor = oldColor;
				latestGlucoseSlopeOutput = "";
				latestSlopeInfoColor = oldColor;
				
				//Time Ago
				timeAgoOutput = TimeSpan.formatHoursMinutesFromSeconds((nowTimestamp - latestGlucoseTimestamp)/1000);
				if (nowTimestamp - latestGlucoseTimestamp < TIME_6_MINUTES)
					timeAgoColor = newColor;
				else
					timeAgoColor = oldColor;
			}
			else if (glucoseList.length > 1)
			{
				//Timestamps
				previousGlucoseTimestamp = glucoseList[glucoseList.length - 2].timestamp;
				latestGlucoseTimestamp = glucoseList[glucoseList.length - 1].timestamp;
				
				//BG Values
				//Previous
				previousGlucoseValue = glucoseList[glucoseList.length - 2].calculatedValue;
				previousGlucoseValueFormatted = GlucoseFactory.getGlucoseOutput(previousGlucoseValue).glucoseValueFormatted;
				if (previousGlucoseValue < 40) previousGlucoseValue = 40;
				else if (previousGlucoseValue > 400) previousGlucoseValue = 400;
				
				//Latest
				latestGlucoseValue = glucoseList[glucoseList.length - 1].calculatedValue;
				if (latestGlucoseValue < 40) latestGlucoseValue = 40;
				else if (latestGlucoseValue > 400) latestGlucoseValue = 400;
				
				if (nowTimestamp - latestGlucoseTimestamp <= TIME_16_MINUTES)
				{
					latestGlucoseProperties = GlucoseFactory.getGlucoseOutput(latestGlucoseValue);
					latestGlucoseOutput = latestGlucoseProperties.glucoseOutput;
					latestGlucoseValueFormatted = latestGlucoseProperties.glucoseValueFormatted;
					if (nowTimestamp - latestGlucoseTimestamp < TIME_6_MINUTES)
						latestGlucoseColor = GlucoseFactory.getGlucoseColor(latestGlucoseValue);
					else 
						latestGlucoseColor = oldColor;
				}
				else
				{
					
					latestGlucoseOutput = "---";
					latestGlucoseColor = oldColor;
				}
				
				/* SLOPE */
				if (nowTimestamp - latestGlucoseTimestamp > TIME_16_MINUTES || latestGlucoseTimestamp - previousGlucoseTimestamp > TIME_16_MINUTES)
					latestGlucoseSlopeOutput = "";
				else if (latestGlucoseTimestamp - previousGlucoseTimestamp < TIME_16_MINUTES)
				{
					latestGlucoseSlopeOutput = GlucoseFactory.getGlucoseSlope
						(
							previousGlucoseValue, 
							previousGlucoseValueFormatted, 
							latestGlucoseValue, 
							latestGlucoseValueFormatted
						);
					
					if (latestGlucoseTimestamp - previousGlucoseTimestamp < TIME_6_MINUTES && nowTimestamp - latestGlucoseTimestamp < TIME_6_MINUTES)
						latestSlopeInfoColor = newColor;
					else
						latestSlopeInfoColor = oldColor;
				}
				
				//Arrow
				if (nowTimestamp - latestGlucoseTimestamp > TIME_16_MINUTES || latestGlucoseTimestamp - previousGlucoseTimestamp > TIME_16_MINUTES)
					latestGlucoseSlopeArrow = "";
				else if (latestGlucoseTimestamp - previousGlucoseTimestamp <= TIME_16_MINUTES)
				{
					if ((glucoseList[1] as BgReading).hideSlope)
						latestGlucoseSlopeArrow = "\u21C4";
					else 
						latestGlucoseSlopeArrow = (glucoseList[1] as BgReading).slopeArrow();
						
					if (latestGlucoseTimestamp - previousGlucoseTimestamp < TIME_6_MINUTES && nowTimestamp - latestGlucoseTimestamp < TIME_6_MINUTES)
						latestSlopeArrowColor = newColor;
					else
						latestSlopeArrowColor = oldColor;
				}
				
				/* TIMEAGO */
				nowTimestamp = new Date().valueOf();
				var differenceInSec:Number = (nowTimestamp - latestGlucoseTimestamp) / 1000;
				timeAgoOutput = TimeSpan.formatHoursMinutesFromSeconds(differenceInSec);
				
				if (nowTimestamp - latestGlucoseTimestamp < TIME_6_MINUTES)
					timeAgoColor = newColor;
				else
					timeAgoColor = oldColor;
			}
		}
		
		private function setupLayout():void
		{
			/* Parent Class Layout */
			layout = new AnchorLayout(); 
			
			/* Create Display Object's Container and Corresponding Vertical Layout and Centered LayoutData */
			container = new LayoutGroup();
			var containerLayout:VerticalLayout = new VerticalLayout();
			containerLayout.gap = -50;
			containerLayout.horizontalAlign = HorizontalAlign.CENTER;
			containerLayout.verticalAlign = VerticalAlign.MIDDLE;
			container.layout = containerLayout;
			var containerLayoutData:AnchorLayoutData = new AnchorLayoutData();
			containerLayoutData.horizontalCenter = 0;
			containerLayoutData.verticalCenter = 0;
			container.layoutData = containerLayoutData;
			this.addChild( container );
		}
		
		private function adjustMainMenu():void
		{
			AppInterface.instance.menu.selectedIndex = -1;
		}
		
		private function calculateFontSize ():void
		{
			var deviceType:String = DeviceInfo.getDeviceType();
			
			if(deviceType == DeviceInfo.IPHONE_2G_3G_3GS_4_4S_ITOUCH_2_3_4 || deviceType == DeviceInfo.IPHONE_5_5S_5C_SE_ITOUCH_5_6)
			{
				if(latestGlucoseOutput.length == 2) glucoseFontSize = 260;	
				else if(latestGlucoseOutput.length == 3) glucoseFontSize = 175;
				else if(latestGlucoseOutput.length == 4) glucoseFontSize = 150;
				else if(latestGlucoseOutput.length == 5) glucoseFontSize = 120;
			}
			else if(deviceType == DeviceInfo.IPHONE_6_6S_7_8)
			{
				if(latestGlucoseOutput.length == 2) glucoseFontSize = 310;	
				else if(latestGlucoseOutput.length == 3) glucoseFontSize = 210;
				else if(latestGlucoseOutput.length == 4) glucoseFontSize = 175;
				else if(latestGlucoseOutput.length == 5) glucoseFontSize = 145;
				
			}
			else if(deviceType == DeviceInfo.IPHONE_6PLUS_6SPLUS_7PLUS_8PLUS)
			{
				if(latestGlucoseOutput.length == 2) glucoseFontSize = 300;	
				else if(latestGlucoseOutput.length == 3) glucoseFontSize = 200;
				else if(latestGlucoseOutput.length == 4) glucoseFontSize = 170;
				else if(latestGlucoseOutput.length == 5) glucoseFontSize = 135;
				
			}
			else if(deviceType == DeviceInfo.IPHONE_X)
			{
				if(latestGlucoseOutput.length == 2) glucoseFontSize = 230;	
				else if(latestGlucoseOutput.length == 3) glucoseFontSize = 155;
				else if(latestGlucoseOutput.length == 4) glucoseFontSize = 135;
				else if(latestGlucoseOutput.length == 5) glucoseFontSize = 105;
				
			}
			
			var deviceFontMultiplier:Number = DeviceInfo.getFontMultipier();
			deltaFontSize = 40 * deviceFontMultiplier * userBGFontMultiplier;
			infoFontSize = 16 * deviceFontMultiplier * userTimeAgoFontMultiplier;
		}
		
		/**
		 * Event Listeners
		 */
		private function onBgReadingReceived(e:Event):void
		{
			//Get latest BGReading
			var latestBgReading:BgReading;
			if (!BlueToothDevice.isFollower())
				latestBgReading = BgReading.lastNoSensor();
			else
				latestBgReading = BgReading.lastWithCalculatedValue();
			
			//If the latest BGReading is null, stop execution
			if (latestBgReading == null)
				return;
			
			//Add BGReading to the glucoseList array
			if (glucoseList == null || glucoseList.length == 0)
				glucoseList = [latestBgReading];
			else
			{
				if (latestBgReading.timestamp < latestGlucoseTimestamp)
					return;
				
				if (glucoseList != null && glucoseList.length == 1)
					glucoseList.push(latestBgReading);
				else if (glucoseList != null && glucoseList.length > 1)
				{
					glucoseList.shift();
					glucoseList.push(latestBgReading);
				}
			}
			
			//Reset Update Timer
			if (updateTimer == null)
			{
				updateTimer = new Timer(60 * 1000);
				updateTimer.addEventListener(TimerEvent.TIMER, onUpdateTimer, false, 0, true);
			}
			else
			{
				updateTimer.stop();
				updateTimer.delay = 60 * 1000;
				updateTimer.start();
			}
			
			//Calculate Glucose Values and Update Labels
			calculateValues();
			updateInfo();
		}
		
		private function onUpdateTimer(event:TimerEvent):void
		{
			if (latestGlucoseTimestamp != 0)
			{
				/* Time Ago */
				var nowTimestamp:Number = new Date().valueOf();
				var differenceInSec:Number = (nowTimestamp - latestGlucoseTimestamp) / 1000;
				timeAgoOutput = TimeSpan.formatHoursMinutesFromSeconds(differenceInSec);
				timeAgoDisplay.text = timeAgoOutput;
				
				if (nowTimestamp - latestGlucoseTimestamp < TIME_6_MINUTES)
					timeAgoColor = newColor;
				else
					timeAgoColor = oldColor;
				
				timeAgoDisplay.fontStyles.color = timeAgoColor;
				
				if ( nowTimestamp - latestGlucoseTimestamp > TIME_16_MINUTES )
				{
					//Glucose Value
					latestGlucoseOutput = "---";
					glucoseDisplay.text = latestGlucoseOutput;
					glucoseDisplay.fontStyles.color = oldColor;
					
					/* Slope Display Label */
					latestGlucoseSlopeOutput = "";
					slopeDisplay.text = latestGlucoseSlopeOutput;
					
					//Slope Arrow
					latestGlucoseSlopeArrow = "";
					slopeArrowDisplay.text = latestGlucoseSlopeArrow;
				}
				else if ( nowTimestamp - latestGlucoseTimestamp > TIME_6_MINUTES )
				{
					glucoseDisplay.fontStyles.color = oldColor;
					slopeDisplay.fontStyles.color = oldColor;
					slopeArrowDisplay.fontStyles.color = oldColor;
				}
			}
		}
		
		/**
		 * Utility
		 */
		override protected function draw():void 
		{
			super.draw();
			icon.x = Constants.stageWidth - icon.width - BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding;
		}
		
		override public function dispose():void
		{
			TransmitterService.instance.removeEventListener(TransmitterServiceEvent.BGREADING_EVENT, onBgReadingReceived);
			NightscoutService.instance.removeEventListener(FollowerEvent.BG_READING_RECEIVED, onBgReadingReceived);
			
			if(glucoseDisplay != null)
			{
				glucoseDisplay.dispose();
				glucoseDisplay = null;
			}
			
			if (slopeDisplay != null)
			{
				slopeDisplay.dispose();
				slopeDisplay = null;
			}
			
			if(slopeArrowDisplay != null)
			{
				slopeArrowDisplay.dispose();
				slopeArrowDisplay = null;
			}
			
			if(timeAgoDisplay != null)
			{
				timeAgoDisplay.dispose();
				timeAgoDisplay = null;
			}
			
			if(container != null)
			{
				container.dispose();
				container = null;
			}
			
			if(updateTimer != null)
			{
				updateTimer.stop();
				updateTimer.removeEventListener(TimerEvent.TIMER, onUpdateTimer);
				updateTimer = null;
			}
			
			super.dispose();
			
			System.pauseForGCIfCollectionImminent(0);
		}
	}
}