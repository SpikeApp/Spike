package treatments
{
	import flash.utils.Dictionary;
	
	import database.Database;
	
	import utils.UniqueId;

	public class ProfileManager
	{
		public static var carbAbsorptionRate:Number = 30;
		public static var insulinsList:Array = [];
		private static var insulinsMap:Dictionary = new Dictionary();
		
		public function ProfileManager()
		{
			throw new Error("ProfileManager is not meant to be instantiated!");
		}
		
		public static function init():void
		{
			//Get insulins
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
						dbInsulin.isdefault == "true" ? true : false,
						dbInsulin.lastmodifiedtimestamp
					);
					
					insulinsList.push(insulin);
					insulinsMap[dbInsulin.id] = insulin;
				}
				insulinsList.sortOn(["name"], Array.CASEINSENSITIVE);
			}
			
			//Get Profile
			
		}
		
		public static function getInsulin(ID:String):Insulin
		{
			return insulinsMap[ID];
		}
		
		public static function addInsulin(name:String, dia:Number, type:String, isDefault:Boolean = false, insulinID:String = null, saveToDatabase:Boolean = true):void
		{
			//Generate insulin ID
			var newInsulinID:String = insulinID == null ? UniqueId.createEventId() : insulinID;
			
			//Check duplicates
			if (insulinsMap[newInsulinID] != null)
				return;
			
			//Create new insulin
			var insulin:Insulin = new Insulin
			(
				newInsulinID,
				name,
				dia,
				type,
				isDefault,
				new Date().valueOf()
			);
			
			//Add to Spike
			insulinsList.push(insulin);
			insulinsList.sortOn(["name"], Array.CASEINSENSITIVE);
			insulinsMap[newInsulinID] = insulin;
			
			//Save in database
			if (saveToDatabase)
				Database.insertInsulinSynchronous(insulin);
		}
		
		public static function updateInsulin(insulin:Insulin):void
		{
			Database.updateInsulinSynchronous(insulin);
		}
		
		public static function deleteInsulin(insulin:Insulin):void
		{
			//Find insulin
			for (var i:int = 0; i < insulinsList.length; i++) 
			{
				var userInsulin:Insulin = insulinsList[i];
				if (userInsulin.ID == insulin.ID)
				{
					//Insulin found. Remove it from Spike.
					insulinsList.removeAt(i);
					insulinsMap[insulin.ID] = null;
					
					//Delete from database
					Database.deleteInsulinSynchronous(userInsulin);
					
					break;
				}
			}
		}
		
		public static function addCarbAbsorptionRate(rate:Number):void
		{
			carbAbsorptionRate = rate;
		}
	}
}