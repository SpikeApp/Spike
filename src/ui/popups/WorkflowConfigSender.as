package ui.popups
{	
	import com.spikeapp.spike.airlibrary.SpikeANE;
	
	import flash.errors.IllegalOperationError;
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLVariables;
	
	import feathers.controls.Button;
	import feathers.controls.Callout;
	import feathers.controls.Label;
	import feathers.controls.LayoutGroup;
	import feathers.controls.TextInput;
	import feathers.core.PopUpManager;
	import feathers.data.ArrayCollection;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.HorizontalLayout;
	import feathers.layout.VerticalAlign;
	import feathers.layout.VerticalLayout;
	
	import model.ModelLocator;
	
	import network.EmailSender;
	
	import starling.core.Starling;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.text.TextFormat;
	import starling.utils.SystemUtil;
	
	import ui.screens.display.LayoutFactory;
	
	import utils.Constants;
	import utils.DataValidator;
	import utils.DeviceInfo;

	[ResourceBundle("globaltranslations")]
	[ResourceBundle("treatments")]
	[ResourceBundle("alarmsettingsscreen")]
	[ResourceBundle("transmittersettingsscreen")]
	
	public class WorkflowConfigSender
	{
		/* Constants */
		public static const WORKFLOW_TREATMENTS:String = "treatments";
		public static const WORKFLOW_MIAOMIAO_ON_DEMAND:String = "miaomiaoOnDemand";
		public static const WORKFLOW_ALARMS:String = "alarms";
		
		/* Display Objects */
		private static var workflowConfigSenderCallout:Callout;
		private static var emailField:TextInput;
		private static var emailLabel:Label;
		private static var sendButton:Button;
		private static var selectedWorkflow:String;
		
		/* Properties */
		private static var dataProvider:ArrayCollection;
		private static var mainContainer:LayoutGroup;
		private static var actionButtonsContainer:LayoutGroup;
		private static var cancelButton:Button;
		private static var positionHelper:Sprite;
		
		public function WorkflowConfigSender()
		{
			//Don't allow class to be instantiated
			throw new IllegalOperationError("WorkflowConfigSender class is not meant to be instantiated!");
		}
		
		/**
		 * Functionality
		 */
		public static function displayWorkflowConfigSender(workflow:String):void
		{
			selectedWorkflow = workflow;
			
			createDisplayObjects();
			displayCallout();
		}
		
		private static function displayCallout():void
		{
			if (!SpikeANE.appIsInForeground())
				return
			
			//Close the callout
			if (PopUpManager.isPopUp(workflowConfigSenderCallout))
				PopUpManager.removePopUp(workflowConfigSenderCallout, false);
			else if (workflowConfigSenderCallout != null)
				workflowConfigSenderCallout.close(false);
			
			//Display callout
			PopUpManager.addPopUp(workflowConfigSenderCallout, false, false);
		}
		
		private static function createDisplayObjects():void
		{
			/* Main Container */
			var mainLayout:VerticalLayout = new VerticalLayout();
			mainLayout.horizontalAlign = HorizontalAlign.CENTER;
			mainLayout.gap = 10;
			
			if (mainContainer != null) mainContainer.removeFromParent(true);
			mainContainer = new LayoutGroup();
			mainContainer.layout = mainLayout;
			
			/* Title */
			if (emailLabel != null) emailLabel.removeFromParent(true);
			emailLabel = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('globaltranslations',"user_email_label"), HorizontalAlign.CENTER);
			mainContainer.addChild(emailLabel);
			
			/* Email Input */
			if (emailField != null) emailField.removeFromParent(true);
			emailField = LayoutFactory.createTextInput(false, false, 200, HorizontalAlign.CENTER, false, true);
			mainContainer.addChild(emailField);
			
			/* Action Buttons */
			var actionButtonsLayout:HorizontalLayout = new HorizontalLayout();
			actionButtonsLayout.gap = 5;
			
			if (actionButtonsContainer != null) actionButtonsContainer.removeFromParent(true);
			actionButtonsContainer = new LayoutGroup();
			actionButtonsContainer.layout = actionButtonsLayout;
			mainContainer.addChild(actionButtonsContainer);
			
			//Cancel Button
			if (cancelButton != null) cancelButton.removeFromParent(true);
			cancelButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('globaltranslations',"cancel_button_label"));
			cancelButton.addEventListener(starling.events.Event.TRIGGERED, onCancel);
			actionButtonsContainer.addChild(cancelButton);
			
			//Send Button
			if (sendButton != null) sendButton.removeFromParent();
			sendButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('globaltranslations',"send_button_label_capitalized"));
			sendButton.addEventListener(starling.events.Event.TRIGGERED, onClose);
			actionButtonsContainer.addChild(sendButton);
			
			/* Callout Position Helper Creation */
			if (positionHelper != null) positionHelper.removeFromParent(true);
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
			if (workflowConfigSenderCallout != null) workflowConfigSenderCallout.removeFromParent(true);
			workflowConfigSenderCallout = new Callout();
			workflowConfigSenderCallout.content = mainContainer;
			workflowConfigSenderCallout.origin = positionHelper;
			workflowConfigSenderCallout.minWidth = 240;
			
			emailField.setFocus();
		}
		
		private static function closeCallout():void
		{
			//Close the callout
			if (PopUpManager.isPopUp(workflowConfigSenderCallout))
				SystemUtil.executeWhenApplicationIsActive(PopUpManager.removePopUp, workflowConfigSenderCallout, true);
			else if (workflowConfigSenderCallout != null)
				SystemUtil.executeWhenApplicationIsActive(workflowConfigSenderCallout.close, true);
		}
		
		/**
		 * Event Listeners
		 */
		private static function onClose(e:starling.events.Event):void
		{
			if (emailLabel == null || sendButton == null)
				return;
			
			//Validation
			emailLabel.text = ModelLocator.resourceManagerInstance.getString('globaltranslations',"user_email_label");
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
			
			sendButton.isEnabled = false;
			
			//Subject and Body
			var emailSubject:String;
			var emailBody:String;
			if (selectedWorkflow == WORKFLOW_MIAOMIAO_ON_DEMAND)
			{
				emailSubject = ModelLocator.resourceManagerInstance.getString('transmittersettingsscreen',"workflow_miaomiao_email_subject");
				emailBody = ModelLocator.resourceManagerInstance.getString('transmittersettingsscreen',"workflow_miaomiao_email_body");
			}
			else if (selectedWorkflow == WORKFLOW_ALARMS)
			{
				emailSubject = ModelLocator.resourceManagerInstance.getString('alarmsettingsscreen',"workflow_alarms_email_subject");
				emailBody = ModelLocator.resourceManagerInstance.getString('alarmsettingsscreen',"workflow_alarms_email_body");
			}
			else if (selectedWorkflow == WORKFLOW_TREATMENTS)
			{
				emailSubject = ModelLocator.resourceManagerInstance.getString('treatments',"workflow_email_subject");
				emailBody = ModelLocator.resourceManagerInstance.getString('treatments',"workflow_email_body");
			}
			
			//Create URL Request 
			var vars:URLVariables = new URLVariables();
			vars.mimeType = "text/html";
			vars.emailSubject = emailSubject;
			vars.emailBody = emailBody;
			vars.userEmail = emailField.text.replace(" ", "");
				
			//Send data
			EmailSender.sendData
			(
				EmailSender.TRANSMISSION_URL_NO_ATTACHMENT,
				onLoadCompleteHandler,
				vars
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
				AlertManager.showSimpleAlert
				(
					ModelLocator.resourceManagerInstance.getString('globaltranslations','success_alert_title'),
					ModelLocator.resourceManagerInstance.getString('globaltranslations','configuration_sent_successfully'),
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
					ModelLocator.resourceManagerInstance.getString('globaltranslations','configuration_not_sent') + " " + response.statuscode,
					Number.NaN,
					[
						{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations','cancel_button_label').toUpperCase() },	
						{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations','try_again_button_label'), triggered: onTryAgain },	
					]
				);
				
				function onTryAgain(e:starling.events.Event):void
				{
					Starling.juggler.delayCall(displayWorkflowConfigSender, 0.5);
				}
			}
		}
		
		private static function onCancel(e:starling.events.Event):void
		{
			closeCallout();
		}
	}
}