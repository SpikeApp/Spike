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
 
 */
package Utilities
{
	import mx.collections.ArrayCollection;
	
	import spark.collections.Sort;
	import spark.collections.SortField;
	
	import model.ModelLocator;
	
	/**
	 * Will hold a list of FromAndValueElements<br>
	 * Offers methods to get the value and alarmname for a specific timing (between 00:00 and maximum 24:00:00 = 86400 seconds)<br>
	 * List of alarms, with for each value and name of the alarm. 
	 * 
	 */public class FromtimeAndValueArrayCollection extends ArrayCollection
	 {
		 [ResourceBundle("settingsview")]
		 
		 private var _arrayChanged:Boolean = false;
		 
		 /**
		  * is set to true whenever an item is added or removed, or when array is created<br>
		  * method is available to set the value to false, it is up to the client to use this method<br>
		  * 
		  */
		 public function get arrayChanged():Boolean
		 {
			 return _arrayChanged;
		 }
		 
		 /**
		  * as the name suggests, sets arrrayChanged to false
		  */
		 public function setArrayChangedToFalse():void {
			 _arrayChanged = false;
		 }
		 
		 private var dataSortField:SortField = new SortField();
		 private var dataSort:Sort = new Sort();
		 
		 public function FromtimeAndValueArrayCollection(source:Array, isBgValue:Boolean)
		 {
			 super(source);
			 
			 //check if element exists with from 00:00, if not add it
			 var cntr:int;
			 for (cntr = 0;cntr < length;cntr++) {
				 if ((getItemAt(cntr) as FromtimeAndValue).from == 0) {
					 break;
				 }
			 }
			 if (cntr == length) {
				 var noAlert:String = ModelLocator.resourceManagerInstance.getString("settingsview","no_alert")
				 super.addItem(new FromtimeAndValue("00:00", 100, noAlert, true, false, isBgValue));
			 }
			 
			 dataSortField.name="from";//value in FromtimeAndValue
			 dataSortField.numeric = true;
			 dataSort.fields = [dataSortField];
			 sort = dataSort;
			 refresh();
			 _arrayChanged = true;
		 }
		 
		 override public function removeItemAt(index:int):Object {
			 if ((getItemAt(index) as FromtimeAndValue).from == 0)
				 //we don't remove the first element
				 return (getItemAt(index));
			 var returnValue:Object = super.removeItemAt(index);
			 _arrayChanged = true;
			 refresh();
			 return returnValue;
		 }
		 
		 override public function addItem(item:Object):void {
			 if (!(item is FromtimeAndValue)) {
				 myTrace("in addItem, can only add FromtimeAndValue objects to FromtimeAndValueArrayCollection, throwing error");
				 throw new Error("can only add FromtimeAndValue objects to FromtimeAndValueArrayCollection");
			 }
			 //check if element with same fromtime already exists
			 var cntr:int;
			 
			 //verifications on values, if erros, Error is thrown
			 if ((item as FromtimeAndValue).from > 86400)
				 throw new Error("fromtimeandvalue, you're trying to add an item with from > 86400");
			 
			 //if any element exists with same fromtime, it is removed first
			 for (cntr = 0;cntr < length;cntr++) {
				 if ((getItemAt(cntr) as FromtimeAndValue).from == (item as FromtimeAndValue).from) {
					 super.removeItemAt(cntr);
					 break;
				 }
			 }
			 
			 //if percentage based, and if fromtime = 0 or 86400, then add it as not editable and not deletable
			 if ((item as FromtimeAndValue).from == 0) {
				 super.addItem(new FromtimeAndValue((item as FromtimeAndValue).from, (item as FromtimeAndValue).value, (item as FromtimeAndValue).alarmName, (item as FromtimeAndValue).editable,false,  (item as FromtimeAndValue).isBgValue));
			 } else {
				 super.addItem(new FromtimeAndValue((item as FromtimeAndValue).from, (item as FromtimeAndValue).value, (item as FromtimeAndValue).alarmName, (item as FromtimeAndValue).editable, (item as FromtimeAndValue).deletable,  (item as FromtimeAndValue).isBgValue));
			 }
			 refresh();	
			 _arrayChanged = true;
		 }
		 
		 /**
		  * gets the value for a specific timing.<br>
		  * <br>
		  * fromTime can have one of three formats :
		  * <ul>
		  * <li>
		  * a string representation of a time between 00:00 and 24:00 otherwise an error is thrown
		  * </li>
		  * <li>
		  * a number representing time in seconds, between 0 and 86400
		  * </li>
		  * <li>
		  * a date object - in this case only the Hour of the Day and the Minutes will be taken into account<br>
		  * Which means, if a date object is used , the maximum value can be 23:59<br>
		  * This is treated as real date, no utc conversion or something like that.
		  * </li>
		  * </ul>
		  */
		 public function getValue(timeAsNumber:Number, timeAsString:String, timeAsDate:Date):Number {
			 if (!isNaN(timeAsNumber)) {
				 if (timeAsNumber > 86400) {
					 myTrace("in getValue, fromTimeAsNumber should not be > 86400, throwing exception");
					 throw new Error("fromTimeAsNumber should not be > 86400");
				 }
			 }
			 if (!timeAsString == "") {
				 return getValue(((new Number(timeAsString.split(":")[0])) * 60 + (new Number(timeAsString.split(":")[1])))*60, "", null); 
			 }
			 
			 if (timeAsDate != null) {
				 return getValue(((new Number(timeAsDate.hours)) * 60 + (new Number(timeAsDate.minutes)))*60, "", null); 
			 }
			 
			 if (length == 1)
				 return (getItemAt(0) as FromtimeAndValue).value;
			 
			 var previousItem:int = 0;
			 while (previousItem < length - 1 && (getItemAt(previousItem + 1) as FromtimeAndValue).from < timeAsNumber)
				 previousItem++;
			 
			 myTrace("in getValue, returnvalue = " + (getItemAt(previousItem) as FromtimeAndValue).value);
			 return  (getItemAt(previousItem) as FromtimeAndValue).value;
		 }
		 
		 /**
		  * same as getvalue, but gets the next value
		  */
		 public function getNextValue(timeAsNumber:Number, timeAsString:String, timeAsDate:Date):Number {
			 if (!isNaN(timeAsNumber)) {
				 if (timeAsNumber > 86400) {
					 myTrace("in getNextValue, fromTimeAsNumber should not be > 86400, throwing exception");
					 throw new Error("fromTimeAsNumber should not be > 86400");
				 }
			 }
			 if (!timeAsString == "") {
				 return getNextValue(((new Number(timeAsString.split(":")[0])) * 60 + (new Number(timeAsString.split(":")[1])))*60, "", null); 
			 }
			 
			 if (timeAsDate != null) {
				 return getNextValue(((new Number(timeAsDate.hours)) * 60 + (new Number(timeAsDate.minutes)))*60, "", null); 
			 }
			 
			 if (length == 1)
				 return (getItemAt(0) as FromtimeAndValue).value;
			 
			 var previousItem:int = 0;
			 while (previousItem < length - 1 && (getItemAt(previousItem + 1) as FromtimeAndValue).from < timeAsNumber)
				 previousItem++;
			 
			 previousItem++;
			 if (previousItem == length)
				 previousItem = 0;
			 
			 myTrace("in getNextValue, returnvalue = " + (getItemAt(previousItem) as FromtimeAndValue).value);
			 return  (getItemAt(previousItem) as FromtimeAndValue).value;
		 }
		 
		 /**
		  * gets the alarmName for a specific timing.<br>
		  * <br>
		  * fromTime can have one of three formats :
		  * <ul>
		  * <li>
		  * a string representation of a time between 00:00 and 24:00 otherwise an error is thrown
		  * </li>
		  * <li>
		  * a number representing time in seconds, between 0 and 86400
		  * </li>
		  * <li>
		  * a date object - in this case only the Hour of the Day and the Minutes will be taken into account<br>
		  * Which means, if a date object is used , the maximum value can be 23:59<br>
		  * This is treated as real date, no utc conversion or something like that.
		  * </li>
		  * </ul>
		  */
		 public function getAlarmName(timeAsNumber:Number = Number.NaN,timeAsString:String = "",timeAsDate:Date = null):String {
			 if (!isNaN(timeAsNumber)) {
				 if (timeAsNumber > 86400) {
					 myTrace("in getAlarmName, fromTimeAsNumber should not be > 86400, throwing exception");
					 throw new Error("fromTimeAsNumber should not be > 86400");
				 }
			 }
			 if (!timeAsString == "") {
				 return getAlarmName(((new Number(timeAsString.split(":")[0])) * 60 + (new Number(timeAsString.split(":")[1])))*60); 
			 }
			 
			 if (timeAsDate != null) {
				 return getAlarmName(((new Number(timeAsDate.hours)) * 60 + (new Number(timeAsDate.minutes)))*60); 
			 }
			 
			 if (length == 1)
				 return (getItemAt(0) as FromtimeAndValue).alarmName;
			 
			 var previousItem:int = 0;
			 while (previousItem < length - 1 && (getItemAt(previousItem + 1) as FromtimeAndValue).from < timeAsNumber)
				 previousItem++;
			 
			 myTrace("in getAlarmName, returnvalue = " + (getItemAt(previousItem) as FromtimeAndValue).alarmName);
			 return  (getItemAt(previousItem) as FromtimeAndValue).alarmName;
		 }
		 
		 /**
		  * same as getAlarmName but gets next value
		  */
		 public function getNextAlarmName(timeAsNumber:Number = Number.NaN,timeAsString:String = "",timeAsDate:Date = null):String {
			 if (!isNaN(timeAsNumber)) {
				 if (timeAsNumber > 86400) {
					 myTrace("in getNextAlarmName, fromTimeAsNumber should not be > 86400, throwing exception");
					 throw new Error("fromTimeAsNumber should not be > 86400");
				 }
			 }
			 if (!timeAsString == "") {
				 return getNextAlarmName(((new Number(timeAsString.split(":")[0])) * 60 + (new Number(timeAsString.split(":")[1])))*60); 
			 }
			 
			 if (timeAsDate != null) {
				 return getNextAlarmName(((new Number(timeAsDate.hours)) * 60 + (new Number(timeAsDate.minutes)))*60); 
			 }
			 
			 if (length == 1)
				 return (getItemAt(0) as FromtimeAndValue).alarmName;
			 
			 var previousItem:int = 0;
			 while (previousItem < length - 1 && (getItemAt(previousItem + 1) as FromtimeAndValue).from < timeAsNumber)
				 previousItem++;
			 
			 previousItem++;
			 if (previousItem == length)
				 previousItem = 0;
		 
			 myTrace("in getNextAlarmName, returnvalue = " + (getItemAt(previousItem) as FromtimeAndValue).alarmName);
			 return  (getItemAt(previousItem) as FromtimeAndValue).alarmName;
		 }
		 
		 public function getNextFromTime(timeAsNumber:Number = Number.NaN,timeAsString:String = "",timeAsDate:Date = null):int {
			 if (!isNaN(timeAsNumber)) {
				 if (timeAsNumber > 86400) {
					 myTrace("in getNextFromTime, fromTimeAsNumber should not be > 86400, throwing exception");
					 throw new Error("fromTimeAsNumber should not be > 86400");
				 }
			 }
			 if (!timeAsString == "") {
				 return getNextFromTime(((new Number(timeAsString.split(":")[0])) * 60 + (new Number(timeAsString.split(":")[1])))*60); 
			 }
			 
			 if (timeAsDate != null) {
				 return getNextFromTime(((new Number(timeAsDate.hours)) * 60 + (new Number(timeAsDate.minutes)))*60); 
			 }
			 
			 if (length == 1)
				 return (getItemAt(0) as FromtimeAndValue).from;
			 
			 var previousItem:int = 0;
			 while (previousItem < length - 1 && (getItemAt(previousItem + 1) as FromtimeAndValue).from < timeAsNumber)
				 previousItem++;
			 
			 previousItem++;
			 if (previousItem == length)
				 previousItem = 0;
			 
			 myTrace("in getNextFromTime, returnvalue = " + (getItemAt(previousItem) as FromtimeAndValue).from);
			 return  (getItemAt(previousItem) as FromtimeAndValue).from;
		 }
		 
		 /**
		  * list of alarms, each time specify from value (ie as of which time applicable)<br>
		  * First one should always be time 00:00, and it lasts upto the time of the next value<br>
		  * Each alarm splitted by -<br>
		  * For each alarm specify the bg value in mg/dl for which it applies and the name of the alarm<br>
		  * BG alue and alarm name splitted by ><br>
		  * Example :<br>
		  * 00:00>70>Night-08:00>100>Day  ==> from 00:00 alarm with name Night, applies for value below or above (depending on the case)
		  * 70, as of 08:00 till 23:59 alarm with name Day applies, with value 100.
		  * 
		  */
		 public static function createList(alarmListAsString:String, isBgValue:Boolean):FromtimeAndValueArrayCollection {
			 var splittedByDash:Array = alarmListAsString.split("-");
			 var returnValue:FromtimeAndValueArrayCollection = new FromtimeAndValueArrayCollection(null, isBgValue);
			 for (var ctr:int = 0;ctr < splittedByDash.length;ctr++) {
				 returnValue.addItem( 
					 new FromtimeAndValue(
						 splittedByDash[ctr].split(">")[0],
						 splittedByDash[ctr].split(">")[1],
						 splittedByDash[ctr].split(">")[2],
						 true,
						 true,
						 isBgValue
					 )
				 );
			 }
			 return returnValue;
		 }
		 
		 /**
		  * just overriding it to align some comment<br>
		  * 
		  * using addItemAt does not really make sense because a sort will always occur<br>
		  * better to use addItem, then do getItemIndex to know the new index. 
		  */
		 override public function addItemAt(newObject:Object,index:int):void {
			 return super.addItemAt(newObject,index);
		 }
		 
		 /**
		  * creates the alarmstring list in a string as it's stored in the settings
		  */
		 public function createAlarmString():String {
			 var returnValue:String = "";
			 for (var cntr:int = 0;cntr < length;cntr++) {
				 if (returnValue.length > 0) {
					 returnValue += "-";
				 }
				 returnValue += (getItemAt(cntr) as FromtimeAndValue).fromAsString();
				 returnValue += ">";
				 returnValue += (getItemAt(cntr) as FromtimeAndValue).value.toString();
				 returnValue += ">";
				 returnValue += (getItemAt(cntr) as FromtimeAndValue).alarmName;
			 }
			 myTrace("in createAlarmString, returnvalue = " + returnValue);
			 return returnValue;
		 }
		 
		 public static function replaceAllValues(alarmString:String, newValue:Number, isBgValue:Boolean):String {
			 var oldList:FromtimeAndValueArrayCollection = createList(alarmString, isBgValue);
			 var newList:FromtimeAndValueArrayCollection = new FromtimeAndValueArrayCollection(null, isBgValue);
			 for (var cntr:int = 0;cntr < oldList.length; cntr++) {
				 var fromTimeAndValue:FromtimeAndValue = oldList.getItemAt(cntr) as FromtimeAndValue;
				 var newFromTimeAndValue:FromtimeAndValue = new FromtimeAndValue(fromTimeAndValue.from, newValue, fromTimeAndValue.alarmName, fromTimeAndValue.editable, fromTimeAndValue.deletable, isBgValue);
					newList.addItem(newFromTimeAndValue);			 
			 }
			 return newList.createAlarmString();
		 }
		 
		 private static function myTrace(log:String):void {
			 Trace.myTrace("FromtimeAndValueArrayCollection.as", log);
		 }
		 
	 }
}