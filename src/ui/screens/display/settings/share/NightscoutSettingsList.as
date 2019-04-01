package ui.screens.display.settings.share
{
	import com.adobe.images.PNGEncoder;
	
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequestMethod;
	
	import cryptography.Keys;
	
	import database.CommonSettings;
	
	import feathers.controls.Alert;
	import feathers.controls.Button;
	import feathers.controls.Check;
	import feathers.controls.Label;
	import feathers.controls.LayoutGroup;
	import feathers.controls.TextInput;
	import feathers.controls.ToggleSwitch;
	import feathers.data.ArrayCollection;
	import feathers.events.FeathersEventType;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalAlign;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import network.NetworkConnector;
	
	import org.qrcode.QRCode;
	
	import services.AlarmService;
	import services.NightscoutService;
	
	import starling.display.Image;
	import starling.events.Event;
	import starling.events.ResizeEvent;
	import starling.textures.Texture;
	import starling.utils.SystemUtil;
	
	import treatments.Insulin;
	import treatments.Profile;
	import treatments.ProfileManager;
	
	import ui.popups.AlertManager;
	import ui.popups.EmailFileSender;
	import ui.screens.display.LayoutFactory;
	import ui.screens.display.SpikeList;
	
	import utils.Constants;
	import utils.Cryptography;
	import utils.DeviceInfo;
	
	[ResourceBundle("sharesettingsscreen")]
	[ResourceBundle("globaltranslations")]

	public class NightscoutSettingsList extends SpikeList 
	{
		/* Display Objects */
		private var nsToggle:ToggleSwitch;
		private var nsURL:TextInput;
		private var nsAPISecret:TextInput;
		private var nsLogin:Button;
		private var batteryUploader:Check;
		private var wifiOnlyUploaderCheck:Check;
		private var ocUploader:Check;
		private var predictionsUploader:Check;
		private var inviteFollowersButton:Button;
		private var qrCodeBitmapData:BitmapData;
		private var qrCodeContainer:LayoutGroup;
		private var qrCodeImage:Image;
		private var qrCodeExplanation:Label;
		private var qrCodePopup:Alert;
		
		/* Properties */
		public var needsSave:Boolean = false;
		private var isNSEnabled:Boolean;
		private var selectedURL:String;
		private var selectedAPISecret:String;
		private var isBatteryUploaderEnabled:Boolean;
		private var isWifiOnlyUploaderEnabled:Boolean;
		private var isUploadOptimalCalibrationsEnabled:Boolean;
		private var isUploadPredictionsEnabled:Boolean;
		
		public function NightscoutSettingsList()
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
			/* Get data from database */
			isNSEnabled = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_ON) == "true";
			selectedURL = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_AZURE_WEBSITE_NAME);
			selectedAPISecret = Cryptography.decryptStringLight(Keys.STRENGTH_256_BIT, CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_API_SECRET));
			isBatteryUploaderEnabled = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_BATTERY_UPLOADER_ON) == "true";
			isWifiOnlyUploaderEnabled = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_WIFI_ONLY_UPLOADER_ON) == "true";
			isUploadOptimalCalibrationsEnabled = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_UPLOAD_OPTIMAL_CALIBRATION_TO_NS_ON) == "true";
			isUploadPredictionsEnabled = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_PREDICTIONS_UPLOADER_ON) == "true";
		}
		
		private function setupContent():void
		{
			//On/Off Toggle
			nsToggle = LayoutFactory.createToggleSwitch(isNSEnabled);
			nsToggle.addEventListener( starling.events.Event.CHANGE, onNightscoutOnOff );
			
			//URL
			nsURL = LayoutFactory.createTextInput(false, false, Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr ? 190 : 220, HorizontalAlign.RIGHT, false, false, true);
			if (!Constants.isPortrait) nsURL.width += 100;
			if (DeviceInfo.isTablet()) nsURL.width += 100;
			nsURL.text = selectedURL;
			nsURL.prompt = "yoursite.example.com";
			nsURL.addEventListener( FeathersEventType.ENTER, onTextInputEnter );
			nsURL.addEventListener(starling.events.Event.CHANGE, onSettingsChanged);
			
			//API Secret
			nsAPISecret = LayoutFactory.createTextInput(true, false, Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr ? 120 : 140, HorizontalAlign.RIGHT);
			if (!Constants.isPortrait) nsAPISecret.width += 100;
			if (DeviceInfo.isTablet()) nsAPISecret.width += 100;
			nsAPISecret.text = selectedAPISecret;
			nsAPISecret.addEventListener( FeathersEventType.ENTER, onTextInputEnter );
			nsAPISecret.addEventListener(starling.events.Event.CHANGE, onSettingsChanged);
			
			//Login
			nsLogin = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','login_button_label'));
			nsLogin.pivotX = -3;
			nsLogin.addEventListener(starling.events.Event.TRIGGERED, onNightscoutLogin);
			
			//Battery Uploader
			batteryUploader = LayoutFactory.createCheckMark(isBatteryUploaderEnabled);
			batteryUploader.addEventListener(starling.events.Event.CHANGE, onSettingsChanged);
			
			//Predictions Uploader
			predictionsUploader = LayoutFactory.createCheckMark(isUploadPredictionsEnabled);
			predictionsUploader.addEventListener(starling.events.Event.CHANGE, onSettingsChanged);
			
			//Optimal Calibration Uploader
			ocUploader = LayoutFactory.createCheckMark(isUploadOptimalCalibrationsEnabled);
			ocUploader.addEventListener(starling.events.Event.CHANGE, onSettingsChanged);
			
			//Wi-Fi Only Sync
			wifiOnlyUploaderCheck = LayoutFactory.createCheckMark(isWifiOnlyUploaderEnabled);
			wifiOnlyUploaderCheck.addEventListener(starling.events.Event.CHANGE, onSettingsChanged);
			
			//Invite Followers
			inviteFollowersButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','invite_followers_button_label'));
			inviteFollowersButton.pivotX = -3;
			inviteFollowersButton.addEventListener(starling.events.Event.TRIGGERED, onInviteFollowers);
			
			//Define Nightscout Settings Data
			reloadNightscoutSettings(nsToggle.isSelected);
		}
		
		public function save():void
		{
			if (needsSave)
			{
				var needsCredentialRechek:Boolean = false;
				
				//URL Validation
				if (selectedURL.substr(-1) == "/")
				{
					selectedURL = selectedURL.slice(0, -1);
					nsURL.text = selectedURL;
				}
				
				//Nightscout
				var nsEnabledValue:String;
				
				if (isNSEnabled) nsEnabledValue = "true";
				else nsEnabledValue = "false";
				
				if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_ON) != nsEnabledValue)
					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_ON, nsEnabledValue);
				
				//API Secret
				var apiSecretToSave:String = Cryptography.encryptStringLight(Keys.STRENGTH_256_BIT, selectedAPISecret);
				if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_API_SECRET) != apiSecretToSave)
				{
					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_API_SECRET, apiSecretToSave);
					needsCredentialRechek = true;
				}
				
				//URL
				if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_AZURE_WEBSITE_NAME) != selectedURL)
				{
					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_AZURE_WEBSITE_NAME, selectedURL);
					needsCredentialRechek = true;
				}
				
				//Battery Uploader
				if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_BATTERY_UPLOADER_ON) != String(isBatteryUploaderEnabled))
					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_BATTERY_UPLOADER_ON, String(isBatteryUploaderEnabled));
				
				//Predictions Uploader
				if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_PREDICTIONS_UPLOADER_ON) != String(isUploadPredictionsEnabled))
					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_PREDICTIONS_UPLOADER_ON, String(isUploadPredictionsEnabled));
				
				//Optimal Calibration Uploader
				if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_UPLOAD_OPTIMAL_CALIBRATION_TO_NS_ON) != String(isUploadOptimalCalibrationsEnabled))
				{
					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_UPLOAD_OPTIMAL_CALIBRATION_TO_NS_ON, String(isUploadOptimalCalibrationsEnabled));
					
					if (isUploadOptimalCalibrationsEnabled)
						AlarmService.canUploadCalibrationToNightscout = true;
				}
				
				//Wi-Fi Only Uploader
				if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_WIFI_ONLY_UPLOADER_ON) != String(isWifiOnlyUploaderEnabled))
					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_WIFI_ONLY_UPLOADER_ON, String(isWifiOnlyUploaderEnabled));
				
				//Credentials Recheck
				if (needsCredentialRechek)
					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_URL_AND_API_SECRET_TESTED, "false");
				
				needsSave = false;
			}
		}
		
		private function onSettingsChanged():void
		{
			selectedAPISecret = nsAPISecret.text.replace(" ", "");
			nsURL.text = nsURL.text.replace(" ", "");
			selectedURL = nsURL.text.replace(" ", "");
			isBatteryUploaderEnabled = batteryUploader.isSelected;
			isWifiOnlyUploaderEnabled = wifiOnlyUploaderCheck.isSelected;
			isUploadOptimalCalibrationsEnabled = ocUploader.isSelected;
			isUploadPredictionsEnabled = predictionsUploader.isSelected;
			
			needsSave = true;
		}
		
		private function onNightscoutOnOff(event:starling.events.Event):void
		{
			isNSEnabled = nsToggle.isSelected;
			
			reloadNightscoutSettings(isNSEnabled);
			
			needsSave = true;
		}
		
		private function reloadNightscoutSettings(fullDisplay:Boolean):void
		{
			if(fullDisplay)
			{
				dataProvider = new ArrayCollection(
					[
						{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations','enabled_label'), accessory: nsToggle },
						{ label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','nightscout_url_label'), accessory: nsURL },
						{ label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','nightscout_api_label'), accessory: nsAPISecret },
						{ label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','nightscout_battery_upload_label'), accessory: batteryUploader },
						{ label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','nightscout_predictions_uploader'), accessory: predictionsUploader },
						{ label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','nightscout_optimal_calibration_uploader'), accessory: ocUploader },
						{ label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','wifi_only_sync_label'), accessory: wifiOnlyUploaderCheck },
						{ label: "", accessory: nsLogin },
						{ label: "", accessory: inviteFollowersButton },
					]);
			}
			else
			{
				dataProvider = new ArrayCollection(
					[
						{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations','enabled_label'), accessory: nsToggle },
					]);
			}
		}
		
		private function onTextInputEnter(event:starling.events.Event):void
		{
			//Clear focus to dismiss the keyboard
			nsURL.clearFocus();
			nsAPISecret.clearFocus();
		}
		
		private function onNightscoutLogin(event:starling.events.Event):void
		{
			//Workaround so the NightscoutService doesn't test credentials twice
			NightscoutService.ignoreSettingsChanged = true;
			
			//Save values to database
			save();
			
			//Test Credentials
			NightscoutService.testNightscoutCredentials(true);
			NightscoutService.ignoreSettingsChanged = false;
		}
		
		override protected function onStarlingResize(event:ResizeEvent):void 
		{
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
			
			if (nsURL != null)
			{
				SystemUtil.executeWhenApplicationIsActive( nsURL.clearFocus );
				nsURL.width = Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr ? 190 : 220;
				if (!Constants.isPortrait) nsURL.width += 100;
				if (DeviceInfo.isTablet()) nsURL.width += 100;
			}
			
			if (nsAPISecret != null)
			{
				SystemUtil.executeWhenApplicationIsActive( nsAPISecret.clearFocus );
				nsAPISecret.width = Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr ? 120 : 140;
				if (!Constants.isPortrait) nsAPISecret.width += 100;
				if (DeviceInfo.isTablet()) nsAPISecret.width += 100;
			}
			
			setupRenderFactory();
		}
		
		/**
		 * QR Code
		 */
		private function onInviteFollowers(e:starling.events.Event):void
		{
			if (!NightscoutService.serviceActive)
			{
				AlertManager.showSimpleAlert
				(
					ModelLocator.resourceManagerInstance.getString("globaltranslations","warning_alert_title"),
					ModelLocator.resourceManagerInstance.getString("sharesettingsscreen","needs_dexcom_login"),
					60,
					null,
					HorizontalAlign.CENTER
				);
				
				return;
			}
			
			var alertTreatments:Alert = AlertManager.showActionAlert
			(
				ModelLocator.resourceManagerInstance.getString("globaltranslations","info_alert_title"),
				ModelLocator.resourceManagerInstance.getString("sharesettingsscreen","nightscout_follower_popup_body"),
				Number.NaN,
				[
					{ label: ModelLocator.resourceManagerInstance.getString("globaltranslations","no_uppercase"), triggered: onNoTreatments },
					{ label: ModelLocator.resourceManagerInstance.getString("globaltranslations","yes_uppercase"), triggered: onYesTreatments }
				]
			);
			alertTreatments.buttonGroupProperties.horizontalAlign = HorizontalAlign.CENTER;
			
			var allowTreatments:Boolean = false;
			var includeProfile:Boolean = false;
			
			function onNoTreatments(e:starling.events.Event):void
			{
				allowTreatments = false;
				
				createQRCode();
			}
			
			function onYesTreatments(e:starling.events.Event):void
			{
				allowTreatments = true;
				
				var alertTreatments:Alert = AlertManager.showActionAlert
				(
					ModelLocator.resourceManagerInstance.getString("globaltranslations","info_alert_title"),
					ModelLocator.resourceManagerInstance.getString("sharesettingsscreen","share_profile_with_follower_label"),
					Number.NaN,
					[
						{ label: ModelLocator.resourceManagerInstance.getString("globaltranslations","no_uppercase"), triggered: onNoProfile },
						{ label: ModelLocator.resourceManagerInstance.getString("globaltranslations","yes_uppercase"), triggered: onYesProfile }
					]
				);
				alertTreatments.buttonGroupProperties.horizontalAlign = HorizontalAlign.CENTER;
				
				function onYesProfile(e:starling.events.Event):void
				{
					includeProfile = true;
					
					createQRCode();
				}
				
				function onNoProfile(e:starling.events.Event):void
				{
					includeProfile = false;
					
					createQRCode();
				}
			}
			
			function createQRCode():void
			{
				//Master settings object
				var masterSettings:Object = {};
				masterSettings.followerService = "Nightscout";
				masterSettings.url = selectedURL;
				if (allowTreatments)
				{
					masterSettings.apiSecret = selectedAPISecret;
				}
				masterSettings.urgentHigh = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_URGENT_HIGH_MARK));
				masterSettings.high = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_HIGH_MARK));
				masterSettings.low = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_LOW_MARK));
				masterSettings.urgentLow = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_URGENT_LOW_MARK));
				masterSettings.userType = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_USER_TYPE_PUMP_OR_MDI);
				masterSettings.isAPSUser = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_LOOP_OPENAPS_USER_ENABLED);
				
				if (includeProfile)
				{
					var i:int;
					var allInsulins:Array = [];
					var allProfiles:Array = [];
					
					for (i = 0; i < ProfileManager.insulinsList.length; i++) 
					{
						var insulin:Insulin = ProfileManager.insulinsList[i] as Insulin;
						
						if (!insulin.isHidden)
						{
							var insulinAsObject:Object = {};
							insulinAsObject.ID = insulin.ID;
							insulinAsObject.name = insulin.name;
							insulinAsObject.dia = insulin.dia;
							insulinAsObject.type = insulin.type;
							insulinAsObject.isDefault = insulin.isDefault;
							insulinAsObject.timestamp = insulin.timestamp;
							insulinAsObject.isHidden = insulin.isHidden;
							insulinAsObject.peak = insulin.peak;
							insulinAsObject.curve = insulin.curve;
							
							allInsulins.push(insulinAsObject);
						}
					}
					
					for (i = 0; i < ProfileManager.profilesList.length; i++) 
					{
						var profile:Profile = ProfileManager.profilesList[i] as Profile;
						
						var profileAsObject:Object = {};
						profileAsObject.ID = profile.ID;
						profileAsObject.time = profile.time;
						profileAsObject.name = profile.name;
						profileAsObject.insulinToCarbRatios = profile.insulinToCarbRatios;
						profileAsObject.insulinSensitivityFactors = profile.insulinSensitivityFactors;
						profileAsObject.carbsAbsorptionRate = profile.carbsAbsorptionRate;
						profileAsObject.basalRates = profile.basalRates;
						profileAsObject.targetGlucoseRates = profile.targetGlucoseRates;
						profileAsObject.trendCorrections = profile.trendCorrections;
						profileAsObject.timestamp = profile.timestamp;
						
						allProfiles.push(profileAsObject);
					}
					
					masterSettings.insulins = allInsulins;
					masterSettings.profiles = allProfiles;
					masterSettings.algorithmIOBCOB = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEFAULT_IOB_COB_ALGORITHM);
					masterSettings.fastAbsortionCarbTime = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CARB_FAST_ABSORTION_TIME));
					masterSettings.mediumAbsortionCarbTime = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CARB_MEDIUM_ABSORTION_TIME));
					masterSettings.slowAbsortionCarbTime = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CARB_SLOW_ABSORTION_TIME));
					masterSettings.defaultAbsortionCarbTime = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEFAULT_CARB_ABSORTION_TIME));
				}
				
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
									ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','nightscout_invitation_email_subject'),
									ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','follower_invitation_email_body'),
									"SpikeNightscoutQRCode.png",
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
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			EmailFileSender.instance.removeEventListener(starling.events.Event.COMPLETE, onFileSenderClosed);
			EmailFileSender.instance.removeEventListener(starling.events.Event.CANCEL, onFileSenderClosed);
			
			if(nsToggle != null)
			{
				nsToggle.removeEventListener( starling.events.Event.CHANGE, onNightscoutOnOff );
				nsToggle.dispose();
				nsToggle = null;
			}
			
			if(nsURL != null)
			{
				nsURL.removeEventListener( FeathersEventType.ENTER, onTextInputEnter );
				nsURL.removeEventListener(starling.events.Event.CHANGE, onSettingsChanged);
				nsURL.dispose();
				nsURL = null;
			}
			
			if(nsAPISecret != null)
			{
				nsAPISecret.removeEventListener( FeathersEventType.ENTER, onTextInputEnter );
				nsAPISecret.removeEventListener(starling.events.Event.CHANGE, onSettingsChanged);
				nsAPISecret.dispose();
				nsAPISecret = null;
			}
			
			if(nsLogin != null)
			{
				nsLogin.removeEventListener(starling.events.Event.TRIGGERED, onNightscoutLogin);
				nsLogin.dispose();
				nsLogin = null;
			}
			
			if(batteryUploader != null)
			{
				batteryUploader.removeEventListener(starling.events.Event.CHANGE, onSettingsChanged);
				batteryUploader.dispose();
				batteryUploader = null;
			}
			
			if(predictionsUploader != null)
			{
				predictionsUploader.removeEventListener(starling.events.Event.CHANGE, onSettingsChanged);
				predictionsUploader.dispose();
				predictionsUploader = null;
			}
			
			if(wifiOnlyUploaderCheck != null)
			{
				wifiOnlyUploaderCheck.removeEventListener(starling.events.Event.CHANGE, onSettingsChanged);
				wifiOnlyUploaderCheck.dispose();
				wifiOnlyUploaderCheck = null;
			}
			
			if(ocUploader != null)
			{
				ocUploader.removeEventListener(starling.events.Event.CHANGE, onSettingsChanged);
				ocUploader.dispose();
				ocUploader = null;
			}
			
			if(inviteFollowersButton != null)
			{
				inviteFollowersButton.removeEventListener(starling.events.Event.TRIGGERED, onInviteFollowers);
				inviteFollowersButton.dispose();
				inviteFollowersButton = null;
			}
			
			if(qrCodeExplanation != null)
			{
				qrCodeExplanation.removeFromParent();
				qrCodeExplanation.dispose();
				qrCodeExplanation = null;
			}
			
			if(qrCodeBitmapData != null)
			{
				qrCodeBitmapData.dispose();
				qrCodeBitmapData = null;
			}
			
			if(qrCodeImage != null)
			{
				qrCodeImage.removeFromParent();
				if (qrCodeImage.texture != null)
				{
					qrCodeImage.texture.dispose();
				}
				qrCodeImage.dispose();
				qrCodeImage = null;
			}
			
			if(qrCodeContainer != null)
			{
				qrCodeContainer.removeFromParent();
				qrCodeContainer.dispose();
				qrCodeContainer = null;
			}
			
			if(qrCodePopup != null)
			{
				qrCodePopup.removeFromParent();
				qrCodePopup.dispose();
				qrCodePopup = null;
			}
			
			super.dispose();
		}
	}
}