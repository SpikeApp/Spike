package services
{
	import com.spikeapp.spike.airlibrary.SpikeANE;
	
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import database.BlueToothDevice;
	
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
			if (BlueToothDevice.isMiaoMiao()) {
				//temporary disconnecting to allow other ios device to connect to the miaomiao
				SpikeANE.disconnectMiaoMiao();
				
				//set reconnecttimer to 20 seconds, after 20 seconds ios device will try to reconnect
				reconnectTimer = new Timer(5 * 1000, 1);
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