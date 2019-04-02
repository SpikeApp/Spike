package database
{
	import com.hurlant.util.Base64;
	
	import flash.data.SQLConnection;
	import flash.data.SQLMode;
	import flash.data.SQLResult;
	import flash.data.SQLStatement;
	import flash.errors.SQLError;
	import flash.events.EventDispatcher;
	import flash.events.SQLErrorEvent;
	import flash.events.SQLEvent;
	import flash.filesystem.File;
	import flash.utils.ByteArray;
	
	import mx.collections.ArrayCollection;
	
	import spark.collections.Sort;
	import spark.collections.SortField;
	
	import events.DatabaseEvent;
	import events.SpikeEvent;
	import events.TransmitterServiceEvent;
	
	import model.ModelLocator;
	
	import services.TransmitterService;
	
	import stats.BasicUserStats;
	import stats.StatsManager;
	
	import treatments.BasalRate;
	import treatments.Insulin;
	import treatments.Profile;
	import treatments.Treatment;
	import treatments.food.Food;
	import treatments.food.Recipe;
	
	import ui.chart.helpers.GlucoseFactory;
	
	import utils.TimeSpan;
	import utils.Trace;
	
	[ResourceBundle("alertsettingsscreen")]
	
	public class Database extends EventDispatcher
	{
		private static var _instance:Database = new Database();
		public static function get instance():Database {
			return _instance;
		}
		
		private static var aConn:SQLConnection;
		private static var sqlStatement:SQLStatement;
		private static var sampleDatabaseFileName:String = "spike-sample.db";;
		private static const dbFileName:String = "spike.db";
		private static var dbFile:File  ;
		private static var xmlFileName:String;
		private static var databaseWasCopiedFromSampleFile:Boolean = true;
		private static const debugMode:Boolean = true;
		private static const MAX_DAYS_TO_STORE_BGREADINGS_IN_DATABASE:int = 90;
		
		/**
		 * create table to store the bluetooth device name and address<br>
		 * At most one row should be stored
		 */
		private static const CREATE_TABLE_BLUETOOTH_DEVICE:String = "CREATE TABLE IF NOT EXISTS bluetoothdevice (" +
			"bluetoothdevice_id STRING PRIMARY KEY, " + //unique id, used in all tables that will use Google Sync (note that for iOS no google sync will be done for this table because mac address is not visible in iOS. UDID is used as address but this is different for each install
			"name STRING, " +
			"address STRING, " +
			"lastmodifiedtimestamp TIMESTAMP NOT NULL)";
		
		private static const CREATE_TABLE_CALIBRATION:String = "CREATE TABLE IF NOT EXISTS calibration (" +
			"calibrationid STRING PRIMARY KEY," +
			"lastmodifiedtimestamp TIMESTAMP NOT NULL," +
			"timestamp TIMESTAMP," +
			"sensorAgeAtTimeOfEstimation REAL," +
			"sensorid STRING," +
			"bg REAL," +
			"rawValue REAL," +
			"adjustedRawValue REAL," +
			"sensorConfidence REAL," +
			"slopeConfidence REAL," +
			"rawTimestamp TIMESTAMP," +
			"slope REAL," +
			"intercept REAL," +
			"distanceFromEstimate REAL," +
			"estimateRawAtTimeOfCalibration REAL," +
			"estimateBgAtTimeOfCalibration REAL," +
			"possibleBad BOOLEAN," +
			"checkIn BOOLEAN," +
			"firstDecay REAL," +
			"secondDecay REAL," +
			"firstSlope REAL," +
			"secondSlope REAL," +
			"firstIntercept REAL," +
			"secondIntercept REAL," +
			"firstScale REAL," +
			"secondScale REAL," +
			"FOREIGN KEY (sensorid) REFERENCES sensor(sensorid))";
		
		private static const CREATE_TABLE_SENSOR:String = "CREATE TABLE IF NOT EXISTS sensor (" +
			"sensorid STRING PRIMARY KEY," +
			"lastmodifiedtimestamp TIMESTAMP NOT NULL," +
			"startedat TIMESTAMP," +
			"stoppedat TIMESTAMP," +
			"latestbatterylevel INTEGER)";
		
		private static const CREATE_TABLE_BGREADING:String = "CREATE TABLE IF NOT EXISTS bgreading (" +
			"bgreadingid STRING PRIMARY KEY," +
			"lastmodifiedtimestamp TIMESTAMP NOT NULL," +
			"timestamp TIMESTAMP NOT NULL," +
			"sensorid STRING," +
			"calibrationid STRING," +
			"rawData REAL," +
			"filteredData REAL," +
			"ageAdjustedRawValue REAL," +
			"calibrationFlag BOOLEAN," +
			"calculatedValue REAL," +
			"filteredCalculatedValue REAL," +
			"calculatedValueSlope REAL," +
			"a REAL," +
			"b REAL," +
			"c REAL," +
			"ra REAL," +
			"rb REAL," +
			"rc REAL," +
			"rawCalculated REAL," +
			"hideSlope BOOLEAN," +
			"noise STRING " + ")";
		
		private static const CREATE_TABLE_COMMON_SETTINGS:String = "CREATE TABLE IF NOT EXISTS commonsettings(" +
			"id INTEGER," +
			"value TEXT, " +
			"lastmodifiedtimestamp TIMESTAMP NOT NULL)";
		
		private static const CREATE_TABLE_LOCAL_SETTINGS:String = "CREATE TABLE IF NOT EXISTS localsettings(" +
			"id INTEGER," +
			"value TEXT, " +
			"lastmodifiedtimestamp TIMESTAMP NOT NULL)";
		
		private static const CREATE_TABLE_ALERT_TYPES:String = "CREATE TABLE IF NOT EXISTS alerttypes(" +
			"alerttypeid STRING PRIMARY KEY," +
			"alarmname STRING," +
			"enablelights BOOLEAN," +
			"enablevibration BOOLEAN," +
			"snoozefromnotification BOOLEAN," +
			"soundtext STRING," +
			"defaultsnoozeperiod INTEGER," + // in minutes
			"repeatinminutes INTEGER," + // in minutes
			"lastmodifiedtimestamp TIMESTAMP NOT NULL," +
			"enabled BOOLEAN," + 
			"overridesilentmode BOOLEAN)";
		
		private static const CREATE_TABLE_TREATMENTS:String = "CREATE TABLE IF NOT EXISTS treatments(" +
			"id STRING PRIMARY KEY," +
			"type STRING, " +
			"insulinamount REAL, " +
			"insulinid STRING, " +
			"carbs REAL, " +
			"glucose REAL, " +
			"glucoseestimated REAL, " +
			"note STRING, " +
			"carbdelay REAL, " +
			"basalduration REAL, " +
			"children STRING, " +
			"needsadjustment STRING, " +
			"prebolus REAL, " +
			"duration REAL, " +
			"intensity STRING, " +
			"isbasalabsolute STRING, " +
			"isbasalrelative STRING, " +
			"istempbasalend STRING, " +
			"basalabsoluteamount REAL, " +
			"basalpercentamount REAL, " +
			"lastmodifiedtimestamp TIMESTAMP NOT NULL)";
		
		private static const CREATE_TABLE_INSULINS:String = "CREATE TABLE IF NOT EXISTS insulins(" +
			"id STRING PRIMARY KEY," +
			"name STRING, " +
			"dia REAL, " +
			"type STRING, " +
			"curve STRING, " +
			"peak REAL, " +
			"isdefault STRING, " +
			"ishidden STRING, " +
			"lastmodifiedtimestamp TIMESTAMP NOT NULL)";
		
		private static const CREATE_TABLE_PROFILE:String = "CREATE TABLE IF NOT EXISTS profiles(" +
			"id STRING PRIMARY KEY," +
			"time STRING, " +
			"name STRING, " +
			"insulintocarbratios STRING, " +
			"insulinsensitivityfactors STRING, " +
			"carbsabsorptionrate REAL, " +
			"basalrates STRING, " +
			"targetglucoserates STRING, " +
			"trendcorrections STRING, " +
			"lastmodifiedtimestamp TIMESTAMP NOT NULL)";
		
		private static const CREATE_TABLE_HEALTHKIT_TREATMENTS:String = "CREATE TABLE IF NOT EXISTS healthkittreatments(" +
			"id STRING PRIMARY KEY," +
			"timestamp TIMESTAMP NOT NULL)";
		
		private static const CREATE_TABLE_FOODS:String = "CREATE TABLE IF NOT EXISTS foods(" +
			"id STRING PRIMARY KEY," +
			"name STRING, " +
			"brand STRING, " +
			"proteins STRING, " +
			"carbs STRING, " +
			"fiber STRING, " +
			"fats STRING, " +
			"calories STRING, " +
			"servingsize STRING, " +
			"servingunit STRING, " +
			"link STRING, " +
			"barcode STRING, " +
			"source STRING, " +
			"notes STRING, " +
			"lastmodifiedtimestamp TIMESTAMP NOT NULL)";
		
		private static const CREATE_TABLE_RECIPES_LIST:String = "CREATE TABLE IF NOT EXISTS recipeslist(" +
			"id STRING PRIMARY KEY," +
			"name STRING, " +
			"servingsize STRING, " +
			"servingunit STRING, " +
			"notes STRING, " +
			"lastmodifiedtimestamp TIMESTAMP NOT NULL)";
		
		private static const CREATE_TABLE_RECIPES_FOODS:String = "CREATE TABLE IF NOT EXISTS recipesfoods(" +
			"recipeid STRING," +
			"foodid STRING," +
			"name STRING, " +
			"brand STRING, " +
			"proteins STRING, " +
			"carbs STRING, " +
			"fiber STRING, " +
			"substractfiber STRING, " +
			"fats STRING, " +
			"calories STRING, " +
			"servingsize STRING, " +
			"servingunit STRING, " +
			"recipeservingsize STRING, " +
			"recipeservingunit STRING, " +
			"link STRING, " +
			"barcode STRING, " +
			"source STRING, " +
			"notes STRING, " +
			"defaultunit STRING, " +
			"lastmodifiedtimestamp TIMESTAMP NOT NULL)";
		
		private static const CREATE_TABLE_IOB_COB_CACHES:String = "CREATE TABLE IF NOT EXISTS iobcobcaches(" +
			"cob BLOB," +
			"cobindexes BLOB," +
			"iob BLOB," +
			"iobindexes BLOB)";
		
		private static const CREATE_TABLE_BASAL_RATES:String = "CREATE TABLE IF NOT EXISTS basalrates(" +
			"id STRING PRIMARY KEY," +
			"time STRING, " +
			"hours REAL, " +
			"minutes REAL, " +
			"rate REAL, " +
			"lastmodifiedtimestamp TIMESTAMP NOT NULL)";
		
		private static const SELECT_ALL_BLUETOOTH_DEVICES:String = "SELECT * from bluetoothdevice";
		private static const INSERT_DEFAULT_BLUETOOTH_DEVICE:String = "INSERT into bluetoothdevice (bluetoothdevice_id, name, address, lastmodifiedtimestamp) VALUES (:bluetoothdevice_id,:name, :address, :lastmodifiedtimestamp)";
		
		/**
		 * to update the bloothdevice, there's only one, no need to have a where clause
		 */
		private static const UPDATE_BLUETOOTH_DEVICE:String = "UPDATE bluetoothdevice SET address = :address, name = :name, lastmodifiedtimestamp = :lastmodifiedtimestamp"; 
		/**
		 * constructor, should not be used
		 */
		
		public function Database()
		{
			if (_instance != null) {
				throw new Error("Database class constructor can not be used");	
			}
		}
		
		/**
		 * Create the asynchronous connection to the database<br>
		 * In the complete flow first an attempt will be made to open the database in update mode. <br>
		 * If that fails, it means the database is not existing yet. Then an attempt is made to copy a sample from the assets<br>
		 * <br>
		 * Independent of the result of the attempt to open the database and to copy from the assets, all tables will be created (if not existing yet).<br>
		 * <br>
		 * A default bluetooth device is created if not existing yet with name "", address "", lastmodifiedtimestamp current date, id = BlueToothDevice.DEFAULT_BLUETOOTH_DEVICE_ID
		 **/
		public static function init():void
		{
			if (debugMode) trace("Database.init");
			
			Spike.instance.addEventListener(SpikeEvent.APP_HALTED, onHaltExecution, false, -1000);
			TransmitterService.instance.addEventListener(TransmitterServiceEvent.LAST_BGREADING_RECEIVED, bgReadingEventReceived);
			
			//Check old database file path
			var oldDbPath:File = File.applicationStorageDirectory.resolvePath(dbFileName);
			if (oldDbPath.exists)
			{
				trace("Database.as : Moving database to Documents directory...");
				oldDbPath.moveTo(File.documentsDirectory.resolvePath(dbFileName), true);
			}
			
			//Check database leftovers
			var importedFilesFolder:File = File.documentsDirectory.resolvePath("Inbox");
			if (importedFilesFolder.exists)
			{
				var files:Array = importedFilesFolder.getDirectoryListing();
				for (var i:uint = 0; i < files.length; i++)
				{
					var file:File = files[i] as File;
					
					trace("Database.as : Deleting leftover database file: " + file.name);
					
					file.deleteFile();
				}
			}
			
			dbFile  = File.documentsDirectory.resolvePath(dbFileName);
			
			aConn = new SQLConnection();
			aConn.addEventListener(SQLEvent.OPEN, onConnOpen);
			aConn.addEventListener(SQLErrorEvent.ERROR, onConnError);
			if (debugMode) trace("Database.as : Attempting to open database in update mode. Database:0001");
			aConn.openAsync(dbFile, SQLMode.UPDATE);
			
			function onConnOpen(se:SQLEvent):void
			{
				if (debugMode) trace("Database.as : SQL Connection successfully opened. Database:0002");
				aConn.removeEventListener(SQLEvent.OPEN, onConnOpen);
				aConn.removeEventListener(SQLErrorEvent.ERROR, onConnError);	
				createTables();
			}
			
			function onConnError(see:SQLErrorEvent):void
			{
				if (debugMode) trace("Database.as : SQL Error while attempting to open database in update mode. New attempt");
				aConn.removeEventListener(SQLEvent.OPEN, onConnOpen);
				aConn.removeEventListener(SQLErrorEvent.ERROR, onConnError);
				reAttempt();
			}
			
			function reAttempt():void {
				//attempt to create dbFile based on a sample in assets directory, 
				//if that fails then dbFile will simply not exist and so will be created later on in openAsync 
				databaseWasCopiedFromSampleFile = createDatabaseFromAssets(dbFile);
				aConn = new SQLConnection();
				aConn.addEventListener(SQLEvent.OPEN, onConnOpen);
				aConn.addEventListener(SQLErrorEvent.ERROR, onConnError);
				if (debugMode) trace("Database.as : Attempting to open database in creation mode. Database:0004");
				aConn.openAsync(dbFile, SQLMode.CREATE);
			}
		}
		
		private static function createTables():void
		{			
			if (debugMode) trace("Database.as : in method createtables");
			sqlStatement = new SQLStatement();
			sqlStatement.sqlConnection = aConn;
			createSensorTable();				
		}
		
		private static function createSensorTable():void {
			sqlStatement.clearParameters();
			sqlStatement.text = CREATE_TABLE_SENSOR;
			sqlStatement.addEventListener(SQLEvent.RESULT,tableCreated);
			sqlStatement.addEventListener(SQLErrorEvent.ERROR,tableCreationError);
			sqlStatement.execute();
			
			function tableCreated(se:SQLEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
				createCalibrationTable();
			}
			
			function tableCreationError(see:SQLErrorEvent):void {
				if (debugMode) trace("Database.as : Failed to create sensor table. Database:0028");
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
				dispatchInformation('failed_to_create_sensor_table', see != null ? see.error.message:null);
			}
		}
		
		private static function createCalibrationTable():void {
			sqlStatement.clearParameters();
			sqlStatement.text = CREATE_TABLE_CALIBRATION;
			sqlStatement.addEventListener(SQLEvent.RESULT,tableCreated);
			sqlStatement.addEventListener(SQLErrorEvent.ERROR,tableCreationError);
			sqlStatement.execute();
			
			function tableCreated(se:SQLEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
				createBGreadingTable();
			}
			
			function tableCreationError(see:SQLErrorEvent):void {
				if (debugMode) trace("Database.as : Failed to create calibration table. Database:0026");
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
				dispatchInformation('failed_to_create_calibration_table', see != null ? see.error.message:null);
			}
		}
		
		private static function createBGreadingTable():void {
			sqlStatement.clearParameters();
			sqlStatement.text = CREATE_TABLE_BGREADING;
			sqlStatement.addEventListener(SQLEvent.RESULT,tableCreated);
			sqlStatement.addEventListener(SQLErrorEvent.ERROR,tableCreationError);
			sqlStatement.execute();
			
			function tableCreated(se:SQLEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
				createCommonSettingsTable();
			}
			
			function tableCreationError(see:SQLErrorEvent):void {
				if (debugMode) trace("Database.as : Failed to create bgreading table. Database:0030");
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
				dispatchInformation('failed_to_create_bgreading_table', see != null ? see.error.message:null);
			}
		}
		
		private static function createCommonSettingsTable():void {
			sqlStatement.clearParameters();
			sqlStatement.text = CREATE_TABLE_COMMON_SETTINGS;
			sqlStatement.addEventListener(SQLEvent.RESULT,tableCreated);
			sqlStatement.addEventListener(SQLErrorEvent.ERROR,tableCreationError);
			sqlStatement.execute();
			
			function tableCreated(se:SQLEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
				createLocalSettingsTable();
			}
			
			function tableCreationError(see:SQLErrorEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
				dispatchInformation('failed_to_create_commonsettings_table', see != null ? see.error.message:null);
			}
		}
		
		private static function createLocalSettingsTable():void {
			sqlStatement.clearParameters();
			sqlStatement.text = CREATE_TABLE_LOCAL_SETTINGS;
			sqlStatement.addEventListener(SQLEvent.RESULT,tableCreated);
			sqlStatement.addEventListener(SQLErrorEvent.ERROR,tableCreationError);
			sqlStatement.execute();
			
			function tableCreated(se:SQLEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
				getAllSettings();
			}
			
			function tableCreationError(see:SQLErrorEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
				dispatchInformation('failed_to_create_localsettings_table', see != null ? see.error.message:null);
			}
		}
		
		private static function getAllSettings():void {
			sqlStatement.clearParameters();
			sqlStatement.text = "SELECT * FROM commonsettings";
			sqlStatement.addEventListener(SQLEvent.RESULT, allCommonSettingsRetrieved);
			sqlStatement.addEventListener(SQLErrorEvent.ERROR, allCommonSettingsRetrievalFailed);
			sqlStatement.execute();
			var result:Array;
			
			function allCommonSettingsRetrieved(se:SQLEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT, allCommonSettingsRetrieved);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR, allCommonSettingsRetrievalFailed);
				result = sqlStatement.getResult().data;
				if (result == null)
					result = new Array(0);
				if (result is Array) { //TODO what if it's not an array ?
					for each (var o:Object in result) {
						CommonSettings.setCommonSetting((o.id as int),(o.value as String) == "-" ? "":(o.value as String), false);
					}
				} 
				addMissingCommonSetting(result.length);
			}
			
			function allCommonSettingsRetrievalFailed(see:SQLErrorEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT, allCommonSettingsRetrieved);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR, allCommonSettingsRetrievalFailed);
				if (debugMode) trace("Failure in get all common settings - Database 0035");
				dispatchInformation('error_while_retrieving_common_settings_in_db', see.error.message + " - " + see.error.details);
			}
			
			function allLocalSettingsRetrievalFailed(see:SQLErrorEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT, allLocalSettingsRetrieved);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR, allLocalSettingsRetrievalFailed);
				if (debugMode) trace("Failure in get all local settings - Database 0036");
				dispatchInformation('error_while_retrieving_local_settings_in_db', see.error.message + " - " + see.error.details);
			}
			
			function addMissingCommonSetting(settingId:int):void {
				if (settingId == CommonSettings.getNumberOfSettings()) {
					sqlStatement.clearParameters();
					sqlStatement.text = "SELECT * FROM localsettings";
					sqlStatement.addEventListener(SQLEvent.RESULT, allLocalSettingsRetrieved);
					sqlStatement.addEventListener(SQLErrorEvent.ERROR, allLocalSettingsRetrievalFailed);
					sqlStatement.execute();
				} else {
					insertCommonSetting(settingId, CommonSettings.getCommonSetting(settingId));
					addMissingCommonSetting(settingId +1);
				}
			}
			
			function allLocalSettingsRetrieved(se:SQLEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT, allLocalSettingsRetrieved);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR, allLocalSettingsRetrievalFailed);
				result = sqlStatement.getResult().data;
				if (result == null)
					result = new Array(0);
				if (result is Array) { //TODO what if it's not an array ?
					for each (var o:Object in result) {
						LocalSettings.setLocalSetting((o.id as int),(o.value as String) == "-" ? "":(o.value as String), false);
					}
				} 
				addMissingLocalSetting(result.length);
			}
			
			function addMissingLocalSetting(settingId:int):void {
				if (settingId == LocalSettings.getNumberOfSettings()) {
					createBlueToothDeviceTable();
				} else {
					insertLocalSetting(settingId, LocalSettings.getLocalSetting(settingId));
					addMissingLocalSetting(settingId +1);
				}
			}
		}
		
		private static function createBlueToothDeviceTable():void {
			sqlStatement.clearParameters();
			sqlStatement.text = CREATE_TABLE_BLUETOOTH_DEVICE;
			sqlStatement.addEventListener(SQLEvent.RESULT,tableCreated);
			sqlStatement.addEventListener(SQLErrorEvent.ERROR,tableCreationError);
			sqlStatement.execute();
			
			function tableCreated(se:SQLEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
				selectBlueToothDevices();
			}
			
			function tableCreationError(see:SQLErrorEvent):void {
				if (debugMode) trace("Database.as : Failed to create BlueToothDevice table. Database:0005");
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
				dispatchInformation("failed_to_create_bluetoothdevice_table", see.error.message + " - " + see.error.details);
			}
		}
		
		private static function selectBlueToothDevices():void {
			sqlStatement.clearParameters();
			sqlStatement.text = SELECT_ALL_BLUETOOTH_DEVICES;
			sqlStatement.addEventListener(SQLEvent.RESULT,blueToothDevicesSelected);
			sqlStatement.addEventListener(SQLErrorEvent.ERROR,blueToothDevicesSelectionFailed);
			sqlStatement.execute();
			
			function blueToothDevicesSelected(se:SQLEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,blueToothDevicesSelected);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,blueToothDevicesSelectionFailed);
				var result:Object = sqlStatement.getResult().data;
				if (result != null) {
					if (result is Array) {
						if ((result as Array).length == 1) {
							//there's a bluetoothdevice already, no need to further check
							deleteBgReadingsAsynchronous(true);
							return;
						}
					}
				}
				//not using else here because i think there might be other cases like restult not being null but having no elements ?
				insertBlueToothDevice();
			}
			
			function blueToothDevicesSelectionFailed(se:SQLErrorEvent):void {
				if (debugMode) trace("Database.as : Failed to select BlueToothDevices. Database:0009");
				sqlStatement.removeEventListener(SQLEvent.RESULT,blueToothDevicesSelected);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,blueToothDevicesSelectionFailed);
				dispatchInformation("failed_to_select_bluetoothdevice", se.error.message + " - " + se.error.details);
			}
		}
		
		/**
		 * will add one row, with name and address "", and default id<br>
		 * asynchronous
		 */
		private static function insertBlueToothDevice():void {
			sqlStatement.clearParameters();
			sqlStatement.text = INSERT_DEFAULT_BLUETOOTH_DEVICE;
			sqlStatement.parameters[":bluetoothdevice_id"] = CGMBlueToothDevice.DEFAULT_BLUETOOTH_DEVICE_ID;
			sqlStatement.parameters[":name"] = ""; 
			sqlStatement.parameters[":address"] = "";
			sqlStatement.parameters[":lastmodifiedtimestamp"] = (new Date()).valueOf();
			sqlStatement.addEventListener(SQLEvent.RESULT,defaultBlueToothDeviceInserted);
			sqlStatement.addEventListener(SQLErrorEvent.ERROR,defaultBlueToothDeviceInsetionFailed);
			sqlStatement.execute();
			
			function defaultBlueToothDeviceInserted(se:SQLEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,defaultBlueToothDeviceInserted);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,defaultBlueToothDeviceInsetionFailed);
				deleteBgReadingsAsynchronous(true);
			}
			
			function defaultBlueToothDeviceInsetionFailed(see:SQLErrorEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,defaultBlueToothDeviceInserted);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,defaultBlueToothDeviceInsetionFailed);
				if (debugMode) trace("Database.as : insertBlueToothDevice failed. Database 0014");
				dispatchInformation("failed_to_insert_bluetoothdevice", see.error.message + " - " + see.error.details);
			}
		}
		
		/**
		 * asynchronous 
		 */
		private static function deleteBgReadingsAsynchronous(continueCreatingTables:Boolean):void {
			sqlStatement.clearParameters();
			sqlStatement.text = "DELETE FROM bgreading where (timestamp < :timestamp)";
			sqlStatement.parameters[":timestamp"] = (new Date()).valueOf() - MAX_DAYS_TO_STORE_BGREADINGS_IN_DATABASE * 24 * 60 * 60 * 1000;
			
			sqlStatement.addEventListener(SQLEvent.RESULT,oldBgReadingsDeleted);
			sqlStatement.addEventListener(SQLErrorEvent.ERROR,oldBgReadingDeletionFailed);
			sqlStatement.execute();
			
			function oldBgReadingsDeleted(se:SQLEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,oldBgReadingsDeleted);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,oldBgReadingDeletionFailed);
				if (continueCreatingTables)
					createAlertTypeTable();
			}
			
			function oldBgReadingDeletionFailed(see:SQLErrorEvent):void {
				if (debugMode) trace("Database.as : Failed to delete old bgreadings");
				sqlStatement.removeEventListener(SQLEvent.RESULT,oldBgReadingsDeleted);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,oldBgReadingDeletionFailed);
				dispatchInformation("failed to delete old bgreadings", see.error.message + " - " + see.error.details);
			}
		}
		
		private static function deleteBgReadingsSynchronous():void {
			try {
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.UPDATE);
				conn.begin();
				var deleteRequest:SQLStatement = new SQLStatement();
				deleteRequest.sqlConnection = conn;
				deleteRequest.text = "DELETE FROM bgreading where (timestamp < :timestamp)";
				deleteRequest.parameters[":timestamp"] = (new Date()).valueOf() - MAX_DAYS_TO_STORE_BGREADINGS_IN_DATABASE * 24 * 60 * 60 * 1000;
				deleteRequest.execute();
				deleteRequest.getResult();
				conn.close();
			} catch (error:SQLError) {
				if (conn.connected) conn.close();
				dispatchInformation('deleteBgReadingsSynchronous : error while deleting bgreadings', error.message + " - " + error.details);
			} catch (other:Error) {
				if (conn.connected) conn.close();
				dispatchInformation('deleteBgReadingsSynchronous : error while deleting bgreadings', other.getStackTrace().toString());
			}
		}
		
		private static function bgReadingEventReceived(event:TransmitterServiceEvent):void {
			deleteBgReadingsSynchronous();
		}
		
		private static function createAlertTypeTable():void {
			sqlStatement.clearParameters();
			sqlStatement.text = CREATE_TABLE_ALERT_TYPES;
			sqlStatement.addEventListener(SQLEvent.RESULT,tableCreated);
			sqlStatement.addEventListener(SQLErrorEvent.ERROR,tableCreationError);
			sqlStatement.execute();
			
			function tableCreated(se:SQLEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
				var noAlertName:String = "No Alert";
				if (getAlertType(noAlertName) == null) {
					var noAlert:AlertType = new AlertType(null, Number.NaN, noAlertName, false, false, false, false, false, "no_sound", 10, 0);
					insertAlertTypeSychronous(noAlert);
				}
				var silentAlertName:String = ModelLocator.resourceManagerInstance.getString("alertsettingsscreen","silent_alert");
				if (getAlertType(silentAlertName) == null) {
					var silentAlert:AlertType = new AlertType(null, Number.NaN, silentAlertName, false, false, true, true, false, "no_sound", 30, 0);
					insertAlertTypeSychronous(silentAlert);
				}
				
				createTreatmentsTable();
			}
			
			function tableCreationError(see:SQLErrorEvent):void {
				if (debugMode) trace("Database.as : Failed to create alerttype table.");
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
				dispatchInformation('failed_to_create_bgreading_table', see != null ? see.error.message:null);
			}
		}
		
		private static function createTreatmentsTable():void 
		{
			sqlStatement.clearParameters();
			sqlStatement.text = CREATE_TABLE_TREATMENTS;
			sqlStatement.addEventListener(SQLEvent.RESULT,tableCreated);
			sqlStatement.addEventListener(SQLErrorEvent.ERROR,tableCreationError);
			sqlStatement.execute();
			
			function tableCreated(se:SQLEvent):void 
			{
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
				
				sqlStatement.clearParameters();
				
				//Check if table needs to be updated for new Spike format #1
				sqlStatement.text = "SELECT basalduration FROM treatments";
				sqlStatement.addEventListener(SQLEvent.RESULT,check1Performed);
				sqlStatement.addEventListener(SQLErrorEvent.ERROR,check1Error);
				sqlStatement.execute();
				
				function check1Performed(se:SQLEvent):void 
				{
					sqlStatement.removeEventListener(SQLEvent.RESULT,check1Performed);
					sqlStatement.removeEventListener(SQLErrorEvent.ERROR,check1Error);
					sqlStatement.clearParameters();
					
					//Check if table needs to be updated for new Spike format #2
					sqlStatement.text = "SELECT carbdelay FROM treatments";
					sqlStatement.addEventListener(SQLEvent.RESULT,check2Performed);
					sqlStatement.addEventListener(SQLErrorEvent.ERROR,check2Error);
					sqlStatement.execute();
					
					function check2Performed(se:SQLEvent):void 
					{
						sqlStatement.removeEventListener(SQLEvent.RESULT,check2Performed);
						sqlStatement.removeEventListener(SQLErrorEvent.ERROR,check2Error);
						sqlStatement.clearParameters();
						
						//Check if table needs to be updated for new Spike format #2
						sqlStatement.text = "SELECT children FROM treatments";
						sqlStatement.addEventListener(SQLEvent.RESULT,check3Performed);
						sqlStatement.addEventListener(SQLErrorEvent.ERROR,check3Error);
						sqlStatement.execute();
						
						function check3Performed(se:SQLEvent):void 
						{
							sqlStatement.removeEventListener(SQLEvent.RESULT,check3Performed);
							sqlStatement.removeEventListener(SQLErrorEvent.ERROR,check3Error);
							sqlStatement.clearParameters();
							
							//Check if table needs to be updated for new Spike format #2
							sqlStatement.text = "SELECT needsadjustment FROM treatments";
							sqlStatement.addEventListener(SQLEvent.RESULT,check4Performed);
							sqlStatement.addEventListener(SQLErrorEvent.ERROR,check4Error);
							sqlStatement.execute();
							
							function check4Performed(se:SQLEvent):void 
							{
								sqlStatement.removeEventListener(SQLEvent.RESULT,check4Performed);
								sqlStatement.removeEventListener(SQLErrorEvent.ERROR,check4Error);
								sqlStatement.clearParameters();
								
								//Check if table needs to be updated for new Spike format #2
								sqlStatement.text = "SELECT prebolus FROM treatments";
								sqlStatement.addEventListener(SQLEvent.RESULT,check5Performed);
								sqlStatement.addEventListener(SQLErrorEvent.ERROR,check5Error);
								sqlStatement.execute();
								
								function check5Performed(se:SQLEvent):void 
								{
									sqlStatement.removeEventListener(SQLEvent.RESULT,check5Performed);
									sqlStatement.removeEventListener(SQLErrorEvent.ERROR,check5Error);
									sqlStatement.clearParameters();
									
									//Check if table needs to be updated for new Spike format #2
									sqlStatement.text = "SELECT duration FROM treatments";
									sqlStatement.addEventListener(SQLEvent.RESULT,check6Performed);
									sqlStatement.addEventListener(SQLErrorEvent.ERROR,check6Error);
									sqlStatement.execute();
									
									function check6Performed(se:SQLEvent):void 
									{
										sqlStatement.removeEventListener(SQLEvent.RESULT,check6Performed);
										sqlStatement.removeEventListener(SQLErrorEvent.ERROR,check6Error);
										sqlStatement.clearParameters();
										
										sqlStatement.text = "SELECT intensity FROM treatments";
										sqlStatement.addEventListener(SQLEvent.RESULT,check7Performed);
										sqlStatement.addEventListener(SQLErrorEvent.ERROR,check7Error);
										sqlStatement.execute();
										
										function check7Performed(se:SQLEvent):void 
										{
											sqlStatement.removeEventListener(SQLEvent.RESULT,check7Performed);
											sqlStatement.removeEventListener(SQLErrorEvent.ERROR,check7Error);
											sqlStatement.clearParameters();
											
											sqlStatement.text = "SELECT isbasalabsolute FROM treatments";
											sqlStatement.addEventListener(SQLEvent.RESULT,check8Performed);
											sqlStatement.addEventListener(SQLErrorEvent.ERROR,check8Error);
											sqlStatement.execute();
											
											function check8Performed(se:SQLEvent):void 
											{
												sqlStatement.removeEventListener(SQLEvent.RESULT,check8Performed);
												sqlStatement.removeEventListener(SQLErrorEvent.ERROR,check8Error);
												sqlStatement.clearParameters();
												
												sqlStatement.text = "SELECT isbasalrelative FROM treatments";
												sqlStatement.addEventListener(SQLEvent.RESULT,check9Performed);
												sqlStatement.addEventListener(SQLErrorEvent.ERROR,check9Error);
												sqlStatement.execute();
												
												function check9Performed(se:SQLEvent):void 
												{
													sqlStatement.removeEventListener(SQLEvent.RESULT,check9Performed);
													sqlStatement.removeEventListener(SQLErrorEvent.ERROR,check9Error);
													sqlStatement.clearParameters();
													
													sqlStatement.text = "SELECT istempbasalend FROM treatments";
													sqlStatement.addEventListener(SQLEvent.RESULT,check10Performed);
													sqlStatement.addEventListener(SQLErrorEvent.ERROR,check10Error);
													sqlStatement.execute();
													
													function check10Performed(se:SQLEvent):void 
													{
														sqlStatement.removeEventListener(SQLEvent.RESULT,check10Performed);
														sqlStatement.removeEventListener(SQLErrorEvent.ERROR,check10Error);
														sqlStatement.clearParameters();
														
														sqlStatement.text = "SELECT basalabsoluteamount FROM treatments";
														sqlStatement.addEventListener(SQLEvent.RESULT,check11Performed);
														sqlStatement.addEventListener(SQLErrorEvent.ERROR,check11Error);
														sqlStatement.execute();
														
														function check11Performed(se:SQLEvent):void 
														{
															sqlStatement.removeEventListener(SQLEvent.RESULT,check11Performed);
															sqlStatement.removeEventListener(SQLErrorEvent.ERROR,check11Error);
															sqlStatement.clearParameters();
															
															sqlStatement.text = "SELECT basalpercentamount FROM treatments";
															sqlStatement.addEventListener(SQLEvent.RESULT,check12Performed);
															sqlStatement.addEventListener(SQLErrorEvent.ERROR,check12Error);
															sqlStatement.execute();
															
															function check12Performed(se:SQLEvent):void 
															{
																sqlStatement.removeEventListener(SQLEvent.RESULT,check12Performed);
																sqlStatement.removeEventListener(SQLErrorEvent.ERROR,check12Error);
																sqlStatement.clearParameters();
																
																//All checks performed. Continue with next table
																createInsulinsTable();
															}
															
															function check12Error(see:SQLErrorEvent):void 
															{
																if (debugMode) trace("Database.as : basalpercentamount column not found in treatments table (old version of Spike). Updating table...");
																sqlStatement.clearParameters();
																sqlStatement.text = "ALTER TABLE treatments ADD COLUMN basalpercentamount REAL;";
																sqlStatement.execute();
															}
														}
														
														function check11Error(see:SQLErrorEvent):void 
														{
															if (debugMode) trace("Database.as : basalabsoluteamount column not found in treatments table (old version of Spike). Updating table...");
															sqlStatement.clearParameters();
															sqlStatement.text = "ALTER TABLE treatments ADD COLUMN basalabsoluteamount REAL;";
															sqlStatement.execute();
														}
													}
													
													function check10Error(see:SQLErrorEvent):void 
													{
														if (debugMode) trace("Database.as : istempbasalend column not found in treatments table (old version of Spike). Updating table...");
														sqlStatement.clearParameters();
														sqlStatement.text = "ALTER TABLE treatments ADD COLUMN istempbasalend STRING;";
														sqlStatement.execute();
													}
												}
												
												function check9Error(see:SQLErrorEvent):void 
												{
													if (debugMode) trace("Database.as : isbasalrelative column not found in treatments table (old version of Spike). Updating table...");
													sqlStatement.clearParameters();
													sqlStatement.text = "ALTER TABLE treatments ADD COLUMN isbasalrelative STRING;";
													sqlStatement.execute();
												}
											}
											
											function check8Error(see:SQLErrorEvent):void 
											{
												if (debugMode) trace("Database.as : isbasalabsolute column not found in treatments table (old version of Spike). Updating table...");
												sqlStatement.clearParameters();
												sqlStatement.text = "ALTER TABLE treatments ADD COLUMN isbasalabsolute STRING;";
												sqlStatement.execute();
											}
										}
										
										function check7Error(see:SQLErrorEvent):void 
										{
											if (debugMode) trace("Database.as : intensity column not found in treatments table (old version of Spike). Updating table...");
											sqlStatement.clearParameters();
											sqlStatement.text = "ALTER TABLE treatments ADD COLUMN intensity STRING;";
											sqlStatement.execute();
										}
									}
									
									function check6Error(see:SQLErrorEvent):void 
									{
										if (debugMode) trace("Database.as : duration column not found in treatments table (old version of Spike). Updating table...");
										sqlStatement.clearParameters();
										sqlStatement.text = "ALTER TABLE treatments ADD COLUMN duration REAL;";
										sqlStatement.execute();
									}
								}
								
								function check5Error(see:SQLErrorEvent):void 
								{
									if (debugMode) trace("Database.as : prebolus column not found in treatments table (old version of Spike). Updating table...");
									sqlStatement.clearParameters();
									sqlStatement.text = "ALTER TABLE treatments ADD COLUMN prebolus REAL;";
									sqlStatement.execute();
								}
							}
							
							function check4Error(see:SQLErrorEvent):void 
							{
								if (debugMode) trace("Database.as : needsadjustment column not found in treatments table (old version of Spike). Updating table...");
								sqlStatement.clearParameters();
								sqlStatement.text = "ALTER TABLE treatments ADD COLUMN needsadjustment STRING;";
								sqlStatement.execute();
							}
						}
						
						function check3Error(see:SQLErrorEvent):void 
						{
							if (debugMode) trace("Database.as : children column not found in treatments table (old version of Spike). Updating table...");
							sqlStatement.clearParameters();
							sqlStatement.text = "ALTER TABLE treatments ADD COLUMN children STRING;";
							sqlStatement.execute();
						}
					}
					
					function check2Error(see:SQLErrorEvent):void 
					{
						if (debugMode) trace("Database.as : carbdelay column not found in treatments table (old version of Spike). Updating table...");
						sqlStatement.clearParameters();
						sqlStatement.text = "ALTER TABLE treatments ADD COLUMN carbdelay REAL;";
						sqlStatement.execute();
					}
				}
				
				function check1Error(see:SQLErrorEvent):void 
				{
					if (debugMode) trace("Database.as : basalduration column not found in treatments table (old version of Spike). Updating table...");
					sqlStatement.clearParameters();
					sqlStatement.text = "ALTER TABLE treatments ADD COLUMN basalduration REAL;";
					sqlStatement.execute();
				}
			}
			
			function tableCreationError(see:SQLErrorEvent):void 
			{
				if (debugMode) trace("Database.as : Failed to create insulins table");
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
				dispatchInformation('failed_to_create_insulins_table', see != null ? see.error.message:null);
			}
		}
		
		private static function createInsulinsTable():void {
			sqlStatement.clearParameters();
			sqlStatement.text = CREATE_TABLE_INSULINS;
			sqlStatement.addEventListener(SQLEvent.RESULT,tableCreated);
			sqlStatement.addEventListener(SQLErrorEvent.ERROR,tableCreationError);
			sqlStatement.execute();
			
			function tableCreated(se:SQLEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
				
				sqlStatement.clearParameters();
				
				//Check if table needs to be updated for new Spike format #1
				sqlStatement.text = "SELECT ishidden FROM insulins";
				sqlStatement.addEventListener(SQLEvent.RESULT,check1Performed);
				sqlStatement.addEventListener(SQLErrorEvent.ERROR,check1Error);
				sqlStatement.execute();
				
				function check1Performed(se:SQLEvent):void 
				{
					sqlStatement.removeEventListener(SQLEvent.RESULT,check1Performed);
					sqlStatement.removeEventListener(SQLErrorEvent.ERROR,check1Error);
					sqlStatement.clearParameters();
					
					//Check if table needs to be updated for new Spike format #2
					sqlStatement.text = "SELECT curve FROM insulins";
					sqlStatement.addEventListener(SQLEvent.RESULT,check2Performed);
					sqlStatement.addEventListener(SQLErrorEvent.ERROR,check2Error);
					sqlStatement.execute();
					
					function check2Performed(se:SQLEvent):void 
					{
						sqlStatement.removeEventListener(SQLEvent.RESULT,check2Performed);
						sqlStatement.removeEventListener(SQLErrorEvent.ERROR,check2Error);
						sqlStatement.clearParameters();
						
						//Check if table needs to be updated for new Spike format #3
						sqlStatement.text = "SELECT peak FROM insulins";
						sqlStatement.addEventListener(SQLEvent.RESULT,check3Performed);
						sqlStatement.addEventListener(SQLErrorEvent.ERROR,check3Error);
						sqlStatement.execute();
						
						function check3Performed(se:SQLEvent):void 
						{
							sqlStatement.removeEventListener(SQLEvent.RESULT,check3Performed);
							sqlStatement.removeEventListener(SQLErrorEvent.ERROR,check3Error);
							sqlStatement.clearParameters();
							
							//All checks performed. Continue with next table
							createProfilesTable();
						}
						
						function check3Error(see:SQLErrorEvent):void 
						{
							if (debugMode) trace("Database.as : peak column not found in insulins table (old version of Spike). Updating table...");
							sqlStatement.clearParameters();
							sqlStatement.text = "ALTER TABLE insulins ADD COLUMN peak REAL;";
							sqlStatement.execute();
						}
					}
					
					function check2Error(see:SQLErrorEvent):void 
					{
						if (debugMode) trace("Database.as : curve column not found in insulins table (old version of Spike). Updating table...");
						sqlStatement.clearParameters();
						sqlStatement.text = "ALTER TABLE insulins ADD COLUMN curve STRING;";
						sqlStatement.execute();
					}
				}
				
				function check1Error(see:SQLErrorEvent):void 
				{
					if (debugMode) trace("Database.as : ishidden column not found in insulins table (old version of Spike). Updating table...");
					sqlStatement.clearParameters();
					sqlStatement.text = "ALTER TABLE insulins ADD COLUMN ishidden STRING;";
					sqlStatement.execute();
				}
			}
			
			function tableCreationError(see:SQLErrorEvent):void {
				if (debugMode) trace("Database.as : Failed to create insulins table");
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
				dispatchInformation('failed_to_create_insulins_table', see != null ? see.error.message:null);
			}
		}
		
		private static function createProfilesTable():void {
			sqlStatement.clearParameters();
			sqlStatement.text = CREATE_TABLE_PROFILE;
			sqlStatement.addEventListener(SQLEvent.RESULT,tableCreated);
			sqlStatement.addEventListener(SQLErrorEvent.ERROR,tableCreationError);
			sqlStatement.execute();
			
			function tableCreated(se:SQLEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
				
				sqlStatement.clearParameters();
				
				//Check if table needs to be updated for new Spike format #1
				sqlStatement.text = "SELECT trendcorrections FROM profiles";
				sqlStatement.addEventListener(SQLEvent.RESULT,checkProfilesPerformed);
				sqlStatement.addEventListener(SQLErrorEvent.ERROR,checkProfilesError);
				sqlStatement.execute();
				
				function checkProfilesPerformed(se:SQLEvent):void 
				{
					sqlStatement.removeEventListener(SQLEvent.RESULT,checkProfilesPerformed);
					sqlStatement.removeEventListener(SQLErrorEvent.ERROR,checkProfilesError);
					sqlStatement.clearParameters();
					
					createHealthKitTreatmentsTable();
				}
				
				function checkProfilesError(see:SQLErrorEvent):void 
				{
					if (debugMode) trace("Database.as : trendcorrections column not found in profiles table (old version of Spike). Updating table...");
					sqlStatement.clearParameters();
					sqlStatement.clearParameters();
					sqlStatement.text = "ALTER TABLE profiles ADD COLUMN trendcorrections STRING;";
					sqlStatement.execute();
				}
			}
			
			function tableCreationError(see:SQLErrorEvent):void {
				if (debugMode) trace("Database.as : Failed to create profiles table");
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
				dispatchInformation('failed_to_create_profiles_table', see != null ? see.error.message:null);
			}
		}
		
		private static function createHealthKitTreatmentsTable():void {
			sqlStatement.clearParameters();
			sqlStatement.text = CREATE_TABLE_HEALTHKIT_TREATMENTS;
			sqlStatement.addEventListener(SQLEvent.RESULT,tableCreated);
			sqlStatement.addEventListener(SQLErrorEvent.ERROR,tableCreationError);
			sqlStatement.execute();
			
			function tableCreated(se:SQLEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
				createFoodsTable();
			}
			
			function tableCreationError(see:SQLErrorEvent):void {
				if (debugMode) trace("Database.as : Failed to create healthkittreatments table");
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
				dispatchInformation('failed_to_create_healthkittreatments_table', see != null ? see.error.message:null);
			}
		}
		
		private static function createFoodsTable():void {
			sqlStatement.clearParameters();
			sqlStatement.text = CREATE_TABLE_FOODS;
			sqlStatement.addEventListener(SQLEvent.RESULT,tableCreated);
			sqlStatement.addEventListener(SQLErrorEvent.ERROR,tableCreationError);
			sqlStatement.execute();
			
			function tableCreated(se:SQLEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
				createRecipesListTable();
			}
			
			function tableCreationError(see:SQLErrorEvent):void {
				if (debugMode) trace("Database.as : Failed to create foods table");
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
				dispatchInformation('failed_to_create_foods_table', see != null ? see.error.message:null);
			}
		}
		
		private static function createRecipesListTable():void {
			sqlStatement.clearParameters();
			sqlStatement.text = CREATE_TABLE_RECIPES_LIST;
			sqlStatement.addEventListener(SQLEvent.RESULT,tableCreated);
			sqlStatement.addEventListener(SQLErrorEvent.ERROR,tableCreationError);
			sqlStatement.execute();
			
			function tableCreated(se:SQLEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
				createRecipesFoodsTable();
			}
			
			function tableCreationError(see:SQLErrorEvent):void {
				if (debugMode) trace("Database.as : Failed to create recipes list table");
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
				dispatchInformation('failed_to_create_recipes_list_table', see != null ? see.error.message:null);
			}
		}
		
		private static function createRecipesFoodsTable():void {
			sqlStatement.clearParameters();
			sqlStatement.text = CREATE_TABLE_RECIPES_FOODS;
			sqlStatement.addEventListener(SQLEvent.RESULT,tableCreated);
			sqlStatement.addEventListener(SQLErrorEvent.ERROR,tableCreationError);
			sqlStatement.execute();
			
			function tableCreated(se:SQLEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
				createIOBCOBCachesTable();
			}
			
			function tableCreationError(see:SQLErrorEvent):void {
				if (debugMode) trace("Database.as : Failed to create recipes foods table");
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
				dispatchInformation('failed_to_create_recipes_foods_table', see != null ? see.error.message:null);
			}
		}
		
		private static function createIOBCOBCachesTable():void {
			sqlStatement.clearParameters();
			sqlStatement.text = CREATE_TABLE_IOB_COB_CACHES;
			sqlStatement.addEventListener(SQLEvent.RESULT,tableCreated);
			sqlStatement.addEventListener(SQLErrorEvent.ERROR,tableCreationError);
			sqlStatement.execute();
			
			function tableCreated(se:SQLEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
				createBasalRatesTable();
			}
			
			function tableCreationError(see:SQLErrorEvent):void {
				if (debugMode) trace("Database.as : Failed to create iobcobcaches table.");
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
				dispatchInformation('failed_to_create_iobcobcaches_table', see != null ? see.error.message:null);
			}
		}
		
		private static function createBasalRatesTable():void {
			sqlStatement.clearParameters();
			sqlStatement.text = CREATE_TABLE_BASAL_RATES;
			sqlStatement.addEventListener(SQLEvent.RESULT,tableCreated);
			sqlStatement.addEventListener(SQLErrorEvent.ERROR,tableCreationError);
			sqlStatement.execute();
			
			function tableCreated(se:SQLEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
				finishedCreatingTables();
			}
			
			function tableCreationError(see:SQLErrorEvent):void {
				if (debugMode) trace("Database.as : Failed to create basalrates table.");
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
				dispatchInformation('failed_to_create_basalrates_table', see != null ? see.error.message:null);
			}
		}
		
		private static function finishedCreatingTables():void {
			var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.DATABASE_INIT_FINISHED_EVENT);
			instance.dispatchEvent(event);
		}
		
		private static function createDatabaseFromAssets(targetFile:File):Boolean 			
		{
			var isSuccess:Boolean = true; 
			
			var sampleFile:File = File.applicationDirectory.resolvePath("assets/database/" + sampleDatabaseFileName);
			if ( !sampleFile.exists )
			{
				isSuccess = false;
			}
			else
			{
				sampleFile.copyTo(targetFile);			
			}
			return isSuccess;			
		}
		
		/**
		 * synchronous, no returnvalue, will simply overwrite the bluetoothdevice attributes (which is a single instance)<br>
		 */
		public static function getBlueToothDevice():void {
			var returnValue:CGMBlueToothDevice;
			try {
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.READ);
				conn.begin();
				var getRequest:SQLStatement = new SQLStatement();
				getRequest.sqlConnection = conn;
				getRequest.text = SELECT_ALL_BLUETOOTH_DEVICES;
				getRequest.execute();
				var result:SQLResult = getRequest.getResult();
				conn.close();
				var numResults:int = result.data.length;
				if (numResults == 1) {
					CGMBlueToothDevice.name = result.data[0].name;
					CGMBlueToothDevice.address = result.data[0].address;
					CGMBlueToothDevice.setLastModifiedTimestamp(result.data[0].lastmodifiedtimestamp); 
				} else {
					dispatchInformation('error_while_getting_bluetooth_device_in_db', 'resulting amount of bluetoothdevices should be 1 but is ' + numResults);
				}
			} catch (error:SQLError) {
				if (conn.connected) conn.close();
				dispatchInformation('error_while_getting_bluetooth_device_in_db', error.message + " - " + error.details);
			} catch (other:Error) {
				if (conn.connected) conn.close();
				dispatchInformation('error_while_getting_bluetooth_device_in_db', other.getStackTrace().toString());
			}
		}
		
		/**
		 * to update the one and only bluetoothdevice<br>
		 * synchronous
		 */
		public static function updateBlueToothDeviceSynchronous(address:String, name:String, lastModifiedTimeStamp:Number):void {
			if (address == null) address = "";
			if (name == null) name = "";
			try  {
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.UPDATE);
				conn.begin();
				var updateRequest:SQLStatement = new SQLStatement();
				updateRequest.sqlConnection = conn;
				updateRequest.text = "UPDATE bluetoothdevice SET " +
					"lastmodifiedtimestamp = " + (isNaN(lastModifiedTimeStamp) ? (new Date()).valueOf() : lastModifiedTimeStamp) + "," +
					"address = " + (address == "" ? null:("'" + address + "'")) + ", " + 
					"name = " + (name == "" ? null:("'" + name + "'")); 
				updateRequest.execute();
				conn.commit();
				conn.close();
			} catch (error:SQLError) {
				if (conn.connected) {
					conn.rollback();
					conn.close();
				}
				dispatchInformation('error_while_updating_bluetooth_device', error.message + " - " + error.details);
			}
		}
		
		public static function insertAlertTypeSychronous(alertType:AlertType):void {
			var insertRequest:SQLStatement;
			try {
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.UPDATE);
				conn.begin();
				insertRequest = new SQLStatement();
				insertRequest.sqlConnection = conn;
				insertRequest.text = "INSERT INTO alerttypes (alerttypeid, " +
					"lastmodifiedtimestamp, " +
					"alarmname, " +
					"enablelights, " +
					"enablevibration, " +
					"snoozefromnotification, " +
					"soundtext, " +
					"defaultsnoozeperiod, " +
					"repeatinminutes, " +
					"enabled, " +
					"overridesilentmode) " +
					"VALUES ('" + alertType.uniqueId + "', " +
					alertType.lastModifiedTimestamp + ", " +
					"'" + alertType.alarmName + "', " +
					(alertType.enableLights ? "1":"0")  +", " +
					(alertType.enableVibration ? "1":"0")  +", " +
					(alertType.snoozeFromNotification ? "1":"0")  +", " +
					"'" + alertType.sound + "', " +
					alertType.defaultSnoozePeriodInMinutes +  ", " +
					alertType.repeatInMinutes +  ", " +
					(alertType.enabled ? "1":"0") + ", " +
					(alertType.overrideSilentMode ? "1":"0")
					 + ")";
				insertRequest.execute();
				conn.commit();
				conn.close();
			} catch (error:SQLError) {
				if (conn.connected) {
					conn.rollback();
					conn.close();
				}			
				dispatchInformation('error while inserting alerttype', error.message + " - " + error.details);
			}
		}
		
		public static function deleteAlertTypeSynchronous(alertType:AlertType):void {
			try {
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.UPDATE);
				conn.begin();
				var deleteRequest:SQLStatement = new SQLStatement();
				deleteRequest.sqlConnection = conn;
				deleteRequest.text = "DELETE from alerttypes where alerttypeid = " + "'" + alertType.uniqueId + "'";
				deleteRequest.execute();
				conn.commit();
				conn.close();
			} catch (error:SQLError) {
				if (conn.connected) {
					conn.rollback();
					conn.close();
				}			
				dispatchInformation('error while deleting alerttype', error.message + " - " + error.details);
			}
		}
		
		public static function updateAlertTypeSynchronous(alertType:AlertType):void {
			var insertRequest:SQLStatement;
			try {
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.UPDATE);
				conn.begin();
				insertRequest = new SQLStatement();
				insertRequest.sqlConnection = conn;
				insertRequest.text = "UPDATE alerttypes SET " +
					"lastmodifiedtimestamp = " + alertType.lastModifiedTimestamp.toString() + "," +
					"alarmname = '" + alertType.alarmName + "', " +
					"enablelights = " + (alertType.enableLights ? "1":"0") + ", " + 
					"enablevibration = " + (alertType.enableVibration ? "1":"0") + ", " + 
					"snoozefromnotification = " + (alertType.snoozeFromNotification ? "1":"0") + ", " + 
					"soundtext = '" + alertType.sound + "', " + 
					"defaultsnoozeperiod = " + alertType.defaultSnoozePeriodInMinutes + ", " + 
					"repeatinminutes = " + alertType.repeatInMinutes + ", " + 
					"overridesilentmode = " + (alertType.overrideSilentMode ? "1":"0") + ", " + 
					"enabled = " + (alertType.enabled ? "1":"0") + 
					" WHERE alerttypeid = " + "'" + alertType.uniqueId + "'"; 
				insertRequest.execute();
				conn.commit();
				conn.close();
			} catch (error:SQLError) {
				if (conn.connected) {
					conn.rollback();
					conn.close();
				}			
				dispatchInformation('error while updating alerttype', error.message + " - " + error.details + "\ninsertRequest.txt = " + insertRequest.text);
			}
		}
		
		/**
		 * returns null if no alerttype with that name
		 */
		public static function getAlertType(alarmName:String):AlertType {
			var returnValue:AlertType = null;
			try {
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.READ);
				conn.begin();
				var getRequest:SQLStatement = new SQLStatement();
				getRequest.sqlConnection = conn;
				getRequest.text = "SELECT * FROM alerttypes WHERE alarmname = '" + alarmName +"'";
				getRequest.execute();
				var result:SQLResult = getRequest.getResult();
				conn.close();
				if (result.data != null) {
						returnValue = new AlertType(
							result.data[0].alerttypeid,
							result.data[0].lastmodifiedtimestamp,
							result.data[0].alarmname,
							result.data[0].enablelights == "1" ? true:false,
							result.data[0].enablevibration == "1" ? true:false,
							result.data[0].snoozefromnotification == "1" ? true:false,
							result.data[0].enabled == "1" ? true:false,
							result.data[0].overridesilentmode == "1" ? true:false,
							result.data[0].soundtext,
							result.data[0].defaultsnoozeperiod,
							result.data[0].repeatinminutes
						);
				}
			} catch (error:SQLError) {
				if (conn.connected) conn.close();
				myTrace('error in getAlertType for alarmName ' + alarmName + "," + error.message + " - " + error.details);
			} catch (other:Error) {
				if (conn.connected) conn.close();
				myTrace('error in getAlertType for alarmName ' + alarmName + "," + other.getStackTrace().toString());
			} finally {
				if (conn.connected) conn.close();
				return returnValue;
			}
		}
		
		public static function getAllAlertTypes():ArrayCollection {
			var returnValue:ArrayCollection = new ArrayCollection();
			try {
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.READ);
				conn.begin();
				var getRequest:SQLStatement = new SQLStatement();
				getRequest.sqlConnection = conn;
				getRequest.text = "SELECT * FROM alerttypes";
				getRequest.execute();
				var result:SQLResult = getRequest.getResult();
				conn.close();
				if (result.data != null) {
					var numResults:int = result.data.length;
					for (var i:int = 0; i < numResults; i++) 
					{ 
						returnValue.addItem(new AlertType(
							result.data[i].alerttypeid,
							result.data[i].lastmodifiedtimestamp,
							result.data[i].alarmname,
							result.data[i].enablelights == "1" ? true:false,
							result.data[i].enablevibration == "1" ? true:false,
							result.data[i].snoozefromnotification == "1" ? true:false,
							result.data[i].enabled == "1" ? true:false,
							result.data[i].overridesilentmode == "1" ? true:false,
							result.data[i].soundtext,
							result.data[i].defaultsnoozeperiod,
							result.data[i].repeatinminutes
						));
					} 
				}
			} catch (error:SQLError) {
				if (conn.connected) conn.close();
				myTrace('error_while_getting_alerttypes_in_db' + ", " + error.message + " - " + error.details);
			} catch (other:Error) {
				if (conn.connected) conn.close();
				myTrace('error_while_getting_alerttypes_in_db' + ", " + other.getStackTrace().toString());
			} finally {
				if (conn.connected) conn.close();
				return returnValue;
			}
		}
		
		public static function getAlertTypesList():Array 
		{
			var alertTypesList:Array = [];
			
			try 
			{
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.READ);
				conn.begin();
				
				var getRequest:SQLStatement = new SQLStatement();
				getRequest.sqlConnection = conn;
				getRequest.text = "SELECT * FROM alerttypes";
				getRequest.execute();
				
				var result:SQLResult = getRequest.getResult();
				
				conn.close();
				
				if (result.data != null) 
				{
					var numResults:int = result.data.length;
					for (var i:int = 0; i < numResults; i++) 
					{ 
						alertTypesList.push
						(
							new AlertType
							(
								result.data[i].alerttypeid,
								result.data[i].lastmodifiedtimestamp,
								result.data[i].alarmname,
								result.data[i].enablelights == "1" ? true:false,
								result.data[i].enablevibration == "1" ? true:false,
								result.data[i].snoozefromnotification == "1" ? true:false,
								result.data[i].enabled == "1" ? true:false,
								result.data[i].overridesilentmode == "1" ? true:false,
								result.data[i].soundtext,
								result.data[i].defaultsnoozeperiod,
								result.data[i].repeatinminutes
							)
						);
					} 
				}
			} 
			catch (error:SQLError) 
			{
				if (conn.connected) conn.close();
					myTrace('error_while_getting_alerttypes_in_db' + ", " + error.message + " - " + error.details);
			} 
			catch (other:Error) 
			{
				if (conn.connected) conn.close();
					myTrace('error_while_getting_alerttypes_in_db' + ", " + other.getStackTrace().toString());
			} 
			finally 
			{
				if (conn.connected) conn.close();
				
				alertTypesList = alertTypesList.sortOn(["alarmName"], Array.CASEINSENSITIVE);
				
				return alertTypesList;
			}
		}
		
		/**
		 * deletes all calibrations<br>
		 * REMOVE THIS - CALIBRATIONS SHOULD BE DELETED AFTER X DAYS <br>
		 * synchronous
		 */
		public static function deleteAllCalibrationsSynchronous():void {
			try {
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.UPDATE);
				conn.begin();
				var deleteRequest:SQLStatement = new SQLStatement();
				deleteRequest.sqlConnection = conn;
				deleteRequest.text = "DELETE from calibration";
				deleteRequest.execute();
				conn.commit();
				conn.close();
			} catch (error:SQLError) {
				if (conn.connected) {
					conn.rollback();
					conn.close();
				}			
				dispatchInformation('error_while_deleting_all_calibration_in_db', error.message + " - " + error.details);
			}
		}
		
		/**
		 * latest calibrations with the specified sensor id from large to small (ie descending) 
		 */
		public static function getLatestCalibrations(number:int, sensorId:String):Array { 
			var returnValue:Array = [];
			try {
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.READ);
				conn.begin();
				var getRequest:SQLStatement = new SQLStatement();
				getRequest.sqlConnection = conn;
				getRequest.text = "SELECT * FROM calibration WHERE sensorid = '" + sensorId +"'";
				getRequest.execute();
				var result:SQLResult = getRequest.getResult();
				conn.close();
				if (result.data != null) 
				{	
					var numResults:int = result.data.length;
					var tempReturnValue:Array = [];
					for (var i:int = 0; i < numResults; i++) 
					{ 
						tempReturnValue.push(
							new Calibration(
								result.data[i].timestamp,
								result.data[i].sensorAgeAtTimeOfEstimation,
								((result.data[i].sensorid) as String) == "-" ? null:getSensor(result.data[i].sensorid),
								result.data[i].bg,
								result.data[i].rawValue,
								result.data[i].adjustedRawValue,
								result.data[i].sensorConfidence,
								result.data[i].slopeConfidence,
								result.data[i].rawTimestamp,
								result.data[i].slope,
								result.data[i].intercept,
								result.data[i].distanceFromEstimate,
								result.data[i].estimateRawAtTimeOfCalibration,
								result.data[i].estimateBgAtTimeOfCalibration,
								result.data[i].possibleBad == "1" ? true:false,
								result.data[i].checkIn == "1" ? true:false,
								result.data[i].firstDecay,
								result.data[i].secondDecay,
								result.data[i].firstSlope,
								result.data[i].secondSlope,
								result.data[i].firstIntercept,
								result.data[i].secondIntercept,
								result.data[i].firstScale,
								result.data[i].secondScale,
								result.data[i].lastmodifiedtimestamp,
								result.data[i].calibrationid)
						);
					}
					
					tempReturnValue.sortOn(["timestamp"], Array.NUMERIC | Array.DESCENDING);
					
					for (var cntr:int = 0; cntr < tempReturnValue.length; cntr++) {
						returnValue.push(tempReturnValue[cntr]);
						if (cntr == number - 1) {
							break;
						}
					}
				}
			} catch (error:SQLError) {
				if (conn.connected) conn.close();
				dispatchInformation('error_while_getting_latest_calibrations_in_db', error.message + " - " + error.details);
			} catch (other:Error) {
				if (conn.connected) conn.close();
				dispatchInformation('error_while_getting_latest_calibrations_in_db',other.getStackTrace().toString());
			} finally {
				if (conn.connected) conn.close();
				return returnValue;
			}
		}
		
		
		/**
		 * get calibrations with sensorid and last x days and slopeconfidence != 0 and sensorConfidence != 0<br>
		 * order by timestamp descending<br>
		 * synchronous<br>
		 */
		public static function getCalibrationForSensorInLastXDays(days:int, sensorid:String):ArrayCollection {
			var returnValue:ArrayCollection = new ArrayCollection();
			try {
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.READ);
				conn.begin();
				var getRequest:SQLStatement = new SQLStatement();
				getRequest.sqlConnection = conn;
				getRequest.text = "SELECT * FROM calibration WHERE sensorid = '" + sensorid + "' AND slopeConfidence != 0 " +
					"AND sensorConfidence != 0 and timestamp > " + (new Date((new Date()).valueOf() - (60000 * 60 * 24 * days))).valueOf();
				getRequest.execute();
				var result:SQLResult = getRequest.getResult();
				conn.close();
				if (result.data != null) {
					var numResults:int = result.data.length;
					for (var i:int = 0; i < numResults; i++) 
					{ 
						returnValue.addItem(
							new Calibration(
								result.data[i].timestamp,
								result.data[i].sensorAgeAtTimeOfEstimation,
								((result.data[i].sensorid) as String) == "-" ? null:getSensor(result.data[i].sensorid),
								result.data[i].bg,
								result.data[i].rawValue,
								result.data[i].adjustedRawValue,
								result.data[i].sensorConfidence,
								result.data[i].slopeConfidence,
								result.data[i].rawTimestamp,
								result.data[i].slope,
								result.data[i].intercept,
								result.data[i].distanceFromEstimate,
								result.data[i].estimateRawAtTimeOfCalibration,
								result.data[i].estimateBgAtTimeOfCalibration,
								result.data[i].possibleBad == "1" ? true:false,
								result.data[i].checkIn == "1" ? true:false,
								result.data[i].firstDecay,
								result.data[i].secondDecay,
								result.data[i].firstSlope,
								result.data[i].secondSlope,
								result.data[i].firstIntercept,
								result.data[i].secondIntercept,
								result.data[i].firstScale,
								result.data[i].secondScale,
								result.data[i].lastmodifiedtimestamp,
								result.data[i].calibrationid)
						);
					}
					var dataSortFieldForReturnValue:SortField = new SortField();
					dataSortFieldForReturnValue.name = "timestamp";
					dataSortFieldForReturnValue.numeric = true;
					dataSortFieldForReturnValue.descending = true;//ie from large to small
					var dataSortForBGReadings:Sort = new Sort();
					dataSortForBGReadings.fields=[dataSortFieldForReturnValue];
					returnValue.sort = dataSortForBGReadings;
					returnValue.refresh();
				}
			} catch (error:SQLError) {
				if (conn.connected) conn.close();
				dispatchInformation('error_while_getting_for_sensor_in_lastxdays_in_db', error.message + " - " + error.details);
			} catch (other:Error) {
				if (conn.connected) conn.close();
				dispatchInformation('error_while_getting_for_sensor_in_lastxdays_in_db',other.getStackTrace().toString());
			} finally {
				if (conn.connected) conn.close();
				return returnValue;
			}
		}
		
		/**
		 * get first or last calibration for specified sensorid<br>
		 * if first = true then it will return the first, otherwise the last<br>
		 * returns null if there's none
		 * synchronous<br>
		 */
		public static function getLastOrFirstCalibration(sensorid:String, first:Boolean):Calibration {
			var returnValue:Calibration = null;
			try {
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.READ);
				conn.begin();
				var getRequest:SQLStatement = new SQLStatement();
				getRequest.sqlConnection = conn;
				getRequest.text = "SELECT * FROM calibration WHERE sensorid = '" + sensorid + "'";
				getRequest.execute();
				conn.close();
				var result:SQLResult = getRequest.getResult();
				if (result.data != null) {
					if (result.data != null) {
						var calibrations:Array = [];
						var numResults:int = result.data.length;
						for (var i:int = 0; i < numResults; i++) 
						{ 
							calibrations.push(
								new Calibration(
									result.data[i].timestamp,
									result.data[i].sensorAgeAtTimeOfEstimation,
									((result.data[i].sensorid) as String) == "-" ? null:getSensor(result.data[i].sensorid),
									result.data[i].bg,
									result.data[i].rawValue,
									result.data[i].adjustedRawValue,
									result.data[i].sensorConfidence,
									result.data[i].slopeConfidence,
									result.data[i].rawTimestamp,
									result.data[i].slope,
									result.data[i].intercept,
									result.data[i].distanceFromEstimate,
									result.data[i].estimateRawAtTimeOfCalibration,
									result.data[i].estimateBgAtTimeOfCalibration,
									result.data[i].possibleBad == "1" ? true:false,
									result.data[i].checkIn == "1" ? true:false,
									result.data[i].firstDecay,
									result.data[i].secondDecay,
									result.data[i].firstSlope,
									result.data[i].secondSlope,
									result.data[i].firstIntercept,
									result.data[i].secondIntercept,
									result.data[i].firstScale,
									result.data[i].secondScale,
									result.data[i].lastmodifiedtimestamp,
									result.data[i].calibrationid)
							);
						} 
						
						if (!first)
							calibrations.sortOn(["timestamp"], Array.DESCENDING);
						else
							calibrations.sortOn(["timestamp"]);
						
						if (calibrations.length > 0)
							returnValue = calibrations[0] as Calibration;
					}
				}
			} catch (error:SQLError) {
				if (conn.connected) conn.close();
				dispatchInformation('error_while_getting_last_or_first_calibration_in_db', error.message + " - " + error.details);
			} catch (other:Error) {
				if (conn.connected) conn.close();
				dispatchInformation('error_while_getting_last_or_first_calibration_in_db',other.getStackTrace().toString());
			} finally {
				if (conn.connected) conn.close();
				return returnValue;
			}
		}
		
		/**
		 * inserts a calibration in the database<br>
		 * dispatches info if anything goes wrong 
		 */
		public static function insertCalibrationSynchronous(calibration:Calibration):void {
			var insertText:String = ""
			try {
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.UPDATE);
				conn.begin();
				var insertRequest:SQLStatement = new SQLStatement();
				insertRequest.sqlConnection = conn;
				insertRequest.text = "INSERT INTO calibration (" +
					"calibrationid, " +
					"lastmodifiedtimestamp, " +
					"timestamp," +
					"sensorAgeAtTimeOfEstimation," +
					"sensorid," +
					"bg," +
					"rawValue," +
					"adjustedRawValue," +
					"sensorConfidence," +
					"slopeConfidence," +
					"rawTimestamp," +
					"slope," +
					"intercept," +
					"distanceFromEstimate," +
					"estimateRawAtTimeOfCalibration," +
					"estimateBgAtTimeOfCalibration," +
					"possibleBad," +
					"checkIn," +
					"firstDecay," +
					"secondDecay," +
					"firstSlope," +
					"secondSlope," +
					"firstIntercept," +
					"secondIntercept," +
					"firstScale," +
					"secondScale)" +
					"VALUES ('" + calibration.uniqueId + "', " +
					calibration.lastModifiedTimestamp + ", " +
					calibration.timestamp + ", " +
					calibration.sensorAgeAtTimeOfEstimation + ", " +
					"'" + (calibration.sensor == null ? "-" : calibration.sensor.uniqueId) + "', " + 
					calibration.bg +", " + 
					calibration.rawValue +", " + 
					calibration.adjustedRawValue +", " + 
					calibration.sensorConfidence  +", " + 
					calibration.slopeConfidence +", " +
					calibration.rawTimestamp +", " +
					calibration.slope +", " +
					calibration.intercept +", " +
					calibration.distanceFromEstimate +", " +
					calibration.estimateRawAtTimeOfCalibration +", " +
					calibration.estimateBgAtTimeOfCalibration +", " +
					(calibration.possibleBad ? "1":"0") +", " +
					(calibration.checkIn ? "1":"0") +", " +
					calibration.firstDecay +", " +
					calibration.secondDecay +", " +
					calibration.firstSlope +", " +
					calibration.secondSlope +", " +
					calibration.firstIntercept +", " +
					calibration.secondIntercept +", " +
					calibration.firstScale +", " +
					calibration.secondScale + ")";
				insertText = insertRequest.text;
				insertRequest.execute();
				conn.commit();
				conn.close();
				myTrace("in insertCalibrationSynchronous, insert committed");
			} catch (error:SQLError) {
				if (conn.connected) {
					conn.rollback();
					conn.close();
				}
				dispatchInformation('error_while_inserting_calibration_in_db', error.message + " - " + error.details + " updaterequest text = " + insertText);
			}
		}
		
		/**
		 * deletes a calibration in the database<br>
		 * dispatches info if anything goes wrong <br>
		 */
		public static function deleteCalibrationSynchronous(calibration:Calibration):void {
			try {
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.UPDATE);
				conn.begin();
				var deleteRequest:SQLStatement = new SQLStatement();
				deleteRequest.sqlConnection = conn;
				deleteRequest.text = "DELETE from calibration where calibrationid = " + "'" + calibration.uniqueId + "'";
				deleteRequest.execute();
				conn.commit();
				conn.close();
			} catch (error:SQLError) {
				if (conn.connected) {
					conn.rollback();
					conn.close();
				}
				dispatchInformation('error_while_deleting_calibration_in_db', error.message + " - " + error.details);
			}
		}
		
		/**
		 * updates a calibration in the database<br>
		 * dispatches info if anything goes wrong 
		 */
		public static function updateCalibrationSynchronous(calibration:Calibration):void {
			try {
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.UPDATE);
				conn.begin();
				var updateRequest:SQLStatement = new SQLStatement();
				updateRequest.sqlConnection = conn;
				updateRequest.text = "UPDATE calibration SET " +
					"lastmodifiedtimestamp = " + calibration.lastModifiedTimestamp + ", " + 
					"timestamp = " + calibration.timestamp + ", " + 
					"sensorAgeAtTimeOfEstimation = " + calibration.sensorAgeAtTimeOfEstimation + ", " + 
					"sensorid = '" + (calibration.sensor == null ? "-" : calibration.sensor.uniqueId) + "', " +
					"bg = " +  calibration.bg + ", " +
					"rawValue = " +  calibration.rawValue + ", " +
					"adjustedRawValue = " +  calibration.adjustedRawValue + ", " +
					"sensorConfidence = " +  calibration.sensorConfidence + ", " +
					"slopeConfidence = " +  calibration.slopeConfidence + ", " +
					"rawTimestamp = " +  calibration.rawTimestamp + ", " +
					"slope = " +  calibration.slope + ", " +
					"intercept = " +  calibration.intercept + ", " +
					"distanceFromEstimate = " +  calibration.distanceFromEstimate + ", " +
					"estimateRawAtTimeOfCalibration = " +  calibration.estimateRawAtTimeOfCalibration + ", " +
					"estimateBgAtTimeOfCalibration = " +  calibration.estimateBgAtTimeOfCalibration + ", " +
					"possibleBad = " +  (calibration.possibleBad? "1":"0") + ", " +
					"checkIn = " + (calibration.checkIn? "1":"0") + ", " +
					"firstDecay = " +  calibration.firstDecay + ", " +
					"secondDecay = " +  calibration.secondDecay + ", " +
					"firstSlope = " +  calibration.firstSlope + ", " +
					"secondSlope = " +  calibration.secondSlope + ", " +
					"firstIntercept = " + calibration. firstIntercept + ", " +
					"secondIntercept = " +  calibration.secondIntercept + ", " +
					"firstScale = " +  calibration.firstScale + ", " +
					"secondScale = " +  calibration.secondScale + " " +
					"WHERE calibrationid = " + "'" + calibration.uniqueId + "'";
				updateRequest.execute();
				conn.commit();
				conn.close();
			} catch (error:SQLError) {
				if (conn.connected) {
					conn.rollback();
					conn.close();
				}
				dispatchInformation('error_while_updating_calibration_in_db', error.message + " - " + error.details);
			}
		}
		
		/**
		 * get calibration for specified uniqueId<br>
		 * synchronous
		 */
		public static function getCalibration(uniqueId:String):Calibration {
			var returnValue:Calibration = null;
			try {
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.READ);
				conn.begin();
				var getRequest:SQLStatement = new SQLStatement();
				getRequest.sqlConnection = conn;
				getRequest.text = "SELECT * FROM calibration WHERE calibrationid = '" + uniqueId + "'";
				getRequest.execute();
				var result:SQLResult = getRequest.getResult();
				conn.close();
				if (result.data != null) {
					var numResults:int = result.data.length;
					if (numResults == 1) {
						returnValue = new Calibration(
							result.data[0].timestamp,
							result.data[0].sensorAgeAtTimeOfEstimation,
							((result.data[0].sensorid) as String) == "-" ? null:getSensor(result.data[0].sensorid),
							result.data[0].bg,
							result.data[0].rawValue,
							result.data[0].adjustedRawValue,
							result.data[0].sensorConfidence,
							result.data[0].slopeConfidence,
							result.data[0].rawTimestamp,
							result.data[0].slope,
							result.data[0].intercept,
							result.data[0].distanceFromEstimate,
							result.data[0].estimateRawAtTimeOfCalibration,
							result.data[0].estimateBgAtTimeOfCalibration,
							result.data[0].possibleBad == "1" ? true:false,
							result.data[0].checkIn == "1" ? true:false,
							result.data[0].firstDecay,
							result.data[0].secondDecay,
							result.data[0].firstSlope,
							result.data[0].secondSlope,
							result.data[0].firstIntercept,
							result.data[0].secondIntercept,
							result.data[0].firstScale,
							result.data[0].secondScale,
							result.data[0].lastmodifiedtimestamp,
							result.data[0].calibrationid
						)
					} else {
						dispatchInformation('error_while_getting_calibration_in_db','resulting amount of calibrations should be 1 but is ' + numResults);
					}
				}
			} catch (error:SQLError) {
				if (conn.connected) conn.close();
				dispatchInformation('error_while_getting_calibration_in_db', error.message + " - " + error.details);
			} catch (other:Error) {
				if (conn.connected) conn.close();
				dispatchInformation('error_while_getting_calibration_in_db', other.getStackTrace().toString());
			} finally {
				if (conn.connected) conn.close();
				return returnValue;
			}
		}
		
		/**
		 * get calibration for specified sensorId<br>
		 * if there's no calibration for the specified sensorId then the returnvalue is an empty array<br>
		 * the calibrations will be order in descending order by timestamp<br>
		 * synchronous
		 */
		public static function getCalibrationForSensorId(sensorId:String):Array
		{
			var returnValue:Array = [];
			
			try {
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.READ);
				conn.begin();
				var getRequest:SQLStatement = new SQLStatement();
				getRequest.sqlConnection = conn;
				getRequest.text = "SELECT * FROM calibration WHERE sensorid = '" + sensorId + "'";
				getRequest.execute();
				var result:SQLResult = getRequest.getResult();
				conn.close();
				if (result.data != null) {
					
					var numResults:int = result.data.length;
					for (var i:int = 0; i < numResults; i++) 
					{ 
						returnValue.push(new Calibration(
							result.data[i].timestamp,
							result.data[i].sensorAgeAtTimeOfEstimation,
							((result.data[i].sensorid) as String) == "-" ? null:getSensor(result.data[i].sensorid),
							result.data[i].bg,
							result.data[i].rawValue,
							result.data[i].adjustedRawValue,
							result.data[i].sensorConfidence,
							result.data[i].slopeConfidence,
							result.data[i].rawTimestamp,
							result.data[i].slope,
							result.data[i].intercept,
							result.data[i].distanceFromEstimate,
							result.data[i].estimateRawAtTimeOfCalibration,
							result.data[i].estimateBgAtTimeOfCalibration,
							result.data[i].possibleBad == "1" ? true:false,
							result.data[i].checkIn == "1" ? true:false,
							result.data[i].firstDecay,
							result.data[i].secondDecay,
							result.data[i].firstSlope,
							result.data[i].secondSlope,
							result.data[i].firstIntercept,
							result.data[i].secondIntercept,
							result.data[i].firstScale,
							result.data[i].secondScale,
							result.data[i].lastmodifiedtimestamp,
							result.data[i].calibrationid
						));
					} 
					
					returnValue.sortOn(["timestamp"], Array.NUMERIC);
					
				}
			} catch (error:SQLError) {
				if (conn.connected) conn.close();
				dispatchInformation('error_while_getting_calibration_in_db', error.message + " - " + error.details);
			} catch (other:Error) {
				if (conn.connected) conn.close();
				dispatchInformation('error_while_getting_calibration_in_db', other.getStackTrace().toString());
			} finally {
				if (conn.connected) conn.close();
				return returnValue;
			}
		}
		
		/**
		 * inserts a sensor in the database<br>
		 * dispatches info if anything goes wrong 
		 */
		public static function insertSensor(sensor:Sensor):void {
			try {
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.UPDATE);
				conn.begin();
				var insertRequest:SQLStatement = new SQLStatement();
				insertRequest.sqlConnection = conn;
				insertRequest.text = "INSERT INTO sensor (" +
					"sensorid, " +
					"lastmodifiedtimestamp, " +
					"startedat," +
					"stoppedat," +
					"latestbatterylevel" +
					")" +
					"VALUES ('" + sensor.uniqueId + "', " +
					sensor.lastModifiedTimestamp + ", " +
					sensor.startedAt + ", " +
					sensor.stoppedAt + ", " +
					sensor.latestBatteryLevel + 
					")";
				insertRequest.execute();
				conn.commit();
				conn.close();
			} catch (error:SQLError) {
				if (conn.connected) {
					conn.rollback();
					conn.close();
				}
				dispatchInformation('error_while_inserting_sensor_in_db', error.message + " - " + error.details);
			}
		}
		
		/**
		 * deletes a sensor in the database<br>
		 * dispatches info if anything goes wrong 
		 */
		public static function deleteSensor(sensor:Sensor):void {
			try {
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.UPDATE);
				conn.begin();
				var deleteRequest:SQLStatement = new SQLStatement();
				deleteRequest.sqlConnection = conn;
				deleteRequest.text = "DELETE from sensor where sensorid = " + "'" + sensor.uniqueId + "'";
				deleteRequest.execute();
				conn.commit();
				conn.close();
			} catch (error:SQLError) {
				if (conn.connected) {
					conn.rollback();
					conn.close();
				}
				dispatchInformation('error_while_deleting_sensor_in_db', error.message + " - " + error.details);
			}
		}
		
		/**
		 * updates a sensor in the database<br>
		 * dispatches info if anything goes wrong 
		 */
		public static function updateSensor(sensor:Sensor):void {
			try {
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.UPDATE);
				conn.begin();
				var updateRequest:SQLStatement = new SQLStatement();
				updateRequest.sqlConnection = conn;
				var text:String = "UPDATE sensor SET ";
				text += "lastmodifiedtimestamp = " + sensor.lastModifiedTimestamp + ", "; 
				text += 					"startedat = " + sensor.startedAt + ", "; 
				text += "stoppedat = " + sensor.stoppedAt + ", ";
				text += "latestbatterylevel = " + sensor.latestBatteryLevel + " ";
				text += "WHERE sensorid = " + "'" + sensor.uniqueId + "'";
				updateRequest.text = text;
				updateRequest.execute();
				conn.commit();
				conn.close();
			} catch (error:SQLError) {
				if (conn.connected) {
					conn.rollback();
					conn.close();
				}
				dispatchInformation('error_while_updating_sensor_in_db', error.message + " - " + error.details);
			}
		}
		
		/**
		 * get sensor for specified uniqueId<br>
		 * null if none found<br>
		 * synchronous
		 */
		public static function getSensor(uniqueId:String):Sensor {
			var returnValue:Sensor = null;
			try {
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.READ);
				conn.begin();
				var getRequest:SQLStatement = new SQLStatement();
				getRequest.sqlConnection = conn;
				getRequest.text = "SELECT * FROM sensor WHERE sensorid = '" + uniqueId + "'";
				while (aConn.inTransaction){};
				getRequest.execute();
				var result:SQLResult = getRequest.getResult();
				conn.close();
				if (result.data != null) {
					var numResults:int = result.data.length;
					if (numResults == 1) {
						returnValue = new Sensor(
							result.data[0].startedat,
							result.data[0].stoppedat,
							result.data[0].latestbatterylevel,
							result.data[0].sensorid,
							result.data[0].lastmodifiedtimestamp
						)
					} else {
						dispatchInformation('error_while_getting_sensor_in_db','resulting amount of sensors should be 1 but is ' + numResults);
					}
				}
			} catch (error:SQLError) {
				if (conn.connected) conn.close();
				dispatchInformation('error_while_getting_sensor_in_db', error.message + " - " + error.details);
			} catch (other:Error) {
				if (conn.connected) conn.close();
				dispatchInformation('error_while_getting_sensor_in_db', other.getStackTrace().toString());
			} finally {
				if (conn.connected) conn.close();
				return returnValue;
			}
		}
		
		/**
		 * inserts a bgreading in the database<br>
		 * synchronous<br>
		 * dispatches info if anything goes wrong 
		 */
		public static function insertBgReadingSynchronous(bgreading:BgReading):void {
			try {
				var calibration:Calibration = bgreading.calibration;
				var calibrationIdAsString:String = calibration == null ? "-":bgreading.calibration.uniqueId;
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.UPDATE);
				conn.begin();
				var insertRequest:SQLStatement = new SQLStatement();
				insertRequest.sqlConnection = conn;
				var text:String = "INSERT INTO bgreading (";
				text += "bgreadingid, ";
				text += "lastmodifiedtimestamp, ";
				text += "timestamp,";
				text += "sensorid,";
				text += "calibrationid,";
				text += "rawData,";
				text += "filteredData,";
				text += "ageAdjustedRawValue,";
				text += "calibrationFlag,";
				text += "calculatedValue,";
				text += "filteredCalculatedValue,";
				text += "calculatedValueSlope,";
				text += "a,";
				text += "b,";
				text += "c,";
				text += "ra,";
				text += "rb,";
				text += "rc,";
				text += "rawCalculated,";
				text += "hideSlope,";
				text += "noise) ";
				text += "VALUES ('" + bgreading.uniqueId + "', ";
				text += bgreading.lastModifiedTimestamp + ", ";
				text += bgreading.timestamp + ", ";
				text += "'" + (bgreading.sensor != null ? bgreading.sensor.uniqueId:"") +"',"; 
				text += "'" + calibrationIdAsString + "', ";
				text += bgreading.rawData + ", "; 
				text += bgreading.filteredData + ", "; 
				text += bgreading.ageAdjustedRawValue + ", "; 
				text += (bgreading.calibrationFlag ? "1":"0") + ", ";
				text += bgreading.calculatedValue + ", ";
				text += bgreading.filteredCalculatedValue + ", ";
				text += bgreading.calculatedValueSlope + ", ";
				text += bgreading.a + ", ";
				text += bgreading.b + ", ";
				text += bgreading.c + ", ";
				text += bgreading.ra + ", ";
				text += bgreading.rb + ", ";
				text += bgreading.rc + ", ";
				text += bgreading.rawCalculated + ", ";
				text += (bgreading.hideSlope ? "1":"0") + ", ";
				text += "'" + (bgreading.noise == null ? "-":bgreading.noise) + "'" + ")";
				insertRequest.text = text;
				insertRequest.execute();
				conn.commit();
				conn.close();
			} catch (error:SQLError) {
				if (conn.connected) {
					conn.rollback();
					conn.close();
				}
				dispatchInformation('error_while_inserting_bgreading_in_db', error.message + " - " + error.details);
			}
		}
		
		/**
		 * deletes a bgreading in the database<br>
		 * dispatches info if anything goes wrong 
		 */
		public static function deleteBgReadingSynchronous(bgreading:BgReading):void {
			try {
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.UPDATE);
				conn.begin();
				var deleteRequest:SQLStatement = new SQLStatement();
				deleteRequest.sqlConnection = conn;
				deleteRequest.text = "DELETE from bgreading where bgreadingid = " + "'" + bgreading.uniqueId + "'";
				deleteRequest.execute();
				conn.commit();
				conn.close();
			} catch (error:SQLError) {
				if (conn.connected) {
					conn.rollback();
					conn.close();
				}
				dispatchInformation('error_while_deleting_bgreading_in_db', error.message + " - " + error.details);
			}
		}
		
		/**
		 * updates a calibration in the database<br>
		 * dispatches info if anything goes wrong<br>
		 * synchronous
		 */
		public static function updateBgReadingSynchronous(bgreading:BgReading):void {
			var text:String = "";
			try {
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.UPDATE);
				conn.begin();
				var updateRequest:SQLStatement = new SQLStatement();
				updateRequest.sqlConnection = conn;
				text = "UPDATE bgreading SET ";
				text += "lastmodifiedtimestamp = " + bgreading.lastModifiedTimestamp + ",  "; 
				text += "timestamp = " + bgreading.timestamp + ",  "; 
				text += "sensorid = '" +  bgreading.sensor.uniqueId + "', ";
				text += "calibrationid = " +  (bgreading.calibration == null ? "'-'":("'" + bgreading.calibration.uniqueId + "'")) + ",  ";
				text += "rawData = " +  bgreading.rawData + ",  ";
				text += "filteredData = " +  bgreading.filteredData + ",  ";
				text += "ageAdjustedRawValue = " +  bgreading.ageAdjustedRawValue + ",  ";
				text += "calibrationFlag = " +  (bgreading.calibrationFlag ? "1":"0") + ",  ";
				text += "calculatedValue = " +  bgreading.calculatedValue + ",  ";
				text += "filteredCalculatedValue = " +  bgreading.filteredCalculatedValue + ",  ";
				text += "calculatedValueSlope = " +  bgreading.calculatedValueSlope + ",  ";
				text += "a = " +  bgreading.a + ",  ";
				text += "b = " +  bgreading.b + ",  ";
				text += "c = " +  bgreading.c + ",  ";
				text += "ra = " +  bgreading.ra + ",  ";
				text += "rb = " + bgreading.rb + ",  ";
				text += "rc = " +  bgreading.rc + ",  ";
				text += "rawCalculated = " +  bgreading.rawCalculated + ",  ";
				text += "hideSlope = " +  (bgreading.hideSlope ? "1":"0") + ",  ";
				text += "noise = " +  "'" + (bgreading.noise == null ? "-":bgreading.noise) + "' "; 
				text += "WHERE bgreadingid = " + "'" + bgreading.uniqueId + "' " ;
				updateRequest.text = text;
				updateRequest.execute();
				conn.commit();
				conn.close();
			} catch (error:SQLError) {
				if (conn.connected) {
					conn.rollback();
					conn.close();
				}
				dispatchInformation('error_while_updating_bgreading_in_db', error.message + " - " + error.details + " updaterequest text = " + text);
			}
		}
		
		/**
		 * will get the bgreadings and dispatch them one by one (ie one event per bgreading) in the data field of a BGREADING_RETRIEVAL_EVENT<br>
		 * If the last string is sent, an additional event is set with data = "END_OF_RESULT"<br>
		 * <br>
		 * until = readings with timestamp >= until will not be returned. until is timestamp in ms<br>
		 * asynchronous
		 */
		public static function getBgReadings(from:Number, until:Number):void {
			var localSqlStatement:SQLStatement = new SQLStatement();
			var localdispatcher:EventDispatcher = new EventDispatcher();
			
			localdispatcher.addEventListener(SQLEvent.RESULT,onOpenResult);
			localdispatcher.addEventListener(SQLErrorEvent.ERROR,onOpenError);
			
			if (openSQLConnection(localdispatcher))
				onOpenResult(null);
			
			function onOpenResult(se:SQLEvent):void {
				localdispatcher.removeEventListener(SQLEvent.RESULT,onOpenResult);
				localdispatcher.removeEventListener(SQLErrorEvent.ERROR,onOpenError);
				localSqlStatement.addEventListener(SQLEvent.RESULT,bgReadingsRetrieved);
				localSqlStatement.addEventListener(SQLErrorEvent.ERROR,bgreadingRetrievalFailed);
				localSqlStatement.sqlConnection = aConn;
				localSqlStatement.text =  "SELECT * FROM bgreading WHERE timestamp BETWEEN " + from + " AND " + until + " ORDER BY timestamp ASC";
				localSqlStatement.execute();
			}
			
			function bgReadingsRetrieved(se:SQLEvent):void 
			{
				localSqlStatement.removeEventListener(SQLEvent.RESULT,bgReadingsRetrieved);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,bgreadingRetrievalFailed);
				
				var readingsList:Array = [];
				var tempObject:Object = localSqlStatement.getResult().data;
				
				if (tempObject != null) 
				{
					if (tempObject is Array) 
					{
						for each ( var o:Object in tempObject) 
						{
							var reading:BgReading = new BgReading
							(
								o.timestamp,
								(o.sensorid as String) == "-" ? null:getSensor(o.sensorid),
								(o.calibrationid as String) == "-" ? null:getCalibration(o.calibrationid),
								o.rawData,
								o.filteredData,
								o.ageAdjustedRawValue,
								o.calibrationFlag == "1" ? true:false,
								o.calculatedValue,
								o.filteredCalculatedValue,
								o.calculatedValueSlope,
								o.a,
								o.b,
								o.c,
								o.ra,
								o.rb,
								o.rc,
								o.rawCalculated,
								o.hideSlope == "1" ? true:false,
								(o.noise as String) == "-" ? null:o.noise,
								o.lastmodifiedtimestamp,
								o.bgreadingid
							);
							
							readingsList.push(reading);
						}
					}
				} 
				
				instance.dispatchEvent(new DatabaseEvent(DatabaseEvent.BGREADING_RETRIEVAL_EVENT, false, false, readingsList));
			}
			
			function bgreadingRetrievalFailed(see:SQLErrorEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,bgReadingsRetrieved);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,bgreadingRetrievalFailed);
				dispatchInformation("failed_to_retrieve_bg_reading", see.error.message + " - " + see.error.details);
				if (debugMode) trace("Database.as : Failed to retrieve bgreadings. Database 0032");
				var errorEvent:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
				errorEvent.data = "Failed to retrieve bgreadings . Database:0032";
				instance.dispatchEvent(errorEvent);
				
			}
			
			function onOpenError(see:SQLErrorEvent):void {
				localdispatcher.removeEventListener(SQLEvent.RESULT,onOpenResult);
				localdispatcher.removeEventListener(SQLErrorEvent.ERROR,onOpenError);
				dispatchInformation("failed_to_retrieve_bg_reading_error_opening_database", see.error.message + " - " + see.error.details);
				if (debugMode) trace("Database.as : Failed to open the database. Database 0033");
				var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
				instance.dispatchEvent(event);
				
			}
		}
		
		/**
		 * Gets glucose readings from database without further processing. Returns them in raw format (Object).
		 * The columns parameter represents the columns that should be included in the query. This is done to avoid eturning columns that are not needed for Spike when processing the data.
		 */
		public static function getBgReadingsData(from:Number, until:Number, columns:String):void {
			var localSqlStatement:SQLStatement = new SQLStatement();
			var localdispatcher:EventDispatcher = new EventDispatcher();
			
			localdispatcher.addEventListener(SQLEvent.RESULT,onOpenResult);
			localdispatcher.addEventListener(SQLErrorEvent.ERROR,onOpenError);
			
			if (openSQLConnection(localdispatcher))
				onOpenResult(null);
			
			function onOpenResult(se:SQLEvent):void {
				localdispatcher.removeEventListener(SQLEvent.RESULT,onOpenResult);
				localdispatcher.removeEventListener(SQLErrorEvent.ERROR,onOpenError);
				localSqlStatement.addEventListener(SQLEvent.RESULT,bgReadingsRetrieved);
				localSqlStatement.addEventListener(SQLErrorEvent.ERROR,bgreadingRetrievalFailed);
				localSqlStatement.sqlConnection = aConn;
				localSqlStatement.text =  "SELECT " + columns + " FROM bgreading WHERE timestamp BETWEEN " + from + " AND " + until + " ORDER BY timestamp ASC";
				localSqlStatement.execute();
			}
			
			function bgReadingsRetrieved(se:SQLEvent):void 
			{
				localSqlStatement.removeEventListener(SQLEvent.RESULT,bgReadingsRetrieved);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,bgreadingRetrievalFailed);
				
				instance.dispatchEvent(new DatabaseEvent(DatabaseEvent.BGREADING_RETRIEVAL_EVENT, false, false, localSqlStatement.getResult().data));
				
				localSqlStatement = null;
			}
			
			function bgreadingRetrievalFailed(see:SQLErrorEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,bgReadingsRetrieved);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,bgreadingRetrievalFailed);
				dispatchInformation("failed_to_retrieve_bg_reading", see.error.message + " - " + see.error.details);
				if (debugMode) trace("Database.as : Failed to retrieve bgreadings. Database 0032");
				var errorEvent:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
				errorEvent.data = "Failed to retrieve bgreadings . Database:0032";
				instance.dispatchEvent(errorEvent);
				
			}
			
			function onOpenError(see:SQLErrorEvent):void {
				localdispatcher.removeEventListener(SQLEvent.RESULT,onOpenResult);
				localdispatcher.removeEventListener(SQLErrorEvent.ERROR,onOpenError);
				dispatchInformation("failed_to_retrieve_bg_reading_error_opening_database", see.error.message + " - " + see.error.details);
				if (debugMode) trace("Database.as : Failed to open the database. Database 0033");
				var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
				instance.dispatchEvent(event);
				
			}
		}
		
		/**
		 * Get readings for Spike's internal server synchronously
		 * From: Starting timestamp.
		 * Until: Ending timestamp.
		 * Columns: Data columns to be retrieved from database.
		 * MaxCount: Maximum of records returned from database (if applicable). 1 means all.
		 */
		public static function getBgReadingsDataSynchronous(from:Number, until:Number, columns:String, maxCount:int = 1):Array {
			var returnValue:Array = new Array();
			try {
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.READ);
				conn.begin();
				var getRequest:SQLStatement = new SQLStatement();
				getRequest.sqlConnection = conn;
				if (maxCount == 1)
					getRequest.text =  "SELECT " + columns + " FROM bgreading WHERE timestamp BETWEEN " + from + " AND " + until + " ORDER BY timestamp DESC";
				else
					getRequest.text =  "SELECT " + columns + " FROM bgreading WHERE timestamp BETWEEN " + from + " AND " + until +  " ORDER BY timestamp ASC LIMIT " + maxCount;
				getRequest.execute();
				var result:SQLResult = getRequest.getResult();
				conn.close();
				if (result.data != null)
					returnValue = result.data;
			} catch (error:SQLError) {
				if (conn.connected) conn.close();
				dispatchInformation('error_while_getting_bgreadings_for_spike_server', error.message + " - " + error.details);
			} catch (other:Error) {
				if (conn.connected) conn.close();
				dispatchInformation('error_while_getting_bgreadings_for_spike_server',other.getStackTrace().toString());
			} finally {
				if (conn.connected) conn.close();
				return returnValue;
			}
		}
		
		/**
		 * Get treatments synchronously. Basals NOT included.
		 * From: Starting timestamp.
		 * Until: Ending timestamp.
		 * Columns: Data columns to be retrieved from database.
		 * MaxCount: Maximum of records returned from database (if applicable). 1 means all.
		 */
		public static function getTreatmentsSynchronous(from:Number, until:Number, columns:String = "*", maxCount:int = 1):Array {
			var returnValue:Array = new Array();
			try {
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.READ);
				conn.begin();
				var getRequest:SQLStatement = new SQLStatement();
				getRequest.sqlConnection = conn;
				if (maxCount == 1)
				{
					//getRequest.text =  "SELECT " + columns + " FROM treatments WHERE lastmodifiedtimestamp BETWEEN " + from + " AND " + until + " ORDER BY lastmodifiedtimestamp DESC";
					getRequest.text =  "SELECT " + columns + " FROM treatments WHERE (lastmodifiedtimestamp BETWEEN " + from + " AND " + until + ") AND (type != '" + Treatment.TYPE_MDI_BASAL + "' AND type != '" + Treatment.TYPE_TEMP_BASAL + "' AND type != '" + Treatment.TYPE_TEMP_BASAL_END + "') ORDER BY lastmodifiedtimestamp DESC";
				}
				else
				{
					//getRequest.text =  "SELECT " + columns + " FROM treatments WHERE lastmodifiedtimestamp BETWEEN " + from + " AND " + until +  " ORDER BY lastmodifiedtimestamp ASC LIMIT " + maxCount;
					getRequest.text =  "SELECT " + columns + " FROM treatments WHERE (lastmodifiedtimestamp BETWEEN " + from + " AND " + until +  ") AND (type != '" + Treatment.TYPE_MDI_BASAL + "' AND type != '" + Treatment.TYPE_TEMP_BASAL + "' AND type != '" + Treatment.TYPE_TEMP_BASAL_END + "') ORDER BY lastmodifiedtimestamp ASC LIMIT " + maxCount;
				}
				getRequest.execute();
				var result:SQLResult = getRequest.getResult();
				conn.close();
				if (result.data != null)
					returnValue = result.data;
			} catch (error:SQLError) {
				if (conn.connected) conn.close();
				dispatchInformation('error_while_getting_treatments', error.message + " - " + error.details);
			} catch (other:Error) {
				if (conn.connected) conn.close();
				dispatchInformation('error_while_getting_treatments',other.getStackTrace().toString());
			} finally {
				if (conn.connected) conn.close();
				return returnValue;
			}
		}
		
		/**
		 * Get basals synchronously. Treatments NOT included.
		 * From: Starting timestamp.
		 * Until: Ending timestamp.
		 * Columns: Data columns to be retrieved from database.
		 * MaxCount: Maximum of records returned from database (if applicable). 1 means all.
		 */
		public static function getBasalsSynchronous(from:Number, until:Number, columns:String = "*", maxCount:int = 1):Array {
			var returnValue:Array = new Array();
			try {
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.READ);
				conn.begin();
				var getRequest:SQLStatement = new SQLStatement();
				getRequest.sqlConnection = conn;
				if (maxCount == 1)
				{
					getRequest.text = "SELECT " + columns + " FROM treatments WHERE ((lastmodifiedtimestamp + (basalduration * 60 * 1000)) >= " + from + ") AND (lastmodifiedtimestamp <= " + until + ") AND (type == '" + Treatment.TYPE_MDI_BASAL + "' OR type == '" + Treatment.TYPE_TEMP_BASAL + "' OR type == '" + Treatment.TYPE_TEMP_BASAL_END + "') ORDER BY lastmodifiedtimestamp DESC";
				}
				else
				{
					getRequest.text = "SELECT " + columns + " FROM treatments WHERE ((lastmodifiedtimestamp + (basalduration * 60 * 1000)) >= " + from + ") AND (lastmodifiedtimestamp <= " + until + ") AND (type == '" + Treatment.TYPE_MDI_BASAL + "' OR type == '" + Treatment.TYPE_TEMP_BASAL + "' OR type == '" + Treatment.TYPE_TEMP_BASAL_END + "') ORDER BY lastmodifiedtimestamp ASC LIMIT " + maxCount;
				}
				getRequest.execute();
				var result:SQLResult = getRequest.getResult();
				conn.close();
				if (result.data != null)
					returnValue = result.data;
			} catch (error:SQLError) {
				if (conn.connected) conn.close();
				dispatchInformation('error_while_getting_treatments', error.message + " - " + error.details);
			} catch (other:Error) {
				if (conn.connected) conn.close();
				dispatchInformation('error_while_getting_treatments',other.getStackTrace().toString());
			} finally {
				if (conn.connected) conn.close();
				return returnValue;
			}
		}
		
		/**
		 * inserts a treatment in the database<br>
		 * synchronous<br>
		 * dispatches info if anything goes wrong 
		 */
		public static function insertTreatmentSynchronous(treatment:Treatment):void 
		{
			try 
			{
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.UPDATE);
				conn.begin();
				var insertRequest:SQLStatement = new SQLStatement();
				insertRequest.sqlConnection = conn;
				var text:String = "INSERT INTO treatments (";
				text += "id, ";
				text += "type, ";
				text += "insulinamount, ";
				text += "insulinid, ";
				text += "carbs, ";
				text += "glucose, ";
				text += "glucoseestimated, ";
				text += "note, ";
				text += "lastmodifiedtimestamp, ";
				text += "carbdelay, ";
				text += "basalduration, ";
				text += "children, ";
				text += "prebolus, ";
				text += "duration, ";
				text += "intensity, ";
				text += "isbasalabsolute, ";
				text += "isbasalrelative, ";
				text += "istempbasalend, ";
				text += "basalabsoluteamount, ";
				text += "basalpercentamount, ";
				text += "needsadjustment) ";
				text += "VALUES (";
				text += "'" + treatment.ID + "', ";
				text += "'" + treatment.type + "', ";
				text += treatment.insulinAmount + ", ";
				text += "'" + treatment.insulinID + "', ";
				text += treatment.carbs + ", ";
				text += treatment.glucose + ", ";
				text += treatment.glucoseEstimated + ", ";
				text += "'" + treatment.note + "', ";
				text += treatment.timestamp + ", ";
				text += treatment.carbDelayTime + ", ";
				text += treatment.basalDuration + ", ";
				text += "'" + treatment.extractChildren() + "', ";
				text += (!isNaN(treatment.preBolus) ? treatment.preBolus : "NULL") + ", ";
				text += (!isNaN(treatment.duration) ? treatment.duration : "NULL") + ", ";
				text += "'" + treatment.exerciseIntensity + "', ";
				text += "'" + String(treatment.isBasalAbsolute) + "', ";
				text += "'" + String(treatment.isBasalRelative) + "', ";
				text += "'" + String(treatment.isTempBasalEnd) + "', ";
				text += treatment.basalAbsoluteAmount + ", ";
				text += treatment.basalPercentAmount + ", ";
				text += "'" + String(treatment.needsAdjustment) + "')";
				
				insertRequest.text = text;
				insertRequest.execute();
				conn.commit();
				conn.close();
				
			} catch (error:SQLError) {
				if (conn.connected) {
					conn.rollback();
					conn.close();
				}
				dispatchInformation('error_while_inserting_treatment_in_db', error.message + " - " + error.details);
				trace("ERROR ADDING TREATMENT  TO DABATASE!!!!",  error.message + " - " + error.details);
			}
		}
		
		/**
		 * updates a treatment in the database<br>
		 * synchronous<br>
		 * dispatches info if anything goes wrong 
		 */
		public static function updateTreatmentSynchronous(treatment:Treatment):void 
		{
			try 
			{
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.UPDATE);
				conn.begin();
				var updateRequest:SQLStatement = new SQLStatement();
				updateRequest.sqlConnection = conn;
				updateRequest.text = "UPDATE treatments SET " +
				"id = '" + treatment.ID + "', " +
				"type = '" + treatment.type + "', " +
				"insulinamount = " + treatment.insulinAmount + ", " +
				"insulinid = '" + treatment.insulinID + "', " +
				"carbs = " + treatment.carbs + ", " +
				"glucose = " + treatment.glucose + ", " +
				"glucoseestimated = " + treatment.glucoseEstimated + ", " +
				"note = '" + treatment.note + "', " +
				"lastmodifiedtimestamp = " + treatment.timestamp + ", " +
				"carbdelay = " + treatment.carbDelayTime + ", " +
				"basalduration = " + treatment.basalDuration + ", " +
				"children = '" + treatment.extractChildren() + "', " +
				"prebolus = " + (!isNaN(treatment.preBolus) ? treatment.preBolus : "NULL") + ", " +
				"duration = " + (!isNaN(treatment.duration ) ? treatment.duration : "NULL") + ", " +
				"intensity = '" + treatment.exerciseIntensity + "', " +
				"isbasalabsolute = '" + String(treatment.isBasalAbsolute) + "', " +
				"isbasalrelative = '" + String(treatment.isBasalRelative) + "', " +
				"istempbasalend = '" + String(treatment.isTempBasalEnd) + "', " +
				"basalabsoluteamount = " + treatment.basalAbsoluteAmount + ", " +
				"basalpercentamount = " + treatment.basalPercentAmount + ", " +
				"needsadjustment = '" + String(treatment.needsAdjustment) + "' " +
				"WHERE id = '" + treatment.ID + "'";
				updateRequest.execute();
				conn.commit();
				conn.close();
			} catch (error:SQLError) {
				if (conn.connected) {
					conn.rollback();
					conn.close();
				}
				dispatchInformation('error_while_updating_treatment_in_db', error.message + " - " + error.details);
			}
		}
		
		/**
		 * deletes a treatment in the database<br>
		 * dispatches info if anything goes wrong 
		 */
		public static function deleteTreatmentSynchronous(treatment:Treatment):void {
			try {
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.UPDATE);
				conn.begin();
				var deleteRequest:SQLStatement = new SQLStatement();
				deleteRequest.sqlConnection = conn;
				deleteRequest.text = "DELETE from treatments where id = " + "'" + treatment.ID + "'";
				deleteRequest.execute();
				conn.commit();
				conn.close();
				
			} catch (error:SQLError) {
				if (conn.connected) {
					conn.rollback();
					conn.close();
				}
				dispatchInformation('error_while_deleting_treatment_in_db', error.message + " - " + error.details);
			}
		}
		
		/**
		 * Deletes treatments older than 3 months (not needed anymore)
		 */
		public static function deleteOldTreatments():void {
			try {
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.UPDATE);
				conn.begin();
				var deleteRequest:SQLStatement = new SQLStatement();
				deleteRequest.sqlConnection = conn;
				deleteRequest.text = "DELETE from treatments WHERE lastmodifiedtimestamp < " + (new Date().valueOf() - (95 * 24 * 60 * 60 * 1000));
				deleteRequest.execute();
				conn.commit();
				conn.close();
			} catch (error:SQLError) {
				if (conn.connected) {
					conn.rollback();
					conn.close();
				}
				dispatchInformation('error_while_deleting_old_treatments_in_db', error.message + " - " + error.details);
			}
		}
		
		/**
		 * Get Insulins synchronously
		 */
		public static function getInsulinsSynchronous():Array {
			var returnValue:Array = new Array();
			try {
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.READ);
				conn.begin();
				var getRequest:SQLStatement = new SQLStatement();
				getRequest.sqlConnection = conn;
				getRequest.text =  "SELECT * FROM insulins";
				getRequest.execute();
				var result:SQLResult = getRequest.getResult();
				conn.close();
				if (result.data != null)
					returnValue = result.data;
				
			} catch (error:SQLError) {
				if (conn.connected) conn.close();
				dispatchInformation('error_while_getting_insulins', error.message + " - " + error.details);
			} catch (other:Error) {
				if (conn.connected) conn.close();
				dispatchInformation('error_while_getting_insulins',other.getStackTrace().toString());
			} finally {
				if (conn.connected) conn.close();
				return returnValue;
			}
		}
		
		/**
		 * inserts an insulin in the database<br>
		 * synchronous<br>
		 * dispatches info if anything goes wrong 
		 */
		public static function insertInsulinSynchronous(insulin:Insulin):void 
		{
			try 
			{
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.UPDATE);
				conn.begin();
				var insertRequest:SQLStatement = new SQLStatement();
				insertRequest.sqlConnection = conn;
				var text:String = "INSERT INTO insulins (";
				text += "id, ";
				text += "name, ";
				text += "dia, ";
				text += "type, ";
				text += "curve, ";
				text += "peak, ";
				text += "isdefault, ";
				text += "ishidden, ";
				text += "lastmodifiedtimestamp) ";
				text += "VALUES (";
				text += "'" + insulin.ID + "', ";
				text += "'" + insulin.name + "', ";
				text += insulin.dia + ", ";
				text += "'" + insulin.type + "', ";
				text += "'" + insulin.curve + "', ";
				text += insulin.peak + ", ";
				text += "'" + insulin.isDefault + "', ";
				text += "'" + insulin.isHidden + "', ";
				text += insulin.timestamp + ")";
				
				insertRequest.text = text;
				insertRequest.execute();
				conn.commit();
				conn.close();
			} catch (error:SQLError) {
				if (conn.connected) {
					conn.rollback();
					conn.close();
				}
				dispatchInformation('error_while_inserting_insulin_in_db', error.message + " - " + error.details);
			}
		}
		
		/**
		 * updates an insulin in the database<br>
		 * synchronous<br>
		 * dispatches info if anything goes wrong 
		 */
		public static function updateInsulinSynchronous(insulin:Insulin):void 
		{
			try 
			{
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.UPDATE);
				conn.begin();
				var updateRequest:SQLStatement = new SQLStatement();
				updateRequest.sqlConnection = conn;
				updateRequest.text = "UPDATE insulins SET " +
					"id = '" + insulin.ID + "', " +
					"name = '" + insulin.name + "', " +
					"dia = " + insulin.dia + ", " +
					"type = '" + insulin.type + "', " +
					"curve = '" + insulin.curve + "', " +
					"peak = " + insulin.peak + ", " +
					"isdefault = '" + insulin.isDefault + "', " +
					"ishidden = '" + insulin.isHidden + "', " +
					"lastmodifiedtimestamp = " + insulin.timestamp + " " +
					"WHERE id = '" + insulin.ID + "'";
				updateRequest.execute();
				conn.commit();
				conn.close();
			} catch (error:SQLError) {
				if (conn.connected) {
					conn.rollback();
					conn.close();
				}
				dispatchInformation('error_while_updating_insulin_in_db', error.message + " - " + error.details);
			}
		}
		
		/**
		 * deletes an insulin in the database<br>
		 * dispatches info if anything goes wrong 
		 */
		public static function deleteInsulinSynchronous(insulin:Insulin):void {
			try {
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.UPDATE);
				conn.begin();
				var deleteRequest:SQLStatement = new SQLStatement();
				deleteRequest.sqlConnection = conn;
				deleteRequest.text = "DELETE from insulins WHERE id = " + "'" + insulin.ID + "'";
				deleteRequest.execute();
				conn.commit();
				conn.close();
			} catch (error:SQLError) {
				if (conn.connected) {
					conn.rollback();
					conn.close();
				}
				dispatchInformation('error_while_deleting_insulin_in_db', error.message + " - " + error.details);
			}
		}
		
		/**
		 * Get Profile synchronously
		 */
		public static function getProfilesSynchronous():Array {
			var returnValue:Array = new Array();
			try {
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.READ);
				conn.begin();
				var getRequest:SQLStatement = new SQLStatement();
				getRequest.sqlConnection = conn;
				getRequest.text =  "SELECT * FROM profiles";
				getRequest.execute();
				var result:SQLResult = getRequest.getResult();
				conn.close();
				if (result.data != null)
					returnValue = result.data;
				
			} catch (error:SQLError) {
				if (conn.connected) conn.close();
				dispatchInformation('error_while_getting_profiles', error.message + " - " + error.details);
			} catch (other:Error) {
				if (conn.connected) conn.close();
				dispatchInformation('error_while_getting_profiles',other.getStackTrace().toString());
			} finally {
				if (conn.connected) conn.close();
				return returnValue;
			}
		}
		
		/**
		 * inserts a profile in the database<br>
		 * synchronous<br>
		 * dispatches info if anything goes wrong 
		 */
		public static function insertProfileSynchronous(profile:Profile):void 
		{
			try 
			{
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.UPDATE);
				conn.begin();
				var insertRequest:SQLStatement = new SQLStatement();
				insertRequest.sqlConnection = conn;
				var text:String = "INSERT INTO profiles (";
				text += "id, ";
				text += "time, ";
				text += "name, ";
				text += "insulintocarbratios, ";
				text += "insulinsensitivityfactors, ";
				text += "carbsabsorptionrate, ";
				text += "basalrates, ";
				text += "targetglucoserates, ";
				text += "trendcorrections, ";
				text += "lastmodifiedtimestamp) ";
				text += "VALUES (";
				text += "'" + profile.ID + "', ";
				text += "'" + profile.time + "', ";
				text += "'" + profile.name + "', ";
				text += "'" + profile.insulinToCarbRatios + "', ";
				text += "'" + profile.insulinSensitivityFactors + "', ";
				text += profile.carbsAbsorptionRate + ", ";
				text += "'" + profile.basalRates + "', ";
				text += "'" + profile.targetGlucoseRates + "', ";
				text += "'" + profile.trendCorrections + "', ";
				text += profile.timestamp + ")";
				
				insertRequest.text = text;
				insertRequest.execute();
				conn.commit();
				conn.close();
			} catch (error:SQLError) {
				if (conn.connected) {
					conn.rollback();
					conn.close();
				}
				dispatchInformation('error_while_inserting_profile_in_db', error.message + " - " + error.details);
			}
		}
		
		/**
		 * updates a profile in the database<br>
		 * synchronous<br>
		 * dispatches info if anything goes wrong 
		 */
		public static function updateProfileSynchronous(profile:Profile):void 
		{
			try 
			{
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.UPDATE);
				conn.begin();
				var updateRequest:SQLStatement = new SQLStatement();
				updateRequest.sqlConnection = conn;
				updateRequest.text = "UPDATE profiles SET " +
					"id = '" + profile.ID + "', " +
					"time = '" + profile.time + "', " +
					"name = '" + profile.name + "', " +
					"insulintocarbratios = '" + profile.insulinToCarbRatios + "', " +
					"insulinsensitivityfactors = '" + profile.insulinSensitivityFactors + "', " +
					"carbsabsorptionrate = " + profile.carbsAbsorptionRate + ", " +
					"basalrates = '" + profile.basalRates + "', " +
					"targetglucoserates = '" + profile.targetGlucoseRates + "', " +
					"trendcorrections = '" + profile.trendCorrections + "', " +
					"lastmodifiedtimestamp = " + profile.timestamp + " " +
					"WHERE id = '" + profile.ID + "'";
				updateRequest.execute();
				conn.commit();
				conn.close();
			} catch (error:SQLError) {
				if (conn.connected) {
					conn.rollback();
					conn.close();
				}
				dispatchInformation('error_while_updating_profilr_in_db', error.message + " - " + error.details);
			}
		}
		
		/**
		 * deletes a profile in the database<br>
		 * dispatches info if anything goes wrong 
		 */
		public static function deleteProfileSynchronous(profile:Profile):void {
			try {
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.UPDATE);
				conn.begin();
				var deleteRequest:SQLStatement = new SQLStatement();
				deleteRequest.sqlConnection = conn;
				deleteRequest.text = "DELETE from profiles WHERE id = " + "'" + profile.ID + "'";
				deleteRequest.execute();
				conn.commit();
				conn.close();
			} catch (error:SQLError) {
				if (conn.connected) {
					conn.rollback();
					conn.close();
				}
				dispatchInformation('error_while_deleting_profile_in_db', error.message + " - " + error.details);
			}
		}
		
		/**
		 * Get Basal Rates Synchronously
		 */
		public static function getBasalRatesSynchronous():Array {
			var returnValue:Array = new Array();
			try {
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.READ);
				conn.begin();
				var getRequest:SQLStatement = new SQLStatement();
				getRequest.sqlConnection = conn;
				getRequest.text =  "SELECT * FROM basalrates";
				getRequest.execute();
				var result:SQLResult = getRequest.getResult();
				conn.close();
				if (result.data != null)
					returnValue = result.data;
				
			} catch (error:SQLError) {
				if (conn.connected) conn.close();
				dispatchInformation('error_while_getting_basal_rates', error.message + " - " + error.details);
			} catch (other:Error) {
				if (conn.connected) conn.close();
				dispatchInformation('error_while_getting_basal_rates',other.getStackTrace().toString());
			} finally {
				if (conn.connected) conn.close();
				return returnValue;
			}
		}
		
		/**
		 * inserts a basal rate in the database<br>
		 * synchronous<br>
		 * dispatches info if anything goes wrong 
		 */
		public static function insertBasalRateSynchronous(basalRate:BasalRate):void 
		{
			try 
			{
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.UPDATE);
				conn.begin();
				var insertRequest:SQLStatement = new SQLStatement();
				insertRequest.sqlConnection = conn;
				var text:String = "INSERT INTO basalrates (";
				text += "id, ";
				text += "time, ";
				text += "hours, ";
				text += "minutes, ";
				text += "rate, ";
				text += "lastmodifiedtimestamp) ";
				text += "VALUES (";
				text += "'" + basalRate.ID + "', ";
				text += "'" + basalRate.startTime + "', ";
				text += basalRate.startHours + ", ";
				text += basalRate.startMinutes + ", ";
				text += basalRate.basalRate + ", ";
				text += basalRate.timestamp + ")";
				
				insertRequest.text = text;
				insertRequest.execute();
				conn.commit();
				conn.close();
			} catch (error:SQLError) {
				if (conn.connected) {
					conn.rollback();
					conn.close();
				}
				dispatchInformation('error_while_inserting_basal_rate_in_db', error.message + " - " + error.details);
			}
		}
		
		/**
		 * updates a basal rate in the database<br>
		 * synchronous<br>
		 * dispatches info if anything goes wrong 
		 */
		public static function updateBasalRateSynchronous(basalRate:BasalRate):void 
		{
			try 
			{
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.UPDATE);
				conn.begin();
				var updateRequest:SQLStatement = new SQLStatement();
				updateRequest.sqlConnection = conn;
				updateRequest.text = "UPDATE basalrates SET " +
					"id = '" + basalRate.ID + "', " +
					"time = '" + basalRate.startTime + "', " +
					"hours = " + basalRate.startHours + ", " +
					"minutes = " + basalRate.startMinutes + ", " +
					"rate = " + basalRate.basalRate + ", " +
					"lastmodifiedtimestamp = " + basalRate.timestamp + " " +
					"WHERE id = '" + basalRate.ID + "'";
				updateRequest.execute();
				conn.commit();
				conn.close();
			} catch (error:SQLError) {
				if (conn.connected) {
					conn.rollback();
					conn.close();
				}
				dispatchInformation('error_while_updating_basal_rate_in_db', error.message + " - " + error.details);
			}
		}
		
		/**
		 * deletes a basal rate in the database<br>
		 * dispatches info if anything goes wrong 
		 */
		public static function deleteBasalRateSynchronous(basalRate:BasalRate):void {
			try {
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.UPDATE);
				conn.begin();
				var deleteRequest:SQLStatement = new SQLStatement();
				deleteRequest.sqlConnection = conn;
				deleteRequest.text = "DELETE from basalrates WHERE id = " + "'" + basalRate.ID + "'";
				deleteRequest.execute();
				conn.commit();
				conn.close();
			} catch (error:SQLError) {
				if (conn.connected) {
					conn.rollback();
					conn.close();
				}
				dispatchInformation('error_while_deleting_basal_rate_in_db', error.message + " - " + error.details);
			}
		}
		
		/**
		 * Returns pie chart stats for glucose distribution, glucose variability and tratments.<br>
		 * Between two dates, in a combined query for faster processing.<br>
		 * Readings without calibration are ignored.<br>
		 * Has option to only query and return different sections of stats.
		 */
		public static function getBasicUserStats(fromTime:Number = Number.NaN, untilTime:Number = Number.NaN, page:String = "all"):BasicUserStats 
		{
			var userStats:BasicUserStats = new BasicUserStats(page);
			var a1cOffset:Number = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PIE_CHART_A1C_OFFSET));
			var avgOffset:Number = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PIE_CHART_AVG_OFFSET));
			var rangesOffset:Number = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PIE_CHART_RANGES_OFFSET));
			var variabilityOffSet:Number = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PIE_CHART_VARIABILITY_OFFSET));
			var treatmentsOffSet:Number = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PIE_CHART_TREATMENTS_OFFSET));
			var lowThreshold:Number = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_LOW_MARK));;
			var highThreshold:Number = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_HIGH_MARK));
			var userType:String = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_USER_TYPE_PUMP_OR_MDI);
			var now:Number = new Date().valueOf();
			
			try 
			{
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.READ);
				conn.begin();
				var getRequest:SQLStatement = new SQLStatement();
				getRequest.sqlConnection = conn;
				
				if (page == BasicUserStats.PAGE_ALL || page == BasicUserStats.PAGE_BG_DISTRIBUTION)
				{
					var sqlQuery:String = "";
					sqlQuery += "SELECT AVG(calculatedValue) AS `averageGlucose`, ";
					sqlQuery +=	"(SELECT AVG(calculatedValue) FROM bgreading WHERE calibrationid != '-' AND timestamp BETWEEN " + (isNaN(fromTime) ? (now - a1cOffset) : fromTime) + " AND " + (isNaN(untilTime) ? now : untilTime) + ") AS `averageGlucoseA1C`, ";
					sqlQuery +=	"(SELECT COUNT(bgreadingid) FROM bgreading WHERE calibrationid != '-' AND timestamp BETWEEN " + (isNaN(fromTime) ? (now - TimeSpan.TIME_24_HOURS) : fromTime) + " AND " + (isNaN(untilTime) ? now : untilTime) + ") AS `numReadingsDay`, ";
					sqlQuery +=	"(SELECT COUNT(bgreadingid) FROM bgreading WHERE calibrationid != '-' AND timestamp BETWEEN " + (isNaN(fromTime) ? (now - rangesOffset) : fromTime) + " AND " + (isNaN(untilTime) ? now : untilTime) + ") AS `numReadingsTotal`, ";
					sqlQuery +=	"(SELECT COUNT(bgreadingid) FROM bgreading WHERE calibrationid != '-' AND calculatedValue <= " + lowThreshold + " AND timestamp BETWEEN " + (isNaN(fromTime) ? (now - rangesOffset) : fromTime) + " AND " + (isNaN(untilTime) ? now : untilTime) + ") AS `numReadingsLow`, ";
					sqlQuery +=	"(SELECT COUNT(bgreadingid) FROM bgreading WHERE calibrationid != '-' AND calculatedValue > " + lowThreshold + " AND calculatedValue < " + highThreshold + " AND timestamp BETWEEN " + (isNaN(fromTime) ? (now - rangesOffset) : fromTime) + " AND " + (isNaN(untilTime) ? now : untilTime) + ") AS `numReadingsInRange`, ";
					sqlQuery +=	"(SELECT COUNT(bgreadingid) FROM bgreading WHERE calibrationid != '-' AND calculatedValue >= " + highThreshold + " AND timestamp BETWEEN " + (isNaN(fromTime) ? (now - rangesOffset) : fromTime) + " AND " + (isNaN(untilTime) ? now : untilTime) + ") AS `numReadingsHigh` ";
					sqlQuery +=	"FROM bgreading WHERE calibrationid != '-' AND timestamp BETWEEN " + (isNaN(fromTime) ? (now - avgOffset) : fromTime) + " AND " + (isNaN(untilTime) ? now : untilTime);
					getRequest.text = sqlQuery;
					getRequest.execute();
					var resultBasic:SQLResult = getRequest.getResult();
				}
				
				if (page == BasicUserStats.PAGE_ALL || page == BasicUserStats.PAGE_VARIABILITY)
				{
					getRequest.clearParameters();
					getRequest.text = "SELECT calculatedValue, timestamp, ";
					getRequest.text += "(SELECT COUNT(bgreadingid) FROM bgreading WHERE calibrationid != '-' AND calculatedValue > " + lowThreshold + " AND calculatedValue < " + highThreshold + " AND timestamp BETWEEN " + (isNaN(fromTime) ? (now - variabilityOffSet) : fromTime) + " AND " + (isNaN(untilTime) ? now : untilTime) + ") AS `numReadingsInRangeForVariability`, ";
					getRequest.text += "(SELECT ((COUNT(*)*(SUM(calculatedValue * calculatedValue)) - (SUM(calculatedValue)*SUM(calculatedValue)) )/((COUNT(*)-1)*(COUNT(*))) ) from bgreading WHERE calibrationid != '-' AND calculatedValue > 38 AND timestamp BETWEEN " + (isNaN(fromTime) ? (now - variabilityOffSet) : fromTime) + " AND " + (isNaN(untilTime) ? now : untilTime) + ") AS `stdDeviation` ";
					getRequest.text += "FROM bgreading WHERE calibrationid != '-' AND calculatedValue > 38 AND timestamp BETWEEN " + (isNaN(fromTime) ? (now - variabilityOffSet) : fromTime) + " AND " + (isNaN(untilTime) ? now : untilTime);
					getRequest.execute();
					var resultVariability:SQLResult = getRequest.getResult();
				}
				
				if (page == BasicUserStats.PAGE_ALL || page == BasicUserStats.PAGE_TREATMENTS)
				{
					getRequest.clearParameters();
					getRequest.text = "SELECT SUM(insulinamount) AS `totalBolus`, ";
					getRequest.text +=	"(SELECT SUM(carbs) FROM treatments WHERE lastmodifiedtimestamp BETWEEN " + (isNaN(fromTime) ? (now - treatmentsOffSet) : fromTime) + " AND " + (isNaN(untilTime) ? now : untilTime) + ") AS `totalCarbs`, ";
					if (userType == "mdi")
					{
						getRequest.text +=	"(SELECT SUM(basalabsoluteamount) FROM treatments WHERE lastmodifiedtimestamp BETWEEN " + (isNaN(fromTime) ? (now - treatmentsOffSet) : fromTime) + " AND " + (isNaN(untilTime) ? now : untilTime) + ") AS `totalBasal`, ";
					}
					getRequest.text +=	"(SELECT SUM(duration) FROM treatments WHERE type == '" + Treatment.TYPE_EXERCISE + "' AND lastmodifiedtimestamp BETWEEN " + (isNaN(fromTime) ? (now - treatmentsOffSet) : fromTime) + " AND " + (isNaN(untilTime) ? now : untilTime) + ") AS `totalExercise` ";
					getRequest.text += "FROM treatments WHERE lastmodifiedtimestamp BETWEEN " + (isNaN(fromTime) ? (now - treatmentsOffSet) : fromTime) + " AND " + (isNaN(untilTime) ? now : untilTime);
					getRequest.execute();
					var resultTreatments:SQLResult = getRequest.getResult();
				}
				
				conn.close();
				
				//Glucose Distribution
				if ((page == BasicUserStats.PAGE_ALL || page == BasicUserStats.PAGE_BG_DISTRIBUTION)
					&&
					resultBasic != null
					&&
					resultBasic.data != null 
					&& 
					resultBasic.data is Array 
					&& 
					resultBasic.data[0] != null 
					&& 
					(resultBasic.data[0]["averageGlucose"] != null && !isNaN(resultBasic.data[0]["averageGlucose"])) 
					&&    
					(resultBasic.data[0]["numReadingsDay"] != null && !isNaN(resultBasic.data[0]["numReadingsDay"])) 
					&&    
					(resultBasic.data[0]["numReadingsTotal"] != null && !isNaN(resultBasic.data[0]["numReadingsTotal"])) 
					&&    
					(resultBasic.data[0]["numReadingsLow"] != null && !isNaN(resultBasic.data[0]["numReadingsLow"])) 
					&&    
					(resultBasic.data[0]["numReadingsInRange"] != null && !isNaN(resultBasic.data[0]["numReadingsInRange"])) 
					&&       
					(resultBasic.data[0]["numReadingsHigh"] != null && !isNaN(resultBasic.data[0]["numReadingsHigh"])) 
					&& 
					(resultBasic.data[0]["averageGlucoseA1C"] != null && !isNaN(resultBasic.data[0]["averageGlucoseA1C"]))
				)
				{
					userStats.averageGlucose = ((Number(resultBasic.data[0]["averageGlucose"]) * 10 + 0.5)  >> 0) / 10;
					if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) != "true") userStats.averageGlucose = Math.round(((BgReading.mgdlToMmol((userStats.averageGlucose))) * 10)) / 10;
					userStats.numReadingsDay = Number(resultBasic.data[0]["numReadingsDay"]);
					userStats.numReadingsTotal = Number(resultBasic.data[0]["numReadingsTotal"]);
					userStats.numReadingsLow = Number(resultBasic.data[0]["numReadingsLow"]);
					userStats.numReadingsInRange = Number(resultBasic.data[0]["numReadingsInRange"]);
					userStats.numReadingsHigh = Number(resultBasic.data[0]["numReadingsHigh"]);
					userStats.a1c = ((((46.7 + (((Number(resultBasic.data[0]["averageGlucoseA1C"]) * 10 + 0.5)  >> 0) / 10)) / 28.7) * 10 + 0.5)  >> 0) / 10;
					if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PIE_CHART_A1C_IFCC_ON) == "true")
						userStats.a1c = ((((userStats.a1c - 2.15) * 10.929) * 10 + 0.5)  >> 0) / 10; //IFCC support
					userStats.percentageHigh = (userStats.numReadingsHigh * 100) / userStats.numReadingsTotal;
					userStats.percentageHighRounded = ((userStats.percentageHigh * 10 + 0.5)  >> 0) / 10;
					userStats.percentageInRange = (userStats.numReadingsInRange * 100) / userStats.numReadingsTotal;
					userStats.percentageInRangeRounded = ((userStats.percentageInRange * 10 + 0.5)  >> 0) / 10;
					userStats.percentageLow = 100 - userStats.percentageInRange - userStats.percentageHigh;
					userStats.percentageLowRounded = Math.round((100 - userStats.percentageHighRounded - userStats.percentageInRangeRounded) * 10) / 10;
					userStats.captureRate = ((((userStats.numReadingsDay * 100) / 288) * 10 + 0.5)  >> 0) / 10;
					if (userStats.captureRate > 100) userStats.captureRate = 100;
				}
				
				//Glucose Variability
				if ((page == BasicUserStats.PAGE_ALL || page == BasicUserStats.PAGE_VARIABILITY)
					&&
					resultVariability != null
					&&
					resultVariability.data != null 
					&& 
					resultVariability.data is Array 
					&& 
					resultVariability.data[0] != null 
					&& 
					(resultVariability.data[0]["stdDeviation"] != null && !isNaN(resultVariability.data[0]["stdDeviation"]))
					&& 
					(resultVariability.data[0]["numReadingsInRangeForVariability"] != null && !isNaN(resultVariability.data[0]["numReadingsInRangeForVariability"]))
				)
				{
					var variabilityInRangePct:Number = (resultVariability.data[0]["numReadingsInRangeForVariability"] * 100) / resultVariability.data.length;
					var advancedStats:Object = GlucoseFactory.calculateAdvancedStats(resultVariability.data, variabilityInRangePct);
					userStats.standardDeviation = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true" ? Math.round(Math.sqrt(resultVariability.data[0]["stdDeviation"]) * 10) / 10 : Math.round(BgReading.mgdlToMmol(Math.sqrt(resultVariability.data[0]["stdDeviation"])) * 100) / 100;
					userStats.gvi = advancedStats.GVI != null && !isNaN(advancedStats.GVI) ? advancedStats.GVI : Number.NaN;
					userStats.pgs = advancedStats.PGS != null && !isNaN(advancedStats.PGS) ? advancedStats.PGS : Number.NaN;
					userStats.hourlyChange = advancedStats.meanHourlyChange != null && !isNaN( advancedStats.meanHourlyChange) ? CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true" ? Math.round(advancedStats.meanHourlyChange * 10) / 10 : Math.round(advancedStats.meanHourlyChange * 100) / 100 : Number.NaN;
					userStats.fluctuation5 = advancedStats.timeInFluctuation != null && !isNaN(advancedStats.timeInFluctuation) ? advancedStats.timeInFluctuation : Number.NaN;
					userStats.fluctuation10 = advancedStats.timeInRapidFluctuation != null && !isNaN(advancedStats.timeInRapidFluctuation) ? advancedStats.timeInRapidFluctuation : Number.NaN;
				}
				
				//Treatments
				if ((page == BasicUserStats.PAGE_ALL || page == BasicUserStats.PAGE_TREATMENTS)
					&&
					resultTreatments != null
					&&
					resultTreatments.data != null 
					&& 
					resultTreatments.data is Array 
					&& 
					resultTreatments.data[0] != null 
					&& 
					(resultTreatments.data[0]["totalBolus"] != null && !isNaN(resultTreatments.data[0]["totalBolus"]))
					&& 
					(resultTreatments.data[0]["totalCarbs"] != null && !isNaN(resultTreatments.data[0]["totalCarbs"]))
				)
				{
					userStats.bolus = Math.round(resultTreatments.data[0]["totalBolus"] * 100) / 100;
					userStats.carbs = Math.round(resultTreatments.data[0]["totalCarbs"] * 10) / 10;
					userStats.exercise = resultTreatments.data[0]["totalExercise"] != null && !isNaN(resultTreatments.data[0]["totalExercise"]) ? Math.round(resultTreatments.data[0]["totalExercise"]) : 0;
					if (userType == "pump")
					{
						StatsManager.performBasalCalculations(userStats);
					}
					else if (userType == "mdi")
					{
						if (resultTreatments.data[0]["totalBasal"] != null)
						{
							userStats.basal = !isNaN(resultTreatments.data[0]["totalBasal"]) ? resultTreatments.data[0]["totalBasal"] : 0;
						}
					}
				}
			} catch (error:SQLError) {
				if (conn.connected) conn.close();
				dispatchInformation('error_while_getting_user_stats', error.message + " - " + error.details);
			} catch (other:Error) {
				if (conn.connected) conn.close();
				dispatchInformation('error_while_getting_user_stats',other.getStackTrace().toString());
			} finally {
				if (conn.connected) conn.close();
				return userStats;
			}
		}
		
		/**
		 * Get Healthkit Treatments synchronously
		 */
		public static function getHealthkitTreatmentsSynchronous(from:Number, until:Number):Array {
			var returnValue:Array = new Array();
			try {
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.READ);
				conn.begin();
				var getRequest:SQLStatement = new SQLStatement();
				getRequest.sqlConnection = conn;
				getRequest.text =  "SELECT * FROM healthkittreatments WHERE timestamp BETWEEN " + from + " AND " + until;
				getRequest.execute();
				var result:SQLResult = getRequest.getResult();
				conn.close();
				if (result.data != null)
					returnValue = result.data;
			} catch (error:SQLError) {
				if (conn.connected) conn.close();
				dispatchInformation('error_while_getting_healthkittreatments', error.message + " - " + error.details);
			} catch (other:Error) {
				if (conn.connected) conn.close();
				dispatchInformation('error_while_getting_healthkittreatments',other.getStackTrace().toString());
			} finally {
				if (conn.connected) conn.close();
				return returnValue;
			}
		}
		
		/**
		 * inserts a healthkittreatment in the database<br>
		 * synchronous<br>
		 * dispatches info if anything goes wrong 
		 */
		public static function insertHealthkitTreatmentSynchronous(id:String, timestamp:Number):void 
		{
			try 
			{
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.UPDATE);
				conn.begin();
				var insertRequest:SQLStatement = new SQLStatement();
				insertRequest.sqlConnection = conn;
				var text:String = "INSERT INTO healthkittreatments (";
				text += "id, ";
				text += "timestamp) ";
				text += "VALUES (";
				text += "'" + id + "', ";
				text += timestamp + ")";
				
				insertRequest.text = text;
				insertRequest.execute();
				conn.commit();
				conn.close();
			} catch (error:SQLError) {
				if (conn.connected) {
					conn.rollback();
					conn.close();
				}
				dispatchInformation('error_while_inserting_healthkittreatment_in_db', error.message + " - " + error.details);
			}
		}
		
		/**
		 * Deletes healthkit treatments older than 24H (not needed any more)
		 */
		public static function deleteOldHealthkitTreatments():void {
			try {
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.UPDATE);
				conn.begin();
				var deleteRequest:SQLStatement = new SQLStatement();
				deleteRequest.sqlConnection = conn;
				deleteRequest.text = "DELETE from healthkittreatments WHERE timestamp < " + (new Date().valueOf() - (24 * 60 * 60 * 1000));
				deleteRequest.execute();
				conn.commit();
				conn.close();
			} catch (error:SQLError) {
				if (conn.connected) {
					conn.rollback();
					conn.close();
				}
				dispatchInformation('error_while_deleting_old_healthkitt_treatments_in_db', error.message + " - " + error.details);
			}
		}
		
		/**
		 * Get foods by name synchronously
		 */
		public static function getFavoriteFoodSynchronous(foodName:String, page:int):Object {
			
			var returnObject:Object = {};
			var foodsList:Array = new Array();
			var foodBatchAmount:int = 50;
			var foodOffSet:int = (page - 1) * foodBatchAmount;
			
			try {
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.READ);
				conn.begin();
				var getRequest:SQLStatement = new SQLStatement();
				getRequest.sqlConnection = conn;
				var sqlQuery:String = "";
				sqlQuery += "SELECT *, ";
				sqlQuery += "(SELECT COUNT(id) FROM foods WHERE name LIKE '%" + foodName + "%') AS `totalRecords` ";
				sqlQuery += "FROM foods WHERE name LIKE '%" + foodName + "%' ORDER BY name COLLATE NOCASE ASC LIMIT " + foodBatchAmount + " OFFSET " + foodOffSet;
				getRequest.text = sqlQuery;
				getRequest.execute();
				var result:SQLResult = getRequest.getResult();
				conn.close();
				if (result.data != null)
				{
					returnObject.foodsList = result.data;
					returnObject.totalRecords = result.data[0]["totalRecords"] != null ? int(result.data[0]["totalRecords"]) : 0;
				}
				
			} catch (error:SQLError) {
				if (conn.connected) conn.close();
				dispatchInformation('error_while_getting_profiles', error.message + " - " + error.details);
			} catch (other:Error) {
				if (conn.connected) conn.close();
				dispatchInformation('error_while_getting_profiles',other.getStackTrace().toString());
			} finally {
				if (conn.connected) conn.close();
				return returnObject;
			}
		}
		
		/**
		 * Get foods by barcode synchronously
		 */
		public static function getFavoriteFoodByBarcodeSynchronous(barCode:String):Array {
			
			var foodsList:Array = new Array();
			
			try {
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.READ);
				conn.begin();
				var getRequest:SQLStatement = new SQLStatement();
				getRequest.sqlConnection = conn;
				getRequest.text = "SELECT * FROM foods WHERE barcode LIKE '%" + barCode + "%'";
				getRequest.execute();
				var result:SQLResult = getRequest.getResult();
				conn.close();
				if (result.data != null)
				{
					foodsList = result.data;
				}
				
			} catch (error:SQLError) {
				if (conn.connected) conn.close();
				dispatchInformation('error_while_getting_profiles', error.message + " - " + error.details);
			} catch (other:Error) {
				if (conn.connected) conn.close();
				dispatchInformation('error_while_getting_profiles',other.getStackTrace().toString());
			} finally {
				if (conn.connected) conn.close();
				return foodsList;
			}
		}
		
		/**
		 * inserts a food in the database<br>
		 * synchronous<br>
		 * dispatches info if anything goes wrong 
		 */
		public static function insertFoodSynchronous(food:Food):void 
		{
			try 
			{
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.UPDATE);
				conn.begin();
				var insertRequest:SQLStatement = new SQLStatement();
				insertRequest.sqlConnection = conn;
				var text:String = "INSERT INTO foods (";
				text += "id, ";
				text += "name, ";
				text += "brand, ";
				text += "proteins, ";
				text += "carbs, ";
				text += "fiber, ";
				text += "fats, ";
				text += "calories, ";
				text += "servingsize, ";
				text += "servingunit, ";
				text += "link, ";
				text += "barcode, ";
				text += "source, ";
				text += "notes, ";
				text += "lastmodifiedtimestamp) ";
				text += "VALUES (";
				text += "'" + food.id + "', ";
				text += "'" + food.name.replace(/'/g, "''") + "', ";
				text += "'" + food.brand.replace(/'/g, "''") + "', ";
				text += "'" + food.proteins + "', ";
				text += "'" + food.carbs + "', ";
				text += "'" + food.fiber + "', ";
				text += "'" + food.fats + "', ";
				text += "'" + food.kcal + "', ";
				text += "'" + food.servingSize + "', ";
				text += "'" + food.servingUnit.replace(/'/g, "''") + "', ";
				text += "'" + food.link + "', ";
				text += "'" + food.barcode + "', ";
				text += "'" + food.source + "', ";
				text += "'" + food.note + "', ";
				text += food.timestamp + ")";
				
				insertRequest.text = text;
				insertRequest.execute();
				conn.commit();
				conn.close();
			} catch (error:SQLError) {
				if (conn.connected) {
					conn.rollback();
					conn.close();
				}
				dispatchInformation('error_while_inserting_food_in_db', error.message + " - " + error.details);
			}
		}
		
		/**
		 * updates a food in the database<br>
		 * synchronous<br>
		 * dispatches info if anything goes wrong 
		 */
		public static function updateFoodSynchronous(food:Food):void 
		{
			try 
			{
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.UPDATE);
				conn.begin();
				var updateRequest:SQLStatement = new SQLStatement();
				updateRequest.sqlConnection = conn;
				updateRequest.text = "UPDATE foods SET " +
					"id = '" + food.id + "', " +
					"name = '" + food.name.replace(/'/g, "''") + "', " +
					"brand = '" + food.brand.replace(/'/g, "''") + "', " +
					"proteins = '" + food.proteins + "', " +
					"carbs = '" + food.carbs + "', " +
					"fiber = '" + food.fiber + "', " +
					"fats = '" + food.fats + "', " +
					"calories = '" + food.kcal + "', " +
					"servingsize = '" + food.servingSize + "', " +
					"servingunit = '" + food.servingUnit.replace(/'/g, "''") + "', " +
					"link = '" + food.link + "', " +
					"barcode = '" + food.barcode + "', " +
					"source = '" + food.source + "', " +
					"source = '" + food.note + "', " +
					"lastmodifiedtimestamp = " + food.timestamp + " " +
					"WHERE id = '" + food.id + "'";
				updateRequest.execute();
				conn.commit();
				conn.close();
			} catch (error:SQLError) {
				if (conn.connected) {
					conn.rollback();
					conn.close();
				}
				dispatchInformation('error_while_updating_food_in_db', error.message + " - " + error.details);
			}
		}
		
		/**
		 * Deletes a food in the database<br>
		 * dispatches info if anything goes wrong 
		 */
		public static function deleteFoodSynchronous(food:Food):void {
			try {
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.UPDATE);
				conn.begin();
				var deleteRequest:SQLStatement = new SQLStatement();
				deleteRequest.sqlConnection = conn;
				deleteRequest.text = "DELETE from foods WHERE id = " + "'" + food.id + "'";
				deleteRequest.execute();
				conn.commit();
				conn.close();
			} catch (error:SQLError) {
				if (conn.connected) {
					conn.rollback();
					conn.close();
				}
				dispatchInformation('error_while_deleting_food_in_db', error.message + " - " + error.details);
			}
		}
		
		/**
		 * Checks if food is saved in Database<br>
		 * dispatches info if anything goes wrong 
		 */
		public static function isFoodFavoriteSynchronous(food:Food):Boolean 
		{
			var foodFound:Boolean = false;
			
			try 
			{
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.READ);
				conn.begin();
				var getRequest:SQLStatement = new SQLStatement();
				getRequest.sqlConnection = conn;
				var sqlQuery:String = "";
				sqlQuery +=	"SELECT id FROM foods WHERE id = '" + food.id + "'";
				getRequest.text = sqlQuery;
				getRequest.execute();
				var result:SQLResult = getRequest.getResult();
				conn.close();
				
				if (result.data != null && result.data is Array && result.data.length > 0)
				{
					foodFound = true;
				}
				
			} catch (error:SQLError) {
				if (conn.connected) conn.close();
				dispatchInformation('error_while_checking_if_food_is_favourite', error.message + " - " + error.details);
				return foodFound;
			} catch (other:Error) {
				if (conn.connected) conn.close();
				dispatchInformation('error_while_checking_if_food_is_favourite',other.getStackTrace().toString());
				return foodFound;
			} finally {
				if (conn.connected) conn.close();
				return foodFound;
			}
		}
		
		/**
		 * inserts a recipe in the database<br>
		 * synchronous<br>
		 * dispatches info if anything goes wrong 
		 */
		public static function insertRecipeSynchronous(recipe:Recipe):void 
		{
			try 
			{
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.UPDATE);
				conn.begin();
				var insertRequest:SQLStatement = new SQLStatement();
				insertRequest.sqlConnection = conn;
				
				var text:String;
				
				//Add Recipe
				text = "INSERT INTO recipeslist (";
				text += "id, ";
				text += "name, ";
				text += "servingsize, ";
				text += "servingunit, ";
				text += "notes, ";
				text += "lastmodifiedtimestamp) ";
				text += "VALUES (";
				text += "'" + recipe.id + "', ";
				text += "'" + recipe.name + "', ";
				text += "'" + recipe.servingSize + "', ";
				text += "'" + recipe.servingUnit.replace(/'/g, "''") + "', ";
				text += "'" + recipe.notes + "', ";
				text += recipe.timestamp + ")";
				insertRequest.text = text;
				insertRequest.execute();
				
				//Add Foods
				for (var i:int = 0; i < recipe.foods.length; i++) 
				{
					var food:Food = recipe.foods[i];
					text = "INSERT INTO recipesfoods (";
					text += "recipeid, ";
					text += "foodid, ";
					text += "name, ";
					text += "brand, ";
					text += "proteins, ";
					text += "carbs, ";
					text += "fiber, ";
					text += "substractfiber, ";
					text += "fats, ";
					text += "calories, ";
					text += "servingsize, ";
					text += "servingunit, ";
					text += "recipeservingsize, ";
					text += "recipeservingunit, ";
					text += "link, ";
					text += "barcode, ";
					text += "source, ";
					text += "notes, ";
					text += "defaultunit, ";
					text += "lastmodifiedtimestamp) ";
					text += "VALUES (";
					text += "'" + recipe.id + "', ";
					text += "'" + food.id + "', ";
					text += "'" + food.name.replace(/'/g, "''") + "', ";
					text += "'" + food.brand.replace(/'/g, "''") + "', ";
					text += "'" + food.proteins + "', ";
					text += "'" + food.carbs + "', ";
					text += "'" + food.fiber + "', ";
					text += "'" + food.substractFiber + "', ";
					text += "'" + food.fats + "', ";
					text += "'" + food.kcal + "', ";
					text += "'" + food.servingSize + "', ";
					text += "'" + food.servingUnit.replace(/'/g, "''") + "', ";
					text += "'" + recipe.servingSize + "', ";
					text += "'" + recipe.servingUnit.replace(/'/g, "''") + "', ";
					text += "'" + food.link + "', ";
					text += "'" + food.barcode + "', ";
					text += "'" + food.source + "', ";
					text += "'" + food.note + "', ";
					text += "'" + food.defaultUnit + "', ";
					text += food.timestamp + ")";
					
					insertRequest.text = text;
					insertRequest.execute();
				}
				conn.commit();
				conn.close();
			} catch (error:SQLError) {
				if (conn.connected) {
					conn.rollback();
					conn.close();
				}
				dispatchInformation('error_while_inserting_recipe_or_food_in_db', error.message + " - " + error.details);
			}
		}
		
		/**
		 * Get recipes by name synchronously
		 */
		public static function getRecipesSynchronous(recipeName:String, page:int):Object {
			
			var returnObject:Object = {};
			var recipesList:Array = [];
			var recipeBatchAmount:int = 50;
			var recipeOffSet:int = (page - 1) * recipeBatchAmount;
			
			try {
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.READ);
				conn.begin();
				var getRequest:SQLStatement = new SQLStatement();
				getRequest.sqlConnection = conn;
				var sqlQuery:String = "";
				sqlQuery += "SELECT *, ";
				sqlQuery += "(SELECT COUNT(id) FROM recipeslist WHERE name LIKE '%" + recipeName + "%') AS `totalRecords` ";
				sqlQuery += "FROM recipeslist WHERE name LIKE '%" + recipeName + "%' ORDER BY name COLLATE NOCASE ASC LIMIT " + recipeBatchAmount + " OFFSET " + recipeOffSet;
				getRequest.text = sqlQuery;
				getRequest.execute();
				var result:SQLResult = getRequest.getResult();
				
				if (result.data != null && result.data is Array)
				{
					returnObject.totalRecords = result.data[0]["totalRecords"] != null ? int(result.data[0]["totalRecords"]) : 0;
					
					var foundRecipesList:Array = result.data;
					var numRecipes:int = foundRecipesList.length;
					
					for (var i:int = 0; i < numRecipes; i++) 
					{
						var tempRecipe:Object = foundRecipesList[i] as Object;
						var recipesFoods:Array = [];
						
						var recipe:Recipe = new Recipe
						(
							tempRecipe.id,
							tempRecipe.name,
							tempRecipe.servingsize,
							tempRecipe.servingunit,
							recipesFoods,
							tempRecipe.lastmodifiedtimestamp,
							tempRecipe.notes
						);
						
						//Query database for foods belonging to this recipe
						var recipeSQLQuery:String = "SELECT * FROM recipesfoods WHERE recipeid LIKE '%" + tempRecipe.id + "%' ORDER BY name COLLATE NOCASE ASC";
						getRequest.text = recipeSQLQuery;
						getRequest.execute();
						var recipeResult:SQLResult = getRequest.getResult();
						
						if (recipeResult.data != null && recipeResult.data is Array)
						{
							var tempRecipesFoodsList:Array = recipeResult.data;
							var numRecipeFoods:int = tempRecipesFoodsList.length;
							
							for (var j:int = 0; j < numRecipeFoods; j++) 
							{
								var tempFood:Object = tempRecipesFoodsList[j] as Object;
								var food:Food = new Food
								(
									tempFood.foodid,
									tempFood.name,
									Number(tempFood.proteins),
									Number(tempFood.carbs),
									Number(tempFood.fats),
									Number(tempFood.calories),
									Number(tempFood.servingsize),
									tempFood.servingunit,
									tempFood.lastmodifiedtimestamp,
									Number(tempFood.fiber),
									tempFood.brand,
									tempFood.link,
									tempFood.source,
									tempFood.barcode,
									tempFood.substractfiber == "true" ? true : false,
									Number(tempFood.recipeservingsize),
									tempFood.recipeservingunit,
									tempFood.notes,
									tempFood.defaultunit == "true" ? true : false
								);
								
								recipesFoods.push(food);
							}
						}
						
						recipe.performCalculations();
						recipesList.push(recipe);
					}
					
					returnObject.recipesList = recipesList;
				}
				conn.close();
			} catch (error:SQLError) {
				if (conn.connected) conn.close();
				dispatchInformation('error_while_getting_recipes', error.message + " - " + error.details);
			} catch (other:Error) {
				if (conn.connected) conn.close();
				dispatchInformation('error_while_getting_recipes',other.getStackTrace().toString());
			} finally {
				if (conn.connected) conn.close();
				return returnObject;
			}
		}
		
		/**
		 * Checks if a recipe is saved in Database<br>
		 * dispatches info if anything goes wrong 
		 */
		public static function isRecipeFavoriteSynchronous(recipe:Recipe):Boolean 
		{
			var recipeFound:Boolean = false;
			
			try 
			{
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.READ);
				conn.begin();
				var getRequest:SQLStatement = new SQLStatement();
				getRequest.sqlConnection = conn;
				var sqlQuery:String = "";
				sqlQuery +=	"SELECT id FROM recipeslist WHERE id = '" + recipe.id + "'";
				getRequest.text = sqlQuery;
				getRequest.execute();
				var result:SQLResult = getRequest.getResult();
				conn.close();
				
				if (result.data != null && result.data is Array && result.data.length > 0)
				{
					recipeFound = true;
				}
				
			} catch (error:SQLError) {
				if (conn.connected) conn.close();
				dispatchInformation('error_while_checking_if_recipe_is_favourite', error.message + " - " + error.details);
				return recipeFound;
			} catch (other:Error) {
				if (conn.connected) conn.close();
				dispatchInformation('error_while_checking_if_recipe_is_favourite',other.getStackTrace().toString());
				return recipeFound;
			} finally {
				if (conn.connected) conn.close();
				return recipeFound;
			}
		}
		
		/**
		 * Deletes a recipe and all it's foods from the database<br>
		 * dispatches info if anything goes wrong 
		 */
		public static function deleteRecipeSynchronous(recipe:Recipe):void {
			try {
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.UPDATE);
				conn.begin();
				var deleteRequest:SQLStatement = new SQLStatement();
				deleteRequest.sqlConnection = conn;
				deleteRequest.text = "DELETE from recipeslist WHERE id = " + "'" + recipe.id + "'";
				deleteRequest.execute();
				deleteRequest.text = "DELETE from recipesfoods WHERE recipeid = " + "'" + recipe.id + "'";
				deleteRequest.execute();
				conn.commit();
				conn.close();
			} catch (error:SQLError) {
				if (conn.connected) {
					conn.rollback();
					conn.close();
				}
				dispatchInformation('error_while_deleting_recipe_in_db', error.message + " - " + error.details);
			}
		}
		
		/**
		 * Get IOB/COB Caches
		 */
		public static function getIOBCOBCachesSynchronous():Array {
			var returnValue:Array = [];
			try {
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.READ);
				conn.begin();
				var getRequest:SQLStatement = new SQLStatement();
				getRequest.sqlConnection = conn;
				getRequest.text =  "SELECT * FROM iobcobcaches";
				getRequest.execute();
				var result:SQLResult = getRequest.getResult();
				conn.close();
				if (result.data != null)
					returnValue = result.data;
			} catch (error:SQLError) {
				if (conn.connected) conn.close();
				dispatchInformation('error_while_getting_iobcobcaches', error.message + " - " + error.details);
			} catch (other:Error) {
				if (conn.connected) conn.close();
				dispatchInformation('error_while_getting_iobcobcaches',other.getStackTrace().toString());
			} finally {
				if (conn.connected) conn.close();
				return returnValue;
			}
		}
		
		/**
		 * Updates COB/IOB caches<br>
		 * Synchronous
		 */
		public static function updateIOBCOBCachesSynchronous(iob:String, iobIndexes:String, cob:String, cobIndexes:String):void 
		{
			try  {
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.UPDATE);
				conn.begin();
				var updateRequest:SQLStatement = new SQLStatement();
				updateRequest.sqlConnection = conn;
				updateRequest.text = "UPDATE iobcobcaches SET " +
					"iob = '" + iob + "'," +
					"iobindexes = '" + iobIndexes + "'," +
					"cob = '" + cob + "'," +
					"cobindexes = '" + cobIndexes + "'"; 
				updateRequest.execute();
				conn.commit();
				conn.close();
			} catch (error:SQLError) {
				if (conn.connected) {
					conn.rollback();
					conn.close();
				}
				dispatchInformation('error_while_updating_iob_cob_caches', error.message + " - " + error.details);
			}
		}
		
		/**
		 * Creates Default cached objects in the database 
		 */
		public static function insertEmptyIOBCOBCaches():void 
		{
			//Empty dummy object
			var emptyObject:Object = {};
			var emptyObjectBytes:ByteArray = new ByteArray();
			emptyObjectBytes.writeObject(emptyObject);
			var emptyObjectSerialized:String = Base64.encodeByteArray(emptyObjectBytes);
			
			//Empty dummy array
			var emptyArray:Array = [];
			var emptyArrayBytes:ByteArray = new ByteArray();
			emptyArrayBytes.writeObject(emptyArray);
			var emptyArraySerialized:String = Base64.encodeByteArray(emptyArrayBytes);
			
			try 
			{
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.UPDATE);
				conn.begin();
				var insertRequest:SQLStatement = new SQLStatement();
				insertRequest.sqlConnection = conn;
				var text:String = "INSERT INTO iobcobcaches (";
				text += "cob, ";
				text += "cobindexes, ";
				text += "iob, ";
				text += "iobindexes) ";
				text += "VALUES (";
				text += "'" + emptyObjectSerialized + "', ";
				text += "'" + emptyArraySerialized + "', ";
				text += "'" + emptyObjectSerialized + "', ";
				text += "'" + emptyArraySerialized + "')";
				
				insertRequest.text = text;
				insertRequest.execute();
				conn.commit();
				conn.close();
			} catch (error:SQLError) {
				if (conn.connected) {
					conn.rollback();
					conn.close();
				}
				dispatchInformation('error_while_inserting_empty_iobcobcaches_in_db', error.message + " - " + error.details);
			}
		}
		
		/**
		 * Deletes all IOB/COB caches
		 */
		public static function deleteAllIOBCOBCachesSynchronous():void 
		{
			try {
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.UPDATE);
				conn.begin();
				var deleteRequest:SQLStatement = new SQLStatement();
				deleteRequest.sqlConnection = conn;
				deleteRequest.text = "DELETE * from iobcobcaches";
				deleteRequest.execute();
				conn.commit();
				conn.close();
			} catch (error:SQLError) {
				if (conn.connected) {
					conn.rollback();
					conn.close();
				}
				dispatchInformation('error_while_deleting_all_iob_cob_caches_in_db', error.message + " - " + error.details);
			}
		}
		
		/**
		 * Spike Settings
		 */
		public static function updateCommonSetting(settingId:int,newValue:String, lastModifiedTimeStamp:Number = Number.NaN):void {
			if (newValue == null || newValue == "") newValue = "-";
			try {
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.UPDATE);
				conn.begin();
				var updateRequest:SQLStatement = new SQLStatement();
				updateRequest.sqlConnection = conn;
				var text:String = "UPDATE commonsettings SET ";
				text += "lastmodifiedtimestamp = " + (isNaN(lastModifiedTimeStamp) ? (new Date()).valueOf() : lastModifiedTimeStamp) + ",";
				text += " value = '" + newValue + "'";
				text += " where id  = " + settingId;
				updateRequest.text = text;
				updateRequest.execute();
				conn.commit();
				conn.close();
			} catch (error:SQLError) {
				if (conn.connected) {
					conn.rollback();
					conn.close();
				}
				dispatchInformation('error_while_updating_common_setting', error.message + " - " + error.details);
			}
		}
		
		public static function insertCommonSetting(settingId:int, newValue:String, lastModifiedTimeStamp:Number = Number.NaN):void {
			if (newValue == null || newValue == "") newValue = "-";//don't like the null or empty string values, - should be replaced back to null or ""
			try  {
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.UPDATE);
				conn.begin();
				var insertRequest:SQLStatement = new SQLStatement();
				insertRequest.sqlConnection = conn;
				var text:String = "INSERT INTO commonsettings (lastmodifiedtimestamp, value, id) ";
				text += "VALUES (" + (isNaN(lastModifiedTimeStamp) ? (new Date()).valueOf() : lastModifiedTimeStamp) + ", ";
				text += "'" + newValue + "'" + ", ";
				text += settingId + ")"; 
				insertRequest.text = text;
				insertRequest.execute();
				conn.commit();
				conn.close();
			} catch (error:SQLError) {
				if (conn.connected) {
					conn.rollback();
					conn.close();
				}
				dispatchInformation('error_while_inserting_common_setting', error.message + " - " + error.details);
			}
		}
		
		public static function updateLocalSetting(settingId:int,newValue:String, lastModifiedTimeStamp:Number = Number.NaN):void {
			if (newValue == null || newValue == "") newValue = "-";
			try {
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.UPDATE);
				conn.begin();
				var updateRequest:SQLStatement = new SQLStatement();
				updateRequest.sqlConnection = conn;
				var text:String =  "UPDATE localsettings SET ";
				text += "lastmodifiedtimestamp = " + (isNaN(lastModifiedTimeStamp) ? (new Date()).valueOf() : lastModifiedTimeStamp) + ",";
				text += " value = '" + newValue + "'";
				text += " where id  = " + settingId;
				updateRequest.text = text;
				updateRequest.execute();
				conn.commit();
				conn.close();
			} catch (error:SQLError) {
				if (conn.connected) {
					conn.rollback();
					conn.close();
				}
				dispatchInformation('error_while_updating_local_setting', error.message + " - " + error.details);
			}
		}
		
		public static function insertLocalSetting(settingId:int, newValue:String, lastModifiedTimeStamp:Number = Number.NaN):void {
			if (newValue == null || newValue == "") newValue = "-";//don't like the null or empty string values, - should be replaced back to null or ""
			try  {
				var conn:SQLConnection = new SQLConnection();
				conn.open(dbFile, SQLMode.UPDATE);
				conn.begin();
				var insertRequest:SQLStatement = new SQLStatement();
				insertRequest.sqlConnection = conn;
				insertRequest.text = "INSERT INTO localsettings (lastmodifiedtimestamp, value, id) " +
					"VALUES (" + (isNaN(lastModifiedTimeStamp) ? (new Date()).valueOf() : lastModifiedTimeStamp) + ", " +
					"'" + newValue + "'" + ", "  +
					settingId + ")"; 
				insertRequest.execute();
				conn.commit();
				conn.close();
			} catch (error:SQLError) {
				if (conn.connected) {
					conn.rollback();
					conn.close();
				}
				dispatchInformation('error_while_inserting_local_setting', error.message + " - " + error.details);
			}
		}
		
		/**
		 * if aconn is not open then open aconn to dbFile , in asynchronous mode, in UPDATE mode<br>
		 * returns true if aconn is open<br>
		 * if aConn is closed then connection will be opened asynchronous mode and an event will be dispatched to the dispatcher after opening the connecion<br>
		 * so that means if openSQLConnection returns true then there's no need to wait for the dispatcher event to trigger. <br>
		 */ 
		private static function openSQLConnection(dispatcher:EventDispatcher):Boolean {
			if (aConn != null && aConn.connected) { 
				return true;
			} else {
				aConn = new SQLConnection();
				aConn.addEventListener(SQLEvent.OPEN, onConnOpen);
				aConn.addEventListener(SQLErrorEvent.ERROR, onConnError);
				aConn.openAsync(dbFile, SQLMode.UPDATE);
			}
			
			return false;
			
			function onConnOpen(se:SQLEvent):void {
				if (debugMode) trace("Database.as : SQL Connection successfully opened in method Database.openSQLConnection");
				aConn.removeEventListener(SQLEvent.OPEN, onConnOpen);
				aConn.removeEventListener(SQLErrorEvent.ERROR, onConnError);	
				if (dispatcher != null) {
					dispatcher.dispatchEvent(new DatabaseEvent(DatabaseEvent.RESULT_EVENT));
				}
			}
			
			function onConnError(see:SQLErrorEvent):void {
				if (debugMode) trace("Database.as : SQL Error while attempting to open database in method Database.openSQLConnection");
				aConn.removeEventListener(SQLEvent.OPEN, onConnOpen);
				aConn.removeEventListener(SQLErrorEvent.ERROR, onConnError);
				if (dispatcher != null) {
					dispatcher.dispatchEvent(new DatabaseEvent(DatabaseEvent.ERROR_EVENT));
				}
			}
		}
		
		/**
		 * Closes connection to the database. Useful for database restores
		 */
		private static function onHaltExecution(e:SpikeEvent):void
		{
			Trace.myTrace("Database.as", "Closing connection to database...");
			
			if (aConn != null && aConn.connected)
			{
				aConn.addEventListener(SQLEvent.CLOSE, onConnClosed);
				aConn.close();
			}
			else
			{
				Trace.myTrace("Database.as", "Connection to database closed!");
				_instance.dispatchEvent( new DatabaseEvent(DatabaseEvent.DATABASE_CLOSED_EVENT) );
			}
		}
		
		private static function onConnClosed(e:SQLEvent):void
		{
			Trace.myTrace("Database.as", "Connection to database closed!");
			_instance.dispatchEvent( new DatabaseEvent(DatabaseEvent.DATABASE_CLOSED_EVENT) );
		}
		
		private static function dispatchInformation(informationResourceName:String, additionalInfo:String = null):void {
			var information:String = informationResourceName + (additionalInfo == null ? "":" - ") + additionalInfo;
			myTrace(information);
		}
		
		private static function myTrace(log:String):void {
			Trace.myTrace("Database.as", log);
		}
	}
}