package ui.screens
{
	import flash.display.StageOrientation;
	import flash.system.System;
	
	import database.CGMBlueToothDevice;
	
	import feathers.controls.Label;
	import feathers.controls.ScrollPolicy;
	import feathers.events.FeathersEventType;
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
			Starling.current.stage.addEventListener(starling.events.Event.RESIZE, onStarlingResize);
			addEventListener(FeathersEventType.CREATION_COMPLETE, setupContent);
			
			/* Adjust Menu */
			adjustMainMenu();
			
			/* Scroll Policy */
			this.horizontalScrollPolicy = ScrollPolicy.OFF;
		}
		
		/**
		 * Functionality
		 */
		private function setupContent(event:Event):void
		{
			/* License */
			licenseTitleLabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('disclaimerscreen','license_label'));
			screenRenderer.addChild(licenseTitleLabel);
			
			licenseContentLabel = LayoutFactory.createContentLabel(ModelLocator.resourceManagerInstance.getString('disclaimerscreen','license_content'), Constants.stageWidth - (BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding * 2));
			screenRenderer.addChild(licenseContentLabel);
			
			/* Disclaimer */
			disclaimerTitleLabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('disclaimerscreen','disclaimer_label'));
			screenRenderer.addChild(disclaimerTitleLabel);
			
			disclaimerContentLabel = LayoutFactory.createContentLabel(ModelLocator.resourceManagerInstance.getString('disclaimerscreen','disclaimer_content'), Constants.stageWidth - (BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding * 2));
			screenRenderer.addChild(disclaimerContentLabel);
			
			/* Notice */
			noticeTitleLabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('disclaimerscreen','important_notice_label'));
			screenRenderer.addChild(noticeTitleLabel);
			
			noticeContentLabel = LayoutFactory.createContentLabel(ModelLocator.resourceManagerInstance.getString('disclaimerscreen','important_notice_content'), Constants.stageWidth - (BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding * 2), true, false);
			screenRenderer.addChild(noticeContentLabel);
			
			/* Acknowledgements */
			acknowledgmentsTitleLabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('disclaimerscreen','acknowledgments_label'));
			screenRenderer.addChild(acknowledgmentsTitleLabel);
			
			acknowledgmentsContentLabel = LayoutFactory.createContentLabel(ModelLocator.resourceManagerInstance.getString('disclaimerscreen','acknowledgments_content'), Constants.stageWidth - (BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding * 2));
			screenRenderer.addChild(acknowledgmentsContentLabel);
			
			/* Developers */
			developersTitleLabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('disclaimerscreen','developers_label'));
			screenRenderer.addChild(developersTitleLabel);
			
			developersContentLabel = LayoutFactory.createContentLabel(ModelLocator.resourceManagerInstance.getString('disclaimerscreen','developers_content'), Constants.stageWidth - (BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding * 2), true, true);
			screenRenderer.addChild(developersContentLabel);
			
			onStarlingResize(null);
		}
		
		private function adjustMainMenu():void
		{
			if (!CGMBlueToothDevice.isFollower())
				AppInterface.instance.menu.selectedIndex = Constants.isPortrait ? 8 : 7;
			else
				AppInterface.instance.menu.selectedIndex = Constants.isPortrait ? 5 : 4;
		}
		
		/**
		 * Event Handlers
		 */
		private function onStarlingResize(event:ResizeEvent):void 
		{
			if (Constants.isPortrait || Constants.deviceModel != DeviceInfo.IPHONE_X_Xs_XsMax_Xr)
			{
				screenRenderer.x = 0;
				licenseContentLabel.width = Constants.stageWidth - (BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding * 2);
				disclaimerContentLabel.width = Constants.stageWidth - (BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding * 2);
				noticeContentLabel.width = Constants.stageWidth - (BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding * 2);
				acknowledgmentsContentLabel.width = Constants.stageWidth - (BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding * 2);
				developersContentLabel.width = Constants.stageWidth - (BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding * 2);
			}
			else
			{
				if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr && !Constants.isPortrait)
				{
					if (Constants.currentOrientation == StageOrientation.ROTATED_RIGHT)
					{
						screenRenderer.x = 30;
						licenseContentLabel.width = Constants.stageWidth - (BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding * 2) - 30;
						disclaimerContentLabel.width = Constants.stageWidth - (BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding * 2) - 30;
						noticeContentLabel.width = Constants.stageWidth - (BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding * 2) - 30;
						acknowledgmentsContentLabel.width = Constants.stageWidth - (BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding * 2) - 30;
						developersContentLabel.width = Constants.stageWidth - (BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding * 2) - 30;
					}
					else if (Constants.currentOrientation == StageOrientation.ROTATED_LEFT)
					{
						screenRenderer.x = 0;
						licenseContentLabel.width = Constants.stageWidth - (BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding * 2) - 30;
						disclaimerContentLabel.width = Constants.stageWidth - (BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding * 2) - 30;
						noticeContentLabel.width = Constants.stageWidth - (BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding * 2) - 30;
						acknowledgmentsContentLabel.width = Constants.stageWidth - (BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding * 2) - 30;
						developersContentLabel.width = Constants.stageWidth - (BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding * 2) - 30;
					}
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
			if (licenseTitleLabel != null)
			{
				licenseTitleLabel.removeFromParent();
				licenseTitleLabel.dispose();
				licenseTitleLabel = null;
			}
			
			if (licenseContentLabel != null)
			{
				licenseContentLabel.removeFromParent();
				licenseContentLabel.dispose();
				licenseContentLabel = null;
			}
			
			if (disclaimerTitleLabel != null)
			{
				disclaimerTitleLabel.removeFromParent();
				disclaimerTitleLabel.dispose();
				disclaimerTitleLabel = null;
			}
			
			if (disclaimerContentLabel != null)
			{
				disclaimerContentLabel.removeFromParent();
				disclaimerContentLabel.dispose();
				disclaimerContentLabel = null;
			}
			
			if (noticeTitleLabel != null)
			{
				noticeTitleLabel.removeFromParent();
				noticeTitleLabel.dispose();
				noticeTitleLabel = null;
			}
			
			if (noticeContentLabel != null)
			{
				noticeContentLabel.removeFromParent();
				noticeContentLabel.dispose();
				noticeContentLabel = null;
			}
			
			if (acknowledgmentsTitleLabel != null)
			{
				acknowledgmentsTitleLabel.removeFromParent();
				acknowledgmentsTitleLabel.dispose();
				acknowledgmentsTitleLabel = null;
			}
			
			if (acknowledgmentsContentLabel != null)
			{
				acknowledgmentsContentLabel.removeFromParent();
				acknowledgmentsContentLabel.dispose();
				acknowledgmentsContentLabel = null;
			}
			
			if (developersTitleLabel != null)
			{
				developersTitleLabel.removeFromParent();
				developersTitleLabel.dispose();
				developersTitleLabel = null;
			}
			
			if (developersContentLabel != null)
			{
				developersContentLabel.removeFromParent();
				developersContentLabel.dispose();
				developersContentLabel = null;
			}
		}
		
		override public function dispose():void
		{
			Starling.current.stage.removeEventListener(starling.events.Event.RESIZE, onStarlingResize);
			removeEventListener(FeathersEventType.CREATION_COMPLETE, setupContent);
			
			disposeDisplayObjects();
			
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