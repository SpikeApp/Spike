package services
{
	import com.distriqt.extension.cloudstorage.CloudStorage;
	import com.distriqt.extension.cloudstorage.documents.Document;
	import com.distriqt.extension.cloudstorage.events.DocumentEvent;
	import com.distriqt.extension.cloudstorage.events.DocumentStoreEvent;
	import com.distriqt.extension.networkinfo.NetworkInfo;
	import com.spikeapp.spike.airlibrary.SpikeANE;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;
	import flash.utils.CompressionAlgorithm;
	
	import database.CommonSettings;
	import database.Database;
	
	import distriqtkey.DistriqtKey;
	
	import events.DatabaseEvent;
	import events.FollowerEvent;
	import events.ICloudEvent;
	import events.SettingsServiceEvent;
	import events.TransmitterServiceEvent;
	
	import model.ModelLocator;
	
	import utils.TimeSpan;
	import utils.Trace;
	
	[ResourceBundle("icloudservice")]
	
	public class ICloudService extends EventDispatcher
	{
		//Objects & Properties
		private static var _instance:ICloudService = new ICloudService();
		private static var localDatabaseData:ByteArray;
		private static var remoteDatabaseData:ByteArray;
		private static var appHalted:Boolean = false;
		
		public function ICloudService()
		{
			if (_instance != null)
				throw new Error("ICloudService is not meant to be instantiated");
		}
		
		public static function init():void
		{
			CloudStorage.init( !ModelLocator.IS_IPAD ? DistriqtKey.distriqtKey : DistriqtKey.distriqtKeyIpad );
			
			try
			{
				if (CloudStorage.isSupported)
				{
					if (CloudStorage.service.documentStore.isSupported)
					{
						CloudStorage.service.documentStore.addEventListener( DocumentStoreEvent.CONFLICT, onDocumentStoreConflict );
						
						if (CloudStorage.service.documentStore.setup())
						{
							Trace.myTrace("ICloudService.as", "Service started!");
							
							CommonSettings.instance.addEventListener(SettingsServiceEvent.SETTING_CHANGED, onSettingsChanged);
							
							var currentSchedule:Number = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_ICLOUD_BACKUP_SCHEDULER_TIMESPAN));
							if (!isNaN(currentSchedule) && currentSchedule > 0)
							{
								Trace.myTrace("ICloudService.as", "Automatic iCloud backups are enabled.");
								TransmitterService.instance.addEventListener(TransmitterServiceEvent.LAST_BGREADING_RECEIVED, onBgReadingReceived, false, -1000, true);
								NightscoutService.instance.addEventListener(FollowerEvent.BG_READING_RECEIVED, onBgReadingReceived, false, -1000, true);
							}
							else
								Trace.myTrace("ICloudService.as", "Automatic iCloud backups are disabled.");
						}
						else
							Trace.myTrace("ICloudService.as", "Error activating iCloud storage!");
					}
				}
			} 
			catch(error:Error) 
			{
				Trace.myTrace("ICloudService.as", "Error activating iCloud storage!");
			}
		}
		
		/**
		 * Public Methods
		 */
		public static function backupDatabase():void
		{
			//Validation
			if (appHalted)
				return;
			
			Trace.myTrace("ICloudService.as", "Backup database called!");
			
			if (!NetworkInfo.networkInfo.isReachable())
			{
				Trace.myTrace("ICloudService.as", "Can't perform database backup. There's no internet connection!");
				return;
			}
			
			try
			{
				if (CloudStorage.isSupported)
				{
					if (CloudStorage.service.documentStore.isSupported)
					{	
						if (CloudStorage.service.documentStore.isAvailable)
						{
							//Load database into memory
							var localDatabaseFile:File = File.applicationStorageDirectory.resolvePath("spike.db");
							if (localDatabaseFile.exists && localDatabaseFile.size > 0)
							{
								//Create database file stream
								var databaseStream:FileStream = new FileStream();
								databaseStream.open(localDatabaseFile, FileMode.READ);
								
								//Read database raw bytes into memory
								if (localDatabaseData != null)
								{
									localDatabaseData.clear();
									localDatabaseData = null;
								}
								localDatabaseData = new ByteArray();
								databaseStream.readBytes(localDatabaseData);
								databaseStream.close();
								
								//Compress database
								localDatabaseData.compress(CompressionAlgorithm.ZLIB);
								
								//Create database iCloud document
								var document:Document = new Document();
								document.filename = ModelLocator.IS_IPAD ? "database/spike-ipad.db" : "database/spike.db";
								document.data = localDatabaseData;
								
								//Save database to iCloud
								CloudStorage.service.documentStore.addEventListener( DocumentEvent.SAVE_COMPLETE, onDocumentStoreSaveComplete );
								CloudStorage.service.documentStore.addEventListener( DocumentEvent.SAVE_ERROR, onDocumentStoreSaveError );
								
								Trace.myTrace("ICloudService.as", "Saving database...");
								
								CloudStorage.service.documentStore.saveDocument( document );
							}
							else
							{
								Trace.myTrace("ICloudService.as", "Local database not found!");
								_instance.dispatchEvent( new ICloudEvent(ICloudEvent.LOCAL_DATABASE_NOT_FOUND) );
							}
						}
						else
						{
							Trace.myTrace("ICloudService.as", "iCloud document storage not available!");
							_instance.dispatchEvent( new ICloudEvent(ICloudEvent.ICLOUD_STORAGE_NOT_AVAILABLE) );
						}
					}
					else
					{
						Trace.myTrace("ICloudService.as", "iCloud storage is not supported in this device!");
						_instance.dispatchEvent( new ICloudEvent(ICloudEvent.ICLOUD_STORAGE_NOT_SUPPORTED) );
					}
				}
				else
				{
					Trace.myTrace("ICloudService.as", "iCloud storage is not supported in this device!");
					_instance.dispatchEvent( new ICloudEvent(ICloudEvent.ICLOUD_STORAGE_NOT_SUPPORTED) );
				}
			}
			catch (e:Error)
			{
				Trace.myTrace("ICloudService.as", "An uknown iCloud error has ocurred! Error: " + e.message);
				_instance.dispatchEvent( new ICloudEvent(ICloudEvent.ICLOUD_UNKNOWN_ERROR, false, false, e.message) );
			}
		}
		
		public static function restoreDatabase():void
		{
			Trace.myTrace("ICloudService.as", "Restore database called!");
			
			if (!NetworkInfo.networkInfo.isReachable())
			{
				Trace.myTrace("ICloudService.as", "Can't perform database restore. There's no internet connection!");
				return;
			}
			
			try
			{
				if (CloudStorage.isSupported)
				{
					if (CloudStorage.service.documentStore.isSupported)
					{
						if (CloudStorage.service.documentStore.isAvailable)
						{
							//First let's check if a backup already exists.
							var databaseFile:Document;
							CloudStorage.service.documentStore.update();
							var documents:Vector.<Document> = CloudStorage.service.documentStore.listDocuments();
							for each (var document:Document in documents)
							{
								if (document.filename.indexOf(ModelLocator.IS_IPAD ? "database/spike-ipad.db" : "database/spike.db") != -1)
								{
									//Found Spike's database!
									databaseFile = document;
									break;
								}
							}
							
							if (databaseFile != null)
							{
								CloudStorage.service.documentStore.addEventListener( DocumentEvent.LOAD_COMPLETE, onDocumentLoadComplete );
								CloudStorage.service.documentStore.addEventListener( DocumentEvent.LOAD_ERROR, onDocumentLoadError );
								
								CloudStorage.service.documentStore.loadDocument( databaseFile.filename );
							}
							else 
							{
								Trace.myTrace("ICloudService.as", "Remote database not found!");
								CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_ICLOUD_BACKUP_LAST_PERFORMED, "0");
								_instance.dispatchEvent( new ICloudEvent(ICloudEvent.REMOTE_DATABASE_NOT_FOUND) );
							}
						}
						else
						{
							Trace.myTrace("ICloudService.as", "iCloud document storage not available!");
							_instance.dispatchEvent( new ICloudEvent(ICloudEvent.ICLOUD_STORAGE_NOT_AVAILABLE) );
						}
					}
					else
					{
						Trace.myTrace("ICloudService.as", "iCloud storage is not supported in this device!");
						_instance.dispatchEvent( new ICloudEvent(ICloudEvent.ICLOUD_STORAGE_NOT_SUPPORTED) );
					}
				}
				else
				{
					Trace.myTrace("ICloudService.as", "iCloud storage is not supported in this device!");
					_instance.dispatchEvent( new ICloudEvent(ICloudEvent.ICLOUD_STORAGE_NOT_SUPPORTED) );
				}
			}
			catch (e:Error)
			{
				Trace.myTrace("ICloudService.as", "An uknown iCloud error has ocurred! Error: " + e.message);
				_instance.dispatchEvent( new ICloudEvent(ICloudEvent.ICLOUD_UNKNOWN_ERROR, false, false, e.message) );
			}
		}
			
		/**
		 * Event Listeners
		 */
		private static function onDocumentStoreSaveComplete( event:DocumentEvent ):void
		{
			Trace.myTrace("ICloudService.as", "Database successfully saved to iCloud!");
			
			//Clear event listeners
			CloudStorage.service.documentStore.removeEventListener( DocumentEvent.SAVE_COMPLETE, onDocumentStoreSaveComplete );
			CloudStorage.service.documentStore.removeEventListener( DocumentEvent.SAVE_ERROR, onDocumentStoreSaveError );
			
			//Clear database from memory
			if (localDatabaseData != null)
			{
				localDatabaseData.clear();
				localDatabaseData = null;
			}
			
			//Update local database
			if (!appHalted)
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_ICLOUD_BACKUP_LAST_PERFORMED, String(new Date().valueOf()));
			
			//Dispatch event
			_instance.dispatchEvent( new ICloudEvent(ICloudEvent.DATABASE_SAVED_SUCCESSFULLY) );
		}
		
		private static function onDocumentStoreSaveError( event:DocumentEvent ):void
		{
			Trace.myTrace("ICloudService.as", "An uknown iCloud error has ocurred! Error: " + event.error);
			
			//Clear events
			CloudStorage.service.documentStore.removeEventListener( DocumentEvent.SAVE_COMPLETE, onDocumentStoreSaveComplete );
			CloudStorage.service.documentStore.removeEventListener( DocumentEvent.SAVE_ERROR, onDocumentStoreSaveError );
			
			//Notify listeners
			_instance.dispatchEvent( new ICloudEvent(ICloudEvent.ERROR_SAVING_DATABASE, false, false, event.error) );
		}
		
		private static function onDocumentLoadComplete( event:DocumentEvent ):void
		{
			Trace.myTrace("ICloudService.as", "Document load complete!");
			
			CloudStorage.service.documentStore.removeEventListener( DocumentEvent.LOAD_COMPLETE, onDocumentLoadComplete );
			CloudStorage.service.documentStore.removeEventListener( DocumentEvent.LOAD_ERROR, onDocumentLoadError );
			
			if (event.document && event.document.data)
			{
				Trace.myTrace("ICloudService.as", "Database last modified: " + event.document.modifiedDate.toLocaleString());
				
				//Save database for later restore
				if (remoteDatabaseData != null)
				{
					remoteDatabaseData.clear();
					remoteDatabaseData = null;
				}
				remoteDatabaseData = event.document.data;
				
				//Uncompress database
				remoteDatabaseData.uncompress(CompressionAlgorithm.ZLIB);
				
				//Notify ANE
				SpikeANE.performDatabaseResetActions();
				
				//Halt Spike
				Trace.myTrace("ICloudService.as", "Halting Spike...");
				appHalted = true;
				Database.instance.addEventListener(DatabaseEvent.DATABASE_CLOSED_EVENT, onLocalDatabaseClosed);
				Spike.haltApp();
			}
			else
			{
				Trace.myTrace("ICloudService.as", "Error loading database! File seems to be empty.");
				_instance.dispatchEvent( new ICloudEvent(ICloudEvent.ERROR_LOADING_DATABASE, false, false, ModelLocator.resourceManagerInstance.getString('icloudservice','empty_icloud_database_label')) );
			}
		}
		
		private static function onLocalDatabaseClosed(e:DatabaseEvent):void
		{
			Trace.myTrace("ICloudService.as", "Spike halted and local database connection closed!");
			
			//Restore database
			var databaseTargetFile:File = File.applicationStorageDirectory.resolvePath("spike.db");
			var databaseFileStream:FileStream = new FileStream();
			databaseFileStream.open(databaseTargetFile, FileMode.WRITE);
			databaseFileStream.writeBytes(remoteDatabaseData, 0, remoteDatabaseData.length);
			databaseFileStream.close();
			
			//Clear database from memory
			if (remoteDatabaseData != null)
			{
				remoteDatabaseData.clear();
				remoteDatabaseData = null;
			}
			
			//Notify listeners
			Trace.myTrace("ICloudService.as", "Database successfully restored!");
			_instance.dispatchEvent( new ICloudEvent(ICloudEvent.DATABASE_RESTORED_SUCCESSFULLY) );
		}
		
		private static function onDocumentLoadError( event:DocumentEvent ):void
		{
			Trace.myTrace("ICloudService.as", "Error loading document!");
			
			CloudStorage.service.documentStore.removeEventListener( DocumentEvent.LOAD_COMPLETE, onDocumentLoadComplete );
			CloudStorage.service.documentStore.removeEventListener( DocumentEvent.LOAD_ERROR, onDocumentLoadError );
			
			//Notify listeners
			_instance.dispatchEvent( new ICloudEvent(ICloudEvent.ERROR_LOADING_DATABASE, false, false, event.error) );
		}
			
		private static function onDocumentStoreConflict( event:DocumentStoreEvent ):void
		{
			Trace.myTrace("ICloudService.as", "A conflict was found with the iCloud version of the database!");
			
			_instance.dispatchEvent( new ICloudEvent(ICloudEvent.ICLOUD_CONFLICT_ERROR) );
		}
		
		private static function onBgReadingReceived(e:Event):void
		{
			//Validation
			if (appHalted || (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_ICLOUD_BACKUP_SCHEDULER_WIFI_ONLY) == "true" && NetworkInfo.networkInfo.isWWAN()))
				return;
			
			var now:Number = new Date().valueOf();
			var currentSchedule:Number = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_ICLOUD_BACKUP_SCHEDULER_TIMESPAN));
			if (currentSchedule == 0)
			{
				TransmitterService.instance.removeEventListener(TransmitterServiceEvent.LAST_BGREADING_RECEIVED, onBgReadingReceived);
				NightscoutService.instance.removeEventListener(FollowerEvent.BG_READING_RECEIVED, onBgReadingReceived);
				return;
			}
			var lastBackup:Number = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_ICLOUD_BACKUP_LAST_PERFORMED));
			
			if (now - lastBackup >= currentSchedule)
			{
				Trace.myTrace("ICloudService.as", "Performing automatic database iCloud backup...");
				backupDatabase();
			}
		}
		
		private static function onSettingsChanged(event:SettingsServiceEvent):void 
		{
			//Validation
			if (appHalted)
				return;
			
			if (event.data == CommonSettings.COMMON_SETTING_ICLOUD_BACKUP_SCHEDULER_TIMESPAN) 
			{
				var currentSchedule:Number = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_ICLOUD_BACKUP_SCHEDULER_TIMESPAN));
				if (!isNaN(currentSchedule) && currentSchedule > 0)
				{
					var timeSpan:String = "";
					if (currentSchedule == TimeSpan.TIME_24_HOURS)
						timeSpan = "daily";
					else if (currentSchedule == 7 * TimeSpan.TIME_24_HOURS)
						timeSpan = "weekly";
					else if (currentSchedule == 30 * TimeSpan.TIME_24_HOURS)
						timeSpan = "monthly";
					
					Trace.myTrace("ICloudService.as", "Setting automatic database iCloud backups to " + timeSpan);
					TransmitterService.instance.addEventListener(TransmitterServiceEvent.LAST_BGREADING_RECEIVED, onBgReadingReceived, false, -1000, true);
					NightscoutService.instance.addEventListener(FollowerEvent.BG_READING_RECEIVED, onBgReadingReceived, false, -1000, true);
				}
				else
				{
					Trace.myTrace("ICloudService.as", "Deactivating automatic iCloud backups...");
					TransmitterService.instance.removeEventListener(TransmitterServiceEvent.LAST_BGREADING_RECEIVED, onBgReadingReceived);
					NightscoutService.instance.removeEventListener(FollowerEvent.BG_READING_RECEIVED, onBgReadingReceived);
				}
			}
		}

		/**
		 * Getters & Setters
		 */
		public static function get instance():ICloudService
		{
			return _instance;
		}
	}
}