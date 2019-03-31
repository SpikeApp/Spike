package utils
{
	import model.ModelLocator;

	[ResourceBundle("chartscreen")]
	
	/**
	 * Represents an interval of time 
	 */ 
	public class TimeSpan
	{
		/**
		 * Constants that hold time in minutes
		 */
		public static const TIME_ONE_DAY_IN_MINUTES:int = 1440;
		
		/**
		 * Constants that hold time in milliseconds
		 */
		public static const TIME_2_WEEKS:int = 1209600000;
		public static const TIME_1_WEEK:int = 604800000;
		public static const TIME_48_HOURS:int = 172800000;
		public static const TIME_24_HOURS_6_MINUTES:int = 86760000;
		public static const TIME_24_HOURS:int = 86400000;
		public static const TIME_23_HOURS_59_MINUTES:int = 86340000;
		public static const TIME_23_HOURS_57_MINUTES:int = 82620000;
		public static const TIME_8_HOURS:int = 28800000;
		public static const TIME_6_HOURS:int = 21600000;
		public static const TIME_4_HOURS:int = 14400000;
		public static const TIME_3_HOURS:int = 10800000;
		public static const TIME_2_HOURS:int = 7200000;
		public static const TIME_1_HOUR:int = 3600000;
		public static const TIME_45_MINUTES:int = 2700000;
		public static const TIME_30_MINUTES:int = 1800000;
		public static const TIME_24_MINUTES:int = 1440000;
		public static const TIME_16_MINUTES:int = 960000;
		public static const TIME_15_MINUTES:int = 900000;
		public static const TIME_11_MINUTES:int = 660000;
		public static const TIME_10_MINUTES:int = 600000;
		public static const TIME_9_MINUTES:int = 540000;
		public static const TIME_7_MINUTES:int = 420000;
		public static const TIME_6_MINUTES:int = 360000;
		public static const TIME_5_MINUTES_30_SECONDS:int = 330000;
		public static const TIME_5_MINUTES_20_SECONDS:int = 320000;
		public static const TIME_5_MINUTES_10_SECONDS:int = 310000;
		public static const TIME_5_MINUTES:int = 300000;
		public static const TIME_4_MINUTES_45_SECONDS:int = 315000;
		public static const TIME_4_MINUTES_30_SECONDS:int = 270000;
		public static const TIME_4_MINUTES:int = 240000;
		public static const TIME_2_MINUTES_30_SECONDS:int = 150000;
		public static const TIME_1_MINUTE:int = 60000;
		public static const TIME_75_SECONDS:int = 75000;
		public static const TIME_45_SECONDS:int = 45000;
		public static const TIME_31_SECONDS:int = 31000;
		public static const TIME_30_SECONDS:int = 30000;
		public static const TIME_10_SECONDS:int = 10000;
		public static const TIME_5_SECONDS:int = 5000;
		public static const TIME_3_SECONDS:int = 3000;
		public static const TIME_2_SECONDS:int = 2000;
		
		/**
		 * The number of milliseconds in one day
		 */ 
		public static const MILLISECONDS_IN_DAY : Number = 86400000;
		
		/**
		 * The number of milliseconds in one hour
		 */ 
		public static const MILLISECONDS_IN_HOUR : Number = 3600000;
		
		/**
		 * The number of milliseconds in one minute
		 */ 
		public static const MILLISECONDS_IN_MINUTE : Number = 60000;
		
		/**
		 * The number of milliseconds in one second
		 */ 
		public static const MILLISECONDS_IN_SECOND : Number = 1000;
		
		/**
		 * The different time formats
		 */
		public static const TIME_FORMAT_12H:String = "12h";
		public static const TIME_FORMAT_24H:String = "24h";
		
		
		private var _totalMilliseconds : Number;
		
		public function TimeSpan(milliseconds : Number)
		{
			_totalMilliseconds = Math.floor(milliseconds);
		}
		
		/**
		 * Adds the timespan represented by this instance to the date provided and returns a new date object.
		 * @param date The date to add the timespan to
		 * @return A new Date with the offseted time
		 */     
		public function add(date : Date) : Date
		{
			var ret : Date = new Date(date.time);
			ret.milliseconds += totalMilliseconds;
			
			return ret;
		}
		
		/**
		 * Formats seconds into a reabale hours plus minutes string
		 */
		public static function formatHoursMinutesFromSeconds(secs:Number, prefixInHours:Boolean = true, prefixInMinutes:Boolean = true):String
		{
			var h:Number=Math.floor(secs/3600);
			var m:Number=Math.floor((secs%3600)/60);
			var s:Number=Math.floor((secs%3600)%60);
			var agoSuffix:String = " " + ModelLocator.resourceManagerInstance.getString('chartscreen','time_ago_suffix');
			
			return(h==0?"":(h<10 && prefixInHours?"0"+h.toString()+ModelLocator.resourceManagerInstance.getString('chartscreen','hours_small_abbreviation_label'):h.toString()+ModelLocator.resourceManagerInstance.getString('chartscreen','hours_small_abbreviation_label')))+(m==0 && h==0?ModelLocator.resourceManagerInstance.getString('chartscreen','now'):m<10 && prefixInMinutes?"0"+m.toString()+ModelLocator.resourceManagerInstance.getString('chartscreen','minutes_small_abbreviation_label'):m.toString()+ModelLocator.resourceManagerInstance.getString('chartscreen','minutes_small_abbreviation_label'));
		}
		
		public static function formatHoursMinutesFromSecondsChart(secs:Number, prefixInHours:Boolean = true, prefixInMinutes:Boolean = true, allowWhiteText:Boolean = true):String
		{
			var time:String;
			var h:Number=Math.floor(secs/3600);
			var m:Number=Math.floor((secs%3600)/60);
			var s:Number=Math.floor((secs%3600)%60);
			
			if (h == 0)
				time = (h==0?"":(h<10 && prefixInHours?"0"+h.toString()+ModelLocator.resourceManagerInstance.getString('chartscreen','hours_small_abbreviation_label'):h.toString()+ModelLocator.resourceManagerInstance.getString('chartscreen','hours_small_abbreviation_label')))+(m==0 && h==0?ModelLocator.resourceManagerInstance.getString('chartscreen','now'):m<10 && prefixInMinutes?"0"+m.toString()+ (allowWhiteText ? " " : "") + ModelLocator.resourceManagerInstance.getString('chartscreen','minutes_abbreviation_label'):m.toString()+ (allowWhiteText ? " " : "") + ModelLocator.resourceManagerInstance.getString('chartscreen','minutes_abbreviation_label'));
			else 
				time = (h==0?"":(h<10 && prefixInHours?"0"+h.toString()+ModelLocator.resourceManagerInstance.getString('chartscreen','hours_small_abbreviation_label'):h.toString()+ModelLocator.resourceManagerInstance.getString('chartscreen','hours_small_abbreviation_label')))+(m==0 && h==0?ModelLocator.resourceManagerInstance.getString('chartscreen','now'):m<10 && prefixInMinutes?"0"+m.toString()+ModelLocator.resourceManagerInstance.getString('chartscreen','minutes_small_abbreviation_label'):m.toString()+ModelLocator.resourceManagerInstance.getString('chartscreen','minutes_small_abbreviation_label'));
			
			return time;
		}
		
		public static function formatHoursMinutesFromMinutes(minutes:Number, prefixInHours:Boolean = true, prefixInMinutes:Boolean = true):String
		{
			var time:String;
			var h:Number = Math.floor(minutes/60);
			var m:Number = Math.floor(minutes%60);
			
			if (h == 0)
				time = m<10 && prefixInMinutes?"0"+m.toString()+ModelLocator.resourceManagerInstance.getString('chartscreen','minutes_abbreviation_label'):m.toString()+ModelLocator.resourceManagerInstance.getString('chartscreen','minutes_abbreviation_label');
			else if (h > 0 && m == 0)
				time = (h==0?"":(h<10 && prefixInHours?"0"+h.toString()+ModelLocator.resourceManagerInstance.getString('chartscreen','hours_small_abbreviation_label'):h.toString()+ModelLocator.resourceManagerInstance.getString('chartscreen','hours_small_abbreviation_label')));
			else 
				time = (h==0?"":(h<10 && prefixInHours?"0"+h.toString()+ModelLocator.resourceManagerInstance.getString('chartscreen','hours_small_abbreviation_label'):h.toString()+ModelLocator.resourceManagerInstance.getString('chartscreen','hours_small_abbreviation_label')))+(m<10 && prefixInMinutes?"0"+m.toString()+ModelLocator.resourceManagerInstance.getString('chartscreen','minutes_small_abbreviation_label'):m.toString()+ModelLocator.resourceManagerInstance.getString('chartscreen','minutes_small_abbreviation_label'));
			
			return time;
		}
		
		/**
		 * Formats hours plus minutes into a reabale hours plus minutes string. Supports 24H/12H TimeFormat
		 */
		public static function formatHoursMinutes (hours:Number, minutes:Number, timeFormat:String, specialWidgetOutput:Boolean = false, specialWidgetOutputUncondensed:Boolean = false):String
		{
			var hoursOutput:String = "";
			var amPmOutput:String = "";
			var minutesOutput:String = "";
			
			/* Hours */
			if (timeFormat == TIME_FORMAT_24H)
			{
				if (hours < 10)
					hoursOutput = "0" + hours;
				else
					hoursOutput = hours.toString();
			}
			else if (timeFormat == TIME_FORMAT_12H)
			{
				if (hours >= 12)
				{
					if (hours >= 13)
						hours -= 12; //Subtract 12 to the hour value to get 12H date format
					
					hoursOutput = hours.toString();
					
					amPmOutput = "PM";
				}
				else
				{
					hoursOutput = hours.toString();
					
					if (hoursOutput == "0")
						hoursOutput = "12";
					
					amPmOutput = "AM";
				}
			}
			
			/* Minutes */
			if (minutes < 10)
				minutesOutput = "0" + minutes;
			else
				minutesOutput = minutes.toString();
			
			var totalOutput:String;
			if (!specialWidgetOutput)
			{
				if (!specialWidgetOutputUncondensed)
					totalOutput = hoursOutput + ":" + minutesOutput + amPmOutput;
				else
				{
					totalOutput = hoursOutput + ":" + minutesOutput;
					if (amPmOutput != "")
						totalOutput += "\n" + amPmOutput;
				}
			}
			else
			{
				totalOutput = "";
				totalOutput += hoursOutput + "\n";
				totalOutput += minutesOutput;
				if (amPmOutput != "")
					totalOutput += "\n" + amPmOutput;
			}
			
			return totalOutput;
		}
		
		public static function getFormattedDateFromTimestamp(timestamp:Number):String
		{
			//Calculate Age
			var realDate:Date = new Date(timestamp)
			var nowDate:Date = new Date();
			var realDays:String = fromDates(realDate, nowDate).days.toString();
			var realHours:String = fromDates(realDate, nowDate).hours.toString();
			
			return realDays + "d " + realHours + "h";
		}
		
		/**
		 * Creates a TimeSpan from the different between two dates
		 * 
		 * Note that start can be after end, but it will result in negative values. 
		 *  
		 * @param start The start date of the timespan
		 * @param end The end date of the timespan
		 * @return A TimeSpan that represents the difference between the dates
		 * 
		 */     
		public static function fromDates(start : Date, end : Date) : TimeSpan
		{
			return new TimeSpan(end.time - start.time);
		}
		
		/**
		 * Creates a TimeSpan from the specified number of milliseconds
		 * @param milliseconds The number of milliseconds in the timespan
		 * @return A TimeSpan that represents the specified value
		 */     
		public static function fromMilliseconds(milliseconds : Number) : TimeSpan
		{
			return new TimeSpan(milliseconds);
		}
		
		/**
		 * Creates a TimeSpan from the specified number of seconds
		 * @param seconds The number of seconds in the timespan
		 * @return A TimeSpan that represents the specified value
		 */ 
		public static function fromSeconds(seconds : Number) : TimeSpan
		{
			return new TimeSpan(seconds * MILLISECONDS_IN_SECOND);
		}
		
		/**
		 * Creates a TimeSpan from the specified number of minutes
		 * @param minutes The number of minutes in the timespan
		 * @return A TimeSpan that represents the specified value
		 */ 
		public static function fromMinutes(minutes : Number) : TimeSpan
		{
			return new TimeSpan(minutes * MILLISECONDS_IN_MINUTE);
		}
		
		/**
		 * Creates a TimeSpan from the specified number of hours
		 * @param hours The number of hours in the timespan
		 * @return A TimeSpan that represents the specified value
		 */ 
		public static function fromHours(hours : Number) : TimeSpan
		{
			return new TimeSpan(hours * MILLISECONDS_IN_HOUR);
		}
		
		/**
		 * Creates a TimeSpan from the specified number of days
		 * @param days The number of days in the timespan
		 * @return A TimeSpan that represents the specified value
		 */ 
		public static function fromDays(days : Number) : TimeSpan
		{
			return new TimeSpan(days * MILLISECONDS_IN_DAY);
		}
		
		/**
		 * Gets the number of whole days
		 * 
		 * @example In a TimeSpan created from TimeSpan.fromHours(25), 
		 *          totalHours will be 1.04, but hours will be 1 
		 * @return A number representing the number of whole days in the TimeSpan
		 */
		public function get days() : int
		{
			return int(_totalMilliseconds / MILLISECONDS_IN_DAY);
		}
		
		/**
		 * Gets the number of whole hours (excluding entire days)
		 * 
		 * @example In a TimeSpan created from TimeSpan.fromMinutes(1500), 
		 *          totalHours will be 25, but hours will be 1 
		 * @return A number representing the number of whole hours in the TimeSpan
		 */
		public function get hours() : int
		{
			return int(_totalMilliseconds / MILLISECONDS_IN_HOUR) % 24;
		}
		
		public function get hoursFormatted() : String
		{
			var hours:int = int(_totalMilliseconds / MILLISECONDS_IN_HOUR) % 24;
			var hoursOutput:String;
			
			if (hours >= 10) hoursOutput = String(hours);
			else hoursOutput = "0" + hours;
			
			return hoursOutput;
		}
		
		/**
		 * Gets the number of whole minutes (excluding entire hours)
		 * 
		 * @example In a TimeSpan created from TimeSpan.fromMilliseconds(65500), 
		 *          totalSeconds will be 65.5, but seconds will be 5 
		 * @return A number representing the number of whole minutes in the TimeSpan
		 */
		public function get minutes() : int
		{
			return int(_totalMilliseconds / MILLISECONDS_IN_MINUTE) % 60; 
		}
		
		public function get minutesFormatted() : String
		{
			var minutes:int = int(_totalMilliseconds / MILLISECONDS_IN_MINUTE) % 60;
			var minutesOutput:String;
			
			if (minutes >= 10) minutesOutput = String(minutes);
			else minutesOutput = "0" + minutes;
			
			return minutesOutput;
		}
		
		/**
		 * Gets the number of whole seconds (excluding entire minutes)
		 * 
		 * @example In a TimeSpan created from TimeSpan.fromMilliseconds(65500), 
		 *          totalSeconds will be 65.5, but seconds will be 5 
		 * @return A number representing the number of whole seconds in the TimeSpan
		 */
		public function get seconds() : int
		{
			return int(_totalMilliseconds / MILLISECONDS_IN_SECOND) % 60;
		}
		
		/**
		 * Gets the number of whole milliseconds (excluding entire seconds)
		 * 
		 * @example In a TimeSpan created from TimeSpan.fromMilliseconds(2123), 
		 *          totalMilliseconds will be 2001, but milliseconds will be 123 
		 * @return A number representing the number of whole milliseconds in the TimeSpan
		 */
		public function get milliseconds() : int
		{
			return int(_totalMilliseconds) % 1000;
		}
		
		/**
		 * Gets the total number of days.
		 * 
		 * @example In a TimeSpan created from TimeSpan.fromHours(25), 
		 *          totalHours will be 1.04, but hours will be 1 
		 * @return A number representing the total number of days in the TimeSpan
		 */
		public function get totalDays() : Number
		{
			return _totalMilliseconds / MILLISECONDS_IN_DAY;
		}
		
		/**
		 * Gets the total number of hours.
		 * 
		 * @example In a TimeSpan created from TimeSpan.fromMinutes(1500), 
		 *          totalHours will be 25, but hours will be 1 
		 * @return A number representing the total number of hours in the TimeSpan
		 */
		public function get totalHours() : Number
		{
			return _totalMilliseconds / MILLISECONDS_IN_HOUR;
		}
		
		/**
		 * Gets the total number of minutes.
		 * 
		 * @example In a TimeSpan created from TimeSpan.fromMilliseconds(65500), 
		 *          totalSeconds will be 65.5, but seconds will be 5 
		 * @return A number representing the total number of minutes in the TimeSpan
		 */
		public function get totalMinutes() : Number
		{
			return _totalMilliseconds / MILLISECONDS_IN_MINUTE;
		}
		
		/**
		 * Gets the total number of seconds.
		 * 
		 * @example In a TimeSpan created from TimeSpan.fromMilliseconds(65500), 
		 *          totalSeconds will be 65.5, but seconds will be 5 
		 * @return A number representing the total number of seconds in the TimeSpan
		 */
		public function get totalSeconds() : Number
		{
			return _totalMilliseconds / MILLISECONDS_IN_SECOND;
		}
		
		/**
		 * Gets the total number of milliseconds.
		 * 
		 * @example In a TimeSpan created from TimeSpan.fromMilliseconds(2123), 
		 *          totalMilliseconds will be 2001, but milliseconds will be 123 
		 * @return A number representing the total number of milliseconds in the TimeSpan
		 */
		public function get totalMilliseconds() : Number
		{
			return _totalMilliseconds;
		}
	}
}