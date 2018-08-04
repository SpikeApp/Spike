package ui.screens
{
	import flash.system.System;
	
	import database.CGMBlueToothDevice;
	import database.CommonSettings;
	
	import feathers.controls.DragGesture;
	import feathers.controls.Label;
	import feathers.controls.LayoutGroup;
	import feathers.controls.ScrollPolicy;
	import feathers.controls.WebView;
	import feathers.events.FeathersEventType;
	import feathers.layout.AnchorLayout;
	import feathers.layout.AnchorLayoutData;
	import feathers.layout.HorizontalAlign;
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
	
	[ResourceBundle("nightscoutscreen")]
	
	public class NightscoutViewScreen extends BaseSubScreen
	{
		/* Display Objects */
		private var nsWebView:WebView;
		private var errorContainer:LayoutGroup;
		private var errorLabel:Label;
		
		/* Properties */
		private var nightscoutURL:String;
		
		public function NightscoutViewScreen() 
		{
			super();
			styleNameList.add( BaseMaterialDeepGreyAmberMobileTheme.THEME_STYLE_NAME_HEADER_WITH_SHADOW );
			styleNameList.add( BaseMaterialDeepGreyAmberMobileTheme.THEME_STYLE_NAME_PANEL_WITHOUT_PADDING );
		}
		
		override protected function initialize():void 
		{
			super.initialize();
			
			Starling.current.stage.addEventListener(starling.events.Event.RESIZE, onStarlingResize);
			
			setupHeader();
			setupInitialContent();
			adjustMainMenu();
			
			addEventListener(FeathersEventType.TRANSITION_IN_COMPLETE, onSetupContent);
			
			this.horizontalScrollPolicy = ScrollPolicy.OFF;
		}
		
		/**
		 * Functionality
		 */
		private function setupHeader():void
		{
			/* Set Header Title */
			title = ModelLocator.resourceManagerInstance.getString('nightscoutscreen','screen_title');
			
			/* Set Header Icon */
			icon = getScreenIcon(MaterialDeepGreyAmberMobileThemeIcons.nightscoutTexture);
			iconContainer = new <DisplayObject>[icon];
			headerProperties.rightItems = iconContainer;
		}
		
		private function setupInitialContent():void
		{
			nightscoutURL = !CGMBlueToothDevice.isFollower() ? CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_AZURE_WEBSITE_NAME) : CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_URL);
			if (nightscoutURL.indexOf('http') == -1)
				nightscoutURL = "https://" + nightscoutURL;
		}
		
		private function onSetupContent(e:Event):void
		{
			//Deactivate menu drag gesture 
			AppInterface.instance.drawers.openGesture = DragGesture.NONE;
			
			//Size
			var availableScreenHeight:Number = Constants.stageHeight - this.header.height + 8;
			
			//Create web view
			nsWebView = new WebView();
			nsWebView.width = Constants.stageWidth;
			nsWebView.height = availableScreenHeight;
			nsWebView.addEventListener(FeathersEventType.ERROR, onLoadURLErrorTriggered);
			nsWebView.loadURL( nightscoutURL );
			if (nsWebView != null) addChild( nsWebView );
		}
		
		private function adjustMainMenu():void
		{
			AppInterface.instance.menu.selectedIndex = -1;
		}	
		
		private function disposeWebView():void
		{
			if (nsWebView != null)
			{
				nsWebView.removeEventListener(FeathersEventType.ERROR, onLoadURLErrorTriggered);
				nsWebView.removeFromParent();
				nsWebView.dispose();
				nsWebView = null;
			}
		}
		
		private function displayErrorMessage():void
		{
			/* Parent Class Layout */
			layout = new AnchorLayout(); 
			
			/* Create Display Object's Container and Corresponding Vertical Layout and Centered LayoutData */
			errorContainer = new LayoutGroup();
			var containerLayout:VerticalLayout = new VerticalLayout();
			containerLayout.horizontalAlign = HorizontalAlign.CENTER;
			containerLayout.verticalAlign = VerticalAlign.MIDDLE;
			errorContainer.layout = containerLayout;
			var containerLayoutData:AnchorLayoutData = new AnchorLayoutData();
			containerLayoutData.horizontalCenter = 0;
			containerLayoutData.verticalCenter = 0;
			errorContainer.layoutData = containerLayoutData;
			this.addChild( errorContainer );
			
			/* Create Error Message */
			errorLabel = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('nightscoutscreen','load_url_error_message'), HorizontalAlign.CENTER, VerticalAlign.TOP, 14, true);
			errorContainer.addChild(errorLabel);
		}
		
		/**
		 * Event Listeners
		 */
		
		protected function onLoadURLErrorTriggered(event:Event):void
		{
			disposeWebView();
			displayErrorMessage();
		}
		
		override protected function onBackButtonTriggered(event:Event):void
		{
			//Activate menu drag gesture
			AppInterface.instance.drawers.openGesture = DragGesture.EDGE;
			
			disposeWebView();
			dispatchEventWith(Event.COMPLETE);
		}
		
		private function onStarlingResize(event:ResizeEvent):void 
		{
			width = Constants.stageWidth;
			
			if (nsWebView != null)
			{
				var availableScreenHeight:Number = Constants.stageHeight - this.header.height + 8;
				nsWebView.width = Constants.stageWidth;
				nsWebView.height = availableScreenHeight;
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
		override protected function draw():void 
		{
			super.draw();
			icon.x = Constants.stageWidth - icon.width - BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding;
		}
		
		override public function dispose():void
		{
			Starling.current.stage.removeEventListener(starling.events.Event.RESIZE, onStarlingResize);
			
			if (errorLabel != null)
			{
				errorLabel.removeFromParent();
				errorLabel.dispose();
				errorLabel = null;
			}
			
			if (errorContainer != null)
			{
				errorContainer.removeFromParent();
				errorContainer.dispose();
				errorContainer = null;
			}
			
			super.dispose();
			
			System.pauseForGCIfCollectionImminent(0);
		}
	}
}