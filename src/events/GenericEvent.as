package events
{
	import flash.events.Event;
	import flash.system.Capabilities;
	
	import spark.formatters.DateTimeFormatter;
	
	import model.ModelLocator;

	public class GenericEvent extends Event
	{
		
		private var _timeStamp:Number;

		public function set timeStamp(value:Number):void
		{
			_timeStamp = value;
		}

		private static var dateFormatter:DateTimeFormatter;

		public function get timeStamp():Number
		{
			return _timeStamp;
		}

		public function getTimeStampAsString(): String {
			if (dateFormatter == null) {
				dateFormatter = new DateTimeFormatter();
				dateFormatter.dateTimePattern = ModelLocator.resourceManagerInstance.getString('general','datetimepatternforlogginginfo');
				dateFormatter.useUTC = false;
				dateFormatter.setStyle("locale",Capabilities.language.substr(0,2));
			}
			
			var date:Date = new Date();
			var milliSeconds:String = date.milliseconds.toString();
			if (milliSeconds.length < 3)
				milliSeconds = "0" + milliSeconds;
			if (milliSeconds.length < 3)
				milliSeconds = "0" + milliSeconds;
			
			var returnValue:String = dateFormatter.format(date) + " " + milliSeconds + " ";
			return returnValue;
		}
		
		public function GenericEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			_timeStamp = (new Date()).valueOf();
		}
	}
}