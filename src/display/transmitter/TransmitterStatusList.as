package display.transmitter
{
	
	import com.distriqt.extension.bluetoothle.BluetoothLE;
	import com.distriqt.extension.bluetoothle.BluetoothLEState;
	import com.distriqt.extension.bluetoothle.events.PeripheralEvent;
	
	import flash.desktop.NativeApplication;
	import flash.desktop.SystemIdleMode;
	import flash.system.System;
	
	import G4Model.TransmitterStatus;
	
	import G5Model.TransmitterStatus;
	
	import Utilities.Trace;
	
	import databaseclasses.BlueToothDevice;
	import databaseclasses.CommonSettings;
	
	import display.LayoutFactory;
	
	import events.BlueToothServiceEvent;
	
	import feathers.controls.Alert;
	import feathers.controls.Button;
	import feathers.controls.GroupedList;
	import feathers.controls.Label;
	import feathers.controls.LayoutGroup;
	import feathers.controls.renderers.DefaultGroupedListItemRenderer;
	import feathers.controls.renderers.IGroupedListItemRenderer;
	import feathers.data.HierarchicalCollection;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.HorizontalLayout;
	import feathers.layout.VerticalAlign;
	import feathers.layout.VerticalLayoutData;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.ModelLocator;
	
	import services.BluetoothService;
	
	import starling.display.Image;
	import starling.events.Event;
	import starling.textures.Texture;
	
	import ui.InterfaceController;
	
	import utils.AlertManager;
	import utils.Constants;
	
	[ResourceBundle("transmitterscreen")]

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

		public function TransmitterStatusList()
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
			if (BlueToothDevice.known()) transmitterNameValue = BlueToothDevice.name;
			else transmitterNameValue = ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_unknown');
			
			/* Get connectiion status */
			// Only for xDrip type of device the status will be shown because peripheralConnected is usually not connected for Dexcom (or others alike) and peripheralConnectionStatusChangeTimestamp is not being set for Dexcom (or others alike)
			if (InterfaceController.peripheralConnected)
				transmitterConnectionStatusValue = ModelLocator.resourceManagerInstance.getString('transmitterscreen','connection_status_connected');
			else if (!isNaN(InterfaceController.peripheralConnectionStatusChangeTimestamp))
				transmitterConnectionStatusValue = ModelLocator.resourceManagerInstance.getString('transmitterscreen','connection_status_last_connection') + " " + InterfaceController.dateFormatterForSensorStartTimeAndDate.format(new Date(InterfaceController.peripheralConnectionStatusChangeTimestamp));
			
			/* Battery and Transmitter Type */
			if (BlueToothDevice.isDexcomG5()) 
			{
				/* Transmitter Type */
				transmitterTypeValue = ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_dexcom_g5');
				
				/* Voltage A */
				voltageAValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_G5_VOLTAGEA);
				if (voltageAValue == "unknown" || transmitterNameValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_unknown')) voltageAValue = ModelLocator.resourceManagerInstance.getString('transmitterscreen','battery_unknown');
				
				if (voltageAValue != ModelLocator.resourceManagerInstance.getString('transmitterscreen','battery_unknown'))
					voltageAStatus = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_G5_VOLTAGEA)) < G5Model.TransmitterStatus.LOW_BATTERY_WARNING_LEVEL_VOLTAGEA ? ModelLocator.resourceManagerInstance.getString('transmitterscreen','voltage_status_low'):ModelLocator.resourceManagerInstance.getString('transmitterscreen','voltage_status_ok');
					
				/* Voltage B */
				voltageBValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_G5_VOLTAGEB);
				if (voltageBValue == "unknown" || transmitterNameValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_unknown')) voltageBValue = ModelLocator.resourceManagerInstance.getString('transmitterscreen','battery_unknown');
				
				if (voltageBValue != ModelLocator.resourceManagerInstance.getString('transmitterscreen','battery_unknown'))
					voltageBStatus = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_G5_VOLTAGEB)) < G5Model.TransmitterStatus.LOW_BATTERY_WARNING_LEVEL_VOLTAGEB ? ModelLocator.resourceManagerInstance.getString('transmitterscreen','voltage_status_low'):ModelLocator.resourceManagerInstance.getString('transmitterscreen','voltage_status_ok'); 
				
				/* Resistance */
				resistanceValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_G5_RESIST);
				if (resistanceValue == "unknown" || transmitterNameValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_unknown')) resistanceValue = ModelLocator.resourceManagerInstance.getString('transmitterscreen','battery_unknown');
				
				if (resistanceValue != ModelLocator.resourceManagerInstance.getString('transmitterscreen','battery_unknown'))
					resistanceStatus = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_G5_RESIST)) > G5Model.TransmitterStatus.RESIST_BAD ? ModelLocator.resourceManagerInstance.getString('transmitterscreen','resistance_status_bad'):(Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_G5_RESIST)) > G5Model.TransmitterStatus.RESIST_NOTICE ? ModelLocator.resourceManagerInstance.getString('transmitterscreen','resistance_status_notice'):(Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_G5_RESIST)) > G5Model.TransmitterStatus.RESIST_NORMAL ? ModelLocator.resourceManagerInstance.getString('transmitterscreen','resistance_status_normal'):ModelLocator.resourceManagerInstance.getString('transmitterscreen','resistance_status_good')));
			}
			else if (BlueToothDevice.isDexcomG4()) 
			{
				/* Transmitter Type */
				transmitterTypeValue = ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_dexcom_g4');
				
				/* Battery Level */
				batteryLevelValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_G4_TRANSMITTER_BATTERY_VOLTAGE);
				if (batteryLevelValue == "0" || transmitterNameValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_unknown')) 
					batteryLevelValue = ModelLocator.resourceManagerInstance.getString('transmitterscreen','battery_unknown');
				else 
					batteryLevelValue = capitalizeString(G4Model.TransmitterStatus.getBatteryLevel(Number(batteryLevelValue)).batteryLevel);
			}
			else if (BlueToothDevice.isBlueReader())
			{
				/* Transmitter Type */
				transmitterTypeValue = ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_bluereader');
				
				/* Battery Level */
				batteryLevelValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BLUEREADER_BATTERY_LEVEL);
				
				if (batteryLevelValue == "0" || transmitterNameValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_unknown')) 
					batteryLevelValue = ModelLocator.resourceManagerInstance.getString('transmitterscreen','battery_unknown');
				else
					batteryLevelValue = String((Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BLUEREADER_BATTERY_LEVEL)))/1000);
			}
			else if (BlueToothDevice.isBluKon())
			{
				/* Transmitter Type */
				transmitterTypeValue = ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_blucon');
				
				/* Battery Level */
				batteryLevelValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BLUKON_BATTERY_LEVEL);
				if (batteryLevelValue == "0" || transmitterNameValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_unknown'))
					batteryLevelValue = ModelLocator.resourceManagerInstance.getString('transmitterscreen','battery_unknown');
			}
			else if (BlueToothDevice.isLimitter())
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
			/* Define Battery Status Icons*/
			if (transmitterTypeValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_dexcom_g5')) //Dexcom G5
			{
				/* Voltage A */
				if (voltageAStatus == ModelLocator.resourceManagerInstance.getString('transmitterscreen','battery_unknown') || transmitterNameValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_unknown'))
					voltageAIconTexture = MaterialDeepGreyAmberMobileThemeIcons.batteryUnknownTexture;
				else if (voltageAStatus == ModelLocator.resourceManagerInstance.getString('transmitterscreen','voltage_status_ok'))
					voltageAIconTexture = MaterialDeepGreyAmberMobileThemeIcons.batteryOkTexture;
				else if(voltageAStatus == ModelLocator.resourceManagerInstance.getString('transmitterscreen','voltage_status_low'))
					voltageAIconTexture = MaterialDeepGreyAmberMobileThemeIcons.batteryBadTexture;
				
				if(voltageAIconTexture != null)
					voltageAIcon = new Image(voltageAIconTexture);
				
				/* Voltage B */
				if (voltageBStatus == ModelLocator.resourceManagerInstance.getString('transmitterscreen','battery_unknown') || transmitterNameValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_unknown'))
					voltageBIconTexture = MaterialDeepGreyAmberMobileThemeIcons.batteryUnknownTexture;
				else if (voltageBStatus == ModelLocator.resourceManagerInstance.getString('transmitterscreen','voltage_status_ok'))
					voltageBIconTexture = MaterialDeepGreyAmberMobileThemeIcons.batteryOkTexture;
				else if(voltageBStatus == ModelLocator.resourceManagerInstance.getString('transmitterscreen','voltage_status_low'))
					voltageBIconTexture = MaterialDeepGreyAmberMobileThemeIcons.batteryBadTexture;
				
				if(voltageBIconTexture != null)
					voltageBIcon = new Image(voltageBIconTexture);
				
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
					resistanceIcon = new Image(resistanceIconTexture);
			}
			else //Rest of the thansmitters
			{
				if(batteryLevelValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','battery_unknown') || transmitterNameValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_unknown'))
					batteryLevelIconTexture = MaterialDeepGreyAmberMobileThemeIcons.batteryUnknownTexture;
				else if(Number(batteryLevelValue) > 60) //OK Battery
					batteryLevelIconTexture = MaterialDeepGreyAmberMobileThemeIcons.batteryOkTexture;
				else if(Number(batteryLevelValue) > 30) //Alert Battery
					batteryLevelIconTexture = MaterialDeepGreyAmberMobileThemeIcons.batteryAlertTexture;
				else //Low Battery
					batteryLevelIconTexture = MaterialDeepGreyAmberMobileThemeIcons.batteryBadTexture;
				
				if(batteryLevelIconTexture != null)
					batteryLevelIcon = new Image(batteryLevelIconTexture);
			}
			
			/* Define Info & Battery/Connection Status Labels */
			transmitterTypeLabel = LayoutFactory.createLabel(transmitterTypeValue, HorizontalAlign.RIGHT);
			transmitterNameLabel = LayoutFactory.createLabel(transmitterNameValue, HorizontalAlign.RIGHT);
			if (transmitterConnectionStatusValue != null)
				transmitterConnectionStatusLabel = LayoutFactory.createLabel(transmitterConnectionStatusValue, HorizontalAlign.RIGHT);
			
			if (transmitterTypeValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_dexcom_g5'))
			{
				
				voltageALabel = LayoutFactory.createLabel(voltageAValue, HorizontalAlign.RIGHT);
				voltageBLabel = LayoutFactory.createLabel(voltageBValue, HorizontalAlign.RIGHT);
				resistanceLabel = LayoutFactory.createLabel(resistanceValue, HorizontalAlign.RIGHT);
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
			if (transmitterConnectionStatusValue != null)
				infoSectionChildren.push({ label: ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_connection_status_label'), accessory: transmitterConnectionStatusLabel });
			
			infoSection.children = infoSectionChildren;
			
			screenDataContent.push(infoSection);
			
			/* Battery Section */
			var batterySection:Object = {};
			batterySection.header = { label: ModelLocator.resourceManagerInstance.getString('transmitterscreen','battery_section_label') };
			if(transmitterTypeValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_dexcom_g5'))
			{
				batterySection.children = [
					{ label: ModelLocator.resourceManagerInstance.getString('transmitterscreen','voltage_a_label'), accessory: voltageALabel, icon: voltageAIcon },
					{ label: ModelLocator.resourceManagerInstance.getString('transmitterscreen','voltage_b_label'), accessory: voltageBLabel, icon: voltageBIcon },
					{ label: ModelLocator.resourceManagerInstance.getString('transmitterscreen','resistance_label'), accessory: resistanceLabel, icon: resistanceIcon }
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
			if ((!BluetoothService.bluetoothPeripheralActive() && !BlueToothDevice.alwaysScan()) || (BlueToothDevice.known() && !BlueToothDevice.alwaysScan())) 
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
				
				if(!BluetoothService.bluetoothPeripheralActive() && !BlueToothDevice.alwaysScan()) //Scan Action
				{
					scanButtonIcon = MaterialDeepGreyAmberMobileThemeIcons.bluetoothSearchingTexture;
					scanButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('transmitterscreen','scan_device_button_label'), false, scanButtonIcon);
					scanButton.gap = 5;
					scanButton.addEventListener(Event.TRIGGERED, onTransmitterScan);
					actionControls.addChild(scanButton);
				}
				
				if(BlueToothDevice.known() && !BlueToothDevice.alwaysScan()) //Forget Action
				{
					forgetButtonIcon = MaterialDeepGreyAmberMobileThemeIcons.bluetoothDisabledTexture;
					forgetButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('transmitterscreen','forget_device_button_label'), false, forgetButtonIcon);
					forgetButton.gap = 3;
					forgetButton.addEventListener(Event.TRIGGERED, onTransmitterForget);
					actionControls.addChild(forgetButton);
				}
				
				actionsSection.children = [
					{ label: "", accessory: actionControls }
				];
				
				/* Add Actions Section to Display List */
				screenDataContent.push(actionsSection);
			}
				
			/* Set Screen Content */
			dataProvider = new HierarchicalCollection(screenDataContent);	
			
			/* Set Content Renderer */
			this.itemRendererFactory = function ():IGroupedListItemRenderer {
				const item:DefaultGroupedListItemRenderer = new DefaultGroupedListItemRenderer();
				item.labelField = "label";
				item.iconField = "icon";
				item.accessoryField = "accessory";
				item.gap = 8;
				return item;
			};
		}
		
		/**
		 * Event Handlers
		 */
		private function onTransmitterScan(e:Event):void
		{
			if (BluetoothLE.service.centralManager.state == BluetoothLEState.STATE_ON) 
			{
				BluetoothService.instance.addEventListener(BlueToothServiceEvent.STOPPED_SCANNING, InterfaceController.btScanningStopped);
				BluetoothLE.service.centralManager.addEventListener(PeripheralEvent.CONNECT, InterfaceController.userInitiatedBTScanningSucceeded);
				BluetoothService.startScanning(true);
				
				AlertManager.showSimpleAlert(
					ModelLocator.resourceManagerInstance.getString('transmitterscreen',"scan_for_device_alert_title"),
					ModelLocator.resourceManagerInstance.getString('transmitterscreen',"scanning_started_message"),
					30
				);
				
				Trace.myTrace("TransmitterStatusList.as", "in onTransmitterScan, initial scan for device, setting systemIdleMode = SystemIdleMode.KEEP_AWAKE");
				NativeApplication.nativeApplication.systemIdleMode = SystemIdleMode.KEEP_AWAKE;
			} 
			else 
			{
				var alert:Alert = AlertManager.showSimpleAlert(
					ModelLocator.resourceManagerInstance.getString('transmitterscreen',"scanning_failed_alert_title"),
					ModelLocator.resourceManagerInstance.getString('transmitterscreen',"bluetooth_not_switched_on_message")
				);
				alert.height = 310;
				
				Trace.myTrace("TransmitterStatusList.as", "in onTransmitterScan, can't scan, bluetooth is off.");
			}
		}
		
		private function onTransmitterForget():void
		{
			BlueToothDevice.forgetBlueToothDevice();
			
			AlertManager.showSimpleAlert
			(
				ModelLocator.resourceManagerInstance.getString('transmitterscreen',"forget_device_alert_title"),
				ModelLocator.resourceManagerInstance.getString('transmitterscreen',"forget_device_alert_message"),
				Number.NaN,
				null,
				HorizontalAlign.CENTER
			);
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
		
		override public function dispose():void
		{
			if(voltageAIconTexture != null)
			{
				voltageAIconTexture.dispose();
				voltageAIconTexture = null;
				voltageAIcon.dispose();
				voltageAIcon = null;
				voltageALabel.dispose();
				voltageALabel = null;
			}
			
			if(voltageBIconTexture != null)
			{
				voltageBIconTexture.dispose();
				voltageBIconTexture = null;
				voltageBIcon.dispose();
				voltageAIcon = null;
				voltageBLabel.dispose();
				voltageBLabel = null;
			}
			
			if(resistanceIconTexture != null)
			{
				resistanceIconTexture.dispose();
				resistanceIconTexture = null;
				resistanceIcon.dispose();
				resistanceIcon = null;
				resistanceLabel.dispose();
				resistanceLabel = null;
			}
			
			if(resistanceIconTexture != null)
			{
				resistanceIconTexture.dispose();
				resistanceIconTexture = null;
				resistanceIcon.dispose();
				resistanceIcon = null;
				resistanceLabel.dispose();
				resistanceLabel = null;
			}
			
			if(batteryLevelIconTexture != null)
			{
				batteryLevelIconTexture.dispose();
				batteryLevelIconTexture = null;
				batteryLevelIcon.dispose();
				batteryLevelIconTexture = null;
				batteryLevelLabel.dispose();
				batteryLevelLabel = null;
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
			
			if(transmitterConnectionStatusLabel != null)
			{
				transmitterConnectionStatusLabel.dispose();
				transmitterConnectionStatusLabel = null;
			}
			
			if(scanButton != null)
			{
				scanButtonIcon.dispose();
				scanButtonIcon = null;
				scanButton.dispose();
				scanButton = null;
			}
			
			if(forgetButton != null)
			{
				forgetButtonIcon.dispose();
				forgetButtonIcon = null;
				forgetButton.dispose();
				forgetButton = null;
			}

			System.pauseForGCIfCollectionImminent(0);
			
			super.dispose();
		}
	}
}