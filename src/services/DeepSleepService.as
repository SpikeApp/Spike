package services
{
	import com.freshplanet.ane.AirBackgroundFetch.BackgroundFetch;
	
	import flash.errors.IllegalOperationError;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import database.BlueToothDevice;
	import database.CommonSettings;
	
	import events.DeepSleepServiceEvent;
	import events.SettingsServiceEvent;
	import events.SpikeEvent;
	
	import utils.Trace;
	
	/**
	 * deepsleep timer will start a timer that expires every 10 seconds, indefinitely<br>
	 * at expiry a short sound of 1ms without anything in it will be played.<br>
	 * to keep the app awake<br>
	 * It also dispatches an event each time the timer expires, to notify other apps that need to do something at regular intervals
	 */
	public class DeepSleepService extends EventDispatcher
	{
		private static var deepSleepTimer:Timer;
		
		private static var _instance:DeepSleepService = new DeepSleepService();
		
		/**
		 * how often to play the 1ms sound, in ms 
		 */
		private static var deepSleepInterval:int = 5000;
		private static var lastLogPlaySoundTimeStamp:Number = 0;
		
		public static function get instance():DeepSleepService
		{
			return _instance;
		}
		
		public function DeepSleepService()
		{
			//Don't allow class to be instantiated
			if (_instance != null) {
				throw new IllegalOperationError("DeepSleepService class is not meant to be instantiated!");
			}
		}
		
		public static function init():void {
			setDeepSleepInterval();
			startDeepSleepTimer();
			Spike.instance.addEventListener(SpikeEvent.APP_IN_FOREGROUND, checkDeepSleepTimer);
			CommonSettings.instance.addEventListener(SettingsServiceEvent.SETTING_CHANGED, onCommonSettingsChanged);
		}
		
		private static function onCommonSettingsChanged(event:SettingsServiceEvent):void {
			if (event.data == CommonSettings.COMMON_SETTING_PERIPHERAL_TYPE) {
				setDeepSleepInterval();
			}
		}
		
		/**
		 * sets  deepSleepInterval, dependent on type of peripheral
		 */
		private static function setDeepSleepInterval():void {
			if (BlueToothDevice.isDexcomG4() || BlueToothDevice.isDexcomG5()) {
				//for dexcom G4 and G5 it is sufficient to wake up every 10 seconds
				if (deepSleepInterval != 10000) {
					deepSleepInterval = 10000;
					if (deepSleepTimer != null) {
						if (deepSleepTimer.running) {
							deepSleepTimer.stop();
							startDeepSleepTimer();
						}
					}
				}
			} else {
				//for follower it must be every 5 seconds, also for blucon it is better
				if (deepSleepInterval != 5000) {
					deepSleepInterval = 5000;
					if (deepSleepTimer != null) {
						if (deepSleepTimer.running) {
							deepSleepTimer.stop();
							startDeepSleepTimer();
						}
					}
				}
			}
		}
		
		private static function startDeepSleepTimer():void {
			deepSleepTimer = new Timer(deepSleepInterval,0);
			deepSleepTimer.addEventListener(TimerEvent.TIMER, deepSleepTimerListener);
			deepSleepTimer.start();
		}
		
		private static function checkDeepSleepTimer(event:Event):void {
			if (deepSleepTimer != null) {
				if (deepSleepTimer.running) {
					return;
				} else {
					deepSleepTimer = null;										
				}
			}
			startDeepSleepTimer();
		}
		
		private static function deepSleepTimerListener(event:Event):void {
			if (BackgroundFetch.isPlayingSound()) {
			} else {	
				if ((new Date()).valueOf() - lastLogPlaySoundTimeStamp > 1 * 60 * 1000) {
					myTrace("in deepSleepTimerListener, call playSound");
					lastLogPlaySoundTimeStamp = (new Date()).valueOf();
				}
				BackgroundFetch.playSound("../assets/1-millisecond-of-silence.mp3", 0);
			}
			//for other services that need to do something at regular intervals
			_instance.dispatchEvent(new DeepSleepServiceEvent(DeepSleepServiceEvent.DEEP_SLEEP_SERVICE_TIMER_EVENT));
		}
		
		private static function myTrace(log:String):void 
		{
			Trace.myTrace("DeepSleepService.as", log);
		}
	}
}