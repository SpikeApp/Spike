package utils
{
	public class DateTimeUtilities
	{
		public function DateTimeUtilities()
		{
		}
		
		public static function createNSFormattedDateAndTime(dateAndTime:Date):String {
			var month:String = (dateAndTime.monthUTC + 1).toString().length < 2 ? "0" + (dateAndTime.monthUTC + 1).toString() : (dateAndTime.monthUTC + 1).toString();
			var hours:String = (dateAndTime.hoursUTC).toString().length < 2 ? "0" + (dateAndTime.hoursUTC).toString() : dateAndTime.hoursUTC.toString();
			var minutes:String = (dateAndTime.minutesUTC).toString().length < 2 ? "0" + (dateAndTime.minutesUTC).toString() : dateAndTime.minutesUTC.toString();
			var seconds:String = (dateAndTime.secondsUTC).toString().length < 2 ? "0" + (dateAndTime.secondsUTC).toString() : dateAndTime.secondsUTC.toString();
			var milliseconds:String = (dateAndTime.millisecondsUTC).toString().length < 3 ? ((dateAndTime.secondsUTC).toString().length < 2 ? "00" + (dateAndTime.millisecondsUTC).toString() : "0" + (dateAndTime.millisecondsUTC).toString()) : (dateAndTime.millisecondsUTC).toString() ;
			var day:String = (dateAndTime.dateUTC).toString().length < 2 ? "0" + (dateAndTime.dateUTC).toString() : dateAndTime.dateUTC.toString();
			var returnValue:String =  dateAndTime.fullYearUTC + "-" + month + "-" + day + "T" + hours + ":" + minutes + ":" + seconds + "."  + milliseconds + "Z";
			return returnValue;
		}
		
		/**
		 * return value format yyyyMMdd-hhmmss local time
		 */
		public static function createSiDiaryFileNameFormattedDateAndTime(dateAndTime:Date):String {
			var month:String = (dateAndTime.month + 1).toString().length < 2 ? "0" + (dateAndTime.month + 1).toString() : (dateAndTime.month + 1).toString();
			var hours:String = (dateAndTime.hours).toString().length < 2 ? "0" + (dateAndTime.hours).toString() : dateAndTime.hours.toString();
			var minutes:String = (dateAndTime.minutes).toString().length < 2 ? "0" + (dateAndTime.minutes).toString() : dateAndTime.minutes.toString();
			var day:String = (dateAndTime.date).toString().length < 2 ? "0" + (dateAndTime.date).toString() : dateAndTime.date.toString();
			var returnValue:String =  dateAndTime.fullYear + "_" + month + "_" + day + "-" + hours + "_" + minutes;
			return returnValue;
		}
				
		/**
		 * return value format dd.MM.yyyy;HH:mm local time
		 */
		public static function createSiDiaryEntryFormattedDateAndTime(dateAndTime:Date):String {
			var month:String = (dateAndTime.month + 1).toString().length < 2 ? "0" + (dateAndTime.month + 1).toString() : (dateAndTime.month + 1).toString();
			var hours:String = (dateAndTime.hours).toString().length < 2 ? "0" + (dateAndTime.hours).toString() : dateAndTime.hours.toString();
			var minutes:String = (dateAndTime.minutes).toString().length < 2 ? "0" + (dateAndTime.minutes).toString() : dateAndTime.minutes.toString();
			var seconds:String = (dateAndTime.seconds).toString().length < 2 ? "0" + (dateAndTime.seconds).toString() : dateAndTime.seconds.toString();
			var milliseconds:String = (dateAndTime.milliseconds).toString().length < 3 ? ((dateAndTime.seconds).toString().length < 2 ? "00" + (dateAndTime.milliseconds).toString() : "0" + (dateAndTime.milliseconds).toString()) : (dateAndTime.milliseconds).toString() ;
			var day:String = (dateAndTime.date).toString().length < 2 ? "0" + (dateAndTime.date).toString() : dateAndTime.date.toString();
			var returnValue:String =  day + "." + month + "." + dateAndTime.fullYear + ";" + hours + ":" + minutes;
			return returnValue;
		}
		
		/**
		 * returns a new Date object<br>
		 * use this when dtDate has been created with local time in ms, eg new Date(0) is 00:00 1970... local time, ie locally this could be UTC time -1<br>
		 * in that case returnvalue will be the exact UTC time
		 */
		public static function convertToUTC(dtDate:Date):Date{
			var returnValue:Date = new Date();
			returnValue.setTime(dtDate.getTime() + (dtDate.getTimezoneOffset() * 60000))
			return returnValue;
		}
		
		/**
		 * the opposite of convertToUTC
		 */
		public static function convertFromUTC(dtDate:Date):Date{
			var returnValue:Date = new Date();
			returnValue.setTime(dtDate.getTime() - (dtDate.getTimezoneOffset() * 60000))
			return returnValue;
		}
		
		/**
		 * Example format 2017-12-23T17:59:10.330+0100<br><br>
		 * or 2018-06-21T21:25:28.000Z<br>
		 */
		public static function parseDateTimeString(dateTime:String):Date {
			
			var date:String = dateTime.split("T")[0];
			var time:String = dateTime.split("T")[1];
						
			var year:Number = date.split("-")[0];
			var month:Number = date.split("-")[1];
			var day:Number = date.split("-")[2];
						
			var hour:Number = time.split(":")[0];
			var minute:Number = time.split(":")[1];
			var second:Number = (time.split(":")[2] as String).split(".")[0];
			var millisecondsecond:Number = (time.split(":")[2] as String).split(".")[1].substr(0,3);

			if (dateTime.indexOf("Z") > -1) {
				return new Date(Date.parse(year + "/" + month + "/" + day + "/" + " " + hour + ":" + minute + ":" + second + " GMT-0000"));
			} else {
				return new Date(year,month - 1,day,hour,minute,second,millisecondsecond);
			}
		}
	}
}