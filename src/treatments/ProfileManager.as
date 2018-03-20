package treatments
{
	import database.Database;

	public class ProfileManager
	{
		public static var insulinsList:Array = [];
		
		public function ProfileManager()
		{
			throw new Error("ProfileManager is not meant to be instantiated!");
		}
		
		public static function init():void
		{
			var dbInsulines:Array = Database.getInsulinsSynchronous();
			if (dbInsulines != null && dbInsulines.length > 0)
			{
				for (var i:int = 0; i < dbInsulines.length; i++) 
				{
					var dbInsulin:Object = dbInsulines[i] as Object;
					if (dbInsulin == null)
						continue;
					
					var insulin:Insulin = new Insulin
					(
						dbInsulin.id,
						dbInsulin.name,
						dbInsulin.dia,
						dbInsulin.type,
						dbInsulin.lastmodifiedtimestamp
					);
					
					insulinsList.push(insulin);
				}	
			}
		}
		
		public static function getInsulin(ID:String):Insulin
		{
			var insulinMatched:Insulin;
			
			for (var i:int = 0; i < insulinsList.length; i++) 
			{
				var insulin:Insulin = insulinsList[i] as Insulin;
				if (insulin == null)
					continue;
				
				if (insulin.ID == ID)
				{
					insulinMatched = insulin;
					break;
				}
			}
			
			return insulinMatched;
		}
	}
}