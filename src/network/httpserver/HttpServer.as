package network.httpserver
{
    import com.distriqt.extension.notifications.Notifications;
    import com.distriqt.extension.notifications.builders.NotificationBuilder;
    
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.events.ProgressEvent;
    import flash.events.ServerSocketConnectEvent;
    import flash.net.ServerSocket;
    import flash.net.Socket;
    import flash.net.URLVariables;
    import flash.utils.ByteArray;
    import flash.utils.clearInterval;
    import flash.utils.setTimeout;
    
    import events.HTTPServerEvent;
    
    import model.ModelLocator;
    
    import services.NotificationService;
    
    import ui.popups.AlertManager;
    
    import utils.BadgeBuilder;
    import utils.SpikeJSON;
    import utils.Trace;
	
	[ResourceBundle("httpserverservice")]
	
    public class HttpServer extends EventDispatcher
    {
		/* Constants */
		private static const MAX_CONNECTION_ATTEMPTS:uint = 50;
		private static var _instance:HttpServer = new HttpServer();
		
        private var _serverSocket:ServerSocket;
        private var _controllers:Object = new Object();
        private var _isConnected:Boolean = false;
		private var _connectionRetries:int = 0;
		private var _timeoutID:int = -1;

        public function HttpServer() {}
        
        public function get isConnected():Boolean
        {
            return _isConnected;
        }
        
        /**
        * Begin listening on a specified port.
        * 
        * @param port The localhost port to begin listening on.
        */
        public function listen(port:int):void
        {   
			//Clear previous connection retry
			if( _timeoutID != -1 ) 
				clearInterval( _timeoutID );
			
			//Connect server
            try
            {
                _serverSocket = new ServerSocket();
                _serverSocket.addEventListener(Event.CONNECT, socketConnectHandler);
				_serverSocket.addEventListener(Event.CLOSE, close);
                _serverSocket.bind(port);
                _serverSocket.listen();
            }
            catch (error:Error)
            {
				_isConnected = false;
				
				if (_connectionRetries < MAX_CONNECTION_ATTEMPTS)
				{
					_connectionRetries++;
					_timeoutID = setTimeout( listen, 5000, port );
					
					Trace.myTrace("HttpServer.as", "Server error! Retrying connection in 5 seconds. Reconnection attempt: " + _connectionRetries);
					
					_isConnected = false;
					
					return;
				}
				else
				{
					Trace.myTrace("HttpServer.as", "Server error! Can't bind to port: " + port + ". Notifying user...");
					
					//Alert
					var message:String = ModelLocator.resourceManagerInstance.getString('httpserverservice','error_alert_mesage').replace("{port}", port.toString());
					
					AlertManager.showSimpleAlert(ModelLocator.resourceManagerInstance.getString('httpserverservice','error_alert_title'), message);
					
					//Notification
					var notificationBuilder:NotificationBuilder = new NotificationBuilder()
						.setCount(BadgeBuilder.getAppBadge())
						.setId(NotificationService.ID_FOR_HTTP_SERVER_DOWN)
						.setAlert(ModelLocator.resourceManagerInstance.getString('httpserverservice','error_alert_title'))
						.setTitle(ModelLocator.resourceManagerInstance.getString('httpserverservice','error_alert_title'))
						.setBody(message)
						.enableVibration(true)
						.enableLights(true)
						.setSound("../assets/sounds/Insistently.caf");
					
					Notifications.service.notify(notificationBuilder.build());
					
					_isConnected = false;
					
					_instance.dispatchEvent(new HTTPServerEvent(HTTPServerEvent.SERVER_OFFLINE, false, false, { title: ModelLocator.resourceManagerInstance.getString('httpserverservice','error_alert_title'), message: message } ));
					
					return;
				}
            }
			
			Trace.myTrace("HttpServer.as", "Connection successful!");
			
			_isConnected = true;
        }
		
		/**
		 * Close Server
		 */
		public function close(e:Event = null):void
		{
			_serverSocket.removeEventListener(Event.CONNECT, socketConnectHandler);
			_serverSocket.removeEventListener(Event.CLOSE, close);
			
			try
			{
				_serverSocket.close();
				
				for (var i:String in _controllers)
				{
					if (i != null)
						_controllers[i] = null;
				}
			} 
			catch(error:Error)
			{
				Trace.myTrace("HttpServer.as", "Error closing server. Error: " + error.message);
			}
			
			_controllers = null;
			_serverSocket = null;
			
			Trace.myTrace("HttpServer.as", "Server closed!");
		}
        
        /**
        * Add a Controller to the Server
         */
        public function registerController(controller:ActionController):HttpServer
        {
            _controllers[controller.route] = controller;
            return this;  
        }
        
        /**
        * Handle new connections to the server.
         */
        private function socketConnectHandler(event:ServerSocketConnectEvent):void
        {
            var socket:Socket = event.socket;
            socket.addEventListener(ProgressEvent.SOCKET_DATA, socketDataHandler, false, 0, true);
        }
        
        /**
        * Handle data written to open connections. This is where the request is
        * parsed and routed to a controller.
         */
        private function socketDataHandler(event:ProgressEvent):void
        {
			try
            {
                var socket:Socket = event.target as Socket;
                var bytes:ByteArray = new ByteArray();

                // Get the request string and pull out the URL 
                socket.readBytes(bytes);
                var request:String          = "" + bytes;
				var url:String              = request.substring(4, request.indexOf("HTTP/") - 1).replace(".json","");
				if (url.substr(-1) == "/")
					url = url.slice(0, -1);
				
				// Parse out the controller name, action name and paramert list
                var url_pattern:RegExp      = /(.*)\/([^\?]*)\??(.*)$/;
                var controller_key:String   = url.replace(url_pattern, "$1").replace(" ", "");
                var action_key:String       = url.replace(url_pattern, "$2");
				var param_string:String     = url.replace(url_pattern, "$3");
				param_string = param_string == "" ? null : param_string;
				
				var parameters:URLVariables;
				
				if (request.substring(0, 4).toUpperCase().indexOf("GET") != -1 ) 
				{
					//GET request
					parameters = new URLVariables(param_string);
				}
				else if (request.substring(0, 4).toUpperCase().indexOf("POST") != -1 ) 
				{
					//POST request
					var postJSONResponse:Object = null;
					try
					{
						var messageLines:Array = request.split("\n");
						//postJSONResponse = JSON.parse(messageLines[messageLines.length - 1]);
						postJSONResponse = SpikeJSON.parse(messageLines[messageLines.length - 1]);
					} 
					catch(error:Error) 
					{
						Trace.myTrace("HttpServer.as", "Error parsing POST resquest! Error Message: " + error.message + ", POST Request: " + messageLines[messageLines.length - 1]);
						try
						{
							Trace.myTrace("HttpServer.as", "Trying to parse as URLVariables...");
							postJSONResponse = new URLVariables(messageLines[messageLines.length - 1]);
						} 
						catch(error:Error) 
						{
							Trace.myTrace("HttpServer.as", "Error parsing as URLVariables! Error: " + error.message);
						}
					}
					
					parameters = objectToURLVariables(postJSONResponse, param_string);
				}
				
				//Determine if the call is to a .json file and notify endpoint
				if (request.indexOf(".json") != -1)
					parameters.extension = "json";
				
				//Determine if the request is GET or POST and notify endpoint
				if (request.substring(0, 4).toUpperCase().indexOf("POST") != -1)
					parameters.method = "POST";
				else if (request.substring(0, 4).toUpperCase().indexOf("GET") != -1 ) 
					parameters.method = "GET";
				
				var controller:ActionController = _controllers[controller_key];
                
                if (controller) 
                    socket.writeUTFBytes(controller.doAction(action_key, parameters));
                
				//Discard socket
                socket.flush();
                socket.close();
				socket.removeEventListener(ProgressEvent.SOCKET_DATA, socketDataHandler);
				socket = null;
            }
            catch (error:Error)
            {
				if (String(error.message).indexOf("favicon.ico") == -1 && String(error.message).indexOf("1069") == -1 && String(error.message).indexOf("1009") == -1)
				{
					Trace.myTrace("HttpServer.as", "Error parsing request! Error: " + error.message);
                	AlertManager.showSimpleAlert(ModelLocator.resourceManagerInstance.getString('httpserverservice','error_alert_title'), error.message, 30);
				}
            }
        }
		
		private function objectToURLVariables(parameters:Object, variables:String = null):URLVariables
		{
			var paramsToSend:URLVariables;
			
			try
			{
				if (variables == null)
					paramsToSend = new URLVariables();
				else
					paramsToSend = new URLVariables(variables);
				
				if (parameters != null)
				{
					for (var i:String in parameters)
					{
						if (i != null)
						{
							if (parameters[i] is Array)
								paramsToSend[i] = parameters[i];
							else
								paramsToSend[i] = parameters[i].toString();
						}
					}
				}
			} 
			catch(error:Error) 
			{
				Trace.myTrace("HttpServer.as", "Error creating parameters! Error: " + error.message);
				
				paramsToSend = new URLVariables();
			}
			
			return paramsToSend;
		}

		public function get serverSocket():ServerSocket
		{
			return _serverSocket;
		}

		public static function get instance():HttpServer
		{
			return _instance;
		}
    }
}