package events
{
	import flash.events.Event;
	
	import treatments.food.Food;
	import treatments.food.Recipe;

	public class FoodEvent extends Event
	{
		[Event(name="foodsSearchResult",type="events.FoodEvent")]
		[Event(name="foodDetailsResult",type="events.FoodEvent")]
		[Event(name="foodNotFound",type="events.FoodEvent")]
		[Event(name="foodServerError",type="events.FoodEvent")]
		[Event(name="recipesSearchResult",type="events.FoodEvent")]
		[Event(name="recipeDetailsResult",type="events.FoodEvent")]
		[Event(name="recipeNotFound",type="events.FoodEvent")]
		
		public static const FOODS_SEARCH_RESULT:String = "foodsSearchResult";
		public static const FOOD_DETAILS_RESULT:String = "foodDetailsResult";
		public static const FOOD_NOT_FOUND:String = "foodNotFound";
		public static const FOOD_SERVER_ERROR:String = "foodServerError";
		public static const RECIPES_SEARCH_RESULT:String = "recipesSearchResult";
		public static const RECIPE_DETAILS_RESULT:String = "recipeDetailsResult";
		public static const RECIPE_NOT_FOUND:String = "recipeNotFound";
		
		public var food:Food;
		public var foodsList:Array;
		public var recipe:Recipe;
		public var recipesList:Array;
		public var errorMessage:String;
		public var searchProperties:Object;
		
		public function FoodEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false, food:Food = null, foodsList:Array = null, recipe:Recipe = null, recipesList:Array = null, errorMessage:String = null, searchProperties:Object = null) 
		{
			super(type, bubbles, cancelable);
			
			this.food = food;
			this.foodsList = foodsList;
			this.recipe = recipe;
			this.recipesList = recipesList;
			this.errorMessage = errorMessage;
			this.searchProperties = searchProperties;
		}
	}
}