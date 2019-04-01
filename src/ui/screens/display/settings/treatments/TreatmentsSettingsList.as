package ui.screens.display.settings.treatments
{
	import flash.display.StageOrientation;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	
	import database.CGMBlueToothDevice;
	import database.CommonSettings;
	
	import feathers.controls.Button;
	import feathers.controls.Check;
	import feathers.controls.PanelScreen;
	import feathers.controls.ScrollPolicy;
	import feathers.controls.ToggleSwitch;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.data.ListCollection;
	import feathers.layout.AnchorLayoutData;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalAlign;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.ModelLocator;
	
	import starling.display.Image;
	import starling.events.Event;
	import starling.textures.Texture;
	
	import ui.AppInterface;
	import ui.chart.visualcomponents.ColorPicker;
	import ui.screens.Screens;
	import ui.screens.display.LayoutFactory;
	import ui.screens.display.SpikeList;
	
	import utils.Constants;
	import utils.DeviceInfo;
	
	[ResourceBundle("treatments")]
	[ResourceBundle("globaltranslations")]
	
	public class TreatmentsSettingsList extends SpikeList 
	{
		/* Display Objects */
		private var chevronIconTexture:Texture;
		private var profileIconImage:Image;
		private var treatmentsEnabled:ToggleSwitch;
		private var nightscoutSyncEnabled:Check;
		private var chartDisplayTreatmentsEnabled:Check;
		private var displayIOBEnabled:Check;
		private var displayCOBEnabled:Check;
		private var insulinColorPicker:ColorPicker;
		private var carbsColorPicker:ColorPicker;
		private var bgCheckColorPicker:ColorPicker;
		private var strokeColorPicker:ColorPicker;
		private var treatmentPillColorPicker:ColorPicker;
		private var newSensorColorPicker:ColorPicker;
		private var _parent:PanelScreen;
		private var resetColors:Button;
		private var loadInstructions:Button;
		private var pumpUserEnabled:Check;
		private var bolusWizardIconImage:Image;
		private var foodManagerIconImage:Image;
		private var chartDisplayBasalsEnabled:Check;
		private var downloadNSBasalsEnabled:Check;
		
		/* Internal Variables */
		public var needsSave:Boolean = false;
		private var treatmentsEnabledValue:Boolean;
		private var nightscoutSyncEnabledValue:Boolean;
		private var downloadNSBasalsEnabledValue:Boolean;
		private var chartDisplayTreatmentsEnabledValue:Boolean;
		private var chartDisplayBasalsEnabledValue:Boolean;
		private var displayIOBEnabledValue:Boolean;
		private var displayCOBEnabledValue:Boolean;
		private var insulinMarkerColorValue:uint;
		private var carbsMarkerColorValue:uint;
		private var bgCheckMarkerColorValue:uint;
		private var treatmentPillColorValue:uint;
		private var strokeMarkerColorValue:uint;
		private var newSensorMarkerColorValue:uint;
		private var pumpUserEnabledValue:Boolean;
		private var colorPickers:Array = [];

		public function TreatmentsSettingsList(parentDisplayObject:PanelScreen)
		{
			this._parent = parentDisplayObject;
			
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
			treatmentsEnabledValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_ENABLED) == "true";
			chartDisplayTreatmentsEnabledValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_ON_CHART_ENABLED) == "true";
			chartDisplayBasalsEnabledValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SHOW_BASALS_ON_CHART) == "true";
			nightscoutSyncEnabledValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_NIGHTSCOUT_DOWNLOAD_ENABLED) == "true";
			displayIOBEnabledValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_IOB_ENABLED) == "true";
			displayCOBEnabledValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_COB_ENABLED) == "true";
			insulinMarkerColorValue = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_INSULIN_MARKER_COLOR));
			carbsMarkerColorValue = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_CARBS_MARKER_COLOR));
			bgCheckMarkerColorValue = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_BGCHECK_MARKER_COLOR));
			strokeMarkerColorValue = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_STROKE_COLOR));
			treatmentPillColorValue = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_PILL_COLOR));
			newSensorMarkerColorValue = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_NEW_SENSOR_MARKER_COLOR));
			pumpUserEnabledValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_LOOP_OPENAPS_USER_ENABLED) == "true";
			downloadNSBasalsEnabledValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DOWNLOAD_NIGHTSCOUT_BASALS) == "true";
		}
		
		private function setupContent():void
		{
			/* Icons */
			chevronIconTexture = MaterialDeepGreyAmberMobileThemeIcons.chevronRightTexture;
			profileIconImage = new Image(chevronIconTexture);
			bolusWizardIconImage = new Image(chevronIconTexture);
			foodManagerIconImage = new Image(chevronIconTexture);
			
			/* Enable/Disable Switch */
			treatmentsEnabled = LayoutFactory.createToggleSwitch(treatmentsEnabledValue);
			treatmentsEnabled.addEventListener(Event.CHANGE, onSettingsChanged);
			
			/* Enable/Disable Display Treatments on Chart */
			chartDisplayTreatmentsEnabled = LayoutFactory.createCheckMark(chartDisplayTreatmentsEnabledValue);
			chartDisplayTreatmentsEnabled.addEventListener(Event.CHANGE, onSettingsChanged);
			
			/* Enable/Disable Display Basals on Chart */
			chartDisplayBasalsEnabled = LayoutFactory.createCheckMark(chartDisplayBasalsEnabledValue);
			chartDisplayBasalsEnabled.addEventListener(Event.CHANGE, onSettingsChanged);
			
			/* Enable/Disable IOB */
			displayIOBEnabled = LayoutFactory.createCheckMark(displayIOBEnabledValue);
			displayIOBEnabled.addEventListener(Event.CHANGE, onSettingsChanged);
			
			/* Enable/Disable COB */
			displayCOBEnabled = LayoutFactory.createCheckMark(displayCOBEnabledValue);
			displayCOBEnabled.addEventListener(Event.CHANGE, onSettingsChanged);
			
			/* Enable/Disable Nightscout Treatments Downloads */
			nightscoutSyncEnabled = LayoutFactory.createCheckMark(nightscoutSyncEnabledValue);
			nightscoutSyncEnabled.addEventListener(Event.CHANGE, onSettingsChanged);
			
			/* Enable/Disable Nightscout Basals Downloads */
			downloadNSBasalsEnabled = LayoutFactory.createCheckMark(downloadNSBasalsEnabledValue);
			downloadNSBasalsEnabled.addEventListener(Event.CHANGE, onSettingsChanged);
			
			/* Enable/Disable Pump User */
			pumpUserEnabled = LayoutFactory.createCheckMark(pumpUserEnabledValue);
			pumpUserEnabled.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Insulin Color Picker
			insulinColorPicker = new ColorPicker(20, insulinMarkerColorValue, _parent, HorizontalAlign.LEFT, VerticalAlign.BOTTOM);
			insulinColorPicker.name = "insulinColor";
			insulinColorPicker.addEventListener(ColorPicker.CHANGED, onColorChanged);
			insulinColorPicker.addEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened);
			insulinColorPicker.addEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
			colorPickers.push(insulinColorPicker);
			
			//Carbs Color Picker
			carbsColorPicker = new ColorPicker(20, carbsMarkerColorValue, _parent, HorizontalAlign.LEFT, VerticalAlign.BOTTOM);
			carbsColorPicker.name = "carbsColor";
			carbsColorPicker.addEventListener(ColorPicker.CHANGED, onColorChanged);
			carbsColorPicker.addEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened);
			carbsColorPicker.addEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
			colorPickers.push(carbsColorPicker);
			
			//BG Check Color Picker
			bgCheckColorPicker = new ColorPicker(20, bgCheckMarkerColorValue, _parent, HorizontalAlign.LEFT, VerticalAlign.BOTTOM);
			bgCheckColorPicker.name = "bgCheckColor";
			bgCheckColorPicker.addEventListener(ColorPicker.CHANGED, onColorChanged);
			bgCheckColorPicker.addEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened);
			bgCheckColorPicker.addEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
			
			//New Sensor
			newSensorColorPicker = new ColorPicker(20, newSensorMarkerColorValue, _parent, HorizontalAlign.LEFT, VerticalAlign.BOTTOM);
			newSensorColorPicker.name = "sensorCheckColor";
			newSensorColorPicker.addEventListener(ColorPicker.CHANGED, onColorChanged);
			newSensorColorPicker.addEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened);
			newSensorColorPicker.addEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
			
			//Stroke Color Picker
			strokeColorPicker = new ColorPicker(20, strokeMarkerColorValue, _parent, HorizontalAlign.LEFT, VerticalAlign.BOTTOM);
			strokeColorPicker.name = "strokeColor";
			strokeColorPicker.addEventListener(ColorPicker.CHANGED, onColorChanged);
			strokeColorPicker.addEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened);
			strokeColorPicker.addEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
			
			//Treatment Pill Color Picker
			treatmentPillColorPicker = new ColorPicker(20, treatmentPillColorValue, _parent, HorizontalAlign.LEFT, VerticalAlign.BOTTOM);
			treatmentPillColorPicker.name = "treatmentPillColor";
			treatmentPillColorPicker.addEventListener(ColorPicker.CHANGED, onColorChanged);
			treatmentPillColorPicker.addEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened);
			treatmentPillColorPicker.addEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
			colorPickers.push(treatmentPillColorPicker);
			
			//Color Reset Button
			resetColors = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('treatments',"default_colors_label"));
			resetColors.pivotX = -3;
			resetColors.addEventListener(Event.TRIGGERED, onResetColor);
			
			//Email configuration files
			loadInstructions = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('treatments',"read_instructions_label"));
			loadInstructions.pivotX = -3;
			loadInstructions.addEventListener(Event.TRIGGERED, onLoadInstructions);
			
			layoutData = new AnchorLayoutData( 0, 0, 0, 0 );
			addEventListener( Event.CHANGE, onMenuChanged );
			
			refreshContent();
		}
		
		private function refreshContent():void
		{
			/* Data */
			var data:Array = [];
			
			data.push({ screen: Screens.SETTINGS_PROFILE, label: ModelLocator.resourceManagerInstance.getString('treatments',"profile_menu_label"), accessory: profileIconImage, selectable: true });
			if (!CGMBlueToothDevice.isFollower() || (CGMBlueToothDevice.isFollower() && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_URL) != "" && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_API_SECRET) != "" && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FOLLOWER_MODE) == "Nightscout"))
			{
				data.push({ screen: Screens.SETTINGS_BOLUS_WIZARD, label: ModelLocator.resourceManagerInstance.getString('treatments',"bolus_wizard_settings_label"), accessory: bolusWizardIconImage, selectable: true });
				data.push({ screen: Screens.SETTINGS_FOOD_MANAGER, label: ModelLocator.resourceManagerInstance.getString('treatments',"food_manager_label"), accessory: foodManagerIconImage, selectable: true });
			}
			data.push({ label: ModelLocator.resourceManagerInstance.getString('globaltranslations',"enabled"), accessory: treatmentsEnabled, selectable: false });
			if (treatmentsEnabledValue)
			{
				data.push({ label: ModelLocator.resourceManagerInstance.getString('treatments',"display_treatments_on_chart_label"), accessory: chartDisplayTreatmentsEnabled, selectable: false });
				data.push({ label: ModelLocator.resourceManagerInstance.getString('treatments',"display_basals_on_chart_label"), accessory: chartDisplayBasalsEnabled, selectable: false });
				if (chartDisplayTreatmentsEnabledValue)
				{
					data.push({ label: ModelLocator.resourceManagerInstance.getString('treatments',"display_iob_label"), accessory: displayIOBEnabled, selectable: false });
					data.push({ label: ModelLocator.resourceManagerInstance.getString('treatments',"display_cob_label"), accessory: displayCOBEnabled, selectable: false });
					data.push({ label: ModelLocator.resourceManagerInstance.getString('treatments',"download_ns_treatments_label"), accessory: nightscoutSyncEnabled, selectable: false });
					data.push({ label: ModelLocator.resourceManagerInstance.getString('treatments',"download_ns_basals_label"), accessory: downloadNSBasalsEnabled, selectable: false });
					if (nightscoutSyncEnabledValue)
						data.push({ label: ModelLocator.resourceManagerInstance.getString('treatments',"loop_openaps_user_label"), accessory: pumpUserEnabled, selectable: false });
					data.push({ label: ModelLocator.resourceManagerInstance.getString('treatments',"insulin_marker_color_label"), accessory: insulinColorPicker, selectable: false });
					data.push({ label: ModelLocator.resourceManagerInstance.getString('treatments',"carbs_marker_color_label"), accessory: carbsColorPicker, selectable: false });
					data.push({ label: ModelLocator.resourceManagerInstance.getString('treatments',"bg_check_marker_color_label"), accessory: bgCheckColorPicker, selectable: false });
					data.push({ label: ModelLocator.resourceManagerInstance.getString('treatments',"sensor_check_marker_color_label"), accessory: newSensorColorPicker, selectable: false });
					data.push({ label: ModelLocator.resourceManagerInstance.getString('treatments',"stroke_marker_color_label"), accessory: strokeColorPicker, selectable: false });
					data.push({ label: ModelLocator.resourceManagerInstance.getString('treatments',"pill_color_label"), accessory: treatmentPillColorPicker, selectable: false });
					data.push({ label: "", accessory: resetColors, selectable: false });
					data.push({ label: "", accessory: loadInstructions, selectable: false });
				}
			}
			
			dataProvider = new ListCollection(data);
		}
		
		public function save():void
		{
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_ENABLED) != String(treatmentsEnabledValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_ENABLED, String(treatmentsEnabledValue));
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_ON_CHART_ENABLED) != String(chartDisplayTreatmentsEnabledValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_ON_CHART_ENABLED, String(chartDisplayTreatmentsEnabledValue));
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_NIGHTSCOUT_DOWNLOAD_ENABLED) != String(nightscoutSyncEnabledValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_NIGHTSCOUT_DOWNLOAD_ENABLED, String(nightscoutSyncEnabledValue));
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_IOB_ENABLED) != String(displayIOBEnabledValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_IOB_ENABLED, String(displayIOBEnabledValue));
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_COB_ENABLED) != String(displayCOBEnabledValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_COB_ENABLED, String(displayCOBEnabledValue));
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_INSULIN_MARKER_COLOR) != String(insulinMarkerColorValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_INSULIN_MARKER_COLOR, String(insulinMarkerColorValue));
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_CARBS_MARKER_COLOR) != String(carbsMarkerColorValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_CARBS_MARKER_COLOR, String(carbsMarkerColorValue));
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_BGCHECK_MARKER_COLOR) != String(bgCheckMarkerColorValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_BGCHECK_MARKER_COLOR, String(bgCheckMarkerColorValue));
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_NEW_SENSOR_MARKER_COLOR) != String(newSensorMarkerColorValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_NEW_SENSOR_MARKER_COLOR, String(newSensorMarkerColorValue));
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_STROKE_COLOR) != String(strokeMarkerColorValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_STROKE_COLOR, String(strokeMarkerColorValue));
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_PILL_COLOR) != String(treatmentPillColorValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_PILL_COLOR, String(treatmentPillColorValue));
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_LOOP_OPENAPS_USER_ENABLED) != String(pumpUserEnabledValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_LOOP_OPENAPS_USER_ENABLED, String(pumpUserEnabledValue));
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SHOW_BASALS_ON_CHART) != String(chartDisplayBasalsEnabledValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_SHOW_BASALS_ON_CHART, String(chartDisplayBasalsEnabledValue));
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DOWNLOAD_NIGHTSCOUT_BASALS) != String(downloadNSBasalsEnabledValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_DOWNLOAD_NIGHTSCOUT_BASALS, String(downloadNSBasalsEnabledValue));
			
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
			treatmentsEnabledValue = treatmentsEnabled.isSelected;
			chartDisplayTreatmentsEnabledValue = chartDisplayTreatmentsEnabled.isSelected;
			nightscoutSyncEnabledValue = nightscoutSyncEnabled.isSelected;
			displayIOBEnabledValue = displayIOBEnabled.isSelected;
			displayCOBEnabledValue = displayCOBEnabled.isSelected;
			pumpUserEnabledValue = pumpUserEnabled.isSelected;
			chartDisplayBasalsEnabledValue = chartDisplayBasalsEnabled.isSelected;
			downloadNSBasalsEnabledValue = downloadNSBasalsEnabled.isSelected;
			
			refreshContent();
			
			needsSave = true;
		}
		
		private function onLoadInstructions(e:Event):void
		{
			navigateToURL(new URLRequest("https://github.com/SpikeApp/Spike/wiki/Treatments"));
		}
		
		private function onColorPaletteOpened(e:Event):void
		{
			var triggerName:String = e.data.name;
			for (var i:int = 0; i < colorPickers.length; i++) 
			{
				var currentName:String = colorPickers[i].name;
				if(currentName != triggerName)
					(colorPickers[i] as ColorPicker).palette.visible = false;
			}
			_parent.verticalScrollPolicy = ScrollPolicy.OFF;
		}
		
		private function onColorPaletteClosed(e:Event):void
		{
			_parent.verticalScrollPolicy = ScrollPolicy.ON;
		}
		
		private function onColorChanged(e:Event):void
		{
			var currentTargetName:String = (e.currentTarget as ColorPicker).name;
			
			if(currentTargetName == "insulinColor")
			{
				if(insulinColorPicker.value != insulinMarkerColorValue)
				{
					insulinMarkerColorValue = insulinColorPicker.value;
					needsSave = true;
				}
			}
			else if(currentTargetName == "carbsColor")
			{
				if(carbsColorPicker.value != carbsMarkerColorValue)
				{
					carbsMarkerColorValue = carbsColorPicker.value;
					needsSave = true;
				}
			}
			else if(currentTargetName == "bgCheckColor")
			{
				if(bgCheckColorPicker.value != bgCheckMarkerColorValue)
				{
					bgCheckMarkerColorValue = bgCheckColorPicker.value;
					needsSave = true;
				}
			}
			else if(currentTargetName == "sensorCheckColor")
			{
				if(newSensorColorPicker.value != newSensorMarkerColorValue)
				{
					newSensorMarkerColorValue = newSensorColorPicker.value;
					needsSave = true;
				}
			}
			else if(currentTargetName == "treatmentPillColor")
			{
				if(treatmentPillColorPicker.value != treatmentPillColorValue)
				{
					treatmentPillColorValue = treatmentPillColorPicker.value;
					needsSave = true;
				}
			}
			else if(currentTargetName == "strokeColor")
			{
				if(strokeColorPicker.value != strokeMarkerColorValue)
				{
					strokeMarkerColorValue = strokeColorPicker.value;
					needsSave = true;
				}
			}
		}
		
		private function onResetColor(e:Event):void
		{
			//Insulin Color Picker
			insulinColorPicker.setColor(0x0086FF);
			insulinMarkerColorValue = 0x0086FF;
			
			//Carbs Color Picker
			carbsColorPicker.setColor(0xF8A246);
			carbsMarkerColorValue = 0xF8A246;
			
			//BG Check Color Picker
			bgCheckColorPicker.setColor(0xFF0000);
			bgCheckMarkerColorValue = 0xFF0000;
			
			//New Sensor Color Picker
			newSensorColorPicker.setColor(0x666666);
			newSensorMarkerColorValue = 0x666666;
			
			//Stroke Color Picker
			strokeColorPicker.setColor(0xEEEEEE);
			strokeMarkerColorValue = 0xEEEEEE;
			
			//Low Color Picker
			treatmentPillColorPicker.setColor(0xEEEEEE);
			treatmentPillColorValue = 0xEEEEEE;
			
			needsSave = true;
		}
		
		private function onMenuChanged(e:Event):void 
		{
			const screenName:String = selectedItem.screen as String;
			
			if (needsSave)
				save();
			
			AppInterface.instance.navigator.pushScreen( screenName );
		}
		
		/**
		 * Utility 
		 */
		override public function dispose():void
		{
			removeEventListener( Event.CHANGE, onMenuChanged );
			
			if (chevronIconTexture != null)
			{
				chevronIconTexture.dispose();
				chevronIconTexture = null;
			}
			
			if (profileIconImage != null)
			{
				if (profileIconImage.texture != null)
					profileIconImage.texture.dispose();
				profileIconImage.dispose();
				profileIconImage = null;
			}
			
			if (bolusWizardIconImage != null)
			{
				if (bolusWizardIconImage.texture != null)
					bolusWizardIconImage.texture.dispose();
				bolusWizardIconImage.dispose();
				bolusWizardIconImage = null;
			}
			
			if (foodManagerIconImage != null)
			{
				if (foodManagerIconImage.texture != null)
					foodManagerIconImage.texture.dispose();
				foodManagerIconImage.dispose();
				foodManagerIconImage = null;
			}
			
			if (treatmentsEnabled != null)
			{
				treatmentsEnabled.removeEventListener(Event.CHANGE, onSettingsChanged);
				treatmentsEnabled.dispose();
				treatmentsEnabled = null;
			}
			
			if (chartDisplayTreatmentsEnabled != null)
			{
				chartDisplayTreatmentsEnabled.removeEventListener(Event.CHANGE, onSettingsChanged);
				chartDisplayTreatmentsEnabled.dispose();
				chartDisplayTreatmentsEnabled = null;
			}
			
			if (chartDisplayBasalsEnabled != null)
			{
				chartDisplayBasalsEnabled.removeEventListener(Event.CHANGE, onSettingsChanged);
				chartDisplayBasalsEnabled.dispose();
				chartDisplayBasalsEnabled = null;
			}
			
			if (nightscoutSyncEnabled != null)
			{
				nightscoutSyncEnabled.removeEventListener(Event.CHANGE, onSettingsChanged);
				nightscoutSyncEnabled.dispose();
				nightscoutSyncEnabled = null;
			}
			
			if (downloadNSBasalsEnabled != null)
			{
				downloadNSBasalsEnabled.removeEventListener(Event.CHANGE, onSettingsChanged);
				downloadNSBasalsEnabled.dispose();
				downloadNSBasalsEnabled = null;
			}
			
			if (displayIOBEnabled != null)
			{
				displayIOBEnabled.removeEventListener(Event.CHANGE, onSettingsChanged);
				displayIOBEnabled.dispose();
				displayIOBEnabled = null;
			}
			
			if (displayCOBEnabled != null)
			{
				displayCOBEnabled.removeEventListener(Event.CHANGE, onSettingsChanged);
				displayCOBEnabled.dispose();
				displayCOBEnabled = null;
			}
			
			if (insulinColorPicker != null)
			{
				insulinColorPicker.removeEventListener(ColorPicker.CHANGED, onColorChanged);
				insulinColorPicker.removeEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened);
				insulinColorPicker.removeEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
				insulinColorPicker.dispose();
				insulinColorPicker = null;
			}
			
			if (carbsColorPicker != null)
			{
				carbsColorPicker.removeEventListener(ColorPicker.CHANGED, onColorChanged);
				carbsColorPicker.removeEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened);
				carbsColorPicker.removeEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
				carbsColorPicker.dispose();
				carbsColorPicker = null;
			}
			
			if (bgCheckColorPicker != null)
			{
				bgCheckColorPicker.removeEventListener(ColorPicker.CHANGED, onColorChanged);
				bgCheckColorPicker.removeEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened);
				bgCheckColorPicker.removeEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
				bgCheckColorPicker.dispose();
				bgCheckColorPicker = null;
			}
			
			if (newSensorColorPicker != null)
			{
				newSensorColorPicker.removeEventListener(ColorPicker.CHANGED, onColorChanged);
				newSensorColorPicker.removeEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened);
				newSensorColorPicker.removeEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
				newSensorColorPicker.dispose();
				newSensorColorPicker = null;
			}
			
			if (strokeColorPicker != null)
			{
				strokeColorPicker.removeEventListener(ColorPicker.CHANGED, onColorChanged);
				strokeColorPicker.removeEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened);
				strokeColorPicker.removeEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
				strokeColorPicker.dispose();
				strokeColorPicker = null;
			}
			
			if (treatmentPillColorPicker != null)
			{
				treatmentPillColorPicker.removeEventListener(ColorPicker.CHANGED, onColorChanged);
				treatmentPillColorPicker.removeEventListener(ColorPicker.PALETTE_OPEN, onColorPaletteOpened);
				treatmentPillColorPicker.removeEventListener(ColorPicker.PALETTE_CLOSE, onColorPaletteClosed);
				treatmentPillColorPicker.dispose();
				treatmentPillColorPicker = null;
			}
			
			if (resetColors != null)
			{
				resetColors.removeEventListener(Event.TRIGGERED, onResetColor);
				resetColors.dispose();
				resetColors = null;
			}
			
			if (loadInstructions != null)
			{
				loadInstructions.removeEventListener(Event.TRIGGERED, onLoadInstructions);
				loadInstructions.dispose();
				loadInstructions = null;
			}
			
			if (pumpUserEnabled != null)
			{
				pumpUserEnabled.removeEventListener(Event.CHANGE, onSettingsChanged);
				pumpUserEnabled.dispose();
				pumpUserEnabled = null;
			}
			
			super.dispose();
		}
	}
}