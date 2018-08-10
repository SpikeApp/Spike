package treatments
{
	public class Food
	{
		public var name:String;
		public var brand:String;
		public var proteins:Number;
		public var carbs:Number;
		public var fiber:Number;
		public var fats:Number;
		public var kcal:Number;
		public var link:String;
		
		public function Food(name:String, proteins:Number, carbs:Number, fats:Number, fiber:Number = Number.NaN, kcal:Number = Number.NaN, brand:String = "", link:String = "")
		{
			this.name = name;
			this.proteins = proteins;
			this.carbs = carbs;
			this.fats = fats;
			this.fiber = fiber;
			this.kcal = kcal;
			this.brand = brand;
			this.link = link;
		}
	}
}