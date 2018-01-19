package ui.screens
{
	import flash.system.System;
	
	import ui.screens.display.LayoutFactory;
	
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
		/* Display Objects */
		private var licenseTitleLabel:Label;
		private var licenseContentLabel:Label;
		private var disclaimerTitleLabel:Label;
		private var disclaimerContentLabel:Label;
		private var noticeTitleLabel:Label;
		private var noticeContentLabel:Label;
		private var acknowledgmentsTitleLabel:Label;
		private var acknowledgmentsContentLabel:Label;
		private var developersTitleLabel:Label;
		private var developersContentLabel:Label;
		
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
		
		/**
		 * Functionality
		 */
		private function setupContent(event:Event):void
		{
			/* License */
			licenseTitleLabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('disclaimerscreen','license_label'));
			screenRenderer.addChild(licenseTitleLabel);
			
			licenseContentLabel = LayoutFactory.createContentLabel(ModelLocator.resourceManagerInstance.getString('disclaimerscreen','license_content'), this.width - (BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding * 2));
			screenRenderer.addChild(licenseContentLabel);
			
			/* Disclaimer */
			disclaimerTitleLabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('disclaimerscreen','disclaimer_label'));
			screenRenderer.addChild(disclaimerTitleLabel);
			
			disclaimerContentLabel = LayoutFactory.createContentLabel(ModelLocator.resourceManagerInstance.getString('disclaimerscreen','disclaimer_content'), this.width - (BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding * 2));
			screenRenderer.addChild(disclaimerContentLabel);
			
			/* Notice */
			noticeTitleLabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('disclaimerscreen','important_notice_label'));
			screenRenderer.addChild(noticeTitleLabel);
			
			noticeContentLabel = LayoutFactory.createContentLabel(ModelLocator.resourceManagerInstance.getString('disclaimerscreen','important_notice_content'), this.width - (BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding * 2), true, false);
			screenRenderer.addChild(noticeContentLabel);
			
			/* Acknowledgements */
			acknowledgmentsTitleLabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('disclaimerscreen','acknowledgments_label'));
			screenRenderer.addChild(acknowledgmentsTitleLabel);
			
			acknowledgmentsContentLabel = LayoutFactory.createContentLabel(ModelLocator.resourceManagerInstance.getString('disclaimerscreen','acknowledgments_content'), this.width - (BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding * 2));
			screenRenderer.addChild(acknowledgmentsContentLabel);
			
			/* Developers */
			developersTitleLabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('disclaimerscreen','developers_label'));
			screenRenderer.addChild(developersTitleLabel);
			
			developersContentLabel = LayoutFactory.createContentLabel(ModelLocator.resourceManagerInstance.getString('disclaimerscreen','developers_content'), this.width - (BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding * 2), true, true);
			screenRenderer.addChild(developersContentLabel);
		}
		
		private function adjustMainMenu():void
		{
			AppInterface.instance.menu.selectedIndex = 5;
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			removeEventListener(FeathersEventType.CREATION_COMPLETE, setupContent);
			
			if (licenseTitleLabel != null)
			{
				licenseTitleLabel.dispose();
				licenseTitleLabel = null;
			}
			
			if (licenseContentLabel != null)
			{
				licenseContentLabel.dispose();
				licenseContentLabel = null;
			}
			
			if (disclaimerTitleLabel != null)
			{
				disclaimerTitleLabel.dispose();
				disclaimerTitleLabel = null;
			}
			
			if (disclaimerContentLabel != null)
			{
				disclaimerContentLabel.dispose();
				disclaimerContentLabel = null;
			}
			
			if (noticeTitleLabel != null)
			{
				noticeTitleLabel.dispose();
				noticeTitleLabel = null;
			}
			
			if (noticeContentLabel != null)
			{
				noticeContentLabel.dispose();
				noticeContentLabel = null;
			}
			
			if (acknowledgmentsTitleLabel != null)
			{
				acknowledgmentsTitleLabel.dispose();
				acknowledgmentsTitleLabel = null;
			}
			
			if (acknowledgmentsContentLabel != null)
			{
				acknowledgmentsContentLabel.dispose();
				acknowledgmentsContentLabel = null;
			}
			
			if (developersTitleLabel != null)
			{
				developersTitleLabel.dispose();
				developersTitleLabel = null;
			}
			
			if (developersContentLabel != null)
			{
				developersContentLabel.dispose();
				developersContentLabel = null;
			}
			
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