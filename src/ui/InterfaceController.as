package ui
{
	import com.adobe.touch3D.Touch3D;
	import com.adobe.touch3D.Touch3DEvent;
	import com.coltware.airxzip.ZipEntry;
	import com.coltware.airxzip.ZipFileReader;
	import com.distriqt.extension.application.Application;
	import com.distriqt.extension.bluetoothle.BluetoothLE;
	import com.distriqt.extension.bluetoothle.events.PeripheralEvent;
	import com.distriqt.extension.notifications.Notifications;
	import com.distriqt.extension.systemgestures.ScreenEdges;
	import com.distriqt.extension.systemgestures.SystemGestures;
	import com.hurlant.util.Base64;
	import com.spikeapp.spike.airlibrary.SpikeANE;
	import com.spikeapp.spike.airlibrary.SpikeANEEvent;
	
	import flash.desktop.NativeApplication;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.InvokeEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.URLLoader;
	import flash.net.URLVariables;
	import flash.system.Capabilities;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import flash.text.engine.LineJustification;
	import flash.text.engine.SpaceJustifier;
	import flash.utils.ByteArray;
	import flash.utils.setTimeout;
	
	import mx.utils.ObjectUtil;
	
	import spark.formatters.DateTimeFormatter;
	
	import cryptography.Keys;
	
	import database.CGMBlueToothDevice;
	import database.CommonSettings;
	import database.Database;
	import database.LocalSettings;
	import database.Sensor;
	
	import events.BlueToothServiceEvent;
	import events.DatabaseEvent;
	import events.NotificationServiceEvent;
	import events.SettingsServiceEvent;
	
	import feathers.controls.Alert;
	import feathers.controls.text.TextBlockTextRenderer;
	import feathers.core.ITextRenderer;
	import feathers.data.ListCollection;
	import feathers.layout.HorizontalAlign;
	
	import model.ModelLocator;
	
	import network.NetworkConnector;
	
	import services.CalibrationService;
	import services.NotificationService;
	import services.TutorialService;
	import services.bluetooth.CGMBluetoothService;
	
	import starling.core.Starling;
	import starling.events.Event;
	
	import ui.popups.AlertManager;
	import ui.screens.Screens;
	
	import utils.Constants;
	import utils.Cryptography;
	import utils.DeviceInfo;
	import utils.TimeSpan;
	import utils.Trace;

	[ResourceBundle("transmitterscreen")]
	[ResourceBundle("globaltranslations")]
	[ResourceBundle("sensorscreen")]
	[ResourceBundle("3dtouch")]
	[ResourceBundle("crashreport")]
	[ResourceBundle("disclaimerscreen")]
	[ResourceBundle("maintenancesettingsscreen")]

	public class InterfaceController extends EventDispatcher
	{
		private static var initialStart:Boolean = true;
		private static var _instance:InterfaceController;
		public static var dateFormatterForSensorStartTimeAndDate:DateTimeFormatter;
		public static var peripheralConnected:Boolean = false;
		public static var peripheralConnectionStatusChangeTimestamp:Number;
		private static var lastInvoke:Number = 0;
		private static var backupDatabaseData:ByteArray;
		private static var uniqueId:String = "";
		private static var devicePropertiesHash:String = "";
		
		public function InterfaceController() {}
		
		public static function init():void
		{
			if(_instance == null)
				_instance = new InterfaceController();
			
			if (initialStart) 
			{
				if (DeviceInfo.isDeviceCompatible())
				{
					Trace.init();
					Database.instance.addEventListener(DatabaseEvent.DATABASE_INIT_FINISHED_EVENT,onInitResult);
					Database.instance.addEventListener(DatabaseEvent.ERROR_EVENT,onInitError);
					Database.init();
					initialStart = false;
					CommonSettings.instance.addEventListener(SettingsServiceEvent.SETTING_CHANGED, onSettingsChanged);
					
					dateFormatterForSensorStartTimeAndDate = new DateTimeFormatter();
					dateFormatterForSensorStartTimeAndDate.dateTimePattern = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_DATE_FORMAT).slice(0,2) == "24" ? "dd MMM HH:mm" : "dd MMM h:mm a";
					dateFormatterForSensorStartTimeAndDate.useUTC = false;
					dateFormatterForSensorStartTimeAndDate.setStyle("locale", Constants.getUserLocale());
				}
				else
				{
					var txtFormat:TextFormat = new TextFormat();
					txtFormat.size = 24;
					txtFormat.font = "Roboto";
					txtFormat.bold = true;
					txtFormat.align = TextFormatAlign.CENTER;
					
					var incompatibilityMessage:TextField = new TextField();
					incompatibilityMessage.defaultTextFormat = txtFormat;
					incompatibilityMessage.textColor = 0xEEEEEE;
					incompatibilityMessage.width = Constants.appStage.stageWidth;
					incompatibilityMessage.y = (Constants.appStage.stageHeight - incompatibilityMessage.textHeight) / 2;
					incompatibilityMessage.text = ModelLocator.resourceManagerInstance.getString('globaltranslations','incompatible_device_message');
					incompatibilityMessage.selectable = false;
					Constants.appStage.addChild(incompatibilityMessage);
				}
			}
			
			
			function onInitResult(event:DatabaseEvent):void
			{
				Trace.myTrace("interfaceController.as", "Database initialized successfully!");
				//at this moment the database is intialised, but the logs, bgreadings, ... might still be read in the ModelLocator, Modellocator is listening to the same event
				
				//Cryptography
				if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_DATABASE_IS_ENCRYPTED) != "true")
				{
					Trace.myTrace("interfaceController.as", "Encrypting database passwords for backwards compatibility...");
					
					//Main Nightscout API Secret
					var mainNightscoutAPISecret:String = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_API_SECRET);
					mainNightscoutAPISecret = Cryptography.encryptStringLight(Keys.STRENGTH_256_BIT, mainNightscoutAPISecret);
					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_API_SECRET, mainNightscoutAPISecret);
					
					//Follower Nightscout API Secret
					var followerNightscoutAPISecret:String = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_API_SECRET);
					followerNightscoutAPISecret = Cryptography.encryptStringLight(Keys.STRENGTH_256_BIT, followerNightscoutAPISecret);
					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_API_SECRET, followerNightscoutAPISecret);
					
					//Dexcom Share Password
					var dexcomSharePassword:String = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEXCOM_SHARE_PASSWORD);
					dexcomSharePassword = Cryptography.encryptStringLight(Keys.STRENGTH_256_BIT, dexcomSharePassword);
					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_DEXCOM_SHARE_PASSWORD, dexcomSharePassword);
					
					//IFTTT Maker Keys
					var IFTTTMakerKeys:String = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_MAKER_KEY);
					IFTTTMakerKeys = Cryptography.encryptStringLight(Keys.STRENGTH_256_BIT, IFTTTMakerKeys);
					LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_MAKER_KEY, IFTTTMakerKeys);
					
					//Internal HTTP Password
					var internalHTTPPassword:String = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_LOOP_SERVER_PASSWORD);
					internalHTTPPassword = Cryptography.encryptStringLight(Keys.STRENGTH_256_BIT, internalHTTPPassword);
					LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_LOOP_SERVER_PASSWORD, internalHTTPPassword);
					
					//Update Flag
					LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_DATABASE_IS_ENCRYPTED, "true");
				}
				
				//NSLog
				if (ModelLocator.INTERNAL_TESTING)
					LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_NSLOG, "true");
				else
					LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_NSLOG, "false");
				
				Database.instance.removeEventListener(DatabaseEvent.ERROR_EVENT,onInitError);
				CGMBluetoothService.instance.addEventListener(BlueToothServiceEvent.BLUETOOTH_SERVICE_INITIATED, blueToothServiceInitiated);
				
				/* File Association */
				NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE, onInvoke);
				
				//System Gestures
				removeSystemGestures();
				
				//3D Touch Management
				setup3DTouch();
				
				//Track Installation
				setTimeout(trackInstallationUsage, TimeSpan.TIME_30_SECONDS);
			}
			
			function onInitError(event:DatabaseEvent):void
			{	
				Trace.myTrace("interfaceController.as", "Error initializing database!");
			}
		}
		
		private static function trackInstallationUsage():void
		{
			Trace.myTrace("interfaceController.as", "Tracking installation & usage...");
			
			if (Application.isSupported)
			{
				uniqueId = Application.service.device.uniqueId("vendor", true);
				if (uniqueId != null && uniqueId != "")
				{
					var deviceType:String = Application.service.device.device;
					var deviceModel:String = Application.service.device.model;
					var deviceYear:int = Application.service.device.yearClass;
					var iOSVersion:String = Application.service.device.os.version;
					var country:String = Application.service.device.locale.country;
					var language:String = Application.service.device.locale.language;;
					var timezone:String = Application.service.device.localTimeZone.id;
					
					devicePropertiesHash = Base64.encode(deviceType + deviceModel + deviceYear + iOSVersion + country + language + timezone);
					var parameters:URLVariables;
					
					if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_TRACKED_VENDOR_ID) != uniqueId || LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_TRACKED_DEVICE_HASH) != devicePropertiesHash)
					{
						parameters = new URLVariables();
						parameters.uniqueId = uniqueId;
						parameters.deviceType = deviceType;
						parameters.deviceModel = deviceModel;
						parameters.deviceYear = deviceYear;
						parameters.iOSVersion = iOSVersion;
						parameters.country = country;
						parameters.language = language;
						parameters.timezone = timezone;
						
						NetworkConnector.trackInstallationUsage
						(
							"https://spike-app.com/tracking/installation.php",
							parameters,
							onInstallationTrackComplete,
							onInstallationTrackFailed
						);
						
						Trace.myTrace("interfaceController.as", "Sending device information to server for installation tracking...");
					}
					else if (Number(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_TRACKED_DEVICE_LATEST_TIMESTAMP)) != 0 && new Date().valueOf() - Number(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_TRACKED_DEVICE_LATEST_TIMESTAMP)) > TimeSpan.TIME_2_WEEKS)
					{
						parameters = new URLVariables();
						parameters.uniqueId = uniqueId;
						
						NetworkConnector.trackInstallationUsage
						(
							"https://spike-app.com/tracking/usage.php",
							parameters,
							onInstallationTrackComplete,
							onInstallationTrackFailed
						);
						
						Trace.myTrace("interfaceController.as", "Sending device id to server for usage tracking...");
					}
					else
					{
						Trace.myTrace("interfaceController.as", "Installation/usage already previously tracked. Aborting!");
					}
				}
				else
				{
					Trace.myTrace("interfaceController.as", "Can't track installation. Unable to retrieve device unique id!");
				}
			}
			else
			{
				Trace.myTrace("interfaceController.as", "Can't track installation. Device not supported!");
			}
		}
		
		private static function onInstallationTrackComplete(e:flash.events.Event):void
		{
			//Get loader
			var loader:URLLoader = e.currentTarget as URLLoader;
			
			//Get response
			var response:URLVariables = loader.data as URLVariables;
			
			//Dispose loader
			loader.removeEventListener(flash.events.Event.COMPLETE, onInstallationTrackComplete);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onInstallationTrackFailed);
			loader = null;
			
			if (response != null && response.success != null)
			{
				if (response.success == "true")
				{
					Trace.myTrace("interfaceController.as", "Installation/usage successfully tracked!");
					
					LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_TRACKED_VENDOR_ID, uniqueId, true, false);
					LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_TRACKED_DEVICE_HASH, devicePropertiesHash, true, false);
					LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_TRACKED_DEVICE_LATEST_TIMESTAMP, String(new Date().valueOf()), true, false);
				}
				else
				{
					Trace.myTrace("interfaceController.as", "Error tracking installation/usage. Server returned an error!");
				}
			}
		}
		
		private static function onInstallationTrackFailed(error:Error):void
		{
			Trace.myTrace("interfaceController.as", "Failed to track installation! Error: " + error.message);
		}
		
		private static function removeSystemGestures():void
		{
			//Completely remove ability to defer system gestures so users don't have to swipe twice to close Spike
			if (DeviceInfo.getDeviceType() == DeviceInfo.IPHONE_X_Xs_XsMax_Xr)
				SystemGestures.service.setDeferredScreenEdges(ScreenEdges.NONE);
		}
		
		private static function onSettingsChanged(event:SettingsServiceEvent):void 
		{
			/* Transmitter Info Alerts */
			if (event.data == CommonSettings.COMMON_SETTING_PERIPHERAL_TYPE) 
			{
				if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PERIPHERAL_TYPE) == "" || CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PERIPHERAL_TYPE) == "Follow" || CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_MODE) == "Follower")
					return;
				
				if (CGMBlueToothDevice.alwaysScan()) 
				{
					if ((CGMBlueToothDevice.isDexcomG5() || CGMBlueToothDevice.isDexcomG6()) && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_G5_G6_INFO_SCREEN_SHOWN) == "false" && !TutorialService.isActive) 
					{
						var alertMessageG5G6:String = ModelLocator.resourceManagerInstance.getString('transmitterscreen','g5_info_screen');
						if (CGMBlueToothDevice.isDexcomG6())
							alertMessageG5G6.replace("G5", "G6");
							
						if (Sensor.getActiveSensor() == null)
							alertMessageG5G6 += "\n\n" + ModelLocator.resourceManagerInstance.getString('transmitterscreen','sensor_not_started');
							
						var alertG5G6:Alert = AlertManager.showSimpleAlert
						(
							ModelLocator.resourceManagerInstance.getString('transmitterscreen','alert_info_title'),
							alertMessageG5G6
						);
						alertG5G6.height = 400;
						
						CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_G5_G6_INFO_SCREEN_SHOWN,"true");
					} 
					else if (CGMBlueToothDevice.isBluKon() && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BLUKON_INFO_SCREEN_SHOWN) == "false" && !TutorialService.isActive) 
					{
						var alertMessageBlucon:String = ModelLocator.resourceManagerInstance.getString('transmitterscreen','blucon_info_screen');
						if (Sensor.getActiveSensor() == null)
							alertMessageBlucon += "\n\n" + ModelLocator.resourceManagerInstance.getString('transmitterscreen','sensor_not_started');
							
						var alertBlucon:Alert = AlertManager.showSimpleAlert
						(
							ModelLocator.resourceManagerInstance.getString('transmitterscreen','alert_info_title'),
							alertMessageBlucon
						);
						alertBlucon.height = 400;
							
						CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_BLUKON_INFO_SCREEN_SHOWN,"true");
					}
				} 
				else if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_G4_INFO_SCREEN_SHOWN) == "false" && !TutorialService.isActive) 
				{
					if (CGMBlueToothDevice.knowsFSLAge())
					{
						//variables are named miaomiao but this is used for all FSL peripherals, ie all type limitter
						var alertMiaoMiao:Alert = AlertManager.showSimpleAlert
							(
								ModelLocator.resourceManagerInstance.getString('transmitterscreen','alert_info_title'),
								ModelLocator.resourceManagerInstance.getString('transmitterscreen','miaomiao_info_screen')
							);
						alertMiaoMiao.height = 400;
					}
					else
					{
						var alertMessageG4:String = ModelLocator.resourceManagerInstance.getString('transmitterscreen','g4_info_screen');
						if (Sensor.getActiveSensor() == null)
							alertMessageG4 += "\n\n" + ModelLocator.resourceManagerInstance.getString('transmitterscreen','sensor_not_started');
						
						var alertG4:Alert = AlertManager.showSimpleAlert
							(
								ModelLocator.resourceManagerInstance.getString('transmitterscreen','alert_info_title'),
								alertMessageG4
							);
						alertG4.height = 400;
					}
					
					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_G4_INFO_SCREEN_SHOWN,"true");
				}
			}
		}
		
		private static function setup3DTouch():void
		{
			if(Capabilities.cpuArchitecture == "ARM") 
			{
				var touch:Touch3D = new Touch3D();
				if (touch.isSupported() || Constants.deviceModel == DeviceInfo.IPHONE_6_6S_7_8)
				{
					touch.init();
					touch.addEventListener(Touch3DEvent.SHORTCUT_ITEM, itemStatus);
					touch.removeShortcutItem("calibration");
					touch.removeShortcutItem("startsensor");
					touch.removeShortcutItem("stopsensor");
					touch.addShortcutItem("calibration", ModelLocator.resourceManagerInstance.getString('3dtouch','calibration_menu'), "", "UIApplicationShortcutIconTypeAdd");
					touch.addShortcutItem("startsensor", ModelLocator.resourceManagerInstance.getString('3dtouch','start_sensor_menu'), "", "UIApplicationShortcutIconTypeConfirmation");
					touch.addShortcutItem("stopsensor", ModelLocator.resourceManagerInstance.getString('3dtouch','stop_sensor_menu'), "", "UIApplicationShortcutIconTypeProhibit");
				}
			}
		}
		
		private static function itemStatus(e:Touch3DEvent):void
		{
			if (e.itemValue == "calibration")
				Starling.juggler.delayCall(CalibrationService.calibrationOnRequest, 0.4);
			else if (e.itemValue == "stopsensor")
			{
				Starling.juggler.delayCall(stopSensor, 0.4);
				
				function stopSensor():void
				{
					AlertManager.showActionAlert(
						ModelLocator.resourceManagerInstance.getString('sensorscreen','stop_sensor_alert_title'),
						ModelLocator.resourceManagerInstance.getString('sensorscreen','stop_sensor_alert_message'),
						60,
						[
							{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations','cancel_button_label').toUpperCase() },
							{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations','stop_alert_button_label'), triggered: onStopSensorTriggered }
						]
					);
				}
			}
			else if (e.itemValue == "startsensor")
			{
				Starling.juggler.delayCall(startSensor, 0.4);
				
				function startSensor():void
				{
					if (Sensor.getActiveSensor() == null)
						AppInterface.instance.navigator.pushScreen(Screens.SENSOR_START);
					else
					{
						AlertManager.showActionAlert(
							ModelLocator.resourceManagerInstance.getString('sensorscreen','sensor_active_alert_title'),
							ModelLocator.resourceManagerInstance.getString('sensorscreen','sensor_active_alert_message'),
							60,
							[
								{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations','cancel_button_label').toUpperCase() },
								{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations','stop_alert_button_label'), triggered: onStopSensorTriggered }
							]
						);
					}
				}
			}
		}
		
		private static function onStopSensorTriggered(e:starling.events.Event):void
		{
			/* Stop the Sensor */
			Sensor.stopSensor();
			NotificationService.updateBgNotification(null);
			
			/* Navigate to the Start Sensor screen */
			AppInterface.instance.navigator.pushScreen(Screens.SENSOR_START);
		}
		/**
		 * Notification Event Handlers
		 */
		public static function notificationServiceInitiated(e:NotificationServiceEvent):void 
		{
			NotificationService.updateBgNotification(null);
			
			/* Display Initial Disclaimer */
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_DISCLAIMER_ACCEPTED) == "false")
			{
				var disclaimerAlert:Alert = AlertManager.showActionAlert
				(
					ModelLocator.resourceManagerInstance.getString('disclaimerscreen', "screen_title"),
					ModelLocator.resourceManagerInstance.getString('disclaimerscreen', "disclaimer_content") + "\n\n" + ModelLocator.resourceManagerInstance.getString('disclaimerscreen', "important_notice_label").toUpperCase() + "\n\n" + ModelLocator.resourceManagerInstance.getString('disclaimerscreen', "important_notice_content"),
					Number.NaN,
					[
						{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations', "agree_alert_button_label"), triggered: onDisclaimerAccepted }
					]
				);
				disclaimerAlert.height = 420;	
			}
			else
				onDisclaimerAccepted(null);
		}
		
		private static function onDisclaimerAccepted (e:starling.events.Event):void
		{
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_DISCLAIMER_ACCEPTED, "true");
			
			/* Display Initial License Agreement */
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_LICENSE_INFO_ACCEPTED) == "false")
			{
				var licenseAlert:Alert = AlertManager.showActionAlert
				(
					ModelLocator.resourceManagerInstance.getString('globaltranslations', "license_alert_title"),
					ModelLocator.resourceManagerInstance.getString('globaltranslations', "license_alert_message"),
					Number.NaN,
					[
						{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations', "agree_alert_button_label"), triggered: onLicenseAccepted }
					]
				);
				licenseAlert.height = 420;
			}
		}
		
		private static function onLicenseAccepted (e:starling.events.Event):void
		{
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_LICENSE_INFO_ACCEPTED, "true");
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_SELECTION_UNIT_DONE) == "false") 
			{
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_SELECTION_UNIT_DONE,"true");
				
				/* Start Tutorial */
				TutorialService.init();
			} 
		}
		
		/**
		 * Bluetooth Event Handlers
		 */
		private static function blueToothServiceInitiated(be:BlueToothServiceEvent):void 
		{
			CGMBluetoothService.instance.addEventListener(BlueToothServiceEvent.DEVICE_NOT_PAIRED, deviceNotPaired);
			CGMBluetoothService.instance.addEventListener(BlueToothServiceEvent.BLUETOOTH_DEVICE_CONNECTION_COMPLETED, bluetoothDeviceConnectionCompleted);
			BluetoothLE.service.centralManager.addEventListener(PeripheralEvent.DISCONNECT, central_peripheralDisconnectHandler);
			SpikeANE.instance.addEventListener(SpikeANEEvent.MIAOMIAO_CONNECTED, bluetoothDeviceConnectionCompleted);
			SpikeANE.instance.addEventListener(SpikeANEEvent.MIAOMIAO_DISCONNECTED, central_peripheralDisconnectHandler);
			SpikeANE.instance.addEventListener(SpikeANEEvent.G5_CONNECTED, bluetoothDeviceConnectionCompleted);
			SpikeANE.instance.addEventListener(SpikeANEEvent.G5_DISCONNECTED, central_peripheralDisconnectHandler);
			
			//Statusbar
			SpikeANE.setStatusBarToWhite();
		}
		
		private static function deviceNotPaired(event:flash.events.Event):void 
		{
			if (SpikeANE.appIsInForeground())
				return;
			
			if (CGMBlueToothDevice.isBluKon())
				return; //blukon keeps on trying to connect, there's always a request to pair, no need to give additional comments
			
			AlertManager.showSimpleAlert
			(
				ModelLocator.resourceManagerInstance.getString("transmitterscreen","device_not_paired_alert_title"),
				ModelLocator.resourceManagerInstance.getString("transmitterscreen","device_not_paired_alert_message"),
				240,
				deviceNotPairedAlertClosed
			);
		}
		
		private static function deviceNotPairedAlertClosed(event:starling.events.Event):void 
		{
			Notifications.service.cancel(NotificationService.ID_FOR_DEVICE_NOT_PAIRED);
		}
		
		private static function bluetoothDeviceConnectionCompleted(event:flash.events.Event):void 
		{
			Trace.myTrace("interfaceController.as", "in bluetoothDeviceConnectionCompleted");
			if (!peripheralConnected) 
			{
				Trace.myTrace("interfaceController.as", "in bluetoothDeviceConnectionCompleted, setting peripheralConnected = true");
				peripheralConnected = true;
				peripheralConnectionStatusChangeTimestamp = (new Date()).valueOf();
			}
		}
		
		private static function central_peripheralDisconnectHandler(event:flash.events.Event):void 
		{
			if (peripheralConnected) 
			{
				Trace.myTrace("interfaceController.as", "in central_peripheralDisconnectHandler, setting peripheralConnected = false");
				peripheralConnected = false;
				peripheralConnectionStatusChangeTimestamp = (new Date()).valueOf();
			}
		}
		
		public static function btScanningStopped(event:BlueToothServiceEvent):void 
		{
			CGMBluetoothService.instance.removeEventListener(BlueToothServiceEvent.STOPPED_SCANNING, InterfaceController.btScanningStopped);
			
			if (!CGMBluetoothService.bluetoothPeripheralActive()) 
			{
				AlertManager.showSimpleAlert
				(
					ModelLocator.resourceManagerInstance.getString('transmitterscreen',"scanning_failed_alert_title"),
					ModelLocator.resourceManagerInstance.getString('transmitterscreen',"scanning_failed_message") + (CGMBlueToothDevice.known() ? (" " + ModelLocator.resourceManagerInstance.getString('transmitterscreen',"with_name") + " " + CGMBlueToothDevice.name) + "\n\n" + ModelLocator.resourceManagerInstance.getString('transmitterscreen',"explain_expected_device_name"): ""),
					Number.NaN,
					null,
					HorizontalAlign.CENTER
				);	
			}
		}
		
		public static function userInitiatedBTScanningSucceeded(event:flash.events.Event):void 
		{
			BluetoothLE.service.centralManager.removeEventListener(PeripheralEvent.CONNECT, InterfaceController.userInitiatedBTScanningSucceeded);
			SpikeANE.instance.removeEventListener(SpikeANEEvent.MIAOMIAO_CONNECTED, InterfaceController.userInitiatedBTScanningSucceeded);
			
			//Vibrate device to warn user that scan was successful
			SpikeANE.vibrate();
			
			/*AlertManager.showSimpleAlert
			(
				ModelLocator.resourceManagerInstance.getString('transmitterscreen',"scan_for_device_alert_title"),
				ModelLocator.resourceManagerInstance.getString('transmitterscreen',"connected_to_peripheral_device_id_stored"),
				30
			);*/
		}
		
		/**
		 * Spike Database Import
		 */
		private static function onInvoke(event:InvokeEvent):void 
		{
			if (event == null || event.arguments == null || (event.arguments as Array).length == 0 || event.arguments[0] == null)
				return;
			
			var now:Number = new Date().valueOf();
			if (now - lastInvoke > 5000)
			{
				//Do nothing.
			}
			else
			{
				return;
			}
			
			var items:Array = event.arguments;
			
			if ( items.length > 0 ) 
			{
				var isZip:Boolean = false;
				
				var file:File = new File( event.arguments[0] );
				if (((file.type == ".db" && file.extension == "db") || (file.type == ".zip" && file.extension == "zip")) && file.name.indexOf("spike") != -1 && file.size > 0)
				{
					lastInvoke = now;
					
					if (file.type == ".zip" && file.extension == "zip")
					{
						isZip = true;
					}
					
					var alert:Alert = Alert.show
						(
							ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','database_restore_confirmation_label'),
							ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
							new ListCollection
							(
								[
									{ label: ModelLocator.resourceManagerInstance.getString("globaltranslations","no_uppercase"), triggered: ignoreRestore  },	
									{ label: ModelLocator.resourceManagerInstance.getString("globaltranslations","yes_uppercase"), triggered: restoreDatabase }	
								]
							)
						)
					alert.buttonGroupProperties.gap = 10;
					alert.buttonGroupProperties.horizontalAlign = HorizontalAlign.CENTER;
					alert.messageFactory = function():ITextRenderer
					{
						var messageRenderer:TextBlockTextRenderer = new TextBlockTextRenderer();
						messageRenderer.textJustifier = new SpaceJustifier( "en", LineJustification.ALL_BUT_MANDATORY_BREAK);
						
						return messageRenderer;
					};
					
					function restoreDatabase(e:starling.events.Event):void
					{
						var canProceed:Boolean = false;
						
						if (!isZip)
						{
							//Read file into memory
							var databaseStream:FileStream = new FileStream();
							databaseStream.open(file, FileMode.READ);
							
							//Read database raw bytes into memory
							backupDatabaseData = new ByteArray();
							databaseStream.readBytes(backupDatabaseData);
							databaseStream.close();
							
							canProceed = true;
						}
						else
						{
							var zipArchive:ZipFileReader = new ZipFileReader();
							zipArchive.open(file);
							
							var list:Array = zipArchive.getEntries();
							for each(var entry:ZipEntry in list)
							{
								if(!entry.isDirectory())
								{
									if(entry.getFilename() == "spike.db")
									{
										backupDatabaseData = zipArchive.unzip(entry);
										canProceed = true;
									}
								}
							}
						}
						
						//Delete file
						if (file != null)
							file.deleteFile();
						
						if (canProceed && backupDatabaseData != null)
						{
							//Notify ANE
							SpikeANE.setDatabaseResetStatus(true);
							
							//Halt Spike
							Trace.myTrace("Spike.as", "Halting Spike...");
							Database.instance.addEventListener(DatabaseEvent.DATABASE_CLOSED_EVENT, onLocalDatabaseClosed);
							Spike.haltApp();
						}
					}
					
					function ignoreRestore(e:starling.events.Event):void
					{
						//Delete file
						if (file != null)
							file.deleteFile();
					}
				}
			}
		}
		
		private static function onLocalDatabaseClosed(e:DatabaseEvent):void
		{
			Trace.myTrace("Spike.as", "Spike halted and local database connection closed!");
			
			NativeApplication.nativeApplication.removeEventListener(InvokeEvent.INVOKE, onInvoke);
			
			//Restore database
			var databaseTargetFile:File = File.documentsDirectory.resolvePath("spike.db");
			var databaseFileStream:FileStream = new FileStream();
			databaseFileStream.open(databaseTargetFile, FileMode.WRITE);
			databaseFileStream.writeBytes(backupDatabaseData, 0, backupDatabaseData.length);
			databaseFileStream.close();
			
			//Alert user
			var alert:Alert = Alert.show
			(
				ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','restore_successfull_label'),
				ModelLocator.resourceManagerInstance.getString('globaltranslations','success_alert_title')
			);
			alert.buttonsDataProvider = new ListCollection(
				[
					{ label: ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','terminate_spike_button_label'), triggered: onTerminateSpike }
				]
			);
			alert.messageFactory = function():ITextRenderer
			{
				var messageRenderer:TextBlockTextRenderer = new TextBlockTextRenderer();
				messageRenderer.textJustifier = new SpaceJustifier( "en", LineJustification.ALL_BUT_MANDATORY_BREAK);
				
				return messageRenderer;
			};
			
			Trace.myTrace("Spike.as", "Database successfully restored!");
			
			function onTerminateSpike(e:starling.events.Event):void
			{
				SpikeANE.terminateApp();
			}
		}
		
		/**
		 * Getters & Setters
		 */
		public static function get instance():InterfaceController
		{
			if (_instance == null)
				return new InterfaceController();
			
			return _instance;
		}
	}
}