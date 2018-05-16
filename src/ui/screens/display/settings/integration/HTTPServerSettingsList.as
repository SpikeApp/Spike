package ui.screens.display.settings.integration
{
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLVariables;
	
	import database.LocalSettings;
	
	import feathers.controls.Button;
	import feathers.controls.Callout;
	import feathers.controls.Label;
	import feathers.controls.LayoutGroup;
	import feathers.controls.List;
	import feathers.controls.TextInput;
	import feathers.controls.ToggleSwitch;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.controls.text.HyperlinkTextFieldTextRenderer;
	import feathers.core.ITextRenderer;
	import feathers.core.PopUpManager;
	import feathers.data.ArrayCollection;
	import feathers.events.FeathersEventType;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.HorizontalLayout;
	import feathers.layout.VerticalAlign;
	import feathers.layout.VerticalLayout;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.ModelLocator;
	
	import network.EmailSender;
	
	import starling.core.Starling;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.ResizeEvent;
	import starling.utils.SystemUtil;
	
	import ui.popups.AlertManager;
	import ui.screens.display.LayoutFactory;
	
	import utils.Constants;
	import utils.DataValidator;
	
	[ResourceBundle("globaltranslations")]
	[ResourceBundle("httpserversettingsscreen")]

	public class HTTPServerSettingsList extends List 
	{
		/* Display Objects */
		private var loopOfflineToggle:ToggleSwitch;
		private var instructionsTitleLabel:Label;
		private var instructionsDescriptionLabel:Label;
		private var userNameTextInput:TextInput;
		private var passwordTextInput:TextInput;
		private var sendEmail:Button;
		private var emailField:TextInput;
		private var emailLabel:Label;
		private var sendButton:Button;
		private var instructionsSenderCallout:Callout;
		private var dexcomCredentialsLabel:Label;
		private var developersAPITitleLabel:Label;
		private var developersAPIDescriptionLabel:Label;
		private var actionsContainer:LayoutGroup;
		private var positionHelper:Sprite;
		
		/* Properties */
		public var needsSave:Boolean = false;
		private var httpServiceEnabled:Boolean;
		private var serverUsername:String;
		private var serverPassword:String;

		public function HTTPServerSettingsList()
		{
			super();
		}
		override protected function initialize():void 
		{
			super.initialize();
			
			Starling.current.stage.addEventListener(starling.events.Event.RESIZE, onStarlingResize);
			
			setupProperties();
			setupInitialState();
			setupContent();
		}
		
		/**
		 * Functionality
		 */
		private function setupProperties():void
		{
			//Set Properties
			clipContent = false;
			isSelectable = false;
			autoHideBackground = true;
			hasElasticEdges = false;
			paddingBottom = 5;
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
		}
		
		private function setupInitialState():void
		{
			httpServiceEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_LOOP_SERVER_ON) == "true";
			serverUsername = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_LOOP_SERVER_USERNAME);
			serverPassword = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_LOOP_SERVER_PASSWORD);
		}
		
		private function setupContent():void
		{
			//HTTP Server On/Off Toggle
			loopOfflineToggle = LayoutFactory.createToggleSwitch(httpServiceEnabled);
			loopOfflineToggle.addEventListener(starling.events.Event.CHANGE, onSettingsChanged);
			
			dexcomCredentialsLabel = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('httpserversettingsscreen','dexcom_share_credentials_label'), HorizontalAlign.CENTER);
			dexcomCredentialsLabel.width = width - 20;
			
			//UserneName TextInput
			userNameTextInput = LayoutFactory.createTextInput(false, false, Constants.isPortrait ? 140 : 240, HorizontalAlign.RIGHT);
			userNameTextInput.text = serverUsername;
			userNameTextInput.addEventListener(FeathersEventType.ENTER, onEnterPressed);
			userNameTextInput.addEventListener(starling.events.Event.CHANGE, onUpdateSaveStatus);
			userNameTextInput.addEventListener(FeathersEventType.FOCUS_OUT, onFocusOut);
			
			//Password TextInput
			passwordTextInput = LayoutFactory.createTextInput(true, false, Constants.isPortrait ? 140 : 240, HorizontalAlign.RIGHT);
			passwordTextInput.text = serverPassword;
			passwordTextInput.addEventListener(FeathersEventType.ENTER, onEnterPressed);
			passwordTextInput.addEventListener(starling.events.Event.CHANGE, onUpdateSaveStatus);
			passwordTextInput.addEventListener(FeathersEventType.FOCUS_OUT, onFocusOut);
			
			//Instructions Title Label
			instructionsTitleLabel = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('httpserversettingsscreen','instructions_title_label'), HorizontalAlign.CENTER, VerticalAlign.TOP, 17, true);
			instructionsTitleLabel.width = width - 20;
			
			//Instructions Description Label
			instructionsDescriptionLabel = new Label();
			instructionsDescriptionLabel.text = ModelLocator.resourceManagerInstance.getString('httpserversettingsscreen','instructions_description_label');
			instructionsDescriptionLabel.width = width - 20;
			instructionsDescriptionLabel.wordWrap = true;
			instructionsDescriptionLabel.paddingTop = 10;
			instructionsDescriptionLabel.isQuickHitAreaEnabled = false;
			instructionsDescriptionLabel.textRendererFactory = function():ITextRenderer 
			{
				var textRenderer:HyperlinkTextFieldTextRenderer = new HyperlinkTextFieldTextRenderer();
				textRenderer.wordWrap = true;
				textRenderer.isHTML = true;
				textRenderer.pixelSnapping = true;
					
				return textRenderer;
			};
			
			//Developer's API Title Label
			developersAPITitleLabel = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('httpserversettingsscreen','developer_info_label'), HorizontalAlign.CENTER, VerticalAlign.TOP, 17, true);
			developersAPITitleLabel.width = width - 20;
			
			//Developer's API Description Label
			developersAPIDescriptionLabel = new Label();
			developersAPIDescriptionLabel.text = ModelLocator.resourceManagerInstance.getString('httpserversettingsscreen','developer_info_description');
			developersAPIDescriptionLabel.width = width - 20;
			developersAPIDescriptionLabel.wordWrap = true;
			developersAPIDescriptionLabel.paddingTop = 10;
			developersAPIDescriptionLabel.isQuickHitAreaEnabled = false;
			developersAPIDescriptionLabel.textRendererFactory = function():ITextRenderer 
			{
				var textRenderer:HyperlinkTextFieldTextRenderer = new HyperlinkTextFieldTextRenderer();
				textRenderer.wordWrap = true;
				textRenderer.isHTML = true;
				textRenderer.pixelSnapping = true;
				
				return textRenderer;
			};
			
			//Send Container
			var actionsLayout:HorizontalLayout = new HorizontalLayout();
			actionsLayout.horizontalAlign = HorizontalAlign.CENTER;
			
			actionsContainer = new LayoutGroup();
			actionsContainer.layout = actionsLayout;
			actionsContainer.width = width - 20;
			
			//Send Email Button
			sendEmail = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('globaltranslations','email_button_label'), false, MaterialDeepGreyAmberMobileThemeIcons.sendTexture);
			sendEmail.addEventListener(starling.events.Event.TRIGGERED, onSendEmail);
			actionsContainer.addChild(sendEmail);
			
			//Set Item Renderer
			itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "text";
				itemRenderer.accessoryField = "accessory";
				
				return itemRenderer;
			};
			
			(layout as VerticalLayout).hasVariableItemDimensions = true;
			
			refreshContent();
		}
		
		private function refreshContent():void
		{
			var content:Array = [];
			content.push({ text: ModelLocator.resourceManagerInstance.getString('globaltranslations','enabled'), accessory: loopOfflineToggle });
			if (httpServiceEnabled)
			{
				content.push({ text: "", accessory: dexcomCredentialsLabel });
				content.push({ text: ModelLocator.resourceManagerInstance.getString('httpserversettingsscreen','username_label_title'), accessory: userNameTextInput });
				content.push({ text: ModelLocator.resourceManagerInstance.getString('httpserversettingsscreen','password_label_title'), accessory: passwordTextInput });
				content.push({ text: "", accessory: instructionsTitleLabel });
				content.push({ text: "", accessory: instructionsDescriptionLabel });
				content.push({ text: "", accessory: actionsContainer });
				content.push({ text: "", accessory: developersAPITitleLabel });
				content.push({ text: "", accessory: developersAPIDescriptionLabel });
			}
			
			dataProvider = new ArrayCollection(content);
		}
		
		public function save():void
		{
			//Feature On/Off
			var httpServiceValueToSave:String;
			if(httpServiceEnabled) httpServiceValueToSave = "true";
			else httpServiceValueToSave = "false";
				
			if(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_LOOP_SERVER_ON) != httpServiceValueToSave)
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_LOOP_SERVER_ON, httpServiceValueToSave);
				
			//Username
			if(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_LOOP_SERVER_USERNAME) != userNameTextInput.text)
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_LOOP_SERVER_USERNAME, userNameTextInput.text);
				
			//Password
			if(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_LOOP_SERVER_PASSWORD) != passwordTextInput.text)
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_LOOP_SERVER_PASSWORD, passwordTextInput.text);
			
			needsSave = false;
		}
		
		/**
		 * Event Handlers
		 */
		private function onSendEmail(e:starling.events.Event):void
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
			sendButton.addEventListener(starling.events.Event.TRIGGERED, onClose);
			actionButtonsContainer.addChild(sendButton);
			
			/* Callout Position Helper Creation */
			positionHelper = new Sprite();
			positionHelper.x = Constants.stageWidth / 2;
			positionHelper.y = 70;
			Starling.current.stage.addChild(positionHelper);
			
			/* Callout Creation */
			instructionsSenderCallout = new Callout();
			instructionsSenderCallout.content = mainContainer;
			instructionsSenderCallout.origin = positionHelper;
			instructionsSenderCallout.minWidth = 240;
			
			//Close the callout
			if (PopUpManager.isPopUp(instructionsSenderCallout))
				PopUpManager.removePopUp(instructionsSenderCallout, false);
			else if (instructionsSenderCallout != null)
				instructionsSenderCallout.close(false);
			
			//Display callout
			PopUpManager.addPopUp(instructionsSenderCallout, false, false);
			
			emailField.setFocus();
		}
		
		private function onClose(e:starling.events.Event):void
		{
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
			
			//Create URL Request 
			var vars:URLVariables = new URLVariables();
			vars.mimeType = "text/html";
			vars.emailSubject = ModelLocator.resourceManagerInstance.getString('httpserversettingsscreen',"email_instructions_subject");
			vars.emailBody = ModelLocator.resourceManagerInstance.getString('httpserversettingsscreen','instructions_description_label') + "<p>Have a great day!</p><p>Spike App</p>";
			vars.userName = "";
			vars.userEmail = emailField.text.replace(" ", "");
			
			//Send Email
			EmailSender.sendData
			(
				EmailSender.TRANSMISSION_URL_NO_ATTACHMENT,
				onLoadCompleteHandler,
				vars
			);
		}
		
		private function onLoadCompleteHandler(event:flash.events.Event):void 
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
						ModelLocator.resourceManagerInstance.getString('globaltranslations','instructions_sent_successfully'),
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
						ModelLocator.resourceManagerInstance.getString('globaltranslations','instructions_not_sent') + " " + response.statuscode,
						Number.NaN,
						[
							{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations','cancel_button_label').toUpperCase() },	
							{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations','try_again_button_label'), triggered: onTryAgain },	
						]
					);
				
				function onTryAgain(e:starling.events.Event):void
				{
					Starling.juggler.delayCall(onSendEmail, 0.5, null);
				}
			}
		}
		
		private function onCancel(e:starling.events.Event):void
		{
			closeCallout();
		}
		
		private function closeCallout():void
		{
			//Close the callout
			if (PopUpManager.isPopUp(instructionsSenderCallout))
				PopUpManager.removePopUp(instructionsSenderCallout, true);
			else if (instructionsSenderCallout != null)
				instructionsSenderCallout.close(true);
		}

		private function onSettingsChanged(e:starling.events.Event):void
		{
			httpServiceEnabled = loopOfflineToggle.isSelected;
			
			refreshContent();
			
			needsSave = true;
		}
		
		private function onUpdateSaveStatus(e:starling.events.Event):void
		{
			needsSave = true;
		}
		
		private function onEnterPressed(e:starling.events.Event):void
		{
			userNameTextInput.clearFocus();
			passwordTextInput.clearFocus();
			
			if (needsSave)
				save();
		}
		
		private function onFocusOut(e:starling.events.Event):void
		{
			if (needsSave)
				save();
		}
		
		private function onStarlingResize(event:ResizeEvent):void 
		{
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
			
			if (userNameTextInput != null)
			{
				userNameTextInput.width = Constants.isPortrait ? 140 : 240;
				SystemUtil.executeWhenApplicationIsActive( userNameTextInput.clearFocus );
			}
			
			if (passwordTextInput != null)
			{
				passwordTextInput.width = Constants.isPortrait ? 140 : 240;
				passwordTextInput.clearFocus();
			}
			
			if (instructionsTitleLabel != null)
				instructionsTitleLabel.width = width - 20;
			
			if (instructionsDescriptionLabel != null)
				instructionsDescriptionLabel.width = width - 20;
			
			if (developersAPITitleLabel != null)
				developersAPITitleLabel.width = width - 20;
			
			if (developersAPIDescriptionLabel != null)
				developersAPIDescriptionLabel.width = width - 20;
			
			if (actionsContainer != null)
				actionsContainer.width = width - 20;
			
			if (positionHelper != null)
				positionHelper.x = Constants.stageWidth / 2;
			
			if (emailField != null)
				emailField.clearFocus();
		}
		
		/**
		 * Utility
		 */		
		override public function dispose():void
		{
			Starling.current.stage.removeEventListener(starling.events.Event.RESIZE, onStarlingResize);
			
			if (positionHelper != null)
			{
				positionHelper.removeFromParent();
				positionHelper.dispose();
				positionHelper = null;
			}
			
			if(loopOfflineToggle != null)
			{
				loopOfflineToggle.removeEventListener(starling.events.Event.CHANGE, onSettingsChanged);
				loopOfflineToggle.dispose();
				loopOfflineToggle = null;
			}
			
			if (instructionsTitleLabel != null)
			{
				instructionsTitleLabel.dispose();
				instructionsTitleLabel = null;
			}
			
			if (instructionsDescriptionLabel != null)
			{
				instructionsDescriptionLabel.dispose();
				instructionsDescriptionLabel = null;
			}
			
			if (userNameTextInput != null)
			{
				userNameTextInput.removeEventListener(starling.events.Event.CHANGE, onUpdateSaveStatus);
				userNameTextInput.removeEventListener(FeathersEventType.FOCUS_OUT, onFocusOut);
				userNameTextInput.removeEventListener(FeathersEventType.ENTER, onEnterPressed);
				userNameTextInput.dispose();
				userNameTextInput = null;
			}
			
			if (passwordTextInput != null)
			{
				passwordTextInput.removeEventListener(starling.events.Event.CHANGE, onUpdateSaveStatus);
				passwordTextInput.removeEventListener(FeathersEventType.FOCUS_OUT, onFocusOut);
				passwordTextInput.removeEventListener(FeathersEventType.ENTER, onEnterPressed);
				passwordTextInput.dispose();
				passwordTextInput = null;
			}
			
			if (sendEmail != null)
			{
				sendEmail.removeEventListener(starling.events.Event.TRIGGERED, onSendEmail);
				sendEmail.dispose();
				sendEmail = null;
			}
			
			if (emailField != null)
			{
				emailField.dispose();
				emailField = null;
			}
			
			if (emailLabel != null)
			{
				emailLabel.dispose();
				emailLabel = null;
			}
			
			if (sendButton != null)
			{
				actionsContainer.removeChild(sendButton)
				sendButton.removeEventListener(starling.events.Event.TRIGGERED, onClose);
				sendButton.dispose();
				sendButton = null;
			}
			
			if (actionsContainer != null)
			{
				actionsContainer.dispose();
				actionsContainer = null;
			}
			
			if (instructionsSenderCallout != null)
			{
				instructionsSenderCallout.dispose();
				instructionsSenderCallout = null;
			}
			
			if (dexcomCredentialsLabel != null)
			{
				dexcomCredentialsLabel.dispose();
				dexcomCredentialsLabel = null;
			}
			
			if (developersAPITitleLabel != null)
			{
				developersAPITitleLabel.dispose();
				developersAPITitleLabel = null;
			}
			
			if (developersAPIDescriptionLabel != null)
			{
				developersAPIDescriptionLabel.dispose();
				developersAPIDescriptionLabel = null;
			}
			
			super.dispose();
		}
	}
}