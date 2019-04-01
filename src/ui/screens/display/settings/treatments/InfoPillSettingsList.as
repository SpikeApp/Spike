package ui.screens.display.settings.treatments
{
	import flash.display.StageOrientation;
	
	import database.CGMBlueToothDevice;
	import database.CommonSettings;
	
	import feathers.controls.Check;
	import feathers.controls.ToggleSwitch;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.data.ListCollection;
	import feathers.layout.AnchorLayoutData;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import starling.events.Event;
	
	import ui.screens.display.LayoutFactory;
	import ui.screens.display.SpikeList;
	
	import utils.Constants;
	import utils.DeviceInfo;
	
	[ResourceBundle("chartscreen")]
	[ResourceBundle("globaltranslations")]
	
	public class InfoPillSettingsList extends SpikeList 
	{
		/* Display Objects */
		private var infoPillEnabled:ToggleSwitch;
		private var displayBasalEnabled:Check;
		private var displayRawEnabled:Check;
		private var displayUploaderBatteryEnabled:Check;
		private var displayOpenAPSMomentEnabled:Check;
		private var displayLoopMomentEnabled:Check;
		private var displayPumpBatteryEnabled:Check;
		private var displayPumpReservoirEnabled:Check;
		private var displayPumpStatusEnabled:Check;
		private var displayPumpTimeEnabled:Check;
		private var displayCAGEEnabled:Check;
		private var displaySAGEEnabled:Check;
		private var displayIAGEEnabled:Check;
		private var displayTransmitterBatteryEnabled:Check;
		private var displaySensorNoiseEnabled:Check;
		private var displayBAGEEnabled:Check;
		
		/* Internal Variables */
		public var needsSave:Boolean = false;
		private var infoPillEnabledValue:Boolean;
		private var basalEnabledValue:Boolean;
		private var rawEnabledValue:Boolean;
		private var uploaderBatteryEnabledValue:Boolean;
		private var openAPSMomentEnabledValue:Boolean;
		private var loopMomentEnabledValue:Boolean;
		private var pumpBatteryEnabledValue:Boolean;
		private var pumpReservoirEnabledValue:Boolean;
		private var pumpStatusEnabledValue:Boolean;
		private var pumpTimeEnabledValue:Boolean;
		private var cageEnabledValue:Boolean;
		private var sageEnabledValue:Boolean;
		private var iageEnabledValue:Boolean;
		private var transmitterBatteryEnabledValue:Boolean;
		private var sensorNoiseEnabledValue:Boolean;
		private var bageEnabledValue:Boolean;
		
		public function InfoPillSettingsList()
		{
			super();
		}
		
		override protected function initialize():void 
		{
			super.initialize();
			
			setupProperties();
			setupInitialContent();
			setupContent();
		}
		
		/**
		 * Functionality
		 */
		private function setupProperties():void
		{
			/* Properties */
			clipContent = false;
			isSelectable = true;
			autoHideBackground = true;
			hasElasticEdges = false;
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
		}
		
		private function setupInitialContent():void
		{
			infoPillEnabledValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_INFO_PILL_ON) == "true";
			transmitterBatteryEnabledValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TRANSMITTER_BATTERY_ON) == "true";
			rawEnabledValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_RAW_GLUCOSE_ON) == "true";
			basalEnabledValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BASAL_ON) == "true";
			uploaderBatteryEnabledValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_UPLOADER_BATTERY_ON) == "true";
			openAPSMomentEnabledValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_OPENAPS_MOMENT_ON) == "true";
			loopMomentEnabledValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_LOOP_MOMENT_ON) == "true";
			pumpBatteryEnabledValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PUMP_BATTERY_ON) == "true";
			pumpReservoirEnabledValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PUMP_RESERVOIR_ON) == "true";
			pumpStatusEnabledValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PUMP_STATUS_ON) == "true";
			pumpTimeEnabledValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PUMP_TIME_ON) == "true";
			cageEnabledValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CAGE_ON) == "true";
			sageEnabledValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SAGE_ON) == "true";
			sensorNoiseEnabledValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_INFO_PILL_SENSOR_NOISE_ON) == "true";
			iageEnabledValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_IAGE_ON) == "true";
			bageEnabledValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BAGE_ON) == "true";
		}
		
		private function setupContent():void
		{
			/* Enable/Disable Switch */
			infoPillEnabled = LayoutFactory.createToggleSwitch(infoPillEnabledValue);
			infoPillEnabled.addEventListener(Event.CHANGE, onSettingsChanged);
			
			/* Enable/Disable Transmitter Battery */
			displayTransmitterBatteryEnabled = LayoutFactory.createCheckMark(transmitterBatteryEnabledValue);
			displayTransmitterBatteryEnabled.addEventListener(Event.CHANGE, onSettingsChanged);
			
			/* Enable/Disable Raw */
			displayRawEnabled = LayoutFactory.createCheckMark(rawEnabledValue);
			displayRawEnabled.addEventListener(Event.CHANGE, onSettingsChanged);
			
			/* Enable/Disable Basal */
			displayBasalEnabled = LayoutFactory.createCheckMark(basalEnabledValue);
			displayBasalEnabled.addEventListener(Event.CHANGE, onSettingsChanged);
			
			/* Enable/Disable Uploader Battery */
			displayUploaderBatteryEnabled = LayoutFactory.createCheckMark(uploaderBatteryEnabledValue);
			displayUploaderBatteryEnabled.addEventListener(Event.CHANGE, onSettingsChanged);
			
			/* Enable/Disable OpenAPS Moment */
			displayOpenAPSMomentEnabled = LayoutFactory.createCheckMark(openAPSMomentEnabledValue);
			displayOpenAPSMomentEnabled.addEventListener(Event.CHANGE, onSettingsChanged);
			
			/* Enable/Disable Loop Moment */
			displayLoopMomentEnabled = LayoutFactory.createCheckMark(loopMomentEnabledValue);
			displayLoopMomentEnabled.addEventListener(Event.CHANGE, onSettingsChanged);
			
			/* Enable/Disable Pump Battery */
			displayPumpBatteryEnabled = LayoutFactory.createCheckMark(pumpBatteryEnabledValue);
			displayPumpBatteryEnabled.addEventListener(Event.CHANGE, onSettingsChanged);
			
			/* Enable/Disable Pump Reservoir */
			displayPumpReservoirEnabled = LayoutFactory.createCheckMark(pumpReservoirEnabledValue);
			displayPumpReservoirEnabled.addEventListener(Event.CHANGE, onSettingsChanged);
			
			/* Enable/Disable Pump Status */
			displayPumpStatusEnabled = LayoutFactory.createCheckMark(pumpStatusEnabledValue);
			displayPumpStatusEnabled.addEventListener(Event.CHANGE, onSettingsChanged);
			
			/* Enable/Disable Pump Time */
			displayPumpTimeEnabled = LayoutFactory.createCheckMark(pumpTimeEnabledValue);
			displayPumpTimeEnabled.addEventListener(Event.CHANGE, onSettingsChanged);
			
			/* Enable/Disable CAGE */
			displayCAGEEnabled = LayoutFactory.createCheckMark(cageEnabledValue);
			displayCAGEEnabled.addEventListener(Event.CHANGE, onSettingsChanged);
			
			/* Enable/Disable SAGE */
			displaySAGEEnabled = LayoutFactory.createCheckMark(sageEnabledValue);
			displaySAGEEnabled.addEventListener(Event.CHANGE, onSettingsChanged);
			
			/* Enable/Disable Sensor Noise */
			displaySensorNoiseEnabled = LayoutFactory.createCheckMark(sensorNoiseEnabledValue);
			displaySensorNoiseEnabled.addEventListener(Event.CHANGE, onSettingsChanged);
			
			/* Enable/Disable IAGE */
			displayIAGEEnabled = LayoutFactory.createCheckMark(iageEnabledValue);
			displayIAGEEnabled.addEventListener(Event.CHANGE, onSettingsChanged);
			
			/* Enable/Disable BAGE */
			displayBAGEEnabled = LayoutFactory.createCheckMark(bageEnabledValue);
			displayBAGEEnabled.addEventListener(Event.CHANGE, onSettingsChanged);
			
			/* Renderer */
			itemRendererFactory = function():IListItemRenderer 
			{
				const item:DefaultListItemRenderer = new DefaultListItemRenderer();
				item.labelField = "label";
				item.accessoryField = "accessory";
				item.itemHasSelectable = true;
				item.selectableField = "selectable";
				return item;
			};
			
			layoutData = new AnchorLayoutData( 0, 0, 0, 0 );
			
			refreshContent();
		}
		
		private function refreshContent():void
		{
			/* Data */
			var data:Array = [];
			
			data.push({ label: ModelLocator.resourceManagerInstance.getString('globaltranslations',"enabled"), accessory: infoPillEnabled, selectable: false });
			if (infoPillEnabledValue)
			{
				data.push({ label: ModelLocator.resourceManagerInstance.getString('chartscreen',"transmitter_battery"), accessory: displayTransmitterBatteryEnabled, selectable: false });
				if (!CGMBlueToothDevice.isBlueReader() && !CGMBlueToothDevice.isBluKon() && !CGMBlueToothDevice.isLimitter() && !CGMBlueToothDevice.isMiaoMiao() && !CGMBlueToothDevice.isTransmiter_PL())
					data.push({ label: ModelLocator.resourceManagerInstance.getString('chartscreen',"raw_glucose_extended"), accessory: displayRawEnabled, selectable: false });
				data.push({ label: ModelLocator.resourceManagerInstance.getString('chartscreen',"sensor_age"), accessory: displaySAGEEnabled, selectable: false });
				data.push({ label: ModelLocator.resourceManagerInstance.getString('chartscreen',"sensor_noise_label"), accessory: displaySensorNoiseEnabled, selectable: false });
				data.push({ label: ModelLocator.resourceManagerInstance.getString('chartscreen',"canula_age"), accessory: displayCAGEEnabled, selectable: false });
				data.push({ label: ModelLocator.resourceManagerInstance.getString('chartscreen',"insulin_age"), accessory: displayIAGEEnabled, selectable: false });
				data.push({ label: ModelLocator.resourceManagerInstance.getString('chartscreen',"battery_age"), accessory: displayBAGEEnabled, selectable: false });
				data.push({ label: ModelLocator.resourceManagerInstance.getString('chartscreen',"basal_insulin"), accessory: displayBasalEnabled, selectable: false });
				data.push({ label: ModelLocator.resourceManagerInstance.getString('chartscreen',"openaps_moment"), accessory: displayOpenAPSMomentEnabled, selectable: false });
				data.push({ label: ModelLocator.resourceManagerInstance.getString('chartscreen',"loop_moment"), accessory: displayLoopMomentEnabled, selectable: false });
				data.push({ label: ModelLocator.resourceManagerInstance.getString('chartscreen',"uploader_battery"), accessory: displayUploaderBatteryEnabled, selectable: false });
				data.push({ label: ModelLocator.resourceManagerInstance.getString('chartscreen',"pump_reservoir"), accessory: displayPumpReservoirEnabled, selectable: false });
				data.push({ label: ModelLocator.resourceManagerInstance.getString('chartscreen',"pump_time"), accessory: displayPumpTimeEnabled, selectable: false });
				data.push({ label: ModelLocator.resourceManagerInstance.getString('chartscreen',"pump_status"), accessory: displayPumpStatusEnabled, selectable: false });
				data.push({ label: ModelLocator.resourceManagerInstance.getString('chartscreen',"pump_battery"), accessory: displayPumpBatteryEnabled, selectable: false });
			}
			
			dataProvider = new ListCollection(data);
		}
		
		public function save():void
		{
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_INFO_PILL_ON) != String(infoPillEnabledValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_INFO_PILL_ON, String(infoPillEnabledValue));
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TRANSMITTER_BATTERY_ON) != String(transmitterBatteryEnabledValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_TRANSMITTER_BATTERY_ON, String(transmitterBatteryEnabledValue));
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_RAW_GLUCOSE_ON) != String(rawEnabledValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_RAW_GLUCOSE_ON, String(rawEnabledValue));
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BASAL_ON) != String(basalEnabledValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_BASAL_ON, String(basalEnabledValue));
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_UPLOADER_BATTERY_ON) != String(uploaderBatteryEnabledValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_UPLOADER_BATTERY_ON, String(uploaderBatteryEnabledValue));
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_OPENAPS_MOMENT_ON) != String(openAPSMomentEnabledValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_OPENAPS_MOMENT_ON, String(openAPSMomentEnabledValue));
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_LOOP_MOMENT_ON) != String(loopMomentEnabledValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_LOOP_MOMENT_ON, String(loopMomentEnabledValue));
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PUMP_BATTERY_ON) != String(pumpBatteryEnabledValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_PUMP_BATTERY_ON, String(pumpBatteryEnabledValue));
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PUMP_RESERVOIR_ON) != String(pumpReservoirEnabledValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_PUMP_RESERVOIR_ON, String(pumpReservoirEnabledValue));
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PUMP_STATUS_ON) != String(pumpStatusEnabledValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_PUMP_STATUS_ON, String(pumpStatusEnabledValue));
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PUMP_TIME_ON) != String(pumpTimeEnabledValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_PUMP_TIME_ON, String(pumpTimeEnabledValue));
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CAGE_ON) != String(cageEnabledValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_CAGE_ON, String(cageEnabledValue));
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SAGE_ON) != String(sageEnabledValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_SAGE_ON, String(sageEnabledValue));
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_INFO_PILL_SENSOR_NOISE_ON) != String(sensorNoiseEnabledValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_INFO_PILL_SENSOR_NOISE_ON, String(sensorNoiseEnabledValue));
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_IAGE_ON) != String(iageEnabledValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_IAGE_ON, String(iageEnabledValue));
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BAGE_ON) != String(bageEnabledValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_BAGE_ON, String(bageEnabledValue));
			
			needsSave = false;
		}
		
		override protected function setupRenderFactory():void
		{
			/* List Item Renderer */
			itemRendererFactory = function():IListItemRenderer 
			{
				const item:DefaultListItemRenderer = new DefaultListItemRenderer();
				item.labelField = "label";
				item.accessoryField = "accessory";
				item.itemHasSelectable = true;
				item.selectableField = "selectable";
				item.accessoryLabelProperties.wordWrap = true;
				item.defaultLabelProperties.wordWrap = true;
				if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr && !Constants.isPortrait)
				{
					if (Constants.currentOrientation == StageOrientation.ROTATED_RIGHT)
						item.paddingLeft = 30;
					else if (Constants.currentOrientation == StageOrientation.ROTATED_LEFT)
						item.paddingRight = 30;
				}
				return item;
			};
		}
		
		/**
		 * Event Handlers
		 */
		private function onSettingsChanged(e:Event):void
		{	
			infoPillEnabledValue = infoPillEnabled.isSelected;
			transmitterBatteryEnabledValue = displayTransmitterBatteryEnabled.isSelected;
			rawEnabledValue = displayRawEnabled.isSelected;
			basalEnabledValue = displayBasalEnabled.isSelected;
			uploaderBatteryEnabledValue = displayUploaderBatteryEnabled.isSelected;
			openAPSMomentEnabledValue = displayOpenAPSMomentEnabled.isSelected;
			loopMomentEnabledValue = displayLoopMomentEnabled.isSelected;
			pumpBatteryEnabledValue = displayPumpBatteryEnabled.isSelected;
			pumpReservoirEnabledValue = displayPumpReservoirEnabled.isSelected;
			pumpStatusEnabledValue = displayPumpStatusEnabled.isSelected;
			pumpTimeEnabledValue = displayPumpTimeEnabled.isSelected;
			cageEnabledValue = displayCAGEEnabled.isSelected;
			sageEnabledValue = displaySAGEEnabled.isSelected;
			sensorNoiseEnabledValue = displaySensorNoiseEnabled.isSelected;
			iageEnabledValue = displayIAGEEnabled.isSelected;
			bageEnabledValue = displayBAGEEnabled.isSelected;
			
			refreshContent();
			
			needsSave = true;
		}
		
		/**
		 * Utility 
		 */
		override public function dispose():void
		{
			if (infoPillEnabled != null)
			{
				infoPillEnabled.removeEventListener(Event.CHANGE, onSettingsChanged);
				infoPillEnabled.dispose();
				infoPillEnabled = null;
			}
			
			if (displayRawEnabled != null)
			{
				displayRawEnabled.removeEventListener(Event.CHANGE, onSettingsChanged);
				displayRawEnabled.dispose();
				displayRawEnabled = null;
			}
			
			if (displayBasalEnabled != null)
			{
				displayBasalEnabled.removeEventListener(Event.CHANGE, onSettingsChanged);
				displayBasalEnabled.dispose();
				displayBasalEnabled = null;
			}
			
			if (displayUploaderBatteryEnabled != null)
			{
				displayUploaderBatteryEnabled.removeEventListener(Event.CHANGE, onSettingsChanged);
				displayUploaderBatteryEnabled.dispose();
				displayUploaderBatteryEnabled = null;
			}
			
			if (displayOpenAPSMomentEnabled != null)
			{
				displayOpenAPSMomentEnabled.removeEventListener(Event.CHANGE, onSettingsChanged);
				displayOpenAPSMomentEnabled.dispose();
				displayOpenAPSMomentEnabled = null;
			}
			
			if (displayLoopMomentEnabled != null)
			{
				displayLoopMomentEnabled.removeEventListener(Event.CHANGE, onSettingsChanged);
				displayLoopMomentEnabled.dispose();
				displayLoopMomentEnabled = null;
			}
			
			if (displayPumpBatteryEnabled != null)
			{
				displayPumpBatteryEnabled.removeEventListener(Event.CHANGE, onSettingsChanged);
				displayPumpBatteryEnabled.dispose();
				displayPumpBatteryEnabled = null;
			}
			
			if (displayPumpReservoirEnabled != null)
			{
				displayPumpReservoirEnabled.removeEventListener(Event.CHANGE, onSettingsChanged);
				displayPumpReservoirEnabled.dispose();
				displayPumpReservoirEnabled = null;
			}
			
			if (displayPumpStatusEnabled != null)
			{
				displayPumpStatusEnabled.removeEventListener(Event.CHANGE, onSettingsChanged);
				displayPumpStatusEnabled.dispose();
				displayPumpStatusEnabled = null;
			}
			
			if (displayPumpTimeEnabled != null)
			{
				displayPumpTimeEnabled.removeEventListener(Event.CHANGE, onSettingsChanged);
				displayPumpTimeEnabled.dispose();
				displayPumpTimeEnabled = null;
			}
			
			if (displayCAGEEnabled != null)
			{
				displayCAGEEnabled.removeEventListener(Event.CHANGE, onSettingsChanged);
				displayCAGEEnabled.dispose();
				displayCAGEEnabled = null;
			}
			
			if (displaySAGEEnabled != null)
			{
				displaySAGEEnabled.removeEventListener(Event.CHANGE, onSettingsChanged);
				displaySAGEEnabled.dispose();
				displaySAGEEnabled = null;
			}
			
			if (displaySensorNoiseEnabled != null)
			{
				displaySensorNoiseEnabled.removeEventListener(Event.CHANGE, onSettingsChanged);
				displaySensorNoiseEnabled.dispose();
				displaySensorNoiseEnabled = null;
			}
			
			if (displayIAGEEnabled != null)
			{
				displayIAGEEnabled.removeEventListener(Event.CHANGE, onSettingsChanged);
				displayIAGEEnabled.dispose();
				displayIAGEEnabled = null;
			}
			
			if (displayBAGEEnabled != null)
			{
				displayBAGEEnabled.removeEventListener(Event.CHANGE, onSettingsChanged);
				displayBAGEEnabled.dispose();
				displayBAGEEnabled = null;
			}
			
			if (displayTransmitterBatteryEnabled != null)
			{
				displayTransmitterBatteryEnabled.removeEventListener(Event.CHANGE, onSettingsChanged);
				displayTransmitterBatteryEnabled.dispose();
				displayTransmitterBatteryEnabled = null;
			}
			
			super.dispose();
		}
	}
}