package ui.screens.display.settings.maintenance
{
	import com.adobe.images.PNGEncoder;
	import com.distriqt.extension.networkinfo.NetworkInfo;
	import com.distriqt.extension.scanner.AuthorisationStatus;
	import com.distriqt.extension.scanner.Scanner;
	import com.distriqt.extension.scanner.ScannerOptions;
	import com.distriqt.extension.scanner.Symbology;
	import com.distriqt.extension.scanner.events.AuthorisationEvent;
	import com.distriqt.extension.scanner.events.ScannerEvent;
	
	import flash.display.BitmapData;
	import flash.display.StageOrientation;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequestMethod;
	import flash.utils.setTimeout;
	
	import cryptography.Keys;
	
	import database.CommonSettings;
	import database.LocalSettings;
	
	import feathers.controls.Alert;
	import feathers.controls.Button;
	import feathers.controls.Label;
	import feathers.controls.LayoutGroup;
	import feathers.data.ArrayCollection;
	import feathers.extensions.MaterialDesignSpinner;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.HorizontalLayout;
	import feathers.layout.VerticalAlign;
	import feathers.layout.VerticalLayout;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import network.NetworkConnector;
	
	import org.qrcode.QRCode;
	
	import starling.core.Starling;
	import starling.display.Image;
	import starling.events.Event;
	import starling.events.ResizeEvent;
	import starling.textures.Texture;
	import starling.utils.SystemUtil;
	
	import treatments.Insulin;
	import treatments.Profile;
	import treatments.ProfileManager;
	
	import ui.AppInterface;
	import ui.popups.AlertManager;
	import ui.popups.EmailFileSender;
	import ui.screens.display.LayoutFactory;
	import ui.screens.display.SpikeList;
	
	import utils.Constants;
	import utils.Cryptography;
	import utils.DeviceInfo;
	import utils.Trace;
	
	[ResourceBundle("maintenancesettingsscreen")]
	[ResourceBundle("globaltranslations")]
	
	public class SettingsMaintenanceSettingsList extends SpikeList
	{
		/* Display Objects */
		private var backupButton:Button;
		private var restoreButton:Button;
		private var actionsContainer:LayoutGroup;
		private var qrCodeImage:Image;
		private var qrCodeBitmapData:BitmapData;
		private var qrCodeContainer:LayoutGroup;
		private var restoreInstructions:Label;
		private var sendEmailContainer:LayoutGroup;
		private var sendQRCodeButton:Button;
		private var preloaderContainer:LayoutGroup;
		private var preloader:MaterialDesignSpinner;
		
		//Properties
		private var renderTimoutID1:uint;
		private var renderTimoutID2:uint;
		private var renderTimoutID3:uint;
		private var isLoading:Boolean = false;
		
		public function SettingsMaintenanceSettingsList()
		{
			super(true);
			
			setupProperties();
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
		
		private function setupContent():void
		{
			//Actions Container
			var actionsLayout:HorizontalLayout = new HorizontalLayout();
			actionsLayout.horizontalAlign = HorizontalAlign.RIGHT;
			actionsLayout.gap = 5;
			actionsContainer = new LayoutGroup();
			actionsContainer.layout = actionsLayout;
			
			//Restore Button
			restoreButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','restore_button_label'));
			restoreButton.addEventListener(starling.events.Event.TRIGGERED, onRestoreSettings);
			actionsContainer.addChild(restoreButton);
			
			//Backup Button
			backupButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','backup_button_label'));
			backupButton.addEventListener(starling.events.Event.TRIGGERED, onBackup);
			actionsContainer.addChild(backupButton);
			
			//QR Code container
			var qrCodeLayout:HorizontalLayout = new HorizontalLayout();
			qrCodeLayout.horizontalAlign = HorizontalAlign.CENTER;
			qrCodeLayout.paddingTop = qrCodeLayout.paddingBottom = 10;
			
			qrCodeContainer = new LayoutGroup;
			qrCodeContainer.layout = qrCodeLayout;
			qrCodeContainer.width = width;
			
			//Send Button
			var sendEmailLayout:HorizontalLayout = new HorizontalLayout();
			sendEmailLayout.horizontalAlign = HorizontalAlign.CENTER;
			
			sendEmailContainer = new LayoutGroup();
			sendEmailContainer.width = width;
			sendEmailContainer.layout = sendEmailLayout;
			
			sendQRCodeButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('globaltranslations',"email_button_label"));
			sendQRCodeButton.addEventListener(starling.events.Event.TRIGGERED, onSendQRCode);
			sendEmailContainer.addChild(sendQRCodeButton);
			
			//Preloader
			preloaderContainer = new LayoutGroup();
			preloaderContainer.pivotX = -15;
			
			preloader = new MaterialDesignSpinner();
			preloader.color = 0x0086FF;
			preloader.touchable = false;
			preloader.scale = 0.6;
			preloaderContainer.addChild(preloader);
			preloader.validate();
			preloaderContainer.validate();
			preloader.y += 10;
			
			//Restore Instructions
			restoreInstructions = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','restore_instructions_label'), HorizontalAlign.JUSTIFY, VerticalAlign.TOP);
			restoreInstructions.width = width;
			restoreInstructions.wordWrap = true;
			restoreInstructions.paddingTop = restoreInstructions.paddingBottom = 10;
			
			refreshContent();
		}
		
		private function refreshContent():void
		{
			//Set Data
			var data:Array = [];
			data.push( { label: ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','actions_label'), accessory: actionsContainer } );
			if (isLoading)
				data.push( { label: ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','status_label'), accessory: preloaderContainer } );
			if (qrCodeImage != null)
			{
				data.push( { label: "", accessory: qrCodeContainer } );
				data.push( { label: "", accessory: sendEmailContainer } );
				data.push( { label: "", accessory: restoreInstructions } );
			}
			
			dataProvider = new ArrayCollection( data );
		}
		
		private function scanSettingsQRCode():void
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
		
		/**
		 * Event Listeners
		 */
		private function onBackup(e:starling.events.Event):void
		{
			//Validation
			if (!NetworkInfo.networkInfo.isReachable())
			{
				AlertManager.showSimpleAlert
					(
						ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
						ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','no_network_connection')
					);
				
				return;
			}
			
			isLoading = true;
			refreshContent();
			
			//Parse all settings into a string
			var i:int = 0;
			var appVersion:String = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_APPLICATION_VERSION);
			var allCommonSettings:Array = CommonSettings.getAllSettings();
			var allLocalSettings:Array = LocalSettings.getAllSettings();
			var allInsulins:Array = [];
			var allProfiles:Array = [];
			
			for (i = 0; i < ProfileManager.insulinsList.length; i++) 
			{
				var insulin:Insulin = ProfileManager.insulinsList[i] as Insulin;
				
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
			
			var allSettingsObject:Object = {};
			allSettingsObject.appVersion = appVersion;
			allSettingsObject.commonSettings = allCommonSettings;
			allSettingsObject.localSettings = allLocalSettings;
			allSettingsObject.insulins = allInsulins;
			allSettingsObject.profiles = allProfiles;
			allSettingsObject.algorithmIOBCOB = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEFAULT_IOB_COB_ALGORITHM);
			allSettingsObject.fastAbsortionCarbTime = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CARB_FAST_ABSORTION_TIME));
			allSettingsObject.mediumAbsortionCarbTime = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CARB_MEDIUM_ABSORTION_TIME));
			allSettingsObject.slowAbsortionCarbTime = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CARB_SLOW_ABSORTION_TIME));
			allSettingsObject.defaultAbsortionCarbTime = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEFAULT_CARB_ABSORTION_TIME));
			
			try
			{
				var allSettingsString:String = JSON.stringify(allSettingsObject);
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
			
			//Encrypt settings
			var allSettingsEncrypted:String = Cryptography.encryptStringStrong(Keys.STRENGTH_256_BIT, allSettingsString);
			
			//Upload them (anonymously and privatly)
			var parameters:Object = {};
			parameters.language = "plaintext";
			parameters.title = "SpikeSettings";
			parameters["public"] = false;
			parameters.files = [ { name: "settings.txt", content: allSettingsEncrypted } ];
			
			NetworkConnector.createGlotConnector("https://snippets.glot.io/snippets", null, URLRequestMethod.POST, JSON.stringify(parameters), null, onSettingsUploaded, onSettingsUploadError);
		}
		
		private function onSettingsUploaded(e:flash.events.Event):void
		{
			//Get loader
			var loader:URLLoader = e.currentTarget as URLLoader;
			
			if (loader == null || loader.data == null)
			{
				AlertManager.showSimpleAlert
					(
						ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
						ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','error_backing_up_settings')
					);
				
				return;
			}
			
			//Get response
			var response:String = loader.data;
			
			//Dispose loader
			loader.removeEventListener(flash.events.Event.COMPLETE, onSettingsUploaded);
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
						ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','parse_settings_error')
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
						var settingsQRCode:QRCode = new QRCode();
						settingsQRCode.encode(encryptedURL);
						
						if (qrCodeImage != null) qrCodeImage.removeFromParent(true);
						qrCodeBitmapData = settingsQRCode.bitmapData;
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
							qrCodeImage = new Image(Texture.fromBitmapData(qrCodeBitmapData));
							qrCodeContainer.addChild(qrCodeImage);
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
							ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','error_backing_up_settings')
						);
				}
			}
			else
			{
				AlertManager.showSimpleAlert
					(
						ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
						ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','error_backing_up_settings')
					);
			}
			
			isLoading = false;
			refreshContent();
		}
		
		private function onSettingsUploadError(error:Error):void
		{
			isLoading = false;
			refreshContent();
			
			AlertManager.showSimpleAlert
				(
					ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
					ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','error_backing_up_settings')
				);
		}
		
		private function onRestoreSettings(e:starling.events.Event):void
		{
			//Validation
			if (!NetworkInfo.networkInfo.isReachable())
			{
				AlertManager.showSimpleAlert
					(
						ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
						ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','no_network_connection')
					);
				
				return;
			}
			
			var alert:Alert = AlertManager.showActionAlert
				(
					ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
					ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','settings_restore_confirmation_label'),
					Number.NaN,
					[
						{ label: ModelLocator.resourceManagerInstance.getString("globaltranslations","no_uppercase")  },	
						{ label: ModelLocator.resourceManagerInstance.getString("globaltranslations","yes_uppercase"), triggered: restoreSettings }	
					],
					HorizontalAlign.JUSTIFY
				);
			alert.buttonGroupProperties.gap = 10;
			alert.buttonGroupProperties.horizontalAlign = HorizontalAlign.CENTER;
			
			function restoreSettings(e:starling.events.Event):void
			{
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
								scanSettingsQRCode();
								break;						
						}
					}
				}
				catch (e:Error)
				{
					Trace.myTrace("SettingsMaintenanceSettings.as", "Scanner Error: " + e);
					
					AlertManager.showSimpleAlert
						(
							ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
							ModelLocator.resourceManagerInstance.getString('globaltranslations','error_activating_scanner') + " " + e
						);
				}
			}
		}
		
		private function onCameraAuthorization( event:AuthorisationEvent ):void
		{
			switch (event.status)
			{
				case AuthorisationStatus.SHOULD_EXPLAIN:
					break;
				
				case AuthorisationStatus.AUTHORISED:
					scanSettingsQRCode();
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
						//Activate preloader
						isLoading = true;
						refreshContent();
						
						//Get Settings
						NetworkConnector.createGlotConnector(urlDecrypted, null, URLRequestMethod.GET, null, null, onEncyptedSettingsReceived, onSettingsReceivedError);
					}
					else
					{
						AlertManager.showSimpleAlert
							(
								ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
								ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','invalid_qr_code')
							);
					}
				} 
				catch(error:Error) 
				{
					AlertManager.showSimpleAlert
						(
							ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
							ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','invalid_qr_code')
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
						ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','error_restoring_settings')
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
					var allSettingsJSON:Object = JSON.parse(settingsDecrypted);
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
				
				if (allSettingsJSON != null && allSettingsJSON.commonSettings != null && allSettingsJSON.commonSettings is Array && allSettingsJSON.localSettings != null && allSettingsJSON.localSettings is Array)
				{
					var appVersion:String = allSettingsJSON.appVersion;
					var commonSettingsArray:Array = allSettingsJSON.commonSettings;
					var localSettingsArray:Array = allSettingsJSON.localSettings;
					var commonSettingsLength:int = commonSettingsArray.length;
					var localSettingsLength:int = localSettingsArray.length;
					var peripheralType:String = "";
					var insulinsArray:Array = allSettingsJSON.insulins;
					var insulinsLength:int = insulinsArray.length;
					var profilesArray:Array = allSettingsJSON.profiles;
					var profilesLength:int = profilesArray.length;
					var i:int;
					
					//Import Insulins
					try
					{
						if (insulinsArray != null && insulinsArray is Array && insulinsArray.length > 0)
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
					} 
					catch(error:Error) {}
					
					//Import Profiles
					try
					{
						if (profilesArray != null && profilesArray is Array && profilesArray.length > 0)
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
					} 
					catch(error:Error) {}
					
					//Import Individual Profile Settings
					if (allSettingsJSON.algorithmIOBCOB != null)
					{
						CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_DEFAULT_IOB_COB_ALGORITHM, String(allSettingsJSON.algorithmIOBCOB));
					}
					
					if (allSettingsJSON.fastAbsortionCarbTime != null)
					{
						CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_CARB_FAST_ABSORTION_TIME, String(allSettingsJSON.fastAbsortionCarbTime));
					}
					
					if (allSettingsJSON.mediumAbsortionCarbTime != null)
					{
						CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_CARB_MEDIUM_ABSORTION_TIME, String(allSettingsJSON.mediumAbsortionCarbTime));
					}
					
					if (allSettingsJSON.slowAbsortionCarbTime != null)
					{
						CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_CARB_SLOW_ABSORTION_TIME, String(allSettingsJSON.slowAbsortionCarbTime));
					}
					
					if (allSettingsJSON.defaultAbsortionCarbTime != null)
					{
						CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_DEFAULT_CARB_ABSORTION_TIME, String(allSettingsJSON.defaultAbsortionCarbTime));
					}
					
					//Import Settings
					for (i = 0; i < commonSettingsLength; i++) 
					{
						if (i == CommonSettings.COMMON_SETTING_PERIPHERAL_TYPE)
						{
							peripheralType = String(commonSettingsArray[i]);
						}
						else
							CommonSettings.setCommonSetting(i, String(commonSettingsArray[i]));
					}
					
					for (i = 0; i < localSettingsLength; i++) 
					{
						LocalSettings.setLocalSetting(i, String(localSettingsArray[i]));
					}
					
					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_PERIPHERAL_TYPE, peripheralType);
					
					//Refresh main menu. Menu items are different for hosts and followers
					AppInterface.instance.menu.refreshContent();
					
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
							ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','invalid_qr_code')
						);
				}
			}
			else
			{
				AlertManager.showSimpleAlert
					(
						ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
						ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','error_restoring_settings')
					);
			}
			
			//Activate preloader
			isLoading = false;
			refreshContent();
		}
		
		private function onSettingsReceivedError(error:Error):void
		{
			isLoading = false;
			refreshContent();
			
			AlertManager.showSimpleAlert
				(
					ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
					ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','error_restoring_settings')
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
		
		private function onSendQRCode(e:starling.events.Event):void
		{
			//Validation
			if (!NetworkInfo.networkInfo.isReachable())
			{
				AlertManager.showSimpleAlert
					(
						ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
						ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','no_network_connection')
					);
				
				return;
			}
			
			if (qrCodeBitmapData == null)
				return;
			
			if (sendQRCodeButton != null)
				sendQRCodeButton.isEnabled = false;
			
			EmailFileSender.instance.addEventListener(starling.events.Event.COMPLETE, onFileSenderClosed);
			EmailFileSender.instance.addEventListener(starling.events.Event.CANCEL, onFileSenderClosed);
			EmailFileSender.sendFile
			(
				ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','email_subject'),
				ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','email_body'),
				"SpikeQRCode.png",
				PNGEncoder.encode(qrCodeBitmapData),
				"image/png",
				ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','email_sent_success_message'),
				ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','email_sent_error_message'),
				""
			);
		}
		
		private function onFileSenderClosed(e:starling.events.Event):void
		{
			EmailFileSender.instance.removeEventListener(starling.events.Event.COMPLETE, onFileSenderClosed);
			EmailFileSender.instance.removeEventListener(starling.events.Event.CANCEL, onFileSenderClosed);
			
			if (sendQRCodeButton != null)
				sendQRCodeButton.isEnabled = true;
		}
		
		override protected function onStarlingResize(event:ResizeEvent):void 
		{
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
			
			if (restoreInstructions != null)
			{
				if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr && !Constants.isPortrait)
					restoreInstructions.width = width - (Constants.currentOrientation == StageOrientation.ROTATED_RIGHT ? 30 : 40);
				else
					restoreInstructions.width = width;
			}
			
			if (qrCodeContainer != null)
				qrCodeContainer.width = width;
			
			if (sendEmailContainer != null)
				sendEmailContainer.width = width;
			
			setupRenderFactory();
		}
		
		/**
		 * Helpers
		 */
		
		
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
			if (this.layout != null)
				(this.layout as VerticalLayout).hasVariableItemDimensions = true;
			
			super.draw();
		}
		
		override public function dispose():void
		{
			EmailFileSender.instance.removeEventListener(starling.events.Event.COMPLETE, onFileSenderClosed);
			EmailFileSender.instance.removeEventListener(starling.events.Event.CANCEL, onFileSenderClosed);
			EmailFileSender.dispose();
			
			if (backupButton != null)
			{
				backupButton.removeEventListener(starling.events.Event.TRIGGERED, onBackup);
				backupButton.removeFromParent();
				backupButton.dispose();
				backupButton = null;
			}
			
			if (restoreButton != null)
			{
				restoreButton.removeEventListener(starling.events.Event.TRIGGERED, onRestoreSettings);
				restoreButton.removeFromParent();
				restoreButton.dispose();
				restoreButton = null;
			}
			
			if (qrCodeImage != null)
			{
				qrCodeImage.removeFromParent();
				if(qrCodeImage.texture != null)
					qrCodeImage.texture.dispose();
				qrCodeImage.dispose();
				qrCodeImage = null;
			}
			
			if (qrCodeBitmapData != null)
			{
				qrCodeBitmapData.dispose();
				qrCodeBitmapData = null;
			}
			
			if (actionsContainer != null)
			{
				actionsContainer.removeFromParent();
				actionsContainer.dispose();
				actionsContainer = null;
			}
			
			if (qrCodeContainer != null)
			{
				qrCodeContainer.removeFromParent();
				qrCodeContainer.dispose();
				qrCodeContainer = null;
			}
			
			if (restoreInstructions != null)
			{
				restoreInstructions.removeFromParent();
				restoreInstructions.dispose();
				restoreInstructions = null;
			}
			
			if (sendEmailContainer != null)
			{
				sendEmailContainer.removeFromParent();
				sendEmailContainer.dispose();
				sendEmailContainer = null;
			}
			
			if (preloader != null)
			{
				preloader.removeFromParent();
				preloader.dispose();
				preloader = null;
			}
			
			if (preloaderContainer != null)
			{
				preloaderContainer.removeFromParent();
				preloaderContainer.dispose();
				preloaderContainer = null;
			}
			
			super.dispose();
		}
	}
}