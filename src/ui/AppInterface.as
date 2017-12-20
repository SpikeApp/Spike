package ui
{
	import data.AlarmNavigatorData;
	
	import display.menu.MenuList;
	
	import events.ScreenEvent;
	
	import feathers.controls.Drawers;
	import feathers.controls.StackScreenNavigator;
	import feathers.controls.StackScreenNavigatorItem;
	import feathers.motion.Cover;
	import feathers.motion.Reveal;
	import feathers.motion.Slide;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeWithIcons;
	
	import screens.AboutSettingsScreen;
	import screens.AlarmsCustomizerSettingsScreen;
	import screens.AlarmsSettingsScreen;
	import screens.AlertTypeCustomizerScreen;
	import screens.AlertTypesListScreen;
	import screens.ChartScreen;
	import screens.ChartSettingsScreen;
	import screens.DisclaimerScreen;
	import screens.FullScreenGlucoseScreen;
	import screens.GeneralSettingsScreen;
	import screens.LoggingTracingSettingsScreen;
	import screens.MainSettingsScreen;
	import screens.Screens;
	import screens.SensorScreen;
	import screens.SensorStartScreen;
	import screens.ShareSettingsScreen;
	import screens.SpeechSettingsScreen;
	import screens.TransmitterScreen;
	import screens.TransmitterSettingsScreen;
	
	import starling.animation.Transitions;
	import starling.display.Sprite;
	import starling.events.Event;
	
	public class AppInterface extends Sprite 
	{
		/* Display Objetcts */
		private static var _instance:AppInterface;
		public var menu:MenuList;
		public var drawers:Drawers;
		public var navigator:StackScreenNavigator;
		
		public function AppInterface() 
		{
			super();
			_instance = this;
		}
		
		public function start():void 
		{
			InterfaceController.init();
		}
		
		public function init():void
		{
			/* Init Theme */
			new MaterialDeepGreyAmberMobileThemeWithIcons();
			
			/* Screen Navigator */
			navigator = new StackScreenNavigator();
			navigator.pushTransition = Slide.createSlideLeftTransition(0.6, Transitions.EASE_IN_OUT);
			navigator.popTransition = Slide.createSlideRightTransition(0.6, Transitions.EASE_IN_OUT);
			
			/* Chart Screen */
			var chartScreenItem:StackScreenNavigatorItem = new StackScreenNavigatorItem( ChartScreen );
			chartScreenItem.pushTransition = Cover.createCoverUpTransition(0.6, Transitions.EASE_IN_OUT);
			chartScreenItem.popTransition = Reveal.createRevealDownTransition(0.6, Transitions.EASE_IN_OUT);
			navigator.addScreen( Screens.GLUCOSE_CHART, chartScreenItem );
			
			/* Fullscreen Glucose Screen */
			var fullScreenGlucoseScreenItem:StackScreenNavigatorItem = new StackScreenNavigatorItem( FullScreenGlucoseScreen );
			fullScreenGlucoseScreenItem.pushTransition = Cover.createCoverUpTransition(0.6, Transitions.EASE_IN_OUT);
			fullScreenGlucoseScreenItem.popTransition = Reveal.createRevealDownTransition(0.6, Transitions.EASE_IN_OUT);
			fullScreenGlucoseScreenItem.addPopEvent(Event.COMPLETE);
			navigator.addScreen( Screens.FULLSCREEN_GLUCOSE, fullScreenGlucoseScreenItem );
			
			/* Sensor Screen */
			var sensorScreenItem:StackScreenNavigatorItem = new StackScreenNavigatorItem( SensorScreen );
			sensorScreenItem.pushTransition = Cover.createCoverUpTransition(0.6, Transitions.EASE_IN_OUT);
			sensorScreenItem.popTransition = Reveal.createRevealDownTransition(0.6, Transitions.EASE_IN_OUT);
			sensorScreenItem.addPopEvent(Event.COMPLETE);
			navigator.addScreen( Screens.SENSOR_STATUS, sensorScreenItem );
			
			/* Sensor Screen */
			var sensorStartScreenItem:StackScreenNavigatorItem = new StackScreenNavigatorItem( SensorStartScreen );
			sensorStartScreenItem.addPopEvent(Event.COMPLETE);
			navigator.addScreen( Screens.SENSOR_START, sensorStartScreenItem );
			
			/* Transmitter Screen */
			var transmitterScreenItem:StackScreenNavigatorItem = new StackScreenNavigatorItem( TransmitterScreen );
			transmitterScreenItem.pushTransition = Cover.createCoverUpTransition(0.6, Transitions.EASE_IN_OUT);
			transmitterScreenItem.popTransition = Reveal.createRevealDownTransition(0.6, Transitions.EASE_IN_OUT);
			transmitterScreenItem.addPopEvent(Event.COMPLETE);
			navigator.addScreen( Screens.TRANSMITTER, transmitterScreenItem );
			
			/* Main Settings Screen */
			var settingsScreenItem:StackScreenNavigatorItem = new StackScreenNavigatorItem( MainSettingsScreen );
			settingsScreenItem.pushTransition = Cover.createCoverUpTransition(0.6, Transitions.EASE_IN_OUT);
			settingsScreenItem.popTransition = Reveal.createRevealDownTransition(0.6, Transitions.EASE_IN_OUT);
			settingsScreenItem.addPopEvent(Event.COMPLETE);
			navigator.addScreen( Screens.SETTINGS_MAIN, settingsScreenItem );
			
			/* General Settings Screen */
			var generalSettingsScreenItem:StackScreenNavigatorItem = new StackScreenNavigatorItem( GeneralSettingsScreen );
			generalSettingsScreenItem.addPopEvent(Event.COMPLETE);
			navigator.addScreen( Screens.SETTINGS_GENERAL, generalSettingsScreenItem );
			
			/* Transmitter Settings Screen */
			var transmitterSettingsScreenItem:StackScreenNavigatorItem = new StackScreenNavigatorItem( TransmitterSettingsScreen );
			transmitterSettingsScreenItem.addPopEvent(Event.COMPLETE);
			navigator.addScreen( Screens.SETTINGS_TRANSMITTER, transmitterSettingsScreenItem );
			
			/* Chart Settings Screen */
			var chartSettingsScreenItem:StackScreenNavigatorItem = new StackScreenNavigatorItem( ChartSettingsScreen );
			chartSettingsScreenItem.addPopEvent(Event.COMPLETE);
			navigator.addScreen( Screens.SETTINGS_CHART, chartSettingsScreenItem );
			
			/* Alarms Settings Screen */
			var alarmsSettingsScreenItem:StackScreenNavigatorItem = new StackScreenNavigatorItem( AlarmsSettingsScreen );
			alarmsSettingsScreenItem.addPopEvent(Event.COMPLETE);
			navigator.addScreen( Screens.SETTINGS_ALARMS, alarmsSettingsScreenItem );
			
			/* Alert Types List Settings Screen */
			var alertTypesSettingsScreenItem:StackScreenNavigatorItem = new StackScreenNavigatorItem( AlertTypesListScreen );
			alertTypesSettingsScreenItem.addPopEvent(Event.COMPLETE);
			navigator.addScreen( Screens.SETTINGS_ALERT_TYPES_LIST, alertTypesSettingsScreenItem );
			
			/* Alert Type Customizer Settings Screen */
			var alertTypeCustomizerScreenItem:StackScreenNavigatorItem = new StackScreenNavigatorItem( AlertTypeCustomizerScreen );
			alertTypeCustomizerScreenItem.addPopEvent(Event.COMPLETE);
			navigator.addScreen( Screens.SETTINGS_ALERT_TYPE_CUSTOMIZER, alertTypeCustomizerScreenItem );
			
			/* Alarms Customizer Settings Screen */
			var alarmNavigatorData:AlarmNavigatorData = AlarmNavigatorData.getInstance();
			
			var alarmsCustomizerSettingsScreenItem:StackScreenNavigatorItem = new StackScreenNavigatorItem( AlarmsCustomizerSettingsScreen );
			alarmsCustomizerSettingsScreenItem.properties.options = alarmNavigatorData;
			alarmsCustomizerSettingsScreenItem.addPopEvent(Event.COMPLETE);
			navigator.addScreen( Screens.SETTINGS_ALARMS_CUSTOMIZER, alarmsCustomizerSettingsScreenItem );
			
			/* Speech Settings Screen */
			var speechSettingsScreenItem:StackScreenNavigatorItem = new StackScreenNavigatorItem( SpeechSettingsScreen );
			speechSettingsScreenItem.addPopEvent(Event.COMPLETE);
			navigator.addScreen( Screens.SETTINGS_SPEECH, speechSettingsScreenItem );
			
			/* Share Settings Screen */
			var shareSettingsScreenItem:StackScreenNavigatorItem = new StackScreenNavigatorItem( ShareSettingsScreen );
			shareSettingsScreenItem.addPopEvent(Event.COMPLETE);
			navigator.addScreen( Screens.SETTINGS_SHARE, shareSettingsScreenItem );
			
			/* Logging/Tracing Settings Screen */
			var loggingTracingSettingsScreenItem:StackScreenNavigatorItem = new StackScreenNavigatorItem( LoggingTracingSettingsScreen );
			loggingTracingSettingsScreenItem.addPopEvent(Event.COMPLETE);
			navigator.addScreen( Screens.SETTINGS_LOGGING_TRACING, loggingTracingSettingsScreenItem );
			
			/* About Settings Screen */
			var aboutSettingsScreenItem:StackScreenNavigatorItem = new StackScreenNavigatorItem( AboutSettingsScreen );
			aboutSettingsScreenItem.addPopEvent(Event.COMPLETE);
			navigator.addScreen( Screens.SETTINGS_ABOUT, aboutSettingsScreenItem );
			
			/* Disclaimer Screen */
			var disclaimerScreenItem:StackScreenNavigatorItem = new StackScreenNavigatorItem( DisclaimerScreen );
			disclaimerScreenItem.pushTransition = Cover.createCoverUpTransition(0.6, Transitions.EASE_IN_OUT);
			disclaimerScreenItem.popTransition = Reveal.createRevealDownTransition(0.6, Transitions.EASE_IN_OUT);
			disclaimerScreenItem.addPopEvent(Event.COMPLETE);
			navigator.addScreen( Screens.DISCLAIMER, disclaimerScreenItem );
			
			/* Screen Navigator */
			navigator.rootScreenID = Screens.GLUCOSE_CHART;
			
			/* Main Menu */
			menu = new MenuList();
			menu.addEventListener( ScreenEvent.SWITCH, onScreenSwitch );
			
			/* Drawers */
			drawers = new Drawers( navigator );
			drawers.leftDrawer = menu;
			drawers.clipDrawers = false;
			drawers.leftDrawerToggleEventType = ScreenEvent.TOGGLE_MENU;
			addChild( drawers );
		}
		
		private function onScreenSwitch( event:Event ):void 
		{
			drawers.toggleLeftDrawer();
			navigator.pushScreen( event.data.screen );
		}

		public static function get instance():AppInterface
		{
			return _instance;
		}
	}
}
