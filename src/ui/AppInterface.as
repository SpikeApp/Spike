package ui
{
	//import com.demonsters.debugger.MonsterDebugger;
	
	import events.ScreenEvent;
	
	import feathers.controls.Drawers;
	import feathers.controls.StackScreenNavigator;
	import feathers.controls.StackScreenNavigatorItem;
	import feathers.motion.Cover;
	import feathers.motion.Reveal;
	import feathers.motion.Slide;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeWithIcons;
	
	import starling.animation.Transitions;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.utils.SystemUtil;
	
	import ui.screens.AboutScreen;
	import ui.screens.AdvancedSettingsScreen;
	import ui.screens.AlarmsCustomizerSettingsScreen;
	import ui.screens.AlarmsSettingsScreen;
	import ui.screens.AlertTypesListScreen;
	import ui.screens.BugReportScreen;
	import ui.screens.ChartScreen;
	import ui.screens.ChartSettingsScreen;
	import ui.screens.DisclaimerScreen;
	import ui.screens.FullScreenGlucoseScreen;
	import ui.screens.GeneralSettingsScreen;
	import ui.screens.GlucoseManagementScreen;
	import ui.screens.HelpScreen;
	import ui.screens.IFTTTSettingsScreen;
	import ui.screens.IntegrationSettingsScreen;
	import ui.screens.MainSettingsScreen;
	import ui.screens.NightscoutViewScreen;
	import ui.screens.ProfileSettingsScreen;
	import ui.screens.Screens;
	import ui.screens.SensorScreen;
	import ui.screens.SensorStartScreen;
	import ui.screens.ShareSettingsScreen;
	import ui.screens.SpeechSettingsScreen;
	import ui.screens.TransmitterScreen;
	import ui.screens.TransmitterSettingsScreen;
	import ui.screens.TreatmentsManagementScreen;
	import ui.screens.TreatmentsSettingsScreen;
	import ui.screens.WatchSettingsScreen;
	import ui.screens.WidgetSettingsScreen;
	import ui.screens.data.AlarmNavigatorData;
	import ui.screens.display.menu.MenuList;
	
	import utils.Constants;
	import utils.DeviceInfo;
	
	public class AppInterface extends Sprite 
	{
		/* Display Objetcts */
		private static var _instance:AppInterface;
		public var menu:MenuList;
		public var drawers:Drawers;
		public var navigator:StackScreenNavigator;
		public var chartSettingsScreenItem:StackScreenNavigatorItem;
		private var spikeIsActive:Boolean = false;
		
		public function AppInterface() 
		{
			_instance = this;
			
			/*MonsterDebugger.initialize(this);
			MonsterDebugger.trace(this, "Hello World!");*/
		}
		
		public function start():void 
		{
			if (!spikeIsActive)
			{
				spikeIsActive = true;
				
				Constants.deviceModel = DeviceInfo.getDeviceType();
	
				SystemUtil.executeWhenApplicationIsActive( InterfaceController.init );
			}
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
			
			/* Glucose Management Screen */
			var glucoseManagementScreenItem:StackScreenNavigatorItem = new StackScreenNavigatorItem( GlucoseManagementScreen );
			glucoseManagementScreenItem.pushTransition = Cover.createCoverUpTransition(0.6, Transitions.EASE_IN_OUT);
			glucoseManagementScreenItem.popTransition = Reveal.createRevealDownTransition(0.6, Transitions.EASE_IN_OUT);
			glucoseManagementScreenItem.addPopEvent(Event.COMPLETE);
			navigator.addScreen( Screens.GLUCOSE_MANAGEMENT, glucoseManagementScreenItem );
			
			/* Nightscout View Screen */
			var nightscoutViewScreenItem:StackScreenNavigatorItem = new StackScreenNavigatorItem( NightscoutViewScreen );
			nightscoutViewScreenItem.pushTransition = Cover.createCoverUpTransition(0.6, Transitions.EASE_IN_OUT);
			nightscoutViewScreenItem.popTransition = Reveal.createRevealDownTransition(0.6, Transitions.EASE_IN_OUT);
			nightscoutViewScreenItem.addPopEvent(Event.COMPLETE);
			navigator.addScreen( Screens.NIGHTSCOUT_VIEW, nightscoutViewScreenItem );
			
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
			
			/* Treatments Settings Screen */
			var treatmentsSettingsScreenItem:StackScreenNavigatorItem = new StackScreenNavigatorItem( TreatmentsSettingsScreen );
			treatmentsSettingsScreenItem.addPopEvent(Event.COMPLETE);
			navigator.addScreen( Screens.SETTINGS_TREATMENTS, treatmentsSettingsScreenItem );
			
			/* Profile Settings Screen */
			var profileSettingsScreenItem:StackScreenNavigatorItem = new StackScreenNavigatorItem( ProfileSettingsScreen );
			profileSettingsScreenItem.addPopEvent(Event.COMPLETE);
			navigator.addScreen( Screens.SETTINGS_PROFILE, profileSettingsScreenItem );
			
			/* Chart Settings Screen */
			chartSettingsScreenItem = new StackScreenNavigatorItem( ChartSettingsScreen );
			chartSettingsScreenItem.addPopEvent(Event.COMPLETE);
			navigator.addScreen( Screens.SETTINGS_CHART, chartSettingsScreenItem );
			
			/* Widget Settings Screen */
			var widgetSettingsScreenItem:StackScreenNavigatorItem = new StackScreenNavigatorItem( WidgetSettingsScreen );
			widgetSettingsScreenItem.addPopEvent(Event.COMPLETE);
			navigator.addScreen( Screens.SETTINGS_WIDGET, widgetSettingsScreenItem );
			
			/* Alarms Settings Screen */
			var alarmsSettingsScreenItem:StackScreenNavigatorItem = new StackScreenNavigatorItem( AlarmsSettingsScreen );
			alarmsSettingsScreenItem.addPopEvent(Event.COMPLETE);
			navigator.addScreen( Screens.SETTINGS_ALARMS, alarmsSettingsScreenItem );
			
			/* Alert Types List Settings Screen */
			var alertTypesSettingsScreenItem:StackScreenNavigatorItem = new StackScreenNavigatorItem( AlertTypesListScreen );
			alertTypesSettingsScreenItem.addPopEvent(Event.COMPLETE);
			navigator.addScreen( Screens.SETTINGS_ALERT_TYPES_LIST, alertTypesSettingsScreenItem );
			
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
			
			/* Integration Settings Screen */
			var integrationSettingsScreenItem:StackScreenNavigatorItem = new StackScreenNavigatorItem( IntegrationSettingsScreen );
			integrationSettingsScreenItem.addPopEvent(Event.COMPLETE);
			navigator.addScreen( Screens.SETTINGS_INTEGRATION, integrationSettingsScreenItem );
			
			/* Watch Settings Screen */
			var watchSettingsScreenItem:StackScreenNavigatorItem = new StackScreenNavigatorItem( WatchSettingsScreen );
			watchSettingsScreenItem.addPopEvent(Event.COMPLETE);
			navigator.addScreen( Screens.SETTINGS_APPLE_WATCH, watchSettingsScreenItem );
			
			/* Advanced Settings Screen */
			var advancedSettingsScreenItem:StackScreenNavigatorItem = new StackScreenNavigatorItem( AdvancedSettingsScreen );
			advancedSettingsScreenItem.addPopEvent(Event.COMPLETE);
			navigator.addScreen( Screens.SETTINGS_ADVANCED, advancedSettingsScreenItem );
			
			/* About Settings Screen */
			var aboutSettingsScreenItem:StackScreenNavigatorItem = new StackScreenNavigatorItem( AboutScreen );
			aboutSettingsScreenItem.addPopEvent(Event.COMPLETE);
			navigator.addScreen( Screens.SETTINGS_ABOUT, aboutSettingsScreenItem );
			
			/* IFTTT Settings Screen */
			var IFTTTSettingsScreenItem:StackScreenNavigatorItem = new StackScreenNavigatorItem( IFTTTSettingsScreen );
			IFTTTSettingsScreenItem.addPopEvent(Event.COMPLETE);
			navigator.addScreen( Screens.SETTINGS_IFTTT, IFTTTSettingsScreenItem );
			
			/* Help Screen */
			var helpScreenItem:StackScreenNavigatorItem = new StackScreenNavigatorItem( HelpScreen );
			helpScreenItem.pushTransition = Cover.createCoverUpTransition(0.6, Transitions.EASE_IN_OUT);
			helpScreenItem.popTransition = Reveal.createRevealDownTransition(0.6, Transitions.EASE_IN_OUT);
			helpScreenItem.addPopEvent(Event.COMPLETE);
			navigator.addScreen( Screens.HELP, helpScreenItem );
			
			/* Bug Report Screen */
			var bugReportScreenItem:StackScreenNavigatorItem = new StackScreenNavigatorItem( BugReportScreen );
			bugReportScreenItem.pushTransition = Cover.createCoverUpTransition(0.6, Transitions.EASE_IN_OUT);
			bugReportScreenItem.popTransition = Reveal.createRevealDownTransition(0.6, Transitions.EASE_IN_OUT);
			bugReportScreenItem.addPopEvent(Event.COMPLETE);
			navigator.addScreen( Screens.SETTINGS_BUG_REPORT, bugReportScreenItem );
			
			/* Disclaimer Screen */
			var disclaimerScreenItem:StackScreenNavigatorItem = new StackScreenNavigatorItem( DisclaimerScreen );
			disclaimerScreenItem.pushTransition = Cover.createCoverUpTransition(0.6, Transitions.EASE_IN_OUT);
			disclaimerScreenItem.popTransition = Reveal.createRevealDownTransition(0.6, Transitions.EASE_IN_OUT);
			disclaimerScreenItem.addPopEvent(Event.COMPLETE);
			navigator.addScreen( Screens.DISCLAIMER, disclaimerScreenItem );
			
			/* Treatments Management Screen */
			var treatmentsManagementScreenItem:StackScreenNavigatorItem = new StackScreenNavigatorItem( TreatmentsManagementScreen );
			treatmentsManagementScreenItem.pushTransition = Cover.createCoverUpTransition(0.6, Transitions.EASE_IN_OUT);
			treatmentsManagementScreenItem.popTransition = Reveal.createRevealDownTransition(0.6, Transitions.EASE_IN_OUT);
			treatmentsManagementScreenItem.addPopEvent(Event.COMPLETE);
			navigator.addScreen( Screens.ALL_TREATMENTS, treatmentsManagementScreenItem );
			
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
