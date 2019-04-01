package ui.screens.display.dexcomshare
{
	import com.distriqt.extension.networkinfo.NetworkInfo;
	
	import database.BgReading;
	import database.CommonSettings;
	
	import events.DexcomShareEvent;
	
	import feathers.controls.Button;
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
	import feathers.data.ArrayCollection;
	import feathers.events.FeathersEventType;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.HorizontalLayout;
	import feathers.layout.RelativePosition;
	import feathers.layout.VerticalAlign;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.ModelLocator;
	
	import services.DexcomShareService;
	
	import starling.events.Event;
	
	import ui.screens.display.LayoutFactory;
	
	import utils.Constants;
	import utils.DataValidator;
	import utils.DeviceInfo;
	import utils.SpikeJSON;
	import utils.Trace;
	
	[ResourceBundle("sharesettingsscreen")]
	[ResourceBundle("globaltranslations")]
	
	public class DexcomShareFollowerCreator extends List
	{
		/* Display Objects */
		private var userDisplayName:TextInput;
		private var followerName:TextInput;
		private var followerEmail:TextInput;
		private var graphViewCheck:Check;
		private var actionsContainer:LayoutGroup;
		private var cancel:Button;
		private var sendInvite:Button;
		private var urgentLowSwitch:ToggleSwitch;
		private var lowSwitch:ToggleSwitch;
		private var highSwitch:ToggleSwitch;
		private var missedReadingSwitch:ToggleSwitch;
		private var urgentLowValue:NumericStepper;
		private var lowValue:NumericStepper;
		private var highValue:NumericStepper;
		private var lowDelay:PickerList;
		private var highDelay:PickerList;
		private var missedReadingsDelay:PickerList;
		private var errorLabel:Label;
		private var urgentLowSound:PickerList;
		private var lowSound:PickerList;
		private var highSound:PickerList;
		private var missedReadingsSound:PickerList;
		private var lowRepeat:PickerList;
		private var highRepeat:PickerList;
		
		/* Data Objects */
		private var followersList:Array;
		
		/* Data Variables */
		private var scrollPosition:Number = 0;
		private var errorMessage:String;
		private var isMmol:Boolean = false;
		
		/* Logical variables */
		private var isUrgentLowAlarmEnabled:Boolean = false;
		private var isLowAlarmEnabled:Boolean = false;
		private var isHighAlarmEnabled:Boolean = false;
		private var isMissedReadingsAlarmEnabled:Boolean = false;

		public function DexcomShareFollowerCreator(prevFollowersList:Array)
		{
			super();
			
			followersList = prevFollowersList;
		}
		
		override protected function initialize():void 
		{
			super.initialize();
			
			setupProperties();
			setupContent();
		}
		
		/**
		 * Functionality
		 */
		private function setupProperties():void
		{
			/* List Properties */
			clipContent = false;
			isSelectable = false;
			autoHideBackground = true;
			hasElasticEdges = false;
			if (Constants.deviceModel == DeviceInfo.IPHONE_2G_3G_3GS_4_4S_ITOUCH_2_3_4 || Constants.deviceModel == DeviceInfo.IPHONE_5_5S_5C_SE_ITOUCH_5_6)
				width = 250;
			else if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr)
				width = 240;
			else
				width = 300;
			
			if (Constants.deviceModel == DeviceInfo.IPHONE_2G_3G_3GS_4_4S_ITOUCH_2_3_4)
				height = 300;
			else if (Constants.deviceModel == DeviceInfo.IPHONE_5_5S_5C_SE_ITOUCH_5_6 || Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr)
				height = 400;
			else
				height = 500;
			
			/* Glucose Unit */
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) != "true")
				isMmol = true;
		}
		
		private function setupContent():void
		{
			/* Accessories */
			userDisplayName = LayoutFactory.createTextInput(false, false, width - 14, HorizontalAlign.LEFT);
			userDisplayName.addEventListener(FeathersEventType.ENTER, onTextInputEnter);
			userDisplayName.prompt = ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','user_display_name_label_prompt');
			userDisplayName.pivotX = -3;
			
			followerName = LayoutFactory.createTextInput(false, false, width - 14, HorizontalAlign.LEFT);
			followerName.addEventListener(FeathersEventType.ENTER, onTextInputEnter);
			followerName.prompt = ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','follower_name_label_prompt');
			followerName.pivotX = -3;
			
			followerEmail = LayoutFactory.createTextInput(false, false, width - 14, HorizontalAlign.LEFT, false, true);
			followerEmail.addEventListener(FeathersEventType.ENTER, onTextInputEnter);
			followerEmail.prompt = ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','follower_email_label_prompt');
			followerEmail.pivotX = -3;
			
			graphViewCheck = LayoutFactory.createCheckMark(true);
			
			urgentLowSwitch = LayoutFactory.createToggleSwitch(false);
			urgentLowSwitch.addEventListener(Event.CHANGE, onUrgentLowSwitchChanged);
			if (!isMmol)
				urgentLowValue = LayoutFactory.createNumericStepper(40, 55, 55, 5);
			else
				urgentLowValue = LayoutFactory.createNumericStepper(2.2, 3, 3, 0.2);
			urgentLowSound = createAlarmSoundList("urgent low");
			
			lowSwitch = LayoutFactory.createToggleSwitch(false);
			lowSwitch.addEventListener(Event.CHANGE, onLowSwitchChanged);
			if (!isMmol)
				lowValue = LayoutFactory.createNumericStepper(60, 100, 70, 5);
			else
				lowValue = LayoutFactory.createNumericStepper(3.3, 5.5, 3.8, 0.2);
			lowDelay = createDelay("low");
			lowRepeat = createRepeat("low");
			lowSound = createAlarmSoundList("low");
			
			highSwitch = LayoutFactory.createToggleSwitch(false);
			highSwitch.addEventListener(Event.CHANGE, onHighSwitchChanged);
			if (!isMmol)
				highValue = LayoutFactory.createNumericStepper(120, 400, 200, 10);
			else
				highValue = LayoutFactory.createNumericStepper(6.6, 22.1, 11, 0.5);
			highDelay = createDelay("high");
			highRepeat = createRepeat("high");
			highSound = createAlarmSoundList("high");
			
			missedReadingSwitch = LayoutFactory.createToggleSwitch(false);
			missedReadingSwitch.addEventListener(Event.CHANGE, onMissedReadingsSwitchChanged);
			missedReadingsDelay = createDelay("missed readings");
			missedReadingsSound = createAlarmSoundList("missed readings");
			
			errorLabel = LayoutFactory.createLabel("", HorizontalAlign.CENTER, VerticalAlign.TOP, 14, false, 0xFF0000);
			errorLabel.wordWrap = true;
			errorLabel.width = width - 20;
			
			//Action Buttons
			var actionsContainerLayout:HorizontalLayout = new HorizontalLayout();
			actionsContainerLayout.gap = 5;
			
			actionsContainer = new LayoutGroup();
			actionsContainer.layout = actionsContainerLayout;
			
			cancel = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('globaltranslations','cancel_button_label'), false, MaterialDeepGreyAmberMobileThemeIcons.cancelTexture);
			cancel.addEventListener(Event.TRIGGERED, onCancel);
			actionsContainer.addChild(cancel);
			
			sendInvite = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','invite_follower_button_label'), false, MaterialDeepGreyAmberMobileThemeIcons.personAddTexture);
			sendInvite.addEventListener(Event.TRIGGERED, onSendInvite);
			actionsContainer.addChild(sendInvite);
			
			/*Item Renderer */
			itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "label";
				itemRenderer.accessoryField = "accessory";
				itemRenderer.accessoryLabelProperties.wordWrap = true;
				itemRenderer.defaultLabelProperties.wordWrap = true;
				return itemRenderer;
			};
			
			refreshContent();
		}
		
		private function refreshContent():void
		{
			scrollPosition = verticalScrollPosition;
			
			var listDataProviderItems:Array = [];
			
			if (errorMessage != null && errorLabel != null)
			{
				errorLabel.text = errorMessage;
				errorMessage = null;
				listDataProviderItems.push({ label: "", accessory: errorLabel });
				scrollPosition = 0;
			}
			
			listDataProviderItems.push({ label: "", accessory: userDisplayName });
			listDataProviderItems.push({ label: "", accessory: followerName });
			listDataProviderItems.push({ label: "", accessory: followerEmail });
			listDataProviderItems.push({ label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','allow_graph_view_label'), accessory: graphViewCheck });
			listDataProviderItems.push({ label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','urgent_low_alarm_label'), accessory: urgentLowSwitch });
			if (urgentLowSwitch != null && urgentLowSwitch.isSelected)
			{
				listDataProviderItems.push({ label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','notify_below_label'), accessory: urgentLowValue });
				listDataProviderItems.push({ label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','alert_sound'), accessory: urgentLowSound });
			}
			listDataProviderItems.push({ label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','low_alarm_label'), accessory: lowSwitch });
			if (lowSwitch != null && lowSwitch.isSelected)
			{
				listDataProviderItems.push({ label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','notify_below_label'), accessory: lowValue });
				listDataProviderItems.push({ label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','for_more_than_label'), accessory: lowDelay });
				listDataProviderItems.push({ label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','and_repeat_label'), accessory: lowRepeat });
				listDataProviderItems.push({ label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','alert_sound'), accessory: lowSound });
			}
			listDataProviderItems.push({ label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','high_alarm_label'), accessory: highSwitch });
			if (highSwitch != null && highSwitch.isSelected)
			{
				listDataProviderItems.push({ label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','notify_above_label'), accessory: highValue });
				listDataProviderItems.push({ label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','for_more_than_label'), accessory: highDelay });
				listDataProviderItems.push({ label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','and_repeat_label'), accessory: highRepeat });
				listDataProviderItems.push({ label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','alert_sound'), accessory: highSound });
			}
			listDataProviderItems.push({ label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','missed_readings_alarm_label'), accessory: missedReadingSwitch });
			if (missedReadingSwitch != null && missedReadingSwitch.isSelected)
			{
				listDataProviderItems.push({ label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','for_more_than_label'), accessory: missedReadingsDelay });
				listDataProviderItems.push({ label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','alert_sound'), accessory: missedReadingsSound });
			}
			listDataProviderItems.push({ label: "", accessory: actionsContainer });
			
			dataProvider = new ArrayCollection(listDataProviderItems);
			
			verticalScrollPosition = scrollPosition;
		}
		
		/**
		 * Event Handlers
		 */
		private function onUrgentLowSwitchChanged(e:Event):void
		{
			var alarmSwitch:ToggleSwitch = e.currentTarget as ToggleSwitch;
			isUrgentLowAlarmEnabled = alarmSwitch.isSelected;
			refreshContent();
		}
		
		private function onLowSwitchChanged(e:Event):void
		{
			var alarmSwitch:ToggleSwitch = e.currentTarget as ToggleSwitch;
			isLowAlarmEnabled = alarmSwitch.isSelected;
			refreshContent();
		}
		
		private function onHighSwitchChanged(e:Event):void
		{
			var alarmSwitch:ToggleSwitch = e.currentTarget as ToggleSwitch;
			isHighAlarmEnabled = alarmSwitch.isSelected;
			refreshContent();
		}
		
		private function onMissedReadingsSwitchChanged(e:Event):void
		{
			var alarmSwitch:ToggleSwitch = e.currentTarget as ToggleSwitch;
			isMissedReadingsAlarmEnabled = alarmSwitch.isSelected;
			refreshContent();
		}
		
		private function onSendInvite(e:Event):void
		{
			//Validation
			if (!NetworkInfo.networkInfo.isReachable())
			{
				errorMessage = ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','error_message_no_internet_connection');
				refreshContent();
				return;
			}
			
			if (userDisplayName.text == "")
			{
				errorMessage = ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','error_message_user_display_name_empty');
				refreshContent();
				return;
			}
			
			if (followerName.text == "")
			{
				errorMessage = ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','error_message_follower_name_empty');
				refreshContent();
				return;
			}
			
			var isDuplicate:Boolean = false;
			var loopLength:uint = followersList.length;
			for (var i:int = 0; i < loopLength; i++) 
			{
				var followerContactName:String = String(followersList[i].contactName);
				if (followerContactName == followerName.text)
				{
					isDuplicate = true;
					break;
				}
			}
			
			if (isDuplicate)
			{
				errorMessage = ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','error_message_duplicate_follower_name');
				refreshContent();
				return;
			}
			
			if (followerEmail.text == "")
			{
				errorMessage = ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','error_message_follower_email_empty');
				refreshContent();
				return;
			}
			
			if (!DataValidator.validateEmail(followerEmail.text))
			{
				errorMessage = ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','error_message_follower_email_invalid');
				refreshContent();
				return;
			}
			
			//First we create the contact
			DexcomShareService.instance.addEventListener(DexcomShareEvent.CREATE_CONTACT, onContactCreated);
			DexcomShareService.createContact(followerName.text, followerEmail.text);
		}
		
		private function onContactCreated(e:DexcomShareEvent):void
		{
			Trace.myTrace("DexcomShareFollowerCreator.as", "onContactCreated called!");
			
			DexcomShareService.instance.removeEventListener(DexcomShareEvent.CREATE_CONTACT, onContactCreated);
			
			if (!NetworkInfo.networkInfo.isReachable())
			{
				errorMessage = ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','error_message_no_internet_connection');
				refreshContent();
				return;
			}
			
			var response:String = String(e.data);
			
			Trace.myTrace("DexcomShareFollowerCreator.as", "Response: " + response);
			
			if (e.data != null && response != "" && response.indexOf("Code") == -1)
			{
				var contactID:String = response.split('"').join('');
				
				Trace.myTrace("DexcomShareFollowerCreator.as", "Contact created successfully. ContactID: " + contactID);
				
				//HIGH ALARM
				var highAlarmDelay:String;
				var highAlarmRepeat:String;
				var highAlarmValue:Number;
				var highAlarmSound:String;
				if (highSwitch.isEnabled) 
				{
					highAlarmDelay = String(highDelay.selectedItem.data);
					highAlarmRepeat = String(highRepeat.selectedItem.data);
					if (!isMmol)
						highAlarmValue = highValue.value;
					else
						highAlarmValue = (Math.round(BgReading.mmolToMgdl(highValue.value) / 10)  *  10);
					highAlarmSound = String(highSound.selectedItem.data);
				}
				else 
				{
					highAlarmDelay = "1H";
					highAlarmRepeat = "2H";
					highAlarmValue = 401;
					highAlarmSound = "High.wav";
				}
				
				
				//LOW ALARM
				var lowAlarmDelay:String;
				var lowAlarmRepeat:String;
				var lowAlarmValue:Number;
				var lowAlarmSound:String;
				if (lowSwitch.isEnabled) 
				{
					lowAlarmDelay = String(lowDelay.selectedItem.data);
					lowAlarmRepeat = String(lowRepeat.selectedItem.data);
					if (!isMmol)
						lowAlarmValue = lowValue.value;
					else
						lowAlarmValue = (Math.round(BgReading.mmolToMgdl(lowValue.value) / 5)  *  5);
					lowAlarmSound = String(lowSound.selectedItem.data);
				}
				else 
				{
					lowAlarmDelay = "30M";
					lowAlarmRepeat = "2H";
					lowAlarmValue = 70;
					lowAlarmSound = "Low.wav";
				}
				
				//URGENT LOW ALARM
				var urgentLowAlarmValue:Number;
				var urgentLowAlarmSound:String;
				if (urgentLowSwitch.isEnabled)
				{
					if (!isMmol)
						urgentLowAlarmValue = urgentLowValue.value;
					else
						urgentLowAlarmValue = (Math.round(BgReading.mmolToMgdl(urgentLowValue.value) / 5)  *  5);
					urgentLowAlarmSound = "UrgentLow.wav";
				}
				else 
				{
					urgentLowAlarmValue = 55;
					urgentLowAlarmSound = String(urgentLowSound.selectedItem.data);
				}
				
				//MISSED READINGS
				var missedReadingsFinalDelay:String;
				var missedReadingsFinalSound:String;
				if (missedReadingSwitch.isEnabled)
				{
					missedReadingsFinalDelay = String(missedReadingsDelay.selectedItem.data);
					missedReadingsFinalSound = String(missedReadingsSound.selectedItem.data);
				}
				else 
				{
					missedReadingsFinalDelay = "1H";
					missedReadingsFinalSound = "NoData.wav";
				}
				
				//PARAMETERS
				var highAlert:Object = {
					MinValue: 200,
					AlarmDelay: "PT" + highAlarmDelay,
					AlertType: 1,
					IsEnabled: highSwitch.isSelected,
					RealarmDelay: "PT" + highAlarmRepeat,
					Sound: highAlarmSound,
					MaxValue: highAlarmValue
				};
				
				var lowAlert:Object = {
					MinValue: 39,
					AlarmDelay: "PT" + lowAlarmDelay,
					AlertType: 2,
					IsEnabled: lowSwitch.isSelected,
					RealarmDelay: "PT" + lowAlarmRepeat,
					Sound: lowAlarmSound,
					MaxValue: lowAlarmValue
				};
				
				var fixedLowAlert:Object = {
					MinValue: 39,
					AlarmDelay: "PT0M",
					AlertType: 3,
					IsEnabled: urgentLowSwitch.isSelected,
					RealarmDelay: "PT30M",
					Sound: urgentLowAlarmSound,
					MaxValue: urgentLowAlarmValue
				}
				
				var noDataAlert:Object = {
					MinValue: 39,
					AlarmDelay: "PT" + missedReadingsFinalDelay,
					AlertType: 4,
					IsEnabled: missedReadingSwitch.isSelected,
					RealarmDelay: "PT0M",
					Sound: missedReadingsFinalSound,
					MaxValue: 401
				}
				
				var newFollowerParameters:Object = new Object();
				newFollowerParameters.AlertSettings = new Object();
				newFollowerParameters.AlertSettings.HighAlert = highAlert;
				newFollowerParameters.AlertSettings.LowAlert = lowAlert;
				newFollowerParameters.AlertSettings.FixedLowAlert = fixedLowAlert;
				newFollowerParameters.AlertSettings.NoDataAlert = noDataAlert;
				newFollowerParameters.Permissions = graphViewCheck.isSelected ? 1 : 0;
				newFollowerParameters.DisplayName = userDisplayName.text;
				
				DexcomShareService.instance.addEventListener(DexcomShareEvent.INVITE_FOLLOWER, onFollowerInvited);
				//DexcomShareService.inviteFollower(contactID, JSON.stringify(newFollowerParameters));
				DexcomShareService.inviteFollower(contactID, SpikeJSON.stringify(newFollowerParameters));
			}
			else
			{
				if (e.data == null)
				{
					Trace.myTrace("DexcomShareFollowerCreator.as", "Error connecting to Dexcom servers!");
					errorMessage = ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','error_message_dexcom_server_unavailable');
					refreshContent();
				}
				else
				{
					var responseInfo:Object = parseDexcomResponse(response);
					
					if (responseInfo == null || responseInfo.Code == null || responseInfo.Message == null)
					{
						Trace.myTrace("DexcomShareFollowerCreator.as", "Unknown error while trying to create the follower.");
						errorMessage = ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','error_message_unknown_error_creating_follower');
						refreshContent();
					}
					else
					{
						Trace.myTrace("DexcomShareFollowerCreator.as", "Can't create follower. Error: " + responseInfo.Message)
						errorMessage = ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','error_message_error_creating_follower') + " " + responseInfo.Message;
						refreshContent();
					}
				}
			}
			
		}
		
		private function onFollowerInvited(e:DexcomShareEvent):void
		{
			Trace.myTrace("DexcomShareFollowerCreator.as", "onFollowerInvited called.");
			
			DexcomShareService.instance.removeEventListener(DexcomShareEvent.INVITE_FOLLOWER, onFollowerInvited);
			
			var response:String = String(e.data);
			
			Trace.myTrace("DexcomShareFollowerCreator.as", "Response: " + response);
			
			if (e.data != null && response != "" && response.indexOf("Code") == -1)
			{
				Trace.myTrace("DexcomShareFollowerCreator.as", "Invite sent successfully!");
				dispatchEventWith(Event.COMPLETE, false, { success: true } );
			}
			else
			{
				if (e.data == null)
				{
					Trace.myTrace("DexcomShareFollowerCreator.as", "Error connecting to Dexcom servers!");
					errorMessage = ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','error_message_dexcom_server_unavailable');
					refreshContent();
				}
				else
				{
					var responseInfo:Object = parseDexcomResponse(response);
					
					if (responseInfo == null || responseInfo.Code == null || responseInfo.Message == null)
					{
						Trace.myTrace("DexcomShareFollowerCreator.as", "Unknown error while sending invite.");
						errorMessage = ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','error_message_unknown_error_sending_invite');
						refreshContent();
					}
					else
					{
						Trace.myTrace("DexcomShareFollowerCreator.as", "Can't send invite. Error: " + responseInfo.Message);
						errorMessage = ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','error_message_error_sending_invite') + " " + responseInfo.Message;
						refreshContent();
					}
				}
			}
		}
		
		private function onTextInputEnter(e:Event):void
		{
			userDisplayName.clearFocus();
			followerName.clearFocus();
			followerEmail.clearFocus();
		}
		
		private function onCancel(e:Event):void
		{
			dispatchEventWith(Event.COMPLETE);
		}
		
		/**
		 * Helpers
		 */
		private function createDelay(alarm:String):PickerList
		{	
			var delayPopUp:DropDownPopUpContentManager = new DropDownPopUpContentManager();
			delayPopUp.primaryDirection = RelativePosition.TOP;
			var delay:PickerList = LayoutFactory.createPickerList();
			delay.popUpContentManager = delayPopUp;
			
			var delayProvider:ArrayCollection = new ArrayCollection();
			
			if (alarm != "missed readings")
			{
				delayProvider.push( { label: "0" + ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','minutes'), data: "0M" } );
				delayProvider.push( { label: "15" + ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','minutes'), data: "15M" } );
			}
			delayProvider.push( { label: "30" + ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','minutes'), data: "30M" } );
			delayProvider.push( { label: "45" + ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','minutes'), data: "45M" } );
			delayProvider.push( { label: "1" + ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','hours'), data: "1H" } );
			delayProvider.push( { label: "1" + ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','hours') + "30" + ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','minutes'), data: "1H30M" } );
			delayProvider.push( { label: "2" + ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','hours'), data: "2H" } );
			if (alarm == "high" || alarm == "missed readings")
			{
				delayProvider.push( { label: "3" + ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','hours'), data: "3H" } );
				delayProvider.push( { label: "4" + ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','hours'), data: "4H" } );
				delayProvider.push( { label: "5" + ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','hours'), data: "5H" } );
				delayProvider.push( { label: "6" + ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','hours'), data: "6H" } );
			}
			
			delay.dataProvider = delayProvider;
			if (alarm == "high" || alarm == "missed readings")
				delay.selectedIndex = 4;
			else
				delay.selectedIndex = 2;
			
			delay.itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "label";
				itemRenderer.accessoryField = "accessory";
				
				return itemRenderer;
			};
			
			if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr)
				delay.maxWidth = 100;
			
			return delay;
		}
		
		private function createRepeat(alarm:String):PickerList
		{	
			var repeatPopUp:DropDownPopUpContentManager = new DropDownPopUpContentManager();
			repeatPopUp.primaryDirection = RelativePosition.TOP;
			var repeat:PickerList = LayoutFactory.createPickerList();
			repeat.popUpContentManager = repeatPopUp;
			
			var repeatProvider:ArrayCollection = new ArrayCollection();
			
			repeatProvider.push( { label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','never'), data: "0M" } );
			repeatProvider.push( { label: "30" + ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','minutes'), data: "30M" } );
			repeatProvider.push( { label: "45" + ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','minutes'), data: "45M" } );
			repeatProvider.push( { label: "1" + ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','hours'), data: "1H" } );
			repeatProvider.push( { label: "1" + ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','hours') + "30" + ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','minutes'), data: "1H30M" } );
			repeatProvider.push( { label: "2" + ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','hours'), data: "2H" } );
			if (alarm == "high")
			{
				repeatProvider.push( { label: "3" + ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','hours'), data: "3H" } );
				repeatProvider.push( { label: "4" + ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','hours'), data: "4H" } );
				repeatProvider.push( { label: "5" + ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','hours'), data: "5H" } );
				repeatProvider.push( { label: "6" + ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','hours'), data: "6H" } );
			}
			
			repeat.dataProvider = repeatProvider;
			
			repeat.selectedIndex = 5;
			
			repeat.itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "label";
				itemRenderer.accessoryField = "accessory";
				
				return itemRenderer;
			};
			
			if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr)
				repeat.maxWidth = 130;
			
			return repeat;
		}
		
		private function createAlarmSoundList(alarm:String):PickerList
		{
			var alarmSoundsPopUp:VerticalCenteredPopUpContentManager  = new VerticalCenteredPopUpContentManager ();
			alarmSoundsPopUp.margin = 20;
			var alarmSounds:PickerList = LayoutFactory.createPickerList();
			alarmSounds.popUpContentManager = alarmSoundsPopUp;
			
			var alarmSoundsProvider:ArrayCollection = new ArrayCollection();
			
			alarmSoundsProvider.push( { label: "Alarm Clock Long", data: "AlarmClockLong.caf" } );
			alarmSoundsProvider.push( { label: "Alarm Clock Short", data: "AlarmClockShort.caf" } );
			alarmSoundsProvider.push( { label: "Baby Cry", data: "BabyCry.caf" } );
			alarmSoundsProvider.push( { label: "Beep", data: "Beep.wav" } );
			alarmSoundsProvider.push( { label: "Dinging", data: "Dinging.caf" } );
			alarmSoundsProvider.push( { label: "Dings", data: "Dings.caf" } );
			alarmSoundsProvider.push( { label: "Disconnected", data: "Disconnected.caf" } );
			alarmSoundsProvider.push( { label: "Door Bell", data: "DoorBell.caf" } );
			alarmSoundsProvider.push( { label: "Fire Alarm", data: "FireAlarm.caf" } );
			if (alarm == "high")
			{
				alarmSoundsProvider.push( { label: "High", data: "High.wav" } );
				alarmSoundsProvider.push( { label: "High Attentive", data: "HighAtt.wav" } );
			}
			if (alarm == "missed readings")
			{
				alarmSoundsProvider.push( { label: "Long No Data Attentive", data: "LongNoDataAtt.wav" } );
				alarmSoundsProvider.push( { label: "No Data", data: "NoData.wav" } );
				alarmSoundsProvider.push( { label: "No Data Attentive", data: "NoDataAtt.wav" } );
			}
			if (alarm == "low")
			{
				alarmSoundsProvider.push( { label: "Low", data: "Low.wav" } );
				alarmSoundsProvider.push( { label: "Low Attentive", data: "LowAtt.wav" } );
			}
			alarmSoundsProvider.push( { label: "Quiet Beeps", data: "QuietBeeps.caf" } );
			alarmSoundsProvider.push( { label: "Short Alarm", data: "ShortAlarm.caf" } );
			alarmSoundsProvider.push( { label: "Short Beeps 1", data: "ShortBeeps1.caf" } );
			alarmSoundsProvider.push( { label: "Short Beeps 2", data: "ShortBeeps2.caf" } );
			alarmSoundsProvider.push( { label: "Siren 1", data: "Siren1.caf" } );
			alarmSoundsProvider.push( { label: "Siren 2", data: "Siren2.caf" } );
			alarmSoundsProvider.push( { label: "Truck Siren", data: "TruckSiren.caf" } );
			alarmSoundsProvider.push( { label: "Tune", data: "Tune.caf" } );
			if (alarm == "urgent low")
			{
				alarmSoundsProvider.push( { label: "Urgent Low", data: "UrgentLow.wav" } );
				alarmSoundsProvider.push( { label: "Urgent Low Attentive", data: "UrgentLowAtt.wav" } );
			}
			
			alarmSounds.dataProvider = alarmSoundsProvider;
			
			if (alarm == "high")
				alarmSounds.selectedIndex = 9;
			else if (alarm == "low")
				alarmSounds.selectedIndex = 9;
			else if (alarm == "missed readings")
				alarmSounds.selectedIndex = 10;
			else if (alarm == "urgent low")
				alarmSounds.selectedIndex = 17;
			
			alarmSounds.itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "label";
				itemRenderer.accessoryField = "accessory";
				
				return itemRenderer;
			};
			
			if (Constants.deviceModel == DeviceInfo.IPHONE_2G_3G_3GS_4_4S_ITOUCH_2_3_4 || Constants.deviceModel == DeviceInfo.IPHONE_5_5S_5C_SE_ITOUCH_5_6)
				alarmSounds.maxWidth = 165;
			else if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr)
				alarmSounds.maxWidth = 155;
			
			return alarmSounds;
		}
		
		private function parseDexcomResponse(response:String):Object
		{
			var responseInfo:Object;
			
			try
			{
				//responseInfo = JSON.parse(response);
				responseInfo = SpikeJSON.parse(response);
			} 
			catch(error:Error) 
			{
				Trace.myTrace("DexcomShareFollowerCreator.as", "Can't parse server response! Error: " + error.message);
			}
			
			return responseInfo;
		}
		
		/**
		 * Utility
		 */
		
		override public function dispose():void
		{
			if (userDisplayName != null)
			{
				userDisplayName.addEventListener(FeathersEventType.ENTER, onTextInputEnter);
				userDisplayName.dispose();
				userDisplayName = null;
			}
			
			if (followerName != null)
			{
				followerName.addEventListener(FeathersEventType.ENTER, onTextInputEnter);
				followerName.dispose();
				followerName = null;
			}
			
			if (followerEmail != null)
			{
				followerEmail.addEventListener(FeathersEventType.ENTER, onTextInputEnter);
				followerEmail.dispose();
				followerEmail = null;
			}
			
			if (graphViewCheck != null)
			{
				graphViewCheck.dispose();
				graphViewCheck = null;
			}
			
			if (cancel != null)
			{
				actionsContainer.removeChild(cancel);
				cancel.addEventListener(Event.TRIGGERED, onCancel);
				cancel.dispose();
				cancel = null;
			}
			
			if (sendInvite != null)
			{
				actionsContainer.removeChild(sendInvite);
				sendInvite.addEventListener(Event.TRIGGERED, onSendInvite);
				sendInvite.dispose();
				sendInvite = null;
			}
			
			if (actionsContainer != null)
			{
				actionsContainer.dispose();
				actionsContainer = null;
			}
			
			if (urgentLowSwitch != null)
			{
				urgentLowSwitch.addEventListener(Event.CHANGE, onUrgentLowSwitchChanged);
				urgentLowSwitch.dispose();
				urgentLowSwitch = null;
			}
			
			if (lowSwitch != null)
			{
				lowSwitch.addEventListener(Event.CHANGE, onLowSwitchChanged);
				lowSwitch.dispose();
				lowSwitch = null;
			}
			
			if (highSwitch != null)
			{
				highSwitch.addEventListener(Event.CHANGE, onHighSwitchChanged);
				highSwitch.dispose();
				highSwitch = null;
			}
			
			if (missedReadingSwitch != null)
			{
				missedReadingSwitch.addEventListener(Event.CHANGE, onMissedReadingsSwitchChanged);
				missedReadingSwitch.dispose();
				missedReadingSwitch = null;
			}
			
			if (urgentLowValue != null)
			{
				urgentLowValue.dispose();
				urgentLowValue = null;
			}
			
			if (lowValue != null)
			{
				lowValue.dispose();
				lowValue = null;
			}
			
			if (highValue != null)
			{
				highValue.dispose();
				highValue = null;
			}
			
			if (lowDelay != null)
			{
				lowDelay.dispose();
				lowDelay = null;
			}
			
			if (highDelay != null)
			{
				highDelay.dispose();
				highDelay = null;
			}
			
			if (missedReadingsDelay != null)
			{
				missedReadingsDelay.dispose();
				missedReadingsDelay = null;
			}
			
			if (errorLabel != null)
			{
				errorLabel.dispose();
				errorLabel = null;
			}
			
			if (urgentLowSound != null)
			{
				urgentLowSound.dispose();
				urgentLowSound = null;
			}
			
			if (lowSound != null)
			{
				lowSound.dispose();
				lowSound = null;
			}
			
			if (highSound != null)
			{
				highSound.dispose();
				highSound = null;
			}
			
			if (missedReadingsSound != null)
			{
				missedReadingsSound.dispose();
				missedReadingsSound = null;
			}
			
			if (lowRepeat != null)
			{
				lowRepeat.dispose();
				lowRepeat = null;
			}
			
			if (highRepeat != null)
			{
				highRepeat.dispose();
				highRepeat = null;
			}
			
			super.dispose();
		}
	}
}