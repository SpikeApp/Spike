/**
 Copyright (C) 2016  Johan Degraeve
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/gpl.txt>.
 
 */
package databaseclasses
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
		public static const LOCAL_SETTING_TIMESTAMP_SINCE_LAST_INFO_UKNOWN_PACKET_TYPE:int = 25;
		public static const LOCAL_SETTING_DONTASKAGAIN_ABOUT_UNKNOWN_PACKET_TYPE:int = 26;
		public static const LOCAL_SETTING_SPEECH_INSTRUCTIONS_ACCEPTED:int = 27;
		public static const LOCAL_SETTING_OVERRIDE_MUTE:int = 28;
		public static const LOCAL_SETTING_UPDATE_SERVICE_INITIALCHECK:int = 29;
		
		private static var localSettings:Array = [
			"false",//LOCAL_SETTING_DETAILED_TRACING_ENABLED
			"",//LOCAL_SETTING_TRACE_FILE_NAME
			"false",//LOCAL_SETTING_WARNING_THAT_NIGHTSCOUT_URL_AND_SECRET_IS_NOT_OK_ALREADY_GIVEN
			"true",//LOCAL_SETTING_ALWAYS_ON_NOTIFICATION
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
			"true"//LOCAL_SETTING_UPDATE_SERVICE_INITIALCHECK
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
	}
}