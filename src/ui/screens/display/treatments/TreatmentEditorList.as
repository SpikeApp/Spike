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
	
	import ui.screens.display.LayoutFactory;
	
	import utils.GlucoseHelper;
	
	[ResourceBundle("profilesettingsscreen")]
	[ResourceBundle("globaltranslations")]

	public class TreatmentEditorList extends GroupedList 
	{	
		/* Display Objects */
		private var treatmentTime:DateTimeSpinner;
		private var saveTreatment:Button;
		private var cancelTreatment:Button;
		private var actionButtonsContainer:LayoutGroup;
		private var treatment:Treatment;
		private var insulinsPicker:PickerList;
		private var insulinAmountStepper:NumericStepper;
		private var carbsAmountStepper:NumericStepper;
		private var glucoseAmountStepper:NumericStepper;
		private var noteTextArea:TextArea;
		
		/* Properties */
		private var headerLabelValue:String;
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
					treatmentType = "Bolus";
				
				//User+s insulins
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
				insulinAmountStepper.addEventListener(Event.CHANGE, onSettingsChanged);
			}
			if (treatment.type == Treatment.TYPE_CARBS_CORRECTION || treatment.type == Treatment.TYPE_MEAL_BOLUS)
			{
				if (treatment.type == Treatment.TYPE_CARBS_CORRECTION)
					treatmentType = "Carbs";
				
				//Carbs Amount
				carbsAmountStepper = LayoutFactory.createNumericStepper(1, 1000, treatment.carbs, 0.5);
				carbsAmountStepper.addEventListener(Event.CHANGE, onSettingsChanged);
			}
			if (treatment.type == Treatment.TYPE_GLUCOSE_CHECK)
			{
				treatmentType = "BG Check";
				
				//Glucose Amount
				glucoseAmountStepper = LayoutFactory.createNumericStepper
				(
					isMgDl ? 30 : Math.round(((BgReading.mgdlToMmol((30))) * 10)) / 10,
					isMgDl ? 400 : Math.round(((BgReading.mgdlToMmol((400))) * 10)) / 10,
					isMgDl ? treatment.glucose : Math.round(((BgReading.mgdlToMmol((treatment.glucose))) * 10)) / 10,
					isMgDl ? 1 : 0.1
				);
				glucoseAmountStepper.addEventListener(Event.CHANGE, onSettingsChanged);
			}
			if (treatment.type == Treatment.TYPE_MEAL_BOLUS)
				treatmentType = "Meal";
			if (treatment.type == Treatment.TYPE_NOTE)
				treatmentType = "Note";
			
			treatmentTime = new DateTimeSpinner();
			treatmentTime.editingMode = DateTimeMode.TIME;
			treatmentTime.value = new Date(treatment.timestamp);
			treatmentTime.height = 40;
			treatmentTime.paddingTop = 5;
			treatmentTime.paddingBottom = 5;
			treatmentTime.pivotX = -1;
			treatmentTime.addEventListener(Event.CHANGE, onSettingsChanged);
			
			/* Treatment Note */
			noteTextArea = new TextArea();
			noteTextArea.width = 140;
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
			saveTreatment.addEventListener(Event.TRIGGERED, onSave);
			actionButtonsContainer.addChild(saveTreatment);
			
			/* Data */
			var screenDataContent:Array = [];
			
			var infoSection:Object = {};
			infoSection.header = { label: treatmentType };
			
			var infoSectionChildren:Array = [];
			
			infoSectionChildren.push({ label: "Time", accessory: treatmentTime });
			if (treatment.type == Treatment.TYPE_BOLUS || treatment.type == Treatment.TYPE_MEAL_BOLUS)
			{
				infoSectionChildren.push({ label: "Insulin", accessory: insulinsPicker });
				infoSectionChildren.push({ label: "Amount (U)", accessory: insulinAmountStepper });
			}
			if (treatment.type == Treatment.TYPE_CARBS_CORRECTION || treatment.type == Treatment.TYPE_MEAL_BOLUS)
			{
				infoSectionChildren.push({ label: "Amount (g)", accessory: carbsAmountStepper });
			}
			if (treatment.type == Treatment.TYPE_GLUCOSE_CHECK)
			{
				infoSectionChildren.push({ label: "Value (" + GlucoseHelper.getGlucoseUnit() + ")", accessory: glucoseAmountStepper });
			}
			infoSectionChildren.push({ label: "Note", accessory: noteTextArea });
			
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
		private function onSave(e:Event):void
		{
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
			
			
			super.dispose();
		}
	}
}