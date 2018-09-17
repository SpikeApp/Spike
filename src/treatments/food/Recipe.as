package treatments.food
{
	import utils.UniqueId;

	public class Recipe
	{
		public var id:String;
		public var name:String;
		public var servingSize:String;
		public var servingUnit:String;
		public var foods:Array;
		public var timestamp:Number;
		public var notes:String;
		public var totalProteins:Number = 0;
		public var totalCarbs:Number = 0;
		public var totalFiber:Number = 0;
		public var totalFats:Number = 0;
		public var totalCalories:Number = 0;
		
		public function Recipe(id:String, name:String, servingSize:String, servingUnit:String, foods:Array, timestamp:Number, notes:String = "")
		{
			this.id = id == null ? UniqueId.createEventId() : id;
			this.name = name;
			this.servingSize = servingSize;
			this.servingUnit = servingUnit;
			this.foods = foods;
			this.timestamp = timestamp;
			this.notes = notes;
		}
		
		public function performCalculations():void
		{
			//Add to totals
			for (var i:int = 0; i < foods.length; i++) 
			{
				var food:Food = foods[i];
				var foodProteins:Number = (Number(servingSize) / food.recipeServingSize) * food.proteins;
				var foodCarbs:Number = (Number(servingSize) / food.recipeServingSize) * food.carbs;
				var foodFiber:Number = (Number(servingSize) / food.recipeServingSize) * food.fiber;
				var foodFats:Number = (Number(servingSize) / food.recipeServingSize) * food.fats;
				var foodCalories:Number = (Number(servingSize) / food.recipeServingSize) * food.kcal;;
				
				totalProteins += !isNaN(foodProteins) ? foodProteins : 0;
				totalCarbs += !isNaN(foodCarbs) ? foodCarbs : 0;
				totalFiber += !isNaN(foodFiber) ? foodFiber : 0;
				if (food.substractFiber && !isNaN(foodFiber)) totalCarbs -= foodFiber;
				totalFats += !isNaN(foodFats) ? foodFats : 0;
				totalCalories += !isNaN(foodCalories) ? foodCalories : 0;
			}
			
			//Round Values
			totalProteins = Math.round(totalProteins * 100) / 100;
			totalCarbs = Math.round(totalCarbs * 100) / 100;
			totalFiber = Math.round(totalFiber * 100) / 100;
			totalFats = Math.round(totalFats * 100) / 100;
			totalCalories = Math.round(totalCalories * 100) / 100;
		}
	}
}