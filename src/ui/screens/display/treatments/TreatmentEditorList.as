package ui.screens.display.treatments
{
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
	
	[ResourceBundle("globaltranslations")]
	[ResourceBundle("treatments")]

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
		
		/* Properties */
		private var treatment:Treatment;
		private var isMgDl:Boolean;

		private var treatmentTimeConatiner:LayoutGroup;
		
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
			width = 300;
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
			if (treatment.type == Treatment.TYPE_BOLUS || treatment.type == Treatment.TYPE_MEAL_BOLUS)
			{
				//Treatment Type
				if (treatment.type == Treatment.TYPE_BOLUS)
					treatmentType = ModelLocator.resourceManagerInstance.getString('treatments',"treatment_name_bolus");
				
				//User's insulins
				var userInsulins:Array = ProfileManager.insulinsList;
				insulinsPicker = LayoutFactory.createPickerList()
				var insulinsList:ArrayCollection = new ArrayCollection();
				var selectedInsulin:int = 0;
				if (userInsulins != null)
				{
					for (var i:int = 0; i < userInsulins.length; i++) 
					{
						var insulin:Insulin = userInsulins[i];
						
						insulinsList.push( {label: insulin.name, id: insulin.ID} );
						
						if (insulin.ID == treatment.insulinID)
							selectedInsulin = i;
					}
				}
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
				insulinAmountStepper = LayoutFactory.createNumericStepper(0.1, 150, treatment.insulinAmount, 0.1);
				insulinAmountStepper.pivotX = -10;
				insulinAmountStepper.addEventListener(Event.CHANGE, onSettingsChanged);
			}
			if (treatment.type == Treatment.TYPE_CARBS_CORRECTION || treatment.type == Treatment.TYPE_MEAL_BOLUS)
			{
				//Treatment Type
				if (treatment.type == Treatment.TYPE_CARBS_CORRECTION)
					treatmentType = ModelLocator.resourceManagerInstance.getString('treatments',"treatment_name_carbs");
				
				//Carbs Amount
				carbsAmountStepper = LayoutFactory.createNumericStepper(1, 1000, treatment.carbs, 0.5);
				carbsAmountStepper.pivotX = -10;
				carbsAmountStepper.addEventListener(Event.CHANGE, onSettingsChanged);
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
			
			//Treatment Time
			var treatmentTimeLayout:VerticalLayout = new VerticalLayout();
			treatmentTimeLayout.verticalAlign = VerticalAlign.MIDDLE;
			treatmentTimeConatiner = new LayoutGroup();
			treatmentTimeConatiner.height = 60;
			treatmentTimeConatiner.layout = treatmentTimeLayout;
			
			treatmentTime = new DateTimeSpinner();
			treatmentTime.editingMode = DateTimeMode.TIME;
			treatmentTime.value = new Date(treatment.timestamp);
			treatmentTime.height = 40;
			treatmentTime.addEventListener(Event.CHANGE, onSettingsChanged);
			treatmentTimeConatiner.addChild(treatmentTime);
			
			/* Treatment Note */
			noteTextArea = new TextArea();
			noteTextArea.width = 140;
			noteTextArea.height = 120;
			if ((treatment.type == Treatment.TYPE_MEAL_BOLUS || treatment.type == Treatment.TYPE_BOLUS || treatment.type == Treatment.TYPE_CORRECTION_BOLUS) && Constants.deviceModel == DeviceInfo.IPHONE_2G_3G_3GS_4_4S_ITOUCH_2_3_4)
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
			if (treatment.type == Treatment.TYPE_BOLUS || treatment.type == Treatment.TYPE_MEAL_BOLUS)
			{
				infoSectionChildren.push({ label: ModelLocator.resourceManagerInstance.getString('treatments',"treatment_insulin_label"), accessory: insulinsPicker });
				infoSectionChildren.push({ label: ModelLocator.resourceManagerInstance.getString('treatments',"treatment_insulin_amount_label"), accessory: insulinAmountStepper });
			}
			if (treatment.type == Treatment.TYPE_CARBS_CORRECTION || treatment.type == Treatment.TYPE_MEAL_BOLUS)
			{
				infoSectionChildren.push({ label: ModelLocator.resourceManagerInstance.getString('treatments',"treatment_carbs_amount_label"), accessory: carbsAmountStepper });
			}
			if (treatment.type == Treatment.TYPE_GLUCOSE_CHECK)
			{
				infoSectionChildren.push({ label: ModelLocator.resourceManagerInstance.getString('treatments',"treatment_value_label") + " (" + GlucoseHelper.getGlucoseUnit() + ")", accessory: glucoseAmountStepper });
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
			saveTreatment.isEnabled = true;
		}
		
		/**
		 * Event Handlers
		 */
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
			treatment.note = noteTextArea.text;
			
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
			
			super.dispose();
		}
	}
}