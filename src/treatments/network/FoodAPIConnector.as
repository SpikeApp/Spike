package treatments.network
{
	import com.hurlant.crypto.Crypto;
	import com.hurlant.crypto.hash.HMAC;
	import com.hurlant.util.Base64;
	import com.hurlant.util.Hex;
	
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.utils.ByteArray;
	
	import mx.utils.ObjectUtil;

	public class FoodAPIConnector
	{
		//MODES
		private static const FATSECRET_MODE:String = "fatSecret";
		private static const OPENFOODFACTS_MODE:String = "openFoodFacts";
		private static const USDA_SEARCH_MODE:String = "usdaSearch";
		private static const USDA_REPORT_MODE:String = "usdaReport";
		
		//FATSECRET
		private static const FATSECRET_CONSUMER_KEY:String = "54294f24da104eda9f94489aaba00132";
		private static const FATSECRET_SHARED_SECRET:String = "3cc1aaa47a534666b6132d43313e4e72";
		private static const FATSECRET_API_URL:String = "http://platform.fatsecret.com/rest/server.api";
		
		//OPENFOODFACTS
		private static const OPENFOODFACTS_API_URL:String = "https://world.openfoodfacts.org/cgi/search.pl?";
		
		//USDA
		private static const USDA_SEARCH_API_URL:String = "https://api.nal.usda.gov/ndb/search/?";
		private static const USDA_REPORT_API_URL:String = "https://api.nal.usda.gov/ndb/reports/?";
		private static const USDA_API_KEY:String = "llUnuttV7sRdAGI8oXLR6r2ijTsKHBuUeMdpAFw2";
		
		//Properties
		private static var currentMode:String = "";
		
		public function FoodAPIConnector()
		{
			throw new Error("FoodAPIConnector is not meant to be instantiated!");
		}
		
		public static function fatSecretSearchFood(food:String)
		{
			currentMode = FATSECRET_MODE;
			
			var nonce:Number = Math.round(Math.random() * 1000000);
			var timestamp:Number = new Date().valueOf();
			
			var queryParameters:Object = new Object();
			queryParameters.method = "foods.search";
			queryParameters.oauth_consumer_key = FATSECRET_CONSUMER_KEY;
			queryParameters.oauth_nonce = nonce;
			queryParameters.oauth_signature_method = "HMAC-SHA1";
			queryParameters.oauth_timestamp = timestamp;
			queryParameters.oauth_version = "1.0";
			queryParameters.format = "json";
			queryParameters.max_results = 50;
			queryParameters.search_expression = food;
			
			var params:String = sortRequestParamsFatSecret(queryParameters);
			var signatureBase:String = "POST" + "&" + encodeURIComponent(FATSECRET_API_URL) + "&" + encodeURIComponent(params);
			var encryptedString:String = hashHMAC(FATSECRET_SHARED_SECRET + "&", signatureBase);
			
			var noChacheHeader:URLRequestHeader = new URLRequestHeader("pragma", "no-cache");
			var request:URLRequest = new URLRequest(FATSECRET_API_URL + "?" + params + "&" + "oauth_signature=" + encryptedString);
			request.method = URLRequestMethod.POST;
			request.requestHeaders.push(noChacheHeader);
			
			var urlLoader:URLLoader = new URLLoader();
			urlLoader.dataFormat = URLLoaderDataFormat.TEXT;
			urlLoader.addEventListener(Event.COMPLETE, localCompleteHandler, false, 0, true);
			urlLoader.load(request);
		}
		
		private static function openFoodFactsSearchFood(food:String):void
		{
			currentMode = OPENFOODFACTS_MODE;
			
			var parameters:URLVariables = new URLVariables();
			parameters.search_terms = food;
			parameters.search_simple = 1;
			parameters.action = "process";
			parameters.json = 1;
			
			var callURL:String = OPENFOODFACTS_API_URL + parameters.toString();
			
			var request:URLRequest = new URLRequest(callURL);
			request.method = URLRequestMethod.GET;
			
			var urlLoader:URLLoader = new URLLoader();
			urlLoader.addEventListener(Event.COMPLETE, localCompleteHandler, false, 0, true);
			urlLoader.load(request);
		}
		
		private static function usdaSearchFood(food:String):void
		{
			currentMode = USDA_SEARCH_MODE;
			
			var queryParameters:Object = new Object();
			queryParameters.format = "json";
			queryParameters.max = 50;
			queryParameters.offset = 0;
			queryParameters.sort = "r";
			queryParameters.api_key = USDA_API_KEY;
			queryParameters.q = food;
			
			var request:URLRequest = new URLRequest(USDA_SEARCH_API_URL + createUSDARequestParams(queryParameters));
			request.method = URLRequestMethod.POST;
			
			var urlLoader:URLLoader = new URLLoader();
			urlLoader.addEventListener(Event.COMPLETE, localCompleteHandler, false, 0, true);
			urlLoader.load(request);
		}
		
		private static function usdaGetFoodInfo(ndbNumber:Number):void
		{
			currentMode = USDA_REPORT_MODE;
			
			var queryParameters:Object = new Object();
			queryParameters.format = "json";
			queryParameters.ndbno = ndbNumber;
			queryParameters.type = "b";
			queryParameters.api_key = USDA_API_KEY;
			
			var request:URLRequest = new URLRequest(USDA_REPORT_API_URL + createUSDARequestParams(queryParameters));
			request.method = URLRequestMethod.POST;
			
			var urlLoader:URLLoader = new URLLoader();
			urlLoader.addEventListener(Event.COMPLETE, localCompleteHandler, false, 0, true);
			urlLoader.load(request);
		}
		
		/**
		 * HELPER FUNCTIONS FOR FATSECRET
		 */
		
		/**
		 * Creates an HMAC compatible with OAUTH 1.0. The HMAC is encrypted using SHA1, encoded to BASE64 and finally URL escaped.
		 */
		private static function hashHMAC(concatedSecrets:String, stringToSign:String):String
		{
			var hmac:HMAC = Crypto.getHMAC("sha1");
			var key:ByteArray = Hex.toArray(Hex.fromString(concatedSecrets));
			var message:ByteArray = Hex.toArray(Hex.fromString(stringToSign));
			var result:ByteArray = hmac.compute(key, message);
			
			return encodeURIComponent(Base64.encodeByteArray(result));	
		}
		
		/**
		 * Encodes and sorts properties of an object alphabetically. Required for OAUTH 1.0 queries.
		 */
		private static function sortRequestParamsFatSecret(requestParams:Object):String 
		{
			var params:Array = new Array();
			
			for (var requestParam:String in requestParams) 
			{
				var key:String = requestParam;
				var value:String = requestParams[requestParam].toString();
				if (key == "search_expression" || value.indexOf(" ") != -1)
					value = encodeURIComponent(value);
				
				params.push(key + "=" + value);
			}
			
			params.sort();
			return params.join("&");
		}
		
		/**
		 * Formats parameters for USDA API requests
		 */
		private static function createUSDARequestParams(requestParams:Object):String 
		{
			var params:Array = new Array();
			
			for (var requestParam:String in requestParams) 
			{
				var key:String = requestParam;
				var value:String = requestParams[requestParam].toString();
				
				if (key == "q") value = encodeURIComponent(value);
				
				params.push(key + "=" + value);
			}
			
			return params.join("&");
		}
		
		/**
		 * Converts Kj to Kcal
		 */
		private static function convertKjToKcal(value:Number):Number
		{
			return Math.round(value * 0.2390057361);
		}
		
		/**
		 * EVENT HANDLERS
		 */
		private static function localCompleteHandler(e:Event):void
		{
			var loader:URLLoader = e.currentTarget as URLLoader;
			var response:String = String(loader.data);
			
			//Discard loader
			loader.removeEventListener(Event.COMPLETE, localCompleteHandler);
			loader = null;
			
			//Process responde
			if (currentMode == FATSECRET_MODE)
			{
				try
				{
					var foodsJSON:Object = JSON.parse(response);
					trace(ObjectUtil.toString(foodsJSON));
				} 
				catch(error:Error) 
				{
					trace("Error parsing FatSecret's response!");
				}
			}
			else if (currentMode == OPENFOODFACTS_MODE)
			{
				try
				{
					var processedResponse:Object = JSON.parse(response);
					var products:Array = processedResponse.products != null && processedResponse.products is Array ? processedResponse.products : [];
					
					for (var i:int = 0; i < products.length; i++) 
					{
						var productName:String = String(products[i].product_name != null ? products[i].product_name : "");
						trace("productName", productName);
						var productGenericName:String = String(products[i].generic_name != null ? products[i].generic_name : "");
						trace("productGenericName", productGenericName);
						var productBrand:String = String(products[i].brands != null ? products[i].brands : "");
						trace("productBrand", productBrand);
						var productCategories:String = String(products[i].categories != null ? products[i].categories : "");
						trace("productCategories", productCategories);
						var productCountries:String = String(products[i].countries != null ? products[i].countries : "");
						trace("productCountries", productCountries);
						var productIngredients:String = String(products[i].ingredients_text != null ? products[i].ingredients_text : "");
						trace("productIngredients", productIngredients);
						var productLink:String = String(products[i].link != null ? products[i].link : "");
						trace("productLink", productLink);
						var productCalories:String = String(products[i].nutriments.energy_value != null ? products[i].nutriments.energy_value : "");
						if (productCalories != "" && products[i].nutriments.energy_unit != null && String(products[i].nutriments.energy_unit).toUpperCase() == "KJ")
							productCalories = String(convertKjToKcal(Number(productCalories)));
						trace("productCalories", productCalories);
						var productProteins:String = String(products[i].nutriments.proteins_100g != null ? products[i].nutriments.proteins_100g : "");
						trace("productProteins", productProteins);
						var productCarbs:String = String(products[i].nutriments.carbohydrates_100g != null ? products[i].nutriments.carbohydrates_100g : "");
						trace("productCarbs", productCarbs);
						var productFats:String = String(products[i].nutriments.fat_100g != null ? products[i].nutriments.fat_100g : "");
						trace("productFats", productFats);
						
						trace("------------------------------------------------------------------------------------");
					}
					
					
					//trace(ObjectUtil.toString(processedResponse));
				} 
				catch(error:Error) 
				{
					trace("Error parsing OpenFoodFacts's response!");
				}
			}
			else if (currentMode == USDA_SEARCH_MODE)
			{
				trace(response);
			}
			
			//Reset mode
			currentMode = "";
		}
	}
}