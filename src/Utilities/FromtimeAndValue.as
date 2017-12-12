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
	
	/**
	 * a class that can hold a from time<br>
	 * a value (decimal value)<br>
	 * an alarmName<br>
	 * <br>
	 * from time between 0 and 24 hours<br>
	 * <br>
	 * Once created, value, alarm name and from can't be modified anymore.<br>
	 */
	public class FromtimeAndValue
	{
		private var _from:int;//time in seconds
		public function get from():int {return _from;}
		private var _value:Number;
		
		private var _alarmName:String;
		
		public function get alarmName():String
		{
			return _alarmName;
		}
		
		public function get value():Number
		{
			return _value;
		}
		
		private var _editable:Boolean = true;
		
		/**
		 * get should only be used by the itemrenderer FromtimeAndValueItemRenderer<br>
		 * 
		 */
		public function get editable():Boolean
		{
			return _editable;
		}
		
		
		private var _deletable:Boolean = true;
		/**
		 * get should only be used by the itemrenderer FromtimeAndValueItemRenderer<br>
		 * 
		 */
		public function get deletable():Boolean
		{
			return _deletable;
		}
		
		private var _hasAddButton:Boolean = true;
		
		/**
		 * should it have an add button or not<br>
		 * If yes, an add button is shown in the itemrenderer, and treated in listview<br>
		 * It means a new item can be added after this one.
		 */
		public function get hasAddButton():Boolean
		{
			return _hasAddButton;
		}
		
		/**
		 * @private
		 */
		public function set hasAddButton(value:Boolean):void
		{
			_hasAddButton = value;
		}
		
		private var _isBgValue:Boolean = true;

		public function get isBgValue():Boolean
		{
			return _isBgValue;
		}

		public function set isBgValue(value:Boolean):void
		{
			_isBgValue = value;
		}
		
		
		/**
		 * the fromtime in format hh:mm 
		 */
		public function fromAsString():String {
			//return _from.toString();;
			var minutes:Number = (Math.round(from % 3600/60));
			var hours:Number = Math.floor(from/3600);
			if (minutes == 60) {
				minutes = 0;
				hours++;
			}
			return (hours < 10 ? "0" + hours:hours) + ":" + (minutes < 10 ? "0" + minutes:minutes);
		}
		
		/**
		 * newFrom can be integer or Number, in which case it represents time in seconds ! (not in milliseconds)<br>
		 * or String, in which case it represents time in format HH:mm<br>
		 * <br>
		 * once created, value and from can't be modified anymore.<br>
		 */
		public function FromtimeAndValue(newFrom:Object,newValue:Number, alarmName:String, isEditable:Boolean,isDeletable:Boolean, isBgvalue:Boolean)
		 {
			 _editable = isEditable;
			 _deletable = isDeletable;
			 _alarmName = alarmName;
			 _value = newValue;
			 _isBgValue = isBgvalue;
			 
			 if (newFrom is Number || newFrom is int)
				 _from = newFrom as Number;
			 else if (newFrom is String)
				 _from = ((new Number(newFrom.split(":")[0])) * 60 + (new Number(newFrom.split(":")[1])))*60;
			 else
				 throw new Error("error in FromtimeAndValue, newFrom should be Number, int or String");
			 
			 if (_from < 0 || _from > 86400000)
				 throw new Error("error in FromtimeAndValue, newFrom should be between 00:00 and 24:00 or between 0 and 86400");
		 }
	}
}