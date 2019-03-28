package database
 {
 	import flash.events.EventDispatcher;
 	
 	import events.SettingsServiceEvent;
 	
 	import model.ModelLocator;
 	
 	import utils.DeviceInfo;

	 /**
	  * common settings are settings that are shared with other devices, ie settings that will be synchronized
	  */
	 public class CommonSettings extends EventDispatcher
	 {
		 [ResourceBundle("alertsettingsscreen")]
		 
		 private static var _instance:CommonSettings = new CommonSettings();

		 public static function get instance():CommonSettings
		 {
			 return _instance;
		 }
		 
		 public static const APP_UPDATE_API_URL:String = "https://spike-app.com/app/latest_ignition_update.json";
		 
		 /**
		 * Witout https:// and without /api/v1/treatments<br>
		  */
		 public static const DEFAULT_SITE_NAME:String = "";
		 public static const DEFAULT_API_SECRET:String = "";
		 
		 //LIST OF SETTINGID's
		 /**
		  * Unique Id of the currently active sensor<br>
		  * value "0" means there's no sensor active
		  *  
		  */
		 public static const COMMON_SETTING_CURRENT_SENSOR:int = 0; 
		 /**
		  * transmitter battery level (ie 215, 214,...)<br>
		  * 0 means level not known
		  */
		 public static const COMMON_SETTING_G4_TRANSMITTER_BATTERY_VOLTAGE:int = 1;
		 /**
		  * bridge battery level<br>
		  * 0 means level not known
		  */
		 public static const COMMON_SETTING_BRIDGE_BATTERY_PERCENTAGE:int = 2;
		 public static const COMMON_SETTING_G4_INFO_SCREEN_SHOWN:int = 3;
		 /**
		  * Witout https:// and without /api/v1/treatments<br>
		  */
		 public static const COMMON_SETTING_AZURE_WEBSITE_NAME:int = 4;
		 public static const COMMON_SETTING_API_SECRET:int = 5;
		 public static const COMMON_SETTING_URL_AND_API_SECRET_TESTED:int = 6; 
		 /**
		 * 0 = never synced 
		  */
		 public static const COMMON_SETTING_NIGHTSCOUT_UPLOAD_BGREADING_TIMESTAMP:int = 7;
		 /**
		 * not used anymore
		  */
		 public static const COMMON_SETTING_ADDITIONAL_CALIBRATION_REQUEST_ALERT:int = 8;
		 /**
		 * true or false, if true unit is mg/dl 
		  */
		 public static const COMMON_SETTING_DO_MGDL:int = 9;
		 /**
		 * low bg value, in mgdl, should be converted each time it is used or displayed
		  */
		 public static const COMMON_SETTING_LOW_MARK:int = 10;
		 /**
		 * high bg value, in mgdl, should be converted each time it is used or displayed
		  */
		 public static const COMMON_SETTING_HIGH_MARK:int = 11;
		 /**
		 * transmitter id, 00000 is not set 
		 */
		 public static const COMMON_SETTING_TRANSMITTER_ID:int = 12;
		 /**
		 * last update TRANSMITTER_BATTERY_VOLTAGE in ms since 1 1 1970<br>
		 * updated automatically when the setting COMMON_SETTING_TRANSMITTER_BATTERY_VOLTAGE
		  */
		 public static const COMMON_SETTING_UNUSED:int = 13;
		 public static const COMMON_SETTING_G5_G6_BATTERY_MARKER:int = 14;
		 public static const COMMON_SETTING_G5_G6_BATTERY_FROM_MARKER:int = 15;
		 /**
		 * Possible values :<br>
		 * G4 : any xdrip or xbridge that receives G4 transmitter signal<br> 
		 * G5<br>
		 * Limitter<br>
		 * Bluereader<br>
		 * BluKon<br>
		 * Transmiter PL<br>
		 * <br>
		 * Default value is an empty string, peripheral type unknown
		  */
		 public static const COMMON_SETTING_PERIPHERAL_TYPE:int = 16;
		 public static const COMMON_SETTING_G5_G6_INFO_SCREEN_SHOWN:int = 17;
		 public static const COMMON_SETTING_INITIAL_SELECTION_PERIPHERAL_TYPE_DONE:int = 18;
		 public static const COMMON_SETTING_LICENSE_INFO_CONFIRMED:int = 19;
		 /**
		 * only related to quickblox subscription in iosxdripreader.mxml activateHandler 
		  */
		 public static const COMMON_SETTING_TIME_SINCE_LAST_QUICK_BLOX_SUBSCRIPTION:int = 20;
		 /**
		 * the string that has all the intervals with low alert types 
		  */
		 public static const COMMON_SETTING_LOW_ALERT:int = 21;
		 /**
		 * the string that has all the intervals with high alert types 
		  */
		 public static const COMMON_SETTING_HIGH_ALERT:int = 22;
		 /**
		  * the string that has all the intervals with missed reading alert types 
		  */
		 public static const COMMON_SETTING_MISSED_READING_ALERT:int = 23;
		 /**
		  * the string that has all the intervals with phone muted alert types
		  */
		 public static const COMMON_SETTING_PHONE_MUTED_ALERT:int = 24;
		 /**
		 * Not used anymore
		  */
		 public static const COMMON_SETTING_G5_STATUS:int = 25;
		 /**
		  * data read from g5 transmitter, default value 'unknown'
		  */
		 public static const COMMON_SETTING_G5_G6_VOLTAGEA:int = 26;
		 /**
		  * data read from g5 transmitter, default value 'unknown'
		  */
		 public static const COMMON_SETTING_G5_G6_VOLTAGEB:int = 27;
		 /**
		  * data read from g5 transmitter, default value 'unknown'
		  */
		 public static const COMMON_SETTING_G5_G6_RESIST:int = 28;
		 /**
		  * data read from g5 transmitter, default value 'unknown'
		  */
		 public static const COMMON_SETTING_G5_G6_TEMPERATURE:int = 29;
		 /**
		  * data read from g5 transmitter, default value 'unknown'
		  */
		 public static const COMMON_SETTING_G5_G6_RUNTIME:int = 30;
		 
		 /**
		  * the string that has all the intervals with battery low alert types
		  */
		 public static const COMMON_SETTING_BATTERY_ALERT:int = 31;
		 public static const COMMON_SETTING_CALIBRATION_REQUEST_ALERT:int = 32;
		 public static const COMMON_SETTING_VERY_LOW_ALERT:int = 33;
		 public static const COMMON_SETTING_VERY_HIGH_ALERT:int = 34;
		 /**
		  * 0 = never synced 
		  */
		 public static const COMMON_SETTING_DEXCOMSHARE_SYNC_TIMESTAMP:int = 35;
		 
		 /**
		 * For limitter and/or bluereaderw<br>
		 * value 0 means level not known
		  */
		 public static const COMMON_SETTING_FSL_SENSOR_BATTERY_LEVEL:int = 36;
		 /**
		  * For bluereaderw<br>
		  * value 0 means level not known
		  */
		 public static const COMMON_SETTING_BLUEREADER_BATTERY_LEVEL:int = 37;
		 /**
		  * For any device that reads Freestyle and that gets the sensorage from the Freestyle sensor<br>
		  * This is not the case for Bluereader, bluereader doesn't read the sensorage from the sensor, COMMON_SETTING_FSL_SENSOR_AGE will remain 0<br>
		  * <br>
		  * value 0 means level not known<br>
		  * time in minutes<br>
		  */
		 public static const COMMON_SETTING_FSL_SENSOR_AGE:int = 38;
		 /**
		  * For blukon<br>
		  * value 0 means level not known
		  */
		 public static const COMMON_SETTING_BLUKON_BATTERY_LEVEL:int = 39;
		 
		 /**
		 * For blucon only, sensor age check is done only every x hours (constant in Bluetoothservice)
		  */
		 public static const COMMON_SETTING_TIME_STAMP_LAST_SENSOR_AGE_CHECK_IN_MS:int = 40;
		 
		 /**
		 * dexcom receiver serial number
		  */
		 public static const COMMON_SETTING_DEXCOM_SHARE_SERIALNUMBER:int = 41;
		 public static const COMMON_SETTING_DEXCOM_SHARE_ACCOUNTNAME:int = 42;
		 public static const COMMON_SETTING_DEXCOM_SHARE_PASSWORD:int = 43;
		 public static const COMMON_SETTING_DEXCOM_SHARE_ON:int = 44;
		 public static const COMMON_SETTING_DEXCOM_SHARE_US_URL:int = 45;
		 public static const COMMON_SETTING_BLUKON_INFO_SCREEN_SHOWN:int = 46;
		 public static const COMMON_SETTING_NIGHTSCOUT_UPLOAD_CALIBRATION_TIMESTAMP:int = 47;
		 public static const COMMON_SETTING_BLUKON_EXTERNAL_ALGORITHM:int = 48;
		 public static const COMMON_SETTING_SPEAK_READINGS_ON:int = 49;
		 public static const COMMON_SETTING_SPEAK_READINGS_INTERVAL:int = 50;
		 public static const COMMON_SETTING_SPEAK_TREND_ON:int = 51;
		 public static const COMMON_SETTING_SPEAK_DELTA_ON:int = 52;
		 public static const COMMON_SETTING_APP_UPDATE_NOTIFICATIONS_ON:int = 53;
		 public static const COMMON_SETTING_APP_UPDATE_LAST_UPDATE_CHECK:int = 54;
		 public static const COMMON_SETTING_APP_UPDATE_IGNORE_UPDATE:int = 55;
		 public static const COMMON_SETTING_APP_UPDATE_USER_GROUP:int = 56;
		 public static const COMMON_SETTING_SPEECH_LANGUAGE:int = 57;
		 
		 /**
		  * urgent low bg value, in mgdl, should be converted each time it is used or displayed
		  */
		 public static const COMMON_SETTING_URGENT_LOW_MARK:int = 58;
		 /**
		  * urgent high bg value, in mgdl, should be converted each time it is used or displayed
		  */
		 public static const COMMON_SETTING_URGENT_HIGH_MARK:int = 59;
		 
		 /**
		  * Chart Settings #1
		  */
		 public static const COMMON_SETTING_CHART_URGENT_HIGH_COLOR:int = 60;
		 public static const COMMON_SETTING_CHART_HIGH_COLOR:int = 61;
		 public static const COMMON_SETTING_CHART_IN_RANGE_COLOR:int = 62;
		 public static const COMMON_SETTING_CHART_LOW_COLOR:int = 63;
		 public static const COMMON_SETTING_CHART_URGENT_LOW_COLOR:int = 64;
		 public static const COMMON_SETTING_CHART_AXIS_COLOR:int = 65;
		 public static const COMMON_SETTING_CHART_FONT_COLOR:int = 66;
		 public static const COMMON_SETTING_CHART_AXIS_FONT_COLOR:int = 67;
		 public static const COMMON_SETTING_CHART_PIE_CHART_FONT_COLOR:int = 68;
		 public static const COMMON_SETTING_CHART_MARKER_RADIUS:int = 69;
		 public static const COMMON_SETTING_CHART_BG_FONT_SIZE:int = 70;
		 public static const COMMON_SETTING_CHART_TIMEAGO_FONT_SIZE:int = 71;
		 public static const COMMON_SETTING_CHART_AXIS_FONT_SIZE:int = 72;
		 public static const COMMON_SETTING_CHART_SELECTED_TIMELINE_RANGE:int = 73;
		 public static const COMMON_SETTING_CHART_DISPLAY_LINE:int = 74;
		 public static const COMMON_SETTING_CHART_DISPLAY_GLUCOSE_DISTRIBUTION:int = 75;
		 public static const COMMON_SETTING_CHART_DATE_FORMAT:int = 76;
		 
		 /**
		  * Extra Nightscout Setting (Visual Only)
		  */
		 public static const COMMON_SETTING_NIGHTSCOUT_ON:int = 77;
		 
		 /**
		  * Extra G5 Setting for transmitter runtime
		  */
		 public static const COMMON_SETTING_G5_G6_SENSOR_RX_TIMESTAMP:int = 78;
		 
		 /**
		  * Widget #1
		  */
		 public static const COMMON_SETTING_WIDGET_HISTORY_TIMESPAN:int = 79;
		 public static const COMMON_SETTING_WIDGET_SMOOTH_LINE:int = 80;
		 public static const COMMON_SETTING_WIDGET_SHOW_MARKERS:int = 81;
		 public static const COMMON_SETTING_WIDGET_SHOW_MARKER_LABEL:int = 82;
		 public static const COMMON_SETTING_WIDGET_SHOW_GRID_LINES:int = 83;
		 public static const COMMON_SETTING_WIDGET_LINE_THICKNESS:int = 84;
		 public static const COMMON_SETTING_WIDGET_MARKER_RADIUS:int = 85;
		 public static const COMMON_SETTING_WIDGET_URGENT_HIGH_COLOR:int = 86;
		 public static const COMMON_SETTING_WIDGET_HIGH_COLOR:int = 87;
		 public static const COMMON_SETTING_WIDGET_IN_RANGE_COLOR:int = 88;
		 public static const COMMON_SETTING_WIDGET_LOW_COLOR:int = 89;
		 public static const COMMON_SETTING_WIDGET_URGENT_LOW_COLOR:int = 90;
		 public static const COMMON_SETTING_WIDGET_GLUCOSE_MARKER_COLOR:int = 91;
		 public static const COMMON_SETTING_WIDGET_AXIS_COLOR:int = 92;
		 public static const COMMON_SETTING_WIDGET_AXIS_FONT_COLOR:int = 93;
		 public static const COMMON_SETTING_WIDGET_BACKGROUND_COLOR:int = 94;
		 public static const COMMON_SETTING_WIDGET_BACKGROUND_OPACITY:int = 95;
		 public static const COMMON_SETTING_WIDGET_GRID_LINES_COLOR:int = 96;
		 public static const COMMON_SETTING_WIDGET_DISPLAY_LABELS_COLOR:int = 97;
		 public static const COMMON_SETTING_WIDGET_OLD_DATA_COLOR:int = 98;
		 
		 /**
		  * Chart Settings #2
		  */
		 public static const COMMON_SETTING_CHART_OLD_DATA_COLOR:int = 99;
		 
		 /**
		  * Widget #2
		  */
		 public static const COMMON_SETTING_WIDGET_MAIN_LINE_COLOR:int = 100;
		 
		 /**
		  * Chart Settings #3
		  */
		 public static const COMMON_SETTING_CHART_SCALE_MODE_DYNAMIC:int = 101;
		 public static const COMMON_SETTING_CHART_MAX_VALUE:int = 102;
		 public static const COMMON_SETTING_CHART_MIN_VALUE:int = 103;
		 public static const COMMON_SETTING_CHART_RESIZE_ON_OUT_OF_BOUNDS:int = 104;
		 
		 /**
		  * Deep Sleep Timer
		  */
		 public static const COMMON_SETTING_DEEP_SLEEP_SELF_MANAGEMENT_ON:int = 105;
		 public static const COMMON_SETTING_DEEP_SLEEP_MODE:int = 106;
		 
		 /**
		  * Follower
		  */
		 public static const COMMON_SETTING_DATA_COLLECTION_MODE:int = 107;
		 public static const COMMON_SETTING_DATA_COLLECTION_NS_URL:int = 108;
		 public static const COMMON_SETTING_FOLLOWER_MODE:int = 109;
		 
		 /**
		 * Pie Chart Colors
		 */
		 public static const COMMON_SETTING_PIE_CHART_LOW_COLOR:int = 110;
		 public static const COMMON_SETTING_PIE_CHART_IN_RANGE_COLOR:int = 111;
		 public static const COMMON_SETTING_PIE_CHART_HIGH_COLOR:int = 112;
		 
		 /**
		  * Deep Sleep Timer #2
		  */
		 public static const COMMON_SETTING_DEEP_SLEEP_ALTERNATIVE_MODE:int = 113;
		 
		 /**
		  * Follower #2
		  */
		 public static const COMMON_SETTING_DATA_COLLECTION_NS_OFFSET:int = 114;
		 public static const COMMON_SETTING_DATA_COLLECTION_NS_API_SECRET:int = 115;
		 
		 /**
		  * Deep Sleep Timer #3
		  */
		 public static const COMMON_SETTING_DEEP_SLEEP_ALTERNATIVE_MODE_2:int = 116;
		 
		 /**
		  * MiaoMiao	 
		  */
		 public static const COMMON_SETTING_NFC_AGE_PROBEM:int = 117;
		 public static const COMMON_SETTING_MIAOMIAO_BATTERY_LEVEL:int = 118;
		 public static const COMMON_SETTING_MIAOMIAO_HARDWARE:int = 119;
		 public static const COMMON_SETTING_MIAOMIAO_FW:int = 120;
		 
		 /**
		 * Healthkit
		 */
		 public static const COMMON_SETTING_HEALTHKIT_SYNC_TIMESTAMP:int = 121;
		 
		 /**
		  * Treatments
		  */
		 public static const COMMON_SETTING_TREATMENTS_ENABLED:int = 122;
		 public static const COMMON_SETTING_TREATMENTS_ON_CHART_ENABLED:int = 123;
		 public static const COMMON_SETTING_TREATMENTS_NIGHTSCOUT_DOWNLOAD_ENABLED:int = 124;
		 public static const COMMON_SETTING_TREATMENTS_IOB_ENABLED:int = 125;
		 public static const COMMON_SETTING_TREATMENTS_COB_ENABLED:int = 126;
		 public static const COMMON_SETTING_TREATMENTS_INSULIN_MARKER_COLOR:int = 127;
		 public static const COMMON_SETTING_TREATMENTS_CARBS_MARKER_COLOR:int = 128;
		 public static const COMMON_SETTING_TREATMENTS_BGCHECK_MARKER_COLOR:int = 129;
		 public static const COMMON_SETTING_TREATMENTS_PILL_COLOR:int = 130;
		 public static const COMMON_SETTING_TREATMENTS_STROKE_COLOR:int = 131;
		 public static const COMMON_SETTING_TREATMENTS_NEW_SENSOR_MARKER_COLOR:int = 132;
		 
		 /**
		 * Chart Settings #4
		 */
		 public static const COMMON_SETTING_CHART_ROUND_MGDL_ON:int = 133;
		 /** 
		  * bluereader battery management
		  */
		 public static const COMMON_SETTING_BLUEREADER_FULL_BATTERY:int = 134;
		 /**
		  * xbrdiger battery level
		  */
		 public static const COMMON_SETTING_XBRIDGER_BATTERY_LEVEL:int = 135;

		 /**
		 * warning will be given after 14 days that sensor is about to expire, can still last for 12 hours after that 
		  */
		 public static const COMMON_SETTING_LIBRE_SENSOR_14DAYS_WARNING_GIVEN:int = 136;
		 
		 /**
		 * if true, for any device type limitter, default calibration will be used<br>
		  */
		 public static const COMMON_SETTTING_LIBRE_USE_DEFAULT_CALIBRATION:int = 137;
		 
		 /**
		  * Treatments #2
		  */
		 public static const COMMON_SETTING_TREATMENTS_LOOP_OPENAPS_USER_ENABLED:int = 138;
		 
		 /**
		  * Pie Chart #2
		  */
		 public static const COMMON_SETTING_PIE_CHART_A1C_OFFSET:int = 139;
		 public static const COMMON_SETTING_PIE_CHART_AVG_OFFSET:int = 140;
		 public static const COMMON_SETTING_PIE_CHART_RANGES_OFFSET:int = 141;
		 
		 /**
		 * G5 firmware info, empty string means not known<br>
		 * The contents is the hex string as received from G5<br>
		 * To read the contents, G5VersionInfo.getG5VersionInfo
		  */
		 public static const COMMON_SETTING_G5_G6_VERSION_INFO:int = 142;
		 
		 /**
		  * Apply IFCC calculation to A1C values
		  * Useful for some countries like New Zealand.
		  */
		 public static const COMMON_SETTING_PIE_CHART_A1C_IFCC_ON:int = 143;
		 
		 /**
		 * Rotation
		 */
		 public static const COMMON_SETTING_PREVENT_SCREEN_ROTATION_ON:int = 144;
		 
		 /**
		 * Info Pill
		 */
		 public static const COMMON_SETTING_INFO_PILL_ON:int = 145;
		 public static const COMMON_SETTING_BASAL_ON:int = 146;
		 public static const COMMON_SETTING_RAW_GLUCOSE_ON:int = 147;
		 public static const COMMON_SETTING_UPLOADER_BATTERY_ON:int = 148;
		 public static const COMMON_SETTING_OUTCOME_ON:int = 149;
		 public static const COMMON_SETTING_EFFECT_ON:int = 150;
		 public static const COMMON_SETTING_OPENAPS_MOMENT_ON:int = 151;
		 public static const COMMON_SETTING_LOOP_MOMENT_ON:int = 152;
		 public static const COMMON_SETTING_PUMP_BATTERY_ON:int = 153;
		 public static const COMMON_SETTING_PUMP_RESERVOIR_ON:int = 154;
		 public static const COMMON_SETTING_PUMP_STATUS_ON:int = 155;
		 public static const COMMON_SETTING_PUMP_TIME_ON:int = 156;
		 public static const COMMON_SETTING_CAGE_ON:int = 157;
		 public static const COMMON_SETTING_SAGE_ON:int = 158;
		 public static const COMMON_SETTING_IAGE_ON:int = 159;
		 public static const COMMON_SETTING_TRANSMITTER_BATTERY_ON:int = 160;
		 
		 /**
		 * Pie Chart #3 
		 */
		 public static const COMMON_SETTING_SHOW_PIE_IN_LANDSCAPE:int = 161;
		 
		 /**
		  * NIGHTSCOUT BATTERY UPLOADER 
		  */
		 public static const COMMON_SETTING_NIGHTSCOUT_BATTERY_UPLOADER_ON:int = 162;
		 public static const COMMON_SETTING_NIGHTSCOUT_LAST_BATTERY_UPLOADED:int = 163;
		 public static const COMMON_SETTING_NIGHTSCOUT_LAST_BATTERY_UPLOADED_TIMESTAMP:int = 164;
		 
		 /**
		  * NIGHTSCOUT & DEXCOM SHARE WI-FI ONLY UPLOADER 
		  */
		 public static const COMMON_SETTING_NIGHTSCOUT_WIFI_ONLY_UPLOADER_ON:int = 165;
		 public static const COMMON_SETTING_DEXCOM_SHARE_WIFI_ONLY_UPLOADER_ON:int = 166;
		 
		 /**
		  * SPEECH SETTINGS #2 
		  */
		 public static const COMMON_SETTING_SPEECH_THRESHOLD_ON:int = 167;
		 public static const COMMON_SETTING_SPEECH_THRESHOLD_HIGH:int = 168;
		 public static const COMMON_SETTING_SPEECH_THRESHOLD_LOW:int = 169;
		 
		 /**
		  * CARB DELAY SETTINGS 
		  */
		 public static const COMMON_SETTING_CARB_FAST_ABSORTION_TIME:int = 170;
		 public static const COMMON_SETTING_CARB_MEDIUM_ABSORTION_TIME:int = 171;
		 public static const COMMON_SETTING_CARB_SLOW_ABSORTION_TIME:int = 172;
		 
		 /**
		  * FAST RISE/DROP ALARMS 
		  */
		 public static const COMMON_SETTING_FAST_RISE_ALERT:int = 173;
		 public static const COMMON_SETTING_FAST_DROP_ALERT:int = 174;
		 
		 /**
		  * CARB DELAY SETTINGS #2
		  */
		 public static const COMMON_SETTING_DEFAULT_CARB_ABSORTION_TIME:int = 175;
		 
		 /**
		 * App Language
		 */
		 public static const COMMON_SETTING_APP_LANGUAGE:int = 176;
		 
		 /**
		  * FAST RISE/DROP ALARMS #2
		  */
		 public static const COMMON_SETTING_FAST_RISE_ALERT_GLUCOSE_THRESHOLDS_ON:int = 177;
		 public static const COMMON_SETTING_FAST_RISE_ALERT_LOW_GLUCOSE_THRESHOLD:int = 178;
		 public static const COMMON_SETTING_FAST_RISE_ALERT_HIGH_GLUCOSE_THRESHOLD:int = 179;
		 public static const COMMON_SETTING_FAST_DROP_ALERT_GLUCOSE_THRESHOLDS_ON:int = 180;
		 public static const COMMON_SETTING_FAST_DROP_ALERT_LOW_GLUCOSE_THRESHOLD:int = 181;
		 public static const COMMON_SETTING_FAST_DROP_ALERT_HIGH_GLUCOSE_THRESHOLD:int = 182;
		 
		 /**
		 * Nightscout optimal calibration notifier
		 */
		 public static const COMMON_SETTING_UPLOAD_OPTIMAL_CALIBRATION_TO_NS_ON:int = 183;
		 
		 /**
		  * Chart Settings #5
		  */
		 public static const COMMON_SETTING_CHART_DISPLAY_RAW_ON:int = 184;
		 public static const COMMON_SETTING_CHART_RAW_COLOR:int = 185;
		 
		 /**
		  * Optimal calibration notifiers
		  */
		 public static const COMMON_SETTING_OPTIMAL_CALIBRATION_ON_DEMAND_NOTIFIER_ON:int = 186;
		 public static const COMMON_SETTING_OPTIMAL_CALIBRATION_BY_ALARM_NOTIFIED_ON:int = 187;
		 
		 /**
		  * iCloud #1
		  */
		 public static const COMMON_SETTING_ICLOUD_BACKUP_SCHEDULER_TIMESPAN:int = 188;
		 public static const COMMON_SETTING_ICLOUD_BACKUP_LAST_PERFORMED:int = 189;
		 public static const COMMON_SETTING_ICLOUD_BACKUP_SCHEDULER_WIFI_ONLY:int = 190;
		 
		 /**
		 * App Center
		 */
		 public static const COMMON_SETTING_APP_CENTER_UPDATE_NOTIFICATIONS_ON:int = 191;
		 
		 /**
		 * Speech System Volume
		 */
		 public static const COMMON_SETTING_SPEECH_USER_DEFINED_SYSTEM_VOLUME_ON:int = 192;
		 public static const COMMON_SETTING_SPEECH_USER_DEFINED_SYSTEM_VOLUME_VALUE:int = 193;
		 
		 /**
		 * Chart Settings #6
		 */
		 public static const COMMON_SETTING_CHART_DISPLAY_TARGET_LINE:int = 194;
		 public static const COMMON_SETTING_CHART_DISPLAY_URGENT_HIGH_LINE:int = 195;
		 public static const COMMON_SETTING_CHART_DISPLAY_HIGH_LINE:int = 196;
		 public static const COMMON_SETTING_CHART_DISPLAY_LOW_LINE:int = 197;
		 public static const COMMON_SETTING_CHART_DISPLAY_URGENT_LOW_LINE:int = 198;
		 public static const COMMON_SETTING_CHART_TARGET_LINE_COLOR:int = 199;
		 
		 /**
		 * Bolus Wizard #1
		 */
		 public static const COMMON_SETTING_BOLUS_WIZARD_DEFAULT_EXTENDED_BOLUS_SOUND:int = 200;
		 public static const COMMON_SETTING_BOLUS_WIZARD_INSULIN_PRECISION:int = 201;
		 public static const COMMON_SETTING_BOLUS_WIZARD_CARBS_PRECISION:int = 202;
		 
		 /**
		  * Food Manager #1
		  */
		 public static const COMMON_SETTING_FOOD_MANAGER_FIBER_PRECISION:int = 203;
		 public static const COMMON_SETTING_FOOD_MANAGER_DEFAULT_SCREEN:int = 204;
		 public static const COMMON_SETTING_FOOD_MANAGER_SEARCH_AS_I_TYPE:int = 205;
		 
		 /**
		 * Bolus Wizard #2
		 */
		 public static const COMMON_SETTING_BOLUS_WIZARD_EXERCISE_BEFORE_LOW_15MIN:int = 206;
		 public static const COMMON_SETTING_BOLUS_WIZARD_EXERCISE_BEFORE_LOW_30MIN:int = 207;
		 public static const COMMON_SETTING_BOLUS_WIZARD_EXERCISE_BEFORE_LOW_45MIN:int = 208;
		 public static const COMMON_SETTING_BOLUS_WIZARD_EXERCISE_BEFORE_LOW_60MIN:int = 209;
		 public static const COMMON_SETTING_BOLUS_WIZARD_EXERCISE_BEFORE_LOW_90MIN:int = 210;
		 public static const COMMON_SETTING_BOLUS_WIZARD_EXERCISE_BEFORE_LOW_120MIN:int = 211;
		 public static const COMMON_SETTING_BOLUS_WIZARD_EXERCISE_BEFORE_LOW_180MIN:int = 212;
		 public static const COMMON_SETTING_BOLUS_WIZARD_EXERCISE_BEFORE_MODERATE_15MIN:int = 213;
		 public static const COMMON_SETTING_BOLUS_WIZARD_EXERCISE_BEFORE_MODERATE_30MIN:int = 214;
		 public static const COMMON_SETTING_BOLUS_WIZARD_EXERCISE_BEFORE_MODERATE_45MIN:int = 215;
		 public static const COMMON_SETTING_BOLUS_WIZARD_EXERCISE_BEFORE_MODERATE_60MIN:int = 216;
		 public static const COMMON_SETTING_BOLUS_WIZARD_EXERCISE_BEFORE_MODERATE_90MIN:int = 217;
		 public static const COMMON_SETTING_BOLUS_WIZARD_EXERCISE_BEFORE_MODERATE_120MIN:int = 218;
		 public static const COMMON_SETTING_BOLUS_WIZARD_EXERCISE_BEFORE_MODERATE_180MIN:int = 219;
		 public static const COMMON_SETTING_BOLUS_WIZARD_EXERCISE_BEFORE_HIGH_15MIN:int = 220;
		 public static const COMMON_SETTING_BOLUS_WIZARD_EXERCISE_BEFORE_HIGH_30MIN:int = 221;
		 public static const COMMON_SETTING_BOLUS_WIZARD_EXERCISE_BEFORE_HIGH_45MIN:int = 222;
		 public static const COMMON_SETTING_BOLUS_WIZARD_EXERCISE_BEFORE_HIGH_60MIN:int = 223;
		 public static const COMMON_SETTING_BOLUS_WIZARD_EXERCISE_BEFORE_HIGH_90MIN:int = 224;
		 public static const COMMON_SETTING_BOLUS_WIZARD_EXERCISE_BEFORE_HIGH_120MIN:int = 225;
		 public static const COMMON_SETTING_BOLUS_WIZARD_EXERCISE_BEFORE_HIGH_180MIN:int = 226;
		 public static const COMMON_SETTING_BOLUS_WIZARD_EXERCISE_AFTER_LOW_15MIN:int = 227;
		 public static const COMMON_SETTING_BOLUS_WIZARD_EXERCISE_AFTER_LOW_30MIN:int = 228;
		 public static const COMMON_SETTING_BOLUS_WIZARD_EXERCISE_AFTER_LOW_45MIN:int = 229;
		 public static const COMMON_SETTING_BOLUS_WIZARD_EXERCISE_AFTER_LOW_60MIN:int = 230;
		 public static const COMMON_SETTING_BOLUS_WIZARD_EXERCISE_AFTER_LOW_90MIN:int = 231;
		 public static const COMMON_SETTING_BOLUS_WIZARD_EXERCISE_AFTER_LOW_120MIN:int = 232;
		 public static const COMMON_SETTING_BOLUS_WIZARD_EXERCISE_AFTER_LOW_180MIN:int = 233;
		 public static const COMMON_SETTING_BOLUS_WIZARD_EXERCISE_AFTER_MODERATE_15MIN:int = 234;
		 public static const COMMON_SETTING_BOLUS_WIZARD_EXERCISE_AFTER_MODERATE_30MIN:int = 235;
		 public static const COMMON_SETTING_BOLUS_WIZARD_EXERCISE_AFTER_MODERATE_45MIN:int = 236;
		 public static const COMMON_SETTING_BOLUS_WIZARD_EXERCISE_AFTER_MODERATE_60MIN:int = 237;
		 public static const COMMON_SETTING_BOLUS_WIZARD_EXERCISE_AFTER_MODERATE_90MIN:int = 238;
		 public static const COMMON_SETTING_BOLUS_WIZARD_EXERCISE_AFTER_MODERATE_120MIN:int = 239;
		 public static const COMMON_SETTING_BOLUS_WIZARD_EXERCISE_AFTER_MODERATE_180MIN:int = 240;
		 public static const COMMON_SETTING_BOLUS_WIZARD_EXERCISE_AFTER_HIGH_15MIN:int = 241;
		 public static const COMMON_SETTING_BOLUS_WIZARD_EXERCISE_AFTER_HIGH_30MIN:int = 242;
		 public static const COMMON_SETTING_BOLUS_WIZARD_EXERCISE_AFTER_HIGH_45MIN:int = 243;
		 public static const COMMON_SETTING_BOLUS_WIZARD_EXERCISE_AFTER_HIGH_60MIN:int = 244;
		 public static const COMMON_SETTING_BOLUS_WIZARD_EXERCISE_AFTER_HIGH_90MIN:int = 245;
		 public static const COMMON_SETTING_BOLUS_WIZARD_EXERCISE_AFTER_HIGH_120MIN:int = 246;
		 public static const COMMON_SETTING_BOLUS_WIZARD_EXERCISE_AFTER_HIGH_180MIN:int = 247;
		 public static const COMMON_SETTING_BOLUS_WIZARD_SICKNESS_ADJUSTMENT:int = 248;
		 
		 /**
		  * Food Manager #2
		  */
		 public static const COMMON_SETTING_FOOD_MANAGER_IMPORT_FOODS_AS_NOTE:int = 249;
		 
		 /**
		 * Bolus Wizard #3
		 */
		 public static const COMMON_SETTING_BOLUS_WIZARD_AUTO_IOB_ENABLED:int = 250;
		 public static const COMMON_SETTING_BOLUS_WIZARD_AUTO_COB_ENABLED:int = 251;
		 public static const COMMON_SETTING_BOLUS_WIZARD_AUTO_TREND_ENABLED:int = 252;
		 public static const COMMON_SETTING_BOLUS_WIZARD_ACCEPTABLE_MARGIN:int = 253;
		 public static const COMMON_SETTING_BOLUS_WIZARD_SUGGESTION_LABEL_COLOR:int = 254;
		 public static const COMMON_SETTING_BOLUS_WIZARD_SUGGESTION_COMPONENTS_ON_TOP:int = 255;
		 public static const COMMON_SETTING_BOLUS_WIZARD_NO_SPACE_BETWEEN_SUGGESTIONS:int = 256;
		 
		 /**
		  * Chart Settings #7
		  */
		 public static const COMMON_SETTING_CHART_GLUCOSE_LINE_THICKNESS:int = 257;
		 
		 /**
		 * Predictions #1
		 */
		 public static const COMMON_SETTING_DEFAULT_IOB_COB_ALGORITHM:int = 258;
		 public static const COMMON_SETTING_GLUCOSE_PREDICTIONS_ENABLED:int = 259;
		 public static const COMMON_SETTING_GLUCOSE_PREDICTIONS_DEFAULT_COLOR:int = 260;
		 public static const COMMON_SETTING_GLUCOSE_PREDICTIONS_MINUTES_FOR_1_HOUR:int = 261;
		 public static const COMMON_SETTING_GLUCOSE_PREDICTIONS_MINUTES_FOR_3_HOURS:int = 262;
		 public static const COMMON_SETTING_GLUCOSE_PREDICTIONS_MINUTES_FOR_6_HOURS:int = 263;
		 public static const COMMON_SETTING_GLUCOSE_PREDICTIONS_MINUTES_FOR_12_HOURS:int = 264;
		 public static const COMMON_SETTING_GLUCOSE_PREDICTIONS_MINUTES_FOR_24_HOURS:int = 265;
		 public static const COMMON_SETTING_GLUCOSE_PREDICTIONS_INCLUDE_IOB_COB:int = 266;
		 
		 /**
		  * Info Pill #2
		  */
		 public static const COMMON_SETTING_INFO_PILL_SENSOR_NOISE_ON:int = 267;
		 
		 /**
		  * Predictions #2
		  */
		 public static const COMMON_SETTING_GLUCOSE_PREDICTIONS_UAM_COLOR:int = 268;
		 public static const COMMON_SETTING_NIGHTSCOUT_PREDICTIONS_UPLOADER_ON:int = 269;
		 public static const COMMON_SETTING_GLUCOSE_PREDICTIONS_SINGLE_LINE_ENABLED:int = 270;
		 
		 /**
		  * Info Pill #3
		  */
		 public static const COMMON_SETTING_BAGE_ON:int = 271;
		 
		 /**
		  * Predictions #3
		  */
		 public static const COMMON_SETTING_GLUCOSE_PREDICTIONS_ZT_COLOR:int = 272;
		 
		 /**
		  * Pump Treatments
		  */
		 public static const COMMON_SETTING_LAST_INSULIN_CARTRIDGE_CHANGE:int = 273;
		 public static const COMMON_SETTING_LAST_PUMP_SITE_CHANGE:int = 274;
		 public static const COMMON_SETTING_LAST_PUMP_BATTERY_CHANGE:int = 275;
		 
		 /**
		 * PIE CHART #$
		 */
		 public static const COMMON_SETTING_PIE_CHART_VARIABILITY_OFFSET:int = 276;
		 public static const COMMON_SETTING_PIE_CHART_TREATMENTS_OFFSET:int = 277;
		 public static const COMMON_SETTING_PIE_CHART_ACTIVE_PAGE:int = 278;
		 
		 /**
		 * Follower #3
		 */
		 public static const COMMON_SETTING_DATA_COLLECTION_DS_USERNAME:int = 279;
		 public static const COMMON_SETTING_DATA_COLLECTION_DS_PASSWORD:int = 280;
		 public static const COMMON_SETTING_DATA_COLLECTION_DS_SERVER:int = 281;
		 
		 /**
		 * Basals
		 */
		 public static const COMMON_SETTING_USER_TYPE_PUMP_OR_MDI:int = 282;
		 public static const COMMON_SETTING_PREFERRED_TEMP_BASAL_MODE:int = 283;
		 public static const COMMON_SETTING_TEMP_BASAL_AREA_COLOR:int = 284;
		 public static const COMMON_SETTING_ABSOLUTE_BASAL_LINE_COLOR:int = 285;
		 public static const COMMON_SETTING_BASAL_RATE_LINE_COLOR:int = 286;
		 public static const COMMON_SETTING_ABSOLUTE_BASAL_AREA_COLOR:int = 287;
		 public static const COMMON_SETTING_DOWNLOAD_NIGHTSCOUT_BASALS:int = 288;
		 public static const COMMON_SETTING_SHOW_BASALS_ON_CHART:int = 289;
		 public static const COMMON_SETTING_BASALS_AREA_SIZE_PERCENTAGE:int = 290;
		 
		 /**
		  * iCloud #2
		  */
		 public static const COMMON_SETTING_USER_WARNED_OF_NON_OPTIMAL_ICLOUD_BACKUP_SCHEDULE:int = 291;

		 private static var commonSettings:Array = [
			 "0",//COMMON_SETTING_CURRENT_SENSOR
			 "0",//COMMON_SETTING_G4_TRANSMITTER_BATTERY_VOLTAGE
			 "0",//COMMON_SETTING_BRIDGE_BATTERY_PERCENTAGE
			 "false",//COMMON_SETTING_G4_INFO_SCREEN_SHOWN
			 "",//COMMON_SETTING_AZURE_WEBSITE_NAME
			 "",//COMMON_SETTING_API_SECRET
			 "false",//COMMON_SETTING_URL_AND_API_SECRET_TESTED
			 "0",//COMMON_SETTING_NIGHTSCOUT_SYNC_TIMESTAMP
			 "true",//COMMON_SETTING_ADDITIONAL_CALIBRATION_REQUEST_ALERT -- not used anymore
			 "true",//COMMON_SETTING_DO_MGDL
			 "70",//COMMON_SETTING_LOW_MARK
			 "170",//COMMON_SETTING_HIGH_MARK
			 "",//COMMON_SETTING_TRANSMITTER_ID
			 "0",//COMMON_SETTING_UNUSED
			 "",//COMMON_SETTING_G5_BATTERY_MARKER
			 "0",//COMMON_SETTING_G5_BATTERY_FROM_MARKER
			 "",//COMMON_SETTING_PERIPHERAL_TYPE
			 "false",//COMMON_SETTING_G5_INFO_SCREEN_SHOWN
			 "false",//COMMON_SETTING_INITIAL_SELECTION_PERIPHERAL_TYPE_DONE
			 "false",//COMMON_SETTING_LICENSE_INFO_CONFIRMED
			 "0",//COMMON_SETTING_TIME_SINCE_LAST_QUICK_BLOX_SUBSCRIPTION
			 "00:00>0>DefaultNoAlertToBeReplaced",//COMMON_SETTING_LOW_ALERT
			 "00:00>0>DefaultNoAlertToBeReplaced",//COMMON_SETTING_HIGH_ALERT
			 "00:00>0>DefaultNoAlertToBeReplaced",//COMMON_SETTING_MISSED_READING_ALERT
			 "00:00>0>DefaultNoAlertToBeReplaced",//COMMON_SETTING_PHONE_MUTED_ALERT
			 "unknown",//COMMON_SETTING_G5_STATUS
			 "unknown",//COMMON_SETTING_G5_VOLTAGEA
			 "unknown",//COMMON_SETTING_G5_VOLTAGEB
			 "unknown",//COMMON_SETTING_G5_RESIST
			 "unknown",//COMMON_SETTING_G5_TEMPERATURE
			 "unknown",//COMMON_SETTING_G5_RUNTIME
			 "00:00>0>DefaultNoAlertToBeReplaced",//COMMON_SETTING_BATTERY_ALERT
			 "00:00>24>DefaultNoAlertToBeReplaced-08:00>24>SilentToBeReplaced-23:00>24>DefaultNoAlertToBeReplaced",//COMMON_SETTING_CALIBRATION_REQUEST_ALERT
			 "00:00>0>DefaultNoAlertToBeReplaced",//COMMON_SETTING_VERY_LOW_ALERT
			 "00:00>0>DefaultNoAlertToBeReplaced",//COMMON_SETTING_VERY_HIGH_ALERT
			 "0",//COMMON_SETTING_FSL_SENSOR_BATTERY_LEVEL
			 "0",//COMMON_SETTING_BLUEREADER_BATTERY_LEVEL
			 "0",//COMMON_SETTING_FSL_SENSOR_AGE
			 "0",//COMMON_SETTING_BLUKON_BATTERY_LEVEL
			 "0",//COMMON_SETTING_TIME_STAMP_LAST_SENSOR_AGE_CHECK_IN_MS
			 "0",//COMMON_SETTING_DEXCOMSHARE_SYNC_TIMESTAMP
			 "SM00000000",//COMMON_SETTING_DEXCOM_SHARE_SERIALNUMBER
			 "",//COMMON_SETTING_DEXCOM_SHARE_ACCOUNTNAME
			 "",//COMMON_SETTING_DEXCOM_SHARE_PASSWORD
			 "false",//COMMON_SETTING_DEXCOM_SHARE_ON
			 "false",//COMMON_SETTING_DEXCOM_SHARE_US_URL
			 "false",//COMMON_SETTING_BLUKON_INFO_SCREEN_SHOWN
			 "0",//COMMON_SETTING_NIGHTSCOUT_UPLOAD_CALIBRATION_TIMESTAMP
			 "false",//COMMON_SETTING_BLUKON_EXTERNAL_ALGORITHM
			 "false",//COMMON_SETTING_SPEAK_READINGS_ON
			 "1",//COMMON_SETTING_SPEAK_READINGS_INTERVAL
			 "false",//COMMON_SETTING_SPEAK_TREND_ON
			 "false",//COMMON_SETTING_SPEAK_DELTA_ON
			 "true",//COMMON_SETTING_APP_UPDATE_NOTIFICATIONS_ON
			 "0",//COMMON_SETTING_APP_UPDATE_LAST_UPDATE_CHECK
			 "",//COMMON_SETTING_APP_UPDATE_IGNORE_UPDATE
			 "",//COMMON_SETTING_APP_UPDATE_USER_GROUP
			 "en-US",//COMMON_SETTING_SPEECH_LANGUAGE
			 "55",//COMMON_SETTING_URGENT_LOW_MARK
			 "200",//COMMON_SETTING_URGENT_HIGH_MARK
			 "16711680",//COMMON_SETTING_CHART_URGENT_HIGH_COLOR
			 "16776960",//COMMON_SETTING_CHART_HIGH_COLOR
			 "65280",//COMMON_SETTING_CHART_IN_RANGE_COLOR
			 "16776960",//COMMON_SETTING_CHART_LOW_COLOR
			 "16711680",//COMMON_SETTING_CHART_URGENT_LOW_COLOR
			 "15658734",//COMMON_SETTING_CHART_AXIS_COLOR
			 "15658734",//COMMON_SETTING_CHART_FONT_COLOR
			 "15658734",//COMMON_SETTING_CHART_AXIS_FONT_COLOR
			 "15658734",//COMMON_SETTING_CHART_PIE_CHART_FONT_COLOR
			 !DeviceInfo.isTablet() ? "3" : "5",//COMMON_SETTING_CHART_MARKER_RADIUS
			 "1.2",//COMMON_SETTING_CHART_BG_FONT_SIZE
			 "1.2",//COMMON_SETTING_CHART_TIMEAGO_FONT_SIZE
			 "1.2",//COMMON_SETTING_CHART_AXIS_FONT_SIZE
			 "8",//COMMON_SETTING_CHART_SELECTED_TIMELINE_RANGE
			 "false",//COMMON_SETTING_CHART_DISPLAY_LINE
			 "true",//COMMON_SETTING_CHART_DISPLAY_PIE_CHART
			 "24",//COMMON_SETTING_CHART_DATE_FORMAT
			 "false",//COMMON_SETTING_NIGHTSCOUT_ON
			 "0",//COMMON_SETTING_G5_SENSOR_RX_TIMESTAMP
			 "1",//COMMON_SETTING_WIDGET_HISTORY_TIMESPAN
			 "true",//COMMON_SETTING_WIDGET_SMOOTH_LINE
			 "true",//COMMON_SETTING_WIDGET_SHOW_MARKERS
			 "true",//COMMON_SETTING_WIDGET_SHOW_MARKER_LABEL
			 "false",//COMMON_SETTING_WIDGET_SHOW_GRID_LINES
			 "1",//COMMON_SETTING_WIDGET_LINE_THICKNESS
			 "6",//COMMON_SETTING_WIDGET_MARKER_RADIUS
			 "16711680",//COMMON_SETTING_WIDGET_URGENT_HIGH_COLOR
			 "16776960",//COMMON_SETTING_WIDGET_HIGH_COLOR
			 "65280",//COMMON_SETTING_WIDGET_IN_RANGE_COLOR
			 "16776960",//COMMON_SETTING_WIDGET_LOW_COLOR
			 "16711680",//COMMON_SETTING_WIDGET_URGENT_LOW_COLOR
			 "16777215",//COMMON_SETTING_WIDGET_GLUCOSE_MARKER_COLOR
			 "16777215",//COMMON_SETTING_WIDGET_AXIS_COLOR
			 "16777215",//COMMON_SETTING_WIDGET_AXIS_FONT_COLOR
			 "0",//COMMON_SETTING_WIDGET_BACKGROUND_COLOR
			 "70",//COMMON_SETTING_WIDGET_BACKGROUND_OPACITY
			 "16777215",//COMMON_SETTING_WIDGET_GRID_LINES_COLOR
			 "16777215",//COMMON_SETTING_WIDGET_DISPLAY_LABELS_COLOR
			 "11250603",//COMMON_SETTING_WIDGET_OLD_DATA_COLOR
			 "11250603",//COMMON_SETTING_CHART_OLD_DATA_COLOR
			 "16777215",//COMMON_SETTING_WIDGET_MAIN_LINE_COLOR
			 "false",//COMMON_SETTING_CHART_SCALE_MODE_DYNAMIC
			 "200",//COMMON_SETTING_CHART_MAX_VALUE
			 "40",//COMMON_SETTING_CHART_MIN_VALUE
			 "true",//COMMON_SETTING_CHART_RESIZE_ON_OUT_OF_BOUNDS
			 "false",//COMMON_SETTING_DEEP_SLEEP_SELF_MANAGEMENT_ON
			 "0",//COMMON_SETTING_DEEP_SLEEP_MODE
			 "Host",//COMMON_SETTING_DATA_COLLECTION_MODE
			 "",//COMMON_SETTING_DATA_COLLECTION_NS_URL
			 "Nightscout",//COMMON_SETTING_FOLLOWER_MODE
			 "16711680",//COMMON_SETTING_PIE_CHART_LOW_COLOR
			 "65280",//COMMON_SETTING_PIE_CHART_IN_RANGE_COLOR
			 "16776960",//COMMON_SETTING_PIE_CHART_HIGH_COLOR
			 "false",//COMMON_SETTING_DEEP_SLEEP_ALTERNATIVE_MODE
			 "0",//COMMON_SETTING_DATA_COLLECTION_NS_OFFSET
			 "",//COMMON_SETTING_DATA_COLLECTION_NS_API_SECRET
			"false",//COMMON_SETTING_DEEP_SLEEP_ALTERNATIVE_MODE_2
			 "false",//COMMON_SETTING_NFC_AGE_PROBEM
			 "0",//COMMON_SETTING_MIAOMIAO_BATTERY_LEVEL
			 "",//COMMON_SETTING_MIAOMIAO_HARDWARE
			 "",//COMMON_SETTING_MIAOMIAO_FW
			 "0",//COMMON_SETTING_HEALTHKIT_SYNC_TIMESTAMP
			 "true",//COMMON_SETTING_TREATMENTS_ENABLED
			 "true",//COMMON_SETTING_TREATMENTS_ON_CHART_ENABLED
			 "true",//COMMON_SETTING_TREATMENTS_NIGHTSCOUT_DOWNLOAD_ENABLED
			 "true",//COMMON_SETTING_TREATMENTS_IOB_ENABLED
			 "true",//COMMON_SETTING_TREATMENTS_COB_ENABLED
			 "0x0086FF",//COMMON_SETTING_TREATMENTS_INSULIN_MARKER_COLOR
			 "0xF8A246",//COMMON_SETTING_TREATMENTS_CARBS_MARKER_COLOR
			 "0xFF0000",//COMMON_SETTING_TREATMENTS_BGCHECK_MARKER_COLOR
			 "0xEEEEEE",//COMMON_SETTING_TREATMENTS_PILL_COLOR
			 "0xEEEEEE",//COMMON_SETTING_TREATMENTS_STROKE_COLOR
			 "0x666666",//COMMON_SETTING_TREATMENTS_NEW_SENSOR_MARKER_COLOR
			 "false",//COMMON_SETTING_CHART_ROUND_MGDL_ON
			 "0",//COMMON_SETTING_BLUEREADER_FULL_BATTERY
			 "0",//COMMON_SETTING_XBRIDGER_BATTERY_LEVEL
			 "false",//COMMON_SETTING_LIBRE_SENSOR_14DAYS_WARNING_GIVEN
			 "false",//COMMON_SETTTING_LIBRE_USE_DEFAULT_CALIBRATION
			 "false",//COMMON_SETTING_TREATMENTS_LOOP_OPENAPS_USER_ENABLED
			 "86400000",//COMMON_SETTING_PIE_CHART_A1C_OFFSET (1 DAY)
			 "86400000",//COMMON_SETTING_PIE_CHART_AVG_OFFSET (1 DAY)
			 "86400000",//COMMON_SETTING_PIE_CHART_RANGES_OFFSET (1 DAY)
			 "",//COMMON_SETTING_G5_VERSION_INFO
			 "false",//COMMON_SETTING_PIE_CHART_A1C_IFCC_ON
			 "false",//COMMON_SETTING_PREVENT_SCREEN_ROTATION_ON
			 "true",//COMMON_SETTING_INFO_PILL_ON
			 "true",//COMMON_SETTING_BASAL_ON
			 "true",//COMMON_SETTING_RAW_GLUCOSE_ON
			 "true",//COMMON_SETTING_UPLOADER_BATTERY_ON
			 "true",//COMMON_SETTING_OUTCOME_ON
			 "true",//COMMON_SETTING_EFFECT_ON
			 "true",//COMMON_SETTING_OPENAPS_MOMENT_ON
			 "true",//COMMON_SETTING_LOOP_MOMENT_ON
			 "true",//COMMON_SETTING_PUMP_BATTERY_ON
			 "true",//COMMON_SETTING_PUMP_RESERVOIR_ON
			 "true",//COMMON_SETTING_PUMP_STATUS_ON
			 "true",//COMMON_SETTING_PUMP_TIME_ON
			 "true",//COMMON_SETTING_CAGE_ON
			 "true",//COMMON_SETTING_SAGE_ON
			 "true",//COMMON_SETTING_IAGE_ON
			 "true",//COMMON_SETTING_TRANSMITTER_BATTERY_ON
			 "false",//COMMON_SETTING_SHOW_PIE_IN_LANDSCAPE
			 "false",//COMMON_SETTING_NIGHTSCOUT_BATTERY_UPLOADER_ON
			 "",//COMMON_SETTING_NIGHTSCOUT_LAST_BATTERY_UPLOADED
			 "0",//COMMON_SETTING_NIGHTSCOUT_LAST_BATTERY_UPLOADED_TIMESTAMP
			 "false",//COMMON_SETTING_NIGHTSCOUT_WIFI_ONLY_UPLOADER_ON
			 "false",//COMMON_SETTING_DEXCOM_SHARE_WIFI_ONLY_UPLOADER_ON
			 "false",//COMMON_SETTING_SPEECH_THRESHOLD_ON
			 "0",//COMMON_SETTING_SPEECH_THRESHOLD_HIGH
			 "0",//COMMON_SETTING_SPEECH_THRESHOLD_LOW
			 "5",//COMMON_SETTING_CARB_FAST_ABSORTION_TIME
			 "10",//COMMON_SETTING_CARB_MEDIUM_ABSORTION_TIME
			 "20",//COMMON_SETTING_CARB_SLOW_ABSORTION_TIME
			 "00:00>0>DefaultNoAlertToBeReplaced",//COMMON_SETTING_FAST_RISE_ALERT
			 "00:00>0>DefaultNoAlertToBeReplaced",//COMMON_SETTING_FAST_DROP_ALERT
			 "20",//COMMON_SETTING_DEFAULT_CARB_ABSORTION_TIME
			 "en_US",//COMMON_SETTING_APP_LANGUAGE
			 "false",//COMMON_SETTING_FAST_RISE_ALERT_GLUCOSE_THRESHOLDS_ON
			 "",//COMMON_SETTING_FAST_RISE_ALERT_LOW_GLUCOSE_THRESHOLD
			 "",//COMMON_SETTING_FAST_RISE_ALERT_HIGH_GLUCOSE_THRESHOLD
			 "false",//COMMON_SETTING_FAST_DROP_ALERT_GLUCOSE_THRESHOLDS_ON
			 "",//COMMON_SETTING_FAST_DROP_ALERT_LOW_GLUCOSE_THRESHOLD
			 "",//COMMON_SETTING_FAST_DROP_ALERT_HIGH_GLUCOSE_THRESHOLD
			 "false",//COMMON_SETTING_UPLOAD_OPTIMAL_CALIBRATION_TO_NS_ON
			 "false",//COMMON_SETTING_CHART_DISPLAY_RAW_ON
			 "0xEEEEEE",//COMMON_SETTING_CHART_RAW_COLOR
			 "false",//COMMON_SETTING_OPTIMAL_CALIBRATION_ON_DEMAND_NOTIFIER_ON
			 "false",//COMMON_SETTING_OPTIMAL_CALIBRATION_BY_ALARM_NOTIFIED_ON
			 "43200000",//COMMON_SETTING_ICLOUD_BACKUP_SCHEDULER_TIMESPAN (Twice-daily by default)
			 "0",//COMMON_SETTING_ICLOUD_BACKUP_LAST_PERFORMED
			 "true",//COMMON_SETTING_ICLOUD_BACKUP_SCHEDULER_WIFI_ONLY
			 "true",//COMMON_SETTING_APP_CENTER_UPDATE_NOTIFICATIONS_ON
			 "false",//COMMON_SETTING_SPEECH_USER_DEFINED_SYSTEM_VOLUME_ON
			 "50",//COMMON_SETTING_SPEECH_USER_DEFINED_SYSTEM_VOLUME_VALUE
			 "true",//COMMON_SETTING_CHART_DISPLAY_TARGET_LINE
			 "true",//COMMON_SETTING_CHART_DISPLAY_URGENT_HIGH_LINE
			 "true",//COMMON_SETTING_CHART_DISPLAY_HIGH_LINE
			 "true",//COMMON_SETTING_CHART_DISPLAY_LOW_LINE
			 "true",//COMMON_SETTING_CHART_DISPLAY_URGENT_LOW_LINE
			 "15658734",//COMMON_SETTING_CHART_TARGET_LINE_COLOR
			 "",//COMMON_SETTING_BOLUS_WIZARD_DEFAULT_EXTENDED_BOLUS_SOUND
			 "0.5",//COMMON_SETTING_BOLUS_WIZARD_INSULIN_PRECISION
			 "1",//COMMON_SETTING_BOLUS_WIZARD_CARBS_PRECISION
			 "1",//COMMON_SETTING_FOOD_MANAGER_FIBER_PRECISION
			 "favorites",//COMMON_SETTING_FOOD_MANAGER_DEFAULT_SCREEN
			 "false",//COMMON_SETTING_FOOD_MANAGER_SEARCH_AS_I_TYPE
			 "0",//COMMON_SETTING_BOLUS_WIZARD_EXERCISE_BEFORE_LOW_15MIN
			 "0",//COMMON_SETTING_BOLUS_WIZARD_EXERCISE_BEFORE_LOW_30MIN
			 "10",//COMMON_SETTING_BOLUS_WIZARD_EXERCISE_BEFORE_LOW_45MIN
			 "15",//COMMON_SETTING_BOLUS_WIZARD_EXERCISE_BEFORE_LOW_60MIN
			 "20",//COMMON_SETTING_BOLUS_WIZARD_EXERCISE_BEFORE_LOW_90MIN
			 "30",//COMMON_SETTING_BOLUS_WIZARD_EXERCISE_BEFORE_LOW_120MIN
			 "45",//COMMON_SETTING_BOLUS_WIZARD_EXERCISE_BEFORE_LOW_180MIN
			 "5",//COMMON_SETTING_BOLUS_WIZARD_EXERCISE_BEFORE_MODERATE_15MIN
			 "15",//COMMON_SETTING_BOLUS_WIZARD_EXERCISE_BEFORE_MODERATE_30MIN
			 "20",//COMMON_SETTING_BOLUS_WIZARD_EXERCISE_BEFORE_MODERATE_45MIN
			 "30",//COMMON_SETTING_BOLUS_WIZARD_EXERCISE_BEFORE_MODERATE_60MIN
			 "40",//COMMON_SETTING_BOLUS_WIZARD_EXERCISE_BEFORE_MODERATE_90MIN
			 "55",//COMMON_SETTING_BOLUS_WIZARD_EXERCISE_BEFORE_MODERATE_120MIN
			 "75",//COMMON_SETTING_BOLUS_WIZARD_EXERCISE_BEFORE_MODERATE_180MIN
			 "10",//COMMON_SETTING_BOLUS_WIZARD_EXERCISE_BEFORE_HIGH_15MIN
			 "20",//COMMON_SETTING_BOLUS_WIZARD_EXERCISE_BEFORE_HIGH_30MIN
			 "30",//COMMON_SETTING_BOLUS_WIZARD_EXERCISE_BEFORE_HIGH_45MIN
			 "45",//COMMON_SETTING_BOLUS_WIZARD_EXERCISE_BEFORE_HIGH_60MIN
			 "60",//COMMON_SETTING_BOLUS_WIZARD_EXERCISE_BEFORE_HIGH_90MIN
			 "75",//COMMON_SETTING_BOLUS_WIZARD_EXERCISE_BEFORE_HIGH_120MIN
			 "85",//COMMON_SETTING_BOLUS_WIZARD_EXERCISE_BEFORE_HIGH_180MIN
			 "0",//COMMON_SETTING_BOLUS_WIZARD_EXERCISE_AFTER_LOW_15MIN
			 "0",//COMMON_SETTING_BOLUS_WIZARD_EXERCISE_AFTER_LOW_30MIN
			 "0",//COMMON_SETTING_BOLUS_WIZARD_EXERCISE_AFTER_LOW_45MIN
			 "5",//COMMON_SETTING_BOLUS_WIZARD_EXERCISE_AFTER_LOW_60MIN
			 "7",//COMMON_SETTING_BOLUS_WIZARD_EXERCISE_AFTER_LOW_90MIN
			 "10",//COMMON_SETTING_BOLUS_WIZARD_EXERCISE_AFTER_LOW_120MIN
			 "15",//COMMON_SETTING_BOLUS_WIZARD_EXERCISE_AFTER_LOW_180MIN
			 "0",//COMMON_SETTING_BOLUS_WIZARD_EXERCISE_AFTER_MODERATE_15MIN
			 "10",//COMMON_SETTING_BOLUS_WIZARD_EXERCISE_AFTER_MODERATE_30MIN
			 "15",//COMMON_SETTING_BOLUS_WIZARD_EXERCISE_AFTER_MODERATE_45MIN
			 "20",//COMMON_SETTING_BOLUS_WIZARD_EXERCISE_AFTER_MODERATE_60MIN
			 "25",//COMMON_SETTING_BOLUS_WIZARD_EXERCISE_AFTER_MODERATE_90MIN
			 "25",//COMMON_SETTING_BOLUS_WIZARD_EXERCISE_AFTER_MODERATE_120MIN
			 "30",//COMMON_SETTING_BOLUS_WIZARD_EXERCISE_AFTER_MODERATE_180MIN
			 "0",//COMMON_SETTING_BOLUS_WIZARD_EXERCISE_AFTER_HIGH_15MIN
			 "20",//COMMON_SETTING_BOLUS_WIZARD_EXERCISE_AFTER_HIGH_30MIN
			 "30",//COMMON_SETTING_BOLUS_WIZARD_EXERCISE_AFTER_HIGH_45MIN
			 "40",//COMMON_SETTING_BOLUS_WIZARD_EXERCISE_AFTER_HIGH_60MIN
			 "45",//COMMON_SETTING_BOLUS_WIZARD_EXERCISE_AFTER_HIGH_90MIN
			 "50",//COMMON_SETTING_BOLUS_WIZARD_EXERCISE_AFTER_HIGH_120MIN
			 "60",//COMMON_SETTING_BOLUS_WIZARD_EXERCISE_AFTER_HIGH_180MIN
			 "0",//COMMON_SETTING_BOLUS_WIZARD_SICKNESS_ADJUSTMENT
			 "true",//COMMON_SETTING_FOOD_MANAGER_IMPORT_FOODS_AS_NOTE
			 "true",//COMMON_SETTING_BOLUS_WIZARD_AUTO_IOB_ENABLED
			 "true",//COMMON_SETTING_BOLUS_WIZARD_AUTO_COB_ENABLED
			 "false",//COMMON_SETTING_BOLUS_WIZARD_AUTO_TREND_ENABLED
			 "10",//COMMON_SETTING_BOLUS_WIZARD_ACCEPTABLE_MARGIN
			 "0xFF0000",//COMMON_SETTING_BOLUS_WIZARD_SUGGESTION_LABEL_COLOR
			 "false",//COMMON_SETTING_BOLUS_WIZARD_SUGGESTION_COMPONENTS_ON_TOP
			 "false",//COMMON_SETTING_BOLUS_WIZARD_NO_SPACE_BETWEEN_SUGGESTIONS
			 "1",//COMMON_SETTING_CHART_GLUCOSE_LINE_THICKNESS
			 "nightscout", //COMMON_SETTING_DEFAULT_IOB_COB_ALGORITHM
			 "false", //COMMON_SETTING_GLUCOSE_PREDICTIONS_ENABLED
			 "0xEF00E7", //COMMON_SETTING_GLUCOSE_PREDICTIONS_DEFAULT_COLOR
			 "20", //COMMON_SETTING_GLUCOSE_PREDICTIONS_MINUTES_FOR_1_HOUR
			 "60", //COMMON_SETTING_GLUCOSE_PREDICTIONS_MINUTES_FOR_3_HOURS
			 "120", //COMMON_SETTING_GLUCOSE_PREDICTIONS_MINUTES_FOR_6_HOURS
			 "180", //COMMON_SETTING_GLUCOSE_PREDICTIONS_MINUTES_FOR_12_HOURS
			 "240", //COMMON_SETTING_GLUCOSE_PREDICTIONS_MINUTES_FOR_24_HOURS
			 "true", //COMMON_SETTING_GLUCOSE_PREDICTIONS_INCLUDE_IOB_COB
			 "true", //COMMON_SETTING_INFO_PILL_SENSOR_NOISE_ON
			 "0xA0A0A0", //COMMON_SETTING_GLUCOSE_PREDICTIONS_UAM_COLOR
			 "false", //COMMON_SETTING_NIGHTSCOUT_PREDICTIONS_UPLOADER_ON
			 "false", //COMMON_SETTING_GLUCOSE_PREDICTIONS_SINGLE_LINE_ENABLED
			 "true", //COMMON_SETTING_BAGE_ON
			 "0x00D1FE", //COMMON_SETTING_GLUCOSE_PREDICTIONS_ZT_COLOR
			 "0", //COMMON_SETTING_LAST_INSULIN_CARTRIDGE_CHANGE
			 "0", //COMMON_SETTING_LAST_PUMP_SITE_CHANGE
			 "0", //COMMON_SETTING_LAST_PUMP_BATTERY_CHANGE
			 "86400000", //COMMON_SETTING_PIE_CHART_VARIABILITY_OFFSET (1 Day)
			 "86400000", //COMMON_SETTING_PIE_CHART_TREATMENTS_OFFSET (1 Day)
			 "1", //COMMON_SETTING_PIE_CHART_ACTIVE_PAGE
			 "", //COMMON_SETTING_DATA_COLLECTION_DS_USERNAME
			 "", //COMMON_SETTING_DATA_COLLECTION_DS_PASSWORD
			 "us", //COMMON_SETTING_DATA_COLLECTION_DS_SERVER
			 "mdi", //COMMON_SETTING_USER_TYPE_PUMP_OR_MDI
			 "absolute", //COMMON_SETTING_PREFERRED_TEMP_BASAL_MODE
			 "0x164569", //COMMON_SETTING_TEMP_BASAL_AREA_COLOR
			 "0x0086FF", //COMMON_SETTING_ABSOLUTE_BASAL_LINE_COLOR
			 "0x0086FF", //COMMON_SETTING_BASAL_RATE_LINE_COLOR
			 "0x1A344C", //COMMON_SETTING_ABSOLUTE_BASAL_AREA_COLOR
			 "true", //COMMON_SETTING_DOWNLOAD_NIGHTSCOUT_BASALS
			 "true", //COMMON_SETTING_SHOW_BASALS_ON_CHART
			 DeviceInfo.isSmallScreenDevice() ? "20" : "15", //COMMON_SETTING_BASALS_AREA_SIZE_PERCENTAGE
			 "false" //COMMON_SETTING_USER_WARNED_OF_NON_OPTIMAL_ICLOUD_BACKUP_SCHEDULE
		 ];

		 public function CommonSettings()
		 {
			 if (_instance != null) {
				 throw new Error("CommonSettings class  constructor can not be used");	
			 }
		 }
		 
		 public static function getCommonSetting(commonSettingId:int):String {
			 var noAlert:String;
			 var newString:String;
			 if (commonSettingId == COMMON_SETTING_BATTERY_ALERT) {
				 if ((commonSettings[COMMON_SETTING_BATTERY_ALERT] as String).indexOf('DefaultValue') > -1) {
					 //actually the alert value is reset when user changes the transmittertype, which is each time the app starts
					 //as a result this branch is not useful anymore
					 newString = (commonSettings[COMMON_SETTING_BATTERY_ALERT] as String)
						 .replace('DefaultValue', "300");//default value for G5 is 300 - if user picks other transmitter type, (s)he will need to change the default value
					 setCommonSetting(COMMON_SETTING_BATTERY_ALERT, newString);
				 }
			 }
			 if (commonSettingId == COMMON_SETTING_LOW_ALERT) {
				 if ((commonSettings[COMMON_SETTING_LOW_ALERT] as String).indexOf('DefaultNoAlertToBeReplaced') > -1) {
					 noAlert = ModelLocator.resourceManagerInstance.getString("alertsettingsscreen","no_alert")
					 newString = (commonSettings[COMMON_SETTING_LOW_ALERT] as String)
						 .replace('DefaultNoAlertToBeReplaced', noAlert);
					 setCommonSetting(COMMON_SETTING_LOW_ALERT, newString);
				 }
			 }
			 if (commonSettingId == COMMON_SETTING_VERY_LOW_ALERT) {
				 if ((commonSettings[COMMON_SETTING_VERY_LOW_ALERT] as String).indexOf('DefaultNoAlertToBeReplaced') > -1) {
					 noAlert = ModelLocator.resourceManagerInstance.getString("alertsettingsscreen","no_alert")
					 newString = (commonSettings[COMMON_SETTING_VERY_LOW_ALERT] as String)
						 .replace('DefaultNoAlertToBeReplaced', noAlert);
					 setCommonSetting(COMMON_SETTING_VERY_LOW_ALERT, newString);
				 }
			 }
			 if (commonSettingId == COMMON_SETTING_VERY_HIGH_ALERT) {
				 if ((commonSettings[COMMON_SETTING_VERY_HIGH_ALERT] as String).indexOf('DefaultNoAlertToBeReplaced') > -1) {
					 noAlert = ModelLocator.resourceManagerInstance.getString("alertsettingsscreen","no_alert")
					 newString = (commonSettings[COMMON_SETTING_VERY_HIGH_ALERT] as String)
						 .replace('DefaultNoAlertToBeReplaced', noAlert);
					 setCommonSetting(COMMON_SETTING_VERY_HIGH_ALERT, newString);
				 }
			 }
			 if (commonSettingId == COMMON_SETTING_HIGH_ALERT) {
				 if ((commonSettings[COMMON_SETTING_HIGH_ALERT] as String).indexOf('DefaultNoAlertToBeReplaced') > -1) {
					 noAlert = ModelLocator.resourceManagerInstance.getString("alertsettingsscreen","no_alert")
					 newString = (commonSettings[COMMON_SETTING_HIGH_ALERT] as String)
						 .replace('DefaultNoAlertToBeReplaced', noAlert);
					 setCommonSetting(COMMON_SETTING_HIGH_ALERT, newString);
				 }
			 }
			 if (commonSettingId == COMMON_SETTING_FAST_RISE_ALERT) {
				 if ((commonSettings[COMMON_SETTING_FAST_RISE_ALERT] as String).indexOf('DefaultNoAlertToBeReplaced') > -1) {
					 noAlert = ModelLocator.resourceManagerInstance.getString("alertsettingsscreen","no_alert")
					 newString = (commonSettings[COMMON_SETTING_FAST_RISE_ALERT] as String)
						 .replace('DefaultNoAlertToBeReplaced', noAlert);
					 setCommonSetting(COMMON_SETTING_FAST_RISE_ALERT, newString);
				 }
			 }
			 if (commonSettingId == COMMON_SETTING_FAST_DROP_ALERT) {
				 if ((commonSettings[COMMON_SETTING_FAST_DROP_ALERT] as String).indexOf('DefaultNoAlertToBeReplaced') > -1) {
					 noAlert = ModelLocator.resourceManagerInstance.getString("alertsettingsscreen","no_alert")
					 newString = (commonSettings[COMMON_SETTING_FAST_DROP_ALERT] as String)
						 .replace('DefaultNoAlertToBeReplaced', noAlert);
					 setCommonSetting(COMMON_SETTING_FAST_DROP_ALERT, newString);
				 }
			 }
			 if (commonSettingId == COMMON_SETTING_MISSED_READING_ALERT) {
				 if ((commonSettings[COMMON_SETTING_MISSED_READING_ALERT] as String).indexOf('DefaultNoAlertToBeReplaced') > -1) {
					 noAlert = ModelLocator.resourceManagerInstance.getString("alertsettingsscreen","no_alert")
					 newString = (commonSettings[COMMON_SETTING_MISSED_READING_ALERT] as String)
						 .replace('DefaultNoAlertToBeReplaced', noAlert);
					 setCommonSetting(COMMON_SETTING_MISSED_READING_ALERT, newString);
				 }
			 }
			 if (commonSettingId == COMMON_SETTING_PHONE_MUTED_ALERT) {
				 if ((commonSettings[COMMON_SETTING_PHONE_MUTED_ALERT] as String).indexOf('DefaultNoAlertToBeReplaced') > -1) {
					 noAlert = ModelLocator.resourceManagerInstance.getString("alertsettingsscreen","no_alert")
					 newString = (commonSettings[COMMON_SETTING_PHONE_MUTED_ALERT] as String)
						 .replace('DefaultNoAlertToBeReplaced', noAlert);
					 setCommonSetting(COMMON_SETTING_PHONE_MUTED_ALERT, newString);
				 }
				 if ((commonSettings[COMMON_SETTING_PHONE_MUTED_ALERT] as String).indexOf('SilentToBeReplaced') > -1) {
					 noAlert = ModelLocator.resourceManagerInstance.getString("alertsettingsscreen","silent_alert")
					 newString = (commonSettings[COMMON_SETTING_PHONE_MUTED_ALERT] as String)
						 .replace('SilentToBeReplaced', noAlert);
					 setCommonSetting(COMMON_SETTING_PHONE_MUTED_ALERT, newString);
				 }
				 if ((commonSettings[COMMON_SETTING_PHONE_MUTED_ALERT] as String).indexOf('SilentPhoneMutedToBeReplaced') > -1) {
					 noAlert = ModelLocator.resourceManagerInstance.getString("alertsettingsscreen","silent_alert")
					 newString = (commonSettings[COMMON_SETTING_PHONE_MUTED_ALERT] as String)
						 .replace('SilentPhoneMutedToBeReplaced', noAlert);
					 setCommonSetting(COMMON_SETTING_PHONE_MUTED_ALERT, newString);
				 }
			 }
			 if (commonSettingId == COMMON_SETTING_BATTERY_ALERT) {
				 if ((commonSettings[COMMON_SETTING_BATTERY_ALERT] as String).indexOf('DefaultNoAlertToBeReplaced') > -1) {
					 noAlert = ModelLocator.resourceManagerInstance.getString("alertsettingsscreen","no_alert")
					 newString = (commonSettings[COMMON_SETTING_BATTERY_ALERT] as String)
						 .replace('DefaultNoAlertToBeReplaced', noAlert);
					 setCommonSetting(COMMON_SETTING_BATTERY_ALERT, newString);
				 }
				 if ((commonSettings[COMMON_SETTING_BATTERY_ALERT] as String).indexOf('SilentToBeReplaced') > -1) {
					 noAlert = ModelLocator.resourceManagerInstance.getString("alertsettingsscreen","silent_alert")
					 newString = (commonSettings[COMMON_SETTING_BATTERY_ALERT] as String)
						 .replace('SilentToBeReplaced', noAlert);
					 setCommonSetting(COMMON_SETTING_BATTERY_ALERT, newString);
				 }
				 if ((commonSettings[COMMON_SETTING_BATTERY_ALERT] as String).indexOf('SilentPhoneMutedToBeReplaced') > -1) {
					 noAlert = ModelLocator.resourceManagerInstance.getString("alertsettingsscreen","silent_alert")
					 newString = (commonSettings[COMMON_SETTING_BATTERY_ALERT] as String)
						 .replace('SilentPhoneMutedToBeReplaced', noAlert);
					 setCommonSetting(COMMON_SETTING_BATTERY_ALERT, newString);
				 }
			 }
			 if (commonSettingId == COMMON_SETTING_CALIBRATION_REQUEST_ALERT) {
				 if ((commonSettings[COMMON_SETTING_CALIBRATION_REQUEST_ALERT] as String).indexOf('DefaultNoAlertToBeReplaced') > -1) {
					 noAlert = ModelLocator.resourceManagerInstance.getString("alertsettingsscreen","no_alert")
					 newString = (commonSettings[COMMON_SETTING_CALIBRATION_REQUEST_ALERT] as String)
						 .replace('DefaultNoAlertToBeReplaced', noAlert);
					 setCommonSetting(COMMON_SETTING_CALIBRATION_REQUEST_ALERT, newString);
				 }
				 if ((commonSettings[COMMON_SETTING_CALIBRATION_REQUEST_ALERT] as String).indexOf('SilentToBeReplaced') > -1) {
					 noAlert = ModelLocator.resourceManagerInstance.getString("alertsettingsscreen","silent_alert")
					 newString = (commonSettings[COMMON_SETTING_CALIBRATION_REQUEST_ALERT] as String)
						 .replace('SilentToBeReplaced', noAlert);
					 setCommonSetting(COMMON_SETTING_CALIBRATION_REQUEST_ALERT, newString);
				 }
			 }
			 return commonSettings[commonSettingId];
		 }
		 
		 /**
		  * if  updateDatabase = true and dispatchSettingChangedEvent = true, then SETTING_CHANGED will be dispatched
		  */
		 public static function setCommonSetting(commonSettingId:int, newValue:String, updateDatabase:Boolean = true, dispatchSettingChangedEvent:Boolean = true):void {
			 if (commonSettings[commonSettingId] != newValue) {
				 if (commonSettingId == COMMON_SETTING_TRANSMITTER_ID) {
					 newValue = newValue.toUpperCase();
				 }
				 if (commonSettingId == COMMON_SETTING_G5_G6_BATTERY_MARKER) {
					 commonSettings[COMMON_SETTING_G5_G6_BATTERY_FROM_MARKER] = (new Date()).valueOf();
				 }
				 commonSettings[commonSettingId] = newValue;
				 if (updateDatabase) {
					 Database.updateCommonSetting(commonSettingId, newValue);
					 if (dispatchSettingChangedEvent) {
						 var settingChangedEvent:SettingsServiceEvent = new SettingsServiceEvent(SettingsServiceEvent.SETTING_CHANGED);
						 settingChangedEvent.data = commonSettingId;
						 _instance.dispatchEvent(settingChangedEvent);
					 }
				 }
			 }
		 }
		 
		 public static function getNumberOfSettings():int {
			 return commonSettings.length;
		 }
		 
		 public static function getAllSettings():Array
		 {
			 return commonSettings;
		 }
	 }
 }