package screens
{	
	import display.extraoptions.ExtraOptionsList;
	import display.treatments.TreatmentsList;
	
	import events.ScreenEvent;
	
	import feathers.controls.Button;
	import feathers.controls.Callout;
	import feathers.controls.List;
	import feathers.controls.PanelScreen;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import starling.display.DisplayObject;
	import starling.display.Image;
	import starling.events.Event;
	
	import ui.AppInterface;
	
	public class BaseScreen extends PanelScreen
	{
		/* Display Objects */
		protected var menuButton:Button;
		protected var treatmentsButton:Button;
		protected var moreButton:Button;
		protected var callout:Callout;
		
		public function BaseScreen()
		{
			super();
		}
		
		override protected function initialize():void {
			super.initialize();
			
			/* Add default menu button to the header */
			menuButton = new Button();
			menuButton.defaultIcon = new Image( MaterialDeepGreyAmberMobileThemeIcons.menuTexture );
			menuButton.styleNameList.add( BaseMaterialDeepGreyAmberMobileTheme.THEME_STYLE_NAME_BUTTON_HEADER_QUIET_ICON_ONLY );
			menuButton.addEventListener( Event.TRIGGERED, onMenuButtonTriggered );
			headerProperties.leftItems = new <DisplayObject>[
				menuButton
			];
			backButtonHandler = onBackButton;
			
			/* Add more options to the header */
			moreButton = new Button();
			moreButton.defaultIcon = new Image( MaterialDeepGreyAmberMobileThemeIcons.moreVerticalTexture );
			moreButton.styleNameList.add( BaseMaterialDeepGreyAmberMobileTheme.THEME_STYLE_NAME_BUTTON_HEADER_QUIET_ICON_ONLY );
			moreButton.addEventListener( Event.TRIGGERED, onMoreButtonTriggered );
			moreButton.validate();
			
			/* Add treatments to the header */
			treatmentsButton = new Button();
			treatmentsButton.defaultIcon = new Image( MaterialDeepGreyAmberMobileThemeIcons.addTexture );
			treatmentsButton.styleNameList.add( BaseMaterialDeepGreyAmberMobileTheme.THEME_STYLE_NAME_BUTTON_HEADER_QUIET_ICON_ONLY );
			treatmentsButton.addEventListener( Event.TRIGGERED, onTreatmentButtonTriggered );
			treatmentsButton.validate();
			
			/* Populate Header */
			headerProperties.rightItems = new <DisplayObject>[
				treatmentsButton,
				moreButton
			];
			
			headerProperties.gap = -10;
			headerProperties.disposeItems = true;
		}
		
		private function onMenuButtonTriggered():void 
		{
			toggleMenu();
		}
		
		private function onBackButton():void 
		{
			toggleMenu();
		}
		
		protected function onTreatmentButtonTriggered():void 
		{
			var treatmentsList:List = new TreatmentsList();
			callout = Callout.show( treatmentsList, treatmentsButton );
		}
		
		protected function onMoreButtonTriggered():void 
		{
			var extraOptionsList:List = new ExtraOptionsList();
			extraOptionsList.addEventListener(ExtraOptionsList.CLOSE, onCloseCallOut);
			callout = Callout.show( extraOptionsList, moreButton );
		}
		
		private function onCloseCallOut(e:Event):void
		{
			callout.close(true);
		}
		
		private function toggleMenu():void 
		{
			if(!AppInterface.instance.drawers.isLeftDrawerOpen)
				dispatchEventWith( ScreenEvent.TOGGLE_MENU );
		}
		
		override protected function draw():void
		{
			super.draw();
		}
	}
}