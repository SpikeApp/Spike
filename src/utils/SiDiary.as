package utils
{
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLVariables;
	import flash.utils.ByteArray;
	
	import database.BgReading;
	import database.BlueToothDevice;
	import database.Calibration;
	import database.Database;
	import database.LocalSettings;
	
	import events.DatabaseEvent;
	
	import feathers.controls.Button;
	import feathers.controls.Callout;
	import feathers.controls.Label;
	import feathers.controls.LayoutGroup;
	import feathers.controls.TextInput;
	import feathers.core.PopUpManager;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.HorizontalLayout;
	import feathers.layout.VerticalAlign;
	import feathers.layout.VerticalLayout;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import network.EmailSender;
	
	import starling.core.Starling;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.EventDispatcher;
	import starling.events.ResizeEvent;
	import starling.text.TextFormat;
	import starling.utils.SystemUtil;
	
	import ui.popups.AlertManager;
	import ui.screens.display.LayoutFactory;
	
	[ResourceBundle("sidiary")]
	[ResourceBundle("globaltranslations")]
	
	public class SiDiary extends EventDispatcher
	{
		/* Variables */
		private static var fileName:String;
		private static var lastExportTimeStamp:Number;
		private static var output:String;
		
		/* Display Objects */
		private static var emailLabel:Label;
		private static var emailField:TextInput;
		private static var sendButton:Button;
		private static var siDiarySenderCallout:Callout;
		private static var _instance:SiDiary = new SiDiary();
		private static var positionHelper:Sprite;
		
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
			
			Starling.current.stage.addEventListener(starling.events.Event.RESIZE, onStarlingResize);
			
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
			
			if (lastExportTimeStamp > firstReading.timestamp || BlueToothDevice.isFollower())
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
			
			//Warn listeners
			_instance.dispatchEventWith(starling.events.Event.COMPLETE);
			
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
			/* Main Container */
			var mainLayout:VerticalLayout = new VerticalLayout();
			mainLayout.horizontalAlign = HorizontalAlign.CENTER;
			mainLayout.gap = 10;
			
			var mainContainer:LayoutGroup = new LayoutGroup();
			mainContainer.layout = mainLayout;
			
			/* Title */
			emailLabel = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('globaltranslations',"user_email_label"), HorizontalAlign.CENTER);
			mainContainer.addChild(emailLabel);
			
			/* Email Input */
			emailField = LayoutFactory.createTextInput(false, false, 200, HorizontalAlign.CENTER);
			emailField.fontStyles.size = 12;
			mainContainer.addChild(emailField);
			
			/* Action Buttons */
			var actionButtonsLayout:HorizontalLayout = new HorizontalLayout();
			actionButtonsLayout.gap = 5;
			
			var actionButtonsContainer:LayoutGroup = new LayoutGroup();
			actionButtonsContainer.layout = actionButtonsLayout;
			mainContainer.addChild(actionButtonsContainer);
			
			//Cancel Button
			var cancelButton:Button = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('globaltranslations',"cancel_button_label"));
			cancelButton.addEventListener(starling.events.Event.TRIGGERED, onCancel);
			actionButtonsContainer.addChild(cancelButton);
			
			//Send Button
			sendButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('globaltranslations',"send_button_label_capitalized"));
			sendButton.addEventListener(starling.events.Event.TRIGGERED, onSend);
			actionButtonsContainer.addChild(sendButton);
			
			/* Callout Position Helper Creation */
			positionHelper = new Sprite();
			positionHelper.x = Constants.stageWidth / 2;
			positionHelper.y = 70;
			Starling.current.stage.addChild(positionHelper);
			
			/* Callout Creation */
			siDiarySenderCallout = new Callout();
			siDiarySenderCallout.content = mainContainer;
			siDiarySenderCallout.origin = positionHelper;
			siDiarySenderCallout.minWidth = 240;
			
			//Close the callout
			if (PopUpManager.isPopUp(siDiarySenderCallout))
				PopUpManager.removePopUp(siDiarySenderCallout, false);
			else
				siDiarySenderCallout.close(false);
			
			//Display callout
			PopUpManager.addPopUp(siDiarySenderCallout, false, false);
			
			emailField.setFocus();
		}
		
		private static function closeCallout():void
		{
			if (siDiarySenderCallout == null)
				return;
			
			//Close the callout
			if (PopUpManager.isPopUp(siDiarySenderCallout))
				PopUpManager.removePopUp(siDiarySenderCallout, true);
			else
				siDiarySenderCallout.close(true);
		}
		
		private static function dispose():void
		{
			Starling.current.stage.removeEventListener(starling.events.Event.RESIZE, onStarlingResize);
			
			//Dispose Objects
			output = null;
			fileData = null;
			fileName = null;
			readingsList = null;
			
			//Dispose display objects
			if (positionHelper != null)
			{
				positionHelper.removeFromParent();
				positionHelper.dispose();
				positionHelper = null;
			}
			
			if (emailLabel != null)
			{
				emailLabel.dispose();
				emailLabel = null;
			}
			
			if (emailField != null)
			{
				emailField.dispose();
				emailField = null;
			}
			
			if (sendButton != null)
			{
				sendButton.dispose();
				sendButton = null;
			}
			
			if (siDiarySenderCallout != null)
			{
				siDiarySenderCallout.dispose();
				siDiarySenderCallout = null;
			}
		}
		
		/**
		 * Event Listeners
		 */
		private static function onSend(e:starling.events.Event):void
		{
			if (emailLabel == null || sendButton == null || output == null || output == "")
				return;
			
			Trace.myTrace("SiDiary.as", "Sending CSV file...");
			
			//Validation
			emailLabel.text = ModelLocator.resourceManagerInstance.getString('globaltranslations',"user_email_label");
			if (emailLabel.fontStyles != null)
				emailLabel.fontStyles.color = 0xEEEEEE;
			else
				emailLabel.fontStyles = new TextFormat("Roboto", 14, 0xEEEEEE, HorizontalAlign.CENTER, VerticalAlign.TOP);
			
			if (emailField.text == "")
			{
				emailLabel.text = ModelLocator.resourceManagerInstance.getString('globaltranslations',"email_address_required");
				emailLabel.fontStyles.color = 0xFF0000;
				return;
			}
			else if (!DataValidator.validateEmail(emailField.text))
			{
				emailLabel.text = ModelLocator.resourceManagerInstance.getString('globaltranslations',"email_address_invalid");
				emailLabel.fontStyles.color = 0xFF0000;
				return;
			}
			
			//Disable send button temporarily
			sendButton.isEnabled = false;
			
			//Calculate File Name
			fileName ="SiDiary" + DateTimeUtilities.createSiDiaryFileNameFormattedDateAndTime(new Date()) + ".csv";
			
			//Read csv raw bytes into memory
			fileData = new ByteArray();
			fileData.writeUTFBytes(output);
			
			//Create URL Request Address
			var vars:URLVariables = new URLVariables();
			vars.fileName = fileName;
			vars.mimeType = "text/csv";
			vars.emailSubject = ModelLocator.resourceManagerInstance.getString('sidiary',"email_subject");
			vars.emailBody = ModelLocator.resourceManagerInstance.getString('sidiary',"email_body");;
			vars.userEmail = emailField.text.replace(" ", "");
			vars.mode = EmailSender.MODE_EMAIL_USER;
			
			//Send data
			EmailSender.sendData
			(
				EmailSender.TRANSMISSION_URL_WITH_ATTACHMENT,
				onLoadCompleteHandler,
				vars,
				fileData
			);
		}
		
		private static function onLoadCompleteHandler(event:flash.events.Event):void 
		{ 
			var loader:URLLoader = URLLoader(event.target);
			loader.removeEventListener(flash.events.Event.COMPLETE, onLoadCompleteHandler);
			
			var response:Object = loader.data;
			loader = null;
			
			if (response.success == "true")
			{
				Trace.myTrace("SiDiary.as", "CSV file successfully sent!");
				
				AlertManager.showSimpleAlert
					(
						ModelLocator.resourceManagerInstance.getString('globaltranslations','success_alert_title'),
						ModelLocator.resourceManagerInstance.getString('sidiary','file_sent_successfully')
					);
				
				closeCallout();
				dispose();
				
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_TIMESTAMP_SINCE_LAST_EXPORT_SIDIARY, (new Date()).valueOf().toString());
			}
			else
			{
				Trace.myTrace("SiDiary.as", "Error sending CSV file. Status Code: " + response.statuscode);
				
				sendButton.isEnabled = true;
				
				AlertManager.showActionAlert
					(
						ModelLocator.resourceManagerInstance.getString('globaltranslations','error_alert_title'),
						ModelLocator.resourceManagerInstance.getString('sidiary','file_not_sent') + " " + response.statuscode,
						Number.NaN,
						[
							{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations','cancel_button_label').toUpperCase() },	
							{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations','try_again_button_label'), triggered: onTryAgain },	
						]
					);
				
				function onTryAgain(e:starling.events.Event):void
				{
					Starling.juggler.delayCall(sendData, 0.5, null);
				}
			}
		}
		
		private static function onCancel(e:starling.events.Event):void
		{
			Trace.myTrace("SiDiary.as", "CSV file not sent! User cancelled!");
			
			closeCallout();
			dispose();	
		}
		
		private static function onStarlingResize(event:ResizeEvent):void 
		{
			if (positionHelper != null)
				positionHelper.x = Constants.stageWidth / 2;
			
			if (emailField != null)
				SystemUtil.executeWhenApplicationIsActive( emailField.clearFocus );
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