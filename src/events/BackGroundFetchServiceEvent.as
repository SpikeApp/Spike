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
	[Event(name="LogInfo",type="events.BackGroundFetchServiceEvent")]
	[Event(name="LoadRequestResult",type="events.BackGroundFetchServiceEvent")]
	[Event(name="LoadRequestERror",type="events.BackGroundFetchServiceEvent")]
	[Event(name="PerformFetch",type="events.BackGroundFetchServiceEvent")]
	[Event(name="DeviceTokenReceived",type="events.BackGroundFetchServiceEvent")]


	public class BackGroundFetchServiceEvent extends GenericEvent
	{
		/**
		 * load request was successful, data.information contains the result
		 */
		public static const LOAD_REQUEST_RESULT:String = "LoadRequestResult";
		/**
		 * load request was successful, data.information contains the error
		 */
		public static const LOAD_REQUEST_ERROR:String = "LoadRequestERror";
		/**
		 * performFetch received
		 */
		public static const PERFORM_FETCH:String = "PerformFetch";
		/**
		 * ios has sent device token, the token itself is not in the event
		 */
		public static const DEVICE_TOKEN_RECEIVED:String = "DeviceTokenReceived";

		public var data:*;

		public function BackGroundFetchServiceEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}