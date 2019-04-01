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
	import ui.screens.display.settings.treatments.FoodManagerCalculationsSettingsList;
	import ui.screens.display.settings.treatments.FoodManagerUISettingsList;
	
	import utils.Constants;
	import utils.DeviceInfo;
	
	[ResourceBundle("treatments")]
	[ResourceBundle("foodmanager")]

	public class FoodManagerSettingsScreen extends BaseSubScreen
	{
		/* Display Objects */
		private var foodManagerCalculationsSettings:FoodManagerCalculationsSettingsList;
		private var foodManagerCalculationsLabel:Label;
		private var foodManagerUILabel:Label;
		private var foodManagerUISettings:FoodManagerUISettingsList;
		
		public function FoodManagerSettingsScreen() 
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
			title = ModelLocator.resourceManagerInstance.getString('foodmanager','food_manager_title_label');
			
			/* Set Header Icon */
			icon = getScreenIcon(MaterialDeepGreyAmberMobileThemeIcons.foodManagerTexture);
			iconContainer = new <DisplayObject>[icon];
			headerProperties.rightItems = iconContainer;
		}
		
		private function setupContent():void
		{
			//Deactivate menu drag gesture 
			AppInterface.instance.drawers.openGesture = DragGesture.NONE;
			
			//Calculations Label
			foodManagerCalculationsLabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('treatments','calculations_label'), true);
			screenRenderer.addChild(foodManagerCalculationsLabel);
			
			//Calculations Settings
			foodManagerCalculationsSettings = new FoodManagerCalculationsSettingsList();
			screenRenderer.addChild(foodManagerCalculationsSettings);
			
			//UI Label
			foodManagerUILabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('foodmanager','user_interface_lable'), true);
			screenRenderer.addChild(foodManagerUILabel);
			
			//UI Settings
			foodManagerUISettings = new FoodManagerUISettingsList();
			screenRenderer.addChild(foodManagerUISettings);
		}
		
		/**
		 * Event Handlers
		 */
		override protected function onBackButtonTriggered(event:Event):void
		{
			if (foodManagerCalculationsSettings.needsSave)
				foodManagerCalculationsSettings.save();
			
			if (foodManagerUISettings.needsSave)
				foodManagerUISettings.save();
			
			//Activate menu drag gesture
			AppInterface.instance.drawers.openGesture = DragGesture.EDGE;
			
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
				if (foodManagerCalculationsLabel != null) foodManagerCalculationsLabel.paddingLeft = 30;
				if (foodManagerUILabel != null) foodManagerUILabel.paddingLeft = 30;
			}
			else
			{
				if (foodManagerCalculationsLabel != null) foodManagerCalculationsLabel.paddingLeft = 0;
				if (foodManagerUILabel != null) foodManagerUILabel.paddingLeft = 0;
			}
			
			setupHeaderSize();
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			if (foodManagerCalculationsLabel != null)
			{
				foodManagerCalculationsLabel.removeFromParent();
				foodManagerCalculationsLabel.dispose();
				foodManagerCalculationsLabel = null;
			}
			
			if (foodManagerCalculationsSettings != null)
			{
				foodManagerCalculationsSettings.removeFromParent();
				foodManagerCalculationsSettings.dispose();
				foodManagerCalculationsSettings = null;
			}
			
			if (foodManagerUILabel != null)
			{
				foodManagerUILabel.removeFromParent();
				foodManagerUILabel.dispose();
				foodManagerUILabel = null;
			}
			
			if (foodManagerUISettings != null)
			{
				foodManagerUISettings.removeFromParent();
				foodManagerUISettings.dispose();
				foodManagerUISettings = null;
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