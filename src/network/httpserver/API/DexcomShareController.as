package network.httpserver.API
{
	import flash.net.URLVariables;
	
	import database.BgReading;
	import database.BlueToothDevice;
	
	import network.httpserver.ActionController;
	
	import utils.SpikeJSON;
	import utils.Trace;
	
	public class DexcomShareController extends ActionController
	{
		/* Constants */
		private static const TIME_5_SECONDS:int = 5000;
		private static const SESSION_ID:String = "\"d89443d2-327c-4a6f-89e5-496bbb0317db\"";
		
		/* Variables */
		public var accountName:String;
		public var password:String;
		
		public function DexcomShareController(path:String)
		{
			super(path);
		}
		
		/**
		 * Functionality
		 */
		public function LoginPublisherAccountByName(params:URLVariables):String
		{
			Trace.myTrace("DexcomShareController.as", "LoginPublisherAccountByName called!");
			
			try
			{
				if (String(params.accountName) != accountName)
				{
					Trace.myTrace("LoopServiceController.as", "Invalid account name.");
					return responseSuccess(getBadAccountResponse(params.accountName));
				}
				else if (String(params.password) != password)
				{
					Trace.myTrace("LoopServiceController.as", "Invalid password.");
					return responseSuccess(getBadPasswordResponse(params.password));
				}
			} 
			catch(error:Error) 
			{
				Trace.myTrace("DexcomShareController.as", "Error trying to validate credentials. Error: " + error.message);
				
				return responseSuccess(SESSION_ID);
			}
			
			Trace.myTrace("DexcomShareController.as", "Authentication successful!");
			
			return responseSuccess(SESSION_ID);
		}
		
		public function ReadPublisherLatestGlucoseValues(params:URLVariables):String
		{
			Trace.myTrace("DexcomShareController.as", "ReadPublisherLatestGlucoseValues called!");
			
			var response:String;
			
			try
			{
				var numReadings:int = 1;
				if (params.maxCount != null)	
					numReadings = int(params.maxCount);
				
				var dexcomReadingsList:Array = BgReading.latest(numReadings, BlueToothDevice.isFollower());
				var dexcomReadingsCollection:Array = [];
				
				for (var i:int = 0; i < dexcomReadingsList.length; i++) 
				{
					var bgReading:BgReading = dexcomReadingsList[i] as BgReading;
					if (bgReading == null || bgReading.calculatedValue == 0)
						continue;
					
					dexcomReadingsCollection.push(createGlucoseReading(bgReading));
				}
				
				//response = JSON.stringify(dexcomReadingsCollection);
				response = SpikeJSON.stringify(dexcomReadingsCollection);
				response = response.replace(/\\\\/gi, "\\");
				
				dexcomReadingsList = null;
				dexcomReadingsCollection = null;
				params = null;
				
				Trace.myTrace("DexcomShareController.as", "Returning glucose values for " + numReadings + " reading(s).");
			} 
			catch(error:Error) 
			{
				Trace.myTrace("DexcomShareController.as", "Error processing response. Returning and empty array. Error: " + error.message);
				
				response = "[]";
			}
			
			return responseSuccess(response);
		}
		
		/**
		 * Utility
		 */
		private static function getBadAccountResponse(accountName:String):String
		{
			var now:Date = new Date();
			var nowFormatted:String = now.fullYear + "-" + (now.month + 1) + "-" + now.date + " " + now.hours + ":" + now.minutes + ":" + now.seconds;
			
			var response:Object = new Object();
			response.Code = "SSO_AuthenticateAccountNotFound";
			response.Message = "Create SSO account during login failed. AccountName=" + accountName;
			response.SubCode = "<OnlineException DateThrownLocal=\\\"" + nowFormatted + "\\\" DateThrown=\\\"" + nowFormatted + "\\\" ErrorCode=\\\"SSO_AuthenticateAccountNotFound\\\" Type=\\\"15\\\" Category=\\\"1\\\" Severity=\\\"2\\\" TypeString=\\\"SingleSignOn\\\" CategoryString=\\\"System\\\" SeverityString=\\\"Severe\\\" HostName=\\\"\\\" HostIP=\\\"\\\" Id=\\\"{B8B89DCA-CC07-4BC0-BBFB-39E4614AA1A5}\\\" Message=\\\"Create SSO account during login failed. AccountName=" + accountName + "\\\" FullText=\\\"Dexcom.Common.OnlineException: Create SSO account during login failed. AccountName=" + accountName + "\\\" \\/>";
			response.TypeName = "FaultException";
			
			//var responseJSON:String = JSON.stringify(response);
			var responseJSON:String = SpikeJSON.stringify(response);
			responseJSON = responseJSON.replace(/\\\\\\/gi, "\\");
			responseJSON = responseJSON.replace(/\\\\/gi, "\\");
			
			return responseJSON;
		}
		
		private static function getBadPasswordResponse(password:String):String
		{
			var now:Date = new Date();
			var nowFormatted:String = now.fullYear + "-" + (now.month + 1) + "-" + now.date + " " + now.hours + ":" + now.minutes + ":" + now.seconds;
			
			var response:Object = new Object();
			response.Code = "SSO_AuthenticatePasswordInvalid";
			response.Message = "Replay of bad password to SSO account gave invalid password error. AccountId=d98ee1af-bb4b-4777-8025-39d7379944aa";
			response.SubCode = "<OnlineException DateThrownLocal=\\\"" + nowFormatted + "\\\" DateThrown=\\\"" + nowFormatted + "\\\" ErrorCode=\\\"SSO_AuthenticatePasswordInvalid\\\" Type=\\\"15\\\" Category=\\\"1\\\" Severity=\\\"2\\\" TypeString=\\\"SingleSignOn\\\" CategoryString=\\\"System\\\" SeverityString=\\\"Severe\\\" HostName=\\\"\\\" HostIP=\\\"\\\" Id=\\\"{5ACCCF0F-8789-4CAF-9B87-39E46149B61B}\\\" Message=\\\"Replay of bad password to SSO account gave invalid password error. AccountId=d98ee1af-bb4b-4777-8025-39d7379944aa\\\" FullText=\\\"Dexcom.Common.OnlineException: Replay of bad password to SSO account gave invalid password error. AccountId=d98ee1af-bb4b-4777-8025-39d7379944aa\\\" \\/>";
			response.TypeName = "FaultException";
			
			//var responseJSON:String = JSON.stringify(response);
			var responseJSON:String = SpikeJSON.stringify(response);
			responseJSON = responseJSON.replace(/\\\\\\/gi, "\\");
			responseJSON = responseJSON.replace(/\\\\/gi, "\\");
			
			return responseJSON;
		}
		
		private static function createGlucoseReading(glucoseReading:BgReading):Object
		{
			var newReading:Object = new Object();
			newReading.DT = toDateString(glucoseReading.timestamp);
			newReading.ST = newReading.DT;
			newReading.Trend = glucoseReading.getSlopeOrdinal();
			newReading.Value = Math.round(glucoseReading.calculatedValue);
			newReading.WT = toDateString(glucoseReading.timestamp - TIME_5_SECONDS);
			
			return newReading;
		}
		
		private static function toDateString(timestamp:Number):String 
		{
			var shortened:Number = Math.floor(timestamp/1000);
			
			return "\\/Date(" + (Number(shortened * 1000)).toString() + ")\\/";
		}
	}
}