package ui.popups
{	
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
	
	import network.DataSender;
	
	import starling.core.Starling;
	import starling.display.Sprite;
	import starling.events.Event;
	
	import ui.screens.display.LayoutFactory;
	
	import utilities.Constants;

	[ResourceBundle("globaltranslations")]
	[ResourceBundle("wixelsender")]
	
	public class G4WixelSender
	{
		/* Display Objects */
		private static var wixelSenderCallout:Callout;
		
		/* Properties */
		private static var dataProvider:ArrayCollection;

		private static var emailField:TextInput;
		
		public function G4WixelSender()
		{
			//Don't allow class to be instantiated
			throw new IllegalOperationError("G4WixelSender class is not meant to be instantiated!");
		}
		
		/**
		 * Functionality
		 */
		public static function displayWixelSender():void
		{
			createDisplayObjects();
			displayCallout();
		}
		
		private static function displayCallout():void
		{
			//Close the callout
			if (PopUpManager.isPopUp(wixelSenderCallout))
				PopUpManager.removePopUp(wixelSenderCallout, true);
			
			//Display callout
			PopUpManager.addPopUp(wixelSenderCallout, false, false);
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
			var emailLabel:Label = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('wixelsender',"user_email_label"), HorizontalAlign.CENTER);
			mainContainer.addChild(emailLabel);
			
			/* Email Input */
			emailField = LayoutFactory.createTextInput(false, false, 200, HorizontalAlign.RIGHT);
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
			var sendButton:Button = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('wixelsender',"send_alert_button_label"));
			sendButton.addEventListener(starling.events.Event.TRIGGERED, onClose);
			actionButtonsContainer.addChild(sendButton);
			
			/* Callout Position Helper Creation */
			var positionHelper:Sprite = new Sprite();
			positionHelper.x = Constants.stageWidth / 2;
			positionHelper.y = 70;
			Starling.current.stage.addChild(positionHelper);
			
			/* Callout Creation */
			wixelSenderCallout = new Callout();
			wixelSenderCallout.content = mainContainer;
			wixelSenderCallout.origin = positionHelper;
			wixelSenderCallout.minWidth = 240;
		}
		
		private static function closeCallout():void
		{
			//Close the callout
			if (PopUpManager.isPopUp(wixelSenderCallout))
				PopUpManager.removePopUp(wixelSenderCallout, true);
			else
				wixelSenderCallout.close(true);
		}
		
		/**
		 * Event Listeners
		 */
		private static function onClose(e:starling.events.Event):void
		{
			//Get the wixel zip file
			var fileName:String = "xBridge2.zip";
			var file:File = File.applicationDirectory.resolvePath("assets/files/" + fileName);
			if (file.exists && file.size > 0)
			{
				var fileStream:FileStream = new FileStream();
				fileStream.open(file, FileMode.READ);
				
				//Read trace log raw bytes into memory
				var fileData:ByteArray = new ByteArray();
				fileStream.readBytes(fileData);
				fileStream.close();
				
				//Create URL Request AddressModelLocator.resourceManagerInstance.getString('wixelsender',"send_alert_button_label")
				var emailBody:String = ModelLocator.resourceManagerInstance.getString('wixelsender',"email_body");
				
				var vars:URLVariables = new URLVariables();
				vars.fileName = fileName;
				vars.mimeType = "application/zip";
				vars.emailSubject = ModelLocator.resourceManagerInstance.getString('wixelsender',"email_subject");
				vars.emailBody = emailBody;
				vars.userEmail = emailField.text;
				vars.mode = DataSender.MODE_EMAIL_USER;
				
				//Send data
				DataSender.sendData
				(
					DataSender.TRANSMISSION_URL_WITH_ATTACHMENT,
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
			}
		}
		
		private static function onLoadCompleteHandler(event:flash.events.Event):void 
		{ 
			var loader:URLLoader = URLLoader(event.target);
			loader.removeEventListener(flash.events.Event.COMPLETE, onLoadCompleteHandler);
			
			var response:Object = loader.data;
			
			if (response.success == "true")
			{
				AlertManager.showSimpleAlert
				(
					ModelLocator.resourceManagerInstance.getString('globaltranslations','success_alert_title'),
					ModelLocator.resourceManagerInstance.getString('wixelsender','wixel_file_sent_successfully'),
					Number.NaN,
					null,
					HorizontalAlign.CENTER
				);
				
				closeCallout();
			}
			else
			{
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
					Starling.juggler.delayCall(displayWixelSender, 0.5);
				}
			}
		}
		
		private static function onCancel(e:starling.events.Event):void
		{
			closeCallout();
		}
	}
}