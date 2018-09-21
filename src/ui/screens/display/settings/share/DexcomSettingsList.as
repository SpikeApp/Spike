package ui.screens.display.settings.share
{
	import com.adobe.utils.StringUtil;
	
	import cryptography.Keys;
	
	import database.CGMBlueToothDevice;
	import database.CommonSettings;
	
	import feathers.controls.Button;
	import feathers.controls.Callout;
	import feathers.controls.Check;
	import feathers.controls.Label;
	import feathers.controls.LayoutGroup;
	import feathers.controls.List;
	import feathers.controls.PickerList;
	import feathers.controls.ScrollContainer;
	import feathers.controls.TextInput;
	import feathers.controls.ToggleSwitch;
	import feathers.controls.popups.DropDownPopUpContentManager;
	import feathers.core.PopUpManager;
	import feathers.data.ArrayCollection;
	import feathers.events.FeathersEventType;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.HorizontalLayout;
	import feathers.layout.VerticalLayout;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import services.DexcomShareService;
	
	import starling.core.Starling;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.ResizeEvent;
	import starling.utils.SystemUtil;
	
	import ui.popups.AlertManager;
	import ui.screens.display.LayoutFactory;
	import ui.screens.display.SpikeList;
	import ui.screens.display.dexcomshare.DexcomShareFollowersList;
	
	import utils.Constants;
	import utils.Cryptography;
	import utils.DeviceInfo;
	
	[ResourceBundle("sharesettingsscreen")]
	[ResourceBundle("globaltranslations")]

	public class DexcomSettingsList extends SpikeList 
	{
		/* Display Objects */
		private var dsUsername:TextInput;
		private var dsPassword:TextInput;
		private var dsLogin:Button;
		private var dsServer:PickerList;
		private var dsToggle:ToggleSwitch;
		private var dsSerial:TextInput;
		private var actionsContainer:LayoutGroup;
		private var manageFollowers:Button;
		private var positionHelper:Sprite;
		private var followerManager:DexcomShareFollowersList;
		private var followerManagerCallout:Callout;
		private var followerManagerContainer:ScrollContainer;
		private var nonDexcomInstructions:Label;
		private var wifiSyncOnlyCheck:Check;
		
		/* Properties */
		public var needsSave:Boolean = false;
		private var isDexcomEnabled:Boolean;
		private var selectedUsername:String;
		private var selectedPassword:String;
		private var selectedServerCode:String;
		private var selectedServerIndex:int;
		private var selectedDexcomShareSerialNumber:String;
		private var isSyncWifiOnly:Boolean;
		
		public function DexcomSettingsList()
		{
			super();
		}
		override protected function initialize():void 
		{
			super.initialize();
			
			setupProperties();
			setupIntitialState();
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
		
		private function setupIntitialState():void
		{
			/* Get data from database */
			isDexcomEnabled = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEXCOM_SHARE_ON) == "true";
			selectedUsername = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEXCOM_SHARE_ACCOUNTNAME);
			selectedPassword = Cryptography.decryptStringLight(Keys.STRENGTH_256_BIT, CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEXCOM_SHARE_PASSWORD));
			selectedServerCode = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEXCOM_SHARE_US_URL) == "true" ? "us" : "non-us";
			selectedDexcomShareSerialNumber = !CGMBlueToothDevice.isDexcomG5() ? CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEXCOM_SHARE_SERIALNUMBER).toUpperCase() : "";
			isSyncWifiOnly = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEXCOM_SHARE_WIFI_ONLY_UPLOADER_ON) == "true";
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEXCOM_SHARE_US_URL) == "true")
				selectedServerCode = "us";
			else
				selectedServerCode = "non-us";
			
			if (!CGMBlueToothDevice.isDexcomG5() && !CGMBlueToothDevice.isDexcomG6())
				selectedDexcomShareSerialNumber = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEXCOM_SHARE_SERIALNUMBER).toUpperCase();
			else
				selectedDexcomShareSerialNumber = "";	
		}
		
		private function setupContent():void
		{
			//On/Off Toggle
			dsToggle = LayoutFactory.createToggleSwitch(isDexcomEnabled);
			dsToggle.addEventListener( Event.CHANGE, onDexcomShareOnOff );
			
			//Username
			dsUsername = LayoutFactory.createTextInput(false, false, Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr ? 120 : 140, HorizontalAlign.RIGHT);
			if (!Constants.isPortrait) dsUsername.width += 100;
			if (DeviceInfo.isTablet()) dsUsername.width += 100;
			dsUsername.text = selectedUsername;
			dsUsername.addEventListener( FeathersEventType.ENTER, onTextInputEnter );
			dsUsername.addEventListener(Event.CHANGE, onTextInputChanged);
			
			//Password
			dsPassword = LayoutFactory.createTextInput(true, false, Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr ? 120 : 140, HorizontalAlign.RIGHT);
			if (!Constants.isPortrait) dsPassword.width += 100;
			if (DeviceInfo.isTablet()) dsPassword.width += 100;
			dsPassword.text = selectedPassword;
			dsPassword.addEventListener( FeathersEventType.ENTER, onTextInputEnter );
			dsPassword.addEventListener(Event.CHANGE, onTextInputChanged);
			
			//Serial
			if (!CGMBlueToothDevice.isDexcomG5() && !CGMBlueToothDevice.isDexcomG6())
			{
				dsSerial = LayoutFactory.createTextInput(false, false, Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr ? 120 : 140, HorizontalAlign.RIGHT);
				if (!Constants.isPortrait) dsSerial.width += 100;
				if (DeviceInfo.isTablet()) dsSerial.width += 100;
				dsSerial.text = selectedDexcomShareSerialNumber;
				dsSerial.addEventListener( FeathersEventType.ENTER, onTextInputEnter );
				dsSerial.addEventListener(Event.CHANGE, onTextInputChanged);
			}
			
			/* Server */
			dsServer = LayoutFactory.createPickerList();
			
			//Temp Data Objects
			var serversLabelsList:Array = ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','dexcom_share_server_name_list').split(",");
			var serversCodeList:Array = ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','dexcom_share_server_code_list').split(",");
			var dsServerList:ArrayCollection = new ArrayCollection();
			var dataLength:int = serversLabelsList.length;
			for (var i:int = 0; i < dataLength; i++) 
			{
				dsServerList.push({ label: StringUtil.trim(serversLabelsList[i]), code: StringUtil.trim(serversCodeList[i]) });
				if (selectedServerCode == StringUtil.trim(serversCodeList[i]))
					selectedServerIndex = i;
			}
			
			dsServer.labelField = "label";
			dsServer.pivotX = -3;
			dsServer.popUpContentManager = new DropDownPopUpContentManager();
			dsServer.dataProvider = dsServerList;
			dsServer.selectedIndex = selectedServerIndex;
			dsServer.listFactory = function():List
			{
				var list:List = new List();
				list.minWidth = 120;
				
				return list;
			};
			dsServer.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Wi-Fi Sync Only
			wifiSyncOnlyCheck = LayoutFactory.createCheckMark(isSyncWifiOnly);
			wifiSyncOnlyCheck.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Actions Container
			var actionsLayout:HorizontalLayout = new HorizontalLayout();
			actionsLayout.gap = 5;
			
			actionsContainer = new LayoutGroup();
			actionsContainer.layout = actionsLayout;
			actionsContainer.pivotX = -3;
			
			//Invite Follower
			manageFollowers = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','manage_followers_button_label'));
			manageFollowers.addEventListener( Event.TRIGGERED, onManageFollowers );
			actionsContainer.addChild(manageFollowers);
			
			//Login
			dsLogin = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','login_button_label'));
			dsLogin.addEventListener( Event.TRIGGERED, onDexcomShareLogin );
			actionsContainer.addChild(dsLogin);
			
			//Non dexcom instructions
			nonDexcomInstructions = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','non_dexcom_transmitter_instructions'), HorizontalAlign.JUSTIFY);
			nonDexcomInstructions.wordWrap = true;
			nonDexcomInstructions.width = width - 10;
			nonDexcomInstructions.paddingTop = nonDexcomInstructions.paddingBottom = 10;
			
			//Define Dexcom Share Settings Data
			reloadDexcomShareSettings(isDexcomEnabled);
		}
		
		public function save():void
		{
			//Dexcom Share
			var dexcomEnabledValue:String;
			
			if (isDexcomEnabled) dexcomEnabledValue = "true";
			else dexcomEnabledValue = "false";
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEXCOM_SHARE_ON) != isDexcomEnabled)
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_DEXCOM_SHARE_ON, dexcomEnabledValue);
			
			//Username
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEXCOM_SHARE_ACCOUNTNAME) != selectedUsername)
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_DEXCOM_SHARE_ACCOUNTNAME, selectedUsername);
			
			//Password
			var passwordToSave:String = Cryptography.encryptStringLight(Keys.STRENGTH_256_BIT, selectedPassword);
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEXCOM_SHARE_PASSWORD) != passwordToSave)
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_DEXCOM_SHARE_PASSWORD, passwordToSave);
			
			//Serial
			if (!CGMBlueToothDevice.isDexcomG5() && !CGMBlueToothDevice.isDexcomG6() && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEXCOM_SHARE_SERIALNUMBER) != selectedDexcomShareSerialNumber.toUpperCase())
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_DEXCOM_SHARE_SERIALNUMBER, selectedDexcomShareSerialNumber.toUpperCase());
			
			//Server
			var dexcomServerValue:String;
			
			if (selectedServerCode == "us") dexcomServerValue = "true";
			else dexcomServerValue = "false";
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEXCOM_SHARE_US_URL) != dexcomServerValue)
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_DEXCOM_SHARE_US_URL, dexcomServerValue);
			
			//Wi-Fi Only
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEXCOM_SHARE_WIFI_ONLY_UPLOADER_ON) != String(isSyncWifiOnly))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_DEXCOM_SHARE_WIFI_ONLY_UPLOADER_ON, String(isSyncWifiOnly));
			
			needsSave = false;
		}
		
		private function reloadDexcomShareSettings(fullDisplay:Boolean):void
		{
			if(fullDisplay)
			{
				var listDataProviderItems:Array = [];
				
				listDataProviderItems.push({ label: ModelLocator.resourceManagerInstance.getString('globaltranslations','enabled_label'), accessory: dsToggle });
				listDataProviderItems.push({ label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','dexcom_share_username_label'), accessory: dsUsername });
				listDataProviderItems.push({ label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','dexcom_share_password_label'), accessory: dsPassword });
				if (!CGMBlueToothDevice.isDexcomG5() && !CGMBlueToothDevice.isDexcomG6())
					listDataProviderItems.push({ label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','serial_label'), accessory: dsSerial });
				listDataProviderItems.push({ label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','dexcom_share_server_label'), accessory: dsServer });
				listDataProviderItems.push({ label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','wifi_only_sync_label'), accessory: wifiSyncOnlyCheck });
				listDataProviderItems.push({ label: "", accessory: actionsContainer });
				if (!CGMBlueToothDevice.isDexcomG4() && !CGMBlueToothDevice.isDexcomG5() && !CGMBlueToothDevice.isDexcomG6())
					listDataProviderItems.push({ label: "", accessory: nonDexcomInstructions });
				
				dataProvider = new ArrayCollection(listDataProviderItems);
			}
			else
			{
				dataProvider = new ArrayCollection
				(
					[
						{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations','enabled_label'), accessory: dsToggle }
					]
				);
			}
		}
		
		private function setupCalloutPosition():void
		{
			//Position helper for the callout
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
		}
		
		/**
		 * Event Listeners
		 */
		private function onTextInputChanged(e:Event):void
		{
			//Update internal values
			selectedUsername = dsUsername.text;
			selectedPassword = dsPassword.text;
			if(dsSerial != null)
				selectedDexcomShareSerialNumber = dsSerial.text;
			
			needsSave = true;
		}
		
		private function onSettingsChanged(e:Event):void
		{
			selectedServerCode = dsServer.selectedItem.code;
			isSyncWifiOnly = wifiSyncOnlyCheck.isSelected;
			
			needsSave = true;
		}
		
		private function onTextInputEnter(event:Event):void
		{
			//Clear focus to dismiss the keyboard
			dsUsername.clearFocus();
			dsPassword.clearFocus();
			if (dsSerial != null)
				dsSerial.clearFocus();
		}
		
		private function onDexcomShareOnOff(event:Event):void
		{
			isDexcomEnabled = dsToggle.isSelected;
			
			reloadDexcomShareSettings(isDexcomEnabled);
			
			needsSave = true;
		}
		
		private function onDexcomShareLogin(event:Event):void
		{
			//Workaround for duplicate checking
			DexcomShareService.ignoreSettingsChanged = true;
			
			//Save values to database
			save();
			
			//Test Credentials
			DexcomShareService.testDexcomShareCredentials(true);
		}
		
		private function onManageFollowers(e:Event):void
		{
			if(DexcomShareService.isAuthorized())
			{
				//SessionID exists, show followers
				setupCalloutPosition();
				
				//Create Followers List
				followerManager = new DexcomShareFollowersList();
				followerManager.addEventListener(Event.CANCEL, onFollowerCancel);
				followerManagerContainer = new ScrollContainer();
				followerManagerContainer.addChild(followerManager);
				
				//Display Callout
				followerManagerCallout = new Callout();
				followerManagerCallout.content = followerManagerContainer;
				followerManagerCallout.origin = positionHelper;
				PopUpManager.addPopUp(followerManagerCallout, false, false);
			}
			else
			{
				AlertManager.showSimpleAlert
				(
					ModelLocator.resourceManagerInstance.getString("globaltranslations","warning_alert_title"),
					ModelLocator.resourceManagerInstance.getString("sharesettingsscreen","needs_dexcom_login"),
					60,
					null,
					HorizontalAlign.CENTER
				);
			}
		}

		private function onFollowerCancel(e:Event):void
		{
			if (PopUpManager.isPopUp(followerManagerCallout))
				PopUpManager.removePopUp(followerManagerCallout);
			else
			{
				if (followerManagerCallout != null)
					followerManagerCallout.close();
				
				PopUpManager.removeAllPopUps();
			}
		}
		
		override protected function onStarlingResize(event:ResizeEvent):void 
		{
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
			
			if (nonDexcomInstructions != null)
			{
				if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr && !Constants.isPortrait)
					nonDexcomInstructions.width = width - 40;
				else
					nonDexcomInstructions.width = width - 10;
			}
			
			if (dsUsername != null)
			{
				SystemUtil.executeWhenApplicationIsActive( dsUsername.clearFocus );
				dsUsername.width = Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr ? 120 : 140;
				if (!Constants.isPortrait) dsUsername.width += 100;
				if (DeviceInfo.isTablet()) dsUsername.width += 100;
			}
			
			if (dsPassword != null)
			{
				SystemUtil.executeWhenApplicationIsActive( dsPassword.clearFocus );
				dsPassword.width = Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr ? 120 : 140;
				if (!Constants.isPortrait) dsPassword.width += 100;
				if (DeviceInfo.isTablet()) dsPassword.width += 100;
			}
			
			if (dsSerial != null)
			{
				SystemUtil.executeWhenApplicationIsActive( dsSerial.clearFocus );
				dsSerial.width = Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr ? 120 : 140;
				if (!Constants.isPortrait) dsSerial.width += 100;
				if (DeviceInfo.isTablet()) dsSerial.width += 100;
			}
			
			if (positionHelper != null)
				positionHelper.x = Constants.stageWidth / 2;
			
			setupRenderFactory();
		}
		
		/**
		 * Utility
		 */
		override protected function draw():void
		{
			if ((layout as VerticalLayout) != null)
				(layout as VerticalLayout).hasVariableItemDimensions = true;
			
			super.draw();
		}
		
		override public function dispose():void
		{
			if(dsUsername != null)
			{
				dsUsername.removeEventListener( FeathersEventType.ENTER, onTextInputEnter );
				dsUsername.dispose();
				dsUsername = null;
			}
			if(dsPassword != null)
			{
				dsPassword.removeEventListener( FeathersEventType.ENTER, onTextInputEnter );
				dsPassword.removeEventListener(Event.CHANGE, onTextInputChanged);
				dsPassword.dispose();
				dsPassword = null;
			}
			if(dsServer != null)
			{
				dsServer.removeEventListener(Event.CHANGE, onSettingsChanged);
				dsServer.dispose();
				dsServer = null;
			}
			if(dsToggle != null)
			{
				dsToggle.removeEventListener( Event.CHANGE, onDexcomShareOnOff );
				dsToggle.dispose();
				dsToggle = null;
			}
			if(dsSerial != null)
			{
				dsSerial.removeEventListener( FeathersEventType.ENTER, onTextInputEnter );
				dsSerial.removeEventListener(Event.CHANGE, onTextInputChanged);
				dsSerial.dispose();
				dsSerial = null;
			}
			if(dsLogin != null)
			{
				actionsContainer.removeChild(dsLogin);
				dsLogin.removeEventListener( Event.TRIGGERED, onDexcomShareLogin );
				dsLogin.dispose();
				dsLogin = null;
			}
			if(manageFollowers != null)
			{
				actionsContainer.removeChild(manageFollowers);
				manageFollowers.removeEventListener( Event.TRIGGERED, onManageFollowers );
				manageFollowers.dispose();
				manageFollowers = null;
			}
			if (actionsContainer != null)
			{
				actionsContainer.dispose();
				actionsContainer = null;
			}
			
			if (positionHelper != null)
			{
				Starling.current.stage.removeChild(positionHelper);
				positionHelper.dispose();
				positionHelper = null;
			}
			
			if (followerManager != null)
			{
				followerManagerContainer.removeChild(followerManager);
				followerManager.dispose();
				followerManager = null;
			}
			
			if (followerManagerContainer != null)
			{
				followerManagerContainer.dispose();
				followerManagerContainer = null;
			}
			
			if (followerManagerCallout != null)
			{
				followerManagerCallout.dispose();
				followerManagerCallout = null;
			}
			
			if (nonDexcomInstructions != null)
			{
				nonDexcomInstructions.dispose();
				nonDexcomInstructions = null;
			}
			if(wifiSyncOnlyCheck != null)
			{
				wifiSyncOnlyCheck.removeEventListener(Event.CHANGE, onSettingsChanged);
				wifiSyncOnlyCheck.dispose();
				wifiSyncOnlyCheck = null;
			}
			
			super.dispose();
		}
	}
}