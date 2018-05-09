package ui.screens
{	
	import flash.system.System;
	
	import feathers.controls.Button;
	import feathers.controls.LayoutGroup;
	import feathers.controls.PanelScreen;
	import feathers.controls.ScrollBarDisplayMode;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalLayout;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import starling.display.DisplayObject;
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.textures.Texture;
	
	import ui.AppInterface;
	
	import utils.Constants;
	
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
			
			setupLayoutManager();
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
				AppInterface.instance.menu.selectedIndex = 0;
			}
			
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
			if (iconTexture != null)
			{
				iconTexture.dispose();
				iconTexture = null;
			}
			
			if (iconImage != null)
			{
				iconImage.removeFromParent();
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