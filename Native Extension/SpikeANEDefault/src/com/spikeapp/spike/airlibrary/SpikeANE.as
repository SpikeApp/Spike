package com.spikeapp.spike.airlibrary
{
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	public class SpikeANE extends EventDispatcher
	{
		public function SpikeANE(target:IEventDispatcher=null)
		{
			super(target);
		}
		
		public static function traceNSLog(log:String) : void { 
			trace(log);
		}
		
		public static function init():void {
		}
	}
}