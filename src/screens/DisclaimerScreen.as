package screens
{
	import display.LayoutFactory;
	
	import feathers.controls.Label;
	import feathers.events.FeathersEventType;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.ModelLocator;
	
	import starling.display.DisplayObject;
	import starling.events.Event;
	
	import ui.AppInterface;
	
	import utils.Constants;
	
	[ResourceBundle("disclaimerscreen")]

	public class DisclaimerScreen extends BaseSubScreen
	{
		public function DisclaimerScreen() 
		{
			super();
			styleNameList.add( BaseMaterialDeepGreyAmberMobileTheme.THEME_STYLE_NAME_HEADER_WITH_SHADOW );
		}
		
		override protected function initialize():void 
		{
			super.initialize();
			
			/* Set Header Title */
			title = ModelLocator.resourceManagerInstance.getString('disclaimerscreen','screen_title');
			
			/* Set Header Icon */
			icon = getScreenIcon(MaterialDeepGreyAmberMobileThemeIcons.disclaimerTexture);
			iconContainer = new <DisplayObject>[icon];
			headerProperties.rightItems = iconContainer;
			
			/* Create Content */
			addEventListener(FeathersEventType.CREATION_COMPLETE, setupContent);
			
			/* Adjust Menu */
			adjustMainMenu();
		}
		
		private function setupContent(event:Event):void
		{
			/* License */
			var licenseTitleLabel:Label = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('disclaimerscreen','license_label'));
			screenRenderer.addChild(licenseTitleLabel);
			
			var licenseContentLabel:Label = LayoutFactory.createContentLabel(ModelLocator.resourceManagerInstance.getString('disclaimerscreen','license_content'), this.width - (BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding * 2));
			screenRenderer.addChild(licenseContentLabel);
			
			/* Disclaimer */
			var disclaimerTitleLabel:Label = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('disclaimerscreen','disclaimer_label'));
			screenRenderer.addChild(disclaimerTitleLabel);
			
			var disclaimerContentLabel:Label = LayoutFactory.createContentLabel(ModelLocator.resourceManagerInstance.getString('disclaimerscreen','disclaimer_content'), this.width - (BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding * 2));
			screenRenderer.addChild(disclaimerContentLabel);
			
			/* Notice */
			var noticeTitleLabel:Label = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('disclaimerscreen','important_notice_label'));
			screenRenderer.addChild(noticeTitleLabel);
			
			var noticeContentLabel:Label = LayoutFactory.createContentLabel(ModelLocator.resourceManagerInstance.getString('disclaimerscreen','important_notice_content'), this.width - (BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding * 2), true, false);
			screenRenderer.addChild(noticeContentLabel);
			
			/* Acknowledgements */
			var acknowledgmentsTitleLabel:Label = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('disclaimerscreen','acknowledgments_label'));
			screenRenderer.addChild(acknowledgmentsTitleLabel);
			
			var acknowledgmentsContentLabel:Label = LayoutFactory.createContentLabel(ModelLocator.resourceManagerInstance.getString('disclaimerscreen','acknowledgments_content'), this.width - (BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding * 2));
			screenRenderer.addChild(acknowledgmentsContentLabel);
			
			/* Developers */
			var developersTitleLabel:Label = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('disclaimerscreen','developers_label'));
			screenRenderer.addChild(developersTitleLabel);
			
			var developersContentLabel:Label = LayoutFactory.createContentLabel(ModelLocator.resourceManagerInstance.getString('disclaimerscreen','developers_content'), this.width - (BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding * 2), true, true);
			screenRenderer.addChild(developersContentLabel);
		}
		
		private function adjustMainMenu():void
		{
			AppInterface.instance.menu.selectedIndex = 4;
		}
		
		override protected function draw():void 
		{
			var layoutInvalid:Boolean = isInvalid( INVALIDATION_FLAG_LAYOUT );
			super.draw();
			icon.x = Constants.stageWidth - icon.width - BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding;
		}
	}
}