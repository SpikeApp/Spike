package services
{
	import com.distriqt.extension.networkinfo.NetworkInfo;
	import com.distriqt.extension.networkinfo.events.NetworkInfoEvent;
	import com.spikeapp.spike.airlibrary.SpikeANE;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.TimerEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.utils.Timer;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	import cryptography.Keys;
	
	import database.BgReading;
	import database.CGMBlueToothDevice;
	import database.CommonSettings;
	import database.FollowerBgReading;
	
	import events.CalibrationServiceEvent;
	import events.DexcomShareEvent;
	import events.FollowerEvent;
	import events.SettingsServiceEvent;
	import events.SpikeEvent;
	import events.TransmitterServiceEvent;
	
	import feathers.controls.Alert;
	import feathers.core.PopUpManager;
	import feathers.layout.HorizontalAlign;
	
	import model.ModelLocator;
	
	import network.NetworkConnector;
	
	import starling.events.Event;
	
	import ui.popups.AlertManager;
	
	import utils.Constants;
	import utils.Cryptography;
	import utils.DeviceInfo;
	import utils.SpikeJSON;
	import utils.TimeSpan;
	import utils.Trace;
	import utils.UniqueId;
	
	[ResourceBundle("dexcomshareservice")]
	[ResourceBundle("globaltranslations")]

	public class DexcomShareService extends EventDispatcher
	{
		/* Instance */
		public static const instance:DexcomShareService = new DexcomShareService();
		
		/* Constants */
		private static const US_SHARE_URL:String = "https://share2.dexcom.com/ShareWebServices/Services/";
		private static const INTERNATIONAL_SHARE_URL:String = "https://shareous1.dexcom.com/ShareWebServices/Services/";
		private static const APPLICATION_ID:String = "d8665ade-9673-4e27-9ff6-92db4ce13d13";
		private static const MODE_GLUCOSE_READING:String = "glucoseReading";
		private static const MODE_TEST_CREDENTIALS:String = "testCredentials";
		private static const MODE_REMOTE_MONITORING_SESSION:String = "remoteMonitoringSession";
		private static const MODE_ASSIGN_RECEIVER:String = "assignReceiver";
		private static const MODE_LIST_FOLLOWERS:String = "listFollowers";
		private static const MODE_DELETE_FOLLOWER:String = "deleteFollower";
		private static const MODE_CREATE_CONTACT:String = "createContact";
		private static const MODE_INVITE_FOLLOWER:String = "inviteFollower";
		private static const MODE_GET_FOLLOWER_INFO:String = "getFollowerInfo";
		private static const MODE_GET_FOLLOWER_ALARMS:String = "getFollowerAlarms";
		private static const MODE_CHANGE_FOLLOWER_NAME:String = "changeFollowerName";
		private static const MODE_CHANGE_FOLLOWER_PERMISSIONS:String = "changeFollowerPermissions";
		private static const MODE_DISABLE_FOLLOWER_SHARING:String = "disableFollowerSharing";
		private static const MODE_ENABLE_FOLLOWER_SHARING:String = "enableFollowerSharing";
		private static const MODE_GET_FOLLOWER_READINGS:String = "getFollowerReadings";
		private static const MAX_SYNC_TIME:Number = 45 * 1000; //45 seconds
		private static const RETRY_TIME_FOR_SERVER_ERRORS:Number = TimeSpan.TIME_4_MINUTES_30_SECONDS;
		private static const RETRY_TIME_FOR_MAX_AUTHENTICATION_RETRIES:Number = TimeSpan.TIME_10_MINUTES;
		private static const MAX_RETRIES_FOR_MONITORING_SESSION_NOT_ACTIVE:int = 5;
		private static const MAX_RETRIES_FOR_SESSION_NOT_VALID:int = 10;
		
		/* Data Objects */
		private static var activeGlucoseReadings:Array = [];
		private static var serviceTimer:Timer;
		
		/* Logical Variables */
		private static var serviceStarted:Boolean = false;
		public static var serviceActive:Boolean = false;
		private static var externalAuthenticationCall:Boolean = false;
		public static var ignoreSettingsChanged:Boolean = false;
		private static var _syncGlucoseReadingsActive:Boolean;
		private static var syncGlucoseReadingsActiveLastChange:Number = (new Date()).valueOf();
		private static var showAssignementPopup:Boolean = true;
		private static var serviceHalted:Boolean = false;
		
		/* Data Variables */
		private static var dexcomShareURL:String = "";
		private static var accountName:String = "";
		private static var accountPassword:String = "";
		private static var dexcomShareSessionID:String = "";
		private static var transmitterID:String = "";
		private static var networkChangeOcurrances:int = 0;
		private static var lastGlucoseReadingsSyncTimeStamp:Number;
		private static var nextFunctionToCall:Function = null;
		private static var timeStampOfLastLoginAttemptSinceJSONParsingErrorReceived:Number = 0;
		private static var timeStampOfLastSSO_AuthenticateMaxAttemptsExceeed:Number = 0;
		private static var retriesForSessionNotActive:int = 0;
		private static var retriesForSessionNotValid:int = 0;

		/* Follower Mode */
		private static var dsUsernameFollower:String;
		private static var dsPasswordFollower:String;
		private static var dsURLFollower:String;
		private static var followerModeEnabled:Boolean = false;
		private static var nextFollowDownloadTime:Number = 0;
		private static var timeOfFirstBgReadingToDowload:Number;
		private static var lastFollowDownloadAttempt:Number;
		private static var waitingForDSData:Boolean = false;
		private static var followerTimer:uint = 0;
		private static var followerAggressiveFetchRetry:uint = 0;
		private static var followerModerateFetchRetry:uint = 0;
		
		public function DexcomShareService()
		{
			if (instance != null)
				throw new Error("DexcomShareService is not meant to be instantiated");
		}
		
		public static function init():void
		{
			if (serviceStarted)
				return;
			
			Trace.myTrace("DexcomShareService.as", "Service started!");
			
			serviceStarted = true;
			
			//Event listener for settings changes
			CommonSettings.instance.addEventListener(SettingsServiceEvent.SETTING_CHANGED, onSettingChanged);
			
			Spike.instance.addEventListener(SpikeEvent.APP_HALTED, onHaltExecution);
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEXCOM_SHARE_ON) == "true" &&
				CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEXCOM_SHARE_ACCOUNTNAME) != "" &&
				CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEXCOM_SHARE_PASSWORD) != "" &&
				!CGMBlueToothDevice.isFollower())
			{
				setupDexcomShareProperties();
				nextFunctionToCall = getInitialMasterGlucoseReadings;
				activateService();
			}
			else if (CGMBlueToothDevice.isFollower() &&
					CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FOLLOWER_MODE) == "Dexcom" &&
					CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_DS_USERNAME) != "" &&
					CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_DS_PASSWORD) != "" &&
					CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_DS_SERVER) != "")
			{
				setupFollowerProperties();
				activateFollower();
			}
		}
		
		/**
		 * CREDENTIALS TEST
		 */
		public static function testDexcomShareCredentials(externalCall:Boolean = false, followerMode:Boolean = false):void
		{
			if (NetworkInfo.networkInfo.isReachable())
			{
				setupDexcomShareProperties();
				setupFollowerProperties();
				externalAuthenticationCall = externalCall;
				nextFunctionToCall = !followerMode ? syncGlucoseReadings : getFollowerGlucoseReadings;
				login(followerMode);
			}
			else
			{
				AlertManager.showSimpleAlert
				(
					Constants.deviceModel != DeviceInfo.IPHONE_X_Xs_XsMax_Xr ? ModelLocator.resourceManagerInstance.getString("dexcomshareservice","credential_test_alert_title") : ModelLocator.resourceManagerInstance.getString("dexcomshareservice","credential_test_alert_title_x"),
					ModelLocator.resourceManagerInstance.getString("dexcomshareservice","credential_test_alert_message_network_unreachable"),
					60
				);
			}
		}
		
		private static function login(followerMode:Boolean = false):void 
		{
			var authParameters:Object = new Object();
			authParameters["accountName"] = followerModeEnabled || followerMode ? dsUsernameFollower : accountName;
			authParameters["applicationId"] = APPLICATION_ID;
			authParameters["password"] = followerModeEnabled || followerMode ? dsPasswordFollower : accountPassword;
			
			//NetworkConnector.createDSConnector(dexcomShareURL + "General/LoginPublisherAccountByName", URLRequestMethod.POST, null, JSON.stringify(authParameters), MODE_TEST_CREDENTIALS, onTestCredentialsComplete, onConnectionFailed);
			NetworkConnector.createDSConnector((followerModeEnabled ? dsURLFollower : dexcomShareURL) + "General/LoginPublisherAccountByName", URLRequestMethod.POST, null, SpikeJSON.stringify(authParameters), MODE_TEST_CREDENTIALS, onTestCredentialsComplete, onConnectionFailed);
		}
		
		private static function onTestCredentialsComplete(e:flash.events.Event):void
		{
			Trace.myTrace("DexcomShareService.as", "onTestCredentialsComplete called");
			
			if (serviceHalted)
				return;
			
			var loader:URLLoader = e.currentTarget as URLLoader;
			var response:String = loader.data;
			loader = null;
			
			if (response != "")
			{
				if (response.indexOf("Code") == -1)
				{
					//Set Session ID
					dexcomShareSessionID = response.split('"').join('');
					
					Trace.myTrace("DexcomShareService.as", "Authentication successful! Session ID: " + dexcomShareSessionID);
					
					//Alert User
					if (externalAuthenticationCall)
					{
						AlertManager.showSimpleAlert(
							Constants.deviceModel != DeviceInfo.IPHONE_X_Xs_XsMax_Xr ? ModelLocator.resourceManagerInstance.getString("dexcomshareservice","credential_test_alert_title") : ModelLocator.resourceManagerInstance.getString("dexcomshareservice","credential_test_alert_title_x"),
							ModelLocator.resourceManagerInstance.getString("dexcomshareservice","credential_test_alert_message_ok"),
							Number.NaN,
							null,
							HorizontalAlign.CENTER
						);
					}
					
					if (!serviceActive && !CGMBlueToothDevice.isFollower())
						activateService();
					else if (!followerModeEnabled && CGMBlueToothDevice.isFollower())
						activateFollower();
					
					//Perform next steps
					if (nextFunctionToCall != null)
					{
						nextFunctionToCall.call();
						nextFunctionToCall = null;
					}
				}
				else
				{
					Trace.myTrace("DexcomShareService.as", "Authentication error! Trying to parse error...");
					
					if (serviceActive && !CGMBlueToothDevice.isFollower())
						deactivateService();
					else if (followerModeEnabled && CGMBlueToothDevice.isFollower())
						deactivateFollowerMode();
					
					var responseInfo:Object = parseDexcomError(response, null);
					
					if (responseInfo != null)
					{
						var errorCode:String = responseInfo.Code;
						
						Trace.myTrace("DexcomShareService.as", "Error parsed successfully! Error code: " + errorCode);
						
						if (errorCode != null)
						{	
							if (errorCode == "SSO_AuthenticateAccountNotFound") 
							{
								if (externalAuthenticationCall) 
								{
									Trace.myTrace("DexcomShareService.as", "Alerting user of invalid account.");
									
									AlertManager.showSimpleAlert
										(
											Constants.deviceModel != DeviceInfo.IPHONE_X_Xs_XsMax_Xr ? ModelLocator.resourceManagerInstance.getString("dexcomshareservice","credential_test_alert_title") : ModelLocator.resourceManagerInstance.getString("dexcomshareservice","credential_test_alert_title_x"),
											ModelLocator.resourceManagerInstance.getString("dexcomshareservice","credential_test_alert_message_account_name_not_found"),
											60,
											null,
											HorizontalAlign.CENTER
										);
								}
							}
							else if (errorCode == "SSO_AuthenticatePasswordInvalid") 
							{
								if (externalAuthenticationCall) 
								{
									Trace.myTrace("DexcomShareService.as", "Alerting user of invalid password.");
									
									AlertManager.showSimpleAlert
										(
											Constants.deviceModel != DeviceInfo.IPHONE_X_Xs_XsMax_Xr ? ModelLocator.resourceManagerInstance.getString("dexcomshareservice","credential_test_alert_title") : ModelLocator.resourceManagerInstance.getString("dexcomshareservice","credential_test_alert_title_x"),
											ModelLocator.resourceManagerInstance.getString("dexcomshareservice","credential_test_alert_message_invalid_password"),
											60,
											null,
											HorizontalAlign.CENTER
										);
									
								}
							}
							else if (errorCode == "SSO_AuthenticateMaxAttemptsExceeed") 
							{
								if (SpikeANE.appIsInForeground()) 
								{
									Trace.myTrace("DexcomShareService.as", "Alerting user of max authentication attempts exceeded.");
									
									AlertManager.showSimpleAlert
										(
											Constants.deviceModel != DeviceInfo.IPHONE_X_Xs_XsMax_Xr ? ModelLocator.resourceManagerInstance.getString("dexcomshareservice","credential_test_alert_title") : ModelLocator.resourceManagerInstance.getString("dexcomshareservice","credential_test_alert_title_x"),
											ModelLocator.resourceManagerInstance.getString("dexcomshareservice","credential_test_alert_message_max_login_attempts_excceded"),
											60
										);
								}
								
								timeStampOfLastSSO_AuthenticateMaxAttemptsExceeed = (new Date()).valueOf();
							}
							else
							{
								if (SpikeANE.appIsInForeground()) 
								{
									AlertManager.showSimpleAlert
									(
										ModelLocator.resourceManagerInstance.getString("dexcomshareservice","credential_test_alert_title"),
										ModelLocator.resourceManagerInstance.getString("dexcomshareservice","credential_test_alert_message_error") + " " + errorCode,
										60
									);
								}
							}
						} 
						else
						{
							Trace.myTrace("DexcomShareService.as", "There's no error code in server's response. Aborting!");
							
							if (SpikeANE.appIsInForeground()) 
							{
								AlertManager.showSimpleAlert
								(
									ModelLocator.resourceManagerInstance.getString("dexcomshareservice","credential_test_alert_title"),
									ModelLocator.resourceManagerInstance.getString("dexcomshareservice","unknown_authentication_error"),
									60
								);
							}
						}
						
					}
					else
					{
						Trace.myTrace("DexcomShareService.as", "Unable to parse error!");
						
						if (externalAuthenticationCall)
						{
							//Alert User
							Trace.myTrace("DexcomShareService.as", "Displaying generic error message to the user.");
							
							AlertManager.showSimpleAlert(
								Constants.deviceModel != DeviceInfo.IPHONE_X_Xs_XsMax_Xr ? ModelLocator.resourceManagerInstance.getString("dexcomshareservice","credential_test_alert_title") : ModelLocator.resourceManagerInstance.getString("dexcomshareservice","credential_test_alert_title_x"),
								ModelLocator.resourceManagerInstance.getString("dexcomshareservice","credential_test_alert_message_error") + " " + ModelLocator.resourceManagerInstance.getString("dexcomshareservice","credential_test_alert_message_error_unknown")
							);
						}
					}
				}
			}
			else
			{
				Trace.myTrace("DexcomShareService.as", "Authentication error! Error: Service unavailable");
				if (externalAuthenticationCall)
				{
					//Alert User
					AlertManager.showSimpleAlert(
						Constants.deviceModel != DeviceInfo.IPHONE_X_Xs_XsMax_Xr ? ModelLocator.resourceManagerInstance.getString("dexcomshareservice","credential_test_alert_title") : ModelLocator.resourceManagerInstance.getString("dexcomshareservice","credential_test_alert_title_x"),
						ModelLocator.resourceManagerInstance.getString("dexcomshareservice","credential_test_alert_message_error") + " " + ModelLocator.resourceManagerInstance.getString("dexcomshareservice","credential_test_alert_message_service_unavailable")
					);
				}
			}
			
			externalAuthenticationCall = false;
		}
		
		/**
		 * GLUCOSE READINGS
		 */
		private static function createGlucoseReading(glucoseReading:BgReading):Object
		{
			var newReading:Object = new Object();
			newReading.Trend = glucoseReading.getSlopeOrdinal();
			newReading.ST = toDateString(glucoseReading.timestamp);
			newReading.DT = newReading.ST;
			newReading.Value = Math.round(glucoseReading.calculatedValue);
			newReading["direction"] = glucoseReading.slopeName();
			
			return newReading;
		}
		
		private static function getInitialMasterGlucoseReadings(e:flash.events.Event = null):void
		{
			lastGlucoseReadingsSyncTimeStamp = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEXCOMSHARE_SYNC_TIMESTAMP));
			var now:Number = (new Date()).valueOf();
			
			for(var i:int = ModelLocator.bgReadings.length - 1 ; i >= 0; i--)
			{
				var glucoseReading:BgReading = ModelLocator.bgReadings[i] as BgReading;
				
				if (glucoseReading.timestamp > lastGlucoseReadingsSyncTimeStamp && now - glucoseReading.timestamp < 24 * 3600 * 1000) 
				{
					if (glucoseReading.calculatedValue != 0) 
						activeGlucoseReadings.push(createGlucoseReading(glucoseReading));
				}
				else
					break;
			}
			
			if (activeGlucoseReadings.length > 0)
			{
				Trace.myTrace("DexcomShareService.as", "Number of initial glucose readings to upload: " + activeGlucoseReadings.length);
				syncGlucoseReadings();
			}
			else
				Trace.myTrace("DexcomShareService.as", "No initial glucose readings!");
		}
		
		private static function syncGlucoseReadings():void
		{
			if (activeGlucoseReadings.length == 0 || syncGlucoseReadingsActive || !NetworkInfo.networkInfo.isReachable())
				return;
			
			if ((new Date()).valueOf() - timeStampOfLastSSO_AuthenticateMaxAttemptsExceeed < RETRY_TIME_FOR_MAX_AUTHENTICATION_RETRIES * 60 * 1000) 
				return;
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEXCOM_SHARE_WIFI_ONLY_UPLOADER_ON) == "true" && NetworkInfo.networkInfo.isWWAN())
				return;
			
			if (dexcomShareSessionID == "")
			{
				nextFunctionToCall = syncGlucoseReadings;
				login();
				return;
			}
			
			if (CGMBlueToothDevice.isFollower())
			{
				deactivateService();
				return;
			}
			
			syncGlucoseReadingsActive = true;
			
			var data:Object = new Object();
			data.Egvs = activeGlucoseReadings;
			data.SN = transmitterID;
			data.TA = -5;
			
			//NetworkConnector.createDSConnector(dexcomShareURL + "Publisher/PostReceiverEgvRecords", URLRequestMethod.POST, dexcomShareSessionID, JSON.stringify(data), MODE_GLUCOSE_READING, onUploadGlucoseReadingsComplete, onConnectionFailed);
			NetworkConnector.createDSConnector(dexcomShareURL + "Publisher/PostReceiverEgvRecords", URLRequestMethod.POST, dexcomShareSessionID, SpikeJSON.stringify(data), MODE_GLUCOSE_READING, onUploadGlucoseReadingsComplete, onConnectionFailed);
		}
		
		private static function onUploadGlucoseReadingsComplete(e:flash.events.Event):void
		{
			Trace.myTrace("DexcomShareService.as", "in onUploadGlucoseReadingsComplete.");
			
			//Get loader
			var loader:URLLoader = e.currentTarget as URLLoader;
			
			//Get response
			var response:String = loader.data;
			
			//Dispose loader
			loader.removeEventListener(flash.events.Event.COMPLETE, onUploadGlucoseReadingsComplete);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onUploadGlucoseReadingsComplete);
			loader = null;
			
			//Validation
			if (serviceHalted)
				return;
			
			//Check response
			if (response == "")
			{
				Trace.myTrace("DexcomShareService.as", "Glucose reading(s) uploaded successfully!");
				
				glucoseUploadSuccessfull();
			}
			else
			{
				Trace.myTrace("DexcomShareService.as", "Error uploading glucose reading(s)! Trying to parse error...");
				
				var responseInfo:Object = parseDexcomError(response, syncGlucoseReadings);
				
				if (responseInfo != null)
				{
					var errorCode:String = responseInfo.Code;
					
					Trace.myTrace("DexcomShareService.as", "Error parsed successfully! Error code: " + errorCode);
					
					if (errorCode == null)
					{
						Trace.myTrace("DexcomShareService.as", "There's no error code in server's response. Aborting!");
						syncGlucoseReadingsActive = false;
					}
					else if (errorCode == "SessionNotValid" || errorCode == "SessionIdNotFound")
					{
						if (retriesForSessionNotValid <= MAX_RETRIES_FOR_SESSION_NOT_VALID)
						{
							retriesForSessionNotValid++;
							dexcomShareSessionID = "";
							nextFunctionToCall = syncGlucoseReadings;
							setTimeout(login, 5000); //5 seconds
						}
					}
					else if (errorCode == "MonitoringSessionNotActive") 
					{
						NetworkConnector.createDSConnector(dexcomShareURL + "Publisher/StartRemoteMonitoringSession?sessionId=" + escape(dexcomShareSessionID) + "&serialNumber=" + escape(transmitterID), URLRequestMethod.POST, null, null, MODE_GLUCOSE_READING, onStartRemoteMonitoringResponse, onConnectionFailed);
					}
					else if (errorCode == "DuplicateEgvPosted") 
					{
						Trace.myTrace("DexcomShareService.as", "There were duplicate glucose entries. Not problematic. Treating as successful!");
						
						glucoseUploadSuccessfull();
					}
					else if (errorCode == "MonitoredReceiverSerialNumberDoesNotMatch") 
					{
						if (SpikeANE.appIsInForeground()) 
						{
							AlertManager.showSimpleAlert(
								ModelLocator.resourceManagerInstance.getString("dexcomshareservice","upload_alert_title"),
								ModelLocator.resourceManagerInstance.getString("dexcomshareservice","upload_alert_message_receiver_sn_missmatch"),
								60
							);
						}
					}
					else if (errorCode == "MonitoredReceiverNotAssigned") 
					{
						if (SpikeANE.appIsInForeground()) 
						{
							var message:String = ModelLocator.resourceManagerInstance.getString("dexcomshareservice","upload_alert_message_receiver_unassigned_1");
							message += " " + transmitterID;
							message += " " + ModelLocator.resourceManagerInstance.getString("dexcomshareservice","upload_alert_message_receiver_unassigned_2");
							message += " " + CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEXCOM_SHARE_ACCOUNTNAME);
							message += ". " + ModelLocator.resourceManagerInstance.getString("dexcomshareservice","upload_alert_message_receiver_unassigned_3");
							
							var alert:Alert = AlertManager.showActionAlert
								(
									ModelLocator.resourceManagerInstance.getString("dexcomshareservice","upload_alert_title"),
									message,
									90,
									[
										{ label: ModelLocator.resourceManagerInstance.getString("globaltranslations","no_uppercase")  },	
										{ label: ModelLocator.resourceManagerInstance.getString("globaltranslations","yes_uppercase") }	
									]
								);
							alert.addEventListener(starling.events.Event.CLOSE, onUserRequestAssignment);
							
							function onUserRequestAssignment(e:starling.events.Event, data:Object):void
							{
								if (PopUpManager.isPopUp(alert))
									PopUpManager.removePopUp(alert, true);
								else if (alert != null)
									alert.removeFromParent(true);
								
								if( data.label == ModelLocator.resourceManagerInstance.getString("globaltranslations","yes_uppercase") )
									assignReceiver(transmitterID);
							}
						}
					}
					else 
					{
						Trace.myTrace("DexcomShareService.as", "No action taken. Error code is unknown.");
					} 
				}
				
				syncGlucoseReadingsActive = false;
			}
		}
		
		private static function glucoseUploadSuccessfull():void
		{
			//Validation
			if (serviceHalted)
				return;
			
			activeGlucoseReadings.length = 0;
			CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_DEXCOMSHARE_SYNC_TIMESTAMP, (new Date()).valueOf().toString());
		}
		
		private static function onBgreadingReceived(e:flash.events.Event):void 
		{
			//Validation
			if (serviceHalted)
				return;
			
			var latestGlucoseReading:BgReading;
			if(!CGMBlueToothDevice.isFollower())
				latestGlucoseReading= BgReading.lastNoSensor();
			else
				latestGlucoseReading= BgReading.lastWithCalculatedValue();
			
			if(latestGlucoseReading == null || (latestGlucoseReading.calculatedValue == 0 && latestGlucoseReading.calibration == null) || latestGlucoseReading.calculatedValue == 0)
				return;
			
			activeGlucoseReadings.push(createGlucoseReading(latestGlucoseReading));
			
		}
		
		private static function onLastBgreadingReceived(e:flash.events.Event):void 
		{		
			//Validation
			if (serviceHalted)
				return;
			
			syncGlucoseReadings();
		}
		
		/**
		 * Remote Monitoring
		 */
		private static function onStartRemoteMonitoringResponse(e:flash.events.Event):void
		{
			//Validation
			if (serviceHalted)
				return;
			
			retriesForSessionNotActive ++;
			
			var loader:URLLoader = e.currentTarget as URLLoader;
			
			if (String(loader.data).indexOf("MonitoredReceiverSerialNumberDoesNotMatch") == -1 && String(loader.data).indexOf("NotAssigned") == -1 && String(loader.data).indexOf("MonitoredReceiverNotAssigned") == -1 && retriesForSessionNotActive < MAX_RETRIES_FOR_MONITORING_SESSION_NOT_ACTIVE)
				syncGlucoseReadings();
			else
			{
				assignReceiver(transmitterID, false);
			}
				
			loader.removeEventListener(flash.events.Event.COMPLETE, onStartRemoteMonitoringResponse);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onStartRemoteMonitoringResponse);
			loader = null;
		}
		
		/**
		 * ASSIGN RECEIVER
		 */
		private static function assignReceiver(receiverID:String, showPopup:Boolean = true):void
		{
			Trace.myTrace("DexcomShareService.as", "assignReceiver called!");
			
			showAssignementPopup = showPopup;
			
			NetworkConnector.createDSConnector(dexcomShareURL + "Publisher/ReplacePublisherAccountMonitoredReceiver?sessionId=" + escape(dexcomShareSessionID) + "&serialNumber=" + escape(receiverID), URLRequestMethod.POST, null, null, MODE_ASSIGN_RECEIVER, onAssignReceiverResponse, onConnectionFailed);
		}
		
		private static function onAssignReceiverResponse(e:flash.events.Event):void
		{
			Trace.myTrace("DexcomShareService.as", "onAssignReceiverResponse called!");
			
			var loader:URLLoader = e.currentTarget as URLLoader;
			var response:String = String(loader.data);
			
			//Validation
			if (serviceHalted)
				return;
			
			if (response.indexOf("Code") == -1)
			{
				Trace.myTrace("DexcomShareService.as", "Receiver assigned successfully!!");
				getInitialMasterGlucoseReadings();
				
				if (SpikeANE.appIsInForeground() && showAssignementPopup)
				{
					Trace.myTrace("DexcomShareService.as", "Notifying user...");
					
					AlertManager.showSimpleAlert
					(
						ModelLocator.resourceManagerInstance.getString("dexcomshareservice","assignment_alert_title"),
						ModelLocator.resourceManagerInstance.getString("dexcomshareservice","assignment_alert_message_success"),
						60
					);
				}
				
				showAssignementPopup = true;
				syncGlucoseReadings();
			}
			else
			{
				Trace.myTrace("DexcomShareService.as", "Error assigning receiver! Trying to parse error code");
				
				var responseInfo:Object = parseDexcomError(response, null);
				
				if (responseInfo != null)
				{
					var errorCode:String = responseInfo.Code;
				
					Trace.myTrace("DexcomShareService.as", "Error parsed successfully! Error code: " + errorCode + " | Message: " + responseInfo.Message);
					
					if (errorCode == null)
					{
						Trace.myTrace("DexcomShareService.as", "There's no error code in server's response. Aborting!");
						
						if (SpikeANE.appIsInForeground())
						{
							Trace.myTrace("DexcomShareService.as", "Notifying user...");
							
							AlertManager.showSimpleAlert
							(
								ModelLocator.resourceManagerInstance.getString("dexcomshareservice","assignment_alert_title"),
								ModelLocator.resourceManagerInstance.getString("dexcomshareservice","assignment_alert_message_unknown_error"),
								60
							);
						}
					}
					else
					{
						if (SpikeANE.appIsInForeground())
						{
							Trace.myTrace("DexcomShareService.as", "Notifying user...");
							
							AlertManager.showSimpleAlert
							(
								ModelLocator.resourceManagerInstance.getString("dexcomshareservice","assignment_alert_title"),
								ModelLocator.resourceManagerInstance.getString("dexcomshareservice","assignment_alert_message_error") + " " + responseInfo.Message,
								60
							);
						}
					}
				}
			}
			
			//Dispose loader
			if (loader != null)
			{
				loader.removeEventListener(flash.events.Event.COMPLETE, onAssignReceiverResponse);
				loader.removeEventListener(IOErrorEvent.IO_ERROR, onAssignReceiverResponse);
				loader = null;
			}
		}
		
		/**
		 * DEXCOM FOLLOWERS MANAGEMENT
		 */
		public static function getFollowers():void
		{
			if (dexcomShareSessionID == "")
			{
				nextFunctionToCall = getFollowers;
				login();
				return;
			}
			
			NetworkConnector.createDSConnector(dexcomShareURL + "Publisher/ListPublisherAccountSubscriptions", URLRequestMethod.POST, dexcomShareSessionID, null, MODE_LIST_FOLLOWERS, onListFollowersResponse, onConnectionFailed);
		}
		
		private static function onListFollowersResponse(e:flash.events.Event):void
		{
			//Validation
			if (serviceHalted)
				return;
			
			var loader:URLLoader = e.currentTarget as URLLoader;
			
			instance.dispatchEvent(new DexcomShareEvent(DexcomShareEvent.LIST_FOLLOWERS, loader.data));
			
			//Dispose loader
			loader.removeEventListener(flash.events.Event.COMPLETE, onListFollowersResponse);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onListFollowersResponse);
			loader = null;
		}
		
		public static function deleteFollower(contactID:String):void
		{
			NetworkConnector.createDSConnector(dexcomShareURL + "Publisher/DeleteContact?sessionId=" + escape(dexcomShareSessionID) + "&contactId=" + escape(contactID), URLRequestMethod.POST, null, null, MODE_DELETE_FOLLOWER, onDeleteFollowerResponse, onConnectionFailed);
		}
		
		private static function onDeleteFollowerResponse(e:flash.events.Event):void
		{
			//Validation
			if (serviceHalted)
				return;
			
			var loader:URLLoader = e.currentTarget as URLLoader;
			
			instance.dispatchEvent(new DexcomShareEvent(DexcomShareEvent.DELETE_FOLLOWER, loader.data));
			
			//Dispose loader
			loader.removeEventListener(flash.events.Event.COMPLETE, onDeleteFollowerResponse);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onDeleteFollowerResponse);
			loader = null;
		}
		
		public static function createContact(contactName:String, contactEmail:String):void
		{
			NetworkConnector.createDSConnector(dexcomShareURL + "Publisher/CreateContact?sessionId=" + escape(dexcomShareSessionID) + "&contactName=" + contactName + "&emailAddress=" + escape(contactEmail), URLRequestMethod.POST, null, null, MODE_CREATE_CONTACT, onCreateContactResponse, onConnectionFailed);
		}
		
		private static function onCreateContactResponse(e:flash.events.Event):void
		{
			//Validation
			if (serviceHalted)
				return;
			
			var loader:URLLoader = e.currentTarget as URLLoader;
			
			instance.dispatchEvent(new DexcomShareEvent(DexcomShareEvent.CREATE_CONTACT, loader.data));
			
			//Dispose loader
			loader.removeEventListener(flash.events.Event.COMPLETE, onCreateContactResponse);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onCreateContactResponse);
			loader = null;
		}
		
		public static function inviteFollower(contactID:String, parameters:String):void
		{
			NetworkConnector.createDSConnector(dexcomShareURL + "Publisher/CreateSubscriptionInvitation?sessionId=" + escape(dexcomShareSessionID) + "&contactId=" + escape(contactID), URLRequestMethod.POST, null, parameters, MODE_INVITE_FOLLOWER, onInviteFollowerResponse, onConnectionFailed);
		}
		
		private static function onInviteFollowerResponse(e:flash.events.Event):void
		{
			//Validation
			if (serviceHalted)
				return;
			
			var loader:URLLoader = e.currentTarget as URLLoader;
			
			instance.dispatchEvent(new DexcomShareEvent(DexcomShareEvent.INVITE_FOLLOWER, loader.data));
			
			//Dispose loader
			loader.removeEventListener(flash.events.Event.COMPLETE, onInviteFollowerResponse);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onInviteFollowerResponse);
			loader = null;
		}
		
		public static function getFollowerInfo(contactID:String):void
		{
			NetworkConnector.createDSConnector(dexcomShareURL + "Publisher/ReadContact?sessionId=" + escape(dexcomShareSessionID) + "&contactId=" + escape(contactID), URLRequestMethod.POST, null, null, MODE_GET_FOLLOWER_INFO, onGetFollowerInfoResponse, onConnectionFailed);
		}
		
		private static function onGetFollowerInfoResponse(e:flash.events.Event):void
		{
			//Validation
			if (serviceHalted)
				return;
			
			var loader:URLLoader = e.currentTarget as URLLoader;
			
			instance.dispatchEvent(new DexcomShareEvent(DexcomShareEvent.GET_FOLLOWER_INFO, loader.data));
			
			//Dispose loader
			loader.removeEventListener(flash.events.Event.COMPLETE, onGetFollowerInfoResponse);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onGetFollowerInfoResponse);
			loader = null;
		}
		
		public static function getFollowerAlarms(subscriptionID:String):void
		{
			NetworkConnector.createDSConnector(dexcomShareURL + "General/ReadSubscriptionAlerts?sessionId=" + escape(dexcomShareSessionID) + "&subscriptionId=" + escape(subscriptionID), URLRequestMethod.POST, null, null, MODE_GET_FOLLOWER_ALARMS, onGetFollowerAlarmsResponse, onConnectionFailed);
		}
		
		private static function onGetFollowerAlarmsResponse(e:flash.events.Event):void
		{
			//Validation
			if (serviceHalted)
				return;
			
			var loader:URLLoader = e.currentTarget as URLLoader;
			
			instance.dispatchEvent(new DexcomShareEvent(DexcomShareEvent.GET_FOLLOWER_ALARMS, loader.data));
			
			//Dispose loader
			loader.removeEventListener(flash.events.Event.COMPLETE, onGetFollowerAlarmsResponse);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onGetFollowerAlarmsResponse);
			loader = null;
		}
		
		public static function changeFollowerName(contactID:String, contactName:String):void
		{
			NetworkConnector.createDSConnector(dexcomShareURL + "Publisher/UpdateContactName?sessionId=" + escape(dexcomShareSessionID) + "&contactId=" + escape(contactID) + "&contactName=" + escape(contactName), URLRequestMethod.POST, null, null, MODE_CHANGE_FOLLOWER_NAME, onChangeFollowerNameResponse, onConnectionFailed);
		}
		
		private static function onChangeFollowerNameResponse(e:flash.events.Event):void
		{
			//Validation
			if (serviceHalted)
				return;
			
			var loader:URLLoader = e.currentTarget as URLLoader;
			
			instance.dispatchEvent(new DexcomShareEvent(DexcomShareEvent.CHANGE_FOLLOWER_NAME, loader.data));
			
			//Dispose loader
			loader.removeEventListener(flash.events.Event.COMPLETE, onChangeFollowerNameResponse);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onChangeFollowerNameResponse);
			loader = null;
		}
		
		public static function changeFollowerPermissions(subscriptionID:String, permissions:int):void
		{
			NetworkConnector.createDSConnector(dexcomShareURL + "Publisher/UpdateSubscriptionPermissions?sessionId=" + escape(dexcomShareSessionID) + "&subscriptionId=" + escape(subscriptionID) + "&permissions=" + permissions, URLRequestMethod.POST, null, null, MODE_CHANGE_FOLLOWER_PERMISSIONS, onChangeFollowerPermissionsResponse, onConnectionFailed);
		}
		
		private static function onChangeFollowerPermissionsResponse(e:flash.events.Event):void
		{
			//Validation
			if (serviceHalted)
				return;
			
			var loader:URLLoader = e.currentTarget as URLLoader;
			
			instance.dispatchEvent(new DexcomShareEvent(DexcomShareEvent.CHANGE_FOLLOWER_PERMISSIONS, loader.data));
			
			//Dispose loader
			loader.removeEventListener(flash.events.Event.COMPLETE, onChangeFollowerPermissionsResponse);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onChangeFollowerPermissionsResponse);
			loader = null;
		}
		
		public static function enableFollowerSharing(subscriptionID:String):void
		{
			NetworkConnector.createDSConnector(dexcomShareURL + "General/ResumeSubscription?sessionId=" + escape(dexcomShareSessionID) + "&subscriptionId=" + escape(subscriptionID), URLRequestMethod.POST, null, null, MODE_ENABLE_FOLLOWER_SHARING, onEnableFollowerSharingResponse, onConnectionFailed);
		}
		
		private static function onEnableFollowerSharingResponse(e:flash.events.Event):void
		{
			//Validation
			if (serviceHalted)
				return;
			
			var loader:URLLoader = e.currentTarget as URLLoader;
			
			instance.dispatchEvent(new DexcomShareEvent(DexcomShareEvent.ENABLE_FOLLOWER_SHARING, loader.data));
			
			//Dispose loader
			loader.removeEventListener(flash.events.Event.COMPLETE, onEnableFollowerSharingResponse);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onEnableFollowerSharingResponse);
			loader = null;
		}
		
		public static function disableFollowerSharing(subscriptionID:String):void
		{
			NetworkConnector.createDSConnector(dexcomShareURL + "General/PauseSubscription?sessionId=" + escape(dexcomShareSessionID) + "&subscriptionId=" + escape(subscriptionID), URLRequestMethod.POST, null, null, MODE_ENABLE_FOLLOWER_SHARING, onDisableFollowerSharingResponse, onConnectionFailed);
		}
		
		private static function onDisableFollowerSharingResponse(e:flash.events.Event):void
		{
			//Validation
			if (serviceHalted)
				return;
			
			var loader:URLLoader = e.currentTarget as URLLoader;
			
			instance.dispatchEvent(new DexcomShareEvent(DexcomShareEvent.DISABLE_FOLLOWER_SHARING, loader.data));
			
			//Dispose loader
			loader.removeEventListener(flash.events.Event.COMPLETE, onDisableFollowerSharingResponse);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onDisableFollowerSharingResponse);
			loader = null;
		}
		
		/**
		 * Functionality
		 */
		private static function activateService():void
		{
			Trace.myTrace("DexcomShareService.as", "Service activated!");
			serviceActive = true;
			followerModeEnabled = false;
			activateEventListeners();
			nextFunctionToCall = getInitialMasterGlucoseReadings;
			login();
		}
		
		private static function deactivateService():void
		{
			Trace.myTrace("DexcomShareService.as", "Service deactivated!");
			serviceActive = false;
			deactivateMasterEventListeners();
		}
		
		private static function setupDexcomShareProperties():void
		{
			//URL
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEXCOM_SHARE_US_URL) == "true")
				dexcomShareURL = US_SHARE_URL;
			else
				dexcomShareURL = INTERNATIONAL_SHARE_URL;
			
			//Account Name
			accountName = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEXCOM_SHARE_ACCOUNTNAME);
			
			//Password
			accountPassword = Cryptography.decryptStringLight(Keys.STRENGTH_256_BIT, CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEXCOM_SHARE_PASSWORD));
			
			//Transmitter ID
			if (CGMBlueToothDevice.isDexcomG5() || CGMBlueToothDevice.isDexcomG6()) transmitterID = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TRANSMITTER_ID);
			else transmitterID = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEXCOM_SHARE_SERIALNUMBER);
		}
		
		private static function activateEventListeners():void
		{
			deactivateFollowerEventListeners();
			
			TransmitterService.instance.addEventListener(TransmitterServiceEvent.BGREADING_RECEIVED, onBgreadingReceived);
			TransmitterService.instance.addEventListener(TransmitterServiceEvent.LAST_BGREADING_RECEIVED, onLastBgreadingReceived);
			NightscoutService.instance.addEventListener(FollowerEvent.BG_READING_RECEIVED, onBgreadingReceived);
			Spike.instance.addEventListener(SpikeEvent.APP_IN_FOREGROUND, onAppActivated);
			NetworkInfo.networkInfo.addEventListener(NetworkInfoEvent.CHANGE, onNetworkChange);
			CalibrationService.instance.addEventListener(CalibrationServiceEvent.INITIAL_CALIBRATION_EVENT, getInitialMasterGlucoseReadings);
		}
		private static function deactivateMasterEventListeners():void
		{
			TransmitterService.instance.removeEventListener(TransmitterServiceEvent.BGREADING_RECEIVED, onBgreadingReceived);
			TransmitterService.instance.removeEventListener(TransmitterServiceEvent.LAST_BGREADING_RECEIVED, onLastBgreadingReceived);
			NightscoutService.instance.removeEventListener(FollowerEvent.BG_READING_RECEIVED, onBgreadingReceived);
			Spike.instance.removeEventListener(SpikeEvent.APP_IN_FOREGROUND, onAppActivated);
			NetworkInfo.networkInfo.removeEventListener(NetworkInfoEvent.CHANGE, onNetworkChange);
			CalibrationService.instance.removeEventListener(CalibrationServiceEvent.INITIAL_CALIBRATION_EVENT, getInitialMasterGlucoseReadings);
		}
		
		private static function activateTimer():void
		{
			serviceTimer = new Timer(2.5 * 60 * 1000);
			serviceTimer.addEventListener(TimerEvent.TIMER, onServiceTimer, false, 0, true);
			serviceTimer.start();
		}
		
		private static function deactivateTimer():void
		{
			if (serviceTimer != null)
			{
				serviceTimer.stop();;
				serviceTimer.removeEventListener(TimerEvent.TIMER, onServiceTimer);
				serviceTimer = null;
			}
		}
		
		private static function parseDexcomError(response:String, nextAction:Function):Object
		{
			var responseInfo:Object;
			
			try
			{
				//responseInfo = JSON.parse(response);
				responseInfo = SpikeJSON.parse(response);
			} 
			catch(error:Error) 
			{
				Trace.myTrace("DexcomShareService.as", "Can't parse server response! Error: " + error.message);
				
				var now:Number = (new Date()).valueOf();
				if (now - timeStampOfLastLoginAttemptSinceJSONParsingErrorReceived > RETRY_TIME_FOR_SERVER_ERRORS) 
				{
					Trace.myTrace("DexcomShareService.as", "Trying new login...");
					timeStampOfLastLoginAttemptSinceJSONParsingErrorReceived = now;
					dexcomShareSessionID = "";
					nextFunctionToCall = nextAction;
					login();
				}
				else
				{
					Trace.myTrace("DexcomShareService.as", "Not trying new login...");
				}
			}
			
			return responseInfo;
		}
		
		private static function resync():void
		{
			if (activeGlucoseReadings.length > 0) syncGlucoseReadings();
		}
		
		/**
		 * FOLLOWER MODE
		 */
		private static function setupFollowerProperties():void
		{
			dsUsernameFollower = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_DS_USERNAME);
			dsPasswordFollower = Cryptography.decryptStringLight(Keys.STRENGTH_256_BIT, CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_DS_PASSWORD));
			dsURLFollower = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_DS_SERVER) == "us" ? US_SHARE_URL : INTERNATIONAL_SHARE_URL;
		}
		
		private static function activateFollower():void
		{
			if(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FOLLOWER_MODE).toUpperCase() != "DEXCOM")
			{
				return;
			}
			
			Trace.myTrace("DexcomShareService.as", "Follower mode activated!");
			
			followerModeEnabled = true;
			serviceActive = false;
			clearTimeout(followerTimer);
			activateFollowerEventListeners()
			
			nextFunctionToCall = getFollowerGlucoseReadings;
			login();
		}
		
		private static function deactivateFollowerMode():void
		{
			Trace.myTrace("DexcomShareService.as", "Follower mode deactivated!");
			
			followerModeEnabled = false;
			clearTimeout(followerTimer);
			nextFollowDownloadTime = 0;
			followerAggressiveFetchRetry = 0;
			followerModerateFetchRetry = 0;
			ModelLocator.bgReadings.length = 0;
			deactivateFollowerEventListeners();
		}
		
		private static function activateFollowerEventListeners():void
		{
			deactivateMasterEventListeners();
			Spike.instance.addEventListener(SpikeEvent.APP_IN_FOREGROUND, onAppActivated);
		}
		
		private static function deactivateFollowerEventListeners():void
		{
			Spike.instance.removeEventListener(SpikeEvent.APP_IN_FOREGROUND, onAppActivated);
		}
		
		private static function setNextFollowerFetch():void
		{
			//Time variables
			var now:Number = new Date().valueOf();
			var latestBGReading:BgReading = BgReading.lastNoSensor();
			
			if (latestBGReading != null) 
			{
				if (now - latestBGReading.timestamp >= TimeSpan.TIME_5_MINUTES_20_SECONDS)
				{
					//We missed at least a reading. Start with more aggressive into less aggressive fetch strategies.
					if (followerAggressiveFetchRetry < 3)
					{
						//Try in 10 seconds. 3 aggressive mode retries.
						nextFollowDownloadTime = now + TimeSpan.TIME_10_SECONDS; 
						followerAggressiveFetchRetry++
					}
					else if (followerModerateFetchRetry < 10)
					{
						//Try in 1 minute. 10 moderate mode retries.
						nextFollowDownloadTime = now + TimeSpan.TIME_1_MINUTE; 
						followerModerateFetchRetry++
					}
					else
					{
						//Try every 5 minuets. Light mode that goes on indefinitely
						nextFollowDownloadTime = latestBGReading.timestamp + TimeSpan.TIME_5_MINUTES_20_SECONDS;
						while (nextFollowDownloadTime < now) 
						{
							nextFollowDownloadTime += TimeSpan.TIME_5_MINUTES;
						}
					}
				}
				else
				{
					//Last reading fetch was successful. Set next fetch to 5m20s after last reading.
					nextFollowDownloadTime = latestBGReading.timestamp + TimeSpan.TIME_5_MINUTES_20_SECONDS;
					while (nextFollowDownloadTime < now) 
					{
						nextFollowDownloadTime += TimeSpan.TIME_5_MINUTES;
					}
				}
			}
			else
			{
				//We still don't have readings. Start with more aggressive into less aggressive fetch strategies.
				if (followerAggressiveFetchRetry < 3)
				{
					//Try in 30 seconds. 3 aggressive mode retries.
					nextFollowDownloadTime = now + TimeSpan.TIME_30_SECONDS;
					followerAggressiveFetchRetry++;
				}
				else if (followerModerateFetchRetry < 10)
				{
					//Try in 1 minute. 10 moderate mode retries.
					nextFollowDownloadTime = now + TimeSpan.TIME_1_MINUTE;
					followerModerateFetchRetry++;
				}
				else
				{
					//Try every 5 minuets. Light mode that goes on indefinitely
					nextFollowDownloadTime = now + TimeSpan.TIME_5_MINUTES;	
				}
			}
			
			//Calculate timer interval
			var interval:Number = nextFollowDownloadTime - now;
			clearTimeout(followerTimer);
			followerTimer = setTimeout(getFollowerGlucoseReadings, interval);
			
			var timeSpan:TimeSpan = TimeSpan.fromMilliseconds(interval);
			Trace.myTrace("DexcomShareService.as", "Fetching new follower data in: " + timeSpan.minutes + "m " + timeSpan.seconds + "s");
		}
		
		private static function getFollowerGlucoseReadings():void
		{
			Trace.myTrace("DexcomShareService.as", "getFollowerGlucoseReadings called!");
			
			var now:Number = (new Date()).valueOf();
			var latestBGReading:BgReading = BgReading.lastWithCalculatedValue();
			
			if (latestBGReading != null && !isNaN(latestBGReading.timestamp) && now - latestBGReading.timestamp < TimeSpan.TIME_5_MINUTES)
			{
				Trace.myTrace("DexcomShareService.as", "Last BG reading is less than 5 minutes old. Ignoring...");
				
				return;
			}
			
			if (!CGMBlueToothDevice.isFollower() || CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FOLLOWER_MODE).toUpperCase() != "DEXCOM")
			{ 
				Trace.myTrace("DexcomShareService.as", "Spike is not in follower mode. Aborting!");
				
				deactivateFollowerMode();
				
				return
			}
			
			if (dsURLFollower == "" || dexcomShareSessionID == "")
			{
				Trace.myTrace("DexcomShareService.as", "Follower URL or Session ID is not set. Aborting!");
				
				deactivateFollowerMode();
				
				return;
			}
			
			if (!NetworkInfo.networkInfo.isReachable())
			{
				Trace.myTrace("DexcomShareService.as", "There's no Internet connection. Will try again later!");
				
				setNextFollowerFetch();
				
				return;
			}
			
			if (nextFollowDownloadTime < now) 
			{
				var minutesToDownload:Number = 0;
				
				if (latestBGReading == null)
				{
					minutesToDownload = 24 * 60; //24h in minutes, 1 full day
					timeOfFirstBgReadingToDowload = now - TimeSpan.TIME_24_HOURS
				}
				else
				{
					minutesToDownload = (now - (latestBGReading.timestamp + 1)) / 1000 / 60; //iMnutes since last BG Reading
					timeOfFirstBgReadingToDowload = latestBGReading.timestamp + 1;
				}
				
				var parameters:URLVariables = new URLVariables();
				parameters["sessionId"] = dexcomShareSessionID;
				parameters["minutes"] = Math.round(minutesToDownload);
				parameters["maxCount"] = Math.round((minutesToDownload / 5) + 1);
				
				waitingForDSData = true;
				lastFollowDownloadAttempt = now;
				
				NetworkConnector.createDSConnector(dsURLFollower + "Publisher/ReadPublisherLatestGlucoseValues" + "?" + parameters.toString(), URLRequestMethod.POST, null, null, MODE_GET_FOLLOWER_READINGS, onGetFollowerReadingsComplete, onConnectionFailed);
			}
			else
			{
				Trace.myTrace("DexcomShareService.as", "Tried to make a fetch while in the past. Scheduling new fetch...");
				setNextFollowerFetch();
			}
		}
		
		private static function onGetFollowerReadingsComplete(e:flash.events.Event):void
		{
			if (serviceHalted)
				return;
			
			Trace.myTrace("DexcomShareService.as", "onGetFollowerReadingsComplete called");
			
			var now:Number = (new Date()).valueOf();
			
			//Get loader
			var loader:URLLoader = e.currentTarget as URLLoader;
			
			//Get response
			var response:String = loader.data;
			
			//Dispose loader
			loader.removeEventListener(flash.events.Event.COMPLETE, onGetFollowerReadingsComplete);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onConnectionFailed);
			loader = null;
			
			//Validate call
			if (!waitingForDSData || (now - lastFollowDownloadAttempt > TimeSpan.TIME_4_MINUTES_30_SECONDS)) 
			{
				Trace.myTrace("DexcomShareService.as", "Not waiting for data or last download attempt was more than 4 minutes, 30 seconds ago. Ignoring!");
				waitingForDSData = false;
				return;
			}
			
			waitingForDSData = false;
			
			//Validate response
			if (response.length == 0)
			{
				Trace.myTrace("DexcomShareService.as", "Server's gave an empty response. Retrying in a few minutes.");
				
				setNextFollowerFetch();
				return;
			}
			
			if (response.indexOf("[") != -1)
			{
				try
				{
					var BgReadingsToSend:Array = [];
					var DSResponseJSON:Object = SpikeJSON.parse(response);
					
					if (DSResponseJSON is Array)
					{
						var DSBgReadings:Array = DSResponseJSON as Array;
						var newData:Boolean = false;
						
						for (var arrayCounter:int = DSBgReadings.length - 1 ; arrayCounter >= 0; arrayCounter--)
						{
							var DSFollowReading:Object = DSBgReadings[arrayCounter];
							if (DSFollowReading.ST != null) 
							{
								var DSFollowReadingTime:Number = Number(String(DSFollowReading.ST).replace("/Date(", "").replace(")/", ""));
								if (now - DSFollowReadingTime > TimeSpan.TIME_24_HOURS_6_MINUTES)
								{
									continue;
								}
								
								if (isNaN(DSFollowReading.Value) || DSFollowReading.Value < 38)
								{
									continue;
								}
								
								if (DSFollowReadingTime >= timeOfFirstBgReadingToDowload) 
								{
									var bgReading:FollowerBgReading = new FollowerBgReading
									(
										DSFollowReadingTime, //timestamp
										null, //sensor id, not known here as the reading comes from NS
										null, //calibration object
										Number.NaN, //unfiltered (raw)
										Number.NaN, //filteres
										Number.NaN, //ageAdjustedRawValue
										false, //calibrationFlag
										DSFollowReading.Value >= 40 ? DSFollowReading.Value : 40, //calculatedValue
										Number.NaN, //filteredCalculatedValue
										Number.NaN, //CalculatedValueSlope
										Number.NaN, //a
										Number.NaN, //b
										Number.NaN, //c
										Number.NaN, //ra
										Number.NaN, //cb
										Number.NaN, //rc
										Number.NaN, //rawCalculated
										false, //hideSlope
										"", //noise
										DSFollowReadingTime, //lastmodifiedtimestamp
										UniqueId.createEventId() //unique id
									);  
									
									ModelLocator.addBGReading(bgReading);
									bgReading.findSlope(true);
									BgReadingsToSend.push(bgReading);
									newData = true;
								} 
								else
									continue;
							} 
							else 
							{
								Trace.myTrace("DexcomShareService.as", "Dexcom Share follower has returned a reading without date. Ignoring!");
							}
						}
						
						if (newData) 
						{
							//Notify Listeners
							instance.dispatchEvent(new FollowerEvent(FollowerEvent.BG_READING_RECEIVED, false, false, BgReadingsToSend));
							
							//Reset Variables
							followerAggressiveFetchRetry = 0;
							followerModerateFetchRetry = 0;
						}
					}
					else 
					{
						Trace.myTrace("DexcomShareService.as", "Dexcom Share follower response was not a JSON array. Ignoring! Response: " + response);
					}
					
				} 
				catch(error:Error) 
				{
					Trace.myTrace("DexcomShareService.as", "Unable to parse server response. Aborting! Response: " + response);
				}
			}
			else if (response.indexOf("SessionIdNotFound") != -1)
			{
				nextFunctionToCall = getFollowerGlucoseReadings;
				login(true);
				return;
			}
			else
			{
				Trace.myTrace("DexcomShareService.as", "Dexcom Share follower response was unknown. Ignoring! Response: " + response);
			}
			
			setNextFollowerFetch();
		}
		
		/**
		 * General Event Listeners
		 */
		private static function onConnectionFailed(error:Error, mode:String):void
		{
			//Validation
			if (serviceHalted)
				return;
			
			if (mode == MODE_GLUCOSE_READING)
			{
				Trace.myTrace("DexcomShareService.as", "in onConnectionFailed, Error uploading glucose readings. Error: " + error.message);
				syncGlucoseReadingsActive = false;
			}
			else if (mode == MODE_TEST_CREDENTIALS)
			{
				Trace.myTrace("DexcomShareService.as", "in onConnectionFailed, Authentication failed! Error: " + error.message);
				externalAuthenticationCall = false;
			}
			else if (mode == MODE_REMOTE_MONITORING_SESSION)
			{
				Trace.myTrace("DexcomShareService.as", "in onConnectionFailed, Remote monitoring session request failed! Error: " + error.message);
			}
			else if (mode == MODE_ASSIGN_RECEIVER)
			{
				Trace.myTrace("DexcomShareService.as", "in onConnectionFailed, Can't assign new receiver! Error: " + error.message);
			}
			else if (mode == MODE_LIST_FOLLOWERS)
			{
				Trace.myTrace("DexcomShareService.as", "in onConnectionFailed, Can't list followers! Error: " + error.message);
				instance.dispatchEvent(new DexcomShareEvent(DexcomShareEvent.LIST_FOLLOWERS, null));
			}
			else if (mode == MODE_DELETE_FOLLOWER)
			{
				Trace.myTrace("DexcomShareService.as", "in onConnectionFailed, Can't delete follower! Error: " + error.message);
				instance.dispatchEvent(new DexcomShareEvent(DexcomShareEvent.DELETE_FOLLOWER, null));
			}
			else if (mode == MODE_CREATE_CONTACT)
			{
				Trace.myTrace("DexcomShareService.as", "in onConnectionFailed, Can't create contact! Error: " + error.message);
				instance.dispatchEvent(new DexcomShareEvent(DexcomShareEvent.CREATE_CONTACT, null));
			}
			else if (mode == MODE_INVITE_FOLLOWER)
			{
				Trace.myTrace("DexcomShareService.as", "in onConnectionFailed, Can't invite follower! Error: " + error.message);
				instance.dispatchEvent(new DexcomShareEvent(DexcomShareEvent.INVITE_FOLLOWER, null));
			}
			else if (mode == MODE_GET_FOLLOWER_INFO)
			{
				Trace.myTrace("DexcomShareService.as", "in onConnectionFailed, Can't get follower info! Error: " + error.message);
				instance.dispatchEvent(new DexcomShareEvent(DexcomShareEvent.GET_FOLLOWER_INFO, null));
			}
			else if (mode == MODE_GET_FOLLOWER_ALARMS)
			{
				Trace.myTrace("DexcomShareService.as", "in onConnectionFailed, Can't get follower alarms! Error: " + error.message);
				instance.dispatchEvent(new DexcomShareEvent(DexcomShareEvent.GET_FOLLOWER_ALARMS, null));
			}
			else if (mode == MODE_CHANGE_FOLLOWER_NAME)
			{
				Trace.myTrace("DexcomShareService.as", "in onConnectionFailed, Can't change follower name! Error: " + error.message);
				instance.dispatchEvent(new DexcomShareEvent(DexcomShareEvent.CHANGE_FOLLOWER_NAME, null));
			}
			else if (mode == MODE_CHANGE_FOLLOWER_PERMISSIONS)
			{
				Trace.myTrace("DexcomShareService.as", "in onConnectionFailed, Can't change follower permissions! Error: " + error.message);
				instance.dispatchEvent(new DexcomShareEvent(DexcomShareEvent.CHANGE_FOLLOWER_PERMISSIONS, null));
			}
			else if (mode == MODE_ENABLE_FOLLOWER_SHARING)
			{
				Trace.myTrace("DexcomShareService.as", "in onConnectionFailed, Can't enable follower sharing! Error: " + error.message);
				instance.dispatchEvent(new DexcomShareEvent(DexcomShareEvent.ENABLE_FOLLOWER_SHARING, null));
			}
			else if (mode == MODE_DISABLE_FOLLOWER_SHARING)
			{
				Trace.myTrace("DexcomShareService.as", "in onConnectionFailed, Can't disable follower sharing! Error: " + error.message);
				instance.dispatchEvent(new DexcomShareEvent(DexcomShareEvent.DISABLE_FOLLOWER_SHARING, null));
			}
			else if (mode == MODE_GET_FOLLOWER_READINGS)
			{
				Trace.myTrace("DexcomShareService.as", "in onConnectionFailed, Can't fetch follower readings! Error: " + error.message);
				setNextFollowerFetch();
			}
		}
		
		private static function onSettingChanged(e:SettingsServiceEvent):void
		{
			//Validation
			if (serviceHalted)
				return;
			
			if (!CGMBlueToothDevice.isFollower())
			{
				setupDexcomShareProperties();
			}
			else
			{
				setupFollowerProperties();
			}
			
			if (ignoreSettingsChanged)
			{
				ignoreSettingsChanged = false;
				return;
			}
			
			if (e.data == CommonSettings.COMMON_SETTING_DEXCOM_SHARE_ON) 
			{
				if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEXCOM_SHARE_ON) == "false")
				{
					Trace.myTrace("DexcomShareService.as", "onSettingChanged called, deactivating service.");
					deactivateService();
					return;
				}
				else
				{
					if (accountName == "" || accountPassword == "")
					{
						Trace.myTrace("DexcomShareService.as", "onSettingChanged called, user or password are blank, deactivating service.");
						deactivateService();
						return;
					}
					
					if (!serviceActive)
					{
						Trace.myTrace("DexcomShareService.as", "onSettingChanged called, activating service.");
						activateService();
					}
				}
			}
			
			if (!CGMBlueToothDevice.isFollower() &&
				(e.data == CommonSettings.COMMON_SETTING_DEXCOM_SHARE_ACCOUNTNAME || 
				e.data == CommonSettings.COMMON_SETTING_DEXCOM_SHARE_PASSWORD || 
				e.data == CommonSettings.COMMON_SETTING_DEXCOM_SHARE_US_URL ||
				e.data == CommonSettings.COMMON_SETTING_DEXCOM_SHARE_SERIALNUMBER)) 
			{
				Trace.myTrace("DexcomShareService.as", "onSettingChanged called, account name, password or URL changed. Resetting session ID and login again.");
				dexcomShareSessionID = "";
				
				if (followerModeEnabled)
				{
					deactivateFollowerMode();
				}
				
				if (accountName == "" || accountPassword == "")
				{
					deactivateService();
					return;
				}
				
				nextFunctionToCall = getInitialMasterGlucoseReadings;
				login();
			} 
			
			if (CGMBlueToothDevice.isFollower()
				&&
				(e.data == CommonSettings.COMMON_SETTING_DATA_COLLECTION_DS_USERNAME ||
				e.data == CommonSettings.COMMON_SETTING_DATA_COLLECTION_DS_PASSWORD ||
				e.data == CommonSettings.COMMON_SETTING_DATA_COLLECTION_DS_SERVER) ||
				e.data == CommonSettings.COMMON_SETTING_FOLLOWER_MODE && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FOLLOWER_MODE) == "Dexcom") 
			{
				dexcomShareSessionID = "";
				
				if (serviceActive)
				{
					deactivateService();
				}
				
				if (dsUsernameFollower == "" || dsPasswordFollower == "")
				{
					deactivateFollowerMode();
					return;
				}
				
				if (!followerModeEnabled)
				{
					activateFollower();
				}
				else
				{
					nextFunctionToCall = getFollowerGlucoseReadings;
					login();
				}
			}
			
			if (e.data == CommonSettings.COMMON_SETTING_DATA_COLLECTION_MODE)
			{
				if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_MODE) == "Follower")
				{
					deactivateService();
					setupFollowerProperties();
					if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FOLLOWER_MODE) == "Dexcom"
						&&
						CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_DS_USERNAME) != ""
						&&
						CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_DS_PASSWORD) != ""
						)
					{
						nextFunctionToCall = getFollowerGlucoseReadings;
						activateFollower();
					}
				}
				else
				{
					if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEXCOM_SHARE_ON) == "true" &&
						CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEXCOM_SHARE_ACCOUNTNAME) != "" &&
						CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEXCOM_SHARE_PASSWORD) != "" &&
						!CGMBlueToothDevice.isFollower())
					{
						setupDexcomShareProperties();
						nextFunctionToCall = getInitialMasterGlucoseReadings;
						activateService();
					}
				}
			}
		}
		
		private static function onServiceTimer(e:TimerEvent):void
		{
			resync();
		}
		
		private static function onAppActivated(e:flash.events.Event):void
		{
			Trace.myTrace("DexcomShareService.as", "App in foreground. Calling resync.");
			resync();
		}
		
		private static function onNetworkChange( event:NetworkInfoEvent ):void
		{
			if(NetworkInfo.networkInfo.isReachable() && networkChangeOcurrances > 0)
			{
				Trace.myTrace("DexcomShareService.as", "Network is reachable again. Calling resync.");
				resync();
			}
			else
				networkChangeOcurrances++;
		}
		
		/**
		 * Stops the service entirely. Useful for database restores
		 */
		private static function onHaltExecution(e:SpikeEvent):void
		{
			Trace.myTrace("DexcomShareService.as", "Stopping service...");
			
			serviceHalted = true;
			
			CommonSettings.instance.removeEventListener(SettingsServiceEvent.SETTING_CHANGED, onSettingChanged);
			
			deactivateService();
		}
		
		/**
		 * Utility
		 */
		private static function toDateString(timestamp:Number):String 
		{
			var shortened:Number = Math.floor(timestamp/1000);
			return "/Date(" + (Number(shortened * 1000)).toString() + ")/";
		}
		
		public static function isAuthorized():Boolean
		{
			if (dexcomShareSessionID !== "")
				return true;
			
			return false;
		}
		
		/**
		 * Getters & Setters (With Timeout Management)
		 */
		private static function get syncGlucoseReadingsActive():Boolean
		{
			if (!_syncGlucoseReadingsActive)
				return false;
			
			var now:Number = (new Date()).valueOf();
			
			if (now - syncGlucoseReadingsActiveLastChange > MAX_SYNC_TIME)
			{
				syncGlucoseReadingsActiveLastChange = now;
				_syncGlucoseReadingsActive = false;
				return false;
			}
			
			return true;
		}
		
		private static function set syncGlucoseReadingsActive(value:Boolean):void
		{
			syncGlucoseReadingsActiveLastChange = (new Date()).valueOf();
			_syncGlucoseReadingsActive = value;
		}
	}
}