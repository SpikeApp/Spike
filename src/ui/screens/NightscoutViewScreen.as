package ui.screens
{
	import flash.events.ErrorEvent;
	import flash.geom.Rectangle;
	import flash.media.StageWebView;
	import flash.system.System;
	
	import databaseclasses.CommonSettings;
	
	import feathers.controls.DragGesture;
	import feathers.controls.Label;
	import feathers.controls.LayoutGroup;
	import feathers.events.FeathersEventType;
	import feathers.layout.AnchorLayout;
	import feathers.layout.AnchorLayoutData;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalAlign;
	import feathers.layout.VerticalLayout;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.ModelLocator;
	
	import starling.display.DisplayObject;
	import starling.events.Event;
	
	import ui.AppInterface;
	import ui.screens.display.LayoutFactory;
	
	import utils.Constants;
	
	[ResourceBundle("nightscoutscreen")]
	
	public class NightscoutViewScreen extends BaseSubScreen
	{
		/* Display Objects */
		private var webView:StageWebView;
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
			
			setupHeader();
			setupInitialContent();
			adjustMainMenu();
			
			addEventListener(FeathersEventType.TRANSITION_IN_COMPLETE, onSetupContent);
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
			nightscoutURL = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_AZURE_WEBSITE_NAME);
			if (nightscoutURL.indexOf('http') == -1)
				nightscoutURL = "https://" + nightscoutURL;
		}
		
		private function onSetupContent(e:Event):void
		{
			//Deactivate menu drag gesture 
			AppInterface.instance.drawers.openGesture = DragGesture.NONE;
			
			//Create web view
			webView = new StageWebView();
			webView.stage = Constants.appStage; 
			webView.viewPort = new Rectangle( 0, 140, Constants.appStage.stageWidth, Constants.appStage.stageHeight - 140 ); 
			webView.addEventListener( ErrorEvent.ERROR, onLoadURLErrorTriggered );
			webView.loadURL( nightscoutURL );
		}
		
		private function adjustMainMenu():void
		{
			AppInterface.instance.menu.selectedIndex = -1;
		}	
		
		private function disposeWebView():void
		{
			if (webView != null)
			{
				webView.stage = null;
				webView.viewPort = null;
				webView.dispose();
				webView = null;
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
		
		protected function onLoadURLErrorTriggered(event:ErrorEvent):void
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
			if (errorLabel != null)
			{
				if (errorContainer != null)
					errorContainer.removeChild(errorLabel);
				
				errorLabel.dispose();
				errorLabel = null;
			}
			
			if (errorContainer != null)
			{
				errorContainer.dispose();
				errorContainer = null;
			}
			
			super.dispose();
			
			System.pauseForGCIfCollectionImminent(0);
		}
	}
}