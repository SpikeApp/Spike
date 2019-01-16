package database
{
	import G5G6Model.G5G6VersionInfo;
	
	import model.ModelLocator;
	
	import services.bluetooth.CGMBluetoothService;
	
	import utils.Trace;
	
	/**
	 * This is for CGM transmitters only<br
	 * <br>
	 * Overview of currently known device types<br>
	 * <br>
	 * - G4 with xbridge or xdrip. Not an always scan device, needs a transmitter id however scanning will happen even without knowing a transmitter id because the the bridge itself doesn't have a transmitter id.<br>
	 * User needs to start scanning manually. Device will scan for specific UUID known for xbridge/xdrip. As soon as a device is found, it will connect, no matter what name it has.<br>
	 * Once a device is found, the app will store the address of the bridge, in the future the app will only connect to a transmitter with that address. Scanning happens automatically once the address is known as soon as the app starts<br>
	 * Transmitter id will either be read from xdrip (if no transmitter id  set in app), or will be written from device to bridge (if transmitter id is set in app, but it doesn't match the transmitter id in the xdrip<br>
	 * <br>
	 * - G5/G6 : works only if transmitter is known. As soon as transmitter id is known, scanning will start for specific UUID. If a device is found, it must have name "DexcomAB" with AB last two characters of the transmitter id <br>
	 * <br>
	 * - Transmiter PL : similar to G4, except that it uses another scanning UUID.<br>
	 * <br>
	 * - BlueReader : similar to G4, except that no scanning UUID is known. App will scan without specifying a UUID. As a result scanning doesn't work when in background<br>. First connection must happen while the app is in the foreground.<br>
	 * Once a successful connection is done, the app will only reconnect to this device. For transmitter types without known scanning UUID (bluereader and miaomaio) reconnection strategy is different.<br>
	 * <br>
	 * - MiaoMiao  similar to Bluereader. Handled by backgroundfetch ANE
	 * <br>
	 * - xbridgr : requested by Marek Macner. Uses an adapted version of the xbridge protocol, for FSL
	 */
	
	[ResourceBundle("transmitterscreen")]
	
	public class CGMBlueToothDevice extends SuperDatabaseClass
	{
		public static const DEFAULT_BLUETOOTH_DEVICE_ID:String = "1465501584186cb0d5f60b3c";
		private static var _instance:CGMBlueToothDevice = new CGMBlueToothDevice(DEFAULT_BLUETOOTH_DEVICE_ID, Number.NaN);//note that while calling Database.getbluetoothdevice, all attributes will be overwritten by the values stored in the database
		
		/**
		 * in case we need attributes of the superclass (like uniqueid), then we need to get an instance of this class
		 */
		public static function get instance():CGMBlueToothDevice
		{
			return _instance;
		}
		
		private static var _name:String;
		
		/**
		 * name of the device, empty string means not yet assigned to a bluetooth peripheral<br>
		 * return value will never be null, although the stored value may be null
		 */
		public static function get name():String
		{
			return _name == null ? "":_name;
		}
		
		/**
		 * sets the name, also update in database will be done
		 */
		public static function set name(value:String):void
		{
			if (value == _name)
				return;
			
			_name = value;
			if (_name == null)
				_name = "";

			Database.updateBlueToothDeviceSynchronous(_address, _name, (new Date()).valueOf());
		}
		
		private static var _address:String;
		
		/**
		 * address of the device, empty string means not yet assigned to a bluetooth peripheral<br>
		 * return value will never be null (although actual stored value may still be null)
		 */
		public static function get address():String
		{
			return _address == null ? "":_address;
		}
		
		/**
		 * sets the address, also update in database will be done
		 */
		public static function set address(value:String):void
		{
			if (value == _address)
				return;
			
			_address = value;
			if (_address == null)
				_address = "";
			Database.updateBlueToothDeviceSynchronous(_address, _name, (new Date()).valueOf());

		}
		
		public function set lastModifiedTimestamp(lastmodifiedtimestamp:Number):void
		{
			_lastModifiedTimestamp = lastmodifiedtimestamp;
		}
		
		public function CGMBlueToothDevice(bluetoothdeviceid:String, lastmodifiedtimestamp:Number)
		{	
			super(bluetoothdeviceid, lastmodifiedtimestamp);
			if (_instance != null) {
				throw new Error("BlueToothDevice class  constructor can not be used");	
			}
		}
		
		/**
		 * sets address and name of bluetoothdevice to empty string, ie there's no device known anymore<br>
		 * also updates database and calls bluetoothservce.forgetdevice
		 */
		public static function forgetBlueToothDevice():void {
			myTrace("in forgetBlueToothDevice");
			var tempAddress:String = _address;
			_address = "";
			_name = "";
			Database.updateBlueToothDeviceSynchronous("", "", (new Date()).valueOf());
			CGMBluetoothService.forgetActiveBluetoothPeripheral(tempAddress);
		}
		
		/**
		 * is a bluetoothdevice known or not<br>
		 * It will look at the address and if it's different from "" then returns true 
		 */
		public static function known():Boolean {
			if (_address == null)
				return false;
			return (_address != "");
		}
		
		public static function setLastModifiedTimestamp(newtimestamp:Number):void {
			instance.lastModifiedTimestamp = newtimestamp;
		}
		
		/**
		 * True for xdrip or xbridge connecting to Dexcom G4
		 */
		public static function isDexcomG4():Boolean {
			return (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PERIPHERAL_TYPE).toUpperCase() == "G4");
		}
		
		public static function isDexcomG5():Boolean {
			return (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PERIPHERAL_TYPE).toUpperCase() == "G5");
		}
		
		public static function isDexcomG6():Boolean {
			return (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PERIPHERAL_TYPE).toUpperCase() == "G6");
		}
		
		public static function isBlueReader():Boolean {
			return (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PERIPHERAL_TYPE).toUpperCase() == "BLUEREADER");
		}
		
		public static function isBluKon():Boolean {
			return (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PERIPHERAL_TYPE).toUpperCase() == "BLUKON" ||
				CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PERIPHERAL_TYPE).toUpperCase() == "BLUCON");
		}
		
		public static function isLimitter():Boolean {
			return (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PERIPHERAL_TYPE).toUpperCase() == "LIMITTER");
		}

		public static function isTransmiter_PL():Boolean {
			return (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PERIPHERAL_TYPE).toUpperCase() == "TRANSMITER PL");
		}
		
		public static function isMiaoMiao():Boolean {
			return (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PERIPHERAL_TYPE).toUpperCase() == "MIAOMIAO");
		}
		
		public static function isxBridgeR():Boolean {
			return (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PERIPHERAL_TYPE).toUpperCase() == "XBRIDGER");
		}
		
		/**
		 * Follower mode, not really a bluetoothdevice but it comes in handy to put it here also
		 */
		public static function isFollower():Boolean {
			return (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PERIPHERAL_TYPE).toUpperCase() == "FOLLOW"); 
		}
		
		public static function isDexcomFollower():Boolean
		{
			return isFollower() && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FOLLOWER_MODE) == "Dexcom";
		}
		
		/**
		 * for type BlueReader, Limitter, BluKon, ie devices that transmit FSL sensor data<br>
		 * important for calibration
		 *  
		 */
		public static function isTypeLimitter():Boolean {
			return (isBlueReader() || isBluKon() || isLimitter() || isTransmiter_PL() || isMiaoMiao() || isxBridgeR());
		}
		
		/**
		 * devices that set COMMON_SETTING_FSL_SENSOR_AGE 
		 */
		public static function knowsFSLAge():Boolean {
			return (isMiaoMiao() || isxBridgeR());
		}
		
		/**
		 * If true, then scanning can start as soon as transmitter id is chosen. For the moment this is only the case for Dexcom G5, G6 and Blukon<br>
		 * For others like xdrip, bluereader, etc... scanning can only start if user initiates it, once a device is known by it' address, then scanning will always happen for those devices<br>
		 */
		public static function alwaysScan():Boolean {
			return (isDexcomG5() || isDexcomG6() || isBluKon()); 
		}

		public static function needsTransmitterId():Boolean {
			return (isDexcomG5() || isDexcomG6() || isDexcomG4() || isBluKon() || isxBridgeR());
		}
		
		public static function transmitterIdKnown():Boolean {
			return (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TRANSMITTER_ID) != "00000");
		}
		
		/**
		 * possible values : G4, G5, G6, BlueReader, BluKon, Limitter, xBridgeR, Follow 
		 */
		public static function deviceType():String {
			if (isDexcomG4()) 
				return "G4";
			if (isDexcomG5())
				return "G5";
			if (isDexcomG6())
				return "G6";
			if (isBlueReader())
				return "BlueReader";
			if (isBluKon())
				return "BluKon";
			if (isLimitter())
				return "Limitter";
			if (isFollower())
				return "Follow";
			if (isTransmiter_PL())
				return "Transmiter PL";
			if (isMiaoMiao())
				return "MiaoMiao";
			if (isxBridgeR())
				return "xBridgeR";
			
			return "unknown";
		}
		
		public static function getFirmwareVersion():String
		{
			if (isDexcomG5() || isDexcomG6())
				return G5G6VersionInfo.getG5G6VersionInfo().firmware_version_string;
			else if (isMiaoMiao())
				return CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_MIAOMIAO_FW);
			
			return null;
		}
		
		public static function getHardwareVersion():String
		{
			if (isDexcomG5() || isDexcomG6())
				return String(G5G6VersionInfo.getG5G6VersionInfo().hardwarev);
			
			return null;
		}
		
		public static function getSoftwareVersion():String
		{
			if (isDexcomG5() || isDexcomG6())
				return G5G6VersionInfo.getG5G6VersionInfo().bluetooth_firmware_version_string;
			
			return null;
		}
		
		public static function getManufacturer():String
		{
			if (isDexcomG4() || isDexcomG5() || isDexcomG6())
				return "Dexcom";
			else if (isMiaoMiao())
				return "MiaoMiao";
			else if (isBluKon())
				return "Ambrosia";
			else if (isBlueReader())
				return "Keßler";
			else if (isLimitter())
				return "JoernL";
			else if (isTransmiter_PL())
				return "mTransmiter";
				
			return null;
		}
		
		public static function getLocalIdentifier():String
		{
			if (_address != null && _address != "")
				return _address;
			
			return null;
		}
		
		public static function getTransmitterName():String
		{
			var transmitterName:String = "";
			
			if (CGMBlueToothDevice.isDexcomG6()) transmitterName = "G6";
			else if (CGMBlueToothDevice.isDexcomG5()) transmitterName = "G5";
			else if (CGMBlueToothDevice.isDexcomG4()) transmitterName = "G4";
			else if (CGMBlueToothDevice.isBluKon()) transmitterName = ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_blucon');
			else if (CGMBlueToothDevice.isMiaoMiao()) transmitterName = ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_miaomiao');
			else if (CGMBlueToothDevice.isBlueReader()) transmitterName = ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_bluereader');
			else if (CGMBlueToothDevice.isLimitter()) transmitterName = ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_limitter');
			else if (CGMBlueToothDevice.isTransmiter_PL()) transmitterName = ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_transmitter_pl');
			
			return transmitterName;
		}

		private static function myTrace(log:String):void {
			Trace.myTrace("BlueToothDevice.as", log);
		}
		
	}
}