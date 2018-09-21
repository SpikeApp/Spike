package ui.screens.display.dexcomshare
{
	import com.distriqt.extension.networkinfo.NetworkInfo;
	
	import flash.system.Capabilities;
	
	import spark.formatters.DateTimeFormatter;
	
	import database.BgReading;
	import database.CommonSettings;
	
	import events.DexcomShareEvent;
	
	import feathers.controls.Button;
	import feathers.controls.Label;
	import feathers.controls.LayoutGroup;
	import feathers.controls.List;
	import feathers.controls.TextInput;
	import feathers.controls.ToggleSwitch;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.data.ArrayCollection;
	import feathers.events.FeathersEventType;
	import feathers.extensions.MaterialDesignSpinner;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.HorizontalLayout;
	import feathers.layout.VerticalAlign;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.ModelLocator;
	
	import services.DexcomShareService;
	
	import starling.core.Starling;
	import starling.events.Event;
	
	import ui.screens.display.LayoutFactory;
	
	import utils.Constants;
	import utils.DeviceInfo;
	import utils.SpikeJSON;
	import utils.Trace;
	
	[ResourceBundle("sharesettingsscreen")]
	[ResourceBundle("globaltranslations")]
	
	public class DexcomShareFollowerEditor extends List
	{
		/* Constants */
		private const MAX_CONNECTION_RETRIES:uint = 3;
		
		/* Logical Variables */
		private var isSaveEnabled:Boolean = false;
		
		/* Data Variables */
		private var initialFollowerState:Number;
		private var initialFollowerSharingActive:Boolean;
		private var initialAllowGraphView:Boolean;
		private var initialContactID:String;
		private var initialSubscriptionID:String;
		private var initialFollowerName:String;
		private var changeFollowerNameRetries:int = 0;
		private var changeFollowerPermissionsRetries:int = 0;
		private var enableFollowerSharingRetries:int = 0;
		private var disableFollowerSharingRetries:int = 0;
		private var getFollowerInfoExtendedRetries:int = 0;
		private var getFollowerAlarmsRetries:int = 0;
		private var errorMessage:String;
		private var isMmol:Boolean = false;
		
		/* Objects */
		private var dateFormatterForInvite:DateTimeFormatter;
		private var queueList:Array = [];
		private var followerInfo:Object;
		private var followerInfoExtended:Object;
		private var followerAlarms:Object;

		/* Display Objects */
		private var actionsContainer:LayoutGroup;
		private var cancelButton:Button;
		private var saveButton:Button;
		private var followerName:TextInput;
		private var userDisplayName:Label;
		private var followerEmail:Label;
		private var invitationDate:Label;
		private var allowGraphView:ToggleSwitch;
		private var followerSharingActiveSwitch:ToggleSwitch;
		private var lowAlarmSwitch:ToggleSwitch;
		private var urgentLowAlarmSwitch:ToggleSwitch;
		private var highAlarmSwitch:ToggleSwitch;
		private var missedReadingsAlarmSwitch:ToggleSwitch;
		private var urgentLowValue:Label;
		private var lowAlarmValue:Label;
		private var highAlarmValue:Label;
		private var lowAlarmDelay:Label;
		private var highAlarmDelay:Label;
		private var missedReadingsAlarmDelay:Label;
		private var statusLabel:Label;
		private var preloader:MaterialDesignSpinner;
		private var missedReadingsSound:Label;
		private var highSound:Label;
		private var lowSound:Label;
		private var urgentLowSound:Label;
		private var lowAlarmRepeat:Label;
		private var highAlarmRepeat:Label;
		private var errorMesageLabel:Label;
		private var managedByFollowerLabel:Label;
		
		public function DexcomShareFollowerEditor(follower:Object)
		{
			super();
			
			followerInfo = follower;
		}
		
		override protected function initialize():void 
		{
			super.initialize();
			
			setupProperties();
			setupPreloader();
			Starling.juggler.delayCall(setupInitialContent, 1.5);
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
			
			/* Date Formatter */
			dateFormatterForInvite = new DateTimeFormatter();
			dateFormatterForInvite.dateTimePattern = "dd MMM";
			dateFormatterForInvite.useUTC = false;
			dateFormatterForInvite.setStyle("locale", Constants.getUserLocale());
			
			/* Glucose Unit */
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) != "true")
				isMmol = true;
		}
		
		private function setupPreloader():void
		{
			preloader = new MaterialDesignSpinner();
			preloader.color = 0x0086FF;
			preloader.validate();
			preloader.x = (width - preloader.width) / 2;
			preloader.y = (height - preloader.height) / 2;
			addChild(preloader);
		}
		
		private function setupInitialContent():void
		{
			/* Get initial relevant follower properties */
			initialFollowerName = followerInfo.ContactName;
			initialFollowerSharingActive = followerInfo.IsEnabled;
			initialAllowGraphView = followerInfo.Permissions == 1 ? true : false;
			initialContactID = followerInfo.ContactId;
			initialSubscriptionID = followerInfo.SubscriptionId;
			initialFollowerState = followerInfo.State;
			
			/* Get extended follower info (e-mail address) */
			getExtendedFollowerInfo();
		}
		
		private function setupContent():void
		{
			/* Accessories */
			errorMesageLabel = LayoutFactory.createLabel(errorMessage, HorizontalAlign.CENTER, VerticalAlign.TOP, 14, false, 0xFF0000);
			errorMesageLabel.wordWrap;
			errorMesageLabel.width = width - 20;
			
			userDisplayName = LayoutFactory.createLabel(followerInfo.DisplayName, HorizontalAlign.RIGHT);
			
			followerName = LayoutFactory.createTextInput(false, false, 120, HorizontalAlign.RIGHT);
			followerName.text = initialFollowerName;
			followerName.addEventListener(Event.CHANGE, onSettingsChanged);
			followerName.addEventListener(FeathersEventType.ENTER, onTextInputEnter);
			
			followerEmail = LayoutFactory.createLabel(followerInfoExtended.Email, HorizontalAlign.RIGHT, VerticalAlign.TOP, 9);
			if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr)
				followerEmail.width = 150;
			else
				followerEmail.width = 160;
			
			var inviteDate:Date = convertDexcomDateToRegularDate(followerInfo.DateTimeCreated.DateTime);
			invitationDate = LayoutFactory.createLabel(dateFormatterForInvite.format(inviteDate) + " " + inviteDate.fullYear, HorizontalAlign.RIGHT);
			
			var statusValue:String;
			if (initialFollowerState == 2) statusValue = ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','status_invited');
			else if (initialFollowerState == 6) statusValue = ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','status_active');
			else if (initialFollowerState == 7) statusValue = ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','status_paused');
			else if (initialFollowerState == 10) statusValue = ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','status_removed');
			else statusValue = ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','status_unknown');
			
			statusLabel = LayoutFactory.createLabel(statusValue, HorizontalAlign.RIGHT);
			
			followerSharingActiveSwitch = LayoutFactory.createToggleSwitch(initialFollowerSharingActive);
			followerSharingActiveSwitch.addEventListener(Event.CHANGE, onSettingsChanged);
			
			allowGraphView = LayoutFactory.createToggleSwitch(initialAllowGraphView);
			allowGraphView.addEventListener(Event.CHANGE, onSettingsChanged);
			
			managedByFollowerLabel = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','managed_by_follower_label'), HorizontalAlign.CENTER);
			managedByFollowerLabel.width = width - 20;
			
			urgentLowAlarmSwitch = LayoutFactory.createToggleSwitch(Boolean(followerAlarms.FixedLowAlert.IsEnabled));
			if (!isMmol)
				urgentLowValue = LayoutFactory.createLabel(followerAlarms.FixedLowAlert.MaxValue, HorizontalAlign.RIGHT);
			else
			{
				var urgentLowConvertedValue:Number = Math.round(((BgReading.mgdlToMmol((Number(followerAlarms.FixedLowAlert.MaxValue)))) * 10)) / 10;
				urgentLowValue = LayoutFactory.createLabel(String(urgentLowConvertedValue), HorizontalAlign.RIGHT);
			}
			urgentLowSound = LayoutFactory.createLabel(convertDexcomAlarmToString(followerAlarms.FixedLowAlert.Sound), HorizontalAlign.RIGHT);
			
			lowAlarmSwitch = LayoutFactory.createToggleSwitch(Boolean(followerAlarms.LowAlert.IsEnabled));
			if (!isMmol)
				lowAlarmValue = LayoutFactory.createLabel(followerAlarms.LowAlert.MaxValue, HorizontalAlign.RIGHT);
			else
			{
				var lowConvertedValue:Number = Math.round(((BgReading.mgdlToMmol((Number(followerAlarms.LowAlert.MaxValue)))) * 10)) / 10;
				lowAlarmValue = LayoutFactory.createLabel(String(lowConvertedValue), HorizontalAlign.RIGHT);
			}
			lowAlarmDelay = LayoutFactory.createLabel(convertDexcomDelayToString(followerAlarms.LowAlert.AlarmDelay), HorizontalAlign.RIGHT);
			lowAlarmRepeat = LayoutFactory.createLabel(convertDexcomDelayToString(followerAlarms.LowAlert.RealarmDelay), HorizontalAlign.RIGHT);
			lowSound = LayoutFactory.createLabel(convertDexcomAlarmToString(followerAlarms.LowAlert.Sound), HorizontalAlign.RIGHT);
			
			highAlarmSwitch = LayoutFactory.createToggleSwitch(Boolean(followerAlarms.HighAlert.IsEnabled));
			if (!isMmol)
				highAlarmValue = LayoutFactory.createLabel(followerAlarms.HighAlert.MaxValue, HorizontalAlign.RIGHT);
			else
			{
				var highConvertedValue:Number = Math.round(((BgReading.mgdlToMmol((Number(followerAlarms.HighAlert.MaxValue)))) * 10)) / 10;
				highAlarmValue = LayoutFactory.createLabel(String(highConvertedValue), HorizontalAlign.RIGHT);
			}
			highAlarmDelay = LayoutFactory.createLabel(convertDexcomDelayToString(followerAlarms.HighAlert.AlarmDelay), HorizontalAlign.RIGHT);
			highAlarmRepeat = LayoutFactory.createLabel(convertDexcomDelayToString(followerAlarms.HighAlert.RealarmDelay), HorizontalAlign.RIGHT);
			highSound = LayoutFactory.createLabel(convertDexcomAlarmToString(followerAlarms.HighAlert.Sound), HorizontalAlign.RIGHT);
			
			missedReadingsAlarmSwitch = LayoutFactory.createToggleSwitch(Boolean(followerAlarms.NoDataAlert.IsEnabled));
			missedReadingsAlarmDelay = LayoutFactory.createLabel(convertDexcomDelayToString(followerAlarms.NoDataAlert.AlarmDelay), HorizontalAlign.RIGHT);
			missedReadingsSound = LayoutFactory.createLabel(convertDexcomAlarmToString(followerAlarms.NoDataAlert.Sound), HorizontalAlign.RIGHT);
			
			/* Action Buttons */
			var actionsContainerLayout:HorizontalLayout = new HorizontalLayout();
			actionsContainerLayout.gap = 5;
			
			actionsContainer = new LayoutGroup();
			actionsContainer.layout = actionsContainerLayout;
			
			cancelButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('globaltranslations','cancel_button_label'), false, MaterialDeepGreyAmberMobileThemeIcons.cancelTexture);
			cancelButton.addEventListener(Event.TRIGGERED, onCancel);
			actionsContainer.addChild(cancelButton);
			
			saveButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('globaltranslations','save_button_label'), false, MaterialDeepGreyAmberMobileThemeIcons.saveTexture);
			saveButton.isEnabled = isSaveEnabled;
			saveButton.addEventListener(Event.TRIGGERED, onSave);
			actionsContainer.addChild(saveButton);
			
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
			
			//Remove preloader
			disposePreloader();
			
			//Show content
			refreshContent();
		}
		
		private function refreshContent():void
		{
			/* List Data */
			var listDataProviderItems:Array = [];
			
			if (errorMessage != null)
			{
				errorMesageLabel.text = errorMessage;
				listDataProviderItems.push({ label: "", accessory: errorMesageLabel });
				errorMessage = null;
			}
			listDataProviderItems.push({ label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','display_name'), accessory: userDisplayName });
			listDataProviderItems.push({ label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','name'), accessory: followerName });
			listDataProviderItems.push({ label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','email'), accessory: followerEmail });
			listDataProviderItems.push({ label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','invitation_date'), accessory: invitationDate });
			listDataProviderItems.push({ label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','status'), accessory: statusLabel });
			listDataProviderItems.push({ label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','sharing_enabled'), accessory: followerSharingActiveSwitch });
			listDataProviderItems.push({ label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','graph_view'), accessory: allowGraphView });
			listDataProviderItems.push({ label: "", accessory: managedByFollowerLabel });
			listDataProviderItems.push({ label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','urgent_low_alarm_label'), accessory: urgentLowAlarmSwitch });
			if (urgentLowAlarmSwitch.isSelected)
			{
				listDataProviderItems.push({ label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','notify_below_label'), accessory: urgentLowValue });
				listDataProviderItems.push({ label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','sound'), accessory: urgentLowSound });
			}
			listDataProviderItems.push({ label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','low_alarm_label'), accessory: lowAlarmSwitch });
			if (lowAlarmSwitch.isSelected)
			{
				listDataProviderItems.push({ label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','notify_below_label'), accessory: lowAlarmValue });
				listDataProviderItems.push({ label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','for_more_than_label'), accessory: lowAlarmDelay });
				listDataProviderItems.push({ label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','and_repeat_label'), accessory: lowAlarmRepeat });
				listDataProviderItems.push({ label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','sound'), accessory: lowSound });
			}
			listDataProviderItems.push({ label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','high_alarm_label'), accessory: highAlarmSwitch });
			if (highAlarmSwitch.isSelected)
			{
				listDataProviderItems.push({ label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','notify_above_label'), accessory: highAlarmValue });
				listDataProviderItems.push({ label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','for_more_than_label'), accessory: highAlarmDelay });
				listDataProviderItems.push({ label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','and_repeat_label'), accessory: highAlarmRepeat });
				listDataProviderItems.push({ label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','sound'), accessory: highSound });
			}
			listDataProviderItems.push({ label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','missed_readings_alarm_label'), accessory: missedReadingsAlarmSwitch });
			if (missedReadingsAlarmSwitch.isSelected)
			{
				listDataProviderItems.push({ label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','for_more_than_label'), accessory: missedReadingsAlarmDelay });
				listDataProviderItems.push({ label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','sound'), accessory: missedReadingsSound });
			}
			listDataProviderItems.push({ label: "", accessory: actionsContainer });
			
			dataProvider = new ArrayCollection(listDataProviderItems);
		}
		
		private function processQueue(completedProcess:Function = null):void
		{
			//Remove completed process from the queue
			if (completedProcess != null)
			{
				for (var i:int = 0; i < queueList.length; i++) 
				{
					if (completedProcess == queueList[i])
					{
						queueList.removeAt(i);
						break;
					}
				}
			}
			
			if (queueList.length > 0)
			{
				//Call corresponding action
				var action:Function = queueList[0];
				action.call();
			}
			else
			{
				Trace.myTrace("DexcomShareFollowerEditor.as", "Queue finished successfully. Closing popup.");
				dispatchEventWith(Event.COMPLETE, false, { success: true });
			}
		}
		
		private function getExtendedFollowerInfo():void
		{
			Trace.myTrace("DexcomShareFollowerEditor.as", "getExtendedFollowerInfo called!");
			
			//Connect to Dexcom servers
			DexcomShareService.instance.addEventListener(DexcomShareEvent.GET_FOLLOWER_INFO, onGetFollowerInfoResponse);
			DexcomShareService.getFollowerInfo(initialContactID);
		}
		
		private function getFollowerAlarms():void
		{
			Trace.myTrace("DexcomShareFollowerEditor.as", "getFollowerAlarms called!");
			
			//Connect to Dexcom servers
			DexcomShareService.instance.addEventListener(DexcomShareEvent.GET_FOLLOWER_ALARMS, onGetFollowerAlarmsResponse);
			DexcomShareService.getFollowerAlarms(initialSubscriptionID);
		}
		
		private function changeFollowerName():void
		{
			Trace.myTrace("DexcomShareFollowerEditor.as", "changeFollowerName called!");
			
			//Connect to Dexcom servers
			DexcomShareService.instance.addEventListener(DexcomShareEvent.CHANGE_FOLLOWER_NAME, onChangeFollowerNameResponse);
			DexcomShareService.changeFollowerName(initialContactID, followerName.text);
		}
		
		private function enableFollowerSharing():void
		{
			Trace.myTrace("DexcomShareFollowerEditor.as", "enableFollowerSharing called!");
			
			//Connect to Dexcom servers
			DexcomShareService.instance.addEventListener(DexcomShareEvent.ENABLE_FOLLOWER_SHARING, onEnableFollowerSharingResponse);
			DexcomShareService.enableFollowerSharing(initialSubscriptionID);
		}
		
		private function disableFollowerSharing():void
		{
			Trace.myTrace("DexcomShareFollowerEditor.as", "disableFollowerSharing called!");
			
			//Connect to Dexcom servers
			DexcomShareService.instance.addEventListener(DexcomShareEvent.DISABLE_FOLLOWER_SHARING, onDisableFollowerSharingResponse);
			DexcomShareService.disableFollowerSharing(initialSubscriptionID);
		}
		
		private function changeFollowerPermissions():void
		{
			Trace.myTrace("DexcomShareFollowerEditor.as", "changeFollowerPermissions called!");
			
			//Get permissions
			var permissions:int;
			if (allowGraphView.isSelected) permissions = 1;
			else permissions = 0;
			
			//Connect to Dexcom servers
			DexcomShareService.instance.addEventListener(DexcomShareEvent.CHANGE_FOLLOWER_PERMISSIONS, onChangFollowerPermissionsResponse);
			DexcomShareService.changeFollowerPermissions(initialSubscriptionID, permissions);
		}
		
		/**
		 * Event Listeners
		 */
		private function onGetFollowerInfoResponse(e:DexcomShareEvent):void
		{
			Trace.myTrace("DexcomShareFollowerEditor.as", "onGetFollowerInfoResponse called!");
			
			DexcomShareService.instance.removeEventListener(DexcomShareEvent.GET_FOLLOWER_INFO, onGetFollowerInfoResponse);
			
			var response:String = String(e.data);
			
			if (response != null) 
				followerInfoExtended = parseDexcomResponse(response);
			
			if (response != null && response.indexOf("ContactId") != -1)
			{
				Trace.myTrace("DexcomShareFollowerEditor.as", "Extended follower info retrieved successfully! Requesting follower's alarms...");
				
				//Connect to Dexcom servers to get follower's alarms
				getFollowerAlarms();
			}
			else
			{
				if (getFollowerInfoExtendedRetries < MAX_CONNECTION_RETRIES)
				{
					Trace.myTrace("DexcomShareFollowerEditor.as", "Error requesting extended follower info! Retrying...");
					getFollowerInfoExtendedRetries++;
					getExtendedFollowerInfo();
				}
				else if (response == null)
				{
					Trace.myTrace("DexcomShareFollowerEditor.as", "Error connecting to Dexcom servers!");
					errorMessage = ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','error_message_dexcom_server_unavailable');
					setupContent();
				}
				else
				{
					if (followerInfoExtended == null || followerInfoExtended.Code == null || followerInfoExtended.Message == null)
					{
						Trace.myTrace("DexcomShareFollowerEditor.as", "Unknown error while trying to retrieve the follower's extended info. Aborting...");
						errorMessage = ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','error_message_unknown_error_getting_follower_info');
					}
					else
					{
						Trace.myTrace("DexcomShareFollowerEditor.as", "Error while trying to retrieve the follower's extended info, aborting. Error: " + followerInfoExtended.Message);
						errorMessage = ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','error_message_error_getting_follower_info') + " " + followerInfoExtended.Message;
					}
					
					setupContent();
				}
			}
		}
		
		private function onGetFollowerAlarmsResponse(e:DexcomShareEvent):void
		{
			Trace.myTrace("DexcomShareFollowerEditor.as", "onGetFollowerAlarmsResponse called!");
			
			DexcomShareService.instance.removeEventListener(DexcomShareEvent.GET_FOLLOWER_ALARMS, onGetFollowerAlarmsResponse);
			
			var response:String = String(e.data);
			if (response != null)
				followerAlarms = parseDexcomResponse(response);
			
			if (response != null && response.indexOf("Alert") != -1)
			{
				Trace.myTrace("DexcomShareFollowerEditor.as", "Follower alarms retrieved successfully! Drawing content...");
				
				setupContent();
			}
			else
			{
				if (getFollowerAlarmsRetries < MAX_CONNECTION_RETRIES)
				{
					Trace.myTrace("DexcomShareFollowerEditor.as", "Error requesting follower alarms! Retrying...");
					getFollowerAlarmsRetries++;
					getFollowerAlarms();
				}
				else if (response == null)
				{
					Trace.myTrace("DexcomShareFollowerEditor.as", "Error connecting to Dexcom servers!");
					errorMessage = ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','error_message_dexcom_server_unavailable');
					setupContent();
				}
				else
				{
					if (followerAlarms == null || followerAlarms.Code == null || followerAlarms.Message == null)
					{
						Trace.myTrace("DexcomShareFollowerEditor.as", "Unknown error while trying to retrieve the follower's alarms. Aborting...");
						errorMessage = ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','error_message_unknown_error_getting_follower_alarms');
					}
					else
					{
						Trace.myTrace("DexcomShareFollowerEditor.as", "Error while trying to retrieve the follower's alarms, aborting. Error: " + followerAlarms.Message);
						errorMessage = ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','error_message_error_getting_follower_alarms') + " " + followerAlarms.Message;
					}
					
					setupContent();
				}
			}
		}
		
		private function onChangeFollowerNameResponse(e:DexcomShareEvent):void
		{
			Trace.myTrace("DexcomShareFollowerEditor.as", "onChangeFollowerNameResponse called!");
			
			DexcomShareService.instance.removeEventListener(DexcomShareEvent.CHANGE_FOLLOWER_NAME, onChangeFollowerNameResponse);
			
			var response:String = String(e.data);
			
			if (response != null && response == "")
			{
				Trace.myTrace("DexcomShareFollowerEditor.as", "Follower's name changed successfully!");
				
				processQueue(changeFollowerName);
			}
			else
			{
				var responseInfo:Object = parseDexcomResponse(response);
				
				if (changeFollowerNameRetries < MAX_CONNECTION_RETRIES)
				{
					Trace.myTrace("DexcomShareFollowerEditor.as", "Error changing follower+s name! Retrying...");
					changeFollowerNameRetries++;
					changeFollowerName();
				}
				else if (response == null)
				{
					Trace.myTrace("DexcomShareFollowerEditor.as", "Error connecting to Dexcom servers!");
					errorMessage = ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','error_message_dexcom_server_unavailable');
					saveButton.isEnabled = true;
					refreshContent();
				}
				else
				{
					if (responseInfo == null || responseInfo.Code == null || responseInfo.Message == null)
					{
						Trace.myTrace("DexcomShareFollowerEditor.as", "Unknown error while trying to change follower's name. Aborting...");
						errorMessage = ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','error_message_unknown_error_changing_follower_name');
					}
					else
					{
						Trace.myTrace("DexcomShareFollowerEditor.as", "Error while trying to change follower's name. Aborting. Error: " + responseInfo.Message);
						errorMessage = ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','error_message_error_changing_follower_name') + " " + responseInfo.Message;
					}
					
					saveButton.isEnabled = true;
					refreshContent();
				}
			}	
		}
		
		private function onEnableFollowerSharingResponse(e:DexcomShareEvent):void
		{
			Trace.myTrace("DexcomShareFollowerEditor.as", "onEnableFollowerSharingResponse called!");
			
			DexcomShareService.instance.removeEventListener(DexcomShareEvent.ENABLE_FOLLOWER_SHARING, onEnableFollowerSharingResponse);
			
			var response:String = String(e.data);
			
			if (response != null && response == "")
			{
				Trace.myTrace("DexcomShareFollowerEditor.as", "Enabled follower sharing successfully!");
				
				processQueue(enableFollowerSharing);
			}
			else
			{
				var responseInfo:Object = parseDexcomResponse(response);
				
				if (enableFollowerSharingRetries < MAX_CONNECTION_RETRIES)
				{
					Trace.myTrace("DexcomShareFollowerEditor.as", "Error enabling follower sharing! Retrying...");
					enableFollowerSharingRetries++;
					enableFollowerSharing();
				}
				else if (response == null)
				{
					Trace.myTrace("DexcomShareFollowerEditor.as", "Error connecting to Dexcom servers!");
					errorMessage = ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','error_message_dexcom_server_unavailable');
					saveButton.isEnabled = true;
					refreshContent();
				}
				else
				{
					if (responseInfo == null || responseInfo.Code == null || responseInfo.Message == null)
					{
						Trace.myTrace("DexcomShareFollowerEditor.as", "Unknown error while trying to enable follower sharing. Aborting...");
						errorMessage = ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','error_message_unknown_error_enabling_follower_sharing');
					}
					else
					{
						Trace.myTrace("DexcomShareFollowerEditor.as", "Error while trying to enable follower sharing. Aborting. Error: " + responseInfo.Message);
						errorMessage = ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','error_message_error_enabling_follower_sharing') + " " + responseInfo.Message;
					}
					
					saveButton.isEnabled = true;
					refreshContent();
				}
			}	
		}
		
		private function onDisableFollowerSharingResponse(e:DexcomShareEvent):void
		{
			Trace.myTrace("DexcomShareFollowerEditor.as", "onDisableFollowerSharingResponse called!");
			
			DexcomShareService.instance.removeEventListener(DexcomShareEvent.DISABLE_FOLLOWER_SHARING, onDisableFollowerSharingResponse);
			
			var response:String = String(e.data);
			
			if (response != null && response == "")
			{
				Trace.myTrace("DexcomShareFollowerEditor.as", "Disabled follower sharing successfully!");
				
				processQueue(disableFollowerSharing);
			}
			else
			{
				var responseInfo:Object = parseDexcomResponse(response);
				
				if (disableFollowerSharingRetries < MAX_CONNECTION_RETRIES)
				{
					Trace.myTrace("DexcomShareFollowerEditor.as", "Error disabling follower sharing! Retrying...");
					disableFollowerSharingRetries++;
					disableFollowerSharing();
				}
				else if (response == null)
				{
					Trace.myTrace("DexcomShareFollowerEditor.as", "Error connecting to Dexcom servers!");
					errorMessage = ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','error_message_dexcom_server_unavailable');
					saveButton.isEnabled = true;
					refreshContent();
				}
				else
				{
					if (responseInfo == null || responseInfo.Code == null || responseInfo.Message == null)
					{
						Trace.myTrace("DexcomShareFollowerEditor.as", "Unknown error while trying to disable follower sharing. Aborting...");
						errorMessage = ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','error_message_unknown_error_disabling_follower_sharing');
					}
					else
					{
						Trace.myTrace("DexcomShareFollowerEditor.as", "Error while trying to disable follower sharing. Aborting. Error: " + responseInfo.Message);
						errorMessage = ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','error_message_error_disabling_follower_sharing') + " " + responseInfo.Message;
					}
					
					saveButton.isEnabled = true;
					refreshContent();
				}
			}	
		}
		
		private function onChangFollowerPermissionsResponse(e:DexcomShareEvent):void
		{
			Trace.myTrace("DexcomShareFollowerEditor.as", "onChangFollowerPermissionsResponse called!");
			
			DexcomShareService.instance.removeEventListener(DexcomShareEvent.CHANGE_FOLLOWER_PERMISSIONS, onChangFollowerPermissionsResponse);
			
			var response:String = String(e.data);
			
			if (response != null && response == "")
			{
				Trace.myTrace("DexcomShareFollowerEditor.as", "Changed follower permissions successfully!");
				
				processQueue(changeFollowerPermissions);
			}
			else
			{
				var responseInfo:Object = parseDexcomResponse(response);
				
				if (changeFollowerPermissionsRetries < MAX_CONNECTION_RETRIES)
				{
					Trace.myTrace("DexcomShareFollowerEditor.as", "Error changing follower permissions! Retrying...");
					changeFollowerPermissionsRetries++;
					changeFollowerPermissions();
				}
				else if (response == null)
				{
					Trace.myTrace("DexcomShareFollowerEditor.as", "Error connecting to Dexcom servers!");
					errorMessage = ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','error_message_dexcom_server_unavailable');
					saveButton.isEnabled = true;
					refreshContent();
				}
				else
				{
					if (responseInfo == null || responseInfo.Code == null || responseInfo.Message == null)
					{
						Trace.myTrace("DexcomShareFollowerEditor.as", "Unknown error while trying to change follower permissions. Aborting...");
						errorMessage = ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','error_message_unknown_error_changing_follower_permissions');
					}
					else
					{
						Trace.myTrace("DexcomShareFollowerEditor.as", "Error while trying to change follower permissions. Aborting. Error: " + responseInfo.Message);
						errorMessage = ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','error_message_error_changing_follower_permissions') + " " + responseInfo.Message;
					}
					
					saveButton.isEnabled = true;
					refreshContent();
				}
			}
		}
		
		private function onSettingsChanged(e:Event):void
		{
			//Enable save button if user made changes
			var saveEnabled:Boolean = false;
			
			if (followerName.text != "" && followerName.text != initialFollowerName)
				saveEnabled = true;
			else if (followerSharingActiveSwitch.isSelected != initialFollowerSharingActive)
				saveEnabled = true;
			else if (allowGraphView.isSelected != initialAllowGraphView)
				saveEnabled = true;
			
			saveButton.isEnabled = saveEnabled;
		}
		
		private function onTextInputEnter(e:Event):void
		{
			//Dismiss mobile keyboard
			followerName.clearFocus();
		}
		
		private function onSave(e:Event):void
		{
			if (!NetworkInfo.networkInfo.isReachable())
			{
				errorMessage = ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','error_message_no_internet_connection');
				refreshContent();
				return;
			}
			
			if (userDisplayName.text == "")
			{
				errorMessage = ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','error_message_display_name_empty');
				refreshContent();
				return;
			}
			
			//Disable save button
			saveButton.isEnabled = false;
			
			//Clear queue
			queueList.length = 0;
			
			//Populate queue with actions
			if (followerName.text != "" && followerName.text != initialFollowerName)
				queueList.push(changeFollowerName);
			
			if (followerSharingActiveSwitch.isSelected != initialFollowerSharingActive && initialFollowerState != 2)
			{
				if (followerSharingActiveSwitch.isSelected)
					queueList.push(enableFollowerSharing);
				else
					queueList.push(disableFollowerSharing);
			}
			
			if (allowGraphView.isSelected != initialAllowGraphView)
				queueList.push(changeFollowerPermissions);
			
			//Process queue
			processQueue(null);
		}
		
		private function onCancel(e:Event):void
		{
			//Close popup
			dispatchEventWith(Event.COMPLETE);
		}
		
		/**
		 * Helpers
		 */
		private function disposePreloader():void
		{
			if (preloader != null)
			{
				removeChild(preloader);
				preloader.dispose();
				preloader = null;
			}
		}
		
		private function convertDexcomDateToRegularDate(dsDate:String):Date
		{
			var formattedDateString:String = dsDate.replace("/Date(", "").replace(")/", "");
			
			return new Date(Number(formattedDateString));
		}
		
		private function convertDexcomDelayToString(delay:String):String
		{
			return delay.replace("PT", "").replace("H", ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','hours')).replace("M", ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','minutes')).replace("0S", ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','never'));
		}
		
		private function convertDexcomAlarmToString(alarmSoundFile:String):String
		{
			var alarmSoundName:String;
			
			if (alarmSoundFile == "AlarmClockLong.caf")
				alarmSoundName = "Alarm Clock Long";
			else if (alarmSoundFile == "AlarmClockShort.caf")
				alarmSoundName = "Alarm Clock Short";
			else if (alarmSoundFile == "BabyCry.caf")
				alarmSoundName = "Baby Cry";
			else if (alarmSoundFile == "Beep.wav")
				alarmSoundName = "Beep";
			else if (alarmSoundFile == "Dinging.caf")
				alarmSoundName = "Dinging";
			else if (alarmSoundFile == "Dings.caf")
				alarmSoundName = "Dings";
			else if (alarmSoundFile == "Disconnected.caf")
				alarmSoundName = "Disconnected";
			else if (alarmSoundFile == "DoorBell.caf")
				alarmSoundName = "Door Bell";
			else if (alarmSoundFile == "FireAlarm.caf")
				alarmSoundName = "Fire Alarm";
			else if (alarmSoundFile == "High.wav")
				alarmSoundName = "High";
			else if (alarmSoundFile == "HighAtt.wav")
				alarmSoundName = "High Attentive";
			else if (alarmSoundFile == "LongNoDataAtt.wav")
				alarmSoundName = "Long No Data Attentive";
			else if (alarmSoundFile == "NoData.wav")
				alarmSoundName = "No Data";
			else if (alarmSoundFile == "NoDataAtt.wav")
				alarmSoundName = "No Data Attentive";
			else if (alarmSoundFile == "Low.wav")
				alarmSoundName = "Low";
			else if (alarmSoundFile == "LowAtt.wav")
				alarmSoundName = "Low Attentive";
			else if (alarmSoundFile == "QuietBeeps.caf")
				alarmSoundName = "Quiet Beeps";
			else if (alarmSoundFile == "ShortAlarm.caf")
				alarmSoundName = "Short Alarm";
			else if (alarmSoundFile == "ShortBeeps1.caf")
				alarmSoundName = "Short Beeps 1";
			else if (alarmSoundFile == "ShortBeeps2.caf")
				alarmSoundName = "Short Beeps 2";
			else if (alarmSoundFile == "Siren1.caf")
				alarmSoundName = "Siren 1";
			else if (alarmSoundFile == "Siren2.caf")
				alarmSoundName = "Siren 2";
			else if (alarmSoundFile == "TruckSiren.caf")
				alarmSoundName = "Truck Siren";
			else if (alarmSoundFile == "Tune.caf")
				alarmSoundName = "Tune";
			else if (alarmSoundFile == "UrgentLow.wav")
				alarmSoundName = "Urgent Low";
			else if (alarmSoundFile == "UrgentLowAtt.wav")
				alarmSoundName = "Urgent Low Attentive";
			
			return alarmSoundName;
		}
		
		private static function parseDexcomResponse(response:String):Object
		{
			var responseInfo:Object;
			
			try
			{
				//responseInfo = JSON.parse(response);
				responseInfo = SpikeJSON.parse(response);
			} 
			catch(error:Error) 
			{
				Trace.myTrace("DexcomShareFollowerEditor.as", "Can't parse server response! Error: " + error.message);
			}
			
			return responseInfo;
		}
		
		/**
		 * Utility
		 */
		override protected function draw():void
		{
			super.draw();
			
			//Disable action accessories that are not meant to be modified by the user. They serve as information only.
			if (urgentLowAlarmSwitch != null)
				urgentLowAlarmSwitch.isEnabled = false;
			
			if (lowAlarmSwitch != null)
				lowAlarmSwitch.isEnabled = false;
			
			if (highAlarmSwitch != null)
				highAlarmSwitch.isEnabled = false;
			
			if (missedReadingsAlarmSwitch != null)
				missedReadingsAlarmSwitch.isEnabled = false;
			
			if (followerSharingActiveSwitch != null && initialFollowerState == 2)
				followerSharingActiveSwitch.isEnabled = false;
		}
		
		override public function dispose():void
		{
			if (cancelButton != null)
			{
				actionsContainer.removeChild(cancelButton);
				cancelButton.removeEventListener(Event.TRIGGERED, onCancel);
				cancelButton.dispose();
				cancelButton = null;
			}
			
			if (saveButton != null)
			{
				actionsContainer.removeChild(saveButton);
				saveButton.removeEventListener(Event.TRIGGERED, onSave);
				saveButton.dispose();
				saveButton = null;
			}
			
			if (actionsContainer != null)
			{
				actionsContainer.dispose();
				actionsContainer = null;
			}
			
			if (followerName != null)
			{
				followerName.removeEventListener(Event.CHANGE, onSettingsChanged);
				followerName.removeEventListener(FeathersEventType.ENTER, onTextInputEnter);
				followerName.dispose();
				followerName = null;
			}
			
			if (userDisplayName != null)
			{
				userDisplayName.dispose();
				userDisplayName = null;
			}
			
			if (followerEmail != null)
			{
				followerEmail.dispose();
				followerEmail = null;
			}
			
			if (invitationDate != null)
			{
				invitationDate.dispose();
				invitationDate = null;
			}
			
			if (allowGraphView != null)
			{
				allowGraphView.removeEventListener(Event.CHANGE, onSettingsChanged);
				allowGraphView.dispose();
				allowGraphView = null;
			}
			
			if (followerSharingActiveSwitch != null)
			{
				followerSharingActiveSwitch.removeEventListener(Event.CHANGE, onSettingsChanged);
				followerSharingActiveSwitch.dispose();
				followerSharingActiveSwitch = null;
			}
			
			if (lowAlarmSwitch != null)
			{
				lowAlarmSwitch.dispose();
				lowAlarmSwitch = null;
			}
			
			if (urgentLowAlarmSwitch != null)
			{
				urgentLowAlarmSwitch.dispose();
				urgentLowAlarmSwitch = null;
			}
			
			if (highAlarmSwitch != null)
			{
				highAlarmSwitch.dispose();
				highAlarmSwitch = null;
			}
			
			if (missedReadingsAlarmSwitch != null)
			{
				missedReadingsAlarmSwitch.dispose();
				missedReadingsAlarmSwitch = null;
			}
			
			if (urgentLowValue != null)
			{
				urgentLowValue.dispose();
				urgentLowValue = null;
			}
			
			if (lowAlarmValue != null)
			{
				lowAlarmValue.dispose();
				lowAlarmValue = null;
			}
			
			if (highAlarmValue != null)
			{
				highAlarmValue.dispose();
				highAlarmValue = null;
			}
			
			if (lowAlarmDelay != null)
			{
				lowAlarmDelay.dispose();
				lowAlarmDelay = null;
			}
			
			if (highAlarmDelay != null)
			{
				highAlarmDelay.dispose();
				highAlarmDelay = null;
			}
			
			if (missedReadingsAlarmDelay != null)
			{
				missedReadingsAlarmDelay.dispose();
				missedReadingsAlarmDelay = null;
			}
			
			if (statusLabel != null)
			{
				statusLabel.dispose();
				statusLabel = null;
			}
			
			if (preloader != null)
			{
				preloader.dispose();
				preloader = null;
			}
			
			if (missedReadingsSound != null)
			{
				missedReadingsSound.dispose();
				missedReadingsSound = null;
			}
			
			if (highSound != null)
			{
				highSound.dispose();
				highSound = null;
			}
			
			if (lowSound != null)
			{
				lowSound.dispose();
				lowSound = null;
			}
			
			if (urgentLowSound != null)
			{
				urgentLowSound.dispose();
				urgentLowSound = null;
			}
			
			if (lowAlarmRepeat != null)
			{
				lowAlarmRepeat.dispose();
				lowAlarmRepeat = null;
			}
			
			if (highAlarmRepeat != null)
			{
				highAlarmRepeat.dispose();
				highAlarmRepeat = null;
			}
			
			if (errorMesageLabel != null)
			{
				errorMesageLabel.dispose();
				errorMesageLabel = null;
			}
			
			if (managedByFollowerLabel != null)
			{
				managedByFollowerLabel.dispose();
				managedByFollowerLabel = null;
			}
			
			super.dispose();
		}
	}
}