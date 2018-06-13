package services
{
	import com.distriqt.extension.networkinfo.NetworkInfo;
	import com.hurlant.crypto.hash.SHA1;
	import com.hurlant.util.Hex;
	import com.spikeapp.spike.airlibrary.SpikeANE;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.TimerEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.utils.Timer;
	
	import database.BgReading;
	import database.CGMBlueToothDevice;
	import database.CommonSettings;
	import database.LocalSettings;
	
	import events.SettingsServiceEvent;
	import events.TransmitterServiceEvent;
	
	import network.NetworkConnector;
	
	import utils.SpikeJSON;
	import utils.Trace;
	import utils.libre.GlucoseData;

	public class MultipleMiaoMiaoService
	{
		/* Constants */
		private static const TIME_8_HOURS:int = 8 * 60 * 60 * 1000;
		private static const TIME_1_HOUR:int = 60 * 60 * 1000;
		private static const TIME_4_MINUTES_30_SECONDS:int = (4 * 60 * 1000) + 30000;

		//timers
		//timer to reconnect to MiaoMiao
		private static var reconnectTimer:Timer;
		//timer to check if reading was received on time
		private static var checkReadingTimer:Timer;
		
		//NightScout download
		private static var nightscoutDownloadURL:String = "";
		private static var nightscoutDownloadOffset:Number = 0;
		private static var nightscoutDownloadAPISecret:String = "";
		private static var waitingForNSData:Boolean = false;
		private static var lastNSDownloadAttempt:Number;
		private static const MODE_GLUCOSE_READING_GET:String = "glucoseReadingGet";
		private static var timeOfFirstBgReadingToDowload:Number;
		
		/* Objects */
		private static var hash:SHA1 = new SHA1();
	
		public function MultipleMiaoMiaoService() {
		}
		
		public static function init():void {
			myTrace("init");
			CommonSettings.instance.addEventListener(SettingsServiceEvent.SETTING_CHANGED, commonSettingChanged);
			
			//initialize variables
			setupService();
			
			//immediately start with checking if we have the latest reading
			checkLatestReading();
		}

		private static function bgReadingReceived(be:TransmitterServiceEvent):void {
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_MIAOMIAO_MULTIPLE_DEVICE_ON) == "true"
				&&
				CGMBlueToothDevice.isMiaoMiao()) {
				//temporary disconnecting to allow other ios device to connect to the miaomiao
				//It doesn't harm to make this call even if there's no miaomiao connection for the moment
				SpikeANE.disconnectMiaoMiao();
				
				if (reconnectTimer != null && reconnectTimer.running) {
					myTrace("reconnectTimer already running, not restarting");
				} else {
					//set reconnecttimer to 10 seconds
					reconnectTimer = new Timer(10 * 1000, 1);
					reconnectTimer.addEventListener(TimerEvent.TIMER, reconnect);
					reconnectTimer.start();
				}
				
				//start timer to verify if new reading was received on time
				if (checkReadingTimer != null && checkReadingTimer.running) {
					myTrace("checkReadingTimer already running, not restarting");
				} else {
					//set checkReadingTimer to 5 minutes and 20 seconds
					resetCheckReadingTimer(5 * 60 + 20);
				}
			}
		}
		
		private static function resetCheckReadingTimer(delayInSeconds:Number):void {
			if (checkReadingTimer != null && checkReadingTimer.running) {
				checkReadingTimer.stop();
			}
			if (isNaN(delayInSeconds)) {
				myTrace("in resetCheckReadingTimer but delayInSeconds is NAN, not starting timer");			
			} else {
				myTrace("in resetCheckReadingTimer setting timer with delay " + delayInSeconds);	
				checkReadingTimer = new Timer(delayInSeconds * 1000, 1);
				checkReadingTimer.addEventListener(TimerEvent.TIMER, checkLatestReading);
				checkReadingTimer.start();
			}
		}
		
		private static function checkLatestReading(event:Event = null):void {
			if (isMiaoMiaoMultiple()) {
				myTrace("in checkLatestReading");

				var latestBGReading:BgReading = BgReading.lastNoSensor();
				if (latestBGReading != null && !isNaN(latestBGReading.timestamp) && now - latestBGReading.timestamp < 5 * 60 * 1000) {
					return;
				}

				var now:Number = (new Date()).valueOf();
				
				if (nightscoutDownloadURL == "") {
					myTrace("in checkLatestReading, Download URL is not set. Aborting!");
					return;
				}
				
				if (!NetworkInfo.networkInfo.isReachable()) {
					myTrace("in checkLatestReading, There's no Internet connection. Will try again later!");
					resetCheckReadingTimer(calculateNextFollowDownloadDelayInSeconds(now, latestBGReading));
					return;
				}
				
				if (latestBGReading != null && !isNaN(latestBGReading.timestamp) && now - latestBGReading.timestamp < 5 * 60 * 1000) {
					myTrace("in checkLatestReading, there's a reading less than 5 minutes old");
					resetCheckReadingTimer(calculateNextFollowDownloadDelayInSeconds(now, latestBGReading));
					return;
				}
				
				if (latestBGReading == null) 
					timeOfFirstBgReadingToDowload = now - TIME_8_HOURS;
				else
					timeOfFirstBgReadingToDowload = latestBGReading.timestamp + 1; //We add 1ms to avoid overlaps
				
				var numberOfReadings:Number = ((now - timeOfFirstBgReadingToDowload) / TIME_1_HOUR * 12) + 1; //Add one more just to make sure we get all readings
				var parameters:URLVariables = new URLVariables();
				parameters["find[dateString][$gte]"] = timeOfFirstBgReadingToDowload;
				parameters["count"] = Math.round(numberOfReadings);
				
				waitingForNSData = true;
				lastNSDownloadAttempt = (new Date()).valueOf();
				
				NetworkConnector.createNSConnector(nightscoutDownloadURL + parameters.toString(), nightscoutDownloadAPISecret != "" ? nightscoutDownloadAPISecret : null, URLRequestMethod.GET, null, MODE_GLUCOSE_READING_GET, onDownloadGlucoseReadingsComplete, onConnectionFailed);
			}
		}
		
		private static function onConnectionFailed(error:Error, mode:String):void
		{
			if (mode == MODE_GLUCOSE_READING_GET)
			{
				myTrace("in onConnectionFailed. Can't make connection to the server while trying to download glucose readings. Error: " +  error.message);
				
				resetCheckReadingTimer(calculateNextFollowDownloadDelayInSeconds((new Date()).valueOf(), BgReading.lastNoSensor()));
			}
		}
		

		private static function onDownloadGlucoseReadingsComplete(e:Event):void {
			myTrace("in onDownloadGlucoseReadingsComplete");

			var glucoseData:GlucoseData;
			var now:Number = (new Date()).valueOf();
			
			//Validate call
			if (!waitingForNSData || (now - lastNSDownloadAttempt > TIME_4_MINUTES_30_SECONDS)) {
				myTrace("Not waiting for data or last download attempt was more than 4 minutes, 30 seconds ago. Ignoring!");
				waitingForNSData = false;
				resetCheckReadingTimer(calculateNextFollowDownloadDelayInSeconds(now, BgReading.lastNoSensor()));
				return;
			}
			
			waitingForNSData = false;
			
			//Get loader
			var loader:URLLoader = e.currentTarget as URLLoader;
			
			//Get response
			var response:String = loader.data;
			
			//Dispose loader
			loader.removeEventListener(Event.COMPLETE, onDownloadGlucoseReadingsComplete);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onDownloadGlucoseReadingsComplete);
			loader = null;
			
			//Validate response
			if (response.length == 0) {
				myTrace("in onDownloadGlucoseReadingsComplete, Server's gave an empty response. Retry later.");
				resetCheckReadingTimer(calculateNextFollowDownloadDelayInSeconds(now, BgReading.lastNoSensor()));
				return;
			}
			
			//temporary remove the eventlistener, because BGREADING_EVENTs are going to be dispatched 
			TransmitterService.instance.removeEventListener(TransmitterServiceEvent.LAST_BGREADING_RECEIVED, bgReadingReceived);
			
			try {
				var NSResponseJSON:Object = SpikeJSON.parse(response);
				if (NSResponseJSON is Array) {
					var NSBgReadings:Array = NSResponseJSON as Array;
					var newData:Boolean = false;
					var bgReadingList:Array = new Array();//arraylist of glucosedata
					myTrace("in onDownloadGlucoseReadingsComplete, received " + (NSBgReadings.length - 1) + " readings.");
					for(var arrayCounter:int = NSBgReadings.length - 1 ; arrayCounter >= 0; arrayCounter--) {
						var NSDownloadReading:Object = NSBgReadings[arrayCounter];
						if (NSDownloadReading.date) {
							var NSDownloadReadingDate:Date = new Date(NSDownloadReading.date);
							NSDownloadReadingDate.setMinutes(NSDownloadReadingDate.minutes + nightscoutDownloadOffset);
							var NSDownloadReadingTime:Number = NSDownloadReadingDate.valueOf();
							if (NSDownloadReadingTime >= timeOfFirstBgReadingToDowload) {
								glucoseData = new GlucoseData();
								glucoseData.glucoseLevelRaw = NSDownloadReading.unfiltered as int;
								glucoseData.realDate = NSDownloadReadingTime;
								bgReadingList.push(glucoseData);
								myTrace("in onDownloadGlucoseReadingsComplete, adding glucosedata with realdate =  " + (new Date(NSDownloadReadingTime)).toString() + " and value = " + glucoseData.glucoseLevelRaw);
							} else {
								myTrace("in onDownloadGlucoseReadingsComplete, ignored with realdate =  " + (new Date(NSDownloadReadingTime)).toString() + " because timestamp < " + (new Date(NSDownloadReadingTime)).toString());
							}
						} else {
							myTrace("in onDownloadGlucoseReadingsComplete, Nightscout has returned a reading without date. Ignoring!");
							if (NSDownloadReading._id)
								myTrace("in onDownloadGlucoseReadingsComplete, Reading ID: " + NSDownloadReading._id);
						}
					}
					
					//sort the array, old reading needs to be treated first
					bgReadingList.sortOn(["realDate"], Array.NUMERIC);
					
					//process all readings
					for (var cntr:int = 0; cntr < bgReadingList.length ;cntr ++) {
						var gd:GlucoseData = bgReadingList[cntr] as GlucoseData;
						if (gd.glucoseLevelRaw > 0) {
							newData = true;
							myTrace("in onDownloadGlucoseReadingsComplete, created bgreading at: " + (new Date(NSDownloadReadingTime)).toString() + ", with unfiltered value " + NSDownloadReading.unfiltered);
							BgReading.create(gd.glucoseLevelRaw, gd.glucoseLevelRaw, gd.realDate).saveToDatabaseSynchronous();
							TransmitterService.dispatchBgReadingReceivedEvent();
						} else {
							myTrace("in onDownloadGlucoseReadingsComplete, received glucoseLevelRaw = 0");
						}
					}
					
					//Notify Listeners
					if (newData)
						TransmitterService.dispatchLastBgReadingReceivedEvent();
				} 
				else 
					myTrace("in onDownloadGlucoseReadingsComplete, Nightscout response was not a JSON array. Ignoring! Response: " + response);
			} 
			catch (error:Error) 
			{
				myTrace("in onDownloadGlucoseReadingsComplete, Error parsing Nightscout responde! Error: " + error.message + " Response: " + response);
			}
			
			TransmitterService.instance.addEventListener(TransmitterServiceEvent.LAST_BGREADING_RECEIVED, bgReadingReceived);
			resetCheckReadingTimer(calculateNextFollowDownloadDelayInSeconds(now, BgReading.lastNoSensor()));
		}
		
		private static function calculateNextFollowDownloadDelayInSeconds(now:Number, latestBGReading:BgReading):int {
			var nextFollowDownloadTimeStamp:Number = Number.NaN;
			if (latestBGReading != null) {
				nextFollowDownloadTimeStamp = latestBGReading.timestamp + 5 * 60 * 1000 + 20000;//timestamp of latest stored reading + 5 minutes + 20 seconds	
				while (nextFollowDownloadTimeStamp < now) {
					nextFollowDownloadTimeStamp += 5 * 60 * 1000;
				}
			} else {
				nextFollowDownloadTimeStamp = now + 5 * 60 * 1000;
			}
			return (nextFollowDownloadTimeStamp - now)/1000;
		}
		
		/**
		 * OS device will try to reconnect, <br>
		 * bluetoothperipheral must be known already, meaning it must be a miaomiao which already had a connection in the past <br><br>
		 * If that reconnect doesn't succeed immediately (because miaomiao is not in range are already connected to another iOS device)
		 * then iOS will store internally the "wish" to connect. As soon as the MiaoMiao comes in range not connected to any other device, then it will connect<br>
		 */
		private static function reconnect(event:Event):void {
			if (isMiaoMiaoMultiple()) {
				SpikeANE.reconnectMiaoMiao();
			}
		}

		private static function commonSettingChanged(event:SettingsServiceEvent):void {
			if (event.data == CommonSettings.COMMON_SETTING_PERIPHERAL_TYPE 
				|| event.data == CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_URL
				|| event.data == CommonSettings.COMMON_SETTING_AZURE_WEBSITE_NAME
				|| event.data == CommonSettings.COMMON_SETTING_API_SECRET
				|| event.data == CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_API_SECRET
				|| event.data == CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_OFFSET) {
				setupService();
			}
		}
		
		private static function localSettingChanged(event:SettingsServiceEvent):void {
			if (event.data == LocalSettings.LOCAL_SETTING_MIAOMIAO_MULTIPLE_DEVICE_ON) {
				setupService();
			}
		}
		
		private static function setupService():void {
			if (isMiaoMiaoMultiple()) {
				TransmitterService.instance.addEventListener(TransmitterServiceEvent.LAST_BGREADING_RECEIVED, bgReadingReceived);
				resetCheckReadingTimer(calculateNextFollowDownloadDelayInSeconds((new Date()).valueOf(), BgReading.lastNoSensor()));
				setupNightScoutDownloadProperties();
			} else {
				if (reconnectTimer != null) {
					if (reconnectTimer.running) {
						myTrace("in setupService, reconnectTimer running, stopping it now");
						reconnectTimer.stop();
					}
				}
				if (checkReadingTimer != null) {
					if (checkReadingTimer.running) {
						myTrace("in setupService, checkReadingTimer running, stopping it now");
						checkReadingTimer.stop();
					}
				}
				TransmitterService.instance.removeEventListener(TransmitterServiceEvent.LAST_BGREADING_RECEIVED, bgReadingReceived);
			}
		}

		private static function setupNightScoutDownloadProperties():void
		{
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_URL) != "") {
				nightscoutDownloadURL = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_URL);
			} else {
				nightscoutDownloadURL = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_AZURE_WEBSITE_NAME);
			}
			if (nightscoutDownloadURL != "") {
				nightscoutDownloadURL += "/api/v1/entries/sgv.json?";
				if (nightscoutDownloadURL.indexOf('http') == -1) 
					nightscoutDownloadURL = "https://" + nightscoutDownloadURL;
			}
			
			nightscoutDownloadOffset = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_OFFSET));
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_API_SECRET) != "") {
				nightscoutDownloadAPISecret = Hex.fromArray(hash.hash(Hex.toArray(Hex.fromString(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_API_SECRET)))));
			} else {
				nightscoutDownloadAPISecret = "";
			}
		}
		
		/**
		 * true if device is miaomiao && LOCAL_SETTING_MIAOMIAO_MULTIPLE_DEVICE_ON = true
		 */
		private static function isMiaoMiaoMultiple():Boolean {
			return (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_MIAOMIAO_MULTIPLE_DEVICE_ON) == "true"
				&&
				CGMBlueToothDevice.isMiaoMiao());
		}
		
		private static function myTrace(log:String):void {
			Trace.myTrace("MultipleMiaoMiaoService.as", log);
		}
	}
}