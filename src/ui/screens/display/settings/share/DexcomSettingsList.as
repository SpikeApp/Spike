package ui.screens.display.settings.share
{
	import com.adobe.images.PNGEncoder;
	import com.adobe.utils.StringUtil;
	import com.distriqt.extension.networkinfo.NetworkInfo;
	
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequestMethod;
	
	import cryptography.Keys;
	
	import database.CGMBlueToothDevice;
	import database.CommonSettings;
	
	import feathers.controls.Alert;
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
	import feathers.layout.VerticalAlign;
	import feathers.layout.VerticalLayout;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import network.NetworkConnector;
	
	import org.qrcode.QRCode;
	
	import services.DexcomShareService;
	
	import starling.core.Starling;
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.ResizeEvent;
	import starling.textures.Texture;
	import starling.utils.SystemUtil;
	
	import ui.popups.AlertManager;
	import ui.popups.EmailFileSender;
	import ui.screens.display.LayoutFactory;
	import ui.screens.display.SpikeList;
	import ui.screens.display.dexcomshare.DexcomShareFollowersList;
	
	import utils.Constants;
	import utils.Cryptography;
	import utils.DeviceInfo;
	
	[ResourceBundle("sharesettingsscreen")]
	[ResourceBundle("maintenancesettingsscreen")]
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
		private var qrCodeBitmapData:BitmapData;
		private var qrCodeImage:Image;
		private var qrCodePopup:Alert;
		private var qrCodeContainer:LayoutGroup;
		private var qrCodeExplanation:Label;
		
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
			dsToggle.addEventListener( starling.events.Event.CHANGE, onDexcomShareOnOff );
			
			//Username
			dsUsername = LayoutFactory.createTextInput(false, false, Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr ? 120 : 140, HorizontalAlign.RIGHT);
			if (!Constants.isPortrait) dsUsername.width += 100;
			if (DeviceInfo.isTablet()) dsUsername.width += 100;
			dsUsername.text = selectedUsername;
			dsUsername.addEventListener( FeathersEventType.ENTER, onTextInputEnter );
			dsUsername.addEventListener(starling.events.Event.CHANGE, onTextInputChanged);
			
			//Password
			dsPassword = LayoutFactory.createTextInput(true, false, Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr ? 120 : 140, HorizontalAlign.RIGHT);
			if (!Constants.isPortrait) dsPassword.width += 100;
			if (DeviceInfo.isTablet()) dsPassword.width += 100;
			dsPassword.text = selectedPassword;
			dsPassword.addEventListener( FeathersEventType.ENTER, onTextInputEnter );
			dsPassword.addEventListener(starling.events.Event.CHANGE, onTextInputChanged);
			
			//Serial
			if (!CGMBlueToothDevice.isDexcomG5() && !CGMBlueToothDevice.isDexcomG6())
			{
				dsSerial = LayoutFactory.createTextInput(false, false, Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr ? 120 : 140, HorizontalAlign.RIGHT);
				if (!Constants.isPortrait) dsSerial.width += 100;
				if (DeviceInfo.isTablet()) dsSerial.width += 100;
				dsSerial.text = selectedDexcomShareSerialNumber;
				dsSerial.addEventListener( FeathersEventType.ENTER, onTextInputEnter );
				dsSerial.addEventListener(starling.events.Event.CHANGE, onTextInputChanged);
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
			dsServer.addEventListener(starling.events.Event.CHANGE, onSettingsChanged);
			
			//Wi-Fi Sync Only
			wifiSyncOnlyCheck = LayoutFactory.createCheckMark(isSyncWifiOnly);
			wifiSyncOnlyCheck.addEventListener(starling.events.Event.CHANGE, onSettingsChanged);
			
			//Actions Container
			var actionsLayout:HorizontalLayout = new HorizontalLayout();
			actionsLayout.gap = 5;
			
			actionsContainer = new LayoutGroup();
			actionsContainer.layout = actionsLayout;
			actionsContainer.pivotX = -3;
			
			//Invite Follower
			manageFollowers = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','manage_followers_button_label'));
			manageFollowers.addEventListener( starling.events.Event.TRIGGERED, onManageFollowers );
			actionsContainer.addChild(manageFollowers);
			
			//Login
			dsLogin = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','login_button_label'));
			dsLogin.addEventListener( starling.events.Event.TRIGGERED, onDexcomShareLogin );
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
		private function onTextInputChanged(e:starling.events.Event):void
		{
			//Update internal values
			selectedUsername = dsUsername.text;
			selectedPassword = dsPassword.text;
			if(dsSerial != null)
				selectedDexcomShareSerialNumber = dsSerial.text;
			
			needsSave = true;
		}
		
		private function onSettingsChanged(e:starling.events.Event):void
		{
			selectedServerCode = dsServer.selectedItem.code;
			isSyncWifiOnly = wifiSyncOnlyCheck.isSelected;
			
			needsSave = true;
		}
		
		private function onTextInputEnter(event:starling.events.Event):void
		{
			//Clear focus to dismiss the keyboard
			dsUsername.clearFocus();
			dsPassword.clearFocus();
			if (dsSerial != null)
				dsSerial.clearFocus();
		}
		
		private function onDexcomShareOnOff(event:starling.events.Event):void
		{
			isDexcomEnabled = dsToggle.isSelected;
			
			reloadDexcomShareSettings(isDexcomEnabled);
			
			needsSave = true;
		}
		
		private function onDexcomShareLogin(event:starling.events.Event):void
		{
			//Workaround for duplicate checking
			DexcomShareService.ignoreSettingsChanged = true;
			
			//Save values to database
			save();
			
			//Test Credentials
			DexcomShareService.testDexcomShareCredentials(true);
		}
		
		private function onManageFollowers(e:starling.events.Event):void
		{
			if(DexcomShareService.isAuthorized())
			{
				var alert:Alert = AlertManager.showActionAlert
				(
					ModelLocator.resourceManagerInstance.getString("globaltranslations","info_alert_title"),
					ModelLocator.resourceManagerInstance.getString("sharesettingsscreen","select_dexcom_follower_app_popup_body"),
					Number.NaN,
					[
						{ label: "DEXCOM FOLLOW", triggered: onOfficialDexcomFollower },
						{ label: "SPIKE", triggered: onSpikeDexcomFollower }
					]
				);
				alert.buttonGroupProperties.horizontalAlign = HorizontalAlign.CENTER;
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
			
			function onOfficialDexcomFollower(e:starling.events.Event):void
			{
				//SessionID exists, show followers
				setupCalloutPosition();
				
				//Create Followers List
				followerManager = new DexcomShareFollowersList();
				followerManager.addEventListener(starling.events.Event.CANCEL, onFollowerCancel);
				followerManagerContainer = new ScrollContainer();
				followerManagerContainer.addChild(followerManager);
				
				//Display Callout
				followerManagerCallout = new Callout();
				followerManagerCallout.content = followerManagerContainer;
				followerManagerCallout.origin = positionHelper;
				PopUpManager.addPopUp(followerManagerCallout, false, false);
			}
			
			function onSpikeDexcomFollower(e:starling.events.Event):void
			{
				//Validation
				if (!NetworkInfo.networkInfo.isReachable())
				{
					AlertManager.showSimpleAlert
					(
						ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
						ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','no_network_connection')
					);
					
					return;
				}
				
				//Master settings object
				var masterSettings:Object = {};
				masterSettings.followerService = "Dexcom";
				masterSettings.username = selectedUsername;
				masterSettings.password = selectedPassword;
				masterSettings.server = selectedServerCode;
				masterSettings.urgentHigh = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_URGENT_HIGH_MARK));
				masterSettings.high = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_HIGH_MARK));
				masterSettings.low = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_LOW_MARK));
				masterSettings.urgentLow = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_URGENT_LOW_MARK));
				
				//Encode master settings
				try
				{
					var masterSettingsString:String = JSON.stringify(masterSettings);
				} 
				catch(error:Error) 
				{
					AlertManager.showSimpleAlert
					(
						ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
						ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','parse_settings_error')
					);
					
					return;
				}
				
				//Encrypt master settings
				var masterSettingsEncrypted:String = Cryptography.encryptStringStrong(Keys.STRENGTH_256_BIT, masterSettingsString);
				
				//Upload them (anonymously and privatly)
				var parameters:Object = {};
				parameters.language = "plaintext";
				parameters.title = "SpikeFollowerSettings";
				parameters["public"] = false;
				parameters.files = [ { name: "follower.txt", content: masterSettingsEncrypted } ];
				
				NetworkConnector.createGlotConnector("https://snippets.glot.io/snippets", null, URLRequestMethod.POST, JSON.stringify(parameters), null, onMasterSettingsUploaded, onSettingsUploadError);
			}
		}
		
		private function onMasterSettingsUploaded(e:flash.events.Event):void
		{
			//Get loader
			var loader:URLLoader = e.currentTarget as URLLoader;
			
			if (loader == null || loader.data == null)
			{
				AlertManager.showSimpleAlert
				(
					ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
					ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','error_backing_up_master_settings')
				);
				
				return;
			}
			
			//Get response
			var response:String = loader.data;
			
			//Dispose loader
			loader.removeEventListener(flash.events.Event.COMPLETE, onMasterSettingsUploaded);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onSettingsUploadError);
			loader = null;
			
			//Parse response and extract link
			try
			{
				var responseJSON:Object = JSON.parse(response);
			} 
			catch(error:Error) 
			{
				AlertManager.showSimpleAlert
				(
					ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
					ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','error_backing_up_master_settings')
				);
				
				return;
			}
			
			if (responseJSON != null && responseJSON.url != null)
			{
				var url:String = String(responseJSON.url);
				if (url.indexOf("https://snippets.glot.io") != -1)
				{
					var encryptedURL:String = Cryptography.encryptStringStrong(Keys.STRENGTH_256_BIT, url);
					try
					{
						//Create QR Code
						var masterSettingsQRCode:QRCode = new QRCode();
						masterSettingsQRCode.encode(encryptedURL);
						
						if (qrCodeBitmapData != null) qrCodeBitmapData.dispose();
						qrCodeBitmapData = masterSettingsQRCode.bitmapData;
						
						if (qrCodeBitmapData == null)
						{
							AlertManager.showSimpleAlert
							(
								ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
								ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','error_creating_qr_code')
							);
						}
						else
						{
							if (qrCodeContainer != null) qrCodeContainer.dispose();
							qrCodeContainer = LayoutFactory.createLayoutGroup("vertical", HorizontalAlign.CENTER, VerticalAlign.TOP, 15);
							
							if (qrCodeImage != null) 
							{
								if (qrCodeImage.texture != null) qrCodeImage.texture.dispose();
								qrCodeImage.dispose();
							}
							qrCodeImage = new Image(Texture.fromBitmapData(qrCodeBitmapData));
							qrCodeContainer.addChild(qrCodeImage);
							
							if (qrCodeExplanation != null) qrCodeExplanation.dispose();
							qrCodeExplanation = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','follower_invitation_in_app_instructions'), HorizontalAlign.JUSTIFY);
							qrCodeExplanation.wordWrap = true;
							
							if (qrCodePopup != null) qrCodePopup.removeFromParent(true);
							qrCodePopup = AlertManager.showActionAlert
							(
								ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','qr_code'),
								"",
								Number.NaN,
								[
									{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations','cancel_button_label').toUpperCase() },
									{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations','email_button_label').toUpperCase(), triggered: sendQRCodeByEmail }
								],
								HorizontalAlign.JUSTIFY,
								qrCodeContainer
							);
							qrCodePopup.validate();
							qrCodeContainer.width = qrCodePopup.width;
							qrCodeExplanation.width = qrCodeContainer.width;
							qrCodeContainer.addChild(qrCodeExplanation);
							
							qrCodePopup.gap = 0;
							qrCodePopup.headerProperties.maxHeight = 30;
							qrCodePopup.buttonGroupProperties.paddingTop = -10;
							qrCodePopup.buttonGroupProperties.gap = 10;
							qrCodePopup.buttonGroupProperties.horizontalAlign = HorizontalAlign.CENTER;
							
							function sendQRCodeByEmail(e:starling.events.Event):void
							{
								//Close popup
								if (qrCodePopup != null)
								{
									qrCodePopup.removeFromParent(true);
								}
								
								//Send QR Code by Email
								EmailFileSender.instance.addEventListener(starling.events.Event.COMPLETE, onFileSenderClosed);
								EmailFileSender.instance.addEventListener(starling.events.Event.CANCEL, onFileSenderClosed);
								EmailFileSender.sendFile
								(
									ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','dexcom_share_invitation_email_subject'),
									ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','follower_invitation_email_body'),
									"SpikeDexcomShareQRCode.png",
									PNGEncoder.encode(qrCodeBitmapData),
									"image/png",
									ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','follower_qr_code_email_sent_success_message'),
									ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','email_sent_error_message'),
									"",
									ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','follower_email_address_popup_title')
								);
							}
						}
					} 
					catch(error:Error) 
					{
						AlertManager.showSimpleAlert
						(
							ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
							ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','error_creating_qr_code')
						);
					}
				}
				else
				{
					AlertManager.showSimpleAlert
					(
						ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
						ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','error_backing_up_master_settings')
					);
				}
			}
			else
			{
				AlertManager.showSimpleAlert
				(
					ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
					ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','error_backing_up_master_settings')
				);
			}
		}
		
		private function onFileSenderClosed(e:starling.events.Event):void
		{
			EmailFileSender.instance.removeEventListener(starling.events.Event.COMPLETE, onFileSenderClosed);
			EmailFileSender.instance.removeEventListener(starling.events.Event.CANCEL, onFileSenderClosed);
		}
		
		private function onSettingsUploadError(error:Error):void
		{
			AlertManager.showSimpleAlert
			(
				ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
				ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','error_backing_up_master_settings')
			);
		}
		
		private function onFollowerCancel(e:starling.events.Event):void
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
			EmailFileSender.instance.removeEventListener(starling.events.Event.COMPLETE, onFileSenderClosed);
			EmailFileSender.instance.removeEventListener(starling.events.Event.CANCEL, onFileSenderClosed);
			
			if(dsUsername != null)
			{
				dsUsername.removeEventListener( FeathersEventType.ENTER, onTextInputEnter );
				dsUsername.dispose();
				dsUsername = null;
			}
			if(dsPassword != null)
			{
				dsPassword.removeEventListener( FeathersEventType.ENTER, onTextInputEnter );
				dsPassword.removeEventListener(starling.events.Event.CHANGE, onTextInputChanged);
				dsPassword.dispose();
				dsPassword = null;
			}
			if(dsServer != null)
			{
				dsServer.removeEventListener(starling.events.Event.CHANGE, onSettingsChanged);
				dsServer.dispose();
				dsServer = null;
			}
			if(dsToggle != null)
			{
				dsToggle.removeEventListener( starling.events.Event.CHANGE, onDexcomShareOnOff );
				dsToggle.dispose();
				dsToggle = null;
			}
			if(dsSerial != null)
			{
				dsSerial.removeEventListener( FeathersEventType.ENTER, onTextInputEnter );
				dsSerial.removeEventListener(starling.events.Event.CHANGE, onTextInputChanged);
				dsSerial.dispose();
				dsSerial = null;
			}
			if(dsLogin != null)
			{
				actionsContainer.removeChild(dsLogin);
				dsLogin.removeEventListener( starling.events.Event.TRIGGERED, onDexcomShareLogin );
				dsLogin.dispose();
				dsLogin = null;
			}
			if(manageFollowers != null)
			{
				actionsContainer.removeChild(manageFollowers);
				manageFollowers.removeEventListener( starling.events.Event.TRIGGERED, onManageFollowers );
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
				wifiSyncOnlyCheck.removeEventListener(starling.events.Event.CHANGE, onSettingsChanged);
				wifiSyncOnlyCheck.dispose();
				wifiSyncOnlyCheck = null;
			}
			
			if (qrCodeExplanation != null)
			{
				qrCodeExplanation.removeFromParent();
				qrCodeExplanation.dispose();
				qrCodeExplanation = null;
			}
			
			if (qrCodeImage != null)
			{
				qrCodeImage.removeFromParent();
				if (qrCodeImage.texture != null)
				{
					qrCodeImage.texture.dispose();
				}
				qrCodeImage.dispose();
				qrCodeImage = null;
			}
			
			if (qrCodeBitmapData != null)
			{
				qrCodeBitmapData.dispose();
				qrCodeBitmapData = null;
			}
			
			if (qrCodeContainer != null)
			{
				qrCodeContainer.removeFromParent();
				qrCodeContainer.dispose();
				qrCodeContainer = null;
			}
			
			if (qrCodePopup != null)
			{
				qrCodePopup.removeFromParent();
				qrCodePopup.dispose();
				qrCodePopup = null;
			}
			
			super.dispose();
		}
	}
}