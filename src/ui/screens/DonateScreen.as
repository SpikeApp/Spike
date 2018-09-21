package ui.screens
{
	import flash.display.StageOrientation;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.net.navigateToURL;
	import flash.system.System;
	
	import database.CGMBlueToothDevice;
	
	import feathers.controls.Button;
	import feathers.controls.Label;
	import feathers.controls.LayoutGroup;
	import feathers.controls.ScrollPolicy;
	import feathers.layout.AnchorLayout;
	import feathers.layout.AnchorLayoutData;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.HorizontalLayout;
	import feathers.layout.VerticalAlign;
	import feathers.layout.VerticalLayout;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.ModelLocator;
	
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.events.Event;
	import starling.events.ResizeEvent;
	
	import ui.AppInterface;
	import ui.screens.display.LayoutFactory;
	
	import utils.Constants;
	import utils.DeviceInfo;
	
	[ResourceBundle("donatescreen")]

	public class DonateScreen extends BaseSubScreen
	{
		/* Internal Variables */
		private var currency:String = "EUR";
		
		/* Internal Properties */
		private var variables:URLVariables;
		private var request:URLRequest;
		
		/* Display Objects */
		private var container:LayoutGroup;
		private var donationDescription:Label;
		private var donationTitle:Label;
		private var contentContainer:LayoutGroup;
		private var actionsContainer:LayoutGroup;
		private var donateEuroButton:Button;
		private var donateDollarsButton:Button;
		
		public function DonateScreen() 
		{
			super();
			styleNameList.add( BaseMaterialDeepGreyAmberMobileTheme.THEME_STYLE_NAME_HEADER_WITH_SHADOW );
		}
		
		override protected function initialize():void 
		{
			super.initialize();
			
			/* Set Header Title */
			title = ModelLocator.resourceManagerInstance.getString('donatescreen','screen_title');
			
			/* Set Header Icon */
			icon = getScreenIcon(MaterialDeepGreyAmberMobileThemeIcons.donateTexture);
			iconContainer = new <DisplayObject>[icon];
			headerProperties.rightItems = iconContainer;
			
			/* Create Content */
			Starling.current.stage.addEventListener(starling.events.Event.RESIZE, onStarlingResize);
			
			/* Scroll Policy */
			this.horizontalScrollPolicy = ScrollPolicy.OFF;
			
			/* Actions */
			setupLayout();
			setupContent();
			adjustMainMenu();
		}
		
		/**
		 * Functionality
		 */
		private function setupLayout():void
		{
			/* Parent Class Layout */
			layout = new AnchorLayout(); 
			
			/* Create Display Object's Container and Corresponding Vertical Layout and Centered LayoutData */
			container = new LayoutGroup();
			var containerLayout:VerticalLayout = new VerticalLayout();
			containerLayout.gap = -50;
			containerLayout.horizontalAlign = HorizontalAlign.CENTER;
			containerLayout.verticalAlign = VerticalAlign.MIDDLE;
			container.layout = containerLayout;
			var containerLayoutData:AnchorLayoutData = new AnchorLayoutData();
			containerLayoutData.horizontalCenter = 0;
			containerLayoutData.verticalCenter = 0;
			container.layoutData = containerLayoutData;
			this.addChild( container );
		}
		
		private function setupContent():void
		{
			var contentLayout:VerticalLayout = new VerticalLayout();
			contentLayout.horizontalAlign = HorizontalAlign.CENTER;
			contentLayout.gap = 15;
			contentContainer = new LayoutGroup();
			contentContainer.layout = contentLayout;
			
			donationTitle = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('donatescreen','donation_title_label'), HorizontalAlign.CENTER, VerticalAlign.TOP, 18, true);
			contentContainer.addChild(donationTitle);
			
			donationDescription = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('donatescreen','donation_description_label'), HorizontalAlign.CENTER, VerticalAlign.TOP);
			donationDescription.wordWrap = true;
			contentContainer.addChild(donationDescription);
			
			var actionsLayout:HorizontalLayout = new HorizontalLayout();
			actionsLayout.gap = 6;
			actionsLayout.paddingTop = 20;
			actionsContainer = new LayoutGroup();
			actionsContainer.layout = actionsLayout;
			contentContainer.addChild(actionsContainer);
			
			donateEuroButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('donatescreen','euro_currency_button_label'), false, MaterialDeepGreyAmberMobileThemeIcons.donateTexture);
			donateEuroButton.addEventListener(Event.TRIGGERED, onCurrencyEuros);
			actionsContainer.addChild(donateEuroButton);
			donateDollarsButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('donatescreen','dollars_currency_button_label'), false, MaterialDeepGreyAmberMobileThemeIcons.donateTexture);
			donateDollarsButton.addEventListener(Event.TRIGGERED, onCurrencyDollars);
			actionsContainer.addChild(donateDollarsButton);
			
			container.addChild(contentContainer);
			
			onStarlingResize(null);
		}
		
		private function adjustMainMenu():void
		{
			if (!CGMBlueToothDevice.isFollower())
				AppInterface.instance.menu.selectedIndex = Constants.isPortrait ? 9 : 8;
			else
				AppInterface.instance.menu.selectedIndex = Constants.isPortrait ? 6 : 5;
		}
		
		private function donate():void
		{
			variables = new URLVariables();
			variables.cmd = "_donations";
			variables.add = "1";
			variables.business = "paypal@spike-app.com";
			variables.item_name = "Donation to Spike";
			variables.tax = "0";
			variables.currency_code = currency;
			variables.no_shipping = "0";
			variables.undefined_quantity = "1";
			variables.rn = "1";
			variables.lc = "US";
			variables.shipping = "0";
			variables.shopping_url = "https://spike-app.com";
			variables["return"] = "https://spike-app.com/thank-you/";
			
			request = new URLRequest("https://www.paypal.com/cgi-bin/webscr");
			request.method = URLRequestMethod.POST;
			request.data = variables;
			navigateToURL(request, "_self");
		}
		
		/**
		 * Event Handlers
		 */
		private function onCurrencyDollars(e:Event):void
		{
			currency = "USD";
			donate();
		}
		
		private function onCurrencyEuros(e:Event):void
		{
			currency = "EUR";
			donate();
		}
		
		private function onStarlingResize(event:ResizeEvent):void 
		{
			if (!Constants.isPortrait && Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr)
			{
				if (donationTitle != null && donationDescription != null && contentContainer != null)
				{
					if (Constants.currentOrientation == StageOrientation.ROTATED_RIGHT)
					{
						contentContainer.x = 40;
					}
					else if (Constants.currentOrientation == StageOrientation.ROTATED_LEFT)
					{
						contentContainer.x = 0;
					}
					
					contentContainer.width = Constants.stageWidth - 50;
					donationTitle.width = Constants.stageWidth - 20 - 50;
					donationTitle.width = Constants.stageWidth - 20 - 50;
					donationDescription.width = Constants.stageWidth - 20 - 50;
				}
			}
			else
			{
				if (donationTitle != null && donationDescription != null && contentContainer != null)
				{
					contentContainer.width = Constants.stageWidth;
					contentContainer.x = 0;
					donationTitle.width = Constants.stageWidth - 20;
					donationTitle.width = Constants.stageWidth - 20;
					donationDescription.width = Constants.stageWidth - 20;
				}
			}
		}
		
		override protected function onTransitionInComplete(e:Event):void
		{
			//Swipe to pop functionality
			AppInterface.instance.navigator.isSwipeToPopEnabled = false;
		}
		
		/**
		 * Utility
		 */
		private function disposeDisplayObjects():void
		{
			if (donationDescription != null)
			{
				donationDescription.removeFromParent();
				donationDescription.dispose();
				donationDescription = null;
			}
			
			if (donationTitle != null)
			{
				donationTitle.removeFromParent();
				donationTitle.dispose();
				donationTitle = null;
			}
			
			if (donateEuroButton != null)
			{
				donateEuroButton.addEventListener(Event.TRIGGERED, onCurrencyEuros);
				donateEuroButton.removeFromParent();
				donateEuroButton.dispose();
				donateEuroButton = null;
			}
			
			if (donateDollarsButton != null)
			{
				donateDollarsButton.addEventListener(Event.TRIGGERED, onCurrencyDollars);
				donateDollarsButton.removeFromParent();
				donateDollarsButton.dispose();
				donateDollarsButton = null;
			}
			
			if (actionsContainer != null)
			{
				actionsContainer.removeFromParent();
				actionsContainer.dispose();
				actionsContainer = null;
			}
			
			if (contentContainer != null)
			{
				contentContainer.removeFromParent();
				contentContainer.dispose();
				contentContainer = null;
			}
			
			if (container != null)
			{
				container.removeFromParent();
				container.dispose();
				container = null;
			}
		}
		
		override public function dispose():void
		{
			Starling.current.stage.removeEventListener(starling.events.Event.RESIZE, onStarlingResize);
			
			disposeDisplayObjects();
			
			if (request != null) request = null; 
			if (variables != null) variables = null; 
			
			super.dispose();
			
			System.pauseForGCIfCollectionImminent(0);
		}
		
		override protected function draw():void 
		{
			super.draw();
			icon.x = Constants.stageWidth - icon.width - BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding;
		}
	}
}