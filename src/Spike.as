package 
{
	import flash.desktop.NativeApplication;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.display3D.Context3DProfile;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.UncaughtErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLVariables;
	import flash.system.System;
	import flash.utils.clearInterval;
	import flash.utils.setTimeout;
	
	import mx.utils.ObjectUtil;
	
	import events.SpikeEvent;
	
	import feathers.utils.ScreenDensityScaleFactorManager;
	
	import network.EmailSender;
	
	import starling.core.Starling;
	import starling.events.Event;
	import starling.utils.SystemUtil;
	
	import ui.AppInterface;
	
	import utils.Constants;
	import utils.Trace;
	
	[SWF(frameRate="60", backgroundColor="#20222a")]
	
	public class Spike extends Sprite 
	{
		private static const TIME_1_MINUTE:int = 60 * 1000;
		private var starling:Starling;
		private var scaler:ScreenDensityScaleFactorManager;	
		private var timeoutID:int = -1;
		private var lastCrashReportTimestamp:Number = 0;
		
		private static var _instance:Spike;
		
		public static function get instance():Spike
		{
			return _instance;
		}
		
		public function Spike() 
		{
			SystemUtil.initialize();
			
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			//stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
			
			_instance = this;
			
			stage.addEventListener( flash.events.Event.RESIZE, onStageResize );
			
			/* Global Exceptions Handling */
			loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onUncaughtError);
			
			/* Start Starling */
			timeoutID = setTimeout( initStarling, 50 );
		}
		
		private function onUncaughtError(e:UncaughtErrorEvent):void
		{
			if (e.error is Error)
			{
				var error:Error = e.error as Error;
				sendError("<p>Error ID: " + error.errorID + "</p><p>Error Name: " + error.name + "</p><p> Error Message: " + error.message + "</p><p>Error Stack Trace: " + error.getStackTrace() + "</p>");
			}
			else
			{
				var errorEvent:ErrorEvent = e.error as ErrorEvent;
				sendError("<p>Error Event ID: " + errorEvent.errorID + "</p><p>Text: " + errorEvent.text + "</p><p>Type: " + errorEvent.type + "</p><p>Target: " + ObjectUtil.toString(errorEvent.target) + "</p><p>Current Target: " + ObjectUtil.toString(errorEvent.currentTarget));
			}
		}
		
		private function sendError(error:String):void
		{
			//Things we don't want to report
			if ( 
				error.indexOf("ioError") != -1 ||
				error.indexOf("Unexpected < encountered") != -1 ||
				error.indexOf("Unexpected T encountered") != -1 ||
				error.indexOf("PickerList/closeList()") != -1
				)
			{
				return;
			}
			
			var now:Number = new Date().valueOf();
			
			//Don't send consecutive errors that might happen on onEnterFrame events. Not usefull and will save battery life
			if (now - lastCrashReportTimestamp < TIME_1_MINUTE)
				return;
			
			lastCrashReportTimestamp = now;
			
			//Create URL Request 
			var vars:URLVariables = new URLVariables();
			vars.mimeType = "text/html";
			vars.emailSubject = "Spike Uncaught Error";
			vars.emailBody = error;
			vars.userName = "";
			vars.userEmail = "bug@spike-app.com";
			
			//Send Email
			EmailSender.sendData
			(
				EmailSender.TRANSMISSION_URL_NO_ATTACHMENT,
				onLoadCompleteHandler,
				vars
			);
		}
		
		private function onLoadCompleteHandler(event:flash.events.Event):void 
		{ 
			var loader:URLLoader = URLLoader(event.target);
			loader.removeEventListener(flash.events.Event.COMPLETE, onLoadCompleteHandler);
			loader = null;
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
			Starling.current.stage3D.addEventListener(flash.events.Event.CONTEXT3D_CREATE, onContextCreated, false, 50, true);
			
			/* Handle Application Activation & Deactivation */
			NativeApplication.nativeApplication.addEventListener( flash.events.Event.ACTIVATE, onActivate );
			NativeApplication.nativeApplication.addEventListener( flash.events.Event.DEACTIVATE, onDeactivate );
		}
		
		private function onContextCreated(event:flash.events.Event):void
		{
			Trace.myTrace("Spike.as", "onContextCreated! Event Debug: " + ObjectUtil.toString(event));
		}
		
		/**
		 * Event Handlers
		 */
		private function onStarlingReady( event:starling.events.Event, root:AppInterface ):void 
		{
			/* Start Starling */
			SystemUtil.executeWhenApplicationIsActive( starling.start );
			
			/* Start Interface */
			SystemUtil.executeWhenApplicationIsActive( root.start );
		}
		
		private function onActivate( event:flash.events.Event ):void 
		{
			//Resume normal framerate
			Starling.current.nativeStage.frameRate = 60;
			
			//Start Starling
			NativeApplication.nativeApplication.executeInBackground = false;
			SystemUtil.executeWhenApplicationIsActive( starling.start );
			
			//Update Variables
			Constants.appInForeground = true;
			
			//Notify Services
			myTrace("dispatching event SpikeEvent.APP_IN_FOREGROUND");
			instance.dispatchEvent(new SpikeEvent(SpikeEvent.APP_IN_FOREGROUND));
		}
		
		private function onDeactivate( event:flash.events.Event ):void 
		{
			//Decrease framerate almost to a halt
			Starling.current.nativeStage.frameRate = 0.5;
			
			//Update Variables
			Constants.noLockEnabled = false;
			Constants.appInForeground = false;
			
			//Stop Starling 
			NativeApplication.nativeApplication.executeInBackground = true;
			starling.stop( true );
			
			//Notify Services
			myTrace("dispatching event SpikeEvent.APP_IN_BACKGROUND");
			instance.dispatchEvent(new SpikeEvent(SpikeEvent.APP_IN_BACKGROUND));
			
			//Call Garbage Collector
			System.pauseForGCIfCollectionImminent(0);
		}
		
		/**
		 * Utility Functions
		 */
		private static function myTrace(log:String):void {
			Trace.myTrace("Spike.as", log);
		}	
	}	
}
