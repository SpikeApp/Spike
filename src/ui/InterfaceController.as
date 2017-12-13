package ui
{
	import flash.events.Event;
	
	import Utilities.Trace;
	
	import databaseclasses.Database;
	
	import events.DatabaseEvent;

	public class InterfaceController
	{
		private static var initialStart:Boolean = true;
		
		public function InterfaceController() {}
		
		public static function init():void
		{
			
			if (initialStart) {
				Trace.init();
				Database.instance.addEventListener(DatabaseEvent.DATABASE_INIT_FINISHED_EVENT,onInitResult);
				Database.instance.addEventListener(DatabaseEvent.ERROR_EVENT,onInitError);
				//need to know when modellocator is populated, then we can also update display
				//Database.instance.addEventListener(DatabaseEvent.BGREADING_RETRIEVAL_EVENT, bgReadingReceivedFromDatabase);
				Database.init();
				initialStart = false;
				//CommonSettings.instance.addEventListener(SettingsServiceEvent.SETTING_CHANGED, settingChanged);
				
				
				/*dateFormatterForSensorStartTimeAndDate = new DateTimeFormatter();
				dateFormatterForSensorStartTimeAndDate.dateTimePattern = ModelLocator.resourceManagerInstance.getString('homeview','datetimepatternforstatusinfo');
				dateFormatterForSensorStartTimeAndDate.useUTC = false;
				dateFormatterForSensorStartTimeAndDate.setStyle("locale",Capabilities.language.substr(0,2));*/
			}
			
			
			function onInitResult(event:Event):void
			{
				trace("Interface Controller : Database initialized successfully!");
				//at this moment the database is intialised, but the logs, bgreadings, ... might still be read in the ModelLocator, Modellocator is listening to the same event
				
				//set calibration button in the correct state
				/*if (Calibration.allForSensor().length > 1) {
					_calibrateButtonActive = true;
				}*
				
				/*BluetoothService.instance.addEventListener(BlueToothServiceEvent.BLUETOOTH_SERVICE_INITIATED, blueToothServiceInitiated);
				
				TransmitterService.instance.addEventListener(TransmitterServiceEvent.BGREADING_EVENT, transmitterServiceBGReadingEventReceived);
				
				CalibrationService.instance.addEventListener(CalibrationServiceEvent.INITIAL_CALIBRATION_EVENT, initialCalibrationEventReceived);
				CalibrationService.instance.addEventListener(CalibrationServiceEvent.NEW_CALIBRATION_EVENT, newCalibrationEventReceived);*/
				
			}
			
			function onInitError(event:Event):void
			{	
				trace("Interface Controller : Error initializing database!");
			}
			
		}
		
		
	}
}