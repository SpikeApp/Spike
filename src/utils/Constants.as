package utils
{
	import flash.display.Stage;
	
	import starling.core.Starling;
	
	public class Constants 
	{
		
		private static var mScaleFactor:Number;
		private static var mStageWidth:int;
		private static var mStageHeight:int;
		private static var _appStage:Stage;
		
		public static const IPAD_WIDTH:int = 512;
		public static const IPAD_HEIGHT:int = 384;
		
		public static function init( stageWidth:int, stageHeight:int, stage:Stage ):void 
		{
			mStageWidth = stageWidth;
			mStageHeight = stageHeight;
			mScaleFactor = Starling.contentScaleFactor;
			_appStage = stage;
		}
		
		public static function get stageWidth():int 
		{
			return mStageWidth;
		}
		
		public static function get stageHeight():int 
		{
			return mStageHeight;
		}
		
		public static function get scaleFactor():int 
		{
			return mScaleFactor;
		}

		public static function get appStage():Stage
		{
			return _appStage;
		}

	}
}