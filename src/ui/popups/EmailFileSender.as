package ui.popups
{
	import com.distriqt.extension.networkinfo.NetworkInfo;
	import com.spikeapp.spike.airlibrary.SpikeANE;
	
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
	import feathers.layout.HorizontalAlign;
	import feathers.layout.HorizontalLayout;
	import feathers.layout.VerticalLayout;
	
	import model.ModelLocator;
	
	import network.EmailSender;
	
	import starling.core.Starling;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.EventDispatcher;
	import starling.events.ResizeEvent;
	import starling.utils.SystemUtil;
	
	import ui.screens.display.LayoutFactory;
	
	import utils.Constants;
	import utils.DataValidator;
	import utils.DeviceInfo;
	
	[ResourceBundle("globaltranslations")]
	[ResourceBundle("sidiarysettingsscreen")]

	public class EmailFileSender extends EventDispatcher
	{
		//Display Objects
		private static var mainContainer:LayoutGroup;
		private static var emailLabel:Label;
		private static var emailField:TextInput;
		private static var actionButtonsContainer:LayoutGroup;
		private static var cancelButton:Button;
		private static var sendButton:Button;
		private static var positionHelper:Sprite;
		private static var emailCallout:Callout;
		
		//Properties
		private static var emailSubjectProperty:String;
		private static var emailBodyProperty:String;
		private static var fileDataProperty:*;
		private static var fileNameProperty:String;
		private static var mimeTypeProperty:String;
		private static var emailSentMessageProperty:String;
		private static var emailFailedMessageProperty:String;
		private static var fileNotFoundMessageProperty:String;
		private static var calloutTitleMessageProperty:String;
		
		//Instance
		private static var _instance:EmailFileSender = new EmailFileSender();
		
		public function EmailFileSender()
		{
			//Don't allow class to be instantiated
			if (_instance != null)
				throw new IllegalOperationError("EmailFileSender class is not meant to be instantiated!");
		}
		
		public static function sendFile(emailSubject:String, emailBody:String, fileName:String, fileData:*, mimeType:String, emailSentMessage:String, emailFailedMessage:String, fileNotFoundMessage:String, calloutTitleMessage:String = null):void
		{
			if (!NetworkInfo.networkInfo.isReachable())
			{
				AlertManager.showSimpleAlert
				(
					ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
					ModelLocator.resourceManagerInstance.getString('globaltranslations','no_internet_connection_message')
				);
				
				return;
			}
			
			emailSubjectProperty = emailSubject;
			emailBodyProperty = emailBody;
			fileNameProperty = fileName;
			fileDataProperty = fileData;
			mimeTypeProperty = mimeType;
			emailSentMessageProperty = emailSentMessage;
			emailFailedMessageProperty = emailFailedMessage;
			fileNotFoundMessageProperty = fileNotFoundMessage;
			calloutTitleMessageProperty = calloutTitleMessage == null ? ModelLocator.resourceManagerInstance.getString('globaltranslations',"user_email_label") : calloutTitleMessage;
			
			Starling.current.stage.addEventListener(starling.events.Event.RESIZE, onStarlingResize);
			
			createDisplayObjects();
			displayCallout();
		}
		
		private static function createDisplayObjects():void
		{
			/* Main Container */
			var mainLayout:VerticalLayout = new VerticalLayout();
			mainLayout.horizontalAlign = HorizontalAlign.CENTER;
			mainLayout.gap = 10;
			
			mainContainer = new LayoutGroup();
			mainContainer.layout = mainLayout;
			
			/* Title */
			emailLabel = LayoutFactory.createLabel(calloutTitleMessageProperty, HorizontalAlign.CENTER);
			mainContainer.addChild(emailLabel);
			
			/* Email Input */
			emailField = LayoutFactory.createTextInput(false, false, 200, HorizontalAlign.CENTER, false, true);
			mainContainer.addChild(emailField);
			
			/* Action Buttons */
			var actionButtonsLayout:HorizontalLayout = new HorizontalLayout();
			actionButtonsLayout.gap = 5;
			
			actionButtonsContainer = new LayoutGroup();
			actionButtonsContainer.layout = actionButtonsLayout;
			mainContainer.addChild(actionButtonsContainer);
			
			//Cancel Button
			cancelButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('globaltranslations',"cancel_button_label"));
			cancelButton.addEventListener(starling.events.Event.TRIGGERED, onCancel);
			actionButtonsContainer.addChild(cancelButton);
			
			//Send Button
			sendButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('globaltranslations',"send_button_label_capitalized"));
			sendButton.addEventListener(starling.events.Event.TRIGGERED, onSend);
			actionButtonsContainer.addChild(sendButton);
			
			/* Callout Position Helper Creation */
			positionHelper = new Sprite();
			positionHelper.x = Constants.stageWidth / 2;
			
			var yPos:Number = 0;
			if (!isNaN(Constants.headerHeight))
				yPos = Constants.headerHeight - 10;
			else
			{
				if (Constants.deviceModel != DeviceInfo.IPHONE_X_Xs_XsMax_Xr)
					yPos = 68;
				else
					yPos = Constants.isPortrait ? 98 : 68;
			}
			
			positionHelper.y = yPos;
			Starling.current.stage.addChild(positionHelper);
			
			/* Callout Creation */
			emailCallout = new Callout();
			emailCallout.content = mainContainer;
			emailCallout.origin = positionHelper;
			emailCallout.minWidth = 240;
			
			emailField.setFocus();
		}
		
		private static function displayCallout():void
		{
			if (!SpikeANE.appIsInForeground())
				return
			
			//Display callout
			PopUpManager.addPopUp(emailCallout, false, false);
		}
		
		/**
		 * Event Listeners
		 */
		private static function onSend(e:starling.events.Event):void
		{
			if (emailLabel == null || sendButton == null || fileDataProperty == null || fileNameProperty === null || mimeTypeProperty == null || emailSubjectProperty == null || emailBodyProperty == null || emailSentMessageProperty == null || emailFailedMessageProperty == null || fileNotFoundMessageProperty == null)
			{
				_instance.dispatchEventWith(starling.events.Event.CANCEL);
				dispose();
				return;
			}
			
			if (!NetworkInfo.networkInfo.isReachable())
			{
				_instance.dispatchEventWith(starling.events.Event.CANCEL);
				dispose();
				
				AlertManager.showSimpleAlert
				(
					ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
					ModelLocator.resourceManagerInstance.getString('globaltranslations','no_internet_connection_message')
				);
				
				return;
			}
			
			//Validation
			emailLabel.text = ModelLocator.resourceManagerInstance.getString('globaltranslations',"user_email_label");
			emailLabel.fontStyles.color = 0xEEEEEE;
			
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
			
			sendButton.isEnabled = false;
			sendButton.label = ModelLocator.resourceManagerInstance.getString('sidiarysettingsscreen',"export_button__standby_label");
			sendButton.invalidate();
			sendButton.validate();
			mainContainer.validate();
			emailCallout.validate();
			
			//Get the file
			if ((fileDataProperty is File && fileDataProperty.exists && fileDataProperty.size > 0) || fileDataProperty is ByteArray)
			{
				var fileBytes:ByteArray;
				
				if (fileDataProperty is File)
				{
					var fileStream:FileStream = new FileStream();
					fileStream.open(fileDataProperty, FileMode.READ);
					
					//Read trace log raw bytes into memory
					fileBytes = new ByteArray();
					fileStream.readBytes(fileBytes);
					fileStream.close();
				}
				else if (fileDataProperty is ByteArray)
				{
					fileBytes = fileDataProperty;
				}
				
				//Create URL Request Address
				var vars:URLVariables = new URLVariables();
				vars.fileName = fileNameProperty;
				vars.mimeType = mimeTypeProperty;
				vars.emailSubject = emailSubjectProperty;
				vars.emailBody = emailBodyProperty;
				vars.userEmail = emailField.text.replace(" ", "");
				vars.mode = EmailSender.MODE_EMAIL_USER;
				
				//Send data
				EmailSender.sendData
				(
					EmailSender.TRANSMISSION_URL_WITH_ATTACHMENT,
					onLoadCompleteHandler,
					vars,
					fileBytes
				);
			}
			else
			{
				_instance.dispatchEventWith(starling.events.Event.CANCEL);
				dispose(true);
				
				if (fileDataProperty is File)
				{
					AlertManager.showSimpleAlert
					(
						ModelLocator.resourceManagerInstance.getString('globaltranslations','error_alert_title'),
						fileNotFoundMessageProperty
					);
				}
				
				dispose();
			}
		}
		
		private static function onLoadCompleteHandler(event:flash.events.Event):void 
		{ 
			var loader:URLLoader = URLLoader(event.target);
			
			var response:Object = loader.data;
			
			loader.removeEventListener(flash.events.Event.COMPLETE, onLoadCompleteHandler);
			loader = null;
			
			if (response.success == "true")
			{
				PopUpManager.removeAllPopUps();
				
				AlertManager.showSimpleAlert
				(
					ModelLocator.resourceManagerInstance.getString('globaltranslations','success_alert_title'),
					emailSentMessageProperty,
					Number.NaN
				);
				
				_instance.dispatchEventWith(starling.events.Event.COMPLETE);
				
				dispose();
			}
			else
			{
				AlertManager.showActionAlert
				(
					ModelLocator.resourceManagerInstance.getString('globaltranslations','error_alert_title'),
					emailFailedMessageProperty + " " + response.statuscode,
					Number.NaN,
					[
						{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations','cancel_button_label').toUpperCase(), triggered:onCancelRetry },	
						{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations','try_again_button_label'), triggered: onTryAgain },	
					]
				);
				
				_instance.dispatchEventWith(starling.events.Event.CANCEL);
				
				dispose(true);
				
				function onTryAgain(e:starling.events.Event):void
				{
					Starling.juggler.delayCall(sendFile, 0.5, emailSubjectProperty, emailBodyProperty, fileNameProperty, fileDataProperty, mimeTypeProperty, emailSentMessageProperty, emailFailedMessageProperty, fileNotFoundMessageProperty);
				}
				
				function onCancelRetry(e:starling.events.Event):void
				{
					_instance.dispatchEventWith(starling.events.Event.CANCEL);
					
					dispose();
				}
			}
		}
		
		private static function onCancel(e:starling.events.Event):void
		{
			_instance.dispatchEventWith(starling.events.Event.CANCEL);
			
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
		 * Utility
		 */
		public static function dispose(keepProperties:Boolean = false):void
		{
			Starling.current.stage.removeEventListener(starling.events.Event.RESIZE, onStarlingResize);
			
			_instance.removeEventListeners();
			
			if (!SystemUtil.isApplicationActive)
			{
				SystemUtil.executeWhenApplicationIsActive(dispose, keepProperties);
				
				return;
			}
			
			if (positionHelper != null)
			{
				positionHelper.removeFromParent();
				positionHelper.dispose();
				positionHelper = null;
			}
			
			if (cancelButton != null)
			{
				cancelButton.removeEventListener(starling.events.Event.TRIGGERED, onCancel);
				cancelButton.removeFromParent();
				cancelButton.dispose();
				cancelButton = null;
			}
			
			if (sendButton != null)
			{
				sendButton.removeEventListener(starling.events.Event.TRIGGERED, onSend);
				sendButton.removeFromParent();
				sendButton.dispose();
				sendButton = null;
			}
			
			if (emailLabel != null)
			{
				emailLabel.removeFromParent();
				emailLabel.dispose();
				emailLabel = null;
			}
			
			if (emailField != null)
			{
				emailField.removeFromParent();
				emailField.dispose();
				emailField = null;
			}
			
			if (actionButtonsContainer != null)
			{
				actionButtonsContainer.removeFromParent();
				actionButtonsContainer.dispose();
				actionButtonsContainer = null;
			}
			
			if (mainContainer != null)
			{
				mainContainer.removeFromParent();
				mainContainer.dispose();
				mainContainer = null;
			}
			
			if (keepProperties == false)
			{
				emailSubjectProperty = null;
				emailBodyProperty = null;
				fileDataProperty = null;
				fileNameProperty = null;
				mimeTypeProperty = null;
				emailSentMessageProperty = null;
				emailFailedMessageProperty = null;
				fileNotFoundMessageProperty = null;
			}
			
			//Close the callout
			if (PopUpManager.isPopUp(emailCallout))
				PopUpManager.removePopUp(emailCallout, true);
			else if (emailCallout != null)
				emailCallout.close(true);
		}

		/**
		 * Getters & Setters
		 */
		public static function get instance():EmailFileSender
		{
			return _instance;
		}
	}
}