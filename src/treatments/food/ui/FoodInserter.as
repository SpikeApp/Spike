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
	
	import starling.events.Event;
	
	import treatments.food.Food;
	
	import ui.screens.display.LayoutFactory;
	
	import utils.UniqueId;
	
	public class FoodInserter extends LayoutGroup
	{
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
		
		public function FoodInserter(width:Number)
		{
			super();
			
			this.width = width;
			
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
			title = LayoutFactory.createLabel("New Food", HorizontalAlign.CENTER, VerticalAlign.TOP, 18, true);
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
			nameInputText.addEventListener(Event.CHANGE, onValuesChanged);
			nameContainer = new NutritionFactsSectionWithAction(width);
			nameContainer.title.text = "Name";
			nameContainer.setComponent(nameInputText);
			nameRowContainer.addChild(nameContainer);
			
			//Link Row
			brandRowContainer = LayoutFactory.createLayoutGroup("horizontal");
			brandRowContainer.width = width;
			addChild(brandRowContainer);
			
			brandInputText = LayoutFactory.createTextInput(false, false, width, HorizontalAlign.CENTER, false, false, false, true, true);
			brandInputText.height = 30;
			brandInputText.addEventListener(Event.CHANGE, onValuesChanged);
			brandContainer = new NutritionFactsSectionWithAction(width);
			brandContainer.title.text = "Brand";
			brandContainer.setComponent(brandInputText);
			brandRowContainer.addChild(brandContainer);
			
			//Serving & Link Unit
			linkRowContainer = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.LEFT, VerticalAlign.MIDDLE, 10);
			linkRowContainer.width = width;
			addChild(linkRowContainer);
			
			servingUnitInputText = LayoutFactory.createTextInput(false, false, (width - 10) / 2, HorizontalAlign.CENTER);
			servingUnitInputText.paddingLeft = servingUnitInputText.paddingRight = 0;
			servingUnitInputText.height = 30;
			servingUnitInputText.addEventListener(Event.CHANGE, onValuesChanged);
			servingUnitContainer = new NutritionFactsSectionWithAction((width - 10) / 2);
			servingUnitContainer.title.text = "Serving Unit";
			servingUnitContainer.setComponent(servingUnitInputText);
			linkRowContainer.addChild(servingUnitContainer);
			
			linkInputText = LayoutFactory.createTextInput(false, false, (width - 10) / 2, HorizontalAlign.CENTER);
			linkInputText.paddingLeft = linkInputText.paddingRight = 0;
			linkInputText.height = 30;
			linkInputText.addEventListener(Event.CHANGE, onValuesChanged);
			linkContainer = new NutritionFactsSectionWithAction((width - 10) / 2);
			linkContainer.title.text = "Link";
			linkContainer.setComponent(linkInputText);
			linkRowContainer.addChild(linkContainer);
			
			//First Row
			firstRowContainer = LayoutFactory.createLayoutGroup("horizontal");
			firstRowContainer.width = width;
			addChild(firstRowContainer);
			
			servingSizeInputText = LayoutFactory.createTextInput(false, false, 60, HorizontalAlign.CENTER, true);
			servingSizeInputText.height = 30;
			servingSizeInputText.addEventListener(Event.CHANGE, onValuesChanged);
			servingSizeContainer = new NutritionFactsSectionWithAction(width / 3);
			servingSizeContainer.title.text = "Serving Size";
			servingSizeContainer.setComponent(servingSizeInputText);
			firstRowContainer.addChild(servingSizeContainer);
			
			carbsInputText = LayoutFactory.createTextInput(false, false, 60, HorizontalAlign.CENTER, true);
			carbsInputText.height = 30;
			carbsInputText.addEventListener(Event.CHANGE, onValuesChanged);
			carbsContainer = new NutritionFactsSectionWithAction(width / 3);
			carbsContainer.title.text = "Carbs";
			carbsContainer.setComponent(carbsInputText);
			firstRowContainer.addChild(carbsContainer);
			
			fiberInputText = LayoutFactory.createTextInput(false, false, 60, HorizontalAlign.CENTER, true);
			fiberInputText.height = 30;
			fiberInputText.addEventListener(Event.CHANGE, onValuesChanged);
			fiberContainer = new NutritionFactsSectionWithAction(width / 3);
			fiberContainer.title.text = "Fiber";
			fiberContainer.setComponent(fiberInputText);
			firstRowContainer.addChild(fiberContainer);
			
			//Second Row
			secondRowContainer = LayoutFactory.createLayoutGroup("horizontal");
			secondRowContainer.width = width;
			addChild(secondRowContainer);
			
			proteinsInputText = LayoutFactory.createTextInput(false, false, 60, HorizontalAlign.CENTER, true);
			proteinsInputText.height = 30;
			proteinsInputText.addEventListener(Event.CHANGE, onValuesChanged);
			proteinsContainer = new NutritionFactsSectionWithAction(width / 3);
			proteinsContainer.title.text = "Proteins";
			proteinsContainer.setComponent(proteinsInputText);
			secondRowContainer.addChild(proteinsContainer);
			
			fatsInputText = LayoutFactory.createTextInput(false, false, 60, HorizontalAlign.CENTER, true);
			fatsInputText.height = 30;
			fatsInputText.addEventListener(Event.CHANGE, onValuesChanged);
			fatsContainer = new NutritionFactsSectionWithAction(width / 3);
			fatsContainer.title.text = "Fats";
			fatsContainer.setComponent(fatsInputText);
			secondRowContainer.addChild(fatsContainer);
			
			caloriesInputText = LayoutFactory.createTextInput(false, false, 60, HorizontalAlign.CENTER, true);
			caloriesInputText.height = 30;
			caloriesInputText.addEventListener(Event.CHANGE, onValuesChanged);
			caloriesContainer = new NutritionFactsSectionWithAction(width / 3);
			caloriesContainer.title.text = "Calories";
			caloriesContainer.setComponent(caloriesInputText);
			secondRowContainer.addChild(caloriesContainer);
			
			//Actions Row
			actionsRowContainer = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.CENTER, VerticalAlign.MIDDLE, 10);
			(actionsRowContainer.layout as HorizontalLayout).paddingTop = 10;
			(actionsRowContainer.layout as HorizontalLayout).paddingBottom = -10;
			actionsRowContainer.width = width;
			addChild(actionsRowContainer);
			
			cancelButton = LayoutFactory.createButton("CANCEL");
			cancelButton.addEventListener(Event.TRIGGERED, onCancel);
			actionsRowContainer.addChild(cancelButton);
			
			saveButton = LayoutFactory.createButton("SAVE");
			saveButton.isEnabled = false;
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