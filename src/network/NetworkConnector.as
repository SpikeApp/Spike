package network
{
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	
	import utils.Trace;

	public class NetworkConnector
	{
		public static var nightscoutTreatmentsLastModifiedHeader:String = "";
		
		public function NetworkConnector()
		{
		}
		
		/**
		 * Functionality
		 */
		public static function createNSConnector(URL:String, apiSecret:String, method:String, parameters:String = null, mode:String = null, completeHandler:Function = null, errorHandler:Function = null):void
		{
			//Create the URL Request
			var request:URLRequest = new URLRequest(URL);
			request.useCache = false;
			request.cacheResponse = false;
			request.method = method;
			if (parameters != null)
			{
				request.data = parameters;
				request.contentType = "application/json";
			}
			
			//Create Headers
			var noChacheHeader:URLRequestHeader = new URLRequestHeader("pragma", "no-cache");
			request.requestHeaders.push(noChacheHeader);
			if (apiSecret != null)
			{
				var apiSecretHeader:URLRequestHeader = new URLRequestHeader("api-secret", apiSecret);
				request.requestHeaders.push(apiSecretHeader);
			}
			
			//Create the URL Loader
			var urlLoader:URLLoader = new URLLoader();
			urlLoader.dataFormat = URLLoaderDataFormat.TEXT;
			//urlLoader.addEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, localHTTPStatus, false, 0, true);
			//urlLoader.addEventListener(HTTPStatusEvent.HTTP_STATUS, localHTTPStatus, false, 0, true);
			
			var finalCompleteHandler:Function;
			var finalIOHandler:Function;
			if (completeHandler != null)
			{
				finalCompleteHandler = completeHandler;
				finalIOHandler = completeHandler;
			}
			else
			{
				finalCompleteHandler = localCompleteHandler;
				finalIOHandler = localIOErrorHandler;
			}
				
			urlLoader.addEventListener(Event.COMPLETE, finalCompleteHandler, false, 0, true);
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, finalIOHandler, false, 0, true);
			
			//Perform connection
			try 
			{ 
				urlLoader.load(request); 
			}  
			catch (error:Error) 
			{
				manageConnectionError(urlLoader, error, finalCompleteHandler, finalIOHandler, errorHandler, mode);
			}
		}
		
		public static function createDSConnector(URL:String, method:String, sessionID:String = null, parameters:String = null, mode:String = null, completeHandler:Function = null, errorHandler:Function = null):void
		{
			//Create the URL Request
			var request:URLRequest = new URLRequest(sessionID == null ? URL : URL + "?sessionId=" + escape(sessionID));
			request.useCache = false;
			request.cacheResponse = false;
			request.method = method;
			if (parameters != null)
				request.data = parameters;
			request.contentType = "application/json";
			
			//Create Headers
			var noChacheHeader:URLRequestHeader = new URLRequestHeader("pragma", "no-cache");
			request.requestHeaders.push(noChacheHeader);
			
			//Create the URL Loader
			var urlLoader:URLLoader = new URLLoader();
			urlLoader.dataFormat = URLLoaderDataFormat.TEXT;
			//urlLoader.addEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, localHTTPStatus, false, 0, true);
			//urlLoader.addEventListener(HTTPStatusEvent.HTTP_STATUS, localHTTPStatus, false, 0, true);
			
			var finalCompleteHandler:Function;
			var finalIOHandler:Function;
			if (completeHandler != null)
			{
				finalCompleteHandler = completeHandler;
				finalIOHandler = completeHandler;
			}
			else
			{
				finalCompleteHandler = localCompleteHandler;
				finalIOHandler = localIOErrorHandler;
			}
			
			urlLoader.addEventListener(Event.COMPLETE, finalCompleteHandler, false, 0, true);
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, finalIOHandler, false, 0, true);
			
			//Perform connection
			try 
			{ 
				urlLoader.load(request); 
			}  
			catch (error:Error) 
			{
				manageConnectionError(urlLoader, error, finalCompleteHandler, finalIOHandler, errorHandler, mode);
			}
		}
		
		public static function createIFTTTConnector(URL:String, method:String, parameters:String, completeHandler:Function = null, errorHandler:Function = null):void
		{
			//Create the URL Request
			var request:URLRequest = new URLRequest(URL);
			request.useCache = false;
			request.cacheResponse = false;
			request.method = method;
			request.data = parameters;
			request.contentType = "application/json";
			
			//Create Headers
			var noChacheHeader:URLRequestHeader = new URLRequestHeader("pragma", "no-cache");
			request.requestHeaders.push(noChacheHeader);
			
			//Create the URL Loader
			var urlLoader:URLLoader = new URLLoader();
			urlLoader.dataFormat = URLLoaderDataFormat.TEXT;
			urlLoader.addEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, localHTTPStatus, false, 0, true);
			urlLoader.addEventListener(HTTPStatusEvent.HTTP_STATUS, localHTTPStatus, false, 0, true);
			
			var finalCompleteHandler:Function;
			var finalIOHandler:Function;
			if (completeHandler != null)
			{
				finalCompleteHandler = completeHandler;
				finalIOHandler = completeHandler;
			}
			else
			{
				finalCompleteHandler = localCompleteHandler;
				finalIOHandler = localIOErrorHandler;
			}
			
			urlLoader.addEventListener(Event.COMPLETE, finalCompleteHandler, false, 0, true);
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, finalIOHandler, false, 0, true);
			
			//Perform connection
			try 
			{ 
				urlLoader.load(request); 
			}  
			catch (error:Error) 
			{
				manageConnectionError(urlLoader, error, finalCompleteHandler, finalIOHandler, errorHandler);
			}
		}
		
		public static function createGlotConnector(URL:String, token:String, method:String, parameters:String = null, mode:String = null, completeHandler:Function = null, errorHandler:Function = null):void
		{
			//Create the URL Request
			var request:URLRequest = new URLRequest(URL);
			request.useCache = false;
			request.cacheResponse = false;
			request.method = method;
			if (parameters != null)
			{
				request.data = parameters;
				request.contentType = "application/json";
			}
			
			//Create Headers
			var noChacheHeader:URLRequestHeader = new URLRequestHeader("pragma", "no-cache");
			request.requestHeaders.push(noChacheHeader);
			if (token != null)
			{
				var apiSecretHeader:URLRequestHeader = new URLRequestHeader("Authorization", "Token " + token);
				request.requestHeaders.push(apiSecretHeader);
			}
			
			//Create the URL Loader
			var urlLoader:URLLoader = new URLLoader();
			urlLoader.dataFormat = URLLoaderDataFormat.TEXT;
			//urlLoader.addEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, localHTTPStatus, false, 0, true);
			//urlLoader.addEventListener(HTTPStatusEvent.HTTP_STATUS, localHTTPStatus, false, 0, true);
			
			var finalCompleteHandler:Function;
			var finalIOHandler:Function;
			if (completeHandler != null)
			{
				finalCompleteHandler = completeHandler;
				finalIOHandler = completeHandler;
			}
			else
			{
				finalCompleteHandler = localCompleteHandler;
				finalIOHandler = localIOErrorHandler;
			}
			
			urlLoader.addEventListener(Event.COMPLETE, finalCompleteHandler, false, 0, true);
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, finalIOHandler, false, 0, true);
			
			//Perform connection
			try 
			{ 
				urlLoader.load(request); 
			}  
			catch (error:Error) 
			{
				manageConnectionError(urlLoader, error, finalCompleteHandler, finalIOHandler, errorHandler, mode);
			}
		}
		
		public static function createAppCenterConnector(URL:String, apiSecret:String, method:String, parameters:String = null, mode:String = null, completeHandler:Function = null, errorHandler:Function = null):void
		{
			//Create the URL Request
			var request:URLRequest = new URLRequest(URL);
			request.useCache = false;
			request.cacheResponse = false;
			request.method = method;
			if (parameters != null)
			{
				request.data = parameters;
				request.contentType = "application/json";
			}
			
			//Create Headers
			var apiSecretHeader:URLRequestHeader = new URLRequestHeader("X-API-Token", apiSecret);
			request.requestHeaders.push(apiSecretHeader);
			var acceptHeader:URLRequestHeader = new URLRequestHeader("accept", "application/json");
			request.requestHeaders.push(acceptHeader);
			var contenTypeHeader:URLRequestHeader = new URLRequestHeader("Content-Type", "application/json");
			request.requestHeaders.push(contenTypeHeader);
			
			//Create the URL Loader
			var urlLoader:URLLoader = new URLLoader();
			urlLoader.dataFormat = URLLoaderDataFormat.TEXT;
			//urlLoader.addEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, localHTTPStatus, false, 0, true);
			//urlLoader.addEventListener(HTTPStatusEvent.HTTP_STATUS, localHTTPStatus, false, 0, true);
			
			var finalCompleteHandler:Function;
			var finalIOHandler:Function;
			if (completeHandler != null)
			{
				finalCompleteHandler = completeHandler;
				finalIOHandler = completeHandler;
			}
			else
			{
				finalCompleteHandler = localCompleteHandler;
				finalIOHandler = localIOErrorHandler;
			}
			
			urlLoader.addEventListener(Event.COMPLETE, finalCompleteHandler, false, 0, true);
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, finalIOHandler, false, 0, true);
			
			//Perform connection
			try 
			{ 
				urlLoader.load(request); 
			}  
			catch (error:Error) 
			{
				manageConnectionError(urlLoader, error, finalCompleteHandler, finalIOHandler, errorHandler, mode);
			}
		}
		
		public static function createSpikeUpdateConnector(URL:String, method:String, parameters:String = null, mode:String = null, completeHandler:Function = null, errorHandler:Function = null):void
		{
			//Create the URL Request
			var request:URLRequest = new URLRequest(URL);
			request.useCache = false;
			request.cacheResponse = false;
			request.method = method;
			if (parameters != null)
			{
				request.data = parameters;
				request.contentType = "application/json";
			}
			
			//Create Headers
			var contenTypeHeader:URLRequestHeader = new URLRequestHeader("Content-Type", "application/json");
			request.requestHeaders.push(contenTypeHeader);
			
			//Create the URL Loader
			var urlLoader:URLLoader = new URLLoader();
			urlLoader.dataFormat = URLLoaderDataFormat.TEXT;
			//urlLoader.addEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, localHTTPStatus, false, 0, true);
			//urlLoader.addEventListener(HTTPStatusEvent.HTTP_STATUS, localHTTPStatus, false, 0, true);
			
			var finalCompleteHandler:Function;
			var finalIOHandler:Function;
			if (completeHandler != null)
			{
				finalCompleteHandler = completeHandler;
				finalIOHandler = completeHandler;
			}
			else
			{
				finalCompleteHandler = localCompleteHandler;
				finalIOHandler = localIOErrorHandler;
			}
			
			urlLoader.addEventListener(Event.COMPLETE, finalCompleteHandler, false, 0, true);
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, finalIOHandler, false, 0, true);
			
			//Perform connection
			try 
			{ 
				urlLoader.load(request); 
			}  
			catch (error:Error) 
			{
				manageConnectionError(urlLoader, error, finalCompleteHandler, finalIOHandler, errorHandler, mode);
			}
		}
		
		public static function trackInstallationUsage(url:String, parameters:URLVariables, completeHandler:Function = null, errorHandler:Function = null):void
		{
			//Create the URL Request
			var request:URLRequest = new URLRequest(url);
			request.useCache = false;
			request.cacheResponse = false;
			request.method = URLRequestMethod.POST;
			request.data = parameters;
			
			//Create the URL Loader
			var urlLoader:URLLoader = new URLLoader();
			urlLoader.dataFormat = URLLoaderDataFormat.VARIABLES;
			
			var finalCompleteHandler:Function;
			var finalIOHandler:Function;
			if (completeHandler != null)
			{
				finalCompleteHandler = completeHandler;
				finalIOHandler = completeHandler;
			}
			else
			{
				finalCompleteHandler = localCompleteHandler;
				finalIOHandler = localIOErrorHandler;
			}
			
			urlLoader.addEventListener(Event.COMPLETE, finalCompleteHandler, false, 0, true);
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, finalIOHandler, false, 0, true);
			
			//Perform connection
			try 
			{ 
				urlLoader.load(request); 
			}  
			catch (error:Error) 
			{
				manageConnectionError(urlLoader, error, finalCompleteHandler, finalIOHandler, errorHandler);
			}
		}
		
		private static function manageConnectionError(loader:URLLoader, error:Error, completeHandler:Function, ioHandler:Function, errorHandler:Function = null, mode:String = null):void
		{
			//Dispose Loader
			loader.removeEventListener(Event.COMPLETE, completeHandler);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, ioHandler);
			loader.removeEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, localHTTPStatus);
			loader.removeEventListener(HTTPStatusEvent.HTTP_STATUS, localHTTPStatus);
			loader = null;
			
			//Notify Caller
			if (errorHandler != null)
			{
				if (mode != null)
				{
					errorHandler.call(null, error, mode);
				}
				else
				{
					errorHandler.call(null, error);
				}
			}
		}
		
		private static function disposeLoader(loader:URLLoader):void
		{
			if (loader != null)
			{
				loader.removeEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, localHTTPStatus);
				loader.removeEventListener(HTTPStatusEvent.HTTP_STATUS, localHTTPStatus);
				loader.removeEventListener(Event.COMPLETE, localCompleteHandler);
				loader.removeEventListener(IOErrorEvent.IO_ERROR, localIOErrorHandler);
				loader = null;
			}
		}
		
		/**
		 * Local Event Listeners
		 */
		private static function localHTTPStatus(e:HTTPStatusEvent):void
		{
			var loader:URLLoader = e.currentTarget as URLLoader;
			
			if (loader != null)
			{
				if (e != null && e.responseURL != null && e.responseURL.indexOf("/api/v1/treatments.json?find") != -1)
				{
					//It's a call to treatments
					if (e.responseHeaders != null && e.responseHeaders.length > 0)
					{
						for(var i:int = e.responseHeaders.length - 1 ; i >= 0; i--)
						{
							if (e.responseHeaders[i].name != null && e.responseHeaders[i].value != null && e.responseHeaders[i].name == "Etag")
							{
								nightscoutTreatmentsLastModifiedHeader = e.responseHeaders[i].value;
								break;
							}
						}
					}
				}
				
				if (String(loader.data) != "undefined")
					Trace.myTrace("NetworkConnector.as", "localHTTPStatus called. Message: " + String(loader.data));
				
				loader.removeEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, localHTTPStatus);
				loader.removeEventListener(HTTPStatusEvent.HTTP_STATUS, localHTTPStatus);
			}
		}
		
		private static function localIOErrorHandler(e:IOErrorEvent):void
		{
			var loader:URLLoader = e.currentTarget as URLLoader;
			Trace.myTrace("NetworkConnector.as", "localIOErrorHandler called. Message: " + String(loader.data));
			
			disposeLoader(e.currentTarget as URLLoader);
		}
		
		private static function localCompleteHandler(e:Event):void
		{
			var loader:URLLoader = e.currentTarget as URLLoader;
			Trace.myTrace("NetworkConnector.as", "localCompleteHandler called. Message: " + String(loader.data));
			
			disposeLoader(e.currentTarget as URLLoader);
		}
	}
}