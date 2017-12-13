package 
{
	import flash.desktop.NativeApplication;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.display3D.Context3DProfile;
	import flash.events.Event;
	import flash.utils.clearInterval;
	import flash.utils.setTimeout;
	
	import Utilities.Trace;
	
	import events.IosXdripReaderEvent;
	
	import feathers.utils.ScreenDensityScaleFactorManager;
	
	import services.DialogService;
	
	import starling.core.Starling;
	import starling.events.Event;
	
	import ui.AppInterface;
	
	import utils.Constants;
	
	[SWF(frameRate="60", backgroundColor="#20222a")]
	public class iOSDrip extends Sprite 
	{
		
		private var starling:Starling;
		
		private var scaler:ScreenDensityScaleFactorManager;
		
		private var timeoutID:int = -1;
		
		private static var _instance:iOSDrip;
		
		public static function get instance():iOSDrip
		{
			return _instance;
		}
		
		public function iOSDrip() 
		{
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			//stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
			
			_instance = this;
			
			stage.addEventListener( flash.events.Event.RESIZE, onStageResize );
			timeoutID = setTimeout( initStarling, 50 );
		}
		
		private function onStageResize( event:flash.events.Event ):void 
		{
			stage.removeEventListener( flash.events.Event.RESIZE, onStageResize );
			if( timeoutID != -1 ) 
				clearInterval( timeoutID );
			timeoutID = setTimeout( initStarling, 50 );
		}
		
		/**
		 * Initialization
		 */
		
		private function initStarling():void 
		{
			NativeApplication.nativeApplication.executeInBackground = true;
			DialogService.init(this.stage);
			
			
			/* Initialize and start the Starling instance */
			starling = new Starling( AppInterface, stage, null, null, "auto", Context3DProfile.BASELINE_EXTENDED );
			starling.enableErrorChecking = false;
			starling.skipUnchangedFrames = true;
			starling.antiAliasing = 1;
			//Starling.current.showStatsAt("right", "bottom");
			//Starling.current.showStatsAt("left", "bottom");
			scaler = new ScreenDensityScaleFactorManager( starling );
			
			/* Initialize Constants */
			Constants.init( starling.stage.stageWidth, starling.stage.stageHeight, stage );
			starling.addEventListener( starling.events.Event.ROOT_CREATED, onStarlingReady );
			
			/* Handle application Activation & Deactivation */
			NativeApplication.nativeApplication.addEventListener( flash.events.Event.ACTIVATE, onActivate );
			NativeApplication.nativeApplication.addEventListener( flash.events.Event.DEACTIVATE, onDeactivate );
		}
		
		/**
		 * Signal / Event handlers
		 */
		
		private function onStarlingReady( event:starling.events.Event, root:AppInterface ):void 
		{
			/* Start Starling */
			starling.start();
			
			/* Start Interface */
			root.start();
		}
		
		/**
		 * Application activate/deactivate handlers
		 */
		
		private function onActivate( event:flash.events.Event ):void 
		{
			myTrace("dispatching event IosXdripReaderEvent.APP_IN_FOREGROUND");
			dispatchEvent(new IosXdripReaderEvent(IosXdripReaderEvent.APP_IN_FOREGROUND));
			
			starling.start();
		}
		
		private function onDeactivate( event:flash.events.Event ):void 
		{
			starling.stop( true );
		}
		
		/**
		 * Utility Functions
		 */
		
		private static function myTrace(log:String):void {
			Trace.myTrace("iOSDrip.as", log);
		}
		
	}
	
}
