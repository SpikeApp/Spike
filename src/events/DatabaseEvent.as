/**
 Copyright (C) 2013  hippoandfriends
 
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
package events
{
	[Event(name="ResultEvent",type="events.DatabaseEvent")]
	[Event(name="ErrorEvent",type="events.DatabaseEvent")]
	[Event(name="LoggingInsertedEvent",type="events.DatabaseEvent")]
	[Event(name="LoggingInsertionFailedEvent",type="events.DatabaseEvent")]
	[Event(name="DatabaseInitFinishedEvent",type="events.DatabaseEvent")]
	[Event(name="BGReadingRetrievedEvent",type="events.DatabaseEvent")]
	[Event(name="LogRetrievedEvent",type="events.DatabaseEvent")]
	
	public class DatabaseEvent extends GenericEvent
	{
		public static const RESULT_EVENT:String = "ResultEvent";
		public static const ERROR_EVENT:String = "ErrorEvent";
		public static const LOGGING_INSERTED_EVENT:String = "LoggingInsertedEvent";
		public static const LOGGING_INSERTION_FAILED_EVENT:String = "LoggingInsertionFailedEvent";
		public static const DATABASE_INIT_FINISHED_EVENT:String = "DatabaseInitFinishedEvent";
		public static const BGREADING_RETRIEVAL_EVENT:String = "BGReadingRetrievedEvent";
		public static const LOGRETRIEVED_EVENT:String = "LogRetrievedEvent";
		
		public var data:*;
		
		public function DatabaseEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}