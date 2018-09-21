package ui.screens
{
	import flash.display.StageOrientation;
	import flash.system.System;
	
	import feathers.controls.DragGesture;
	import feathers.controls.Label;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.ModelLocator;
	
	import starling.display.DisplayObject;
	import starling.events.Event;
	import starling.events.ResizeEvent;
	
	import ui.AppInterface;
	import ui.screens.display.LayoutFactory;
	import ui.screens.display.settings.treatments.InfoPillSettingsList;
	import ui.screens.display.settings.treatments.TreatmentsSettingsList;
	
	import utils.Constants;
	import utils.DeviceInfo;
	
	[ResourceBundle("treatments")]
	
	public class TreatmentsSettingsScreen extends BaseSubScreen
	{
		/* Display Objects */
		private var treatmentsSettings:TreatmentsSettingsList;
		private var treatmentsLabel:Label;
		private var infoPillLabel:Label;
		private var infoPillSettings:InfoPillSettingsList;
		
		public function TreatmentsSettingsScreen() 
		{
			super();
			
			setupHeader();	
		}
		override protected function initialize():void 
		{
			super.initialize();
			
			setupContent();
		}
		
		/**
		 * Functionality
		 */
		private function setupHeader():void
		{
			/* Set Header Title */
			title = ModelLocator.resourceManagerInstance.getString('treatments',"treatments_screen_title");
			
			/* Set Header Icon */
			icon = getScreenIcon(MaterialDeepGreyAmberMobileThemeIcons.treatmentsTexture);
			iconContainer = new <DisplayObject>[icon];
			headerProperties.rightItems = iconContainer;
		}
		
		private function setupContent():void
		{
			//Deactivate menu drag gesture 
			AppInterface.instance.drawers.openGesture = DragGesture.NONE;
			
			//Treatments Section Label
			treatmentsLabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('treatments',"treatments_screen_title"), true);
			screenRenderer.addChild(treatmentsLabel);
			
			//Treatments Settings
			treatmentsSettings = new TreatmentsSettingsList(this);
			screenRenderer.addChild(treatmentsSettings);
			
			//Info Pill Section Label
			infoPillLabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('treatments',"info_pill"), true);
			screenRenderer.addChild(infoPillLabel);
			
			//Info Pill Settings
			infoPillSettings = new InfoPillSettingsList();
			screenRenderer.addChild(infoPillSettings);
		}
		
		/**
		 * Event Handlers
		 */
		override protected function onBackButtonTriggered(event:Event):void
		{
			//Activate menu drag gesture
			AppInterface.instance.drawers.openGesture = DragGesture.EDGE;
			
			//Save settings
			if (treatmentsSettings.needsSave)
				treatmentsSettings.save();
			if (infoPillSettings.needsSave)
				infoPillSettings.save();
			
			//Pop Screen
			dispatchEventWith(Event.COMPLETE);
		}
		
		override protected function onTransitionInComplete(e:Event):void
		{
			//Swipe to pop functionality
			AppInterface.instance.navigator.isSwipeToPopEnabled = true;
		}
		
		override protected function onStarlingBaseResize(e:ResizeEvent):void 
		{
			if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr && !Constants.isPortrait && Constants.currentOrientation == StageOrientation.ROTATED_RIGHT)
			{
				if (treatmentsLabel != null) treatmentsLabel.paddingLeft = 30;
				if (infoPillLabel != null) infoPillLabel.paddingLeft = 30;
			}
			else
			{
				if (treatmentsLabel != null) treatmentsLabel.paddingLeft = 0;
				if (infoPillLabel != null) infoPillLabel.paddingLeft = 0;
			}
			
			setupHeaderSize();
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			if (treatmentsSettings != null)
			{
				treatmentsSettings.removeFromParent();
				treatmentsSettings.dispose();
				treatmentsSettings = null;
			}
			
			if (treatmentsLabel != null)
			{
				treatmentsLabel.removeFromParent();
				treatmentsLabel.dispose();
				treatmentsLabel = null;
			}
			
			if (infoPillLabel != null)
			{
				infoPillLabel.removeFromParent();
				infoPillLabel.dispose();
				infoPillLabel = null;
			}
			
			if (infoPillSettings != null)
			{
				infoPillSettings.removeFromParent();
				infoPillSettings.dispose();
				infoPillSettings = null;
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