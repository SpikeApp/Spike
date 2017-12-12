package services
{
	import com.freshplanet.ane.AirBackgroundFetch.BackgroundFetch;
	
	import flash.errors.IllegalOperationError;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import Utilities.Trace;
	
	import events.DeepSleepServiceEvent;
	import events.DialogServiceEvent;
	import events.IosXdripReaderEvent;

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
			startDeepSleepTimer();
			iosxdripreader.instance.addEventListener(IosXdripReaderEvent.APP_IN_FOREGROUND, checkDeepSleepTimer);
		}
		
		private static function startDeepSleepTimer():void {
			deepSleepTimer = new Timer(10000,0);
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
				BackgroundFetch.playSound("../assets/1-millisecond-of-silence.mp3");
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