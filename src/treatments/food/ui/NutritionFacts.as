package treatments.food.ui
{
	import feathers.controls.LayoutGroup;
	import feathers.controls.PickerList;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.HorizontalLayout;
	import feathers.layout.VerticalAlign;
	import feathers.layout.VerticalLayout;
	
	import starling.display.DisplayObject;
	
	import ui.screens.display.LayoutFactory;
	
	public class NutritionFacts extends LayoutGroup
	{
		private var firstRowContainer:LayoutGroup;
		private var secondRowContainer:LayoutGroup;
		private var thirdRowContainer:LayoutGroup;
		private var servingSizeContainer:NutritionFactsSection;
		private var carbsContainer:NutritionFactsSection;
		private var fiberContainer:NutritionFactsSection;
		private var proteinsContainer:NutritionFactsSection;
		private var fatsContainer:NutritionFactsSection;
		private var caloriesContainer:NutritionFactsSection;
		private var linkContainer:NutritionFactsSectionWithAction;
		private var subtractFiberContainer:NutritionFactsSectionWithAction;
		private var amountContainer:NutritionFactsSectionWithAction;
		private var servingSizePickerListContainer:NutritionFactsSectionWithAction;
		
		public function NutritionFacts(width:Number)
		{
			super();
			
			this.width = width;
			
			var verticalLayout:VerticalLayout = new VerticalLayout();
			verticalLayout.gap = 10;
			this.layout = verticalLayout;
			
			createContent();
		}
		
		private function createContent():void
		{
			//First Row
			firstRowContainer = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.LEFT, VerticalAlign.TOP);
			firstRowContainer.width = width;
			addChild(firstRowContainer);
			
			servingSizeContainer = new NutritionFactsSection(width / 3);
			servingSizePickerListContainer = new NutritionFactsSectionWithAction(width / 3);
			firstRowContainer.addChild(servingSizeContainer);
			
			carbsContainer = new NutritionFactsSection(width / 3);
			firstRowContainer.addChild(carbsContainer);
			
			fiberContainer = new NutritionFactsSection(width / 3);
			firstRowContainer.addChild(fiberContainer);
			
			//Second Row
			secondRowContainer = LayoutFactory.createLayoutGroup("horizontal");
			secondRowContainer.width = width;
			addChild(secondRowContainer);
			
			proteinsContainer = new NutritionFactsSection(width / 3);
			secondRowContainer.addChild(proteinsContainer);
			
			fatsContainer = new NutritionFactsSection(width / 3);
			secondRowContainer.addChild(fatsContainer);
			
			caloriesContainer = new NutritionFactsSection(width / 3);
			secondRowContainer.addChild(caloriesContainer);
			
			//Third Row
			thirdRowContainer = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.RIGHT, VerticalAlign.TOP);
			thirdRowContainer.width = width;
			addChild(thirdRowContainer);
			
			linkContainer = new NutritionFactsSectionWithAction(width / 3);
			thirdRowContainer.addChild(linkContainer);
			
			subtractFiberContainer = new NutritionFactsSectionWithAction(width / 3);
			thirdRowContainer.addChild(subtractFiberContainer);
			
			amountContainer = new NutritionFactsSectionWithAction(width / 3);
			thirdRowContainer.addChild(amountContainer);
		}
		
		private function updateLayout(newPadding:Number):void
		{
			if (!isNaN(newPadding))
			{
				(secondRowContainer.layout as HorizontalLayout).paddingBottom = newPadding;
				carbsContainer.value.paddingTop = newPadding;
				fiberContainer.value.paddingTop = newPadding;
				proteinsContainer.value.paddingTop = newPadding;
				fatsContainer.value.paddingTop = newPadding;
				caloriesContainer.value.paddingTop = newPadding;
				linkContainer.title.paddingBottom = newPadding;
				subtractFiberContainer.title.paddingBottom = newPadding;
				amountContainer.title.paddingBottom = newPadding;
			}
			else
			{
				(secondRowContainer.layout as HorizontalLayout).paddingBottom = 0;
				carbsContainer.value.paddingTop = 0;
				fiberContainer.value.paddingTop = 0;
				proteinsContainer.value.paddingTop = 0;
				fatsContainer.value.paddingTop = 0;
				caloriesContainer.value.paddingTop = 0;
				linkContainer.title.paddingBottom = 0;
				subtractFiberContainer.title.paddingBottom = 0;
				amountContainer.title.paddingBottom = 0;
			}
		}
		
		/**
		 * Public Methods
		 */
		public function setServingsTitle(title:String):void
		{
			servingSizeContainer.title.text = title;
		}
		
		public function setServingsValue(value:String):void
		{
			servingSizeContainer.value.text = value;
			firstRowContainer.removeChild(servingSizePickerListContainer);
			firstRowContainer.addChild(servingSizeContainer);
			
			updateLayout(Number.NaN);
		}
		
		public function setServingsListTitle(title:String):void
		{
			servingSizePickerListContainer.title.text = title;
		}
		
		public function setServingsListComponent(component:PickerList):void
		{
			component.maxWidth = width / 3;
			servingSizePickerListContainer.setComponent(component);
			firstRowContainer.removeChild(servingSizeContainer);
			firstRowContainer.addChild(servingSizePickerListContainer);
			
			updateLayout(10);
		}
		
		public function setCarbsTitle(title:String):void
		{
			carbsContainer.title.text = title;
		}
		
		public function setCarbsValue(value:String):void
		{
			carbsContainer.value.text = value;
		}
		
		public function setFiberTitle(title:String):void
		{
			fiberContainer.title.text = title;
		}
		
		public function setFiberValue(value:String):void
		{
			fiberContainer.value.text = value;
		}
		
		public function setProteinsTitle(title:String):void
		{
			proteinsContainer.title.text = title;
		}
		
		public function setProteinsValue(value:String):void
		{
			proteinsContainer.value.text = value;
		}
		
		public function setFatsTitle(title:String):void
		{
			fatsContainer.title.text = title;
		}
		
		public function setFatsValue(value:String):void
		{
			fatsContainer.value.text = value;
		}
		
		public function setCaloriesTitle(title:String):void
		{
			caloriesContainer.title.text = title;
		}
		
		public function setCaloriesValue(value:String):void
		{
			caloriesContainer.value.text = value;
		}
		
		public function setLinkTitle(title:String):void
		{
			linkContainer.title.text = title;
		}
		
		public function setLinkComponent(component:DisplayObject):void
		{
			linkContainer.setComponent(component);
		}
		
		public function setSubtractFiberTitle(title:String):void
		{
			subtractFiberContainer.title.text = title;
		}
		
		public function setSubtractFiberComponent(component:DisplayObject):void
		{
			subtractFiberContainer.setComponent(component);
		}
		
		public function setAmountTitle(title:String):void
		{
			amountContainer.title.text = title;
		}
		
		public function setAmountComponent(component:DisplayObject):void
		{
			amountContainer.setComponent(component);
		}
		
		public function isRecipe():void
		{
			thirdRowContainer.removeChildren();
			thirdRowContainer.addChild(amountContainer);
		}
		
		public function isFood():void
		{
			thirdRowContainer.removeChildren();
			thirdRowContainer.addChild(linkContainer);
			thirdRowContainer.addChild(subtractFiberContainer);
			thirdRowContainer.addChild(amountContainer);
		}
		
		override public function dispose():void
		{
			if (servingSizeContainer != null)
			{
				servingSizeContainer.removeFromParent();
				servingSizeContainer.dispose();
				servingSizeContainer = null;
			}
			
			if (servingSizePickerListContainer != null)
			{
				servingSizePickerListContainer.removeFromParent();
				servingSizePickerListContainer.dispose();
				servingSizePickerListContainer = null;
			}
			
			if (carbsContainer != null)
			{
				carbsContainer.removeFromParent();
				carbsContainer.dispose();
				carbsContainer = null;
			}
			
			if (fiberContainer != null)
			{
				fiberContainer.removeFromParent();
				fiberContainer.dispose();
				fiberContainer = null;
			}
			
			if (proteinsContainer != null)
			{
				proteinsContainer.removeFromParent();
				proteinsContainer.dispose();
				proteinsContainer = null;
			}
			
			if (fatsContainer != null)
			{
				fatsContainer.removeFromParent();
				fatsContainer.dispose();
				fatsContainer = null;
			}
			
			if (caloriesContainer != null)
			{
				caloriesContainer.removeFromParent();
				caloriesContainer.dispose();
				caloriesContainer = null;
			}
			
			if (linkContainer != null)
			{
				linkContainer.removeFromParent();
				linkContainer.dispose();
				linkContainer = null;
			}
			
			if (subtractFiberContainer != null)
			{
				subtractFiberContainer.removeFromParent();
				subtractFiberContainer.dispose();
				subtractFiberContainer = null;
			}
			
			if (amountContainer != null)
			{
				amountContainer.removeFromParent();
				amountContainer.dispose();
				amountContainer = null;
			}
			
			if (firstRowContainer != null)
			{
				firstRowContainer.removeFromParent();
				firstRowContainer.dispose();
				firstRowContainer = null;
			}
			
			if (secondRowContainer != null)
			{
				secondRowContainer.removeFromParent();
				secondRowContainer.dispose();
				secondRowContainer = null;
			}
			
			if (thirdRowContainer != null)
			{
				thirdRowContainer.removeFromParent();
				thirdRowContainer.dispose();
				thirdRowContainer = null;
			}

			super.dispose();
		}
	}
}