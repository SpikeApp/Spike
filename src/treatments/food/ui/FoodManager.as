package treatments.food.ui
{
	import com.distriqt.extension.scanner.AuthorisationStatus;
	import com.distriqt.extension.scanner.Scanner;
	import com.distriqt.extension.scanner.ScannerOptions;
	import com.distriqt.extension.scanner.Symbology;
	import com.distriqt.extension.scanner.events.AuthorisationEvent;
	import com.distriqt.extension.scanner.events.ScannerEvent;
	
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	import database.CommonSettings;
	import database.Database;
	
	import events.FoodEvent;
	
	import feathers.controls.Alert;
	import feathers.controls.Button;
	import feathers.controls.Callout;
	import feathers.controls.Check;
	import feathers.controls.Label;
	import feathers.controls.LayoutGroup;
	import feathers.controls.List;
	import feathers.controls.PickerList;
	import feathers.controls.ScrollBarDisplayMode;
	import feathers.controls.ScrollContainer;
	import feathers.controls.ScrollPolicy;
	import feathers.controls.TextInput;
	import feathers.controls.popups.DropDownPopUpContentManager;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.data.ArrayCollection;
	import feathers.extensions.MaterialDesignSpinner;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.HorizontalLayout;
	import feathers.layout.RelativePosition;
	import feathers.layout.VerticalAlign;
	import feathers.layout.VerticalLayout;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.ModelLocator;
	
	import starling.animation.Transitions;
	import starling.core.Starling;
	import starling.display.Image;
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.text.TextFormat;
	import starling.textures.Texture;
	import starling.utils.SystemUtil;
	
	import treatments.food.Food;
	import treatments.food.Recipe;
	import treatments.food.connectors.FoodAPIConnector;
	
	import ui.popups.AlertManager;
	import ui.screens.display.LayoutFactory;
	
	import utils.Constants;
	import utils.DeviceInfo;
	import utils.UniqueId;
	
	[ResourceBundle("foodmanager")]

	public class FoodManager extends LayoutGroup
	{
		//CONSTANTS
		private static const ELASTICITY:Number = 0.6;
		private static const THRESHOLD:Number = 0.1;
		
		//MODES
		private static const FAVORITES_MODE:String = "favorites";
		private static const RECIPES_MODE:String = "recipes";
		private static const FATSECRET_MODE:String = "fatSecret";
		private static const OPENFOODFACTS_MODE:String = "openFoodFacts";
		private static const USDA_MODE:String = "usdaSearch";
		
		//COMPONENTS
		private var title:Label;
		private var searchContainer:LayoutGroup;
		private var searchInput:TextInput;
		private var searchButton:Button;
		private var foodResultsList:List;
		private var actionsContainer:LayoutGroup;
		private var finishButton:Button;
		private var addFoodButton:Button;
		private var databaseAPISelector:PickerList;
		private var scanButton:Button;
		private var foodDetailsContainer:LayoutGroup;
		private var mainContentContainer:ScrollContainer;
		private var foodDetailsTitle:Label;
		private var foodLink:Button;
		private var foodAmountInput:TextInput;
		private var basketPreloaderContainer:LayoutGroup;
		private var basketAmountLabel:Label;
		private var basketSprite:Sprite;
		private var basketImage:Image;
		private var preloader:MaterialDesignSpinner;
		private var basketCallout:Callout;
		private var basketHitArea:Quad;
		private var substractFiberCheck:Check;
		private var paginationContainer:LayoutGroup;
		private var firstPageButton:Button;
		private var previousPageButton:Button;
		private var paginationLabel:Label;
		private var nextPageButton:Button;
		private var lastPageButton:Button;
		private var nutritionFacts:NutritionFacts;
		private var addFoodContainer:LayoutGroup;
		private var cartTotals:CartTotalsSection;
		private var saveRecipe:Button;
		private var foodDetailsTitleContainer:LayoutGroup;
		private var favoriteButton:Button;
		private var unfavoriteButton:Button;
		private var addFavorite:Sprite;
		private var addFavoriteImage:Image;
		private var addFavoriteHitArea:Quad;
		private var addFavoriteBackground:Quad;
		private var foodInserter:FoodInserter;
		private var footerContainer:LayoutGroup;
		private var foodServingSizePickerList:PickerList;
		private var instructionsButton:Button;
		private var mainActionsContainer:LayoutGroup;
		private var editfavoriteButton:Button;
		
		//PROPERTIES
		public var cartList:Array;
		private var currentMode:String = "";
		private var renderTimoutID1:uint;
		private var renderTimoutID2:uint;
		private var renderTimoutID3:uint;
		private var containerHeight:Number;
		private var selectedFoodLink:String;
		private var activeFood:Food;
		private var basketList:List;
		private var deleteButtonsList:Array = [];
		private var currentPage:int = 1;
		private var totalPages:int = 1;	
		private var dontClearSearchResults:Boolean = false;
		private var activeRecipe:Recipe;
		private var loadedFromExternalContainer:Boolean; 
		private var defaultScreen:String;
		private var fiberPrecision:Number;
		private var autoSearchTimeoutID:uint = 0;
		private var globalMultiplier:Number = 1;
		private var globalUnit:String = "";	
		private var accessoryList:Array = [];
		private var searchBarCodeActive:Boolean = false;

		public function FoodManager(width:Number, containerHeight:Number, loadedFromExternalContainer:Boolean = false)
		{
			this.width = width;
			this.containerHeight = containerHeight;
			this.loadedFromExternalContainer = loadedFromExternalContainer;
			
			setupProperties();
			setupInitialSettings();
			createContent(); 
		}
		
		private function setupProperties():void
		{
			this.layout = new VerticalLayout();
			this.cartList = [];
		}
		
		private function setupInitialSettings():void
		{
			defaultScreen = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FOOD_MANAGER_DEFAULT_SCREEN);
			fiberPrecision = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FOOD_MANAGER_FIBER_PRECISION));
		}
		
		private function createContent():void
		{
			var mainLayout:VerticalLayout = new VerticalLayout();
			mainLayout.horizontalAlign = HorizontalAlign.CENTER;
			mainLayout.gap = 10;
			
			mainContentContainer = new ScrollContainer();
			mainContentContainer.height = containerHeight;
			mainContentContainer.width = width;
			mainContentContainer.horizontalScrollPolicy = ScrollPolicy.OFF;
			mainContentContainer.scrollBarDisplayMode = ScrollBarDisplayMode.FIXED_FLOAT;
			mainContentContainer.verticalScrollBarProperties.paddingRight = -10;
			mainContentContainer.layout = mainLayout;
			addChild(mainContentContainer);
			
			//Title
			title = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('foodmanager','food_manager_title_label'), HorizontalAlign.CENTER, VerticalAlign.TOP, 18, true);
			title.width = width;
			mainContentContainer.addChild(title);
			
			//Search Controls
			databaseAPISelector = LayoutFactory.createPickerList();
			databaseAPISelector.itemRendererFactory = function():IListItemRenderer
			{
				var renderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				renderer.paddingRight = renderer.paddingLeft = 15;
				return renderer;
			};
			databaseAPISelector.dataProvider = new ArrayCollection
			(
				[
					{ label: ModelLocator.resourceManagerInstance.getString('foodmanager','favourites_label') },
					{ label: ModelLocator.resourceManagerInstance.getString('foodmanager','recipes_label') },
					{ label: "FatSecret" },
					{ label: "Open Food Facts" },
					{ label: "USDA" },
				]
			);
			databaseAPISelector.labelField = "label";
			databaseAPISelector.popUpContentManager = new DropDownPopUpContentManager();
			databaseAPISelector.selectedIndex = -1;
			databaseAPISelector.addEventListener(starling.events.Event.CHANGE, onAPIChanged);
			mainContentContainer.addChild(databaseAPISelector);
			
			searchContainer = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.CENTER, VerticalAlign.MIDDLE, 5);
			searchContainer.width = width;
			mainContentContainer.addChild(searchContainer);
			
			searchInput = LayoutFactory.createTextInput(false, false, width/2, HorizontalAlign.CENTER, false, false, false, false, true);
			searchInput.prompt = ModelLocator.resourceManagerInstance.getString('foodmanager','search_food_label');
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FOOD_MANAGER_SEARCH_AS_I_TYPE) == "true")
				searchInput.addEventListener(Event.CHANGE, onSearchInputChanged);
			searchContainer.addChild(searchInput);
			
			searchButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('foodmanager','go_button_label'));
			searchButton.paddingLeft = searchButton.paddingRight = 15;
			searchButton.validate();
			searchButton.addEventListener(starling.events.Event.TRIGGERED, onPerformSearch);
			searchContainer.addChild(searchButton);
			
			scanButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('foodmanager','scan_button_label'));
			scanButton.paddingLeft = scanButton.paddingRight = 15;
			scanButton.validate();
			scanButton.addEventListener(starling.events.Event.TRIGGERED, onScan);
			searchContainer.addChild(scanButton);
			
			var totalSearchWidh:Number = searchButton.width + scanButton.width + 5;
			var difference:Number = width - totalSearchWidh - 5;
			searchInput.width = difference;
			
			//Results List
			foodResultsList = new List();
			var resultsLayout:VerticalLayout = new VerticalLayout();
			resultsLayout.hasVariableItemDimensions = true;
			foodResultsList.layout = resultsLayout;
			foodResultsList.width = width;
			foodResultsList.maxWidth = width;
			foodResultsList.height = 150;
			foodResultsList.addEventListener(Event.CHANGE, onFoodOrRecipeSelected);
			mainContentContainer.addChild(foodResultsList);
			
			foodResultsList.itemRendererFactory = function():IListItemRenderer 
			{
				const item:DefaultListItemRenderer = new DefaultListItemRenderer();
				item.labelField = "label";
				item.accessoryField = "accessory";
				item.iconSourceField = "icon";
				item.accessoryLabelProperties.wordWrap = true;
				item.defaultLabelProperties.wordWrap = true;
				item.width = width;
				
				return item;
			};
			
			//Footer Actions Container
			footerContainer = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.LEFT, VerticalAlign.TOP);
			footerContainer.width = width;
			mainContentContainer.addChild(footerContainer);
			
			//Pagination Container
			paginationContainer = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.LEFT, VerticalAlign.MIDDLE);
			paginationContainer.width = width/2;
			footerContainer.addChild(paginationContainer);
			
			firstPageButton = LayoutFactory.createButton("<<");
			firstPageButton.paddingLeft = firstPageButton.paddingRight = firstPageButton.paddingTop = firstPageButton.paddingBottom = 0;
			firstPageButton.isEnabled = false;
			firstPageButton.addEventListener(Event.TRIGGERED, onFirstPage);
			paginationContainer.addChild(firstPageButton);
			
			previousPageButton = LayoutFactory.createButton("<");
			previousPageButton.paddingLeft = previousPageButton.paddingRight = previousPageButton.paddingTop = previousPageButton.paddingBottom = 0;
			previousPageButton.isEnabled = false;
			previousPageButton.addEventListener(Event.TRIGGERED, onPreviousPage);
			paginationContainer.addChild(previousPageButton);
			
			paginationLabel = LayoutFactory.createLabel("1/1", HorizontalAlign.CENTER, VerticalAlign.MIDDLE);
			paginationLabel.paddingLeft = paginationLabel.paddingRight = 5;
			paginationLabel.isEnabled = false;
			paginationContainer.addChild(paginationLabel);
			
			nextPageButton = LayoutFactory.createButton(">");
			nextPageButton.paddingLeft = nextPageButton.paddingRight = nextPageButton.paddingTop = nextPageButton.paddingBottom = 0;
			nextPageButton.isEnabled = false;
			nextPageButton.addEventListener(Event.TRIGGERED, onNextPage);
			paginationContainer.addChild(nextPageButton);
			
			lastPageButton = LayoutFactory.createButton(">>");
			lastPageButton.paddingLeft = lastPageButton.paddingRight = lastPageButton.paddingTop = lastPageButton.paddingBottom = 0;
			lastPageButton.isEnabled = false;
			lastPageButton.addEventListener(Event.TRIGGERED, onLastPage);
			paginationContainer.addChild(lastPageButton);
			
			//Basket & Preloader Container
			basketPreloaderContainer = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.RIGHT, VerticalAlign.TOP);
			basketPreloaderContainer.width = width/2;
			footerContainer.addChild(basketPreloaderContainer);
			
			//Add Favorite
			addFavorite = new Sprite();
			addFavorite.touchable = true;
			addFavorite.addEventListener(TouchEvent.TOUCH, onAddManualFavorite);
			
			addFavoriteImage = new Image(MaterialDeepGreyAmberMobileThemeIcons.addTexture);
			addFavoriteImage.scale = 1;
			addFavoriteImage.touchable = false;
			addFavoriteImage.y = 5;
			addFavorite.addChild(addFavoriteImage);
			
			addFavoriteBackground = new Quad(addFavoriteImage.bounds.width + 10, addFavoriteImage.bounds.height, 0xFF0000);
			addFavoriteBackground.alpha = 0;
			addFavoriteBackground.touchable = false;
			addFavoriteBackground.y = 5;
			addFavorite.addChildAt(addFavoriteBackground, 0);
			
			addFavoriteHitArea = new Quad(addFavoriteImage.bounds.width, addFavoriteImage.bounds.height, 0x00FF00);
			addFavoriteHitArea.alpha = 0;
			addFavoriteHitArea.touchable = true;
			addFavoriteHitArea.y = 5;
			addFavorite.addChild(addFavoriteHitArea);
			
			//Preloader
			preloader = new MaterialDesignSpinner();
			preloader.color = 0x0086FF;
			preloader.touchable = false;
			preloader.scale = 0.4;
			preloader.validate();
			
			//Basket
			basketSprite = new Sprite();
			basketSprite.touchable = true;
			basketSprite.addEventListener(TouchEvent.TOUCH, onDisplayBasket);
			basketPreloaderContainer.addChild(basketSprite);
			
			basketImage = new Image(MaterialDeepGreyAmberMobileThemeIcons.foodBasketTexture);
			basketImage.scale = 0.8;
			basketImage.touchable = false;
			basketSprite.addChild(basketImage);
			
			basketAmountLabel = LayoutFactory.createLabel("0", HorizontalAlign.CENTER, VerticalAlign.MIDDLE, 10, true, 0xFFFFFF);
			basketAmountLabel.touchable = false;
			basketAmountLabel.width = 15;
			basketAmountLabel.x = 7;
			basketAmountLabel.y = -1;
			basketSprite.addChild(basketAmountLabel);
			
			basketHitArea = new Quad(basketImage.bounds.width, basketImage.bounds.height, 0xFF0000);
			basketHitArea.alpha = 0;
			basketHitArea.touchable = true;
			basketSprite.addChild(basketHitArea);
			
			basketPreloaderContainer.readjustLayout();
			basketPreloaderContainer.validate();
			preloader.x += 15;
			preloader.y += 9;
			basketSprite.y += 5;
			
			var basketListLayout:VerticalLayout = new VerticalLayout();
			basketListLayout.hasVariableItemDimensions = true;
			
			basketList = new List();
			basketList.layout = basketListLayout;
			basketList.width = 220;
			basketList.maxHeight = 400;
			basketList.itemRendererFactory = function():IListItemRenderer 
			{
				const item:DefaultListItemRenderer = new DefaultListItemRenderer();
				item.labelField = "label";
				item.accessoryField = "accessory";
				item.iconSourceField = "icon";
				item.accessoryLabelProperties.wordWrap = true;
				item.defaultLabelProperties.wordWrap = true;
				item.width = 250;
				item.paddingRight = 30;
				
				return item;
			};
			
			saveRecipe = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('foodmanager','save_as_recipe_label'));
			saveRecipe.pivotX = 48;
			saveRecipe.addEventListener(Event.TRIGGERED, onSaveRecipe);
			
			//Food Details
			foodDetailsContainer = LayoutFactory.createLayoutGroup("vertical", HorizontalAlign.CENTER, VerticalAlign.TOP, 5);
			foodDetailsContainer.width = width;
			foodDetailsContainer.maxWidth = width;
			(foodDetailsContainer.layout as VerticalLayout).paddingBottom = -5;
			(foodDetailsContainer.layout as VerticalLayout).paddingTop = -10;
			
			foodDetailsTitleContainer = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.CENTER, VerticalAlign.MIDDLE, 0);
			foodDetailsTitleContainer.width = width;
			foodDetailsContainer.addChild(foodDetailsTitleContainer);
			
			foodDetailsTitle = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('foodmanager','nutrition_facts_label'), HorizontalAlign.CENTER, VerticalAlign.TOP, 18, true);
			foodDetailsTitle.touchable = false;
			foodDetailsTitle.paddingTop = foodDetailsTitle.paddingBottom = 10;
			foodDetailsTitleContainer.addChild(foodDetailsTitle);
			
			favoriteButton = new Button();
			favoriteButton.defaultIcon = new Image(MaterialDeepGreyAmberMobileThemeIcons.favoriteOutlineTexture);
			favoriteButton.styleNameList.add(Button.ALTERNATE_STYLE_NAME_QUIET_BUTTON);
			favoriteButton.addEventListener(Event.TRIGGERED, onAddFoodOrRecipeAsFavorite);
			
			unfavoriteButton = new Button();
			unfavoriteButton.defaultIcon = new Image(MaterialDeepGreyAmberMobileThemeIcons.favoriteTexture);
			unfavoriteButton.styleNameList.add(Button.ALTERNATE_STYLE_NAME_QUIET_BUTTON);
			unfavoriteButton.addEventListener(Event.TRIGGERED, onRemoveFoodOrRecipeAsFavorite);
			
			editfavoriteButton = new Button();
			editfavoriteButton.defaultIcon = new Image(MaterialDeepGreyAmberMobileThemeIcons.editTexture);
			editfavoriteButton.styleNameList.add(Button.ALTERNATE_STYLE_NAME_QUIET_BUTTON);
			editfavoriteButton.addEventListener(Event.TRIGGERED, onEditFavorite);
			
			//Add Food Components
			addFoodContainer = LayoutFactory.createLayoutGroup("vertical", HorizontalAlign.CENTER, VerticalAlign.MIDDLE, 10);
			
			foodAmountInput = LayoutFactory.createTextInput(false, false, 60, HorizontalAlign.CENTER, true);
			foodAmountInput.maxChars = 5;
			foodAmountInput.height = 30;
			foodAmountInput.addEventListener(Event.CHANGE, onFoodAmountChanged);
			addFoodContainer.addChild(foodAmountInput);
			
			addFoodButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('globaltranslations','add_button_label'));
			addFoodButton.paddingLeft = addFoodButton.paddingRight = 12;
			addFoodButton.height = 32;
			addFoodButton.addEventListener(starling.events.Event.TRIGGERED, onAddFoodOrRecipe);
			addFoodContainer.addChild(addFoodButton);
			
			//Subtract Fiber Component
			substractFiberCheck = LayoutFactory.createCheckMark(false);
			substractFiberCheck.paddingTop = 3;
			
			//Link Component
			foodLink = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('foodmanager','go_button_label'), true);
			foodLink.paddingLeft = foodLink.paddingRight = 4;
			foodLink.height = 27;
			foodLink.addEventListener(Event.TRIGGERED, onFoodLinkTriggered);
			
			//Nutrition Facts Component
			foodServingSizePickerList = LayoutFactory.createPickerList();
			foodServingSizePickerList.itemRendererFactory = function():IListItemRenderer
			{
				var renderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				renderer.paddingRight = renderer.paddingLeft = 15;
				return renderer;
			};
			foodServingSizePickerList.buttonFactory = function():Button
			{
				var button:Button = new Button();
				button.padding = 10;
				button.width = width / 3;
				button.maxWidth = width / 3;
				
				return button;
			};
			foodServingSizePickerList.addEventListener(Event.CHANGE, onServingChanged);
			
			foodServingSizePickerList.labelField = "label";
			foodServingSizePickerList.popUpContentManager = new DropDownPopUpContentManager();
			foodServingSizePickerList.selectedIndex = -1;
			
			nutritionFacts = new NutritionFacts(width);
			nutritionFacts.setServingsTitle(ModelLocator.resourceManagerInstance.getString('foodmanager','serving_size_label'));
			nutritionFacts.setServingsListTitle(ModelLocator.resourceManagerInstance.getString('foodmanager','serving_size_label'));
			nutritionFacts.setServingsListComponent(foodServingSizePickerList);
			nutritionFacts.setCarbsTitle(ModelLocator.resourceManagerInstance.getString('foodmanager','carbs_label'));
			nutritionFacts.setFiberTitle(ModelLocator.resourceManagerInstance.getString('foodmanager','fiber_label'));
			nutritionFacts.setProteinsTitle(ModelLocator.resourceManagerInstance.getString('foodmanager','proteins_label'));
			nutritionFacts.setFatsTitle(ModelLocator.resourceManagerInstance.getString('foodmanager','fats_label'));
			nutritionFacts.setCaloriesTitle(ModelLocator.resourceManagerInstance.getString('foodmanager','calories_label'));
			nutritionFacts.setSubtractFiberTitle(fiberPrecision == 1 ? ModelLocator.resourceManagerInstance.getString('foodmanager','subtract_whole_fiber') : ModelLocator.resourceManagerInstance.getString('foodmanager','subtract_half_fiber'));
			nutritionFacts.setSubtractFiberComponent(substractFiberCheck);
			nutritionFacts.setLinkTitle(ModelLocator.resourceManagerInstance.getString('foodmanager','link_button_label'));
			nutritionFacts.setLinkComponent(foodLink);
			nutritionFacts.setAmountTitle(ModelLocator.resourceManagerInstance.getString('foodmanager','amount_label'));
			nutritionFacts.setAmountComponent(addFoodContainer);
			foodDetailsContainer.addChild(nutritionFacts);
			
			//Actions
			mainActionsContainer = LayoutFactory.createLayoutGroup("vertical", HorizontalAlign.CENTER, VerticalAlign.MIDDLE, 10);
			mainActionsContainer.width = width;
			(mainActionsContainer.layout as VerticalLayout).paddingTop = 4;
			if (loadedFromExternalContainer) (mainActionsContainer.layout as VerticalLayout).paddingBottom = 10;
			mainContentContainer.addChild(mainActionsContainer);
			
			actionsContainer = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.CENTER, VerticalAlign.TOP, 5);
			actionsContainer.width = width;
			mainActionsContainer.addChild(actionsContainer);
			
			finishButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('foodmanager','finish_button_label').toUpperCase());
			finishButton.addEventListener(starling.events.Event.TRIGGERED, onCompleteFoodManager);
			actionsContainer.addChild(finishButton);
			
			instructionsButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('globaltranslations','instructions_button_label').toUpperCase());
			instructionsButton.addEventListener(Event.TRIGGERED, onInstructionsTriggered);
			mainActionsContainer.addChild(instructionsButton);
			
			//Setup Initial Screen
			if (defaultScreen == "favorites")
			{
				databaseAPISelector.selectedIndex = 0;
			}
			else if (defaultScreen == "recipes")
			{
				databaseAPISelector.selectedIndex = 1
			}
			else if (defaultScreen == "fatsecret")
			{
				databaseAPISelector.selectedIndex = 2;
			}
			else if (defaultScreen == "openfoodfacts")
			{
				databaseAPISelector.selectedIndex = 3;
			}
			else if (defaultScreen == "usda")
			{
				databaseAPISelector.selectedIndex = 4;
			}
		}
		
		private function onInstructionsTriggered(e:Event):void
		{
			navigateToURL(new URLRequest("https://github.com/SpikeApp/Spike/wiki/Food-Manager"));
		}
		
		private function onServingChanged(e:Event):void
		{
			if (foodDetailsTitleContainer != null) foodDetailsTitleContainer.x = 0;
			
			if (activeFood != null)
			{
				if (foodServingSizePickerList.selectedItem.multiplier != null)
				{
					globalMultiplier = foodServingSizePickerList.selectedItem.multiplier;
					globalUnit = foodServingSizePickerList.selectedItem.label;
					foodAmountInput.text = "1";
				}
				else
				{
					globalMultiplier = 1;
					globalUnit = "";
					foodAmountInput.text = String(activeFood.servingSize);
				}
				
				displayFoodDetails(activeFood, true);
			}
		}
		
		private function getInitialFavorites():void
		{
			if (foodDetailsTitleContainer != null) foodDetailsTitleContainer.x = 0;
			
			searchBarCodeActive = false;
			
			FoodAPIConnector.instance.addEventListener(FoodEvent.FOODS_SEARCH_RESULT, onFoodsSearchResult);
			FoodAPIConnector.instance.addEventListener(FoodEvent.FOOD_NOT_FOUND, onFoodOrRecipeNotFound);
			
			FoodAPIConnector.favoritesSearchFood("", currentPage);
		}
		
		private function getInitialRecipes():void
		{
			if (foodDetailsTitleContainer != null) foodDetailsTitleContainer.x = 0;
			
			searchBarCodeActive = false;
			
			FoodAPIConnector.instance.addEventListener(FoodEvent.RECIPES_SEARCH_RESULT, onRecipesSearchResult);
			FoodAPIConnector.instance.addEventListener(FoodEvent.RECIPE_NOT_FOUND, onFoodOrRecipeNotFound);
			
			FoodAPIConnector.recipesSearch("", currentPage);
		}
		
		private function onSearchInputChanged(e:Event):void
		{
			clearTimeout(autoSearchTimeoutID);
			
			if (currentMode != FAVORITES_MODE && currentMode != RECIPES_MODE)
			{
				autoSearchTimeoutID = setTimeout( function():void {
					clearTimeout(autoSearchTimeoutID);
					searchBarCodeActive = false;
					onPerformSearch();
				}, 500 );
			}
			else
			{
				searchBarCodeActive = false;
				onPerformSearch();
			}
		}
		
		private function populateBasketList():void
		{
			if (foodDetailsTitleContainer != null) foodDetailsTitleContainer.x = 0;
			
			var cartData:Array = [];
			var totalProteins:Number = 0;
			var totalProteinsNaN:Boolean = false;
			var totalCarbs:Number = 0;
			var totalCarbsNaN:Boolean = false;
			var totalFiber:Number = 0;
			var totalFiberNaN:Boolean = false;
			var totalFiberToSubstract:Number = 0;
			var totalFats:Number = 0;
			var totalFatsNaN:Boolean = false;
			var totalCalories:Number = 0;
			var totalCaloriesNaN:Boolean = false;
			
			for (var i:int = 0; i < cartList.length; i++) 
			{
				var cartItem:Object = cartList[i];
				var cartFood:Food = cartItem.food as Food;
				var cartMultiplier:Number = cartItem.multiplier;
				var cartGlobalUnit:String = cartItem.globalUnit;
				var cartQuantity:Number = cartItem.quantity;
				var cartServingSize:Number = cartFood.servingSize;
				var cartID:String = cartItem.id;
				var defaultUnit:Boolean = cartFood.defaultUnit;
				
				if (cartMultiplier != 1)
				{
					cartQuantity = cartQuantity * cartServingSize;
				}
				
				var deleteButton:Button = createDeleteButton();
				accessoryList.push(deleteButton);
				
				cartData.push( { label: cartItem.quantity + (cartMultiplier != 1 || !defaultUnit ? " x " : " ") + (cartGlobalUnit == "" ? cartItem.servingUnit : cartGlobalUnit) + " " + cartFood.name, accessory: deleteButton, food: cartFood, quantity: cartQuantity, servingUnit: (cartGlobalUnit == "" ? cartItem.servingUnit : cartGlobalUnit), id: cartID } );
				
				var itemProteins:Number = Math.round(((cartQuantity / cartServingSize) * cartFood.proteins * cartMultiplier) * 100) / 100;
				if (!isNaN(itemProteins))
					totalProteins += itemProteins;
				else
					totalProteinsNaN = true;
				
				var itemCarbs:Number = Math.round(((cartQuantity / cartServingSize) * cartFood.carbs * cartMultiplier) * 100) / 100;
				if(!isNaN(itemCarbs))
					totalCarbs += itemCarbs;
				else
					totalCarbsNaN = true;
				
				var itemFiber:Number = Math.round(((cartQuantity / cartServingSize) * cartFood.fiber * cartMultiplier) * 100) / 100;
				if (!isNaN(itemFiber))
				{
					totalFiber += itemFiber;
					if (cartItem.substractFiber)
						totalFiberToSubstract += fiberPrecision == 1 ? itemFiber : itemFiber / 2;
				}
				else
					totalFiberNaN = true;
				
				var itemFats:Number = Math.round(((cartQuantity / cartServingSize) * cartFood.fats * cartMultiplier) * 100) / 100;
				if (!isNaN(itemFats))
					totalFats += itemFats;
				else
					totalFatsNaN = true;
				
				var itemCalories:Number = Math.round(((cartQuantity / cartServingSize) * cartFood.kcal * cartMultiplier));
				if (!isNaN(itemCalories))
					totalCalories += itemCalories;
				else
					totalCaloriesNaN = true;
			}
			
			//Round values
			totalProteins = Math.round(totalProteins * 100) / 100;
			totalCarbs = Math.round((totalCarbs - totalFiberToSubstract) * 100) / 100;
			totalFiber = Math.round(totalFiber * 100) / 100;
			totalFiberToSubstract = Math.round(totalFiberToSubstract * 100) / 100;
			totalFats = Math.round(totalFats * 100) / 100;
			totalCalories = Math.round(totalCalories);
			
			//Create Total's UI
			if (cartData.length > 0)
			{
				var cartWidth:Number = 210;
				
				if (cartTotals != null) cartTotals.removeFromParent(true);
				cartTotals = new CartTotalsSection(cartWidth);
				cartTotals.width = cartWidth;
				cartTotals.title.text = ModelLocator.resourceManagerInstance.getString('foodmanager','cart_totals_label');
				cartTotals.title.width = cartWidth;
				cartTotals.title.validate();
				cartTotals.value.wordWrap = true;
				cartTotals.value.text = ModelLocator.resourceManagerInstance.getString('foodmanager','proteins_label') + ": " + (totalProteins == 0 && totalProteinsNaN ? ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available') : totalProteins + "g") + "\n" + ModelLocator.resourceManagerInstance.getString('foodmanager','carbs_label') + ": " + (totalCarbs == 0 && totalCarbsNaN ? ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available') : totalCarbs + "g") + (totalFiberToSubstract != 0 ? " (-" + totalFiberToSubstract + "g " + ModelLocator.resourceManagerInstance.getString('foodmanager','fiber_label').toLocaleLowerCase() + ")" : "") + "\n" + ModelLocator.resourceManagerInstance.getString('foodmanager','fiber_label') + ": " + (totalFiber == 0 && totalFiberNaN ? ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available') : totalFiber + "g") + "\n" + ModelLocator.resourceManagerInstance.getString('foodmanager','fats_label') + ": " + (totalFats == 0 && totalFatsNaN ? ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available') : totalFats + "g") + "\n" + ModelLocator.resourceManagerInstance.getString('foodmanager','calories_label') + ": " + (totalCalories == 0 && totalCaloriesNaN ? ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available') : totalCalories + "Kcal");
				cartTotals.value.width = cartWidth;
				cartTotals.value.validate();
					
				cartData.push( { label: "", accessory: cartTotals } );
				cartData.push( { label: "", accessory: saveRecipe } );
			}
			
			basketList.width = cartWidth;
			basketList.dataProvider = new ArrayCollection( cartData );
		}
		
		private function scanFood():void
		{
			if (foodDetailsTitleContainer != null) foodDetailsTitleContainer.x = 0;
			
			Scanner.service.addEventListener( ScannerEvent.CODE_FOUND, onBarcodeFound );
			Scanner.service.addEventListener( ScannerEvent.CANCELLED, onScanCanceled );
			
			resetComponents();
			removeFoodInserter();
			
			var options:ScannerOptions = new ScannerOptions();
			options.camera = ScannerOptions.CAMERA_REAR;
			options.torchMode = ScannerOptions.TORCH_AUTO;
			options.cancelLabel = ModelLocator.resourceManagerInstance.getString('globaltranslations','cancel_button_label').toUpperCase();
			options.colour = 0x0086FF;
			options.textColour = 0xEEEEEE;
			options.singleResult = true;
			options.symbologies = [Symbology.UPCA, Symbology.EAN13, Symbology.EAN8, Symbology.UPCE];
			
			Scanner.service.startScan( options );
		}
		
		/**
		 * Helper Functions
		 */
		private function displayRecipeDetails(selectedRecipe:Recipe):void
		{
			activeRecipe = selectedRecipe;
			
			if (foodDetailsContainer.parent == null)
			{
				var detailsIndex:int = mainContentContainer.getChildIndex(mainActionsContainer);
				mainContentContainer.addChildAt(foodDetailsContainer, detailsIndex);
			}
			
			nutritionFacts.setServingsValue(!isNaN(Number(selectedRecipe.servingSize)) ? selectedRecipe.servingSize + " " + (selectedRecipe.servingUnit != null && selectedRecipe.servingUnit != "" && selectedRecipe.servingUnit != "undefined" ? selectedRecipe.servingUnit : "" ) : ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available') );
			nutritionFacts.setCarbsValue(!isNaN(selectedRecipe.totalCarbs) ? String(selectedRecipe.totalCarbs) + "g" : ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available') );
			nutritionFacts.setFiberValue(!isNaN(selectedRecipe.totalFiber) ? String(selectedRecipe.totalFiber) + "g" : ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available') );
			nutritionFacts.setProteinsValue(!isNaN(selectedRecipe.totalProteins) ? String(selectedRecipe.totalProteins) + "g" : ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available') );
			nutritionFacts.setFatsValue(!isNaN(selectedRecipe.totalFats) ? String(selectedRecipe.totalFats) + "g" : ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available') );
			nutritionFacts.setCaloriesValue(!isNaN(selectedRecipe.totalCalories) ? Math.round(selectedRecipe.totalCalories) + "Kcal" : ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available') );
			
			nutritionFacts.isRecipe();
			
			foodDetailsTitleContainer.x = 0;
			editfavoriteButton.removeFromParent();
			
			if (Database.isRecipeFavoriteSynchronous(selectedRecipe))
			{
				//Recipe is a favorite
				foodDetailsTitleContainer.addChild(unfavoriteButton);
				favoriteButton.removeFromParent();
			}
			else
			{
				//Recipe is not a favorite
				foodDetailsTitleContainer.addChild(favoriteButton);
				unfavoriteButton.removeFromParent();
			}
			
			foodAmountInput.text = selectedRecipe.servingSize;
			addFoodButton.isEnabled = true;
		}
		
		private function displayFoodDetails(selectedFood:Food, skipServingUpdate:Boolean = false):void
		{
			if (selectedFood == null)
				return;
			
			if (selectedFood.note == "")
			{
				globalMultiplier = 1;
				globalUnit = "";
				foodAmountInput.text = String(selectedFood.servingSize);
			}
			
			onFoodAmountChanged(null);
			activeFood = selectedFood;
			
			if (foodDetailsContainer.parent == null)
			{
				var detailsIndex:int = mainContentContainer.getChildIndex(mainActionsContainer);
				mainContentContainer.addChildAt(foodDetailsContainer, detailsIndex);
			}
			
			if (!skipServingUpdate)
			{
				if (selectedFood.note == "")
					nutritionFacts.setServingsValue(!isNaN(selectedFood.servingSize) ? selectedFood.servingSize + (selectedFood.servingUnit != null && selectedFood.servingUnit != "" && selectedFood.servingUnit != "undefined" ? selectedFood.servingUnit : "" ) : ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available') );
				else
				{
					var servingOptions:Array;
					
					try
					{
						servingOptions = JSON.parse(selectedFood.note) as Array;
					} 
					catch(error:Error) 
					{
						nutritionFacts.setServingsValue(!isNaN(selectedFood.servingSize) ? selectedFood.servingSize + (selectedFood.servingUnit != null && selectedFood.servingUnit != "" && selectedFood.servingUnit != "undefined" ? selectedFood.servingUnit : "" ) : ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available') );
					}
					
					if (servingOptions != null)
					{
						servingOptions.unshift( { label: !isNaN(selectedFood.servingSize) ? selectedFood.servingSize + (selectedFood.servingUnit != null && selectedFood.servingUnit != "" && selectedFood.servingUnit != "undefined" ? selectedFood.servingUnit : "" ) : ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available') } );
						foodServingSizePickerList.dataProvider = new ArrayCollection(servingOptions);
						foodServingSizePickerList.invalidate();
						nutritionFacts.setServingsListComponent(foodServingSizePickerList);
					}
					else
						nutritionFacts.setServingsValue(!isNaN(selectedFood.servingSize) ? selectedFood.servingSize + (selectedFood.servingUnit != null && selectedFood.servingUnit != "" && selectedFood.servingUnit != "undefined" ? selectedFood.servingUnit : "" ) : ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available') );
				}
			}
			
			nutritionFacts.setCarbsValue(!isNaN(selectedFood.carbs) ? String(Math.round(selectedFood.carbs * globalMultiplier * 100) / 100) + "g" : ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available') );
			nutritionFacts.setFiberValue(!isNaN(selectedFood.fiber) ? String(Math.round(selectedFood.fiber * globalMultiplier * 100) / 100) + "g" : ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available') );
			nutritionFacts.setProteinsValue(!isNaN(selectedFood.proteins) ? String(Math.round(selectedFood.proteins * globalMultiplier * 100) / 100) + "g" : ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available') );
			nutritionFacts.setFatsValue(!isNaN(selectedFood.fats) ? String(Math.round(selectedFood.fats * globalMultiplier * 100) / 100) + "g" : ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available') );
			nutritionFacts.setCaloriesValue(!isNaN(selectedFood.kcal) ? (Math.round(selectedFood.kcal * globalMultiplier)) + "Kcal" : ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available') );
			
			nutritionFacts.isFood();
			
			if (selectedFood.link != null && selectedFood.link != "")
			{
				foodLink.isEnabled = true;
				selectedFoodLink = selectedFood.link;
			}
			else
				foodLink.isEnabled = false;
			
			substractFiberCheck.isEnabled = isNaN(selectedFood.fiber) ? false : true;
			addFoodButton.isEnabled = !isNaN(selectedFood.carbs) ? true : false;
			
			foodDetailsTitleContainer.x = 0;
			editfavoriteButton.removeFromParent();
			
			if (Database.isFoodFavoriteSynchronous(selectedFood))
			{
				//Food is a favorite
				foodDetailsTitleContainer.addChild(unfavoriteButton);
				favoriteButton.removeFromParent();
			}
			else
			{
				//Food is not a favorite
				foodDetailsTitleContainer.addChild(favoriteButton);
				unfavoriteButton.removeFromParent();
			}
			
			if (currentMode == FAVORITES_MODE)
			{
				foodDetailsTitleContainer.addChild(editfavoriteButton);
				foodDetailsTitleContainer.validate();
				editfavoriteButton.x -= 22;
				foodDetailsContainer.validate();
				foodDetailsTitleContainer.x = 20;
			}
		}
		
		private function updateFoodDetails(amount:Number):void
		{
			if (foodDetailsTitleContainer != null) foodDetailsTitleContainer.x = 0;
			
			if (currentMode != RECIPES_MODE)
			{
				var selectedFood:Food = activeFood;
				
				if (selectedFood != null && !isNaN(amount))
				{
					if (globalMultiplier != 1)
					{
						amount = (amount * selectedFood.servingSize);
					}
					
					nutritionFacts.setCarbsValue(!isNaN(selectedFood.carbs) ? String(Math.round(((amount / selectedFood.servingSize) * selectedFood.carbs * globalMultiplier) * 100) / 100) + "g" : ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available') );
					nutritionFacts.setFiberValue(!isNaN(selectedFood.fiber) ? String(Math.round(((amount / selectedFood.servingSize) * selectedFood.fiber * globalMultiplier) * 100) / 100) + "g" : ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available') );
					nutritionFacts.setProteinsValue(!isNaN(selectedFood.proteins) ? String(Math.round(((amount / selectedFood.servingSize) * selectedFood.proteins * globalMultiplier) * 100) / 100) + "g" : ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available') );
					nutritionFacts.setFatsValue(!isNaN(selectedFood.fats) ? String(Math.round(((amount / selectedFood.servingSize) * selectedFood.fats * globalMultiplier) * 100) / 100) + "g" : ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available') );
					nutritionFacts.setCaloriesValue(!isNaN(selectedFood.kcal) ? String(Math.round(((amount / selectedFood.servingSize) * selectedFood.kcal * globalMultiplier))) + "Kcal" : ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available') );
				}
			}
			else if (currentMode == RECIPES_MODE)
			{
				var selectedRecipe:Recipe = activeRecipe;
				
				if (selectedRecipe != null && !isNaN(amount))
				{
					selectedRecipe.performCalculations(amount);
					
					nutritionFacts.setCarbsValue(!isNaN(selectedRecipe.totalCarbs) ? selectedRecipe.totalCarbs + "g" : ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available') );
					nutritionFacts.setFiberValue(!isNaN(selectedRecipe.totalFiber) ? selectedRecipe.totalFiber + "g" : ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available') );
					nutritionFacts.setProteinsValue(!isNaN(selectedRecipe.totalProteins) ? selectedRecipe.totalProteins + "g" : ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available') );
					nutritionFacts.setFatsValue(!isNaN(selectedRecipe.totalFats) ? selectedRecipe.totalFats + "g" : ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available') );
					nutritionFacts.setCaloriesValue(!isNaN(selectedRecipe.totalCalories) ? Math.round(selectedRecipe.totalCalories) + "Kcal" : ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available') );
				}
			}
		}
		
		private function updatePagination(paginationProperties:Object):void
		{
			if (foodDetailsTitleContainer != null) foodDetailsTitleContainer.x = 0;
			
			currentPage = paginationProperties.pageNumber;
			totalPages = paginationProperties.totalPages;
			
			paginationLabel.text = currentPage + "/" + totalPages;
			
			if (currentPage >= 100 && Constants.deviceModel == DeviceInfo.IPHONE_2G_3G_3GS_4_4S_ITOUCH_2_3_4 || Constants.deviceModel == DeviceInfo.IPHONE_5_5S_5C_SE_ITOUCH_5_6)
			{
				if (paginationLabel.fontStyles == null)
				{
					paginationLabel.fontStyles = new TextFormat("Roboto", 14, 0xEEEEEE, HorizontalAlign.CENTER, VerticalAlign.MIDDLE);
				}
				
				paginationLabel.fontStyles.size = 10;
			}
			else if (currentPage >= 10 && Constants.deviceModel == DeviceInfo.IPHONE_2G_3G_3GS_4_4S_ITOUCH_2_3_4 || Constants.deviceModel == DeviceInfo.IPHONE_5_5S_5C_SE_ITOUCH_5_6)
			{
				if (paginationLabel.fontStyles == null)
				{
					paginationLabel.fontStyles = new TextFormat("Roboto", 14, 0xEEEEEE, HorizontalAlign.CENTER, VerticalAlign.MIDDLE);
				}
				
				paginationLabel.fontStyles.size = 12;
			}
			else
			{
				if (paginationLabel.fontStyles == null)
				{
					paginationLabel.fontStyles = new TextFormat("Roboto", 14, 0xEEEEEE, HorizontalAlign.CENTER, VerticalAlign.MIDDLE);
				}
				
				paginationLabel.fontStyles.size = 14;
			}
			
			firstPageButton.focusManager = null;
			previousPageButton.focusManager = null;
			lastPageButton.focusManager = null;
			previousPageButton.focusManager = null;
			
			if (currentPage == 1)
			{
				firstPageButton.isEnabled = false;
				previousPageButton.isEnabled = false;
			}
			else
			{
				firstPageButton.isEnabled = true;
				previousPageButton.isEnabled = true;
			}
			
			if (currentPage == totalPages)
			{
				lastPageButton.isEnabled = false;
				nextPageButton.isEnabled = false;
			}
			else
			{
				lastPageButton.isEnabled = true;
				nextPageButton.isEnabled = true;
			}
			
			if (!firstPageButton.isEnabled && !previousPageButton.isEnabled && !lastPageButton.isEnabled && !nextPageButton.isEnabled)
				paginationLabel.isEnabled = false;
			else
				paginationLabel.isEnabled = true;
		}
		
		private function createDeleteButton():Button
		{
			var deleteButton:Button = new Button();
			var deleteButtonTexture:Texture = MaterialDeepGreyAmberMobileThemeIcons.deleteForeverTexture;
			var deleteButtonIcon:Image = new Image(deleteButtonTexture);
			deleteButton.defaultIcon = deleteButtonIcon;
			deleteButton.styleNameList.add( BaseMaterialDeepGreyAmberMobileTheme.THEME_STYLE_NAME_BUTTON_HEADER_QUIET_ICON_ONLY );
			deleteButton.scale = 0.8;
			deleteButton.pivotX = 20;
			deleteButton.addEventListener(Event.TRIGGERED, onDeleteFoodFromCart);
			
			//Save so it can be discarted later
			deleteButtonsList.push( { button: deleteButton, texture: deleteButtonTexture, icon: deleteButtonIcon } );
			
			return deleteButton;
		}
		
		private function resetComponents(resetPagination:Boolean = true, dontClearSearchResults:Boolean = false):void
		{
			if (foodDetailsTitleContainer != null) foodDetailsTitleContainer.x = 0;
			
			if (!dontClearSearchResults)
			{
				foodResultsList.dataProvider = new ArrayCollection([]);
				foodResultsList.selectedItem = null;
			}
			
			foodResultsList.selectedIndex = -1;
			foodDetailsContainer.removeFromParent();
			hidePreloader();
			removeFoodInserter();
			
			if (resetPagination)
			{
				currentPage = 1;
				totalPages = 1;
				paginationLabel.text = currentPage + "/" + totalPages;
				paginationLabel.isEnabled = false;
				firstPageButton.isEnabled = false;
				previousPageButton.isEnabled = false;
				nextPageButton.isEnabled = false;
				lastPageButton.isEnabled = false;
			}
		}
		
		private function resetComponentsExtended():void
		{
			searchInput.text = "";
		}
		
		private function showPreloader():void
		{
			preloader.visible = true;
			var suggestedIndex:int = basketPreloaderContainer.getChildIndex(basketSprite);
			basketPreloaderContainer.addChildAt(preloader, suggestedIndex);
			addFavorite.visible = false;
			addFavorite.removeFromParent();
			basketPreloaderContainer.readjustLayout();
			basketPreloaderContainer.validate();
			preloader.x += 15;
			preloader.y += 9;
			basketSprite.y += 5;
			(actionsContainer.layout as HorizontalLayout).paddingTop = -5;
		}
		
		private function hidePreloader():void
		{
			try
			{
				preloader.visible = false;
				preloader.removeFromParent();
				basketPreloaderContainer.readjustLayout();
				basketPreloaderContainer.validate();
				basketSprite.y += 5;
				(actionsContainer.layout as HorizontalLayout).paddingTop = 4;
			} 
			catch(error:Error) {}
		}
		
		private function showAddFavorite():void
		{
			if (foodDetailsTitleContainer != null) foodDetailsTitleContainer.x = 0;
			
			addFavorite.visible = true;
			var suggestedIndex:int = basketPreloaderContainer.getChildIndex(basketSprite);
			basketPreloaderContainer.addChildAt(addFavorite, suggestedIndex);
			preloader.visible = false;
			preloader.removeFromParent();
			basketPreloaderContainer.readjustLayout();
			basketPreloaderContainer.validate();
			basketSprite.y += 5;
		}
		
		private function hideAddFavorite():void
		{
			if (foodDetailsTitleContainer != null) foodDetailsTitleContainer.x = 0;
			
			addFavorite.visible = false;
			addFavorite.removeFromParent();
			basketPreloaderContainer.readjustLayout();
			basketPreloaderContainer.validate();
			basketSprite.y += 5;
		}
		
		private function removeFoodInserter():void
		{
			if (foodDetailsTitleContainer != null) foodDetailsTitleContainer.x = 0;
			
			if (foodInserter != null && foodInserter.parent != null)
			{
				foodInserter.removeEventListener(Event.COMPLETE, onAddManualFavoriteComplete);
				foodInserter.removeFromParent();
				foodInserter.dispose();
				foodInserter = null;
			}
			
			actionsContainer.addChild(finishButton);
			addFavorite.alpha = 1;
			addFavorite.addEventListener(TouchEvent.TOUCH, onAddManualFavorite);
		}
		
		private function removeFoodEventListeners():void
		{
			FoodAPIConnector.instance.removeEventListener(FoodEvent.FOOD_NOT_FOUND, onFoodOrRecipeNotFound);
			FoodAPIConnector.instance.removeEventListener(FoodEvent.FOODS_SEARCH_RESULT, onFoodsSearchResult);
			FoodAPIConnector.instance.removeEventListener(FoodEvent.FOOD_DETAILS_RESULT, onFoodDetailsReceived);
			FoodAPIConnector.instance.removeEventListener(FoodEvent.RECIPE_NOT_FOUND, onFoodOrRecipeNotFound);
			FoodAPIConnector.instance.removeEventListener(FoodEvent.RECIPES_SEARCH_RESULT, onRecipesSearchResult);
			FoodAPIConnector.instance.removeEventListener(FoodEvent.FOOD_SERVER_ERROR, onServerError);
		}
		
		private function jump( cart:Sprite, force:Number ):void {
			if( force < THRESHOLD ) return;
			
			var duration:Number = 0.3 * force;
			duration = (duration < 0.07) ? 0.07 : duration;
			
			Starling.juggler.tween(
				cart,
				duration,
				{
					transition: Transitions.EASE_OUT,
					y: cart.y - (90 * force)
				}
			);
			
			Starling.juggler.tween(
				cart,
				duration,
				{
					delay: duration,
					transition: Transitions.EASE_IN,
					y: cart.y,
					// Once it ends, jump again (bounce), this time a little lower
					onComplete: jump,
					onCompleteArgs: [cart, force * ELASTICITY]
				}
			);
		}
		
		private function recoverFromContextLost():void
		{
			renderTimoutID1 = setTimeout( function():void {
				SystemUtil.executeWhenApplicationIsActive(Starling.current.start);
			}, 100 );
			
			renderTimoutID2 = setTimeout( function():void {
				SystemUtil.executeWhenApplicationIsActive(Starling.current.start);
			}, 500 );
			
			renderTimoutID3 = setTimeout( function():void {
				SystemUtil.executeWhenApplicationIsActive(Starling.current.start);
			}, 1000 );
		}
		
		/**
		 * Event Handlers
		 */
		private function onAPIChanged(e:starling.events.Event):void
		{
			resetComponents();
			removeFoodEventListeners();
			hidePreloader();
			foodAmountInput.text = "";
			
			if (databaseAPISelector.selectedIndex == 0)
			{
				currentMode = FAVORITES_MODE;
				searchContainer.addChild(scanButton);
				searchInput.prompt = ModelLocator.resourceManagerInstance.getString('foodmanager','search_food_label');
				searchInput.text = "";
				showAddFavorite();
				getInitialFavorites();
			}
			if (databaseAPISelector.selectedIndex == 1)
			{
				currentMode = RECIPES_MODE;
				searchContainer.removeChild(scanButton);
				searchInput.prompt = ModelLocator.resourceManagerInstance.getString('foodmanager','search_recipe_label');
				searchInput.text = "";
				hideAddFavorite();
				getInitialRecipes();
			}
			else if (databaseAPISelector.selectedIndex == 2)
			{
				currentMode = FATSECRET_MODE;
				searchContainer.addChild(scanButton);
				searchInput.prompt = ModelLocator.resourceManagerInstance.getString('foodmanager','search_food_label');
				hideAddFavorite();
			}
			else if (databaseAPISelector.selectedIndex == 3)
			{
				currentMode = OPENFOODFACTS_MODE;
				searchContainer.addChild(scanButton);
				searchInput.prompt = ModelLocator.resourceManagerInstance.getString('foodmanager','search_food_label');
				hideAddFavorite();
			}
			else if (databaseAPISelector.selectedIndex == 4)
			{
				currentMode = USDA_MODE;
				searchContainer.addChild(scanButton);
				searchInput.prompt = ModelLocator.resourceManagerInstance.getString('foodmanager','search_food_label');
				hideAddFavorite();
			}
		}
		
		private function onPerformSearch(e:starling.events.Event = null, resetPagination:Boolean = true):void
		{
			FoodAPIConnector.instance.addEventListener(FoodEvent.FOODS_SEARCH_RESULT, onFoodsSearchResult);
			FoodAPIConnector.instance.addEventListener(FoodEvent.FOOD_NOT_FOUND, onFoodOrRecipeNotFound);
			FoodAPIConnector.instance.addEventListener(FoodEvent.FOOD_SERVER_ERROR, onServerError);
			FoodAPIConnector.instance.addEventListener(FoodEvent.RECIPES_SEARCH_RESULT, onRecipesSearchResult);
			FoodAPIConnector.instance.addEventListener(FoodEvent.RECIPE_NOT_FOUND, onFoodOrRecipeNotFound);
			resetComponents(resetPagination == true || (e != null && e.currentTarget is Button));
			searchBarCodeActive = false;
			
			if (currentMode == FAVORITES_MODE)
			{
				hidePreloader();
				FoodAPIConnector.favoritesSearchFood(searchInput.text, currentPage);
			}
			else if (currentMode == RECIPES_MODE)
			{
				hidePreloader();
				FoodAPIConnector.recipesSearch(searchInput.text, currentPage);
			}
			else if (currentMode == FATSECRET_MODE)
			{
				showPreloader();
				FoodAPIConnector.fatSecretSearchFood(searchInput.text, currentPage);
			}
			else if (currentMode == OPENFOODFACTS_MODE)
			{
				showPreloader();
				FoodAPIConnector.openFoodFactsSearchFood(searchInput.text, currentPage);
			}
			else if (currentMode == USDA_MODE)
			{
				showPreloader();
				FoodAPIConnector.usdaSearchFood(searchInput.text, currentPage);
			}
		}
		
		private function onFoodOrRecipeSelected(e:Event):void
		{
			if (foodDetailsTitleContainer != null) foodDetailsTitleContainer.x = 0;
			
			if (foodResultsList.selectedItem != null)
			{
				foodAmountInput.text = "";
				substractFiberCheck.isSelected = false;
				removeFoodInserter();
				
				var selectedFood:Food;
				var selectedRecipe:Recipe;
				
				if (currentMode == OPENFOODFACTS_MODE || currentMode == FAVORITES_MODE)
				{
					if (foodResultsList.selectedItem.food == null) return;
					
					selectedFood = foodResultsList.selectedItem.food;
					displayFoodDetails(selectedFood);
				}
				else if (currentMode == RECIPES_MODE)
				{
					if (foodResultsList.selectedItem.recipe == null) return;
					
					selectedRecipe = foodResultsList.selectedItem.recipe;
					displayRecipeDetails(selectedRecipe);
				}
				else if (currentMode == FATSECRET_MODE)
				{
					if (foodResultsList.selectedItem.food == null) return;
					
					selectedFood = foodResultsList.selectedItem.food;
					showPreloader();
					FoodAPIConnector.instance.addEventListener(FoodEvent.FOOD_DETAILS_RESULT, onFoodDetailsReceived);
					FoodAPIConnector.instance.addEventListener(FoodEvent.FOOD_NOT_FOUND, onFoodOrRecipeNotFound);
					FoodAPIConnector.instance.addEventListener(FoodEvent.FOOD_SERVER_ERROR, onServerError);
					FoodAPIConnector.fatSecretGetFoodDetails(selectedFood.id);
				}
				else if (currentMode == USDA_MODE)
				{
					if (foodResultsList.selectedItem.food == null) return;
					
					selectedFood = foodResultsList.selectedItem.food;
					showPreloader();
					FoodAPIConnector.instance.addEventListener(FoodEvent.FOOD_DETAILS_RESULT, onFoodDetailsReceived);
					FoodAPIConnector.instance.addEventListener(FoodEvent.FOOD_NOT_FOUND, onFoodOrRecipeNotFound);
					FoodAPIConnector.instance.addEventListener(FoodEvent.FOOD_SERVER_ERROR, onServerError);
					FoodAPIConnector.usdaGetFoodInfo(selectedFood.id);
				}
			}
		}
		
		private function onAddFoodOrRecipeAsFavorite(e:Event):void
		{
			/*if (currentMode == FATSECRET_MODE)
			{
				AlertManager.showActionAlert
					(
						"Warning",
						"Due to violation of FatSecret's Terms of Use, Spike can't save their nutritional data locally.",
						Number.NaN,
						[
							{ label: "Terms Of Use", triggered: onShowFSTermsOfUse },
							{ label: "OK" }
						]
					);
				
				function onShowFSTermsOfUse(e:Event = null):void
				{
					navigateToURL(new URLRequest("http://www.platform.fatsecret.com/api/Default.aspx?screen=tou"));
				}
				
				return;
			}*/
			
			if (foodDetailsTitleContainer != null) foodDetailsTitleContainer.x = 0;
			
			if (activeFood != null && currentMode != RECIPES_MODE)
			{
				Database.insertFoodSynchronous(activeFood);
				favoriteButton.removeFromParent();
				foodDetailsTitleContainer.addChild(unfavoriteButton);
				
				if (currentMode == FAVORITES_MODE)
				{
					foodDetailsTitleContainer.addChild(editfavoriteButton);
					foodDetailsTitleContainer.validate();
					editfavoriteButton.x -= 22;
					foodDetailsContainer.validate();
					foodDetailsTitleContainer.x = 20;
					
					FoodAPIConnector.instance.addEventListener(FoodEvent.FOODS_SEARCH_RESULT, onFoodsSearchResult);
					FoodAPIConnector.instance.addEventListener(FoodEvent.FOOD_NOT_FOUND, onFoodOrRecipeNotFound);
					
					dontClearSearchResults = true;
					
					FoodAPIConnector.favoritesSearchFood(searchInput.text, currentPage);
				}
			}
			else if (activeRecipe != null && currentMode == RECIPES_MODE)
			{
				Database.insertRecipeSynchronous(activeRecipe);
				favoriteButton.removeFromParent();
				foodDetailsTitleContainer.addChild(unfavoriteButton);
				
				FoodAPIConnector.instance.addEventListener(FoodEvent.RECIPES_SEARCH_RESULT, onRecipesSearchResult);
				FoodAPIConnector.instance.addEventListener(FoodEvent.RECIPE_NOT_FOUND, onFoodOrRecipeNotFound);
				
				dontClearSearchResults = true;
				
				FoodAPIConnector.recipesSearch(searchInput.text, currentPage);
			}
		}
		
		private function onRemoveFoodOrRecipeAsFavorite(e:Event):void
		{
			if (foodDetailsTitleContainer != null) foodDetailsTitleContainer.x = 0;
			
			if (activeFood != null && currentMode != RECIPES_MODE)
			{
				Database.deleteFoodSynchronous(activeFood);
				editfavoriteButton.removeFromParent();
				unfavoriteButton.removeFromParent();
				foodDetailsTitleContainer.addChild(favoriteButton);
				
				if (currentMode == FAVORITES_MODE)
				{
					FoodAPIConnector.instance.addEventListener(FoodEvent.FOODS_SEARCH_RESULT, onFoodsSearchResult);
					FoodAPIConnector.instance.addEventListener(FoodEvent.FOOD_NOT_FOUND, onFoodOrRecipeNotFound);
					
					dontClearSearchResults = true;
					
					FoodAPIConnector.favoritesSearchFood(searchInput.text, currentPage);
				}
			}
			else if (activeRecipe != null && currentMode == RECIPES_MODE)
			{
				Database.deleteRecipeSynchronous(activeRecipe);
				unfavoriteButton.removeFromParent();
				foodDetailsTitleContainer.addChild(favoriteButton);
				
				FoodAPIConnector.instance.addEventListener(FoodEvent.RECIPES_SEARCH_RESULT, onRecipesSearchResult);
				FoodAPIConnector.instance.addEventListener(FoodEvent.RECIPE_NOT_FOUND, onFoodOrRecipeNotFound);
				
				dontClearSearchResults = true;
				
				FoodAPIConnector.recipesSearch(searchInput.text, currentPage);
			}
		}
		
		private function onFoodsSearchResult(e:FoodEvent):void
		{
			//Reset variables
			removeFoodEventListeners();
			hidePreloader();
			if (foodDetailsTitleContainer != null) foodDetailsTitleContainer.x = 0;
			
			//Clear/reset components, unless a special contition has been met
			if (!dontClearSearchResults)
			{
				resetComponents();
				foodAmountInput.text = "";
			}
			
			if (e.foodsList != null)
			{
				//Populate foods list with results
				foodResultsList.dataProvider = new ArrayCollection(e.foodsList);
				
				//If we're in favorite mode and we favorite/unfavorite food, have the food list update and select accordingly
				if (dontClearSearchResults && activeFood != null)
				{
					var visibleFoods:Array = e.foodsList as Array;
					for (var i:int = 0; i < visibleFoods.length; i++) 
					{
						var food:Food = visibleFoods[i].food;
						if (food != null && food.id == activeFood.id)
						{
							foodResultsList.removeEventListener(Event.CHANGE, onFoodOrRecipeSelected);
							foodResultsList.selectedIndex = i;
							foodResultsList.addEventListener(Event.CHANGE, onFoodOrRecipeSelected);
							break;
						}
					}
					
				}
				else
				{
					if (searchBarCodeActive && e.foodsList.length == 1)
					{
						//We only have one result from the food scan. Select that food automatically.
						foodResultsList.selectedIndex = 0;
					}
				}
			}
			
			//Update pagination
			if (e.searchProperties != null)
			{
				updatePagination(e.searchProperties);
			}
			
			//Reset variables
			dontClearSearchResults = false;
			searchBarCodeActive = false;
		}
		
		private function onRecipesSearchResult(e:FoodEvent):void
		{
			//Reset variables
			removeFoodEventListeners();
			hidePreloader();
			if (foodDetailsTitleContainer != null) foodDetailsTitleContainer.x = 0;
			
			//Clear/reset components
			if (!dontClearSearchResults)
			{
				resetComponents();
				foodAmountInput.text = "";
			}
			
			if (e.recipesList != null)
			{
				//Populate recipes list with results
				foodResultsList.dataProvider = new ArrayCollection(e.recipesList);
			}
			
			//Update pagination
			if (e.searchProperties != null)
			{
				updatePagination(e.searchProperties);
			}
		}
		
		private function onFoodDetailsReceived(e:FoodEvent):void
		{
			if (foodDetailsTitleContainer != null) foodDetailsTitleContainer.x = 0;
			
			var food:Food = e.food;
			
			removeFoodEventListeners();
			hidePreloader();
			foodAmountInput.text = "";
			substractFiberCheck.isSelected = false;
			
			if (food != null)
				displayFoodDetails(food);
		}
		
		private function onFoodOrRecipeNotFound (e:FoodEvent):void
		{
			if (foodDetailsTitleContainer != null) foodDetailsTitleContainer.x = 0;
			removeFoodEventListeners();
			hidePreloader();
			searchBarCodeActive = false;
			
			foodResultsList.dataProvider = new ArrayCollection( [ { label: ModelLocator.resourceManagerInstance.getString('foodmanager','no_search_results_label') } ] );
		}
		
		private function onServerError (e:FoodEvent):void
		{
			if (foodDetailsTitleContainer != null) foodDetailsTitleContainer.x = 0;
			removeFoodEventListeners();
			hidePreloader();
			searchBarCodeActive = false;
			
			AlertManager.showSimpleAlert
			(
				ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
				e.errorMessage
			);
		}
		
		private function onAddManualFavorite(e:starling.events.TouchEvent):void
		{
			var touch:Touch = e.getTouch(stage);
			
			if(touch != null && touch.phase == TouchPhase.BEGAN) 
			{
				if (foodDetailsTitleContainer != null) foodDetailsTitleContainer.x = 0;
				
				foodDetailsContainer.removeFromParent();
				
				if (foodInserter != null) foodInserter.removeFromParent(true);
				foodInserter = new FoodInserter(width);
				foodInserter.addEventListener(Event.COMPLETE, onAddManualFavoriteComplete);
				var favoriteIndex:int = mainContentContainer.getChildIndex(mainActionsContainer);
				mainContentContainer.addChildAt(foodInserter, favoriteIndex);
				actionsContainer.removeChild(finishButton);
				addFavorite.alpha = 0.2;
				addFavorite.removeEventListener(TouchEvent.TOUCH, onAddManualFavorite);
			}
		}
		
		private function onEditFavorite(e:Event):void
		{
			if (foodDetailsTitleContainer != null) foodDetailsTitleContainer.x = 0;
			
			foodDetailsContainer.removeFromParent();
			
			if (foodInserter != null) foodInserter.removeFromParent(true);
			foodInserter = new FoodInserter(width, activeFood);
			foodInserter.addEventListener(Event.COMPLETE, onAddManualFavoriteComplete);
			var favoriteIndex:int = mainContentContainer.getChildIndex(mainActionsContainer);
			mainContentContainer.addChildAt(foodInserter, favoriteIndex);
			actionsContainer.removeChild(finishButton);
			addFavorite.alpha = 0.2;
			addFavorite.removeEventListener(TouchEvent.TOUCH, onAddManualFavorite);
		}
		
		private function onAddManualFavoriteComplete(e:Event):void
		{
			if (foodDetailsTitleContainer != null) foodDetailsTitleContainer.x = 0;
			
			foodInserter.removeEventListener(Event.COMPLETE, onAddManualFavoriteComplete);
			foodInserter.removeFromParent();
			foodInserter.dispose();
			foodInserter = null;
			
			actionsContainer.addChild(finishButton);
			addFavorite.alpha = 1;
			addFavorite.addEventListener(TouchEvent.TOUCH, onAddManualFavorite);
			
			if (currentMode == FAVORITES_MODE)
			{
				FoodAPIConnector.instance.addEventListener(FoodEvent.FOODS_SEARCH_RESULT, onFoodsSearchResult);
				FoodAPIConnector.instance.addEventListener(FoodEvent.FOOD_NOT_FOUND, onFoodOrRecipeNotFound);
				
				FoodAPIConnector.favoritesSearchFood(searchInput.text, currentPage);
			}
		}
		
		private function onSaveRecipe(e:Event):void
		{
			if (foodDetailsTitleContainer != null) foodDetailsTitleContainer.x = 0;
			
			//Variables
			var recipeName:String = "";
			var recipeServingSize:String = "";
			var recipeServingUnit:String = "";
			var recipeNotes:String = "";
			
			var contentLayout:VerticalLayout = new VerticalLayout();
			contentLayout.horizontalAlign = HorizontalAlign.CENTER;
			contentLayout.verticalAlign = VerticalAlign.TOP;
			contentLayout.gap = 10;
			contentLayout.paddingBottom = -25;
			var contentContainer:LayoutGroup = new LayoutGroup();
			contentContainer.layout = contentLayout;
			var recipeNameTextInput:TextInput = LayoutFactory.createTextInput(false, false, 250, HorizontalAlign.CENTER, false, false, false, true, true);
			recipeNameTextInput.prompt = ModelLocator.resourceManagerInstance.getString('foodmanager','name_label');
			recipeNameTextInput.addEventListener(Event.CHANGE, onRecipeNameChanged);
			contentContainer.addChild(recipeNameTextInput);
			
			var servingsContent:LayoutGroup = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.CENTER, VerticalAlign.MIDDLE, 10);
			var recipeServingSizeTextInput:TextInput = LayoutFactory.createTextInput(false, false, 120, HorizontalAlign.CENTER, true, false, false, true, true);
			recipeServingSizeTextInput.prompt = ModelLocator.resourceManagerInstance.getString('foodmanager','serving_size_label');
			recipeServingSizeTextInput.addEventListener(Event.CHANGE, onRecipeServingSizeChanged);
			servingsContent.addChild(recipeServingSizeTextInput);
			var recipeServingUnitTextInput:TextInput = LayoutFactory.createTextInput(false, false, 120, HorizontalAlign.CENTER, false, false, false, true, true);
			recipeServingUnitTextInput.prompt = ModelLocator.resourceManagerInstance.getString('foodmanager','serving_unit_label');
			recipeServingUnitTextInput.addEventListener(Event.CHANGE, onRecipeServingUnitChanged);
			servingsContent.addChild(recipeServingUnitTextInput);
			contentContainer.addChild(servingsContent);
			
			var notesTextInput:TextInput = LayoutFactory.createTextInput(false, false, 250, HorizontalAlign.CENTER, false, false, false, true, true);
			notesTextInput.prompt = "Notes";
			notesTextInput.addEventListener(Event.CHANGE, onRecipeNotesChanged);
			//contentContainer.addChild(notesTextInput);
			
			var actionsContainer:LayoutGroup = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.CENTER, VerticalAlign.TOP, 10);
			var cancelButton:Button = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('globaltranslations','cancel_button_label'));
			cancelButton.addEventListener(Event.TRIGGERED, onCancelRecipe);
			var saveButton:Button = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('globaltranslations','save_button_label'));
			saveButton.isEnabled = false;
			saveButton.addEventListener(Event.TRIGGERED, onSaveRecipe);
			actionsContainer.addChild(cancelButton);
			actionsContainer.addChild(saveButton);
			
			contentContainer.addChild(actionsContainer);
			
			var recipePopup:Alert = Alert.show("", ModelLocator.resourceManagerInstance.getString('foodmanager','add_recipe_label'), null, contentContainer, true, false);
			recipePopup.validate();
			recipePopup.x = ((Constants.stageWidth - recipePopup.width) / 2) + 5;
			recipePopup.y = 70;
			recipePopup.gap = 0;
			recipePopup.headerProperties.maxHeight = 30;
			recipeNameTextInput.setFocus();
			
			function onRecipeNameChanged(e:Event):void
			{
				var origin:TextInput = e.currentTarget as TextInput;
				if (origin == null)
					return;
				
				recipeName = origin.text;
				validateFields();
			}
			
			function onRecipeServingSizeChanged(e:Event):void
			{
				var origin:TextInput = e.currentTarget as TextInput;
				if (origin == null)
					return;
				
				recipeServingSize = origin.text;
				validateFields();
			}
			
			function onRecipeServingUnitChanged(e:Event):void
			{
				var origin:TextInput = e.currentTarget as TextInput;
				if (origin == null)
					return;
				
				recipeServingUnit = origin.text;
				validateFields();
			}
			
			function onRecipeNotesChanged(e:Event):void
			{
				var origin:TextInput = e.currentTarget as TextInput;
				if (origin == null)
					return;
				
				recipeNotes = origin.text;
				validateFields();
			}
			
			function validateFields():void
			{
				saveButton.isEnabled = recipeName == "" || recipeServingSize == "" || recipeServingUnit == "" ? false : true;
			}
			
			function onSaveRecipe(e:Event):void
			{
				disposeRecipeUI();
				
				if (cartList == null && cartList.length == 0)
					return;
				
				var recipeFoods:Array = [];
				
				for (var i:int = 0; i < cartList.length; i++) 
				{
					var cartItem:Object = cartList[i];
					var cartFood:Food = cartItem.food as Food;
					var quantity:Number = cartItem.quantity;
					var multiplier:Number = cartItem.multiplier;
					var substractFiber:Boolean = cartItem.substractFiber;
					var servingSize:Number = cartFood.servingSize;
					var servingUnit:String = cartFood.servingUnit;
					var globalUnit:String = cartItem.globalUnit;
					
					if (cartItem == null || cartFood == null)
						continue;
					
					if (multiplier != 1)
					{
						quantity = quantity * servingSize;
						servingUnit = globalUnit != null && globalUnit != "" ? globalUnit : servingUnit;
					}
					
					var food:Food = new Food
					(
						cartFood.id,
						cartFood.name,
						Math.round(((quantity / cartFood.servingSize) * cartFood.proteins * multiplier) * 100) / 100,
						Math.round(((quantity / cartFood.servingSize) * cartFood.carbs * multiplier) * 100) / 100,
						Math.round(((quantity / cartFood.servingSize) * cartFood.fats * multiplier) * 100) / 100,
						Math.round(((quantity / cartFood.servingSize) * cartFood.kcal * multiplier) * 100) / 100,
						cartItem.quantity,
						servingUnit,
						new Date().valueOf(),
						Math.round(((quantity / cartFood.servingSize) * cartFood.fiber * multiplier) * 100) / 100,
						cartFood.brand,
						cartFood.link,
						cartFood.source,
						cartFood.barcode,
						cartItem.substractFiber,
						Number(recipeServingSize),
						recipeServingUnit,
						"",
						multiplier == 1
					);
					
					recipeFoods.push(food);
				}
				
				var recipe:Recipe = new Recipe
				(
					null,
					recipeName,
					recipeServingSize,
					recipeServingUnit,
					recipeFoods,
					new Date().valueOf(),
					recipeNotes
				);
				
				//Add to database
				Database.insertRecipeSynchronous(recipe);
				
				//Refresh Recipes List
				FoodAPIConnector.instance.addEventListener(FoodEvent.RECIPES_SEARCH_RESULT, onRecipesSearchResult);
				FoodAPIConnector.instance.addEventListener(FoodEvent.RECIPE_NOT_FOUND, onFoodOrRecipeNotFound);
				
				FoodAPIConnector.recipesSearch(searchInput.text, currentPage);
			}
			
			function onCancelRecipe(e:Event):void
			{
				disposeRecipeUI();
			}
			
			function disposeRecipeUI():void
			{
				if (recipeNameTextInput != null)
				{
					recipeNameTextInput.removeFromParent();
					recipeNameTextInput.dispose();
					recipeNameTextInput = null;
				}
				
				if (recipeServingSizeTextInput != null)
				{
					recipeServingSizeTextInput.removeFromParent();
					recipeServingSizeTextInput.dispose();
					recipeServingSizeTextInput = null;
				}
				
				if (recipeServingUnitTextInput != null)
				{
					recipeServingUnitTextInput.removeFromParent();
					recipeServingUnitTextInput.dispose();
					recipeServingUnitTextInput = null;
				}
				
				if (notesTextInput != null)
				{
					notesTextInput.removeFromParent();
					notesTextInput.dispose();
					notesTextInput = null;
				}
				
				if (servingsContent != null)
				{
					servingsContent.removeFromParent();
					servingsContent.dispose();
					servingsContent = null;
				}
				
				if (contentContainer != null)
				{
					contentContainer.removeFromParent();
					contentContainer.dispose();
					contentContainer = null;
				}
				
				if (cancelButton != null)
				{
					cancelButton.removeEventListener(Event.TRIGGERED, onCancelRecipe);
					cancelButton.removeFromParent();
					cancelButton.dispose();
					cancelButton = null;
				}
				
				if (saveButton != null)
				{
					saveButton.removeEventListener(Event.TRIGGERED, onSaveRecipe);
					saveButton.removeFromParent();
					saveButton.dispose();
					saveButton = null;
				}
				
				if (actionsContainer != null)
				{
					actionsContainer.removeFromParent();
					actionsContainer.dispose();
					actionsContainer = null;
				}
				
				if (recipePopup != null)
				{
					recipePopup.removeFromParent();
					recipePopup.dispose();
					recipePopup = null;
				}
				
				if (basketCallout != null)
				{
					basketCallout.removeFromParent();
					basketCallout.dispose();
					basketCallout = null;
				}
			}
		}
		
		private function onFoodAmountChanged(e:Event):void
		{
			if (foodDetailsTitleContainer != null) foodDetailsTitleContainer.x = 0;
			
			addFoodButton.isEnabled = foodAmountInput.text != null && foodAmountInput.text.length > 0 ? true : false;
			
			if(foodAmountInput != null && activeFood != null && currentMode != RECIPES_MODE)
				updateFoodDetails(foodAmountInput.text != null && foodAmountInput.text.length > 0 ? Number(foodAmountInput.text) : globalMultiplier == 1 ? activeFood.servingSize : 1);
			else if (foodAmountInput != null && activeRecipe != null && currentMode == RECIPES_MODE)
				updateFoodDetails(foodAmountInput.text != null && foodAmountInput.text.length > 0 ? Number(foodAmountInput.text) : Number(activeRecipe.servingSize));
		}
		
		private function onFirstPage(e:Event):void
		{
			currentPage = 1;
			onPerformSearch(null, false);
		}
		
		private function onPreviousPage(e:Event):void
		{
			currentPage -= 1;
			onPerformSearch(null, false);
		}
		
		private function onNextPage(e:Event):void
		{
			currentPage += 1;
			onPerformSearch(null, false);
		}
		
		private function onLastPage(e:Event):void
		{
			currentPage = totalPages;
			onPerformSearch(null, false);
		}
		
		private function onAddFoodOrRecipe(e:starling.events.Event):void
		{
			if (foodDetailsTitleContainer != null) foodDetailsTitleContainer.x = 0;
			
			addFoodButton.isEnabled = false;
			
			if (currentMode != RECIPES_MODE)
			{
				if (activeFood == null) return;
				
				cartList.push( { food:activeFood, quantity: Number(foodAmountInput.text), servingUnit: activeFood.servingUnit, substractFiber: substractFiberCheck.isSelected, multiplier: globalMultiplier, globalUnit: globalUnit, id: UniqueId.createEventId() } );
			}
			else
			{
				for (var i:int = 0; i < activeRecipe.foods.length; i++) 
				{
					var recipeFood:Food = activeRecipe.foods[i];
					
					if (recipeFood == null) continue;
					
					cartList.push( { food:recipeFood, quantity: (Number(foodAmountInput.text) / Number(activeRecipe.servingSize)) * recipeFood.servingSize, servingUnit: recipeFood.servingUnit, substractFiber: recipeFood.substractFiber, multiplier: 1, globalUnit: "", id: UniqueId.createEventId() } );
				}
				
			}
			
			basketAmountLabel.text = String(cartList.length);
			jump(basketSprite, 0.4);
			
			setTimeout( function():void {
				addFoodButton.isEnabled = true;
			}, 750 );
		}
		
		private function onFoodLinkTriggered(e:Event):void
		{
			navigateToURL(new URLRequest(selectedFoodLink));
		}
		
		private function onDisplayBasket(e:starling.events.TouchEvent):void
		{
			var touch:Touch = e.getTouch(stage);
			
			if(touch != null && touch.phase == TouchPhase.BEGAN) 
			{
				if (cartList.length > 0)
				{
					populateBasketList();
					if (basketCallout != null) basketCallout.removeFromParent(true);
					basketCallout = Callout.show(basketList, basketSprite, new <String>[RelativePosition.LEFT]);
					basketCallout.disposeContent = false;
					basketCallout.disposeOnSelfClose = false;
					basketCallout.width = 262;
					basketCallout.maxWidth = 262;
					Callout.stagePaddingTop = Callout.stagePaddingBottom = 10;
					basketCallout.validate();
					basketCallout.addEventListener(Event.CLOSE, onBasketCalloutClosed);
				}
			}
		}
		
		private function onBasketCalloutClosed(e:Event):void
		{
			if (foodDetailsTitleContainer != null) foodDetailsTitleContainer.x = 0;
			
			for(var i:int = deleteButtonsList.length - 1 ; i >= 0; i--) 
			{
				var button:Button = deleteButtonsList[i].button;
				var icon:Image = deleteButtonsList[i].icon;
				var texture:Texture = deleteButtonsList[i].texture;
				var item:Object = deleteButtonsList[i];
				
				if (texture != null)
				{
					texture.dispose();
					texture = null;
				}
				
				if (icon != null)
				{
					icon.removeFromParent();
					icon.dispose();
					icon = null;
				}
				
				if (button != null)
				{
					button.addEventListener(Event.TRIGGERED, onDeleteFoodFromCart);
					button.removeFromParent();
					button.dispose();
					button = null;
				}
				
				item = null;
			}
			
			deleteButtonsList.length = 0;
		}
		
		private function onDeleteFoodFromCart(e:Event):void
		{
			var itemID:String = (((e.currentTarget as Button).parent as Object).data as Object).id;
			
			if (itemID != null)
			{
				//Delete from cart
				for (var i:int = 0; i < cartList.length; i++) 
				{
					var cartItem:Object = cartList[i] as Object;
					if (cartItem.id != null && cartItem.id == itemID)
					{
						cartList.removeAt(i);
						break;
					}
				}
				
				//Recreate the cart list
				populateBasketList();
				
				//Refresh cart counter
				basketAmountLabel.text = String(cartList.length);
				
				//Adjust callout if needed
				if (cartList.length == 0)
					basketCallout.close(true);
			}
		}
		
		private function onScan(e:starling.events.Event):void
		{
			try
			{
				if (Scanner.isSupported)
				{
					Scanner.service.addEventListener( AuthorisationEvent.CHANGED, onCameraAuthorization );
					switch (Scanner.service.authorisationStatus())
					{
						case AuthorisationStatus.NOT_DETERMINED:
						case AuthorisationStatus.SHOULD_EXPLAIN:
							// REQUEST ACCESS: This will display the permission dialog
							Scanner.service.requestAccess();
							return;
							
						case AuthorisationStatus.DENIED:
						case AuthorisationStatus.UNKNOWN:
						case AuthorisationStatus.RESTRICTED:
							// ACCESS DENIED: You should inform your user appropriately
							return;
							
						case AuthorisationStatus.AUTHORISED:
							scanFood();
							break;						
					}
				}
			}
			catch (e:Error)
			{
				trace( e );
			}
		}
		
		private function onBarcodeFound( event:ScannerEvent ):void
		{
			if (foodDetailsTitleContainer != null) foodDetailsTitleContainer.x = 0;
			
			//Remove scanner events
			Scanner.service.removeEventListener( ScannerEvent.CODE_FOUND, onBarcodeFound );
			Scanner.service.removeEventListener( ScannerEvent.CANCELLED, onScanCanceled );
			
			//Clear results list
			foodResultsList.selectedItem = null;
			foodResultsList.dataProvider = new ArrayCollection([]);
			
			//Force starling to render after context being lost by the camera overlay.
			recoverFromContextLost();
			
			if (int(event.symbologyType) == 9)
			{
				//TODO: Convert UPC-E to UPC-A and specify it as GTIN-13 number
			}
			
			//Get barcode
			var barCode:String = event.data != null ? String(event.data) : "";
			
			//Call corresponding API
			if (barCode != null && barCode != "")
			{
				FoodAPIConnector.instance.addEventListener(FoodEvent.FOODS_SEARCH_RESULT, onFoodsSearchResult);
				FoodAPIConnector.instance.addEventListener(FoodEvent.FOOD_NOT_FOUND, onFoodOrRecipeNotFound);
				FoodAPIConnector.instance.addEventListener(FoodEvent.FOOD_SERVER_ERROR, onServerError);
				
				searchBarCodeActive = true;
				
				if (currentMode == OPENFOODFACTS_MODE)
				{
					showPreloader();
					FoodAPIConnector.openFoodFactsSearchCode(barCode);
				}
				else if (currentMode == USDA_MODE)
				{
					showPreloader();
					FoodAPIConnector.usdaSearchFood(barCode, 1);
				}
				else if (currentMode == FATSECRET_MODE)
				{
					showPreloader();
					FoodAPIConnector.fatSecretSearchCode(barCode);
				}
				else if (currentMode == FAVORITES_MODE)
				{
					hidePreloader();
					FoodAPIConnector.favoritesSearchBarCode(barCode);
				}
			}
		}
		
		private function onScanCanceled( event:ScannerEvent ):void
		{
			if (foodDetailsTitleContainer != null) foodDetailsTitleContainer.x = 0;
			
			//Remove scanner events
			Scanner.service.removeEventListener( ScannerEvent.CODE_FOUND, onBarcodeFound );
			Scanner.service.removeEventListener( ScannerEvent.CANCELLED, onScanCanceled );
			
			//Clear results list
			foodResultsList.selectedItem = null;
			foodResultsList.dataProvider = new ArrayCollection([]);
			
			//Force starling to render after context being lost by the camera overlay.
			recoverFromContextLost();
		}
		
		private function onCameraAuthorization( event:AuthorisationEvent ):void
		{
			switch (event.status)
			{
				case AuthorisationStatus.SHOULD_EXPLAIN:
					// Should display a reason you need this feature
					break;
				
				case AuthorisationStatus.AUTHORISED:
					scanFood();
					break;
				
				case AuthorisationStatus.RESTRICTED:
				case AuthorisationStatus.DENIED:
					// ACCESS DENIED: You should inform your user appropriately
					break;
			}
		}
		
		private function onCompleteFoodManager(e:starling.events.Event):void
		{
			resetComponents(false, true);
			resetComponentsExtended();
			dispatchEventWith(starling.events.Event.COMPLETE);
		}
		
		override public function dispose():void
		{
			clearTimeout(autoSearchTimeoutID);
			removeFoodEventListeners();
			
			if (accessoryList != null)
			{
				for (var i:int = 0; i < accessoryList.length; i++) 
				{
					var button:Button = accessoryList[i];
					if (button != null)
					{
						button.removeEventListener(Event.TRIGGERED, onDeleteFoodFromCart);
						button.removeFromParent();
						if (button.defaultIcon != null)
						{
							if ((button.defaultIcon as Image).texture != null)
								(button.defaultIcon as Image).texture.dispose();
							
							button.defaultIcon.dispose();
						}
						button.dispose();
						button = null;
					}
				}
				accessoryList.length = 0;
				accessoryList = null;
			}
			
			if (title != null)
			{
				title.removeFromParent();
				title.dispose();
				title = null;
			}
			
			if (databaseAPISelector != null)
			{
				databaseAPISelector.removeEventListener(starling.events.Event.CHANGE, onAPIChanged);
				databaseAPISelector.removeFromParent();
				databaseAPISelector.dispose();
				databaseAPISelector = null;
			}
			
			if (searchInput != null)
			{
				searchInput.removeEventListener(Event.CHANGE, onSearchInputChanged);
				searchInput.removeFromParent();
				searchInput.dispose();
				searchInput = null;
			}
			
			if (searchButton != null)
			{
				searchButton.removeEventListener(starling.events.Event.TRIGGERED, onPerformSearch);
				searchButton.removeFromParent();
				searchButton.dispose();
				searchButton = null;
			}
			
			if (scanButton != null)
			{
				scanButton.removeEventListener(starling.events.Event.TRIGGERED, onScan);
				scanButton.removeFromParent();
				scanButton.dispose();
				scanButton = null;
			}
			
			if (foodResultsList != null)
			{
				foodResultsList.removeEventListener(Event.CHANGE, onFoodOrRecipeSelected);
				foodResultsList.removeFromParent();
				foodResultsList.dispose();
				foodResultsList = null;
			}
			
			if (paginationLabel != null)
			{
				paginationLabel.removeFromParent();
				paginationLabel.dispose();
				paginationLabel = null;
			}
			
			if (firstPageButton != null)
			{
				firstPageButton.removeEventListener(Event.TRIGGERED, onFirstPage);
				firstPageButton.removeFromParent();
				firstPageButton.dispose();
				firstPageButton = null;
			}
			
			if (previousPageButton != null)
			{
				previousPageButton.removeEventListener(Event.TRIGGERED, onPreviousPage);
				previousPageButton.removeFromParent();
				previousPageButton.dispose();
				previousPageButton = null;
			}
			
			if (nextPageButton != null)
			{
				nextPageButton.removeEventListener(Event.TRIGGERED, onNextPage);
				nextPageButton.removeFromParent();
				nextPageButton.dispose();
				nextPageButton = null;
			}
			
			if (lastPageButton != null)
			{
				lastPageButton.removeEventListener(Event.TRIGGERED, onLastPage);
				lastPageButton.removeFromParent();
				lastPageButton.dispose();
				lastPageButton = null;
			}
			
			if (foodServingSizePickerList != null)
			{
				foodServingSizePickerList.removeEventListener(Event.CHANGE, onServingChanged);
				foodServingSizePickerList.removeFromParent();
				foodServingSizePickerList.dispose();
				foodServingSizePickerList = null;
			}
			
			if (addFavorite != null)
			{
				addFavorite.removeEventListener(TouchEvent.TOUCH, onAddManualFavorite);
				addFavorite.removeFromParent();
				addFavorite.dispose();
				addFavorite = null;
			}
			
			if (addFavoriteImage != null)
			{
				addFavoriteImage.removeFromParent();
				if (addFavoriteImage.texture != null)
					addFavoriteImage.texture.dispose();
				addFavoriteImage.dispose();
				addFavoriteImage = null;
			}
			
			if (addFavoriteBackground != null)
			{
				addFavoriteBackground.removeFromParent();
				addFavoriteBackground.dispose();
				addFavoriteBackground = null;
			}
			
			if (addFavoriteHitArea != null)
			{
				addFavoriteHitArea.removeFromParent();
				addFavoriteHitArea.dispose();
				addFavoriteHitArea = null;
			}
			
			if (preloader != null)
			{
				preloader.removeFromParent();
				preloader.dispose();
				preloader = null;
			}
			
			if (basketSprite != null)
			{
				basketSprite.removeEventListener(TouchEvent.TOUCH, onDisplayBasket);
				basketSprite.removeFromParent();
				basketSprite.dispose();
				basketSprite = null;
			}
			
			if (basketImage != null)
			{
				basketImage.removeFromParent();
				if (basketImage.texture != null)
					basketImage.texture.dispose();
				basketImage.dispose();
				basketImage = null;
			}
			
			if (basketAmountLabel != null)
			{
				basketAmountLabel.removeFromParent();
				basketAmountLabel.dispose();
				basketAmountLabel = null;
			}
			
			if (basketHitArea != null)
			{
				basketHitArea.removeFromParent();
				basketHitArea.dispose();
				basketHitArea = null;
			}
			
			if (cartTotals != null)
			{
				cartTotals.removeFromParent();
				cartTotals.dispose();
				cartTotals = null;
			}
			
			if (basketList != null)
			{
				basketList.removeFromParent();
				basketList.dispose();
				basketList = null;
			}
			
			if (saveRecipe != null)
			{
				saveRecipe.removeEventListener(Event.TRIGGERED, onSaveRecipe);
				saveRecipe.removeFromParent();
				saveRecipe.dispose();
				saveRecipe = null;
			}
			
			if (foodDetailsTitle != null)
			{
				foodDetailsTitle.removeFromParent();
				foodDetailsTitle.dispose();
				foodDetailsTitle = null;
			}
			
			if (favoriteButton != null)
			{
				favoriteButton.removeEventListener(Event.TRIGGERED, onAddFoodOrRecipeAsFavorite);
				favoriteButton.removeFromParent();
				favoriteButton.dispose();
				favoriteButton = null;
			}
			
			if (unfavoriteButton != null)
			{
				unfavoriteButton.removeEventListener(Event.TRIGGERED, onRemoveFoodOrRecipeAsFavorite);
				unfavoriteButton.removeFromParent();
				unfavoriteButton.dispose();
				unfavoriteButton = null;
			}
			
			if (editfavoriteButton != null)
			{
				editfavoriteButton.removeEventListener(Event.TRIGGERED, onEditFavorite);
				editfavoriteButton.removeFromParent();
				editfavoriteButton.dispose();
				editfavoriteButton = null;
			}
			
			if (foodAmountInput != null)
			{
				foodAmountInput.removeEventListener(Event.CHANGE, onFoodAmountChanged);
				foodAmountInput.removeFromParent();
				foodAmountInput.dispose();
				foodAmountInput = null;
			}
			
			if (addFoodButton != null)
			{
				addFoodButton.removeEventListener(starling.events.Event.TRIGGERED, onAddFoodOrRecipe);
				addFoodButton.removeFromParent();
				addFoodButton.dispose();
				addFoodButton = null;
			}
			
			if (substractFiberCheck != null)
			{
				substractFiberCheck.removeFromParent();
				substractFiberCheck.dispose();
				substractFiberCheck = null;
			}
			
			if (foodLink != null)
			{
				foodLink.removeEventListener(Event.TRIGGERED, onFoodLinkTriggered);
				foodLink.removeFromParent();
				foodLink.dispose();
				foodLink = null;
			}
			
			if (nutritionFacts != null)
			{
				nutritionFacts.removeFromParent();
				nutritionFacts.dispose();
				nutritionFacts = null;
			}
			
			if (finishButton != null)
			{
				finishButton.removeEventListener(Event.TRIGGERED, onCompleteFoodManager);
				finishButton.removeFromParent();
				finishButton.dispose();
				finishButton = null;
			}
			
			if (instructionsButton != null)
			{
				instructionsButton.removeEventListener(Event.TRIGGERED, onInstructionsTriggered);
				instructionsButton.removeFromParent();
				instructionsButton.dispose();
				instructionsButton = null;
			}
			
			if (foodInserter != null)
			{
				foodInserter.removeEventListener(Event.COMPLETE, onAddManualFavoriteComplete);
				foodInserter.removeFromParent();
				foodInserter.dispose();
				foodInserter = null;
			}
			
			if (actionsContainer != null)
			{
				actionsContainer.removeFromParent();
				actionsContainer.dispose();
				actionsContainer = null;
			}
			
			if (mainActionsContainer != null)
			{
				mainActionsContainer.removeFromParent();
				mainActionsContainer.dispose();
				mainActionsContainer = null;
			}
			
			if (addFoodContainer != null)
			{
				addFoodContainer.removeFromParent();
				addFoodContainer.dispose();
				addFoodContainer = null;
			}
			
			if (foodDetailsTitleContainer != null)
			{
				foodDetailsTitleContainer.removeFromParent();
				foodDetailsTitleContainer.dispose();
				foodDetailsTitleContainer = null;
			}
			
			if (foodDetailsContainer != null)
			{
				foodDetailsContainer.removeFromParent();
				foodDetailsContainer.dispose();
				foodDetailsContainer = null;
			}
			
			if (basketPreloaderContainer != null)
			{
				basketPreloaderContainer.removeFromParent();
				basketPreloaderContainer.dispose();
				basketPreloaderContainer = null;
			}
			
			if (paginationContainer != null)
			{
				paginationContainer.removeFromParent();
				paginationContainer.dispose();
				paginationContainer = null;
			}
			
			if (footerContainer != null)
			{
				footerContainer.removeFromParent();
				footerContainer.dispose();
				footerContainer = null;
			}
			
			if (searchContainer != null)
			{
				searchContainer.removeFromParent();
				searchContainer.dispose();
				searchContainer = null;
			}
			
			if (mainContentContainer != null)
			{
				mainContentContainer.removeFromParent();
				mainContentContainer.dispose();
				mainContentContainer = null;
			}
			
			super.dispose();
		}
	}
}