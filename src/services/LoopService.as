package services
{
	import network.httpserver.HttpServer;
	
	import flash.system.System;
	
	import database.LocalSettings;
	
	import events.SettingsServiceEvent;
	import events.TransmitterServiceEvent;
	
	import utils.Trace;

	public class LoopService
	{
		/* Objects */
		private static var loopServer:HttpServer;

		/* Variables */
		private static var loopServiceEnabled:Boolean;
		private static var serverUsername:String;
		private static var serverPassword:String;
		private static var serviceActive:Boolean = false;

		private static var authenticationController:LoopServiceController;

		private static var glucoseController:LoopServiceController;
		
		public function LoopService()
		{
			throw new Error("LoopService is not meant to be instantiated!");
		}
		
		public static function init():void
		{
			Trace.myTrace("LoopService.as", "Service started!");
			
			getInitialProperties();
			
			if (loopServiceEnabled && serverUsername != "" && serverPassword != "")
				activateService();
			
			LocalSettings.instance.addEventListener(SettingsServiceEvent.SETTING_CHANGED, onSettingsChanged);
		}
		
		private static function getInitialProperties():void
		{
			loopServiceEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_LOOP_SERVER_ON) == "true";
			serverUsername = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_LOOP_SERVER_USERNAME);
			serverPassword = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_LOOP_SERVER_PASSWORD);
			
			if (authenticationController != null)
			{
				authenticationController.accountName = serverUsername;
				authenticationController.password = serverPassword;
			}
		}
		
		private static function activateService():void
		{
			Trace.myTrace("LoopService.as", "Service activated!");
			
			try
			{
				//Controllers
				authenticationController = new LoopServiceController('/ShareWebServices/Services/General');
				authenticationController.accountName = serverUsername;
				authenticationController.password = serverPassword;
				
				glucoseController = new LoopServiceController('/ShareWebServices/Services/Publisher');
				
				//Server
				loopServer = new HttpServer();
				loopServer.registerController(authenticationController);			
				loopServer.registerController(glucoseController);
				loopServer.listen(1979);
				
				TransmitterService.instance.addEventListener(TransmitterServiceEvent.BGREADING_EVENT, onBgreadingReceived);
			} 
			catch(error:Error) 
			{
				Trace.myTrace("LoopService.as", "Cannot activate service. Error: " + error.message);
			}
			
			serviceActive = true;
		}
		
		private static function deactivateService():void
		{
			Trace.myTrace("LoopService.as", "Service deactivated!");
			
			if (authenticationController != null)
				authenticationController = null;
			
			if (glucoseController != null)
				glucoseController = null;
			
			if (loopServer != null)
			{
				loopServer.close();
				loopServer = null;
			}
			
			TransmitterService.instance.removeEventListener(TransmitterServiceEvent.BGREADING_EVENT, onBgreadingReceived);
			
			serviceActive = false;
		}
		
		/**
		 * Event Handlers
		 */
		private static function onBgreadingReceived(e:TransmitterServiceEvent):void 
		{
			//Reenable Loop Server in case it goes down
			if (serviceActive && !loopServer.serverSocket.listening)
			{	
				Trace.myTrace("LoopService.as", "Service is down... Reconnecting!");
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
				getInitialProperties();
			else
				return;
			
			if (loopServiceEnabled && serverUsername != "" && serverPassword != "")
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
	}
}