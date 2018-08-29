package utils
{
	import flash.utils.ByteArray;
	
	import database.BgReading;
	import database.CGMBlueToothDevice;
	import database.Calibration;
	import database.Database;
	import database.LocalSettings;
	
	import events.DatabaseEvent;
	
	import model.ModelLocator;
	
	import starling.events.Event;
	import starling.events.EventDispatcher;
	
	import ui.popups.AlertManager;
	import ui.popups.EmailFileSender;
	
	[ResourceBundle("sidiary")]
	
	public class SiDiary extends EventDispatcher
	{
		/* Variables */
		private static var fileName:String;
		private static var lastExportTimeStamp:Number;
		private static var output:String;
		
		/* Properties */
		private static var _instance:SiDiary = new SiDiary();
		
		/* Objects */
		private static var fileData:ByteArray;
		private static var readingsList:Array;
		
		public function SiDiary()
		{
			if (_instance != null)
				throw new Error("SiDiary is not meant to be instantiated");
		}
		
		/**
		 * Functionality
		 */
		public static function exportSiDiary():void 
		{
			Trace.myTrace("SiDiary.as", "User requested export...");
			
			//Instantiate objects
			readingsList = [];
			lastExportTimeStamp = Number(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_TIMESTAMP_SINCE_LAST_EXPORT_SIDIARY));
			
			//Validation
			if (ModelLocator.bgReadings == null || ModelLocator.bgReadings.length == 0)
			{
				AlertManager.showSimpleAlert
				(
					ModelLocator.resourceManagerInstance.getString("sidiary","alert_title"),
					ModelLocator.resourceManagerInstance.getString("sidiary","no_data_alert_message")
				);
				
				//Warn listeners
				_instance.dispatchEventWith(starling.events.Event.COMPLETE);
				
				return
			}
			
			const firstReading:BgReading = ModelLocator.bgReadings[0] as BgReading;
			
			if (lastExportTimeStamp > firstReading.timestamp || CGMBlueToothDevice.isFollower())
			{
				Trace.myTrace("SiDiary.as", "Using ModelLocator readings...");
				
				//Use ModelLocator readings list
				readingsList = ModelLocator.bgReadings.concat();
				formatData();
			}
			else
			{
				Trace.myTrace("SiDiary.as", "Using database readings...");
				
				//Use readings from database
				Database.instance.addEventListener(DatabaseEvent.BGREADING_RETRIEVAL_EVENT, onBgReadingsReceived);
				Database.getBgReadingsData(lastExportTimeStamp, Number(new Date().valueOf()), "timestamp, calculatedValue");
				
				function onBgReadingsReceived(de:DatabaseEvent):void 
				{
					Trace.myTrace("SiDiary.as", "Got data from database...");
					
					Database.instance.removeEventListener(DatabaseEvent.BGREADING_RETRIEVAL_EVENT, onBgReadingsReceived);
					
					readingsList = de.data as Array;
					formatData();
				}
			}
		}
		
		private static function formatData():void
		{
			if (readingsList == null)
				return;
			
			Trace.myTrace("SiDiary.as", "Formatting data...");
			
			//Process glucose output
			var outputArray:Array = [];
			outputArray[0] = "DAY;TIME;UDT_CGMS;BG_LEVEL;CH_GR;BOLUS;REMARK\n"; //CSV Header
			var index:int = 1;
			var newData:Boolean = false;
			for(var i:int = readingsList.length - 1 ; i >= 0; i--)
			{
				if (readingsList[i] == null)
					continue;
				
				if (readingsList[i].timestamp > lastExportTimeStamp) 
				{
					if (readingsList[i].calculatedValue != 0) 
					{
						outputArray[index] = DateTimeUtilities.createSiDiaryEntryFormattedDateAndTime(new Date(readingsList[i].timestamp)) + ";" + Math.round(readingsList[i].calculatedValue) + ";;;;;;" + "\n";
						index++;
					}
				} 
				else
					break;
			}
			
			//Process calibrations output
			var calibrations:Array = Calibration.allForSensor();
			var calibrationsLength:int = calibrations.length - 1;
			while (calibrationsLength > -1) {
				var calibration:Calibration = calibrations[calibrationsLength] as Calibration;
				if (calibration.timestamp > lastExportTimeStamp) 
				{
					outputArray[index] = DateTimeUtilities.createSiDiaryEntryFormattedDateAndTime(new Date(calibration.timestamp)) + ";;" + Math.round(calibration.bg) + ";;;;;" + "\n";
					index++;
				}
				calibrationsLength--;
			}
			
			//Process entire CSV output
			output = outputArray.join("");
			
			//Clean up memory
			if (readingsList != null)
			{
				readingsList.length = 0;
				readingsList = null;
			}
			
			if (outputArray != null)
			{
				outputArray.length = 0;
				outputArray = null;
			}
			
			if (index > 1) 
			{
				Trace.myTrace("SiDiary.as", "There's new data to export. Requesting user's email address...");
				
				sendData(); 
			}
			else 
			{
				Trace.myTrace("SiDiary.as", "No new data to export!");
				
				AlertManager.showSimpleAlert
				(
					ModelLocator.resourceManagerInstance.getString("sidiary","alert_title"),
					ModelLocator.resourceManagerInstance.getString("sidiary","no_new_data_alert_message")
				);
				
				//Warn listeners
				_instance.dispatchEventWith(starling.events.Event.COMPLETE);
			}
		}
		
		private static function sendData():void
		{
			if (output == null)
				return;
			
			fileData = new ByteArray();
			fileData.writeUTFBytes(output);
			
			EmailFileSender.instance.addEventListener(Event.COMPLETE, onCSVSent);
			EmailFileSender.instance.addEventListener(Event.CANCEL, onCSVCanceled);
			EmailFileSender.sendFile
			(
				ModelLocator.resourceManagerInstance.getString('sidiary',"email_subject"),
				ModelLocator.resourceManagerInstance.getString('sidiary',"email_body"),
				"SiDiary" + DateTimeUtilities.createSiDiaryFileNameFormattedDateAndTime(new Date()) + ".csv",
				fileData,
				"text/csv",
				ModelLocator.resourceManagerInstance.getString('sidiary','file_sent_successfully'),
				ModelLocator.resourceManagerInstance.getString('sidiary','file_not_sent'),
				""
			);
		}
		
		private static function onCSVSent(e:Event):void
		{
			EmailFileSender.instance.removeEventListener(Event.COMPLETE, onCSVSent);
			EmailFileSender.instance.removeEventListener(Event.CANCEL, onCSVCanceled);
			
			//Warn listeners
			_instance.dispatchEventWith(starling.events.Event.COMPLETE);
			
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_TIMESTAMP_SINCE_LAST_EXPORT_SIDIARY, String(new Date().valueOf()));
			
			dispose();
		}
		
		private static function onCSVCanceled(e:Event):void
		{
			EmailFileSender.instance.removeEventListener(Event.COMPLETE, onCSVSent);
			EmailFileSender.instance.removeEventListener(Event.CANCEL, onCSVCanceled);
			
			//Warn listeners
			_instance.dispatchEventWith(starling.events.Event.COMPLETE);
			
			dispose();
		}
		
		private static function dispose():void
		{
			//Dispose Objects
			output = null;
			fileData = null;
			fileName = null;
			if (readingsList != null)
			{
				readingsList.length = 0;
				readingsList = null;
			}
		}

		/**
		 * Getters & Setters
		 */
		public static function get instance():SiDiary
		{
			return _instance;
		}

	}
}