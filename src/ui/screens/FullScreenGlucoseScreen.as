package ui.screens
{
	import com.spikeapp.spike.airlibrary.SpikeANE;
	
	import flash.desktop.NativeApplication;
	import flash.desktop.SystemIdleMode;
	import flash.display.StageOrientation;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.system.System;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	
	import database.BgReading;
	import database.CGMBlueToothDevice;
	import database.CommonSettings;
	
	import events.FollowerEvent;
	import events.PredictionEvent;
	import events.TransmitterServiceEvent;
	
	import feathers.controls.DragGesture;
	import feathers.controls.Label;
	import feathers.controls.LayoutGroup;
	import feathers.controls.ScrollPolicy;
	import feathers.events.FeathersEventType;
	import feathers.layout.AnchorLayout;
	import feathers.layout.AnchorLayoutData;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalAlign;
	import feathers.layout.VerticalLayout;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.Forecast;
	import model.ModelLocator;
	
	import services.DexcomShareService;
	import services.NightscoutService;
	import services.TransmitterService;
	
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.Quad;
	import starling.events.Event;
	import starling.events.ResizeEvent;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.utils.Align;
	import starling.utils.SystemUtil;
	
	import treatments.TreatmentsManager;
	
	import ui.AppInterface;
	import ui.InterfaceController;
	import ui.chart.helpers.GlucoseFactory;
	import ui.chart.layout.GraphLayoutFactory;
	import ui.screens.display.LayoutFactory;
	
	import utils.Constants;
	import utils.DeviceInfo;
	import utils.GlucoseHelper;
	import utils.TimeSpan;
	
	[ResourceBundle("fullscreenglucosescreen")]
	[ResourceBundle("chartscreen")]
	[ResourceBundle("globaltranslations")]

	public class FullScreenGlucoseScreen extends BaseSubScreen
	{	
		/* Display Objects */
		private var glucoseDisplay:Label;
		private var timeAgoDisplay:Label;
		private var slopeDisplay:Label;
		private var container:LayoutGroup;
		private var IOBCOBDisplay:Label;
		private var miaoMiaoHitArea:Quad;

		/* Properties */
		private var outdateDataMaxTime:int = 0;
		private var oldColor:uint = 0xababab;
		private var newColor:uint = 0xEEEEEE;
		private var glucoseFontSize:Number;
		private var infoFontSize:Number;
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
		private var nowTimestamp:Number;
		private var latestGlucoseProperties:Object;
		private var latestGlucoseValueFormatted:Number;
		private var previousGlucoseValueFormatted:Number;
		private var touchTimer:Number;
		
		[Embed(source="/assets/theme/fonts/OpenSans-Bold.ttf", embedAsCFF="false", fontWeight="bold", fontName="OpenSansBold", fontFamily="OpenSansBold", mimeType="application/x-font")]
		private static const OPEN_SANS_BOLD:Class;
		
		public function FullScreenGlucoseScreen() 
		{
			super();
			styleNameList.add( BaseMaterialDeepGreyAmberMobileTheme.THEME_STYLE_NAME_HEADER_WITH_SHADOW );
			styleNameList.add( BaseMaterialDeepGreyAmberMobileTheme.THEME_STYLE_NAME_PANEL_WITHOUT_PADDING );
		}
		
		override protected function initialize():void 
		{
			super.initialize();
			
			addEventListener(FeathersEventType.CREATION_COMPLETE, onCreation);
			Starling.current.stage.addEventListener(starling.events.Event.RESIZE, onStarlingResize);
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_LOOP_OPENAPS_USER_ENABLED) == "true" && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_GLUCOSE_PREDICTIONS_ENABLED) == "true")
			{
				Forecast.instance.addEventListener(PredictionEvent.APS_RETRIEVED, onAPSPredictionRetrieved);
			}
			
			this.horizontalScrollPolicy = ScrollPolicy.OFF;
			
			setupHeader();
			setupLayout();
			setupInitialContent();
			setupContent();
			setupEventListeners();
			adjustMainMenu();
			updateInfo();
		}
		
		/**
		 * Functionality
		 */
		private function setupHeader():void
		{
			/* Set Header Title */
			if (Constants.deviceModel != DeviceInfo.IPHONE_2G_3G_3GS_4_4S_ITOUCH_2_3_4 && Constants.deviceModel != DeviceInfo.IPHONE_5_5S_5C_SE_ITOUCH_5_6)
				title = ModelLocator.resourceManagerInstance.getString('fullscreenglucosescreen','screen_title');
			else
				title = ModelLocator.resourceManagerInstance.getString('fullscreenglucosescreen','screen_title_small');
			
			/* Set Header Icon */
			icon = getScreenIcon(MaterialDeepGreyAmberMobileThemeIcons.fullscreenTexture);
			iconContainer = new <DisplayObject>[icon];
			headerProperties.rightItems = iconContainer;
		}
		
		private function setupInitialContent():void
		{			
			//Time
			outdateDataMaxTime = CGMBlueToothDevice.isFollower() ? TimeSpan.TIME_7_MINUTES : TimeSpan.TIME_6_MINUTES;
			
			//Glucose Unit
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true") 
				glucoseUnit = "mg/dl";
			else
				glucoseUnit = "mmol/L";
			
			//Font Size
			userBGFontMultiplier = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_BG_FONT_SIZE));
			userTimeAgoFontMultiplier = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_TIMEAGO_FONT_SIZE));
		
			//User's Readings
			glucoseList = ModelLocator.bgReadings;
			
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
			glucoseDisplay.fontStyles.leading = getLeading(latestGlucoseSlopeArrow);
			container.addChild(glucoseDisplay);
			
			/* TimeAgo Display Label */
			timeAgoDisplay = LayoutFactory.createLabel(timeAgoOutput, HorizontalAlign.LEFT, VerticalAlign.MIDDLE, infoFontSize, false, timeAgoColor);
			timeAgoDisplay.width = 350;
			timeAgoDisplay.y = 10;
			timeAgoDisplay.x = Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr && !Constants.isPortrait && Constants.currentOrientation == StageOrientation.ROTATED_RIGHT ? 40 : 10;
			timeAgoDisplay.validate();
			addChild(timeAgoDisplay);
			
			/* MiaoMiao HitArea */
			if (CGMBlueToothDevice.isMiaoMiao())
			{
				miaoMiaoHitArea = new Quad(150, timeAgoDisplay.height + 25, 0xFF0000);
				miaoMiaoHitArea.alpha = 0;
				miaoMiaoHitArea.addEventListener(TouchEvent.TOUCH, onRequestMiaoMiaoReading);
				miaoMiaoHitArea.x = timeAgoDisplay.x;
				addChild(miaoMiaoHitArea);
			}
			
			/* Slope Display Label */
			slopeDisplay = LayoutFactory.createLabel(latestGlucoseSlopeOutput != "" && latestGlucoseSlopeOutput != null ? latestGlucoseSlopeOutput + " " + GlucoseHelper.getGlucoseUnit() : "", HorizontalAlign.RIGHT, VerticalAlign.MIDDLE, infoFontSize, false, latestSlopeInfoColor);
			slopeDisplay.width = 300;
			slopeDisplay.validate();
			slopeDisplay.x = Constants.stageWidth - slopeDisplay.width - (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr && !Constants.isPortrait && Constants.currentOrientation == StageOrientation.ROTATED_LEFT ? 40 : 10);
			slopeDisplay.y = timeAgoDisplay.y;
			addChild(slopeDisplay);
			
			/* IOB/COB Display Label */
			var now:Number = new Date().valueOf();
			IOBCOBDisplay = GraphLayoutFactory.createChartStatusText(timeAgoColor != 0 ? "IOB: " + GlucoseFactory.formatIOB(TreatmentsManager.getTotalIOB(now).iob) + "  COB: " + GlucoseFactory.formatCOB(TreatmentsManager.getTotalCOB(now, CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEFAULT_IOB_COB_ALGORITHM) == "openaps").cob) + getPredictionText() : "", timeAgoColor, infoFontSize, Align.CENTER, false, Constants.stageWidth);
			var IOBCOBLayoutData:AnchorLayoutData = new AnchorLayoutData();
			if (Constants.deviceModel != DeviceInfo.IPHONE_X_Xs_XsMax_Xr)
				IOBCOBLayoutData.bottom = 10;
			else
				IOBCOBLayoutData.bottom = 20;
			IOBCOBDisplay.layoutData = IOBCOBLayoutData;
			addChild(IOBCOBDisplay);
			
			/* Setup Timer */
			updateTimer = new Timer(15 * 1000);
			updateTimer.addEventListener(TimerEvent.TIMER, onUpdateTimer, false, 0, true);
			updateTimer.start();
		}
		
		private function setupEventListeners():void
		{
			TransmitterService.instance.addEventListener(TransmitterServiceEvent.LAST_BGREADING_RECEIVED, onBgReadingReceived, false, 0, true);
			NightscoutService.instance.addEventListener(FollowerEvent.BG_READING_RECEIVED, onBgReadingReceived, false, 0, true);
			DexcomShareService.instance.addEventListener(FollowerEvent.BG_READING_RECEIVED, onBgReadingReceived, false, 0, true);
			this.addEventListener(TouchEvent.TOUCH, onTouch);
		}
		
		private function updateInfo():void
		{
			/* Determine Font Sizes */
			calculateFontSize();
			
			/* Glucose Display Label */
			glucoseDisplay.text = latestGlucoseOutput;
			glucoseDisplay.fontStyles.leading = getLeading(latestGlucoseSlopeArrow);
			glucoseDisplay.fontStyles.color = latestGlucoseColor;
			glucoseDisplay.fontStyles.size = glucoseFontSize;
			
			/* TimeAgo Display Label */
			timeAgoDisplay.text = timeAgoOutput;
			timeAgoDisplay.fontStyles.color = timeAgoColor;
			
			if (CGMBlueToothDevice.isMiaoMiao() && miaoMiaoHitArea != null)
			{
				timeAgoDisplay.validate();
				miaoMiaoHitArea.x = timeAgoDisplay.x;
			}
			
			/* Slope Display Label */
			slopeDisplay.text = latestGlucoseSlopeOutput != "" && latestGlucoseSlopeOutput != null ? latestGlucoseSlopeOutput + " " + GlucoseHelper.getGlucoseUnit() : "";
			slopeDisplay.fontStyles.color = latestSlopeInfoColor;
			
			/* IOB / COB Display Label */
			var now:Number = new Date().valueOf();
			IOBCOBDisplay.fontStyles.color = timeAgoColor;
			IOBCOBDisplay.text = getPredictionText() + "IOB: " + GlucoseFactory.formatIOB(TreatmentsManager.getTotalIOB(now).iob) + "  COB: " + GlucoseFactory.formatCOB(TreatmentsManager.getTotalCOB(now, CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEFAULT_IOB_COB_ALGORITHM) == "openaps").cob);
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
				latestGlucoseSlopeOutput = "";
				latestSlopeInfoColor = oldColor;
				timeAgoOutput = "";
				timeAgoColor = oldColor
				
			}
			else if (glucoseList.length == 1)
			{
				if (glucoseList[glucoseList.length - 1] == null)
				{
					//NO BGREADINGS AVAILABLE
					latestGlucoseOutput = "---";
					latestGlucoseColor = oldColor;
					latestGlucoseSlopeArrow = "";
					latestGlucoseSlopeOutput = "";
					latestSlopeInfoColor = oldColor;
					timeAgoOutput = "";
					timeAgoColor = oldColor
					return;
				}
				
				//Timestamp
				latestGlucoseTimestamp = glucoseList[glucoseList.length - 1].timestamp;
				
				//BG Value
				if (glucoseList[glucoseList.length - 1] == null)
					return;
				
				latestGlucoseValue = glucoseList[glucoseList.length - 1].calculatedValue;
				
				if (latestGlucoseValue < 40) latestGlucoseValue = 40;
				else if (latestGlucoseValue > 400) latestGlucoseValue = 400;
				
				if (nowTimestamp - latestGlucoseTimestamp <= TimeSpan.TIME_16_MINUTES)
				{
					latestGlucoseProperties = GlucoseFactory.getGlucoseOutput(latestGlucoseValue);
					latestGlucoseOutput = latestGlucoseProperties.glucoseOutput;
					latestGlucoseValueFormatted = latestGlucoseProperties.glucoseValueFormatted;
					if (nowTimestamp - latestGlucoseTimestamp < outdateDataMaxTime)
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
				latestGlucoseSlopeOutput = "";
				latestSlopeInfoColor = oldColor;
				
				//Time Ago
				timeAgoOutput = TimeSpan.formatHoursMinutesFromSecondsChart((nowTimestamp - latestGlucoseTimestamp)/1000, false, false);
				timeAgoOutput != ModelLocator.resourceManagerInstance.getString('chartscreen','now') ? timeAgoOutput += " " + ModelLocator.resourceManagerInstance.getString('chartscreen','time_ago_suffix') : timeAgoOutput += "";
				if (nowTimestamp - latestGlucoseTimestamp < outdateDataMaxTime)
					timeAgoColor = newColor;
				else
					timeAgoColor = oldColor;
			}
			else if (glucoseList.length > 1)
			{
				if (glucoseList[glucoseList.length - 2] == null || glucoseList[glucoseList.length - 1] == null)
					return;
				
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
				
				if (nowTimestamp - latestGlucoseTimestamp <= TimeSpan.TIME_16_MINUTES)
				{
					latestGlucoseProperties = GlucoseFactory.getGlucoseOutput(latestGlucoseValue);
					latestGlucoseOutput = latestGlucoseProperties.glucoseOutput;
					latestGlucoseValueFormatted = latestGlucoseProperties.glucoseValueFormatted;
					if (nowTimestamp - latestGlucoseTimestamp < outdateDataMaxTime)
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
				if (nowTimestamp - latestGlucoseTimestamp > TimeSpan.TIME_16_MINUTES || latestGlucoseTimestamp - previousGlucoseTimestamp > TimeSpan.TIME_16_MINUTES)
					latestGlucoseSlopeOutput = "";
				else if (latestGlucoseTimestamp - previousGlucoseTimestamp < TimeSpan.TIME_16_MINUTES)
				{
					latestGlucoseSlopeOutput = GlucoseFactory.getGlucoseSlope
						(
							previousGlucoseValue, 
							previousGlucoseValueFormatted, 
							latestGlucoseValue, 
							latestGlucoseValueFormatted
						);
					
					if (nowTimestamp - latestGlucoseTimestamp < outdateDataMaxTime)
						latestSlopeInfoColor = newColor;
					else
						latestSlopeInfoColor = oldColor;
				}
				
				//Arrow
				if (nowTimestamp - latestGlucoseTimestamp > TimeSpan.TIME_16_MINUTES || latestGlucoseTimestamp - previousGlucoseTimestamp > TimeSpan.TIME_16_MINUTES)
					latestGlucoseSlopeArrow = "";
				else if (latestGlucoseTimestamp - previousGlucoseTimestamp <= TimeSpan.TIME_16_MINUTES)
				{
					if ((glucoseList[glucoseList.length - 1] as BgReading).hideSlope)
						latestGlucoseSlopeArrow = "\u21C4";
					else 
						latestGlucoseSlopeArrow = (glucoseList[glucoseList.length - 1] as BgReading).slopeArrow();
				}
				
				/* TIMEAGO */
				nowTimestamp = new Date().valueOf();
				var differenceInSec:Number = (nowTimestamp - latestGlucoseTimestamp) / 1000;
				timeAgoOutput = TimeSpan.formatHoursMinutesFromSecondsChart(differenceInSec, false, false);
				timeAgoOutput != ModelLocator.resourceManagerInstance.getString('chartscreen','now') ? timeAgoOutput += " " + ModelLocator.resourceManagerInstance.getString('chartscreen','time_ago_suffix') : timeAgoOutput += "";
				
				if (nowTimestamp - latestGlucoseTimestamp < outdateDataMaxTime)
					timeAgoColor = newColor;
				else
					timeAgoColor = oldColor;
			}
			
			if (Constants.isPortrait)
				latestGlucoseOutput = latestGlucoseOutput + "\n" + latestGlucoseSlopeArrow;
			else
				latestGlucoseOutput = latestGlucoseOutput + " " + latestGlucoseSlopeArrow;
			
			/* IOB / COB Display Label */
			if (IOBCOBDisplay != null)
			{
				var now:Number = new Date().valueOf();
				IOBCOBDisplay.fontStyles.color = timeAgoColor;
				IOBCOBDisplay.text = getPredictionText() + "IOB: " + GlucoseFactory.formatIOB(TreatmentsManager.getTotalIOB(now).iob) + "  COB: " + GlucoseFactory.formatCOB(TreatmentsManager.getTotalCOB(now, CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEFAULT_IOB_COB_ALGORITHM) == "openaps").cob);
			}
		}
		
		private function getPredictionText():String
		{
			var predictionsText:String = "";
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_GLUCOSE_PREDICTIONS_ENABLED) == "true")
			{
				var predictionsLengthInMinutes:Number = Forecast.getCurrentPredictionsDuration();
				if (!isNaN(predictionsLengthInMinutes))
				{
					var currentPrediction:Number = Forecast.getLastPredictiveBG(predictionsLengthInMinutes);
					if (!isNaN(currentPrediction))
					{
						predictionsText = TimeSpan.formatHoursMinutesFromMinutes(predictionsLengthInMinutes, false) + " " + ModelLocator.resourceManagerInstance.getString('chartscreen','prediction_label') + ": " + (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true" ? String(Math.round(currentPrediction)) : String(Math.round(BgReading.mgdlToMmol(currentPrediction * 10)) / 10)) + "\n";
					}
					else
					{
						predictionsText = TimeSpan.formatHoursMinutesFromMinutes(predictionsLengthInMinutes, false) + " " + ModelLocator.resourceManagerInstance.getString('chartscreen','prediction_label') + ": " + ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available') + "\n";
					}
				}
			}
			
			return predictionsText;
		}
		
		private function getLeading(arrow:String):Number
		{
			var leading:Number = -150 / 2.5;
			
			if (arrow != null)
			{
				if (arrow.indexOf("\u21C4") != -1 || arrow.indexOf("\u2192") != -1) //FLAT
					leading = -glucoseFontSize / 2;
				else if (arrow.indexOf("\u2198") != -1 || arrow.indexOf("\u2197") != -1) //45º Down/UP
					leading = -glucoseFontSize / 3;
				else if (arrow.indexOf("\u2193") != -1 || arrow.indexOf("\u2191") != -1) //Down/Up
				{
					if (Constants.deviceModel == DeviceInfo.IPHONE_2G_3G_3GS_4_4S_ITOUCH_2_3_4)
						leading = -glucoseFontSize / 2.5;
					else
						leading = -glucoseFontSize / 3;
				}
			}
			
			return leading;
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
		
		private function calculateFontSize():void
		{
			if (latestGlucoseOutput == null || latestGlucoseSlopeArrow == null)
				return;
			
			var sNativeFormat:flash.text.TextFormat = new flash.text.TextFormat();
			sNativeFormat.font = "OpenSansBold";
			sNativeFormat.bold = true;
			sNativeFormat.color = 0xFFFFFF;
			sNativeFormat.size = 600;
			sNativeFormat.leading = getLeading(latestGlucoseSlopeArrow);
			
			var formattedGlucoseOutput:String = Constants.isPortrait ? latestGlucoseOutput.substring(0, latestGlucoseOutput.indexOf("\n")) : latestGlucoseOutput.substring(0, latestGlucoseOutput.indexOf(" "));
			if (formattedGlucoseOutput == null) formattedGlucoseOutput = "";
			if (!Constants.isPortrait) formattedGlucoseOutput += " -->";
			if (Constants.isPortrait && (latestGlucoseSlopeArrow.indexOf("\u2197") != -1 || latestGlucoseSlopeArrow.indexOf("\u2198") != -1 || latestGlucoseSlopeArrow.indexOf("\u2191") != -1 || latestGlucoseSlopeArrow.indexOf("\u2193") != -1))
				formattedGlucoseOutput += "\n |";
			
			var nativeTextField:flash.text.TextField = new flash.text.TextField();
			nativeTextField.defaultTextFormat = sNativeFormat;
			nativeTextField.width  = Constants.stageWidth;
			nativeTextField.height = Constants.stageHeight;
			nativeTextField.selectable = false;
			nativeTextField.multiline = true;
			nativeTextField.wordWrap = false;
			nativeTextField.embedFonts = true;
			nativeTextField.text = formattedGlucoseOutput;
			
			if (sNativeFormat == null) return;
			
			var textFormat:flash.text.TextFormat = sNativeFormat;
			var maxTextWidth:int  = Constants.stageWidth - (Constants.isPortrait ? Constants.stageWidth * 0.2 : Constants.stageWidth * 0.1);
			var maxTextHeight:int = Constants.stageHeight - Constants.headerHeight;
			
			if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr && !Constants.isPortrait)
				maxTextHeight -= maxTextHeight * 0.35;
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_GLUCOSE_PREDICTIONS_ENABLED) == "true")
				maxTextHeight -= maxTextHeight * 0.30;
			
			if (isNaN(maxTextWidth) || isNaN(maxTextHeight)) 
				return;
			
			var size:Number = Number(textFormat.size);
			
			while (nativeTextField.textWidth > maxTextWidth || nativeTextField.textHeight > maxTextHeight)
			{
				if (size <= 4) break;
				
				textFormat.size = size--;
				nativeTextField.defaultTextFormat = textFormat;
				
				nativeTextField.text = formattedGlucoseOutput;
			}
			
			var deviceFontMultiplier:Number = DeviceInfo.getFontMultipier();
			infoFontSize = 22 * deviceFontMultiplier * userTimeAgoFontMultiplier;
			
			glucoseFontSize =  Number(textFormat.size);
			if (isNaN(glucoseFontSize)) glucoseFontSize = 130;
		}
		
		/**
		 * Event Listeners
		 */
		private function onBgReadingReceived(e:flash.events.Event):void
		{
			//Get latest BGReading
			var latestBgReading:BgReading;
			if (!CGMBlueToothDevice.isFollower())
				latestBgReading = BgReading.lastNoSensor();
			else
				latestBgReading = BgReading.lastWithCalculatedValue();
			
			//If the latest BGReading is null, stop execution
			if (latestBgReading == null)
				return;
			
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
			SystemUtil.executeWhenApplicationIsActive( calculateValues );
			SystemUtil.executeWhenApplicationIsActive( updateInfo );
		}
		
		private function onAPSPredictionRetrieved(e:PredictionEvent):void
		{
			if (!SystemUtil.isApplicationActive)
				return;
			
			/* IOB / COB Display Label */
			if (IOBCOBDisplay != null)
			{
				var now:Number = new Date().valueOf();
				IOBCOBDisplay.fontStyles.color = timeAgoColor;
				IOBCOBDisplay.text = getPredictionText() + "IOB: " + GlucoseFactory.formatIOB(TreatmentsManager.getTotalIOB(now).iob) + "  COB: " + GlucoseFactory.formatCOB(TreatmentsManager.getTotalCOB(now, CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEFAULT_IOB_COB_ALGORITHM) == "openaps").cob);
			}
		}
		
		private function onUpdateTimer(event:TimerEvent):void
		{
			if (latestGlucoseTimestamp != 0 && SystemUtil.isApplicationActive)
			{
				/* Time Ago */
				var nowTimestamp:Number = new Date().valueOf();
				var differenceInSec:Number = (nowTimestamp - latestGlucoseTimestamp) / 1000;
				timeAgoOutput = TimeSpan.formatHoursMinutesFromSecondsChart(differenceInSec, false, false);
				timeAgoOutput != ModelLocator.resourceManagerInstance.getString('chartscreen','now') ? timeAgoOutput += " " + ModelLocator.resourceManagerInstance.getString('chartscreen','time_ago_suffix') : timeAgoOutput += "";
				timeAgoDisplay.text = timeAgoOutput;
				
				if (nowTimestamp - latestGlucoseTimestamp < outdateDataMaxTime)
					timeAgoColor = newColor;
				else
					timeAgoColor = oldColor;
				
				timeAgoDisplay.fontStyles.color = timeAgoColor;
				
				if (CGMBlueToothDevice.isMiaoMiao() && miaoMiaoHitArea != null)
				{
					timeAgoDisplay.validate();
					miaoMiaoHitArea.x = timeAgoDisplay.x;
				}
				
				if ( nowTimestamp - latestGlucoseTimestamp > TimeSpan.TIME_16_MINUTES )
				{
					//Glucose Value
					latestGlucoseOutput = "---";
					glucoseDisplay.text = latestGlucoseOutput;
					glucoseDisplay.fontStyles.color = oldColor;
					
					/* Slope Display Label */
					latestGlucoseSlopeOutput = "";
					slopeDisplay.text = latestGlucoseSlopeOutput != "" && latestGlucoseSlopeOutput != null ? latestGlucoseSlopeOutput  + " " + GlucoseHelper.getGlucoseUnit() : "";
					
					//Slope Arrow
					latestGlucoseSlopeArrow = "";
					
					glucoseDisplay.fontStyles.leading = getLeading(latestGlucoseSlopeArrow);
				}
				else if ( nowTimestamp - latestGlucoseTimestamp > outdateDataMaxTime )
				{
					glucoseDisplay.fontStyles.color = oldColor;
					slopeDisplay.fontStyles.color = oldColor;
				}
				
				
				if (Constants.isPortrait)
					latestGlucoseOutput = latestGlucoseOutput + "\n" + latestGlucoseSlopeArrow;
				else
					latestGlucoseOutput = latestGlucoseOutput + " " + latestGlucoseSlopeArrow;
			}
			
			/* IOB / COB Display Label */
			if (IOBCOBDisplay != null && SystemUtil.isApplicationActive)
			{
				var now:Number = new Date().valueOf();
				IOBCOBDisplay.fontStyles.color = timeAgoColor;
				IOBCOBDisplay.text = getPredictionText() + "IOB: " + GlucoseFactory.formatIOB(TreatmentsManager.getTotalIOB(now).iob) + "  COB: " + GlucoseFactory.formatCOB(TreatmentsManager.getTotalCOB(now, CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEFAULT_IOB_COB_ALGORITHM) == "openaps").cob);
			}
		}
		
		private function onTouch (e:TouchEvent):void
		{
			var touch:Touch = e.getTouch(stage);
			if(touch != null && touch.phase == TouchPhase.BEGAN)
			{
				touchTimer = getTimer();
				addEventListener(starling.events.Event.ENTER_FRAME, onHold);
			}
			
			if(touch != null && touch.phase == TouchPhase.ENDED)
			{
				touchTimer = Number.NaN;
				removeEventListener(starling.events.Event.ENTER_FRAME, onHold);
			}
		}
		
		private function onHold(e:starling.events.Event):void
		{
			if (isNaN(touchTimer))
				return;
			
			if (getTimer() - touchTimer > 1000)
			{
				touchTimer = Number.NaN;
				removeEventListener(starling.events.Event.ENTER_FRAME, onHold);
				
				//Pop screen
				onBackButtonTriggered(null);
			}
		}
		
		private function onRequestMiaoMiaoReading(e:TouchEvent):void
		{
			var touch:Touch = e.getTouch(stage);
			if(touch != null && touch.phase == TouchPhase.BEGAN)
			{
				this.removeEventListener(TouchEvent.TOUCH, onTouch);
				this.removeEventListener(starling.events.Event.ENTER_FRAME, onHold);
				
				//Request MiaoMiao Reading On-Demand
				if (CGMBlueToothDevice.isMiaoMiao() && CGMBlueToothDevice.known() && InterfaceController.peripheralConnected)
				{
					SpikeANE.sendStartReadingCommmandToMiaoMia();
					SpikeANE.vibrate();
				}
			}
			else if (touch != null && touch.phase == TouchPhase.ENDED)
			{
				this.addEventListener(TouchEvent.TOUCH, onTouch);
			}
		}
		
		override protected function onBackButtonTriggered(event:starling.events.Event):void
		{
			//Pop this screen off
			dispatchEventWith(starling.events.Event.COMPLETE);
			
			//Activate menu drag gesture
			AppInterface.instance.drawers.openGesture = DragGesture.EDGE;
			
			//Deactivate Keep Awake
			NativeApplication.nativeApplication.systemIdleMode = SystemIdleMode.NORMAL;
			Constants.noLockEnabled = false;
		}
		
		private function onStarlingResize(event:ResizeEvent):void 
		{
			if (!SystemUtil.isApplicationActive)
			{
				SystemUtil.executeWhenApplicationIsActive(onStarlingResize, null);
				return;
			}
			
			width = Constants.stageWidth;
			
			if (IOBCOBDisplay != null)
				IOBCOBDisplay.width = Constants.stageWidth;
			
			//Adjust header for iPhone X
			onCreation(null);
			
			//Adjust label position
			if (timeAgoDisplay != null && slopeDisplay != null)
			{
				timeAgoDisplay.x = Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr && !Constants.isPortrait && Constants.currentOrientation == StageOrientation.ROTATED_RIGHT ? 40 : 10;
				
				if (CGMBlueToothDevice.isMiaoMiao() && miaoMiaoHitArea != null)
				{
					timeAgoDisplay.validate();
					miaoMiaoHitArea.x = timeAgoDisplay.x;
				}
				
				slopeDisplay.x = Constants.stageWidth - slopeDisplay.width - (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr && !Constants.isPortrait && Constants.currentOrientation == StageOrientation.ROTATED_LEFT ? 40 : 10);
			}
			
			SystemUtil.executeWhenApplicationIsActive( calculateValues );
			SystemUtil.executeWhenApplicationIsActive( updateInfo );
		}
		
		private function onCreation(event:starling.events.Event):void
		{
			if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr && this.header != null)
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
		}
		
		override protected function onTransitionInComplete(e:starling.events.Event):void
		{
			//Swipe to pop functionality
			AppInterface.instance.navigator.isSwipeToPopEnabled = false;
			AppInterface.instance.drawers.openGesture = DragGesture.NONE;
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
			Starling.current.stage.removeEventListener(starling.events.Event.RESIZE, onStarlingResize);
			TransmitterService.instance.removeEventListener(TransmitterServiceEvent.LAST_BGREADING_RECEIVED, onBgReadingReceived);
			NightscoutService.instance.removeEventListener(FollowerEvent.BG_READING_RECEIVED, onBgReadingReceived);
			DexcomShareService.instance.removeEventListener(FollowerEvent.BG_READING_RECEIVED, onBgReadingReceived);
			this.removeEventListener(TouchEvent.TOUCH, onTouch);
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_LOOP_OPENAPS_USER_ENABLED) == "true" && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_GLUCOSE_PREDICTIONS_ENABLED) == "true")
			{
				Forecast.instance.removeEventListener(PredictionEvent.APS_RETRIEVED, onAPSPredictionRetrieved);
			}
			
			if(updateTimer != null)
			{
				updateTimer.stop();
				updateTimer.removeEventListener(TimerEvent.TIMER, onUpdateTimer);
				updateTimer = null;
			}
			
			if(glucoseDisplay != null)
			{
				glucoseDisplay.removeFromParent();
				glucoseDisplay.dispose();
				glucoseDisplay = null;
			}
			
			if (slopeDisplay != null)
			{
				slopeDisplay.removeFromParent();
				slopeDisplay.dispose();
				slopeDisplay = null;
			}
			
			if(timeAgoDisplay != null)
			{
				timeAgoDisplay.removeFromParent();
				timeAgoDisplay.dispose();
				timeAgoDisplay = null;
			}
			
			if (miaoMiaoHitArea != null)
			{
				miaoMiaoHitArea.removeEventListener(TouchEvent.TOUCH, onRequestMiaoMiaoReading);
				miaoMiaoHitArea.removeFromParent();
				miaoMiaoHitArea.dispose();
				miaoMiaoHitArea = null;
			}
			
			if (IOBCOBDisplay != null)
			{
				IOBCOBDisplay.removeFromParent();
				IOBCOBDisplay.dispose();
				IOBCOBDisplay = null;
			}
			
			if(container != null)
			{
				container.removeFromParent();
				container.dispose();
				container = null;
			}
			
			super.dispose();
			
			System.pauseForGCIfCollectionImminent(0);
		}
	}
}