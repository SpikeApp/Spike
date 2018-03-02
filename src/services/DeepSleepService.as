package services
{
	import com.freshplanet.ane.AirBackgroundFetch.BackgroundFetch;
	
	import flash.errors.IllegalOperationError;
	import flash.events.EventDispatcher;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	import flash.net.URLRequest;
	import flash.utils.clearInterval;
	import flash.utils.setInterval;
	
	import database.BlueToothDevice;
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
		
		/* Objects */
		private static var _instance:DeepSleepService = new DeepSleepService();
		private static var soundPlayer:Sound;
		private static var channel:SoundChannel;
		private static var soundTransform:SoundTransform;
		private static var soundFile:URLRequest;
		
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
		}
		
		private static function createSoundProperties():void
		{
			soundTransform = new SoundTransform(0.001);
			soundFile = new URLRequest("../assets/sounds/1-millisecond-of-silence.mp3");
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
				if (BlueToothDevice.isDexcomG4() || BlueToothDevice.isDexcomG5()) 
				{
					Trace.myTrace("DeepSleepService.as", "Setting interval to AUTOMATIC_DEXCOM");
					deepSleepInterval = AUTOMATIC_DEXCOM;
				}
				else if (BlueToothDevice.isFollower())
				{
					Trace.myTrace("DeepSleepService.as", "Setting interval to AUTOMATIC_FOLLOWER");
					deepSleepInterval = AUTOMATIC_FOLLOWER;
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
			Trace.myTrace("DeepSleepService.as", "Starting deep sleep interval!");
			
			//Clear any previous intervals
			clearInterval( intervalID );
			
			//Start new interval
			intervalID = setInterval( playSound, deepSleepInterval);
		}
		
		private static function playSound():void 
		{
			if (!BackgroundFetch.isPlayingSound() && !Constants.appInForeground && !BackgroundFetch.appIsInForeground()) //No need to play if the app is in the foregorund
			{
				var now:Number = new Date().valueOf();
				if (now - lastLogPlaySoundTimeStamp > 1 * 60 * 1000) 
				{
					Trace.myTrace("DeepSleepService.as", "Playing deep sleep sound...");
					lastLogPlaySoundTimeStamp = now;
				}
				
				if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEEP_SLEEP_ALTERNATIVE_MODE) == "true")
				{
					soundPlayer = null;
					soundPlayer = new Sound(soundFile);
					channel = soundPlayer.play();
					channel.soundTransform = soundTransform;
				}
				else
					BackgroundFetch.playSound("../assets/sounds/1-millisecond-of-silence.mp3", 0);
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