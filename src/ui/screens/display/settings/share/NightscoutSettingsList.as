package ui.screens.display.settings.share
{
	import cryptography.Keys;
	
	import database.CommonSettings;
	
	import feathers.controls.Button;
	import feathers.controls.Check;
	import feathers.controls.TextInput;
	import feathers.controls.ToggleSwitch;
	import feathers.data.ArrayCollection;
	import feathers.events.FeathersEventType;
	import feathers.layout.HorizontalAlign;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import services.AlarmService;
	import services.NightscoutService;
	
	import starling.events.Event;
	import starling.events.ResizeEvent;
	import starling.utils.SystemUtil;
	
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
			nsToggle.addEventListener( Event.CHANGE, onNightscoutOnOff );
			
			//URL
			nsURL = LayoutFactory.createTextInput(false, false, Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr ? 190 : 220, HorizontalAlign.RIGHT, false, false, true);
			if (!Constants.isPortrait) nsURL.width += 100;
			if (DeviceInfo.isTablet()) nsURL.width += 100;
			nsURL.text = selectedURL;
			nsURL.prompt = "yoursite.example.com";
			nsURL.addEventListener( FeathersEventType.ENTER, onTextInputEnter );
			nsURL.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//API Secret
			nsAPISecret = LayoutFactory.createTextInput(true, false, Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr ? 120 : 140, HorizontalAlign.RIGHT);
			if (!Constants.isPortrait) nsAPISecret.width += 100;
			if (DeviceInfo.isTablet()) nsAPISecret.width += 100;
			nsAPISecret.text = selectedAPISecret;
			nsAPISecret.addEventListener( FeathersEventType.ENTER, onTextInputEnter );
			nsAPISecret.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Login
			nsLogin = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','login_button_label'));
			nsLogin.pivotX = -3;
			nsLogin.addEventListener(Event.TRIGGERED, onNightscoutLogin);
			
			//Battery Uploader
			batteryUploader = LayoutFactory.createCheckMark(isBatteryUploaderEnabled);
			batteryUploader.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Predictions Uploader
			predictionsUploader = LayoutFactory.createCheckMark(isUploadPredictionsEnabled);
			predictionsUploader.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Optimal Calibration Uploader
			ocUploader = LayoutFactory.createCheckMark(isUploadOptimalCalibrationsEnabled);
			ocUploader.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Wi-Fi Only Sync
			wifiOnlyUploaderCheck = LayoutFactory.createCheckMark(isWifiOnlyUploaderEnabled);
			wifiOnlyUploaderCheck.addEventListener(Event.CHANGE, onSettingsChanged);
			
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
		
		private function onNightscoutOnOff(event:Event):void
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
		
		private function onTextInputEnter(event:Event):void
		{
			//Clear focus to dismiss the keyboard
			nsURL.clearFocus();
			nsAPISecret.clearFocus();
		}
		
		private function onNightscoutLogin(event:Event):void
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
		 * Utility
		 */
		override public function dispose():void
		{
			if(nsToggle != null)
			{
				nsToggle.removeEventListener( Event.CHANGE, onNightscoutOnOff );
				nsToggle.dispose();
				nsToggle = null;
			}
			if(nsURL != null)
			{
				nsURL.removeEventListener( FeathersEventType.ENTER, onTextInputEnter );
				nsURL.removeEventListener(Event.CHANGE, onSettingsChanged);
				nsURL.dispose();
				nsURL = null;
			}
			if(nsAPISecret != null)
			{
				nsAPISecret.removeEventListener( FeathersEventType.ENTER, onTextInputEnter );
				nsAPISecret.removeEventListener(Event.CHANGE, onSettingsChanged);
				nsAPISecret.dispose();
				nsAPISecret = null;
			}
			if(nsLogin != null)
			{
				nsLogin.removeEventListener(Event.TRIGGERED, onNightscoutLogin);
				nsLogin.dispose();
				nsLogin = null;
			}
			if(batteryUploader != null)
			{
				batteryUploader.removeEventListener(Event.CHANGE, onSettingsChanged);
				batteryUploader.dispose();
				batteryUploader = null;
			}
			if(predictionsUploader != null)
			{
				predictionsUploader.removeEventListener(Event.CHANGE, onSettingsChanged);
				predictionsUploader.dispose();
				predictionsUploader = null;
			}
			if(wifiOnlyUploaderCheck != null)
			{
				wifiOnlyUploaderCheck.removeEventListener(Event.CHANGE, onSettingsChanged);
				wifiOnlyUploaderCheck.dispose();
				wifiOnlyUploaderCheck = null;
			}
			if(ocUploader != null)
			{
				ocUploader.removeEventListener(Event.CHANGE, onSettingsChanged);
				ocUploader.dispose();
				ocUploader = null;
			}
			
			super.dispose();
		}
	}
}