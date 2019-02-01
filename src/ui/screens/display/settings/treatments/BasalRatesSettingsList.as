package ui.screens.display.settings.treatments
{
	import flash.display.StageOrientation;
	
	import database.CGMBlueToothDevice;
	import database.CommonSettings;
	
	import events.TreatmentsEvent;
	
	import feathers.controls.Button;
	import feathers.controls.DateTimeMode;
	import feathers.controls.DateTimeSpinner;
	import feathers.controls.Label;
	import feathers.controls.LayoutGroup;
	import feathers.controls.NumericStepper;
	import feathers.controls.PickerList;
	import feathers.controls.popups.DropDownPopUpContentManager;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.data.ArrayCollection;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.HorizontalLayout;
	import feathers.layout.VerticalAlign;
	import feathers.layout.VerticalLayout;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import services.NightscoutService;
	
	import starling.events.Event;
	import starling.events.ResizeEvent;
	
	import treatments.BasalRate;
	import treatments.ProfileManager;
	
	import ui.chart.helpers.GlucoseFactory;
	import ui.popups.AlertManager;
	import ui.screens.display.LayoutFactory;
	import ui.screens.display.SpikeList;
	
	import utils.Constants;
	import utils.DeviceInfo;
	import utils.MathHelper;
	import utils.TimeSpan;
	
	[ResourceBundle("profilesettingsscreen")]
	[ResourceBundle("globaltranslations")]
	
	public class BasalRatesSettingsList extends SpikeList 
	{
		/* Display Objects */
		private var modeLabel:Label;
		private var addBasalRateButton:Button;
		private var saveBasalRateButton:Button;
		private var cancelBasalRateButton:Button;
		private var actionsContainer:LayoutGroup;
		private var basalRateStartTime:DateTimeSpinner;
		private var basalRateStepper:NumericStepper;
		private var basalModePicker:PickerList;
		private var inserterContainer:LayoutGroup;
		private var nsBasalProfileImporterButton:Button;
		
		/* Properties */
		public var needsSave:Boolean = false;
		private var userBasalRates:Array;
		private var accessoryList:Array = [];
		private var addMode:Boolean = false;
		private var editMode:Boolean = false;	
		private var selectedBasalRate:BasalRate;
		private var timeFormat:String;
		private var basalsModeValue:String;
		
		public function BasalRatesSettingsList()
		{
			super(true);
			
			setupProperties();
			setupInitialContent();	
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
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
		}
		
		private function setupInitialContent():void
		{
			/* Get Settings */
			userBasalRates = ProfileManager.basalRatesList;
			basalsModeValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BASALS_MODE);
			timeFormat = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_DATE_FORMAT);
		}
		
		private function setupContent():void
		{	
			//MANAGEMENT MODE Label
			modeLabel = LayoutFactory.createLabel("", HorizontalAlign.CENTER, VerticalAlign.TOP, 14, true);
			modeLabel.wordWrap = true;
			modeLabel.width = width;
			
			//BASAL MODE
			basalModePicker = LayoutFactory.createPickerList();
			
			var basalModeList:ArrayCollection = new ArrayCollection();
			basalModeList.push( { label: ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','multiple_daily_injections_aka_pen_user_label'), id: "mdi" } );
			basalModeList.push( { label: ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','pump_user_label'), id: "pump" } );
			
			basalModePicker.popUpContentManager = new DropDownPopUpContentManager();
			basalModePicker.dataProvider = basalModeList;
			
			if (basalsModeValue == "mdi")
				basalModePicker.selectedIndex = 0;
			else if (basalsModeValue == "pump")
				basalModePicker.selectedIndex = 1;
			
			basalModePicker.itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "label";
				return itemRenderer;
			}
			basalModePicker.addEventListener(Event.CHANGE, onBasalsModeChanged);
			
			//Inserter Container
			inserterContainer = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.LEFT, VerticalAlign.TOP, 5);
			
			//Nightscout Profile Import
			if (!CGMBlueToothDevice.isFollower() && NightscoutService.serviceActive)
			{
				nsBasalProfileImporterButton = LayoutFactory.createButton("Import From Nightscout");
				nsBasalProfileImporterButton.addEventListener(Event.TRIGGERED, onImportNightscoutBasalProfile);
				inserterContainer.addChild(nsBasalProfileImporterButton);
			}
			
			//ADD Button
			addBasalRateButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('globaltranslations','add_button_label'));
			addBasalRateButton.addEventListener(Event.TRIGGERED, onAddBasalRate);
			inserterContainer.addChild(addBasalRateButton);
			
			//Actions Container
			var actionsLayout:HorizontalLayout = new HorizontalLayout();
			actionsLayout.gap = 5;
			actionsContainer = new LayoutGroup();
			actionsContainer.layout = actionsLayout;
			
			//CANCEL Button
			cancelBasalRateButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('globaltranslations','cancel_button_label'));
			cancelBasalRateButton.addEventListener(Event.TRIGGERED, onCancelBasalRate);
			actionsContainer.addChild(cancelBasalRateButton);
			
			//SAVE Button
			saveBasalRateButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('globaltranslations','save_button_label'));
			saveBasalRateButton.addEventListener(Event.TRIGGERED, onSaveBasalRate);
			actionsContainer.addChild(saveBasalRateButton);
			
			//RATE
			basalRateStepper = LayoutFactory.createNumericStepper(0, 100, 0, 0.01);
			
			//START Time
			basalRateStartTime = new DateTimeSpinner();
			basalRateStartTime.editingMode = DateTimeMode.TIME;
			basalRateStartTime.locale = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_APP_LANGUAGE);
			basalRateStartTime.height = 60;
			basalRateStartTime.paddingTop = 5;
			basalRateStartTime.paddingBottom = 5;
			basalRateStartTime.paddingRight = 12;
			basalRateStartTime.minuteStep = 1;
			basalRateStartTime.addEventListener(Event.CHANGE, onTimeChanged);
			
			configureComponents();
			refreshContent();
		}
		
		private function refreshContent():void
		{
			//Set screen content
			var data:Array = [];
			
			data.push( { label: "Mode", accessory:  basalModePicker} );
			
			if (basalsModeValue == "pump")
			{
				//Basal Rates Title
				data.push( { label: ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','basal_rates_title') } );
				
				//Loop Basal Rates
				var validBasalRate:Boolean = false;
				for (var i:int = 0; i < userBasalRates.length; i++) 
				{
					var basalRate:BasalRate = userBasalRates[i];
					if (basalRate != null && basalRate.startTime != "" && !isNaN(basalRate.basalRate))
					{
						//Accessory
						var basalRateAccessory:TreatmentManagerAccessory;
						if (!CGMBlueToothDevice.isFollower())
						{
							basalRateAccessory = new TreatmentManagerAccessory();
							basalRateAccessory.addEventListener(TreatmentManagerAccessory.EDIT, onEditBasalRate);
							basalRateAccessory.addEventListener(TreatmentManagerAccessory.DELETE, onDeleteBasalRate);
							accessoryList.push(basalRateAccessory);
						}
						
						//Data
						data.push( { label: ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','start_time_label') + ": " + TimeSpan.formatHoursMinutes(basalRate.startHours, basalRate.startMinutes, timeFormat.slice(0,2) == "24" ? TimeSpan.TIME_FORMAT_24H : TimeSpan.TIME_FORMAT_12H) + ", " + ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','basal_rate_label') + ": " + GlucoseFactory.formatIOB(basalRate.basalRate), accessory: basalRateAccessory, basalRate: basalRate  } );
						validBasalRate = true;
					}
				}
				
				if (!validBasalRate && !editMode && !addMode)
				{
					data.push( { label: !CGMBlueToothDevice.isFollower() ? ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','add_configuration_label') : ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available') } );
				}
				
				//Add Components
				if (addMode || editMode)
				{
					if (addMode) modeLabel.text = ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','add_basal_rate_label');	
					else if (editMode)modeLabel.text = ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','edit_basal_rate_label');
					
					data.push( { label: "", accessory:  modeLabel} );
					data.push( { label: ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','start_time_label'), accessory: basalRateStartTime } );
					data.push( { label: ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','basal_rate_label'), accessory: basalRateStepper } );
				}
				
				if (!addMode && !editMode)
				{
					var lastBasalRate:BasalRate = userBasalRates[userBasalRates.length - 1] as BasalRate;
					if (((lastBasalRate != null && lastBasalRate.startTime != "23:59") || lastBasalRate == null) && !CGMBlueToothDevice.isFollower())
					{
						data.push( { label: "", accessory: inserterContainer } );
					}
				}
				else
				{
					data.push( { label: "", accessory: actionsContainer } );
				}
			}
			
			dataProvider = new ArrayCollection(data);
		}
		
		private function configureComponents():void
		{
			var basalRateSugestedTime:Date = new Date();
			basalRateSugestedTime.hours = 0;
			basalRateSugestedTime.minutes = 0;
			basalRateSugestedTime.seconds = 0;
			basalRateSugestedTime.milliseconds = 0;
			
			if (editMode && selectedBasalRate != null && selectedBasalRate.startTime == "00:00")
			{
				//Use default date
			}
			else if (!editMode)
			{
				//Get last basal rate
				var lastBasalRate:BasalRate = userBasalRates[userBasalRates.length - 1] as BasalRate;
				if (lastBasalRate != null)
				{
					if (lastBasalRate.startMinutes == 59 && lastBasalRate.startHours < 23)
					{
						basalRateSugestedTime.hours = lastBasalRate.startHours + 1;
						basalRateSugestedTime.minutes = 0;
					}
					else if (lastBasalRate.startMinutes == 59 && lastBasalRate.startHours == 23)
					{
						basalRateSugestedTime.hours = 12;
						basalRateSugestedTime.minutes = 0;
					}
					else
					{
						basalRateSugestedTime.hours = lastBasalRate.startHours;
						basalRateSugestedTime.minutes = lastBasalRate.startMinutes + 1;
					}
				}
			}
			else if (editMode && selectedBasalRate != null)
			{
				//Suggested date should be equal to selected profile date
				basalRateSugestedTime.hours = selectedBasalRate.startHours;
				basalRateSugestedTime.minutes = selectedBasalRate.startMinutes;
			}
			
			basalRateStartTime.value = basalRateSugestedTime;
			
			if (editMode && selectedBasalRate != null && selectedBasalRate.startTime == "00:00")
			{
				basalRateStartTime.touchable = false;
				basalRateStartTime.alpha = 0.6;
			}
			else
			{
				basalRateStartTime.touchable = true;
				basalRateStartTime.alpha = 1;
			}
			
			if (addMode)
			{
				basalRateStepper.value = 0;
			}
			else if (editMode && selectedBasalRate != null)
			{
				basalRateStepper.value = selectedBasalRate.basalRate;
			}
			
			if (saveBasalRateButton != null) saveBasalRateButton.isEnabled = true;
		}
		
		private function doesBasalRateTimeOverlap():Boolean
		{
			var overlapFound:Boolean = false;
			var suggestedHour:Number = basalRateStartTime.value.hours;
			var suggestedMinutes:Number = basalRateStartTime.value.minutes;
			
			for (var i:int = 0; i < userBasalRates.length; i++) 
			{
				var existingBasalRate:BasalRate = userBasalRates[i] as BasalRate;
				
				if (editMode && selectedBasalRate.ID == existingBasalRate.ID)
					continue;
				
				if (suggestedHour == existingBasalRate.startHours && suggestedMinutes == existingBasalRate.startMinutes)
				{
					overlapFound = true;
					break;
				}
			}
			
			return overlapFound;
		}
		
		public function save():void
		{
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BASALS_MODE) != basalsModeValue)
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_BASALS_MODE, basalsModeValue);
			
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
				item.iconSourceField = "icon";
				item.paddingTop = 5;
				item.paddingBottom = 5;
				item.accessoryLabelProperties.wordWrap = true;
				item.defaultLabelProperties.wordWrap = true;
				
				if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr && !Constants.isPortrait)
				{
					if (Constants.currentOrientation == StageOrientation.ROTATED_RIGHT)
					{
						item.paddingLeft = 30;
						if (noRightPadding) item.paddingRight = 0;
					}
					else if (Constants.currentOrientation == StageOrientation.ROTATED_LEFT)
						item.paddingRight = 30;
				}
				else
					if (noRightPadding) item.paddingRight = 0;
				
				return item;
			};
		}
		
		/**
		 * Event Listeners
		 */
		private function onAddBasalRate(e:Event):void
		{
			addMode = true;
			editMode = false;
			
			configureComponents();
			refreshContent();
		}
		
		private function onEditBasalRate(e:Event):void
		{
			var basalRate:BasalRate = (((e.currentTarget as TreatmentManagerAccessory).parent as Object).data as Object).basalRate as BasalRate;
			
			addMode = false;
			editMode = false;
			
			if (basalRate != null)
			{
				editMode = true;
				selectedBasalRate = basalRate;
			}
			
			configureComponents();
			refreshContent();
		}
		
		private function onDeleteBasalRate(e:Event):void
		{
			var basalRate:BasalRate = (((e.currentTarget as TreatmentManagerAccessory).parent as Object).data as Object).basalRate as BasalRate;
			
			AlertManager.showActionAlert
			(
				ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
				ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','delete_basal_rate_confirmation_label'),
				Number.NaN,
				[
					{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations','cancel_button_label').toUpperCase() },
					{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations','yes_uppercase').toUpperCase(), triggered: deleteBasalRate }
				]
			);
			
			function deleteBasalRate():void
			{
				if (basalRate != null)
				{
					ProfileManager.deleteBasalRate(basalRate);
					
					configureComponents();
					refreshContent();
				}
			}
		}
		
		private function onSaveBasalRate(e:Event):void
		{
			if (!editMode && doesBasalRateTimeOverlap())
			{
				AlertManager.showSimpleAlert
				(
					ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
					ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','conflicting_basal_rate_label')
				);
				
				return;
			}
			
			if (addMode)
			{
				var newBasalRate:BasalRate = new BasalRate(basalRateStepper.value, basalRateStartTime.value.hours, basalRateStartTime.value.minutes);
				ProfileManager.insertBasalRate(newBasalRate);
			}
			else if (editMode && selectedBasalRate != null)
			{
				selectedBasalRate.startTime = MathHelper.formatNumberToString(basalRateStartTime.value.hours) + ":" + MathHelper.formatNumberToString(basalRateStartTime.value.minutes);
				selectedBasalRate.startHours = basalRateStartTime.value.hours;
				selectedBasalRate.startMinutes = basalRateStartTime.value.minutes;
				selectedBasalRate.basalRate = basalRateStepper.value;
				selectedBasalRate.timestamp = new Date().valueOf();
				
				ProfileManager.updateBasalRate(selectedBasalRate);
				
				selectedBasalRate = null;
			}
			
			addMode = false;
			editMode = false;
			
			refreshContent();
		}
		
		private function onCancelBasalRate(e:Event):void
		{
			addMode = false;
			editMode = false;
			selectedBasalRate = null;
			
			refreshContent();
		}
		
		private function onBasalsModeChanged(e:Event):void
		{
			basalsModeValue = basalModePicker.selectedItem.id;

			refreshContent();
			
			needsSave = true;
		}
		
		private function onTimeChanged(e:Event):void
		{
			saveBasalRateButton.isEnabled = doesBasalRateTimeOverlap() ? false : true;
		}
		
		private function onImportNightscoutBasalProfile(e:Event):void
		{
			//First delete all existing basal rates
			ProfileManager.deleteAllBasalRates();
			
			//Refresh Content
			refreshContent();
			
			//Query Nightscout
			NightscoutService.instance.addEventListener(TreatmentsEvent.NIGHTSCOUT_BASAL_PROFILE_IMPORTED, onNightscoutBasalProfileImported);
			NightscoutService.getNightscoutProfile(true);
		}
		
		private function onNightscoutBasalProfileImported (e:TreatmentsEvent):void
		{
			NightscoutService.instance.removeEventListener(TreatmentsEvent.NIGHTSCOUT_BASAL_PROFILE_IMPORTED, onNightscoutBasalProfileImported);
			
			refreshContent();
		}
		
		override protected function onStarlingResize(event:ResizeEvent):void 
		{
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
			
			if (modeLabel != null)
				modeLabel.width = width;
			
			setupRenderFactory();
		}
		
		/**
		 * Utility
		 */	
		override protected function draw():void
		{
			if ((layout as VerticalLayout) != null)
			{
				(layout as VerticalLayout).hasVariableItemDimensions = true;
				(layout as VerticalLayout).useVirtualLayout = false;
			}
			
			super.draw();
		}
		
		override public function dispose():void
		{
			NightscoutService.instance.removeEventListener(TreatmentsEvent.NIGHTSCOUT_BASAL_PROFILE_IMPORTED, onNightscoutBasalProfileImported);
			
			if (basalRateStepper != null)
			{
				basalRateStepper.dispose();
				basalRateStepper = null;
			}
			
			if (basalRateStartTime != null)
			{
				basalRateStartTime.removeEventListener(Event.CHANGE, onTimeChanged);
				basalRateStartTime.dispose();
				basalRateStartTime = null;
			}
			
			if (addBasalRateButton != null)
			{
				addBasalRateButton.removeEventListener(Event.TRIGGERED, onAddBasalRate);
				addBasalRateButton.removeFromParent();
				addBasalRateButton.dispose();
				addBasalRateButton = null;
			}
			
			if (nsBasalProfileImporterButton != null)
			{
				nsBasalProfileImporterButton.removeEventListener(Event.TRIGGERED, onImportNightscoutBasalProfile);
				nsBasalProfileImporterButton.removeFromParent();
				nsBasalProfileImporterButton.dispose();
				nsBasalProfileImporterButton = null;
			}
			
			if (inserterContainer != null)
			{
				inserterContainer.removeFromParent();
				inserterContainer.dispose();
				inserterContainer = null;
			}
			
			if (saveBasalRateButton != null)
			{
				saveBasalRateButton.removeEventListener(Event.TRIGGERED, onSaveBasalRate);
				saveBasalRateButton.removeFromParent();
				saveBasalRateButton.dispose();
				saveBasalRateButton = null;
			}
			
			if (cancelBasalRateButton != null)
			{
				cancelBasalRateButton.removeEventListener(Event.TRIGGERED, onCancelBasalRate);
				cancelBasalRateButton.removeFromParent();
				cancelBasalRateButton.dispose();
				cancelBasalRateButton = null;
			}
			
			if (basalModePicker != null)
			{
				basalModePicker.removeEventListener(Event.CHANGE, onBasalsModeChanged);
				basalModePicker.removeFromParent();
				basalModePicker.dispose();
				basalModePicker = null;
			}
			
			if (actionsContainer != null)
			{
				actionsContainer.dispose();
				actionsContainer = null;
			}
			
			if (modeLabel != null)
			{
				modeLabel.dispose();
				modeLabel = null;
			}
			
			super.dispose();
		}
	}
}