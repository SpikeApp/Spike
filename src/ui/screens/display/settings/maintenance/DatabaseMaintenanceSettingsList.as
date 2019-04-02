package ui.screens.display.settings.maintenance
{
	import com.distriqt.extension.networkinfo.NetworkInfo;
	import com.spikeapp.spike.airlibrary.SpikeANE;
	
	import flash.display.StageOrientation;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.text.engine.LineJustification;
	import flash.text.engine.SpaceJustifier;
	import flash.utils.ByteArray;
	
	import spark.formatters.DateTimeFormatter;
	
	import database.CommonSettings;
	
	import events.ICloudEvent;
	
	import feathers.controls.Alert;
	import feathers.controls.Button;
	import feathers.controls.Check;
	import feathers.controls.Label;
	import feathers.controls.LayoutGroup;
	import feathers.controls.PickerList;
	import feathers.controls.popups.DropDownPopUpContentManager;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.controls.text.TextBlockTextRenderer;
	import feathers.core.ITextRenderer;
	import feathers.core.PopUpManager;
	import feathers.data.ArrayCollection;
	import feathers.data.ListCollection;
	import feathers.extensions.MaterialDesignSpinner;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.HorizontalLayout;
	import feathers.layout.VerticalAlign;
	import feathers.layout.VerticalLayout;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import org.aszip.compression.CompressionMethod;
	import org.aszip.saving.Method;
	import org.aszip.zip.ASZip;
	
	import services.ICloudService;
	
	import starling.events.Event;
	import starling.events.ResizeEvent;
	
	import ui.popups.AlertManager;
	import ui.popups.EmailFileSender;
	import ui.screens.display.LayoutFactory;
	import ui.screens.display.SpikeList;
	
	import utils.Constants;
	import utils.DeviceInfo;
	import utils.TimeSpan;
	
	[ResourceBundle("maintenancesettingsscreen")]
	[ResourceBundle("globaltranslations")]
	
	public class DatabaseMaintenanceSettingsList extends SpikeList
	{
		/* Display Objects */
		private var backupButton:Button;
		private var restoreButton:Button;
		private var actionsContainer:LayoutGroup;
		private var preloader:MaterialDesignSpinner;
		private var preloaderContainer:LayoutGroup;
		private var backupScheduler:PickerList;
		private var lastBackupLabel:Label;
		private var instructionsLabel:Label;
		private var wifiOnlyCheck:Check;
		private var emailDatabaseButton:Button;
		
		/* Properties */
		private var isLoading:Boolean = false;
		private var dateFormatterForBackupDate:DateTimeFormatter;
		private var wifiOnlyValue:Boolean;

		public function DatabaseMaintenanceSettingsList()
		{
			super(true);
			
			setupProperties();
			setupInitialContent();
			setupContent();
		}
		
		/**
		 * Functionality
		 */
		private function setupProperties():void
		{
			//Set Properties
			clipContent = false;
			isSelectable = false;
			autoHideBackground = true;
			hasElasticEdges = false;
			paddingBottom = 5;
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
		}
		
		private function setupInitialContent():void
		{
			//Set date formatter
			dateFormatterForBackupDate = new DateTimeFormatter();
			dateFormatterForBackupDate.dateTimePattern = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_DATE_FORMAT).slice(0,2) == "24" ? "dd MMM HH:mm" : "dd MMM h:mm a";
			dateFormatterForBackupDate.useUTC = false;
			dateFormatterForBackupDate.setStyle("locale", Constants.getUserLocale());
			
			//Get settings
			wifiOnlyValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_ICLOUD_BACKUP_SCHEDULER_WIFI_ONLY) == "true";
		}
		
		private function setupContent():void
		{
			//Actions Container
			var actionsLayout:HorizontalLayout = new HorizontalLayout();
			actionsLayout.horizontalAlign = HorizontalAlign.RIGHT;
			actionsLayout.gap = 5;
			actionsContainer = new LayoutGroup();
			actionsContainer.layout = actionsLayout;
			
			//Restore Button
			restoreButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','restore_button_label'));
			restoreButton.addEventListener(starling.events.Event.TRIGGERED, onRestoreDatabase);
			actionsContainer.addChild(restoreButton);
			
			//Backup Button
			backupButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','backup_button_label'));
			backupButton.addEventListener(starling.events.Event.TRIGGERED, onBackupDatabase);
			actionsContainer.addChild(backupButton);
			
			//Email Button
			emailDatabaseButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','send_database_email_button_label'));
			emailDatabaseButton.addEventListener(starling.events.Event.TRIGGERED, onEmailDatabase);
			
			//Schedule
			backupScheduler = LayoutFactory.createPickerList();
			var backupSchedulerDataProvider:ArrayCollection = new ArrayCollection();
			backupSchedulerDataProvider.push( { label: ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','no_automatic_backup_label'), timespan: 0 } );
			backupSchedulerDataProvider.push( { label: ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','twice_daily_backup_label'), timespan: 0.5 * TimeSpan.TIME_24_HOURS } );
			backupSchedulerDataProvider.push( { label: ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','daily_backup_label'), timespan: TimeSpan.TIME_24_HOURS } );
			backupSchedulerDataProvider.push( { label: ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','weekly_backup_label'), timespan: 7 * TimeSpan.TIME_24_HOURS } );
			backupSchedulerDataProvider.push( { label: ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','monthly_backup_label'), timespan: 30 * TimeSpan.TIME_24_HOURS } );
			backupScheduler.dataProvider = backupSchedulerDataProvider;
			backupScheduler.popUpContentManager = new DropDownPopUpContentManager();
			backupScheduler.addEventListener(Event.CHANGE, onBackupSchedulerChanged);
			backupScheduler.itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "label";
				itemRenderer.paddingRight = 10;
				itemRenderer.paddingLeft = 10;
				return itemRenderer;
			};
			var selectedIndex:int = 0;
			var currentSchedule:Number = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_ICLOUD_BACKUP_SCHEDULER_TIMESPAN));
			for (var i:int = 0; i < backupSchedulerDataProvider.length; i++) 
			{
				var tempSchedule:Number = backupSchedulerDataProvider.arrayData[i].timespan;
				if (tempSchedule == currentSchedule)
				{
					selectedIndex = i;
					break;
				}
			}
			backupScheduler.selectedIndex = selectedIndex;
			
			//Wi-Fi Only
			wifiOnlyCheck = LayoutFactory.createCheckMark(wifiOnlyValue);
			wifiOnlyCheck.pivotX = 3;
			wifiOnlyCheck.addEventListener(Event.CHANGE, onWifiOnly);
			
			//Backup label
			lastBackupLabel = LayoutFactory.createLabel("", HorizontalAlign.RIGHT, VerticalAlign.TOP, 10);
			lastBackupLabel.paddingRight = 3;
			
			//Preloader
			preloaderContainer = new LayoutGroup();
			preloaderContainer.pivotX = -15;
			
			preloader = new MaterialDesignSpinner();
			preloader.color = 0x0086FF;
			preloader.touchable = false;
			preloader.scale = 0.6;
			preloaderContainer.addChild(preloader);
			preloader.validate();
			preloaderContainer.validate();
			preloader.y += 10;
			
			//Instructions
			instructionsLabel = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','database_backup_restore_explanation_label'), HorizontalAlign.JUSTIFY, VerticalAlign.TOP);
			instructionsLabel.width = width;
			instructionsLabel.wordWrap = true;
			instructionsLabel.paddingTop = instructionsLabel.paddingBottom = 10;
			
			refreshContent();
		}
		
		private function refreshContent():void
		{
			//Get last backup date
			var lastBackupTimestamp:String = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_ICLOUD_BACKUP_LAST_PERFORMED);
			if (lastBackupTimestamp == "0" || lastBackupTimestamp == "")
			{
				lastBackupLabel.text = ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','last_backup_label') + ": " + ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available');
			}
			else
			{
				var nowDate:Date = new Date();
				var lastBackupDate:Date = new Date(Number(lastBackupTimestamp));
				
				if (nowDate.fullYear - lastBackupDate.fullYear > 1)
				{
					lastBackupLabel.text = ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','last_backup_label') + ": " + ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available');
				}
				else
				{	
					lastBackupLabel.text = ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','last_backup_label') + ": " + dateFormatterForBackupDate.format(lastBackupDate);
				}
			}
			
			//Set Data
			var data:Array = [];
			data.push( { label: ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','schedule_backups_label'), accessory: backupScheduler } );
			data.push( { label: ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','automatic_backups_only_on_wifi_label'), accessory: wifiOnlyCheck } );
			data.push( { label: ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','icloud_actions_label'), accessory: actionsContainer } );
			data.push( { label: ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','email_actions_label'), accessory: emailDatabaseButton } );
			if (isLoading)
				data.push( { label: ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','status_label'), accessory: preloaderContainer } );
			data.push( { label: "", accessory: lastBackupLabel } );
			data.push( { label: "", accessory: instructionsLabel } );
			
			dataProvider = new ArrayCollection( data );
		}
		
		/**
		 * Event Listeners
		 */
		private function onEmailDatabase(e:starling.events.Event):void
		{
			if(emailDatabaseButton != null)
				emailDatabaseButton.isEnabled = false;
			
			var fileToSend:*;
			var fileName:String;
			var mimeType:String;
			
			var db:File = File.documentsDirectory.resolvePath("spike.db");
			//If database is bigger than 14mb, zip it efore sending it.
			if (db.size > 14000000)
			{
				//Create Stream
				var fileStream:FileStream = new FileStream();
				fileStream.open(db, FileMode.READ);
				
				//Read trace log raw bytes into memory
				var dbBytes:ByteArray = new ByteArray();
				fileStream.readBytes(dbBytes);
				fileStream.close();
				
				//Compress
				var zip:ASZip = new ASZip(CompressionMethod.GZIP);
				zip.addFile(dbBytes, "spike.db");
				var myZipFile:ByteArray = zip.saveZIP( Method.LOCAL );
				
				fileToSend = myZipFile;
				fileName = "spike.zip";
				mimeType = "application/zip";
			}
			else
			{
				fileToSend = db;
				fileName = "spike.db";
				mimeType = "application/x-sqlite3";
			}
			
			EmailFileSender.instance.addEventListener(Event.COMPLETE, onFileSenderClosed);
			EmailFileSender.instance.addEventListener(Event.CANCEL, onFileSenderClosed);
			EmailFileSender.sendFile
			(
				ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','database_email_subject'),
				ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','database_email_body'),
				fileName,
				fileToSend,
				mimeType,
				ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','database_email_success_message'),
				ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','database_email_error_message'),
				ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','missing_local_database_label')
			);
		}
		
		private function onFileSenderClosed(e:starling.events.Event):void
		{
			EmailFileSender.instance.removeEventListener(Event.COMPLETE, onFileSenderClosed);
			EmailFileSender.instance.removeEventListener(Event.CANCEL, onFileSenderClosed);
			
			if (emailDatabaseButton != null)
				emailDatabaseButton.isEnabled = true;
		}
		
		private function onBackupDatabase(e:starling.events.Event):void
		{
			if (!NetworkInfo.networkInfo.isReachable())
			{
				AlertManager.showSimpleAlert
				(
					ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
					ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','no_internet_connection_backup_label')
				);
				
				return;
			}
			
			showPreloader();
			activateBackupEventListeners();
			ICloudService.backupDatabase();
		}
		
		private function onRestoreDatabase(e:starling.events.Event):void
		{
			if (!NetworkInfo.networkInfo.isReachable())
			{
				AlertManager.showSimpleAlert
				(
					ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
					ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','no_internet_connection_restore_label')
				);
				
				return;
			}
			
			var alert:Alert = AlertManager.showActionAlert
			(
				ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
				ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','database_restore_confirmation_label'),
				Number.NaN,
				[
					{ label: ModelLocator.resourceManagerInstance.getString("globaltranslations","no_uppercase")  },	
					{ label: ModelLocator.resourceManagerInstance.getString("globaltranslations","yes_uppercase"), triggered: restoreDatabase }	
				],
				HorizontalAlign.JUSTIFY
			);
			alert.buttonGroupProperties.gap = 10;
			alert.buttonGroupProperties.horizontalAlign = HorizontalAlign.CENTER;
			
			function restoreDatabase(e:Event):void
			{
				showPreloader();
				activateRestoreEventListeners();
				ICloudService.restoreDatabase();
			}
		}
		
		private function onDatabaseSavedSuccessfully(e:ICloudEvent):void
		{
			hidePreloader();
			deactivateBackupEventListeners();
			
			AlertManager.showSimpleAlert
			(
				ModelLocator.resourceManagerInstance.getString('globaltranslations','success_alert_title'),
				ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','backup_successfull_label')
			);
		}
		
		private function onDatabaseRestoredSuccessfully(e:ICloudEvent):void
		{
			hidePreloader();
			deactivateRestoreEventListeners();
			
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
		
		private function onErrorSavingDatabase(e:ICloudEvent):void
		{
			hidePreloader();
			deactivateBackupEventListeners();
			
			AlertManager.showSimpleAlert
			(
				ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
				ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','error_saving_database_label') + " " + String(e.data)
			);
		}
		
		private function onErrorLoadingDatabase(e:ICloudEvent):void
		{
			hidePreloader();
			deactivateRestoreEventListeners();
			
			AlertManager.showSimpleAlert
			(
				ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
				ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','error_loading_database_label') + " " + String(e.data)
			);
		}
		
		private function onLocalDatabaseNotFound(e:ICloudEvent):void
		{
			hidePreloader();
			deactivateBackupEventListeners();
		
			AlertManager.showSimpleAlert
			(
				ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
				ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','missing_local_database_label')
			);
		}
		
		private function onICloudStorageNotAvailable(e:ICloudEvent):void
		{
			hidePreloader();
			deactivateBackupEventListeners();
			deactivateRestoreEventListeners();
			
			AlertManager.showSimpleAlert
			(
				ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
				ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','icloud_storage_not_available')
			);
		}
		
		private function onICloudStorageNotSupported(e:ICloudEvent):void
		{
			hidePreloader();
			deactivateBackupEventListeners();
			deactivateRestoreEventListeners();
			
			AlertManager.showSimpleAlert
			(
				ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
				ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','icloud_storage_not_supported')
			);
		}
		
		private function onUnknownICloudError(e:ICloudEvent):void
		{
			hidePreloader();
			deactivateBackupEventListeners();
			deactivateRestoreEventListeners();
			
			AlertManager.showSimpleAlert
			(
				ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
				ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','unknown_icloud_error_label') + " " + String(e.data)
			);
		}
		
		private function onFileConflict(e:ICloudEvent):void
		{
			hidePreloader();
			deactivateBackupEventListeners();
			deactivateRestoreEventListeners();
			
			AlertManager.showSimpleAlert
			(
				ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
				ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','icloud_conflict_error_label')
			);
		}
		
		private function onRemoteDatabaseNotFound(e:ICloudEvent):void
		{
			hidePreloader();
			deactivateRestoreEventListeners();
			
			AlertManager.showSimpleAlert
			(
				ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
				ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','missing_remote_database_label')
			);
		}
		
		private function onBackupSchedulerChanged(e:Event):void
		{
			CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_ICLOUD_BACKUP_SCHEDULER_TIMESPAN, String(backupScheduler.selectedItem.timespan));
		}
		
		private function onWifiOnly(e:Event):void
		{
			CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_ICLOUD_BACKUP_SCHEDULER_WIFI_ONLY, String(wifiOnlyCheck.isSelected));
		}
		
		override protected function onStarlingResize(event:ResizeEvent):void 
		{
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
			
			if (instructionsLabel != null)
			{
				if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr && !Constants.isPortrait)
					instructionsLabel.width = width - (Constants.currentOrientation == StageOrientation.ROTATED_RIGHT ? 30 : 40);
			else
				instructionsLabel.width = width;
			}
			
			setupRenderFactory();
		}
		
		/**
		 * Helper Functions
		 */
		private function activateBackupEventListeners():void
		{
			ICloudService.instance.addEventListener(ICloudEvent.LOCAL_DATABASE_NOT_FOUND, onLocalDatabaseNotFound);
			ICloudService.instance.addEventListener(ICloudEvent.ICLOUD_STORAGE_NOT_AVAILABLE, onICloudStorageNotAvailable);
			ICloudService.instance.addEventListener(ICloudEvent.ICLOUD_STORAGE_NOT_SUPPORTED, onICloudStorageNotSupported);
			ICloudService.instance.addEventListener(ICloudEvent.ICLOUD_UNKNOWN_ERROR, onUnknownICloudError);
			ICloudService.instance.addEventListener(ICloudEvent.DATABASE_SAVED_SUCCESSFULLY, onDatabaseSavedSuccessfully);
			ICloudService.instance.addEventListener(ICloudEvent.ERROR_SAVING_DATABASE, onErrorSavingDatabase);
			ICloudService.instance.addEventListener(ICloudEvent.ICLOUD_CONFLICT_ERROR, onFileConflict);
		}
		
		private function deactivateBackupEventListeners():void
		{
			ICloudService.instance.removeEventListener(ICloudEvent.LOCAL_DATABASE_NOT_FOUND, onLocalDatabaseNotFound);
			ICloudService.instance.removeEventListener(ICloudEvent.ICLOUD_STORAGE_NOT_AVAILABLE, onICloudStorageNotAvailable);
			ICloudService.instance.removeEventListener(ICloudEvent.ICLOUD_STORAGE_NOT_SUPPORTED, onICloudStorageNotSupported);
			ICloudService.instance.removeEventListener(ICloudEvent.ICLOUD_UNKNOWN_ERROR, onUnknownICloudError);
			ICloudService.instance.removeEventListener(ICloudEvent.DATABASE_SAVED_SUCCESSFULLY, onDatabaseSavedSuccessfully);
			ICloudService.instance.removeEventListener(ICloudEvent.ERROR_SAVING_DATABASE, onErrorSavingDatabase);
			ICloudService.instance.removeEventListener(ICloudEvent.ICLOUD_CONFLICT_ERROR, onFileConflict);
		}
		
		private function activateRestoreEventListeners():void
		{
			ICloudService.instance.addEventListener(ICloudEvent.ICLOUD_STORAGE_NOT_AVAILABLE, onICloudStorageNotAvailable);
			ICloudService.instance.addEventListener(ICloudEvent.ICLOUD_STORAGE_NOT_SUPPORTED, onICloudStorageNotSupported);
			ICloudService.instance.addEventListener(ICloudEvent.ICLOUD_UNKNOWN_ERROR, onUnknownICloudError);
			ICloudService.instance.addEventListener(ICloudEvent.DATABASE_RESTORED_SUCCESSFULLY, onDatabaseRestoredSuccessfully);
			ICloudService.instance.addEventListener(ICloudEvent.ERROR_LOADING_DATABASE, onErrorLoadingDatabase);
			ICloudService.instance.addEventListener(ICloudEvent.ICLOUD_CONFLICT_ERROR, onFileConflict);
			ICloudService.instance.addEventListener(ICloudEvent.REMOTE_DATABASE_NOT_FOUND, onRemoteDatabaseNotFound);
		}
		
		private function deactivateRestoreEventListeners():void
		{
			ICloudService.instance.removeEventListener(ICloudEvent.ICLOUD_STORAGE_NOT_AVAILABLE, onICloudStorageNotAvailable);
			ICloudService.instance.removeEventListener(ICloudEvent.ICLOUD_STORAGE_NOT_SUPPORTED, onICloudStorageNotSupported);
			ICloudService.instance.removeEventListener(ICloudEvent.ICLOUD_UNKNOWN_ERROR, onUnknownICloudError);
			ICloudService.instance.removeEventListener(ICloudEvent.DATABASE_RESTORED_SUCCESSFULLY, onDatabaseRestoredSuccessfully);
			ICloudService.instance.removeEventListener(ICloudEvent.ERROR_LOADING_DATABASE, onErrorLoadingDatabase);
			ICloudService.instance.removeEventListener(ICloudEvent.ICLOUD_CONFLICT_ERROR, onFileConflict);
			ICloudService.instance.removeEventListener(ICloudEvent.REMOTE_DATABASE_NOT_FOUND, onRemoteDatabaseNotFound);
		}
		
		private function showPreloader():void
		{
			isLoading = true;
			refreshContent();
		}
		
		private function hidePreloader():void
		{
			isLoading = false;
			refreshContent();
		}
		
		/**
		 * Utility
		 */
		override protected function draw():void
		{
			if (this.layout != null)
				(this.layout as VerticalLayout).hasVariableItemDimensions = true;
			
			super.draw();
		}
		
		override public function dispose():void
		{
			EmailFileSender.instance.removeEventListener(Event.COMPLETE, onFileSenderClosed);
			EmailFileSender.instance.removeEventListener(Event.CANCEL, onFileSenderClosed);
			EmailFileSender.dispose();
			
			if (backupScheduler != null)
			{
				backupScheduler.removeEventListener(Event.CHANGE, onBackupSchedulerChanged);
				backupScheduler.removeFromParent();
				backupScheduler.dispose();
				backupScheduler = null;
			}
			
			if (wifiOnlyCheck != null)
			{
				wifiOnlyCheck.removeEventListener(Event.CHANGE, onWifiOnly);
				wifiOnlyCheck.removeFromParent();
				wifiOnlyCheck.dispose();
				wifiOnlyCheck = null;
			}
			
			if (instructionsLabel != null)
			{
				instructionsLabel.removeFromParent();
				instructionsLabel.dispose();
				instructionsLabel = null;
			}
			
			if (backupButton != null)
			{
				backupButton.removeEventListener(starling.events.Event.TRIGGERED, onBackupDatabase);
				backupButton.removeFromParent();
				backupButton.dispose();
				backupButton = null;
			}
			
			if (restoreButton != null)
			{
				restoreButton.removeEventListener(starling.events.Event.TRIGGERED, onRestoreDatabase);
				restoreButton.removeFromParent();
				restoreButton.dispose();
				restoreButton = null;
			}
			
			if (emailDatabaseButton != null)
			{
				emailDatabaseButton.removeEventListener(starling.events.Event.TRIGGERED, onEmailDatabase);
				emailDatabaseButton.removeFromParent();
				emailDatabaseButton.dispose();
				emailDatabaseButton = null;
			}
			
			if (actionsContainer != null)
			{
				actionsContainer.removeFromParent();
				actionsContainer.dispose();
				actionsContainer = null;
			}
			
			if (preloader != null)
			{
				preloader.removeFromParent();
				preloader.dispose();
				preloader = null;
			}
			
			if (preloaderContainer != null)
			{
				preloaderContainer.removeFromParent();
				preloaderContainer.dispose();
				preloaderContainer = null;
			}
			
			super.dispose();
		}
	}
}