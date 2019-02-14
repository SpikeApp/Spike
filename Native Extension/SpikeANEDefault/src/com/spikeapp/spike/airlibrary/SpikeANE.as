package com.spikeapp.spike.airlibrary
{
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.StatusEvent;
	import flash.utils.ByteArray;
	
	public class SpikeANE extends EventDispatcher
	{
		public static const APPLICATION_DIR:String = "application";
		public static const CACHE_DIR:String = "cache";
		public static const DOCUMENTS_DIR:String = "documents";
		public static const STORAGE_DIR:String = "storage";
		
		private static var _instance:SpikeANE = new SpikeANE();

		public function SpikeANE(target:IEventDispatcher=null)
		{
			super(target);
		}
		
		public static function get instance():SpikeANE
		{
			return _instance;
		}
		
		public static function traceNSLog(log:String) : void { 
			trace(log);
		}
		
		public static function init():void {
		}
		
		/******************
		 ** MIAOMIAO FUNCTIONS
		 * ****************/
		public static function startScanningForMiaoMiao():void {
		}
		
		public static function setMiaoMiaoMac(newMac:String):void {
		}
		
		public static function resetMiaoMiaoMac():void {
		}
		
		public static function cancelMiaoMiaoConnection(MAC:String):void {
		}
		
		public static function stopScanningMiaoMiao():void {
		}
		
		public static function forgetMiaoMiaoPeripheral():void {
		}
		
		public static function sendStartReadingCommmandToMiaoMia():void {
		}
		
		public static function startScanDeviceMiaoMiao():void {
		}
		
		public static function stopScanDeviceMiaoMiao():void {
		}
		
		public static function confirmSensorChangeMiaoMiao():void {
		}
		
		/******************
		 * G5 FUNCTIONS
		 ******************/
		public static function startScanningForG5():void {
		}
		
		public static function setG5Mac(newMac:String):void {
		}
		
		public static function resetG5Mac():void {
		}
		
		public static function cancelG5Connection(MAC:String):void {
		}
		
		public static function stopScanningG5():void {
		}
		
		public static function forgetG5Peripheral():void {
		}
		
		public static function startScanDeviceG5():void {
		}
		
		public static function stopScanDeviceG5():void {
		}
		
		public static function setTransmitterIdG5(transmitterID:String, cryptKey:ByteArray):void {
		}
		
		public static function setG5Reset(resetG5:Boolean):void {
		}
		
		public static function setTestData(testdata:ByteArray):void {
		}
		
		public static function doG5FirmwareVersionRequest():void {
		}
		
		public static function doG5BatteryInfoRequest():void {
		}
		
		public static function disconnectG5():void {
		}
		
		/****************
		 * ** Status event received from objective-c side
		 * ***************/
		private static function onStatus(event:StatusEvent): void
		{
		}

		/**********************
		 * ** HEALTHKIT
		 * *******************/
		public static function initHealthKit():void {
		}
		
		public static function storeBGInHealthKitMgDl(value:Number, timeStamp:Number = Number.NaN):void {
		}

		public static function storeCarbInHealthKitGram(value:Number, timeStamp:Number = Number.NaN):void {
		}
		
		public static function storeInsulin(value:Number, isBolus:Boolean = true, timeStamp:Number = Number.NaN):void {
		}
		
		/*************************************
		 ** SOUND AND SPEECH RELATED FUNCTIONS
		 *************************************/
		public static function stopPlayingSound():void {
		}

		public static function playSound(sound:String, volume:Number = Number.NaN, systemVolume:Number = Number.NaN):void {
		}
		
		public static function isPlayingSound():Boolean {
			return false;
		}

		public static function say(text:String, language:String, systemVolume:Number = Number.NaN):void {
		}

		public static function setAvAudioSessionCategory(toCategoryPlayback:Boolean):void {
		}

		/***************
		 ** APPLICATION
		 ***************/
		public static function appIsInBackground():Boolean {
				return false;
		}
		
		public static function appIsInForeground():Boolean {
			return true;
		}

		public static function initUserDefaults():void {
		}
		
		public static function setUserDefaultsData(key:String, data:String):void {
		}
		
		public static function getAppVersion():String {
			return "x.x.x";
		}
		
		public static function setDatabaseResetStatus(isResetted:Boolean):void {
		}
		
		public static function getDatabaseResetStatus():Boolean {
			return false;
		}
		
		public static function terminateApp():void {
		}
		
		public static function setStatusBarToWhite():void {
		}
		
		public static function openWithDefaultApplication(filePath:String, basePath:String = APPLICATION_DIR):void{
		}
		
		/**********
		 ** DEVICE
		 **********/
		public static function checkMuted():void {
		}
		
		public static function vibrate():void {
		}
		
		public static function getBatteryLevel():void {
		}
		
		public static function getBatteryStatus():void {
		}
		
		/************
		 ** UTILITIES
		 ************/
		public static function generateHMAC_SHA1(key:String, data:String):String {
			return "";
		}
		
		public static function AESEncryptWithKey(key:ByteArray, data:ByteArray):ByteArray {
			return null;
		}

		public static function startMonitoringAndRangingBeaconsInRegion(region:String):void {
		}
		
		public static function stopMonitoringAndRangingBeaconsInRegion(region:String):void {
		}
		
		public static function writeTraceToFile(filePath:String, text:String):void {
		}
		
		public static function resetTraceFilePath():void {
		}
	}
}