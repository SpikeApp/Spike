package services
{
	import com.spikeapp.spike.airlibrary.SpikeANE;
	
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import database.CGMBlueToothDevice;
	
	import events.TransmitterServiceEvent;
	
	import utils.Trace;

	public class MultipleMiaoMiaoService
	{
		private static var reconnectTimer:Timer;//sometimes discover services just doesn't give anything, mainly with xdrip/xbridge this happened
	
		public function MultipleMiaoMiaoService()
		{
		}
		
		public static function init():void {
			myTrace("init");
			TransmitterService.instance.addEventListener(TransmitterServiceEvent.BGREADING_EVENT, bgReadingReceived);
		}

		private static function bgReadingReceived(be:TransmitterServiceEvent):void {
			if (CGMBlueToothDevice.isMiaoMiao()) {
				//temporary disconnecting to allow other ios device to connect to the miaomiao
				SpikeANE.disconnectMiaoMiao();
				
				if (reconnectTimer != null) {
					if (reconnectTimer.running) {
						myTrace("timer already running, not restarting");
						return;
					}
				}
				//set reconnecttimer to 10 seconds, after 10 seconds ios device will try to reconnect
				myTrace("starting timer");
				reconnectTimer = new Timer(10 * 1000, 1);
				reconnectTimer.addEventListener(TimerEvent.TIMER, reconnect);
				reconnectTimer.start();
			}
		}
		
		private static function reconnect(event:Event):void {
			SpikeANE.reconnectMiaoMiao();
		}

		private static function myTrace(log:String):void {
			Trace.myTrace("MultipleMiaoMiaoService.as", log);
		}

	}
}