package services
{
	import com.distriqt.extension.calendar.AuthorisationStatus;
	import com.distriqt.extension.calendar.Calendar;
	import com.distriqt.extension.calendar.events.AuthorisationEvent;
	import com.distriqt.extension.calendar.objects.EventObject;
	
	import flash.events.Event;
	
	import database.BgReading;
	import database.CGMBlueToothDevice;
	import database.Calibration;
	import database.CommonSettings;
	import database.LocalSettings;
	
	import distriqtkey.DistriqtKey;
	
	import events.FollowerEvent;
	import events.SettingsServiceEvent;
	import events.SpikeEvent;
	import events.TransmitterServiceEvent;
	import events.TreatmentsEvent;
	
	import model.Forecast;
	import model.ModelLocator;
	
	import treatments.Treatment;
	import treatments.TreatmentsManager;
	
	import ui.chart.helpers.GlucoseFactory;
	import ui.popups.AlertManager;
	
	import utils.BgGraphBuilder;
	import utils.GlucoseHelper;
	import utils.TimeSpan;
	import utils.Trace;
	import utils.UniqueId;
	
	[ResourceBundle("treatments")]
	[ResourceBundle("watchsettingsscreen")]
	[ResourceBundle("globaltranslations")]
	
	public class WatchService
	{
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
		private static var applyGapFix:Boolean;
		private static var displayCOBEnabled:Boolean;
		private static var displayIOBEnabled:Boolean;
		private static var displayPredictionsEnabled:Boolean;
		
		public function WatchService()
		{
			throw new Error("WatchService is not meant to be instantiated!");
		}
		
		public static function init():void
		{
			Trace.myTrace("WatchService.as", "Service started!");
			
			Spike.instance.addEventListener(SpikeEvent.APP_HALTED, onHaltExecution);
			
			try
			{
				Calendar.init( !ModelLocator.IS_IPAD ? DistriqtKey.distriqtKey : DistriqtKey.distriqtKeyIpad );
				if (Calendar.isSupported)
				{
					getInitialProperties();
					LocalSettings.instance.addEventListener(SettingsServiceEvent.SETTING_CHANGED, onSettingsChanged);
					
					if (Calendar.service.authorisationStatus() == AuthorisationStatus.AUTHORISED && watchComplicationEnabled && calendarID != "")
					{
						activateService();
					}
					else if (Calendar.service.authorisationStatus() != AuthorisationStatus.AUTHORISED && watchComplicationEnabled && calendarID != "")
					{
						Calendar.service.addEventListener( AuthorisationEvent.CHANGED, onCalendarAuthorisation );
						Calendar.service.requestAccess();
					}
				}
			}
			catch (e:Error)
			{
				Trace.myTrace("WatchService.as", "Error initiating Calendar ANE: " + e);
			}
		}
		
		private static function onCalendarAuthorisation(event:AuthorisationEvent):void
		{
			Calendar.service.removeEventListener( AuthorisationEvent.CHANGED, onCalendarAuthorisation );
			
			if (Calendar.service.authorisationStatus() == AuthorisationStatus.AUTHORISED)
			{
				activateService();
			}
			else
			{
				Trace.myTrace("WatchService.as", "Error authorizing calendar access. Notifying user...");
				
				AlertManager.showSimpleAlert
				(
					ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
					ModelLocator.resourceManagerInstance.getString('watchsettingsscreen','alert_message_manual_athorization_2')
				)
			}
		}
		
		/**
		 * Functionality
		 */
		private static function getInitialProperties():void
		{
			watchComplicationEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_ON) == "true";
			displayNameEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_NAME_ON) == "true";
			displayPredictionsEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_PREDICTIONS_ON) == "true";
			displayNameValue = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_NAME);
			calendarID = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_SELECTED_CALENDAR_ID);;
			displayTrendEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_TREND) == "true";
			displayDeltaEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_DELTA) == "true";
			displayUnitsEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_UNITS) == "true";
			applyGapFix = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_GAP_FIX_ON) == "true" || CGMBlueToothDevice.isFollower() || CGMBlueToothDevice.isMiaoMiao();
			displayIOBEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_IOB_ON) == "true";
			displayCOBEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_COB_ON) == "true";
		}
		
		private static function activateService():void
		{
			Trace.myTrace("WatchService.as", "Service activated!");
			
			serviceActive = true;
			TransmitterService.instance.addEventListener(TransmitterServiceEvent.LAST_BGREADING_RECEIVED, onBloodGlucoseReceived, false, 160, false);
			NightscoutService.instance.addEventListener(FollowerEvent.BG_READING_RECEIVED, onBloodGlucoseReceived, false, 160, false);
			DexcomShareService.instance.addEventListener(FollowerEvent.BG_READING_RECEIVED, onBloodGlucoseReceived, false, 160, false);
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
			TransmitterService.instance.removeEventListener(TransmitterServiceEvent.LAST_BGREADING_RECEIVED, onBloodGlucoseReceived);
			NightscoutService.instance.removeEventListener(FollowerEvent.BG_READING_RECEIVED, onBloodGlucoseReceived);
			DexcomShareService.instance.removeEventListener(FollowerEvent.BG_READING_RECEIVED, onBloodGlucoseReceived);
			TreatmentsManager.instance.removeEventListener(TreatmentsEvent.TREATMENT_ADDED, onTreatmentsChanged);
			TreatmentsManager.instance.removeEventListener(TreatmentsEvent.TREATMENT_DELETED, onTreatmentsChanged);
			TreatmentsManager.instance.removeEventListener(TreatmentsEvent.TREATMENT_UPDATED, onTreatmentsChanged);
			TreatmentsManager.instance.removeEventListener(TreatmentsEvent.IOB_COB_UPDATED, onTreatmentsChanged);
			deleteAllEvents();
		}
		
		private static function deleteAllEvents():void
		{
			Trace.myTrace("WatchService.as", "Deleting all previous calendar events");
			
			var now:Date = new Date();
			var past:Date = new Date(now.valueOf() - TimeSpan.TIME_24_HOURS);
			deleteEvents(past, now, calendarID, "Created by Spike");
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
		
		private static function processLatestGlucose(initialStart:Boolean = false):void
		{
			Trace.myTrace("WatchService.as", "Syncing glucose and treatments to watch.");
			
			//Get glucose output
			var currentReading:BgReading = !CGMBlueToothDevice.isFollower() ? BgReading.lastNoSensor() : BgReading.lastWithCalculatedValue();
			var glucoseValue:String;
			
			//Initial Start Validation
			if (initialStart)
				if (currentReading == null || currentReading.calculatedValue == 0 || (new Date()).valueOf() - currentReading.timestamp > TimeSpan.TIME_5_MINUTES)
					return;
			
			if (currentReading != null && currentReading.calculatedValue != 0) 
			{
				if ((new Date().getTime()) - (60000 * 11) - currentReading.timestamp > 0)
					glucoseValue = "---"
				else 
				{
					glucoseValue = BgGraphBuilder.unitizedString(currentReading.calculatedValue, CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true");
					
					if (!currentReading.hideSlope && displayTrendEnabled)
						glucoseValue += " " + currentReading.slopeArrow();
					
					if (displayDeltaEnabled)
					{
						glucoseValue += " " + GlucoseHelper.calculateLatestDelta(true);
						glucoseValue += displayUnitsEnabled ? " " + GlucoseHelper.getGlucoseUnit() : "";
					}
					else if (!displayDeltaEnabled && displayUnitsEnabled)
						glucoseValue += " " + GlucoseHelper.getGlucoseUnit();
				}
			}
			else
				glucoseValue = "---";	
			
			//Event dates
			var now:Number = currentReading != null ? currentReading.timestamp : new Date().valueOf();
			
			var future:Number;
			if (currentReading != null && currentReading.calculatedValue != 0)
				future = !applyGapFix ? currentReading.timestamp + TimeSpan.TIME_5_MINUTES : currentReading.timestamp + TimeSpan.TIME_10_MINUTES;
			else
				future = !applyGapFix ? new Date().valueOf() + TimeSpan.TIME_5_MINUTES : new Date().valueOf() + TimeSpan.TIME_10_MINUTES;
			
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
					title += ModelLocator.resourceManagerInstance.getString('treatments','cob_label').charAt(0) + ":" + GlucoseFactory.formatCOB(TreatmentsManager.getTotalCOB(nowTreatments, CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEFAULT_IOB_COB_ALGORITHM) == "openaps").cob) + " " + ModelLocator.resourceManagerInstance.getString('treatments','iob_label').charAt(0) + ":" + GlucoseFactory.formatIOB(TreatmentsManager.getTotalIOB(nowTreatments).iob);
				else if (displayIOBEnabled)
					title += ModelLocator.resourceManagerInstance.getString('treatments','iob_label') + ":" + GlucoseFactory.formatIOB(TreatmentsManager.getTotalIOB(nowTreatments).iob);
				else if (displayCOBEnabled)
					title += ModelLocator.resourceManagerInstance.getString('treatments','cob_label') + ":" + GlucoseFactory.formatCOB(TreatmentsManager.getTotalCOB(nowTreatments, CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEFAULT_IOB_COB_ALGORITHM) == "openaps").cob);
			}
			
			if (displayPredictionsEnabled)
			{
				if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_GLUCOSE_PREDICTIONS_ENABLED) == "true")
				{
					var predictionsLengthInMinutes:Number = Forecast.getCurrentPredictionsDuration();
					if (!isNaN(predictionsLengthInMinutes))
					{
						var currentPrediction:Number = Forecast.getLastPredictiveBG(predictionsLengthInMinutes);
						if (!isNaN(currentPrediction))
						{
							title += "\n" + TimeSpan.formatHoursMinutesFromMinutes(predictionsLengthInMinutes, false) + ": " + (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true" ? String(Math.round(currentPrediction)) : String(Math.round(BgReading.mgdlToMmol(currentPrediction * 10)) / 10)) + (displayUnitsEnabled ? " " + GlucoseHelper.getGlucoseUnit() : "");
						}
						else
						{
							title += "\n" + TimeSpan.formatHoursMinutesFromMinutes(predictionsLengthInMinutes, false) + ": " + ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available');
						}
					}
				}
			}
			
			//Create watch event
			var watchEvent:EventObject = new EventObject();
			watchEvent.title = title;
			watchEvent.notes = "Created by Spike, ID: " + UniqueId.createNonce(6);
			watchEvent.startTimestamp = now;
			watchEvent.endTimestamp = future;
			watchEvent.calendarId = calendarID;
			
			//Delete all previous events from the calendar
			deleteAllEvents();
			
			//Sync new event to watch
			Calendar.service.addEvent( watchEvent );
		}
		
		/**
		 * Event Listeners
		 */
		private static function onBloodGlucoseReceived(e:Event):void
		{
			if ((Calibration.allForSensor().length < 2 && !CGMBlueToothDevice.isFollower()) || Calendar.service.authorisationStatus() != AuthorisationStatus.AUTHORISED || !watchComplicationEnabled || calendarID == "")
				return;
			
			processLatestGlucose();
		}
		
		private static function onTreatmentsChanged(e:TreatmentsEvent):void
		{
			if (e.treatment != null && e.treatment.type == Treatment.TYPE_EXTENDED_COMBO_BOLUS_CHILD)
				return;
			
			if (displayCOBEnabled || displayIOBEnabled)
				processLatestGlucose();
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
				e.data == LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_GAP_FIX_ON ||
				e.data == LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_IOB_ON ||
				e.data == LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_COB_ON ||
				e.data == LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_PREDICTIONS_ON
			)
			{
				getInitialProperties();
				
				if 
				(
					e.data == LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_IOB_ON ||
					e.data == LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_COB_ON
				)
					onTreatmentsChanged(null);
				else if 
				(
					e.data == LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_NAME_ON || 
					e.data == LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_NAME ||
					e.data == LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_UNITS ||
					e.data == LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_SELECTED_CALENDAR_ID ||
					e.data == LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_TREND ||
					e.data == LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_DELTA ||
					e.data == LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_DELTA ||
					e.data == LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_GAP_FIX_ON ||
					e.data == LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_PREDICTIONS_ON
				)
					onBloodGlucoseReceived(null);
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
		
		/**
		 * Stops the service entirely. Useful for database restores
		 */
		private static function onHaltExecution(e:SpikeEvent):void
		{
			Trace.myTrace("WatchService.as", "Stopping service...");
			
			LocalSettings.instance.removeEventListener(SettingsServiceEvent.SETTING_CHANGED, onSettingsChanged);
			
			deactivateService();
			
			Trace.myTrace("WatchService.as", "Service stopped!");
		}
	}
}