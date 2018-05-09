package ui.screens
{
	import flash.system.System;
	
	import feathers.controls.DragGesture;
	import feathers.controls.Label;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.ModelLocator;
	
	import starling.display.DisplayObject;
	import starling.events.Event;
	
	import ui.AppInterface;
	import ui.screens.display.LayoutFactory;
	import ui.screens.display.settings.treatments.CarbsSettingsList;
	import ui.screens.display.settings.treatments.InsulinsSettingsList;
	
	import utils.Constants;
	
	[ResourceBundle("profilesettingsscreen")]

	public class ProfileSettingsScreen extends BaseSubScreen
	{
		/* Display Objects */
		private var insulinsSettings:InsulinsSettingsList;
		private var insulinsLabel:Label;
		private var carbsLabel:Label;
		private var carbsSettings:CarbsSettingsList;
		
		public function ProfileSettingsScreen() 
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
			title = ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','screen_title');
			
			/* Set Header Icon */
			icon = getScreenIcon(MaterialDeepGreyAmberMobileThemeIcons.profileTexture);
			iconContainer = new <DisplayObject>[icon];
			headerProperties.rightItems = iconContainer;
		}
		
		private function setupContent():void
		{
			//Deactivate menu drag gesture 
			AppInterface.instance.drawers.openGesture = DragGesture.NONE;
			
			//Insulins Section Label
			insulinsLabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','insulins_label'), true);
			screenRenderer.addChild(insulinsLabel);
			
			//Insulins Settings
			insulinsSettings = new InsulinsSettingsList();
			screenRenderer.addChild(insulinsSettings);
			
			//Carbs Section Label
			carbsLabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','carbs_label'), true);
			screenRenderer.addChild(carbsLabel);
			
			//Insulins Settings
			carbsSettings = new CarbsSettingsList();
			screenRenderer.addChild(carbsSettings);
		}
		
		/**
		 * Event Handlers
		 */
		override protected function onBackButtonTriggered(event:Event):void
		{
			if (carbsSettings.needsSave)
				carbsSettings.save();
			
			//Activate menu drag gesture
			AppInterface.instance.drawers.openGesture = DragGesture.EDGE;
			
			//Pop Screen
			dispatchEventWith(Event.COMPLETE);
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			if (insulinsLabel != null)
			{
				insulinsLabel.removeFromParent();
				insulinsLabel.dispose();
				insulinsLabel = null;
			}
			
			if (insulinsSettings != null)
			{
				insulinsSettings.removeFromParent();
				insulinsSettings.dispose();
				insulinsSettings = null;
			}
			
			if (carbsLabel != null)
			{
				carbsLabel.removeFromParent();
				carbsLabel.dispose();
				carbsLabel = null;
			}
			
			if (carbsSettings != null)
			{
				carbsSettings.removeFromParent();
				carbsSettings.dispose();
				carbsSettings = null;
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