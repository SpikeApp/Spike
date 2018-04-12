package ui.popups
{	
	import com.freshplanet.ane.AirBackgroundFetch.BackgroundFetch;
	
	import flash.errors.IllegalOperationError;
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.URLLoader;
	import flash.net.URLVariables;
	import flash.utils.ByteArray;
	
	import feathers.controls.Button;
	import feathers.controls.Callout;
	import feathers.controls.Label;
	import feathers.controls.LayoutGroup;
	import feathers.controls.TextInput;
	import feathers.core.PopUpManager;
	import feathers.data.ArrayCollection;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.HorizontalLayout;
	import feathers.layout.VerticalLayout;
	
	import model.ModelLocator;
	
	import network.EmailSender;
	
	import starling.core.Starling;
	import starling.display.Sprite;
	import starling.events.Event;
	
	import ui.screens.display.LayoutFactory;
	
	import utils.Constants;
	import utils.DataValidator;

	[ResourceBundle("globaltranslations")]
	[ResourceBundle("wixelsender")]
	
	public class TreatmentsConfigSender
	{
		/* Display Objects */
		private static var treatmentsConfigSenderCallout:Callout;
		private static var emailField:TextInput;
		private static var emailLabel:Label;
		private static var sendButton:Button;
		
		/* Properties */
		private static var dataProvider:ArrayCollection;

		private static var filesList:Array;
		
		public function TreatmentsConfigSender()
		{
			//Don't allow class to be instantiated
			throw new IllegalOperationError("TreatmentsConfigSender class is not meant to be instantiated!");
		}
		
		/**
		 * Functionality
		 */
		public static function displayTreatmentsConfigSender():void
		{
			createDisplayObjects();
			displayCallout();
		}
		
		private static function displayCallout():void
		{
			if (!BackgroundFetch.appIsInForeground())
				return
			
			//Close the callout
			if (PopUpManager.isPopUp(treatmentsConfigSenderCallout))
				PopUpManager.removePopUp(treatmentsConfigSenderCallout, false);
			else if (treatmentsConfigSenderCallout != null)
				treatmentsConfigSenderCallout.close(false);
			
			//Display callout
			PopUpManager.addPopUp(treatmentsConfigSenderCallout, false, false);
		}
		
		private static function createDisplayObjects():void
		{
			/* Main Container */
			var mainLayout:VerticalLayout = new VerticalLayout();
			mainLayout.horizontalAlign = HorizontalAlign.CENTER;
			mainLayout.gap = 10;
			
			var mainContainer:LayoutGroup = new LayoutGroup();
			mainContainer.layout = mainLayout;
			
			/* Title */
			emailLabel = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('wixelsender',"user_email_label"), HorizontalAlign.CENTER);
			mainContainer.addChild(emailLabel);
			
			/* Email Input */
			emailField = LayoutFactory.createTextInput(false, false, 200, HorizontalAlign.CENTER);
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
			sendButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('wixelsender',"send_alert_button_label"));
			sendButton.addEventListener(starling.events.Event.TRIGGERED, onClose);
			actionButtonsContainer.addChild(sendButton);
			
			/* Callout Position Helper Creation */
			var positionHelper:Sprite = new Sprite();
			positionHelper.x = Constants.stageWidth / 2;
			positionHelper.y = 70;
			Starling.current.stage.addChild(positionHelper);
			
			/* Callout Creation */
			treatmentsConfigSenderCallout = new Callout();
			treatmentsConfigSenderCallout.content = mainContainer;
			treatmentsConfigSenderCallout.origin = positionHelper;
			treatmentsConfigSenderCallout.minWidth = 240;
			
			emailField.setFocus();
		}
		
		private static function closeCallout():void
		{
			//Close the callout
			if (PopUpManager.isPopUp(treatmentsConfigSenderCallout))
				PopUpManager.removePopUp(treatmentsConfigSenderCallout, true);
			else if (treatmentsConfigSenderCallout != null)
				treatmentsConfigSenderCallout.close(true);
		}
		
		/**
		 * Event Listeners
		 */
		private static function onClose(e:starling.events.Event):void
		{
			//Validation
			emailLabel.text = ModelLocator.resourceManagerInstance.getString('wixelsender',"user_email_label");
			emailLabel.fontStyles.color = 0xEEEEEE;
			
			if (emailField.text == "")
			{
				emailLabel.text = ModelLocator.resourceManagerInstance.getString('wixelsender',"email_address_required");
				emailLabel.fontStyles.color = 0xFF0000;
				return;
			}
			else if (!DataValidator.validateEmail(emailField.text))
			{
				emailLabel.text = ModelLocator.resourceManagerInstance.getString('wixelsender',"email_address_invalid");
				emailLabel.fontStyles.color = 0xFF0000;
				return;
			}
			
			sendButton.isEnabled = false;
			
			filesList = 
			[
				{
					fileName: "SpikeBGCheck.wflow",
					emailSubject: "BG Check Treatment",
					emailBody: "Configuration file for Spike BG Treatment"
				},
				{
					fileName: "SpikeBolus.wflow",
					emailSubject: "Bolus Treatment",
					emailBody: "Configuration file for Spike Bolus"
				},
				{
					fileName: "SpikeCarbs.wflow",
					emailSubject: "Carb Treatment",
					emailBody: "Configuration file for Spike Carbs"
				},
				{
					fileName: "SpikeMeal.wflow",
					emailSubject: "Meal Treatment",
					emailBody: "Configuration file for Spike Meal"
				},
				{
					fileName: "SpikeSampleNote.wflow",
					emailSubject: "Note Treatment",
					emailBody: "Configuration file for Spike Note example"
				}
			];
			
			for (var i:int = 0; i < filesList.length; i++) 
			{
				//Get corresponding file
				var fileName:String = filesList[i].fileName as String;
				trace("fileName", fileName);
				var file:File = File.applicationDirectory.resolvePath("assets/files/" + fileName);
				if (file.exists && file.size > 0)
				{
					var fileStream:FileStream = new FileStream();
					fileStream.open(file, FileMode.READ);
					
					//Read trace log raw bytes into memory
					var fileData:ByteArray = new ByteArray();
					fileStream.readBytes(fileData);
					fileStream.close();
					
					//Create URL Request Address
					var emailBody:String = filesList[i].emailBody as String;
					trace("emailBody", emailBody);
					
					var vars:URLVariables = new URLVariables();
					vars.fileName = fileName;
					vars.mimeType = "application/zip";
					vars.emailSubject = filesList[i].emailSubject as String;
					trace("vars.emailSubject", vars.emailSubject);
					vars.emailBody = emailBody;
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
				else
				{
					AlertManager.showSimpleAlert
					(
						ModelLocator.resourceManagerInstance.getString('globaltranslations','error_alert_title'),
						ModelLocator.resourceManagerInstance.getString('wixelsender','wixel_file_not_found')
					);
					
					sendButton.isEnabled = true;
				}
			}
		}
		
		private static function onLoadCompleteHandler(event:flash.events.Event):void 
		{ 
			var loader:URLLoader = URLLoader(event.target);
			loader.removeEventListener(flash.events.Event.COMPLETE, onLoadCompleteHandler);
			
			var response:Object = loader.data;
			loader = null;
			
			if (response.success == "true")
			{
				AlertManager.showSimpleAlert
				(
					ModelLocator.resourceManagerInstance.getString('globaltranslations','success_alert_title'),
					ModelLocator.resourceManagerInstance.getString('wixelsender','wixel_file_sent_successfully'),
					Number.NaN
				);
				
				closeCallout();
			}
			else
			{
				sendButton.isEnabled = true;
				
				AlertManager.showActionAlert
				(
					ModelLocator.resourceManagerInstance.getString('globaltranslations','error_alert_title'),
					ModelLocator.resourceManagerInstance.getString('wixelsender','wixel_file_not_sent') + " " + response.statuscode,
					Number.NaN,
					[
						{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations','cancel_button_label').toUpperCase() },	
						{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations','try_again_button_label'), triggered: onTryAgain },	
					]
				);
				
				function onTryAgain(e:starling.events.Event):void
				{
					Starling.juggler.delayCall(displayTreatmentsConfigSender, 0.5);
				}
			}
		}
		
		private static function onCancel(e:starling.events.Event):void
		{
			closeCallout();
		}
	}
}