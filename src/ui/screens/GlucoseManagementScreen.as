package ui.screens
{
	import flash.system.System;
	
	import feathers.controls.DragGesture;
	import feathers.events.FeathersEventType;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.ModelLocator;
	
	import starling.display.DisplayObject;
	import starling.events.Event;
	import starling.textures.Texture;
	
	import ui.AppInterface;
	import ui.screens.display.readings.ReadingsManagementList;
	
	import utils.Constants;
	
	[ResourceBundle("glucosemanagementscreen")]

	public class GlucoseManagementScreen extends BaseSubScreen
	{
		/* Display Objects */
		private var readingsSection:ReadingsManagementList;
		private var iconTexture:Texture;
		
		public function GlucoseManagementScreen() 
		{
			super();
			
			setupHeader();	
		}
		override protected function initialize():void 
		{
			super.initialize();
			
			addEventListener(FeathersEventType.TRANSITION_IN_COMPLETE, onTransitionComplete);
			setupContent();
		}
		
		/**
		 * Functionality
		 */
		private function setupHeader():void
		{
			/* Set Header Title */
			title = ModelLocator.resourceManagerInstance.getString('glucosemanagementscreen','screen_title');
			
			/* Set Header Icon */
			iconTexture = MaterialDeepGreyAmberMobileThemeIcons.readingsTexture;
			icon = getScreenIcon(iconTexture);
			iconContainer = new <DisplayObject>[icon];
			headerProperties.rightItems = iconContainer;
		}
		
		private function setupContent():void
		{
			//Deactivate menu drag gesture 
			AppInterface.instance.drawers.openGesture = DragGesture.NONE;
			
			//About Section
			readingsSection = new ReadingsManagementList();
			screenRenderer.addChild(readingsSection);
		}
		
		/**
		 * Event Handlers
		 */
		private function onTransitionComplete(e:Event):void
		{
			readingsSection.populateReadings();
		}
		
		override protected function onBackButtonTriggered(event:Event):void
		{
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
			if (iconTexture != null)
			{
				iconTexture.dispose();
				iconTexture = null;
			}
			
			if (icon != null)
			{
				icon.removeFromParent();
				icon.dispose();
				icon = null;
			}
			
			if (readingsSection != null)
			{
				readingsSection.removeFromParent();
				readingsSection.dispose();
				readingsSection = null;
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