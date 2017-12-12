/**
 Copyright 2017 Johan Degraeve
 * 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License. */
/**
 * based on DateSpinner.as from Adobe : http://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/spark/components/DateSpinner.html<br>
 * Spinner to get a time between 00:00 and 24:00<br>
 * Time set here is UTC time, not local time<br>
 */
package skins
{
	import flash.events.Event;
	import flash.utils.Dictionary;
	
	import mx.collections.ArrayCollection;
	import mx.collections.IList;
	import mx.collections.ISort;
	import mx.core.IFactory;
	import mx.core.IVisualElementContainer;
	import mx.core.mx_internal;
	import mx.events.FlexEvent;
	
	import spark.collections.Sort;
	import spark.collections.SortField;
	import spark.components.SpinnerList;
	import spark.components.calendarClasses.DateSelectorDisplayMode;
	import spark.components.supportClasses.SkinnableComponent;
	import spark.events.IndexChangeEvent;
	import spark.formatters.DateTimeFormatter;
	import spark.formatters.NumberFormatter;
	import spark.globalization.supportClasses.DateTimeFormatterEx;
	
	import Utilities.DateTimeUtilities;
	
	use namespace mx_internal;
	
	[Exclude(name="textAlign", kind="style")]
	
	//--------------------------------------
	//  Events
	//--------------------------------------
	/**
	 *  Dispatched after the selected date has been changed by the user.
	 *
	 *  @eventType flash.events.Event.CHANGE
	 *  
	 *  @langversion 3.0
	 *  @playerversion AIR 3
	 *  @productversion Flex 4.6
	 */
	[Event(name="change", type="flash.events.Event")]
	
	/**
	 *  Dispatched after the selected date has been changed, either
	 *  by the user (i.e. interactively) or programmatically.
	 *
	 *  @eventType mx.events.FlexEvent.VALUE_COMMIT
	 *  
	 *  @langversion 3.0
	 *  @playerversion AIR 3
	 *  @productversion Flex 4.6
	 */
	[Event(name="valueCommit", type="mx.events.FlexEvent")]
	
	//--------------------------------------
	//  Styles
	//--------------------------------------
	
	include "../assets/StyleableTextFieldTextStyles.as"
	
	/**
	 *  The TimeSpinner36Hours control presents an interface for picking a particular time between 00:00 and 24:00 
	 */
	public class TimeSpinner36Hours extends SkinnableComponent
	{
		//--------------------------------------------------------------------------
		//
		//  Class constants
		//
		//--------------------------------------------------------------------------
		
		protected static const HOUR_ITEM:String = "hourItem";
		
		/**
		 *  Specifies to the <code>createDateItemList()</code> method that the list is for showing
		 *  minutes.
		 * 
		 *  @langversion 3.0
		 *  @playerversion AIR 3
		 *  @productversion Flex 4.6
		 */
		protected static const MINUTE_ITEM:String = "minuteItem";
		
		/**
		 *  Specifies to the <code>createDateItemList()</code> method that the list is for showing
		 *  meridian options.
		 * 
		 *  @langversion 3.0
		 *  @playerversion AIR 3
		 *  @productversion Flex 4.6
		 */
		private static const MS_IN_DAY:Number = 1000 * 60 * 60 * 24;
		
		// default min/max date
		private static const MIN_DATE_DEFAULT:Date = DateTimeUtilities.convertToUTC(new Date(0));
		private static const MAX_DATE_DEFAULT:Date = DateTimeUtilities.convertToUTC(new Date(86400000));//24 hours
		
		// the internal DateTimeFormatter that provides a set of extended functionalities
		private var dateTimeFormatterEx:DateTimeFormatterEx = new DateTimeFormatterEx();
		private var dateTimeFormatter:DateTimeFormatter = new DateTimeFormatter();
		
		private var displayModeChanged:Boolean = false;
		// the NumberFormatter to identify the longest yearList item in DATE mode
		private var numberFormatter:NumberFormatter;
		
		
		// Emphasized constant
		mx_internal static const EMPHASIZED_PROPERTY_NAME:String = "_emphasized_"; 
		
		public function TimeSpinner36Hours()
		{
			super();
		}
		
		//--------------------------------------------------------------------------
		//
		//  Variables
		//
		//--------------------------------------------------------------------------
		
		private var dispatchValueCommitEvent:Boolean = false;
		private var dispatchChangeEvent:Boolean = false;
		
		private var populateHourDataProvider:Boolean = true;
		private var populateMinuteDataProvider:Boolean = true;
		
		// caching the longest digit (the array value) between index and 9, inclusive, and refresh when locale changes
		private var longestDigitArray:Array = new Array(-1, -1, -1, -1, -1, -1, -1, -1, -1, -1);
		
		private var dateObj:Date = new Date();
		
		// controls whether we should snap to or animate to spinner values
		private var useAnimationToSetSelectedDate:Boolean = false;
		
		// keep track of which lists are currently animating for programmatic animations
		private var listsBeingAnimated:Dictionary = new Dictionary();
		
		//--------------------------------------------------------------------------
		//
		//  Skin parts 
		//
		//--------------------------------------------------------------------------
		
		[SkinPart]
		/**
		 *  The default factory for creating SpinnerList interfaces for all fields.
		 *  This is used by the <code>createDateItemList()</code> method.
		 * 
		 *  @langversion 3.0
		 *  @playerversion AIR 3
		 *  @productversion Flex 4.6
		 */
		public var dateItemList:IFactory;
		
		[SkinPart] 
		/**
		 *  The container for the date part lists.
		 * 
		 *  @langversion 3.0
		 *  @playerversion AIR 3
		 *  @productversion Flex 4.6
		 */
		public var listContainer:IVisualElementContainer;
		
		//--------------------------------------------------------------------------
		//
		//  Properties
		//
		//--------------------------------------------------------------------------
		
		protected var hourList:SpinnerList;
		
		/**
		 *  The SpinnerList that shows the minutes field of the date.
		 * 
		 *  @langversion 3.0
		 *  @playerversion AIR 3
		 *  @productversion Flex 4.6 
		 */ 
		protected var minuteList:SpinnerList;
		
		//----------------------------------
		//  displayMode
		//----------------------------------
		
		private var _displayMode:String = DateSelectorDisplayMode.TIME;
		
		
		[Inspectable(category="General", enumeration="date,time,dateAndTime", defaultValue="date")]
		
		public function get displayMode():String
		{
			return _displayMode;
		}
		
		//----------------------------------
		//  maxDate
		//----------------------------------
		
		private var _maxDate:Date = new Date(MAX_DATE_DEFAULT.time);
		
		private var maxDateChanged:Boolean = false;
		
		/**
		 *  Maximum time.
		 */
		public function get maxDate():Date
		{
			return new Date(_maxDate.time);
		}
		
		/**
		 * Maximum date, default value = 86400000 (24 hours)
		 */     
		public function set maxDate(value:Date):void
		{
			// don't allow minDate to be outside of the defaults
			if (value && 
				(value.time < MIN_DATE_DEFAULT.time || value.time > MAX_DATE_DEFAULT.time))
				value = null;
			
			// ignore if no change
			if ((_maxDate && value && _maxDate.time == value.time)
				|| (_maxDate == null && value == null))
				return;
			
			_maxDate = new Date(value != null ? value.time : MAX_DATE_DEFAULT.time);
			maxDateChanged = true;
			syncSelectedDate = true;
			
			invalidateProperties();
		}
		
		//----------------------------------
		//  minDate
		//----------------------------------
		
		private var _minDate:Date = new Date(MIN_DATE_DEFAULT.time);
		
		private var minDateChanged:Boolean = false;
		
		/**
		 *  Minimum time. Default value = 0
		 * 
		 */
		public function get minDate():Date
		{
			return new Date(_minDate.time);
		}
		
		/**
		 *  @private
		 */     
		public function set minDate(value:Date):void
		{
			// don't allow minDate to be outside of the defaults
			if (value && 
				(value.time < MIN_DATE_DEFAULT.time || value.time > MAX_DATE_DEFAULT.time))
				value = null;
			
			// ignore if no change
			if ((_minDate && value && _minDate.time == value.time)
				|| (_minDate == null && value == null))
				return;
			
			_minDate = new Date(value != null ? value.time : MIN_DATE_DEFAULT.time);
			minDateChanged = true;        
			syncSelectedDate = true;
			
			invalidateProperties();
		}
		
		//----------------------------------
		//  minuteStepSize
		//----------------------------------
		private var _minuteStepSize:int = 1;
		
		public function get minuteStepSize():int
		{
			return _minuteStepSize;
		}
		
		//----------------------------------
		//  selectedDate
		//----------------------------------
		private var _selectedDate:Date = todayDate;
		
		// set to true initially so that lists will be set to right values on creation
		private var syncSelectedDate:Boolean = true;
		
		[Bindable(event="valueCommit")]
		/**
		 *  Date that is currently selected in the DateSpinner control.
		 * 
		 *  <p>Note that the Date object returned by the getter is a copy of 
		 *  the internal Date, and the one provided to the setter is copied
		 *  internally, so modifications to these will not be reflected in the
		 *  DateSpinner. To modify the DateSpinner's date, get and modify the
		 *  current selectedDate and then re-set the selectedDate.</p>
		 *
		 *  @default the current date
		 * 
		 *  @langversion 3.0
		 *  @playerversion AIR 3
		 *  @productversion Flex 4.6
		 * 
		 */
		public function get selectedDate():Date
		{
			return new Date(_selectedDate.time);
		}
		
		/**
		 *  @private
		 */
		public function set selectedDate(value:Date):void
		{
			// no-op if null; there must always be a selectedDate
			if (value == null)
				value = todayDate;
			
			// short-circuit if no change
			if (value.time == _selectedDate.time)
				return;
			
			/*if (value.time < _minDate.time || value.time > _maxDate.time)
			throw new Error("error in set selectedDate, value must be between " + _minDate + " and " + _maxDate);*/
			
			_selectedDate = new Date(value.time);
			syncSelectedDate = true;
			
			dispatchValueCommitEvent = true;
			
			invalidateProperties();
		}
		
		//----------------------------------
		//  todayDate
		//----------------------------------
		
		mx_internal static var _todayDate:Date = null;
		
		/**
		 *  @private
		 *  Function to retrieve the current Date. Provided so that
		 *  testing can override by setting the _todayDate variable.
		 */
		private static function get todayDate():Date
		{
			if (_todayDate != null)
			{
				// use a copy, not the original that was passed in
				return new Date(_todayDate.time);
			}
			
			return new Date();
		}
		
		//--------------------------------------------------------------------------
		//
		//  Overridden methods
		//
		//--------------------------------------------------------------------------
		
		/**
		 *  @private
		 */
		override protected function attachSkin():void
		{
			super.attachSkin();
			
			displayModeChanged = true;
			
			invalidateProperties();
		}    
		
		/**
		 *  @private
		 */
		override protected function commitProperties():void
		{
			super.commitProperties();
			
			var localeStr:String = getStyle("locale");
			// stop any animations if we might be resetting the visible values
			if (syncSelectedDate)
				stopAllAnimations();
			
			// ==================================================
			// switch out lists if the display mode changed
			
			if (displayModeChanged)//i don't think we will come here
			{
				setupDateItemLists();
				
				displayModeChanged = false;
				syncSelectedDate = true;
			}
			
			// ==================================================
			// populate the lists with the appropriate data providers
			
			populateDateItemLists(localeStr);
			
			// ==================================================
			
			// correct any integrity violations
			if (minDateChanged || maxDateChanged || syncSelectedDate)
			{        
				// check min <= max
				if (_minDate.time > _maxDate.time)
				{
					// note assumption here that we're not using the defaults since they
					// should always maintain minDate < maxDate integrity
					
					// correct min/max dates, one day apart
					if (!maxDateChanged)
						_minDate.time = _maxDate.time - MS_IN_DAY; // min date was changed past max
					else
						_maxDate.time = _minDate.time + MS_IN_DAY; // max date was changed past min
				}
				
				// make sure there's at least one minuteStepSize between the min and max
				//if ((_maxDate.time - _minDate.time) < (minuteStepSize * 60 * 1000))
				//	_maxDate.time = _minDate.time + (minuteStepSize * 60 * 1000);
				
				var origSelectedDate:Date = new Date(_selectedDate.time);
				
				// check minDate <= selectedDate <= maxDate
				if (!_selectedDate || _selectedDate.time < _minDate.time )
				{
					_selectedDate = new Date(_minDate.time);
				}
				else if (_selectedDate.time > _maxDate.time )
				{
					_selectedDate = new Date(_maxDate.time );
				}
				
				minDateChanged = false;
				maxDateChanged = false;
				
				if (origSelectedDate.time != _selectedDate.time)
					dispatchValueCommitEvent = true;
				
				disableInvalidSpinnerValues(_selectedDate);
			}
			
			// ==================================================
			// update selections on the lists if necessary
			if (syncSelectedDate)
			{
				updateListsToSelectedDate(useAnimationToSetSelectedDate);
				syncSelectedDate = false;
				
				if (dispatchChangeEvent || dispatchValueCommitEvent)
				{
					// dispatch the events: now or after animation?
					if (useAnimationToSetSelectedDate)
					{
						// we animated the list ourselves; wait for lists
						// to report VALUE_COMMIT before dispatching our events
						var numEls:int = listContainer.numElements;
						var sl:SpinnerList;
						for (var elIdx:int = 0; elIdx < numEls; elIdx++)
						{
							sl = listContainer.getElementAt(elIdx) as SpinnerList;
							sl.addEventListener(FlexEvent.VALUE_COMMIT, waitForSpinnerListValueCommit_handler);
						}
					}
					else
					{
						// dispatch our events immediately
						dispatchSelectedDateChangedEvents();
					}
				}
			}
			
			// reset flags
			useAnimationToSetSelectedDate = false;
		}
		
		/**
		 *  @private
		 */
		override public function styleChanged(styleProp:String):void
		{
			super.styleChanged(styleProp);
			
			// if locale changed, all date item formats need to be regenerated
			if (styleProp == "locale")
			{
				displayModeChanged = true; // order of lists may be different with new locale
				
				populateHourDataProvider = true;
				populateMinuteDataProvider = true;
				
				syncSelectedDate = true;
				
				invalidateProperties();
			}
		}
		
		//--------------------------------------------------------------------------
		//
		//  Methods
		//
		//--------------------------------------------------------------------------
		
		/**
		 *  Create a list object for the specified date part.
		 * 
		 *  @param datePart Use date part constants, e.g. YEAR_ITEM.
		 *  @param itemIndex Index of the date part in the overall list container.
		 *  @param itemCount Number of date parts being shown.
		 * 
		 *  @langversion 3.0
		 *  @playerversion AIR 3
		 *  @productversion Flex 4.6
		 * 
		 *  @return A SpinnerList that contains the part.
		 */
		protected function createDateItemList(datePart:String, itemIndex:int, itemCount:int):SpinnerList
		{
			return SpinnerList(createDynamicPartInstance("dateItemList"));
		}
		
		/**
		 *  @private
		 *  Sets up the date item lists based on the current mode. Clears pre-existing lists.
		 */    
		private function setupDateItemLists():void
		{
			// an array of the list and position objects that will be sorted by position
			var fieldPositionObjArray:ArrayCollection = new ArrayCollection();
			var listSort:ISort = new Sort();
			listSort.fields = [new SortField("position")];
			fieldPositionObjArray.sort = listSort;
			
			// clean out the container and all existing lists
			// they may be in different positions, which will affect how they
			// need to be (re)created
			cleanContainer();
			
			var fieldPosition:int = 0;
			var listItem:Object;
			var tempList:SpinnerList;
			var numItems:int;
			
			// configure the correct lists to use
			fieldPositionObjArray.addItem(generateFieldPositionObject(HOUR_ITEM, dateTimeFormatterEx.getHourPosition()));
			fieldPositionObjArray.addItem(generateFieldPositionObject(MINUTE_ITEM, dateTimeFormatterEx.getMinutePosition()));
			
			// sort fieldPosition objects by position               
			fieldPositionObjArray.refresh();
			
			numItems = fieldPositionObjArray.length;
			
			for each (listItem in fieldPositionObjArray)
			{
				switch(listItem.dateItem)
				{
					case HOUR_ITEM:
					{
						hourList = createDateItemList(HOUR_ITEM, fieldPosition++, numItems);
						tempList = hourList;
						break;
					}
					case MINUTE_ITEM:
					{
						minuteList = createDateItemList(MINUTE_ITEM, fieldPosition++, numItems);
						tempList = minuteList;
						break;
					}
				}
				if (tempList && listContainer)
				{
					tempList.addEventListener(IndexChangeEvent.CHANGE, dateItemList_changeHandler);
					listContainer.addElement(tempList);
				}
			}
		}
		
		/**
		 *  Populate the currently existing date item lists with correct data providers using the
		 *  provided locale to format the date text correctly.
		 */    
		private function populateDateItemLists(localeStr:String):void
		{
			if (hourList && populateHourDataProvider)
			{
				hourList.dataProvider = generateHours();
				hourList.typicalItem = getLongestLabel(hourList.dataProvider);
				alignList(hourList);
			}
			if (minuteList && populateMinuteDataProvider)
			{
				minuteList.dataProvider = generateMinutes();
				minuteList.typicalItem = getLongestLabel(minuteList.dataProvider);
				
				alignList(minuteList);
			}
			populateHourDataProvider = false;
			populateMinuteDataProvider = false;
		}
		
		// set the selected index on the SpinnerList. use animation only if requested
		private function goToIndex(list:SpinnerList, newIndex:int, useAnimation:Boolean):void
		{
			// don't do anything if it's already on that index
			if (list.selectedIndex == newIndex)
				return;
			
			if (useAnimation)
			{
				list.animateToSelectedIndex(newIndex);
				listsBeingAnimated[list] = true;
			}
			else
			{
				list.selectedIndex = newIndex;
			}
		}
		
		// generate hour objects for a SpinnerList
		private function generateHours():IList
		{
			var ac:ArrayCollection = new ArrayCollection();
			
			var minHour:int = 0 ;
			var maxHour:int = 23;
			
			
			for (var i:int = minHour; i <= maxHour; i++)
			{
				var hours:String = new Number(i).toString();
				ac.addItem( generateDateItemObject(hours.length == 1 ? "0" + hours:hours, i) );
			}
			
			return ac;
		}
		
		private function generateMinutes():IList
		{
			var ac:ArrayCollection = new ArrayCollection();
			
			dateTimeFormatter.dateTimePattern = dateTimeFormatterEx.getMinutePattern();
			
			for (var i:int = 0; i <= 59; i += minuteStepSize)
			{
				dateObj.minutes = i;
				ac.addItem( generateDateItemObject(dateTimeFormatter.format(dateObj), i) );
			}
			
			return ac;
		}
		
		private function findDateItemIndexInDataProvider(item:Number, dataProvider:IList):int
		{
			for (var i:int = 0; i < dataProvider.length; i++)
			{
				if (dataProvider.getItemAt(i).data == item)
					return i;
			}
			return -1;
		}
		
		private function getLongestLabel(list:IList):Object
		{
			var idx:int = -1;
			var maxWidth:Number = 0;
			var labelWidth:Number;
			for (var i:int = 0; i < list.length; i++)
			{
				// note: measureText() measures UITextField while our labels will be
				// shown in StyleableTextField, but that's okay because we're only
				// looking for the text that is relatively longest in the list
				labelWidth = measureText(list[i].label).width;
				if (labelWidth > maxWidth)
				{
					maxWidth = labelWidth;
					idx = i;
				}
			}
			if (idx != -1)
				return list.getItemAt(idx);
			
			return null;
		}
		
		// set textAlign on list based on position, listType, or typicalItem content type:
		// left list => align right
		// right list => align left
		// HOUR list => align right
		// MINUTE list => align left
		// numeric or (numeric + text) => align right
		// (text + numeric) => align left
		// all other cases => align center
		mx_internal function alignList(list:SpinnerList):void
		{
			// set outside alignments tight; set alignments for HOUR and MINUTE
			if (list == listContainer.getElementAt(0))
				list.setStyle("textAlign", "right");
			else if (list == listContainer.getElementAt(listContainer.numElements - 1))
				list.setStyle("textAlign", "left");
			else if (list == hourList)
				list.setStyle("textAlign", "right");
			else if (list == minuteList)
				list.setStyle("textAlign", "left");
			else
			{
				var testString:String = list.typicalItem["label"];
				if (testString == null)
				{
					// nothing to test; use default
					list.setStyle("textAlign", "center");
					return;
				}
				
				var numericPattern:RegExp = /^\d+$/;
				var numericWithTextRight:RegExp = /^\d+\D+$/;
				var numericWithTextLeft:RegExp = /^\D+\d+$/;
				if (numericPattern.test(testString) || numericWithTextRight.test(testString)) // e.g. ja-JP month
					list.setStyle("textAlign", "right");
				else if (numericWithTextLeft.test(testString))
					list.setStyle("textAlign", "left");
				else
					list.setStyle("textAlign", "center"); // default
			}
		}
		
		private function updateListsToSelectedDate(useAnimation:Boolean):void
		{
			var newIndex:int;
			if (hourList)
			{
				newIndex = _selectedDate.hours + (_selectedDate.date - 1) * 24;
				goToIndex(hourList, newIndex, useAnimation);
			}
			if (minuteList)
			{
				newIndex = findDateItemIndexInDataProvider(_selectedDate.minutes, minuteList.dataProvider);
				goToIndex(minuteList, newIndex, useAnimation);
			}
		}
		
		// modify existing date item spinner list data providers to mark
		// as disabled any combinations that could result by moving one spinner
		// where the resulting new date would be invalid, either by definition
		// (e.g. Apr 31 is not a valid date) or by limitation (e.g. outside of the
		// range defined by minDate and maxDate)
		private function disableInvalidSpinnerValues(thisDate:Date):void
		{
			var tempDate:Date;
			var listData:IList;
			
			// run through the entire list of dates and set enabled flags as necessary
			//var cd:CalendarDate = new CalendarDate(thisDate);
			var listLength:int;
			
			// disable dates in spinners that are invalid (e.g. Apr 31) or fall outside
			// of the min/max date range
			// disable hours that fall outside of the min/max dates
			if (hourList && (displayMode == DateSelectorDisplayMode.TIME || displayMode == DateSelectorDisplayMode.DATE_AND_TIME))
			{
				tempDate = new Date(thisDate.time);
				listData = hourList.dataProvider;
				listLength = listData.length;
				var i:int;
				var curObj:Object;
				var newEnabledValue:Boolean;
				var o:Object;
				
				for (i = 0; i < listLength; i++)
				{
					curObj = listData[i];
					
					newEnabledValue = true;
					
					if (tempDate.date == 2)
						tempDate.date = 1;
					tempDate.hours = i;
					
					if (tempDate.hours + (tempDate.date - 1) * 24 < _minDate.hours + (_minDate.date - 1) * 24 )
						newEnabledValue = false;
					
					if (tempDate.hours + (tempDate.date - 1) * 24 > _maxDate.hours + (_maxDate.date - 1) * 24 )
						newEnabledValue = false;
					
					if (curObj[SpinnerList.ENABLED_PROPERTY_NAME] != newEnabledValue)
					{
						o = generateDateItemObject(curObj.label, curObj.data, newEnabledValue);
						o[EMPHASIZED_PROPERTY_NAME] = curObj[EMPHASIZED_PROPERTY_NAME];
						listData[i] = o;
					}
				}
			}
			
			// disable minutes that fall outside of the min/max dates
			if (minuteList && (displayMode == DateSelectorDisplayMode.TIME || displayMode == DateSelectorDisplayMode.DATE_AND_TIME))
			{
				tempDate = new Date(thisDate.time);
				listData = minuteList.dataProvider;
				listLength = listData.length;
				
				for (i = 0; i < listLength; i++)
				{
					curObj = listData[i];
					
					newEnabledValue = true;
					
					tempDate.minutes = curObj.data;
					
					var minHourMatch:Boolean = (tempDate.hours + (tempDate.date - 1) * 24 == _minDate.hours + (_minDate.date - 1) * 24 );
					var maxHourMatch:Boolean = (tempDate.hours + (tempDate.date - 1) * 24 == _maxDate.hours + (_maxDate.date - 1) * 24 );
					
					if (minHourMatch && tempDate.minutes < _minDate.minutes)
						newEnabledValue = false;
					
					if (maxHourMatch && tempDate.minutes > _maxDate.minutes)
						newEnabledValue = false;
					
					if (curObj[SpinnerList.ENABLED_PROPERTY_NAME] != newEnabledValue)
					{
						o = generateDateItemObject(curObj.label, curObj.data, newEnabledValue);
						o[EMPHASIZED_PROPERTY_NAME] = curObj[EMPHASIZED_PROPERTY_NAME];
						listData[i] = o;
					}
				}
			}
		}
		
		// clean out the container: remove all elements, detach event listeners, null out references
		private function cleanContainer():void
		{
			if (listContainer)
				listContainer.removeAllElements();
			
			if (hourList)
			{
				hourList.removeEventListener(IndexChangeEvent.CHANGE, dateItemList_changeHandler);
				hourList = null;
			}
			if (minuteList)
			{
				minuteList.removeEventListener(IndexChangeEvent.CHANGE, dateItemList_changeHandler);
				minuteList = null;
			}
		}
		
		// convenience method to generate the standard object format for data in the list dataproviders
		private function generateDateItemObject(label:String, data:*, enabled:Boolean = true):Object
		{
			var obj:Object = { label:label, data:data };
			obj[SpinnerList.ENABLED_PROPERTY_NAME] = enabled;
			return obj;
		}
		
		// generate the fieldPosition object that contains the date part name and position based on locale
		private function generateFieldPositionObject(datePart:String, position:int):Object
		{
			var obj:Object = { dateItem:datePart, position:position };
			return obj;
		}
		
		// returns true if any of the lists are currently animating
		private function get spinnersAnimating():Boolean
		{
			if (!listContainer)
				return false;
			
			var len:int = listContainer.numElements;
			for (var i:int = 0; i < len; i++)
			{
				var list:SpinnerList = listContainer.getElementAt(i) as SpinnerList;
				// return true as soon as we have one list still in touch interaction
				if (list && list.scroller && list.scroller.inTouchInteraction)
					return true;
			}
			return false;
		}
		
		// return the longest digit between min and 9, inclusive
		// call updateNumberFormatter() before calling this function to refresh longestDigitArray
		private function getLongestDigit(min:int = 0):int
		{
			var longestDigit:int = longestDigitArray[min];
			var labelWidth:Number = -1;
			var maxWidth:Number = 0;
			
			if (longestDigit == -1)
			{
				for (var i:int = min; i < 10; i++)
				{
					labelWidth = measureText(numberFormatter.format(i)).width;
					if (labelWidth > maxWidth)
					{
						maxWidth = labelWidth;
						longestDigit = i;
					}
				}
				
				longestDigitArray[min] = longestDigit;
			}
			
			return longestDigit;
		}
		
		// instantiate the number formatter and update its locale property
		private function updateNumberFormatter():void
		{
			if(!numberFormatter)
				numberFormatter = new NumberFormatter();
			
			// reset to -1
			for (var i:int = 0; i < longestDigitArray.length; i++) 
				longestDigitArray[i] = -1;
			
			var localeStr:String = getStyle("locale");
			if (localeStr)
				numberFormatter.setStyle("locale", localeStr);
			else
				numberFormatter.clearStyle("locale");
		}
		
		// used to delay the dispatch of change events from this DateSpinner until
		// the underlying SpinnerLists have stopped animating (signified by
		// a VALUE_COMMIT event)
		private function waitForSpinnerListValueCommit_handler(event:FlexEvent):void
		{
			// if listsBeingAnimated contains event.target remove it
			if (listsBeingAnimated[event.target])
			{
				delete listsBeingAnimated[event.target];
			}
			
			// if we're still waiting on any lists, don't dispatch yet
			for (var key:Object in listsBeingAnimated)
			{
				return;
			}
			
			// if no more in listsBeingAnimated, dispatch
			dispatchSelectedDateChangedEvents();
			
			// clean up
			var numEls:int = listContainer.numElements;
			var sl:SpinnerList;
			for (var elIdx:int = 0; elIdx < numEls; elIdx++)
			{
				sl = listContainer.getElementAt(elIdx) as SpinnerList;
				sl.removeEventListener(FlexEvent.VALUE_COMMIT, waitForSpinnerListValueCommit_handler);
			}
		}
		
		// dispatch the appropriate events when selectedDate changed
		private function dispatchSelectedDateChangedEvents():void
		{
			if (dispatchChangeEvent)
			{
				if (hasEventListener(Event.CHANGE))
					dispatchEvent(new Event(Event.CHANGE));
				
				dispatchChangeEvent = false;
			}
			if (dispatchValueCommitEvent)
			{
				if (hasEventListener(FlexEvent.VALUE_COMMIT))
					dispatchEvent(new FlexEvent(FlexEvent.VALUE_COMMIT));
				
				dispatchValueCommitEvent = false;
			}
		}
		
		private function stopAllAnimations():void
		{
			if (spinnersAnimating)
			{
				var len:int = listContainer.numElements;
				for (var i:int = 0; i < len; i++)
				{
					var list:SpinnerList = listContainer.getElementAt(i) as SpinnerList;
					// return true as soon as we have one list still in touch interaction
					if (list && list.scroller && list.scroller.inTouchInteraction)
						list.scroller.stopAnimations();
				}       
			}
		}
		
		//----------------------------------------------------------------------------------------------
		//
		//  Event handlers
		//
		//----------------------------------------------------------------------------------------------
		/**
		 *  Handles changes in the underlying SpinnerLists; applies them to the selectedDate
		 * @param event
		 * 
		 */ 
		private function dateItemList_changeHandler(event:IndexChangeEvent):void
		{
			if (spinnersAnimating)
			{
				// don't commit any changes until all spinners have come to a stop
				return;
			}
			
			var newDate:Date = new Date(0);
			
			var numLists:int = listContainer.numElements;
			var currentList:SpinnerList;
			
			// loop through all lists in the container and adjust selectedDate to their values
			for (var i:int = 0; i < numLists; i++)
			{
				currentList = listContainer.getElementAt(i) as SpinnerList;
				var newValue:* = currentList.selectedItem;
				
				switch (currentList)
				{
					case hourList:
						newDate.hours = newValue.data;
						break;
					case minuteList:
						newDate.minutes = newValue.data;
						break;
					default:
						// unknown list; don't know how to handle
						break;
				}
			}
			
			dispatchChangeEvent = true;
			
			selectedDate = newDate;
		}
	}
}
