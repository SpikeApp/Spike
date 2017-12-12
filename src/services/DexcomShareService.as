package services
{
	import com.distriqt.extension.networkinfo.NetworkInfo;
	import com.freshplanet.ane.AirBackgroundFetch.BackgroundFetch;
	
	import flash.events.EventDispatcher;
	import flash.net.URLRequestMethod;
	
	import Utilities.Trace;
	
	import databaseclasses.BgReading;
	import databaseclasses.BlueToothDevice;
	import databaseclasses.CommonSettings;
	
	import events.BackGroundFetchServiceEvent;
	import events.SettingsServiceEvent;
	
	import model.ModelLocator;
	
	import views.SettingsView;

	public class DexcomShareService extends EventDispatcher
	{
		[ResourceBundle("dexcomshareservice")]
		
		private static const US_SHARE_BASE_URL:String = "https://share2.dexcom.com/ShareWebServices/Services/";
		private static const NON_US_SHARE_BASE_URL:String = "https://shareous1.dexcom.com/ShareWebServices/Services/";

		private static var initialStart:Boolean = true;
		
		private static var dexcomShareStatus:String = "";
		private static const dexcomShareStatus_Waiting_LoginPublisherAccountByName:String = "Waiting_LoginPublisherAccountByName";
		private static const dexcomShareStatus_Waiting_PostReceiverEgvRecords:String = "Waiting_PostReceiverEgvRecords";
		private static const dexcomShareStatus_Waiting_StartRemoteMonitoringSession:String = "Waiting_StartRemoteMonitoringSession";
		private static const dexcomShareStatus_Waiting_credentialTest:String = "Waiting_credentialTest";
		private static var dexcomShareSessionId:String = "";
		
		private static var _syncRunning:Boolean = false;
		private static var lastSyncrunningChangeDate:Number = (new Date()).valueOf();
		private static const maxMinutesToKeepSyncRunningTrue:int = 1;
		private static var timeStampOfLastSSO_AuthenticateMaxAttemptsExceeed:Number = 0;
		private static const timeToWaitAfterSSO_AuthenticateMaxAttemptsExceeedInMinutes = 10;
		private static var timeStampOfLastLoginAttemptSinceJSONParsingErrorReceived:Number = 0;

		private static var dexcomShareUrl:String = "";

		public static function DexcomShareSyncRunning():Boolean {
			return syncRunning;
		}

		private static function get syncRunning():Boolean
		{
			if (!_syncRunning)
				return false;
			
			if ((new Date()).valueOf() - lastSyncrunningChangeDate > maxMinutesToKeepSyncRunningTrue * 60 * 1000) {
				lastSyncrunningChangeDate = (new Date()).valueOf();
				_syncRunning = false;
				return false;
			}
			return true;
		}
		
		/**
		 * if value is false then sets also  dexcomShareStatus = ""
		 */
		private static function set syncRunning(value:Boolean):void
		{
			myTrace("set syncRunning to " + value);
			_syncRunning = value;
			lastSyncrunningChangeDate = (new Date()).valueOf();
			if (_syncRunning == false)
				dexcomShareStatus = "";
		}

		public function DexcomShareService()
		{
			if (_instance != null) {
				throw new Error("DexcomShareService class constructor can not be used");	
			}
		}
		
		private static var _instance:DexcomShareService = new DexcomShareService();
		
		public static function get instance():DexcomShareService
		{
			return _instance;
		}

		public static function init():void {
			if (!initialStart)
				return;
			else
				initialStart = false;
			
			BackGroundFetchService.instance.addEventListener(BackGroundFetchServiceEvent.LOAD_REQUEST_ERROR, createAndLoadUrlRequestFailed);
			BackGroundFetchService.instance.addEventListener(BackGroundFetchServiceEvent.LOAD_REQUEST_RESULT, createAndLoadUrlRequestSuccess);
			CommonSettings.instance.addEventListener(SettingsServiceEvent.SETTING_CHANGED, settingChanged);
			dexcomShareUrl = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEXCOM_SHARE_US_URL) == "true" ?
				US_SHARE_BASE_URL
				:
				NON_US_SHARE_BASE_URL;
		}
		
		private static function settingChanged(event:SettingsServiceEvent):void {
			if (event.data == CommonSettings.COMMON_SETTING_DEXCOM_SHARE_US_URL) {
				dexcomShareUrl = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEXCOM_SHARE_US_URL) == "true" ?
					US_SHARE_BASE_URL
					:
					NON_US_SHARE_BASE_URL;
				myTrace("in settingChanged, reinitialising share url to " + dexcomShareUrl);
			}
			
			if (event.data == CommonSettings.COMMON_SETTING_DEXCOM_SHARE_ACCOUNTNAME 
				|| 
				event.data == CommonSettings.COMMON_SETTING_DEXCOM_SHARE_PASSWORD 
				|| 
				event.data == CommonSettings.COMMON_SETTING_DEXCOM_SHARE_US_URL) {
				myTrace("in settingChanged, account name or password or url changed, resetting session id");
				dexcomShareSessionId = "";
			} 

			if (event.data == CommonSettings.COMMON_SETTING_DEXCOM_SHARE_ACCOUNTNAME 
				|| 
				event.data == CommonSettings.COMMON_SETTING_DEXCOM_SHARE_PASSWORD) {
				if (NetworkInfo.networkInfo.isReachable()) {
					myTrace("in settingChanged, calling testCredentials");
					testCredentials();
				} else {
					myTrace("in settingChanged, but network not reachable");
				}
			} else if (event.data == CommonSettings.COMMON_SETTING_DEXCOM_SHARE_ON
				|| 
				event.data == CommonSettings.COMMON_SETTING_DEXCOM_SHARE_SERIALNUMBER
				|| 
				event.data == CommonSettings.COMMON_SETTING_DEXCOM_SHARE_US_URL) {
				if (NetworkInfo.networkInfo.isReachable()) {
					myTrace("in settingChanged, calling sync");
					sync();
				} else {
					myTrace("in settingChanged, but network not reachable");
				}
			} 
		}
		
		public static function sync():void {
			myTrace("in sync");
			if (!NetworkInfo.networkInfo.isReachable()) {
				myTrace("network not reachable, return");
				return;
			}

			if (syncRunning) {
				myTrace("sync running already, return");
				return;
			} else if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEXCOM_SHARE_ON) == "false") {
				myTrace("in sync, COMMON_SETTING_DEXCOM_SHARE_ON == false, return");
				return;
			} else if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEXCOM_SHARE_ACCOUNTNAME) == "account name") {
				myTrace("in sync, COMMON_SETTING_DEXCOM_SHARE_ACCOUNTNAME == default value, return");
				return;
			} else if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEXCOM_SHARE_PASSWORD) == "password") {
				myTrace("in sync, COMMON_SETTING_DEXCOM_SHARE_PASSWORD == default value, return");
				return;
			} else {
				if (NightScoutService.NightScoutSyncRunning()) {
					myTrace("nightscoutsync running already, return");
					return;
				}
			}
			
			if ((new Date()).valueOf() - timeStampOfLastSSO_AuthenticateMaxAttemptsExceeed < timeToWaitAfterSSO_AuthenticateMaxAttemptsExceeedInMinutes * 60 * 1000) {
				myTrace("in sync, SSO_AuthenticateMaxAttemptsExceeed was less than " + timeToWaitAfterSSO_AuthenticateMaxAttemptsExceeedInMinutes + " minutes ago, return");
				return;
			}

			syncRunning = true;
			
			if (dexcomShareSessionId != "") {
				myTrace("in sync, dexcomShareSessionId not empty calling uploadBGRecords"),
				uploadBGRecords();
			} else {
				myTrace("in sync, dexcomShareSessionId empty trying to login");
				login();
			}
		}
		
		private static function login():void {
			myTrace("in login");
			var authParameters:Object = new Object();
			authParameters["accountName"] = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEXCOM_SHARE_ACCOUNTNAME);
			authParameters["applicationId"] = "d8665ade-9673-4e27-9ff6-92db4ce13d13";
			authParameters["password"] = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEXCOM_SHARE_PASSWORD);
			BackGroundFetchService.createAndLoadUrlRequest(dexcomShareUrl + "General/LoginPublisherAccountByName", URLRequestMethod.POST, null, JSON.stringify(authParameters), "application/json");
			dexcomShareStatus = dexcomShareStatus_Waiting_LoginPublisherAccountByName;
		}
		
		private static function testCredentials():void {
			myTrace("in testCredentials");
			if (syncRunning || NightScoutService.NightScoutSyncRunning()) {
				myTrace("dexcom or nightscout sync running, return");
				return;
			}
			if (NetworkInfo.networkInfo.isReachable()) {
				login();
				dexcomShareStatus = dexcomShareStatus_Waiting_credentialTest;
			} else {
				myTrace("in testCredentials but network  not reachable");
			}
		}
		
		private static function createAndLoadUrlRequestSuccess(event:BackGroundFetchServiceEvent):void {
			if (dexcomShareStatus == dexcomShareStatus_Waiting_LoginPublisherAccountByName) {
				myTrace("in createAndLoadUrlRequestSuccess and dexcomShareStatus == dexcomShareStatus_Waiting_LoginPublisherAccountByName");
				myTrace("in createAndLoadUrlRequestSuccess event.data.information = " + event.data.information as String);
				dexcomShareSessionId = event.data.information.split('"').join('');
				myTrace("in createAndLoadUrlRequestSuccess, dexcomShareSessionId = " + dexcomShareSessionId); 
				uploadBGRecords();
			} else if (dexcomShareStatus == dexcomShareStatus_Waiting_PostReceiverEgvRecords) {
				myTrace("in createAndLoadUrlRequestSuccess and dexcomShareStatus == dexcomShareStatus_Waiting_PostReceiverEgvRecords");
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_DEXCOMSHARE_SYNC_TIMESTAMP, (new Date()).valueOf().toString());
				syncRunning = false;
			} else if (dexcomShareStatus == dexcomShareStatus_Waiting_StartRemoteMonitoringSession) {
				myTrace("in createAndLoadUrlRequestSuccess and dexcomShareStatus == dexcomShareStatus_Waiting_StartRemoteMonitoringSession");
				uploadBGRecords();
			} else if (dexcomShareStatus == dexcomShareStatus_Waiting_credentialTest) {
				myTrace("in createAndLoadUrlRequestSuccess and dexcomShareStatus == dexcomShareStatus_Waiting_credentialTest");
				if (BackgroundFetch.appIsInForeground()) {
					DialogService.openSimpleDialog(ModelLocator.resourceManagerInstance.getString("dexcomshareservice","credentialtest"),
						ModelLocator.resourceManagerInstance.getString("dexcomshareservice","credentialtest_success"),
						60);
					sync();
				}
			}
		}
		
		private static function uploadBGRecords():void {
			dexcomShareStatus = dexcomShareStatus_Waiting_PostReceiverEgvRecords;
			myTrace("in uploadBGRecords");
			var lastSyncTimeStamp:Number = new Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEXCOMSHARE_SYNC_TIMESTAMP));
			var now:Number = (new Date()).valueOf();
			var Egvs:Array = [];
			
			var cntr:int = ModelLocator.bgReadings.length - 1;
			var arrayCntr:int = 0;
			
			while (cntr > -1) {
				var bgReading:BgReading = ModelLocator.bgReadings.getItemAt(cntr) as BgReading;
				if (bgReading.timestamp > lastSyncTimeStamp && now - bgReading.timestamp < 24 * 3600 * 1000) {
					if (bgReading.calculatedValue != 0) {
						var newReading:Object = new Object();
						newReading.Trend = bgReading.getSlopeOrdinal();
						newReading.ST = toDateString(bgReading.timestamp);
						newReading.DT = newReading.ST;
						newReading.Value = Math.round(bgReading.calculatedValue);

						newReading["direction"] = bgReading.slopeName();
						Egvs[arrayCntr] = newReading;
					}
				} else {
					break;
				}
				cntr--;
				arrayCntr++;
			}		
			
			if (Egvs.length > 0) {
				myTrace("in uploadBGRecords, there are " + Egvs.length + " records to upload");
				var uploaddata:Object = new Object();
				uploaddata.Egvs = Egvs;
				uploaddata.SN = getSerialNumber();
				uploaddata.TA = -5;
				dexcomShareStatus = dexcomShareStatus_Waiting_PostReceiverEgvRecords;
				myTrace("dexcomShareUrl = " + dexcomShareUrl);
				myTrace("uploaddata = " + JSON.stringify(uploaddata));
				BackgroundFetch.createAndLoadDexWithJSONDataUrlRequest(dexcomShareUrl + "Publisher/PostReceiverEgvRecords",  
					URLRequestMethod.POST, 
					JSON.stringify(uploaddata),
					"sessionId", dexcomShareSessionId );
			} else {
				myTrace("in uploadBGRecords, no records to upload");
				syncRunning = false;
			}
		}

		private static function createAndLoadUrlRequestFailed(event:BackGroundFetchServiceEvent):void {
			if (dexcomShareStatus == "") {
				myTrace("in createAndLoadUrlRequestFailed but dexcomShareStatus is empty, not interested, returning");
				return;
			}
			
			var eventDataInformation:String;
			if (event.data) {
				if (event.data.information) {
					eventDataInformation = event.data.information as String;
				} else {
					myTrace("in createAndLoadUrlRequestFailed but there's no event.data.information, returning");
					syncRunning = false;
					return;
				}
			} else {
				myTrace("in createAndLoadUrlRequestFailed but there's no event.data, returning");
				syncRunning = false;
				return;
			}

			var code:String = "";
			var eventAsJSONObject:Object;
			try {
				eventAsJSONObject = JSON.parse(eventDataInformation);
			} catch (error:Error) {
				myTrace("in createAndLoadUrlRequestFailed, exception while json parsing, error = " + error.message);
				if ((new Date()).valueOf() - timeStampOfLastLoginAttemptSinceJSONParsingErrorReceived > 4.5 * 60 * 1000) {
					myTrace("in createAndLoadUrlRequestFailed, trying new login");
					timeStampOfLastLoginAttemptSinceJSONParsingErrorReceived = (new Date()).valueOf();
					dexcomShareSessionId = "";
					syncRunning = true;
					login();
					return;
				} else {
					myTrace("in createAndLoadUrlRequestFailed, not trying new login");
					syncRunning = false;
					return;
				}
			}
			
			if (!eventAsJSONObject.Code) {
				myTrace("in createAndLoadUrlRequestFailed, there's no code in the response, returning");
				syncRunning = false;
				return;
			}
			
			code = eventAsJSONObject.Code as String;
			myTrace("in createAndLoadUrlRequestFailed and code = " + code);

			if (code == "SessionNotValid" || code == "SessionIdNotFound") {
				dexcomShareSessionId = "";
				syncRunning = true;
				login();
				return;
			}

			if (dexcomShareStatus == dexcomShareStatus_Waiting_PostReceiverEgvRecords) {
				myTrace("in createAndLoadUrlRequestFailed and dexcomShareStatus == dexcomShareStatus_Waiting_PostReceiverEgvRecords, code = " + code);
				if (code == "MonitoringSessionNotActive") {
					dexcomShareStatus == dexcomShareStatus_Waiting_StartRemoteMonitoringSession;
					BackGroundFetchService.createAndLoadUrlRequest(dexcomShareUrl + "Publisher/StartRemoteMonitoringSession?sessionId=" + 
						escape(dexcomShareSessionId) + "&serialNumber=" +
						escape(getSerialNumber()),
						URLRequestMethod.POST, 
						null,
						null,
						"application/json");
				} else if (code == "DuplicateEgvPosted") {
					myTrace("code DuplicateEgvPosted, treated as successful and setting lastsynctimestamp to current data and time");
					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_DEXCOMSHARE_SYNC_TIMESTAMP, (new Date()).valueOf().toString());
					syncRunning = false;
				} else if (code == "MonitoredReceiverSerialNumberDoesNotMatch") {
					myTrace("code MonitoredReceiverSerialNumberDoesNotMatch");
					if (BackgroundFetch.appIsInForeground()) {
						DialogService.openSimpleDialog(ModelLocator.resourceManagerInstance.getString("dexcomshareservice","upload_error"),
							ModelLocator.resourceManagerInstance.getString("dexcomshareservice","monitored_receiver_sn_doesnotmatch"),
							60);
					}
					syncRunning = false;
				} else if (code == "MonitoredReceiverNotAssigned") {
					myTrace("code MonitoredReceiverNotAssigned");
					if (BackgroundFetch.appIsInForeground()) {
						var message:String =
							ModelLocator.resourceManagerInstance.getString("dexcomshareservice","monitored_receiver_not_assigned_1") +
							" " + (BlueToothDevice.isDexcomG4() ? CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEXCOM_SHARE_SERIALNUMBER)
								:  CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TRANSMITTER_ID)) + " " +
							ModelLocator.resourceManagerInstance.getString("dexcomshareservice","monitored_receiver_not_assigned_2") +
							" " + CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEXCOM_SHARE_ACCOUNTNAME) + ". " +
							ModelLocator.resourceManagerInstance.getString("dexcomshareservice","monitored_receiver_not_assigned_3");
						DialogService.openSimpleDialog(ModelLocator.resourceManagerInstance.getString("dexcomshareservice","upload_error"),
							message,
							60);
					}
					syncRunning = false;
				}  else {
					myTrace("in createAndLoadUrlRequestFailed, unknown code for status dexcomShareStatus_Waiting_PostReceiverEgvRecords");
					syncRunning = false;
				} 
			} else if (dexcomShareStatus == dexcomShareStatus_Waiting_LoginPublisherAccountByName) {
				myTrace("in createAndLoadUrlRequestFailed and dexcomShareStatus == dexcomShareStatus_Waiting_LoginPublisherAccountByName, code = " + code);
				syncRunning = false;
				if (code == "SSO_AuthenticateAccountNotFound") {
					if (BackgroundFetch.appIsInForeground()) {
						DialogService.openSimpleDialog(ModelLocator.resourceManagerInstance.getString("dexcomshareservice","login_error"),
							ModelLocator.resourceManagerInstance.getString("dexcomshareservice","account_name_not_found"),
							60);
					}
				} else if (code == "SSO_AuthenticatePasswordInvalid") {
					if (BackgroundFetch.appIsInForeground()) {
						DialogService.openSimpleDialog(ModelLocator.resourceManagerInstance.getString("dexcomshareservice","login_error"),
							ModelLocator.resourceManagerInstance.getString("dexcomshareservice","invalid_password"),
							60);
					}
				} else if (code == "SSO_AuthenticateMaxAttemptsExceeed") {
					if (BackgroundFetch.appIsInForeground()) {
						DialogService.openSimpleDialog(ModelLocator.resourceManagerInstance.getString("dexcomshareservice","login_error"),
							ModelLocator.resourceManagerInstance.getString("dexcomshareservice","max_login_attempts_excceded"),
							60);
						timeStampOfLastSSO_AuthenticateMaxAttemptsExceeed = (new Date()).valueOf();
					}
				} else {
					myTrace("in createAndLoadUrlRequestFailed, unknown code for status dexcomShareStatus_Waiting_LoginPublisherAccountByName");
				}
			} else if (dexcomShareStatus == dexcomShareStatus_Waiting_StartRemoteMonitoringSession) {
				myTrace("in createAndLoadUrlRequestFailed and dexcomShareStatus == dexcomShareStatus_Waiting_StartRemoteMonitoringSession");
				syncRunning = false;
			} else if (dexcomShareStatus == dexcomShareStatus_Waiting_credentialTest) {
				myTrace("in createAndLoadUrlRequestFailed and dexcomShareStatus == dexcomShareStatus_Waiting_credentialTest");
				var errorMessage:String = "";
				if (code == "SSO_AuthenticateAccountNotFound") {
					errorMessage = ModelLocator.resourceManagerInstance.getString("dexcomshareservice","account_name_not_found");
				} else if (code == "SSO_AuthenticatePasswordInvalid") {
					errorMessage = ModelLocator.resourceManagerInstance.getString("dexcomshareservice","invalid_password");
				} else if (code == "SSO_AuthenticateMaxAttemptsExceeed") {
					errorMessage = ModelLocator.resourceManagerInstance.getString("dexcomshareservice","dexcom_max_login_attempts_exceeded");
				} else {
					errorMessage = code;
				}
				if (BackgroundFetch.appIsInForeground()) {
					DialogService.openSimpleDialog(ModelLocator.resourceManagerInstance.getString("dexcomshareservice","login_error"),
						errorMessage,
						60);
				}
				dexcomShareStatus = "";
			} else {
				myTrace("in createAndLoadUrlRequestFailed and dexcomShareStatus == " + dexcomShareStatus);
				syncRunning = false;
			} 
		}
		
		private static function toDateString(timestamp:Number):String {
			var shortened:Number = Math.floor(timestamp/1000);
			return "/Date(" + (new Number(shortened * 1000)).toString() + ")/";
		}
		
		private static function getSerialNumber():String {
			return (BlueToothDevice.isDexcomG5() ? CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TRANSMITTER_ID) : CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEXCOM_SHARE_SERIALNUMBER));
		}
		
		private static function myTrace(log:String):void {
			Trace.myTrace("DexcomShareService.as", log);
		}
	}
}