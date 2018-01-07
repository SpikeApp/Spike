package ui.screens.data
{
	import databaseclasses.AlertType;

	public class AlertNavigatorData 
	{		
		private static var instance:AlertNavigatorData;
		
		private var _alertData:AlertType
		
		public static function getInstance():AlertNavigatorData 
		{
			if (instance == null) 
			{
				instance = new AlertNavigatorData(new SingletonBlocker());
			}
			
			return instance;
		}

		public function AlertNavigatorData(key:SingletonBlocker):void 
		{
			if (key == null) 
			{
				throw new Error("Error: Instantiation failed: Use AlertNavigatorData.getInstance() instead of new.");
			}
		}
		
		/**
		 * Getters & Setters
		 */
		public function get alertData():AlertType
		{
			return _alertData;
		}
		
		public function set alertData(value:AlertType):void
		{
			_alertData = value;
		}
	}
}

// Helpers
internal class SingletonBlocker {}