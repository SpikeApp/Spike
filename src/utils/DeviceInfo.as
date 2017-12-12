package utils
{
	import feathers.system.DeviceCapabilities;

	public class DeviceInfo
	{
		public static const IPHONE_4_4S:String = "iPhone4_4S";
		public static const IPHONE_5_5S_5C_SE:String = "iPhone5_5S_5C_SE";
		public static const IPHONE_6_6S_7_8:String = "iPhone6_6S_7_8";
		public static const IPHONE_6PLUS_6SPLUS_7PLUS_8PLUS:String = "iPhone6P_6SP_7P_8P";
		public static const IPHONE_X:String = "iPhoneX";
		public static const TABLET:String = "tablet";
		
		public function DeviceInfo(){}
		
		public static function getDeviceType():String
		{
			var screenInchesWidth:Number = DeviceCapabilities.screenInchesX(Constants.appStage);
			var screenInchesHeight:Number = DeviceCapabilities.screenInchesY(Constants.appStage);
			var hypotenuse:Number = Math.sqrt((screenInchesWidth * screenInchesWidth) + (screenInchesHeight * screenInchesHeight));
			hypotenuse = (( hypotenuse * 10 + 0.5)  >> 0) / 10;
			
			var deviceType:String;
			if (hypotenuse > 5.81 || DeviceCapabilities.isTablet(Constants.appStage))
				deviceType = TABLET;
			else if (hypotenuse >= 5.8)
				deviceType = IPHONE_X;
			else if (hypotenuse >= 5.5)
				deviceType = IPHONE_6PLUS_6SPLUS_7PLUS_8PLUS;
			else if (hypotenuse >= 4.7)
				deviceType = IPHONE_6_6S_7_8;
			else if (hypotenuse >= 4)
				deviceType = IPHONE_5_5S_5C_SE;
			else if (hypotenuse >= 3.5)
				deviceType = IPHONE_4_4S;
			
			return deviceType;
		}
		
		public static function getFontMultipier():Number
		{
			var fontMultiplier:Number;
			var deviceType:String = getDeviceType();
			if (deviceType == IPHONE_4_4S)
				fontMultiplier = 1;
			else if (deviceType == IPHONE_5_5S_5C_SE)
				fontMultiplier = 1.1;
			else if (deviceType == IPHONE_6_6S_7_8)
				fontMultiplier = 1.25;
			else if (deviceType == IPHONE_6PLUS_6SPLUS_7PLUS_8PLUS)
				fontMultiplier = 1.4;
			else if (deviceType == IPHONE_X)
				fontMultiplier = 1.55;
			else if (deviceType == TABLET)
				fontMultiplier = 1.7;
			
			return fontMultiplier;
		}
		
		public static function getVerticalPaddingMultipier():Number
		{
			var paddingMultiplier:Number;
			var deviceType:String = getDeviceType();
			if (deviceType == IPHONE_4_4S)
				paddingMultiplier = 2;
			else if (deviceType == IPHONE_5_5S_5C_SE)
				paddingMultiplier = 2.2;
			else if (deviceType == IPHONE_6_6S_7_8)
				paddingMultiplier = 2.5;
			else if (deviceType == IPHONE_6PLUS_6SPLUS_7PLUS_8PLUS)
				paddingMultiplier = 2.8;
			else if (deviceType == IPHONE_X)
				paddingMultiplier = 3.1;
			else if (deviceType == TABLET)
				paddingMultiplier = 3.4;
			
			return paddingMultiplier;
		}
		
		public static function getHorizontalPaddingMultipier():Number
		{
			var paddingMultiplier:Number;
			var deviceType:String = getDeviceType();
			if (deviceType == IPHONE_4_4S || deviceType == IPHONE_5_5S_5C_SE)
				paddingMultiplier = 1;
			else if (deviceType == IPHONE_6_6S_7_8 || IPHONE_6PLUS_6SPLUS_7PLUS_8PLUS)
				paddingMultiplier = 1.4;
			else if (deviceType == IPHONE_X)
				paddingMultiplier = 1.5;
			else if (deviceType == TABLET)
				paddingMultiplier = 1.5;
			
			return paddingMultiplier;
		}
		
		public static function getSizeMultipier():Number
		{
			var sizeMultiplier:Number;
			var deviceType:String = getDeviceType();
			if (deviceType == IPHONE_4_4S || deviceType == IPHONE_5_5S_5C_SE)
				sizeMultiplier = 1;
			else if (deviceType == IPHONE_6_6S_7_8)
				sizeMultiplier = 1.25;
			else if (deviceType == IPHONE_6PLUS_6SPLUS_7PLUS_8PLUS)
				sizeMultiplier = 1.15;
			else if (deviceType == IPHONE_X)
				sizeMultiplier = 1;
			else if (deviceType == TABLET)
				sizeMultiplier = 1.3;
			
			return sizeMultiplier;
		}
	}
}