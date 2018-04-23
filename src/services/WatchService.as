package services
{
	import com.distriqt.extension.calendar.AuthorisationStatus;
	import com.distriqt.extension.calendar.Calendar;
	import com.distriqt.extension.calendar.objects.EventObject;
	
	import flash.events.Event;
	
	import database.BgReading;
	import database.BlueToothDevice;
	import database.Calibration;
	import database.CommonSettings;
	import database.LocalSettings;
	
	import distriqtkey.DistriqtKey;
	
	import events.FollowerEvent;
	import events.SettingsServiceEvent;
	import events.TransmitterServiceEvent;
	import events.TreatmentsEvent;
	
	import model.ModelLocator;
	
	import treatments.TreatmentsManager;
	
	import ui.chart.GlucoseFactory;
	
	import utils.BgGraphBuilder;
	import utils.Trace;
	import utils.UniqueId;
	
	[ResourceBundle("generalsettingsscreen")]

	public class WatchService
	{
		/* Constants */
		private static const TIME_5_MINUTES:int = (5 * 60 * 1000) + 7000;
		private static const TIME_6_MINUTES:int = 6 * 60 * 1000;
		private static const TIME_10_MINUTES:int = 10 * 60 * 1000;
		private static const TIME_30_MINUTES:int = 30 * 60 * 1000;
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
		private static var applyGapFix:Boolean;
		private static var displayCOBEnabled:Boolean;
		private static var displayIOBEnabled:Boolean;
		
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
			applyGapFix = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_GAP_FIX_ON) == "true";
			displayIOBEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_IOB_ON) == "true";
			displayCOBEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_COB_ON) == "true";
		}
		
		private static function activateService():void
		{
			Trace.myTrace("WatchService.as", "Service activated!");
			
			serviceActive = true;
			TransmitterService.instance.addEventListener(TransmitterServiceEvent.BGREADING_EVENT, onBloodGlucoseReceived);
			NightscoutService.instance.addEventListener(FollowerEvent.BG_READING_RECEIVED, onBloodGlucoseReceived);
			TreatmentsManager.instance.addEventListener(TreatmentsEvent.TREATMENT_ADDED, onTreatmentsChanged);
			TreatmentsManager.instance.addEventListener(TreatmentsEvent.TREATMENT_DELETED, onTreatmentsChanged);
			TreatmentsManager.instance.addEventListener(TreatmentsEvent.TREATMENT_UPDATED, onTreatmentsChanged);
			TreatmentsManager.instance.addEventListener(TreatmentsEvent.IOB_COB_UPDATED, onTreatmentsChanged);
			deleteAllEvents();
			processLatestGlucose(true);
		}
		
		private static function deactivateService():void
		{
			Trace.myTrace("WatchService.as", "Service deactivated!");
			
			serviceActive = false;
			TransmitterService.instance.removeEventListener(TransmitterServiceEvent.BGREADING_EVENT, onBloodGlucoseReceived);
			NightscoutService.instance.removeEventListener(FollowerEvent.BG_READING_RECEIVED, onBloodGlucoseReceived);
			TreatmentsManager.instance.removeEventListener(TreatmentsEvent.TREATMENT_ADDED, onTreatmentsChanged);
			TreatmentsManager.instance.removeEventListener(TreatmentsEvent.TREATMENT_DELETED, onTreatmentsChanged);
			TreatmentsManager.instance.removeEventListener(TreatmentsEvent.TREATMENT_UPDATED, onTreatmentsChanged);
			TreatmentsManager.instance.removeEventListener(TreatmentsEvent.IOB_COB_UPDATED, onTreatmentsChanged);
			deleteAllEvents();
		}
		
		private static function processQueue():void
		{
			while (queue.length > glucoseHistoryValue) 
			{
				var eventObject:EventObject = queue.shift();
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
		
		private static function deleteLastEvent():void
		{
			if (queue.length > 0)
			{
				var now:Number = new Date().valueOf();
				var lastEvent:EventObject = queue[queue.length - 1] as EventObject;
				var events:Array = Calendar.service.getEvents( new Date(now - TIME_30_MINUTES), new Date(now), calendarID );
				for each (var event:EventObject in events)
				{
					if (event != null && event.notes != null && lastEvent != null && lastEvent.notes != null && event.notes.indexOf(lastEvent.notes) != -1)
					{
						Calendar.service.removeEvent(event);
						removeEventFromQueue(event);
						lastEvent = null;
					}
				}
			}
		}
		
		private static function removeEventFromQueue(event:EventObject):void
		{
			for(var i:int = queue.length - 1 ; i >= 0; i--)
			{
				var queueEvent:EventObject = queue[i];
				if (queueEvent != null && queueEvent.notes == event.notes)
				{
					var removedEvent:EventObject = queue.removeAt(i);
					removedEvent = null;
					break;
				}
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
		
		private static function adjustPreviousGlucose():void
		{
			if (queue.length < 2)
				return;
			
			var previousEvent:EventObject = queue[queue.length - 2] as EventObject;
			var startDate:Date = previousEvent.startDate
			var events:Array = Calendar.service.getEvents( startDate, new Date() );
			
			for each (var event:EventObject in events)
			{
				if (event.notes == previousEvent.notes)
				{
					//Match found... Let's edit the start/end time of the event so it doesn't overlap the last one
					var lastEvent:EventObject = queue[queue.length - 1] as EventObject;
					var editedEvent:EventObject = new EventObject;
					editedEvent.title = event.title;
					editedEvent.notes = event.notes;
					editedEvent.startDate = event.startDate;
					editedEvent.endDate = new Date(lastEvent.startDate.valueOf() - 100); //minus 100ms
					editedEvent.calendarId = calendarID;
					
					//Delete the Event
					Calendar.service.removeEvent(event);
					
					//Add the new modified event that will replace the one we just deleted
					Calendar.service.addEvent(editedEvent);
					
					queue[queue.length - 2] = editedEvent;
					
					break;
				}
			}
		}
		
		private static function processLatestGlucose(initialStart:Boolean = false):void
		{
			Trace.myTrace("WatchService.as", "Syncing glucose and treatments to watch.");
			
			//Get glucose output
			var currentReading:BgReading;
			if (!BlueToothDevice.isFollower())
				currentReading = BgReading.lastNoSensor();
			else
				currentReading = BgReading.lastWithCalculatedValue();
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
			var previousEvent:EventObject;
			if (!initialStart)
				now = (new Date()).valueOf();
			else
				now = currentReading.timestamp;	
			
			var future:Number;
			if (currentReading != null && currentReading.calculatedValue != 0)
			{
				if (!applyGapFix)
					future = currentReading.timestamp + TIME_5_MINUTES;
				else
					future = currentReading.timestamp + TIME_10_MINUTES;
			}
			else
			{
				if (!applyGapFix)
					future = now + TIME_5_MINUTES;
				else
					future = now + TIME_10_MINUTES;
			}
			
			//Title
			var title:String = "";
			if (displayNameEnabled && displayNameValue != "")
				title += displayNameValue + "\n";
			title += glucoseValue;
			if (displayIOBEnabled || displayCOBEnabled)
			{
				title += "\n";
				var nowTreatments:Number = new Date().valueOf();
				if (displayIOBEnabled && displayCOBEnabled)
					title += "I:" + GlucoseFactory.formatIOB(TreatmentsManager.getTotalIOB(nowTreatments)) + " " + "C:" + GlucoseFactory.formatCOB(TreatmentsManager.getTotalCOB(nowTreatments));
				else if (displayIOBEnabled)
					title += "IOB:" + GlucoseFactory.formatIOB(TreatmentsManager.getTotalIOB(nowTreatments));
				else if (displayCOBEnabled)
					title += "COB:" + GlucoseFactory.formatCOB(TreatmentsManager.getTotalCOB(nowTreatments));
			}
			
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
			
			//Adjust previous glucose
			adjustPreviousGlucose();
		}
		
		/**
		 * Event Listeners
		 */
		private static function onBloodGlucoseReceived(e:Event):void
		{
			if ((Calibration.allForSensor().length < 2 && !BlueToothDevice.isFollower()) || Calendar.service.authorisationStatus() != AuthorisationStatus.AUTHORISED || !watchComplicationEnabled || calendarID == "")
				return;
			
			//Process Latest Glucose
			processLatestGlucose();
			
			//Process Queue
			processQueue();
		}
		
		private static function onTreatmentsChanged(e:Event):void
		{
			//Process Latest Glucose
			if (displayCOBEnabled || displayIOBEnabled)
			{
				deleteLastEvent();
				processLatestGlucose();
			}
		}
		
		private static function onSettingsChanged(e:SettingsServiceEvent):void
		{
			if (e.data == LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_ON || 
				e.data == LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_NAME_ON || 
				e.data == LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_NAME ||
				e.data == LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_SELECTED_CALENDAR_ID ||
				e.data == LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_TREND ||
				e.data == LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_DELTA ||
				e.data == LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_UNITS ||
				e.data == LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_GLUCOSE_HISTORY ||
				e.data == LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_GAP_FIX_ON ||
				e.data == LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_IOB_ON ||
				e.data == LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_COB_ON
			)
			{
				getInitialProperties();
				if 
				(
					e.data == LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_IOB_ON ||
					e.data == LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_COB_ON ||
					e.data == LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_NAME_ON || 
					e.data == LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_NAME ||
					e.data == LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_GAP_FIX_ON
				)
					onTreatmentsChanged(null);
			}
			else
				return;
				
			if (Calendar.service.authorisationStatus() == AuthorisationStatus.AUTHORISED && watchComplicationEnabled && calendarID != "")
			{
				if (!serviceActive)
					activateService();
			}
			else
			{
				if (serviceActive)
					deactivateService();
			}
		}
	}
}