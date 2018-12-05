package treatments
{
	public class Insulin
	{
		/* Properties */
		public var ID:String;
		public var name:String;
		public var dia:Number;
		public var type:String;
		public var isDefault:Boolean;
		public var timestamp:Number;
		public var isHidden:Boolean = false;
		public var curve:String;
		public var peak:Number;
		
		public function Insulin(id:String, name:String, dia:Number, type:String, isDefault:Boolean, timestamp:Number, isHidden:Boolean = false, curve:String = "bilinear", peak:Number = 75)
		{
			this.ID = id;
			this.name = name;
			this.dia = dia;
			this.type = type;
			this.isDefault = isDefault;
			this.timestamp = timestamp;
			this.isHidden = isHidden;
			this.curve = curve;
			this.peak = peak;
		}
	}
}