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
	}
}