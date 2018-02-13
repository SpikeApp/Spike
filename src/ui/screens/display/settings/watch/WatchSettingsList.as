package ui.screens.display.settings.watch
{
	import com.distriqt.extension.calendar.AuthorisationStatus;
	import com.distriqt.extension.calendar.Calendar;
	import com.distriqt.extension.calendar.events.AuthorisationEvent;
	import com.distriqt.extension.calendar.objects.CalendarObject;
	
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLVariables;
	
	import database.LocalSettings;
	
	import feathers.controls.Button;
	import feathers.controls.Callout;
	import feathers.controls.Check;
	import feathers.controls.Label;
	import feathers.controls.LayoutGroup;
	import feathers.controls.List;
	import feathers.controls.NumericStepper;
	import feathers.controls.PickerList;
	import feathers.controls.TextInput;
	import feathers.controls.ToggleSwitch;
	import feathers.controls.popups.DropDownPopUpContentManager;
	import feathers.controls.popups.VerticalCenteredPopUpContentManager;
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
	
	import ui.popups.AlertManager;
	import ui.screens.display.LayoutFactory;
	
	import utils.Constants;
	import utils.DataValidator;
	import utils.Trace;
	
	[ResourceBundle("globaltranslations")]
	[ResourceBundle("watchsettingsscreen")]

	public class WatchSettingsList extends List 
	{
		/* Display Objects */
		private var watchComplicationToggle:ToggleSwitch;
		private var instructionsTitleLabel:Label;
		private var instructionsDescriptionLabel:Label;
		private var displayNameToggle:ToggleSwitch;
		private var displayNameTextInput:TextInput;
		private var calendarPickerList:PickerList;
		private var displayTrend:Check;
		private var displayDelta:Check;
		private var displayUnits:Check;
		private var glucoseHistory:NumericStepper;
		private var authorizeButton:Button;
		
		/* Properties */
		public var needsSave:Boolean = false;
		private var watchComplicationEnabled:Boolean;
		private var displayNameEnabled:Boolean;
		private var displayNameValue:String;
		private var isDeviceAuthorized:Boolean;
		private var selectedCalendarID:String;
		private var displayTrendEnabled:Boolean;
		private var displayDeltaEnabled:Boolean;
		private var displayUnitsEnabled:Boolean;
		private var glucoseHistoryValue:int;

		private var sendEmail:Button;

		private var emailLabel:Label;

		private var emailField:TextInput;

		private var sendButton:Button;

		private var instructionsSenderCallout:Callout;

		public function WatchSettingsList()
		{
			super();
		}
		override protected function initialize():void 
		{
			super.initialize();
			
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
			watchComplicationEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_ON) == "true";
			displayNameEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_NAME_ON) == "true";
			displayNameValue = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_NAME);
			selectedCalendarID = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_SELECTED_CALENDAR_ID);
			isDeviceAuthorized = Calendar.service.authorisationStatus() == AuthorisationStatus.AUTHORISED;
			displayTrendEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_TREND) == "true";
			displayDeltaEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_DELTA) == "true";
			displayUnitsEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_UNITS) == "true";
			glucoseHistoryValue = int(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_GLUCOSE_HISTORY));
		}
		
		private function setupContent():void
		{
			//Complication On/Off Toggle
			watchComplicationToggle = LayoutFactory.createToggleSwitch(watchComplicationEnabled);
			watchComplicationToggle.addEventListener(starling.events.Event.CHANGE, onSettingsChanged);
			
			//Authorization Button
			authorizeButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('watchsettingsscreen','authorize_button_label'), false, MaterialDeepGreyAmberMobileThemeIcons.permContactCalTexture);
			authorizeButton.addEventListener(starling.events.Event.TRIGGERED, onAuthorizeDevice);
			
			//Calendar List
			calendarPickerList = LayoutFactory.createPickerList();
			calendarPickerList.labelField = "label";
			calendarPickerList.pivotX = -3;
			calendarPickerList.itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "label";
				
				return itemRenderer;
			}
			
			if(isDeviceAuthorized)
				populateCalendarList();
			
			calendarPickerList.addEventListener(starling.events.Event.CHANGE, onUpdateSaveStatus);
			
			//Display Name Toggle
			displayNameToggle = LayoutFactory.createToggleSwitch(displayNameEnabled);
			displayNameToggle.addEventListener(starling.events.Event.CHANGE, onSettingsChanged);
			
			//Display Name TextInput
			displayNameTextInput = LayoutFactory.createTextInput(false, false, 140, HorizontalAlign.RIGHT);
			displayNameTextInput.text = displayNameValue;
			displayNameTextInput.addEventListener(FeathersEventType.ENTER, onEnterPressed);
			displayNameTextInput.addEventListener(starling.events.Event.CHANGE, onUpdateSaveStatus);
			
			//Display Trend
			displayTrend = LayoutFactory.createCheckMark(displayTrendEnabled);
			displayTrend.addEventListener(starling.events.Event.CHANGE, onUpdateSaveStatus);
			
			//Display Delta
			displayDelta = LayoutFactory.createCheckMark(displayDeltaEnabled);
			displayDelta.addEventListener(starling.events.Event.CHANGE, onUpdateSaveStatus);
			
			//Display Units
			displayUnits = LayoutFactory.createCheckMark(displayUnitsEnabled);
			displayUnits.addEventListener(starling.events.Event.CHANGE, onUpdateSaveStatus);
			
			//History
			glucoseHistory = LayoutFactory.createNumericStepper(1, 36, glucoseHistoryValue);
			glucoseHistory.pivotX = -12;
			glucoseHistory.addEventListener(starling.events.Event.CHANGE, onUpdateSaveStatus);
			
			//Instructions Title Label
			instructionsTitleLabel = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('watchsettingsscreen','instructions_title_label'), HorizontalAlign.CENTER, VerticalAlign.TOP, 17, true);
			instructionsTitleLabel.width = width - 20;
			
			//Instructions Description Label
			instructionsDescriptionLabel = new Label();
			instructionsDescriptionLabel.text = ModelLocator.resourceManagerInstance.getString('watchsettingsscreen','instructions_description_label');
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
			
			//Send Email Button
			sendEmail = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('globaltranslations','email_button_label'), false, MaterialDeepGreyAmberMobileThemeIcons.sendTexture);
			sendEmail.addEventListener(starling.events.Event.TRIGGERED, onSendEmail);
			
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
			content.push({ text: ModelLocator.resourceManagerInstance.getString('globaltranslations','enabled'), accessory: watchComplicationToggle });
			if (watchComplicationEnabled)
			{
				if (isDeviceAuthorized)
				{
					content.push({ text: ModelLocator.resourceManagerInstance.getString('watchsettingsscreen','calendar_label'), accessory: calendarPickerList });
					content.push({ text: ModelLocator.resourceManagerInstance.getString('watchsettingsscreen','display_name_label'), accessory: displayNameToggle });
					if (displayNameEnabled)
						content.push({ text: ModelLocator.resourceManagerInstance.getString('watchsettingsscreen','your_name_label'), accessory: displayNameTextInput });
					content.push({ text: ModelLocator.resourceManagerInstance.getString('watchsettingsscreen','display_trend_label'), accessory: displayTrend });
					content.push({ text: ModelLocator.resourceManagerInstance.getString('watchsettingsscreen','display_delta_label'), accessory: displayDelta });
					content.push({ text: ModelLocator.resourceManagerInstance.getString('watchsettingsscreen','display_units_label'), accessory: displayUnits });
					content.push({ text: ModelLocator.resourceManagerInstance.getString('watchsettingsscreen','glucose_history_label'), accessory: glucoseHistory });
				}
				else
					content.push({ text: "", accessory: authorizeButton });
			}
			
			content.push({ text: "", accessory: instructionsTitleLabel });
			content.push({ text: "", accessory: instructionsDescriptionLabel });
			content.push({ text: "", accessory: sendEmail });
			
			
			dataProvider = new ArrayCollection(content);
		}
		
		private function populateCalendarList():void
		{
			var content:ArrayCollection = new ArrayCollection();
			var selectedIndex:int = 0;
			var calendarMatch:Boolean = false;
			
			var calendars:Array = Calendar.service.getCalendars();
			for each (var calendar:CalendarObject in calendars)
			{
				content.push({ label: calendar.name, id: calendar.id });
				
				if (calendar.id == selectedCalendarID)
					calendarMatch = true;
				
				if (!calendarMatch)
					selectedIndex++;
			}
			
			if (content.length <= 6)
			{
				var dropDownPopup:DropDownPopUpContentManager = new DropDownPopUpContentManager();
				calendarPickerList.popUpContentManager = calloutPopUp;
				calendarPickerList.listFactory = function():List
				{
					var list:List = new List();
					list.paddingLeft = list.paddingRight = 10;
					
					return list;
				};
			}
			else
			{
				var calloutPopUp:VerticalCenteredPopUpContentManager = new VerticalCenteredPopUpContentManager();
				calloutPopUp.margin = 10;
				calendarPickerList.popUpContentManager = calloutPopUp;
			}
			
			//Populate Content
			calendarPickerList.dataProvider = content;
			
			//Select Predefined Calendar
			if (!calendarMatch)
			{
				calendarPickerList.selectedIndex = -1;
				calendarPickerList.prompt = ModelLocator.resourceManagerInstance.getString('watchsettingsscreen','select_calendar_label');
			}
			else
				calendarPickerList.selectedIndex = selectedIndex;
		}
		
		public function save():void
		{
			if (!needsSave)
				return;
			
			//Feature On/Off
			var complicationValueToSave:String;
			if(watchComplicationEnabled) complicationValueToSave = "true";
			else complicationValueToSave = "false";
			
			if(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_ON) != complicationValueToSave)
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_ON, complicationValueToSave);
			
			//Display Name
			var displayNameOnOffValueToSave:String;
			if(displayNameToggle.isSelected) displayNameOnOffValueToSave = "true";
			else displayNameOnOffValueToSave = "false";
			
			if(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_NAME_ON) != displayNameOnOffValueToSave)
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_NAME_ON, displayNameOnOffValueToSave);
			
			var displayNameValueToSave:String = displayNameTextInput.text;
			
			if(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_NAME) != displayNameValueToSave)
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_NAME, displayNameValueToSave);
			
			//Calendar ID
			if (isDeviceAuthorized && calendarPickerList.selectedIndex != -1)
			{
				var calendarIDValue:String = calendarPickerList.selectedItem.id;
				if(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_SELECTED_CALENDAR_ID) != calendarIDValue)
					LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_SELECTED_CALENDAR_ID, calendarIDValue);
			}
			
			//Trend
			var trendValueToSave:String;
			if (displayTrend.isSelected) trendValueToSave = "true";
			else trendValueToSave = "false";
			
			if(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_TREND) != trendValueToSave)
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_TREND, trendValueToSave);
			
			//Delta
			var deltaValueToSave:String;
			if (displayDelta.isSelected) deltaValueToSave = "true";
			else deltaValueToSave = "false";
			
			if(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_DELTA) != deltaValueToSave)
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_DELTA, deltaValueToSave);
			
			//Units
			var unitsValueToSave:String;
			if (displayUnits.isSelected) unitsValueToSave = "true";
			else unitsValueToSave = "false";
			
			if(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_UNITS) != unitsValueToSave)
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_UNITS, unitsValueToSave);
			
			//History
			var historyValueToSave:String = String(glucoseHistory.value);
			
			if(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_GLUCOSE_HISTORY) != historyValueToSave)
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_GLUCOSE_HISTORY, historyValueToSave);
			
			needsSave = false;
		}
		
		/**
		 * Event Handlers
		 */
		private function onAuthorizeDevice(e:starling.events.Event):void
		{
			Trace.myTrace("WatchSettingsList.as", "onAuthorizeDevice called!");
			
			if (Calendar.service.authorisationStatus() == AuthorisationStatus.NOT_DETERMINED || Calendar.service.authorisationStatus() == AuthorisationStatus.UNKNOWN)
			{
				Calendar.service.addEventListener( AuthorisationEvent.CHANGED, onCalendarAuthorisation );
				Calendar.service.requestAccess();
			}
			else if (Calendar.service.authorisationStatus() == AuthorisationStatus.DENIED || Calendar.service.authorisationStatus() == AuthorisationStatus.RESTRICTED || Calendar.service.authorisationStatus() == AuthorisationStatus.SHOULD_EXPLAIN)
			{
				AlertManager.showSimpleAlert
				(
					ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
					ModelLocator.resourceManagerInstance.getString('watchsettingsscreen','alert_message_manual_athorization_1')
				);
			}
		}
		
		private function onCalendarAuthorisation(event:AuthorisationEvent):void
		{
			Trace.myTrace("WatchSettingsList.as", "onCalendarAuthorisation called!");
			
			Calendar.service.removeEventListener( AuthorisationEvent.CHANGED, onCalendarAuthorisation );
			
			if (Calendar.service.authorisationStatus() == AuthorisationStatus.AUTHORISED)
			{
				Trace.myTrace("WatchSettingsList.as", "Device successfully authorized!");
				
				isDeviceAuthorized = true;
				populateCalendarList();
				refreshContent();
			}
			else
			{
				Trace.myTrace("WatchSettingsList.as", "Error authorizing calendar access. Notifying user...");
				
				AlertManager.showSimpleAlert
				(
					ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
					ModelLocator.resourceManagerInstance.getString('watchsettingsscreen','alert_message_manual_athorization_2')
				)
			}
		}
		
		private function onSettingsChanged(e:starling.events.Event):void
		{
			watchComplicationEnabled = watchComplicationToggle.isSelected;
			displayNameEnabled = displayNameToggle.isSelected;
			
			refreshContent();
			
			needsSave = true;
			
			save();
		}
		
		private function onUpdateSaveStatus(e:starling.events.Event):void
		{
			needsSave = true;
			
			save();
		}
		
		private function onEnterPressed(e:starling.events.Event):void
		{
			displayNameTextInput.clearFocus();
		}
		
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
			var positionHelper:Sprite = new Sprite();
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
				PopUpManager.removePopUp(instructionsSenderCallout, true);
			
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
			vars.emailSubject = ModelLocator.resourceManagerInstance.getString('watchsettingsscreen',"watch_instructions_subject");
			vars.emailBody = ModelLocator.resourceManagerInstance.getString('watchsettingsscreen','instructions_description_label') + "<p>Have a great day!</p><p>Spike App</p>";
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
			else
				instructionsSenderCallout.close(true);
		}
		
		/**
		 * Utility
		 */
		override protected function draw():void
		{
			super.draw();
			
			if (authorizeButton != null)
				authorizeButton.x = (width / 2) - (authorizeButton.width / 2);
		}
		
		override public function dispose():void
		{
			if(watchComplicationToggle != null)
			{
				watchComplicationToggle.removeEventListener(starling.events.Event.CHANGE, onSettingsChanged);
				watchComplicationToggle.dispose();
				watchComplicationToggle = null;
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
			
			if (displayNameToggle != null)
			{
				displayNameToggle.removeEventListener(starling.events.Event.CHANGE, onSettingsChanged);
				displayNameToggle.dispose();
				displayNameToggle = null;
			}
			
			if (displayNameTextInput != null)
			{
				displayNameTextInput.removeEventListener(FeathersEventType.ENTER, onEnterPressed);
				displayNameTextInput.dispose();
				displayNameTextInput = null;
			}
			
			if (calendarPickerList != null)
			{
				calendarPickerList.removeEventListener(starling.events.Event.CHANGE, onUpdateSaveStatus);
				calendarPickerList.dispose();
				calendarPickerList = null;
			}
			
			if (displayTrend != null)
			{
				displayTrend.removeEventListener(starling.events.Event.CHANGE, onUpdateSaveStatus);
				displayTrend.dispose();
				displayTrend = null;
			}
			
			if (displayDelta != null)
			{
				displayDelta.removeEventListener(starling.events.Event.CHANGE, onUpdateSaveStatus);
				displayDelta.dispose();
				displayDelta = null;
			}
			
			if (displayUnits != null)
			{
				displayUnits.removeEventListener(starling.events.Event.CHANGE, onUpdateSaveStatus);
				displayUnits.dispose();
				displayUnits = null;
			}
			
			if (glucoseHistory != null)
			{
				glucoseHistory.removeEventListener(starling.events.Event.CHANGE, onUpdateSaveStatus);
				glucoseHistory.dispose();
				glucoseHistory = null;
			}
			
			if (authorizeButton != null)
			{
				authorizeButton.removeEventListener(starling.events.Event.TRIGGERED, onAuthorizeDevice);
				authorizeButton.dispose();
				authorizeButton = null;
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
				sendButton.removeEventListener(starling.events.Event.TRIGGERED, onClose);
				sendButton.dispose();
				sendButton = null;
			}
			
			if (instructionsSenderCallout != null)
			{
				instructionsSenderCallout.dispose();
				instructionsSenderCallout = null;
			}
			
			super.dispose();
		}
	}
}