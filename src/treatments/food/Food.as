package treatments.food
{
	public class Food
	{
		public var id:String;
		public var name:String;
		public var brand:String;
		public var proteins:Number;
		public var carbs:Number;
		public var fiber:Number;
		public var fats:Number;
		public var kcal:Number;
		public var link:String;
		public var servingSize:Number;
		public var servingUnit:String;
		public var source:String;
		public var barcode:String;
		public var timestamp:Number;
		public var substractFiber:Boolean;
		public var recipeServingSize:Number;
		public var recipeServingUnit:String;
		public var note:String;
		public var defaultUnit:Boolean;
		
		public function Food(id:String, 
							 name:String, 
							 proteins:Number, 
							 carbs:Number, 
							 fats:Number, 
							 kcal:Number, 
							 servingSize:Number, 
							 servingUnit:String, 
							 timestamp:Number, 
							 fiber:Number = Number.NaN, 
							 brand:String = "", 
							 link:String = "", 
							 source:String = "", 
							 barcode:String = "", 
							 substractFiber:Boolean = false, 
							 recipeServingSize:Number = 0, 
							 recipeServingUnit:String = "", 
							 note:String = "",
							 defaultUnit:Boolean = true
		)
		{
			this.id = id;
			this.name = name;
			this.proteins = proteins;
			this.carbs = carbs;
			this.fats = fats;
			this.kcal = kcal;
			this.servingSize = servingSize;
			this.servingUnit = servingUnit;
			this.fiber = fiber;
			this.brand = brand;
			this.link = link;
			this.timestamp = timestamp;
			this.source = source;
			this.barcode = barcode;
			this.substractFiber = substractFiber;
			this.recipeServingSize = recipeServingSize;
			this.recipeServingUnit = recipeServingUnit;
			this.note = note;
			this.defaultUnit = defaultUnit;
		}
	}
}