package treatments.ui
{
	import feathers.controls.LayoutGroup;
	import feathers.layout.HorizontalAlign;
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
			firstRowContainer = LayoutFactory.createLayoutGroup("horizontal");
			firstRowContainer.width = width;
			addChild(firstRowContainer);
			
			servingSizeContainer = new NutritionFactsSection(width / 3);
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
			thirdRowContainer = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.LEFT, VerticalAlign.TOP);
			thirdRowContainer.width = width;
			addChild(thirdRowContainer);
			
			linkContainer = new NutritionFactsSectionWithAction(width / 3);
			thirdRowContainer.addChild(linkContainer);
			
			subtractFiberContainer = new NutritionFactsSectionWithAction(width / 3);
			thirdRowContainer.addChild(subtractFiberContainer);
			
			amountContainer = new NutritionFactsSectionWithAction(width / 3);
			thirdRowContainer.addChild(amountContainer);
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
	}
}