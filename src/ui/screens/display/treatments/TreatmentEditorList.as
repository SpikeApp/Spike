package ui.screens.display.treatments
{
	import com.adobe.utils.StringUtil;
	
	import database.BgReading;
	import database.CommonSettings;
	
	import feathers.controls.Button;
	import feathers.controls.DateTimeMode;
	import feathers.controls.DateTimeSpinner;
	import feathers.controls.GroupedList;
	import feathers.controls.LayoutGroup;
	import feathers.controls.NumericStepper;
	import feathers.controls.PickerList;
	import feathers.controls.TextArea;
	import feathers.controls.popups.DropDownPopUpContentManager;
	import feathers.controls.renderers.DefaultGroupedListItemRenderer;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IGroupedListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.data.ArrayCollection;
	import feathers.data.HierarchicalCollection;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.HorizontalLayout;
	import feathers.layout.VerticalAlign;
	import feathers.layout.VerticalLayout;
	import feathers.layout.VerticalLayoutData;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.ModelLocator;
	
	import starling.events.Event;
	import starling.text.TextFormat;
	
	import treatments.Insulin;
	import treatments.ProfileManager;
	import treatments.Treatment;
	import treatments.TreatmentsManager;
	
	import ui.popups.AlertManager;
	import ui.screens.display.LayoutFactory;
	
	import utils.Constants;
	import utils.DeviceInfo;
	import utils.GlucoseHelper;
	import utils.TimeSpan;
	
	[ResourceBundle("globaltranslations")]
	[ResourceBundle("treatments")]
	[ResourceBundle("chartscreen")]
	[ResourceBundle("generalsettingsscreen")]

	public class TreatmentEditorList extends GroupedList 
	{	
		/* Display Objects */
		private var treatmentTime:DateTimeSpinner;
		private var saveTreatment:Button;
		private var cancelTreatment:Button;
		private var actionButtonsContainer:LayoutGroup;
		private var insulinsPicker:PickerList;
		private var insulinAmountStepper:NumericStepper;
		private var carbsAmountStepper:NumericStepper;
		private var glucoseAmountStepper:NumericStepper;
		private var noteTextArea:TextArea;
		private var treatmentTimeConatiner:LayoutGroup;
		private var carbTypePicker:PickerList;
		private var splitNowStepper:NumericStepper;
		private var splitExtStepper:NumericStepper;
		private var extensionDuration:NumericStepper;
		private var exerciseDurationStepper:NumericStepper;
		private var exerciseIntensityPicker:PickerList;
		private var tempBasalDurationStepper:NumericStepper;
		
		/* Properties */
		private var treatment:Treatment;
		private var isMgDl:Boolean;

		public function TreatmentEditorList(treatment:Treatment)
		{
			super();
			
			this.treatment = treatment;
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
			//Set Properties
			clipContent = false;
			isSelectable = false;
			autoHideBackground = true;
			hasElasticEdges = false;
			layoutData = new VerticalLayoutData( 100 );
			width = Constants.stageWidth * 0.85;
			maxWidth = 300;
			(layout as VerticalLayout).hasVariableItemDimensions = true;
			(layout as VerticalLayout).useVirtualLayout = false;
		}
		
		private function setupInitialState(glucoseUnit:String = null):void
		{
			isMgDl = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true";
		}
		
		private function setupContent():void
		{
			var treatmentType:String;
			var userInsulins:Array;
			var insulinsList:ArrayCollection;
			var selectedInsulin:int;
			var insulin:Insulin;
			var allInsulinTypes:Array;
			var longActing:String;
			var i:int
			
			if (treatment.type == Treatment.TYPE_BOLUS || treatment.type == Treatment.TYPE_CORRECTION_BOLUS || treatment.type == Treatment.TYPE_MEAL_BOLUS || treatment.type == Treatment.TYPE_EXTENDED_COMBO_BOLUS_PARENT || treatment.type == Treatment.TYPE_EXTENDED_COMBO_MEAL_PARENT)
			{
				//Treatment Type
				if (treatment.type == Treatment.TYPE_BOLUS || treatment.type == Treatment.TYPE_CORRECTION_BOLUS)
					treatmentType = ModelLocator.resourceManagerInstance.getString('treatments',"treatment_name_bolus");
				
				//User's insulins
				userInsulins = ProfileManager.insulinsList;
				insulinsPicker = LayoutFactory.createPickerList()
				insulinsList = new ArrayCollection();
				allInsulinTypes = ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','insulin_types_list').split(",");
				longActing = StringUtil.trim(allInsulinTypes[4]);
				
				selectedInsulin = 0;
				if (userInsulins != null)
				{
					for (i = 0; i < userInsulins.length; i++) 
					{
						insulin = userInsulins[i];
						
						if (insulin != null && insulin.type != longActing)
						{
							insulinsList.push( {label: insulin.name + (insulin.isHidden == true && insulin.name.indexOf("Nightscout") == -1 ? " " + "(" + ModelLocator.resourceManagerInstance.getString('generalsettingsscreen',"collection_list").split(",")[0] + ")" : ""), id: insulin.ID} );
							
							if (insulin.ID == treatment.insulinID)
								selectedInsulin = insulinsList.length - 1;
						}
					}
				}
				insulinsPicker.maxWidth = 150;
				insulinsPicker.labelField = "label";
				insulinsPicker.itemRendererFactory = function():IListItemRenderer
				{
					var renderer:DefaultListItemRenderer = new DefaultListItemRenderer();
					renderer.paddingRight = renderer.paddingLeft = 20;
					return renderer;
				};
				insulinsPicker.popUpContentManager = new DropDownPopUpContentManager();
				insulinsPicker.dataProvider = insulinsList;
				insulinsPicker.selectedIndex = selectedInsulin;
				insulinsPicker.addEventListener(Event.CHANGE, onSettingsChanged);
				
				//Insulin Amount
				insulinAmountStepper = LayoutFactory.createNumericStepper(treatment.type == Treatment.TYPE_MEAL_BOLUS ? 0 : 0.1, 150, treatment.insulinAmount, 0.1);
				if (treatment.type == Treatment.TYPE_EXTENDED_COMBO_BOLUS_PARENT || treatment.type == Treatment.TYPE_EXTENDED_COMBO_MEAL_PARENT)
				{
					insulinAmountStepper.value = treatment.getTotalInsulin();
				}
				insulinAmountStepper.pivotX = -10;
				insulinAmountStepper.addEventListener(Event.CHANGE, onSettingsChanged);
			}
			
			if (treatment.type == Treatment.TYPE_EXTENDED_COMBO_BOLUS_PARENT || treatment.type == Treatment.TYPE_EXTENDED_COMBO_MEAL_PARENT)
			{
				var parentSplit:Number = Math.round((treatment.insulinAmount * 100) / treatment.getTotalInsulin());
				var childrenSplit:Number = 100 - parentSplit;
				
				splitNowStepper = LayoutFactory.createNumericStepper(0, 100, parentSplit, 5);
				splitNowStepper.pivotX = -10;
				splitNowStepper.addEventListener(Event.CHANGE, onSettingsChanged);
				splitNowStepper.addEventListener(Event.CHANGE, onSplitNowChanged);
				
				splitExtStepper = LayoutFactory.createNumericStepper(0, 100, childrenSplit, 5);
				splitExtStepper.pivotX = -10;
				splitExtStepper.addEventListener(Event.CHANGE, onSettingsChanged);
				splitExtStepper.addEventListener(Event.CHANGE, onSplitExtChanged);
				
				extensionDuration = LayoutFactory.createNumericStepper(10, 1000, treatment.childTreatments.length * 5, 5);
				extensionDuration.pivotX = -10;
				extensionDuration.addEventListener(Event.CHANGE, onSettingsChanged);
			}
			
			if (treatment.type == Treatment.TYPE_CARBS_CORRECTION || treatment.type == Treatment.TYPE_MEAL_BOLUS || treatment.type == Treatment.TYPE_EXTENDED_COMBO_MEAL_PARENT)
			{
				//Treatment Type
				if (treatment.type == Treatment.TYPE_CARBS_CORRECTION)
					treatmentType = ModelLocator.resourceManagerInstance.getString('treatments',"treatment_name_carbs");
				
				//Carbs Amount
				carbsAmountStepper = LayoutFactory.createNumericStepper(treatment.type == Treatment.TYPE_MEAL_BOLUS ? 0 : 1, 1000, treatment.carbs, 0.5);
				carbsAmountStepper.pivotX = -10;
				carbsAmountStepper.addEventListener(Event.CHANGE, onSettingsChanged);
				
				//Carb absorption delay
				carbTypePicker = LayoutFactory.createPickerList();
				carbTypePicker.popUpContentManager = new DropDownPopUpContentManager();
				carbTypePicker.labelField = "label";
				carbTypePicker.itemRendererFactory = function():IListItemRenderer
				{
					var renderer:DefaultListItemRenderer = new DefaultListItemRenderer();
					renderer.paddingRight = renderer.paddingLeft = 20;
					return renderer;
				};
				
				var carbTypeListDataProvider:ArrayCollection = new ArrayCollection();
				carbTypeListDataProvider.push( { label: ModelLocator.resourceManagerInstance.getString('treatments','carbs_fast_label') } );
				carbTypeListDataProvider.push( { label: ModelLocator.resourceManagerInstance.getString('treatments','carbs_medium_label') } );
				carbTypeListDataProvider.push( { label: ModelLocator.resourceManagerInstance.getString('treatments','carbs_slow_label') } );
				
				carbTypePicker.dataProvider = carbTypeListDataProvider;
				
				//Get current carb type
				var carbType:String = TreatmentsManager.getCarbTypeName(treatment);
				if (carbType == ModelLocator.resourceManagerInstance.getString('treatments','carbs_fast_label'))
					carbTypePicker.selectedIndex = 0;
				else if (carbType == ModelLocator.resourceManagerInstance.getString('treatments','carbs_medium_label'))
					carbTypePicker.selectedIndex = 1;
				else if (carbType == ModelLocator.resourceManagerInstance.getString('treatments','carbs_slow_label'))
					carbTypePicker.selectedIndex = 2;
				
				carbTypePicker.addEventListener(Event.CHANGE, onSettingsChanged);
			}
			
			if (treatment.type == Treatment.TYPE_GLUCOSE_CHECK)
			{
				//Treatment Type
				treatmentType = ModelLocator.resourceManagerInstance.getString('treatments',"treatment_name_bg_check");
				
				//Glucose Amount
				glucoseAmountStepper = LayoutFactory.createNumericStepper
				(
					isMgDl ? 30 : Math.round(((BgReading.mgdlToMmol((30))) * 10)) / 10,
					isMgDl ? 400 : Math.round(((BgReading.mgdlToMmol((400))) * 10)) / 10,
					isMgDl ? treatment.glucose : Math.round(((BgReading.mgdlToMmol((treatment.glucose))) * 10)) / 10,
					isMgDl ? 1 : 0.1
				);
				glucoseAmountStepper.pivotX = -10;
				glucoseAmountStepper.addEventListener(Event.CHANGE, onSettingsChanged);
			}
			
			if (treatment.type == Treatment.TYPE_MEAL_BOLUS)
				treatmentType = ModelLocator.resourceManagerInstance.getString('treatments',"treatment_name_meal"); //Treatment Type
			
			if (treatment.type == Treatment.TYPE_NOTE)
				treatmentType = ModelLocator.resourceManagerInstance.getString('treatments',"treatment_name_note"); //Treatment Type
			
			if (treatment.type == Treatment.TYPE_EXTENDED_COMBO_BOLUS_PARENT)
				treatmentType = ModelLocator.resourceManagerInstance.getString('treatments',"extended_bolus_treatment"); //Treatment Type
			
			if (treatment.type == Treatment.TYPE_EXTENDED_COMBO_MEAL_PARENT)
				treatmentType = ModelLocator.resourceManagerInstance.getString('treatments',"meal_with_extended_bolus"); //Treatment Type
			
			if (treatment.type == Treatment.TYPE_EXERCISE)
			{
				treatmentType = ModelLocator.resourceManagerInstance.getString('treatments',"treatment_name_exercise"); //Treatment Type
				
				//Exercise Duration
				exerciseDurationStepper = LayoutFactory.createNumericStepper(5, 1000, treatment.duration, 5);
				exerciseDurationStepper.pivotX = -10;
				exerciseDurationStepper.addEventListener(Event.CHANGE, onSettingsChanged);
				
				//Exercise Intensity
				exerciseIntensityPicker = LayoutFactory.createPickerList();
				exerciseIntensityPicker.popUpContentManager = new DropDownPopUpContentManager();
				exerciseIntensityPicker.labelField = "label";
				exerciseIntensityPicker.itemRendererFactory = function():IListItemRenderer
				{
					var renderer:DefaultListItemRenderer = new DefaultListItemRenderer();
					renderer.paddingRight = renderer.paddingLeft = 20;
					return renderer;
				};
				
				var exerciseIntensityDataProvider:ArrayCollection = new ArrayCollection();
				exerciseIntensityDataProvider.push( { label: ModelLocator.resourceManagerInstance.getString('treatments','exercise_intensity_high_label') } );
				exerciseIntensityDataProvider.push( { label: ModelLocator.resourceManagerInstance.getString('treatments','exercise_intensity_moderate_label') } );
				exerciseIntensityDataProvider.push( { label: ModelLocator.resourceManagerInstance.getString('treatments','exercise_intensity_low_label') } );
				
				exerciseIntensityPicker.dataProvider = exerciseIntensityDataProvider;
				
				if (treatment.exerciseIntensity == Treatment.EXERCISE_INTENSITY_HIGH)
					exerciseIntensityPicker.selectedIndex = 0;
				else if (treatment.exerciseIntensity == Treatment.EXERCISE_INTENSITY_MODERATE)
					exerciseIntensityPicker.selectedIndex = 1;
				else if (treatment.exerciseIntensity == Treatment.EXERCISE_INTENSITY_LOW)
					exerciseIntensityPicker.selectedIndex = 2;
				
				exerciseIntensityPicker.addEventListener(Event.CHANGE, onSettingsChanged);
			}
			
			if (treatment.type == Treatment.TYPE_INSULIN_CARTRIDGE_CHANGE)
				treatmentType = ModelLocator.resourceManagerInstance.getString('treatments',"treatment_name_insulin_cartridge_change");
			
			if (treatment.type == Treatment.TYPE_PUMP_BATTERY_CHANGE)
				treatmentType = ModelLocator.resourceManagerInstance.getString('treatments',"treatment_name_pump_battery_change"); 
			
			if (treatment.type == Treatment.TYPE_PUMP_SITE_CHANGE)
				treatmentType = ModelLocator.resourceManagerInstance.getString('treatments',"treatment_name_pump_site_change"); 
			
			if (treatment.type == Treatment.TYPE_TEMP_BASAL || treatment.type == Treatment.TYPE_MDI_BASAL)
			{
				treatmentType = !treatment.isTempBasalEnd ? ModelLocator.resourceManagerInstance.getString('treatments',"treatment_name_temp_basal") : ModelLocator.resourceManagerInstance.getString('treatments',"treatment_name_temp_basal_end");
				if (treatment.type == Treatment.TYPE_MDI_BASAL)
				{
					treatmentType = ModelLocator.resourceManagerInstance.getString('treatments',"treatment_name_basal")
				}
				
				if (treatment.type == Treatment.TYPE_MDI_BASAL)
				{
					//User's insulins
					userInsulins = ProfileManager.insulinsList;
					insulinsPicker = LayoutFactory.createPickerList()
					insulinsList = new ArrayCollection();
				 	allInsulinTypes = ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','insulin_types_list').split(",");
					longActing = StringUtil.trim(allInsulinTypes[4]);
					
					selectedInsulin = 0;
					if (userInsulins != null)
					{
						for (i = 0; i < userInsulins.length; i++) 
						{
							insulin = userInsulins[i];
							
							if (insulin != null && insulin.type == longActing)
							{
								insulinsList.push( {label: insulin.name + (insulin.isHidden == true && insulin.name.indexOf("Nightscout") == -1 ? " " + "(" + ModelLocator.resourceManagerInstance.getString('generalsettingsscreen',"collection_list").split(",")[0] + ")" : ""), id: insulin.ID} );
								
								if (insulin.ID == treatment.insulinID)
								{
									selectedInsulin = insulinsList.length - 1;
								}
							}
						}
					}
					insulinsPicker.maxWidth = 150;
					insulinsPicker.labelField = "label";
					insulinsPicker.itemRendererFactory = function():IListItemRenderer
					{
						var renderer:DefaultListItemRenderer = new DefaultListItemRenderer();
						renderer.paddingRight = renderer.paddingLeft = 20;
						return renderer;
					};
					insulinsPicker.popUpContentManager = new DropDownPopUpContentManager();
					insulinsPicker.dataProvider = insulinsList;
					insulinsPicker.selectedIndex = selectedInsulin;
					insulinsPicker.addEventListener(Event.CHANGE, onSettingsChanged);
				}
				
				//Insulin Amount
				insulinAmountStepper = LayoutFactory.createNumericStepper(treatment.type == Treatment.TYPE_TEMP_BASAL ? 0 : 0.1, 150, treatment.isBasalAbsolute ? Math.round(treatment.basalAbsoluteAmount * 100) / 100 : treatment.basalPercentAmount, treatment.type == Treatment.TYPE_TEMP_BASAL ? 0.01 : 0.5);
				if (treatment.type == Treatment.TYPE_MDI_BASAL)
				{
					insulinAmountStepper.step = 0.5;
					insulinAmountStepper.minimum = 0.5;
					insulinAmountStepper.maximum = 200;
				}
				insulinAmountStepper.pivotX = -10;
				insulinAmountStepper.addEventListener(Event.CHANGE, onSettingsChanged);
				
				//Basal Duration
				tempBasalDurationStepper = LayoutFactory.createNumericStepper(0, 10000, treatment.basalDuration, 5);
				tempBasalDurationStepper.pivotX = -10;
				tempBasalDurationStepper.addEventListener(Event.CHANGE, onSettingsChanged);
			}
			
			//Treatment Time
			var treatmentTimeLayout:VerticalLayout = new VerticalLayout();
			treatmentTimeLayout.verticalAlign = VerticalAlign.MIDDLE;
			treatmentTimeConatiner = new LayoutGroup();
			treatmentTimeConatiner.height = 60;
			treatmentTimeConatiner.layout = treatmentTimeLayout;
			
			treatmentTime = new DateTimeSpinner();
			treatmentTime.editingMode = DateTimeMode.TIME;
			treatmentTime.locale = Constants.getUserLocale(true);
			treatmentTime.value = new Date(treatment.timestamp);
			treatmentTime.height = 40;
			treatmentTime.addEventListener(Event.CHANGE, onSettingsChanged);
			treatmentTimeConatiner.addChild(treatmentTime);
			
			/* Treatment Note */
			noteTextArea = new TextArea();
			noteTextArea.width = 140;
			noteTextArea.height = 120;
			if ((treatment.type == Treatment.TYPE_MEAL_BOLUS || treatment.type == Treatment.TYPE_BOLUS || treatment.type == Treatment.TYPE_CORRECTION_BOLUS || treatment.type == Treatment.TYPE_EXTENDED_COMBO_BOLUS_PARENT || treatment.type == Treatment.TYPE_EXTENDED_COMBO_MEAL_PARENT) && Constants.deviceModel == DeviceInfo.IPHONE_2G_3G_3GS_4_4S_ITOUCH_2_3_4)
				noteTextArea.height = 50;
			noteTextArea.fontStyles = new TextFormat("Roboto", 14, 0xEEEEEE, HorizontalAlign.RIGHT, VerticalAlign.TOP);
			noteTextArea.paddingTop = noteTextArea.paddingBottom = 10;
			noteTextArea.maxChars = 50;
			noteTextArea.text = treatment.note;
			noteTextArea.addEventListener(Event.CHANGE, onSettingsChanged);
			
			/* Action Buttons */
			var actionButtonsLayout:HorizontalLayout = new HorizontalLayout();
			actionButtonsLayout.gap = 5;
			
			actionButtonsContainer = new LayoutGroup();
			actionButtonsContainer.layout = actionButtonsLayout;
			actionButtonsContainer.pivotX = -3;
			
			cancelTreatment = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('globaltranslations',"cancel_button_label"), false, MaterialDeepGreyAmberMobileThemeIcons.cancelTexture);
			cancelTreatment.addEventListener(Event.TRIGGERED, onCancelTreatment);
			actionButtonsContainer.addChild(cancelTreatment);
			
			saveTreatment = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('globaltranslations',"save_button_label"), false, MaterialDeepGreyAmberMobileThemeIcons.saveTexture);
			saveTreatment.isEnabled = false;
			saveTreatment.addEventListener(Event.TRIGGERED, onSaveTreatment);
			actionButtonsContainer.addChild(saveTreatment);
			
			/* Data */
			var screenDataContent:Array = [];
			
			var infoSection:Object = {};
			infoSection.header = { label: treatmentType };
			
			var infoSectionChildren:Array = [];
			infoSectionChildren.push({ label: ModelLocator.resourceManagerInstance.getString('treatments',"treatment_time_label"), accessory: treatmentTimeConatiner });
			if (treatment.type == Treatment.TYPE_BOLUS || treatment.type == Treatment.TYPE_CORRECTION_BOLUS || treatment.type == Treatment.TYPE_MEAL_BOLUS || treatment.type == Treatment.TYPE_EXTENDED_COMBO_BOLUS_PARENT || treatment.type == Treatment.TYPE_EXTENDED_COMBO_MEAL_PARENT)
			{
				infoSectionChildren.push({ label: ModelLocator.resourceManagerInstance.getString('treatments',"treatment_insulin_label"), accessory: insulinsPicker });
				infoSectionChildren.push({ label: ModelLocator.resourceManagerInstance.getString('treatments',"treatment_insulin_amount_label"), accessory: insulinAmountStepper });
			}
			if (treatment.type == Treatment.TYPE_EXTENDED_COMBO_BOLUS_PARENT || treatment.type == Treatment.TYPE_EXTENDED_COMBO_MEAL_PARENT)
			{
				infoSectionChildren.push({ label: ModelLocator.resourceManagerInstance.getString('treatments',"extended_bolus_split_label") + " 1 (%)", accessory: splitNowStepper });
				infoSectionChildren.push({ label: ModelLocator.resourceManagerInstance.getString('treatments',"extended_bolus_split_label") + " 2 (%)", accessory: splitExtStepper });
				infoSectionChildren.push({ label: ModelLocator.resourceManagerInstance.getString('treatments',"extended_bolus_duration_minutes_label"), accessory: extensionDuration });
			}
			if (treatment.type == Treatment.TYPE_CARBS_CORRECTION || treatment.type == Treatment.TYPE_MEAL_BOLUS || treatment.type == Treatment.TYPE_EXTENDED_COMBO_MEAL_PARENT)
			{
				infoSectionChildren.push({ label: ModelLocator.resourceManagerInstance.getString('treatments',"treatment_carbs_amount_label"), accessory: carbsAmountStepper });
				infoSectionChildren.push({ label: ModelLocator.resourceManagerInstance.getString('treatments',"carbs_type_label"), accessory: carbTypePicker });
			}
			if (treatment.type == Treatment.TYPE_GLUCOSE_CHECK)
			{
				infoSectionChildren.push({ label: ModelLocator.resourceManagerInstance.getString('treatments',"treatment_value_label") + " (" + GlucoseHelper.getGlucoseUnit() + ")", accessory: glucoseAmountStepper });
			}
			if (treatment.type == Treatment.TYPE_EXERCISE)
			{
				infoSectionChildren.push({ label: ModelLocator.resourceManagerInstance.getString('treatments',"exercise_duration_label"), accessory: exerciseDurationStepper });
				infoSectionChildren.push({ label: ModelLocator.resourceManagerInstance.getString('treatments',"exercise_intensity_label"), accessory: exerciseIntensityPicker });
			}
			if (treatment.type == Treatment.TYPE_TEMP_BASAL || treatment.type == Treatment.TYPE_MDI_BASAL)
			{
				if (treatment.type == Treatment.TYPE_MDI_BASAL)
					infoSectionChildren.push({ label: ModelLocator.resourceManagerInstance.getString('treatments',"treatment_insulin_label"), accessory: insulinsPicker });
				
				if (!treatment.isTempBasalEnd)
					infoSectionChildren.push({ label: treatment.type == Treatment.TYPE_TEMP_BASAL && treatment.isBasalRelative ? ModelLocator.resourceManagerInstance.getString('treatments',"treatment_insulin_amount_relative_temp_basal_label") : ModelLocator.resourceManagerInstance.getString('treatments',"treatment_insulin_amount_label"), accessory: insulinAmountStepper });
				
				if (!treatment.isTempBasalEnd && treatment.type != Treatment.TYPE_MDI_BASAL)
					infoSectionChildren.push({ label: ModelLocator.resourceManagerInstance.getString('treatments',"exercise_duration_label"), accessory: tempBasalDurationStepper });
			}
			infoSectionChildren.push({ label: ModelLocator.resourceManagerInstance.getString('treatments',"treatment_note_label"), accessory: noteTextArea });
			infoSectionChildren.push({ label: "", accessory: actionButtonsContainer });
			infoSection.children = infoSectionChildren;
			screenDataContent.push(infoSection);
			
			dataProvider = new HierarchicalCollection(screenDataContent);
			
			itemRendererFactory = function():IGroupedListItemRenderer
			{
				var itemRenderer:DefaultGroupedListItemRenderer = new DefaultGroupedListItemRenderer();
				itemRenderer.labelField = "label";
				itemRenderer.iconSourceField = "accessory";
				itemRenderer.paddingLeft = -5;
				
				return itemRenderer;
			};
			
			(layout as VerticalLayout).hasVariableItemDimensions = true;
			(layout as VerticalLayout).useVirtualLayout = false;
		}
		
		private function onSettingsChanged(e:Event):void
		{
			if (saveTreatment != null)
				saveTreatment.isEnabled = true;
		}
		
		/**
		 * Event Handlers
		 */
		private function onSplitNowChanged(e:Event):void
		{
			if (splitNowStepper != null && splitExtStepper != null)
			{
				splitExtStepper.value = 100 - splitNowStepper.value;
			}
		}
		
		private function onSplitExtChanged(e:Event):void
		{
			if (splitNowStepper != null && splitExtStepper != null)
			{
				splitNowStepper.value = 100 - splitExtStepper.value;
			}
		}
		
		private function onSaveTreatment(e:Event):void
		{
			//Check if selected time range is acceptable
			var firstBGReadingTimeStamp:Number;
			if (ModelLocator.bgReadings != null && ModelLocator.bgReadings.length > 0)
			{
				firstBGReadingTimeStamp = (ModelLocator.bgReadings[0] as BgReading).timestamp;
			}
			else
				return
			
			if(treatmentTime.value.valueOf() < firstBGReadingTimeStamp || treatmentTime.value.valueOf() > new Date().valueOf())
			{
				AlertManager.showSimpleAlert
				(
					ModelLocator.resourceManagerInstance.getString('globaltranslations',"warning_alert_title"),
					ModelLocator.resourceManagerInstance.getString('treatments',"out_of_range_treatment_time_message")
				);
				return
			}
			
			//Update treatment properties that are the same for all treatments
			treatment.timestamp = treatmentTime.value.valueOf();
			if (treatment.type != Treatment.TYPE_TEMP_BASAL && treatment.type != Treatment.TYPE_MDI_BASAL)
			{
				treatment.glucoseEstimated = TreatmentsManager.getEstimatedGlucose(treatmentTime.value.valueOf());
			}
			treatment.note = noteTextArea.text;
			
			var carbDelayTime:Number;
			
			//Update treatment properties specific to each treatment type
			if(treatment.type == Treatment.TYPE_BOLUS || treatment.type == Treatment.TYPE_CORRECTION_BOLUS)
			{
				treatment.insulinAmount = insulinAmountStepper.value;
				treatment.insulinID = insulinsPicker.selectedItem.id;
				treatment.dia = ProfileManager.getInsulin(treatment.insulinID).dia;
				treatment.glucoseEstimated = TreatmentsManager.getEstimatedGlucose(treatment.timestamp);
			}
			else if(treatment.type == Treatment.TYPE_CARBS_CORRECTION)
			{
				treatment.carbs = carbsAmountStepper.value;
				treatment.glucoseEstimated = TreatmentsManager.getEstimatedGlucose(treatment.timestamp);
				
				if (carbTypePicker.selectedIndex == 0)
					carbDelayTime = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CARB_FAST_ABSORTION_TIME));
				else if (carbTypePicker.selectedIndex == 1)
					carbDelayTime = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CARB_MEDIUM_ABSORTION_TIME));
				else if (carbTypePicker.selectedIndex == 2)
					carbDelayTime = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CARB_SLOW_ABSORTION_TIME));
				
				treatment.carbDelayTime = carbDelayTime;
				
			}
			else if(treatment.type == Treatment.TYPE_GLUCOSE_CHECK)
			{
				treatment.glucose = Number(isMgDl ? glucoseAmountStepper.value : Math.round(BgReading.mmolToMgdl(glucoseAmountStepper.value)));
				treatment.glucoseEstimated = treatment.glucose;
			}
			else if(treatment.type == Treatment.TYPE_MEAL_BOLUS)
			{
				treatment.insulinAmount = insulinAmountStepper.value;
				treatment.insulinID = insulinsPicker.selectedItem.id;
				treatment.dia = ProfileManager.getInsulin(treatment.insulinID).dia;
				treatment.carbs = carbsAmountStepper.value;
				treatment.glucoseEstimated = TreatmentsManager.getEstimatedGlucose(treatment.timestamp);
				
				if (carbTypePicker.selectedIndex == 0)
					carbDelayTime = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CARB_FAST_ABSORTION_TIME));
				else if (carbTypePicker.selectedIndex == 1)
					carbDelayTime = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CARB_MEDIUM_ABSORTION_TIME));
				else if (carbTypePicker.selectedIndex == 2)
					carbDelayTime = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CARB_SLOW_ABSORTION_TIME));
				
				treatment.carbDelayTime = carbDelayTime;
			}
			else if (treatment.type == Treatment.TYPE_EXTENDED_COMBO_BOLUS_PARENT || treatment.type == Treatment.TYPE_EXTENDED_COMBO_MEAL_PARENT)
			{
				var internalExtendedBolusOverallInsulinAmount:Number = Math.round(treatment.getTotalInsulin() * 100) / 100;
				var internalExtendedBolusParentInsulinAmount:Number = treatment.insulinAmount;
				var internalExtendedBolusParentSplit:Number = Math.round((internalExtendedBolusParentInsulinAmount * 100) / internalExtendedBolusOverallInsulinAmount);
				var internalExtendedBolusChildrenSplit:Number = 100 - internalExtendedBolusParentSplit;
				var numberOfExtendedBolusChildren:uint = treatment.childTreatments.length;
				var internalExtendedBolusDuration:Number = numberOfExtendedBolusChildren * 5;
				
				if (internalExtendedBolusOverallInsulinAmount != insulinAmountStepper.value 
					||
					internalExtendedBolusParentSplit != splitNowStepper.value
					||
					internalExtendedBolusChildrenSplit != splitExtStepper.value
					||
					internalExtendedBolusDuration != extensionDuration.value)
				{
					//First we delete all children
					for (var k:int = 0; k < numberOfExtendedBolusChildren; k++) 
					{
						var internalExtendedBolusChild:Treatment = TreatmentsManager.getTreatmentByID(treatment.childTreatments[k]);
						if (internalExtendedBolusChild != null)
						{
							//Delete child
							TreatmentsManager.deleteTreatment(internalExtendedBolusChild, false, false, true, false, false);
						}
					}
					
					//Recalculate amounts and splits
					var immediateBolusAmount:Number = Math.round((Math.round(Number(insulinAmountStepper.value) * 100) / 100) * ((Number(splitNowStepper.value)) / 100) * 100) / 100;
					var remainingBolusAmount:Number = (Math.round(Number(insulinAmountStepper.value) * 100) / 100) - immediateBolusAmount;
					var extendedSteps:Number = Math.round(Number(extensionDuration.value) / 5);
					var extendedBolusAmount:Number = Math.round((remainingBolusAmount/extendedSteps) * 100) / 100;
					var latestReading:BgReading = BgReading.lastWithCalculatedValue();
					
					//Extended Bolus Children
					var extendedChildren:Array = [];
					for (var m:int = 0; m < extendedSteps; m++) 
					{
						var extendedTreatmentBolusAmount:Number = m < extendedSteps - 1 ? extendedBolusAmount : remainingBolusAmount;
						var childTimestamp:Number = treatmentTime.value.valueOf() + ((m + 1) * TimeSpan.TIME_5_MINUTES);
						
						var extendedTreatment:Treatment = new Treatment
							(
								Treatment.TYPE_EXTENDED_COMBO_BOLUS_CHILD,
								childTimestamp,
								extendedTreatmentBolusAmount,
								insulinsPicker != null && insulinsPicker.selectedItem != null && insulinsPicker.selectedItem.id != null ? insulinsPicker.selectedItem.id : "",
								0,
								0,
								TreatmentsManager.getEstimatedGlucose(childTimestamp)
							);
						extendedTreatment.needsAdjustment = latestReading != null && latestReading.timestamp >= childTimestamp ? false : true;
						TreatmentsManager.addExternalTreatment(extendedTreatment, false);
						extendedChildren.push(extendedTreatment.ID);
						
						remainingBolusAmount -= extendedTreatmentBolusAmount;
					}
					
					//Update parent
					treatment.childTreatments = extendedChildren;
					treatment.insulinAmount = immediateBolusAmount;
					treatment.needsAdjustment = latestReading != null && latestReading.timestamp >= treatmentTime.value.valueOf() ? false : true;
					if (treatment.timestamp != treatmentTime.value.valueOf())
					{
						treatment.timestamp = treatmentTime.value.valueOf();
						treatment.glucoseEstimated = TreatmentsManager.getEstimatedGlucose(treatmentTime.value.valueOf());
					}
					
					if (insulinsPicker != null && insulinsPicker.selectedItem != null && insulinsPicker.selectedItem.id != null && insulinsPicker.selectedItem.id != treatment.insulinID)
					{
						treatment.insulinID = insulinsPicker.selectedItem.id;
						var newInsulin:Insulin = ProfileManager.getInsulin(treatment.insulinID);
						if (newInsulin != null)
						{
							treatment.dia = newInsulin.dia;
						}
					}
				}
				
				if (treatment.type == Treatment.TYPE_EXTENDED_COMBO_MEAL_PARENT)
				{
					treatment.carbs = carbsAmountStepper.value;
					
					if (carbTypePicker.selectedIndex == 0)
						carbDelayTime = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CARB_FAST_ABSORTION_TIME));
					else if (carbTypePicker.selectedIndex == 1)
						carbDelayTime = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CARB_MEDIUM_ABSORTION_TIME));
					else if (carbTypePicker.selectedIndex == 2)
						carbDelayTime = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CARB_SLOW_ABSORTION_TIME));
					
					treatment.carbDelayTime = carbDelayTime;
				}
			}
			else if(treatment.type == Treatment.TYPE_EXERCISE)
			{
				var exerciseIntensity:String = "";
				if (exerciseIntensityPicker.selectedIndex == 0)
				{
					exerciseIntensity = Treatment.EXERCISE_INTENSITY_HIGH;
				}
				else if (exerciseIntensityPicker.selectedIndex == 1)
				{
					exerciseIntensity = Treatment.EXERCISE_INTENSITY_MODERATE;
				}
				else if (exerciseIntensityPicker.selectedIndex == 2)
				{
					exerciseIntensity = Treatment.EXERCISE_INTENSITY_LOW;
				}
				
				treatment.duration = exerciseDurationStepper.value;
				treatment.exerciseIntensity = exerciseIntensity;
			}
			else if(treatment.type == Treatment.TYPE_TEMP_BASAL || treatment.type == Treatment.TYPE_MDI_BASAL)
			{
				//Basal Duration
				if (!treatment.isTempBasalEnd && treatment.type != Treatment.TYPE_MDI_BASAL)
				{
					treatment.basalDuration = tempBasalDurationStepper.value;
				}
				
				//Basal Amount
				if (!treatment.isTempBasalEnd)
				{
					if (treatment.isBasalAbsolute)
					{
						treatment.basalAbsoluteAmount = insulinAmountStepper.value;
					}
					else if (treatment.isBasalRelative)
					{
						treatment.basalPercentAmount = insulinAmountStepper.value;
					}
				}
				
				//Insulin & DIA
				if (treatment.type == Treatment.TYPE_MDI_BASAL)
				{
					if (insulinsPicker != null && insulinsPicker.selectedItem != null && insulinsPicker.selectedItem.id != null)
					{
						treatment.insulinID = String(insulinsPicker.selectedItem.id);
						
						var updatedInsulin:Insulin = ProfileManager.getInsulin(String(insulinsPicker.selectedItem.id));
						if (updatedInsulin != null)
						{
							treatment.basalDuration = updatedInsulin.dia * 60;
						}
					}
				}
			}
			
			//Update treatment in Spike and DB
			TreatmentsManager.updateTreatment(treatment);
			
			//Notify listeners of the change
			dispatchEventWith(Event.CHANGE);
		}
		
		private function onCancelTreatment(e:Event):void
		{
			dispatchEventWith(Event.CANCEL);
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{	
			if (treatmentTime != null)
			{
				treatmentTime.removeFromParent();
				treatmentTime.removeEventListener(Event.CHANGE, onSettingsChanged);
				treatmentTime.dispose();
				treatmentTime = null;
			}
			
			if (treatmentTimeConatiner != null)
			{
				treatmentTimeConatiner.dispose();
				treatmentTimeConatiner = null;
			}
			
			if (saveTreatment != null)
			{
				actionButtonsContainer.removeChild(saveTreatment);
				saveTreatment.removeEventListener(Event.CHANGE, onSaveTreatment);
				saveTreatment.dispose();
				saveTreatment = null;
			}
			
			if (cancelTreatment != null)
			{
				actionButtonsContainer.removeChild(cancelTreatment);
				cancelTreatment.removeEventListener(Event.CHANGE, onCancelTreatment);
				cancelTreatment.dispose();
				cancelTreatment = null;
			}
			
			if (actionButtonsContainer != null)
			{
				actionButtonsContainer.dispose();
				actionButtonsContainer = null;
			}
			
			if (insulinsPicker != null)
			{
				insulinsPicker.removeEventListener(Event.CHANGE, onSettingsChanged);
				insulinsPicker.dispose();
				insulinsPicker = null;
			}
			
			if (insulinAmountStepper != null)
			{
				insulinAmountStepper.removeEventListener(Event.CHANGE, onSettingsChanged);
				insulinAmountStepper.dispose();
				insulinAmountStepper = null;
			}
			
			if (carbsAmountStepper != null)
			{
				carbsAmountStepper.removeEventListener(Event.CHANGE, onSettingsChanged);
				carbsAmountStepper.dispose();
				carbsAmountStepper = null;
			}
			
			if (glucoseAmountStepper != null)
			{
				glucoseAmountStepper.removeEventListener(Event.CHANGE, onSettingsChanged);
				glucoseAmountStepper.dispose();
				glucoseAmountStepper = null;
			}
			
			if (noteTextArea != null)
			{
				noteTextArea.removeEventListener(Event.CHANGE, onSettingsChanged);
				noteTextArea.dispose();
				noteTextArea = null;
			}
			
			if (carbTypePicker != null)
			{
				carbTypePicker.removeEventListener(Event.CHANGE, onSettingsChanged);
				carbTypePicker.dispose();
				carbTypePicker = null;
			}
			
			if (splitNowStepper != null)
			{
				splitNowStepper.removeEventListener(Event.CHANGE, onSettingsChanged);
				splitNowStepper.removeEventListener(Event.CHANGE, onSplitNowChanged);
				splitNowStepper.dispose();
				splitNowStepper = null;
			}
			
			if (splitExtStepper != null)
			{
				splitExtStepper.removeEventListener(Event.CHANGE, onSettingsChanged);
				splitExtStepper.removeEventListener(Event.CHANGE, onSplitExtChanged);
				splitExtStepper.dispose();
				splitExtStepper = null;
			}
			
			if (extensionDuration != null)
			{
				extensionDuration.removeEventListener(Event.CHANGE, onSettingsChanged);
				extensionDuration.dispose();
				extensionDuration = null;
			}
			
			if (exerciseDurationStepper != null)
			{
				exerciseDurationStepper.removeEventListener(Event.CHANGE, onSettingsChanged);
				exerciseDurationStepper.dispose();
				exerciseDurationStepper = null;
			}
			
			if (exerciseIntensityPicker != null)
			{
				exerciseIntensityPicker.removeEventListener(Event.CHANGE, onSettingsChanged);
				exerciseIntensityPicker.dispose();
				exerciseIntensityPicker = null;
			}
			
			if (tempBasalDurationStepper != null)
			{
				tempBasalDurationStepper.removeEventListener(Event.CHANGE, onSettingsChanged);
				tempBasalDurationStepper.dispose();
				tempBasalDurationStepper = null;
			}
			
			super.dispose();
		}
	}
}