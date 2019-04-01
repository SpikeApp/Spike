package treatments.food.connectors
{
	import com.distriqt.extension.networkinfo.NetworkInfo;
	import com.hurlant.crypto.Crypto;
	import com.hurlant.crypto.hash.HMAC;
	import com.hurlant.util.Base64;
	import com.hurlant.util.Hex;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.utils.ByteArray;
	
	import mx.utils.StringUtil;
	
	import database.Database;
	
	import events.FoodEvent;
	
	import model.ModelLocator;
	
	import treatments.food.Food;
	import treatments.food.Recipe;
	
	import utils.SpikeJSON;
	import utils.UniqueId;
	
	[ResourceBundle("foodmanager")]
	
	public class FoodAPIConnector extends EventDispatcher
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
		private static const OPENFOODFACTS_SEARCH_API_URL:String = "https://world.openfoodfacts.org/cgi/search.pl?";
		private static const OPENFOODFACTS_CODE_API_URL:String = "https://world.openfoodfacts.org/code/{barcode}.json";
		
		//USDA
		private static const USDA_SEARCH_API_URL:String = "https://api.nal.usda.gov/ndb/search/?";
		private static const USDA_REPORT_API_URL:String = "https://api.nal.usda.gov/ndb/reports/?";
		private static const USDA_API_KEY:String = "llUnuttV7sRdAGI8oXLR6r2ijTsKHBuUeMdpAFw2";
		
		//Properties
		private static var _instance:FoodAPIConnector = new FoodAPIConnector();
		private static var currentMode:String = "";
		private static var foodDetailMode:Boolean = false;
		private static var currentUSDAPage:int = 1;
		private static var fatSecretBarCode:String = "";
		private static var openFoodFactsBarCode:String = "";
		
		public function FoodAPIConnector()
		{
			if (_instance != null)
				throw new Error("FoodAPIConnector is not meant to be instantiated!");
		}
		
		public static function fatSecretSearchFood(food:String, page:int):void
		{
			if (!NetworkInfo.networkInfo.isReachable())
			{
				_instance.dispatchEvent( new FoodEvent(FoodEvent.FOOD_SERVER_ERROR, false, false, null, null, null, null, ModelLocator.resourceManagerInstance.getString('foodmanager','no_internet_connection')) );
				return;
			}
			
			currentMode = FATSECRET_MODE;
			foodDetailMode = false;
			
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
			queryParameters.page_number = page - 1;
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
			urlLoader.addEventListener(Event.COMPLETE, onAPIResult, false, 0, true);
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onAPIError, false, 0, true);
			urlLoader.load(request);
		}
		
		public static function fatSecretSearchCode(barCode:String):void
		{
			if (!NetworkInfo.networkInfo.isReachable())
			{
				_instance.dispatchEvent( new FoodEvent(FoodEvent.FOOD_SERVER_ERROR, false, false, null, null, null, null, ModelLocator.resourceManagerInstance.getString('foodmanager','no_internet_connection')) );
				return;
			}
			
			currentMode = FATSECRET_MODE;
			foodDetailMode = false;
			fatSecretBarCode = barCode;
			
			var nonce:Number = Math.round(Math.random() * 1000000);
			var timestamp:Number = new Date().valueOf();
			
			var queryParameters:Object = new Object();
			queryParameters.method = "food.find_id_for_barcode";
			queryParameters.oauth_consumer_key = FATSECRET_CONSUMER_KEY;
			queryParameters.oauth_nonce = nonce;
			queryParameters.oauth_signature_method = "HMAC-SHA1";
			queryParameters.oauth_timestamp = timestamp;
			queryParameters.oauth_version = "1.0";
			queryParameters.format = "json";
			queryParameters.max_results = 50;
			queryParameters.barcode = barCode;
			
			var params:String = sortRequestParamsFatSecret(queryParameters);
			var signatureBase:String = "POST" + "&" + encodeURIComponent(FATSECRET_API_URL) + "&" + encodeURIComponent(params);
			var encryptedString:String = hashHMAC(FATSECRET_SHARED_SECRET + "&", signatureBase);
			
			var noChacheHeader:URLRequestHeader = new URLRequestHeader("pragma", "no-cache");
			var request:URLRequest = new URLRequest(FATSECRET_API_URL + "?" + params + "&" + "oauth_signature=" + encryptedString);
			request.method = URLRequestMethod.POST;
			request.requestHeaders.push(noChacheHeader);
			
			var urlLoader:URLLoader = new URLLoader();
			urlLoader.dataFormat = URLLoaderDataFormat.TEXT;
			urlLoader.addEventListener(Event.COMPLETE, onFatSecretCodeResult, false, 0, true);
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onAPIError, false, 0, true);
			urlLoader.load(request);
		}
		
		public static function fatSecretGetFoodDetails(foodID:String, detailMode:Boolean = true):void
		{
			if (!NetworkInfo.networkInfo.isReachable())
			{
				_instance.dispatchEvent( new FoodEvent(FoodEvent.FOOD_SERVER_ERROR, false, false, null, null, null, null, ModelLocator.resourceManagerInstance.getString('foodmanager','no_internet_connection')) );
				return;
			}
			
			currentMode = FATSECRET_MODE;
			foodDetailMode = detailMode;
			
			var nonce:Number = Math.round(Math.random() * 1000000);
			var timestamp:Number = new Date().valueOf();
			
			var queryParameters:Object = new Object();
			queryParameters.method = "food.get";
			queryParameters.oauth_consumer_key = FATSECRET_CONSUMER_KEY;
			queryParameters.oauth_nonce = nonce;
			queryParameters.oauth_signature_method = "HMAC-SHA1";
			queryParameters.oauth_timestamp = timestamp;
			queryParameters.oauth_version = "1.0";
			queryParameters.format = "json";
			queryParameters.max_results = 50;
			queryParameters.food_id = foodID;
			
			var params:String = sortRequestParamsFatSecret(queryParameters);
			var signatureBase:String = "POST" + "&" + encodeURIComponent(FATSECRET_API_URL) + "&" + encodeURIComponent(params);
			var encryptedString:String = hashHMAC(FATSECRET_SHARED_SECRET + "&", signatureBase);
			
			var noChacheHeader:URLRequestHeader = new URLRequestHeader("pragma", "no-cache");
			var request:URLRequest = new URLRequest(FATSECRET_API_URL + "?" + params + "&" + "oauth_signature=" + encryptedString);
			request.method = URLRequestMethod.POST;
			request.requestHeaders.push(noChacheHeader);
			
			var urlLoader:URLLoader = new URLLoader();
			urlLoader.dataFormat = URLLoaderDataFormat.TEXT;
			urlLoader.addEventListener(Event.COMPLETE, onAPIResult, false, 0, true);
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onAPIError, false, 0, true);
			urlLoader.load(request);
		}
		
		public static function openFoodFactsSearchFood(food:String, page:int):void
		{
			if (!NetworkInfo.networkInfo.isReachable())
			{
				_instance.dispatchEvent( new FoodEvent(FoodEvent.FOOD_SERVER_ERROR, false, false, null, null, null, null, ModelLocator.resourceManagerInstance.getString('foodmanager','no_internet_connection')) );
				return;
			}
			
			currentMode = OPENFOODFACTS_MODE;
			foodDetailMode = false;
			
			var parameters:URLVariables = new URLVariables();
			parameters.search_terms = food;
			parameters.search_simple = 1;
			parameters.action = "process";
			parameters.page = page;
			parameters.page_size = 50;
			parameters.json = 1;
			
			var callURL:String = OPENFOODFACTS_SEARCH_API_URL + parameters.toString();
			
			var request:URLRequest = new URLRequest(callURL);
			request.method = URLRequestMethod.GET;
			
			var urlLoader:URLLoader = new URLLoader();
			urlLoader.addEventListener(Event.COMPLETE, onAPIResult, false, 0, true);
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onAPIError, false, 0, true);
			urlLoader.load(request);
		}
		
		public static function openFoodFactsSearchCode(barCode:String):void
		{
			if (!NetworkInfo.networkInfo.isReachable())
			{
				_instance.dispatchEvent( new FoodEvent(FoodEvent.FOOD_SERVER_ERROR, false, false, null, null, null, null, ModelLocator.resourceManagerInstance.getString('foodmanager','no_internet_connection')) );
				return;
			}
			
			currentMode = OPENFOODFACTS_MODE;
			foodDetailMode = false;
			openFoodFactsBarCode = barCode;
			
			var request:URLRequest = new URLRequest(OPENFOODFACTS_CODE_API_URL.replace("{barcode}", barCode));
			request.method = URLRequestMethod.GET;
			
			var urlLoader:URLLoader = new URLLoader();
			urlLoader.addEventListener(Event.COMPLETE, onAPIResult, false, 0, true);
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onAPIError, false, 0, true);
			urlLoader.load(request);
		}
		
		public static function usdaSearchFood(food:String, page:int):void
		{
			if (!NetworkInfo.networkInfo.isReachable())
			{
				_instance.dispatchEvent( new FoodEvent(FoodEvent.FOOD_SERVER_ERROR, false, false, null, null, null, null, ModelLocator.resourceManagerInstance.getString('foodmanager','no_internet_connection')) );
				return;
			}
			
			currentMode = USDA_SEARCH_MODE;
			foodDetailMode = false;
			currentUSDAPage = page;
			
			var queryParameters:Object = new Object();
			queryParameters.format = "json";
			queryParameters.max = 50;
			queryParameters.offset = (page - 1) * 50;
			queryParameters.sort = "r";
			queryParameters.api_key = USDA_API_KEY;
			queryParameters.q = food;
			
			var request:URLRequest = new URLRequest(USDA_SEARCH_API_URL + createUSDARequestParams(queryParameters));
			request.method = URLRequestMethod.POST;
			
			var urlLoader:URLLoader = new URLLoader();
			urlLoader.addEventListener(Event.COMPLETE, onAPIResult, false, 0, true);
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onAPIError, false, 0, true);
			urlLoader.load(request);
		}
		
		public static function usdaGetFoodInfo(ndbNumber:String):void
		{
			if (!NetworkInfo.networkInfo.isReachable())
			{
				_instance.dispatchEvent( new FoodEvent(FoodEvent.FOOD_SERVER_ERROR, false, false, null, null, null, null, ModelLocator.resourceManagerInstance.getString('foodmanager','no_internet_connection')) );
				return;
			}
			
			currentMode = USDA_REPORT_MODE;
			foodDetailMode = true;
			
			var queryParameters:Object = new Object();
			queryParameters.format = "json";
			queryParameters.ndbno = ndbNumber;
			queryParameters.type = "b";
			queryParameters.api_key = USDA_API_KEY;
			
			var request:URLRequest = new URLRequest(USDA_REPORT_API_URL + createUSDARequestParams(queryParameters));
			request.method = URLRequestMethod.POST;
			
			var urlLoader:URLLoader = new URLLoader();
			urlLoader.addEventListener(Event.COMPLETE, onAPIResult, false, 0, true);
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onAPIError, false, 0, true);
			urlLoader.load(request);
		}
		
		public static function favoritesSearchFood(food:String, page:int):void
		{
			var data:Array = [];
			var favoritesDBResult:Object = Database.getFavoriteFoodSynchronous(food ,page);
			
			if (favoritesDBResult != null && favoritesDBResult.foodsList != null && favoritesDBResult.foodsList is Array && favoritesDBResult.totalRecords != null)
			{
				var allFavoritesProperties:Object = { pageNumber: page, totalPages: Math.ceil(favoritesDBResult.totalRecords / 50), totalRecords: favoritesDBResult.totalRecords }
				var foods:Array = favoritesDBResult.foodsList;
				
				for (var i:int = 0; i < foods.length; i++) 
				{
					var unprocessedFavorite:Object = foods[i];
					if (unprocessedFavorite != null)
					{
						var favoriteID:String = unprocessedFavorite.id;
						var favoriteName:String = unprocessedFavorite.name;
						var favoriteBrand:String = unprocessedFavorite.brand;
						var favoriteProteins:Number = Number(unprocessedFavorite.proteins);
						var favoriteCarbs:Number = Number(unprocessedFavorite.carbs);
						var favoriteFiber:Number = Number(unprocessedFavorite.fiber);
						var favoriteFats:Number = Number(unprocessedFavorite.fats);
						var favoriteCalories:Number = Number(unprocessedFavorite.calories);
						var favoriteLink:String = unprocessedFavorite.link;
						var favoriteServingSize:Number = Number(unprocessedFavorite.servingsize);
						var favoriteServingUnit:String = unprocessedFavorite.servingunit;
						var favoriteBarCode:String = unprocessedFavorite.barcode;
						var favoriteSource:String = unprocessedFavorite.source;
						var favoriteTimestamp:Number = Number(unprocessedFavorite.lastmodifiedtimestamp);
						var favoriteNote:String = unprocessedFavorite.notes;
						
						var favoriteFood:Food = new Food
						(
							favoriteID,
							favoriteName,
							favoriteProteins,
							favoriteCarbs,
							favoriteFats,
							favoriteCalories,
							favoriteServingSize,
							favoriteServingUnit,
							favoriteTimestamp,
							favoriteFiber,
							favoriteBrand,
							favoriteLink,
							favoriteSource,
							favoriteBarCode,
							false,
							0,
							"",
							favoriteNote
						);
						
						data.push
						(
							{
								label: favoriteName + (favoriteBrand != "" ? "\n" + favoriteBrand.toUpperCase() : ""),
								food: favoriteFood
							}
						);
					}
				}
				
				//Notify Listeners
				if (data.length > 0)
				{
					_instance.dispatchEvent
					(
						new FoodEvent
						(
							FoodEvent.FOODS_SEARCH_RESULT,
							false,
							false,
							null,
							data,
							null,
							null,
							null,
							allFavoritesProperties
						)
					);
				}
				else
					_instance.dispatchEvent( new FoodEvent(FoodEvent.FOOD_NOT_FOUND) );
			}
			else
				_instance.dispatchEvent( new FoodEvent(FoodEvent.FOOD_NOT_FOUND) );
		}
		
		public static function favoritesSearchBarCode(barcode:String):void
		{
			var data:Array = [];
			var favoritesDBResult:Array = Database.getFavoriteFoodByBarcodeSynchronous(barcode);
			
			if (favoritesDBResult != null && favoritesDBResult.length > 0)
			{
				for (var i:int = 0; i < favoritesDBResult.length; i++) 
				{
					var unprocessedFavorite:Object = favoritesDBResult[i];
					if (unprocessedFavorite != null)
					{
						var favoriteID:String = unprocessedFavorite.id;
						var favoriteName:String = unprocessedFavorite.name;
						var favoriteBrand:String = unprocessedFavorite.brand;
						var favoriteProteins:Number = Number(unprocessedFavorite.proteins);
						var favoriteCarbs:Number = Number(unprocessedFavorite.carbs);
						var favoriteFiber:Number = Number(unprocessedFavorite.fiber);
						var favoriteFats:Number = Number(unprocessedFavorite.fats);
						var favoriteCalories:Number = Number(unprocessedFavorite.calories);
						var favoriteLink:String = unprocessedFavorite.link;
						var favoriteServingSize:Number = Number(unprocessedFavorite.servingsize);
						var favoriteServingUnit:String = unprocessedFavorite.servingunit;
						var favoriteBarCode:String = unprocessedFavorite.barcode;
						var favoriteSource:String = unprocessedFavorite.source;
						var favoriteTimestamp:Number = Number(unprocessedFavorite.lastmodifiedtimestamp);
						var favoriteNotes:String = unprocessedFavorite.notes;
						
						var favoriteFood:Food = new Food
						(
							favoriteID,
							favoriteName,
							favoriteProteins,
							favoriteCarbs,
							favoriteFats,
							favoriteCalories,
							favoriteServingSize,
							favoriteServingUnit,
							favoriteTimestamp,
							favoriteFiber,
							favoriteBrand,
							favoriteLink,
							favoriteSource,
							favoriteBarCode,
							false,
							0,
							"",
							favoriteNotes
						);
						
						data.push
						(
							{
								label: favoriteName + (favoriteBrand != "" ? "\n" + favoriteBrand.toUpperCase() : ""),
								food: favoriteFood
							}
						);
					}
				}
				
				//Notify Listeners
				if (data.length > 0)
				{
					_instance.dispatchEvent
					(
						new FoodEvent
						(
							FoodEvent.FOODS_SEARCH_RESULT,
							false,
							false,
							null,
							data,
							null,
							null,
							null,
							{ pageNumber: 1, totalPages: 1, totalRecords: data.length }
						)
					);
				}
				else
					_instance.dispatchEvent( new FoodEvent(FoodEvent.FOOD_NOT_FOUND) );
			}
			else
				_instance.dispatchEvent( new FoodEvent(FoodEvent.FOOD_NOT_FOUND) );
		}
		
		public static function recipesSearch(recipe:String, page:int):void
		{
			var data:Array = [];
			var recipessDBResult:Object = Database.getRecipesSynchronous(recipe, page);
			
			if (recipessDBResult != null && recipessDBResult.recipesList != null && recipessDBResult.recipesList is Array && recipessDBResult.totalRecords != null)
			{
				var allRecipesProperties:Object = { pageNumber: page, totalPages: Math.ceil(recipessDBResult.totalRecords / 50), totalRecords: recipessDBResult.totalRecords }
				var recipes:Array = recipessDBResult.recipesList;
				
				for (var i:int = 0; i < recipes.length; i++) 
				{
					var recipeObject:Recipe = recipes[i];
					
					data.push
					(
						{
							label: recipeObject.name + (recipeObject.notes != "" ? "\n" + recipeObject.notes : ""),
							recipe: recipeObject
						}
					);
				}
				
				//Notify Listeners
				if (data.length > 0)
				{
					_instance.dispatchEvent
						(
							new FoodEvent
							(
								FoodEvent.RECIPES_SEARCH_RESULT,
								false,
								false,
								null,
								null,
								null,
								data,
								null,
								allRecipesProperties
							)
						);
				}
				else
					_instance.dispatchEvent( new FoodEvent(FoodEvent.RECIPE_NOT_FOUND) );
			}
			else
				_instance.dispatchEvent( new FoodEvent(FoodEvent.RECIPE_NOT_FOUND) );
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
		 * Capitalizes first word except if the word is less than 3 characters to avoid capitalizing "g" and "ml"
		 */
		private static function firstLetterUpperCase(strData:String):String 
		{
			strData = strData.toLowerCase();
			var strArray:Array = strData.split(' ');
			var newArray:Array = [];
			for (var str:String in strArray) 
			{
				if ((strArray[str] as String).length > 2)
				{
					if (strArray[str].charAt(0) != "(")
						newArray.push(strArray[str].charAt(0).toUpperCase() + strArray[str].slice(1));
					else
						newArray.push(strArray[str].charAt(0) + strArray[str].charAt(1).toUpperCase() + strArray[str].slice(2));
				}
				else
					newArray.push(strArray[str]);
			}
			return newArray.join(' ');
		}
		
		/**
		 * Parses FatSecret foods
		 */
		public static function parseFatSecretFood(unprocessedFood:Object):Object
		{
			var food:Object = null;
			var description:String = unprocessedFood.food_description as String;
			
			if (description != null)
			{
				//Serving Size and Unit
				var servingSizeMarker:String = "Per ";
				var servingSizeFirstIndex:int = description.indexOf(servingSizeMarker) + servingSizeMarker.length;
				var servingSizeSecondIndex:int = description.indexOf(" - Calories");
				var servingSizeFinalSecondIndex:int = servingSizeSecondIndex;
				while (isNaN(Number(description.slice(servingSizeFirstIndex, servingSizeFinalSecondIndex))))
				{
					servingSizeFinalSecondIndex -= 1;
				}
				var servingSize:Number = Number(description.slice(servingSizeFirstIndex, servingSizeFinalSecondIndex));
				var servingUnit:String = StringUtil.trim(description.slice(servingSizeFinalSecondIndex, servingSizeSecondIndex));
				
				//Calories
				var caloriesMarker:String = "Calories: ";
				var caloriesFirstIndex:int = description.indexOf(caloriesMarker) + caloriesMarker.length;
				var caloriesSecondIndex:int = description.indexOf(" | Fat");
				var caloriesFinalSecondIndex:int = caloriesSecondIndex;
				while (isNaN(Number(description.slice(caloriesFirstIndex, caloriesFinalSecondIndex))))
				{
					caloriesFinalSecondIndex -= 1;
				}
				var caloriesAmount:Number = Number(description.slice(caloriesFirstIndex, caloriesFinalSecondIndex));
				var caloriesUnit:String = StringUtil.trim(description.slice(caloriesFinalSecondIndex, caloriesSecondIndex));
				if (caloriesUnit.toLowerCase() != "kcal") caloriesAmount = convertKjToKcal(caloriesAmount);
				
				//Fats
				var fatsMarker:String = "Fat: ";
				var fatsFirstIndex:int = description.indexOf(fatsMarker) + fatsMarker.length;
				var fatsSecondIndex:int = description.indexOf(" | Carbs");
				var fatsFinalSecondIndex:int = fatsSecondIndex;
				while (isNaN(Number(description.slice(fatsFirstIndex, fatsFinalSecondIndex))))
				{
					fatsFinalSecondIndex -= 1;
				}
				var fatsAmount:Number = Number(description.slice(fatsFirstIndex, fatsFinalSecondIndex));
				
				//Carbs
				var carbsMarker:String = "Carbs: ";
				var carbsFirstIndex:int = description.indexOf(carbsMarker) + carbsMarker.length;
				var carbsSecondIndex:int = description.indexOf(" | Protein");
				var carbsFinalSecondIndex:int = carbsSecondIndex;
				while (isNaN(Number(description.slice(carbsFirstIndex, carbsFinalSecondIndex))))
				{
					carbsFinalSecondIndex -= 1;
				}
				var carbsAmount:Number = Number(description.slice(carbsFirstIndex, carbsFinalSecondIndex));
				
				//Proteins
				var proteinsMarker:String = "Protein: ";
				var proteinsFirstIndex:int = description.indexOf(proteinsMarker) + proteinsMarker.length;
				var proteinsSecondIndex:int = description.length - 1;
				var proteinsFinalSecondIndex:int = proteinsSecondIndex;
				while (isNaN(Number(description.slice(proteinsFirstIndex, proteinsFinalSecondIndex))))
				{
					proteinsFinalSecondIndex -= 1;
				}
				var proteinsAmount:Number = Number(description.slice(proteinsFirstIndex, proteinsFinalSecondIndex));
				
				food = 
					{
						proteins: proteinsAmount,
						carbs: carbsAmount,
						fats: fatsAmount,
						calories: caloriesAmount,
						servingSize: servingSize,
						servingUnit: servingUnit
					}
			}
			
			return food;
		}
		
		/**
		 * EVENT HANDLERS
		 */
		private static function onAPIResult(e:flash.events.Event):void
		{
			var loader:URLLoader = e.currentTarget as URLLoader;
			var response:String = String(loader.data);
			
			//Discard loader
			loader.removeEventListener(flash.events.Event.COMPLETE, onAPIResult);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onAPIError);
			loader = null;
			
			var data:Array = [];
			var foodsJSON:Object;
			var foodList:Array;
			var i:int = 0;
			var now:Number = new Date().valueOf();
			
			//Process responde
			if (currentMode == FATSECRET_MODE)
			{
				try
				{
					foodsJSON = JSON.parse(response);
					if (foodsJSON.food != null) //Single food
					{
						var selectedFSServing:Object;
						
						var noteFS:String = "";
						var notesListFS:Array = [];
						var carbsPer100FS:Number = Number.NaN;
						
						if (foodsJSON.food.servings.serving is Array)
						{
							var servingsList:Array = foodsJSON.food.servings.serving as Array;
							var selectedServingIndex:int = 0;
							
							for (i = 0; i < servingsList.length; i++) 
							{
								var servingDetails:Object = servingsList[i];
								if (servingDetails.measurement_description == "g" && Number(servingDetails.metric_serving_amount) == 100)
								{
									selectedServingIndex = i;
									
									if(servingDetails.carbohydrate != null && !isNaN(Number(servingDetails.carbohydrate)) && Number(servingDetails.carbohydrate) != 0)
									{
										carbsPer100FS = Number(servingDetails.carbohydrate);
									}
								}
								else
								{
									if (servingDetails.serving_description != null && servingDetails.serving_description != "" && servingDetails.carbohydrate != null && servingDetails.carbohydrate != "" && servingDetails.carbohydrate != "0")
									{
										var formattedFSServing:String = firstLetterUpperCase(servingDetails.serving_description);
										formattedFSServing = formattedFSServing.replace(" g", "g");
										formattedFSServing = formattedFSServing.replace(" ml", "ml");
										formattedFSServing = formattedFSServing.replace(" dl", "dl");
										formattedFSServing = formattedFSServing.replace(" cl", "cl");
										
										var extraFSServing:Object = {};
										extraFSServing.label = formattedFSServing;
										extraFSServing.multiplier = Number(servingDetails.carbohydrate);
										notesListFS.push(extraFSServing);
									}
								}
							}
							
							selectedFSServing = servingsList[selectedServingIndex];
						}
						else if (foodsJSON.food.servings.serving is Object)
						{
							selectedFSServing = foodsJSON.food.servings.serving;
						}
						
						if (!isNaN(carbsPer100FS) && notesListFS.length)
						{
							for (var i2:int = 0; i2 < notesListFS.length; i2++) 
							{
								var extraFSServingParsed:Object = notesListFS[i2]; 
								extraFSServingParsed.multiplier = extraFSServingParsed.multiplier / carbsPer100FS;
							}
							
							noteFS = JSON.stringify(notesListFS);
						}
						
						var servingUnitFS:String = String(selectedFSServing.measurement_description);
						var addedExtras:Boolean = false;
						if (selectedFSServing.serving_description != null && selectedFSServing.serving_description != "" && selectedFSServing.serving_description != "100 g")
						{
							servingUnitFS += " (" + selectedFSServing.serving_description;
							addedExtras = true;
						}
						
						if (selectedFSServing.metric_serving_amount != null && selectedFSServing.metric_serving_amount != "" && addedExtras)
						{
							servingUnitFS += " " + Number(selectedFSServing.metric_serving_amount);
						}
						
						if (selectedFSServing.metric_serving_unit != null && selectedFSServing.metric_serving_unit != "" && addedExtras)
						{
							servingUnitFS += " " + selectedFSServing.metric_serving_unit;
						}
						
						if (addedExtras)
						{
							servingUnitFS += ")";
						}
						
						if (servingUnitFS != "g" && !addedExtras)
						{
							servingUnitFS = servingUnitFS.toLowerCase();
							servingUnitFS = servingUnitFS.replace(/(^[a-z]|\s[a-z])/g, function():String{ return arguments[1].toUpperCase(); });
						}
						
						var singleFSFood:Food = new Food
							(
								String(foodsJSON.food.food_id),
								String(foodsJSON.food.food_name),
								Number(selectedFSServing.protein),
								Number(selectedFSServing.carbohydrate),
								Number(selectedFSServing.fat),
								Number(selectedFSServing.calories),
								Number(selectedFSServing.number_of_units),
								servingUnitFS,
								now,
								Number(selectedFSServing.fiber),
								foodsJSON.food.brand_name != null ? String(foodsJSON.food.brand_name).toUpperCase() : "",
								String(foodsJSON.food.food_url),
								"FatSecret",
								"",
								false,
								0,
								"",
								noteFS
							);
						
						if (!foodDetailMode)
						{
							data.push
								(
									{
										label: String(foodsJSON.food.food_name) + (foodsJSON.food.brand_name != null ? "\n" + String(foodsJSON.food.brand_name).toUpperCase() : ""),
										food: singleFSFood
									}
								);
							
							//Notify Listeners
							if (data.length > 0)
							{
								_instance.dispatchEvent
									(
										new FoodEvent
										(
											FoodEvent.FOODS_SEARCH_RESULT,
											false,
											false,
											null,
											data
										)
									);
							}
							else
								_instance.dispatchEvent( new FoodEvent(FoodEvent.FOOD_NOT_FOUND) );
						}
						else
							_instance.dispatchEvent( new FoodEvent(FoodEvent.FOOD_DETAILS_RESULT, false, false, singleFSFood) );
					}
					else if (foodsJSON.foods != null && foodsJSON.foods.food != null && foodsJSON.foods.food is Array)
					{
						var FSSearchProperties:Object = { pageNumber: Number(foodsJSON.foods.page_number) + 1, totalPages: Math.ceil(Number(foodsJSON.foods.total_results) / 50), totalRecords: Number(foodsJSON.foods.total_results) }
						
						foodList = foodsJSON.foods.food as Array;
						for (i = 0; i < foodList.length; i++) 
						{
							var unprocessedFSFood:Object = foodList[i];
							if (unprocessedFSFood != null)
							{
								var food:Food = new Food
									(
										unprocessedFSFood.food_id,
										unprocessedFSFood.food_name,
										Number.NaN,
										Number.NaN,
										Number.NaN,
										Number.NaN,
										Number.NaN,
										"",
										now,
										Number.NaN,
										unprocessedFSFood.brand_name != null ? String(unprocessedFSFood.brand_name).toUpperCase() : "",
										""
									);
								
								data.push
									(
										{
											label: unprocessedFSFood.food_name + (unprocessedFSFood.brand_name != null ? "\n" + String(unprocessedFSFood.brand_name).toUpperCase() : ""),
											food: food
										}
									);
							}
						}
						
						//Notify Listeners
						if (data.length > 0)
						{
							_instance.dispatchEvent
								(
									new FoodEvent
									(
										FoodEvent.FOODS_SEARCH_RESULT,
										false,
										false,
										null,
										data,
										null,
										null,
										null,
										FSSearchProperties
									)
								);
						}
						else
							_instance.dispatchEvent( new FoodEvent(FoodEvent.FOOD_NOT_FOUND) );
					}
					else
					{
						//Nothing found. Notify listeners
						_instance.dispatchEvent( new FoodEvent(FoodEvent.FOOD_NOT_FOUND) );
					}
				} 
				catch(error:Error) 
				{
					_instance.dispatchEvent( new FoodEvent(FoodEvent.FOOD_SERVER_ERROR, false, false, null, null, null, null, ModelLocator.resourceManagerInstance.getString('foodmanager','error_label') + ": " + error.message + "\n\n" + ModelLocator.resourceManagerInstance.getString('foodmanager','server_response_label') + ": " + response) );
				}
			}
			else if (currentMode == OPENFOODFACTS_MODE)
			{
				try
				{
					foodsJSON = JSON.parse(response);
					
					if (foodsJSON != null && foodsJSON.count != null && Number(foodsJSON.count) == 0)
					{
						_instance.dispatchEvent( new FoodEvent(FoodEvent.FOOD_NOT_FOUND) );
					}
					else if (foodsJSON != null && foodsJSON.products != null && foodsJSON.products is Array)
					{
						var OFFSearchProperties:Object = { pageNumber: Number(foodsJSON.page), totalPages: Math.ceil(Number(foodsJSON.count) / 50), totalRecords: Number(foodsJSON.count) }
						
						foodList = foodsJSON.products;
						for (i = 0; i < foodList.length; i++) 
						{
							var unprocessedOFFFood:Object = foodList[i];
							
							if (unprocessedOFFFood != null)
							{
								var offID:String = unprocessedOFFFood["_id"] != null ? String(unprocessedOFFFood["_id"]) : UniqueId.createEventId();
								var quotePattern:RegExp = /&quot;/g;
								var offName:String = unprocessedOFFFood.product_name != null ? String(unprocessedOFFFood.product_name).replace(/&quot;/g, "\"") : "";
								offName = firstLetterUpperCase(offName);
								if (offName == "") continue;
								var offBrand:String = unprocessedOFFFood.brands != null ? String(unprocessedOFFFood.brands) : "";
								var offProteins:Number = unprocessedOFFFood.nutriments != null && unprocessedOFFFood.nutriments.proteins_100g != null ? Number(unprocessedOFFFood.nutriments.proteins_100g) : Number.NaN;
								var offCarbs:Number = unprocessedOFFFood.nutriments != null && unprocessedOFFFood.nutriments.carbohydrates_100g != null ? Number(unprocessedOFFFood.nutriments.carbohydrates_100g) : Number.NaN;
								if (isNaN(offCarbs)) continue;
								var offFats:Number = unprocessedOFFFood.nutriments != null && unprocessedOFFFood.nutriments.fat_100g != null ? Number(unprocessedOFFFood.nutriments.fat_100g) : Number.NaN;
								var offFiber:Number = unprocessedOFFFood.nutriments != null && unprocessedOFFFood.nutriments.fiber_100g != null ? Number(unprocessedOFFFood.nutriments.fiber_100g) : Number.NaN;
								var offCalories:Number = unprocessedOFFFood.nutriments != null && unprocessedOFFFood.nutriments.energy_100g != null ? Number(unprocessedOFFFood.nutriments.energy_100g) : Number.NaN;
								if (!isNaN(offCalories))
									offCalories = convertKjToKcal(offCalories);
								var offLink:String = unprocessedOFFFood.url != null ? String(unprocessedOFFFood.url) : "";
								var offServingSize:Number = 100;
								var offServingUnit:String = "g/ml";
								var offBarCode:String = unprocessedOFFFood.code != null ? String(unprocessedOFFFood.code) : "";
								var offNote:String = "";
								
								var offNotesList:Array = [];
								
								if (unprocessedOFFFood.serving_quantity != null && !isNaN(Number(unprocessedOFFFood.serving_quantity)) && Number(unprocessedOFFFood.serving_quantity) != 100 && Number(unprocessedOFFFood.serving_quantity) != 0 && unprocessedOFFFood.serving_size != null && String(unprocessedOFFFood.serving_size) != "")
								{
									var unformattedServingSize:String = String(unprocessedOFFFood.serving_size);
									var firstPatternIndex:int = unformattedServingSize.indexOf("(");
									if (firstPatternIndex != -1)
									{
										var secondPatternIndex:int = unformattedServingSize.indexOf(")");
										var extractedString:String = StringUtil.trim(unformattedServingSize.slice(firstPatternIndex + 1, secondPatternIndex));
										var substractedString:String = StringUtil.trim(unformattedServingSize.slice(0, firstPatternIndex));
										
										unformattedServingSize = extractedString + " " + "(" + substractedString + ")";
									}
									
									unformattedServingSize = StringUtil.trim(firstLetterUpperCase(unformattedServingSize));
									unformattedServingSize = unformattedServingSize.replace(" g", "g");
									unformattedServingSize = unformattedServingSize.replace(" ml", "ml");
									unformattedServingSize = unformattedServingSize.replace(" dl", "dl");
									unformattedServingSize = unformattedServingSize.replace(" cl", "cl");
									
									var noteJSON:Object = {};
									noteJSON.label = unformattedServingSize;
									noteJSON.multiplier = Number(unprocessedOFFFood.serving_quantity) / 100;
									
									offNotesList.push(noteJSON);
									
									offNote = JSON.stringify(offNotesList);
								}
								
								var offFood:Food = new Food
								(
									offID,
									offName,
									offProteins,
									offCarbs,
									offFats,
									offCalories,
									offServingSize,
									offServingUnit,
									now,
									offFiber,
									offBrand.toUpperCase(),
									offLink,
									"OpenFoodFacts",
									offBarCode,
									false,
									0,
									"",
									offNote
								);
								
								data.push
								(
									{
										label: offName + (offBrand != "" ? "\n" + offBrand.toUpperCase() : ""),
										food: offFood
									}
								);
							}
						}
						
						//Notify Listeners
						if (data.length > 0)
						{
							_instance.dispatchEvent
								(
									new FoodEvent
									(
										FoodEvent.FOODS_SEARCH_RESULT,
										false,
										false,
										null,
										data,
										null,
										null,
										null,
										OFFSearchProperties
									)
								);
						}
						else
							_instance.dispatchEvent( new FoodEvent(FoodEvent.FOOD_NOT_FOUND) );
					}
				} 
				catch(error:Error) 
				{
					_instance.dispatchEvent( new FoodEvent(FoodEvent.FOOD_SERVER_ERROR, false, false, null, null, null, null, ModelLocator.resourceManagerInstance.getString('foodmanager','error_label') + ": " + error.message + "\n\n" + ModelLocator.resourceManagerInstance.getString('foodmanager','server_response_label') + ": " + response) );
				}
			}
			else if (currentMode == USDA_SEARCH_MODE)
			{
				try
				{
					foodsJSON = JSON.parse(response);
					if (foodsJSON != null && foodsJSON.list != null && foodsJSON.list.item != null && foodsJSON.list.item is Array)
					{
						var USDASearchProperties:Object = { pageNumber: currentUSDAPage, totalPages: Math.ceil(Number(foodsJSON.list.total) / 50), totalRecords: Number(foodsJSON.list.total) }
						
						foodList = foodsJSON.list.item as Array;
						for (i = 0; i < foodList.length; i++) 
						{
							var unprocessedUSDAFood:Object = foodList[i];
							if (unprocessedUSDAFood != null)
							{
								//Name
								var foodName:String = unprocessedUSDAFood.name;
								var upcMatchIndex:int = foodName.indexOf(", UPC");
								if (upcMatchIndex != -1) foodName = foodName.slice(0, upcMatchIndex);
								var gtinMatchIndex:int = foodName.indexOf(", GTIN");
								if (gtinMatchIndex != -1) foodName = foodName.slice(0, gtinMatchIndex);
								foodName = firstLetterUpperCase(foodName);
								
								//Brand
								var brand:String = unprocessedUSDAFood.manu != null ? String(unprocessedUSDAFood.manu).toUpperCase() : "";
								if (brand == "NONE") brand = null;
								
								var usdaFood:Food = new Food
									(
										unprocessedUSDAFood.ndbno,
										foodName,
										Number.NaN,
										Number.NaN,
										Number.NaN,
										Number.NaN,
										Number.NaN,
										"",
										now,
										Number.NaN,
										brand != null  ? brand : "",
										""
									);
								
								data.push
									(
										{
											label: foodName + (brand != null ? "\n" + brand : ""),
											food: usdaFood
										}
									);
							}
						}
						
						//Notify Listeners
						if (data.length > 0)
						{
							_instance.dispatchEvent
								(
									new FoodEvent
									(
										FoodEvent.FOODS_SEARCH_RESULT,
										false,
										false,
										null,
										data,
										null,
										null,
										null,
										USDASearchProperties
									)
								);
						}
						else
							_instance.dispatchEvent( new FoodEvent(FoodEvent.FOOD_NOT_FOUND) );
						
						currentUSDAPage = 1;
					}
					else
						_instance.dispatchEvent( new FoodEvent(FoodEvent.FOOD_NOT_FOUND) );
					
				} 
				catch(error:Error) 
				{
					_instance.dispatchEvent( new FoodEvent(FoodEvent.FOOD_SERVER_ERROR, false, false, null, null, null, null, ModelLocator.resourceManagerInstance.getString('foodmanager','error_label') + ": " + error.message + "\n\n" + ModelLocator.resourceManagerInstance.getString('foodmanager','server_response_label') + ": " + response) );
				}
			}
			else if (currentMode == USDA_REPORT_MODE)
			{
				try
				{
					foodsJSON = JSON.parse(response);
					if (foodsJSON != null && foodsJSON.report != null && foodsJSON.report.food != null && foodsJSON.report.food.nutrients != null && foodsJSON.report.food.nutrients is Array)
					{
						var foodIDUSDA:String = foodsJSON.report.food.ndbno != null ? String(foodsJSON.report.food.ndbno) : UniqueId.createEventId();
						var foodNameUSDA:String = foodsJSON.report.food.name != null ? String(foodsJSON.report.food.name) : "";
						var upcUSDAIndex:int = foodNameUSDA.indexOf("UPC: ");
						var upcBarCode:String = "";
						if (upcUSDAIndex != -1)
							upcBarCode = StringUtil.trim(foodNameUSDA.slice(upcUSDAIndex + 4));
						var upcMatchIndexUSDA:int = foodNameUSDA.indexOf(", UPC");
						if (upcMatchIndexUSDA != -1) foodNameUSDA = foodNameUSDA.slice(0, upcMatchIndexUSDA);
						var gtinMatchIndexUSDA:int = foodNameUSDA.indexOf(", GTIN");
						if (gtinMatchIndexUSDA != -1) foodNameUSDA = foodNameUSDA.slice(0, gtinMatchIndexUSDA);
						foodNameUSDA = firstLetterUpperCase(foodNameUSDA);
						var brandUSDA:String = foodsJSON.report.food.manu != null ? String(foodsJSON.report.food.manu).toUpperCase() : "";
						var servingUnitUSDA:String = foodsJSON.report.food.ru != null ? String(foodsJSON.report.food.ru) : "";
						var proteinsUSDA:Number = Number.NaN;
						var fatsUSDA:Number = Number.NaN;
						var carbsUSDA:Number = Number.NaN;
						var fiberUSDA:Number = Number.NaN;
						var caloriesUSDA:Number = Number.NaN;
						var linkUSDA:String = "https://ndb.nal.usda.gov/ndb/foods/show/" + foodIDUSDA;
						var nutrientsUSDA:Array = foodsJSON.report.food.nutrients;
						var notesUSDA:String = "";
						var notesListUSDA:Array = [];
						
						for (i = 0; i < nutrientsUSDA.length; i++) 
						{
							var nutrientDetails:Object = nutrientsUSDA[i];
							
							if (nutrientDetails.name == "Energy") 
							{
								if (nutrientDetails.value != null)
									caloriesUSDA = Number(nutrientDetails.value);
							}
							else if (nutrientDetails.name == "Protein") 
							{
								if (nutrientDetails.value != null)
									proteinsUSDA = Number(nutrientDetails.value);
							}
							else if (nutrientDetails.name.indexOf("fat") != -1) 
							{
								if (nutrientDetails.value != null)
									fatsUSDA = Number(nutrientDetails.value);
							}
							else if (nutrientDetails.name.indexOf("Carbohydrate") != -1) 
							{
								if (nutrientDetails.value != null)
								{
									carbsUSDA = Number(nutrientDetails.value);
									
									if (nutrientDetails.measures != null && nutrientDetails.measures is Array && (nutrientDetails.measures as Array).length > 0)
									{
										for (var k:int = 0; k < nutrientDetails.measures.length; k++) 
										{
											var measure:Object = nutrientDetails.measures[k];
											var value:Number = Number.NaN;
											var label:String = "";
											
											if (measure.value != null)
											{
												value = Number(measure.value);
											}
											else
												continue;
											
											if (measure.qty != null)
											{
												label += measure.qty + " ";
											}
											
											if (measure.label != null && measure.label != "")
											{
												var unformatedLabel:String = measure.label;
												unformatedLabel = firstLetterUpperCase(unformatedLabel);
												
												label += unformatedLabel + " ";
											}
											
											if (measure.eqv != null && measure.eqv != 0)
											{
												label += "(" + measure.eqv + " ";
											}
											
											if (measure.eunit != null && measure.eunit != "")
											{
												label += measure.eunit + ")";
											}
											
											var formattedServingSizeUSDA:String = StringUtil.trim(firstLetterUpperCase(label));
											formattedServingSizeUSDA = formattedServingSizeUSDA.replace(" g", "g");
											formattedServingSizeUSDA = formattedServingSizeUSDA.replace(" ml", "ml");
											formattedServingSizeUSDA = formattedServingSizeUSDA.replace(" dl", "dl");
											formattedServingSizeUSDA = formattedServingSizeUSDA.replace(" cl", "cl");
											
											var noteJSONUSDA:Object = {};
											noteJSONUSDA.label = formattedServingSizeUSDA;
											noteJSONUSDA.multiplier = value / carbsUSDA;
											notesListUSDA.push(noteJSONUSDA);
										}
										
									}
								}
							}
							else if (nutrientDetails.name.indexOf("Fiber") != -1) 
							{
								if (nutrientDetails.value != null)
									fiberUSDA = Number(nutrientDetails.value);
							}
						}
						
						if (notesListUSDA.length > 0)
						{
							notesUSDA = JSON.stringify(notesListUSDA);
						}
						
						var usdaFoodDetailed:Food = new Food
							(
								foodIDUSDA,
								foodNameUSDA,
								proteinsUSDA,
								carbsUSDA,
								fatsUSDA,
								caloriesUSDA,
								100,
								servingUnitUSDA,
								now,
								fiberUSDA,
								brandUSDA,
								linkUSDA,
								"USDA",
								upcBarCode,
								false,
								0,
								"",
								notesUSDA
							);
						
						_instance.dispatchEvent( new FoodEvent(FoodEvent.FOOD_DETAILS_RESULT, false, false, usdaFoodDetailed) );
					}
				} 
				catch(error:Error) 
				{
					_instance.dispatchEvent( new FoodEvent(FoodEvent.FOOD_SERVER_ERROR, false, false, null, null, null, null, ModelLocator.resourceManagerInstance.getString('foodmanager','error_label') + ": " + error.message + "\n\n" + ModelLocator.resourceManagerInstance.getString('foodmanager','server_response_label') + ": " + response) );
				}
			}
			
			currentMode = "";
			foodDetailMode = false;
			fatSecretBarCode = "";
			openFoodFactsBarCode = "";
		}
		
		private static function onFatSecretCodeResult(e:flash.events.Event):void
		{
			var loader:URLLoader = e.currentTarget as URLLoader;
			var response:String = String(loader.data);
			
			//Discard loader
			loader.removeEventListener(flash.events.Event.COMPLETE, onAPIResult);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onAPIError);
			loader = null;
			
			try
			{
				var codeResponseJSON:Object = SpikeJSON.parse(response);
				if (codeResponseJSON != null && codeResponseJSON.food_id != null && codeResponseJSON.food_id.value != null)
				{
					var foodID:String = codeResponseJSON.food_id.value;
					if (foodID != "0")
						fatSecretGetFoodDetails(foodID, false);
					else
						_instance.dispatchEvent( new FoodEvent(FoodEvent.FOOD_NOT_FOUND) );
				}
			} 
			catch(error:Error) 
			{
				_instance.dispatchEvent( new FoodEvent(FoodEvent.FOOD_SERVER_ERROR, false, false, null, null, null, null, ModelLocator.resourceManagerInstance.getString('foodmanager','error_label') + ": " + error.message + "\n\n" + ModelLocator.resourceManagerInstance.getString('foodmanager','server_response_label') + ": " + response) );
			}
		}
		
		private static function onAPIError(e:IOErrorEvent):void
		{
			var loader:URLLoader = e.currentTarget as URLLoader;
			loader.removeEventListener(Event.COMPLETE, onAPIResult);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onAPIError);
			loader = null;
			
			var errorMessage:String = e.text.indexOf("2032") == -1 ? e.text : ModelLocator.resourceManagerInstance.getString('foodmanager','error_connecting_to_food_service_label');
			
			_instance.dispatchEvent( new FoodEvent(FoodEvent.FOOD_SERVER_ERROR, false, false, null, null, null, null, errorMessage) );
		}
		
		/**
		 * Getters & Setters
		 */
		public static function get instance():FoodAPIConnector
		{
			return _instance;
		}
	}
}