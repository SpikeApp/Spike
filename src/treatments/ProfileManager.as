package treatments
{
	import com.adobe.utils.StringUtil;
	
	import flash.utils.Dictionary;
	
	import database.CGMBlueToothDevice;
	import database.CommonSettings;
	import database.Database;
	
	import model.ModelLocator;
	
	import services.NightscoutService;
	
	import ui.popups.AlertManager;
	
	import utils.Constants;
	import utils.TimeSpan;
	import utils.Trace;
	import utils.UniqueId;
	
	[ResourceBundle("profilesettingsscreen")]
	[ResourceBundle("globaltranslations")]

	public class ProfileManager
	{
		public static var insulinsList:Array = [];
		private static var insulinsMap:Dictionary = new Dictionary();
		public static var profilesList:Array = [];
		private static var profilesMap:Dictionary = new Dictionary();
		private static var profilesMapByTime:Object = {};
		public static var basalRatesList:Array = [];
		public static var basalRatesMap:Dictionary = new Dictionary();
		public static var basalRatesMapByTime:Object = {};
		private static var nightscoutCarbAbsorptionRate:Number = 0;
		public static var totalDeliveredPumpBasalAmount:Number = 0;
		
		public function ProfileManager()
		{
			throw new Error("ProfileManager is not meant to be instantiated!");
		}
		
		public static function init():void
		{
			Trace.myTrace("ProfileManager.as", "init called!");
			
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
					profilesMapByTime[profile.time] = profile;
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
			
			removeDuplicateProfiles();
			
			//Get Basal Rates
			var dbBasalRates:Array = Database.getBasalRatesSynchronous();
			if (dbBasalRates != null && dbBasalRates.length > 0)
			{
				for (i = 0; i < dbBasalRates.length; i++) 
				{
					var dbBasalRate:Object = dbBasalRates[i] as Object;
					if (dbBasalRate == null)
						continue;
					
					var basalRate:BasalRate = new BasalRate
					(
						dbBasalRate.rate,
						dbBasalRate.hours,
						dbBasalRate.minutes,
						dbBasalRate.time,
						dbBasalRate.id,
						dbBasalRate.lastmodifiedtimestamp
					)
					
					basalRatesList.push(basalRate);
					basalRatesMap[dbBasalRate.id] = basalRate;
					basalRatesMapByTime[dbBasalRate.time] = basalRate;
				}
				basalRatesList.sortOn(["startTime"], Array.CASEINSENSITIVE);
				
				Trace.myTrace("ProfileManager.as", "Got basal rates from database!");
			}
			else
				Trace.myTrace("ProfileManager.as", "No basal rates stored in database!");
		}
		
		/**
		 * PROFILES
		 */
		private static function removeDuplicateProfiles():void
		{
			var tempProfilesList:Object = {};
			var tempProfilesArray:Array = [];
			
			var numberOfRealProfiles:uint = profilesList.length;
			for (var i:int = 0; i < numberOfRealProfiles; i++) 
			{
				var realProfile:Profile = profilesList[i];
				if (realProfile == null)
				{
					continue;
				}
				
				if (tempProfilesList[realProfile.time] == null)
				{
					tempProfilesList[realProfile.time] = realProfile;
				}
				else
				{
					var tempProfile:Profile = tempProfilesList[realProfile.time];
					if (tempProfile != null)
					{
						if 
						(
							(realProfile.timestamp >= tempProfile.timestamp && realProfile.insulinSensitivityFactors == "" && tempProfile.insulinSensitivityFactors == "")
							||
							(realProfile.timestamp >= tempProfile.timestamp && realProfile.insulinSensitivityFactors != "" && tempProfile.insulinSensitivityFactors != "")
							||
							(realProfile.insulinSensitivityFactors != "" && tempProfile.insulinSensitivityFactors == "")
						)
						{
							Database.deleteProfileSynchronous(tempProfile);
							
							if (profilesMap[tempProfile.ID])
							{
								delete 	profilesMap[tempProfile.ID];
							}
							
							if (profilesMapByTime[tempProfile.time])
							{
								delete 	profilesMapByTime[tempProfile.time];
							}
							
							tempProfile = null;
							
							tempProfilesList[realProfile.time] = realProfile;
						}
						else
						{
							Database.deleteProfileSynchronous(realProfile);
							
							if (profilesMap[realProfile.ID])
							{
								delete 	profilesMap[realProfile.ID];
							}
							
							if (profilesMapByTime[realProfile.time])
							{
								delete 	profilesMapByTime[realProfile.time];
							}
							
							realProfile = null;
						}
					}
				}
			}
			
			for (var key:String in tempProfilesList)
			{
				var finalProfile:Profile = tempProfilesList[key];
				if (finalProfile != null && finalProfile is Profile)
				{
					tempProfilesArray.push(finalProfile);
				}
			}
			
			profilesList = tempProfilesArray;
			profilesList.sortOn(["time"], Array.CASEINSENSITIVE);
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
			profilesMapByTime[defaultProfile.time] = defaultProfile;
			
			//Save to Database
			Database.insertProfileSynchronous(defaultProfile);
			
			//Return profile
			return defaultProfile;
		}
		
		public static function updateProfile(profile:Profile):void
		{	
			Trace.myTrace("ProfileManager.as", "updateProfile called!");
			
			//Update Database
			Database.updateProfileSynchronous(profile);
			
			//Sort profile list by time
			profilesList.sortOn(["time"], Array.CASEINSENSITIVE);
		}
		
		public static function insertProfile(profile:Profile, overwrite:Boolean = false):void
		{	
			Trace.myTrace("ProfileManager.as", "insertProfile called!");
			
			if (profilesMapByTime[profile.time] == null)
			{
				//Push to memory
				profilesList.push(profile);
				profilesMap[profile.ID] = profile;
				profilesMapByTime[profile.time] = profile;
				
				//Save to Database
				Database.insertProfileSynchronous(profile);
				
				//Sort profile list by time
				profilesList.sortOn(["time"], Array.CASEINSENSITIVE);
			}
			else
			{
				if (overwrite)
				{
					var existingProfile:Profile = profilesMapByTime[profile.time];
					existingProfile.basalRates = profile.basalRates;
					existingProfile.carbsAbsorptionRate = profile.carbsAbsorptionRate;
					existingProfile.insulinCurve = profile.insulinCurve;
					existingProfile.insulinPeakTime = profile.insulinPeakTime;
					existingProfile.insulinSensitivityFactors = profile.insulinSensitivityFactors;
					existingProfile.insulinToCarbRatios = profile.insulinToCarbRatios;
					existingProfile.name = profile.name;
					existingProfile.targetGlucoseRates = profile.targetGlucoseRates;
					existingProfile.time = profile.time;
					existingProfile.trend45Down = profile.trend45Down;
					existingProfile.trend45Up = profile.trend45Up;
					existingProfile.trend90Down = profile.trend90Down;
					existingProfile.trend90Up = profile.trend90Up;
					existingProfile.trendCorrections = profile.trendCorrections;
					existingProfile.trendDoubleDown = profile.trendDoubleDown;
					existingProfile.trendDoubleUp = profile.trendDoubleUp;
					existingProfile.useCustomInsulinPeakTime = profile.useCustomInsulinPeakTime;
					
					updateProfile(existingProfile);
				}
				else
				{
					AlertManager.showSimpleAlert
					(
						ModelLocator.resourceManagerInstance.getString("globaltranslations","warning_alert_title"),
						ModelLocator.resourceManagerInstance.getString("profilesettingsscreen","duplicate_profile_label")
					);
				}
			}
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
						profilesMapByTime[profile.time] = null;
						
						//Delete from database
						Database.deleteProfileSynchronous(userProfile);
						
						//Sort profile list by time
						profilesList.sortOn(["time"], Array.CASEINSENSITIVE);
						
						break;
					}
				}
			}
		}
		
		public static function getProfileByTime(requestedTimestamp:Number):Profile
		{
			var currentProfile:Profile;
			
			try
			{
				var requestedDate:Date = new Date(requestedTimestamp);
				var requestedDateAdjusted:Date = new Date();
				requestedDateAdjusted.hours = requestedDate.hours;
				requestedDateAdjusted.minutes = requestedDate.minutes;
				requestedDateAdjusted.seconds = requestedDate.seconds;
				requestedDateAdjusted.milliseconds = requestedDate.milliseconds;
				var requestedTimestampAdjusted:Number = requestedDateAdjusted.valueOf();
				
				var numberOfProfiles:int = profilesList.length;
				if (numberOfProfiles == 0)
				{
					createDefaultProfile();
					numberOfProfiles = profilesList.length;
				}
				
				for (var i:int = numberOfProfiles - 1 ; i >= 0; i--)
				{
					var profile:Profile = profilesList[i] as Profile;
					if (profile != null)
					{	
						var profileDate:Date = getProfileDate(profile);
						var profileTimestamp:Number = profileDate.valueOf();
						
						if (requestedTimestampAdjusted >= profileTimestamp)
						{
							currentProfile = profile;
							break;
						}
					}
				}
			} 
			catch(error:Error) {}
			
			if (currentProfile == null)
			{
				currentProfile = createDefaultProfile();
			}
			
			return currentProfile;
		}
		
		public static function getProfileDate(profile:Profile):Date
		{
			var profileDate:Date = new Date();
			profileDate.hours = 0;
			profileDate.minutes = 0;
			profileDate.seconds = 0;
			profileDate.milliseconds = 0;
			
			try
			{
				var profileDividedTime:Array = profile.time.split(":");
				var profileHour:Number = Number(profileDividedTime[0]);
				var profileMinutes:Number = Number(profileDividedTime[1]);
				
				if (isNaN(profileHour))
					profileHour = 0;
				
				if (isNaN(profileMinutes))
					profileMinutes = 0;
				
				profileDate.hours = profileHour;
				profileDate.minutes = profileMinutes;
				profileDate.seconds = 0;
				profileDate.milliseconds = 0;
			} 
			catch(error:Error) {}
			
			return profileDate;
		}
		
		/**
		 * BASAL RATES
		 */
		public static function updateBasalRate(basalRate:BasalRate):void
		{	
			Trace.myTrace("ProfileManager.as", "updateBasalRate called!");
			
			//Update Database
			Database.updateBasalRateSynchronous(basalRate);
			
			//Sort basal rates list by time
			basalRatesList.sortOn(["startTime"], Array.CASEINSENSITIVE);
		}
		
		public static function insertBasalRate(basalRate:BasalRate, overwrite:Boolean = false, saveToDatabase:Boolean = true):void
		{	
			if (basalRatesMapByTime[basalRate.startTime] == null)
			{
				//Push to memory
				basalRatesList.push(basalRate);
				basalRatesMap[basalRate.ID] = basalRate;
				basalRatesMapByTime[basalRate.startTime] = basalRate;
				
				//Save to Database
				if (saveToDatabase)
				{
					Database.insertBasalRateSynchronous(basalRate);
				}
				
				//Sort basal rates list by time
				basalRatesList.sortOn(["startTime"], Array.CASEINSENSITIVE);
			}
			else
			{
				if (overwrite)
				{
					var existingBasalRate:BasalRate = basalRatesMapByTime[basalRate.startTime];
					existingBasalRate.basalRate = basalRate.basalRate;
					existingBasalRate.startHours = basalRate.startHours;
					existingBasalRate.startMinutes = basalRate.startMinutes;
					existingBasalRate.startTime = basalRate.startTime;
					existingBasalRate.timestamp = basalRate.timestamp;
					
					if (saveToDatabase)
					{
						updateBasalRate(existingBasalRate);
					}
					else
					{
						//Sort basal rates list by time
						basalRatesList.sortOn(["startTime"], Array.CASEINSENSITIVE);
					}
				}
				else
				{
					AlertManager.showSimpleAlert
					(
						ModelLocator.resourceManagerInstance.getString("globaltranslations","warning_alert_title"),
						ModelLocator.resourceManagerInstance.getString("profilesettingsscreen","duplicate_basal_rate_label")
					);
				}
			}
		}
		
		public static function deleteBasalRate(basalRate:BasalRate):void
		{
			Trace.myTrace("ProfileManager.as", "deleteBasalRate called!");
			
			if (basalRatesMap[basalRate.ID] != null)
			{
				//Find Basal Rate
				for (var i:int = 0; i < basalRatesList.length; i++) 
				{
					var userBasalRate:BasalRate = basalRatesList[i];
					if (userBasalRate.ID == basalRate.ID)
					{
						Trace.myTrace("ProfileManager.as", "Deleting basal rate... Time: " + basalRate.startTime);
						
						//Basal rate found. Remove it from Spike.
						basalRatesList.removeAt(i);
						basalRatesMap[basalRate.ID] = null;
						basalRatesMapByTime[basalRate.startTime] = null;
						
						//Delete from database
						Database.deleteBasalRateSynchronous(basalRate);
						
						//Sort basal rate list by time
						basalRatesList.sortOn(["startTime"], Array.CASEINSENSITIVE);
						
						break;
					}
				}
			}
		}
		
		public static function deleteAllBasalRates():void
		{
			for (var i:int = basalRatesList.length - 1 ; i >= 0; i--)
			{
				var basalRate:BasalRate = basalRatesList[i];
				if (basalRate != null)
				{
					deleteBasalRate(basalRate);
				}
			}
		}
		
		public static function getBasalRateByTime(time:Number):Number
		{
			var scheduledBasalRate:Number = 0;
			var numberOfScheduleBasalRates:uint = basalRatesList.length;
			
			if (numberOfScheduleBasalRates > 0)
			{
				var scheduledBasalOffset:Number = !CGMBlueToothDevice.isFollower() ? (Constants.systemTimeZoneOffset * TimeSpan.TIME_1_HOUR) : (Constants.systemTimeZoneOffset * TimeSpan.TIME_1_HOUR) - ((NightscoutService.hostTimezoneOffset + Constants.systemTimeZoneOffset) * TimeSpan.TIME_1_HOUR);
				var scheduledBasalTimeSpan:TimeSpan = TimeSpan.fromMilliseconds(time - scheduledBasalOffset);
				var scheduledBasalTimeSpanHours:int = scheduledBasalTimeSpan.hours;
				var scheduledBasalTimeSpanMinutes:int = scheduledBasalTimeSpan.minutes;
				
				for (var i:int = numberOfScheduleBasalRates - 1 ; i >= 0; i--)
				{
					var basalRate:BasalRate = basalRatesList[i];
					if (basalRate != null && (scheduledBasalTimeSpanHours > basalRate.startHours || (scheduledBasalTimeSpanHours == basalRate.startHours && scheduledBasalTimeSpanMinutes >= basalRate.startMinutes)))
					{
						scheduledBasalRate = basalRate.basalRate;
						break;
					}
				}
			}
			
			return scheduledBasalRate;
		}
		
		public static function getPumpBasalData(time:Number, isFollower:Boolean, suggestedIndex:Number = Number.NaN, basalsSource:Array = null):Object
		{
			//Common Variables
			var i:int;
			var sourceForBasals:Array = basalsSource != null ? basalsSource : TreatmentsManager.basalsList;
			
			//Basal Rate
			var scheduledBasalRate:Number = 0;
			var numberOfScheduleBasalRates:uint = basalRatesList.length;
			
			if (numberOfScheduleBasalRates > 0)
			{
				var scheduledBasalOffset:Number = !isFollower ? (Constants.systemTimeZoneOffset * TimeSpan.TIME_1_HOUR) : (Constants.systemTimeZoneOffset * TimeSpan.TIME_1_HOUR) - ((NightscoutService.hostTimezoneOffset + Constants.systemTimeZoneOffset) * TimeSpan.TIME_1_HOUR);
				var scheduledBasalTimeSpan:TimeSpan = TimeSpan.fromMilliseconds(time - scheduledBasalOffset);
				var scheduledBasalTimeSpanHours:int = scheduledBasalTimeSpan.hours;
				var scheduledBasalTimeSpanMinutes:int = scheduledBasalTimeSpan.minutes;
				
				for (i = numberOfScheduleBasalRates - 1 ; i >= 0; i--)
				{
					var basalRate:BasalRate = basalRatesList[i];
					if (basalRate != null
						&&
						(scheduledBasalTimeSpanHours > basalRate.startHours
						||
						(scheduledBasalTimeSpanHours == basalRate.startHours && scheduledBasalTimeSpanMinutes >= basalRate.startMinutes))
					)
					{
						scheduledBasalRate = basalRate.basalRate;
						break;
					}
				}
			}
			
			//Temp Basal
			var tempBasalAreaAmount:Number = 0;
			var tempBasalAmount:Number = scheduledBasalRate;
			var tempBasalTreatment:Treatment = null;
			var tempBasalIndex:Number = suggestedIndex;
			var tempBasalTime:Number = time;
			var numberOfBasals:Number = sourceForBasals.length;
			
			if (numberOfBasals > 0)
			{
				var loopStart:int = isNaN(suggestedIndex) ? numberOfBasals - 1 : suggestedIndex;
				for (i = loopStart ; i >= 0; i--)
				{
					var tempBasalInternalTreatment:Treatment = sourceForBasals[i];
					if (tempBasalInternalTreatment != null 
						&& 
						tempBasalInternalTreatment.type == Treatment.TYPE_TEMP_BASAL
						&&
						tempBasalInternalTreatment.timestamp <= time 
						&& 
						tempBasalInternalTreatment.timestamp + (tempBasalInternalTreatment.basalDuration * TimeSpan.TIME_1_MINUTE) >= time
					)
					{
						tempBasalTreatment = tempBasalInternalTreatment;
						tempBasalTime = tempBasalInternalTreatment.timestamp;
						tempBasalIndex = i;
						
						break;
					}
				}
				
				//Special handling for absolute to support temp to 0
				if (tempBasalTreatment != null && tempBasalTreatment.isBasalAbsolute && tempBasalTreatment.basalDuration > 0) 
				{
					tempBasalAreaAmount = tempBasalTreatment.basalAbsoluteAmount;
					tempBasalAmount = tempBasalAreaAmount;
				} 
				else if (tempBasalTreatment != null && tempBasalTreatment.isBasalRelative) 
				{
					tempBasalAreaAmount = scheduledBasalRate * (100 + tempBasalTreatment.basalPercentAmount) / 100;
					tempBasalAmount = tempBasalAreaAmount;
				}
			}
			
			if (tempBasalAreaAmount < 0) tempBasalAreaAmount = 0;
			if (tempBasalAmount < 0) tempBasalAmount = 0;
			
			//
			if (tempBasalTreatment != null)
			{
				totalDeliveredPumpBasalAmount += tempBasalAmount / tempBasalTreatment.basalDuration;
			}
			else
			{
				totalDeliveredPumpBasalAmount += scheduledBasalRate / 60;
			}
			
			//Result
			return {
				scheduledBasalRate: scheduledBasalRate,
				tempBasalAreaAmount: tempBasalAreaAmount,
				tempBasalAmount: tempBasalAmount,
				tempBasalTime: tempBasalTime,
				tempBasalIndex: tempBasalIndex,
				tempBasalTreatment: tempBasalTreatment
			};
		}
		
		public static function getMDIBasalData(time:Number, sourceForBasals:Array = null):Object
		{
			if (sourceForBasals == null)
			{
				sourceForBasals = TreatmentsManager.basalsList;
			}
			
			//Temp Basal
			var mdiBasalAmount:Number = 0;
			var mdiBasalDuration:Number = 0;
			var mdiBasalTreatment:Treatment = null;
			var mdiBasalTreatmentsList:Array = [];
			var mdiBasalTime:Number = time;
			var hasOverlap:Boolean = false;
			var numberOfBasals:Number = sourceForBasals.length;
			
			if (numberOfBasals > 0)
			{
				for (var i:int = numberOfBasals ; i >= 0; i--)
				{
					var mdiBasalInternalTreatment:Treatment = sourceForBasals[i];
					if (mdiBasalInternalTreatment != null 
						&&
						mdiBasalInternalTreatment.type == Treatment.TYPE_MDI_BASAL
						&& 
						mdiBasalInternalTreatment.timestamp <= time 
						&& 
						mdiBasalInternalTreatment.timestamp + (mdiBasalInternalTreatment.basalDuration * TimeSpan.TIME_1_MINUTE) >= time
					)
					{
						mdiBasalAmount += mdiBasalInternalTreatment.basalAbsoluteAmount;
						if (mdiBasalTreatment == null)
						{
							mdiBasalTreatment = mdiBasalInternalTreatment;
							mdiBasalTime = mdiBasalInternalTreatment.timestamp;
							mdiBasalDuration = mdiBasalInternalTreatment.basalDuration;
						}
						else
						{
							hasOverlap = true;
							mdiBasalDuration = ((mdiBasalInternalTreatment.timestamp + (mdiBasalInternalTreatment.basalDuration * TimeSpan.TIME_1_MINUTE)) - mdiBasalTreatment.timestamp) / TimeSpan.TIME_1_MINUTE;
						}
						
						mdiBasalTreatmentsList.push(mdiBasalInternalTreatment);
					}
				}
			}
			
			if (mdiBasalAmount < 0) mdiBasalAmount = 0;
			
			return {
				mdiBasalAmount: mdiBasalAmount,
				mdiBasalDuration: mdiBasalDuration,
				mdiBasalTime: mdiBasalTime,
				mdiBasalTreatment: mdiBasalTreatment,
				mdiBasalTreatmentsList: mdiBasalTreatmentsList,
				hasOverlap: hasOverlap
			};
		}
		
		public static function clearAllBasalRates():void
		{
			basalRatesList.length = 0;
			basalRatesMap = new Dictionary();
			basalRatesMapByTime = {};
		}
		
		/**
		 * INSULINS
		 */
		public static function getInsulin(ID:String):Insulin
		{
			return insulinsMap[ID];
		}
		
		public static function addInsulin(name:String, 
										  dia:Number, 
										  type:String, 
										  isDefault:Boolean = false, 
										  insulinID:String = null, 
										  saveToDatabase:Boolean = true, 
										  isHidden:Boolean = false, 
										  curve:String = "bilinear", 
										  peak:Number = 75, 
										  overwrite:Boolean = false):void
		{
			Trace.myTrace("ProfileManager.as", "addInsulin called!");
			
			//Generate insulin ID
			var newInsulinID:String = insulinID == null ? UniqueId.createEventId() : insulinID;
			
			//Check duplicates
			if (insulinsMap[newInsulinID] != null && insulinID != "000000" && overwrite)
			{
				var existingInsulin:Insulin = insulinsMap[newInsulinID];
				existingInsulin.curve = curve;
				existingInsulin.dia = dia;
				existingInsulin.isDefault = isDefault;
				existingInsulin.isHidden = isHidden;
				existingInsulin.name = name;
				existingInsulin.peak = peak;
				existingInsulin.type = type;
				
				updateInsulin(existingInsulin, saveToDatabase);
				
				return;
			}
			
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
			
			var isFollower:Boolean = CGMBlueToothDevice.isFollower();
			var insulinID:String = "";
			var foundDefault:Boolean = false;
			var i:int = 0;
			var insulin:Insulin;
			var allInsulinTypes:Array = ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','insulin_types_list').split(",");
			var longActing:String = StringUtil.trim(allInsulinTypes[4]);
			
			insulinsList.sortOn(["name"], Array.CASEINSENSITIVE);
			
			for (i = 0; i < insulinsList.length; i++) 
			{
				insulin = insulinsList[i];
				if (insulin.isDefault && insulin.type != longActing && (isFollower || (!isFollower && !insulin.isHidden)))
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
		
		public static function getBasalInsulin():Insulin
		{
			Trace.myTrace("ProfileManager.as", "getBasalInsulin called!");
			
			var matchedInsulin:Insulin;
			var allInsulinTypes:Array = ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','insulin_types_list').split(",");
			var longActing:String = StringUtil.trim(allInsulinTypes[4]);
			
			insulinsList.sortOn(["timestamp"], Array.NUMERIC | Array.DESCENDING);
			
			for (var i:int = 0; i < insulinsList.length; i++) 
			{
				var insulin:Insulin = insulinsList[i];
				if (insulin.type == longActing)
				{
					matchedInsulin = insulin;
					break;
				}
			}
			
			return matchedInsulin;
		}
		
		/**
		 * CARBS
		 */
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
	}
}