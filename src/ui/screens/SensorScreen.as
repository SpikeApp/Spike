package ui.screens
{
	import flash.system.System;
	
	import feathers.controls.ScrollPolicy;
	import feathers.events.FeathersEventType;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.ModelLocator;
	
	import services.TutorialService;
	
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.events.Event;
	
	import ui.AppInterface;
	import ui.screens.display.sensor.SensorStartStopList;
	
	import utils.Constants;
	
	[ResourceBundle("sensorscreen")]
	
	public class SensorScreen extends BaseSubScreen
	{	
		/* Display Objects */
		private var statusList:SensorStartStopList;
		
		public function SensorScreen() 
		{
			super();
			
			setupProperties();	
		}
		
		override protected function initialize():void 
		{
			super.initialize();
			
			setupScreen();
			adjustMainMenu();
			setupEventHandlers();
			
			this.horizontalScrollPolicy = ScrollPolicy.OFF;
		}
		
		/**
		 * Functionality
		 */
		private function setupProperties():void
		{
			/* Set Header Title */
			title = ModelLocator.resourceManagerInstance.getString('sensorscreen','screen_title');
			
			/* Set Header Icon */
			icon = getScreenIcon(MaterialDeepGreyAmberMobileThemeIcons.sensorTexture);
			iconContainer = new <DisplayObject>[icon];
			headerProperties.rightItems = iconContainer;
		}
		
		private function setupScreen():void
		{
			statusList = new SensorStartStopList();
			screenRenderer.addChild(statusList);
		}
		
		private function adjustMainMenu():void
		{
			AppInterface.instance.menu.selectedIndex = Constants.isPortrait ? 2 : 1;
		}
		
		private function setupEventHandlers():void
		{
			if( TutorialService.isActive && TutorialService.eighthStepActive)
				addEventListener(FeathersEventType.TRANSITION_IN_COMPLETE, onScreenIn);
		}
		
		/**
		 * Event Handlers
		 */
		private function onScreenIn(e:Event):void
		{
			if( TutorialService.isActive)
				removeEventListener(FeathersEventType.TRANSITION_IN_COMPLETE, onScreenIn);
			
			if( TutorialService.isActive && TutorialService.eighthStepActive)
				Starling.juggler.delayCall(TutorialService.ninethStep, .2);
		}
		
		override protected function onTransitionInComplete(e:Event):void
		{
			//Swipe to pop functionality
			AppInterface.instance.navigator.isSwipeToPopEnabled = false;
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			if (statusList != null)
			{
				statusList.removeFromParent();
				statusList.dispose();
				statusList = null;
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