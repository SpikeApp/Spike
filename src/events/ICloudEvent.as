package events
{
	import flash.events.Event;

	public class ICloudEvent extends Event
	{
		[Event(name="databaseSavedSuccessfully",type="events.ICloudEvent")]
		[Event(name="databaseRestoredSuccessfully",type="events.ICloudEvent")]
		[Event(name="errorSavingDatabase",type="events.ICloudEvent")]
		[Event(name="errorLoadingDatabase",type="events.ICloudEvent")]
		[Event(name="remoteDatabaseNotFound",type="events.ICloudEvent")]
		[Event(name="localDatabaseNotFound",type="events.ICloudEvent")]
		[Event(name="iCloudStorageNotSupported",type="events.ICloudEvent")]
		[Event(name="iCloudStorageNotAvailable",type="events.ICloudEvent")]
		[Event(name="iCloudUnknownError",type="events.ICloudEvent")]
		[Event(name="iCloudConflictError",type="events.ICloudEvent")]
		
		public static const DATABASE_SAVED_SUCCESSFULLY:String = "databaseSavedSuccessfully";
		public static const DATABASE_RESTORED_SUCCESSFULLY:String = "databaseRestoredSuccessfully";
		public static const ERROR_SAVING_DATABASE:String = "errorSavingDatabase";
		public static const ERROR_LOADING_DATABASE:String = "errorLoadingDatabase";
		public static const REMOTE_DATABASE_NOT_FOUND:String = "remoteDatabaseNotFound";
		public static const LOCAL_DATABASE_NOT_FOUND:String = "localDatabaseNotFound";
		public static const ICLOUD_STORAGE_NOT_SUPPORTED:String = "iCloudStorageNotSupported";
		public static const ICLOUD_STORAGE_NOT_AVAILABLE:String = "iCloudStorageNotAvailable";
		public static const ICLOUD_UNKNOWN_ERROR:String = "iCloudUnknownError";
		public static const ICLOUD_CONFLICT_ERROR:String = "iCloudConflictError";
		
		public var data:Object;
		
		public function ICloudEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false, data:Object = null) 
		{
			super(type, bubbles, cancelable);
			
			this.data = data;
		}
	}
}