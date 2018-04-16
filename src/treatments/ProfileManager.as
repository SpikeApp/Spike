package treatments
{
	import flash.utils.Dictionary;
	
	import database.BlueToothDevice;
	import database.Database;
	
	import model.ModelLocator;
	
	import utils.UniqueId;

	public class ProfileManager
	{
		public static var insulinsList:Array = [];
		private static var insulinsMap:Dictionary = new Dictionary();
		public static var profilesList:Array = [];
		private static var profilesMap:Dictionary = new Dictionary();
		private static var nightscoutCarbAbsorptionRate:Number = 0;
		
		public function ProfileManager()
		{
			throw new Error("ProfileManager is not meant to be instantiated!");
		}
		
		public static function init():void
		{
			if (!BlueToothDevice.isFollower() || ModelLocator.INTERNAL_TESTING)
			{
				//Common variables
				var i:int;
				
				//Get insulins
				var dbInsulines:Array = Database.getInsulinsSynchronous();
				if (dbInsulines != null && dbInsulines.length > 0)
				{
					for (i = 0; i < dbInsulines.length; i++) 
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
				
				//Get Profiles
				var dbProfiles:Array = Database.getProfilesSynchronous();
				if (dbProfiles != null && dbProfiles.length > 0)
				{
					for (i = 0; i < dbProfiles.length; i++) 
					{
						var dbProfile:Object = dbProfiles[i] as Object;
						if (dbProfile == null)
							continue;
						
						var profile:Profile = new Profile
						(
							dbProfile.id,
							dbProfile.time,
							dbProfile.name,
							dbProfile.insulintocarbratios,
							dbProfile.insulinsensitivityfactors,
							dbProfile.carbsabsorptionrate,
							dbProfile.basalrates,
							dbProfile.targetglucoserates,
							Number(dbProfile.lastmodifiedtimestamp)
						);
						
						profilesList.push(profile);
						profilesMap[dbProfile.id] = profile;
					}
					profilesList.sortOn(["name"], Array.CASEINSENSITIVE);
				}
				
				if (profilesList.length == 0)
				{
					//Create default profile
					var defaultProfile:Profile = new Profile
					(
						UniqueId.createEventId(),
						"00:00",
						"Default",
						"",
						"",
						30,
						"",
						"",
						new Date().valueOf()
					);
					
					//Push to memory
					profilesList.push(defaultProfile);
					profilesMap[defaultProfile.ID] = defaultProfile;
					
					//Save to Database
					Database.insertProfileSynchronous(defaultProfile);
				}
			}
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
			if (insulinsMap[newInsulinID] != null && insulinID != "000000")
				return;
			
			if (insulinID != "000000" || insulinsMap[newInsulinID] == null)
			{
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
			else if (insulinID == "000000" && insulinsMap[newInsulinID] != null)
			{
				//Nightscout insulin already exists, let's update it
				var existingNSInsulin:Insulin = insulinsMap[newInsulinID] as Insulin;
				existingNSInsulin.dia = dia;
				existingNSInsulin.timestamp = new Date().valueOf();
				Database.updateInsulinSynchronous(existingNSInsulin);
			}
		}
		
		public static function updateInsulin(insulin:Insulin):void
		{
			if (insulinsMap[insulin.ID] != null)
				Database.updateInsulinSynchronous(insulin);
		}
		
		public static function deleteInsulin(insulin:Insulin):void
		{
			if (insulinsMap[insulin.ID] != null)
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
		}
		
		public static function getDefaultInsulinID():String
		{
			var insulinID:String = "";
			var foundDefault:Boolean = false;
			
			insulinsList.sortOn(["name"], Array.CASEINSENSITIVE);
			
			for (var i:int = 0; i < insulinsList.length; i++) 
			{
				var insulin:Insulin = insulinsList[i];
				if (insulin.isDefault)
				{
					insulinID = insulin.ID;
					foundDefault = true;
					break;
				}
			}
			
			if (!foundDefault && insulinsList.length > 0)
			{
				insulinID = (insulinsList[0] as Insulin).ID;
				foundDefault;
			}
			
			if (insulinsList.length == 0 && !foundDefault)
				insulinID = "000000"; //Nightscout insulin
			
			return insulinID;
		}
		
		public static function updateProfile(profile:Profile):void
		{	
			//Update Database
			Database.updateProfileSynchronous(profile);
		}
		
		public static function addNightscoutCarbAbsorptionRate(rate:Number):void
		{
			nightscoutCarbAbsorptionRate = rate;
		}
		
		public static function getCarbAbsorptionRate():Number
		{
			var carbAbsorptionRate:Number = 0;
			
			if (!BlueToothDevice.isFollower())
			{
				if (profilesList != null && profilesList.length > 0 && profilesList[0] != null && !isNaN((profilesList[0] as Profile).carbsAbsorptionRate))
					carbAbsorptionRate = (profilesList[0] as Profile).carbsAbsorptionRate;
			}
			else
				carbAbsorptionRate = nightscoutCarbAbsorptionRate;
			
			return carbAbsorptionRate;
		}
	}
}