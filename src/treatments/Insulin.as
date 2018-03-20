package treatments
{
	public class Insulin
	{
		/* Constants */
		public static const TYPE_FAST:String = "fast";
		public static const TYPE_BASAL:String = "basal";
		
		/* Properties */
		public var ID:String;
		public var name:String;
		public var dia:Number;
		public var type:String;
		public var timestamp:Number;
		
		public function Insulin(id:String, name:String, dia:Number, type:String, timestamp:Number)
		{
			this.ID = id;
			this.name = name;
			this.dia = dia;
			this.type = type;
			this.timestamp = timestamp;
		}
	}
}