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
package model
{
	import flash.errors.IllegalOperationError;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;

	/**
	 * class with data received from transmitter, generic class<br>
	 * There's no relation with database class, just ust for passing transmitter data from one to another<br>
	 * There's no timestamp, nor uniqueid because this is only to be used temporary to pass the data, reflecting exactly what is received from the transmitter<br>µ
	 * <br>
	 * (used http://stackoverflow.com/questions/1538391/as3-abstract-classes to make this class abstract)
	 */
	public class TransmitterData
	{
		public function TransmitterData()
		{
			inspectAbstract();
		}
		
		private function inspectAbstract():void 
		{
			var className : String = getQualifiedClassName(this);
			if (getDefinitionByName(className) == TransmitterData ) 
			{
				throw new ArgumentError(
					getQualifiedClassName(this) + "Class can not be instantiated.");
			}
		}
	}
}