package ui.screens.display.settings.watch
{
	import com.distriqt.extension.calendar.AuthorisationStatus;
	import com.distriqt.extension.calendar.Calendar;
	import com.distriqt.extension.calendar.events.AuthorisationEvent;
	import com.distriqt.extension.calendar.objects.CalendarObject;
	
	import database.LocalSettings;
	
	import feathers.controls.Button;
	import feathers.controls.Check;
	import feathers.controls.Label;
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
	import feathers.data.ArrayCollection;
	import feathers.events.FeathersEventType;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalAlign;
	import feathers.layout.VerticalLayout;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.ModelLocator;
	
	import starling.events.Event;
	
	import ui.popups.AlertManager;
	import ui.screens.display.LayoutFactory;
	
	import utils.Constants;
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
			watchComplicationToggle.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Authorization Button
			authorizeButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('watchsettingsscreen','authorize_button_label'), false, MaterialDeepGreyAmberMobileThemeIcons.permContactCalTexture);
			authorizeButton.addEventListener(Event.TRIGGERED, onAuthorizeDevice);
			
			//Calendar List
			calendarPickerList = LayoutFactory.createPickerList();
			calendarPickerList.labelField = "label";
			calendarPickerList.pivotX = -3;
			calendarPickerList.addEventListener(Event.CHANGE, onUpdateSaveStatus);
			calendarPickerList.itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "label";
				
				return itemRenderer;
			}
			
			if(isDeviceAuthorized)
				populateCalendarList();
			
			//Display Name Toggle
			displayNameToggle = LayoutFactory.createToggleSwitch(displayNameEnabled);
			displayNameToggle.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Display Name TextInput
			displayNameTextInput = LayoutFactory.createTextInput(false, false, 140, HorizontalAlign.RIGHT);
			displayNameTextInput.text = displayNameValue;
			displayNameTextInput.addEventListener(FeathersEventType.ENTER, onEnterPressed);
			displayNameTextInput.addEventListener(Event.CHANGE, onUpdateSaveStatus);
			
			//Display Trend
			displayTrend = LayoutFactory.createCheckMark(displayTrendEnabled);
			displayTrend.addEventListener(Event.CHANGE, onUpdateSaveStatus);
			
			//Display Delta
			displayDelta = LayoutFactory.createCheckMark(displayDeltaEnabled);
			displayDelta.addEventListener(Event.CHANGE, onUpdateSaveStatus);
			
			//Display Units
			displayUnits = LayoutFactory.createCheckMark(displayUnitsEnabled);
			displayUnits.addEventListener(Event.CHANGE, onUpdateSaveStatus);
			
			//History
			glucoseHistory = LayoutFactory.createNumericStepper(1, 36, glucoseHistoryValue);
			glucoseHistory.pivotX = -12;
			glucoseHistory.addEventListener(Event.CHANGE, onUpdateSaveStatus);
			
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
		private function onAuthorizeDevice(e:Event):void
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
		
		private function onSettingsChanged(e:Event):void
		{
			watchComplicationEnabled = watchComplicationToggle.isSelected;
			displayNameEnabled = displayNameToggle.isSelected;
			
			refreshContent();
			
			needsSave = true;
		}
		
		private function onUpdateSaveStatus(e:Event):void
		{
			needsSave = true;
		}
		
		private function onEnterPressed(e:Event):void
		{
			displayNameTextInput.clearFocus();
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
				watchComplicationToggle.removeEventListener(Event.CHANGE, onSettingsChanged);
				watchComplicationToggle.dispose();
				watchComplicationToggle = null;
			}
			
			if (instructionsTitleLabel != null)
			{
				instructionsTitleLabel.dispose();
				instructionsTitleLabel = null;
			}
			
			if (displayNameToggle != null)
			{
				displayNameToggle.removeEventListener(Event.CHANGE, onSettingsChanged);
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
				calendarPickerList.removeEventListener(Event.CHANGE, onUpdateSaveStatus);
				calendarPickerList.dispose();
				calendarPickerList = null;
			}
			
			if (displayTrend != null)
			{
				displayTrend.removeEventListener(Event.CHANGE, onUpdateSaveStatus);
				displayTrend.dispose();
				displayTrend = null;
			}
			
			if (displayDelta != null)
			{
				displayDelta.removeEventListener(Event.CHANGE, onUpdateSaveStatus);
				displayDelta.dispose();
				displayDelta = null;
			}
			
			if (displayUnits != null)
			{
				displayUnits.removeEventListener(Event.CHANGE, onUpdateSaveStatus);
				displayUnits.dispose();
				displayUnits = null;
			}
			
			if (glucoseHistory != null)
			{
				glucoseHistory.removeEventListener(Event.CHANGE, onUpdateSaveStatus);
				glucoseHistory.dispose();
				glucoseHistory = null;
			}
			
			if (authorizeButton != null)
			{
				authorizeButton.removeEventListener(Event.TRIGGERED, onAuthorizeDevice);
				authorizeButton.dispose();
				authorizeButton = null;
			}
			
			super.dispose();
		}
	}
}