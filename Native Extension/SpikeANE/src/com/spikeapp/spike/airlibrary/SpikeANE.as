package com.spikeapp.spike.airlibrary
{
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.external.ExtensionContext;
	
	public class SpikeANE extends EventDispatcher
	{
		private static var context : ExtensionContext; 
		private static const EXTENSION_ID : String = "com.spike-app.spike.AirNativeExtension";
		public function SpikeANE(target:IEventDispatcher=null)
		{
			super(target);
		}
		
		public static function traceNSLog(log:String) : void { 
			if (context != null) {
				context.call( "traceNSLog", log ); 
			}
		}
		
		public static function init():void {
			if (context == null) {
				context = ExtensionContext.createExtensionContext("com.spike-app.spike.AirNativeExtension","");
				context.call("init");
			}
		}
	}
}