package ui.screens
{	
	import flash.system.System;
	
	import feathers.controls.Button;
	import feathers.controls.LayoutGroup;
	import feathers.controls.PanelScreen;
	import feathers.controls.ScrollBarDisplayMode;
	import feathers.controls.ScrollPolicy;
	import feathers.events.FeathersEventType;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalLayout;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.ResizeEvent;
	import starling.textures.Texture;
	
	import ui.AppInterface;
	
	import utils.Constants;
	import utils.DeviceInfo;
	
	[ResourceBundle("globaltranslations")]
	
	public class BaseSubScreen extends PanelScreen
	{
		protected var backButton:Button;
		protected var screenRenderer:LayoutGroup;
		protected var screenLayout:VerticalLayout;
		protected var icon:Sprite;
		protected var iconContainer:Vector.<DisplayObject>;
		private var iconImage:Image;
		private var iconTexture:Texture;
		
		public function BaseSubScreen()
		{
			super();
			
			styleNameList.add( BaseMaterialDeepGreyAmberMobileTheme.THEME_STYLE_NAME_HEADER_WITH_SHADOW );
			scrollBarDisplayMode = ScrollBarDisplayMode.NONE;
			headerProperties.disposeItems = true;
			horizontalScrollPolicy = ScrollPolicy.OFF;
			
			setupLayoutManager();
			setupEventListeners();
		}
		
		override protected function initialize():void {
			super.initialize();
			
			/* Add default back button to the header */
			backButton = new Button();
			backButton.label = ModelLocator.resourceManagerInstance.getString('globaltranslations','back');
			backButton.styleNameList.add( Button.ALTERNATE_STYLE_NAME_BACK_BUTTON );
			headerProperties.leftItems = new <DisplayObject>[backButton];
			backButton.addEventListener(Event.TRIGGERED, onBackButtonTriggered);
		}
		
		private function setupLayoutManager():void
		{
			//Screen Layout Manager
			screenRenderer = new LayoutGroup();
			screenRenderer.width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
			screenLayout = new VerticalLayout();
			screenLayout.horizontalAlign = HorizontalAlign.LEFT;
			screenRenderer.layout = screenLayout;
			addChild(screenRenderer);
		}
		
		protected function setupHeaderSize():void
		{
			if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr)
			{
				if (this.header != null)
				{
					if (Constants.isPortrait)
					{
						this.header.height = 108;
						this.header.maxHeight = 108;	
					}
					else
					{
						this.header.height = 78;
						this.header.maxHeight = 78;
					}
				}
			}
			else
			{
				if (this.header != null)
				{
					this.header.height = 78;
					this.header.maxHeight = 78;
				}
			}
			
			if (this.header != null)
				Constants.headerHeight = this.header.maxHeight;
		}
		
		private function setupEventListeners():void
		{
			this.addEventListener(FeathersEventType.CREATION_COMPLETE, onScreenCreationComplete);
			this.addEventListener(FeathersEventType.TRANSITION_IN_COMPLETE, onTransitionInComplete);
			this.addEventListener(FeathersEventType.TRANSITION_OUT_COMPLETE, onBackButtonTriggered);
			Starling.current.stage.addEventListener(starling.events.Event.RESIZE, onStarlingBaseResize);
		}
		
		override protected function draw():void
		{
			super.draw();
			backButton.x = 5;
		}
		
		protected function onBackButtonTriggered(event:Event):void
		{
			//Pop this screen off
			dispatchEventWith(Event.COMPLETE);
			
			if(AppInterface.instance.navigator.activeScreenID == Screens.GLUCOSE_CHART)
			{
				//Select menu button from left menu
				AppInterface.instance.menu.selectedIndex = Constants.isPortrait ? 1 : 0;
			}
			
		}
		
		protected function onTransitionInComplete(event:Event):void
		{
			//Meant to be overriden
		}
		
		protected function onScreenCreationComplete(event:Event):void
		{
			onStarlingBaseResize(null)
		}
		
		protected function onStarlingBaseResize(e:ResizeEvent):void 
		{
			setupHeaderSize();
		}
		
		protected function getScreenIcon(texture:Texture):Sprite
		{
			icon = new Sprite();
			iconTexture = texture;
			iconImage = new Image(iconTexture);
			icon.addChild(iconImage);
			
			return icon;
		}
		
		override public function dispose():void
		{
			this.removeEventListener(FeathersEventType.CREATION_COMPLETE, onScreenCreationComplete);
			this.removeEventListener(FeathersEventType.TRANSITION_IN_COMPLETE, onTransitionInComplete);
			this.removeEventListener(FeathersEventType.TRANSITION_OUT_COMPLETE, onBackButtonTriggered);
			Starling.current.stage.removeEventListener(starling.events.Event.RESIZE, onStarlingBaseResize);
			
			if (iconTexture != null)
			{
				iconTexture.dispose();
				iconTexture = null;
			}
			
			if (iconImage != null)
			{
				iconImage.removeFromParent();
				if (iconImage.texture != null)
					iconImage.texture.dispose();
				iconImage.dispose();
				iconImage = null;
			}
			
			if (iconContainer != null)
			{
				iconContainer = null;
			}
			
			if (backButton != null)
			{
				backButton.addEventListener(Event.TRIGGERED, onBackButtonTriggered);
				backButton.removeFromParent();
				backButton.dispose();
				backButton = null;
			}
			
			if (icon != null)
			{
				icon.removeFromParent();
				icon.dispose();
				icon = null;
			}
			
			if (screenRenderer != null)
			{
				screenRenderer.removeFromParent();
				screenRenderer.dispose();
				screenRenderer = null;
			}
			
			System.pauseForGCIfCollectionImminent(0);
			
			super.dispose();
		}
	}
}