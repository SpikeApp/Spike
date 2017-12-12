/**
 Copyright (C) 2017  Johan Degraeve
 
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
 
 * MOST OF THIS CODE HERE IS COPIED FROM THE xDRIP-EXPERIMENTAL PROJECT AND PORTED
 * see https://github.com/StephenBlackWasAlreadyTaken/xDrip-Experimental
 * 
 */
package databaseclasses
{
	import Utilities.FromtimeAndValue;
	import Utilities.FromtimeAndValueArrayCollection;
	
	import model.ModelLocator;
	
	import services.DialogService;

	public class AlertType extends SuperDatabaseClass
	{
		private var _alarmName:String;

		public function get alarmName():String
		{
			return _alarmName;
		}
		
		private var _enableLights:Boolean;

		public function get enableLights():Boolean
		{
			return _enableLights;
		}

		private var _enabled:Boolean;
		
		public function get enabled():Boolean
		{
			return _enabled;
		}
		
		private var _enableVibration:Boolean;

		public function get enableVibration():Boolean
		{
			return _enableVibration;
		}

		private var _snoozeFromNotification:Boolean;

		public function get snoozeFromNotification():Boolean
		{
			return _snoozeFromNotification;
		}

		private var _overrideSilentMode:Boolean;

		public function get overrideSilentMode():Boolean
		{
			return _overrideSilentMode;
		}
	
		private var _sound:String;

		public function get sound():String
		{
			return _sound;
		}
		
		private var _defaultSnoozePeriodInMinutes:int;

		public function get defaultSnoozePeriodInMinutes():int
		{
			return _defaultSnoozePeriodInMinutes;
		}
		
		private var _repeatInMinutes:int;

		/**
		 * 0 is no repeat, for most alerts (or all ?), different from 0 just means repeat every minute using iOS, ie repeat not handled by app
		 */
		public function get repeatInMinutes():int
		{
			return _repeatInMinutes;
		}


		/**
		 * uniqueId and lastmodifiedtimestamp can be null, value will be assigned 
		 */
		public function AlertType(uniqueId:String, lastmodifiedtimestamp:Number, alarmName:String, enableLights:Boolean, enableVibration:Boolean, snoozeFromNotification:Boolean, enabled:Boolean, overrideSilentMode:Boolean, sound:String, defaultSnoozePeriodInMinutes:int, repeatInMinutes:int)
		{
			super(uniqueId, lastmodifiedtimestamp);
			this._alarmName = alarmName;
			this._defaultSnoozePeriodInMinutes = defaultSnoozePeriodInMinutes;
			this._enableLights = enableLights;
			this._enableVibration = enableVibration;
			this._overrideSilentMode = overrideSilentMode;
			this._snoozeFromNotification = snoozeFromNotification;
			this._sound = sound;
			this._enabled = enabled;
			this._repeatInMinutes = repeatInMinutes;
		}
		
		public function storeInDatabase():void {
			Database.insertAlertTypeSychronous(this);
		}
		
		public function deleteFromDatabase():void {
			Database.deleteAlertTypeSynchronous(this);
		}
		
		public function updateInDatabase():void {
			Database.updateAlertTypeSynchronous(this);
		}
		
		/**
		 * if newName not empty, then alarmtypename will be replaced in each alarm , returnvalue will also be true if a replacement occured
		 */
		public static function alertTypeUsed(alarmTypeNameToCheck:String, newName:String = ""):Boolean {
			var alertConstants:Array = [CommonSettings.COMMON_SETTING_LOW_ALERT, 
				CommonSettings.COMMON_SETTING_HIGH_ALERT, 
				CommonSettings.COMMON_SETTING_MISSED_READING_ALERT, 
				CommonSettings.COMMON_SETTING_PHONE_MUTED_ALERT, 
				CommonSettings.COMMON_SETTING_BATTERY_ALERT, 
				CommonSettings.COMMON_SETTING_CALIBRATION_REQUEST_ALERT, 
				CommonSettings.COMMON_SETTING_VERY_LOW_ALERT, 
				CommonSettings.COMMON_SETTING_VERY_HIGH_ALERT];
			var returnValue:Boolean = false;
			for each (var cntr2:int in alertConstants) {
				var setting:String = CommonSettings.getCommonSetting(cntr2);
				var listOfAlertsInTheSetting:FromtimeAndValueArrayCollection =  FromtimeAndValueArrayCollection.createList(setting, false);
				for (var cntr3:int = 0;cntr3 < listOfAlertsInTheSetting.length;cntr3++) {
					var fromTimeAndValue:FromtimeAndValue = listOfAlertsInTheSetting.getItemAt(cntr3) as FromtimeAndValue;
					if (fromTimeAndValue.alarmName.toUpperCase() == alarmTypeNameToCheck.toUpperCase()) {
						returnValue = true;
						if (newName.length > 0) {
							var splitByDash:Array = setting.split("-");
							var splitByGreaterThan:Array;
							var newSetting:String = "";
							if (splitByDash.length > 0) {
								for (var cntr4:int = 0; cntr4 < splitByDash.length; cntr4++) {
									splitByGreaterThan = (splitByDash[cntr4] as String).split(">");
									if (splitByGreaterThan.length > 0) {
										newSetting += splitByGreaterThan[0] + ">" + splitByGreaterThan[1] + ">" + ((splitByGreaterThan[2]) as String == alarmTypeNameToCheck ? newName:(splitByGreaterThan[2] as String));
									}
									if (cntr4 < splitByDash.length - 1)
										newSetting += "-";
								}
							}
							if (newSetting.length > 0) {
								CommonSettings.setCommonSetting(cntr2, newSetting, true, false);
							}
						}
					}
				}
			}
			return returnValue;
		}
	}
}