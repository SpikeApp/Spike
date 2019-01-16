package services
{
	import flash.events.Event;
	
	import cryptography.Keys;
	
	import database.LocalSettings;
	
	import events.FollowerEvent;
	import events.SettingsServiceEvent;
	import events.SpikeEvent;
	import events.TransmitterServiceEvent;
	
	import network.httpserver.HttpServer;
	import network.httpserver.API.DexcomShareController;
	import network.httpserver.API.NightscoutAPI1Controller;
	import network.httpserver.API.NightscoutAPIGeneralController;
	import network.httpserver.API.SpikeTreatmentsController;
	
	import utils.Cryptography;
	import utils.Trace;

	public class HTTPServerService
	{
		/* Objects */
		private static var httpServer:HttpServer;

		/* Variables */
		private static var httpServerServiceEnabled:Boolean;
		private static var dexcomServerUsername:String;
		private static var dexcomServerPassword:String;
		private static var serviceActive:Boolean = false;

		/* Controllers */
		private static var dexcomAuthenticationController:DexcomShareController;
		private static var dexcomGlucoseController:DexcomShareController;
		private static var nsGeneralController:NightscoutAPIGeneralController;
		private static var nsAPI1Controller:NightscoutAPI1Controller;
		private static var nsAPI1StatusController:NightscoutAPI1Controller;
		private static var spikeTreatmentsController:SpikeTreatmentsController;
		
		public function HTTPServerService()
		{
			throw new Error("HTTPServerService is not meant to be instantiated!");
		}
		
		public static function init():void
		{
			Trace.myTrace("HTTPServerService.as", "Service started!");
			
			getInitialProperties();
			
			if (httpServerServiceEnabled)
				activateService();
			
			Spike.instance.addEventListener(SpikeEvent.APP_HALTED, onHaltExecution);
			LocalSettings.instance.addEventListener(SettingsServiceEvent.SETTING_CHANGED, onSettingsChanged);
		}
		
		private static function getInitialProperties():void
		{
			httpServerServiceEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_LOOP_SERVER_ON) == "true";
			dexcomServerUsername = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_LOOP_SERVER_USERNAME);
			dexcomServerPassword = Cryptography.decryptStringLight(Keys.STRENGTH_256_BIT, LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_LOOP_SERVER_PASSWORD));
			
			if (dexcomAuthenticationController != null)
			{
				dexcomAuthenticationController.accountName = dexcomServerUsername;
				dexcomAuthenticationController.password = dexcomServerPassword;
			}
		}
		
		private static function activateService():void
		{
			try
			{
				//Dexcom Controllers
				dexcomAuthenticationController = new DexcomShareController('/ShareWebServices/Services/General');
				dexcomAuthenticationController.accountName = dexcomServerUsername;
				dexcomAuthenticationController.password = dexcomServerPassword;
				dexcomGlucoseController = new DexcomShareController('/ShareWebServices/Services/Publisher');
				
				//Nightscout
				nsGeneralController = new NightscoutAPIGeneralController('');
				nsAPI1Controller = new NightscoutAPI1Controller('/api/v1/entries');
				nsAPI1StatusController = new NightscoutAPI1Controller('/api/v1');
				
				//Spike
				spikeTreatmentsController = new SpikeTreatmentsController('/SpikeTreatments');
				
				//Server
				httpServer = new HttpServer();
				httpServer.registerController(dexcomAuthenticationController);			
				httpServer.registerController(dexcomGlucoseController);
				httpServer.registerController(nsGeneralController);
				httpServer.registerController(nsAPI1Controller);
				httpServer.registerController(nsAPI1StatusController);
				httpServer.registerController(spikeTreatmentsController);
				httpServer.listen(1979);
				
				TransmitterService.instance.addEventListener(TransmitterServiceEvent.LAST_BGREADING_RECEIVED, onBgreadingReceived);
				NightscoutService.instance.addEventListener(FollowerEvent.BG_READING_RECEIVED, onBgreadingReceived);
				DexcomShareService.instance.addEventListener(FollowerEvent.BG_READING_RECEIVED, onBgreadingReceived);
				
				Trace.myTrace("HTTPServerService.as", "Service activated!");
			} 
			catch(error:Error) 
			{
				Trace.myTrace("HTTPServerService.as", "Cannot activate service. Error: " + error.message);
			}
			
			serviceActive = true;
		}
		
		private static function deactivateService():void
		{
			Trace.myTrace("HTTPServerService.as", "Service deactivated!");
			
			if (dexcomAuthenticationController != null)
				dexcomAuthenticationController = null;
			
			if (dexcomGlucoseController != null)
				dexcomGlucoseController = null;
			
			if (nsGeneralController != null)
				nsGeneralController = null;
			
			if (nsAPI1Controller != null)
				nsAPI1Controller = null;
			
			if (nsAPI1StatusController != null)
				nsAPI1StatusController = null;
			
			if (spikeTreatmentsController != null)
				spikeTreatmentsController = null;
			
			if (httpServer != null)
			{
				httpServer.close();
				httpServer = null;
			}
			
			TransmitterService.instance.removeEventListener(TransmitterServiceEvent.LAST_BGREADING_RECEIVED, onBgreadingReceived);
			NightscoutService.instance.removeEventListener(FollowerEvent.BG_READING_RECEIVED, onBgreadingReceived);
			DexcomShareService.instance.removeEventListener(FollowerEvent.BG_READING_RECEIVED, onBgreadingReceived);
			
			serviceActive = false;
		}
		
		/**
		 * Event Handlers
		 */
		private static function onBgreadingReceived(e:Event):void 
		{
			//Reenable Http Server in case it goes down
			if (serviceActive && !httpServer.serverSocket.listening)
			{	
				Trace.myTrace("HTTPServerService.as", "Service is down... Reconnecting!");
				deactivateService()
				activateService();
			}
		}
		private static function onSettingsChanged(e:SettingsServiceEvent):void
		{
			if (e.data == LocalSettings.LOCAL_SETTING_LOOP_SERVER_ON || 
				e.data == LocalSettings.LOCAL_SETTING_LOOP_SERVER_PASSWORD || 
				e.data == LocalSettings.LOCAL_SETTING_LOOP_SERVER_USERNAME
			)
			{
				getInitialProperties();
			}
			
			if (httpServerServiceEnabled)
			{
				if (!serviceActive)
					activateService();
			}
			else
			{
				if (serviceActive)
					deactivateService();
			}
		}
		
		/**
		 * Stops the service entirely. Useful for database restores
		 */
		private static function onHaltExecution(e:SpikeEvent):void
		{
			Trace.myTrace("HTTPServerService.as", "Stopping service...");
			
			LocalSettings.instance.removeEventListener(SettingsServiceEvent.SETTING_CHANGED, onSettingsChanged);
			
			deactivateService();
		}
	}
}