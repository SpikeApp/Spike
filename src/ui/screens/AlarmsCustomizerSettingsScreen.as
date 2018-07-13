package ui.screens
{
	import flash.system.System;
	
	import feathers.controls.DragGesture;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import starling.display.DisplayObject;
	import starling.events.Event;
	
	import ui.AppInterface;
	import ui.screens.data.AlarmNavigatorData;
	import ui.screens.display.settings.alarms.AlarmCustomizerList;
	
	import utils.Constants;
	
	public class AlarmsCustomizerSettingsScreen extends BaseSubScreen
	{
		/* Display Objects */
		private var alarmCustomizer:AlarmCustomizerList;
		
		/* Properties */
		protected var _options:AlarmNavigatorData;

		public function AlarmsCustomizerSettingsScreen() 
		{
			super();;
			
			setupHeader();
		}
		
		override protected function initialize():void 
		{
			super.initialize();
		}
		
		/**
		 * Functionality
		 */
		private function setupHeader():void
		{
			/* Set Header Icon */
			icon = getScreenIcon(MaterialDeepGreyAmberMobileThemeIcons.alarmTexture);
			iconContainer = new <DisplayObject>[icon];
			headerProperties.rightItems = iconContainer;
		}
		
		private function setupContent():void
		{
			/* Set Header Title */
			title = _options.alarmTitle;
			
			//Deactivate menu drag gesture 
			AppInterface.instance.drawers.openGesture = DragGesture.NONE;
			
			//Display Objects
			alarmCustomizer = new AlarmCustomizerList(_options.alarmID, _options.alarmType);
			screenRenderer.addChild(alarmCustomizer);
		}
		
		private function adjustMainMenu():void
		{
			AppInterface.instance.menu.selectedIndex = Constants.isPortrait ? 4 : 3;
		}
		
		/**
		 * Event Listeners
		 */
		override protected function onBackButtonTriggered(event:Event):void
		{
			alarmCustomizer.closeCallout();
			
			if(alarmCustomizer.needsSave)
				alarmCustomizer.save();
			
			//Activate menu drag gesture
			AppInterface.instance.drawers.openGesture = DragGesture.EDGE;
			
			dispatchEventWith(Event.COMPLETE);
		}
		
		override protected function onTransitionInComplete(e:Event):void
		{
			//Swipe to pop functionality
			AppInterface.instance.navigator.isSwipeToPopEnabled = true;
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			if (alarmCustomizer != null)
			{
				alarmCustomizer.removeFromParent();
				alarmCustomizer.dispose();
				alarmCustomizer = null;
			}
			
			super.dispose();
			
			System.pauseForGCIfCollectionImminent(0);
		}
		
		override protected function draw():void 
		{
			var layoutInvalid:Boolean = isInvalid( INVALIDATION_FLAG_LAYOUT );
			super.draw();
			icon.x = Constants.stageWidth - icon.width - BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding;
		}

		/**
		 * Getters & Setters
		 */
		public function get options():AlarmNavigatorData
		{
			return _options;
		}

		public function set options(value:AlarmNavigatorData):void
		{	
			_options = value;
			
			setupContent();
			adjustMainMenu();
			this.invalidate( INVALIDATION_FLAG_DATA );
		}
	}
}