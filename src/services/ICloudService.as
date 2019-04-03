package services
{
	import com.distriqt.extension.cloudstorage.CloudStorage;
	import com.distriqt.extension.cloudstorage.documents.Document;
	import com.distriqt.extension.cloudstorage.events.DocumentEvent;
	import com.distriqt.extension.cloudstorage.events.DocumentStoreEvent;
	import com.distriqt.extension.networkinfo.NetworkInfo;
	import com.spikeapp.spike.airlibrary.SpikeANE;
	
	import flash.events.EventDispatcher;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.text.engine.LineJustification;
	import flash.text.engine.SpaceJustifier;
	import flash.utils.ByteArray;
	import flash.utils.CompressionAlgorithm;
	import flash.utils.getTimer;
	import flash.utils.setTimeout;
	
	import database.CommonSettings;
	import database.Database;
	import database.LocalSettings;
	
	import distriqtkey.DistriqtKey;
	
	import events.DatabaseEvent;
	import events.FollowerEvent;
	import events.ICloudEvent;
	import events.SettingsServiceEvent;
	import events.TransmitterServiceEvent;
	
	import feathers.controls.Alert;
	import feathers.controls.text.TextBlockTextRenderer;
	import feathers.core.ITextRenderer;
	import feathers.core.PopUpManager;
	import feathers.data.ListCollection;
	import feathers.layout.HorizontalAlign;
	
	import model.ModelLocator;
	
	import starling.events.Event;
	
	import ui.popups.AlertManager;
	
	import utils.TimeSpan;
	import utils.Trace;
	
	[ResourceBundle("icloudservice")]
	[ResourceBundle("globaltranslations")]
	[ResourceBundle("maintenancesettingsscreen")]
	
	public class ICloudService extends EventDispatcher
	{
		//Objects & Properties
		private static var _instance:ICloudService = new ICloudService();
		private static var localDatabaseData:ByteArray;
		private static var remoteDatabaseData:ByteArray;
		private static var appHalted:Boolean = false;
		public static var serviceStartedAt:int = 0;
		
		public function ICloudService()
		{
			if (_instance != null)
				throw new Error("ICloudService is not meant to be instantiated");
		}
		
		public static function init():void
		{
			serviceStartedAt = getTimer();
			
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
							
							//Check if it's a new install and an iCloud backup is available
							setTimeout(checkExistingBackup, TimeSpan.TIME_10_SECONDS);
							
							CommonSettings.instance.addEventListener(SettingsServiceEvent.SETTING_CHANGED, onSettingsChanged);
							
							var currentSchedule:Number = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_ICLOUD_BACKUP_SCHEDULER_TIMESPAN));
							if (!isNaN(currentSchedule) && currentSchedule > 0)
							{
								Trace.myTrace("ICloudService.as", "Automatic iCloud backups are enabled.");
								TransmitterService.instance.addEventListener(TransmitterServiceEvent.LAST_BGREADING_RECEIVED, onBgReadingReceived, false, -1000, true);
								NightscoutService.instance.addEventListener(FollowerEvent.BG_READING_RECEIVED, onBgReadingReceived, false, -1000, true);
								DexcomShareService.instance.addEventListener(FollowerEvent.BG_READING_RECEIVED, onBgReadingReceived, false, -1000, true);
							}
							else
								Trace.myTrace("ICloudService.as", "Automatic iCloud backups are disabled.");
						}
						else
							Trace.myTrace("ICloudService.as", "Error activating iCloud storage!");
					}
				}
				
				//Check for non-optimal iCloud backup settings
				setTimeout(checkAutomaticBackupSchedule, TimeSpan.TIME_3_HOURS);
			} 
			catch(error:Error) 
			{
				Trace.myTrace("ICloudService.as", "Error activating iCloud storage!");
			}
		}
		
		private static function checkExistingBackup():void
		{
			if (ModelLocator.bgReadings != null && ModelLocator.bgReadings.length > 0)
			{
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_STOCK_DATABASE, "false", true, false);
			}
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_STOCK_DATABASE) == "true" && NetworkInfo.networkInfo.isReachable())
			{
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_STOCK_DATABASE, "false", true, false);
				
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
									CloudStorage.service.documentStore.addEventListener( DocumentEvent.LOAD_COMPLETE, onInitialBackupLoadComplete );
									CloudStorage.service.documentStore.addEventListener( DocumentEvent.LOAD_ERROR, onInitialBackupLoadError );
									
									CloudStorage.service.documentStore.loadDocument( databaseFile.filename );
								}
							}
						}
					}
				}
				catch (e:Error) {}
			}
		}
		
		private static function onInitialBackupLoadComplete( event:DocumentEvent ):void
		{
			CloudStorage.service.documentStore.removeEventListener( DocumentEvent.LOAD_COMPLETE, onInitialBackupLoadComplete );
			CloudStorage.service.documentStore.removeEventListener( DocumentEvent.LOAD_ERROR, onInitialBackupLoadError );
			
			if (event.document && event.document.data)
			{
				if (new Date().valueOf() - event.document.modifiedDate.valueOf() <= TimeSpan.TIME_1_WEEK)
				{
					//Save database for later restore
					if (remoteDatabaseData != null)
					{
						remoteDatabaseData.clear();
						remoteDatabaseData = null;
					}
					remoteDatabaseData = event.document.data;
					
					//Uncompress database
					remoteDatabaseData.uncompress(CompressionAlgorithm.ZLIB);
					
					//Load local database
					var localDB:File = File.documentsDirectory.resolvePath("spike.db");
					
					if (localDB != null && localDB.size < remoteDatabaseData.length)
					{
						var alert:Alert = AlertManager.showActionAlert
						(
							ModelLocator.resourceManagerInstance.getString('globaltranslations', "info_alert_title"),
							ModelLocator.resourceManagerInstance.getString('icloudservice', "recent_icloud_backup_found_message"),
							Number.NaN,
							[
								{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations', "no_uppercase") },
								{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations', "yes_uppercase"), triggered: onRestoreInitialDatabase }	
							]
						);
						alert.buttonGroupProperties.gap = 0;
						alert.buttonGroupProperties.horizontalAlign = HorizontalAlign.CENTER;
						
						function onRestoreInitialDatabase(e:starling.events.Event):void
						{
							//Notify ANE
							SpikeANE.setDatabaseResetStatus(true);
							
							//Halt Spike
							Trace.myTrace("ICloudService.as", "Halting Spike...");
							appHalted = true;
							_instance.addEventListener(ICloudEvent.DATABASE_RESTORED_SUCCESSFULLY, onDatabaseRestoredSuccessfully);
							Database.instance.addEventListener(DatabaseEvent.DATABASE_CLOSED_EVENT, onLocalDatabaseClosed);
							Spike.haltApp();
						}
					}
				}
			}
		}
		
		private static function onInitialBackupLoadError( event:DocumentEvent ):void
		{
			CloudStorage.service.documentStore.removeEventListener( DocumentEvent.LOAD_COMPLETE, onInitialBackupLoadComplete );
			CloudStorage.service.documentStore.removeEventListener( DocumentEvent.LOAD_ERROR, onInitialBackupLoadError );
		}
		
		private static function onDatabaseRestoredSuccessfully(e:ICloudEvent):void
		{
			_instance.removeEventListener(ICloudEvent.DATABASE_RESTORED_SUCCESSFULLY, onDatabaseRestoredSuccessfully);
			
			var alert:Alert = new Alert();
			alert.title = ModelLocator.resourceManagerInstance.getString('globaltranslations','success_alert_title');
			alert.message = ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','restore_successfull_label');
			alert.buttonsDataProvider = new ListCollection(
				[
					{ label: ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','terminate_spike_button_label'), triggered: onTerminateSpike }
				]
			);
			
			alert.messageFactory = function():ITextRenderer
			{
				var messageRenderer:TextBlockTextRenderer = new TextBlockTextRenderer();
				messageRenderer.textJustifier = new SpaceJustifier( "en", LineJustification.ALL_BUT_MANDATORY_BREAK);
				
				return messageRenderer;
			};
			
			PopUpManager.removeAllPopUps();
			PopUpManager.addPopUp(alert);
			
			function onTerminateSpike(e:Event):void
			{
				SpikeANE.terminateApp();
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
							var localDatabaseFile:File = File.documentsDirectory.resolvePath("spike.db");
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
		 * Private Methods
		 */
		private static function checkAutomaticBackupSchedule ():void
		{
			if ((CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_USER_WARNED_OF_NON_OPTIMAL_ICLOUD_BACKUP_SCHEDULE) == "false") && (Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_ICLOUD_BACKUP_SCHEDULER_TIMESPAN)) != 0.5 * TimeSpan.TIME_24_HOURS))
			{
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_USER_WARNED_OF_NON_OPTIMAL_ICLOUD_BACKUP_SCHEDULE, "true", true, false);
				
				AlertManager.showSimpleAlert
				(
					ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
					ModelLocator.resourceManagerInstance.getString('icloudservice','non_optimal_backup_settings_warning_message')
				);
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
				SpikeANE.setDatabaseResetStatus(true);
				
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
			var databaseTargetFile:File = File.documentsDirectory.resolvePath("spike.db");
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
		
		private static function onBgReadingReceived(e:flash.events.Event):void
		{
			//Validation
			if (appHalted || (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_ICLOUD_BACKUP_SCHEDULER_WIFI_ONLY) == "true" && NetworkInfo.networkInfo.isWWAN()) || (getTimer() - serviceStartedAt < TimeSpan.TIME_30_MINUTES))
				return;
			
			var now:Number = new Date().valueOf();
			var currentSchedule:Number = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_ICLOUD_BACKUP_SCHEDULER_TIMESPAN));
			if (currentSchedule == 0)
			{
				TransmitterService.instance.removeEventListener(TransmitterServiceEvent.LAST_BGREADING_RECEIVED, onBgReadingReceived);
				NightscoutService.instance.removeEventListener(FollowerEvent.BG_READING_RECEIVED, onBgReadingReceived);
				DexcomShareService.instance.removeEventListener(FollowerEvent.BG_READING_RECEIVED, onBgReadingReceived);
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
					if (currentSchedule == 0.5 * TimeSpan.TIME_24_HOURS)
						timeSpan = "twice-daily";
					else if (currentSchedule == TimeSpan.TIME_24_HOURS)
						timeSpan = "daily";
					else if (currentSchedule == 7 * TimeSpan.TIME_24_HOURS)
						timeSpan = "weekly";
					else if (currentSchedule == 30 * TimeSpan.TIME_24_HOURS)
						timeSpan = "monthly";
					
					Trace.myTrace("ICloudService.as", "Setting automatic database iCloud backups to " + timeSpan);
					TransmitterService.instance.addEventListener(TransmitterServiceEvent.LAST_BGREADING_RECEIVED, onBgReadingReceived, false, -1000, true);
					NightscoutService.instance.addEventListener(FollowerEvent.BG_READING_RECEIVED, onBgReadingReceived, false, -1000, true);
					DexcomShareService.instance.addEventListener(FollowerEvent.BG_READING_RECEIVED, onBgReadingReceived, false, -1000, true);
				}
				else
				{
					Trace.myTrace("ICloudService.as", "Deactivating automatic iCloud backups...");
					TransmitterService.instance.removeEventListener(TransmitterServiceEvent.LAST_BGREADING_RECEIVED, onBgReadingReceived);
					NightscoutService.instance.removeEventListener(FollowerEvent.BG_READING_RECEIVED, onBgReadingReceived);
					DexcomShareService.instance.removeEventListener(FollowerEvent.BG_READING_RECEIVED, onBgReadingReceived);
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