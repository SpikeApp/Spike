package ui.screens.display.settings.maintenance
{
	import com.distriqt.extension.scanner.AuthorisationStatus;
	import com.distriqt.extension.scanner.Scanner;
	import com.distriqt.extension.scanner.ScannerOptions;
	import com.distriqt.extension.scanner.Symbology;
	import com.distriqt.extension.scanner.events.AuthorisationEvent;
	import com.distriqt.extension.scanner.events.ScannerEvent;
	import com.hurlant.crypto.symmetric.AESKey;
	import com.hurlant.util.Base64;
	import com.hurlant.util.Hex;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequestMethod;
	import flash.utils.ByteArray;
	
	import mx.utils.ObjectUtil;
	
	import database.CommonSettings;
	import database.LocalSettings;
	
	import distriqtkey.DistriqtKey;
	
	import feathers.controls.Button;
	import feathers.controls.Label;
	import feathers.controls.LayoutGroup;
	import feathers.data.ArrayCollection;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.HorizontalLayout;
	import feathers.layout.VerticalAlign;
	import feathers.layout.VerticalLayout;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import network.NetworkConnector;
	
	import org.qrcode.QRCode;
	
	import starling.display.Image;
	import starling.events.Event;
	import starling.textures.Texture;
	
	import ui.screens.display.LayoutFactory;
	import ui.screens.display.SpikeList;
	
	import utils.Constants;
	
	[ResourceBundle("maintenancesettingsscreen")]
	
	public class SettingsMaintenanceSettingsList extends SpikeList
	{
		/* Display Objects */
		private var backupButton:Button;
		private var restoreButton:Button;
		private var actionsContainer:LayoutGroup;
		private var qrCodeImage:Image;

		private var qrCodeContainer:LayoutGroup;

		private var restoreInstructions:Label;
		
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
			actionsLayout.horizontalAlign = HorizontalAlign.CENTER;
			actionsLayout.gap = 10;
			actionsContainer = new LayoutGroup();
			actionsContainer.layout = actionsLayout;
			actionsContainer.width = width;
			
			//Restore Button
			restoreButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','restore_button_label'));
			restoreButton.addEventListener(starling.events.Event.TRIGGERED, onRestore);
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
			data.push( { label: "", accessory: actionsContainer } );
			if (qrCodeImage != null)
			{
				data.push( { label: "", accessory: qrCodeContainer } );
				data.push( { label: "", accessory: restoreInstructions } );
			}
			
			dataProvider = new ArrayCollection( data );
		}
		
		private function scanSettings():void
		{
			Scanner.service.addEventListener( ScannerEvent.CODE_FOUND, onQRCodeFound );
			Scanner.service.addEventListener( ScannerEvent.CANCELLED, onScanCanceled );
			
			var options:ScannerOptions = new ScannerOptions();
			options.camera = ScannerOptions.CAMERA_REAR;
			options.torchMode = ScannerOptions.TORCH_AUTO;
			options.cancelLabel = "CANCEL";
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
				
			}
		}
		
		/**
		 * Event Listeners
		 */
		private function onBackup(e:starling.events.Event):void
		{
			//Parse all settings into a string
			var allCommonSettings:Array = CommonSettings.getAllSettings();
			var allCommonSettingsString:String = allCommonSettings.join("|||");
			
			var allLocalSettings:Array = LocalSettings.getAllSettings();
			var allLocalSettingsString:String = allLocalSettings.join("|||");
			
			var allSettingsString:String = allCommonSettingsString + "%%%" + allLocalSettingsString;
			
			//Encrypt settings
			var allSettingsEncrypted:String = encodeString("xyCbAH7r6rkQpMZaqksDwUeVUl64UbcH", allSettingsString);
			
			//Upload them (anonymously and privatly)
			var parameters:Object = {};
			parameters.language = "plaintext";
			parameters.title = "Spike Settings";
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
				trace("Error uploading");
				return;
			}
			
			//Get response
			var response:String = loader.data;
			
			//Dispose loader
			loader.removeEventListener(flash.events.Event.COMPLETE, onSettingsUploaded);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onSettingsUploadError);
			loader = null;
			
			//Parse response and extract link
			var responseJSON:Object = JSON.parse(response);
			trace(ObjectUtil.toString(responseJSON));
			
			if (responseJSON != null && responseJSON.url != null)
			{
				var url:String = String(responseJSON.url);
				if (url.indexOf("https://snippets.glot.io") != -1)
				{
					var encryptedURL:String = encodeString("xyCbAH7r6rkQpMZaqksDwUeVUl64UbcH", url);
					
					try
					{
						//Create QR Code
						var settingsQRCode:QRCode = new QRCode();
						settingsQRCode.encode(encryptedURL);
						
						if (qrCodeImage != null) qrCodeImage.removeFromParent(true);
						qrCodeImage = new Image(Texture.fromBitmapData(settingsQRCode.bitmapData));
						qrCodeContainer.addChild(qrCodeImage);
						refreshContent();
					} 
					catch(error:Error) 
					{
						trace("Error creating QR Code");
					}
				}
				else
				{
					trace("Server upload response error");
				}
			}
			else
			{
				trace("Server upload response error");
			}
		}
		
		private function onSettingsUploadError(error:Error):void
		{
			
		}
		
		private function onRestore(e:starling.events.Event):void
		{
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
							scanSettings();
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
					scanSettings();
					break;
				
				case AuthorisationStatus.RESTRICTED:
				case AuthorisationStatus.DENIED:
					// ACCESS DENIED: You should inform your user appropriately
					break;
			}
		}
		
		/**
		 * Helpers
		 */
		private function encodeString(key:String, content:String):String
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
			
			
			super.dispose();
		}
	}
}