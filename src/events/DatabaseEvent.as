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
	import flash.events.Event;

	[Event(name="ResultEvent",type="events.DatabaseEvent")]
	[Event(name="ErrorEvent",type="events.DatabaseEvent")]
	[Event(name="DatabaseInitFinishedEvent",type="events.DatabaseEvent")]
	[Event(name="BGReadingRetrievedEvent",type="events.DatabaseEvent")]
	[Event(name="databaseClosed",type="events.DatabaseEvent")]
	
	public class DatabaseEvent extends Event
	{
		public static const RESULT_EVENT:String = "ResultEvent";
		public static const ERROR_EVENT:String = "ErrorEvent";
		public static const DATABASE_INIT_FINISHED_EVENT:String = "DatabaseInitFinishedEvent";
		public static const BGREADING_RETRIEVAL_EVENT:String = "BGReadingRetrievedEvent";
		public static const DATABASE_CLOSED_EVENT:String = "databaseClosed";
		
		public var data:*;
		
		public function DatabaseEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false, data:* = null)
		{
			super(type, bubbles, cancelable);
			
			this.data = data;
		}
	}
}