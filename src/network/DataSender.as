package network
{
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.utils.ByteArray;
	
	import model.ModelLocator;
	
	import ui.popups.AlertManager;

	public class DataSender
	{
		/* Constants */
		public static const TRANSMISSION_URL_WITH_ATTACHMENT:String = "https://spike-app.com/sparkpost/transmission_with_attachment.php";
		public static const MODE_EMAIL_SUPPORT:String = "emailToSupport";
		public static const MODE_EMAIL_USER:String = "emailToUser";
		
		public function DataSender()
		{
		}
		
		public static function sendData(URL:String, completeHandler:Function, variables:URLVariables = null, rawData:ByteArray = null):void
		{
			//Format URL
			var requestURL:String = URL;
			if (variables != null) requestURL += "?" + variables.toString();
			
			//Create the URL Request
			var request:URLRequest = new URLRequest(requestURL);
			request.contentType = "application/octet-stream";
			request.method = URLRequestMethod.POST;
			if (rawData != null) request.data = rawData;
			
			//Create the URL Loader
			var urlLoader:URLLoader = new URLLoader();
			urlLoader.addEventListener(flash.events.Event.COMPLETE, completeHandler, false, 0, true);
			urlLoader.dataFormat = URLLoaderDataFormat.VARIABLES;
			
			//Send data to server
			try 
			{ 
				urlLoader.load(request); 
			}  
			catch (error:Error) 
			{ 
				AlertManager.showSimpleAlert
				(
					ModelLocator.resourceManagerInstance.getString('globaltranslations','error_alert_title'),
					ModelLocator.resourceManagerInstance.getString('globaltranslations','connection_error') + " " + error
				);
			} 
		}
	}
}