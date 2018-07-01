package services
{
	import com.spikeapp.spike.airlibrary.SpikeANE;
	import com.spikeapp.spike.airlibrary.SpikeANEEvent;
	
	import flash.errors.IllegalOperationError;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	import flash.net.URLRequest;
	import flash.utils.clearInterval;
	import flash.utils.setInterval;
	
	import database.CGMBlueToothDevice;
	import database.CommonSettings;
	
	import events.SettingsServiceEvent;
	
	import utils.Constants;
	import utils.Trace;
	
	public class DeepSleepService extends EventDispatcher
	{
		/* Constants */
		private static const STANDARD_MODE:int = 60 * 1000;
		private static const MODERATE_MODE:int = 30 * 1000;
		private static const AGGRESSIVE_MODE:int = 10 * 1000;
		private static const VERY_AGGRESSIVE_MODE:int = 5 * 1000;
		private static const AUTOMATIC_DEXCOM:int = 10 * 1000;
		private static const AUTOMATIC_NON_DEXCOM:int = 5 * 1000;
		private static const AUTOMATIC_FOLLOWER:int = 30 * 1000;
		private static const TIME_1_MINUTE:int = 1 * 60 * 1000;
		private static const MIAOMIAO_CONNECTED_INITIAL_UPDATE_CHARACTERISTIC_RECEIVED_MODE:int = 0.5 * TIME_1_MINUTE;
		private static const MIAOMIAO_DISCONNECTED_MODE:int = NO_SUSPENSION_PREVENTION_MODE;
		private static const MIAOMIAO_CONNECTED_BUT_NO_INITIAL_UPDATE_CHARACTERISTIC_RECEIVED_MODE:int = 10 * 1000;
		private static const NO_SUSPENSION_PREVENTION_MODE:int = 1000000;
		
		/* Objects */
		private static var _instance:DeepSleepService = new DeepSleepService();
		private static var soundPlayer:Sound;
		private static var channel:SoundChannel;
		private static var soundTransform:SoundTransform;
		private static var soundFile:URLRequest;
		private static var soundFileNight:URLRequest;
		private static var soundTransformNight:SoundTransform;
		
		/* Variables */
		private static var deepSleepInterval:int;
		private static var intervalID:int = -1;
		private static var lastLogPlaySoundTimeStamp:Number = 0;
		
		public function DeepSleepService()
		{
			//Don't allow class to be instantiated
			if (_instance != null) 
			{
				throw new IllegalOperationError("DeepSleepService class is not meant to be instantiated!");
			}
		}
		
		public static function init():void 
		{
			Trace.myTrace("DeepSleepService.as", "Service started!");
			
			//Actions
			createSoundProperties(); //Used for "Alternative Method"
			setDeepSleepInterval();
			startDeepSleepInterval();
			
			//Event Listeners
			CommonSettings.instance.addEventListener(SettingsServiceEvent.SETTING_CHANGED, onCommonSettingsChanged);
			addOrRemoveMiaoMiaoEventListeners();
		}
		
		private static function addOrRemoveMiaoMiaoEventListeners():void {
			if (CGMBlueToothDevice.isMiaoMiao()) {
				//Why listening to MIAOMIAO_INITIAL_UPDATE_CHARACTERISTIC_RECEIVED ?
				//because the suspension prevention timer can be increased back to higher value, when this is received
				//why not sooner , why not as soon as it is connected ?
				//because the Spike ANE may have delayed the sending of F0 (startreading command), the ANE may have started a timer
				//if that's the case, Spike may get suspended before that timer expires, hence it would never expire.
				SpikeANE.instance.addEventListener(SpikeANEEvent.MIAOMIAO_INITIAL_UPDATE_CHARACTERISTIC_RECEIVED, onMiaoMiaoInitialUpdateCharacteristicReceived);
				//Why listening to disconnected ?
				//When disconnected then suspension prevention can be disabled IS THIS RIGHT ??? TO BE TESTED
				SpikeANE.instance.addEventListener(SpikeANEEvent.MIAOMIAO_DISCONNECTED, onMiaoMiaoDisConnected);
				//When connected but no initial characteristic update received, then suspension prevention must be set to a minimum value
				SpikeANE.instance.addEventListener(SpikeANEEvent.MIAOMIAO_CONNECTED, onMiaoMiaoConnected);
			} else {
				SpikeANE.instance.removeEventListener(SpikeANEEvent.MIAOMIAO_INITIAL_UPDATE_CHARACTERISTIC_RECEIVED, onMiaoMiaoInitialUpdateCharacteristicReceived);
				SpikeANE.instance.removeEventListener(SpikeANEEvent.MIAOMIAO_DISCONNECTED, onMiaoMiaoDisConnected);
				SpikeANE.instance.removeEventListener(SpikeANEEvent.MIAOMIAO_CONNECTED, onMiaoMiaoConnected);
			}
		}
		
		private static function createSoundProperties():void
		{
			soundTransform = new SoundTransform(0.001);
			soundTransformNight = new SoundTransform(0.1);
			soundFile = new URLRequest("../assets/sounds/1-millisecond-of-silence.mp3");
			soundFileNight = new URLRequest("../assets/sounds/500ms-of-silence.mp3");
		}
		
		/**
		 * Functionality
		 */
		private static function setDeepSleepInterval():void 
		{	
			//Define new timeout
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEEP_SLEEP_SELF_MANAGEMENT_ON) != "true")
			{
				//Spike manages suspension
				Trace.myTrace("DeepSleepService.as", "Interval managed by Spike");
				if (CGMBlueToothDevice.isDexcomG4() || CGMBlueToothDevice.isDexcomG5()) 
				{
					Trace.myTrace("DeepSleepService.as", "Setting interval to AUTOMATIC_DEXCOM");
					deepSleepInterval = AUTOMATIC_DEXCOM;
				}
				else if (CGMBlueToothDevice.isFollower())
				{
					Trace.myTrace("DeepSleepService.as", "Setting interval to AUTOMATIC_FOLLOWER");
					deepSleepInterval = AUTOMATIC_FOLLOWER;
				}
				else if (CGMBlueToothDevice.isMiaoMiao())
				{
					Trace.myTrace("DeepSleepService.as", "Setting interval to MIAOMIAO_CONNECTED_BUT_NO_INITIAL_UPDATE_CHARACTERISTIC_RECEIVED_MODE");
					//start with highest level of suspension prevention
					deepSleepInterval = MIAOMIAO_CONNECTED_BUT_NO_INITIAL_UPDATE_CHARACTERISTIC_RECEIVED_MODE;
				}
				else
				{
					Trace.myTrace("DeepSleepService.as", "Setting interval to AUTOMATIC_NON_DEXCOM");
					deepSleepInterval = AUTOMATIC_NON_DEXCOM;
				}
			}
			else
			{
				//User manages suspension
				Trace.myTrace("DeepSleepService.as", "Interval managed by user");
				if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEEP_SLEEP_MODE) == "0")
				{
					Trace.myTrace("DeepSleepService.as", "Setting interval to STANDARD_MODE");
					deepSleepInterval = STANDARD_MODE;
				}
				else if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEEP_SLEEP_MODE) == "1")
				{
					Trace.myTrace("DeepSleepService.as", "Setting interval to MODERATE_MODE");
					deepSleepInterval = MODERATE_MODE;
				}
				else if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEEP_SLEEP_MODE) == "2")
				{
					Trace.myTrace("DeepSleepService.as", "Setting interval to AGGRESSIVE_MODE");
					deepSleepInterval = AGGRESSIVE_MODE;
				}
				else if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEEP_SLEEP_MODE) == "3")
				{
					Trace.myTrace("DeepSleepService.as", "Setting interval to VERY_AGGRESSIVE_MODE");
					deepSleepInterval = VERY_AGGRESSIVE_MODE;
				}
			}
		}
		
		private static function startDeepSleepInterval():void 
		{
			//Clear any previous intervals
			clearInterval( intervalID );
			
			if (deepSleepInterval != NO_SUSPENSION_PREVENTION_MODE) {
				//Start new interval
				Trace.myTrace("DeepSleepService.as", "Starting deep sleep interval!");
				intervalID = setInterval( playSound, deepSleepInterval);
			} else {
				Trace.myTrace("DeepSleepService.as", "deepSleepInterval set to maximum value, not starting deep sleep timer");
			}
		}
		
		private static function playSound():void 
		{
			if (!SpikeANE.isPlayingSound() && !Constants.appInForeground && !SpikeANE.appIsInForeground()) //No need to play if the app is in the foregorund
			{
				var nowDate:Date = new Date();
				var now:Number = nowDate.valueOf();
				var hours:Number = nowDate.hours;
				
				if (now - lastLogPlaySoundTimeStamp > TIME_1_MINUTE) 
				{
					Trace.myTrace("DeepSleepService.as", "Playing deep sleep sound...");
					lastLogPlaySoundTimeStamp = now;
				}
				
				if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEEP_SLEEP_ALTERNATIVE_MODE) == "true")
				{
					soundPlayer = null;
					
					if (soundFile == null || soundFileNight == null || soundTransformNight == null || soundTransform == null)
						createSoundProperties();
					
					if (hours >= 1 && hours <= 7)
					{
						//Night mode, play a bigger sound to try an further avoid suspension, also add some volume
						soundPlayer = new Sound(soundFileNight);
						channel = soundPlayer.play();
						if (channel != null)
							channel.soundTransform = soundTransformNight;
						else
						{
							//Spike is suspended in memory. Let's try and play the sound with Backgroundfetch!
							SpikeANE.playSound("../assets/sounds/500ms-of-silence.mp3", 0.01);
						}
					}
					else
					{
						if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEEP_SLEEP_ALTERNATIVE_MODE_2) == "true")
						{
							//Plays with flash player audio and a 500ms sound file
							soundPlayer = new Sound(soundFileNight);
							channel = soundPlayer.play();
							if (channel != null)
								channel.soundTransform = soundTransformNight;
							else
							{
								//Spike is suspended in memory. Let's try and play the sound with Backgroundfetch!
								SpikeANE.playSound("../assets/sounds/500ms-of-silence.mp3", 0.01);
							}
						}
						else
						{
							//Plays with flash player audio
							soundPlayer = new Sound(soundFile);
							channel = soundPlayer.play();
							if (channel != null)
								channel.soundTransform = soundTransform;
							else
							{
								//Spike is suspended in memory. Let's try and play the sound with Backgroundfetch!
								SpikeANE.playSound("../assets/sounds/500ms-of-silence.mp3", 0.01);
							}
						}
					}
				}
				else
				{
					if (hours >= 1 && hours <= 7)
					{
						//Night mode, play a bigger sound to try an further avoid suspension, also add some volume
						SpikeANE.playSound("../assets/sounds/500ms-of-silence.mp3", 0.01);
					}
					else
					{
						if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEEP_SLEEP_ALTERNATIVE_MODE_2) == "true")
							SpikeANE.playSound("../assets/sounds/500ms-of-silence.mp3", 0.01);
						else
							SpikeANE.playSound("../assets/sounds/1-millisecond-of-silence.mp3", 0);
					}
				}
			}
		}
		
		/**
		 * Event Listeners
		 */
		private static function onCommonSettingsChanged(event:SettingsServiceEvent):void 
		{
			if (event.data == CommonSettings.COMMON_SETTING_PERIPHERAL_TYPE ||
				event.data == CommonSettings.COMMON_SETTING_DEEP_SLEEP_SELF_MANAGEMENT_ON ||
				event.data == CommonSettings.COMMON_SETTING_DEEP_SLEEP_MODE
			) 
			{
				Trace.myTrace("DeepSleepService.as", "Settings changed. Defining new interval!");
				setDeepSleepInterval();
				startDeepSleepInterval();
				addOrRemoveMiaoMiaoEventListeners();
			}
		}
		
		private static function onMiaoMiaoInitialUpdateCharacteristicReceived(event:Event):void 
		{
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEEP_SLEEP_SELF_MANAGEMENT_ON) != "true") {
				if (deepSleepInterval != MIAOMIAO_CONNECTED_INITIAL_UPDATE_CHARACTERISTIC_RECEIVED_MODE) {
					Trace.myTrace("DeepSleepService.as", "Setting interval to MIAOMIAO_DID_RECEIVE_INITIAL_UPDATE_CHARACTERISTIC_MODE = " + MIAOMIAO_CONNECTED_INITIAL_UPDATE_CHARACTERISTIC_RECEIVED_MODE/1000 + " seconds");
					deepSleepInterval = MIAOMIAO_CONNECTED_INITIAL_UPDATE_CHARACTERISTIC_RECEIVED_MODE;
					startDeepSleepInterval();
				}
			}
		}
		
		private static function onMiaoMiaoDisConnected(event:Event):void 
		{
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEEP_SLEEP_SELF_MANAGEMENT_ON) != "true") {
				if (deepSleepInterval != MIAOMIAO_DISCONNECTED_MODE) {
					Trace.myTrace("DeepSleepService.as", "Setting interval to MIAOMIAO_DISCONNECTED_MODE = " + MIAOMIAO_DISCONNECTED_MODE/1000 + " seconds");
					deepSleepInterval = MIAOMIAO_DISCONNECTED_MODE;
					startDeepSleepInterval();
				}
			}
		}
		
		private static function onMiaoMiaoConnected(event:Event):void 
		{
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEEP_SLEEP_SELF_MANAGEMENT_ON) != "true") {
				if (deepSleepInterval != MIAOMIAO_CONNECTED_BUT_NO_INITIAL_UPDATE_CHARACTERISTIC_RECEIVED_MODE) {
					Trace.myTrace("DeepSleepService.as", "Setting interval to MIAOMIAO_CONNECTED_BUT_NO_INITIAL_UPDATE_CHARACTERISTIC_RECEIVED_MODE = " + MIAOMIAO_CONNECTED_BUT_NO_INITIAL_UPDATE_CHARACTERISTIC_RECEIVED_MODE/1000 + " seconds");
					deepSleepInterval = MIAOMIAO_CONNECTED_BUT_NO_INITIAL_UPDATE_CHARACTERISTIC_RECEIVED_MODE;
					startDeepSleepInterval();
				}
			}
		}		
		
		/**
		 * Getters & Setters
		 */
		
		public static function get instance():DeepSleepService
		{
			return _instance;
		}
	}
}