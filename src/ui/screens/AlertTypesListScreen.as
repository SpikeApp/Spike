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
	import ui.screens.display.settings.alarms.AlertsList;
	
	import utils.Constants;
	import utils.DeviceInfo;
	
	[ResourceBundle("alertsettingsscreen")]

	public class AlertTypesListScreen extends BaseSubScreen
	{	
		/* Display Objects */
		private var alertTypesLabel:Label;
		private var alertTypesList:AlertsList;
		
		public function AlertTypesListScreen() 
		{
			super();
			
			setupHeader();
		}
		
		override protected function initialize():void 
		{
			super.initialize();
			
			setupContent();
			adjustMainMenu();
		}
		
		/**
		 * Functionality
		 */
		private function setupHeader():void
		{
			/* Set Header Title */
			title = ModelLocator.resourceManagerInstance.getString('alertsettingsscreen','alert_types_list_screen_title');
			
			/* Set Header Icon */
			icon = getScreenIcon(MaterialDeepGreyAmberMobileThemeIcons.alertTexture);
			iconContainer = new <DisplayObject>[icon];
			headerProperties.rightItems = iconContainer;
		}
		
		private function setupContent():void
		{
			//Deactivate menu drag gesture 
			AppInterface.instance.drawers.openGesture = DragGesture.NONE;
			
			//Alert Types Label
			alertTypesLabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('alertsettingsscreen','alerts_list_section_label'), true);
			screenRenderer.addChild(alertTypesLabel);
			
			//Alert Types List
			alertTypesList = new AlertsList();
			screenRenderer.addChild(alertTypesList);
		}
		
		private function adjustMainMenu():void
		{
			AppInterface.instance.menu.selectedIndex = Constants.isPortrait ? 4 : 3;
		}
		
		/**
		 * Event Handlers
		 */
		override protected function onBackButtonTriggered(event:Event):void
		{
			alertTypesList.closeAlertCallout();
			
			//Activate menu drag gesture
			AppInterface.instance.drawers.openGesture = DragGesture.EDGE;
			
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
				if (alertTypesLabel != null) alertTypesLabel.paddingLeft = 30;
			}
			else
			{
				if (alertTypesLabel != null) alertTypesLabel.paddingLeft = 0;
			}
			
			setupHeaderSize();
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			if (alertTypesLabel != null)
			{
				alertTypesLabel.removeFromParent();
				alertTypesLabel.dispose();
				alertTypesLabel = null;
			}
			
			if (alertTypesList != null)
			{
				alertTypesList.removeFromParent();
				alertTypesList.dispose();
				alertTypesList = null;
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