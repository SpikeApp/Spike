package ui.screens.display.transmitter
{
	
	import com.distriqt.extension.bluetoothle.BluetoothLE;
	import com.distriqt.extension.bluetoothle.BluetoothLEState;
	import com.distriqt.extension.bluetoothle.events.PeripheralEvent;
	import com.spikeapp.spike.airlibrary.SpikeANE;
	import com.spikeapp.spike.airlibrary.SpikeANEEvent;
	
	import flash.desktop.NativeApplication;
	import flash.desktop.SystemIdleMode;
	import flash.display.StageOrientation;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	import spark.formatters.DateTimeFormatter;
	
	import G5G6Model.G5G6VersionInfo;
	import G5G6Model.TransmitterStatus;
	import G5G6Model.VersionRequestRxMessage;
	
	import database.CGMBlueToothDevice;
	import database.Calibration;
	import database.CommonSettings;
	import database.Sensor;
	
	import events.BlueToothServiceEvent;
	import events.SettingsServiceEvent;
	
	import feathers.controls.Alert;
	import feathers.controls.Button;
	import feathers.controls.GroupedList;
	import feathers.controls.Label;
	import feathers.controls.LayoutGroup;
	import feathers.controls.TextCallout;
	import feathers.controls.renderers.DefaultGroupedListHeaderOrFooterRenderer;
	import feathers.controls.renderers.DefaultGroupedListItemRenderer;
	import feathers.controls.renderers.IGroupedListHeaderRenderer;
	import feathers.controls.renderers.IGroupedListItemRenderer;
	import feathers.controls.text.TextBlockTextRenderer;
	import feathers.core.ITextRenderer;
	import feathers.data.HierarchicalCollection;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.HorizontalLayout;
	import feathers.layout.RelativePosition;
	import feathers.layout.VerticalAlign;
	import feathers.layout.VerticalLayoutData;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.ModelLocator;
	
	import services.bluetooth.CGMBluetoothService;
	
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.Image;
	import starling.events.Event;
	import starling.events.ResizeEvent;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.textures.Texture;
	import starling.utils.SystemUtil;
	
	import ui.AppInterface;
	import ui.InterfaceController;
	import ui.popups.AlertManager;
	import ui.screens.Screens;
	import ui.screens.display.LayoutFactory;
	
	import utils.Constants;
	import utils.DeviceInfo;
	import utils.Trace;
	
	[ResourceBundle("transmitterscreen")]
	[ResourceBundle("treatments")]
	[ResourceBundle("globaltranslations")]

	public class TransmitterStatusList extends GroupedList 
	{
		/* Display Objects */
		private var voltageAIconTexture:Texture;
		private var voltageAIcon:Image;
		private var voltageALabel:Label;
		private var voltageBIconTexture:Texture;
		private var voltageBIcon:Image;
		private var voltageBLabel:Label;
		private var resistanceIconTexture:Texture;
		private var resistanceIcon:Image;
		private var resistanceLabel:Label;
		private var batteryLevelIconTexture:Texture;
		private var batteryLevelIcon:Image;
		private var batteryLevelLabel:Label;
		private var transmitterTypeLabel:Label;
		private var transmitterNameLabel:Label;
		private var transmitterConnectionStatusLabel:Label;
		private var scanButton:Button;
		private var scanButtonIcon:Texture;
		private var forgetButton:Button;
		private var forgetButtonIcon:Texture;
		private var temperatureLabel:Label;
		private var refreshG5G6BatteryButton:Button;
		private var lastG5G6BatteryUpdateLabel:Label;
		private var batteryStatusG5Callout:TextCallout;
		private var transmitterRuntimeLabel:Label;
		private var screenRefreshLabel:Label;
		private var transmitterFirmwareLabel:Label;
		private var resetG5G6TransmitterButton:Button;
		private var g5G6ActionContainer:LayoutGroup;
		private var otherFirmwareLabel:Label;
		private var bluetoothFirmwareLabel:Label;
		private var transmitterMACAddressLabel:Label;
		
		/* Properties */
		private var transmitterNameValue:String;
		private var transmitterTypeValue:String;
		private var voltageAValue:String;
		private var voltageAStatus:String = "";
		private var voltageBValue:String;
		private var voltageBStatus:String = "";
		private var resistanceValue:String;
		private var resistanceStatus:String = "";
		private var batteryLevelValue:String;
		private var transmitterConnectionStatusValue:String;
		private var temperatureValue:String;
		private var lastG5G6BatteryUpdateValue:String;
		private var timestampForRefresh:Number;
		private var nowDate:Date;
		private var transmitterRuntimeValue:String;
		private var sensorRxTimestamp:Number;
		private var refreshSecondsElapsed:int = 4;
		private var transmitterFirmwareValue:String = "";
		private var transmitterOtherFirmwareValue:String = "";
		private var transmitterBTFirmwareValue:String = "";
		private var timeOut1:uint = 0;
		private var timeOut2:uint = 0;

		/* Objects */
		private var refreshTimer:Timer;

		public function TransmitterStatusList()
		{
			super();
		}
		override protected function initialize():void 
		{
			super.initialize();
			
			Starling.current.stage.addEventListener(starling.events.Event.RESIZE, onStarlingResize);
			
			setupProperties();
			setupInitialState();
			setupContent();
			setupEventListeners();
			setupRefreshTimer();
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
			layoutData = new VerticalLayoutData( 100 );
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
		}
		
		private function setupInitialState():void
		{
			/* Get transmitter name */
			if (CGMBlueToothDevice.known()) transmitterNameValue = CGMBlueToothDevice.name;
			else transmitterNameValue = ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_unknown');
			
			/* Get connectiion status */
			// Only for xDrip type of device the status will be shown because peripheralConnected is usually not connected for Dexcom (or others alike) and peripheralConnectionStatusChangeTimestamp is not being set for Dexcom (or others alike)
			if (InterfaceController.peripheralConnected)
				transmitterConnectionStatusValue = ModelLocator.resourceManagerInstance.getString('transmitterscreen','connection_status_connected');
			else if (!isNaN(InterfaceController.peripheralConnectionStatusChangeTimestamp))
				transmitterConnectionStatusValue = ModelLocator.resourceManagerInstance.getString('transmitterscreen','connection_status_last_connection') + " " + InterfaceController.dateFormatterForSensorStartTimeAndDate.format(new Date(InterfaceController.peripheralConnectionStatusChangeTimestamp));
			
			/* Battery and Transmitter Type */
			if (CGMBlueToothDevice.isDexcomG5() || CGMBlueToothDevice.isDexcomG6()) 
			{
				/* Transmitter Type */
				transmitterTypeValue = CGMBlueToothDevice.isDexcomG5() ? ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_dexcom_g5') : ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_dexcom_g6');
				
				/* Transmitter Firmware */
				var dexcomG5G6TransmitterInfo:VersionRequestRxMessage = G5G6VersionInfo.getG5G6VersionInfo();
				
				transmitterFirmwareValue = dexcomG5G6TransmitterInfo.firmware_version_string;
				if (transmitterFirmwareValue == "")
					transmitterFirmwareValue = ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_unknown');
				
				transmitterOtherFirmwareValue = dexcomG5G6TransmitterInfo.other_firmware_version;
				if (transmitterOtherFirmwareValue == "")
					transmitterOtherFirmwareValue = ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_unknown');
				
				transmitterBTFirmwareValue = dexcomG5G6TransmitterInfo.bluetooth_firmware_version_string;
				if (transmitterBTFirmwareValue == "")
					transmitterBTFirmwareValue = ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_unknown');
				
				dexcomG5G6TransmitterInfo = null;
				
				/* Transmitter Runtime */
				transmitterRuntimeValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_G5_G6_RUNTIME);
				if (transmitterRuntimeValue == "unknown")
					transmitterRuntimeValue = ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_unknown');
				sensorRxTimestamp = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_G5_G6_SENSOR_RX_TIMESTAMP));
				if (sensorRxTimestamp > 0 && transmitterRuntimeValue != ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_unknown'))
				{
					transmitterRuntimeValue += " / " + String(int((sensorRxTimestamp / 86400) *10) / 10);
				}
				
				/* Voltage A */
				voltageAValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_G5_G6_VOLTAGEA);
				if (voltageAValue == "unknown" || transmitterNameValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_unknown')) voltageAValue = ModelLocator.resourceManagerInstance.getString('transmitterscreen','battery_unknown');
				
				if (voltageAValue != ModelLocator.resourceManagerInstance.getString('transmitterscreen','battery_unknown'))
				{
					if (CGMBlueToothDevice.isDexcomG5())
						voltageAStatus = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_G5_G6_VOLTAGEA)) < G5G6Model.TransmitterStatus.LOW_BATTERY_WARNING_LEVEL_VOLTAGEA_G5 ? ModelLocator.resourceManagerInstance.getString('transmitterscreen','voltage_status_low'):ModelLocator.resourceManagerInstance.getString('transmitterscreen','voltage_status_ok');
					else if (CGMBlueToothDevice.isDexcomG6())
						voltageAStatus = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_G5_G6_VOLTAGEA)) < G5G6Model.TransmitterStatus.LOW_BATTERY_WARNING_LEVEL_VOLTAGEA_G6 ? ModelLocator.resourceManagerInstance.getString('transmitterscreen','voltage_status_low'):ModelLocator.resourceManagerInstance.getString('transmitterscreen','voltage_status_ok');
				}
					
				/* Voltage B */
				voltageBValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_G5_G6_VOLTAGEB);
				if (voltageBValue == "unknown" || transmitterNameValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_unknown')) voltageBValue = ModelLocator.resourceManagerInstance.getString('transmitterscreen','battery_unknown');
				
				if (voltageBValue != ModelLocator.resourceManagerInstance.getString('transmitterscreen','battery_unknown'))
				{
					if (CGMBlueToothDevice.isDexcomG5())
						voltageBStatus = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_G5_G6_VOLTAGEB)) < G5G6Model.TransmitterStatus.LOW_BATTERY_WARNING_LEVEL_VOLTAGEB_G5 ? ModelLocator.resourceManagerInstance.getString('transmitterscreen','voltage_status_low'):ModelLocator.resourceManagerInstance.getString('transmitterscreen','voltage_status_ok'); 
					else if (CGMBlueToothDevice.isDexcomG6())
						voltageBStatus = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_G5_G6_VOLTAGEB)) < G5G6Model.TransmitterStatus.LOW_BATTERY_WARNING_LEVEL_VOLTAGEB_G6 ? ModelLocator.resourceManagerInstance.getString('transmitterscreen','voltage_status_low'):ModelLocator.resourceManagerInstance.getString('transmitterscreen','voltage_status_ok'); 
				}
				
				/* Resistance */
				resistanceValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_G5_G6_RESIST);
				if (resistanceValue == "unknown" || transmitterNameValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_unknown')) resistanceValue = ModelLocator.resourceManagerInstance.getString('transmitterscreen','battery_unknown');
				
				if (resistanceValue != ModelLocator.resourceManagerInstance.getString('transmitterscreen','battery_unknown'))
				{
					if (CGMBlueToothDevice.isDexcomG5())
						resistanceStatus = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_G5_G6_RESIST)) > G5G6Model.TransmitterStatus.RESIST_BAD_G5 ? ModelLocator.resourceManagerInstance.getString('transmitterscreen','resistance_status_bad'):(Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_G5_G6_RESIST)) > G5G6Model.TransmitterStatus.RESIST_NOTICE_G5 ? ModelLocator.resourceManagerInstance.getString('transmitterscreen','resistance_status_notice'):(Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_G5_G6_RESIST)) > G5G6Model.TransmitterStatus.RESIST_NORMAL_G5 ? ModelLocator.resourceManagerInstance.getString('transmitterscreen','resistance_status_normal'):ModelLocator.resourceManagerInstance.getString('transmitterscreen','resistance_status_good')));
					else if (CGMBlueToothDevice.isDexcomG6())
						resistanceStatus = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_G5_G6_RESIST)) > G5G6Model.TransmitterStatus.RESIST_BAD_G6 ? ModelLocator.resourceManagerInstance.getString('transmitterscreen','resistance_status_bad'):(Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_G5_G6_RESIST)) > G5G6Model.TransmitterStatus.RESIST_NOTICE_G6 ? ModelLocator.resourceManagerInstance.getString('transmitterscreen','resistance_status_notice'):(Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_G5_G6_RESIST)) > G5G6Model.TransmitterStatus.RESIST_NORMAL_G6 ? ModelLocator.resourceManagerInstance.getString('transmitterscreen','resistance_status_normal'):ModelLocator.resourceManagerInstance.getString('transmitterscreen','resistance_status_good')));
				}
				
				/* Temperature */
				var temperatureValueNumber:Number = Math.abs(Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_G5_G6_TEMPERATURE)));
				
				temperatureValue = "";
				if (isNaN(temperatureValueNumber) || String(temperatureValueNumber) == "0" || String(temperatureValueNumber) == "" || String(temperatureValueNumber).toUpperCase() == ModelLocator.resourceManagerInstance.getString('transmitterscreen','battery_unknown').toUpperCase())
					temperatureValue = ModelLocator.resourceManagerInstance.getString('transmitterscreen','battery_unknown');
				else
				{
					var temperatureCelsius:Number;
					var temperatureFahrenheit:Number;
					
					if (temperatureValueNumber < 60) //Celsius
					{
						temperatureCelsius = Math.round(temperatureValueNumber * 10) / 10;
						temperatureFahrenheit = Math.round(((temperatureValueNumber * 1.8) + 32) * 10) / 10;
					}
					else //Fahrenheit
					{
						temperatureFahrenheit = Math.round(temperatureValueNumber * 10) / 10;
						temperatureCelsius = Math.round(((temperatureValueNumber - 32) / 1.8) * 10) / 10;
					}
					
					temperatureValue = String(temperatureCelsius) + "ºC" + " / " + String(temperatureFahrenheit) + "ºF";
				}	
				
				/* Last Update */
				var lastG5G6BatteryUpdateTimestamp:String = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_G5_G6_BATTERY_FROM_MARKER);
				
				if (lastG5G6BatteryUpdateTimestamp == "0" || lastG5G6BatteryUpdateTimestamp == "")
				{
					lastG5G6BatteryUpdateValue = ModelLocator.resourceManagerInstance.getString('transmitterscreen','last_update_label') + ": " + ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available');
					
					nowDate = new Date();
					timestampForRefresh = nowDate.setFullYear(nowDate.getFullYear() - 1);
				}
				else
				{
					nowDate = new Date();
					var lastUpdateDate:Date = new Date(Number(lastG5G6BatteryUpdateTimestamp));
					
					if (nowDate.fullYear - lastUpdateDate.fullYear > 1)
					{
						lastG5G6BatteryUpdateValue = ModelLocator.resourceManagerInstance.getString('transmitterscreen','last_update_label') + ": " + ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available');
						
						timestampForRefresh = nowDate.setFullYear(nowDate.getFullYear() - 1);
					}
					else
					{
						timestampForRefresh = lastUpdateDate.setFullYear(lastUpdateDate.getFullYear() - 1);
						
						var dateFormatterForSensorStartTimeAndDate:DateTimeFormatter = new DateTimeFormatter();
						dateFormatterForSensorStartTimeAndDate.dateTimePattern = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_DATE_FORMAT).slice(0,2) == "24" ? "dd MMM HH:mm" : "dd MMM h:mm a";
						dateFormatterForSensorStartTimeAndDate.useUTC = false;
						dateFormatterForSensorStartTimeAndDate.setStyle("locale", Constants.getUserLocale());
						
						lastG5G6BatteryUpdateValue = ModelLocator.resourceManagerInstance.getString('transmitterscreen','last_update_label') + ": " + dateFormatterForSensorStartTimeAndDate.format(lastUpdateDate);
					}
				}
				
			}
			else if (CGMBlueToothDevice.isDexcomG4()) 
			{
				/* Transmitter Type */
				transmitterTypeValue = ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_dexcom_g4');
				
				/* Battery Level */
				batteryLevelValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_G4_TRANSMITTER_BATTERY_VOLTAGE);
				
				if (batteryLevelValue.toUpperCase() == "0" || batteryLevelValue.toUpperCase() == "UNKNOWN" || transmitterNameValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_unknown')) 
					batteryLevelValue = ModelLocator.resourceManagerInstance.getString('transmitterscreen','battery_unknown');
			}
			else if (CGMBlueToothDevice.isBlueReader())
			{
				/* Transmitter Type */
				transmitterTypeValue = ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_bluereader');
				
				/* Battery Level */
				batteryLevelValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BLUEREADER_BATTERY_LEVEL);
				
				if (batteryLevelValue == "0" || transmitterNameValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_unknown')) 
					batteryLevelValue = ModelLocator.resourceManagerInstance.getString('transmitterscreen','battery_unknown');
				else
					batteryLevelValue = String(Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BLUEREADER_BATTERY_LEVEL)))  + "%";
			}
			else if (CGMBlueToothDevice.isTransmiter_PL())
			{
				/* Transmitter Type */
				transmitterTypeValue = ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_transmitter_pl');
				
				/* Battery Level */
				batteryLevelValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BLUEREADER_BATTERY_LEVEL);
				
				if (batteryLevelValue == "0" || transmitterNameValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_unknown')) 
					batteryLevelValue = ModelLocator.resourceManagerInstance.getString('transmitterscreen','battery_unknown');
				else
					batteryLevelValue = String(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BLUEREADER_BATTERY_LEVEL) + "%");
			}
			else if (CGMBlueToothDevice.isMiaoMiao())
			{
				/* Transmitter Type */
				transmitterTypeValue = ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_miaomiao');
				
				/* Transmitter Firmware */
				transmitterFirmwareValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_MIAOMIAO_FW);
				if (transmitterFirmwareValue == "" || transmitterNameValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_unknown'))
					transmitterFirmwareValue = ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_unknown');
				
				/* Battery Level */
				batteryLevelValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_MIAOMIAO_BATTERY_LEVEL);
				
				if (batteryLevelValue == "0" || transmitterNameValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_unknown')) 
					batteryLevelValue = ModelLocator.resourceManagerInstance.getString('transmitterscreen','battery_unknown');
				else
					batteryLevelValue = String(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_MIAOMIAO_BATTERY_LEVEL) + "%");
			}
			else if (CGMBlueToothDevice.isBluKon())
			{
				/* Transmitter Type */
				transmitterTypeValue = ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_blucon');
				
				/* Battery Level */
				batteryLevelValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BLUKON_BATTERY_LEVEL) + "%";
				if (batteryLevelValue == "0" || transmitterNameValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_unknown') || !InterfaceController.peripheralConnected)
					batteryLevelValue = ModelLocator.resourceManagerInstance.getString('transmitterscreen','battery_unknown');
			}
			else if (CGMBlueToothDevice.isLimitter())
			{
				/* Transmitter Type */
				transmitterTypeValue = ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_limitter');
				
				/* Battery Level */
				batteryLevelValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BLUEREADER_BATTERY_LEVEL);
				if (batteryLevelValue == "0" || transmitterNameValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_unknown')) 
					batteryLevelValue = ModelLocator.resourceManagerInstance.getString('transmitterscreen','battery_unknown');
				else
					batteryLevelValue = String((Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BLUEREADER_BATTERY_LEVEL)))/1000);
			}
			
			// Set Transmitter Type and Battery Level for cases where the user hasn't yet configured any device in app settings
			if (transmitterTypeValue == null || transmitterTypeValue == "")
				transmitterTypeValue = ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_unknown');
			
			if (batteryLevelValue == null || batteryLevelValue == "")
				batteryLevelValue = ModelLocator.resourceManagerInstance.getString('transmitterscreen','battery_unknown');	
		}
		
		private function setupContent():void
		{
			if (!SystemUtil.isApplicationActive)
			{
				SystemUtil.executeWhenApplicationIsActive(setupContent);
				return;
			}
			
			/* Define Battery Status Icons*/
			if (transmitterTypeValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_dexcom_g5') || transmitterTypeValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_dexcom_g6')) //Dexcom G5/G6
			{
				/* Voltage A */
				if (voltageAStatus == ModelLocator.resourceManagerInstance.getString('transmitterscreen','battery_unknown') || transmitterNameValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_unknown'))
					voltageAIconTexture = MaterialDeepGreyAmberMobileThemeIcons.batteryUnknownTexture;
				else if (voltageAStatus == ModelLocator.resourceManagerInstance.getString('transmitterscreen','voltage_status_ok'))
					voltageAIconTexture = MaterialDeepGreyAmberMobileThemeIcons.batteryOkTexture;
				else if(voltageAStatus == ModelLocator.resourceManagerInstance.getString('transmitterscreen','voltage_status_low'))
					voltageAIconTexture = MaterialDeepGreyAmberMobileThemeIcons.batteryBadTexture;
				
				if(voltageAIconTexture != null)
				{
					voltageAIcon = new Image(voltageAIconTexture);
					voltageAIcon.name = "voltageAIcon";
				}
				
				/* Voltage B */
				if (voltageBStatus == ModelLocator.resourceManagerInstance.getString('transmitterscreen','battery_unknown') || transmitterNameValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_unknown'))
					voltageBIconTexture = MaterialDeepGreyAmberMobileThemeIcons.batteryUnknownTexture;
				else if (voltageBStatus == ModelLocator.resourceManagerInstance.getString('transmitterscreen','voltage_status_ok'))
					voltageBIconTexture = MaterialDeepGreyAmberMobileThemeIcons.batteryOkTexture;
				else if(voltageBStatus == ModelLocator.resourceManagerInstance.getString('transmitterscreen','voltage_status_low'))
					voltageBIconTexture = MaterialDeepGreyAmberMobileThemeIcons.batteryBadTexture;
				
				if(voltageBIconTexture != null)
				{
					voltageBIcon = new Image(voltageBIconTexture);
					voltageBIcon.name = "voltageBIcon";
				}
				
				/* Resistance */
				if (resistanceStatus == ModelLocator.resourceManagerInstance.getString('transmitterscreen','battery_unknown') || transmitterNameValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_unknown'))
					resistanceIconTexture = MaterialDeepGreyAmberMobileThemeIcons.batteryUnknownTexture;
				else if(resistanceStatus == ModelLocator.resourceManagerInstance.getString('transmitterscreen','resistance_status_normal') || resistanceStatus == ModelLocator.resourceManagerInstance.getString('transmitterscreen','resistance_status_good'))
					resistanceIconTexture = MaterialDeepGreyAmberMobileThemeIcons.batteryOkTexture;
				else if(resistanceStatus == ModelLocator.resourceManagerInstance.getString('transmitterscreen','resistance_status_notice'))
					resistanceIconTexture = MaterialDeepGreyAmberMobileThemeIcons.batteryAlertTexture;
				else if(resistanceStatus == ModelLocator.resourceManagerInstance.getString('transmitterscreen','resistance_status_bad'))
					resistanceIconTexture = MaterialDeepGreyAmberMobileThemeIcons.batteryBadTexture;
				
				if(resistanceIconTexture != null)
				{
					resistanceIcon = new Image(resistanceIconTexture);
					resistanceIcon.name = "resistanceIcon";
				}
			}
			else //Rest of the transmitters
			{
				if(batteryLevelValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','battery_unknown') || transmitterNameValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_unknown'))
					batteryLevelIconTexture = MaterialDeepGreyAmberMobileThemeIcons.batteryUnknownTexture;
				else
				{
					if (CGMBlueToothDevice.isDexcomG4())
					{
						var G4BatteryLevel:Number = Number(batteryLevelValue);
						if (G4BatteryLevel >= 213)
							batteryLevelIconTexture = MaterialDeepGreyAmberMobileThemeIcons.batteryOkTexture;
						else if (G4BatteryLevel > 210)
							batteryLevelIconTexture = MaterialDeepGreyAmberMobileThemeIcons.batteryAlertTexture;
						else 
							batteryLevelIconTexture = MaterialDeepGreyAmberMobileThemeIcons.batteryBadTexture;
					}
					else
					{
						if(Number(batteryLevelValue.replace("%", "").replace(" ", "")) > 40) //OK Battery
							batteryLevelIconTexture = MaterialDeepGreyAmberMobileThemeIcons.batteryOkTexture;
						else if(Number(batteryLevelValue.replace("%", "").replace(" ", "")) > 20) //Alert Battery
							batteryLevelIconTexture = MaterialDeepGreyAmberMobileThemeIcons.batteryAlertTexture;
						else //Low Battery
							batteryLevelIconTexture = MaterialDeepGreyAmberMobileThemeIcons.batteryBadTexture;
					}
				}
				
				if(batteryLevelIconTexture != null)
					batteryLevelIcon = new Image(batteryLevelIconTexture);
			}
			
			/* Define Info & Battery/Connection Status Labels */
			transmitterTypeLabel = LayoutFactory.createLabel(transmitterTypeValue, HorizontalAlign.RIGHT);
			transmitterNameLabel = LayoutFactory.createLabel(transmitterNameValue, HorizontalAlign.RIGHT);
			transmitterMACAddressLabel = LayoutFactory.createLabel(CGMBlueToothDevice.address != "" ? CGMBlueToothDevice.address : ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_unknown'), HorizontalAlign.RIGHT);
			transmitterMACAddressLabel.width = Constants.isPortrait ? 140 : 280;
			if (DeviceInfo.isTablet()) transmitterMACAddressLabel.width += 200;
			transmitterMACAddressLabel.wordWrap = true;
			if (CGMBlueToothDevice.isMiaoMiao())
				transmitterFirmwareLabel = LayoutFactory.createLabel(transmitterFirmwareValue, HorizontalAlign.RIGHT);
			
			if (transmitterConnectionStatusValue != null)
				transmitterConnectionStatusLabel = LayoutFactory.createLabel(transmitterConnectionStatusValue, HorizontalAlign.RIGHT);
			if (CGMBlueToothDevice.isDexcomG5() || CGMBlueToothDevice.isDexcomG6())
			{
				transmitterFirmwareLabel = LayoutFactory.createLabel(transmitterFirmwareValue, HorizontalAlign.RIGHT);
				otherFirmwareLabel = LayoutFactory.createLabel(transmitterOtherFirmwareValue, HorizontalAlign.RIGHT);
				bluetoothFirmwareLabel = LayoutFactory.createLabel(transmitterBTFirmwareValue, HorizontalAlign.RIGHT);
				transmitterRuntimeLabel = LayoutFactory.createLabel(transmitterRuntimeValue, HorizontalAlign.RIGHT);
			}
			
			if (transmitterTypeValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_dexcom_g5') || transmitterTypeValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_dexcom_g6'))
			{
				voltageALabel = LayoutFactory.createLabel(voltageAValue, HorizontalAlign.RIGHT);
				voltageBLabel = LayoutFactory.createLabel(voltageBValue, HorizontalAlign.RIGHT);
				resistanceLabel = LayoutFactory.createLabel(resistanceValue, HorizontalAlign.RIGHT);
				temperatureLabel = LayoutFactory.createLabel(temperatureValue, HorizontalAlign.RIGHT);
				lastG5G6BatteryUpdateLabel = LayoutFactory.createLabel(lastG5G6BatteryUpdateValue, HorizontalAlign.RIGHT, VerticalAlign.TOP, 10);
				
				/* G5/G6 Action Buttons */
				var g5G6ActionLayout:HorizontalLayout = new HorizontalLayout();
				g5G6ActionLayout.gap = 5;
				g5G6ActionContainer = new LayoutGroup();
				g5G6ActionContainer.pivotX = -15;
				g5G6ActionContainer.layout = g5G6ActionLayout;
				
				resetG5G6TransmitterButton = LayoutFactory.createButton(CGMBlueToothDevice.isDexcomG5() ? ModelLocator.resourceManagerInstance.getString('transmitterscreen',"reset_g5_button_label") : ModelLocator.resourceManagerInstance.getString('transmitterscreen',"reset_g5_button_label").replace("G5", "G6"), false, MaterialDeepGreyAmberMobileThemeIcons.undoTexture);
				resetG5G6TransmitterButton.addEventListener(Event.TRIGGERED, onResetG5G6);
				g5G6ActionContainer.addChild(resetG5G6TransmitterButton);
				
				refreshG5G6BatteryButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('transmitterscreen',"refresh_button_label"), false, MaterialDeepGreyAmberMobileThemeIcons.refreshTexture);
				refreshG5G6BatteryButton.addEventListener(Event.TRIGGERED, onRefreshG5G6BatteyInfo);
				g5G6ActionContainer.addChild(refreshG5G6BatteryButton);
			}
			else
			{
				batteryLevelLabel = LayoutFactory.createLabel(batteryLevelValue, HorizontalAlign.RIGHT);
			}
			
			/* Set Data */
			var screenDataContent:Array = [];
			
			/* Info Section */
			var infoSection:Object = {};
			infoSection.header = { label: ModelLocator.resourceManagerInstance.getString('transmitterscreen','info_section_title') };
			var infoSectionChildren:Array = [];
			infoSectionChildren.push({ label: ModelLocator.resourceManagerInstance.getString('transmitterscreen','data_source_label'), accessory: transmitterTypeLabel });
			infoSectionChildren.push({ label: ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_name_label'), accessory: transmitterNameLabel });
			infoSectionChildren.push({ label: ModelLocator.resourceManagerInstance.getString('transmitterscreen','mac_address_label'), accessory: transmitterMACAddressLabel });
			if (CGMBlueToothDevice.isMiaoMiao())
				infoSectionChildren.push({ label: ModelLocator.resourceManagerInstance.getString('transmitterscreen','firmware_version_label'), accessory: transmitterFirmwareLabel });
			if (CGMBlueToothDevice.isDexcomG5() || CGMBlueToothDevice.isDexcomG6())
			{
				infoSectionChildren.push({ label: ModelLocator.resourceManagerInstance.getString('transmitterscreen','firmware_version_label'), accessory: transmitterFirmwareLabel });
				infoSectionChildren.push({ label: ModelLocator.resourceManagerInstance.getString('transmitterscreen','other_firmware_version_label'), accessory: otherFirmwareLabel });
				infoSectionChildren.push({ label: ModelLocator.resourceManagerInstance.getString('transmitterscreen','bluetooth_firmware_version_label'), accessory: bluetoothFirmwareLabel });
				infoSectionChildren.push({ label: ModelLocator.resourceManagerInstance.getString('transmitterscreen','transmitter_runtime_label'), accessory: transmitterRuntimeLabel });
			}
			if (transmitterConnectionStatusValue != null)
				infoSectionChildren.push({ label: ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_connection_status_label'), accessory: transmitterConnectionStatusLabel });
			
			infoSection.children = infoSectionChildren;
			
			screenDataContent.push(infoSection);
			
			/* Battery Section */
			var batterySection:Object = {};
			batterySection.header = { label: ModelLocator.resourceManagerInstance.getString('transmitterscreen','battery_section_label') };
			if(transmitterTypeValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_dexcom_g5') || transmitterTypeValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_dexcom_g6'))
			{
				batterySection.children = [
					{ label: ModelLocator.resourceManagerInstance.getString('transmitterscreen','voltage_a_label'), accessory: voltageALabel, icon: voltageAIcon },
					{ label: ModelLocator.resourceManagerInstance.getString('transmitterscreen','voltage_b_label'), accessory: voltageBLabel, icon: voltageBIcon },
					{ label: ModelLocator.resourceManagerInstance.getString('transmitterscreen','resistance_label'), accessory: resistanceLabel, icon: resistanceIcon },
					{ label: ModelLocator.resourceManagerInstance.getString('transmitterscreen','temperature_label'), accessory: temperatureLabel },
					{ label: "", accessory: lastG5G6BatteryUpdateLabel },
					{ label: "", accessory: g5G6ActionContainer }
				];
			}
			else
			{
				batterySection.children = [
					{ label: ModelLocator.resourceManagerInstance.getString('transmitterscreen','battery_level_label'), accessory: batteryLevelLabel, icon: batteryLevelIcon }
				];
			}
			
			screenDataContent.push(batterySection);
			
			//Actions Section
			if ((!CGMBluetoothService.bluetoothPeripheralActive() && !CGMBlueToothDevice.alwaysScan()) || (CGMBlueToothDevice.known() && !CGMBlueToothDevice.alwaysScan())) 
			{
				/* Action Controls Container */
				var actionControls:LayoutGroup = new LayoutGroup();
				var actionControlsLayout:HorizontalLayout = new HorizontalLayout();
				actionControlsLayout.gap = 5;
				actionControlsLayout.horizontalAlign = HorizontalAlign.CENTER;
				actionControlsLayout.verticalAlign = VerticalAlign.MIDDLE;
				actionControlsLayout.paddingRight = -2;
				actionControls.layout = actionControlsLayout;
				
				/* Actions Data */
				var actionsSection:Object = {};
				actionsSection.header = { label: ModelLocator.resourceManagerInstance.getString('transmitterscreen','actions_label') };
				
				if(!CGMBluetoothService.bluetoothPeripheralActive() && !CGMBlueToothDevice.alwaysScan()) //Scan Action
				{
					scanButtonIcon = MaterialDeepGreyAmberMobileThemeIcons.bluetoothSearchingTexture;
					scanButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('transmitterscreen','scan_device_button_label'), false, scanButtonIcon);
					scanButton.gap = 5;
					scanButton.addEventListener(Event.TRIGGERED, onTransmitterScan);
					actionControls.addChild(scanButton);
				}
				
				if(CGMBlueToothDevice.known() && !CGMBlueToothDevice.alwaysScan()) //Forget Action
				{
					forgetButtonIcon = MaterialDeepGreyAmberMobileThemeIcons.bluetoothDisabledTexture;
					forgetButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('transmitterscreen','forget_device_button_label'), false, forgetButtonIcon);
					forgetButton.gap = 3;
					forgetButton.addEventListener(Event.TRIGGERED, onTransmitterForget);
					actionControls.addChild(forgetButton);
				}
				
				var actionsData:Array = [];
				actionsData.push( { label: "", accessory: actionControls } );
				
				actionsSection.children = actionsData;
				
				/* Add Actions Section to Display List */
				screenDataContent.push(actionsSection);
			}
			
			if(!CGMBluetoothService.bluetoothPeripheralActive() && !CGMBlueToothDevice.alwaysScan() && !InterfaceController.peripheralConnected)
			{
				screenRefreshLabel = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('transmitterscreen','refresh_screen_label').replace("{sec}", 5), HorizontalAlign.RIGHT, VerticalAlign.TOP, 10);
				
				var refreshSection:Object = {};
				refreshSection.children = [
					{ label: "", accessory: screenRefreshLabel }
				];
				screenDataContent.push(refreshSection);
			}
				
			/* Set Screen Content */
			dataProvider = new HierarchicalCollection(screenDataContent);	
			
			/* Set Content Renderer */
			this.itemRendererFactory = function ():IGroupedListItemRenderer 
			{
				const item:DefaultGroupedListItemRenderer = new DefaultGroupedListItemRenderer();
				item.labelField = "label";
				item.iconField = "icon";
				item.accessoryField = "accessory";
				item.gap = 8;
				
				if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr && !Constants.isPortrait)
				{
					if (Constants.currentOrientation == StageOrientation.ROTATED_RIGHT)
					{
						item.paddingLeft = 30;
					}
					else if (Constants.currentOrientation == StageOrientation.ROTATED_LEFT)
					{
						item.paddingRight = 30;
					}
				}
				
				if(transmitterTypeValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_dexcom_g5') || transmitterTypeValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_dexcom_g6'))
					item.addEventListener(TouchEvent.TOUCH, onDisplayBatteryStatus);
				
				return item;
			};	
			
			this.headerRendererFactory = function():IGroupedListHeaderRenderer
			{
				var headerRenderer:DefaultGroupedListHeaderOrFooterRenderer = new DefaultGroupedListHeaderOrFooterRenderer();
				headerRenderer.contentLabelField = "label";
				
				if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr && !Constants.isPortrait)
				{
					if (Constants.currentOrientation == StageOrientation.ROTATED_RIGHT)
					{
						headerRenderer.paddingLeft = 30;
					}
					else if (Constants.currentOrientation == StageOrientation.ROTATED_LEFT)
					{
						headerRenderer.paddingRight = 30;
					}
				}
				
				return headerRenderer;
			};
		}
		
		private function setupEventListeners():void
		{
			CommonSettings.instance.addEventListener(SettingsServiceEvent.SETTING_CHANGED, onSettingsChanged, false, 0, true);
		}
		
		private function setupRefreshTimer():void
		{
			if(!CGMBluetoothService.bluetoothPeripheralActive() && !CGMBlueToothDevice.alwaysScan() && !InterfaceController.peripheralConnected)
			{
				if (refreshTimer != null)
					disposeRefreshTimer();
				
				refreshTimer = new Timer(1000);
				refreshTimer.addEventListener(TimerEvent.TIMER, onRefreshTimer);
				refreshTimer.start();
			}
		}
		
		/**
		 * Event Handlers
		 */
		private function onSettingsChanged(event:SettingsServiceEvent):void 
		{
			if (
				event.data == CommonSettings.COMMON_SETTING_G5_G6_RESIST ||
				event.data == CommonSettings.COMMON_SETTING_G5_G6_RUNTIME ||
				event.data == CommonSettings.COMMON_SETTING_G5_G6_TEMPERATURE ||
				event.data == CommonSettings.COMMON_SETTING_G5_G6_VOLTAGEA ||
				event.data == CommonSettings.COMMON_SETTING_G5_G6_VOLTAGEB ||
				event.data == CommonSettings.COMMON_SETTING_G5_STATUS
			) 
			{
				setupInitialState();
				setupContent();
			}
		}
		
		private function onDisplayBatteryStatus(e:TouchEvent):void
		{
			//Get touch data
			var touch:Touch = e.getTouch(stage);
			
			//If a click was recorded, show callout with status info
			if(touch != null && e != null && e.currentTarget != null && touch != null && touch.phase == TouchPhase.BEGAN && (CGMBlueToothDevice.isDexcomG5() || CGMBlueToothDevice.isDexcomG6()))
			{
				var listItem:Object = (e.currentTarget as Object);
				if (listItem == null)
					return;
				
				var message:String;
				var target:DisplayObject;
				
				if (listItem.label != null && listItem.label == ModelLocator.resourceManagerInstance.getString('transmitterscreen','voltage_a_label'))
				{
					message = voltageAStatus;
					target = voltageAIcon;
				}
				else if (listItem.label != null && listItem.label == ModelLocator.resourceManagerInstance.getString('transmitterscreen','voltage_b_label'))
				{
					message = voltageBStatus;
					target = voltageBIcon;
				}
				else if (listItem.label != null && listItem.label == ModelLocator.resourceManagerInstance.getString('transmitterscreen','resistance_label'))
				{
					message = resistanceStatus;
					target = resistanceIcon;
				}
				
				if (message != null && target != null && target.stage != null)
				{
					batteryStatusG5Callout = TextCallout.show(message, target, new <String>[RelativePosition.TOP], false);
					batteryStatusG5Callout.textRendererFactory = function calloutTextRenderer():ITextRenderer
					{
						var messageRenderer:TextBlockTextRenderer = new TextBlockTextRenderer();
						messageRenderer.textAlign = HorizontalAlign.CENTER;
						
						return messageRenderer;
					};
				}
			}
		}
		
		private function onRefreshG5G6BatteyInfo(e:Event):void
		{
			if (CGMBlueToothDevice.known())
			{
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_G5_G6_BATTERY_FROM_MARKER, String(timestampForRefresh));
				lastG5G6BatteryUpdateLabel.text = ModelLocator.resourceManagerInstance.getString('transmitterscreen',"updating_message");
			}
		}
		
		private function onResetG5G6(e:Event):void
		{
			var alertBody:String = "";
			
			if (CGMBlueToothDevice.isDexcomG5())
				alertBody = ModelLocator.resourceManagerInstance.getString('transmitterscreen','reset_g5_warning_message');
			else if (CGMBlueToothDevice.isDexcomG6())
				alertBody = ModelLocator.resourceManagerInstance.getString('transmitterscreen','reset_g5_warning_message').replace("G5", "G6");
				
			AlertManager.showActionAlert
			(
				ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
				alertBody,
				Number.NaN,
				[
					{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations','no_uppercase') },
					{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations','yes_uppercase'), triggered: onResetTransmitter }
				]
			);
			
			function onResetTransmitter(e:Event):void
			{
				CGMBluetoothService.G5G6_RequestReset();
				
				AlertManager.showSimpleAlert
				(
					ModelLocator.resourceManagerInstance.getString('globaltranslations','info_alert_title'),
					ModelLocator.resourceManagerInstance.getString('transmitterscreen','reset_g5_confirmation_message')
				);
			}
		}
		
		private function onTransmitterScan(e:Event):void
		{
			if (BluetoothLE.service.centralManager.state == BluetoothLEState.STATE_ON) 
			{
				CGMBluetoothService.instance.addEventListener(BlueToothServiceEvent.STOPPED_SCANNING, InterfaceController.btScanningStopped, false, 0, true);
				BluetoothLE.service.centralManager.addEventListener(PeripheralEvent.CONNECT, InterfaceController.userInitiatedBTScanningSucceeded, false, 0, true);
				SpikeANE.instance.addEventListener(SpikeANEEvent.MIAOMIAO_CONNECTED, InterfaceController.userInitiatedBTScanningSucceeded, false, 0, true);
				CGMBluetoothService.startScanning(true);
				
				AlertManager.showSimpleAlert(
					ModelLocator.resourceManagerInstance.getString('transmitterscreen',"scan_for_device_alert_title"),
					ModelLocator.resourceManagerInstance.getString('transmitterscreen',"scanning_started_message"),
					30
				);
				
				Trace.myTrace("TransmitterStatusList.as", "in onTransmitterScan, initial scan for device, setting systemIdleMode = SystemIdleMode.KEEP_AWAKE");
				NativeApplication.nativeApplication.systemIdleMode = SystemIdleMode.KEEP_AWAKE;
				SpikeANE.vibrate();
				
				setupRefreshTimer();
			} 
			else 
			{
				var alert:Alert = AlertManager.showSimpleAlert(
					ModelLocator.resourceManagerInstance.getString('transmitterscreen',"scanning_failed_alert_title"),
					ModelLocator.resourceManagerInstance.getString('transmitterscreen',"bluetooth_not_switched_on_message")
				);
				alert.height = 310;
				
				Trace.myTrace("TransmitterStatusList.as", "in onTransmitterScan, can't scan, bluetooth is off.");
				
				disposeRefreshTimer();
			}
		}
		
		private function onTransmitterForget():void
		{
			CGMBlueToothDevice.forgetBlueToothDevice();
			CGMBluetoothService.stopScanning(null);
			InterfaceController.peripheralConnected = false;
			
			if (CGMBlueToothDevice.knowsFSLAge() && Calibration.allForSensor().length < 2)
				Sensor.stopSensor();
			
			AlertManager.showSimpleAlert
			(
				ModelLocator.resourceManagerInstance.getString('transmitterscreen',"forget_device_alert_title"),
				ModelLocator.resourceManagerInstance.getString('transmitterscreen',"forget_device_alert_message"),
				Number.NaN,
				null,
				HorizontalAlign.CENTER
			);
			
			disposeRefreshTimer();
			setupInitialState();
			setupContent();
		}
		
		private function onRefreshTimer(event:TimerEvent):void
		{
			if (refreshSecondsElapsed <= 0)
			{
				refreshSecondsElapsed = 4;
				setupInitialState();
				SystemUtil.executeWhenApplicationIsActive(setupContent);
				if (InterfaceController.peripheralConnected)
				{
					disposeRefreshTimer();
					//Ensure that the battery levels are displayed correctly by refreshing the screen after 3 seconds 
					//so Spike has enough time to get battery info from the transmitter
					timeOut1 = setTimeout(setupInitialState, 3000);
					timeOut2 = setTimeout(setupContent, 3300); 
				}
			}
			else
			{
				if (screenRefreshLabel != null)
					screenRefreshLabel.text = ModelLocator.resourceManagerInstance.getString('transmitterscreen','refresh_screen_label').replace("{sec}", refreshSecondsElapsed);
				refreshSecondsElapsed--;
			}
		}
		
		private function onStarlingResize(event:ResizeEvent):void 
		{
			SystemUtil.executeWhenApplicationIsActive( AppInterface.instance.navigator.replaceScreen, Screens.TRANSMITTER, noTransition);
			
			function noTransition( oldScreen:DisplayObject, newScreen:DisplayObject, completeCallback:Function ):void
			{
				completeCallback();
			};
		}
		
		/**
		 * Utility
		 */
		private function capitalizeString(str:String):String 
		{
			var firstChar:String = str.substr(0, 1); 
			var restOfString:String = str.substr(1, str.length); 
			
			return firstChar.toUpperCase()+restOfString.toLowerCase(); 
		}
		
		private function disposeRefreshTimer():void
		{
			if (refreshTimer != null)
			{
				refreshTimer.stop();
				refreshTimer.removeEventListener(TimerEvent.TIMER, onRefreshTimer);
				refreshTimer = null;
			}
		}
		
		override public function dispose():void
		{
			//Timers and timeouts
			disposeRefreshTimer();
			clearTimeout(timeOut1);
			clearTimeout(timeOut2);
			
			//Event listeners
			Starling.current.stage.removeEventListener(starling.events.Event.RESIZE, onStarlingResize);
			CommonSettings.instance.removeEventListener(SettingsServiceEvent.SETTING_CHANGED, onSettingsChanged);
			CGMBluetoothService.instance.removeEventListener(BlueToothServiceEvent.STOPPED_SCANNING, InterfaceController.btScanningStopped);
			BluetoothLE.service.centralManager.removeEventListener(PeripheralEvent.CONNECT, InterfaceController.userInitiatedBTScanningSucceeded);
			
			//Display Objects
			if(voltageAIconTexture != null)
			{
				voltageAIconTexture.dispose();
				voltageAIconTexture = null;
				if (voltageAIcon.texture != null)
					voltageAIcon.texture.dispose();
				voltageAIcon.dispose();
				voltageAIcon = null;
				voltageALabel.dispose();
				voltageALabel = null;
			}
			
			if(voltageBIconTexture != null)
			{
				voltageBIconTexture.dispose();
				voltageBIconTexture = null;
				if (voltageBIcon.texture != null)
					voltageBIcon.texture.dispose();
				voltageBIcon.dispose();
				voltageAIcon = null;
				voltageBLabel.dispose();
				voltageBLabel = null;
			}
			
			if(resistanceIconTexture != null)
			{
				resistanceIconTexture.dispose();
				resistanceIconTexture = null;
				if (resistanceIcon.texture != null)
					resistanceIcon.texture.dispose();
				resistanceIcon.dispose();
				resistanceIcon = null;
				resistanceLabel.dispose();
				resistanceLabel = null;
			}
			
			if(batteryLevelIconTexture != null)
			{
				batteryLevelIconTexture.dispose();
				batteryLevelIconTexture = null;
				if (batteryLevelIcon.texture != null)
					batteryLevelIcon.texture.dispose();
				batteryLevelIcon.dispose();
				batteryLevelIconTexture = null;
				if (batteryLevelLabel != null)
				{
					batteryLevelLabel.dispose();
					batteryLevelLabel = null;
				}
			}
			
			if(transmitterTypeLabel != null)
			{
				transmitterTypeLabel.dispose();
				transmitterTypeLabel = null;
			}
			
			if(transmitterNameLabel != null)
			{
				transmitterNameLabel.dispose();
				transmitterNameLabel = null;
			}
			
			if(transmitterRuntimeLabel != null)
			{
				transmitterRuntimeLabel.dispose();
				transmitterRuntimeLabel = null;
			}
			
			if (temperatureLabel != null)
			{
				temperatureLabel.dispose();
				temperatureLabel = null;
			}
			
			if(transmitterConnectionStatusLabel != null)
			{
				transmitterConnectionStatusLabel.dispose();
				transmitterConnectionStatusLabel = null;
			}
			
			if (lastG5G6BatteryUpdateLabel != null)
			{
				lastG5G6BatteryUpdateLabel.dispose();
				lastG5G6BatteryUpdateLabel = null;
			}
			
			if(scanButton != null)
			{
				scanButton.removeEventListener(Event.TRIGGERED, onTransmitterScan);
				scanButtonIcon.dispose();
				scanButtonIcon = null;
				scanButton.dispose();
				scanButton = null;
			}
			
			if(forgetButton != null)
			{
				forgetButton.removeEventListener(Event.TRIGGERED, onTransmitterForget);
				forgetButtonIcon.dispose();
				forgetButtonIcon = null;
				forgetButton.dispose();
				forgetButton = null;
			}
			
			if(refreshG5G6BatteryButton != null)
			{
				refreshG5G6BatteryButton.removeEventListener(Event.TRIGGERED, onRefreshG5G6BatteyInfo)
				refreshG5G6BatteryButton.removeFromParent();
				refreshG5G6BatteryButton.dispose();
				refreshG5G6BatteryButton = null;
			}
			
			if (resetG5G6TransmitterButton != null)
			{
				resetG5G6TransmitterButton.removeEventListener(Event.TRIGGERED, onResetG5G6);
				resetG5G6TransmitterButton.removeFromParent();
				resetG5G6TransmitterButton.dispose();
				resetG5G6TransmitterButton = null;
			}
			
			if (g5G6ActionContainer != null)
			{
				g5G6ActionContainer.dispose();
				g5G6ActionContainer = null;
			}
			
			if (screenRefreshLabel != null)
			{
				screenRefreshLabel.dispose();
				screenRefreshLabel = null;
			}
			
			if (transmitterFirmwareLabel != null)
			{
				transmitterFirmwareLabel.dispose();
				transmitterFirmwareLabel = null;
			}
			
			if (otherFirmwareLabel != null)
			{
				otherFirmwareLabel.dispose();
				otherFirmwareLabel = null;
			}
			
			if (bluetoothFirmwareLabel != null)
			{
				bluetoothFirmwareLabel.dispose();
				bluetoothFirmwareLabel = null;
			}
			
			if (transmitterMACAddressLabel != null)
			{
				transmitterMACAddressLabel.dispose();
				transmitterMACAddressLabel = null;
			}
			
			super.dispose();
		}
	}
}