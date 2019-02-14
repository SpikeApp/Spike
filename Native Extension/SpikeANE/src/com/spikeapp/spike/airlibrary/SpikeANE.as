package com.spikeapp.spike.airlibrary
{
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.StatusEvent;
	import flash.external.ExtensionContext;
	import flash.system.Capabilities;
	import flash.utils.ByteArray;
	
	public class SpikeANE extends EventDispatcher
	{
		public static const APPLICATION_DIR:String = "application";
		public static const CACHE_DIR:String = "cache";
		public static const DOCUMENTS_DIR:String = "documents";
		public static const STORAGE_DIR:String = "storage";
		
		private static var context:ExtensionContext; 
		private static var _instance:SpikeANE = new SpikeANE();
		
		public function SpikeANE(target:IEventDispatcher=null)
		{
			if (_instance != null) {
				throw new Error("SpikeANE class constructor can not be used");	
			}
		}
		
		public static function get instance():SpikeANE
		{
			return _instance;
		}
		
		public static function traceNSLog(log:String) : void { 
			if (context != null) {
				context.call( "traceNSLog", log ); 
			}
		}
		
		public static function init():void {
			if (context == null) {
				context = ExtensionContext.createExtensionContext("com.spike-app.spike.AirNativeExtension","");
				context.addEventListener(StatusEvent.STATUS, onStatus);
				context.call("init");
			}
		}
		
		/********
		 ** MIAOMIAO FUNCTIONS
		 * ****************/
		public static function startScanningForMiaoMiao():void {
			context.call("ScanAndConnectToMiaoMiaoDevice");
		}
		
		public static function setMiaoMiaoMac(newMac:String):void {
			context.call("setMiaoMiaoMAC", newMac);
		}
		
		public static function resetMiaoMiaoMac():void {
			context.call("resetMiaoMiaoMac");
		}
		
		public static function cancelMiaoMiaoConnection(MAC:String):void {
			if (MAC == null)
				return;
			if (MAC.length == 0)
				return;
			context.call("cancelMiaoMiaoConnectionWithMAC", MAC);
		}
		
		public static function stopScanningMiaoMiao():void {
			context.call("stopScanningMiaoMiao");
		}
		
		public static function forgetMiaoMiaoPeripheral():void {
			context.call("forgetMiaoMiao");
		}
		
		public static function sendStartReadingCommmandToMiaoMia():void {
			context.call("sendStartReadingCommmandToMiaoMiao");
		}
		
		public static function startScanDeviceMiaoMiao():void {
			context.call("startScanDeviceMiaoMiao");
		}
		
		public static function stopScanDeviceMiaoMiao():void {
			context.call("stopScanDeviceMiaoMiao");
		}
		
		public static function confirmSensorChangeMiaoMiao():void {
			context.call("confirmSensorChangeMiaoMiao");
		}

		/******************
		 ** G5 FUNCTIONS
		 * ****************/
		public static function startScanningForG5():void {
			context.call("ScanAndConnectToG5Device");
		}
		
		public static function setG5Mac(newMac:String):void {
			context.call("setG5MAC", newMac);
		}
		
		public static function resetG5Mac():void {
			context.call("resetG5Mac");
		}
		
		public static function cancelG5Connection(MAC:String):void {
			if (MAC == null)
				return;
			if (MAC.length == 0)
				return;
			context.call("cancelG5ConnectionWithMAC", MAC);
		}
		
		public static function stopScanningG5():void {
			context.call("stopScanningG5");
		}
		
		public static function forgetG5Peripheral():void {
			context.call("forgetG5");
		}
		
		public static function startScanDeviceG5():void {
			context.call("startScanDeviceG5");
		}
		
		public static function stopScanDeviceG5():void {
			context.call("stopScanDeviceG5");
		}
		
		public static function setTransmitterIdG5(transmitterID:String, cryptKey:ByteArray):void {
			cryptKey.position = 0;
			context.call("setTransmitterIdG5", transmitterID, cryptKey.readUTFBytes(cryptKey.length));
		}
		
		public static function setTestData(testdata:ByteArray):void {
			context.call("setTestData",testdata);
		}
		
		public static function setG5Reset(resetG5:Boolean):void {
			context.call("setG5Reset",resetG5);
		}
		
		public static function doG5FirmwareVersionRequest():void {
			context.call("doG5FirmwareVersionRequest");
		}
		
		public static function doG5BatteryInfoRequest():void {
			context.call("doG5BatteryInfoRequest");
		}
		
		public static function disconnectG5():void {
			context.call("disconnectG5");
		}
		
		/**********************
		 * ** HEALTHKIT
		 * *******************/
		public static function initHealthKit():void {
			//example for iOS 10.3 it gives 10.3.
			var iosVersion:String = Capabilities.os.match( /([0-9]\.?){2,3}/ )[0];
			context.call("initHealthKit", iosVersion);
		}

		/**
		 * timestamp in ms, if null then current date and time is used 
		 */
		public static function storeBGInHealthKitMgDl(value:Number, timeStamp:Number = Number.NaN):void {
			var timestamp:Number = isNaN(timeStamp) ? (new Date()).valueOf() / 1000 : timeStamp / 1000;
			context.call("storeBloodGlucoseValue", value, new Number(timestamp));
		}

		/**
		 * timestamp in ms, if null then current date and time is used 
		 */
		public static function storeCarbInHealthKitGram(value:Number, timeStamp:Number = Number.NaN):void {
			var timestamp:Number = isNaN(timeStamp) ? (new Date()).valueOf() / 1000 : timeStamp / 1000;
			context.call("storeCarbValue", value, new Number(timestamp));
		}
		
		/**
		 * timestamp in ms, if null then current date and time is used<br>
		 * isBolus false then it's basal
		 */
		public static function storeInsulin(value:Number, isBolus:Boolean = true, timeStamp:Number = Number.NaN):void {
			var timestamp:Number = isNaN(timeStamp) ? (new Date()).valueOf() / 1000 : timeStamp / 1000;
			context.call("storeInsulinValue", value, new Number(timestamp), isBolus);
		}
		
		/*************************************
		 ** SOUND AND SPEECH RELATED FUNCTIONS
		 * **********************************/
		public static function stopPlayingSound():void {
			context.call("stopPlayingSound");
		}
		
		/**
		 * sets AVAudioPlayer setVolume to the specified value.<br>
		 * If volume = Number.NaN, then volume will not be set
		 * VOLUME PARAMETER NOT FULLY TESTED, PROBABLY DOESN'T WORK, NEEDS TO BE FPANE_FREObjectToDouble in objective-c side
		 */
		public static function playSound(sound:String, volume:Number = Number.NaN, systemVolume:Number = Number.NaN):void {
			context.call("playSound", sound, isNaN(volume) ? 101: new Number(volume), isNaN(systemVolume) ? 101 : systemVolume);
		}
		
		public static function isPlayingSound():Boolean {
			return (context.call("isPlayingSound") as Boolean);
		}

		/**
		 * text : text to be spoken<br> 
		 * language  : examplle "en-US" , or "nl-BE"
		 */
		public static function say(text:String, language:String, systemVolume:Number = Number.NaN):void {
			context.call("say", text, language, isNaN(systemVolume) ? 101 : systemVolume);
		}
		
		/**
		 * if true then will set AVAudioSessionCategoryPlayback in AVAudioSession with option AVAudioSessionCategoryOptionMixWithOthers
		 */
		public static function setAvAudioSessionCategory(toCategoryPlayback:Boolean):void {
			context.call("setAvAudioSessionCategory", toCategoryPlayback ? "AVAudioSessionCategoryPlayback":"AVAudioSessionCategoryAmbient");
		}
		
		/***************
		 ** APPLICATION
		 ***************/
		public static function appIsInBackground():Boolean {
			if (context != null)
				return (context.call("applicationInBackGround") as Boolean);
			else 
				//if context == null, this means app is still starting up, context hasn'b een intialized yet, most probably the app is in foreground
				return false;
		}

		public static function appIsInForeground():Boolean {
			return !appIsInBackground();
		}
		
		public static function initUserDefaults():void {
			context.call("initUserDefaults");
		}
		
		public static function setUserDefaultsData(key:String, data:String):void {
			context.call("setUserDefaultsData", key, data);
		}
		
		public static function getAppVersion():String {
			return (context.call("getAppVersion") as String);
		}
		
		public static function setDatabaseResetStatus(isResetted:Boolean):void {
			context.call("setDatabaseResetStatus", isResetted ? "true" : "false");
		}
		
		public static function getDatabaseResetStatus():Boolean {
			return context.call("getDatabaseResetStatus") as Boolean;
		}
		
		public static function terminateApp():void {
			context.call("terminateApp");
		}
		
		public static function setStatusBarToWhite():void {
			context.call("setStatusBarToWhite");
		}
		
		public static function openWithDefaultApplication(filePath:String, basePath:String = APPLICATION_DIR):void
		{
			context.call('openWithDefaultApplication', filePath, basePath);
		}
		
		/**********
		 ** DEVICE
		 **********/
		public static function checkMuted():void {
				context.call("checkMute");
		}
		
		public static function vibrate():void {
				context.call("vibrate");
		}
		
		public static function getBatteryLevel():Number {
			return (context.call("getBatteryLevel") as Number);
		}
		
		public static function getBatteryStatus():int {
			return (context.call("getBatteryStatus") as int);
		}

		/************
		 ** UTILITIES
		 ************/
		//generateHMAC_SHA1 not yet retested after migratoin to SpikeANE
		public static function generateHMAC_SHA1(key:String, data:String):String {
			return (context.call("generateHMAC_SHA1", key, data) as String);
		}
		
		public static function AESEncryptWithKey(key:ByteArray, data:ByteArray):ByteArray {
			key.position = 0;
			data.position = 0;
			var encrypted:ByteArray = new ByteArray();
			context.call("AESEncryptWithKey", key.readUTFBytes(key.length), data, encrypted);
			return encrypted;
		}

		public static function startMonitoringAndRangingBeaconsInRegion(region:String):void {
			context.call("startMonitoringAndRangingBeaconsInRegion", region);
		}
		
		public static function stopMonitoringAndRangingBeaconsInRegion(region:String):void {
			context.call("stopMonitoringAndRangingBeaconsInRegion", region);
		}
		
		/**
		 * filepath needs to be the full path inclusive filename. <br>
		 * Example how to get the filepath File.applicationStorageDirectory.resolvePath(fileName).nativePath;
		 */
		public static function writeTraceToFile(filePath:String, text:String):void {
			if (context != null)
				context.call("writeTraceToFile", filePath, text);
		}

		public static function resetTraceFilePath():void {
			if (context != null)
				context.call("resetTraceFilePath");
		}

		/************************************************
		 * ** Status event received from objective-c side
		 * *********************************************/
		private static function onStatus(event:StatusEvent): void
		{
			var spikeANEEvent:SpikeANEEvent;
			if (event.code == "StatusEvent_miaomiaoData") {
				spikeANEEvent = new SpikeANEEvent(SpikeANEEvent.MIAO_MIAO_DATA_PACKET_RECEIVED);
				spikeANEEvent.data = new Object();
				spikeANEEvent.data.packet = event.level.split("JJ§§((hhd")[0];
				_instance.dispatchEvent(spikeANEEvent);
			} else if (event.code == "StatusEvent_newMiaoMiaoMac") {
				spikeANEEvent = new SpikeANEEvent(SpikeANEEvent.MIAO_MIAO_NEW_MAC);
				spikeANEEvent.data = new Object();
				spikeANEEvent.data.MAC = event.level.split("JJ§§((hhd")[0];
				_instance.dispatchEvent(spikeANEEvent);
			}  else if (event.code == "StatusEvent_newG5Mac") {
				spikeANEEvent = new SpikeANEEvent(SpikeANEEvent.G5_NEW_MAC);
				spikeANEEvent.data = new Object();
				spikeANEEvent.data.MAC = event.level.split("JJ§§((hhd")[0];
				_instance.dispatchEvent(spikeANEEvent);
			} else if (event.code == "StatusEvent_sensorChangeMessageReceived") {
				spikeANEEvent = new SpikeANEEvent(SpikeANEEvent.SENSOR_CHANGED_MESSAGE_RECEIVED_FROM_MIAOMIAO);
				_instance.dispatchEvent(spikeANEEvent);
			} else if (event.code == "StatusEvent_sensorNotDetectedMessageReceived") {
				spikeANEEvent = new SpikeANEEvent(SpikeANEEvent.SENSOR_NOT_DETECTED_MESSAGE_RECEIVED_FROM_MIAOMIAO);
				_instance.dispatchEvent(spikeANEEvent);
			} else if (event.code == "StatusEvent_miaoMiaoChangeTimeIntervalChangedSuccess") {
				spikeANEEvent = new SpikeANEEvent(SpikeANEEvent.MIAOMIAO_TIME_INTERVAL_CHANGED_SUCCESS);
				_instance.dispatchEvent(spikeANEEvent);
			} else if (event.code == "StatusEvent_miaoMiaoChangeTimeIntervalChangedFailure") {
				spikeANEEvent = new SpikeANEEvent(SpikeANEEvent.MIAOMIAO_TIME_INTERVAL_CHANGED_FAILURE);
				_instance.dispatchEvent(spikeANEEvent);
			} else if (event.code == "StatusEvent_connectedMiaoMiao") {
				spikeANEEvent = new SpikeANEEvent(SpikeANEEvent.MIAOMIAO_CONNECTED);
				_instance.dispatchEvent(spikeANEEvent);
			}  else if (event.code == "StatusEvent_connectedG5") {
				spikeANEEvent = new SpikeANEEvent(SpikeANEEvent.G5_CONNECTED);
				_instance.dispatchEvent(spikeANEEvent);
			} else if (event.code == "StatusEvent_disconnectedMiaoMiao") {
				spikeANEEvent = new SpikeANEEvent(SpikeANEEvent.MIAOMIAO_DISCONNECTED);
				_instance.dispatchEvent(spikeANEEvent);
			} else if (event.code == "StatusEvent_disconnectedG5") {
				spikeANEEvent = new SpikeANEEvent(SpikeANEEvent.G5_DISCONNECTED);
				_instance.dispatchEvent(spikeANEEvent);
			} else if (event.code == "StatusEvent_didRecieveInitialUpdateValueForCharacteristic") {
				spikeANEEvent = new SpikeANEEvent(SpikeANEEvent.MIAOMIAO_INITIAL_UPDATE_CHARACTERISTIC_RECEIVED);
				_instance.dispatchEvent(spikeANEEvent);
			} else if (event.code == "phoneMuted") {
				spikeANEEvent = new SpikeANEEvent(SpikeANEEvent.PHONE_MUTED);
				_instance.dispatchEvent(spikeANEEvent);
			} else if (event.code == "phoneNotMuted") {
				spikeANEEvent = new SpikeANEEvent(SpikeANEEvent.PHONE_NOT_MUTED);
				_instance.dispatchEvent(spikeANEEvent);
			} else if (event.code == "StatusEvent_G5DeviceNotPaired") {
				spikeANEEvent = new SpikeANEEvent(SpikeANEEvent.G5_DEVICE_NOT_PAIRED);
				_instance.dispatchEvent(spikeANEEvent);
			} else if (event.code == "StatusEvent_G5DataPacketReceived") {
				spikeANEEvent = new SpikeANEEvent(SpikeANEEvent.G5_DATA_PACKET_RECEIVED);
				spikeANEEvent.data = new Object();
				spikeANEEvent.data.packet = event.level.split("JJ§§((hhd")[0];
				_instance.dispatchEvent(spikeANEEvent);
			} 
		}
	}
}