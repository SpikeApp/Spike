package services
{
	import com.distriqt.extension.calendar.AuthorisationStatus;
	import com.distriqt.extension.calendar.Calendar;
	import com.distriqt.extension.calendar.objects.EventObject;
	
	import database.BgReading;
	import database.Calibration;
	import database.CommonSettings;
	import database.LocalSettings;
	
	import distriqtkey.DistriqtKey;
	
	import events.SettingsServiceEvent;
	import events.TransmitterServiceEvent;
	
	import model.ModelLocator;
	
	import utils.BgGraphBuilder;
	import utils.Trace;
	import utils.UniqueId;
	
	[ResourceBundle("generalsettingsscreen")]

	public class WatchService
	{
		/* Constants */
		private static const TIME_5_MINUTES:int = (5 * 60 * 1000) + 7000;
		private static const TIME_6_MINUTES:int = 6 * 60 * 1000;
		private static const TIME_1_DAY:int = 24 * 60 * 60 * 1000;
		
		/* Objects */
		private static var previousNow:Date;
		private static var previousFuture:Date;
		private static var queue:Array = [];
		
		/* Properties */
		private static var initialStart:Boolean = true;
		private static var serviceActive:Boolean = false;
		private static var calendarID:String;
		private static var watchComplicationEnabled:Boolean;
		private static var displayNameEnabled:Boolean;
		private static var displayNameValue:String;
		private static var displayTrendEnabled:Boolean;
		private static var displayDeltaEnabled:Boolean;
		private static var displayUnitsEnabled:Boolean;
		private static var glucoseHistoryValue:int;
		
		public function WatchService()
		{
			throw new Error("WatchService is not meant to be instantiated!");
		}
		
		public static function init():void
		{
			Trace.myTrace("WatchService.as", "Service started!");
			
			try
			{
				Calendar.init( DistriqtKey.distriqtKey );
				if (Calendar.isSupported)
				{
					getInitialProperties();
					LocalSettings.instance.addEventListener(SettingsServiceEvent.SETTING_CHANGED, onSettingsChanged);
					
					if (Calendar.service.authorisationStatus() == AuthorisationStatus.AUTHORISED && watchComplicationEnabled && calendarID != "")
						activateService();
				}
			}
			catch (e:Error)
			{
				Trace.myTrace("WatchService.as", "Error initiating Calendar ANE: " + e);
			}
		}
		
		/**
		 * Functionality
		 */
		private static function getInitialProperties():void
		{
			watchComplicationEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_ON) == "true";
			displayNameEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_NAME_ON) == "true";
			displayNameValue = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_NAME);
			calendarID = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_SELECTED_CALENDAR_ID);;
			displayTrendEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_TREND) == "true";
			displayDeltaEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_DELTA) == "true";
			displayUnitsEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_UNITS) == "true";
			glucoseHistoryValue = int(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_GLUCOSE_HISTORY));
		}
		
		private static function activateService():void
		{
			Trace.myTrace("WatchService.as", "Service activated!");
			
			serviceActive = true;
			TransmitterService.instance.addEventListener(TransmitterServiceEvent.BGREADING_EVENT, onBloodGlucoseReceived);
			deleteAllEvents();
			processLatestGlucose(true);
		}
		
		private static function deactivateService():void
		{
			Trace.myTrace("WatchService.as", "Service deactivated!");
			
			serviceActive = false;
			TransmitterService.instance.removeEventListener(TransmitterServiceEvent.BGREADING_EVENT, onBloodGlucoseReceived);
			deleteAllEvents();
		}
		
		private static function processQueue():void
		{
			while (queue.length > glucoseHistoryValue) 
			{
				var eventObject:EventObject = queue.shift();
				trace("Deleting event: ", eventObject.notes);
				deleteEvents(new Date(eventObject.startTimestamp), new Date(eventObject.endTimestamp), eventObject.calendarId, eventObject.notes);
				eventObject = null;
			}
		}
		
		private static function clearQueue():void
		{
			var queueLength:uint = queue.length;
			if (queueLength > 0)
			{
				for (var i:int = 0; i < queueLength; i++) 
				{
					var eventObject:EventObject = queue[i];
					eventObject = null;
				}
				
				queue.length = 0;
			}
		}
		
		private static function deleteAllEvents():void
		{
			Trace.myTrace("WatchService.as", "Deleting all previous calendar events");
			
			var now:Date = new Date();
			var past:Date = new Date(now.valueOf() - TIME_1_DAY);
			deleteEvents(past, now, calendarID, "Created by Spike");
			clearQueue();
		}
		
		private static function deleteEvents(startDate:Date, endDate:Date, calendarID:String, keyword:String):void
		{
			var events:Array = Calendar.service.getEvents( startDate, endDate, calendarID );
			for each (var event:EventObject in events)
			{
				if (event.notes.indexOf(keyword) != -1)
					Calendar.service.removeEvent(event);
			}
		}
		
		private static function getLastEvent(eventObject:EventObject):EventObject
		{
			var calendarEvent:EventObject;
			var calendarEvents:Array = Calendar.service.getEvents( new Date(eventObject.startTimestamp), new Date(eventObject.endTimestamp), calendarID );
			for (var i:int = 0; i < calendarEvents.length; i++) 
			{
				var tempCalendarEvent:EventObject = calendarEvents[i];
				if (tempCalendarEvent.notes.indexOf(eventObject.notes) != -1)
				{
					calendarEvent = tempCalendarEvent;
					break;
				}
			}
			
			
			return calendarEvent;
		}
		
		private static function processLatestGlucose(initialStart:Boolean = false):void
		{
			//Get glucose output
			var currentReading:BgReading = BgReading.lastNoSensor();
			var glucoseValue:String;
			
			//Initial Start Validation
			if (initialStart)
				if (currentReading == null || currentReading.calculatedValue == 0 || (new Date()).valueOf() - currentReading.timestamp > TIME_5_MINUTES)
					return;
			
			if (currentReading != null) 
			{
				if (currentReading.calculatedValue != 0) 
				{
					if ((new Date().getTime()) - (60000 * 11) - currentReading.timestamp > 0)
						glucoseValue = "---"
					else 
					{
						glucoseValue = BgGraphBuilder.unitizedString(currentReading.calculatedValue, CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true");
						
						if (!currentReading.hideSlope && displayTrendEnabled)
							glucoseValue += " " + currentReading.slopeArrow();
						
						if (displayDeltaEnabled)
							glucoseValue += " " + BgGraphBuilder.unitizedDeltaString(displayUnitsEnabled, true);
						else if (!displayDeltaEnabled && displayUnitsEnabled)
						{
							if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true")
								glucoseValue += " " + ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','mgdl');
							else
								glucoseValue += " " + ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','mmol');
						}
					}
				}
			}
			else
				glucoseValue = "---";	
			
			//Event dates
			var now:Number;
			if (!initialStart)
			{
				if (queue.length > 0)
				{
					var previousEvent:EventObject = getLastEvent(queue[queue.length - 1]);
					if (previousEvent != null)
						now = previousEvent.endTimestamp;
					else
						now = (new Date()).valueOf();
				}
				else
					now = (new Date()).valueOf();
			}
			else
				now = currentReading.timestamp;	
			
			var future:Number;
			if (currentReading != null && currentReading.calculatedValue != 0)
				future = currentReading.timestamp + TIME_5_MINUTES;
			else
				future = now + TIME_5_MINUTES;
			
			//Title
			var title:String = "";
			if (displayNameEnabled && displayNameValue != "")
				title += displayNameValue + "\n";
			title += glucoseValue;
			
			//Create watch event
			var watchEvent:EventObject = new EventObject();
			watchEvent.title = title;
			watchEvent.notes = "Created by Spike, ID: " + UniqueId.createNonce(6);
			watchEvent.startTimestamp = now;
			watchEvent.endTimestamp = future;
			watchEvent.calendarId = calendarID;
			
			Calendar.service.addEvent( watchEvent );
			
			//Add watch event to queue
			queue.push(watchEvent);
		}
		
		/**
		 * Event Listeners
		 */
		protected static function onBloodGlucoseReceived(e:TransmitterServiceEvent):void
		{
			if (Calibration.allForSensor().length < 2 || Calendar.service.authorisationStatus() != AuthorisationStatus.AUTHORISED || !watchComplicationEnabled || calendarID == "")
				return;
			
			//Process Latest Glucose
			processLatestGlucose();
			
			//Process Queue
			processQueue();
		}
		
		private static function onSettingsChanged(event:SettingsServiceEvent):void
		{
			getInitialProperties();
			if (Calendar.service.authorisationStatus() == AuthorisationStatus.AUTHORISED && watchComplicationEnabled && calendarID != "")
			{
				if (!serviceActive)
					activateService();
			}
			else
				deactivateService();
		}
	}
}