package treatments
{
	import com.adobe.utils.DateUtil;
	import com.adobe.utils.StringUtil;
	import com.hurlant.util.Base64;
	import com.spikeapp.spike.airlibrary.SpikeANE;
	
	import flash.events.EventDispatcher;
	import flash.system.System;
	import flash.text.SoftKeyboardType;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.setTimeout;
	
	import mx.utils.ObjectUtil;
	
	import database.BgReading;
	import database.CGMBlueToothDevice;
	import database.Calibration;
	import database.CommonSettings;
	import database.Database;
	import database.Sensor;
	
	import events.CalibrationServiceEvent;
	import events.SettingsServiceEvent;
	import events.SpikeEvent;
	import events.TreatmentsEvent;
	
	import feathers.controls.Button;
	import feathers.controls.Callout;
	import feathers.controls.Check;
	import feathers.controls.DateTimeSpinner;
	import feathers.controls.Label;
	import feathers.controls.LayoutGroup;
	import feathers.controls.NumericStepper;
	import feathers.controls.PickerList;
	import feathers.controls.Radio;
	import feathers.controls.ScrollBarDisplayMode;
	import feathers.controls.ScrollContainer;
	import feathers.controls.ScrollPolicy;
	import feathers.controls.TextInput;
	import feathers.controls.popups.DropDownPopUpContentManager;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.core.ToggleGroup;
	import feathers.data.ArrayCollection;
	import feathers.events.FeathersEventType;
	import feathers.layout.Direction;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.HorizontalLayout;
	import feathers.layout.TiledRowsLayout;
	import feathers.layout.VerticalAlign;
	import feathers.layout.VerticalLayout;
	
	import model.ModelLocator;
	
	import services.CalibrationService;
	import services.NightscoutService;
	
	import starling.animation.Transitions;
	import starling.animation.Tween;
	import starling.core.Starling;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.ResizeEvent;
	import starling.utils.SystemUtil;
	
	import treatments.food.Food;
	import treatments.food.ui.FoodManager;
	
	import ui.AppInterface;
	import ui.popups.AlertManager;
	import ui.screens.Screens;
	import ui.screens.display.LayoutFactory;
	
	import utils.Constants;
	import utils.DeviceInfo;
	import utils.TimeSpan;
	import utils.Trace;
	import utils.UniqueId;
	
	[ResourceBundle("treatments")]
	[ResourceBundle("globaltranslations")]

	public class TreatmentsManager extends EventDispatcher
	{
		/* Instance */
		private static var _instance:TreatmentsManager = new TreatmentsManager();
		
		/* Internal objects */
		public static var treatmentsList:Array = [];
		public static var treatmentsMap:Dictionary = new Dictionary();
		public static var basalsList:Array = [];
		public static var basalsMap:Dictionary = new Dictionary();
		
		/* Internal Properties */
		private static const MAX_IOB_COB_CACHED_ITEMS:int = 30;
		public static var pumpIOB:Number = 0;
		public static var pumpCOB:Number = 0;
		public static var nightscoutTreatmentsLastModifiedHeader:String = "";
		private static var foodManager:FoodManager;
		private static var IOBCache:Object = {};
		private static var IOBCacheTimes:Array = [];
		private static var COBCache:Object = {};
		private static var COBCacheTimes:Array = [];
		private static var lastSavedCachesTimestamp:Number = 0;
		private static var mostRecentIOBCaches:Array = [];
		
		/* Domension Variables */
		private static var contentOriginalHeight:Number;
		private static var suggestedCalloutHeight:Number;
		private static var finalCalloutHeight:Number;
		private static var treatmentCallOutWidth:Number;
		private static var treatmentCallOutHeight:Number;
		private static var treatmentCallOutPaddingRight:Number;
		private static var contentScrollContainerWidth:Number;
		private static var contentScrollContainerHeight:Number;
		private static var totalScrollContainerWidth:Number;
		private static var totalScrollContainerHeight:Number;
		private static var yPos:Number;

		//Treatments callout display objects
		private static var treatmentInserterContainer:LayoutGroup;
		private static var treatmentInserterTitleLabel:Label;
		private static var insulinTextInput:TextInput;
		private static var insulinSpacer:Sprite;
		private static var glucoseTextInput:TextInput;
		private static var glucoseSpacer:Sprite;
		private static var carbsTextInput:TextInput;
		private static var carbSpacer:Sprite;
		private static var noteSpacer:Sprite;
		private static var treatmentTime:DateTimeSpinner;
		private static var treatmentSpacer:Sprite;
		private static var otherFieldsContainer:LayoutGroup;
		private static var insulinList:PickerList;
		private static var createInsulinButton:Button;
		private static var notes:TextInput;
		private static var actionContainer:LayoutGroup;
		private static var cancelButton:Button;
		private static var addButton:Button;
		private static var calloutPositionHelper:Sprite;
		private static var treatmentCallout:Callout;
		private static var extendedCarbContainer:LayoutGroup;
		private static var carbOffSet:NumericStepper;
		private static var carbOffsetSuffix:Label;
		private static var carbDelayContainer:LayoutGroup;
		private static var fastCarb:Radio;
		private static var mediumCarb:Radio;
		private static var slowCarb:Radio;
		private static var carbDelayGroup:ToggleGroup;
		private static var foodManagerButton:Button;
		private static var foodManagerContainer:LayoutGroup;
		private static var totalScrollContainer:ScrollContainer;
		private static var contentScrollContainer:ScrollContainer;
		private static var extendedBolusMainContainer:LayoutGroup;
		private static var extendedBolusCheck:Check;
		private static var firstSplitNumericStepper:NumericStepper;
		private static var firstSplitLabel:Label;
		private static var extendedBolusSplitContainer1:LayoutGroup;
		private static var extendedBolusSplitContainer2:LayoutGroup;
		private static var lastSplitLabel:Label;
		private static var lastSplitNumericStepper:NumericStepper;
		private static var extendedDurationNumericStepper:NumericStepper;
		private static var extendedBolusDurationContainer:LayoutGroup;
		private static var extendedDurationLabel:Label;
		private static var exerciseDurationTextInput:TextInput;
		private static var exerciseChangerSpacer:Sprite;
		private static var exerciseIntensityContainer:LayoutGroup;
		private static var exerciseIntensityGroup:ToggleGroup;
		private static var lowIntensity:Radio;
		private static var moderateIntensity:Radio;
		private static var highIntendity:Radio;
		private static var basalDurationTextInput:TextInput;
		private static var basalDurationSpacer:Sprite;
		private static var basalModeGroup:ToggleGroup;
		private static var basalAbsoluteRadio:Radio;
		private static var basalRelativeRadio:Radio;
		private static var basalModeContainer:LayoutGroup;
		
		public function TreatmentsManager()
		{
			if (_instance != null)
				throw new Error("TreatmentsManager is not meant to be instantiated!");
		}
		
		public static function init():void
		{
			Trace.myTrace("TreatmentsManager.as", "init called!");
			
			//Event Listeners
			CalibrationService.instance.addEventListener(CalibrationServiceEvent.INITIAL_CALIBRATION_EVENT, onCalibrationReceived);
			CalibrationService.instance.addEventListener(CalibrationServiceEvent.NEW_CALIBRATION_EVENT, onCalibrationReceived);
			CommonSettings.instance.addEventListener(SettingsServiceEvent.SETTING_CHANGED, onSettingChanged);
			Spike.instance.addEventListener(SpikeEvent.APP_IN_FOREGROUND, onAppInForeground, false, 10000, true);
			
			//Fetch Data From Database
			fetchAllTreatmentsFromDatabase();
			
			//Fetch IOB/COB Caches
			fetchIOBCOBCaches();
			
			//Delete Old Teatments
			Database.deleteOldTreatments();
		}
		
		private static function fetchIOBCOBCaches():void
		{
			Trace.myTrace("TreatmentsManager.as", "Fetching IOB/COB caches from database...");
			
			var databaseCachesList:Array = Database.getIOBCOBCachesSynchronous();
			
			if (databaseCachesList.length == 0)
			{
				//Add empty caches
				Database.insertEmptyIOBCOBCaches();
			}
			else
			{
				//Unserialize saved caches
				var databaseCaches:Object = databaseCachesList[0];
				if (databaseCaches != null && databaseCaches.cob != null && databaseCaches.cobindexes != null && databaseCaches.iob != null && databaseCaches.iobindexes != null)
				{
					try
					{
						COBCache = Base64.decodeToByteArray(databaseCaches.cob).readObject() as Object;
						COBCacheTimes = Base64.decodeToByteArray(databaseCaches.cobindexes).readObject() as Array;
					} 
					catch(error:Error) 
					{
						//Something went wrong try to add default empty caches again and 
						//Set caches in memory to default values
						COBCache = {};
						COBCacheTimes = [];
						
						//Add default empty caches to database
						Database.deleteAllIOBCOBCachesSynchronous();
						Database.insertEmptyIOBCOBCaches();
					}
				}
				else
				{
					//Something went wrong try to add default empty caches again and 
					//Set caches in memory to default values
					COBCache = {};
					COBCacheTimes = [];
					
					//Add default empty caches to database
					Database.deleteAllIOBCOBCachesSynchronous();
					Database.insertEmptyIOBCOBCaches();
				}
			}
		}
		
		private static function onAppInForeground(e:SpikeEvent):void
		{
			setTimeout(saveIOBCOBCache, TimeSpan.TIME_2_SECONDS);
		}
		
		private static function saveIOBCOBCache():void
		{
			if (!SystemUtil.isApplicationActive)
			{
				return;
			}
			
			var now:Number = new Date().valueOf();
			if (now - lastSavedCachesTimestamp < TimeSpan.TIME_2_HOURS)
			{
				//Only save caches every 2 hours or so. Abort!
				return;
			}
			
			var numberOfCaches:uint = COBCacheTimes.length;
			if (numberOfCaches == 0)
			{
				//Nothing to save
				return;
			}
			
			try
			{
				//Sort indexes
				COBCacheTimes.sort(Array.NUMERIC | Array.DESCENDING);
				
				//Define time limit (24h ago)
				var twentyFourHoursAgo:Number = now - TimeSpan.TIME_24_HOURS;
				
				//Loop through all caches and remove the old ones (>24h)
				for(var i:int = numberOfCaches - 1 ; i >= 0; i--)
				{
					var cacheTime:Number = COBCacheTimes[i];
					
					if (cacheTime < twentyFourHoursAgo)
					{
						//Remove the index
						COBCacheTimes.pop(); 
						
						//Remove the corresponding cache
						delete COBCache[cacheTime];
					}
					else
					{
						//We've removed all outdated caches already.
						break;
					}
				}
				
				//Serialize Caches
				//COB
				var COBCachedBytes:ByteArray = new ByteArray();
				COBCachedBytes.writeObject(COBCache);
				var COBCachedBytesString:String = Base64.encodeByteArray(COBCachedBytes);
				
				var COBCachedTimesBytes:ByteArray = new ByteArray();
				COBCachedTimesBytes.writeObject(COBCacheTimes);
				var COBCachedTimesBytesString:String = Base64.encodeByteArray(COBCachedTimesBytes);
				
				//IOB
				var IOBCachedBytes:ByteArray = new ByteArray();
				IOBCachedBytes.writeObject(IOBCache);
				var IOBCachedBytesString:String = Base64.encodeByteArray(IOBCachedBytes);
				
				var IOBCachedTimesBytes:ByteArray = new ByteArray();
				IOBCachedTimesBytes.writeObject(IOBCacheTimes);
				var IOBCachedTimesBytesString:String = Base64.encodeByteArray(IOBCachedTimesBytes);
				
				Database.updateIOBCOBCachesSynchronous(IOBCachedBytesString, IOBCachedTimesBytesString, COBCachedBytesString, COBCachedTimesBytesString);
				
				lastSavedCachesTimestamp = now;
				
				Trace.myTrace("TreatmentsManager.as", "Saved IOB/COB caches to database...");
			} 
			catch(error:Error) {}
		}
		
		public static function clearAllCaches():void
		{
			//Clear caches internally
			IOBCache = {};
			IOBCacheTimes = [];
			COBCache = {};
			COBCacheTimes = [];
			
			//Serialize Caches
			//COB
			var COBCachedBytes:ByteArray = new ByteArray();
			COBCachedBytes.writeObject(COBCache);
			var COBCachedBytesString:String = Base64.encodeByteArray(COBCachedBytes);
			
			var COBCachedTimesBytes:ByteArray = new ByteArray();
			COBCachedTimesBytes.writeObject(COBCacheTimes);
			var COBCachedTimesBytesString:String = Base64.encodeByteArray(COBCachedTimesBytes);
			
			//IOB
			var IOBCachedBytes:ByteArray = new ByteArray();
			IOBCachedBytes.writeObject(IOBCache);
			var IOBCachedBytesString:String = Base64.encodeByteArray(IOBCachedBytes);
			
			var IOBCachedTimesBytes:ByteArray = new ByteArray();
			IOBCachedTimesBytes.writeObject(IOBCacheTimes);
			var IOBCachedTimesBytesString:String = Base64.encodeByteArray(IOBCachedTimesBytes);
			
			//Save them to the database
			Database.updateIOBCOBCachesSynchronous(IOBCachedBytesString, IOBCachedTimesBytesString, COBCachedBytesString, COBCachedTimesBytesString);
			
			//Update internal variables
			lastSavedCachesTimestamp = new Date().valueOf();
			
			Trace.myTrace("TreatmentsManager.as", "All internal caches have been cleared by user request!");
		}
		
		public static function fetchAllTreatmentsFromDatabase():void
		{
			if (!CGMBlueToothDevice.isFollower() || ModelLocator.INTERNAL_TESTING)
			{
				Trace.myTrace("TreatmentsManager.as", "Fetching treatments from database...");
				
				var now:Number = new Date().valueOf();
				var i:int;
				
				//Treatments
				treatmentsList.length = 0;
				var dbTreatments:Array = Database.getTreatmentsSynchronous(now - TimeSpan.TIME_24_HOURS, now + TimeSpan.TIME_24_HOURS);
				
				if (dbTreatments != null && dbTreatments.length > 0)
				{
					for (i = 0; i < dbTreatments.length; i++) 
					{
						var dbTreatment:Object = dbTreatments[i] as Object;
						if (dbTreatment == null)
							continue;
						
						var treatment:Treatment = new Treatment
						(
							dbTreatment.type,
							dbTreatment.lastmodifiedtimestamp,
							dbTreatment.insulinamount,
							dbTreatment.insulinid,
							dbTreatment.carbs,
							dbTreatment.glucose,
							dbTreatment.glucoseestimated,
							dbTreatment.note,
							null,
							dbTreatment.carbdelay
						);
						
						treatment.ID = dbTreatment.id;
						
						if (dbTreatment.needsadjustment != null && dbTreatment.needsadjustment == "true")
						{
							treatment.needsAdjustment = true;
						}
						if (dbTreatment.children != null && String(dbTreatment.children) != "")
						{
							treatment.parseChildren(String(dbTreatment.children));
						}
						if (dbTreatment.prebolus != null && !isNaN(dbTreatment.prebolus))
						{
							treatment.preBolus = Number(dbTreatment.prebolus);
						}
						if (dbTreatment.duration != null && !isNaN(dbTreatment.duration))
						{
							treatment.duration = Number(dbTreatment.duration);
						}
						if (dbTreatment.intensity != null && String(dbTreatment.intensity) != "")
						{
							treatment.exerciseIntensity = String(dbTreatment.intensity);
						}
						
						treatmentsList.push(treatment);
						treatmentsMap[treatment.ID] = treatment;
					}
					
					//Sort Treatments
					treatmentsList.sortOn(["timestamp"], Array.NUMERIC);
					
					Trace.myTrace("TreatmentsManager.as", "Fetched " + treatmentsList.length + " treatment(s)");
				}
				
				//Basals
				basalsList.length = 0;
				var dbBasals:Array = Database.getBasalsSynchronous(now - TimeSpan.TIME_24_HOURS, now + TimeSpan.TIME_24_HOURS);
				
				if (dbBasals != null && dbBasals.length > 0)
				{
					for (i = 0; i < dbBasals.length; i++) 
					{
						var dbBasal:Object = dbBasals[i] as Object;
						if (dbBasal == null)
							continue;
						
						var basal:Treatment = new Treatment
						(
							dbBasal.type,
							dbBasal.lastmodifiedtimestamp,
							dbBasal.insulinamount,
							dbBasal.insulinid,
							dbBasal.carbs,
							dbBasal.glucose,
							dbBasal.glucoseestimated,
							dbBasal.note,
							null,
							dbBasal.carbdelay
						);
						
						basal.ID = dbBasal.id;
						basal.isBasalAbsolute = dbBasal.isbasalabsolute != null && dbBasal.isbasalabsolute == "true";
						basal.isBasalRelative = dbBasal.isbasalrelative != null && dbBasal.isbasalrelative == "true";
						basal.basalDuration = dbBasal.basalduration != null && !isNaN(dbBasal.basalduration) ? dbBasal.basalduration : 0;
						basal.isTempBasalEnd = dbBasal.istempbasalend != null && dbBasal.istempbasalend == "true";
						basal.basalAbsoluteAmount = dbBasal.basalabsoluteamount != null && !isNaN(dbBasal.basalabsoluteamount) ? dbBasal.basalabsoluteamount : 0;
						basal.basalPercentAmount = dbBasal.basalpercentamount != null && !isNaN(dbBasal.basalpercentamount) ? dbBasal.basalpercentamount : 0;
						
						basalsList.push(basal);
						basalsMap[basal.ID] = basal;
					}
					
					//Sort Treatments
					basalsList.sortOn(["timestamp"], Array.NUMERIC);
					
					Trace.myTrace("TreatmentsManager.as", "Fetched " + basalsList.length + " basal(s)");
				}
			}
		}
		
		private static function onSettingChanged(e:SettingsServiceEvent):void
		{
			if (e.data == CommonSettings.COMMON_SETTING_CURRENT_SENSOR && Sensor.getActiveSensor() != null && !NightscoutService.serviceActive )
			{
				addInternalSensorStartTreatment(Sensor.getActiveSensor().startedAt, UniqueId.createEventId());
			}
		}
		
		private static function onCalibrationReceived(e:CalibrationServiceEvent):void 
		{
			//Ensures compatibility with the new method of only one initial calibration
			if (Calibration.allForSensor().length == 1) 
				return;
			
			//No need to do anything. Nightscout service will take care of it
			if (NightscoutService.serviceActive) 
				return;
			
			Trace.myTrace("TreatmentsManager.as", "onCalibrationReceived called! Creating new calibration treatment.");
			
			//Add calibration treatment to Spike
			var lastCalibration:Calibration = Calibration.last();
			TreatmentsManager.addInternalCalibrationTreatment(lastCalibration.bg, lastCalibration.timestamp, lastCalibration.uniqueId);
		}
		
		public static function getTotalIOB(time:Number):Object
		{
			//OpenAPS/Loop Nightscout Support. Return value fetched from NS.
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_LOOP_OPENAPS_USER_ENABLED) == "true")
			{
				return { time: time, activity: 0, iob: pumpIOB, bolusiob: pumpIOB, bolusinsulin: Number.NaN, firstInsulinTime: Number.NaN };
			}
			
			//Algorithm
			var algorithm:String = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEFAULT_IOB_COB_ALGORITHM);
			
			//Cache Time
			var requestedDate:Date = new Date(time);
			requestedDate.milliseconds = 0;
			var cacheTime:Number = requestedDate.valueOf();
			
			//Sort Treatments
			treatmentsList.sortOn(["timestamp"], Array.NUMERIC);
			
			//Get relevant treatments
			var insulinWindow:Number = time - TimeSpan.TIME_8_HOURS;
			var relevantTreatmentsHash:String = "";
			var relevantTreatmentsList:Array = treatmentsList.filter
				(
					function (treatment:Treatment, index:int, arr:Array):Boolean 
					{
						//Consider treatments that contain insulin from up to 8 hours ago
						var validated:Boolean = treatment != null && treatment.insulinAmount > 0 && treatment.timestamp > insulinWindow && treatment.timestamp <= time;
						
						if (validated)
						{
							relevantTreatmentsHash += treatment.timestamp + treatment.insulinAmount + treatment.dia + treatment.insulinID;
						}
						
						return validated;
					}
				);
			
			//Check first layer of caching
			var cachedIOBFirstLayer:Object = IOBCache[cacheTime];
			if (cachedIOBFirstLayer != null && cachedIOBFirstLayer.hash == relevantTreatmentsHash && cachedIOBFirstLayer.algorithm == algorithm)
			{
				//We have a cached data point. Return it instead of performing real calulations
				return cachedIOBFirstLayer.iobCalc;
			}
			
			//Check second layer of caching
			for(var i:int = mostRecentIOBCaches.length - 1 ; i >= 0; i--)
			{
				var mostRecentIOBCache:Number = mostRecentIOBCaches[i];
				
				if (Math.abs(cacheTime - mostRecentIOBCache) < TimeSpan.TIME_5_SECONDS )
				{
					var cachedIOBSecondLayer:Object = IOBCache[mostRecentIOBCache];
					if (cachedIOBSecondLayer != null && cachedIOBSecondLayer.hash == relevantTreatmentsHash && cachedIOBSecondLayer.algorithm == algorithm)
					{
						//We have a cached data point. Return it instead of performing real calulations
						return cachedIOBSecondLayer.iobCalc;
					}
					
					break;
				}
			}
			
			var result:Object;
			
			if (algorithm == "nightscout")
			{
				//Get calculations
				result = getTotalIOBNightscout(time, relevantTreatmentsList);
				
				//Cache them
				IOBCache[cacheTime] = { hash: relevantTreatmentsHash, algorithm: algorithm, iobCalc: result };
				IOBCacheTimes.push(cacheTime);
				
				//Update Internal Variables
				saveMostRecentIOBCache(cacheTime);
				
				//Return them
				return result;
			}
			else if (algorithm == "openaps")
			{
				//Get calculations
				result = getTotalIOBOpenAPS(time, relevantTreatmentsList.reverse());
				
				//Cache them
				IOBCache[cacheTime] = { hash: relevantTreatmentsHash, algorithm: algorithm, iobCalc: result };
				IOBCacheTimes.push(cacheTime);
				
				//Update Internal Variables
				saveMostRecentIOBCache(cacheTime);
				
				//Return them
				return result;
			}
			else
			{
				//Get calculations
				result = getTotalIOBNightscout(time, relevantTreatmentsList); //Defaults to Nightscout if everything else fails
				
				//Cache them
				IOBCache[cacheTime] = { hash: relevantTreatmentsHash, algorithm: algorithm, iobCalc: result };
				IOBCacheTimes.push(cacheTime);
				
				//Update Internal Variables
				saveMostRecentIOBCache(cacheTime);
				
				//Return them
				return result;
			}
			
			function saveMostRecentIOBCache(cache:Number):void
			{
				mostRecentIOBCaches.push(cache);
				if (mostRecentIOBCaches.length > 5)
				{
					mostRecentIOBCaches.shift();
				}
			}
		}
		
		public static function getTotalIOBNightscout(time:Number, relevantTreatments:Array):Object
		{
			var totalIOB:Number = 0;
			var totalActivity:Number = 0;
			var totalActivityForecast:Number = 0;
			var bolusInsulin:Number = 0;
			var firstInsulinTreatmentTime:Number = time;
			var numberOfTreatments:uint = relevantTreatments != null ? relevantTreatments.length : 0;
			
			if (numberOfTreatments > 0)
			{
				var currentProfile:Profile = ProfileManager.getProfileByTime(time);
				var isf:Number = Number.NaN;
				if (currentProfile != null)
				{
					isf = Number(currentProfile.insulinSensitivityFactors);
				}
				
				for (var i:int = 0; i < numberOfTreatments; i++) 
				{
					var treatment:Treatment = relevantTreatments[i];
					var treatmentIOBCalc:Object = treatment.calculateIOBNightscout(time, isf);
					if (treatmentIOBCalc != null)
					{
						totalIOB += treatmentIOBCalc.iobContrib;
						totalActivity += treatmentIOBCalc.activityContrib;
						totalActivityForecast += treatmentIOBCalc.activityForecast;
						if (treatmentIOBCalc.iobContrib > 0)
						{
							bolusInsulin += treatment.insulinAmount;
							
							if (treatment.timestamp < firstInsulinTreatmentTime)
							{
								firstInsulinTreatmentTime = treatment.timestamp;
							}
						}
					}
				}
			}
			
			totalIOB = isNaN(totalIOB) ? 0 : Math.floor(totalIOB * 100) / 100;
			
			var results:Object = 
				{
					time: time,
					activity: totalActivity,
					activityForecast: totalActivityForecast,
					iob: totalIOB,
					bolusiob: totalIOB,
					bolusinsulin: bolusInsulin,
					firstInsulinTime: firstInsulinTreatmentTime
				}
			
			return results;
		}
		
		public static function getTotalIOBOpenAPS(time:Number, relevantTreatments:Array):Object
		{
			var now:Number = time;
			var iob:Number = 0;
			var bolusiob:Number = 0;
			var bolusinsulin:Number = 0;
			var activity:Number = 0;
			var firstInsulinTreatmentTime:Number = time;
			
			var numberOfTreatments:int = relevantTreatments.length;
			for (var i:int = 0; i < numberOfTreatments; i++) 
			{
				var treatment:Treatment = relevantTreatments[i];
				
				if (treatment != null && treatment.timestamp < now && treatment.insulinAmount > 0) //Check if treatment is valid and contains insulin otherwise skip it.
				{
					var dia:Number = treatment.dia;
					var dia_ago:Number = now - (dia * TimeSpan.TIME_1_HOUR);
					
					if (treatment.timestamp > dia_ago)
					{
						var tIOB:Object = treatment.calculateIOBOpenAPS(time);
						
						if (tIOB != null)
						{
							if (!isNaN(tIOB.iobContrib))
							{
								iob += tIOB.iobContrib;
								bolusiob += tIOB.iobContrib;
								bolusinsulin += treatment.insulinAmount;
								
								if (tIOB.iobContrib > 0 && treatment.timestamp < firstInsulinTreatmentTime)
								{
									firstInsulinTreatmentTime = treatment.timestamp;
								}
							}
							
							if (!isNaN(tIOB.activityContrib))
							{
								activity += tIOB.activityContrib;
							}
							
							if (!isNaN(tIOB.iobContrib)) 
							{
								bolusiob += tIOB.iobContrib;
								bolusinsulin += treatment.insulinAmount;
							}
						}
					}
				}
			}
			
			var results:Object = 
			{
				time: time,
				activity: Math.round(activity * 10000) / 10000,
				activityForecast: Math.round(activity * 10000) / 10000,
				iob: Math.round(iob * 1000) / 1000,
				bolusiob: Math.round(bolusiob * 1000) / 1000,
				bolusinsulin: Math.round(bolusinsulin * 1000) / 1000,
				firstInsulinTime: firstInsulinTreatmentTime
			}
			
			return results;
		}
		
		public static function setPumpIOB(value:Number):void
		{
			if (isNaN(value))
				value = 0;
			
			pumpIOB = value;
		}
		
		public static function notifyIOBCOB():void
		{
			_instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.IOB_COB_UPDATED));
		}
		
		public static function getTotalCOB(time:Number, useLastBgReadingTimestamp:Boolean = false, isForPredictions:Boolean = false):Object 
		{
			//OpenAPS/Loop Support. Return value fetched from NS.
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_LOOP_OPENAPS_USER_ENABLED) == "true")
			{
				return { time: time, cob: pumpCOB };
			}
			
			//Sort Treatments
			treatmentsList.sortOn(["timestamp"], Array.NUMERIC);
			
			//Adjust time (if needed)
			if (useLastBgReadingTimestamp)
			{
				var lastBgReading:BgReading = BgReading.lastWithCalculatedValue();
				if (lastBgReading != null)
				{
					if (new Date().valueOf() - lastBgReading._timestamp < TimeSpan.TIME_11_MINUTES)
					{
						var canTrimmTime:Boolean = true;
						
						for(var i:int = treatmentsList.length - 1 ; i >= 0; i--)
						{
							var treatment:Treatment = treatmentsList[i];
							if (treatment != null)
							{
								if (treatment.timestamp < lastBgReading._timestamp)
								{
									break;
								}
								
								if (treatment.carbs > 0 && treatment.timestamp > lastBgReading._timestamp)
								{
									canTrimmTime = false
									break;
								}
							}
						}
						
						if (canTrimmTime)
						{
							time = lastBgReading._timestamp;
						}
					}
				}
			}
			
			//Get current algorithm
			var algorithm:String = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEFAULT_IOB_COB_ALGORITHM);
			
			//Get relevant treatments
			var carbWindow:Number = time - TimeSpan.TIME_6_HOURS;
			var relevantTreatmentsHash:String = "";
			var relevantCarbTreatments:Boolean = false;
			var relevantTreatmentsList:Array = treatmentsList.filter
			(
				function (treatment:Treatment, index:int, arr:Array):Boolean 
				{
					//Consider treatments that contain carbs from up to 6 hours ago and insulin from up to treatment's DIA ago 
					var validated:Boolean = false
					
					var carbsValidated:Boolean = treatment.carbs > 0 && treatment.timestamp > carbWindow && treatment.timestamp <= time; 
					if (carbsValidated) 
					{
						relevantCarbTreatments = true;
					}
					
					var insulinValidated:Boolean = treatment.insulinAmount > 0 && treatment.timestamp >= time - treatment.dia && treatment.timestamp <= time;
					
					if (carbsValidated || insulinValidated)
					{
						validated = true;
					}
					
					if (validated)
					{
						relevantTreatmentsHash += treatment.timestamp + treatment.insulinAmount + treatment.dia + treatment.insulinID + treatment.carbs + treatment.carbDelayTime;
					}
					
					return validated;
				}
			);
			
			//If no relevant treatments are found and COB is not meant for predictions, return COB of zero and avoid calculations
			if (!relevantCarbTreatments && !isForPredictions)
			{
				return {
					time: time,
					cob: 0,
					carbs: 0,
					lastCarbTime: 0,
					firstCarbTime: time,
					carbsAbsorbed: 0,
					currentDeviation: Number.NaN,
					maxDeviation: 0,
					minDeviation: 999,
					slopeFromMaxDeviation: 0,
					slopeFromMinDeviation: 999,
					allDeviations: null
				};
			}
			
			//Check cache
			var cachedCOB:Object = COBCache[time];
			if (cachedCOB != null && cachedCOB.hash == relevantTreatmentsHash && cachedCOB.algorithm == algorithm)
			{
				//We have a cached data point. Return it instead of performing real calulations
				return cachedCOB.cobCalc;
			}
			
			//No cached data found. Perform real calculations
			var result:Object;
			var deviations:Object;
			
			if (algorithm == "nightscout")
			{
				//Get calculations
				result = getTotalCOBNightscout(time, relevantTreatmentsList);
				
				//Get Deviations
				if (isForPredictions)
				{
					deviations = calcDeviations(time);
					if (deviations != null)
					{
						result.currentDeviation = deviations.currentDeviation;
						result.maxDeviation = deviations.maxDeviation;
						result.minDeviation = deviations.minDeviation;
						result.slopeFromMaxDeviation = deviations.slopeFromMaxDeviation;
						result.slopeFromMinDeviation = deviations.slopeFromMinDeviation;
						result.allDeviations = deviations.allDeviations;
					}
				}
				
				//Cache them
				COBCache[time] = { hash: relevantTreatmentsHash, algorithm: algorithm, cobCalc: result };
				COBCacheTimes.push(time);
				
				//Return them
				return result;
			}
			else if (algorithm == "openaps")
			{
				//Get calculations
				result = getTotalCOBOpenAPS(time, relevantTreatmentsList.reverse());
				
				//Cache them
				COBCache[time] = { hash: relevantTreatmentsHash, algorithm: algorithm, cobCalc: result };
				COBCacheTimes.push(time);
				
				//Return them
				return result;
			}
			else
			{
				//Get calculations
				result = getTotalCOBNightscout(time, relevantTreatmentsList); //If everything else we default to Nightscout
				
				//Get Deviations
				if (isForPredictions)
				{
					deviations = calcDeviations(time);
					if (deviations != null)
					{
						result.currentDeviation = deviations.currentDeviation;
						result.maxDeviation = deviations.maxDeviation;
						result.minDeviation = deviations.minDeviation;
						result.slopeFromMaxDeviation = deviations.slopeFromMaxDeviation;
						result.slopeFromMinDeviation = deviations.slopeFromMinDeviation;
						result.allDeviations = deviations.allDeviations;
					}
				}
				
				//Cache them
				COBCache[time] = { hash: relevantTreatmentsHash, algorithm: algorithm, cobCalc: result };
				COBCacheTimes.push(time);
				
				//Return them
				return result;
			}
		}
		
		public static function getTotalCOBNightscout(time:Number, relevantTreatments:Array):Object
		{
			var liverSensRatio:int = 8;
			var totalCOB:Number = 0;
			var isDecaying:Number = 0;
			var lastDecayedBy:Number = 0;
			var lastCarbTime:Number = time;
			var activeCarbs:Number = 0;
			var firstCarbTime:Number = time;
			var numberOfTreatments:int = relevantTreatments != null ? relevantTreatments.length : 0;
			
			if (numberOfTreatments > 0)
			{
				var carbsAbsorptionRate:Number = ProfileManager.getCarbAbsorptionRate();
				var currentProfile:Profile = ProfileManager.getProfileByTime(time);
				var isf:Number = Number.NaN;
				var ic:Number = Number.NaN;
				if (currentProfile != null)
				{
					isf = Number(currentProfile.insulinSensitivityFactors);
					ic = Number(currentProfile.insulinToCarbRatios);
				}
				
				for (var i:int = 0; i < numberOfTreatments; i++) 
				{
					var treatment:Treatment = relevantTreatments[i];
					if (treatment != null && treatment.carbs > 0)
					{
						var cCalc:CobCalc = treatment.calculateCOB(lastDecayedBy, time);
						if (cCalc != null)
						{
							var decaysin_hr:Number = (cCalc.decayedBy - time) / 1000 / 60 / 60;
							
							if (decaysin_hr > -10 && !isNaN(isf)) 
							{
								var actStart:Number = 0;
								if (lastDecayedBy != 0)
								{
									actStart = getTotalIOB(lastDecayedBy).activity;
								}
								
								var actEnd:Number = getTotalIOB(cCalc.decayedBy).activity;
								
								var avgActivity:Number = (actStart + actEnd) / 2;
								var delayedCarbs:Number = ( avgActivity *  liverSensRatio / isf ) * ic;
								var delayMinutes:Number = Math.round(delayedCarbs / carbsAbsorptionRate * 60);
								
								if (delayMinutes > 0) 
								{
									cCalc.decayedBy += (delayMinutes * 60 * 1000);
									decaysin_hr = (cCalc.decayedBy - time) / 1000 / 60 / 60;
								}
							}
							
							lastDecayedBy = cCalc.decayedBy;
							
							if (decaysin_hr > 0) 
							{
								var treatmentCOB:Number = Math.min(Number(treatment.carbs), decaysin_hr * carbsAbsorptionRate);
								if (isNaN(treatmentCOB))
									treatmentCOB = 0;
								totalCOB += treatmentCOB;
								isDecaying = cCalc.isDecaying;
								
								if (treatmentCOB > 0)
								{
									lastCarbTime = treatment.timestamp;
									activeCarbs = treatment.carbs;
									
									if (treatment.timestamp < firstCarbTime)
									{
										firstCarbTime = treatment.timestamp;
									}
								}
							} 
							else 
								totalCOB += 0;
						}
						else
							totalCOB += 0;
					}
				}
			}
			
			if (totalCOB < 0 || isNaN(totalCOB))
				totalCOB = 0;
			else
				totalCOB = Math.round(totalCOB * 10) / 10;
			
			var results:Object = 
				{
					time: time,
					cob: totalCOB,
					carbs: activeCarbs,
					lastCarbTime: lastCarbTime,
					firstCarbTime: firstCarbTime,
					carbsAbsorbed: activeCarbs - totalCOB
				}
			
			return results;
		}
		
		public static function getTotalCOBOpenAPS(time:Number, treatments:Array):Object
		{
			var openAPSTreatmentsList:Array = treatments;
			var currentProfile:Profile = ProfileManager.getProfileByTime(time);
			if (currentProfile == null)
			{
				currentProfile = ProfileManager.createDefaultProfile();
			}
			
			var carbs:Number = 0;
			var mealCarbTime:Number = time;
			var lastCarbTime:Number = 0;
			var mealCOB:Number = 0;
			var carbsToRemove:Number = 0;
			var carbsAbsorbed:Number = 0
			var firstActiveCarbTreatmentTime:Number = time;
			var i:int = 0
			
			// We make a copy of all readings and remove the ones that arrived after the desired COB time.
			// This makes the OpenAPS COB algorithm compatible with retro values.
			// We then reverse the array so the last reading comes first. This is to make it compatible with how OpenAPS expects data to be fed.
			var availableReadings:Array = ModelLocator.bgReadings.concat();
			var numAvailableReadings:uint = availableReadings.length;
			for (i = numAvailableReadings - 1 ; i >= 0; i--)
			{
				var readingCandidate:BgReading = availableReadings[i];
				if (readingCandidate != null)
				{
					if (readingCandidate.timestamp > time)
					{
						availableReadings.pop();
					}
					else
						break;
				}
			}
			availableReadings.reverse();
			
			if (numAvailableReadings == 0 || availableReadings[0] == null)
			{
				//No readings or last reading is invalid, return empty COB.
				return {
					time: time,
					cob: mealCOB,
					carbs: carbs,
					lastCarbTime: lastCarbTime,
					firstCarbTime: firstActiveCarbTreatmentTime,
					carbsAbsorbed: carbsAbsorbed,
					currentDeviation: Number.NaN,
					maxDeviation: 0,
					minDeviation: 999,
					slopeFromMaxDeviation: 0,
					slopeFromMinDeviation: 999,
					allDeviations: null
				};
			}
			
			var iob_inputs:Object = 
			{
				profile: currentProfile,
				history: openAPSTreatmentsList
			};
			
			var COB_inputs:Object = 
			{
				glucose_data: availableReadings,
				iob_inputs: iob_inputs,
				mealTime: mealCarbTime
			};
			
			var carbWindow:Number = time - TimeSpan.TIME_6_HOURS;
			
			var numberOfTreatments:int = openAPSTreatmentsList.length;
			for (i = 0; i < numberOfTreatments; i++) 
			{
				var treatment:Treatment = openAPSTreatmentsList[i];
				var treatmentTime:Number = treatment.timestamp;
				
				if (treatment != null && treatment.carbs > 0 && treatment.timestamp > carbWindow && treatment.timestamp <= time) 
				{
					carbs += treatment.carbs;
					COB_inputs.mealTime = treatmentTime;
					lastCarbTime = Math.max(lastCarbTime, treatmentTime);
						
					var myCarbsAbsorbed:Number = calcMealCOB(COB_inputs).carbsAbsorbed;
					carbsAbsorbed += myCarbsAbsorbed;
					var myMealCOB:Number = Math.max(0, carbs - myCarbsAbsorbed);
						
					if (!isNaN(myMealCOB))
					{
						mealCOB = Math.max(mealCOB, myMealCOB);
							
						if (myMealCOB > 0 && treatment.timestamp < firstActiveCarbTreatmentTime)
						{
							firstActiveCarbTreatmentTime = treatment.timestamp;
						}		
					}
						
					if (myMealCOB < mealCOB) 
					{
						carbsToRemove += treatment.carbs;
					} 
					else 
					{
						carbsToRemove = 0;
					}
				}
			}
			
			// only include carbs actually used in calculating COB
			carbs -= carbsToRemove;
			
			// calculate the current deviation and steepest deviation downslope over the last hour
			COB_inputs.ciTime = time;
			
			// set mealTime to 6h ago for Deviation calculations
			COB_inputs.mealTime = time - TimeSpan.TIME_6_HOURS;
			var c:Object = calcMealCOB(COB_inputs);
			
			// if currentDeviation is null or maxDeviation is 0, set mealCOB to 0 for zombie-carb safety
			if (c.currentDeviation == null || isNaN(c.currentDeviation)) 
			{
				Trace.myTrace("TreatmentsManager.as", "Warning: Setting mealCOB to 0 because currentDeviation is null/undefined");
				mealCOB = 0;
			}
			
			if (c.maxDeviation == null || isNaN(c.maxDeviation)) 
			{
				Trace.myTrace("TreatmentsManager.as", "Warning: Setting mealCOB to 0 because maxDeviation is 0 or undefined");
				mealCOB = 0;
			}
			
			var results:Object = 
			{
				time: time,
				cob: Math.round(mealCOB * 10) / 10,
				carbs: Math.round( carbs * 1000 ) / 1000,
				lastCarbTime: lastCarbTime,
				firstCarbTime: firstActiveCarbTreatmentTime,
				carbsAbsorbed: carbsAbsorbed,
				currentDeviation: Math.round( c.currentDeviation * 100 ) / 100,
				maxDeviation: Math.round( c.maxDeviation * 100 ) / 100,
				minDeviation: Math.round( c.minDeviation * 100 ) / 100,
				slopeFromMaxDeviation: Math.round( c.slopeFromMaxDeviation * 1000 ) / 1000,
				slopeFromMinDeviation: Math.round( c.slopeFromMinDeviation * 1000 ) / 1000,
				allDeviations: c.allDeviations
			}
			
			return results;
		}
		
		private static function calcMealCOB(inputs:Object):Object
		{
			var glucose_data:Array = inputs.glucose_data; //BG Readings in descending order
			var iob_inputs:Object = inputs.iob_inputs; //Should hold history (treatments) and current profile
			var profile:Profile = iob_inputs.profile;
			var mealTime:Number = inputs.mealTime;
			var ciTime:Number = inputs.ciTime != null ? inputs.ciTime : Number.NaN;
			
			var avgDeltas:Array = [];
			var bgis:Array = [];
			var deviations:Array = [];
			var deviationSum:Number = 0;
			var carbsAbsorbed:Number = 0;
			var bucketed_data:Array = [];
			bucketed_data[0] = { glucose: glucose_data[0]._calculatedValue, timestamp: glucose_data[0]._timestamp, date: glucose_data[0]._timestamp };
			
			var j:Number = 0;
			var foundPreMealBG:Boolean = false;
			var lastbgi:Number = 0;
			var i:int;
			
			if (bucketed_data[0] == null || bucketed_data[0].glucose == null || isNaN(bucketed_data[0].glucose) || bucketed_data[0].glucose < 39) 
			{
				lastbgi = -1;
			}
			
			var bgTime:Number;
			
			var glucoseDataLength:int = glucose_data.length;
			for (i = 1; i < glucoseDataLength; ++i)
			{
				var bgReading:BgReading = glucose_data[i];
				if (bgReading == null)
					continue;
				
				var bgCalculatedValue:Number = bgReading._calculatedValue;
				if (isNaN(bgCalculatedValue) || bgCalculatedValue < 39) 
				{
					// Skip reading
					continue;
				}
				
				var spikeBgTime:Number = bgReading._timestamp;
				var lastbgTime:Number;
				bgTime = spikeBgTime;
				
				// only consider BGs for 6h after a meal for calculating COB
				var hoursAfterMeal:Number = (bgTime - mealTime) / TimeSpan.TIME_1_HOUR;
				if (isNaN(hoursAfterMeal) || hoursAfterMeal > 6)
				{
					continue;
				} 
				else if (foundPreMealBG)
				{
					break;
				}
				else if (hoursAfterMeal < 0) 
				{
					foundPreMealBG = true;
				}
				
				// only consider last ~45m of data in CI mode
				// this allows us to calculate deviations for the last ~30m
				if (!isNaN(ciTime)) 
				{
					var hoursAgo:Number = (ciTime - bgTime) / TimeSpan.TIME_45_MINUTES;
					if (hoursAgo > 1 || hoursAgo < 0) 
					{
						continue;
					}
				}
				
				var lastBucketedItem:Object = bucketed_data[bucketed_data.length-1];
				if (lastBucketedItem != null && lastBucketedItem.date != null && !isNaN(lastBucketedItem.date)) 
				{
					lastbgTime = lastBucketedItem.date;
				} 
				else if ((lastbgi >= 0) && glucose_data[lastbgi] != null && !isNaN(glucose_data[lastbgi]._timestamp)) 
				{
					lastbgTime = glucose_data[lastbgi]._timestamp;
				} 
				else 
				{ 
					Trace.myTrace("TreatmentsManager.as", "In calcMealCOB, Could not determine last BG time!");
					continue;
				}
				
				var elapsed_minutes:Number = (bgTime - lastbgTime) / TimeSpan.TIME_1_MINUTE;
				if (Math.abs(elapsed_minutes) > 8) 
				{
					// interpolate missing data points
					if (glucose_data[lastbgi] != null)
					{
						var lastbg:Number = glucose_data[lastbgi]._calculatedValue;
						
						// cap interpolation at a maximum of 4h
						elapsed_minutes = Math.min(240,Math.abs(elapsed_minutes));
						
						while(elapsed_minutes > 5) 
						{
							var previousbgTime:Number = lastbgTime - TimeSpan.TIME_5_MINUTES;
							if (!isNaN(previousbgTime) && glucose_data[i] != null)
							{
								j++;
								bucketed_data[j] = {};
								bucketed_data[j].date = previousbgTime;
								bucketed_data[j].timestamp = previousbgTime;
								var gapDelta:Number = glucose_data[i]._calculatedValue - lastbg;
								var previousbg:Number = lastbg + (5/elapsed_minutes * gapDelta);
								bucketed_data[j].glucose = Math.round(previousbg);
								
								lastbg = previousbg;
								lastbgTime = previousbgTime;
							}
							
							elapsed_minutes = elapsed_minutes - 5;
						}
					}
				}
				else if(Math.abs(elapsed_minutes) > 2) 
				{
					if (glucose_data[i] != null)
					{
						j++;
						bucketed_data[j] = { glucose: glucose_data[i]._calculatedValue, timestamp: bgTime, date: bgTime };
					}
				} 
				else 
				{
					if (bucketed_data[j] != null && glucose_data[i] != null)
					{
						bucketed_data[j].glucose = (bucketed_data[j].glucose + glucose_data[i]._calculatedValue) / 2;
					}
				}
				
				lastbgi = i;	
			}
			
			var currentDeviation:Number;
			var slopeFromMaxDeviation:Number = 0;
			var slopeFromMinDeviation:Number = 999;
			var maxDeviation:Number = 0;
			var minDeviation:Number = 999;
			var allDeviations:Array = [];
			var carbImpactPer5Min:Number = ProfileManager.getCarbAbsorptionRate() / 12;
			
			var buckeredDataLength:uint = bucketed_data.length;
			for (i = 0; i < buckeredDataLength - 3; ++i) 
			{
				bgTime = bucketed_data[i].date;
				
				var tempProfile:Profile = ProfileManager.getProfileByTime(bgTime);
				if (tempProfile == null)
				{
					continue;
				}
				
				var sens:Number = Number(tempProfile.insulinSensitivityFactors);
				if (isNaN(sens) || sens == 0)
				{
					continue;
				}
				
				var ic:Number = Number(tempProfile.insulinToCarbRatios);
				if (isNaN(ic) || ic == 0)
				{
					continue;
				}
				
				var bg:Number;
				var avgDelta:Number;
				var delta:Number;
				if (bucketed_data[i] != null && bucketed_data[i].glucose != null && !isNaN(bucketed_data[i].glucose)) 
				{
					bg = bucketed_data[i].glucose;
					if ( bg < 39 || (bucketed_data[i+3] != null && bucketed_data[i+3].glucose < 39) || bucketed_data[i+1] == null || bucketed_data[i+1].glucose == null || isNaN(bucketed_data[i+1].glucose)) 
					{
						continue;
					}
					avgDelta = (bg - bucketed_data[i+3].glucose) / 3;
					delta = (bg - bucketed_data[i+1].glucose);
				} 
				else 
				{ 
					Trace.myTrace("TreatmentsManager.as", "In calcMealCOB. Could not find glucose data!");
					continue;
				}
				
				avgDelta = Number(avgDelta.toFixed(2));
				iob_inputs.clock=bgTime;
				
				var iob:Object =  getTotalIOB(bgTime);
				var bgi:Number = Math.round(( -iob.activity * sens * 5 ) * 100) / 100;
				
				var deviation:Number = delta - bgi;
				deviation = Number(deviation.toFixed(2));
				
				// calculate the deviation right now, for use in min_5m
				if (i == 0) 
				{ 
					currentDeviation = Math.round((avgDelta-bgi) * 1000) / 1000;
					if (ciTime > bgTime) 
					{
						allDeviations.push(Math.round(currentDeviation));
					}
				} 
				else if (ciTime > bgTime) 
				{
					var avgDeviation:Number = Math.round((avgDelta-bgi) * 1000) / 1000;
					var deviationSlope:Number = (avgDeviation-currentDeviation) / (bgTime-ciTime) * TimeSpan.TIME_5_MINUTES;
					
					if (avgDeviation > maxDeviation) 
					{
						slopeFromMaxDeviation = Math.min(0, deviationSlope);
						maxDeviation = avgDeviation;
					}
					if (avgDeviation < minDeviation) 
					{
						slopeFromMinDeviation = Math.max(0, deviationSlope);
						minDeviation = avgDeviation;
					}
					
					allDeviations.push(Math.round(avgDeviation));
				}
				
				// if bgTime is more recent than mealTime
				if(bgTime > mealTime) 
				{	
					// figure out how many carbs that represents
					// if currentDeviation is > 2 * min_5m_carbimpact, assume currentDeviation/2 worth of carbs were absorbed
					// but always assume at least profile.min_5m_carbimpact (carb absorption rate / 12 to get 5min avg) absorption
					var ci:Number = Math.max(deviation, currentDeviation / 2, carbImpactPer5Min);
					var absorbed:Number = ci * ic / sens;	
					
					// and add that to the running total carbsAbsorbed
					carbsAbsorbed += absorbed;
				}
			}
			
			var output:Object = {
				carbsAbsorbed: carbsAbsorbed,
				currentDeviation: currentDeviation,
				maxDeviation: maxDeviation,
				minDeviation: minDeviation,
				slopeFromMaxDeviation: slopeFromMaxDeviation,
				slopeFromMinDeviation: slopeFromMinDeviation,
				allDeviations: allDeviations
			}
				
			return output;
		}
		
		public static function calcDeviations(time:Number):Object
		{
			// We make a copy of all readings and remove the ones that arrived after the desired COB time.
			// This makes the OpenAPS COB algorithm compatible with retro values.
			// We then reverse the array so the last reading comes first. This is to make it compatible with how OpenAPS expects data to be fed.
			var availableReadings:Array = ModelLocator.bgReadings.concat();
			var numAvailableReadings:uint = availableReadings.length;
			for (i = numAvailableReadings - 1 ; i >= 0; i--)
			{
				var readingCandidate:BgReading = availableReadings[i];
				if (readingCandidate != null)
				{
					if (readingCandidate.timestamp > time)
					{
						availableReadings.pop();
					}
					else
						break;
				}
			}
			availableReadings.reverse();
			
			if (numAvailableReadings == 0 || availableReadings[0] == null)
			{
				//No readings or last reading is invalid, return default deviations.
				return {
					time: time,
					currentDeviation: Number.NaN,
					maxDeviation: 0,
					minDeviation: 999,
					slopeFromMaxDeviation: 0,
					slopeFromMinDeviation: 999,
					allDeviations: null
				};
			}
			
			var glucose_data:Array = availableReadings; //BG Readings in descending order
			var mealTime:Number = time - TimeSpan.TIME_6_HOURS;
			var ciTime:Number = time;
			
			var avgDeltas:Array = [];
			var bgis:Array = [];
			var deviations:Array = [];
			var deviationSum:Number = 0;
			var bucketed_data:Array = [];
			bucketed_data[0] = { glucose: glucose_data[0]._calculatedValue, timestamp: glucose_data[0]._timestamp, date: glucose_data[0]._timestamp };
			
			var j:Number = 0;
			var foundPreMealBG:Boolean = false;
			var lastbgi:Number = 0;
			var i:int;
			
			if (bucketed_data[0] == null || bucketed_data[0].glucose == null || isNaN(bucketed_data[0].glucose) || bucketed_data[0].glucose < 39) 
			{
				lastbgi = -1;
			}
			
			var bgTime:Number;
			
			var glucoseDataLength:int = glucose_data.length;
			for (i = 1; i < glucoseDataLength; ++i)
			{
				var bgReading:BgReading = glucose_data[i];
				if (bgReading == null)
					continue;
				
				var bgCalculatedValue:Number = bgReading._calculatedValue;
				if (isNaN(bgCalculatedValue) || bgCalculatedValue < 39) 
				{
					// Skip reading
					continue;
				}
				
				var spikeBgTime:Number = bgReading._timestamp;
				var lastbgTime:Number;
				bgTime = spikeBgTime;
				
				// only consider BGs for 6h after a meal for calculating COB
				var hoursAfterMeal:Number = (bgTime - mealTime) / TimeSpan.TIME_1_HOUR;
				if (isNaN(hoursAfterMeal) || hoursAfterMeal > 6)
				{
					continue;
				} 
				else if (foundPreMealBG)
				{
					break;
				}
				else if (hoursAfterMeal < 0) 
				{
					foundPreMealBG = true;
				}
				
				// only consider last ~45m of data in CI mode
				// this allows us to calculate deviations for the last ~30m
				if (!isNaN(ciTime)) 
				{
					var hoursAgo:Number = (ciTime - bgTime) / TimeSpan.TIME_45_MINUTES;
					if (hoursAgo > 1 || hoursAgo < 0) 
					{
						continue;
					}
				}
				
				var lastBucketedItem:Object = bucketed_data[bucketed_data.length-1];
				if (lastBucketedItem != null && lastBucketedItem.date != null && !isNaN(lastBucketedItem.date)) 
				{
					lastbgTime = lastBucketedItem.date;
				} 
				else if ((lastbgi >= 0) && glucose_data[lastbgi] != null && !isNaN(glucose_data[lastbgi]._timestamp)) 
				{
					lastbgTime = glucose_data[lastbgi]._timestamp;
				} 
				else 
				{ 
					Trace.myTrace("TreatmentsManager.as", "In calcMealCOB. Could not determine last BG time!");
					continue;
				}
				
				var elapsed_minutes:Number = (bgTime - lastbgTime) / TimeSpan.TIME_1_MINUTE;
				if (Math.abs(elapsed_minutes) > 8) 
				{
					// interpolate missing data points
					if (glucose_data[lastbgi] != null)
					{
						var lastbg:Number = glucose_data[lastbgi]._calculatedValue;
						
						// cap interpolation at a maximum of 4h
						elapsed_minutes = Math.min(240,Math.abs(elapsed_minutes));
						
						while(elapsed_minutes > 5) 
						{
							var previousbgTime:Number = lastbgTime - TimeSpan.TIME_5_MINUTES;
							if (!isNaN(previousbgTime) && glucose_data[i] != null)
							{
								j++;
								bucketed_data[j] = {};
								bucketed_data[j].date = previousbgTime;
								bucketed_data[j].timestamp = previousbgTime;
								var gapDelta:Number = glucose_data[i]._calculatedValue - lastbg;
								var previousbg:Number = lastbg + (5/elapsed_minutes * gapDelta);
								bucketed_data[j].glucose = Math.round(previousbg);
								
								lastbg = previousbg;
								lastbgTime = previousbgTime;
							}
							
							elapsed_minutes = elapsed_minutes - 5;
						}
					}
				}
				else if(Math.abs(elapsed_minutes) > 2) 
				{
					if (glucose_data[i] != null)
					{
						j++;
						bucketed_data[j] = { glucose: glucose_data[i]._calculatedValue, timestamp: bgTime, date: bgTime };
					}
				} 
				else 
				{
					if (bucketed_data[j] != null && glucose_data[i] != null)
					{
						bucketed_data[j].glucose = (bucketed_data[j].glucose + glucose_data[i]._calculatedValue) / 2;
					}
				}
				
				lastbgi = i;	
			}
			
			var currentDeviation:Number;
			var slopeFromMaxDeviation:Number = 0;
			var slopeFromMinDeviation:Number = 999;
			var maxDeviation:Number = 0;
			var minDeviation:Number = 999;
			var allDeviations:Array = [];
			
			var buckeredDataLength:uint = bucketed_data.length;
			for (i = 0; i < buckeredDataLength - 3; ++i) 
			{
				bgTime = bucketed_data[i].date;
				
				var sens:Number;
				var tempProfile:Profile = ProfileManager.getProfileByTime(bgTime);
				if (tempProfile == null)
				{
					//Set default insulin sensitivity factor
					sens = 50;
				}
				else
				{
					sens = Number(tempProfile.insulinSensitivityFactors);
					if (isNaN(sens) || sens == 0)
					{
						//Set default insulin sensitivity factor
						sens = 50;
					}
				}
				
				var bg:Number;
				var avgDelta:Number;
				var delta:Number;
				if (bucketed_data[i] != null && bucketed_data[i].glucose != null && !isNaN(bucketed_data[i].glucose)) 
				{
					bg = bucketed_data[i].glucose;
					if ( bg < 39 || (bucketed_data[i+3] != null && bucketed_data[i+3].glucose < 39) || bucketed_data[i+1] == null || bucketed_data[i+1].glucose == null || isNaN(bucketed_data[i+1].glucose)) 
					{
						continue;
					}
					avgDelta = (bg - bucketed_data[i+3].glucose) / 3;
					delta = (bg - bucketed_data[i+1].glucose);
				} 
				else 
				{ 
					Trace.myTrace("TreatmentsManager.as", "In calcMealCOB. Could not find glucose data!");
					continue;
				}
				
				avgDelta = Number(avgDelta.toFixed(2));
				
				var iob:Object =  getTotalIOB(bgTime);
				var bgi:Number = Math.round(( -iob.activityForecast * sens * 5 ) * 100) / 100;
				
				var deviation:Number = delta - bgi;
				deviation = Number(deviation.toFixed(2));
				
				// calculate the deviation right now, for use in min_5m
				if (i == 0) 
				{ 
					currentDeviation = Math.round((avgDelta-bgi) * 1000) / 1000;
					if (ciTime > bgTime) 
					{
						allDeviations.push(Math.round(currentDeviation));
					}
				} 
				else if (ciTime > bgTime) 
				{
					var avgDeviation:Number = Math.round((avgDelta-bgi) * 1000) / 1000;
					var deviationSlope:Number = (avgDeviation-currentDeviation) / (bgTime-ciTime) * TimeSpan.TIME_5_MINUTES;
					
					if (avgDeviation > maxDeviation) 
					{
						slopeFromMaxDeviation = Math.min(0, deviationSlope);
						maxDeviation = avgDeviation;
					}
					if (avgDeviation < minDeviation) 
					{
						slopeFromMinDeviation = Math.max(0, deviationSlope);
						minDeviation = avgDeviation;
					}
					
					allDeviations.push(Math.round(avgDeviation));
				}
			}
			
			var output:Object = {
				currentDeviation: Math.round(currentDeviation * 100) / 100,
				maxDeviation: Math.round(maxDeviation * 100) / 100,
				minDeviation: Math.round(minDeviation * 100) / 100,
				slopeFromMaxDeviation: Math.round(slopeFromMaxDeviation * 1000) / 1000,
				slopeFromMinDeviation: Math.round(slopeFromMinDeviation * 1000) / 1000,
				allDeviations: allDeviations
			};
				
			return output;
		}
		
		public static function getLastCarbTreatment():Treatment
		{
			for(var i:int = treatmentsList.length - 1 ; i >= 0; i--)
			{
				var treatment:Treatment = treatmentsList[i];
				if (treatment.carbs > 0)
					return treatment;
			}
			
			return null;
		}
		
		public static function setPumpCOB(value:Number):void
		{
			if (isNaN(value))
				value = 0;
			
			pumpCOB = value;
		}
		
		public static function deleteTreatment(treatment:Treatment, updateNightscout:Boolean = true, nullifyTreatment:Boolean = true, deleteFromDatabase:Boolean = true, notifyInternally:Boolean = true, notiyExternally:Boolean = false):void
		{
			if (treatment == null) 
				return;
			
			Trace.myTrace("TreatmentsManager.as", "deleteTreatment called!");
			
			var treatmentListSource:Array = treatment.type != Treatment.TYPE_TEMP_BASAL && treatment.type != Treatment.TYPE_MDI_BASAL ? treatmentsList : basalsList;
			var treatmentMapSource:Dictionary = treatment.type != Treatment.TYPE_TEMP_BASAL && treatment.type != Treatment.TYPE_MDI_BASAL ? treatmentsMap : basalsMap;
			
			if (treatmentMapSource[treatment.ID] != null) //treatment exists
			{
				//Delete from Spike
				for (var i:int = treatmentListSource.length - 1 ; i >= 0; i--)
				{
					var spikeTreatment:Treatment = treatmentListSource[i] as Treatment;
					if (treatment.ID == spikeTreatment.ID)
					{
						if (spikeTreatment.type == Treatment.TYPE_EXTENDED_COMBO_BOLUS_PARENT || spikeTreatment.type == Treatment.TYPE_EXTENDED_COMBO_MEAL_PARENT)
						{
							//Delete children
							var numberOfChildren:uint = spikeTreatment.childTreatments.length;
							for (var j:int = 0; j < numberOfChildren; j++) 
							{
								var child:Treatment = treatmentMapSource[spikeTreatment.childTreatments[j]];
								if (child != null)
								{
									deleteTreatment(child, false, true, deleteFromDatabase, notifyInternally, notiyExternally);
								}
							}
						}
						
						Trace.myTrace("TreatmentsManager.as", "Treatment deleted. Type: " + spikeTreatment.type);
						
						treatmentListSource.removeAt(i);
						
						//Notify listeners
						if (notifyInternally)
						{
							if (spikeTreatment.type != Treatment.TYPE_TEMP_BASAL && spikeTreatment.type != Treatment.TYPE_MDI_BASAL)
								_instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.TREATMENT_DELETED, false, false, spikeTreatment));
							
							if (spikeTreatment.type == Treatment.TYPE_TEMP_BASAL || spikeTreatment.type == Treatment.TYPE_MDI_BASAL)
							{
								_instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.NEW_BASAL_DATA));
								_instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.BASAL_TREATMENT_DELETED, false, false, spikeTreatment));
							}
						}
						
						if (notiyExternally)
						{
							if (spikeTreatment.type != Treatment.TYPE_TEMP_BASAL && spikeTreatment.type != Treatment.TYPE_MDI_BASAL)
								_instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.TREATMENT_EXTERNALLY_DELETED, false, false, spikeTreatment));
						}
						
						//Delete from settings
						if (spikeTreatment.type == Treatment.TYPE_INSULIN_CARTRIDGE_CHANGE)
						{
							CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_LAST_INSULIN_CARTRIDGE_CHANGE, "0", true, false);
						}
						else if (spikeTreatment.type == Treatment.TYPE_PUMP_BATTERY_CHANGE)
						{
							CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_PUMP_BATTERY_ON, "0", true, false);
						}
						else if (spikeTreatment.type == Treatment.TYPE_PUMP_SITE_CHANGE)
						{
							CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_LAST_PUMP_SITE_CHANGE, "0", true, false);
						}
						
						//Delete from Nightscout
						if (updateNightscout && (NightscoutService.serviceActive || NightscoutService.followerModeEnabled))
							NightscoutService.deleteTreatment(spikeTreatment);
						
						//Delete from databse
						if ((!CGMBlueToothDevice.isFollower() || ModelLocator.INTERNAL_TESTING) && deleteFromDatabase)
							Database.deleteTreatmentSynchronous(spikeTreatment);
						
						treatmentMapSource[spikeTreatment.ID] = null;
						if (nullifyTreatment) spikeTreatment = null;
						
						break;
					}
				}
			}
		}
		
		public static function updateTreatment(treatment:Treatment, updateNightscout:Boolean = true):void
		{
			if (treatment == null) 
				return;
			
			Trace.myTrace("TreatmentsManager.as", "updateTreatment called! Treatment type: " + treatment.type);
			
			//Update settings
			if (treatment.type == Treatment.TYPE_INSULIN_CARTRIDGE_CHANGE)
			{
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_LAST_INSULIN_CARTRIDGE_CHANGE, String(treatment.timestamp), true, false);
			}
			else if (treatment.type == Treatment.TYPE_PUMP_BATTERY_CHANGE)
			{
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_PUMP_BATTERY_ON, String(treatment.timestamp), true, false);
			}
			else if (treatment.type == Treatment.TYPE_PUMP_SITE_CHANGE)
			{
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_LAST_PUMP_SITE_CHANGE, String(treatment.timestamp), true, false);
			}
			
			//Notify listeners
			if (treatment.type != Treatment.TYPE_TEMP_BASAL && treatment.type != Treatment.TYPE_MDI_BASAL)
				_instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.TREATMENT_UPDATED, false, false, treatment));
			else
			{
				_instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.NEW_BASAL_DATA));
				_instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.BASAL_TREATMENT_UPDATED, false, false, treatment));
			}
			
			//Update in Database
			if (!CGMBlueToothDevice.isFollower() || ModelLocator.INTERNAL_TESTING)
				Database.updateTreatmentSynchronous(treatment);
			
			//Update Nightscout
			if (updateNightscout)
				NightscoutService.uploadTreatment(treatment);
		}
		
		public static function addInternalTreatment(treatment:Treatment, uploadToNightscout:Boolean = false):void
		{	
			Trace.myTrace("TreatmentsManager.as", "addNightscoutTreatment called! Treatment type: " + treatment.type);
			
			//Save settings
			if (treatment.type == Treatment.TYPE_INSULIN_CARTRIDGE_CHANGE)
			{
				if (treatment.timestamp > Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_LAST_INSULIN_CARTRIDGE_CHANGE)))
				{
					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_LAST_INSULIN_CARTRIDGE_CHANGE, String(treatment.timestamp), true, false);
				}
			}
			else if (treatment.type == Treatment.TYPE_PUMP_BATTERY_CHANGE)
			{
				if (treatment.timestamp > Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_LAST_PUMP_BATTERY_CHANGE)))
				{
					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_LAST_PUMP_BATTERY_CHANGE, String(treatment.timestamp), true, false);
				}
			}
			else if (treatment.type == Treatment.TYPE_PUMP_SITE_CHANGE)
			{
				if (treatment.timestamp > Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_LAST_PUMP_SITE_CHANGE)))
				{
					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_LAST_PUMP_SITE_CHANGE, String(treatment.timestamp), true, false);
				}
			}
			
			//Insert in Database
			if (treatment.type != Treatment.TYPE_TEMP_BASAL && treatment.type != Treatment.TYPE_MDI_BASAL)
			{
				if (treatmentsMap[treatment.ID] == null) //new treatment
				{
					Trace.myTrace("TreatmentsManager.as", "Adding treatment to Spike...");
					
					//Add treatment to Spike
					treatmentsList.push(treatment);
					treatmentsMap[treatment.ID] = treatment;
					
					//Notify listeners
					_instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.TREATMENT_ADDED, false, false, treatment));
					
					//Upload to Nightscout
					if (uploadToNightscout)
						NightscoutService.uploadTreatment(treatment);
					
					//Save to database
					if (!CGMBlueToothDevice.isFollower() || ModelLocator.INTERNAL_TESTING)
						Database.insertTreatmentSynchronous(treatment);
				}
			}
			else
			{
				if (basalsMap[treatment.ID] == null) //new treatment
				{
					Trace.myTrace("TreatmentsManager.as", "Adding treatment to Spike...");
					
					//Add treatment to Spike
					basalsList.push(treatment);
					basalsMap[treatment.ID] = treatment;
					
					//Notify listeners
					_instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.BASAL_TREATMENT_ADDED, false, false, treatment));
					
					//Upload to Nightscout
					if (uploadToNightscout)
						NightscoutService.uploadTreatment(treatment);
					
					//Save to database
					if (!CGMBlueToothDevice.isFollower() || ModelLocator.INTERNAL_TESTING)
						Database.insertTreatmentSynchronous(treatment);
				}
			}
		}
		
		public static function deleteInternalCalibration(timestamp:Number):void
		{
			Trace.myTrace("TreatmentsManager.as", "deleteInternalCalibration called!");
			
			for (var i:int = 0; i < treatmentsList.length; i++) 
			{
				var treatment:Treatment = treatmentsList[i] as Treatment;
				if (treatment.timestamp == timestamp && treatment.type == Treatment.TYPE_GLUCOSE_CHECK && treatment.note == ModelLocator.resourceManagerInstance.getString('treatments','sensor_calibration_note'))
				{
					Trace.myTrace("TreatmentsManager.as", "Calibration found. Deleting...");
					deleteTreatment(treatment);
					break;
				}
			}
		}
		
		public static function addTreatment(type:String):void
		{	
			Trace.myTrace("TreatmentsManager.as", "addTreatment called!");
			
			//Event Listeners
			Starling.current.stage.addEventListener(starling.events.Event.RESIZE, onStarlingResize);
			
			//Time
			var now:Number = new Date().valueOf();
			
			//Total Content Layout
			var totalScrollLayout:TiledRowsLayout = new TiledRowsLayout();
			totalScrollLayout.paging = Direction.HORIZONTAL;
			totalScrollLayout.tileHorizontalAlign = HorizontalAlign.LEFT;
			totalScrollLayout.tileVerticalAlign = VerticalAlign.TOP;
			totalScrollLayout.horizontalAlign = HorizontalAlign.LEFT;
			totalScrollLayout.verticalAlign = VerticalAlign.TOP;
			totalScrollLayout.useSquareTiles = false;
			
			//Total Container
			totalScrollContainer = new ScrollContainer();
			totalScrollContainer.layout = totalScrollLayout;
			totalScrollContainer.snapToPages = true;
			totalScrollContainer.horizontalScrollPolicy = ScrollPolicy.OFF;
			
			//Content Scroll Container
			var contentScrollContainerLayout:VerticalLayout = new VerticalLayout();
			
			contentScrollContainer = new ScrollContainer();
			contentScrollContainer.layout = contentScrollContainerLayout;
			contentScrollContainer.scrollBarDisplayMode = ScrollBarDisplayMode.FIXED_FLOAT;
			totalScrollContainer.addChild(contentScrollContainer);
			
			//Display Container
			var displayLayout:VerticalLayout = new VerticalLayout();
			displayLayout.horizontalAlign = HorizontalAlign.LEFT;
			displayLayout.gap = 10;
			
			treatmentInserterContainer = new LayoutGroup();
			treatmentInserterContainer.layout = displayLayout;
			contentScrollContainer.addChild(treatmentInserterContainer);
			
			//Common Variables
			var canAddInsulin:Boolean = false;
			
			//Title
			var treatmentTitle:String = "";
			if (type == Treatment.TYPE_BOLUS)
				treatmentTitle = ModelLocator.resourceManagerInstance.getString('treatments','enter_units_label');
			else if (type == Treatment.TYPE_NOTE)
				treatmentTitle = ModelLocator.resourceManagerInstance.getString('treatments','enter_note_label');
			else if (type == Treatment.TYPE_GLUCOSE_CHECK)
				treatmentTitle = ModelLocator.resourceManagerInstance.getString('treatments','enter_bg_label');
			else if (type == Treatment.TYPE_CARBS_CORRECTION)
				treatmentTitle = ModelLocator.resourceManagerInstance.getString('treatments','enter_grams_label');
			else if (type == Treatment.TYPE_MEAL_BOLUS)
				treatmentTitle = ModelLocator.resourceManagerInstance.getString('treatments','enter_meal_label');
			else if (type == Treatment.TYPE_EXERCISE)
				treatmentTitle = ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_exercise');
			else if (type == Treatment.TYPE_INSULIN_CARTRIDGE_CHANGE)
				treatmentTitle = ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_insulin_cartridge_change');
			else if (type == Treatment.TYPE_PUMP_SITE_CHANGE)
				treatmentTitle = ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_pump_site_change');
			else if (type == Treatment.TYPE_PUMP_BATTERY_CHANGE)
				treatmentTitle = ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_pump_battery_change');
			else if (type == Treatment.TYPE_TEMP_BASAL)
				treatmentTitle = ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_temp_basal_start');
			else if (type == Treatment.TYPE_TEMP_BASAL_END)
				treatmentTitle = ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_temp_basal_end');
			else if (type == Treatment.TYPE_MDI_BASAL)
				treatmentTitle = ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_basal');
			
			treatmentInserterTitleLabel = LayoutFactory.createLabel(treatmentTitle, HorizontalAlign.CENTER, VerticalAlign.TOP, 18, true);
			if (type == Treatment.TYPE_INSULIN_CARTRIDGE_CHANGE 
				|| 
				type == Treatment.TYPE_PUMP_BATTERY_CHANGE 
				|| 
				type == Treatment.TYPE_PUMP_SITE_CHANGE
				|| 
				type == Treatment.TYPE_TEMP_BASAL_END
			)
			{
				treatmentInserterTitleLabel.paddingBottom = 15;
			}
			treatmentInserterContainer.addChild(treatmentInserterTitleLabel);
			
			//Fields
			if (type == Treatment.TYPE_BOLUS || type == Treatment.TYPE_CORRECTION_BOLUS || type == Treatment.TYPE_MEAL_BOLUS)
			{
				//Logical
				canAddInsulin = true;
				
				//Insulin Amout
				insulinTextInput = LayoutFactory.createTextInput(false, false, 159, HorizontalAlign.CENTER, true);
				insulinTextInput.textEditorProperties.softKeyboardType = SoftKeyboardType.DECIMAL;
				insulinTextInput.addEventListener(FeathersEventType.ENTER, onClearFocus);
				insulinTextInput.maxChars = 5;
				if (type == Treatment.TYPE_MEAL_BOLUS)
					insulinTextInput.prompt = ModelLocator.resourceManagerInstance.getString('treatments','insulin_text_input_prompt');
				treatmentInserterContainer.addChild(insulinTextInput);
				
				//Extended Bolus
				extendedBolusMainContainer = LayoutFactory.createLayoutGroup("vertical", HorizontalAlign.CENTER, VerticalAlign.MIDDLE, 10);
				(extendedBolusMainContainer.layout as VerticalLayout).paddingTop = 10;
				if (type == Treatment.TYPE_BOLUS || type == Treatment.TYPE_CORRECTION_BOLUS)
				{
					(extendedBolusMainContainer.layout as VerticalLayout).paddingBottom = 10;
				}
				
				treatmentInserterContainer.addChild(extendedBolusMainContainer);
				
				extendedBolusCheck = LayoutFactory.createCheckMark(false, ModelLocator.resourceManagerInstance.getString('treatments','extended_bolus_treatment'));
				extendedBolusCheck.addEventListener(Event.CHANGE, onBolusExtendedChanged);
				extendedBolusMainContainer.addChild(extendedBolusCheck);
				
				//Spacer
				insulinSpacer = new Sprite();
				insulinSpacer.height = 10;
				treatmentInserterContainer.addChild(insulinSpacer);
			}
			
			if (type == Treatment.TYPE_GLUCOSE_CHECK)
			{
				//Glucose Amout
				glucoseTextInput = LayoutFactory.createTextInput(false, false, 159, HorizontalAlign.CENTER, true);
				glucoseTextInput.addEventListener(FeathersEventType.ENTER, onClearFocus);
				glucoseTextInput.maxChars = 4;
				treatmentInserterContainer.addChild(glucoseTextInput);
				
				glucoseSpacer = new Sprite();
				glucoseSpacer.height = 10;
				treatmentInserterContainer.addChild(glucoseSpacer);
			}
			
			if (type == Treatment.TYPE_EXERCISE)
			{
				//Duration Amout
				exerciseDurationTextInput = LayoutFactory.createTextInput(false, true, 159, HorizontalAlign.CENTER, false);
				exerciseDurationTextInput.addEventListener(FeathersEventType.ENTER, onClearFocus);
				exerciseDurationTextInput.maxChars = 4;
				exerciseDurationTextInput.prompt = ModelLocator.resourceManagerInstance.getString('treatments','exercise_duration_prompt');
				treatmentInserterContainer.addChild(exerciseDurationTextInput);
				
				exerciseChangerSpacer = new Sprite();
				exerciseChangerSpacer.height = 10;
				treatmentInserterContainer.addChild(exerciseChangerSpacer);
			
				//Intensity
				var exerciseIntensityLayout:HorizontalLayout = new HorizontalLayout();
				exerciseIntensityLayout.distributeWidths = true;
				exerciseIntensityLayout.paddingBottom = 20;
				
				exerciseIntensityContainer = new LayoutGroup();
				exerciseIntensityContainer.layout = exerciseIntensityLayout;
				exerciseIntensityGroup = new ToggleGroup();
				
				lowIntensity = LayoutFactory.createRadioButton(ModelLocator.resourceManagerInstance.getString('treatments','exercise_intensity_low_label') , exerciseIntensityGroup);
				moderateIntensity = LayoutFactory.createRadioButton(ModelLocator.resourceManagerInstance.getString('treatments','exercise_intensity_moderate_label'), exerciseIntensityGroup);
				highIntendity = LayoutFactory.createRadioButton(ModelLocator.resourceManagerInstance.getString('treatments','exercise_intensity_high_label'), exerciseIntensityGroup);
				
				exerciseIntensityGroup.selectedItem = moderateIntensity;
				
				exerciseIntensityContainer.addChild(lowIntensity);
				exerciseIntensityContainer.addChild(moderateIntensity);
				exerciseIntensityContainer.addChild(highIntendity);
				treatmentInserterContainer.addChild(exerciseIntensityContainer);
			}
			
			if (type == Treatment.TYPE_CARBS_CORRECTION || type == Treatment.TYPE_MEAL_BOLUS)
			{
				if (type == Treatment.TYPE_MEAL_BOLUS)
				{
					var extendedCarbLayout:HorizontalLayout = new HorizontalLayout();
					extendedCarbLayout.gap = 0;
					extendedCarbLayout.verticalAlign = VerticalAlign.MIDDLE;
					extendedCarbContainer = new LayoutGroup();
					extendedCarbContainer.layout = extendedCarbLayout;
					
					carbOffSet = LayoutFactory.createNumericStepper(-300, 300, 0, 5);
					carbOffSet.validate();
					
					carbOffsetSuffix = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('treatments','minutes_small_label'), HorizontalAlign.RIGHT);
					carbOffsetSuffix.validate();
				}
				
				//Carbs Amout
				carbsTextInput = LayoutFactory.createTextInput(false, false, 159, HorizontalAlign.CENTER, true);
				carbsTextInput.addEventListener(FeathersEventType.ENTER, onClearFocus);
				carbsTextInput.maxChars = 4;
				if (type == Treatment.TYPE_MEAL_BOLUS)
					carbsTextInput.prompt = ModelLocator.resourceManagerInstance.getString('treatments','carbs_text_input_prompt');
				
				if (type == Treatment.TYPE_MEAL_BOLUS)
				{
					extendedCarbContainer.addChild(carbsTextInput);
					extendedCarbContainer.addChild(carbOffSet);
					extendedCarbContainer.addChild(carbOffsetSuffix);
					treatmentInserterContainer.addChild(extendedCarbContainer);
				}
				else
					treatmentInserterContainer.addChild(carbsTextInput);
				
				//Carb absorption delay
				var carbDelayLayout:HorizontalLayout = new HorizontalLayout();
				carbDelayLayout.distributeWidths = true;
				carbDelayLayout.paddingTop = carbDelayLayout.paddingBottom = 8;
				
				carbDelayContainer = new LayoutGroup();
				carbDelayContainer.layout = carbDelayLayout;
				carbDelayGroup = new ToggleGroup();
				
				fastCarb = LayoutFactory.createRadioButton(ModelLocator.resourceManagerInstance.getString('treatments','carbs_fast_label'), carbDelayGroup);
				mediumCarb = LayoutFactory.createRadioButton(ModelLocator.resourceManagerInstance.getString('treatments','carbs_medium_label'), carbDelayGroup);
				slowCarb = LayoutFactory.createRadioButton(ModelLocator.resourceManagerInstance.getString('treatments','carbs_slow_label'), carbDelayGroup);
				
				var defaultCarbType:String = ProfileManager.getDefaultTimeAbsortionCarbType();
				if (defaultCarbType == "fast")
					carbDelayGroup.selectedItem = fastCarb;
				else if (defaultCarbType == "medium")
					carbDelayGroup.selectedItem = mediumCarb;
				else if (defaultCarbType == "slow")
					carbDelayGroup.selectedItem = slowCarb;
				else
					carbDelayGroup.selectedItem = slowCarb;
				carbDelayContainer.addChild(fastCarb);
				carbDelayContainer.addChild(mediumCarb);
				carbDelayContainer.addChild(slowCarb);
				treatmentInserterContainer.addChild(carbDelayContainer);
				
				//Food manager
				foodManagerContainer = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.CENTER);
				treatmentInserterContainer.addChild(foodManagerContainer);
				
				foodManagerButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('treatments','load_foods_button_label'));
				foodManagerButton.addEventListener(Event.TRIGGERED, onLoadFoodManager);
				foodManagerContainer.addChild(foodManagerButton);
				
				//Spacer
				carbSpacer = new Sprite();
				carbSpacer.height = 10;
				treatmentInserterContainer.addChild(carbSpacer);
			}
			
			if (type == Treatment.TYPE_TEMP_BASAL || type == Treatment.TYPE_MDI_BASAL || type == Treatment.TYPE_TEMP_BASAL_END)
			{
				//Logical
				canAddInsulin = true;
				
				if (type != Treatment.TYPE_TEMP_BASAL_END)
				{
					//Insulin Amout
					insulinTextInput = LayoutFactory.createTextInput(false, false, 159, HorizontalAlign.CENTER, false, false, false, false, false, true);
					insulinTextInput.textEditorProperties.softKeyboardType = SoftKeyboardType.DECIMAL;
					insulinTextInput.addEventListener(FeathersEventType.ENTER, onClearFocus);
					insulinTextInput.maxChars = 5;
					if (type == Treatment.TYPE_MEAL_BOLUS)
						insulinTextInput.prompt = ModelLocator.resourceManagerInstance.getString('treatments','insulin_text_input_prompt');
					treatmentInserterContainer.addChild(insulinTextInput);
					
					//Insulin Spacer
					insulinSpacer = new Sprite();
					insulinSpacer.height = 5;
					treatmentInserterContainer.addChild(insulinSpacer);
				}
				
				if (type == Treatment.TYPE_TEMP_BASAL || type == Treatment.TYPE_TEMP_BASAL_END)
				{
					if (type != Treatment.TYPE_TEMP_BASAL_END)
					{
						//Basal Mode
						var basalModeLayout:HorizontalLayout = new HorizontalLayout();
						basalModeLayout.distributeWidths = true;
						basalModeLayout.paddingBottom = 5;
						
						basalModeContainer = new LayoutGroup();
						basalModeContainer.layout = basalModeLayout;
						
						basalModeGroup = new ToggleGroup();
						basalModeGroup.addEventListener( Event.CHANGE, onBasalModeChanged );
						
						basalAbsoluteRadio = LayoutFactory.createRadioButton(ModelLocator.resourceManagerInstance.getString('treatments','basal_amount_absolute_label') , basalModeGroup);
						basalRelativeRadio = LayoutFactory.createRadioButton(ModelLocator.resourceManagerInstance.getString('treatments','basal_amount_relative_label'), basalModeGroup);
						
						if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PREFERRED_TEMP_BASAL_MODE) == "absolute")
						{
							basalModeGroup.selectedItem = basalAbsoluteRadio;
							onBasalModeChanged(null);
						}
						else if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PREFERRED_TEMP_BASAL_MODE) == "relative")
						{
							basalModeGroup.selectedItem = basalRelativeRadio;
						}
						
						basalModeContainer.addChild(basalAbsoluteRadio);
						basalModeContainer.addChild(basalRelativeRadio);
						treatmentInserterContainer.addChild(basalModeContainer);
					}
					
					if (type != Treatment.TYPE_TEMP_BASAL_END)
					{
						//Duration Amout
						basalDurationTextInput = LayoutFactory.createTextInput(false, true, 159, HorizontalAlign.CENTER, false);
						basalDurationTextInput.addEventListener(FeathersEventType.ENTER, onClearFocus);
						basalDurationTextInput.maxChars = 4;
						basalDurationTextInput.prompt = ModelLocator.resourceManagerInstance.getString('treatments','exercise_duration_prompt');
						treatmentInserterContainer.addChild(basalDurationTextInput);
						
						//Duration Spacer
						basalDurationSpacer = new Sprite();
						basalDurationSpacer.height = 10;
						treatmentInserterContainer.addChild(basalDurationSpacer);
					}
				}
			}
			
			if (type == Treatment.TYPE_NOTE)
			{
				noteSpacer = new Sprite();
				noteSpacer.height = 10;
				treatmentInserterContainer.addChild(noteSpacer);
			}
			
			//Treatment Time
			treatmentTime = new DateTimeSpinner();
			treatmentTime.locale = Constants.getUserLocale(true);
			treatmentTime.minimum = new Date(now - TimeSpan.TIME_24_HOURS);
			treatmentTime.maximum = new Date(now + TimeSpan.TIME_6_HOURS);
			treatmentTime.value = new Date();
			treatmentTime.height = 30;
			treatmentInserterContainer.addChild(treatmentTime);
			if (type == Treatment.TYPE_MEAL_BOLUS || type == Treatment.TYPE_EXERCISE || type == Treatment.TYPE_TEMP_BASAL)
			{
				treatmentTime.minWidth = 270;
			}
			treatmentTime.validate();
			
			treatmentSpacer = new Sprite();
			treatmentSpacer.height = 10;
			treatmentInserterContainer.addChild(treatmentSpacer);
			
			if (type == Treatment.TYPE_BOLUS || type == Treatment.TYPE_CORRECTION_BOLUS || type == Treatment.TYPE_MEAL_BOLUS)
			{
				insulinTextInput.width = treatmentTime.width;
				extendedBolusMainContainer.width = insulinTextInput.width;
			}
			if (type == Treatment.TYPE_GLUCOSE_CHECK)
			{
				glucoseTextInput.width = treatmentTime.width;
			}
			if (type == Treatment.TYPE_EXERCISE)
			{
				exerciseDurationTextInput.width = treatmentTime.width;
				exerciseIntensityContainer.width = treatmentTime.width;
			}
			if (type == Treatment.TYPE_CARBS_CORRECTION)
			{
				carbsTextInput.width = treatmentTime.width;
				carbDelayContainer.width = treatmentTime.width;
				foodManagerContainer.width = treatmentTime.width;
			}
			else if (type == Treatment.TYPE_MEAL_BOLUS)
			{
				extendedCarbContainer.width = treatmentTime.width;
				carbsTextInput.width = treatmentTime.width - carbOffSet.width - carbOffsetSuffix.width;
				carbDelayContainer.width = treatmentTime.width;
				foodManagerContainer.width = treatmentTime.width;
			}
			else if (type == Treatment.TYPE_TEMP_BASAL || type == Treatment.TYPE_MDI_BASAL)
			{
				insulinTextInput.width = treatmentTime.width;
				if (type == Treatment.TYPE_TEMP_BASAL)
				{
					basalDurationTextInput.width = treatmentTime.width;
					basalModeContainer.width = treatmentTime.width;
				}
			}
			
			treatmentInserterTitleLabel.width = treatmentTime.width;
			
			//Other Fields constainer
			var otherFieldsLayout:VerticalLayout = new VerticalLayout();
			otherFieldsLayout.horizontalAlign = HorizontalAlign.CENTER
			otherFieldsLayout.gap = 10;
			
			otherFieldsContainer = new LayoutGroup();
			otherFieldsContainer.layout = otherFieldsLayout;
			otherFieldsContainer.width = treatmentTime.width;
			treatmentInserterContainer.addChild(otherFieldsContainer);
			
			if (type == Treatment.TYPE_BOLUS 
				|| 
				type == Treatment.TYPE_CORRECTION_BOLUS 
				|| 
				type == Treatment.TYPE_MEAL_BOLUS
				|| 
				type == Treatment.TYPE_TEMP_BASAL
				|| 
				type == Treatment.TYPE_MDI_BASAL
			)
			{
				//Insulin Type
				var allInsulinTypes:Array = ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','insulin_types_list').split(",");
				var longActing:String = StringUtil.trim(allInsulinTypes[4]);
				
				var askForInsulinConfiguration:Boolean = true;
				if (ProfileManager.insulinsList != null && ProfileManager.insulinsList.length > 0)
				{
					insulinList = LayoutFactory.createPickerList();
					var insulinDataProvider:ArrayCollection = new ArrayCollection();
					var userInsulins:Array = sortInsulinsByDefault(ProfileManager.insulinsList.concat());
					var numInsulins:int = userInsulins.length
					for (var i:int = 0; i < numInsulins; i++) 
					{
						var insulin:Insulin = userInsulins[i];
						if (type == Treatment.TYPE_MDI_BASAL)
						{
							if (insulin.name.indexOf("Nightscout") == -1 
								&& 
								!insulin.isHidden
								&&
								insulin.type == longActing
							)
							{
								insulinDataProvider.push( { label:insulin.name, id: insulin.ID } );
								askForInsulinConfiguration = false;
							}
						}
						else
						{
							if (insulin.name.indexOf("Nightscout") == -1 
								&& 
								!insulin.isHidden
								&&
								insulin.type != longActing
							)
							{
								insulinDataProvider.push( { label:insulin.name, id: insulin.ID } );
								askForInsulinConfiguration = false;
							}
						}
					}
					insulinList.dataProvider = insulinDataProvider;
					insulinList.popUpContentManager = new DropDownPopUpContentManager();
					insulinList.itemRendererFactory = function():IListItemRenderer
					{
						var renderer:DefaultListItemRenderer = new DefaultListItemRenderer();
						renderer.paddingRight = renderer.paddingLeft = 15;
						return renderer;
					};
					
					if (!askForInsulinConfiguration)
						otherFieldsContainer.addChild(insulinList);
				}
				
				if (askForInsulinConfiguration)
				{
					createInsulinButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('treatments','configure_insulins_button_label'));
					createInsulinButton.addEventListener(Event.TRIGGERED, onConfigureInsulins);
					otherFieldsContainer.addChild(createInsulinButton);
					canAddInsulin = false;
				}
			}
			
			notes = LayoutFactory.createTextInput(false, false, treatmentTime.width, HorizontalAlign.CENTER, false, false, false, true, true);
			notes.addEventListener(FeathersEventType.ENTER, onClearFocus);
			notes.prompt = ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_note');
			notes.maxChars = 50;
			otherFieldsContainer.addChild(notes);
			
			//Action Buttons
			var actionFunction:Function;
			if (type == Treatment.TYPE_BOLUS)
				actionFunction = onInsulinEntered;
			else if (type == Treatment.TYPE_NOTE)
				actionFunction = onNoteEntered;
			else if (type == Treatment.TYPE_GLUCOSE_CHECK)
				actionFunction = onBGCheckEntered;
			else if (type == Treatment.TYPE_CARBS_CORRECTION)
				actionFunction = onCarbsEntered;
			else if (type == Treatment.TYPE_MEAL_BOLUS)
				actionFunction = onMealEntered;
			else if (type == Treatment.TYPE_EXERCISE)
				actionFunction = onExerciseEntered;
			else if (type == Treatment.TYPE_INSULIN_CARTRIDGE_CHANGE)
				actionFunction = onInsulinCartridgeEntered;
			else if (type == Treatment.TYPE_PUMP_BATTERY_CHANGE)
				actionFunction = onPumpBatteryEntered;
			else if (type == Treatment.TYPE_PUMP_SITE_CHANGE)
				actionFunction = onPumpSiteEntered;
			else if (type == Treatment.TYPE_TEMP_BASAL)
				actionFunction = onTempBasalStartEntered;
			else if (type == Treatment.TYPE_TEMP_BASAL_END)
				actionFunction = onTempBasalEndEntered;
			else if (type == Treatment.TYPE_MDI_BASAL)
				actionFunction = onPenBasalEntered;
			
			var actionLayout:HorizontalLayout = new HorizontalLayout();
			actionLayout.gap = 5;
			
			actionContainer = new LayoutGroup();
			actionContainer.layout = actionLayout;
			otherFieldsContainer.addChild(actionContainer);
			
			cancelButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('globaltranslations','cancel_button_label').toUpperCase());
			cancelButton.addEventListener(Event.TRIGGERED, closeCallout);
			actionContainer.addChild(cancelButton);
			
			if (
				((type == Treatment.TYPE_BOLUS || type == Treatment.TYPE_MEAL_BOLUS) && canAddInsulin) 
				|| 
				type == Treatment.TYPE_NOTE 
				|| 
				type == Treatment.TYPE_GLUCOSE_CHECK 
				|| 
				type == Treatment.TYPE_CARBS_CORRECTION
				|| 
				type == Treatment.TYPE_EXERCISE
				|| 
				type == Treatment.TYPE_INSULIN_CARTRIDGE_CHANGE
				|| 
				type == Treatment.TYPE_PUMP_BATTERY_CHANGE
				|| 
				type == Treatment.TYPE_PUMP_SITE_CHANGE
				|| 
				type == Treatment.TYPE_TEMP_BASAL_END
				||
				((type == Treatment.TYPE_TEMP_BASAL || type == Treatment.TYPE_MDI_BASAL) && canAddInsulin) 
			)
			{
				addButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('globaltranslations','add_button_label').toUpperCase());
				addButton.addEventListener(Event.TRIGGERED, actionFunction);
				actionContainer.addChild(addButton);
			}
			
			actionContainer.validate();
			
			//Callout
			calloutPositionHelper = new Sprite();
			yPos = 0;
			if (!isNaN(Constants.headerHeight))
				yPos = Constants.headerHeight - 10;
			else
			{
				if (Constants.deviceModel != DeviceInfo.IPHONE_X_Xs_XsMax_Xr)
					yPos = 68;
				else
					yPos = Constants.isPortrait ? 98 : 68;
			}
			calloutPositionHelper.y = yPos;
			calloutPositionHelper.x = Constants.stageWidth / 2;
			Starling.current.stage.addChild(calloutPositionHelper);
			
			treatmentInserterContainer.validate();
			contentOriginalHeight = treatmentInserterContainer.height + 60;
			suggestedCalloutHeight = Constants.stageHeight - yPos - 10;
			finalCalloutHeight = contentOriginalHeight > suggestedCalloutHeight ?  suggestedCalloutHeight : contentOriginalHeight;
			
			treatmentCallout = Callout.show(totalScrollContainer, calloutPositionHelper);
			treatmentCallout.disposeContent = true;
			treatmentCallout.paddingBottom = 15;
			if (finalCalloutHeight != contentOriginalHeight)
			{
				contentScrollContainerLayout.paddingRight = 10;
				treatmentCallout.paddingRight = 10;
			}
			treatmentCallout.closeOnTouchBeganOutside = false;
			treatmentCallout.closeOnTouchEndedOutside = false;
			treatmentCallout.height = finalCalloutHeight;
			treatmentCallout.paddingBottom = 0;
			treatmentCallout.addEventListener(Event.CLOSE, onTreatmentsCalloutClosed);
			treatmentCallout.validate();
			
			contentScrollContainer.height = finalCalloutHeight - 50;
			contentScrollContainer.maxHeight = finalCalloutHeight - 50;
			contentScrollContainer.validate();
			totalScrollContainer.height = finalCalloutHeight - 50;
			totalScrollContainer.maxHeight = finalCalloutHeight - 50;
			totalScrollContainer.validate();
			
			treatmentCallOutWidth = treatmentCallout.width;
			treatmentCallOutHeight = treatmentCallout.height;
			treatmentCallOutPaddingRight = treatmentCallout.paddingRight;
			contentScrollContainerWidth = contentScrollContainer.width;
			contentScrollContainerHeight = contentScrollContainer.height;
			totalScrollContainerWidth = totalScrollContainer.width;
			totalScrollContainerHeight = totalScrollContainer.height;
			
			//Keyboard Focus
			if (type == Treatment.TYPE_BOLUS || type == Treatment.TYPE_CORRECTION_BOLUS || type == Treatment.TYPE_MEAL_BOLUS || type == Treatment.TYPE_TEMP_BASAL || type == Treatment.TYPE_MDI_BASAL)
				insulinTextInput.setFocus();
			else if (type == Treatment.TYPE_NOTE)
				notes.setFocus();
			else if (type == Treatment.TYPE_GLUCOSE_CHECK)
				glucoseTextInput.setFocus();
			else if (type == Treatment.TYPE_CARBS_CORRECTION)
				carbsTextInput.setFocus();
			else if (type == Treatment.TYPE_TEMP_BASAL || type == Treatment.TYPE_MDI_BASAL)
				insulinTextInput.setFocus();
			else if (type == Treatment.TYPE_EXERCISE)
				exerciseDurationTextInput.setFocus();
			
			//Final Layout Adjustments
			if (actionContainer.width > treatmentTime.width)
			{
				if (type == Treatment.TYPE_BOLUS || type == Treatment.TYPE_CORRECTION_BOLUS || type == Treatment.TYPE_MEAL_BOLUS)
				{
					insulinTextInput.width = actionContainer.width;
					extendedBolusMainContainer.width = insulinTextInput.width;
				}
				if (type == Treatment.TYPE_GLUCOSE_CHECK)
				{
					glucoseTextInput.width = actionContainer.width;
				}
				if (type == Treatment.TYPE_EXERCISE)
				{
					exerciseDurationTextInput.width = actionContainer.width;
					exerciseIntensityContainer.width = actionContainer.width;
				}
				if (type == Treatment.TYPE_CARBS_CORRECTION)
				{
					carbsTextInput.width = actionContainer.width;
					carbDelayContainer.width = actionContainer.width;
					foodManagerContainer.width = actionContainer.width;
				}
				else if (type == Treatment.TYPE_MEAL_BOLUS)
				{
					extendedCarbContainer.width = actionContainer.width;
					carbsTextInput.width = actionContainer.width - carbOffSet.width - carbOffsetSuffix.width;
					carbDelayContainer.width = actionContainer.width;
					foodManagerContainer.width = actionContainer.width;
				}
				else if (type == Treatment.TYPE_TEMP_BASAL || type == Treatment.TYPE_MDI_BASAL)
				{
					insulinTextInput.width = actionContainer.width;
					if (type == Treatment.TYPE_TEMP_BASAL)
					{
						basalDurationTextInput.width = actionContainer.width;
						basalModeContainer.width = actionContainer.width;
					}
				}
				
				notes.width = actionContainer.width;
				treatmentInserterTitleLabel.width = actionContainer.width;
				treatmentInserterContainer.validate();
				treatmentTime.paddingLeft += (actionContainer.width - treatmentTime.width) / 2;
				treatmentInserterContainer.validate();
			}
			
			function closeCallout(e:Event):void
			{
				if (cancelButton != null) cancelButton.removeEventListener(Event.TRIGGERED, closeCallout);
				
				if (treatmentCallout != null) treatmentCallout.close();
			}
			
			function onExerciseEntered (e:Event):void
			{
				if (addButton != null) addButton.removeEventListener(Event.TRIGGERED, onExerciseEntered);
				
				if (!SystemUtil.isApplicationActive || treatmentTime == null || exerciseDurationTextInput == null || exerciseIntensityGroup == null)
					return;
				
				function onAskNewExercise():void
				{
					addTreatment(type);
				}
				
				if (exerciseDurationTextInput.text == "") 
				{
					AlertManager.showSimpleAlert
					(
						ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
						ModelLocator.resourceManagerInstance.getString('treatments','non_numeric_duration'),
						Number.NaN,
						onAskNewExercise
					);					
				}
				else
				{
					var selectedExerciseIntendityIndex:int = exerciseIntensityGroup.selectedIndex;
					var selectedExerciseIntensity:String = Treatment.EXERCISE_INTENSITY_MODERATE;
					if (selectedExerciseIntendityIndex == 0)
						selectedExerciseIntensity = Treatment.EXERCISE_INTENSITY_LOW;
					if (selectedExerciseIntendityIndex == 1)
						selectedExerciseIntensity = Treatment.EXERCISE_INTENSITY_MODERATE;
					if (selectedExerciseIntendityIndex == 2)
						selectedExerciseIntensity = Treatment.EXERCISE_INTENSITY_HIGH;
					
					var treatment:Treatment = new Treatment
					(
						Treatment.TYPE_EXERCISE,
						treatmentTime.value.valueOf(),
						0,
						"",
						0,
						0,
						getEstimatedGlucose(treatmentTime.value.valueOf()),
						notes != null ? notes.text : ""
					);
					
					treatment.exerciseIntensity = selectedExerciseIntensity;
					treatment.duration = Number(exerciseDurationTextInput.text);
					
					//Add to list
					treatmentsList.push(treatment);
					treatmentsMap[treatment.ID] = treatment;
					
					Trace.myTrace("TreatmentsManager.as", "Added treatment to Spike. Type: " + treatment.type);
					
					//Notify listeners
					_instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.TREATMENT_ADDED, false, false, treatment));
					
					//Insert in DB
					if (!CGMBlueToothDevice.isFollower() || ModelLocator.INTERNAL_TESTING)
						Database.insertTreatmentSynchronous(treatment);
					
					//Upload to Nightscout
					NightscoutService.uploadTreatment(treatment);
				}
				
				if (treatmentCallout != null) treatmentCallout.close();
			}
			
			function onInsulinCartridgeEntered (e:Event):void
			{
				if (addButton != null) addButton.removeEventListener(Event.TRIGGERED, onInsulinCartridgeEntered);
				
				if (!SystemUtil.isApplicationActive || treatmentTime == null)
					return;
				
				var treatment:Treatment = new Treatment
				(
					Treatment.TYPE_INSULIN_CARTRIDGE_CHANGE,
					treatmentTime.value.valueOf(),
					0,
					"",
					0,
					0,
					getEstimatedGlucose(treatmentTime.value.valueOf()),
					notes != null ? notes.text : ""
				);
				
				//Add to list
				treatmentsList.push(treatment);
				treatmentsMap[treatment.ID] = treatment;
				
				//Update Settings
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_LAST_INSULIN_CARTRIDGE_CHANGE, String(treatmentTime.value.valueOf()), true, false);
				
				Trace.myTrace("TreatmentsManager.as", "Added treatment to Spike. Type: " + treatment.type);
				
				//Notify listeners
				_instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.TREATMENT_ADDED, false, false, treatment));
				
				//Insert in DB
				if (!CGMBlueToothDevice.isFollower() || ModelLocator.INTERNAL_TESTING)
					Database.insertTreatmentSynchronous(treatment);
				
				//Upload to Nightscout
				NightscoutService.uploadTreatment(treatment);
				
				if (treatmentCallout != null) treatmentCallout.close();
			}
			
			function onPumpBatteryEntered (e:Event):void
			{
				if (addButton != null) addButton.removeEventListener(Event.TRIGGERED, onPumpBatteryEntered);
				
				if (!SystemUtil.isApplicationActive || treatmentTime == null)
					return;
				
				var treatment:Treatment = new Treatment
				(
					Treatment.TYPE_PUMP_BATTERY_CHANGE,
					treatmentTime.value.valueOf(),
					0,
					"",
					0,
					0,
					getEstimatedGlucose(treatmentTime.value.valueOf()),
					notes != null ? notes.text : ""
				);
				
				//Add to list
				treatmentsList.push(treatment);
				treatmentsMap[treatment.ID] = treatment;
				
				//Update Settings
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_LAST_PUMP_BATTERY_CHANGE, String(treatmentTime.value.valueOf()), true, false);
				
				Trace.myTrace("TreatmentsManager.as", "Added treatment to Spike. Type: " + treatment.type);
				
				//Notify listeners
				_instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.TREATMENT_ADDED, false, false, treatment));
				
				//Insert in DB
				if (!CGMBlueToothDevice.isFollower() || ModelLocator.INTERNAL_TESTING)
					Database.insertTreatmentSynchronous(treatment);
				
				//Upload to Nightscout
				NightscoutService.uploadTreatment(treatment);
				
				if (treatmentCallout != null) treatmentCallout.close();
			}
			
			function onPumpSiteEntered (e:Event):void
			{
				if (addButton != null) addButton.removeEventListener(Event.TRIGGERED, onPumpSiteEntered);
				
				if (!SystemUtil.isApplicationActive || treatmentTime == null)
					return;
				
				var treatment:Treatment = new Treatment
				(
					Treatment.TYPE_PUMP_SITE_CHANGE,
					treatmentTime.value.valueOf(),
					0,
					"",
					0,
					0,
					getEstimatedGlucose(treatmentTime.value.valueOf()),
					notes != null ? notes.text : ""
				);
				
				//Add to list
				treatmentsList.push(treatment);
				treatmentsMap[treatment.ID] = treatment;
				
				//Update Settings
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_LAST_PUMP_SITE_CHANGE, String(treatmentTime.value.valueOf()), true, false);
				
				Trace.myTrace("TreatmentsManager.as", "Added treatment to Spike. Type: " + treatment.type);
				
				//Notify listeners
				_instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.TREATMENT_ADDED, false, false, treatment));
				
				//Insert in DB
				if (!CGMBlueToothDevice.isFollower() || ModelLocator.INTERNAL_TESTING)
					Database.insertTreatmentSynchronous(treatment);
				
				//Upload to Nightscout
				NightscoutService.uploadTreatment(treatment);
				
				if (treatmentCallout != null) treatmentCallout.close();
			}
			
			function onBasalModeChanged(e:Event):void
			{
				if (basalModeGroup.selectedItem == basalAbsoluteRadio)
				{
					insulinTextInput.restrict = "0-9.,";
					insulinTextInput.textEditorProperties.softKeyboardType = SoftKeyboardType.DECIMAL;
					insulinTextInput.text = insulinTextInput.text.split("-").join("");
					insulinTextInput.prompt = ModelLocator.resourceManagerInstance.getString('treatments','basal_amount_absolute_prompt');
					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_PREFERRED_TEMP_BASAL_MODE, "absolute", true, false);
				}
				else if (basalModeGroup.selectedItem == basalRelativeRadio)
				{
					insulinTextInput.restrict = "0-9.,\\-";
					insulinTextInput.textEditorProperties.softKeyboardType = SoftKeyboardType.PUNCTUATION;
					insulinTextInput.prompt = ModelLocator.resourceManagerInstance.getString('treatments','basal_amount_relative_prompt');
					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_PREFERRED_TEMP_BASAL_MODE, "relative", true, false);
				}
			}
			
			function onTempBasalStartEntered (e:Event):void
			{
				if (addButton != null) addButton.removeEventListener(Event.TRIGGERED, onTempBasalStartEntered);
				
				if (insulinTextInput == null || insulinTextInput.text == null || basalDurationTextInput == null || basalDurationTextInput.text == null || !SpikeANE.appIsInForeground())
					return;
				
				function onAskNewBasal():void
				{
					addTreatment(type);
				}
				
				insulinTextInput.text = insulinTextInput.text.replace(" ", "");
				var insulinValue:Number = Number((insulinTextInput.text as String).replace(",","."));
				var tempBasalDuration:Number = Number((basalDurationTextInput.text as String).replace(",","."));
				
				if (isNaN(insulinValue) || insulinTextInput.text == "") 
				{
					AlertManager.showSimpleAlert
					(
						ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
						ModelLocator.resourceManagerInstance.getString('treatments','non_numeric_insulin'),
						Number.NaN,
						onAskNewBasal
					);
				}
				else if (isNaN(tempBasalDuration) || basalDurationTextInput.text == "") 
				{
					AlertManager.showSimpleAlert
					(
						ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
						ModelLocator.resourceManagerInstance.getString('treatments','non_numeric_duration'),
						Number.NaN,
						onAskNewBasal
					);					
				}
				else
				{
					//Create Basal Treatment
					var tempBasalStartTreatment:Treatment = new Treatment
					(
						Treatment.TYPE_TEMP_BASAL,
						treatmentTime.value.valueOf(),
						0,
						insulinList.selectedItem.id,
						0,
						0,
						0,
						notes.text
					);
					
					if (basalModeGroup.selectedItem == basalAbsoluteRadio)
					{
						tempBasalStartTreatment.basalAbsoluteAmount = Math.abs(insulinValue);
						tempBasalStartTreatment.isBasalAbsolute = true;
					}
					else if (basalModeGroup.selectedItem == basalRelativeRadio)
					{
						tempBasalStartTreatment.basalPercentAmount = insulinValue;
						tempBasalStartTreatment.isBasalRelative = true;
					}
					
					tempBasalStartTreatment.basalDuration = tempBasalDuration;
					
					//Add to list
					basalsList.push(tempBasalStartTreatment);
					basalsMap[tempBasalStartTreatment.ID] = tempBasalStartTreatment;
					
					Trace.myTrace("TreatmentsManager.as", "Added treatment to Spike. Type: " + tempBasalStartTreatment.type);
					
					//Notify listeners
					_instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.NEW_BASAL_DATA));
					_instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.BASAL_TREATMENT_ADDED, false, false, tempBasalStartTreatment));
					
					//Insert in DB
					if (!CGMBlueToothDevice.isFollower() || ModelLocator.INTERNAL_TESTING)
						Database.insertTreatmentSynchronous(tempBasalStartTreatment);
					
					//Upload to Nightscout
					NightscoutService.uploadTreatment(tempBasalStartTreatment);
				}
				
				if (treatmentCallout != null) treatmentCallout.close();
			}
			
			function onTempBasalEndEntered (e:Event):void
			{
				if (addButton != null) addButton.removeEventListener(Event.TRIGGERED, onTempBasalEndEntered);
				
				if (!SpikeANE.appIsInForeground())
					return;
				
				function onAskNewBasal():void
				{
					addTreatment(type);
				}
				
				//Create Basal Treatment
				var tempBasalEndTreatment:Treatment = new Treatment
				(
					Treatment.TYPE_TEMP_BASAL,
					treatmentTime.value.valueOf(),
					0,
					"",
					0,
					0,
					0,
					notes.text
				);
				
				tempBasalEndTreatment.basalAbsoluteAmount = 0;
				tempBasalEndTreatment.basalPercentAmount = 0;
				tempBasalEndTreatment.isBasalAbsolute = false;
				tempBasalEndTreatment.isBasalRelative = false;
				tempBasalEndTreatment.isTempBasalEnd = true;
				tempBasalEndTreatment.basalDuration = 30;
				
				//Add to list
				basalsList.push(tempBasalEndTreatment);
				basalsMap[tempBasalEndTreatment.ID] = tempBasalEndTreatment;
				
				Trace.myTrace("TreatmentsManager.as", "Added treatment to Spike. Type: " + Treatment.TYPE_TEMP_BASAL_END);
				
				//Notify listeners
				_instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.NEW_BASAL_DATA));
				_instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.BASAL_TREATMENT_ADDED, false, false, tempBasalEndTreatment));
				
				//Insert in DB
				if (!CGMBlueToothDevice.isFollower() || ModelLocator.INTERNAL_TESTING)
					Database.insertTreatmentSynchronous(tempBasalEndTreatment);
				
				//Upload to Nightscout
				NightscoutService.uploadTreatment(tempBasalEndTreatment);
				
				//Close Callout
				if (treatmentCallout != null) treatmentCallout.close();
			}
			
			function onPenBasalEntered (e:Event):void
			{
				if (addButton != null) addButton.removeEventListener(Event.TRIGGERED, onTempBasalEndEntered);
				
				if (!SpikeANE.appIsInForeground())
					return;
				
				function onAskNewBasal():void
				{
					addTreatment(type);
				}
				
				insulinTextInput.text = insulinTextInput.text.replace(" ", "");
				var insulinValue:Number = Number((insulinTextInput.text as String).replace(",","."));
				if (isNaN(insulinValue) || insulinTextInput.text == "" || insulinValue == 0) 
				{
					AlertManager.showSimpleAlert
						(
							ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
							ModelLocator.resourceManagerInstance.getString('treatments','non_numeric_insulin'),
							Number.NaN,
							onAskNewBasal
						);
				}
				else
				{
					//Create Basal Treatment
					var penBasalTreatment:Treatment = new Treatment
					(
						Treatment.TYPE_MDI_BASAL,
						treatmentTime.value.valueOf(),
						0,
						insulinList.selectedItem.id,
						0,
						0,
						0,
						notes.text
					);
					
					penBasalTreatment.basalAbsoluteAmount = Math.abs(insulinValue);
					penBasalTreatment.isBasalAbsolute = true;
					penBasalTreatment.basalDuration = penBasalTreatment.dia * 60;
					
					//Add to list
					basalsList.push(penBasalTreatment);
					basalsMap[penBasalTreatment.ID] = penBasalTreatment;
					
					Trace.myTrace("TreatmentsManager.as", "Added treatment to Spike. Type: " + penBasalTreatment.type);
					
					//Notify listeners
					_instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.NEW_BASAL_DATA));
					_instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.BASAL_TREATMENT_ADDED, false, false, penBasalTreatment));
					
					//Insert in DB
					if (!CGMBlueToothDevice.isFollower() || ModelLocator.INTERNAL_TESTING)
						Database.insertTreatmentSynchronous(penBasalTreatment);
					
					//Upload to Nightscout
					NightscoutService.uploadTreatment(penBasalTreatment);
				}
				
				//Close Callout
				if (treatmentCallout != null) treatmentCallout.close();
			}
			
			function onInsulinEntered (e:Event):void
			{
				if (addButton != null) addButton.removeEventListener(Event.TRIGGERED, onInsulinEntered);
				
				if (insulinTextInput == null || insulinTextInput.text == null || !SpikeANE.appIsInForeground())
					return;
				
				function onAskNewBolus():void
				{
					addTreatment(type);
				}
				
				insulinTextInput.text = insulinTextInput.text.replace(" ", "");
				var insulinValue:Number = Number((insulinTextInput.text as String).replace(",","."));
				if (isNaN(insulinValue) || insulinTextInput.text == "") 
				{
					AlertManager.showSimpleAlert
					(
						ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
						ModelLocator.resourceManagerInstance.getString('treatments','non_numeric_insulin'),
						Number.NaN,
						onAskNewBolus
					);
				}
				else
				{
					if ((extendedBolusCheck != null && !extendedBolusCheck.isSelected) || (firstSplitNumericStepper != null && firstSplitNumericStepper.value == 100))
					{
						var treatment:Treatment = new Treatment
						(
							Treatment.TYPE_BOLUS,
							treatmentTime.value.valueOf(),
							insulinValue,
							insulinList.selectedItem.id,
							0,
							0,
							getEstimatedGlucose(treatmentTime.value.valueOf()),
							notes.text
						);
						
						//Add to list
						treatmentsList.push(treatment);
						treatmentsMap[treatment.ID] = treatment;
						
						Trace.myTrace("TreatmentsManager.as", "Added treatment to Spike. Type: " + treatment.type);
						
						//Notify listeners
						_instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.TREATMENT_ADDED, false, false, treatment));
						
						//Insert in DB
						if (!CGMBlueToothDevice.isFollower() || ModelLocator.INTERNAL_TESTING)
							Database.insertTreatmentSynchronous(treatment);
						
						//Upload to Nightscout
						NightscoutService.uploadTreatment(treatment);
					}
					else
					{
						if (extendedBolusCheck != null && extendedBolusCheck.isSelected && firstSplitNumericStepper != null && firstSplitNumericStepper.value != 100 && lastSplitNumericStepper != null && lastSplitNumericStepper.value != 0 && extendedDurationNumericStepper != null && extendedDurationNumericStepper.value != 0)
						{
							//Add extended bolus treatment to Spike
							addExtendedBolusTreatment
							(
								insulinValue, 
								0,
								firstSplitNumericStepper.value, 
								lastSplitNumericStepper.value, 
								extendedDurationNumericStepper.value, 
								insulinList.selectedItem.id, 
								treatmentTime.value.valueOf(),
								notes.text,
								null,
								Number.NaN,
								true
							);
						}
						else
						{
							AlertManager.showSimpleAlert
							(
								ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
								ModelLocator.resourceManagerInstance.getString('treatments','treatment_insertion_error_label'),
								Number.NaN,
								onAskNewBolus
							);
							
							return;
						}
					}
				}
				
				if (treatmentCallout != null) treatmentCallout.close();
			}
			
			function onCarbsEntered (e:Event):void
			{

				if (addButton != null) addButton.removeEventListener(Event.TRIGGERED, onCarbsEntered);
				
				if (carbsTextInput == null || carbsTextInput.text == null || !SpikeANE.appIsInForeground())
					return;
				
				carbsTextInput.text = carbsTextInput.text.replace(" ", "");
				var carbsValue:Number = Number((carbsTextInput.text as String).replace(",","."));
				if (isNaN(carbsValue) || carbsTextInput.text == "") 
				{
					AlertManager.showSimpleAlert
					(
						ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
						ModelLocator.resourceManagerInstance.getString('treatments','non_numeric_carbs'),
						Number.NaN,
						onAskNewCarbs
					);
					
					function onAskNewCarbs():void
					{
						addTreatment(type);
					}
				}
				else
				{
					//Carb absorption delay
					var selectedCarbDelayIndex:int = carbDelayGroup != null && carbDelayGroup.selectedIndex >= 0 ? carbDelayGroup.selectedIndex : -1;
					var carbDelayMinutes:Number = 20;
					if (selectedCarbDelayIndex == 0)
						carbDelayMinutes = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CARB_FAST_ABSORTION_TIME));
					else if (selectedCarbDelayIndex == 1)
						carbDelayMinutes = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CARB_MEDIUM_ABSORTION_TIME));
					else if (selectedCarbDelayIndex == 2)
						carbDelayMinutes = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CARB_SLOW_ABSORTION_TIME));
					
					var treatment:Treatment = new Treatment
					(
						Treatment.TYPE_CARBS_CORRECTION,
						treatmentTime.value.valueOf(),
						0,
						"",
						carbsValue,
						0,
						getEstimatedGlucose(treatmentTime.value.valueOf()),
						notes.text,
						null,
						carbDelayMinutes
					);
					
					//Add to list
					treatmentsList.push(treatment);
					treatmentsMap[treatment.ID] = treatment;
					
					Trace.myTrace("TreatmentsManager.as", "Added treatment to Spike. Type: " + treatment.type);
					
					//Notify listeners
					_instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.TREATMENT_ADDED, false, false, treatment));
					
					//Insert in DB
					if (!CGMBlueToothDevice.isFollower() || ModelLocator.INTERNAL_TESTING)
						Database.insertTreatmentSynchronous(treatment);
					
					//Upload to Nightscout
					NightscoutService.uploadTreatment(treatment);
				}
				
				if (treatmentCallout != null) treatmentCallout.close();
			}
			
			function onMealEntered (e:Event):void
			{
				if (addButton != null) addButton.removeEventListener(Event.TRIGGERED, onMealEntered);
				
				if (insulinTextInput == null || insulinTextInput.text == null || carbsTextInput == null || carbsTextInput.text == null || carbOffSet == null || !SpikeANE.appIsInForeground())
					return;
				
				insulinTextInput.text = insulinTextInput.text.replace(" ", "");
				carbsTextInput.text = carbsTextInput.text.replace(" ", "");
				var insulinValue:Number = Number((insulinTextInput.text as String).replace(",","."));
				var carbsValue:Number = Number((carbsTextInput.text as String).replace(",","."));
				
				if (isNaN(insulinValue) || insulinTextInput.text == "") 
				{
					AlertManager.showSimpleAlert
					(
						ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
						ModelLocator.resourceManagerInstance.getString('treatments','non_numeric_insulin'),
						Number.NaN,
						onAskNewBolus
					);
					
					function onAskNewBolus():void
					{
						addTreatment(type);
					}
				}
				else if (isNaN(carbsValue) || carbsTextInput.text == "") 
				{
					AlertManager.showSimpleAlert
					(
						ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
						ModelLocator.resourceManagerInstance.getString('treatments','non_numeric_carbs'),
						Number.NaN,
						onAskNewCarbs
					);
					
					function onAskNewCarbs():void
					{
						addTreatment(type);
					}
				}
				else
				{
					//Carb absorption delay
					var selectedCarbDelayIndex:int = carbDelayGroup != null && carbDelayGroup.selectedIndex >= 0 ? carbDelayGroup.selectedIndex : -1;
					var carbDelayMinutes:Number = 20;
					if (selectedCarbDelayIndex == 0)
						carbDelayMinutes = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CARB_FAST_ABSORTION_TIME));
					else if (selectedCarbDelayIndex == 1)
						carbDelayMinutes = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CARB_MEDIUM_ABSORTION_TIME));
					else if (selectedCarbDelayIndex == 2)
						carbDelayMinutes = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CARB_SLOW_ABSORTION_TIME));
					
					if (carbOffSet.value == 0)
					{
						if ((extendedBolusCheck != null && !extendedBolusCheck.isSelected) || (firstSplitNumericStepper != null && firstSplitNumericStepper.value == 100))
						{
							var treatment:Treatment = new Treatment
							(
								Treatment.TYPE_MEAL_BOLUS,
								treatmentTime.value.valueOf(),
								insulinValue,
								insulinList.selectedItem.id,
								carbsValue,
								0,
								getEstimatedGlucose(treatmentTime.value.valueOf()),
								notes.text,
								null,
								carbDelayMinutes
							);
							
							//Add to list
							treatmentsList.push(treatment);
							treatmentsMap[treatment.ID] = treatment;
							
							Trace.myTrace("TreatmentsManager.as", "Added treatment to Spike. Type: " + treatment.type);
							
							//Notify listeners
							_instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.TREATMENT_ADDED, false, false, treatment));
							
							//Insert in DB
							if (!CGMBlueToothDevice.isFollower() || ModelLocator.INTERNAL_TESTING)
								Database.insertTreatmentSynchronous(treatment);
							
							//Upload to Nightscout
							NightscoutService.uploadTreatment(treatment);
						}
						else
						{
							if (extendedBolusCheck != null && extendedBolusCheck.isSelected && firstSplitNumericStepper != null && firstSplitNumericStepper.value != 100 && lastSplitNumericStepper != null && lastSplitNumericStepper.value != 0 && extendedDurationNumericStepper != null && extendedDurationNumericStepper.value != 0)
							{
								//Add extended bolus treatment to Spike
								addExtendedBolusTreatment
								(
									insulinValue, 
									carbsValue,
									firstSplitNumericStepper.value, 
									lastSplitNumericStepper.value, 
									extendedDurationNumericStepper.value, 
									insulinList.selectedItem.id, 
									treatmentTime.value.valueOf(),
									notes.text,
									null,
									carbDelayMinutes,
									true
								);
							}
							else
							{
								AlertManager.showSimpleAlert
								(
									ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
									ModelLocator.resourceManagerInstance.getString('treatments','treatment_insertion_error_label'),
									Number.NaN,
									onAskNewBolus
								);
								
								return;
							}
						}
					}
					else
					{
						/**
						 * WITH CARB OFFSET
						 */
						
						if ((extendedBolusCheck != null && !extendedBolusCheck.isSelected) || (firstSplitNumericStepper != null && firstSplitNumericStepper.value == 100))
						{
							/**
							 * SIMPLE 
							 */
							//Insulin portion
							var treatmentInsulin:Treatment = new Treatment
							(
								Treatment.TYPE_MEAL_BOLUS,
								treatmentTime.value.valueOf(),
								insulinValue,
								insulinList.selectedItem.id,
								0,
								0,
								getEstimatedGlucose(treatmentTime.value.valueOf()),
								notes.text
							);
							treatmentInsulin.preBolus = carbOffSet.value;
							
							//Add to list
							treatmentsList.push(treatmentInsulin);
							treatmentsMap[treatmentInsulin.ID] = treatmentInsulin;
							
							Trace.myTrace("TreatmentsManager.as", "Added treatment to Spike. Type: " + treatmentInsulin.type);
							
							//Carb portion
							var carbTime:Number = treatmentTime.value.valueOf() + (carbOffSet.value * 60 * 1000);
							var nowTime:Number = new Date().valueOf();
							var treatmentCarbs:Treatment = new Treatment
								(
									Treatment.TYPE_MEAL_BOLUS,
									carbTime,
									0,
									insulinList.selectedItem.id,
									carbsValue,
									0,
									getEstimatedGlucose(carbTime <= nowTime ? carbTime : treatmentTime.value.valueOf()),
									notes.text,
									null,
									carbDelayMinutes
								);
							if (carbTime > nowTime) treatmentCarbs.needsAdjustment = true;
							
							//Add to list
							treatmentsList.push(treatmentCarbs);
							treatmentsMap[treatmentCarbs.ID] = treatmentCarbs;
							
							Trace.myTrace("TreatmentsManager.as", "Added treatment to Spike. Type: " + treatmentCarbs.type);
							
							//Notify listeners
							_instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.TREATMENT_ADDED, false, false, treatmentInsulin));
							_instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.TREATMENT_ADDED, false, false, treatmentCarbs));
							
							//Insert in DB
							if (!CGMBlueToothDevice.isFollower() || ModelLocator.INTERNAL_TESTING)
							{
								Database.insertTreatmentSynchronous(treatmentInsulin);
								Database.insertTreatmentSynchronous(treatmentCarbs);
							}
							
							//Upload to Nightscout
							NightscoutService.uploadTreatment(treatmentInsulin);
							NightscoutService.uploadTreatment(treatmentCarbs);
						}
						else
						{
							/**
							 * EXTENDED MEAL
							 */
							if (extendedBolusCheck != null && extendedBolusCheck.isSelected && firstSplitNumericStepper != null && firstSplitNumericStepper.value != 100 && lastSplitNumericStepper != null && lastSplitNumericStepper.value != 0 && extendedDurationNumericStepper != null && extendedDurationNumericStepper.value != 0)
							{
								//Extended Insulin Portion
								addExtendedBolusTreatment
								(
									insulinValue, 
									0,
									firstSplitNumericStepper.value, 
									lastSplitNumericStepper.value, 
									extendedDurationNumericStepper.value, 
									insulinList.selectedItem.id, 
									treatmentTime.value.valueOf(),
									notes.text,
									null,
									carbDelayMinutes,
									true,
									true,
									carbOffSet.value
								);
								
								//Extended Carb Portion
								var extendedCarbTime:Number = treatmentTime.value.valueOf() + (carbOffSet.value * 60 * 1000);
								var extendedNowTime:Number = new Date().valueOf();
								var extendedTreatmentCarbs:Treatment = new Treatment
								(
									Treatment.TYPE_EXTENDED_COMBO_MEAL_PARENT,
									extendedCarbTime,
									0,
									insulinList.selectedItem.id,
									carbsValue,
									0,
									getEstimatedGlucose(extendedCarbTime <= extendedNowTime ? extendedCarbTime : treatmentTime.value.valueOf()),
									notes.text,
									null,
									carbDelayMinutes
								);
								
								if (extendedCarbTime > extendedNowTime) 
									extendedTreatmentCarbs.needsAdjustment = true;
								
								//Add to list
								treatmentsList.push(extendedTreatmentCarbs);
								treatmentsMap[extendedTreatmentCarbs.ID] = extendedTreatmentCarbs;
								
								Trace.myTrace("TreatmentsManager.as", "Added treatment to Spike. Type: " + extendedTreatmentCarbs.type);
								
								//Notify listeners
								_instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.TREATMENT_ADDED, false, false, extendedTreatmentCarbs));
								
								//Insert in DB
								if (!CGMBlueToothDevice.isFollower() || ModelLocator.INTERNAL_TESTING)
								{
									Database.insertTreatmentSynchronous(extendedTreatmentCarbs);
								}
								
								//Upload to Nightscout
								NightscoutService.uploadTreatment(extendedTreatmentCarbs);
							}
							else
							{
								AlertManager.showSimpleAlert
								(
									ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
									ModelLocator.resourceManagerInstance.getString('treatments','treatment_insertion_error_label'),
									Number.NaN,
									onAskNewBolus
								);
								
								return;
							}
						}
					}
				}
				
				if (treatmentCallout != null) treatmentCallout.close();
			}
			
			function onBGCheckEntered (e:Event):void
			{

				if (addButton != null) addButton.removeEventListener(Event.TRIGGERED, onBGCheckEntered);
				
				if (glucoseTextInput == null || glucoseTextInput.text == null || !SpikeANE.appIsInForeground())
					return;
				
				glucoseTextInput.text = glucoseTextInput.text.replace(" ", "");
				var glucoseValue:Number = Number((glucoseTextInput.text as String).replace(",","."));
				if (isNaN(glucoseValue) || glucoseTextInput.text == "") 
				{
					AlertManager.showSimpleAlert
						(
							ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
							ModelLocator.resourceManagerInstance.getString('treatments','non_numeric_glucose'),
							Number.NaN,
							onAskNewGlucose
						);
					
					function onAskNewGlucose():void
					{
						addTreatment(type);
					}
				}
				else
				{
					var glucoseValueToAdd:Number = glucoseValue;
					
					if (glucoseValueToAdd >= 30 && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) != "true")
					{
						//User is on mmol/L but inserted a calibration in mg/dL. Let's do a conversion.
						glucoseValueToAdd = Math.round(glucoseValueToAdd * BgReading.MGDL_TO_MMOLL * 10) / 10;
					}
					
					if (glucoseValueToAdd < 30 && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true")
					{
						//User is on mg/dL but inserted a calibration in mmol/L. Let's do a conversion.
						glucoseValueToAdd = Math.round(glucoseValueToAdd * BgReading.MMOLL_TO_MGDL);
					}
					
					if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) != "true")
					{
						glucoseValueToAdd = Math.round(BgReading.mmolToMgdl(glucoseValueToAdd));
					}
					
					var treatment:Treatment = new Treatment
					(
						Treatment.TYPE_GLUCOSE_CHECK,
						treatmentTime.value.valueOf(),
						0,
						"",
						0,
						glucoseValueToAdd,
						glucoseValueToAdd,
						notes.text
					);
					
					//Add to list
					treatmentsList.push(treatment);
					treatmentsMap[treatment.ID] = treatment;
					
					Trace.myTrace("TreatmentsManager.as", "Added treatment to Spike. Type: " + treatment.type);
					
					//Notify listeners
					_instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.TREATMENT_ADDED, false, false, treatment));
					
					//Insert in DB
					if (!CGMBlueToothDevice.isFollower() || ModelLocator.INTERNAL_TESTING)
						Database.insertTreatmentSynchronous(treatment);
					
					//Upload to Nightscout
					NightscoutService.uploadTreatment(treatment);
				}
				
				if (treatmentCallout != null) treatmentCallout.close();
			}
			
			function onNoteEntered (e:Event):void
			{
				if (addButton != null) addButton.removeEventListener(Event.TRIGGERED, onNoteEntered);
				
				if (notes == null || notes.text == null || !SpikeANE.appIsInForeground())
					return;
				
				if (notes.text == "")
				{
					AlertManager.showSimpleAlert
						(
							ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
							ModelLocator.resourceManagerInstance.getString('treatments','empty_note'),
							Number.NaN,
							onAskNewNote
						);
					
					function onAskNewNote():void
					{
						addTreatment(type);
					}
				}
				else
				{
					var treatment:Treatment = new Treatment
					(
						Treatment.TYPE_NOTE,
						treatmentTime.value.valueOf(),
						0,
						"",
						0,
						0,
						getEstimatedGlucose(treatmentTime.value.valueOf()),
						notes.text
					)
					
					//Add to list
					treatmentsList.push(treatment);
					treatmentsMap[treatment.ID] = treatment;
					
					Trace.myTrace("TreatmentsManager.as", "Added treatment to Spike. Type: " + treatment.type);
					
					//Notify listeners
					_instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.TREATMENT_ADDED, false, false, treatment));
					
					//Insert in DB
					if (!CGMBlueToothDevice.isFollower() || ModelLocator.INTERNAL_TESTING)
						Database.insertTreatmentSynchronous(treatment);
					
					//Upload to Nightscout
					NightscoutService.uploadTreatment(treatment);
				}
				
				if (treatmentCallout != null) treatmentCallout.close();
			}
			
			function onConfigureInsulins(e:Event):void
			{
				if (createInsulinButton != null) createInsulinButton.removeEventListener(Event.TRIGGERED, onConfigureInsulins);
				
				AppInterface.instance.navigator.pushScreen( Screens.SETTINGS_PROFILE );
				
				var popupTween:Tween=new Tween(treatmentCallout, 0.3, Transitions.LINEAR);
				popupTween.fadeTo(0);
				popupTween.onComplete = function():void
				{
					treatmentCallout.close();
				}
				Starling.juggler.add(popupTween);
			}
			
			function onLoadFoodManager(e:Event):void
			{
				var contentWidth:Number = Constants.stageWidth - (Constants.stageWidth * 0.2);
				
				if (contentWidth < 270)
					contentWidth = 270;
				else if (contentWidth > 500)
					contentWidth = 500;
				
				var suggestedCalloutHeight:Number = Constants.stageHeight - yPos - 10;
				
				if (suggestedCalloutHeight > 730)
					suggestedCalloutHeight = 730;
				
				treatmentCallout.paddingRight = 10;
				treatmentCallout.width = contentWidth + treatmentCallout.paddingLeft + treatmentCallout.paddingRight + 10;
				treatmentCallout.height = suggestedCalloutHeight;
				
				if (foodManager == null)
				{	
					foodManager = new FoodManager(contentWidth, treatmentCallout.height - treatmentCallout.paddingTop - treatmentCallout.paddingBottom - 30, true);
					foodManager.addEventListener(Event.COMPLETE, onFoodManagerCompleted);
					totalScrollContainer.addChild(foodManager);
				}
				
				totalScrollContainer.scrollToPageIndex( 1, totalScrollContainer.verticalPageIndex );
			}
			
			function onFoodManagerCompleted(e:Event):void
			{
				if (treatmentCallout != null)
				{
					//Readjust Layout
					treatmentCallout.width = treatmentCallOutWidth;
					treatmentCallout.height = treatmentCallOutHeight;
					treatmentCallout.paddingRight = treatmentCallOutPaddingRight;
					contentScrollContainer.width = contentScrollContainerWidth;
					contentScrollContainer.height = contentScrollContainerHeight;
					totalScrollContainer.width = totalScrollContainerWidth;
					totalScrollContainer.height = totalScrollContainerHeight;
					
					var fiberPrecision:Number = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FOOD_MANAGER_FIBER_PRECISION));
					
					//Calculate all food carbs the user has added to the food manager
					var totalCarbs:Number = 0;
					var foodsList:Array = foodManager.cartList;
					var addedFoods:int = 0;
					var addedFoodNames:Array = [];
					
					for (var i:int = 0; i < foodsList.length; i++) 
					{
						var food:Food = foodsList[i].food;
						var quantity:Number = foodsList[i].quantity;
						var multiplier:Number = foodsList[i].multiplier;
						var carbs:Number = food.carbs;
						var fiber:Number = food.fiber;
						var substractFiber:Boolean = foodsList[i].substractFiber;
						var servingSize:Number = food.servingSize;
						var servingUnit:String = food.servingUnit;
						var defaultUnit:Boolean = food.defaultUnit;
						
						if (food == null || isNaN(quantity) || isNaN(multiplier) || isNaN(carbs)) 
							continue;
						
						if (multiplier != 1)
						{
							quantity = quantity * servingSize;
							servingUnit = foodsList[i].globalUnit != null && foodsList[i].globalUnit != "" ? foodsList[i].globalUnit : servingUnit;
						}
						
						if (substractFiber && !isNaN(fiber))
							carbs -= fiberPrecision == 1 ? fiber : (fiber / 2);
						
						var finalCarbs:Number = (quantity / servingSize) * carbs * multiplier;
						if (!isNaN(finalCarbs))
						{
							totalCarbs += finalCarbs;
							addedFoods += 1;
							addedFoodNames.push(foodsList[i].quantity + (multiplier != 1 || !defaultUnit ? " x " : " ") + servingUnit + " " + food.name);
						}
					}
					
					totalCarbs = Math.round(totalCarbs * 10) / 10;
					
					//Populate the carbs numeric stepper with all carbs from the food manager
					carbsTextInput.text = totalCarbs != 0 ? String(totalCarbs) : "";
					
					//Update foods label
					if (addedFoods > 0 && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FOOD_MANAGER_IMPORT_FOODS_AS_NOTE) == "true")
					{
						notes.text = addedFoodNames.join(", ");
					}
					
					//Scroll to the Bolus Wizard screen
					totalScrollContainer.scrollToPageIndex( 0, totalScrollContainer.verticalPageIndex );
				}
			}
			
			function onClearFocus(e:Event):void
			{
				if (insulinTextInput != null)
					insulinTextInput.clearFocus();
				
				if (carbsTextInput != null)
					carbsTextInput.clearFocus();
				
				if (glucoseTextInput != null)
					glucoseTextInput.clearFocus();
				
				if (notes != null)
					notes.clearFocus();
				
				if (exerciseDurationTextInput != null)
					exerciseDurationTextInput.clearFocus();
			}
			
			function onBolusExtendedChanged(e:Event):void
			{
				if (extendedBolusCheck.isSelected)
				{
					if (extendedBolusMainContainer != null)
					{
						extendedBolusSplitContainer1 = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.LEFT);
						extendedBolusSplitContainer1.width = extendedBolusMainContainer.width;
						extendedBolusMainContainer.addChild(extendedBolusSplitContainer1);
						
						firstSplitLabel = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('treatments',"extended_bolus_split_label") + " 1 (%)" + ":");
						firstSplitNumericStepper = LayoutFactory.createNumericStepper(0, 100, 100, 5);
						firstSplitNumericStepper.addEventListener(Event.CHANGE, onFirstSplitStepperChanged);
						extendedBolusSplitContainer1.addChild(firstSplitLabel);
						extendedBolusSplitContainer1.addChild(firstSplitNumericStepper);
						firstSplitNumericStepper.validate();
						extendedBolusSplitContainer1.validate();
						firstSplitNumericStepper.x = extendedBolusMainContainer.width - firstSplitNumericStepper.width + 12;
						
						extendedBolusSplitContainer2 = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.LEFT);
						extendedBolusSplitContainer2.width = extendedBolusMainContainer.width;
						extendedBolusMainContainer.addChild(extendedBolusSplitContainer2);
						
						lastSplitLabel = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('treatments',"extended_bolus_split_label") + " 2 (%)" + ":");
						lastSplitNumericStepper = LayoutFactory.createNumericStepper(0, 100, 0, 5);
						lastSplitNumericStepper.addEventListener(Event.CHANGE, onLastSplitStepperChanged);
						extendedBolusSplitContainer2.addChild(lastSplitLabel);
						extendedBolusSplitContainer2.addChild(lastSplitNumericStepper);
						lastSplitNumericStepper.validate();
						extendedBolusSplitContainer2.validate();
						lastSplitNumericStepper.x = extendedBolusMainContainer.width - lastSplitNumericStepper.width + 12;
						
						extendedBolusDurationContainer = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.LEFT);
						extendedBolusDurationContainer.width = extendedBolusMainContainer.width;
						extendedBolusMainContainer.addChild(extendedBolusDurationContainer);
						
						extendedDurationLabel = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('treatments',"extended_bolus_duration_minutes_label") + ":");
						extendedDurationNumericStepper = LayoutFactory.createNumericStepper(10, 1000, 120, 5);
						extendedBolusDurationContainer.addChild(extendedDurationLabel);
						extendedBolusDurationContainer.addChild(extendedDurationNumericStepper);
						extendedDurationNumericStepper.validate();
						extendedBolusDurationContainer.validate();
						extendedDurationNumericStepper.x = extendedBolusMainContainer.width - extendedDurationNumericStepper.width + 12;
					}
				}
				else
				{
					disposeExtendedBolusComponents();
				}
				
				//Readjust callout
				
				if (treatmentInserterContainer != null && treatmentCallout != null && contentScrollContainer != null && totalScrollContainer != null)
				{
					treatmentInserterContainer.invalidate();
					contentScrollContainer.invalidate();
					totalScrollContainer.invalidate();
					treatmentCallout.invalidate();
					
					treatmentInserterContainer.validate();
					var contentOriginalHeight:Number = treatmentInserterContainer.height + 60;
					var suggestedCalloutHeight:Number = Constants.stageHeight - yPos - 10;
					var finalCalloutHeight:Number = contentOriginalHeight > suggestedCalloutHeight ?  suggestedCalloutHeight : contentOriginalHeight;
					
					treatmentCallout.height = finalCalloutHeight;
					treatmentCallout.validate();
					
					contentScrollContainer.height = finalCalloutHeight - 50;
					contentScrollContainer.maxHeight = finalCalloutHeight - 50;
					contentScrollContainer.validate();
					totalScrollContainer.height = finalCalloutHeight - 50;
					totalScrollContainer.maxHeight = finalCalloutHeight - 50;
					totalScrollContainer.validate();
				}
			}
			
			function onFirstSplitStepperChanged(e:Event):void
			{
				if (firstSplitNumericStepper != null && lastSplitNumericStepper != null)
				{
					lastSplitNumericStepper.value = 100 - firstSplitNumericStepper.value;
				}
			}
			
			function onLastSplitStepperChanged(e:Event):void
			{
				if (firstSplitNumericStepper != null && lastSplitNumericStepper != null)
				{
					firstSplitNumericStepper.value = 100 - lastSplitNumericStepper.value;
				}
			}
			
			function onStarlingResize(e:ResizeEvent):void
			{
				if (!SystemUtil.isApplicationActive)
				{
					SystemUtil.executeWhenApplicationIsActive(onStarlingResize, e);
					return;
				}
				
				if (calloutPositionHelper != null && treatmentInserterContainer != null && treatmentCallout != null)
				{
					if (!isNaN(Constants.headerHeight))
						yPos = Constants.headerHeight - 10;
					else
					{
						if (Constants.deviceModel != DeviceInfo.IPHONE_X_Xs_XsMax_Xr)
							yPos = 68;
						else
							yPos = Constants.isPortrait ? 98 : 68;
					}
					calloutPositionHelper.y = yPos;
					calloutPositionHelper.x = Constants.stageWidth / 2;
					
					treatmentInserterContainer.validate();
					contentOriginalHeight = treatmentInserterContainer.height + 60;
					suggestedCalloutHeight = Constants.stageHeight - yPos - 10;
					finalCalloutHeight = contentOriginalHeight > suggestedCalloutHeight ?  suggestedCalloutHeight : contentOriginalHeight;
					
					if (finalCalloutHeight != contentOriginalHeight)
					{
						contentScrollContainerLayout.paddingRight = 10;
						treatmentCallout.paddingRight = 10;
					}
					treatmentCallout.height = finalCalloutHeight;
					treatmentCallout.validate();
					
					contentScrollContainer.height = finalCalloutHeight - 50;
					contentScrollContainer.maxHeight = finalCalloutHeight - 50;
					contentScrollContainer.validate();
					totalScrollContainer.height = finalCalloutHeight - 50;
					totalScrollContainer.maxHeight = finalCalloutHeight - 50;
					totalScrollContainer.validate();
					
					treatmentCallOutWidth = treatmentCallout.width;
					treatmentCallOutHeight = treatmentCallout.height;
					treatmentCallOutPaddingRight = treatmentCallout.paddingRight;
					contentScrollContainerWidth = contentScrollContainer.width;
					contentScrollContainerHeight = contentScrollContainer.height;
					totalScrollContainerWidth = totalScrollContainer.width;
					totalScrollContainerHeight = totalScrollContainer.height;
				}
			}
			
			function disposeExtendedBolusComponents():void
			{
				if (firstSplitLabel != null)
				{
					firstSplitLabel.removeFromParent(true);
					firstSplitLabel = null;
				}
				
				if (firstSplitNumericStepper != null)
				{
					firstSplitNumericStepper.removeEventListener(Event.CHANGE, onFirstSplitStepperChanged);
					firstSplitNumericStepper.removeFromParent(true);
					firstSplitNumericStepper = null;
				}
				
				if (extendedBolusSplitContainer1 != null)
				{
					extendedBolusSplitContainer1.removeFromParent(true);
					extendedBolusSplitContainer1 = null;
				}
				
				if (lastSplitLabel != null)
				{
					lastSplitLabel.removeFromParent(true);
					lastSplitLabel = null;
				}
				
				if (lastSplitNumericStepper != null)
				{
					lastSplitNumericStepper.removeEventListener(Event.CHANGE, onLastSplitStepperChanged);
					lastSplitNumericStepper.removeFromParent(true);
					lastSplitNumericStepper = null;
				}
				
				if (extendedBolusSplitContainer2 != null)
				{
					extendedBolusSplitContainer2.removeFromParent(true);
					extendedBolusSplitContainer2 = null;
				}
				
				if (extendedDurationLabel != null)
				{
					extendedDurationLabel.removeFromParent(true);
					extendedDurationLabel = null;
				}
				
				if (extendedDurationNumericStepper != null)
				{
					extendedDurationNumericStepper.removeFromParent(true);
					extendedDurationNumericStepper = null;
				}
				
				if (extendedBolusDurationContainer != null)
				{
					extendedBolusDurationContainer.removeFromParent(true);
					extendedBolusDurationContainer = null;
				}
			}
			
			function onTreatmentsCalloutClosed(e:Event):void
			{
				Starling.current.stage.removeEventListener(starling.events.Event.RESIZE, onStarlingResize);
				
				//Dispose Components	
				if (foodManager != null)
				{
					foodManager.removeEventListener(Event.COMPLETE, onFoodManagerCompleted);
					foodManager.dispose();
					foodManager = null;
				}
				
				if (treatmentInserterTitleLabel != null)
				{
					treatmentInserterTitleLabel.removeFromParent();
					treatmentInserterTitleLabel.dispose();
					treatmentInserterTitleLabel = null;
				}
				
				if (insulinTextInput != null)
				{
					insulinTextInput.removeEventListener(FeathersEventType.ENTER, onClearFocus);
					insulinTextInput.removeFromParent();
					insulinTextInput.dispose();
					insulinTextInput = null;
				}
				
				disposeExtendedBolusComponents();
				
				if (extendedBolusCheck != null)
				{
					extendedBolusCheck.removeEventListener(Event.CHANGE, onBolusExtendedChanged);
					extendedBolusCheck.removeFromParent();
					extendedBolusCheck.dispose();
					extendedBolusCheck = null;
				}
				
				if (extendedBolusMainContainer != null)
				{
					extendedBolusMainContainer.removeFromParent();
					extendedBolusMainContainer.dispose();
					extendedBolusMainContainer = null;
				}
				
				if (glucoseTextInput != null)
				{
					glucoseTextInput.removeEventListener(FeathersEventType.ENTER, onClearFocus);
					glucoseTextInput.removeFromParent();
					glucoseTextInput.dispose();
					glucoseTextInput = null;
				}
				
				if (carbsTextInput != null)
				{
					carbsTextInput.removeEventListener(FeathersEventType.ENTER, onClearFocus);
					carbsTextInput.removeFromParent();
					carbsTextInput.dispose();
					carbsTextInput = null;
				}
				
				if (notes != null)
				{
					notes.removeEventListener(FeathersEventType.ENTER, onClearFocus);
					notes.removeFromParent();
					notes.dispose();
					notes = null;
				}
				
				if (cancelButton != null)
				{
					cancelButton.removeEventListener(Event.TRIGGERED, closeCallout);
					cancelButton.removeFromParent();
					cancelButton.dispose();
					cancelButton = null;
				}
				
				if (addButton != null)
				{
					addButton.removeEventListener(Event.TRIGGERED, actionFunction);
					addButton.removeFromParent();
					addButton.dispose();
					addButton = null;
				}
				
				if (createInsulinButton != null)
				{
					createInsulinButton.removeEventListener(Event.TRIGGERED, onConfigureInsulins);
					createInsulinButton.removeFromParent();
					createInsulinButton.dispose();
					createInsulinButton = null;
				}
				
				if (foodManagerButton != null)
				{
					foodManagerButton.removeEventListener(Event.TRIGGERED, onLoadFoodManager);
					foodManagerButton.removeFromParent();
					foodManagerButton.dispose();
					foodManagerButton = null;
				}
				
				if (insulinSpacer != null)
				{
					insulinSpacer.removeFromParent();
					insulinSpacer.dispose();
					insulinSpacer = null;
				}
				
				if (glucoseSpacer != null)
				{
					glucoseSpacer.removeFromParent();
					glucoseSpacer.dispose();
					glucoseSpacer = null;
				}
				
				if (carbOffSet != null)
				{
					carbOffSet.removeFromParent();
					carbOffSet.dispose();
					carbOffSet = null;
				}
				
				if (carbOffsetSuffix != null)
				{
					carbOffsetSuffix.removeFromParent();
					carbOffsetSuffix.dispose();
					carbOffsetSuffix = null;
				}
				
				if (fastCarb != null)
				{
					fastCarb.removeFromParent();
					fastCarb.dispose();
					fastCarb = null;
				}
				
				if (mediumCarb != null)
				{
					mediumCarb.removeFromParent();
					mediumCarb.dispose();
					mediumCarb = null;
				}
				
				if (slowCarb != null)
				{
					slowCarb.removeFromParent();
					slowCarb.dispose();
					slowCarb = null;
				}
				
				if (carbSpacer != null)
				{
					carbSpacer.removeFromParent();
					carbSpacer.dispose();
					carbSpacer = null;
				}
				
				if (noteSpacer != null)
				{
					noteSpacer.removeFromParent();
					noteSpacer.dispose();
					noteSpacer = null;
				}
				
				if (treatmentTime != null)
				{
					treatmentTime.removeFromParent();
					treatmentTime.dispose();
					treatmentTime = null;
				}
				
				if (treatmentSpacer != null)
				{
					treatmentSpacer.removeFromParent();
					treatmentSpacer.dispose();
					treatmentSpacer = null;
				}
				
				if (insulinList != null)
				{
					insulinList.removeFromParent();
					insulinList.dispose();
					insulinList = null;
				}
				
				if (calloutPositionHelper != null)
				{
					calloutPositionHelper.removeFromParent();
					calloutPositionHelper.dispose();
					calloutPositionHelper = null;
				}
				
				if (highIntendity != null)
				{
					highIntendity.removeFromParent();
					highIntendity.dispose();
					highIntendity = null;
				}
				
				if (moderateIntensity != null)
				{
					moderateIntensity.removeFromParent();
					moderateIntensity.dispose();
					moderateIntensity = null;
				}
				
				if (lowIntensity != null)
				{
					lowIntensity.removeFromParent();
					lowIntensity.dispose();
					lowIntensity = null;
				}
				
				if (exerciseIntensityContainer != null)
				{
					exerciseIntensityContainer.removeFromParent();
					exerciseIntensityContainer.dispose();
					exerciseIntensityContainer = null;
				}
				
				if (exerciseChangerSpacer != null)
				{
					exerciseChangerSpacer.removeFromParent();
					exerciseChangerSpacer.dispose();
					exerciseChangerSpacer = null;
				}
				
				if (exerciseDurationTextInput != null)
				{
					exerciseDurationTextInput.removeEventListener(FeathersEventType.ENTER, onClearFocus);
					exerciseDurationTextInput.removeFromParent();
					exerciseDurationTextInput.dispose();
					exerciseDurationTextInput = null;
				}
				
				if (exerciseChangerSpacer != null)
				{
					exerciseChangerSpacer.removeFromParent();
					exerciseChangerSpacer.dispose();
					exerciseChangerSpacer = null;
				}
				
				if (basalDurationTextInput != null)
				{
					basalDurationTextInput.removeEventListener(FeathersEventType.ENTER, onClearFocus);
					basalDurationTextInput.removeFromParent();
					basalDurationTextInput.dispose();
					basalDurationTextInput = null;
				}
				
				if (basalDurationSpacer != null)
				{
					basalDurationSpacer.removeFromParent();
					basalDurationSpacer.dispose();
					basalDurationSpacer = null;
				}
				
				if (basalAbsoluteRadio != null)
				{
					basalAbsoluteRadio.removeFromParent();
					basalAbsoluteRadio.dispose();
					basalAbsoluteRadio = null;
				}
				
				if (basalRelativeRadio != null)
				{
					basalRelativeRadio.removeFromParent();
					basalRelativeRadio.dispose();
					basalRelativeRadio = null;
				}
				
				if (basalModeContainer != null)
				{
					basalModeContainer.removeFromParent();
					basalModeContainer.dispose();
					basalModeContainer = null;
				}
				
				if (extendedCarbContainer != null)
				{
					extendedCarbContainer.removeFromParent();
					extendedCarbContainer.dispose();
					extendedCarbContainer = null;
				}
				
				if (carbDelayContainer != null)
				{
					carbDelayContainer.removeFromParent();
					carbDelayContainer.dispose();
					carbDelayContainer = null;
				}
				
				if (foodManagerContainer != null)
				{
					foodManagerContainer.removeFromParent();
					foodManagerContainer.dispose();
					foodManagerContainer = null;
				}
				
				if (otherFieldsContainer != null)
				{
					otherFieldsContainer.removeFromParent();
					otherFieldsContainer.dispose();
					otherFieldsContainer = null;
				}
				
				if (actionContainer != null)
				{
					actionContainer.removeFromParent();
					actionContainer.dispose();
					actionContainer = null;
				}
				
				if (totalScrollContainer != null)
				{
					totalScrollContainer.removeFromParent();
					totalScrollContainer.dispose();
					totalScrollContainer = null;
				}
				
				if (contentScrollContainer != null)
				{
					contentScrollContainer.removeFromParent();
					contentScrollContainer.dispose();
					contentScrollContainer = null;
				}
				
				if (treatmentInserterContainer != null)
				{
					treatmentInserterContainer.removeFromParent();
					treatmentInserterContainer.dispose();
					treatmentInserterContainer = null;
				}
				
				if (treatmentCallout != null)
				{
					treatmentCallout.removeEventListener(Event.CLOSE, onTreatmentsCalloutClosed);
					treatmentCallout.disposeContent = true;
					treatmentCallout.removeFromParent();
					treatmentCallout.dispose();
					treatmentCallout = null;
				}
				
				if (basalModeGroup != null)
				{
					basalModeGroup.removeEventListener( Event.CHANGE, onBasalModeChanged);
					basalModeGroup = null;
				}
				
				System.pauseForGCIfCollectionImminent(0);
				System.gc();
			}
		}
		
		public static function addExtendedBolusTreatment(totalInsulinAmount:Number,
														  carbsAmount:Number,
														  firstSplit:Number, 
														  secondSplit:Number, 
														  duration:Number, 
														  insulinID:String, 
														  treatmentTime:Number, 
														  note:String = "",
														  treatmentID:String = null,
														  carbDelayInMinutes:Number = Number.NaN,
														  syncToNightscout:Boolean = true,
														  forceMealTreatment:Boolean = false,
														  carbOffset:Number = Number.NaN
		):void
		{
			var immediateBolusAmount:Number = Math.round(totalInsulinAmount * (firstSplit / 100) * 100) / 100;
			var remainingBolusAmount:Number = totalInsulinAmount - immediateBolusAmount;
			var extendedSteps:Number = Math.round(duration / 5);
			var extendedBolusAmount:Number = Math.round((remainingBolusAmount/extendedSteps) * 100) / 100;
			var latestReading:BgReading = BgReading.lastWithCalculatedValue();
			
			//Extended Bolus Children
			var extendedChildren:Array = [];
			for (var j:int = 0; j < extendedSteps; j++) 
			{
				var extendedTreatmentBolusAmount:Number = j < extendedSteps - 1 ? extendedBolusAmount : remainingBolusAmount;
				
				var childTimestamp:Number = treatmentTime + ((j + 1) * TimeSpan.TIME_5_MINUTES);
				var extendedTreatment:Treatment = new Treatment
					(
						Treatment.TYPE_EXTENDED_COMBO_BOLUS_CHILD,
						childTimestamp,
						extendedTreatmentBolusAmount,
						insulinID,
						0,
						0,
						getEstimatedGlucose(childTimestamp)
					);
				extendedTreatment.needsAdjustment = latestReading != null && latestReading.timestamp >= childTimestamp ? false : true;
				addExternalTreatment(extendedTreatment, false);
				extendedChildren.push(extendedTreatment.ID);
				
				remainingBolusAmount -= extendedTreatmentBolusAmount;
			}
			
			//Extended Bolus Parent
			var extendedParentTreatment:Treatment = new Treatment
			(
				carbsAmount > 0 || forceMealTreatment ? Treatment.TYPE_EXTENDED_COMBO_MEAL_PARENT : Treatment.TYPE_EXTENDED_COMBO_BOLUS_PARENT,
				treatmentTime,
				immediateBolusAmount,
				insulinID,
				carbsAmount,
				0,
				getEstimatedGlucose(treatmentTime),
				note,
				treatmentID,
				carbDelayInMinutes
			);
			extendedParentTreatment.childTreatments = extendedChildren;
			extendedParentTreatment.needsAdjustment = latestReading != null && latestReading.timestamp >= treatmentTime ? false : true;
			if (!isNaN(carbOffset))
			{
				extendedParentTreatment.preBolus = carbOffset;
			}
			
			addExternalTreatment(extendedParentTreatment, syncToNightscout);
		}
		
		private static function sortInsulinsByDefault(insulins:Array):Array
		{
			insulins.sortOn(["name"], Array.CASEINSENSITIVE);
			
			for (var i:int = 0; i < insulins.length; i++) 
			{
				var insulin:Insulin = insulins[i];
				if (insulin.isDefault && !insulin.isHidden)
				{
					//Remove it from the array
					insulins.removeAt(i);
					
					//Add it to the beginning
					insulins.unshift(insulin);
					
					break;
				}
			}
			
			return insulins;
		}
		
		public static function addExternalTreatment(treatment:Treatment, syncToNightscout:Boolean = true):void
		{
			if (treatment == null) 
				return;
			
			Trace.myTrace("TreatmentsManager.as", "addExternalTreatment called! Type: " + treatment.type);
			
			//Save settings
			if (treatment.type == Treatment.TYPE_INSULIN_CARTRIDGE_CHANGE)
			{
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_LAST_INSULIN_CARTRIDGE_CHANGE, String(treatment.timestamp), true, false);
			}
			else if (treatment.type == Treatment.TYPE_PUMP_BATTERY_CHANGE)
			{
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_LAST_PUMP_BATTERY_CHANGE, String(treatment.timestamp), true, false);
			}
			else if (treatment.type == Treatment.TYPE_PUMP_SITE_CHANGE)
			{
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_LAST_PUMP_SITE_CHANGE, String(treatment.timestamp), true, false);
			}
			
			var sourceList:Array = treatment.type == Treatment.TYPE_MDI_BASAL || treatment.type == Treatment.TYPE_TEMP_BASAL || treatment.type == Treatment.TYPE_TEMP_BASAL_END ? basalsList : treatmentsList;
			var sourceMap:Dictionary = treatment.type == Treatment.TYPE_MDI_BASAL || treatment.type == Treatment.TYPE_TEMP_BASAL || treatment.type == Treatment.TYPE_TEMP_BASAL_END ? basalsMap : treatmentsMap;
			
			//Insert in DB
			if (!CGMBlueToothDevice.isFollower() || ModelLocator.INTERNAL_TESTING)
			{
				if (sourceMap[treatment.ID] == null) //new treatment
					Database.insertTreatmentSynchronous(treatment);
			}
			
			if (sourceMap[treatment.ID] == null) //new treatment
			{
				//Add to list
				sourceList.push(treatment);
				sourceMap[treatment.ID] = treatment;
				
				//Notify listeners
				if (treatment.type == Treatment.TYPE_MDI_BASAL || treatment.type == Treatment.TYPE_TEMP_BASAL || treatment.type == Treatment.TYPE_TEMP_BASAL_END)
				{
					_instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.NEW_BASAL_DATA));
					_instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.BASAL_TREATMENT_ADDED, false, false, treatment));
				}
				else
				{
					_instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.TREATMENT_ADDED, false, false, treatment));
				}
				
				//Upload to Nightscou
				if (syncToNightscout)
					NightscoutService.uploadTreatment(treatment);
				
				Trace.myTrace("TreatmentsManager.as", "Treatment added to Spike");
			}
		}
		
		public static function addInternalCalibrationTreatment(glucoseValue:Number, timestamp:Number, treatmentID:String):void
		{
			Trace.myTrace("TreatmentsManager.as", "addInternalCalibrationTreatment called!");
			
			var treatment:Treatment = new Treatment
			(
				Treatment.TYPE_GLUCOSE_CHECK,
				timestamp,
				0,
				"",
				0,
				glucoseValue,
				glucoseValue,
				ModelLocator.resourceManagerInstance.getString('treatments','sensor_calibration_note'),
				treatmentID
			);
			
			if (treatmentsMap[treatment.ID] == null) //New treatment
			{
				//Insert in DB
				if (!CGMBlueToothDevice.isFollower() || ModelLocator.INTERNAL_TESTING)
					Database.insertTreatmentSynchronous(treatment);
				
				//Add to list
				treatmentsList.push(treatment);
				treatmentsMap[treatment.ID] = treatment;
				
				//Notify listeners
				_instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.TREATMENT_ADDED, false, false, treatment));
				
				Trace.myTrace("TreatmentsManager.as", "Added internal calibration to Spike!");
			}
		}
		
		public static function addInternalSensorStartTreatment(timestamp:Number, treatmentID:String):void
		{
			Trace.myTrace("TreatmentsManager.as", "addInternalSensorStartTreatment called!");
			
			var treatment:Treatment = new Treatment
				(
					Treatment.TYPE_SENSOR_START,
					timestamp,
					0,
					"",
					0,
					0,
					getEstimatedGlucose(timestamp),
					"",
					treatmentID
				);
			
			if (treatmentsMap[treatment.ID] == null) //New treatment
			{
				//Insert in DB
				if (!CGMBlueToothDevice.isFollower() || ModelLocator.INTERNAL_TESTING)
					Database.insertTreatmentSynchronous(treatment);
				
				//Add to list
				treatmentsList.push(treatment);
				treatmentsMap[treatment.ID] = treatment;
				
				//Notify listeners
				_instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.TREATMENT_ADDED, false, false, treatment));
				
				Trace.myTrace("TreatmentsManager.as", "Added sensor start to Spike!");
			}
		}
		
		public static function processNightscoutBasals(nsTreatments:Array):void
		{
			var nightscoutBasalsMap:Dictionary = new Dictionary();
			var newBasalData:Boolean = false;
			var firstReadingTimestamp:Number;
			var lastReadingTimestamp:Number;
			var now:Number = new Date().valueOf();
			var isMDIUser:Boolean = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_USER_TYPE_PUMP_OR_MDI) == "mdi";
			
			if (ModelLocator.bgReadings != null && ModelLocator.bgReadings.length > 0)
			{
				firstReadingTimestamp = (ModelLocator.bgReadings[0] as BgReading).timestamp;
				lastReadingTimestamp = new Date().valueOf();
			}
			else
			{
				//There's still no readings in Spike. Abort!
				return
			}
			
			for (var i:int = nsTreatments.length - 1 ; i >= 0; i--)
			{
				var nsBasal:Object = nsTreatments[i];
				var basalTimestamp:Number = DateUtil.parseW3CDTF(nsBasal.created_at).valueOf();
				if (basalTimestamp < firstReadingTimestamp && !isMDIUser)
				{
					//Treatment is outside timespan of first bg reading in spike and user is of type pump. Let's ignore it
					continue; 
				}
				var basalID:String = nsBasal._id != null ? nsBasal._id : UniqueId.createEventId();
				nightscoutBasalsMap[basalID] = nsBasal;
				
				var basalNote:String = "";
				if (nsBasal.reason != null && nsBasal.reason != "")
				{
					basalNote = nsBasal.reason;
				}
				if (nsBasal.notes != null && nsBasal.notes != "")
				{
					if (basalNote != "")
					{
						basalNote += "\n";
					}
					
					basalNote += nsBasal.notes;
				}
				var basalDuration:Number = nsBasal.duration != null && !isNaN(nsBasal.duration) ? nsBasal.duration : 30;
				var basalAbsoluteAmount:Number = nsBasal.absolute != null && !isNaN(nsBasal.absolute) ? nsBasal.absolute : 0;
				var isBasalAbsolute:Boolean = nsBasal.absolute != null && !isNaN(nsBasal.absolute) ? true : false;
				var basalPercentAmount:Number = nsBasal.percent != null && !isNaN(nsBasal.percent) ? nsBasal.percent : 0;
				var isBasalRelative:Boolean = nsBasal.percent != null && !isNaN(nsBasal.percent) && !isBasalAbsolute ? true : false;
				var isTempBasalEnd:Boolean = !isBasalAbsolute && !isBasalRelative;
				var basalInsulinID:String = nsBasal.insulinID != null ? String(nsBasal.insulinID) : "";
				
				if (isMDIUser && basalDuration < 6 * 60)
				{
					//Basal has less than 6h duration. Not relevant for MDI users.
					continue;
				}
				
				if (isTempBasalEnd && basalDuration < 30)
				{
					basalDuration = 30;
				}
				
				//Insulin
				if (isMDIUser && basalInsulinID != "")
				{
					//It's a basal from Spike Master
					var localInsulin:Insulin = ProfileManager.getInsulin(basalInsulinID);
					var basalInsulinName:String = nsBasal.insulinName != null ? nsBasal.insulinName : ModelLocator.resourceManagerInstance.getString("treatments","nightscout_insulin");
					var basalInsulinDIA:Number = nsBasal.insulinDIA != null ? nsBasal.insulinDIA : 24;
					var basalInsulinType:String = nsBasal.insulinType == null ? "Unknown" : String(nsBasal.insulinType);
					
					if (localInsulin == null)
					{
						//Let's create this insulin
						ProfileManager.addInsulin(basalInsulinName, basalInsulinDIA, basalInsulinType, false, basalInsulinID, true, true);
					}
					else
					{
						//Check if insulin needs to be updated
						var needsDBUpdate:Boolean = false;
						if (localInsulin.dia != basalInsulinDIA)
						{
							localInsulin.dia = basalInsulinDIA;
							needsDBUpdate = true;
						}
						
						if (localInsulin.name != basalInsulinName)
						{
							localInsulin.name = basalInsulinName;
							needsDBUpdate = true;
						}
						
						if (needsDBUpdate)
						{
							ProfileManager.updateInsulin(localInsulin, true);
						}
					}
				}
				
				//Check if treatment already exists in Spike
				if (basalsMap[basalID] == null)
				{
					//It's a new treatment. Let's create it
					var basal:Treatment = new Treatment(isMDIUser ? Treatment.TYPE_MDI_BASAL : Treatment.TYPE_TEMP_BASAL, basalTimestamp);
					basal.ID = basalID;
					basal.basalDuration = basalDuration;
					basal.basalAbsoluteAmount = basalAbsoluteAmount;
					basal.isBasalAbsolute = isBasalAbsolute;
					basal.basalPercentAmount = basalPercentAmount;
					basal.isBasalRelative = isBasalRelative;
					basal.isTempBasalEnd = isTempBasalEnd;
					if (isMDIUser)
					{
						basal.insulinID = basalInsulinID;	
					}
					
					//Add treatment to Spike and Databse
					addInternalTreatment(basal);
					
					newBasalData = true;
					
					Trace.myTrace("TreatmentsManager.as", "Added basal treatment!");
				}
				else
				{
					//Treatment exists... Lets check if it was modified
					var wasBasalModified:Boolean = false;
					var spikeBasal:Treatment = basalsMap[basalID];
					
					if (!isNaN(basalDuration) && spikeBasal.basalDuration != basalDuration)
					{
						spikeBasal.basalDuration = basalDuration;
						wasBasalModified = true;
					}
					
					if (!isNaN(basalAbsoluteAmount) && spikeBasal.basalAbsoluteAmount != basalAbsoluteAmount)
					{
						spikeBasal.basalAbsoluteAmount = basalAbsoluteAmount;
						wasBasalModified = true;
					}
					
					if (!isNaN(basalPercentAmount) && spikeBasal.basalPercentAmount != basalPercentAmount)
					{
						spikeBasal.basalPercentAmount = basalPercentAmount;
						wasBasalModified = true;
					}
					
					if (spikeBasal.isBasalAbsolute != isBasalAbsolute)
					{
						spikeBasal.isBasalAbsolute = isBasalAbsolute;
						wasBasalModified = true;
					}
					
					if (spikeBasal.isBasalRelative != isBasalRelative)
					{
						spikeBasal.isBasalRelative = isBasalRelative;
						wasBasalModified = true;
					}
					
					if (spikeBasal.isTempBasalEnd != isTempBasalEnd)
					{
						spikeBasal.isTempBasalEnd = isTempBasalEnd;
						wasBasalModified = true;
					}
						
					if (wasBasalModified)
					{
						//Treatment was modified. Update Spike and notify listeners
						updateTreatment(spikeBasal, false);
						
						newBasalData = true;
						
						Trace.myTrace("TreatmentsManager.as", "Updated nightscout basal treatment.");
					}
				}
			}
			
			//Check for deleted basals in Nightscout
			if (isMDIUser)
			{
				var numSpikeBasals:int = basalsList.length;
				for (var j:int = 0; j <numSpikeBasals; j++) 
				{
					var internalBasal:Treatment = basalsList[j];
					if (nightscoutBasalsMap[internalBasal.ID] == null)
					{
						Trace.myTrace("TreatmentsManager.as", "User deleted MDI basal in Nightscout. Deleting in Spike as well.");
						
						//Treatment is not present in Nightscout. User has deleted it.
						var removeFromDB:Boolean = now - internalBasal.timestamp < TimeSpan.TIME_48_HOURS && (!CGMBlueToothDevice.isFollower() || ModelLocator.INTERNAL_TESTING);
						deleteTreatment(internalBasal, false, true, removeFromDB, true, false);
					}
				}
			}
			
			if (newBasalData)
			{
				//Notify listeners
				_instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.NEW_BASAL_DATA));
			}
		}
		
		public static function processNightscoutTreatments(nsTreatments:Array):void
		{
			Trace.myTrace("TreatmentsManager.as", "processNightscoutTreatments called!");
			
			var nightscoutTreatmentsMap:Dictionary = new Dictionary();
			var numNightscoutTreatments:int = nsTreatments.length;
			var firstReadingTimestamp:Number;
			var lastReadingTimestamp:Number;
			var now:Number = new Date().valueOf();
			
			if (ModelLocator.bgReadings != null && ModelLocator.bgReadings.length > 0)
			{
				firstReadingTimestamp = (ModelLocator.bgReadings[0] as BgReading).timestamp;
				lastReadingTimestamp = new Date().valueOf();
			}
			else
			{
				//There's still no readings in Spike. Abort!
				return
			}
				
			for (var i:int = numNightscoutTreatments - 1 ; i >= 0; i--)
			{
				//Define initial treatment properties
				var nsTreatment:Object = nsTreatments[i];
				var treatmentEventType:String = nsTreatment.eventType;
				var treatmentTimestamp:Number = DateUtil.parseW3CDTF(nsTreatment.created_at).valueOf();
				var treatmentID:String = nsTreatment._id;
				nightscoutTreatmentsMap[treatmentID] = nsTreatment;
				var treatmentType:String = "";
				var treatmentInsulinAmount:Number = 0;
				var treatmentInsulinID:String = "000000"; //Nightscout insulin
				var treatmentCarbs:Number = 0;
				var treatmentGlucose:Number = 0;
				var treatmentNote:String = "";
				var treatmentInsulinName:String = "";
				var treatmentInsulinDIA:Number = Number.NaN;
				var treatmentInsulinPeak:Number = Number.NaN;
				var treatmentInsulinCurve:String = "bilinear";
				var treatmentCarbDelayTime:Number = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEFAULT_CARB_ABSORTION_TIME));
				var treatmentDuration:Number = Number.NaN;
				var treatmentExerciseIntensity:String = Treatment.EXERCISE_INTENSITY_MODERATE;
				
				if (treatmentTimestamp < firstReadingTimestamp)
				{
					//Treatment is outside timespan of first bg reading in spike. Let's ignore it
					continue;
				}
				
				if (nsTreatment.note == ModelLocator.resourceManagerInstance.getString('treatments','sensor_calibration_note') && treatmentEventType == "BG Check")
				{
					//Don't process sensor calibrations
					continue;
				}
				
				//Insulin
				if (nsTreatment.insulinID != null)
				{
					//It's a treatment from Spike Master
					treatmentInsulinID = String(nsTreatment.insulinID);
					var localInsulin:Insulin = ProfileManager.getInsulin(treatmentInsulinID);
					treatmentInsulinName = nsTreatment.insulinName != null ? nsTreatment.insulinName : ModelLocator.resourceManagerInstance.getString("treatments","nightscout_insulin");
					treatmentInsulinDIA = nsTreatment.dia != null ? nsTreatment.dia : ProfileManager.getInsulin("000000").dia;
					treatmentInsulinPeak = nsTreatment.insulinPeak != null ? nsTreatment.insulinPeak : 75;
					treatmentInsulinCurve = nsTreatment.insulinCurve != null ? String(nsTreatment.insulinCurve) : "bilinear";
					
					if (localInsulin == null)
					{
						//Let's create this insulin
						ProfileManager.addInsulin(treatmentInsulinName, treatmentInsulinDIA, nsTreatment.insulinType == null ? "Unknown" : String(nsTreatment.insulinType), false, treatmentInsulinID, true, true, treatmentInsulinCurve, treatmentInsulinPeak);
					}
					else
					{
						//Check if insulin needs to be updated
						var needsDBUpdate:Boolean = false;
						if (localInsulin.dia != treatmentInsulinDIA)
						{
							localInsulin.dia = treatmentInsulinDIA;
							needsDBUpdate = true;
						}
						
						if (localInsulin.name != treatmentInsulinName)
						{
							localInsulin.name = treatmentInsulinName;
							needsDBUpdate = true;
						}
						
						if (localInsulin.peak != treatmentInsulinPeak)
						{
							localInsulin.peak = treatmentInsulinPeak;
							needsDBUpdate = true;
						}
						
						if (localInsulin.curve != treatmentInsulinCurve)
						{
							localInsulin.curve = treatmentInsulinCurve;
							needsDBUpdate = true;
						}
						
						if (needsDBUpdate)
						{
							ProfileManager.updateInsulin(localInsulin, true);
						}
					}
				}
				
				//Carb Delay Time
				if (nsTreatment.carbDelayTime != null)
					treatmentCarbDelayTime = nsTreatment.carbDelayTime;
				
				if (treatmentEventType == "Correction Bolus" || treatmentEventType == "Bolus" || treatmentEventType == "Correction")
				{
					treatmentType = Treatment.TYPE_BOLUS;
					if (nsTreatment.insulin != null)
						treatmentInsulinAmount = Math.round(Number(nsTreatment.insulin) * 100) / 100;
				}
				else if (treatmentEventType == "Meal Bolus" || treatmentEventType == "Snack Bolus")
				{
					treatmentType = Treatment.TYPE_MEAL_BOLUS;
					if (nsTreatment.insulin != null)
						treatmentInsulinAmount = Math.round(Number(nsTreatment.insulin) * 100) / 100;
					if (nsTreatment.carbs != null)
						treatmentCarbs = Number(nsTreatment.carbs);
				}
				else if (treatmentEventType == "Combo Bolus")
				{
					treatmentType = ""; //Set to empty to avoid further processing
					
					var latestReading:BgReading;
					
					if (treatmentsMap[treatmentID] == null)
					{
						if (nsTreatment.enteredinsulin != null && nsTreatment.splitNow != null && nsTreatment.splitExt != null && nsTreatment.duration != null)
						{
							//Add new extended bolus/meal treatment
							addExtendedBolusTreatment
							(
								Math.round(Number(nsTreatment.enteredinsulin) * 100) / 100, 
								nsTreatment.carbs != null ? Number(nsTreatment.carbs) : 0, 
								Number(nsTreatment.splitNow), 
								Number(nsTreatment.splitExt), 
								nsTreatment.duration, 
								treatmentInsulinID, 
								treatmentTimestamp, 
								nsTreatment.notes != null ? String(nsTreatment.notes) : "", 
								treatmentID,
								nsTreatment.carbDelayTime != null ? Number(nsTreatment.carbDelayTime) : Number.NaN,
								false,
								false,
								nsTreatment.preBolus != null ? Number(nsTreatment.preBolus) : Number.NaN
							);
						}
						else if (nsTreatment.insulin == null && nsTreatment.carbs != null)
						{
							//Extended Carb Portion
							latestReading = BgReading.lastWithCalculatedValue();
							var extendedTreatmentCarbs:Treatment = new Treatment
							(
								Treatment.TYPE_EXTENDED_COMBO_MEAL_PARENT,
								treatmentTimestamp,
								0,
								"",
								Number(nsTreatment.carbs),
								0,
								getEstimatedGlucose(treatmentTimestamp),
								nsTreatment.notes != null ? String(nsTreatment.notes) : "",
								treatmentID,
								nsTreatment.carbDelayTime != null ? Number(nsTreatment.carbDelayTime) : Number.NaN
							);
							
							if (latestReading != null && treatmentTimestamp > latestReading.timestamp) 
								extendedTreatmentCarbs.needsAdjustment = true;
							
							//Add to list
							treatmentsList.push(extendedTreatmentCarbs);
							treatmentsMap[extendedTreatmentCarbs.ID] = extendedTreatmentCarbs;
							
							Trace.myTrace("TreatmentsManager.as", "Added treatment to Spike. Type: " + extendedTreatmentCarbs.type);
							
							//Notify listeners
							_instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.TREATMENT_ADDED, false, false, extendedTreatmentCarbs));
							
							//Insert in DB
							if (!CGMBlueToothDevice.isFollower() || ModelLocator.INTERNAL_TESTING)
							{
								Database.insertTreatmentSynchronous(extendedTreatmentCarbs);
							}
						}
					}
					else
					{
						//Check if edits where made.
						var internalExtendedBolusTreatment:Treatment = treatmentsMap[treatmentID];
						var internalExtendedBolusOverallInsulinAmount:Number = Math.round(internalExtendedBolusTreatment.getTotalInsulin() * 100) / 100;
						var internalExtendedBolusParentInsulinAmount:Number = internalExtendedBolusTreatment.insulinAmount;
						var internalExtendedBolusParentSplit:Number = Math.round((internalExtendedBolusParentInsulinAmount * 100) / internalExtendedBolusOverallInsulinAmount);
						var internalExtendedBolusChildrenSplit:Number = 100 - internalExtendedBolusParentSplit;
						var numberOfExtendedBolusChildren:uint = internalExtendedBolusTreatment.childTreatments.length;
						var internalExtendedBolusDuration:Number = numberOfExtendedBolusChildren * 5;
						latestReading = BgReading.lastWithCalculatedValue();
						
						if (
							(nsTreatment.enteredinsulin != null && Number(nsTreatment.enteredinsulin) != internalExtendedBolusOverallInsulinAmount)
							||
							(nsTreatment.splitNow != null && Number(nsTreatment.splitNow) != internalExtendedBolusParentSplit)
							||
							(nsTreatment.splitExt != null && Number(nsTreatment.splitExt) != internalExtendedBolusChildrenSplit)
							||
							(nsTreatment.duration != null && Number(nsTreatment.duration) != internalExtendedBolusDuration)
						)
						{
							if (nsTreatment.enteredinsulin != null && nsTreatment.splitNow != null && nsTreatment.splitExt && nsTreatment.duration)
							{
								//First we delete all children
								for (var k:int = 0; k < numberOfExtendedBolusChildren; k++) 
								{
									var internalExtendedBolusChild:Treatment = treatmentsMap[internalExtendedBolusTreatment.childTreatments[k]];
									if (internalExtendedBolusChild != null)
									{
										//Treatment is not present in Nightscout. User has deleted it
										delete treatmentsMap[internalExtendedBolusTreatment.childTreatments[k]];
										deleteTreatment(internalExtendedBolusChild, false, false, true, false, true);
										
										//Notify Listeners
										_instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.TREATMENT_EXTERNALLY_DELETED, false, false, internalExtendedBolusChild));
									}
								}
								internalExtendedBolusTreatment.childTreatments.length = 0;
								
								//Recalculate amounts and splits
								var immediateBolusAmount:Number = Math.round((Math.round(Number(nsTreatment.enteredinsulin) * 100) / 100) * ((Number(nsTreatment.splitNow)) / 100) * 100) / 100;
								var remainingBolusAmount:Number = (Math.round(Number(nsTreatment.enteredinsulin) * 100) / 100) - immediateBolusAmount;
								var extendedSteps:Number = Math.round(Number(nsTreatment.duration) / 5);
								var extendedBolusAmount:Number = Math.round((remainingBolusAmount/extendedSteps) * 100) / 100;
								
								//Extended Bolus Children
								var extendedChildren:Array = [];
								for (var m:int = 0; m < extendedSteps; m++) 
								{
									var extendedTreatmentBolusAmount:Number = m < extendedSteps - 1 ? extendedBolusAmount : remainingBolusAmount;
									
									var childTimestamp:Number = treatmentTimestamp + ((m + 1) * TimeSpan.TIME_5_MINUTES);
									var extendedTreatment:Treatment = new Treatment
										(
											Treatment.TYPE_EXTENDED_COMBO_BOLUS_CHILD,
											childTimestamp,
											extendedTreatmentBolusAmount,
											treatmentInsulinID,
											0,
											0,
											getEstimatedGlucose(childTimestamp)
										);
									extendedTreatment.needsAdjustment = latestReading != null && latestReading.timestamp >= childTimestamp ? false : true;
									addExternalTreatment(extendedTreatment, false);
									extendedChildren.push(extendedTreatment.ID);
									
									remainingBolusAmount -= extendedTreatmentBolusAmount;
								}
								
								//Update parent
								internalExtendedBolusTreatment.childTreatments = extendedChildren;
								internalExtendedBolusTreatment.insulinAmount = internalExtendedBolusParentInsulinAmount;
								internalExtendedBolusTreatment.needsAdjustment = latestReading != null && latestReading.timestamp >= treatmentTimestamp ? false : true;
								if (Math.abs(internalExtendedBolusTreatment.timestamp - treatmentTimestamp) > 1000)
								{
									internalExtendedBolusTreatment.timestamp = treatmentTimestamp;
									internalExtendedBolusTreatment.glucoseEstimated = getEstimatedGlucose(treatmentTimestamp);
								}
								if (nsTreatment.notes != null && String(nsTreatment.notes) != internalExtendedBolusTreatment.note)
								{
									internalExtendedBolusTreatment.note = String(nsTreatment.notes);
								}
								if (treatmentInsulinID != internalExtendedBolusTreatment.insulinID)
								{
									internalExtendedBolusTreatment.insulinID = treatmentInsulinID;
									if (!isNaN(treatmentInsulinDIA) && internalExtendedBolusTreatment.dia != treatmentInsulinDIA)
									{
										internalExtendedBolusTreatment.dia = treatmentInsulinDIA;
									}
								}
								if (nsTreatment.carbs != null && Number(nsTreatment.carbs) != internalExtendedBolusTreatment.carbs)
								{
									internalExtendedBolusTreatment.carbs = Number(nsTreatment.carbs);
								}
								
								updateTreatment(internalExtendedBolusTreatment, false);
								_instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.TREATMENT_EXTERNALLY_MODIFIED, false, false, internalExtendedBolusTreatment));
							}
						}
						else
						{
							var extendedTreatmentModified:Boolean = false;
							
							if (nsTreatment.notes != null && String(nsTreatment.notes) != internalExtendedBolusTreatment.note)
							{
								internalExtendedBolusTreatment.note = String(nsTreatment.notes);
								extendedTreatmentModified = true;
							}
							
							if (nsTreatment.carbs != null && Number(nsTreatment.carbs) != internalExtendedBolusTreatment.carbs)
							{
								internalExtendedBolusTreatment.carbs = Number(nsTreatment.carbs);
								extendedTreatmentModified = true;
							}
							
							if (Math.abs(internalExtendedBolusTreatment.timestamp - treatmentTimestamp) > 1000)
							{
								var originalTimestamp:Number = internalExtendedBolusTreatment.timestamp;
								var differenceTimestamp:Number = treatmentTimestamp - originalTimestamp;
								internalExtendedBolusTreatment.timestamp = treatmentTimestamp;
								internalExtendedBolusTreatment.glucoseEstimated = getEstimatedGlucose(internalExtendedBolusTreatment.timestamp);
								internalExtendedBolusTreatment.needsAdjustment = latestReading != null && latestReading.timestamp >= internalExtendedBolusTreatment.timestamp ? false : true;
								
								for (var i2:int = 0; i2 < numberOfExtendedBolusChildren; i2++) 
								{
									var child:Treatment = treatmentsMap[internalExtendedBolusTreatment.childTreatments[i2]];
									if (child != null)
									{
										child.timestamp += differenceTimestamp;
										child.glucoseEstimated = getEstimatedGlucose(child.timestamp);
										child.needsAdjustment = latestReading != null && latestReading.timestamp >= child.timestamp ? false : true;
										
										updateTreatment(child, false);
										_instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.TREATMENT_EXTERNALLY_MODIFIED, false, false, child));
									}
								}
								
								extendedTreatmentModified = true;
							}
							
							if (extendedTreatmentModified)
							{
								updateTreatment(internalExtendedBolusTreatment, false);
								_instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.TREATMENT_EXTERNALLY_MODIFIED, false, false, internalExtendedBolusTreatment));
							}
						}
					}
				}
				else if (treatmentEventType == "Carb Correction" || treatmentEventType == "Carbs")
				{
					treatmentType = Treatment.TYPE_CARBS_CORRECTION;
					if (nsTreatment.carbs != null)
						treatmentCarbs = Number(nsTreatment.carbs);
				}
				else if (treatmentEventType == "Note")
				{
					treatmentType = Treatment.TYPE_NOTE;
				}
				else if (treatmentEventType == "Exercise")
				{
					treatmentType = Treatment.TYPE_EXERCISE;
					
					if (nsTreatment.duration != null)
					{
						treatmentDuration = nsTreatment.duration;
					}
					
					if (nsTreatment.exerciseIntensity != null)
					{
						treatmentExerciseIntensity = nsTreatment.exerciseIntensity;
					}
				}
				else if (treatmentEventType == "Insulin Change")
				{
					treatmentType = Treatment.TYPE_INSULIN_CARTRIDGE_CHANGE;
				}
				else if (treatmentEventType == "Site Change")
				{
					treatmentType = Treatment.TYPE_PUMP_SITE_CHANGE;
				}
				else if (treatmentEventType == "Pump Battery Change")
				{
					treatmentType = Treatment.TYPE_PUMP_BATTERY_CHANGE;
				}
				else if (treatmentEventType == "OpenAPS Offline")
				{
					treatmentType = Treatment.TYPE_NOTE;
					treatmentNote += (treatmentNote != "" ? "\n" : "") + "OpenAPS Offline";
				}
				else if (treatmentEventType == "Resume Pump")
				{
					treatmentType = Treatment.TYPE_NOTE;
					treatmentNote += (treatmentNote != "" ? "\n" : "") + "Resume Pump";
				}
				else if (treatmentEventType == "Suspend Pump")
				{
					treatmentType = Treatment.TYPE_NOTE;
					treatmentNote += (treatmentNote != "" ? "\n" : "") + "Suspend Pump";
				}
				else if (treatmentEventType == "Announcement" && nsTreatment.notes != null && nsTreatment.notes != "")
				{
					treatmentType = Treatment.TYPE_NOTE;
					treatmentNote += (treatmentNote != "" ? "\n" : "") + "Announcement: " + nsTreatment.notes;
				}
				else if (treatmentEventType == "Profile Switch")
				{
					treatmentType = Treatment.TYPE_NOTE;
					treatmentNote += (treatmentNote != "" ? "\n" : "") + "Profile Switch" + (nsTreatment.profile != null ? ": " + nsTreatment.profile : "");
				}
				else if (treatmentEventType == "Sensor Start")
					treatmentType = Treatment.TYPE_SENSOR_START;
				else if (treatmentEventType == "BG Check")
				{
					treatmentType = Treatment.TYPE_GLUCOSE_CHECK;
					var glucoseValue:Number = Number(nsTreatment.glucose);
					if (glucoseValue < 25) //It's mmol
						glucoseValue = Math.round(BgReading.mmolToMgdl(glucoseValue));
					
					treatmentGlucose = glucoseValue;
				}
				else if (treatmentEventType == "Bolus Wizard" || treatmentEventType == "<none>")
				{
					//Process special treatments like Bolus Wizard or treatments without and event type.
					if ((nsTreatment.carbs == null || isNaN(nsTreatment.carbs))  && ((nsTreatment.insulin != null || !isNaN(nsTreatment.insulin)) && Number(nsTreatment.insulin) != 0))
					{
						//Bolus treatment
						treatmentType = Treatment.TYPE_BOLUS;
						treatmentInsulinAmount = Math.round(Number(nsTreatment.insulin) * 100) / 100;
					}
					else if (((nsTreatment.carbs != null || !isNaN(nsTreatment.carbs)) && Number(nsTreatment.carbs) != 0)  && (nsTreatment.insulin == null || isNaN(nsTreatment.insulin)))
					{
						//Carb treatment
						treatmentType = Treatment.TYPE_CARBS_CORRECTION;
						treatmentCarbs = Number(nsTreatment.carbs);
					}
					else if (((nsTreatment.carbs != null || !isNaN(nsTreatment.carbs)) && Number(nsTreatment.carbs) != 0)  && ((nsTreatment.insulin != null || !isNaN(nsTreatment.insulin)) && Number(nsTreatment.insulin) != 0))
					{
						//Meal treatment
						treatmentType = Treatment.TYPE_MEAL_BOLUS;
						treatmentInsulinAmount = Math.round(Number(nsTreatment.insulin) * 100) / 100;
						treatmentCarbs = Number(nsTreatment.carbs);
					}
				}
				
				if (nsTreatment.foodType != null && nsTreatment.foodType != "")
					treatmentNote += (treatmentNote != "" ? "\n" : "") + nsTreatment.foodType;
				
				if (nsTreatment.notes != null && nsTreatment.notes != "")
					treatmentNote += (treatmentNote != "" ? "\n" : "") + nsTreatment.notes;
				
				//Check if treatment is supported by Spike
				if (treatmentType != "")
				{
					//Check if treatment already exists in Spike
					if (treatmentsMap[treatmentID] == null)
					{
						//It's a new treatment. Let's create it
						var treatment:Treatment = new Treatment
						(
							treatmentType,
							treatmentTimestamp,
							treatmentInsulinAmount,
							treatmentInsulinID,
							treatmentCarbs,
							treatmentGlucose,
							treatmentEventType != "BG Check" ? getEstimatedGlucose(treatmentTimestamp) : treatmentGlucose,
							treatmentNote,
							treatmentID,
							treatmentCarbDelayTime
						);
						
						if (treatmentType == Treatment.TYPE_EXERCISE)
						{
							treatment.duration = treatmentDuration;
							treatment.exerciseIntensity = treatmentExerciseIntensity;
						}
						
						//If it's a future treatment let's mark that it needs adjustment for proper displaying on the chart
						if (treatmentTimestamp > now)
							treatment.needsAdjustment = true;
						
						//Add treatment to Spike and Databse
						addInternalTreatment(treatment);
						
						Trace.myTrace("TreatmentsManager.as", "Added nightscout treatment. Type: " + treatmentType);
					}
					else
					{
						//Treatment exists... Lets check if it was modified
						var wasTreatmentModified:Boolean = false;
						var spikeTreatment:Treatment = treatmentsMap[treatmentID];
						
						if (spikeTreatment.type != Treatment.TYPE_EXTENDED_COMBO_BOLUS_CHILD)
						{
							if (!isNaN(treatmentCarbs) && spikeTreatment.carbs != treatmentCarbs)
							{
								spikeTreatment.carbs = treatmentCarbs;
								wasTreatmentModified = true;
							}
							if (!isNaN(treatmentCarbDelayTime) && spikeTreatment.carbDelayTime != treatmentCarbDelayTime)
							{
								spikeTreatment.carbDelayTime = treatmentCarbDelayTime;
								wasTreatmentModified = true;
							}
							if (!isNaN(treatmentGlucose) && Math.abs(spikeTreatment.glucose - treatmentGlucose) >= 1) //Nightscout rounds values so we just check if the glucose value differnce is bigger than 1 to avoid triggering this on every treatment
							{
								spikeTreatment.glucose = treatmentGlucose;
								wasTreatmentModified = true;
							}
							if (!isNaN(treatmentInsulinAmount) && spikeTreatment.insulinAmount != treatmentInsulinAmount)
							{
								spikeTreatment.insulinAmount = treatmentInsulinAmount;
								wasTreatmentModified = true;
							}
							if (!isNaN(treatmentInsulinDIA) && spikeTreatment.dia != treatmentInsulinDIA)
							{
								spikeTreatment.dia = treatmentInsulinDIA;
								wasTreatmentModified = true;
							}
							if (treatmentInsulinID != "000000" && spikeTreatment.insulinID != treatmentInsulinID)
							{
								spikeTreatment.insulinID = treatmentInsulinID;
								wasTreatmentModified = true;
							}
							if (spikeTreatment.note != treatmentNote)
							{
								spikeTreatment.note = treatmentNote;
								wasTreatmentModified = true;
							}
							if (Math.abs(spikeTreatment.timestamp - treatmentTimestamp) > 1000) //parseW3CDTF ignores ms so we just check if the time difference is bigger than 1 sec to determine if the user changed the treatment type. This avoids triggering this on every treatment.
							{
								spikeTreatment.timestamp = treatmentTimestamp;
								spikeTreatment.glucoseEstimated = treatmentType != Treatment.TYPE_GLUCOSE_CHECK ? getEstimatedGlucose(treatmentTimestamp) : spikeTreatment.glucose;
								wasTreatmentModified = true;
							}
							if (spikeTreatment.type == Treatment.TYPE_EXERCISE && !isNaN(treatmentDuration) && spikeTreatment.duration != treatmentDuration)
							{
								spikeTreatment.duration = treatmentDuration;
								wasTreatmentModified = true;
							}
							
							if (wasTreatmentModified)
							{
								//Treatment was modified. Update Spike and notify listeners
								updateTreatment(spikeTreatment, false);
								_instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.TREATMENT_EXTERNALLY_MODIFIED, false, false, spikeTreatment));
								
								Trace.myTrace("TreatmentsManager.as", "Updated nightscout treatment. Type: " + spikeTreatment.type);
							}
						}
					}
				}
			}
			
			//Check for deleted treatments in Nightscout
			var numSpikeTreatments:int = treatmentsList.length;
			for (var j:int = 0; j <numSpikeTreatments; j++) 
			{
				var internalTreatment:Treatment = treatmentsList[j];
					
				if (internalTreatment.type == Treatment.TYPE_GLUCOSE_CHECK && internalTreatment.note == ModelLocator.resourceManagerInstance.getString('treatments','sensor_calibration_note'))
				{
					//Don't delete calibration treatments
					continue;
				}
					
				if (nightscoutTreatmentsMap[internalTreatment.ID] == null && internalTreatment.type != Treatment.TYPE_EXTENDED_COMBO_BOLUS_CHILD)
				{
					Trace.myTrace("TreatmentsManager.as", "User deleted treatment in Nightscout. Deleting in Spike as well. Type: " + internalTreatment.type);
					
					//Treatment is not present in Nightscout. User has deleted it.
					var removeFromDB:Boolean = now - internalTreatment.timestamp < TimeSpan.TIME_24_HOURS && (!CGMBlueToothDevice.isFollower() || ModelLocator.INTERNAL_TESTING);
					deleteTreatment(internalTreatment, false, true, removeFromDB, true, true);
				}
			}
			
			//Sort treatments
			treatmentsList.sortOn(["timestamp"], Array.NUMERIC);
		}
		
		public static function removeTreatmentFromMemory(treatment:Treatment):void
		{
			Trace.myTrace("TreatmentsManager.as", "removeTreatmentFromMemory called!");
			
			//Validation
			if (treatment == null)
				return;
			
			//Remove from list
			for (var i:int = 0; i < treatmentsList.length; i++) 
			{
				var internalTreatment:Treatment = treatmentsList[i];
				if (internalTreatment != null && internalTreatment.ID == treatment.ID)
				{
					Trace.myTrace("TreatmentsManager.as", "Removed expired treatment. Type: " + internalTreatment.type);
					treatmentsList.removeAt(i);
					break;
				}
			}
			
			//Remove from map
			treatmentsMap[treatment.ID] = null;
			
			//Dispose
			treatment = null;
		}
		
		public static function removeAllTreatmentsFromMemory():void
		{
			treatmentsList.length = 0;
			treatmentsMap = new Dictionary();
			basalsList.length = 0;
			basalsMap = new Dictionary();
			ProfileManager.basalRatesList.length = 0;
			ProfileManager.basalRatesMap = new Dictionary();
			ProfileManager.basalRatesMapByTime = {};
		}
		
		public static function getEstimatedGlucose(timestamp:Number):Number
		{
			var estimatedGlucose:Number = 100;
			
			if (ModelLocator.bgReadings != null && ModelLocator.bgReadings.length > 0)
			{
				for(var i:int = ModelLocator.bgReadings.length - 1 ; i >= 0; i--)
				{
					var reading:BgReading = ModelLocator.bgReadings[i];
					if (reading.timestamp <= timestamp)
					{
						estimatedGlucose = reading.calculatedValue != 0 ? reading.calculatedValue : 100;
						break;
					}
				}
			}
			
			return estimatedGlucose;
		}
		
		public static function getTotalActiveInsulin():Object
		{
			var activeTotalInsulin:Number = 0;
			var now:Number = new Date().valueOf();
			var firstTreatmentTimestamp:Number = now;
			
			var dataLength:int = treatmentsList.length;
			for (var i:int = 0; i < dataLength; i++) 
			{
				var treatment:Treatment = treatmentsList[i];
				
				if ((treatment.type == Treatment.TYPE_BOLUS || treatment.type == Treatment.TYPE_CORRECTION_BOLUS || treatment.type == Treatment.TYPE_MEAL_BOLUS || treatment.type == Treatment.TYPE_EXTENDED_COMBO_BOLUS_CHILD || treatment.type == Treatment.TYPE_EXTENDED_COMBO_BOLUS_PARENT || treatment.type == Treatment.TYPE_EXTENDED_COMBO_MEAL_PARENT) && treatment.calculateIOBNightscout(now).iobContrib > 0)
				{
					activeTotalInsulin += treatment.insulinAmount;
					if (treatment.timestamp < firstTreatmentTimestamp)
						firstTreatmentTimestamp = treatment.timestamp;
				}
			}
			
			return { timestamp: firstTreatmentTimestamp, insulin: activeTotalInsulin };
		}
		
		public static function getTotalActiveCarbs():Object
		{
			var activeTotalCarbs:Number = 0;
			var now:Number = new Date().valueOf();
			var firstTreatmentTimestamp:Number = now;
			
			var carbsAbsorptionRate:Number = ProfileManager.getCarbAbsorptionRate();
			
			// TODO: figure out the liverSensRatio that gives the most accurate purple line predictions
			var liverSensRatio:int = 8;
			var totalCOB:Number = 0;
			var lastCarbs:Treatment;
			
			var isDecaying:Number = 0;
			var lastDecayedBy:Number = 0;
			
			var currentProfile:Profile = ProfileManager.getProfileByTime(now);
			var isf:Number = Number(currentProfile.insulinSensitivityFactors);
			var ic:Number = Number(currentProfile.insulinToCarbRatios);
			
			var dataLength:int = treatmentsList.length;
			for (var i:int = 0; i < dataLength; i++) 
			{
				var treatment:Treatment = treatmentsList[i];
				
				if (treatment != null && (treatment.type == Treatment.TYPE_CARBS_CORRECTION || treatment.type == Treatment.TYPE_MEAL_BOLUS || treatment.type == Treatment.TYPE_EXTENDED_COMBO_MEAL_PARENT) && now >= treatment.timestamp)
				{
					var cCalc:CobCalc = treatment.calculateCOB(lastDecayedBy, now);
					if (cCalc != null)
					{
						var decaysin_hr:Number = (cCalc.decayedBy - now) / 1000 / 60 / 60;
									
						if (decaysin_hr > -10 && !isNaN(isf)) 
						{
							var actStart:Number = 0;
							if (lastDecayedBy != 0)
							{
								actStart = getTotalIOB(lastDecayedBy).activity;
							}
							
							var actEnd:Number = getTotalIOB(cCalc.decayedBy).activity;
							
							var avgActivity:Number = (actStart + actEnd) / 2;
							var delayedCarbs:Number = ( avgActivity *  liverSensRatio / isf ) * ic;
							var delayMinutes:Number = Math.round(delayedCarbs / carbsAbsorptionRate * 60);
							
							if (delayMinutes > 0) 
							{
								cCalc.decayedBy += (delayMinutes * 60 * 1000);
								decaysin_hr = (cCalc.decayedBy - now) / 1000 / 60 / 60;
							}
						}
						
						lastDecayedBy = cCalc.decayedBy;
						
						if (decaysin_hr > 0) 
						{
							var treatmentCOB:Number = Math.min(Number(treatment.carbs), decaysin_hr * carbsAbsorptionRate);
							if (isNaN(treatmentCOB)) treatmentCOB = 0;
							isDecaying = cCalc.isDecaying;
										
							if (treatmentCOB > 0)
							{
								activeTotalCarbs += treatment.carbs;
								if (treatment.timestamp < firstTreatmentTimestamp)
									firstTreatmentTimestamp = treatment.timestamp;
							}
						} 
					}
				}
			}
			
			return { timestamp: firstTreatmentTimestamp, carbs: activeTotalCarbs };
		}
		
		public static function getCarbTypeName(treatment:Treatment):String
		{
			var carbTypeName:String = ModelLocator.resourceManagerInstance.getString('treatments','carbs_unknown_label');
			
			if (treatment.type == Treatment.TYPE_CARBS_CORRECTION || treatment.type == Treatment.TYPE_MEAL_BOLUS || treatment.type == Treatment.TYPE_EXTENDED_COMBO_MEAL_PARENT)
			{
				if (treatment.carbDelayTime == Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CARB_FAST_ABSORTION_TIME)))
					carbTypeName = ModelLocator.resourceManagerInstance.getString('treatments','carbs_fast_label');
				else if (treatment.carbDelayTime == Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CARB_MEDIUM_ABSORTION_TIME)))
					carbTypeName = ModelLocator.resourceManagerInstance.getString('treatments','carbs_medium_label');
				else if (treatment.carbDelayTime == Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CARB_SLOW_ABSORTION_TIME)))
					carbTypeName = ModelLocator.resourceManagerInstance.getString('treatments','carbs_slow_label');
			}
			
			return carbTypeName;
		}
		
		public static function getLastTreatment():Treatment
		{
			var treatment:Treatment;
			
			if (treatmentsList != null)
			{
				var numberOfTreatments:uint = treatmentsList.length;
				
				if (numberOfTreatments > 0)
				{
					//Sort Treatments
					treatmentsList.sortOn(["timestamp"], Array.NUMERIC);
					
					//Get last treatment
					treatment = treatmentsList[numberOfTreatments - 1];
				}
			}
			
			return treatment;
		}
		
		public static function getTreatmentByID(treatmentID:String):Treatment
		{
			return treatmentsMap[treatmentID];
		}
		
		public static function getExerciseTreatmentIntensity(treatment:Treatment):String
		{
			var exerciseIntensity:String = ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available');
			
			if (treatment.exerciseIntensity == Treatment.EXERCISE_INTENSITY_LOW)
			{
				exerciseIntensity = ModelLocator.resourceManagerInstance.getString('treatments','exercise_intensity_low_label');
			}
			else if (treatment.exerciseIntensity == Treatment.EXERCISE_INTENSITY_MODERATE)
			{
				exerciseIntensity = ModelLocator.resourceManagerInstance.getString('treatments','exercise_intensity_moderate_label');
			}
			else if (treatment.exerciseIntensity == Treatment.EXERCISE_INTENSITY_HIGH)
			{
				exerciseIntensity = ModelLocator.resourceManagerInstance.getString('treatments','exercise_intensity_high_label');
			}
			
			return exerciseIntensity;
		}
		
		public static function lastTreatmentIsCarb():Boolean
		{
			var isLastTreatmentCarb:Boolean = false;
			
			var lastBgReading:BgReading = BgReading.lastWithCalculatedValue();
			if (lastBgReading != null)
			{
				//Sort Treatments
				treatmentsList.sortOn(["timestamp"], Array.NUMERIC);
				
				for(var i:int = treatmentsList.length - 1 ; i >= 0; i--)
				{
					var treatment:Treatment = treatmentsList[i];
					if (treatment != null)
					{
						if (treatment.timestamp < lastBgReading._timestamp)
						{
							break;
						}
							
						if (treatment.carbs > 0 && treatment.timestamp > lastBgReading._timestamp)
						{
							isLastTreatmentCarb = true;
							break;
						}
					}
				}
			}
			
			return isLastTreatmentCarb;
		}
		
		/**
		 * Basals
		 */
		public static function getLastBasalTimestamp():Number
		{
			var lastBasalTimestamp:Number = 0;
			
			var numberOfBasals:uint = basalsList.length;
			if (basalsList.length > 0)
			{
				basalsList.sortOn(["timestamp"], Array.NUMERIC);
				var lastBasalTreatment:Treatment = basalsList[numberOfBasals - 1];
				if (lastBasalTreatment != null)
				{
					lastBasalTimestamp = lastBasalTreatment.timestamp;
				}
			}
			
			return lastBasalTimestamp;
		}
		
		private static function getTempBasalAmount(treatment:Treatment):Number 
		{
			var basalAmount:Number = 0;
			
			if (treatment.type == Treatment.TYPE_TEMP_BASAL)
			{
				if (treatment.isBasalAbsolute)
				{
					basalAmount = treatment.basalAbsoluteAmount;
				}
				else if (treatment.isBasalRelative)
				{
					var currentBasalRate:Number = ProfileManager.getBasalRateByTime(treatment.timestamp);
					basalAmount = currentBasalRate * (100 + treatment.basalPercentAmount) / 100;
				}
			}
			
			return Math.round(basalAmount * 100) / 100;
		}
		
		public static function getHighestBasal(type:String, sourceForBasals:Array = null, isHistoricalData:Boolean = false):Number
		{
			var basalsSource:Array = sourceForBasals != null ? sourceForBasals : basalsList;
			
			var highestTempBasalAmount:Number = 0;
			var twentyFourHoursAgo:Number = new Date().valueOf() - TimeSpan.TIME_24_HOURS;
			
			for (var i:int = basalsSource.length - 1 ; i >= 0; i--)
			{
				var tempBasal:Treatment = basalsSource[i];
				if (tempBasal != null && tempBasal.type == type && (tempBasal.basalAbsoluteAmount > 0 || tempBasal.basalPercentAmount > 0))
				{
					//CleanUp
					if (tempBasal.timestamp < twentyFourHoursAgo && !isHistoricalData)
					{
						//Treatment has expired. Dispose it.
						basalsSource.removeAt(i);
						basalsMap[tempBasal.ID] = null;
						delete basalsMap[tempBasal.ID];
						tempBasal = null;
						
						continue;
					}
					
					//Determine Basal Amount
					var basalAmount:Number = 0;
					if (tempBasal.isBasalAbsolute)
					{
						basalAmount = tempBasal.basalAbsoluteAmount;
					}
					else if (tempBasal.isBasalRelative)
					{
						var currentBasalRate:Number = ProfileManager.getBasalRateByTime(tempBasal.timestamp);
						basalAmount = currentBasalRate * (100 + tempBasal.basalPercentAmount) / 100;
					}
					
					//Compare to highest value
					if (basalAmount > highestTempBasalAmount)
					{
						highestTempBasalAmount = basalAmount;
					}
				}
			}
			
			return highestTempBasalAmount;
		}
		
		public static function cleanUpOldBasals():void
		{
			basalsList.sortOn(["timestamp"], Array.NUMERIC | Array.DESCENDING);
			
			var allowedStartTime:Number = new Date().valueOf() - TimeSpan.TIME_48_HOURS;
			
			for (var i:int = basalsList.length - 1 ; i >= 0; i--)
			{
				var basal:Treatment = basalsList[i];
				if (basal.timestamp + (basal.basalDuration * TimeSpan.TIME_1_MINUTE) < allowedStartTime)
				{
					basalsList.removeAt(i);
					basalsMap[basal.ID] = null;
					delete basalsMap[basal.ID];
					basal = null;
				}
				else
				{
					break;
				}
			}
			
			basalsList.sortOn(["timestamp"], Array.NUMERIC);
		}
		
		public static function clearAllBasals():void
		{
			basalsList.length = 0;
			basalsMap = new Dictionary();
		}

		/**
		 * Setters & Getters
		 */
		public static function get instance():TreatmentsManager
		{
			return _instance;
		}
	}
}