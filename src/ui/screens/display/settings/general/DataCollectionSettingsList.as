package ui.screens.display.settings.general
{
	import com.adobe.utils.StringUtil;
	import com.distriqt.extension.networkinfo.NetworkInfo;
	import com.distriqt.extension.scanner.AuthorisationStatus;
	import com.distriqt.extension.scanner.Scanner;
	import com.distriqt.extension.scanner.ScannerOptions;
	import com.distriqt.extension.scanner.Symbology;
	import com.distriqt.extension.scanner.events.AuthorisationEvent;
	import com.distriqt.extension.scanner.events.ScannerEvent;
	
	import flash.display.StageOrientation;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequestMethod;
	import flash.utils.setTimeout;
	
	import cryptography.Keys;
	
	import database.CommonSettings;
	
	import feathers.controls.Button;
	import feathers.controls.Label;
	import feathers.controls.List;
	import feathers.controls.NumericStepper;
	import feathers.controls.PickerList;
	import feathers.controls.TextInput;
	import feathers.controls.popups.DropDownPopUpContentManager;
	import feathers.data.ArrayCollection;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalLayout;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import network.NetworkConnector;
	
	import services.DexcomShareService;
	import services.NightscoutService;
	
	import starling.core.Starling;
	import starling.events.Event;
	import starling.events.ResizeEvent;
	import starling.utils.SystemUtil;
	
	import treatments.Profile;
	import treatments.ProfileManager;
	import treatments.TreatmentsManager;
	
	import ui.AppInterface;
	import ui.popups.AlertManager;
	import ui.screens.display.LayoutFactory;
	import ui.screens.display.SpikeList;
	
	import utils.Constants;
	import utils.Cryptography;
	import utils.DeviceInfo;
	
	[ResourceBundle("generalsettingsscreen")]
	[ResourceBundle("sharesettingsscreen")]
	[ResourceBundle("maintenancesettingsscreen")]

	public class DataCollectionSettingsList extends SpikeList 
	{
		/* Display Objects */
		private var collectionModePicker:PickerList;
		private var nightscoutURLInput:TextInput;
		private var nightscoutOffsetStepper:NumericStepper;
		private var nightscoutAPISecretTextInput:TextInput;
		private var nightscoutAPIDescription:Label;
		private var nsLogin:Button;
		private var followerServicePicker:PickerList;
		private var dsUsername:TextInput;
		private var dsPassword:TextInput;
		private var dsServer:PickerList;
		private var dsLogin:Button;
		private var qrCodeScannerButton:Button;
		
		/* Properties */
		public var needsSave:Boolean = false;
		private var collectionMode:String;		
		private var followNSURL:String;
		private var nightscoutOffset:Number;
		private var nightscoutAPISecretValue:String;
		private var followerService:String;
		private var dsUsernameValue:String;
		private var dsPasswordValue:String;
		private var dsServerCodeValue:String;
		private var renderTimoutID1:uint;
		private var renderTimoutID2:uint;
		private var renderTimoutID3:uint;
		
		public function DataCollectionSettingsList()
		{
			super(true);
			
			setupProperties();
			setupInitialContent();	
			setupContent();
		}
		
		/**
		 * Functionality
		 */
		private function setupProperties():void
		{
			/* Set Properties */
			clipContent = false;
			isSelectable = false;
			autoHideBackground = true;
			hasElasticEdges = false;
			paddingBottom = 5;
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
		}
		
		private function setupInitialContent():void
		{
			/* Get Values From Database */
			collectionMode = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_MODE);
			followNSURL = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_URL);
			nightscoutOffset = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_OFFSET));
			nightscoutAPISecretValue = Cryptography.decryptStringLight(Keys.STRENGTH_256_BIT, CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_API_SECRET));
			followerService = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FOLLOWER_MODE);
			dsUsernameValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_DS_USERNAME);
			dsPasswordValue = Cryptography.decryptStringLight(Keys.STRENGTH_256_BIT, CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_DS_PASSWORD));
			dsServerCodeValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_DS_SERVER);
		}
		
		private function setupContent():void
		{
			//Common Variables
			var i:int;
			
			//Collection Picker List
			collectionModePicker = LayoutFactory.createPickerList();
			
			/* Collection Picker Data */
			var collectionModesLabelsList:Array = ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','collection_list').split(",");
			var collectionModestList:ArrayCollection = new ArrayCollection();
			for (i = 0; i < collectionModesLabelsList.length; i++) 
			{
				collectionModestList.push({label: StringUtil.trim(collectionModesLabelsList[i]), id: i});
			}
			collectionModesLabelsList.length = 0;
			collectionModesLabelsList = null;
			collectionModePicker.labelField = "label";
			collectionModePicker.popUpContentManager = new DropDownPopUpContentManager();
			collectionModePicker.dataProvider = collectionModestList;
			var selectedModeIndex:int;
			if (collectionMode == "Host")
				selectedModeIndex = 0;
			else if (collectionMode == "Follower")
				selectedModeIndex = 1;
			collectionModePicker.selectedIndex = selectedModeIndex;
			collectionModePicker.addEventListener(starling.events.Event.CHANGE, onCollectionModeChanged);
			
			//Follower Service Picker List
			followerServicePicker = LayoutFactory.createPickerList();
			
			/* Follower Service Picker Data */
			var followerServicesLabelsList:Array = ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','follower_services_list').split(",");
			var followerServicestList:ArrayCollection = new ArrayCollection();
			for (i = 0; i < followerServicesLabelsList.length; i++) 
			{
				followerServicestList.push({label: StringUtil.trim(followerServicesLabelsList[i]), id: i});
			}
			followerServicesLabelsList.length = 0;
			followerServicesLabelsList = null;
			followerServicePicker.labelField = "label";
			followerServicePicker.popUpContentManager = new DropDownPopUpContentManager();
			followerServicePicker.dataProvider = followerServicestList;
			var selectedFollowerServiceIndex:int;
			if (followerService == "Dexcom")
				selectedFollowerServiceIndex = 0
			else if (followerService == "Nightscout")
				selectedFollowerServiceIndex = 1;
			
			followerServicePicker.selectedIndex = selectedFollowerServiceIndex;
			followerServicePicker.addEventListener(starling.events.Event.CHANGE, onFollowerServiceChanged);
			
			/**
			 * Nightscout
			 */
			//Nightscout URL
			nightscoutURLInput = LayoutFactory.createTextInput(false, false, Constants.isPortrait ? 140 : 240, HorizontalAlign.RIGHT, false, false, true);
			if (DeviceInfo.isTablet()) nightscoutURLInput.width += 100;
			nightscoutURLInput.fontStyles.size = 10;
			nightscoutURLInput.text = followNSURL;
			nightscoutURLInput.addEventListener(starling.events.Event.CHANGE, onSettingsChanged);
			
			//Nightscout Offset Stepper
			nightscoutOffsetStepper = LayoutFactory.createNumericStepper(-10000, 10000, nightscoutOffset, 5); 
			nightscoutOffsetStepper.addEventListener(starling.events.Event.CHANGE, onSettingsChanged);
			
			//API Secret
			nightscoutAPISecretTextInput = LayoutFactory.createTextInput(true, false, Constants.isPortrait ? 140 : 240, HorizontalAlign.RIGHT);
			nightscoutAPISecretTextInput.text = nightscoutAPISecretValue;
			if (DeviceInfo.isTablet()) nightscoutAPISecretTextInput.width += 100;
			nightscoutAPISecretTextInput.addEventListener(starling.events.Event.CHANGE, onSettingsChanged);
			
			//NS Login
			nsLogin = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','login_button_label'))
			nsLogin.addEventListener(starling.events.Event.TRIGGERED, onNightscoutLogin);
			
			//API Secret Description
			nightscoutAPIDescription = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','api_secret_description'), HorizontalAlign.JUSTIFY);
			nightscoutAPIDescription.wordWrap = true;
			nightscoutAPIDescription.width = width;
			nightscoutAPIDescription.paddingTop = nightscoutAPIDescription.paddingBottom = 10;
			
			/**
			 * Dexcom Share
			 */
			//Username
			dsUsername = LayoutFactory.createTextInput(false, false, Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr ? 120 : 140, HorizontalAlign.RIGHT);
			if (!Constants.isPortrait) dsUsername.width += 100;
			if (DeviceInfo.isTablet()) dsUsername.width += 100;
			dsUsername.text = dsUsernameValue;
			dsUsername.addEventListener(starling.events.Event.CHANGE, onSettingsChanged);
			
			//Password
			dsPassword = LayoutFactory.createTextInput(true, false, Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr ? 120 : 140, HorizontalAlign.RIGHT);
			if (!Constants.isPortrait) dsPassword.width += 100;
			if (DeviceInfo.isTablet()) dsPassword.width += 100;
			dsPassword.text = dsPasswordValue;
			dsPassword.addEventListener(starling.events.Event.CHANGE, onSettingsChanged);
			
			//Server
			dsServer = LayoutFactory.createPickerList();
			
			//Temp Data Object
			var selectedServerIndex:uint = 0;
			var serversLabelsList:Array = ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','dexcom_share_server_name_list').split(",");
			var serversCodeList:Array = ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','dexcom_share_server_code_list').split(",");
			var dsServerList:ArrayCollection = new ArrayCollection();
			var dataLength:int = serversLabelsList.length;
			for (i = 0; i < dataLength; i++) 
			{
				dsServerList.push({ label: StringUtil.trim(serversLabelsList[i]), code: StringUtil.trim(serversCodeList[i]) });
				if (dsServerCodeValue == StringUtil.trim(serversCodeList[i]))
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
			
			//DS Login
			dsLogin = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','login_button_label'))
			dsLogin.addEventListener(starling.events.Event.TRIGGERED, onDexcomShareLogin);
			
			//QR Code Scanner
			qrCodeScannerButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','scan_qr_code_button_label'));
			qrCodeScannerButton.addEventListener(starling.events.Event.TRIGGERED, onScanQRCode);
			
			refreshContent();
		}
		
		private function refreshContent():void
		{
			var data:Array = [];
			data.push( { label: ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','mode_label'), accessory: collectionModePicker } );
			if (collectionMode == "Follower")
			{
				data.push( { label: ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','follower_service_label'), accessory: followerServicePicker } );
				
				if (followerService == "Nightscout")
				{
					data.push( { label: ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','follower_ns_url'), accessory: nightscoutURLInput } );
					data.push( { label: ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','time_offset'), accessory: nightscoutOffsetStepper } );
					data.push( { label: ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','api_secret'), accessory: nightscoutAPISecretTextInput } );
					data.push( { label: "", accessory: nsLogin } );
					data.push( { label:"", accessory: nightscoutAPIDescription } );
				}
				else if (followerService == "Dexcom")
				{
					data.push( { label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','dexcom_share_username_label'), accessory: dsUsername } );
					data.push( { label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','dexcom_share_password_label'), accessory: dsPassword } );
					data.push( { label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','dexcom_share_server_label'), accessory: dsServer } );
					data.push( { label: "", accessory: dsLogin } );
				}
			}
			data.push( { label: "", accessory: qrCodeScannerButton } );
			
			dataProvider = new ArrayCollection(data);
		}
		
		public function save():void
		{
			//Update Database
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_MODE) != collectionMode)
			{
				//Reset Nightscout eTag to force refresh
				NetworkConnector.nightscoutTreatmentsLastModifiedHeader = "";
				TreatmentsManager.nightscoutTreatmentsLastModifiedHeader = "";
				NightscoutService.treatmentsAPIServerResponse = "";
					
				//Update Database
				if (collectionMode == "Follower")
					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_PERIPHERAL_TYPE, "Follow");
				else if (collectionMode == "Host")
				{
					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_PERIPHERAL_TYPE, "");
					
					//Force fetching readings and treatments from database for master.
					ModelLocator.getMasterReadings();
					TreatmentsManager.fetchAllTreatmentsFromDatabase();
				}
				
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_MODE, collectionMode);
			}
			
			//URL Validation
			if (followNSURL.substr(-1) == "/")
			{
				followNSURL = followNSURL.slice(0, -1);
				nightscoutURLInput.text = followNSURL;
			}
			
			var apiSecretToSave:String = nightscoutAPISecretValue != "" ? Cryptography.encryptStringLight(Keys.STRENGTH_256_BIT, String(nightscoutAPISecretValue)) : "";
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_API_SECRET) != apiSecretToSave)
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_API_SECRET, apiSecretToSave);
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_URL) != followNSURL)
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_URL, followNSURL);
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_OFFSET) != String(nightscoutOffset))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_OFFSET, String(nightscoutOffset));
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FOLLOWER_MODE) != String(followerService))
			{
				NightscoutService.treatmentsAPIServerResponse = "";
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_FOLLOWER_MODE, String(followerService));
			}
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_DS_SERVER) != String(dsServerCodeValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_DS_SERVER, String(dsServerCodeValue));
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_DS_USERNAME) != String(dsUsernameValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_DS_USERNAME, String(dsUsernameValue));
			
			var dsPasswordToSave:String = Cryptography.encryptStringLight(Keys.STRENGTH_256_BIT, String(dsPasswordValue));
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_DS_PASSWORD) != dsPasswordToSave)
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_DS_PASSWORD, dsPasswordToSave);
			
			//Refresh main menu. Menu items are different for hosts and followers
			AppInterface.instance.menu.refreshContent();
			
			needsSave = false;
		}
		
		/**
		 * Event Listeners
		 */
		private function onCollectionModeChanged(e:starling.events.Event):void
		{
			//Update internal variables
			if (collectionModePicker.selectedIndex == 0)
				collectionMode = "Host";
			else if (collectionModePicker.selectedIndex == 1)
				collectionMode = "Follower";
			
			needsSave = true;
			
			refreshContent();
		}
		
		private function onFollowerServiceChanged(e:starling.events.Event):void
		{
			//Update internal variables
			if (followerServicePicker.selectedIndex == 0)
				followerService = "Dexcom";
			else if (followerServicePicker.selectedIndex == 1)
				followerService = "Nightscout";
			
			needsSave = true;
			
			refreshContent();
		}
		
		private function onSettingsChanged(e:starling.events.Event):void
		{
			followNSURL = nightscoutURLInput.text.replace(" ", "");
			nightscoutOffset = nightscoutOffsetStepper.value;
			nightscoutAPISecretValue = nightscoutAPISecretTextInput.text.replace(" ", "");
			nsLogin.isEnabled = nightscoutAPISecretValue.length == 0 ? false : true;
			dsUsernameValue = dsUsername.text;
			dsPasswordValue = dsPassword.text;
			dsServerCodeValue = dsServer != null && dsServer.selectedItem != null && dsServer.selectedItem.code != null ? dsServer.selectedItem.code : "us";
			
			needsSave = true;
		}
		
		private function onNightscoutLogin(event:starling.events.Event):void
		{
			//Workaround so the NightscoutService doesn't test credentials twice
			NightscoutService.ignoreSettingsChanged = true;
			
			//Save values to database
			save();
			
			//Test Credentials
			NightscoutService.testNightscoutCredentialsFollower();
			NightscoutService.ignoreSettingsChanged = false;
			
			//Clear URL so it forces a save again and restart service
			CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_URL, "");
			needsSave = true;
		}
		
		private function onDexcomShareLogin(event:starling.events.Event):void
		{
			//Workaround for duplicate checking
			DexcomShareService.ignoreSettingsChanged = true;
			
			//Save values to database
			save();
			
			//Test Credentials
			DexcomShareService.testDexcomShareCredentials(true, true);
		}
		
		override protected function onStarlingResize(event:ResizeEvent):void 
		{
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
			
			if (followerService == "Nightscout")
			{
				if (nightscoutURLInput != null)
				{
					nightscoutURLInput.width = Constants.isPortrait ? 140 : 240;
					if (DeviceInfo.isTablet()) nightscoutURLInput.width += 100;
				}
				
				if (nightscoutAPISecretTextInput != null)
				{
					nightscoutAPISecretTextInput.width = Constants.isPortrait ? 140 : 240;
					if (DeviceInfo.isTablet()) nightscoutAPISecretTextInput.width += 100;
				}
				
				if (nightscoutAPIDescription != null)
				{
					if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr && !Constants.isPortrait)
						nightscoutAPIDescription.width = width - (Constants.currentOrientation == StageOrientation.ROTATED_RIGHT ? 30 : 40);
					else
						nightscoutAPIDescription.width = width;
				}
			}
			else if (followerService == "Dexcom")
			{
				if (dsUsername != null)
				{
					dsUsername.width = Constants.isPortrait ? 140 : 240;
					if (DeviceInfo.isTablet()) dsUsername.width += 100;
				}
				
				if (dsPassword != null)
				{
					dsPassword.width = Constants.isPortrait ? 140 : 240;
					if (DeviceInfo.isTablet()) dsPassword.width += 100;
				}
			}
			
			setupRenderFactory();
		}
		
		/**
		 * QR Code 
		 */
		private function onScanQRCode(e:starling.events.Event):void
		{
			//Validation
			if (!NetworkInfo.networkInfo.isReachable())
			{
				AlertManager.showSimpleAlert
					(
						ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
						ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','no_network_connection')
					);
				
				return;
			}
			
			try
			{
				if (Scanner.isSupported)
				{
					Scanner.service.addEventListener( AuthorisationEvent.CHANGED, onCameraAuthorization );
					switch (Scanner.service.authorisationStatus())
					{
						case AuthorisationStatus.NOT_DETERMINED:
							
						case AuthorisationStatus.SHOULD_EXPLAIN:
							Scanner.service.requestAccess();
							return;
							
						case AuthorisationStatus.DENIED:
							AlertManager.showSimpleAlert
							(
								ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
								ModelLocator.resourceManagerInstance.getString('globaltranslations','camera_access_denied')
							);
							
							return;
							
						case AuthorisationStatus.UNKNOWN:
							AlertManager.showSimpleAlert
							(
								ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
								ModelLocator.resourceManagerInstance.getString('globaltranslations','camera_access_unknow_error')
							);
							
							return;
							
						case AuthorisationStatus.RESTRICTED:
							AlertManager.showSimpleAlert
							(
								ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
								ModelLocator.resourceManagerInstance.getString('globaltranslations','camera_access_restricted')
							);
							
							return;
							
						case AuthorisationStatus.AUTHORISED:
							scanFollowerSettingsQRCode();
							break;						
					}
				}
			}
			catch (e:Error)
			{
				AlertManager.showSimpleAlert
					(
						ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
						ModelLocator.resourceManagerInstance.getString('globaltranslations','error_activating_scanner') + " " + e
					);
			}
		}
		
		private function onCameraAuthorization( event:AuthorisationEvent ):void
		{
			switch (event.status)
			{
				case AuthorisationStatus.SHOULD_EXPLAIN:
					break;
				
				case AuthorisationStatus.AUTHORISED:
					scanFollowerSettingsQRCode();
					break;
				
				case AuthorisationStatus.RESTRICTED:
					AlertManager.showSimpleAlert
					(
						ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
						ModelLocator.resourceManagerInstance.getString('globaltranslations','camera_access_restricted')
					);
					
					return;
					
				case AuthorisationStatus.DENIED:
					AlertManager.showSimpleAlert
					(
						ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
						ModelLocator.resourceManagerInstance.getString('globaltranslations','camera_access_denied')
					);
					
					return;
			}
		}
		
		private function scanFollowerSettingsQRCode():void
		{
			Scanner.service.addEventListener( ScannerEvent.CODE_FOUND, onQRCodeFound );
			Scanner.service.addEventListener( ScannerEvent.CANCELLED, onScanCanceled );
			
			var options:ScannerOptions = new ScannerOptions();
			options.camera = ScannerOptions.CAMERA_REAR;
			options.torchMode = ScannerOptions.TORCH_AUTO;
			options.cancelLabel = ModelLocator.resourceManagerInstance.getString('globaltranslations',"cancel_button_label").toUpperCase();
			options.colour = 0x0086FF;
			options.textColour = 0xEEEEEE;
			options.singleResult = true;
			options.symbologies = [Symbology.QRCODE];
			
			Scanner.service.startScan( options );
		}
		
		private function onQRCodeFound( event:ScannerEvent ):void
		{
			//Remove scanner events
			Scanner.service.removeEventListener( ScannerEvent.CODE_FOUND, onQRCodeFound );
			Scanner.service.removeEventListener( ScannerEvent.CANCELLED, onScanCanceled );
			
			//Force starling to render after context being lost by the camera overlay.
			recoverFromContextLost();
			
			//Get barcode
			var qrCode:String = event.data != null ? String(event.data) : "";
			
			//Call corresponding API
			if (qrCode != null && qrCode != "")
			{
				try
				{
					var urlDecrypted:String = Cryptography.decryptStringStrong(Keys.STRENGTH_256_BIT, qrCode);
					
					if (urlDecrypted.indexOf("https://snippets.glot.io") != -1)
					{
						//Get Settings
						NetworkConnector.createGlotConnector(urlDecrypted, null, URLRequestMethod.GET, null, null, onEncyptedSettingsReceived, onSettingsReceivedError);
					}
					else
					{
						AlertManager.showSimpleAlert
							(
								ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
								ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','invalid_qr_code')
							);
					}
				} 
				catch(error:Error) 
				{
					AlertManager.showSimpleAlert
						(
							ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
							ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','invalid_qr_code')
						);
				}
			}
		}
		
		private function onEncyptedSettingsReceived(e:flash.events.Event):void
		{
			//Get loader
			var loader:URLLoader = e.currentTarget as URLLoader;
			
			if (loader == null || loader.data == null)
			{
				AlertManager.showSimpleAlert
					(
						ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
						ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','error_restoring_settings')
					);
				
				return;
			}
			
			//Get response
			var response:String = loader.data;
			
			//Dispose loader
			loader.removeEventListener(flash.events.Event.COMPLETE, onEncyptedSettingsReceived);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onSettingsReceivedError);
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
						ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','parse_settings_error')
					);
				
				return;
			}
			
			if (responseJSON != null && responseJSON.files != null && responseJSON.files is Array && responseJSON.files[0] != null && responseJSON.files[0].content != null)
			{
				var settingsEncrypted:String = String(responseJSON.files[0].content);
				var settingsDecrypted:String = Cryptography.decryptStringStrong(Keys.STRENGTH_256_BIT, settingsEncrypted);
				
				try
				{
					var followerSettingsJSON:Object = JSON.parse(settingsDecrypted);
				} 
				catch(error:Error) 
				{
					AlertManager.showSimpleAlert
						(
							ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
							ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','error_restoring_settings')
						);
					
					return;
				}
				
				if (followerSettingsJSON != null && followerSettingsJSON.followerService != null && collectionModePicker != null && followerServicePicker != null && dsUsername != null && dsPassword != null && dsServer != null)
				{
					if (followerSettingsJSON.followerService == "Dexcom")
					{
						if (followerSettingsJSON.username != null 
							&&
							followerSettingsJSON.password != null 
							&&
							followerSettingsJSON.server != null 
							&&
							followerSettingsJSON.urgentHigh != null 
							&&
							followerSettingsJSON.high != null 
							&&
							followerSettingsJSON.low != null 
							&&
							followerSettingsJSON.urgentLow != null 
						)
						{
							collectionMode = "Follower";
							collectionModePicker.selectedIndex = 1;
							followerService = "Dexcom";
							followerServicePicker.selectedIndex = 0;
							dsUsernameValue = followerSettingsJSON.username;
							dsUsername.text = dsUsernameValue;
							dsPasswordValue = followerSettingsJSON.password;
							dsPassword.text = dsPasswordValue;
							dsServerCodeValue = followerSettingsJSON.server;
							dsServer.selectedIndex = dsServerCodeValue == "us" ? 0 : 1;
							
							CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_URGENT_HIGH_MARK, String(followerSettingsJSON.urgentHigh));
							CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_HIGH_MARK, String(followerSettingsJSON.high));
							CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_LOW_MARK, String(followerSettingsJSON.low));
							CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_URGENT_LOW_MARK, String(followerSettingsJSON.urgentLow));
							
							needsSave = true;
							
							refreshContent();
							
							AlertManager.showSimpleAlert
							(
								ModelLocator.resourceManagerInstance.getString('globaltranslations','success_alert_title'),
								ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','settings_imported_successfully')
							);
						}
						else
						{
							AlertManager.showSimpleAlert
							(
								ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
								ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','invalid_qr_code')
							);
						}
					}
					else if (followerSettingsJSON.followerService == "Nightscout")
					{
						if (followerSettingsJSON.url != null 
							&&
							followerSettingsJSON.urgentHigh != null 
							&&
							followerSettingsJSON.high != null 
							&&
							followerSettingsJSON.low != null 
							&&
							followerSettingsJSON.urgentLow != null 
						)
						{
							collectionMode = "Follower";
							collectionModePicker.selectedIndex = 1;
							followerService = "Nightscout";
							followerServicePicker.selectedIndex = 1;
							followNSURL = followerSettingsJSON.url;
							nightscoutURLInput.text = followNSURL;
							nightscoutAPISecretValue = followerSettingsJSON.apiSecret != null ? followerSettingsJSON.apiSecret : "";
							nightscoutAPISecretTextInput.text = nightscoutAPISecretValue;
							
							CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_URGENT_HIGH_MARK, String(followerSettingsJSON.urgentHigh));
							CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_HIGH_MARK, String(followerSettingsJSON.high));
							CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_LOW_MARK, String(followerSettingsJSON.low));
							CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_URGENT_LOW_MARK, String(followerSettingsJSON.urgentLow));
							
							var i:int;
							
							//Master's Profile
							if (followerSettingsJSON.insulins != null && followerSettingsJSON.insulins is Array)
							{
								var insulinsArray:Array = followerSettingsJSON.insulins;
								var insulinsLength:uint = insulinsArray.length;
								
								try
								{
									for (i = 0; i < insulinsLength; i++) 
									{
										var insulinAsObject:Object = insulinsArray[i] as Object;
										if (insulinAsObject.ID != null &&
											insulinAsObject.name != null &&
											insulinAsObject.dia != null &&
											insulinAsObject.type != null &&
											insulinAsObject.isDefault != null &&
											insulinAsObject.isHidden != null
										)
										{
											ProfileManager.addInsulin
											(
												insulinAsObject.name,
												insulinAsObject.dia, 
												insulinAsObject.type, 
												insulinAsObject.isDefault, 
												insulinAsObject.ID, 
												true, 
												insulinAsObject.isHidden,
												insulinAsObject.curve != null ? insulinAsObject.curve : "bilinear",
												insulinAsObject.peak != null ? insulinAsObject.peak : 75,
												true
											);
										}
									}
								} 
								catch(error:Error) {}
							}
							
							if (followerSettingsJSON.profiles != null && followerSettingsJSON.profiles is Array)
							{
								var profilesArray:Array = followerSettingsJSON.profiles;
								var profilesLength:uint = profilesArray.length;
								
								try
								{
									for (i = 0; i < profilesLength; i++) 
									{
										var profileAsObject:Object = profilesArray[i] as Object;
										if (profileAsObject.ID != null &&
											profileAsObject.time != null &&
											profileAsObject.name != null &&
											profileAsObject.insulinToCarbRatios != null &&
											profileAsObject.insulinSensitivityFactors != null &&
											profileAsObject.carbsAbsorptionRate != null &&
											profileAsObject.basalRates != null &&
											profileAsObject.targetGlucoseRates != null &&
											profileAsObject.trendCorrections != null &&
											profileAsObject.timestamp != null
										)
										{
											var profile:Profile = new Profile
												(
													profileAsObject.ID,
													profileAsObject.time,
													profileAsObject.name,
													profileAsObject.insulinToCarbRatios,
													profileAsObject.insulinSensitivityFactors,
													profileAsObject.carbsAbsorptionRate,
													profileAsObject.basalRates,
													profileAsObject.targetGlucoseRates,
													profileAsObject.trendCorrections,
													profileAsObject.timestamp
												);
												
											ProfileManager.insertProfile(profile, true);
										}
									}
								} 
								catch(error:Error) {}
							}
							
							if (followerSettingsJSON.algorithmIOBCOB != null)
							{
								CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_DEFAULT_IOB_COB_ALGORITHM, String(followerSettingsJSON.algorithmIOBCOB));
							}
							
							if (followerSettingsJSON.fastAbsortionCarbTime != null)
							{
								CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_CARB_FAST_ABSORTION_TIME, String(followerSettingsJSON.fastAbsortionCarbTime));
							}
							
							if (followerSettingsJSON.mediumAbsortionCarbTime != null)
							{
								CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_CARB_MEDIUM_ABSORTION_TIME, String(followerSettingsJSON.mediumAbsortionCarbTime));
							}
							
							if (followerSettingsJSON.slowAbsortionCarbTime != null)
							{
								CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_CARB_SLOW_ABSORTION_TIME, String(followerSettingsJSON.slowAbsortionCarbTime));
							}
							
							if (followerSettingsJSON.defaultAbsortionCarbTime != null)
							{
								CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_DEFAULT_CARB_ABSORTION_TIME, String(followerSettingsJSON.defaultAbsortionCarbTime));
							}
							
							if (followerSettingsJSON.userType != null)
							{
								CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_USER_TYPE_PUMP_OR_MDI, String(followerSettingsJSON.userType));
							}
							
							if (followerSettingsJSON.isAPSUser != null)
							{
								CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_LOOP_OPENAPS_USER_ENABLED, String(followerSettingsJSON.isAPSUser));
							}
							
							needsSave = true;
							
							refreshContent();
							
							AlertManager.showSimpleAlert
							(
								ModelLocator.resourceManagerInstance.getString('globaltranslations','success_alert_title'),
								ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','settings_imported_successfully')
							);
						}
						else
						{
							AlertManager.showSimpleAlert
								(
									ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
									ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','invalid_qr_code')
								);
						}
					}
					else
					{
						AlertManager.showSimpleAlert
						(
							ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
							ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','invalid_qr_code')
						);
					}
				}
				else
				{
					AlertManager.showSimpleAlert
					(
						ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
						ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','invalid_qr_code')
					);
				}
			}
			else
			{
				AlertManager.showSimpleAlert
				(
					ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
					ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','error_restoring_settings')
				);
			}
		}
		
		private function onSettingsReceivedError(error:Error):void
		{
			AlertManager.showSimpleAlert
			(
				ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
				ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','error_restoring_settings')
			);
		}
		
		private function onScanCanceled( event:ScannerEvent ):void
		{
			//Remove scanner events
			Scanner.service.removeEventListener( ScannerEvent.CODE_FOUND, onQRCodeFound );
			Scanner.service.removeEventListener( ScannerEvent.CANCELLED, onScanCanceled );
			
			//Force starling to render after context being lost by the camera overlay.
			recoverFromContextLost();
		}
		
		private function recoverFromContextLost():void
		{
			renderTimoutID1 = setTimeout( function():void {
				SystemUtil.executeWhenApplicationIsActive(Starling.current.start);
			}, 100 );
			
			renderTimoutID2 = setTimeout( function():void {
				SystemUtil.executeWhenApplicationIsActive(Starling.current.start);
			}, 500 );
			
			renderTimoutID3 = setTimeout( function():void {
				SystemUtil.executeWhenApplicationIsActive(Starling.current.start);
			}, 1000 );
		}
		
		/**
		 * Utility
		 */
		override protected function draw():void
		{
			super.draw();
			
			if ((layout as VerticalLayout) != null)
				(layout as VerticalLayout).hasVariableItemDimensions = true;
			
			if (nsLogin != null && nightscoutAPISecretTextInput != null && followerService == "Nightscout")
				nsLogin.isEnabled = nightscoutAPISecretTextInput.text.length == 0 ? false : true;
		}
		
		override public function dispose():void
		{
			Scanner.service.removeEventListener( AuthorisationEvent.CHANGED, onCameraAuthorization );
			Scanner.service.removeEventListener( ScannerEvent.CODE_FOUND, onQRCodeFound );
			Scanner.service.removeEventListener( ScannerEvent.CANCELLED, onScanCanceled );
			
			if (collectionModePicker != null)
			{
				collectionModePicker.removeEventListener(starling.events.Event.CHANGE, onCollectionModeChanged);
				collectionModePicker.dispose();
				collectionModePicker = null;
			}
			
			if (nightscoutURLInput != null)
			{
				nightscoutURLInput.removeEventListener(starling.events.Event.CHANGE, onSettingsChanged);
				nightscoutURLInput.dispose();
				nightscoutURLInput = null;
			}
			
			if (nightscoutOffsetStepper != null)
			{
				nightscoutOffsetStepper.removeEventListener(starling.events.Event.CHANGE, onSettingsChanged);
				nightscoutOffsetStepper.dispose();
				nightscoutOffsetStepper = null;
			}
			
			if (nightscoutAPISecretTextInput != null)
			{
				nightscoutAPISecretTextInput.removeEventListener(starling.events.Event.CHANGE, onSettingsChanged);
				nightscoutAPISecretTextInput.dispose();
				nightscoutAPISecretTextInput = null;
			}
			
			if (nsLogin != null)
			{
				nsLogin.removeEventListener(starling.events.Event.TRIGGERED, onNightscoutLogin);
				nsLogin.dispose();
				nsLogin = null;
			}
			
			if (nightscoutAPIDescription != null)
			{
				nightscoutAPIDescription.dispose();
				nightscoutAPIDescription = null;
			}
			
			if (dsUsername != null)
			{
				dsUsername.removeEventListener(starling.events.Event.CHANGE, onSettingsChanged);
				dsUsername.dispose();
				dsUsername = null;
			}
			
			if (dsPassword != null)
			{
				dsPassword.removeEventListener(starling.events.Event.CHANGE, onSettingsChanged);
				dsPassword.dispose();
				dsPassword = null;
			}
			
			if (dsServer != null)
			{
				dsServer.removeEventListener(starling.events.Event.CHANGE, onSettingsChanged);
				dsServer.dispose();
				dsServer = null;
			}
			
			if (followerServicePicker != null)
			{
				followerServicePicker.removeEventListener(starling.events.Event.CHANGE, onFollowerServiceChanged);
				followerServicePicker.dispose();
				followerServicePicker = null;
			}
			
			if (dsLogin != null)
			{
				dsLogin.removeEventListener(starling.events.Event.TRIGGERED, onDexcomShareLogin);
				dsLogin.dispose();
				dsLogin = null;
			}
			
			if (qrCodeScannerButton != null)
			{
				qrCodeScannerButton.removeEventListener(starling.events.Event.TRIGGERED, onScanQRCode);
				qrCodeScannerButton.dispose();
				qrCodeScannerButton = null;
			}
			
			super.dispose();
		}
	}
}