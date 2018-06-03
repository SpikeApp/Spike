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