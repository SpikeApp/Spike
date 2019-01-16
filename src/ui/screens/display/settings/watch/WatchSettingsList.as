package ui.screens.display.settings.watch
{
	import com.distriqt.extension.calendar.AuthorisationStatus;
	import com.distriqt.extension.calendar.Calendar;
	import com.distriqt.extension.calendar.events.AuthorisationEvent;
	import com.distriqt.extension.calendar.objects.CalendarObject;
	
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLVariables;
	
	import mx.utils.ObjectUtil;
	
	import database.CGMBlueToothDevice;
	import database.LocalSettings;
	
	import feathers.controls.Button;
	import feathers.controls.Callout;
	import feathers.controls.Check;
	import feathers.controls.Label;
	import feathers.controls.LayoutGroup;
	import feathers.controls.List;
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
	import starling.events.ResizeEvent;
	import starling.text.TextFormat;
	import starling.utils.SystemUtil;
	
	import ui.popups.AlertManager;
	import ui.screens.display.LayoutFactory;
	import ui.screens.display.SpikeList;
	
	import utils.Constants;
	import utils.DataValidator;
	import utils.DeviceInfo;
	import utils.Trace;
	
	[ResourceBundle("globaltranslations")]
	[ResourceBundle("watchsettingsscreen")]

	public class WatchSettingsList extends SpikeList 
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
		private var authorizeButton:Button;
		private var sendEmail:Button;
		private var emailLabel:Label;
		private var emailField:TextInput;
		private var sendButton:Button;
		private var instructionsSenderCallout:Callout;
		private var gapFixCheck:Check;
		private var displayIOBCheck:Check;
		private var displayCOBCheck:Check;
		private var displayPredictionsCheck:Check;
		
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
		private var gapFixValue:Boolean;
		private var displayIOBEnabled:Boolean;
		private var displayCOBEnabled:Boolean;
		private var displayPredictionsEnabled:Boolean;

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
			gapFixValue = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_GAP_FIX_ON) == "true";
			displayIOBEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_IOB_ON) == "true";
			displayCOBEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_COB_ON) == "true";
			displayPredictionsEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_PREDICTIONS_ON) == "true";
			
			Trace.myTrace("WatchSettingsList.as", "setupInitialState called! AuthorizationStatus = " + Calendar.service.authorisationStatus());
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
			{
				Trace.myTrace("WatchSettingsList.as", "Calendar access is Authorized!");
				populateCalendarList();
			}
			else
				Trace.myTrace("WatchSettingsList.as", "Calendar access not Authorized!");
			
			calendarPickerList.addEventListener(starling.events.Event.CHANGE, onUpdateSaveStatus);
			
			//Display Name Toggle
			displayNameToggle = LayoutFactory.createToggleSwitch(displayNameEnabled);
			displayNameToggle.addEventListener(starling.events.Event.CHANGE, onDisplayNameChanged);
			
			//Display IOB Toggle
			displayIOBCheck = LayoutFactory.createCheckMark(displayIOBEnabled);
			displayIOBCheck.addEventListener(starling.events.Event.CHANGE, onDisplayTreatmentsChanged);
			
			//Display COB Toggle
			displayCOBCheck = LayoutFactory.createCheckMark(displayCOBEnabled);
			displayCOBCheck.addEventListener(starling.events.Event.CHANGE, onDisplayTreatmentsChanged);
			
			//Display Predictions Toggle
			displayPredictionsCheck = LayoutFactory.createCheckMark(displayPredictionsEnabled);
			displayPredictionsCheck.addEventListener(starling.events.Event.CHANGE, onDisplayPredictionsChanged);
			
			//Display Name TextInput
			displayNameTextInput = LayoutFactory.createTextInput(false, false, Constants.isPortrait ? 140 : 240, HorizontalAlign.RIGHT);
			if (DeviceInfo.isTablet()) displayNameTextInput.width += 100;
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
			
			//Gap Fix
			gapFixCheck = LayoutFactory.createCheckMark(gapFixValue);
			gapFixCheck.addEventListener(starling.events.Event.CHANGE, onUpdateSaveStatus);
			
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
			
			(layout as VerticalLayout).hasVariableItemDimensions = true;
			
			refreshContent();
		}
		
		private function refreshContent():void
		{
			Trace.myTrace("WatchSettingsList.as", "refreshContent called!");
			
			var content:Array = [];
			content.push({ label: ModelLocator.resourceManagerInstance.getString('globaltranslations','enabled'), accessory: watchComplicationToggle });
			if (watchComplicationEnabled)
			{
				if (isDeviceAuthorized || Calendar.service.authorisationStatus() == AuthorisationStatus.AUTHORISED)
				{
					populateCalendarList();
					content.push({ label: ModelLocator.resourceManagerInstance.getString('watchsettingsscreen','calendar_label'), accessory: calendarPickerList });
					content.push({ label: ModelLocator.resourceManagerInstance.getString('watchsettingsscreen','display_name_label'), accessory: displayNameToggle });
					if (displayNameEnabled) content.push({ label: ModelLocator.resourceManagerInstance.getString('watchsettingsscreen','your_name_label'), accessory: displayNameTextInput });
					if (!CGMBlueToothDevice.isDexcomFollower()) content.push({ label: ModelLocator.resourceManagerInstance.getString('watchsettingsscreen','display_iob_label'), accessory: displayIOBCheck });
					if (!CGMBlueToothDevice.isDexcomFollower()) content.push({ label: ModelLocator.resourceManagerInstance.getString('watchsettingsscreen','display_cob_label'), accessory: displayCOBCheck });
					content.push({ label: ModelLocator.resourceManagerInstance.getString('watchsettingsscreen','display_predictions_label'), accessory: displayPredictionsCheck });
					content.push({ label: ModelLocator.resourceManagerInstance.getString('watchsettingsscreen','display_trend_label'), accessory: displayTrend });
					content.push({ label: ModelLocator.resourceManagerInstance.getString('watchsettingsscreen','display_delta_label'), accessory: displayDelta });
					content.push({ label: ModelLocator.resourceManagerInstance.getString('watchsettingsscreen','display_units_label'), accessory: displayUnits });
					if (!CGMBlueToothDevice.isFollower() && !CGMBlueToothDevice.isMiaoMiao())
						content.push({ label: ModelLocator.resourceManagerInstance.getString('watchsettingsscreen','gap_fix_label'), accessory: gapFixCheck });
				}
				else
					content.push({ label: "", accessory: authorizeButton });
			}
			
			content.push({ label: "", accessory: instructionsTitleLabel });
			content.push({ label: "", accessory: instructionsDescriptionLabel });
			content.push({ label: "", accessory: sendEmail });
			
			
			dataProvider = new ArrayCollection(content);
		}
		
		private function populateCalendarList():void
		{
			Trace.myTrace("WatchSettingsList.as", "populateCalendarList called!");
			
			var content:ArrayCollection = new ArrayCollection();
			var selectedIndex:int = 0;
			var calendarMatch:Boolean = false;
			
			var calendars:Array = Calendar.service.getCalendars();
			Trace.myTrace("WatchSettingsList.as", "Available calendars in the phone: " + ObjectUtil.toString(calendars));
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
			
			needsSave = false;
			
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
			
			//Display IOB
			if(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_IOB_ON) != String(displayIOBEnabled))
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_IOB_ON, String(displayIOBEnabled));
			
			//Display COB
			if(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_COB_ON) != String(displayCOBEnabled))
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_COB_ON, String(displayCOBEnabled));
			
			//Display Predictions
			if(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_PREDICTIONS_ON) != String(displayPredictionsEnabled))
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_PREDICTIONS_ON, String(displayPredictionsEnabled));
			
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
			
			//Gap Fix
			var gapFixValueToSave:String;
			if (gapFixCheck.isSelected) gapFixValueToSave = "true";
			else gapFixValueToSave = "false";
			
			if(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_GAP_FIX_ON) != gapFixValueToSave)
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_WATCH_COMPLICATION_GAP_FIX_ON, gapFixValueToSave);
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
				
				AlertManager.showSimpleAlert
				(
					ModelLocator.resourceManagerInstance.getString('globaltranslations','info_alert_title'),
					ModelLocator.resourceManagerInstance.getString('watchsettingsscreen','reboot_warning')
				);
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
			
			refreshContent();
			
			needsSave = true;
			
			save();
		}
		
		private function onDisplayNameChanged(e:starling.events.Event):void
		{
			displayNameEnabled = displayNameToggle.isSelected;
			if (displayNameEnabled)
			{
				displayIOBEnabled = false;
				displayCOBEnabled = false;
				displayPredictionsEnabled = false;
				displayIOBCheck.removeEventListener(starling.events.Event.CHANGE, onDisplayTreatmentsChanged);
				displayCOBCheck.removeEventListener(starling.events.Event.CHANGE, onDisplayTreatmentsChanged);
				displayPredictionsCheck.removeEventListener(starling.events.Event.CHANGE, onDisplayPredictionsChanged);
				displayIOBCheck.isSelected = displayIOBEnabled;
				displayCOBCheck.isSelected = displayCOBEnabled;
				displayPredictionsCheck.isSelected = displayPredictionsEnabled;
				displayIOBCheck.addEventListener(starling.events.Event.CHANGE, onDisplayTreatmentsChanged);
				displayCOBCheck.addEventListener(starling.events.Event.CHANGE, onDisplayTreatmentsChanged);
				displayPredictionsCheck.addEventListener(starling.events.Event.CHANGE, onDisplayPredictionsChanged);
			}
			
			refreshContent();
			
			needsSave = true;
			
			save();
		}
		
		private function onDisplayTreatmentsChanged(e:starling.events.Event):void
		{
			displayIOBEnabled = displayIOBCheck.isSelected;
			displayCOBEnabled = displayCOBCheck.isSelected;
			if (displayIOBEnabled || displayCOBEnabled)
			{
				displayNameEnabled = false;
				displayPredictionsEnabled = false;
				displayNameToggle.removeEventListener(starling.events.Event.CHANGE, onDisplayNameChanged);
				displayPredictionsCheck.removeEventListener(starling.events.Event.CHANGE, onDisplayPredictionsChanged);
				displayNameToggle.isSelected = displayNameEnabled;
				displayPredictionsCheck.isSelected = displayPredictionsEnabled;
				displayNameToggle.addEventListener(starling.events.Event.CHANGE, onDisplayNameChanged);
				displayPredictionsCheck.addEventListener(starling.events.Event.CHANGE, onDisplayPredictionsChanged);
			}
			
			refreshContent();
			
			needsSave = true;
			
			save();
		}
		
		private function onDisplayPredictionsChanged(e:starling.events.Event):void
		{
			displayPredictionsEnabled = displayPredictionsCheck.isSelected;
			
			if (displayPredictionsEnabled)
			{
				displayIOBEnabled = false;
				displayCOBEnabled = false;
				displayNameEnabled = false;
				displayIOBCheck.removeEventListener(starling.events.Event.CHANGE, onDisplayTreatmentsChanged);
				displayCOBCheck.removeEventListener(starling.events.Event.CHANGE, onDisplayTreatmentsChanged);
				displayNameToggle.removeEventListener(starling.events.Event.CHANGE, onDisplayNameChanged);
				displayIOBCheck.isSelected = displayIOBEnabled;
				displayCOBCheck.isSelected = displayCOBEnabled;
				displayNameToggle.isSelected = displayNameEnabled;
				displayIOBCheck.addEventListener(starling.events.Event.CHANGE, onDisplayTreatmentsChanged);
				displayCOBCheck.addEventListener(starling.events.Event.CHANGE, onDisplayTreatmentsChanged);
				displayNameToggle.addEventListener(starling.events.Event.CHANGE, onDisplayNameChanged);
			}
			
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
			emailField = LayoutFactory.createTextInput(false, false, 200, HorizontalAlign.CENTER, false, true);
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
			if (emailLabel == null || sendButton == null)
				return;
			
			//Validation
			emailLabel.text = ModelLocator.resourceManagerInstance.getString('globaltranslations',"user_email_label");
			if (emailLabel.fontStyles != null)
				emailLabel.fontStyles.color = 0xEEEEEE;
			else
				emailLabel.fontStyles = new TextFormat("Roboto", 14, 0xEEEEEE, HorizontalAlign.CENTER, VerticalAlign.TOP)
			
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
			else if (instructionsSenderCallout != null)
				instructionsSenderCallout.close(true);
		}
		
		override protected function onStarlingResize(event:ResizeEvent):void 
		{
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
			
			if (displayNameTextInput != null)
			{
				displayNameTextInput.width = Constants.isPortrait ? 140 : 240;
				if (DeviceInfo.isTablet()) displayNameTextInput.width += 100;
				SystemUtil.executeWhenApplicationIsActive( displayNameTextInput.clearFocus );
			}
			
			if (instructionsTitleLabel != null)
			{
				if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr && !Constants.isPortrait)
					instructionsTitleLabel.width = width - 40;
				else
					instructionsTitleLabel.width = width - 20;
			}
			
			if (instructionsDescriptionLabel != null)
			{
				if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr && !Constants.isPortrait)
					instructionsDescriptionLabel.width = width - 40;
				else
					instructionsDescriptionLabel.width = width - 20;
			}
			
			setupRenderFactory();
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
				displayNameToggle.removeEventListener(starling.events.Event.CHANGE, onDisplayNameChanged);
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
				try
				{
					calendarPickerList.dispose();
					calendarPickerList = null;
				} 
				catch(error:Error) {}
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
			
			if (gapFixCheck != null)
			{
				gapFixCheck.removeEventListener(starling.events.Event.CHANGE, onUpdateSaveStatus);
				gapFixCheck.dispose();
				gapFixCheck = null;
			}
			
			if (displayIOBCheck != null)
			{
				displayIOBCheck.removeEventListener(starling.events.Event.CHANGE, onDisplayTreatmentsChanged);
				displayIOBCheck.dispose();
				displayIOBCheck = null;
			}
			
			if (displayCOBCheck != null)
			{
				displayCOBCheck.removeEventListener(starling.events.Event.CHANGE, onDisplayTreatmentsChanged);
				displayCOBCheck.dispose();
				displayCOBCheck = null;
			}
			
			if (displayPredictionsCheck != null)
			{
				displayPredictionsCheck.removeEventListener(starling.events.Event.CHANGE, onDisplayPredictionsChanged);
				displayPredictionsCheck.dispose();
				displayPredictionsCheck = null;
			}
			
			super.dispose();
		}
	}
}