package treatments.food.ui
{
	import database.Database;
	
	import feathers.controls.Button;
	import feathers.controls.Label;
	import feathers.controls.LayoutGroup;
	import feathers.controls.TextInput;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.HorizontalLayout;
	import feathers.layout.VerticalAlign;
	import feathers.layout.VerticalLayout;
	
	import model.ModelLocator;
	
	import starling.events.Event;
	
	import treatments.food.Food;
	
	import ui.screens.display.LayoutFactory;
	
	import utils.UniqueId;
	
	[ResourceBundle("foodmanager")]
	[ResourceBundle("globaltranslations")]
	
	public class FoodInserter extends LayoutGroup
	{
		private const ADD_MODE:String = "addMode";
		private const EDIT_MODE:String = "editMode";
		
		private var firstRowContainer:LayoutGroup;
		private var secondRowContainer:LayoutGroup;
		private var servingSizeContainer:NutritionFactsSectionWithAction;
		private var carbsContainer:NutritionFactsSectionWithAction;
		private var fiberContainer:NutritionFactsSectionWithAction;
		private var proteinsContainer:NutritionFactsSectionWithAction;
		private var fatsContainer:NutritionFactsSectionWithAction;
		private var caloriesContainer:NutritionFactsSectionWithAction;
		private var title:Label;
		private var nameRowContainer:LayoutGroup;
		private var nameInputText:TextInput;
		private var nameContainer:NutritionFactsSectionWithAction;
		private var brandRowContainer:LayoutGroup;
		private var brandInputText:TextInput;
		private var brandContainer:NutritionFactsSectionWithAction;
		private var linkRowContainer:LayoutGroup;
		private var servingUnitInputText:TextInput;
		private var servingUnitContainer:NutritionFactsSectionWithAction;
		private var linkInputText:TextInput;
		private var linkContainer:NutritionFactsSectionWithAction;
		private var servingSizeInputText:TextInput;
		private var carbsInputText:TextInput;
		private var fiberInputText:TextInput;
		private var proteinsInputText:TextInput;
		private var fatsInputText:TextInput;
		private var caloriesInputText:TextInput;
		private var actionsRowContainer:LayoutGroup;
		private var cancelButton:Button;
		private var saveButton:Button;
		
		private var activeFood:Food;
		private var mode:String;
		
		public function FoodInserter(width:Number, food:Food = null)
		{
			super();
			
			this.width = width;
			
			if (food == null)
				mode = ADD_MODE
			else
			{
				activeFood = food;
				mode = EDIT_MODE;
			}
			
			createProperties();
			createContent();
		}
		
		private function createProperties():void
		{
			var verticalLayout:VerticalLayout = new VerticalLayout();
			verticalLayout.gap = 10;
			this.layout = verticalLayout;
		}
		
		private function createContent():void
		{
			//Title
			title = LayoutFactory.createLabel(mode == ADD_MODE ? ModelLocator.resourceManagerInstance.getString('foodmanager','new_food_label') : ModelLocator.resourceManagerInstance.getString('foodmanager','edit_food_label'), HorizontalAlign.CENTER, VerticalAlign.TOP, 18, true);
			title.paddingTop = 0;
			title.paddingBottom = 5;
			title.width = width;
			addChild(title);
			
			//Name
			nameRowContainer = LayoutFactory.createLayoutGroup("horizontal");
			nameRowContainer.width = width;
			addChild(nameRowContainer);
			
			nameInputText = LayoutFactory.createTextInput(false, false, width, HorizontalAlign.CENTER, false, false, false, true, true);
			nameInputText.height = 30;
			if (mode == EDIT_MODE && activeFood != null) nameInputText.text = activeFood.name;
			nameInputText.addEventListener(Event.CHANGE, onValuesChanged);
			nameContainer = new NutritionFactsSectionWithAction(width);
			nameContainer.title.text = ModelLocator.resourceManagerInstance.getString('foodmanager','name_label');
			nameContainer.setComponent(nameInputText);
			nameRowContainer.addChild(nameContainer);
			
			//Link Row
			brandRowContainer = LayoutFactory.createLayoutGroup("horizontal");
			brandRowContainer.width = width;
			addChild(brandRowContainer);
			
			brandInputText = LayoutFactory.createTextInput(false, false, width, HorizontalAlign.CENTER, false, false, false, true, true);
			brandInputText.height = 30;
			if (mode == EDIT_MODE && activeFood != null) brandInputText.text = activeFood.brand;
			brandInputText.addEventListener(Event.CHANGE, onValuesChanged);
			brandContainer = new NutritionFactsSectionWithAction(width);
			brandContainer.title.text = ModelLocator.resourceManagerInstance.getString('foodmanager','brand_label');
			brandContainer.setComponent(brandInputText);
			brandRowContainer.addChild(brandContainer);
			
			//Serving & Link Unit
			linkRowContainer = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.LEFT, VerticalAlign.MIDDLE, 10);
			linkRowContainer.width = width;
			addChild(linkRowContainer);
			
			servingUnitInputText = LayoutFactory.createTextInput(false, false, (width - 10) / 2, HorizontalAlign.CENTER);
			servingUnitInputText.paddingLeft = servingUnitInputText.paddingRight = 0;
			servingUnitInputText.height = 30;
			if (mode == EDIT_MODE && activeFood != null) servingUnitInputText.text = activeFood.servingUnit;
			servingUnitInputText.addEventListener(Event.CHANGE, onValuesChanged);
			servingUnitContainer = new NutritionFactsSectionWithAction((width - 10) / 2);
			servingUnitContainer.title.text = ModelLocator.resourceManagerInstance.getString('foodmanager','serving_unit_label');
			servingUnitContainer.setComponent(servingUnitInputText);
			linkRowContainer.addChild(servingUnitContainer);
			
			linkInputText = LayoutFactory.createTextInput(false, false, (width - 10) / 2, HorizontalAlign.CENTER);
			linkInputText.paddingLeft = linkInputText.paddingRight = 0;
			linkInputText.height = 30;
			if (mode == EDIT_MODE && activeFood != null) linkInputText.text = activeFood.link;
			linkInputText.addEventListener(Event.CHANGE, onValuesChanged);
			linkContainer = new NutritionFactsSectionWithAction((width - 10) / 2);
			linkContainer.title.text = ModelLocator.resourceManagerInstance.getString('foodmanager','link_label');
			linkContainer.setComponent(linkInputText);
			linkRowContainer.addChild(linkContainer);
			
			//First Row
			firstRowContainer = LayoutFactory.createLayoutGroup("horizontal");
			firstRowContainer.width = width;
			addChild(firstRowContainer);
			
			servingSizeInputText = LayoutFactory.createTextInput(false, false, 60, HorizontalAlign.CENTER, true);
			servingSizeInputText.height = 30;
			if (mode == EDIT_MODE && activeFood != null) servingSizeInputText.text = String(activeFood.servingSize);
			servingSizeInputText.addEventListener(Event.CHANGE, onValuesChanged);
			servingSizeContainer = new NutritionFactsSectionWithAction(width / 3);
			servingSizeContainer.title.text = ModelLocator.resourceManagerInstance.getString('foodmanager','serving_size_label');
			servingSizeContainer.setComponent(servingSizeInputText);
			firstRowContainer.addChild(servingSizeContainer);
			
			carbsInputText = LayoutFactory.createTextInput(false, false, 60, HorizontalAlign.CENTER, true);
			carbsInputText.height = 30;
			if (mode == EDIT_MODE && activeFood != null) carbsInputText.text = String(activeFood.carbs);
			carbsInputText.addEventListener(Event.CHANGE, onValuesChanged);
			carbsContainer = new NutritionFactsSectionWithAction(width / 3);
			carbsContainer.title.text = ModelLocator.resourceManagerInstance.getString('foodmanager','carbs_label');
			carbsContainer.setComponent(carbsInputText);
			firstRowContainer.addChild(carbsContainer);
			
			fiberInputText = LayoutFactory.createTextInput(false, false, 60, HorizontalAlign.CENTER, true);
			fiberInputText.height = 30;
			if (mode == EDIT_MODE && activeFood != null) fiberInputText.text = String(activeFood.fiber);
			fiberInputText.addEventListener(Event.CHANGE, onValuesChanged);
			fiberContainer = new NutritionFactsSectionWithAction(width / 3);
			fiberContainer.title.text = ModelLocator.resourceManagerInstance.getString('foodmanager','fiber_label');
			fiberContainer.setComponent(fiberInputText);
			firstRowContainer.addChild(fiberContainer);
			
			//Second Row
			secondRowContainer = LayoutFactory.createLayoutGroup("horizontal");
			secondRowContainer.width = width;
			addChild(secondRowContainer);
			
			proteinsInputText = LayoutFactory.createTextInput(false, false, 60, HorizontalAlign.CENTER, true);
			proteinsInputText.height = 30;
			if (mode == EDIT_MODE && activeFood != null) proteinsInputText.text = String(activeFood.proteins);
			proteinsInputText.addEventListener(Event.CHANGE, onValuesChanged);
			proteinsContainer = new NutritionFactsSectionWithAction(width / 3);
			proteinsContainer.title.text = ModelLocator.resourceManagerInstance.getString('foodmanager','proteins_label');
			proteinsContainer.setComponent(proteinsInputText);
			secondRowContainer.addChild(proteinsContainer);
			
			fatsInputText = LayoutFactory.createTextInput(false, false, 60, HorizontalAlign.CENTER, true);
			fatsInputText.height = 30;
			if (mode == EDIT_MODE && activeFood != null) fatsInputText.text = String(activeFood.fats);
			fatsInputText.addEventListener(Event.CHANGE, onValuesChanged);
			fatsContainer = new NutritionFactsSectionWithAction(width / 3);
			fatsContainer.title.text = ModelLocator.resourceManagerInstance.getString('foodmanager','fats_label');
			fatsContainer.setComponent(fatsInputText);
			secondRowContainer.addChild(fatsContainer);
			
			caloriesInputText = LayoutFactory.createTextInput(false, false, 60, HorizontalAlign.CENTER, true);
			caloriesInputText.height = 30;
			if (mode == EDIT_MODE && activeFood != null) caloriesInputText.text = String(activeFood.kcal);
			caloriesInputText.addEventListener(Event.CHANGE, onValuesChanged);
			caloriesContainer = new NutritionFactsSectionWithAction(width / 3);
			caloriesContainer.title.text = ModelLocator.resourceManagerInstance.getString('foodmanager','calories_label');
			caloriesContainer.setComponent(caloriesInputText);
			secondRowContainer.addChild(caloriesContainer);
			
			//Actions Row
			actionsRowContainer = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.CENTER, VerticalAlign.MIDDLE, 10);
			(actionsRowContainer.layout as HorizontalLayout).paddingTop = 10;
			(actionsRowContainer.layout as HorizontalLayout).paddingBottom = -10;
			actionsRowContainer.width = width;
			addChild(actionsRowContainer);
			
			cancelButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('globaltranslations','cancel_button_label').toUpperCase());
			cancelButton.addEventListener(Event.TRIGGERED, onCancel);
			actionsRowContainer.addChild(cancelButton);
			
			saveButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('globaltranslations','save_button_label').toUpperCase());
			saveButton.isEnabled = mode == ADD_MODE ? false : true;
			saveButton.addEventListener(Event.TRIGGERED, onSave);
			actionsRowContainer.addChild(saveButton);
		}
		
		/**
		 * Event Listeners
		 */
		private function onValuesChanged(e:Event):void
		{
			
			
			if (nameInputText.text != "" && servingSizeInputText.text != "" && servingUnitInputText.text != "" && carbsInputText.text != "")
				saveButton.isEnabled = true;
			else
				saveButton.isEnabled = false;
		}
		
		private function onSave(e:Event):void
		{
			if (mode == ADD_MODE)
			{
				//Create Food
				var food:Food = new Food
				(
					UniqueId.createEventId(),
					nameInputText.text,
					proteinsInputText.text != "" ? Number(proteinsInputText.text) : Number.NaN,
					carbsInputText.text != "" ? Number(carbsInputText.text) : Number.NaN,
					fatsInputText.text != "" ? Number(fatsInputText.text) : Number.NaN,
					caloriesInputText.text != "" ? Number(caloriesInputText.text) : Number.NaN,
					servingSizeInputText.text != "" ? Number(servingSizeInputText.text) : Number.NaN,
					servingUnitInputText.text,
					new Date().valueOf(),
					fiberInputText.text != "" ? Number(fiberInputText.text) : Number.NaN,
					brandInputText.text,
					linkInputText.text,
					"User",
					""
				);
			
				//Save To Database
				Database.insertFoodSynchronous(food);
			}
			else if (activeFood != null)
			{
				activeFood.name = nameInputText.text;
				activeFood.proteins = proteinsInputText.text != "" ? Number(proteinsInputText.text) : Number.NaN;
				activeFood.carbs = carbsInputText.text != "" ? Number(carbsInputText.text) : Number.NaN;
				activeFood.fats = fatsInputText.text != "" ? Number(fatsInputText.text) : Number.NaN;
				activeFood.kcal = caloriesInputText.text != "" ? Number(caloriesInputText.text) : Number.NaN;
				activeFood.servingSize = servingSizeInputText.text != "" ? Number(servingSizeInputText.text) : Number.NaN;
				activeFood.servingUnit = servingUnitInputText.text;
				activeFood.timestamp = new Date().valueOf();
				activeFood.fiber = fiberInputText.text != "" ? Number(fiberInputText.text) : Number.NaN;
				activeFood.brand = brandInputText.text;
				activeFood.link = linkInputText.text;
				activeFood.source = "User";
				activeFood.barcode = "";
				
				Database.updateFoodSynchronous(activeFood);
			}
			
			//Finish
			this.dispatchEventWith(Event.COMPLETE);
		}
		
		private function onCancel(e:Event):void
		{
			this.dispatchEventWith(Event.COMPLETE);
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			if (title != null)
			{
				title.removeFromParent();
				title = null;
			}
			
			if (nameInputText != null)
			{
				nameInputText.addEventListener(Event.CHANGE, onValuesChanged);
				nameInputText.removeFromParent();
				nameInputText = null;
			}
			
			if (brandInputText != null)
			{
				brandInputText.addEventListener(Event.CHANGE, onValuesChanged);
				brandInputText.removeFromParent();
				brandInputText = null;
			}
			
			if (servingUnitInputText != null)
			{
				servingUnitInputText.addEventListener(Event.CHANGE, onValuesChanged);
				servingUnitInputText.removeFromParent();
				servingUnitInputText = null;
			}
			
			if (linkInputText != null)
			{
				linkInputText.addEventListener(Event.CHANGE, onValuesChanged);
				linkInputText.removeFromParent();
				linkInputText = null;
			}
			
			if (servingSizeInputText != null)
			{
				servingSizeInputText.addEventListener(Event.CHANGE, onValuesChanged);
				servingSizeInputText.removeFromParent();
				servingSizeInputText = null;
			}
			
			if (carbsInputText != null)
			{
				carbsInputText.addEventListener(Event.CHANGE, onValuesChanged);
				carbsInputText.removeFromParent();
				carbsInputText = null;
			}
			
			if (fiberInputText != null)
			{
				fiberInputText.addEventListener(Event.CHANGE, onValuesChanged);
				fiberInputText.removeFromParent();
				fiberInputText = null;
			}
			
			if (proteinsInputText != null)
			{
				proteinsInputText.addEventListener(Event.CHANGE, onValuesChanged);
				proteinsInputText.removeFromParent();
				proteinsInputText = null;
			}
			
			if (fatsInputText != null)
			{
				fatsInputText.addEventListener(Event.CHANGE, onValuesChanged);
				fatsInputText.removeFromParent();
				fatsInputText = null;
			}
			
			if (caloriesInputText != null)
			{
				caloriesInputText.addEventListener(Event.CHANGE, onValuesChanged);
				caloriesInputText.removeFromParent();
				caloriesInputText = null;
			}
			
			if (cancelButton != null)
			{
				cancelButton.removeEventListener(Event.TRIGGERED, onCancel);
				cancelButton.removeFromParent();
				cancelButton = null;
			}
			
			if (saveButton != null)
			{
				saveButton.removeEventListener(Event.TRIGGERED, onSave);
				saveButton.removeFromParent();
				saveButton = null;
			}
			
			if (servingSizeContainer != null)
			{
				servingSizeContainer.removeFromParent();
				servingSizeContainer = null;
			}
			
			if (carbsContainer != null)
			{
				carbsContainer.removeFromParent();
				carbsContainer = null;
			}
			
			if (fiberContainer != null)
			{
				fiberContainer.removeFromParent();
				fiberContainer = null;
			}
			
			if (proteinsContainer != null)
			{
				proteinsContainer.removeFromParent();
				proteinsContainer = null;
			}
			
			if (fatsContainer != null)
			{
				fatsContainer.removeFromParent();
				fatsContainer = null;
			}
			
			if (caloriesContainer != null)
			{
				caloriesContainer.removeFromParent();
				caloriesContainer = null;
			}
			
			if (nameContainer != null)
			{
				nameContainer.removeFromParent();
				nameContainer = null;
			}
			
			if (brandContainer != null)
			{
				brandContainer.removeFromParent();
				brandContainer = null;
			}
			
			if (servingUnitContainer != null)
			{
				servingUnitContainer.removeFromParent();
				servingUnitContainer = null;
			}
			
			if (linkContainer != null)
			{
				linkContainer.removeFromParent();
				linkContainer = null;
			}
			
			if (firstRowContainer != null)
			{
				firstRowContainer.removeFromParent();
				firstRowContainer = null;
			}
			
			if (secondRowContainer != null)
			{
				secondRowContainer.removeFromParent();
				secondRowContainer = null;
			}
			
			if (nameRowContainer != null)
			{
				nameRowContainer.removeFromParent();
				nameRowContainer = null;
			}
			
			if (brandRowContainer != null)
			{
				brandRowContainer.removeFromParent();
				brandRowContainer = null;
			}
			
			if (linkRowContainer != null)
			{
				linkRowContainer.removeFromParent();
				linkRowContainer = null;
			}
			
			if (actionsRowContainer != null)
			{
				actionsRowContainer.removeFromParent();
				actionsRowContainer = null;
			}
			
			super.dispose();
		}
	}
}