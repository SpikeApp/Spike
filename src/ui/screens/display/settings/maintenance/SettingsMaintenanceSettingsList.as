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
	import com.hurlant.crypto.symmetric.AESKey;
	import com.hurlant.util.Base64;
	import com.hurlant.util.Hex;
	
	import flash.display.BitmapData;
	import flash.display.StageOrientation;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.utils.ByteArray;
	import flash.utils.setTimeout;
	
	import cryptography.Keys;
	
	import database.CommonSettings;
	import database.LocalSettings;
	
	import distriqtkey.DistriqtKey;
	
	import feathers.controls.Button;
	import feathers.controls.Callout;
	import feathers.controls.Label;
	import feathers.controls.LayoutGroup;
	import feathers.controls.TextInput;
	import feathers.core.PopUpManager;
	import feathers.data.ArrayCollection;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.HorizontalLayout;
	import feathers.layout.VerticalAlign;
	import feathers.layout.VerticalLayout;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import network.EmailSender;
	import network.NetworkConnector;
	
	import org.qrcode.QRCode;
	
	import starling.core.Starling;
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.ResizeEvent;
	import starling.text.TextFormat;
	import starling.textures.Texture;
	import starling.utils.SystemUtil;
	
	import ui.AppInterface;
	import ui.popups.AlertManager;
	import ui.screens.display.LayoutFactory;
	import ui.screens.display.SpikeList;
	
	import utils.Constants;
	import utils.DataValidator;
	import utils.DeviceInfo;
	
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
		private var emailLabel:Label;
		private var emailField:TextInput;
		private var emailActionsContainer:LayoutGroup;
		private var cancelSendEmailButton:Button;
		private var sendQRCodeButton:Button;
		private var sendEmailButton:Button;
		private var positionHelper:Sprite;
		private var qrCodeSenderCallout:Callout;
		private var mainEmailContainer:LayoutGroup;

		//Properties
		private var renderTimoutID1:uint;
		private var renderTimoutID2:uint;
		private var renderTimoutID3:uint;
		
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
		
		private function closeEmailCallout():void
		{
			if (qrCodeSenderCallout != null)
			{
				if (PopUpManager.isPopUp(qrCodeSenderCallout))
					SystemUtil.executeWhenApplicationIsActive(PopUpManager.removePopUp, qrCodeSenderCallout, true);
				else
					SystemUtil.executeWhenApplicationIsActive(qrCodeSenderCallout.close, true);
			}
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
			
			//Parse all settings into a string
			var allCommonSettings:Array = CommonSettings.getAllSettings();
			var allLocalSettings:Array = LocalSettings.getAllSettings();
			var allSettingsObject:Object = { commonSettings: allCommonSettings, localSettings: allLocalSettings };
			
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
			var allSettingsEncrypted:String = encryptString(Keys.AES256, allSettingsString);
			
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
					var encryptedURL:String = encryptString(Keys.AES256, url);
					
					try
					{
						//Create QR Code
						var settingsQRCode:QRCode = new QRCode();
						settingsQRCode.encode(encryptedURL);
						
						if (qrCodeImage != null) qrCodeImage.removeFromParent(true);
						qrCodeBitmapData = settingsQRCode.bitmapData;
						qrCodeImage = new Image(Texture.fromBitmapData(qrCodeBitmapData));
						qrCodeContainer.addChild(qrCodeImage);
						refreshContent();
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
		}
		
		private function onSettingsUploadError(error:Error):void
		{
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
			
			try
			{
				Scanner.init( !ModelLocator.IS_IPAD ? DistriqtKey.distriqtKey : DistriqtKey.distriqtKeyIpad );
				if (Scanner.isSupported)
				{
					Scanner.service.addEventListener( AuthorisationEvent.CHANGED, onCameraAuthorization );
					switch (Scanner.service.authorisationStatus())
					{
						case AuthorisationStatus.NOT_DETERMINED:
						case AuthorisationStatus.SHOULD_EXPLAIN:
							// REQUEST ACCESS: This will display the permission dialog
							Scanner.service.requestAccess();
							return;
							
						case AuthorisationStatus.DENIED:
						case AuthorisationStatus.UNKNOWN:
						case AuthorisationStatus.RESTRICTED:
							// ACCESS DENIED: You should inform your user appropriately
							return;
							
						case AuthorisationStatus.AUTHORISED:
							scanSettingsQRCode();
							break;						
					}
				}
			}
			catch (e:Error)
			{
				trace( e );
			}
		}
		
		private function onCameraAuthorization( event:AuthorisationEvent ):void
		{
			switch (event.status)
			{
				case AuthorisationStatus.SHOULD_EXPLAIN:
					// Should display a reason you need this feature
					break;
				
				case AuthorisationStatus.AUTHORISED:
					scanSettingsQRCode();
					break;
				
				case AuthorisationStatus.RESTRICTED:
				case AuthorisationStatus.DENIED:
					// ACCESS DENIED: You should inform your user appropriately
					break;
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
					var urlDecrypted:String = decodeString(Keys.AES256, qrCode);
					
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
			
			if (responseJSON != null && responseJSON.files != null && responseJSON.files is Array && responseJSON.files[0] != null && responseJSON.files[0].content != null)
			{
				var settingsEncrypted:String = String(responseJSON.files[0].content);
				var settingsDecrypted:String = decodeString(Keys.AES256, settingsEncrypted);
				
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
					var commonSettingsArray:Array = allSettingsJSON.commonSettings;
					var localSettingsArray:Array = allSettingsJSON.localSettings;
					
					//Import Settings
					var i:int;
					var commonSettingsLength:int = commonSettingsArray.length;
					var localSettingsLength:int = localSettingsArray.length;
					
					for (i = 0; i < commonSettingsLength; i++) 
					{
						CommonSettings.setCommonSetting(i, String(commonSettingsArray[i]), true, i != CommonSettings.COMMON_SETTING_PERIPHERAL_TYPE ? true : false);
					}
					
					for (i = 0; i < localSettingsLength; i++) 
					{
						LocalSettings.setLocalSetting(i, String(localSettingsArray[i]));
					}
					
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
		}
		
		private function onSettingsReceivedError(error:Error):void
		{
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
			
			/* Main Container */
			var mainLayout:VerticalLayout = new VerticalLayout();
			mainLayout.horizontalAlign = HorizontalAlign.CENTER;
			mainLayout.gap = 10;
			
			if (mainEmailContainer != null) mainEmailContainer.removeFromParent(true);
			mainEmailContainer = new LayoutGroup();
			mainEmailContainer.layout = mainLayout;
			
			/* Title */
			if (emailLabel != null) emailLabel.removeFromParent(true);
			emailLabel = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('globaltranslations',"user_email_label"), HorizontalAlign.CENTER);
			mainEmailContainer.addChild(emailLabel);
			
			/* Email Input */
			if (emailField != null) emailField.removeFromParent(true);
			emailField = LayoutFactory.createTextInput(false, false, 200, HorizontalAlign.CENTER, false, true);
			emailField.fontStyles.size = 12;
			mainEmailContainer.addChild(emailField);
			
			/* Action Buttons */
			var actionButtonsLayout:HorizontalLayout = new HorizontalLayout();
			actionButtonsLayout.gap = 5;
			
			if (emailActionsContainer != null) emailActionsContainer.removeFromParent(true);
			emailActionsContainer = new LayoutGroup();
			emailActionsContainer.layout = actionButtonsLayout;
			mainEmailContainer.addChild(emailActionsContainer);
			
			//Cancel Button
			if (cancelSendEmailButton != null) cancelSendEmailButton.removeFromParent(true);
			cancelSendEmailButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('globaltranslations',"cancel_button_label"));
			cancelSendEmailButton.addEventListener(starling.events.Event.TRIGGERED, onCancelSendEmail);
			emailActionsContainer.addChild(cancelSendEmailButton);
			
			//Send Button
			if (sendEmailButton != null) sendEmailButton.removeFromParent(true);
			sendEmailButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('globaltranslations',"send_button_label_capitalized"));
			sendEmailButton.addEventListener(starling.events.Event.TRIGGERED, onSendEmail);
			emailActionsContainer.addChild(sendEmailButton);
			
			/* Callout Position Helper Creation */
			if (positionHelper != null) positionHelper.removeFromParent(true);
			positionHelper = new Sprite();
			positionHelper.x = Constants.stageWidth / 2;
			
			var yPos:Number = 0;
			if (!isNaN(Constants.headerHeight))
				yPos = Constants.headerHeight - 10;
			else
			{
				if (Constants.deviceModel != DeviceInfo.IPHONE_X)
					yPos = 68;
				else
					yPos = Constants.isPortrait ? 98 : 68;
			}
			
			positionHelper.y = yPos;
			Starling.current.stage.addChild(positionHelper);
			
			/* Callout Creation */
			if (qrCodeSenderCallout != null) qrCodeSenderCallout.removeFromParent(true);
			qrCodeSenderCallout = new Callout();
			qrCodeSenderCallout.content = mainEmailContainer;
			qrCodeSenderCallout.origin = positionHelper;
			qrCodeSenderCallout.minWidth = 240;
			
			//Close the callout
			if (PopUpManager.isPopUp(qrCodeSenderCallout))
				PopUpManager.removePopUp(qrCodeSenderCallout, false);
			
			//Display callout
			PopUpManager.addPopUp(qrCodeSenderCallout, false, false);
			
			emailField.setFocus();
		}
		
		private function onSendEmail(e:starling.events.Event):void
		{
			if (emailLabel == null || sendEmailButton == null || qrCodeBitmapData == null)
				return;
			
			//Validation
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
			
			emailLabel.text = ModelLocator.resourceManagerInstance.getString('globaltranslations',"user_email_label");
			if (emailLabel.fontStyles != null)
				emailLabel.fontStyles.color = 0xEEEEEE;
			else
				emailLabel.fontStyles = new TextFormat("Roboto", 14, 0xEEEEEE, HorizontalAlign.CENTER, VerticalAlign.TOP);
			
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
			
			//Disable send button temporarily
			sendEmailButton.isEnabled = false;
			
			//Calculate File Name
			var fileName:String ="SpikeQRCode.png";
			
			//Read csv raw bytes into memory
			var fileData:ByteArray = PNGEncoder.encode(qrCodeBitmapData);
			
			//Create URL Request Address
			var vars:URLVariables = new URLVariables();
			vars.fileName = fileName;
			vars.mimeType = "image/png";
			vars.emailSubject = ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','email_subject');
			vars.emailBody = ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','email_body');
			vars.userEmail = emailField.text.replace(" ", "");
			vars.mode = EmailSender.MODE_EMAIL_USER;
			
			//Send data
			EmailSender.sendData
			(
				EmailSender.TRANSMISSION_URL_WITH_ATTACHMENT,
				onEmailSent,
				vars,
				fileData
			);
		}
		
		private function onEmailSent(event:flash.events.Event):void 
		{ 
			if (!SystemUtil.isApplicationActive)
			{
				SystemUtil.executeWhenApplicationIsActive(onEmailSent, event);
				return;
			}
			
			var loader:URLLoader = URLLoader(event.target);
			loader.removeEventListener(flash.events.Event.COMPLETE, onEmailSent);
			
			var response:Object = loader.data;
			loader = null;
			
			if (response.success == "true")
			{
				AlertManager.showSimpleAlert
				(
					ModelLocator.resourceManagerInstance.getString('globaltranslations','success_alert_title'),
					ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','email_sent_success_message')
				);
				
				closeEmailCallout();
			}
			else
			{
				sendEmailButton.isEnabled = true;
				
				AlertManager.showActionAlert
					(
						ModelLocator.resourceManagerInstance.getString('globaltranslations','error_alert_title'),
						ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','email_sent_error_message') + ": " + response.statuscode,
						Number.NaN,
						[
							{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations','cancel_button_label').toUpperCase() },	
							{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations','try_again_button_label'), triggered: onTryAgain },	
						]
					);
				
				function onTryAgain(e:starling.events.Event):void
				{
					Starling.juggler.delayCall(onSendQRCode, 0.5, null);
				}
			}
		}
		
		private function onCancelSendEmail(e:starling.events.Event):void
		{
			closeEmailCallout();
		}
		
		override protected function onStarlingResize(event:ResizeEvent):void 
		{
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
			
			if (restoreInstructions != null)
			{
				if (Constants.deviceModel == DeviceInfo.IPHONE_X && !Constants.isPortrait)
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
		private function encryptString(key:String, content:String):String
		{
			var keyBytes:ByteArray = Hex.toArray(key);
			var contentBytes:ByteArray = Hex.toArray(Hex.fromString(content));
			var aes:AESKey = new AESKey(keyBytes);
			aes.encrypt( contentBytes );
			contentBytes.compress();
			
			return Base64.encodeByteArray(contentBytes);
		}
		
		private function decodeString(key:String, content:String):String
		{
			var keyBytes:ByteArray = Hex.toArray(key);
			var contentBytes:ByteArray = Base64.decodeToByteArray(content);
			contentBytes.uncompress();
			var aes:AESKey = new AESKey(keyBytes);
			aes.decrypt( contentBytes );
			
			return contentBytes.toString();
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
			if (this.layout != null)
				(this.layout as VerticalLayout).hasVariableItemDimensions = true;
			
			super.draw();
		}
		
		override public function dispose():void
		{
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
			
			if (cancelSendEmailButton != null)
			{
				cancelSendEmailButton.removeEventListener(starling.events.Event.TRIGGERED, onCancelSendEmail);
				cancelSendEmailButton.removeFromParent();
				cancelSendEmailButton.dispose();
				cancelSendEmailButton = null;
			}
			
			if (sendQRCodeButton != null)
			{
				sendQRCodeButton.removeEventListener(starling.events.Event.TRIGGERED, onSendQRCode);
				sendQRCodeButton.removeFromParent();
				sendQRCodeButton.dispose();
				sendQRCodeButton = null;
			}
			
			if (sendEmailButton != null)
			{
				sendEmailButton.removeEventListener(starling.events.Event.TRIGGERED, onSendEmail);
				sendEmailButton.removeFromParent();
				sendEmailButton.dispose();
				sendEmailButton = null;
			}
			
			if (qrCodeBitmapData != null)
			{
				qrCodeBitmapData.dispose();
				qrCodeBitmapData = null;
			}
			
			if (qrCodeImage != null)
			{
				qrCodeImage.removeFromParent();
				qrCodeImage.dispose();
				qrCodeImage = null;
			}
			
			if (emailLabel != null)
			{
				emailLabel.removeFromParent();
				emailLabel.dispose();
				emailLabel = null;
			}
			
			if (emailField != null)
			{
				emailField.removeFromParent();
				emailField.dispose();
				emailField = null;
			}
			
			if (positionHelper != null)
			{
				positionHelper.removeFromParent();
				positionHelper.dispose();
				positionHelper = null;
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
			
			if (emailActionsContainer != null)
			{
				emailActionsContainer.removeFromParent();
				emailActionsContainer.dispose();
				emailActionsContainer = null;
			}

			if (mainEmailContainer != null)
			{
				mainEmailContainer.removeFromParent();
				mainEmailContainer.dispose();
				mainEmailContainer = null;
			}
			
			if (qrCodeSenderCallout != null)
			{
				qrCodeSenderCallout.removeFromParent();
				qrCodeSenderCallout.dispose();
				qrCodeSenderCallout = null;
			}
			
			super.dispose();
		}
	}
}