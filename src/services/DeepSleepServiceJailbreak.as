package services
{
	import com.freshplanet.ane.AirBackgroundFetch.BackgroundFetch;
	
	import flash.errors.IllegalOperationError;
	import flash.events.EventDispatcher;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	import flash.net.URLRequest;
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
			/* Init objects */
			soundTransform = new SoundTransform(0.001);
			sound = new Sound(new URLRequest("../assets/sounds/1-millisecond-of-silence.mp3"));
			
			/* Set deep sleep interval */
			setInterval(playSilence, 60000);
		}
		
		private static function playSilence():void 
		{
			sound.play(0, 0, soundTransform); 
			//sound.play(); 
			
			//if (!BackgroundFetch.isPlayingSound()) 
				//BackgroundFetch.playSound("../assets/sounds/20ms-of-silence.caf", 0.1);
		
			//for other services that need to do something at regular intervals
			_instance.dispatchEvent(new DeepSleepServiceEvent(DeepSleepServiceEvent.DEEP_SLEEP_SERVICE_TIMER_EVENT));
		}
	}
}