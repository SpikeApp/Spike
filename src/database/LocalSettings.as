package database
{
	import flash.events.EventDispatcher;
	
	import events.SettingsServiceEvent;

	/**
	 * local settings are settings specific to this device, ie settings that will not be synchronized among different devices.
	 */
	 public class LocalSettings extends EventDispatcher
	{
		private static var _instance:LocalSettings = new LocalSettings();

		public static function get instance():LocalSettings
		{
			return _instance;
		}

		/**
		 * detailed tracing enabled or not
		 */
		public static const LOCAL_SETTING_DETAILED_TRACING_ENABLED:int = 0; 
		/**
		 * filename for local tracing, empty string if currently no tracing 
		 */
		public static const LOCAL_SETTING_TRACE_FILE_NAME:int = 1;
		/**
		 * When user configures nightscout url and api secret, a test is done.<br>
		 * If that fails a dialog is shown<br>
		 * This indicates if that dialog has already been shown before or not, to avoid multiple pop ups.
		 */
		public static const LOCAL_SETTING_WARNING_THAT_NIGHTSCOUT_URL_AND_SECRET_IS_NOT_OK_ALREADY_GIVEN:int = 2;
		/**
		 * Permanent notification on home screen on or off 
		 */
		public static const LOCAL_SETTING_ALWAYS_ON_NOTIFICATION:int = 3;
		/**
		 * device token for remote push notifications 
		 */
		public static const LOCAL_SETTING_DEVICE_TOKEN_ID:int = 4;

		public static const LOCAL_SETTING_UDID_NOT_USED_ANYMORE:int = 5;

		public static const LOCAL_SETTING_SUBSCRIBED_TO_PUSH_NOTIFICATIONS_NOT_USED_ANYMORE:int = 6;
		/**
		 * use nslog, true or false
		 */
		public static const LOCAL_SETTING_NSLOG:int = 7;

		public static const LOCAL_SETTING_WISHED_QBLOX_SUBSCRIPTION_TAG_NOT_USED_ANYMORE:int = 8;

		public static const LOCAL_SETTING_ACTUAL_QBLOX_SUBSCRIPTION_TAG_NOT_USED_ANYMORE:int = 9;
		/**
		 * taken over from Android version xdripplus 
		 */
		public static const LOCAL_SETTING_G5_ALWAYS_AUTHENTICATE:int = 10;
		/**
		 * taken over from Android version xdripplus 
		 */
		public static const LOCAL_SETTING_G5_ALWAYS_UNBOUND:int = 11;
		public static const LOCAL_SETTING_FromtimeAndValueListView_INFO_SHOWN:int = 12;
		/**
		 * if user starts editing missed reading alerts, a warning will be shown that this only works guaranteed if Internet is on 
		 */
		public static const LOCAL_SETTING_MISSED_READING_WARNING_GIVEN_NOT_USED_ANYMORE:int = 13;
		public static const LOCAL_SETTING_PHONE_MUTED_WARNING_GIVEN:int = 14;
		public static const LOCAL_SETTING_TRACE_FILE_PATH_NAME:int = 15;
		public static const LOCAL_SETTING_FROM_TIME_AND_VALUE_ELEMENT_VIEW_VALUE_INFO_GIVEN:int = 16;
		public static const LOCAL_SETTING_LOW_BATTERY_WARNING_GIVEN:int = 17;
		public static const LOCAL_SETTING_CALIBRATION_REQUEST_ALERT_WARNING_GIVEN:int = 18;
		/**
		 * latest application version. First time introduced is version 0.0.46, that's why it's the default value
		 */
		public static const LOCAL_SETTING_APPLICATION_VERSION:int = 19;
		public static const LOCAL_SETTING_CHART_RANGE_INFO_GIVEN:int = 20;
		public static const LOCAL_SETTING_INFO_ABOUT_LONG_PRESS_IN_HOME_SCREEN_GIVEN:int = 21;
		public static const LOCAL_SETTING_HEALTHKIT_STORE_ON:int = 22;
		public static const LOCAL_SETTING_LICENSE_INFO_ACCEPTED:int = 23;
		public static const LOCAL_SETTING_SELECTION_UNIT_DONE:int = 24;
		/**
		 * for G4. in case xdrip has wxl code which doesn't support writing transmitter id from app to xdrip, then Spike can give info and propose user to send
		 * new wxl code that supports this.
		 */
		public static const LOCAL_SETTING_TIMESTAMP_SINCE_LAST_WARNING_OLD_WXL_CODE_USED:int = 25;
		/**
		 * for G4. in case xdrip has wxl code which doesn't support writing transmitter id from app to xdrip, then Spike can give info and propose user to send
		 * new wxl code that supports this.
		 */
		public static const LOCAL_SETTING_DONTASKAGAIN_ABOUT_OLD_WXL_CODE_USED:int = 26;
		public static const LOCAL_SETTING_SPEECH_INSTRUCTIONS_ACCEPTED:int = 27;
		public static const LOCAL_SETTING_OVERRIDE_MUTE:int = 28;
		public static const LOCAL_SETTING_UPDATE_SERVICE_INITIALCHECK:int = 29;
		public static const LOCAL_SETTING_ALWAYS_ON_APP_BADGE:int = 30;
		public static const LOCAL_SETTING_REMOTE_ALERT_LAST_ID:int = 31;
		public static const LOCAL_SETTING_REMOTE_ALERT_LAST_CHECK_TIMESTAMP:int = 32;
		
		/**
		 * Apple Watch
		 */
		public static const LOCAL_SETTING_WATCH_COMPLICATION_ON:int = 33;
		public static const LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_NAME_ON:int = 34;
		public static const LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_NAME:int = 35;
		public static const LOCAL_SETTING_WATCH_COMPLICATION_SELECTED_CALENDAR_ID:int = 36;
		public static const LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_TREND:int = 37;
		public static const LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_DELTA:int = 38;
		public static const LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_UNITS:int = 39;
		public static const LOCAL_SETTING_WATCH_COMPLICATION_GLUCOSE_HISTORY:int = 40;
		
		/**
		 * Loop Integration
		 */
		public static const LOCAL_SETTING_LOOP_SERVER_ON:int = 41;
		public static const LOCAL_SETTING_LOOP_SERVER_USERNAME:int = 42;
		public static const LOCAL_SETTING_LOOP_SERVER_PASSWORD:int = 43;
		
		/**
		 * Sidiary
		 */
		public static const LOCAL_SETTING_TIMESTAMP_SINCE_LAST_EXPORT_SIDIARY:int = 44;
		
		/**
		 * Transmiter PL
		 */
		public static const LOCAL_SETTING_TRANSMITER_PL_AMOUNT_OF_INVALID_SENSOR_AGE_VALUES:int = 45;
		
		/**
		 * App Inactive Alert
		 */
		public static const LOCAL_SETTING_APP_INACTIVE_ALERT:int = 46;
		/**
		 * If user has other app running that connects to the same G5 transmitter, this will not work<br>
		 * The app is trying to detect this situation, to avoid complaints<br>
		 * However the detection mechanism sometimes thinks there's another app trying to connect althought this is not the case<br>
		 * Therefore the amount of notifications will be reduced, this setting counts the number
		 */
		public static const LOCAL_SETTING_AMOUNT_OF_WARNINGS_OTHER_APP:int = 47;
		
		/**
		 * Always on notification interval.
		 * This setting defines the interval (in readings) for the firing of the always on notifications
		 */
		public static const LOCAL_SETTING_ALWAYS_ON_NOTIFICATION_INTERVAL:int = 48;
		
		/**
		 * Apple Watch#2
		 */
		public static const LOCAL_SETTING_WATCH_COMPLICATION_GAP_FIX_ON:int = 49;
		
		/**
		 * IFTTT
		 */
		public static const LOCAL_SETTING_IFTTT_ON:int = 50;
		public static const LOCAL_SETTING_IFTTT_URGENT_HIGH_TRIGGERED_ON:int = 51;
		public static const LOCAL_SETTING_IFTTT_URGENT_HIGH_SNOOZED_ON:int = 52;
		public static const LOCAL_SETTING_IFTTT_HIGH_TRIGGERED_ON:int = 53;
		public static const LOCAL_SETTING_IFTTT_HIGH_SNOOZED_ON:int = 54;
		public static const LOCAL_SETTING_IFTTT_LOW_TRIGGERED_ON:int = 55;
		public static const LOCAL_SETTING_IFTTT_LOW_SNOOZED_ON:int = 56;
		public static const LOCAL_SETTING_IFTTT_URGENT_LOW_TRIGGERED_ON:int = 57;
		public static const LOCAL_SETTING_IFTTT_URGENT_LOW_SNOOZED_ON:int = 58;
		public static const LOCAL_SETTING_IFTTT_MISSED_READINGS_TRIGGERED_ON:int = 59;
		public static const LOCAL_SETTING_IFTTT_MISSED_READINGS_SNOOZED_ON:int = 60;
		public static const LOCAL_SETTING_IFTTT_CALIBRATION_TRIGGERED_ON:int = 61;
		public static const LOCAL_SETTING_IFTTT_CALIBRATION_SNOOZED_ON:int = 62;
		public static const LOCAL_SETTING_IFTTT_PHONE_MUTED_TRIGGERED_ON:int = 63;
		public static const LOCAL_SETTING_IFTTT_PHONE_MUTED_SNOOZED_ON:int = 64;
		public static const LOCAL_SETTING_IFTTT_TRANSMITTER_LOW_BATTERY_TRIGGERED_ON:int = 65;
		public static const LOCAL_SETTING_IFTTT_TRANSMITTER_LOW_BATTERY_SNOOZED_ON:int = 66;
		public static const LOCAL_SETTING_IFTTT_GLUCOSE_READING_ON:int = 67;
		public static const LOCAL_SETTING_IFTTT_MAKER_KEY:int = 68;
		public static const LOCAL_SETTING_IFTTT_GLUCOSE_THRESHOLDS_ON:int = 69;
		public static const LOCAL_SETTING_IFTTT_GLUCOSE_HIGH_THRESHOLD:int = 70;
		public static const LOCAL_SETTING_IFTTT_GLUCOSE_LOW_THRESHOLD:int = 71;
		public static const LOCAL_SETTING_IFTTT_HTTP_SERVER_ERRORS_ON:int = 72;
		
		/**
		 * App Badge #2
		 */
		public static const LOCAL_SETTING_APP_BADGE_MMOL_MULTIPLIER_ON:int = 73;
		
		/**
		 * Values in bugreport screen (email address, name). Will be saved so that user doesn't need to retype them everytime<br>
		 * Default empty string
		 */
		public static const LOCAL_SETTING_BUG_REPORT_EMAIL:int = 74;
		public static const LOCAL_SETTING_BUG_REPORT_NAME:int = 75;
		
		/**
		 * Apple Watch#3
		 */
		public static const LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_IOB_ON:int = 76;
		public static const LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_COB_ON:int = 77;
		
		/**
		 * IFTTT #2
		 */
		public static const LOCAL_SETTING_IFTTT_BOLUS_ADDED_ON:int = 78;
		public static const LOCAL_SETTING_IFTTT_BOLUS_UPDATED_ON:int = 79;
		public static const LOCAL_SETTING_IFTTT_BOLUS_DELETED_ON:int = 80;
		public static const LOCAL_SETTING_IFTTT_CARBS_ADDED_ON:int = 81;
		public static const LOCAL_SETTING_IFTTT_CARBS_UPDATED_ON:int = 82;
		public static const LOCAL_SETTING_IFTTT_CARBS_DELETED_ON:int = 83;
		public static const LOCAL_SETTING_IFTTT_MEAL_ADDED_ON:int = 84;
		public static const LOCAL_SETTING_IFTTT_MEAL_UPDATED_ON:int = 85;
		public static const LOCAL_SETTING_IFTTT_MEAL_DELETED_ON:int = 86;
		public static const LOCAL_SETTING_IFTTT_BGCHECK_ADDED_ON:int = 87;
		public static const LOCAL_SETTING_IFTTT_BGCHECK_UPDATED_ON:int = 88;
		public static const LOCAL_SETTING_IFTTT_BGCHECK_DELETED_ON:int = 89;
		public static const LOCAL_SETTING_IFTTT_NOTE_ADDED_ON:int = 90;
		public static const LOCAL_SETTING_IFTTT_NOTE_UPDATED_ON:int = 91;
		public static const LOCAL_SETTING_IFTTT_NOTE_DELETED_ON:int = 92;
		public static const LOCAL_SETTING_IFTTT_IOB_UPDATED_ON:int = 93;
		public static const LOCAL_SETTING_IFTTT_COB_UPDATED_ON:int = 94;
		
		/**
		 * Alarm snooze times
		 */
		public static const LOCAL_SETTING_VERY_HIGH_ALERT_SNOOZE_PERIOD_IN_MINUTES:int = 95;
		public static const LOCAL_SETTING_VERY_HIGH_ALERT_LATEST_SNOOZE_TIME_IN_MS:int = 96;
		public static const LOCAL_SETTING_HIGH_ALERT_SNOOZE_PERIOD_IN_MINUTES:int = 97;
		public static const LOCAL_SETTING_HIGH_ALERT_LATEST_SNOOZE_TIME_IN_MS:int = 98;
		public static const LOCAL_SETTING_LOW_ALERT_SNOOZE_PERIOD_IN_MINUTES:int = 99;
		public static const LOCAL_SETTING_LOW_ALERT_LATEST_SNOOZE_TIME_IN_MS:int = 100;
		public static const LOCAL_SETTING_VERY_LOW_ALERT_SNOOZE_PERIOD_IN_MINUTES:int = 101;
		public static const LOCAL_SETTING_VERY_LOW_ALERT_LATEST_SNOOZE_TIME_IN_MS:int = 102;
		public static const LOCAL_SETTING_MISSED_READINGS_ALERT_SNOOZE_PERIOD_IN_MINUTES:int = 103;
		public static const LOCAL_SETTING_MISSED_READINGS_ALERT_LATEST_SNOOZE_TIME_IN_MS:int = 104;
		public static const LOCAL_SETTING_PHONE_MUTED_ALERT_SNOOZE_PERIOD_IN_MINUTES:int = 105;
		public static const LOCAL_SETTING_PHONE_MUTED_ALERT_LATEST_SNOOZE_TIME_IN_MS:int = 106;
		public static const LOCAL_SETTING_VERY_HIGH_ALERT_PRESNOOZED:int = 107;
		public static const LOCAL_SETTING_HIGH_ALERT_PRESNOOZED:int = 108;
		public static const LOCAL_SETTING_LOW_ALERT_PRESNOOZED:int = 109;
		public static const LOCAL_SETTING_VERY_LOW_ALERT_PRESNOOZED:int = 110;
		public static const LOCAL_SETTING_MISSED_READINGS_ALERT_PRESNOOZED:int = 111;
		public static const LOCAL_SETTING_PHONE_MUTED_ALERT_PRESNOOZED:int = 112;
		
		/**
		 * Disclaimer
		 */
		public static const LOCAL_SETTING_DISCLAIMER_ACCEPTED:int = 113;
		
		/**
		 * Alarm Snooze Times #2
		 */
		public static const LOCAL_SETTING_FAST_RISE_ALERT_SNOOZE_PERIOD_IN_MINUTES:int = 114;
		public static const LOCAL_SETTING_FAST_RISE_ALERT_LATEST_SNOOZE_TIME_IN_MS:int = 115;
		public static const LOCAL_SETTING_FAST_RISE_ALERT_PRESNOOZED:int = 116;
		public static const LOCAL_SETTING_FAST_DROP_ALERT_SNOOZE_PERIOD_IN_MINUTES:int = 117;
		public static const LOCAL_SETTING_FAST_DROP_ALERT_LATEST_SNOOZE_TIME_IN_MS:int = 118;
		public static const LOCAL_SETTING_FAST_DROP_ALERT_PRESNOOZED:int = 119;
		
		/**
		 * IFTTT #3
		 */
		public static const LOCAL_SETTING_IFTTT_FAST_RISE_TRIGGERED_ON:int = 120;
		public static const LOCAL_SETTING_IFTTT_FAST_RISE_SNOOZED_ON:int = 121;
		public static const LOCAL_SETTING_IFTTT_FAST_DROP_TRIGGERED_ON:int = 122;
		public static const LOCAL_SETTING_IFTTT_FAST_DROP_SNOOZED_ON:int = 123;
		
		/**
		 * MiaoMiao Follower
		 */
		public static const LOCAL_SETTING_MIAOMIAO_MULTIPLE_DEVICE_ON:int = 124;
		public static const LOCAL_SETTING_MIAOMIAO_FOLLOWER_ENABLED:int=125;
		
		/**
		 * Sensor warm-up
		 */
		public static const LOCAL_SETTING_REMOVE_SENSOR_WARMUP_ENABLED:int=126;
		public static const LOCAL_SETTING_REMOVE_SENSOR_WARMUP_WARNING_DISPLAYED:int=127;
		
		/**
		 * Database Encryption
		 */
		public static const LOCAL_SETTING_DATABASE_IS_ENCRYPTED:int=128;
		
		/**
		 * Alarms System Volume
		 */
		public static const LOCAL_SETTING_ALARMS_USER_DEFINED_SYSTEM_VOLUME_ON:int=129;
		public static const LOCAL_SETTING_ALARMS_USER_DEFINED_SYSTEM_VOLUME_VALUE:int=130;
		
		/**
		 * Bolus Wizard Disclaimer
		 */
		public static const LOCAL_SETTING_BOLUS_WIZARD_DISCLAIMER_ACCEPTED:int=131;
		
		/**
		 * Quiet Time For App Center Updates
		 */
		public static const LOCAL_SETTING_APP_CENTER_UPDATER_QUIET_TIME_ENABLED:int=132;
		public static const LOCAL_SETTING_APP_CENTER_UPDATER_QUIET_TIME_START_HOUR:int=133;
		public static const LOCAL_SETTING_APP_CENTER_UPDATER_QUIET_TIME_START_MINUTES:int=134;
		public static const LOCAL_SETTING_APP_CENTER_UPDATER_QUIET_TIME_END_HOUR:int=135;
		public static const LOCAL_SETTING_APP_CENTER_UPDATER_QUIET_TIME_END_MINUTES:int=136;
		
		/**
		 * Apple Watch#3
		 */
		public static const LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_PREDICTIONS_ON:int = 137;
		
		/**
		 * IFTTT #3
		 */
		public static const LOCAL_SETTING_IFTTT_EXERCISE_ADDED_ON:int = 138;
		public static const LOCAL_SETTING_IFTTT_EXERCISE_UPDATED_ON:int = 139;
		public static const LOCAL_SETTING_IFTTT_EXERCISE_DELETED_ON:int = 140;
		public static const LOCAL_SETTING_IFTTT_INSULIN_CARTRIDGE_ADDED_ON:int = 141;
		public static const LOCAL_SETTING_IFTTT_INSULIN_CARTRIDGE_UPDATED_ON:int = 142;
		public static const LOCAL_SETTING_IFTTT_INSULIN_CARTRIDGE_DELETED_ON:int = 143;
		public static const LOCAL_SETTING_IFTTT_PUMP_SITE_ADDED_ON:int = 144;
		public static const LOCAL_SETTING_IFTTT_PUMP_SITE_UPDATED_ON:int = 145;
		public static const LOCAL_SETTING_IFTTT_PUMP_SITE_DELETED_ON:int = 146;
		public static const LOCAL_SETTING_IFTTT_PUMP_BATTERY_ADDED_ON:int = 147;
		public static const LOCAL_SETTING_IFTTT_PUMP_BATTERY_UPDATED_ON:int = 148;
		public static const LOCAL_SETTING_IFTTT_PUMP_BATTERY_DELETED_ON:int = 149;
		public static const LOCAL_SETTING_IFTTT_DIVIDE_BG_EVENTS_BY_THRESHOLD_ON:int = 150;
		public static const LOCAL_SETTING_IFTTT_TEMP_BASAL_START_ADDED_ON:int = 151;
		public static const LOCAL_SETTING_IFTTT_TEMP_BASAL_START_UPDATED_ON:int = 152;
		public static const LOCAL_SETTING_IFTTT_TEMP_BASAL_START_DELETED_ON:int = 153;
		public static const LOCAL_SETTING_IFTTT_TEMP_BASAL_END_ADDED_ON:int = 154;
		public static const LOCAL_SETTING_IFTTT_TEMP_BASAL_END_UPDATED_ON:int = 155;
		public static const LOCAL_SETTING_IFTTT_TEMP_BASAL_END_DELETED_ON:int = 156;
		public static const LOCAL_SETTING_IFTTT_MDI_BASAL_ADDED_ON:int = 157;
		public static const LOCAL_SETTING_IFTTT_MDI_BASAL_UPDATED_ON:int = 158;
		public static const LOCAL_SETTING_IFTTT_MDI_BASAL_DELETED_ON:int = 159;
		
		/**
		 * Ignition Update
		 */
		public static const LOCAL_SETTING_LAST_SHOWN_CHANGELOG:int = 160;
		
		/**
		 * Instalation Tracking
		 */
		public static const LOCAL_SETTING_TRACKED_VENDOR_ID:int = 161;
		public static const LOCAL_SETTING_TRACKED_DEVICE_HASH:int = 162;
		public static const LOCAL_SETTING_TRACKED_DEVICE_LATEST_TIMESTAMP:int = 163;
		public static const LOCAL_SETTING_STOCK_DATABASE:int = 164;

		private static var localSettings:Array = [
			"false",//LOCAL_SETTING_DETAILED_TRACING_ENABLED
			"",//LOCAL_SETTING_TRACE_FILE_NAME
			"false",//LOCAL_SETTING_WARNING_THAT_NIGHTSCOUT_URL_AND_SECRET_IS_NOT_OK_ALREADY_GIVEN
			"false",//LOCAL_SETTING_ALWAYS_ON_NOTIFICATION
			"",//LOCAL_SETTING_DEVICE_TOKEN_ID_NOT_USED_ANYMORE
			"",//LOCAL_SETTING_UDID_NOT_USED_ANYMORE
			"false",//LOCAL_SETTING_SUBSCRIBED_TO_PUSH_NOTIFICATIONS
			"",//LOCAL_SETTING_WISHED_QBLOX_SUBSCRIPTION_TAG_NOT_USED_ANYMORE
			"",//LOCAL_SETTING_ACTUAL_QBLOX_SUBSCRIPTION_TAG_NOT_USED_ANYMORE
			"false",//LOCAL_SETTING_NSLOG
			"false",//LOCAL_SETTING_G5_ALWAYS_AUTHENTICATE
			"false",//LOCAL_SETTING_G5_ALWAYS_UNBOUND
			"false",//LOCAL_SETTING_FromtimeAndValueListView_INFO_SHOWN
			"false",//LOCAL_SETTING_MISSED_READING_WARNING_GIVEN_NOT_USED_ANYMORE
			"false",//LOCAL_SETTING_PHONE_MUTED_WARNING_GIVEN
			"",//LOCAL_SETTING_TRACE_FILE_PATH_NAME
			"false",//LOCAL_SETTING_FROM_TIME_AND_VALUE_ELEMENT_VIEW_VALUE_INFO_GIVEN
			"false",//LOCAL_SETTING_LOW_BATTERY_WARNING_GIVEN
			"false",//LOCAL_SETTING_CALIBRATION_REQUEST_ALERT_WARNING_GIVEN
			"0.0.0",//LOCAL_SETTING_APPLICATION_VERSION 0.0.0 will be overwritten during initial app launch in HomeView
			"false",//LOCAL_SETTING_CHART_RANGE_INFO_GIVEN
			"false",//LOCAL_SETTING_INFO_ABOUT_LONG_PRESS_IN_HOME_SCREEN_GIVEN
			"false",//LOCAL_SETTING_HEALTHKIT_STORE_ON
			"false",//LOCAL_SETTING_LICENSE_INFO_ACCEPTED
			"false",//LOCAL_SETTING_SELECTION_UNIT_DONE
			"0",//LOCAL_SETTING_TIMESTAMP_SINCE_LAST_INFO_UKNOWN_PACKET_TYPE
			"false",//LOCAL_SETTING_DONTASKAGAIN_ABOUT_UNKNOWN_PACKET_TYPE
			"false",//LOCAL_SETTING_SPEECH_INSTRUCTIONS_ACCEPTED
			"false",//LOCAL_SETTING_OVERRIDE_MUTE
			"true",//LOCAL_SETTING_UPDATE_SERVICE_INITIALCHECK
			"true",//LOCAL_SETTING_ALWAYS_ON_APP_BADGE
			"0",//LOCAL_SETTING_REMOTE_ALERT_LAST_ID
			"0",//LOCAL_SETTING_REMOTE_ALERT_LAST_CHECK_TIMESTAMP
			"false",//LOCAL_SETTING_WATCH_COMPLICATION_ON
			"false",//LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_NAME_ON
			"",//LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_NAME
			"",//LOCAL_SETTING_WATCH_COMPLICATION_SELECTED_CALENDAR_ID
			"true",//LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_TREND
			"true",//LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_DELTA
			"true",//LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_UNITS
			"6",//LOCAL_SETTING_WATCH_COMPLICATION_GLUCOSE_HISTORY
			"true",//LOCAL_SETTING_LOOP_SERVER_ON
			"",//LOCAL_SETTING_LOOP_SERVER_USERNAME
			"",//LOCAL_SETTING_LOOP_SERVER_PASSWORD
			"0",//LOCAL_SETTING_TIMESTAMP_SINCE_LAST_EXPORT_SIDIARY
			"0",//LOCAL_SETTING_TRANSMITER_PL_AMOUNT_OF_INVALID_SENSOR_AGE_VALUES
			"true",//LOCAL_SETTING_APP_INACTIVE_ALERT
			"0",//LOCAL_SETTING_AMOUNT_OF_WARNINGS_OTHER_APP
			"3",//LOCAL_SETTING_ALWAYS_ON_NOTIFICATION_INTERVAL
			"false",//LOCAL_SETTING_ALWAYS_ON_NOTIFICATION_INTERVAL
			"false",//LOCAL_SETTING_IFTTT_ON
			"false",//LOCAL_SETTING_IFTTT_URGENT_HIGH_TRIGGERED_ON
			"false",//LOCAL_SETTING_IFTTT_URGENT_HIGH_SNOOZED_ON
			"false",//LOCAL_SETTING_IFTTT_HIGH_TRIGGERED_ON
			"false",//LOCAL_SETTING_IFTTT_HIGH_SNOOZED_ON
			"false",//LOCAL_SETTING_IFTTT_LOW_TRIGGERED_ON
			"false",//LOCAL_SETTING_IFTTT_LOW_SNOOZED_ON
			"false",//LOCAL_SETTING_IFTTT_URGENT_LOW_TRIGGERED_ON
			"false",//LOCAL_SETTING_IFTTT_URGENT_LOW_SNOOZED_ON
			"false",//LOCAL_SETTING_IFTTT_MISSED_READINGS_TRIGGERED_ON
			"false",//LOCAL_SETTING_IFTTT_MISSED_READINGS_SNOOZED_ON
			"false",//LOCAL_SETTING_IFTTT_CALIBRATION_TRIGGERED_ON
			"false",//LOCAL_SETTING_IFTTT_CALIBRATION_SNOOZED_ON
			"false",//LOCAL_SETTING_IFTTT_PHONE_MUTED_TRIGGERED_ON
			"false",//LOCAL_SETTING_IFTTT_PHONE_MUTED_SNOOZED_ON
			"false",//LOCAL_SETTING_IFTTT_TRANSMITTER_LOW_BATTERY_TRIGGERED_ON
			"false",//LOCAL_SETTING_IFTTT_TRANSMITTER_LOW_BATTERY_SNOOZED_ON
			"false",//LOCAL_SETTING_IFTTT_GLUCOSE_READING_ON
			"",//LOCAL_SETTING_IFTTT_GLUCOSE_READING_ON
			"false",//LOCAL_SETTING_IFTTT_GLUCOSE_THRESHOLDS_ON
			"150",//LOCAL_SETTING_IFTTT_GLUCOSE_HIGH_THRESHOLD
			"70",//LOCAL_SETTING_IFTTT_GLUCOSE_LOW_THRESHOLD
			"false",//LOCAL_SETTING_IFTTT_HTTP_SERVER_ERRORS_ON
			"true",//LOCAL_SETTING_APP_BADGE_MMOL_MULTIPLIER_ON
			"",//LOCAL_SETTING_BUG_REPORT_EMAIL
			"",//LOCAL_SETTING_BUG_REPORT_NAME
			"false",//LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_IOB_ON
			"false",//LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_COB_ON
			"false",//LOCAL_SETTING_IFTTT_BOLUS_ADDED_ON
			"false",//LOCAL_SETTING_IFTTT_BOLUS_UPDATED_ON
			"false",//LOCAL_SETTING_IFTTT_BOLUS_DELETED_ON
			"false",//LOCAL_SETTING_IFTTT_CARBS_ADDED_ON
			"false",//LOCAL_SETTING_IFTTT_CARBS_UPDATED_ON
			"false",//LOCAL_SETTING_IFTTT_CARBS_DELETED_ON
			"false",//LOCAL_SETTING_IFTTT_MEAL_ADDED_ON
			"false",//LOCAL_SETTING_IFTTT_MEAL_UPDATED_ON
			"false",//LOCAL_SETTING_IFTTT_MEAL_DELETED_ON
			"false",//LOCAL_SETTING_IFTTT_BGCHECK_ADDED_ON
			"false",//LOCAL_SETTING_IFTTT_BGCHECK_UPDATED_ON
			"false",//LOCAL_SETTING_IFTTT_BGCHECK_DELETED_ON
			"false",//LOCAL_SETTING_IFTTT_NOTE_ADDED_ON
			"false",//LOCAL_SETTING_IFTTT_NOTE_UPDATED_ON
			"false",//LOCAL_SETTING_IFTTT_NOTE_DELETED_ON
			"false",//LOCAL_SETTING_IFTTT_IOB_UPDATED_ON
			"false",//LOCAL_SETTING_IFTTT_COB_UPDATED_ON
			"0",//LOCAL_SETTING_VERY_HIGH_ALERT_SNOOZE_PERIOD_IN_MINUTES
			"Number.NaN",//LOCAL_SETTING_VERY_HIGH_ALERT_LATEST_SNOOZE_TIME_IN_MS
			"0",//LOCAL_SETTING_HIGH_ALERT_SNOOZE_PERIOD_IN_MINUTES
			"Number.NaN",//LOCAL_SETTING_HIGH_ALERT_LATEST_SNOOZE_TIME_IN_MS
			"0",//LOCAL_SETTING_LOW_ALERT_SNOOZE_PERIOD_IN_MINUTES
			"Number.NaN",//LOCAL_SETTING_LOW_ALERT_LATEST_SNOOZE_TIME_IN_MS
			"0",//LOCAL_SETTING_VERY_LOW_ALERT_SNOOZE_PERIOD_IN_MINUTES
			"Number.NaN",//LOCAL_SETTING_VERY_LOW_ALERT_LATEST_SNOOZE_TIME_IN_MS
			"0",//LOCAL_SETTING_MISSED_READINGS_ALERT_SNOOZE_PERIOD_IN_MINUTES
			"Number.NaN",//LOCAL_SETTING_MISSED_READINGS_ALERT_LATEST_SNOOZE_TIME_IN_MS
			"0",//LOCAL_SETTING_PHONE_MUTED_ALERT_SNOOZE_PERIOD_IN_MINUTES
			"Number.NaN",//LOCAL_SETTING_PHONE_MUTED_ALERT_LATEST_SNOOZE_TIME_IN_MS
			"false",//LOCAL_SETTING_VERY_HIGH_ALERT_PRESNOOZED
			"false",//LOCAL_SETTING_HIGH_ALERT_PRESNOOZED
			"false",//LOCAL_SETTING_LOW_ALERT_PRESNOOZED
			"false",//LOCAL_SETTING_VERY_LOW_ALERT_PRESNOOZED
			"false",//LOCAL_SETTING_MISSED_READINGS_ALERT_PRESNOOZED
			"false",//LOCAL_SETTING_PHONE_MUTED_ALERT_PRESNOOZED
			"false",//LOCAL_SETTING_DISCLAIMER_ACCEPTED
			"0",//LOCAL_SETTING_FAST_RISE_ALERT_SNOOZE_PERIOD_IN_MINUTES
			"Number.NaN",//LOCAL_SETTING_FAST_RISE_ALERT_LATEST_SNOOZE_TIME_IN_MS
			"false",//LOCAL_SETTING_FAST_RISE_ALERT_PRESNOOZED
			"0",//LOCAL_SETTING_FAST_DROP_ALERT_SNOOZE_PERIOD_IN_MINUTES
			"Number.NaN",//LOCAL_SETTING_FAST_DROP_ALERT_LATEST_SNOOZE_TIME_IN_MS
			"false",//LOCAL_SETTING_FAST_DROP_ALERT_PRESNOOZED
			"false",//LOCAL_SETTING_IFTTT_FAST_RISE_TRIGGERED_ON
			"false",//LOCAL_SETTING_IFTTT_FAST_RISE_SNOOZED_ON
			"false",//LOCAL_SETTING_IFTTT_FAST_DROP_TRIGGERED_ON
			"false",//LOCAL_SETTING_IFTTT_FAST_DROP_SNOOZED_ON
			"false",//LOCAL_SETTING_MIAOMIAO_MULTIPLE_DEVICE_ON
			"false",//LOCAL_SETTING_MIAOMIAO_FOLLOWER_ENABLED
			"false",//LOCAL_SETTING_REMOVE_SENSOR_WARMUP_ENABLED
			"false",//LOCAL_SETTING_REMOVE_SENSOR_WARMUP_WARNING_DISPLAYED
			"false",//LOCAL_SETTING_DATABASE_IS_ENCRYPTED
			"false",//LOCAL_SETTING_ALARMS_USER_DEFINED_SYSTEM_VOLUME_ON
			"50",//LOCAL_SETTING_ALARMS_USER_DEFINED_SYSTEM_VOLUME_VALUE
			"false",//LOCAL_SETTING_BOLUS_WIZARD_DISCLAIMER_ACCEPTED
			"false",//LOCAL_SETTING_APP_CENTER_UPDATER_QUIET_TIME_ENABLED
			"0",//LOCAL_SETTING_APP_CENTER_UPDATER_QUIET_TIME_START_HOUR
			"0",//LOCAL_SETTING_APP_CENTER_UPDATER_QUIET_TIME_START_MINUTES
			"8",//LOCAL_SETTING_APP_CENTER_UPDATER_QUIET_TIME_END_HOUR
			"0",//LOCAL_SETTING_APP_CENTER_UPDATER_QUIET_TIME_END_MINUTES
			"false",//LOCAL_SETTING_WATCH_COMPLICATION_DISPLAY_PREDICTIONS_ON
			"false",//LOCAL_SETTING_IFTTT_EXERCISE_ADDED_ON
			"false",//LOCAL_SETTING_IFTTT_EXERCISE_UPDATED_ON
			"false",//LOCAL_SETTING_IFTTT_EXERCISE_DELETED_ON
			"false",//LOCAL_SETTING_IFTTT_INSULIN_CARTRIDGE_ADDED_ON
			"false",//LOCAL_SETTING_IFTTT_INSULIN_CARTRIDGE_UPDATED_ON
			"false",//LOCAL_SETTING_IFTTT_INSULIN_CARTRIDGE_DELETED_ON
			"false",//LOCAL_SETTING_IFTTT_PUMP_SITE_ADDED_ON
			"false",//LOCAL_SETTING_IFTTT_PUMP_SITE_UPDATED_ON
			"false",//LOCAL_SETTING_IFTTT_PUMP_SITE_DELETED_ON
			"false",//LOCAL_SETTING_IFTTT_PUMP_BATTERY_ADDED_ON
			"false",//LOCAL_SETTING_IFTTT_PUMP_BATTERY_UPDATED_ON
			"false",//LOCAL_SETTING_IFTTT_PUMP_BATTERY_DELETED_ON
			"false",//LOCAL_SETTING_IFTTT_DIVIDE_BG_EVENTS_BY_THRESHOLD_ON
			"false",//LOCAL_SETTING_IFTTT_TEMP_BASAL_START_ADDED_ON
			"false",//LOCAL_SETTING_IFTTT_TEMP_BASAL_START_UPDATED_ON
			"false",//LOCAL_SETTING_IFTTT_TEMP_BASAL_START_DELETED_ON
			"false",//LOCAL_SETTING_IFTTT_TEMP_BASAL_END_ADDED_ON
			"false",//LOCAL_SETTING_IFTTT_TEMP_BASAL_END_UPDATED_ON
			"false",//LOCAL_SETTING_IFTTT_TEMP_BASAL_END_DELETED_ON
			"false",//LOCAL_SETTING_IFTTT_MDI_BASAL_ADDED_ON
			"false",//LOCAL_SETTING_IFTTT_MDI_BASAL_UPDATED_ON
			"false",//LOCAL_SETTING_IFTTT_MDI_BASAL_DELETED_ON
			"", //LOCAL_SETTING_LAST_SHOWN_CHANGELOG
			"", //LOCAL_SETTING_TRACKED_VENDOR_ID
			"", //LOCAL_SETTING_TRACKED_DEVICE_HASH
			"0", //LOCAL_SETTING_TRACKED_DEVICE_LATEST_TIMESTAMP
			"true" //LOCAL_SETTING_STOCK_DATABASE
		];
		
		public function LocalSettings() {
			if (_instance != null) {
				throw new Error("LocalSettings class constructor can not be used");	
			}
		}
		
		public static function getLocalSetting(localSettingId:int):String {
			return localSettings[localSettingId];
		}

		/**
		 * if  updateDatabase = true and dispatchSettingChangedEvent = true, then SETTING_CHANGED will be dispatched
		 */
		public static function setLocalSetting(localSettingId:int, newValue:String, updateDatabase:Boolean = true, dispatchSettingChangedEvent:Boolean = true):void {
			if (localSettings[localSettingId] != newValue) {
				localSettings[localSettingId] = newValue;
				if (updateDatabase) {
					Database.updateLocalSetting(localSettingId, newValue);
					if (dispatchSettingChangedEvent) {
						var settingChangedEvent:SettingsServiceEvent = new SettingsServiceEvent(SettingsServiceEvent.SETTING_CHANGED);
						settingChangedEvent.data = localSettingId;
						_instance.dispatchEvent(settingChangedEvent);
					}
				}
			}
		}
		
		public static function getNumberOfSettings():int {
			return localSettings.length;
		}
		
		public static function getAllSettings():Array
		{
			return localSettings;
		}
	}
}