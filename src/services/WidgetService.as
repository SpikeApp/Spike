package services
{
	import com.freshplanet.ane.AirBackgroundFetch.BackgroundFetch;
	
	import database.BgReading;
	import database.Calibration;
	import database.CommonSettings;
	import database.LocalSettings;
	
	import events.SettingsServiceEvent;
	import events.TransmitterServiceEvent;
	
	import model.ModelLocator;
	
	import starling.core.Starling;
	
	import utils.BgGraphBuilder;
	import utils.GlucoseHelper;
	import utils.MathHelper;
	import utils.TimeSpan;
	import utils.Trace;

	[ResourceBundle("generalsettingsscreen")]
	[ResourceBundle("widgetservice")]
	
	public class WidgetService
	{
		/* Constants */
		private static const TIME_1_HOUR:int = 60 * 60 * 1000;
		private static const TIME_2_HOURS:int = 2 * 60 * 60 * 1000;
		
		/* Internal Variables */
		private static var displayTrendEnabled:Boolean = true;
		private static var displayDeltaEnabled:Boolean = true;
		private static var displayUnitsEnabled:Boolean = true;
		private static var dateFormat:String;
		private static var historyTimespan:int;
		private static var widgetHistory:int;
		private static var glucoseUnit:String;
		
		/* Objects */
		private static var months:Array;
		private static var startupGlucoseReadingsList:Array;
		private static var activeGlucoseReadingsList:Array;
		
		public function WidgetService()
		{
			throw new Error("WidgetService is not meant to be instantiated!");
		}
		
		public static function init():void
		{
			Trace.myTrace("WidgetService.as", "Service started!");
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_NSLOG, "true");
			
			BackgroundFetch.initUserDefaults();
			
			months = ModelLocator.resourceManagerInstance.getString('widgetservice','months').split(",");
			
			Starling.juggler.delayCall(setInitialGraphData, 3);
			
			CommonSettings.instance.addEventListener(SettingsServiceEvent.SETTING_CHANGED, onSettingsChanged);
			TransmitterService.instance.addEventListener(TransmitterServiceEvent.BGREADING_EVENT, onBloodGlucoseReceived);
		}
		
		private static function onSettingsChanged(e:SettingsServiceEvent):void
		{
			if (e.data == CommonSettings.COMMON_SETTING_DO_MGDL ||
				e.data == CommonSettings.COMMON_SETTING_URGENT_LOW_MARK ||
				e.data == CommonSettings.COMMON_SETTING_LOW_MARK ||
				e.data == CommonSettings.COMMON_SETTING_HIGH_MARK ||
				e.data == CommonSettings.COMMON_SETTING_URGENT_HIGH_MARK ||
				e.data == CommonSettings.COMMON_SETTING_CHART_DATE_FORMAT || 
				e.data == CommonSettings.COMMON_SETTING_WIDGET_HISTORY_TIMESPAN
			)
			{
				setInitialGraphData();
			}
			else if (e.data == CommonSettings.COMMON_SETTING_WIDGET_SMOOTH_LINE)
				BackgroundFetch.setUserDefaultsData("smoothLine", CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_SMOOTH_LINE));
			else if (e.data == CommonSettings.COMMON_SETTING_WIDGET_SHOW_MARKERS)
				BackgroundFetch.setUserDefaultsData("showMarkers", CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_SHOW_MARKERS));
			else if (e.data == CommonSettings.COMMON_SETTING_WIDGET_SHOW_MARKER_LABEL)
				BackgroundFetch.setUserDefaultsData("showMarkerLabel", CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_SHOW_MARKER_LABEL));
			else if (e.data == CommonSettings.COMMON_SETTING_WIDGET_SHOW_GRID_LINES)
				BackgroundFetch.setUserDefaultsData("showGridLines", CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_SHOW_GRID_LINES));
			else if (e.data == CommonSettings.COMMON_SETTING_WIDGET_LINE_THICKNESS)
				BackgroundFetch.setUserDefaultsData("lineThickness", CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_LINE_THICKNESS));
			else if (e.data == CommonSettings.COMMON_SETTING_WIDGET_MARKER_RADIUS)
				BackgroundFetch.setUserDefaultsData("markerRadius", CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_MARKER_RADIUS));
			else if (e.data == CommonSettings.COMMON_SETTING_WIDGET_URGENT_HIGH_COLOR)
				BackgroundFetch.setUserDefaultsData("urgentHighColor", "#" + uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_URGENT_HIGH_COLOR)).toString(16).toUpperCase());
			else if (e.data == CommonSettings.COMMON_SETTING_WIDGET_HIGH_COLOR)
				BackgroundFetch.setUserDefaultsData("highColor", "#" + uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_HIGH_COLOR)).toString(16).toUpperCase());
			else if (e.data == CommonSettings.COMMON_SETTING_WIDGET_IN_RANGE_COLOR)
				BackgroundFetch.setUserDefaultsData("inRangeColor", "#" + uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_IN_RANGE_COLOR)).toString(16).toUpperCase());
			else if (e.data == CommonSettings.COMMON_SETTING_WIDGET_LOW_COLOR)
				BackgroundFetch.setUserDefaultsData("lowColor", "#" + uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_LOW_COLOR)).toString(16).toUpperCase());
			else if (e.data == CommonSettings.COMMON_SETTING_WIDGET_URGENT_LOW_COLOR)
				BackgroundFetch.setUserDefaultsData("urgenLowColor", "#" + uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_URGENT_LOW_COLOR)).toString(16).toUpperCase());
			else if (e.data == CommonSettings.COMMON_SETTING_WIDGET_GLUCOSE_MARKER_COLOR)
				BackgroundFetch.setUserDefaultsData("markerColor", "#" + uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_GLUCOSE_MARKER_COLOR)).toString(16).toUpperCase());
			else if (e.data == CommonSettings.COMMON_SETTING_WIDGET_AXIS_COLOR)
				BackgroundFetch.setUserDefaultsData("axisColor", "#" + uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_AXIS_COLOR)).toString(16).toUpperCase());
			else if (e.data == CommonSettings.COMMON_SETTING_WIDGET_AXIS_FONT_COLOR)
				BackgroundFetch.setUserDefaultsData("axisFontColor", "#" + uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_AXIS_FONT_COLOR)).toString(16).toUpperCase());
			else if (e.data == CommonSettings.COMMON_SETTING_WIDGET_BACKGROUND_COLOR)
				BackgroundFetch.setUserDefaultsData("backgroundColor", "#" + uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_BACKGROUND_COLOR)).toString(16).toUpperCase());
			else if (e.data == CommonSettings.COMMON_SETTING_WIDGET_BACKGROUND_OPACITY)
				BackgroundFetch.setUserDefaultsData("backgroundOpacity", String(Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_BACKGROUND_OPACITY)) / 100));
			else if (e.data == CommonSettings.COMMON_SETTING_WIDGET_GRID_LINES_COLOR)
				BackgroundFetch.setUserDefaultsData("gridLinesColor", "#" + uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_GRID_LINES_COLOR)).toString(16).toUpperCase());
			else if (e.data == CommonSettings.COMMON_SETTING_WIDGET_DISPLAY_LABELS_COLOR)
				BackgroundFetch.setUserDefaultsData("displayLabelsColor", "#" + uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_DISPLAY_LABELS_COLOR)).toString(16).toUpperCase());
			else if (e.data == CommonSettings.COMMON_SETTING_WIDGET_OLD_DATA_COLOR)
				BackgroundFetch.setUserDefaultsData("oldDataColor", "#" + uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_OLD_DATA_COLOR)).toString(16).toUpperCase());
		}
		
		private static function setInitialGraphData():void
		{
			Trace.myTrace("WidgetService.as", "Setting initial widget data!");
			
			dateFormat = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_DATE_FORMAT);
			historyTimespan = int(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_HISTORY_TIMESPAN));
			widgetHistory = historyTimespan * TIME_1_HOUR;
			
			startupGlucoseReadingsList = ModelLocator.bgReadings.concat();
			activeGlucoseReadingsList = [];
			var now:Number = new Date().valueOf();
			var latestGlucoseReading:BgReading = startupGlucoseReadingsList[startupGlucoseReadingsList.length - 1];
			
			for(var i:int = startupGlucoseReadingsList.length - 1 ; i >= 0; i--)
			{
				var timestamp:Number = (startupGlucoseReadingsList[i] as BgReading).timestamp;
				
				if (now - timestamp <= widgetHistory)
				{
					var glucoseValue:Number = Number(BgGraphBuilder.unitizedString((startupGlucoseReadingsList[i] as BgReading).calculatedValue, CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true"));
					if (isNaN(glucoseValue) || glucoseValue < 40)
						glucoseValue = 38;
					
					activeGlucoseReadingsList.push( { value: glucoseValue, time: getGlucoseTimeFormatted(timestamp, true), timestamp: timestamp } );
				}
				else
					break;
			}
			
			activeGlucoseReadingsList.reverse();
			
			//Graph Data
			BackgroundFetch.setUserDefaultsData("chartData", JSON.stringify(activeGlucoseReadingsList));
			
			//Settings
			BackgroundFetch.setUserDefaultsData("smoothLine", CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_SMOOTH_LINE));
			BackgroundFetch.setUserDefaultsData("showMarkers", CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_SHOW_MARKERS));
			BackgroundFetch.setUserDefaultsData("showMarkerLabel", CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_SHOW_MARKER_LABEL));
			BackgroundFetch.setUserDefaultsData("showGridLines", CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_SHOW_GRID_LINES));
			BackgroundFetch.setUserDefaultsData("lineThickness", CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_LINE_THICKNESS));
			BackgroundFetch.setUserDefaultsData("markerRadius", CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_MARKER_RADIUS));
			
			//Display Labels Data
			if (latestGlucoseReading != null)
			{
				var timeFormatted:String = getGlucoseTimeFormatted(latestGlucoseReading.timestamp, false);
				var lastUpdate:String = getLastUpdate(latestGlucoseReading.timestamp) + ", " + timeFormatted;
				BackgroundFetch.setUserDefaultsData("latestWidgetUpdate", ModelLocator.resourceManagerInstance.getString('widgetservice','last_update_label') + " " + lastUpdate);
				BackgroundFetch.setUserDefaultsData("latestGlucoseTime", String(latestGlucoseReading.timestamp));
				BackgroundFetch.setUserDefaultsData("latestGlucoseValue", BgGraphBuilder.unitizedString(latestGlucoseReading.calculatedValue, CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true"));
				BackgroundFetch.setUserDefaultsData("latestGlucoseSlopeArrow", latestGlucoseReading.slopeArrow());
				BackgroundFetch.setUserDefaultsData("latestGlucoseDelta", MathHelper.formatNumberToStringWithPrefix(Number(BgGraphBuilder.unitizedDeltaString(false, true))));
			}
			
			//Threshold Values
			BackgroundFetch.setUserDefaultsData("urgenLowThreshold", CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_URGENT_LOW_MARK));
			BackgroundFetch.setUserDefaultsData("lowThreshold", CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_LOW_MARK));
			BackgroundFetch.setUserDefaultsData("highThreshold", CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_HIGH_MARK));
			BackgroundFetch.setUserDefaultsData("urgentHighThreshold", CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_URGENT_HIGH_MARK));
				
			//Colors
			BackgroundFetch.setUserDefaultsData("urgenLowColor", "#" + uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_URGENT_LOW_COLOR)).toString(16).toUpperCase());
			BackgroundFetch.setUserDefaultsData("lowColor", "#" + uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_LOW_COLOR)).toString(16).toUpperCase());
			BackgroundFetch.setUserDefaultsData("inRangeColor", "#" + uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_IN_RANGE_COLOR)).toString(16).toUpperCase());
			BackgroundFetch.setUserDefaultsData("highColor", "#" + uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_HIGH_COLOR)).toString(16).toUpperCase());
			BackgroundFetch.setUserDefaultsData("urgentHighColor", "#" + uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_URGENT_HIGH_COLOR)).toString(16).toUpperCase());
			BackgroundFetch.setUserDefaultsData("oldDataColor", "#" + uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_OLD_DATA_COLOR)).toString(16).toUpperCase());
			BackgroundFetch.setUserDefaultsData("displayLabelsColor", "#" + uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_DISPLAY_LABELS_COLOR)).toString(16).toUpperCase());
			BackgroundFetch.setUserDefaultsData("markerColor", "#" + uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_GLUCOSE_MARKER_COLOR)).toString(16).toUpperCase());
			BackgroundFetch.setUserDefaultsData("axisColor", "#" + uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_AXIS_COLOR)).toString(16).toUpperCase());
			BackgroundFetch.setUserDefaultsData("axisFontColor", "#" + uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_AXIS_FONT_COLOR)).toString(16).toUpperCase());
			BackgroundFetch.setUserDefaultsData("gridLinesColor", "#" + uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_GRID_LINES_COLOR)).toString(16).toUpperCase());
			BackgroundFetch.setUserDefaultsData("backgroundColor", "#" + uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_BACKGROUND_COLOR)).toString(16).toUpperCase());
			BackgroundFetch.setUserDefaultsData("backgroundOpacity", String(Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_BACKGROUND_OPACITY)) / 100));
			
			//Glucose Unit
			BackgroundFetch.setUserDefaultsData("glucoseUnit", GlucoseHelper.getGlucoseUnit());
			
			//Translations
			BackgroundFetch.setUserDefaultsData("minAgo", ModelLocator.resourceManagerInstance.getString('widgetservice','minute_ago'));
			BackgroundFetch.setUserDefaultsData("hourAgo", ModelLocator.resourceManagerInstance.getString('widgetservice','hour_ago'));
			BackgroundFetch.setUserDefaultsData("ago", ModelLocator.resourceManagerInstance.getString('widgetservice','ago'));
			BackgroundFetch.setUserDefaultsData("now", ModelLocator.resourceManagerInstance.getString('widgetservice','now'));
			BackgroundFetch.setUserDefaultsData("openSpike", ModelLocator.resourceManagerInstance.getString('widgetservice','open_spike'));
		}
		
		private static function processChartGlucoseValues():void
		{
			var currentTimestamp:Number = activeGlucoseReadingsList[0].timestamp;
			var now:Number = new Date().valueOf();
			
			while (now - currentTimestamp > widgetHistory) 
			{
				activeGlucoseReadingsList.shift();
				currentTimestamp = activeGlucoseReadingsList[0].timestamp;
			}
		}
		
		private static function onBloodGlucoseReceived(e:TransmitterServiceEvent):void
		{
			Trace.myTrace("WidgetService.as", "Sending new glucose reading to widget!");
			
			var currentReading:BgReading = BgReading.lastNoSensor();
			
			if (Calibration.allForSensor().length < 2 || currentReading == null || currentReading.calculatedValue == 0)
				return;
			
			activeGlucoseReadingsList.push( { value: currentReading.calculatedValue, time: getGlucoseTimeFormatted(currentReading.timestamp, true), timestamp: currentReading.timestamp } ); 
			processChartGlucoseValues();
			
			//Save data to User Defaults
			var latestGlucoseValue:Number = Number(BgGraphBuilder.unitizedString(currentReading.calculatedValue, CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true"));
			if (isNaN(latestGlucoseValue) || latestGlucoseValue < 40)
				latestGlucoseValue = 38;
			
			BackgroundFetch.setUserDefaultsData("latestWidgetUpdate", ModelLocator.resourceManagerInstance.getString('widgetservice','last_update_label') + " " + getLastUpdate(currentReading.timestamp) + ", " + getGlucoseTimeFormatted(currentReading.timestamp, false));
			BackgroundFetch.setUserDefaultsData("latestGlucoseValue", String(latestGlucoseValue));
			BackgroundFetch.setUserDefaultsData("latestGlucoseSlopeArrow", currentReading.slopeArrow());
			BackgroundFetch.setUserDefaultsData("latestGlucoseDelta", MathHelper.formatNumberToStringWithPrefix(Number(BgGraphBuilder.unitizedDeltaString(false, true))));
			BackgroundFetch.setUserDefaultsData("latestGlucoseTime", String(currentReading.timestamp));
			BackgroundFetch.setUserDefaultsData("chartData", JSON.stringify(activeGlucoseReadingsList));
		}
		
		/**
		 * Utility
		 */
		private static function getLastUpdate(timestamp:Number):String
		{
			var glucoseDate:Date = new Date(timestamp);
			
			return months[glucoseDate.month] + " " + glucoseDate.date;
		}
		
		private static function getGlucoseTimeFormatted(timestamp:Number, formatForChartLabel:Boolean):String
		{
			var glucoseDate:Date = new Date(timestamp);
			var timeFormatted:String;
			
			if (dateFormat.slice(0,2) == "24")
			{
				if (formatForChartLabel)
					timeFormatted = TimeSpan.formatHoursMinutes(glucoseDate.getHours(), glucoseDate.getMinutes(), TimeSpan.TIME_FORMAT_24H, widgetHistory == TIME_2_HOURS);
				else
					timeFormatted = TimeSpan.formatHoursMinutes(glucoseDate.getHours(), glucoseDate.getMinutes(), TimeSpan.TIME_FORMAT_24H);
			}
			else
			{
				if (formatForChartLabel)
					timeFormatted = TimeSpan.formatHoursMinutes(glucoseDate.getHours(), glucoseDate.getMinutes(), TimeSpan.TIME_FORMAT_12H, widgetHistory == TIME_2_HOURS, widgetHistory == TIME_1_HOUR);
				else
					timeFormatted = TimeSpan.formatHoursMinutes(glucoseDate.getHours(), glucoseDate.getMinutes(), TimeSpan.TIME_FORMAT_12H);
			}
			
			return timeFormatted;
		}
	}
}