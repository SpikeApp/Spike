package treatments
{
	import flash.utils.Dictionary;
	
	import database.CGMBlueToothDevice;
	import database.CommonSettings;
	import database.Database;
	
	import utils.Trace;
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
			Trace.myTrace("ProfileManager.as", "init called!");
			
			if (!CGMBlueToothDevice.isFollower() || (CGMBlueToothDevice.isFollower() && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_URL) != "" && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_API_SECRET) != "" && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FOLLOWER_MODE) == "Nightscout"))
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
							dbInsulin.lastmodifiedtimestamp,
							dbInsulin.ishidden != null && dbInsulin.ishidden == "true" ? true : false,
							dbInsulin.curve != null && dbInsulin.curve != "" ? dbInsulin.curve : "bilinear",
							dbInsulin.peak != null && !isNaN(dbInsulin.peak) ? Number(dbInsulin.peak) : 75
						);
						
						insulinsList.push(insulin);
						insulinsMap[dbInsulin.id] = insulin;
						
						if (insulin.ID == "000000" && !insulin.isHidden) //Hide Nightscout insulin from UI
						{
							insulin.isHidden = true;
							updateInsulin(insulin);
						}
					}
					insulinsList.sortOn(["name"], Array.CASEINSENSITIVE);
					
					Trace.myTrace("ProfileManager.as", "Got insulns from database!");
				}
				else
					Trace.myTrace("ProfileManager.as", "No insulins stored in database!");
				
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
							dbProfile.trendcorrections,
							Number(dbProfile.lastmodifiedtimestamp)
						);
						
						profilesList.push(profile);
						profilesMap[dbProfile.id] = profile;
					}
					profilesList.sortOn(["time"], Array.CASEINSENSITIVE);
					
					Trace.myTrace("ProfileManager.as", "Got profile from database!");
				}
				else
					Trace.myTrace("ProfileManager.as", "No profiles stored in database!");
				
				if (profilesList.length == 0)
				{
					Trace.myTrace("ProfileManager.as", "Creating default profile...");
					
					createDefaultProfile();
				}
			}
		}
		
		public static function createDefaultProfile():Profile
		{
			profilesList.length = 0;
			
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
					"",
					new Date().valueOf()
				);
			
			//Push to memory
			profilesList.push(defaultProfile);
			profilesMap[defaultProfile.ID] = defaultProfile;
			
			//Save to Database
			Database.insertProfileSynchronous(defaultProfile);
			
			//Return profile
			return defaultProfile;
		}
		
		public static function getInsulin(ID:String):Insulin
		{
			return insulinsMap[ID];
		}
		
		public static function addInsulin(name:String, dia:Number, type:String, isDefault:Boolean = false, insulinID:String = null, saveToDatabase:Boolean = true, isHidden:Boolean = false, curve:String = "bilinear", peak:Number = 75):void
		{
			Trace.myTrace("ProfileManager.as", "addInsulin called!");
			
			//Generate insulin ID
			var newInsulinID:String = insulinID == null ? UniqueId.createEventId() : insulinID;
			
			//Check duplicates
			if (insulinsMap[newInsulinID] != null && insulinID != "000000")
				return;
			
			if (insulinID != "000000" || insulinsMap[newInsulinID] == null)
			{
				Trace.myTrace("ProfileManager.as", "Created new insulin. Name: " + name);
				
				//Create new insulin
				var insulin:Insulin = new Insulin
				(
					newInsulinID,
					name,
					dia,
					type,
					isDefault,
					new Date().valueOf(),
					isHidden,
					curve,
					peak
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
				Trace.myTrace("ProfileManager.as", "Updating Nightscout insulin");
				
				//Nightscout insulin already exists, let's update it
				var existingNSInsulin:Insulin = insulinsMap[newInsulinID] as Insulin;
				existingNSInsulin.dia = dia;
				existingNSInsulin.timestamp = new Date().valueOf();
				existingNSInsulin.isHidden = true;
				Database.updateInsulinSynchronous(existingNSInsulin);
			}
		}
		
		public static function updateInsulin(insulin:Insulin, saveToDatabase:Boolean = true):void
		{
			Trace.myTrace("ProfileManager.as", "updateInsulin called!");
			
			if (insulinsMap[insulin.ID] != null)
			{
				Trace.myTrace("ProfileManager.as", "Updating insulin " + insulin.name);
				if (saveToDatabase)
					Database.updateInsulinSynchronous(insulin);
			}
			else
				Trace.myTrace("ProfileManager.as", "Can't update an insulin that doesn't exist!");
		}
		
		public static function deleteInsulin(insulin:Insulin):void
		{
			Trace.myTrace("ProfileManager.as", "deleteInsulin called!");
			
			if (insulinsMap[insulin.ID] != null)
			{
				//Find insulin
				for (var i:int = 0; i < insulinsList.length; i++) 
				{
					var userInsulin:Insulin = insulinsList[i];
					if (userInsulin.ID == insulin.ID)
					{
						Trace.myTrace("ProfileManager.as", "Deleting insulin: " + userInsulin.name);
						
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
			Trace.myTrace("ProfileManager.as", "getDefaultInsulinID called!");
			
			var insulinID:String = "";
			var foundDefault:Boolean = false;
			var i:int = 0;
			var insulin:Insulin;
			
			insulinsList.sortOn(["name"], Array.CASEINSENSITIVE);
			
			for (i = 0; i < insulinsList.length; i++) 
			{
				insulin = insulinsList[i];
				if (insulin.isDefault && !insulin.isHidden)
				{
					insulinID = insulin.ID;
					foundDefault = true;
					break;
				}
			}
			
			if (!foundDefault && insulinsList.length > 0)
			{
				for (i = 0; i < insulinsList.length; i++) 
				{
					insulin = insulinsList[i];
					if (!insulin.isHidden)
					{
						Trace.myTrace("ProfileManager.as", "Found default insulin: " + insulin.name);
						insulinID = insulin.ID;
						foundDefault = true;
						break;
					}
				}
			}
			
			if (insulinsList.length == 0 && !foundDefault)
			{
				Trace.myTrace("ProfileManager.as", "Can't find a default insulin. Returning Nightscout insulin.");
				insulinID = "000000"; //Nightscout insulin
			}
			
			return insulinID;
		}
		
		public static function updateProfile(profile:Profile):void
		{	
			Trace.myTrace("ProfileManager.as", "updateProfile called!");
			
			//Update Database
			Database.updateProfileSynchronous(profile);
			
			//Sort profile list by time
			profilesList.sortOn(["time"], Array.CASEINSENSITIVE);
		}
		
		public static function insertProfile(profile:Profile):void
		{	
			Trace.myTrace("ProfileManager.as", "insertProfile called!");
			
			//Push to memory
			profilesList.push(profile);
			profilesMap[profile.ID] = profile;
			
			//Save to Database
			Database.insertProfileSynchronous(profile);
			
			//Sort profile list by time
			profilesList.sortOn(["time"], Array.CASEINSENSITIVE);
		}
		
		public static function deleteProfile(profile:Profile):void
		{
			Trace.myTrace("ProfileManager.as", "deleteProfile called!");
			
			if (profilesMap[profile.ID] != null)
			{
				//Find Profile
				for (var i:int = 0; i < profilesList.length; i++) 
				{
					var userProfile:Profile = profilesList[i];
					if (userProfile.ID == profile.ID)
					{
						Trace.myTrace("ProfileManager.as", "Deleting profile... Name: " + profile.name + ", Time: " + profile.time);
						
						//Profile found. Remove it from Spike.
						profilesList.removeAt(i);
						profilesMap[profile.ID] = null;
						
						//Delete from database
						Database.deleteProfileSynchronous(userProfile);
						
						//Sort profile list by time
						profilesList.sortOn(["time"], Array.CASEINSENSITIVE);
						
						break;
					}
				}
			}
		}
		
		public static function addNightscoutCarbAbsorptionRate(rate:Number):void
		{
			Trace.myTrace("ProfileManager.as", "Adding Nightscout carbs absorption rate: " + rate);
			
			nightscoutCarbAbsorptionRate = rate;
		}
		
		public static function getCarbAbsorptionRate():Number
		{
			var carbAbsorptionRate:Number = 30;
			
			if (!CGMBlueToothDevice.isFollower())
			{
				if (profilesList != null && profilesList.length > 0 && profilesList[0] != null && !isNaN((profilesList[0] as Profile).carbsAbsorptionRate))
					carbAbsorptionRate = (profilesList[0] as Profile).carbsAbsorptionRate;
			}
			else
				carbAbsorptionRate = nightscoutCarbAbsorptionRate;
			
			return carbAbsorptionRate;
		}
		
		public static function getDefaultTimeAbsortionCarbType():String
		{
			var carbType:String = "Unknown";
			var fastAbsortionTimeValue:Number = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CARB_FAST_ABSORTION_TIME));
			var mediumAbsortionTimeValue:Number = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CARB_MEDIUM_ABSORTION_TIME));
			var slowAbsortionTimeValue:Number = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CARB_SLOW_ABSORTION_TIME));
			var defaultAbsortionTimeValue:Number = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEFAULT_CARB_ABSORTION_TIME));
			
			if (defaultAbsortionTimeValue == fastAbsortionTimeValue)
				carbType = "fast";
			else if (defaultAbsortionTimeValue == mediumAbsortionTimeValue)
				carbType = "medium";
			else if (defaultAbsortionTimeValue == slowAbsortionTimeValue)
				carbType = "slow";
			
			return carbType;
		}
		
		public static function getProfileByTime(requestedTimestamp:Number):Profile
		{
			var currentProfile:Profile;
			
			var requestedDate:Date = new Date(requestedTimestamp);
			var requestedHours:Number = requestedDate.hours;
			var requestedMinutes:Number = requestedDate.minutes;
			var numberOfProfiles:int = profilesList.length;
			
			if (numberOfProfiles == 0)
			{
				createDefaultProfile();
			}
			
			for(var i:int = numberOfProfiles - 1 ; i >= 0; i--)
			{
				var profile:Profile = profilesList[i] as Profile;
				if (profile != null)
				{	
					var profileDate:Date = getProfileDate(profile);
					var profileHours:Number = profileDate.hours;
					var profileMinutes:Number = profileDate.minutes;
					
					if (requestedHours >= profileHours || (requestedHours == profileHours && requestedMinutes >= profileMinutes))
					{
						currentProfile = profile;
						break;
					}
				}
			}
				
			/*var profileTimestamp:Number = profileDate.valueOf();
				
			if (requestedTimestamp >= profileTimestamp)
			{
				currentProfile = profile;
				break;
			}*/
			
			return currentProfile;
		}
		
		public static function getProfileDate(profile:Profile):Date
		{
			var profileDividedTime:Array = profile.time.split(":");
			var profileHour:Number = Number(profileDividedTime[0]);
			var profileMinutes:Number = Number(profileDividedTime[1]);
			
			if (isNaN(profileHour))
				profileHour = 0;
			
			if (isNaN(profileMinutes))
				profileMinutes = 0;
			
			var profileDate:Date = new Date();
			profileDate.hours = profileHour;
			profileDate.minutes = profileMinutes;
			profileDate.seconds = 0;
			profileDate.milliseconds = 0;
			
			return profileDate;
		}
	}
}