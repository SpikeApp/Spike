package services
{
	import com.freshplanet.ane.AirBackgroundFetch.BackgroundFetch;
	
	import flash.events.EventDispatcher;
	import flash.utils.setInterval;
	
	import utils.Trace;

	/**
	 * deepsleep timer will start a timer that expires every 60 seconds, indefinitely<br>
	 * at expiry a short sound of 1ms without anything in it will be played.<br>
	 * to keep the app awake<br>
	 * It also dispatches an event each time the timer expires, to notify other apps that need to do something at regular intervals
	 */
	public class DeepSleepService extends EventDispatcher
	{
		private static var _instance:DeepSleepService;

		public static function get instance():DeepSleepService
		{
			return _instance;
		}

		public function DeepSleepService( enforcer:SingletonEnforcer ) {}
		
		public static function init():void 
		{
			Trace.myTrace("DeepSleepService.as", "Service started!");
			
			if (_instance == null)
				_instance = new DeepSleepService(new SingletonEnforcer());
			
			setInterval(playSound, 60000);
		}
		
		private static function playSound():void
		{
			if (!BackgroundFetch.isPlayingSound()) 
				BackgroundFetch.playSound("../assets/sounds/1-millisecond-of-silence.mp3", 0);
		}
	}
}

class SingletonEnforcer {}