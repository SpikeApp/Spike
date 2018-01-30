package services
{
	import com.freshplanet.ane.AirBackgroundFetch.BackgroundFetch;
	
	import flash.errors.IllegalOperationError;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	import flash.net.URLRequest;
	import flash.utils.Timer;
	import flash.utils.setInterval;
	
	import events.DeepSleepServiceEvent;

	/**
	 * deepsleep timer will start a timer that expires every 10 seconds, indefinitely<br>
	 * at expiry a short sound of 1ms without anything in it will be played.<br>
	 * to keep the app awake<br>
	 * It also dispatches an event each time the timer expires, to notify other apps that need to do something at regular intervals
	 */
	public class DeepSleepService extends EventDispatcher
	{
		/* Objects */
		private static var _instance:DeepSleepService = new DeepSleepService();
		private static var sound:Sound;
		private static var soundTransform:SoundTransform;

		public static function get instance():DeepSleepService
		{
			return _instance;
		}

		public function DeepSleepService()
		{
			//Don't allow class to be instantiated
			if (_instance != null)
				throw new IllegalOperationError("DeepSleepService class is not meant to be instantiated!");
		}
		
		public static function init():void 
		{
			trace("STARTED DEEP SLEEP TIMER!!!!");
			/* Init objects */
			soundTransform = new SoundTransform(0.001);
			//sound = new Sound(new URLRequest("../assets/sounds/shorthigh1.mp3"));
			
			/* Set deep sleep interval */
			startDeepSleepTimer();
		}
		
		private static function startDeepSleepTimer():void {
			var deepSleepTimer:Timer = new Timer(30000,0);
			deepSleepTimer.addEventListener(TimerEvent.TIMER, deepSleepTimerListener);
			deepSleepTimer.start();
		}
		
		private static function deepSleepTimerListener(event:Event):void 
		{
			//sound.play(0, 0, soundTransform);
			sound = new Sound(new URLRequest("../assets/sounds/shorthigh1.mp3"));
			sound.play();
			sound.close();
			
			//for other services that need to do something at regular intervals
			_instance.dispatchEvent(new DeepSleepServiceEvent(DeepSleepServiceEvent.DEEP_SLEEP_SERVICE_TIMER_EVENT));
		}
	}
}