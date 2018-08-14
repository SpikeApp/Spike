package treatments.ui
{
	import com.distriqt.extension.scanner.AuthorisationStatus;
	import com.distriqt.extension.scanner.Scanner;
	import com.distriqt.extension.scanner.ScannerOptions;
	import com.distriqt.extension.scanner.Symbology;
	import com.distriqt.extension.scanner.events.AuthorisationEvent;
	import com.distriqt.extension.scanner.events.ScannerEvent;
	
	import flash.geom.Rectangle;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.utils.setTimeout;
	
	import mx.utils.ObjectUtil;
	
	import distriqtkey.DistriqtKey;
	
	import events.FoodEvent;
	
	import feathers.controls.Button;
	import feathers.controls.Callout;
	import feathers.controls.Label;
	import feathers.controls.LayoutGroup;
	import feathers.controls.List;
	import feathers.controls.PickerList;
	import feathers.controls.ScrollContainer;
	import feathers.controls.ScrollPolicy;
	import feathers.controls.TextInput;
	import feathers.controls.popups.DropDownPopUpContentManager;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.controls.text.TextFieldTextRenderer;
	import feathers.core.ITextRenderer;
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
	import starling.display.DisplayObject;
	import starling.display.Image;
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.textures.Texture;
	import starling.utils.SystemUtil;
	
	import treatments.Food;
	import treatments.Insulin;
	import treatments.network.FoodAPIConnector;
	
	import ui.popups.AlertManager;
	import ui.screens.display.LayoutFactory;
	import ui.screens.display.settings.treatments.TreatmentManagerAccessory;

	public class SpikeFoodSearcher extends LayoutGroup
	{
		//CONSTANTS
		private static const ELASTICITY:Number = 0.6;
		private static const THRESHOLD:Number = 0.1;
		
		//MODES
		private static const FAVOURITES_MODE:String = "favourites";
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
		private var servingsContainer:LayoutGroup;
		private var servingSizeLabel:Label;
		private var servingUnitLabel:Label;
		private var carbsContainer:LayoutGroup;
		private var carbsLabel:Label;
		private var fiberLabel:Label;
		private var mainContentContainer:ScrollContainer;
		private var foodDetailsTitle:Label;
		private var proteinsFatsContainer:LayoutGroup;
		private var proteinsLabel:Label;
		private var fatsLabel:Label;
		private var caloriesLinkContainer:LayoutGroup;
		private var caloriesLabel:Label;
		private var foodLink:Button;
		private var foodActionContainer:LayoutGroup;
		private var foodAmountLabel:Label;
		private var foodAmountInput:TextInput;
		private var basketPreloaderContainer:LayoutGroup;
		private var basketAmountLabel:Label;
		private var basketSprite:Sprite;
		private var basketImage:Image;
		private var preloader:MaterialDesignSpinner;
		private var basketCallout:Callout;
		private var basketHitArea:Quad;
		
		//PROPERTIES
		private var currentMode:String = "";
		private var renderTimoutID1:uint;
		private var renderTimoutID2:uint;
		private var renderTimoutID3:uint;
		private var containerHeight:Number;
		private var selectedFoodLink:String;
		public var cartList:Array;
		private var activeFood:Food;
		private var basketList:List;
		private var deleteButtonsList:Array = [];

		public function SpikeFoodSearcher(width:Number, containerHeight:Number)
		{
			this.width = width + 10;
			this.containerHeight = containerHeight;
			
			setupProperties();
			createContent(); 
		}
		
		private function setupProperties():void
		{
			this.layout = new VerticalLayout();
			this.cartList = [];
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
			mainContentContainer.verticalScrollPolicy = ScrollPolicy.AUTO;
			mainContentContainer.layout = mainLayout;
			addChild(mainContentContainer);
			
			//Title
			title = LayoutFactory.createLabel("Food Manager", HorizontalAlign.CENTER, VerticalAlign.TOP, 18, true);
			title.width = width;
			mainContentContainer.addChild(title);
			
			//Search Controls
			databaseAPISelector = LayoutFactory.createPickerList();
			databaseAPISelector.dataProvider = new ArrayCollection
				(
					[
						{ label: "Favourites" },
						{ label: "FatSecret" },
						{ label: "Open Food Facts" },
						{ label: "USDA" },
					]
				);
			databaseAPISelector.labelField = "label";
			databaseAPISelector.popUpContentManager = new DropDownPopUpContentManager();
			databaseAPISelector.addEventListener(starling.events.Event.CHANGE, onAPIChanged);
			mainContentContainer.addChild(databaseAPISelector);
			
			searchContainer = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.CENTER, VerticalAlign.MIDDLE, 5);
			searchContainer.width = width;
			mainContentContainer.addChild(searchContainer);
			
			searchInput = LayoutFactory.createTextInput(false, false, width/2, HorizontalAlign.CENTER, false, false, false, false, true);
			searchInput.prompt = "Search Food";
			searchContainer.addChild(searchInput);
			
			searchButton = LayoutFactory.createButton("Go");
			searchButton.addEventListener(starling.events.Event.TRIGGERED, onPerformSearch);
			searchContainer.addChild(searchButton);
			
			scanButton = LayoutFactory.createButton("Scan");
			scanButton.addEventListener(starling.events.Event.TRIGGERED, onScan);
			searchContainer.addChild(scanButton);
			
			//Results List
			foodResultsList = new List();
			var resultsLayout:VerticalLayout = new VerticalLayout();
			resultsLayout.hasVariableItemDimensions = true;
			foodResultsList.layout = resultsLayout;
			foodResultsList.width = width;
			foodResultsList.maxWidth = width;
			foodResultsList.height = 150;
			foodResultsList.addEventListener(Event.CHANGE, onFoodSelected);
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
			
			//Basket & Preloader Container
			basketPreloaderContainer = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.RIGHT, VerticalAlign.TOP);
			basketPreloaderContainer.width = width;
			mainContentContainer.addChild(basketPreloaderContainer);
			
			//Preloader
			preloader = new MaterialDesignSpinner();
			preloader.color = 0x0086FF;
			preloader.touchable = false;
			preloader.scale = 0.4;
			preloader.validate();
			preloader.visible = false;
			basketPreloaderContainer.addChild(preloader);
			
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
			preloader.y += 4;
			
			basketList = new List();
			basketList.layout = new VerticalLayout();
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
				item.width = 220;
				item.accessoryOffsetX = -20;
				item.paddingRight = -20;
				
				return item;
			};
			
			//Food Details
			foodDetailsContainer = LayoutFactory.createLayoutGroup("vertical", HorizontalAlign.CENTER, VerticalAlign.TOP, 5);
			foodDetailsContainer.width = width;
			foodDetailsContainer.maxWidth = width;
			(foodDetailsContainer.layout as VerticalLayout).paddingBottom = 10;
			(foodDetailsContainer.layout as VerticalLayout).paddingTop = -45;
			
			foodDetailsTitle = LayoutFactory.createLabel("Nutrition Facts", HorizontalAlign.CENTER, VerticalAlign.TOP, 16, true);
			foodDetailsTitle.touchable = false;
			foodDetailsTitle.paddingTop = foodDetailsTitle.paddingBottom = 10;
			foodDetailsTitle.width = width;
			foodDetailsContainer.addChild(foodDetailsTitle);
			
			foodActionContainer = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.CENTER, VerticalAlign.MIDDLE, 5);
			(foodActionContainer.layout as HorizontalLayout).paddingBottom = 10;
			(foodActionContainer.layout as HorizontalLayout).paddingTop = -3;
			foodActionContainer.width = width;
			foodActionContainer.maxWidth = width;
			foodDetailsContainer.addChild(foodActionContainer);
			
			foodAmountLabel = LayoutFactory.createLabel("Amount:", HorizontalAlign.RIGHT);
			foodActionContainer.addChild(foodAmountLabel);
			
			foodAmountInput = LayoutFactory.createTextInput(false, false, 60, HorizontalAlign.CENTER, true);
			foodAmountInput.addEventListener(Event.CHANGE, onFoodAmountChanged);
			foodAmountInput.height = 25;
			foodActionContainer.addChild(foodAmountInput);
			
			addFoodButton = LayoutFactory.createButton("Add");
			addFoodButton.height = 29;
			addFoodButton.paddingLeft = addFoodButton.paddingRight = 8;
			addFoodButton.addEventListener(starling.events.Event.TRIGGERED, onAdd);
			foodActionContainer.addChild(addFoodButton);
			foodActionContainer.validate();
			addFoodButton.y += 1;
			
			servingsContainer = LayoutFactory.createLayoutGroup("horizontal");
			servingsContainer.width = width;
			servingsContainer.maxWidth = width;
			foodDetailsContainer.addChild(servingsContainer);
			
			servingSizeLabel = LayoutFactory.createLabel("");
			servingSizeLabel.paddingLeft = 5;
			servingSizeLabel.width = width/2;
			servingsContainer.addChild(servingSizeLabel);
			
			servingUnitLabel = LayoutFactory.createLabel("");
			servingUnitLabel.paddingLeft = 5;
			servingUnitLabel.width = width/2;
			servingsContainer.addChild(servingUnitLabel);
			
			carbsContainer = LayoutFactory.createLayoutGroup("horizontal");
			carbsContainer.width = width;
			carbsContainer.maxWidth = width;
			foodDetailsContainer.addChild(carbsContainer);
			
			carbsLabel = LayoutFactory.createLabel("");
			carbsLabel.paddingLeft = 5;
			carbsLabel.width = width/2;
			carbsContainer.addChild(carbsLabel);
			
			fiberLabel = LayoutFactory.createLabel("");
			fiberLabel.paddingLeft = 5;
			fiberLabel.width = width/2;
			carbsContainer.addChild(fiberLabel);
			
			proteinsFatsContainer = LayoutFactory.createLayoutGroup("horizontal");
			proteinsFatsContainer.width = width;
			proteinsFatsContainer.maxWidth = width;
			foodDetailsContainer.addChild(proteinsFatsContainer);
			
			proteinsLabel = LayoutFactory.createLabel("");
			proteinsLabel.paddingLeft = 5;
			proteinsLabel.width = width/2;
			proteinsFatsContainer.addChild(proteinsLabel);
			
			fatsLabel = LayoutFactory.createLabel("");
			fatsLabel.paddingLeft = 5;
			fatsLabel.width = width/2;
			proteinsFatsContainer.addChild(fatsLabel);
			
			caloriesLinkContainer = LayoutFactory.createLayoutGroup("horizontal");
			caloriesLinkContainer.width = width;
			caloriesLinkContainer.maxWidth = width;
			foodDetailsContainer.addChild(caloriesLinkContainer);
			
			caloriesLabel = LayoutFactory.createLabel("Calories: N/A");
			caloriesLabel.paddingLeft = 5;
			caloriesLabel.width = width/2;
			caloriesLabel.validate();
			caloriesLinkContainer.addChild(caloriesLabel);
			
			foodLink = LayoutFactory.createButton("External Link", true);
			foodLink.paddingLeft = foodLink.paddingRight = 4;
			foodLink.height = caloriesLabel.height + 4;
			foodLink.addEventListener(Event.TRIGGERED, onFoodLinkTriggered);
			caloriesLinkContainer.addChild(foodLink);
			caloriesLinkContainer.validate();
			foodLink.x += 3;
			caloriesLabel.text = "";
			
			//Actions
			actionsContainer = LayoutFactory.createLayoutGroup("horizontal", HorizontalAlign.CENTER, VerticalAlign.TOP, 5);
			actionsContainer.width = width;
			mainContentContainer.addChild(actionsContainer);
			
			finishButton = LayoutFactory.createButton("Finish");
			finishButton.addEventListener(starling.events.Event.TRIGGERED, onFinish);
			actionsContainer.addChild(finishButton);
		}
		
		/**
		 * Event Handlers
		 */
		private function onFoodAmountChanged(e:Event):void
		{
			addFoodButton.isEnabled = foodAmountInput.text != null && foodAmountInput.text.length > 0 ? true : false;	
		}
		
		private function onDisplayBasket(e:starling.events.TouchEvent):void
		{
			var touch:Touch = e.getTouch(stage);
			
			if(touch != null && touch.phase == TouchPhase.BEGAN) 
			{
				if (cartList.length > 0)
				{
					populateBasketList();
					basketCallout = Callout.show(basketList, basketSprite, new <String>[RelativePosition.LEFT]);
					basketCallout.disposeContent = false;
					basketCallout.disposeOnSelfClose = true;
					basketCallout.addEventListener(Event.CLOSE, onBasketCalloutClosed);
				}
			}
		}
		
		private function onBasketCalloutClosed(e:Event):void
		{
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
		
		private function populateBasketList():void
		{
			var cartData:Array = [];
			
			for (var i:int = 0; i < cartList.length; i++) 
			{
				var cartItem:Object = cartList[i];
				cartData.push( { label: cartItem.quantity + cartItem.servingUnit + " " + (cartItem.food as Food).name, accessory: createDeleteButton(), food: cartItem.food, quantity: cartItem.quantity, servingUnit: cartItem.servingUnit } );
			}
			
			basketList.dataProvider = new ArrayCollection( cartData );
		}
		
		private function createDeleteButton():Button
		{
			var deleteButton:Button = new Button();
			var deleteButtonTexture:Texture = MaterialDeepGreyAmberMobileThemeIcons.deleteForeverTexture;
			var deleteButtonIcon:Image = new Image(deleteButtonTexture);
			deleteButton.defaultIcon = deleteButtonIcon;
			deleteButton.styleNameList.add( BaseMaterialDeepGreyAmberMobileTheme.THEME_STYLE_NAME_BUTTON_HEADER_QUIET_ICON_ONLY );
			deleteButton.scale = 0.8;
			deleteButton.addEventListener(Event.TRIGGERED, onDeleteFoodFromCart);
			
			//Save so it can be discarted later
			deleteButtonsList.push( { button: deleteButton, texture: deleteButtonTexture, icon: deleteButtonIcon } );
			
			return deleteButton;
		}
		
		private function onDeleteFoodFromCart(e:Event):void
		{
			var foodToDelete:Food = (((e.currentTarget as Button).parent as Object).data as Object).food as Food;
			var quantityToDelete:Number = Number((((e.currentTarget as Button).parent as Object).data as Object).quantity);
			var servingUnitToDelete:String = (((e.currentTarget as Button).parent as Object).data as Object).servingUnit as String;
			
			if (foodToDelete != null)
			{
				//Delete from cart
				for (var i:int = 0; i < cartList.length; i++) 
				{
					var cartItem:Object = cartList[i] as Object;
					if ((cartItem.food as Food).id == foodToDelete.id && cartItem.quantity == quantityToDelete && cartItem.servingUnit == servingUnitToDelete)
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
		
		private function onFoodLinkTriggered(e:Event):void
		{
			navigateToURL(new URLRequest(selectedFoodLink));
		}
		
		private function resetComponents():void
		{
			foodResultsList.dataProvider = new ArrayCollection([]);
			foodResultsList.selectedItem = null;
			foodDetailsContainer.removeFromParent();
		}
		
		private function clearCart():void
		{
			
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
		
		private function onAPIChanged(e:starling.events.Event):void
		{
			resetComponents();
			removeFoodEventListeners();
			preloader.visible = false;
			foodAmountInput.text = "";
			
			if (databaseAPISelector.selectedIndex == 0)
				currentMode = FAVOURITES_MODE;
			else if (databaseAPISelector.selectedIndex == 1)
				currentMode = FATSECRET_MODE;
			else if (databaseAPISelector.selectedIndex == 2)
				currentMode = OPENFOODFACTS_MODE;
			else if (databaseAPISelector.selectedIndex == 3)
				currentMode = USDA_MODE;
		}
		
		private function onPerformSearch(e:starling.events.Event):void
		{
			FoodAPIConnector.instance.addEventListener(FoodEvent.FOODS_SEARCH_RESULT, onFoodsSearchResult);
			FoodAPIConnector.instance.addEventListener(FoodEvent.FOOD_NOT_FOUND, onFoodNotFound);
			FoodAPIConnector.instance.addEventListener(FoodEvent.FOOD_SERVER_ERROR, onServerError);
			resetComponents();
			
			preloader.visible = true;
			
			if (currentMode == FAVOURITES_MODE)
			{
				
			}
			else if (currentMode == FATSECRET_MODE)
			{
				FoodAPIConnector.fatSecretSearchFood(searchInput.text);
			}
			else if (currentMode == OPENFOODFACTS_MODE)
			{
				FoodAPIConnector.openFoodFactsSearchFood(searchInput.text);
			}
			else if (currentMode == USDA_MODE)
			{
				FoodAPIConnector.usdaSearchFood(searchInput.text);
			}
		}
		
		private function removeFoodEventListeners():void
		{
			FoodAPIConnector.instance.removeEventListener(FoodEvent.FOOD_NOT_FOUND, onFoodNotFound);
			FoodAPIConnector.instance.removeEventListener(FoodEvent.FOODS_SEARCH_RESULT, onFoodsSearchResult);
			FoodAPIConnector.instance.removeEventListener(FoodEvent.FOOD_DETAILS_RESULT, onFoodDetailsReceived);
			FoodAPIConnector.instance.removeEventListener(FoodEvent.FOOD_SERVER_ERROR, onServerError);
		}
		
		private function onFoodNotFound (e:FoodEvent):void
		{
			removeFoodEventListeners();
			preloader.visible = false;
			
			foodResultsList.dataProvider = new ArrayCollection( [ { label: "No results!" } ] );
		}
		
		private function onServerError (e:FoodEvent):void
		{
			removeFoodEventListeners();
			preloader.visible = false;
			
			AlertManager.showSimpleAlert
			(
				"Warning",
				e.errorMessage
			);
		}
		
		private function onFoodSelected(e:Event):void
		{
			if (foodResultsList.selectedItem != null && foodResultsList.selectedItem.food != null)
			{
				foodAmountInput.text = "";
				
				var selectedFood:Food = foodResultsList.selectedItem.food;
				
				if (currentMode == OPENFOODFACTS_MODE)
				{
					displayFoodDetails(selectedFood);
				}
				else if (currentMode == FATSECRET_MODE)
				{
					preloader.visible = true;
					FoodAPIConnector.instance.addEventListener(FoodEvent.FOOD_DETAILS_RESULT, onFoodDetailsReceived);
					FoodAPIConnector.instance.addEventListener(FoodEvent.FOOD_NOT_FOUND, onFoodNotFound);
					FoodAPIConnector.instance.addEventListener(FoodEvent.FOOD_SERVER_ERROR, onServerError);
					FoodAPIConnector.fatSecretGetFoodDetails(selectedFood.id);
				}
				else if (currentMode == USDA_MODE)
				{
					preloader.visible = true;
					FoodAPIConnector.instance.addEventListener(FoodEvent.FOOD_DETAILS_RESULT, onFoodDetailsReceived);
					FoodAPIConnector.instance.addEventListener(FoodEvent.FOOD_NOT_FOUND, onFoodNotFound);
					FoodAPIConnector.instance.addEventListener(FoodEvent.FOOD_SERVER_ERROR, onServerError);
					FoodAPIConnector.usdaGetFoodInfo(selectedFood.id);
				}
			}
		}
		
		private function onFoodDetailsReceived(e:FoodEvent):void
		{
			removeFoodEventListeners();
			preloader.visible = false;
			foodAmountInput.text = "";
			
			var food:Food = e.food;
			
			if (food != null)
				displayFoodDetails(food);
		}
		
		private function displayFoodDetails(selectedFood:Food):void
		{
			onFoodAmountChanged(null);
			activeFood = selectedFood;
			
			if (foodDetailsContainer.parent == null)
			{
				var detailsIndex:int = mainContentContainer.getChildIndex(actionsContainer);
				mainContentContainer.addChildAt(foodDetailsContainer, detailsIndex);
			}
			
			servingSizeLabel.text = "Serving Size: " + (!isNaN(selectedFood.servingSize) ? selectedFood.servingSize : "N/A" );
			servingUnitLabel.text = "Serving Unit: " + (selectedFood.servingUnit != null && selectedFood.servingUnit != "" && selectedFood.servingUnit != "undefined" ? selectedFood.servingUnit : "N/A" );
			carbsLabel.text = "Carbs: " + (!isNaN(selectedFood.carbs) ? selectedFood.carbs : "N/A" );
			fiberLabel.text = "Fiber: " + (!isNaN(selectedFood.fiber) ? selectedFood.fiber : "N/A" );
			proteinsLabel.text = "Proteins: " + (!isNaN(selectedFood.proteins) ? selectedFood.proteins : "N/A" );
			fatsLabel.text = "Fats: " + (!isNaN(selectedFood.fats) ? selectedFood.fats : "N/A" );
			caloriesLabel.text = "Calories: " + (!isNaN(selectedFood.kcal) ? selectedFood.kcal + " Kcal" : "N/A" );
			if (selectedFood.link != null && selectedFood.link != "")
			{
				foodLink.isEnabled = true;
				selectedFoodLink = selectedFood.link;
			}
			else
				foodLink.isEnabled = false;
		}
		
		private function onFoodsSearchResult(e:FoodEvent):void
		{
			removeFoodEventListeners();
			resetComponents();
			preloader.visible = false;
			foodAmountInput.text = "";
			
			if (e.foodsList != null)
			{
				foodResultsList.dataProvider = new ArrayCollection(e.foodsList);
			}
		}
		
		private function onFinish(e:starling.events.Event):void
		{
			resetComponents();
			dispatchEventWith(starling.events.Event.CANCEL);
		}
		
		private function onAdd(e:starling.events.Event):void
		{
			addFoodButton.isEnabled = false;
			
			cartList.push( { food:activeFood, quantity: Number(foodAmountInput.text), servingUnit: activeFood.servingUnit } );
			basketAmountLabel.text = String(cartList.length);
			jump(basketSprite, 0.4);
			
			setTimeout( function():void {
				addFoodButton.isEnabled = true;
			}, 750 );
			
			//resetComponents();
			//dispatchEventWith(starling.events.Event.COMPLETE);
		}
		
		private function onScan(e:starling.events.Event):void
		{
			try
			{
				Scanner.init( !ModelLocator.IS_IPAD ? DistriqtKey.distriqtKey : DistriqtKey.distriqtKeyIpad );
				if (Scanner.isSupported)
				{
					Scanner.service.addEventListener( AuthorisationEvent.CHANGED, authorisationChangedHandler );
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
		
		private function authorisationChangedHandler( event:AuthorisationEvent ):void
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
		
		private function scanFood():void
		{
			Scanner.service.addEventListener( ScannerEvent.CODE_FOUND, codeFoundHandler );
			Scanner.service.addEventListener( ScannerEvent.CANCELLED, cancelledHandler );
			
			resetComponents();
			
			var options:ScannerOptions = new ScannerOptions();
			options.camera = ScannerOptions.CAMERA_REAR;
			options.torchMode = ScannerOptions.TORCH_AUTO;
			options.cancelLabel = "CANCEL";
			options.colour = 0x0086FF;
			options.textColour = 0xEEEEEE;
			options.singleResult = true;
			options.symbologies = [Symbology.UPCA, Symbology.EAN13, Symbology.EAN8, Symbology.UPCE];
			
			Scanner.service.startScan( options );
		}
		
		private function cancelledHandler( event:ScannerEvent ):void
		{
			//Remove scanner events
			Scanner.service.removeEventListener( ScannerEvent.CODE_FOUND, codeFoundHandler );
			Scanner.service.removeEventListener( ScannerEvent.CANCELLED, cancelledHandler );
			
			//Clear results list
			foodResultsList.selectedItem = null;
			foodResultsList.dataProvider = new ArrayCollection([]);
			
			//Force starling to render after context being lost by the camera overlay.
			recoverFromContextLost();
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
		
		private function codeFoundHandler( event:ScannerEvent ):void
		{
			//Remove scanner events
			Scanner.service.removeEventListener( ScannerEvent.CODE_FOUND, codeFoundHandler );
			Scanner.service.removeEventListener( ScannerEvent.CANCELLED, cancelledHandler );
			
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
				trace("barCode:", barCode);
				
				FoodAPIConnector.instance.addEventListener(FoodEvent.FOODS_SEARCH_RESULT, onFoodsSearchResult);
				FoodAPIConnector.instance.addEventListener(FoodEvent.FOOD_NOT_FOUND, onFoodNotFound);
				FoodAPIConnector.instance.addEventListener(FoodEvent.FOOD_SERVER_ERROR, onServerError);
				preloader.visible = true;
				
				if (currentMode == OPENFOODFACTS_MODE)
					FoodAPIConnector.openFoodFactsSearchCode(barCode);
				else if (currentMode == USDA_MODE)
					FoodAPIConnector.usdaSearchFood(barCode);
				else if (currentMode == FATSECRET_MODE)
					FoodAPIConnector.fatSecretSearchCode(barCode);
			}
		}
	}
}