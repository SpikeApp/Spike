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
package events
{
	import flash.events.Event;

	[Event(name="BGReadingEvent",type="events.TransmitterServiceEvent")]
	
	/**
	 * used by transmitter service to notify on all kinds of events : information messages, etc.. <br>
	 */
	
	public class TransmitterServiceEvent extends Event
	{
		/**
		 * event to inform that there's a new bgreading available<br>
		 * event is dispatched when bgreading is stored in the Modellocator and also in the databaase.<br>
		 * There's no data attached to it.
		 */
		public static const BGREADING_EVENT:String = "BGReadingEvent";
		
		public var data:*;

		public function TransmitterServiceEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}