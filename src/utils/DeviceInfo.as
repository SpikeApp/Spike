package utils
{
	import flash.system.Capabilities;
	
	import database.CommonSettings;
	
	import feathers.system.DeviceCapabilities;

	public class DeviceInfo
	{
		/* Constants */
		public static const IPHONE_2G_3G_3GS_4_4S_ITOUCH_2_3_4:String = "iPhone2G_3G_3GS_iTouch_2_3";
		public static const IPHONE_5_5S_5C_SE_ITOUCH_5_6:String = "iPhone5_5S_5C_SE_iTouch5_6";
		public static const IPHONE_6_6S_7_8:String = "iPhone6_6S_7_8";
		public static const IPHONE_6PLUS_6SPLUS_7PLUS_8PLUS:String = "iPhone6P_6SP_7P_8P";
		public static const IPHONE_X_Xs_XsMax_Xr:String = "iPhoneX_Xs_XsMax_Xr";
		public static const IPAD_1_2_3_4_5_AIR1_2_PRO_97:String = "iPad1-2_3_4_5_Air1_2_Pro9-7";
		public static const IPAD_PRO_105:String = "iPad_Pro_10-5";
		public static const IPAD_PRO_129:String = "iPad_Pro_12-9";
		public static const IPAD_MINI_1_2_3_4:String = "iPad_Mini_1_2_3_4";
		
		/*Internal Variables */
		private static var deviceType:String = null; 
		
		public function DeviceInfo(){}
		
		public static function getDeviceModel():String
		{
			var deviceModel:String = "Spike";
			
			if(Capabilities.cpuArchitecture == "ARM") 
			{
				var deviceSpecs:String = Capabilities.os;
				
				if (deviceSpecs.indexOf("iPhone1,1") != -1)
				{
					deviceModel = "iPhone 2G";
				}
				else if (deviceSpecs.indexOf("iPhone1,2") != -1)
				{
					deviceModel = "iPhone 3G";
				}
				else if (deviceSpecs.indexOf("iPhone2,1") != -1)
				{
					deviceModel = "iPhone 3GS";
				}
				else if (deviceSpecs.indexOf("iPhone3,1") != -1 || deviceSpecs.indexOf("iPhone3,2") != -1 || deviceSpecs.indexOf("iPhone3,3") != -1)
				{
					deviceModel = "iPhone 4";
				}
				else if (deviceSpecs.indexOf("iPhone4,1") != -1)
				{
					deviceModel = "iPhone 4S";
				}
				else if (deviceSpecs.indexOf("iPhone5,1") != -1 || deviceSpecs.indexOf("iPhone5,2") != -1)
				{
					deviceModel = "iPhone 5";
				}
				else if (deviceSpecs.indexOf("iPhone5,3") != -1 || deviceSpecs.indexOf("iPhone5,4") != -1)
				{
					deviceModel = "iPhone 5C";
				}
				else if (deviceSpecs.indexOf("iPhone6,1") != -1 || deviceSpecs.indexOf("iPhone6,2") != -1)
				{
					deviceModel = "iPhone 5S";
				}
				else if (deviceSpecs.indexOf("iPhone8,4") != -1)
				{
					deviceModel = "iPhone SE";
				}
				else if (deviceSpecs.indexOf("iPhone7,2") != -1)
				{
					deviceModel = "iPhone 6";
				}
				else if (deviceSpecs.indexOf("iPhone8,1") != -1)
				{
					deviceModel = "iPhone 6S";
				}
				else if (deviceSpecs.indexOf("iPhone9,1") != -1 || deviceSpecs.indexOf("iPhone9,3") != -1)
				{
					deviceModel = "iPhone 7";
				}
				else if (deviceSpecs.indexOf("iPhone10,1") != -1 || deviceSpecs.indexOf("iPhone10,4") != -1)
				{
					deviceModel = "iPhone 8";
				}
				else if (deviceSpecs.indexOf("iPhone7,1") != -1)
				{
					deviceModel = "iPhone 6 Plus";
				}
				else if (deviceSpecs.indexOf("iPhone8,2") != -1)
				{
					deviceModel = "iPhone 6S Plus";
				}
				else if (deviceSpecs.indexOf("iPhone9,2") != -1 || deviceSpecs.indexOf("iPhone9,4") != -1)
				{
					deviceModel = "iPhone 7 Plus";
				}
				else if (deviceSpecs.indexOf("iPhone10,2") != -1 || deviceSpecs.indexOf("iPhone10,5") != -1)
				{
					deviceModel = "iPhone 8 Plus";
				}
				else if (deviceSpecs.indexOf("iPhone10,3") != -1 || deviceSpecs.indexOf("iPhone10,6") != -1)
				{
					deviceModel = "iPhone X";
				}
				else if (deviceSpecs.indexOf("iPhone11,2") != -1)
				{
					deviceModel = "iPhone Xs";
				}
				else if (deviceSpecs.indexOf("iPhone11,8") != -1)
				{
					deviceModel = "iPhone Xr";
				}
				else if (deviceSpecs.indexOf("iPhone11,4") != -1 || deviceSpecs.indexOf("iPhone11,6") != -1)
				{
					deviceModel = "iPhone Xs Max";
				}
				else if (deviceSpecs.indexOf("iPod2,1") != -1)
				{
					deviceModel = "iPod Touch 2nd Gen";
				}
				else if (deviceSpecs.indexOf("iPod3,1") != -1)
				{
					deviceModel = "iPod Touch 3rd Gen";
				}
				else if (deviceSpecs.indexOf("iPod4,1") != -1)
				{
					deviceModel = "iPod Touch 4th Gen";
				}
				else if (deviceSpecs.indexOf("iPod5,1") != -1)
				{
					deviceModel = "iPod Touch 5th Gen";
				}
				else if (deviceSpecs.indexOf("iPod7,1") != -1)
				{
					deviceModel = "iPod Touch 6th Gen";
				}
				else if (deviceSpecs.indexOf("iPad1,1") != -1)
				{
					deviceModel = "iPad 1";
				}
				else if (deviceSpecs.indexOf("iPad2,1") != -1 || deviceSpecs.indexOf("iPad2,2") != -1 || deviceSpecs.indexOf("iPad2,3") != -1 || deviceSpecs.indexOf("iPad2,4") != -1)
				{
					deviceModel = "iPad 2";
				}
				else if (deviceSpecs.indexOf("iPad3,1") != -1 || deviceSpecs.indexOf("iPad3,2") != -1 || deviceSpecs.indexOf("iPad3,3") != -1)
				{
					deviceModel = "iPad 3";
				}
				else if (deviceSpecs.indexOf("iPad3,4") != -1 || deviceSpecs.indexOf("iPad3,5") != -1 || deviceSpecs.indexOf("iPad3,6") != -1)
				{
					deviceModel = "iPad 4";
				}
				else if (deviceSpecs.indexOf("iPad4,1") != -1 || deviceSpecs.indexOf("iPad4,2") != -1 || deviceSpecs.indexOf("iPad4,3") != -1)
				{
					deviceModel = "iPad Air 1";
				}
				else if (deviceSpecs.indexOf("iPad5,3") != -1 || deviceSpecs.indexOf("iPad5,4") != -1)
				{
					deviceModel = "iPad Air 2";
				}
				else if (deviceSpecs.indexOf("iPad6,11") != -1 || deviceSpecs.indexOf("iPad6,12") != -1)
				{
					deviceModel = "iPad 9.7-Inch 5th Gen";
				}
				else if (deviceSpecs.indexOf("iPad7,3") != -1 || deviceSpecs.indexOf("iPad7,4") != -1)
				{
					deviceModel = "iPad Pro 10.5-Inch";
				}
				else if (deviceSpecs.indexOf("iPad7,1") != -1 || deviceSpecs.indexOf("iPad7,2") != -1 || deviceSpecs.indexOf("iPad6,7") != -1 || deviceSpecs.indexOf("iPad6,8") != -1)
				{
					deviceModel = "iPad Pro 12.9-Inch";
				}
				else if (deviceSpecs.indexOf("iPad2,5") != -1 || deviceSpecs.indexOf("iPad2,6") != -1 || deviceSpecs.indexOf("iPad2,7") != -1)
				{
					deviceModel = "iPad Mini 1";
				}
				else if (deviceSpecs.indexOf("iPad4,4") != -1 || deviceSpecs.indexOf("iPad4,5") != -1 || deviceSpecs.indexOf("iPad4,6") != -1)
				{
					deviceModel = "iPad Mini 2";
				}
				else if (deviceSpecs.indexOf("iPad4,7") != -1 || deviceSpecs.indexOf("iPad4,8") != -1 || deviceSpecs.indexOf("iPad4,9") != -1)
				{
					deviceModel = "iPad Mini 3";
				}
				else if (deviceSpecs.indexOf("iPad5,1") != -1 || deviceSpecs.indexOf("iPad5,2") != -1)
				{
					deviceModel = "iPad Mini 4";
				}
				else
					deviceModel = "iPhone X?";
			}
			
			return deviceModel;
		}
		
		public static function getDeviceType():String
		{
			if (deviceType == null)
			{
				if(Capabilities.cpuArchitecture == "ARM") 
				{
					var deviceSpecs:String = Capabilities.os;
					
					if (deviceSpecs.indexOf("iPhone1,1") != -1 || deviceSpecs.indexOf("iPhone1,2") != -1 || deviceSpecs.indexOf("iPhone2,1") != -1 || deviceSpecs.indexOf("iPod3,1") != -1 || deviceSpecs.indexOf("iPod2,1") != -1 || deviceSpecs.indexOf("iPhone3,1") != -1 || deviceSpecs.indexOf("iPhone3,2") != -1 || deviceSpecs.indexOf("iPhone3,3") != -1 || deviceSpecs.indexOf("iPhone4,1") != -1 || deviceSpecs.indexOf("iPod4,1") != -1)
						deviceType = IPHONE_2G_3G_3GS_4_4S_ITOUCH_2_3_4;
					else if (deviceSpecs.indexOf("iPhone5,1") != -1 || deviceSpecs.indexOf("iPhone5,2") != -1 || deviceSpecs.indexOf("iPhone5,3") != -1 || deviceSpecs.indexOf("iPhone5,4") != -1 || deviceSpecs.indexOf("iPhone6,1") != -1 || deviceSpecs.indexOf("iPhone6,2") != -1 || deviceSpecs.indexOf("iPhone8,4") != -1 || deviceSpecs.indexOf("iPod5,1") != -1 || deviceSpecs.indexOf("iPod7,1") != -1)
						deviceType = IPHONE_5_5S_5C_SE_ITOUCH_5_6;
					else if (deviceSpecs.indexOf("iPhone7,2") != -1 || deviceSpecs.indexOf("iPhone8,1") != -1 || deviceSpecs.indexOf("iPhone9,1") != -1 || deviceSpecs.indexOf("iPhone9,3") != -1 || deviceSpecs.indexOf("iPhone10,1") != -1 || deviceSpecs.indexOf("iPhone10,4") != -1)
						deviceType = IPHONE_6_6S_7_8;
					else if (deviceSpecs.indexOf("iPhone7,1") != -1 || deviceSpecs.indexOf("iPhone8,2") != -1 || deviceSpecs.indexOf("iPhone9,2") != -1 || deviceSpecs.indexOf("iPhone9,4") != -1 || deviceSpecs.indexOf("iPhone10,2") != -1 || deviceSpecs.indexOf("iPhone10,5") != -1)
						deviceType = IPHONE_6PLUS_6SPLUS_7PLUS_8PLUS;
					else if (deviceSpecs.indexOf("iPhone10,3") != -1 || deviceSpecs.indexOf("iPhone10,6") != -1 || deviceSpecs.indexOf("iPhone11,2") != -1 || deviceSpecs.indexOf("iPhone11,6") != -1 || deviceSpecs.indexOf("iPhone11,4") != -1 || deviceSpecs.indexOf("iPhone11,8") != -1)
						deviceType = IPHONE_X_Xs_XsMax_Xr;
					else if (deviceSpecs.indexOf("iPad1,1") != -1 || deviceSpecs.indexOf("iPad2,1") != -1 || deviceSpecs.indexOf("iPad2,2") != -1 || deviceSpecs.indexOf("iPad2,3") != -1 || deviceSpecs.indexOf("iPad2,4") != -1 || deviceSpecs.indexOf("iPad3,1") != -1 || deviceSpecs.indexOf("iPad3,2") != -1 || deviceSpecs.indexOf("iPad3,3") != -1 || deviceSpecs.indexOf("iPad3,4") != -1 || deviceSpecs.indexOf("iPad3,5") != -1 || deviceSpecs.indexOf("iPad3,6") != -1 || deviceSpecs.indexOf("iPad4,1") != -1 || deviceSpecs.indexOf("iPad4,2") != -1 || deviceSpecs.indexOf("iPad4,3") != -1 || deviceSpecs.indexOf("iPad5,3") != -1 || deviceSpecs.indexOf("iPad5,4") != -1 || deviceSpecs.indexOf("iPad6,11") != -1 || deviceSpecs.indexOf("iPad6,12") != -1)
						deviceType = IPAD_1_2_3_4_5_AIR1_2_PRO_97;
					else if (deviceSpecs.indexOf("iPad7,3") != -1 || deviceSpecs.indexOf("iPad7,4") != -1)
						deviceType = IPAD_PRO_105;
					else if (deviceSpecs.indexOf("iPad7,1") != -1 || deviceSpecs.indexOf("iPad7,2") != -1 || deviceSpecs.indexOf("iPad6,7") != -1 || deviceSpecs.indexOf("iPad6,8") != -1)
						deviceType = IPAD_PRO_129;
					else if (deviceSpecs.indexOf("iPad2,5") != -1 || deviceSpecs.indexOf("iPad2,6") != -1 || deviceSpecs.indexOf("iPad2,7") != -1 || deviceSpecs.indexOf("iPad4,4") != -1 || deviceSpecs.indexOf("iPad4,5") != -1 || deviceSpecs.indexOf("iPad4,6") != -1 || deviceSpecs.indexOf("iPad4,7") != -1 || deviceSpecs.indexOf("iPad4,8") != -1 || deviceSpecs.indexOf("iPad4,9") != -1 || deviceSpecs.indexOf("iPad5,1") != -1 || deviceSpecs.indexOf("iPad5,2") != -1)
						deviceType = IPAD_MINI_1_2_3_4;
					else
						deviceType = IPHONE_X_Xs_XsMax_Xr //Default
				}
				else
				{
					var hypotenuse:Number = getHypotenuse();
					
					if (hypotenuse == 3.5)
						deviceType = IPHONE_2G_3G_3GS_4_4S_ITOUCH_2_3_4;
					else if (hypotenuse == 4)
						deviceType = IPHONE_5_5S_5C_SE_ITOUCH_5_6;
					else if (hypotenuse == 4.7)
						deviceType = IPHONE_6_6S_7_8;
					else if (hypotenuse == 5.5)
						deviceType = IPHONE_6PLUS_6SPLUS_7PLUS_8PLUS;
					else if (hypotenuse == 5.9)
						deviceType = IPHONE_X_Xs_XsMax_Xr;
					else if (hypotenuse == 7.9)
						deviceType = IPAD_MINI_1_2_3_4;
					else if (hypotenuse == 9.7)
						deviceType = IPAD_1_2_3_4_5_AIR1_2_PRO_97;
					else if (hypotenuse == 10.5)
						deviceType = IPAD_PRO_105;
					else if (hypotenuse == 12.9)
						deviceType = IPAD_PRO_129;
					else
						deviceType = IPHONE_X_Xs_XsMax_Xr //Default
				}
			}
			
			return deviceType;
		}
		
		private static function getHypotenuse():Number
		{	
			var screenWidthInches:Number = DeviceCapabilities.screenInchesX(Constants.appStage);
			var screenHeightInches:Number = DeviceCapabilities.screenInchesY(Constants.appStage);
			var hypotenuse:Number = Math.sqrt((screenWidthInches * screenWidthInches) + (screenHeightInches * screenHeightInches));
			hypotenuse = (( hypotenuse * 10 + 0.5)  >> 0) / 10;
			
			return hypotenuse;
		}
		
		public static function isDeviceCompatible():Boolean
		{
			var compatibility:Boolean = true;
			var deviceSpecs:String = Capabilities.os;
			
			if (deviceSpecs.indexOf("iPod1,1") != -1 || deviceSpecs.indexOf("iPod2,1") != -1 || deviceSpecs.indexOf("iPod3,1") != -1 || deviceSpecs.indexOf("iPod4,1") != -1 || deviceSpecs.indexOf("iPhone1,1") != -1 || deviceSpecs.indexOf("iPhone1,2") != -1 || deviceSpecs.indexOf("iPhone2,1") != -1 || deviceSpecs.indexOf("iPhone3,1") != -1 || deviceSpecs.indexOf("iPhone3,2") != -1 || deviceSpecs.indexOf("iPhone3,3") != -1 || deviceSpecs.indexOf("iPad1,1") != -1)
				compatibility = false;
			
			return compatibility;
		}
		
		public static function getFontMultipier():Number
		{
			var fontMultiplier:Number;
			var deviceType:String = getDeviceType();
			var dateFormat:String = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_DATE_FORMAT);
			
			if (deviceType == IPHONE_2G_3G_3GS_4_4S_ITOUCH_2_3_4 || deviceType == IPHONE_5_5S_5C_SE_ITOUCH_5_6)
				if (dateFormat == "24H") fontMultiplier = 1;
				else	fontMultiplier = 0.9;
			else if (deviceType == IPHONE_6_6S_7_8)
				if (dateFormat == "24H")	fontMultiplier = 1.15;
				else	fontMultiplier = 1.1;
			else if (deviceType == IPHONE_6PLUS_6SPLUS_7PLUS_8PLUS)
				if (dateFormat == "24H")	fontMultiplier = 1.1;
				else	fontMultiplier = 1.05;
			else if (deviceType == IPHONE_X_Xs_XsMax_Xr)
				if (dateFormat == "24H")	fontMultiplier = 0.85;
				else	fontMultiplier = 0.8;
			else if (deviceType == IPAD_1_2_3_4_5_AIR1_2_PRO_97)
				fontMultiplier = 1.7;
			else if (deviceType == IPAD_PRO_105)
				fontMultiplier = 2;
			else if (deviceType == IPAD_PRO_129)
				fontMultiplier = 2.3;
			else if (deviceType == IPAD_MINI_1_2_3_4)
				fontMultiplier = 1.3;
			else
				fontMultiplier = 1;
			
			
			return fontMultiplier;
		}
		
		public static function getVerticalPaddingMultipier():Number
		{
			var paddingMultiplier:Number;
			var deviceType:String = getDeviceType();
			if (deviceType == IPHONE_2G_3G_3GS_4_4S_ITOUCH_2_3_4)
				paddingMultiplier = 2;
			else if (deviceType == IPHONE_5_5S_5C_SE_ITOUCH_5_6)
				paddingMultiplier = 2.2;
			else if (deviceType == IPHONE_6_6S_7_8)
				paddingMultiplier = 2.5;
			else if (deviceType == IPHONE_6PLUS_6SPLUS_7PLUS_8PLUS || deviceType == IPHONE_X_Xs_XsMax_Xr)
				paddingMultiplier = 2.8;
			else if (deviceType == IPAD_1_2_3_4_5_AIR1_2_PRO_97)
				paddingMultiplier = 3.6;
			else if (deviceType == IPAD_PRO_105 || deviceType == IPAD_PRO_129)
				paddingMultiplier = 4.2;
			else if (deviceType == IPAD_MINI_1_2_3_4 || deviceType == IPHONE_X_Xs_XsMax_Xr)
				paddingMultiplier = 3;
			else
				paddingMultiplier = 2.5;
			
			return paddingMultiplier;
		}
		
		public static function getHorizontalPaddingMultipier():Number
		{
			var paddingMultiplier:Number;
			var deviceType:String = getDeviceType();
			
			if (deviceType == IPHONE_2G_3G_3GS_4_4S_ITOUCH_2_3_4 || deviceType == IPHONE_5_5S_5C_SE_ITOUCH_5_6)
				paddingMultiplier = 1;
			else if (deviceType == IPHONE_6_6S_7_8 || deviceType == IPHONE_6PLUS_6SPLUS_7PLUS_8PLUS || deviceType == IPAD_MINI_1_2_3_4)
				paddingMultiplier = 1.4;
			else if (deviceType == IPHONE_X_Xs_XsMax_Xr)
				paddingMultiplier = 1.2;
			else if (deviceType == IPAD_1_2_3_4_5_AIR1_2_PRO_97 || deviceType == IPAD_PRO_105 || deviceType == IPAD_PRO_129)
				paddingMultiplier = 3;
			else 
				paddingMultiplier = 1.4;
			
			return paddingMultiplier;
		}
		
		public static function getSizeMultipier():Number
		{
			var sizeMultiplier:Number;
			var deviceType:String = getDeviceType();
			if (deviceType == IPHONE_2G_3G_3GS_4_4S_ITOUCH_2_3_4 || deviceType == IPHONE_5_5S_5C_SE_ITOUCH_5_6)
				sizeMultiplier = 0.9;
			else if (deviceType == IPHONE_6_6S_7_8)
				sizeMultiplier = 1.25;
			else if (deviceType == IPHONE_6PLUS_6SPLUS_7PLUS_8PLUS)
				sizeMultiplier = 1.15;
			else if (deviceType == IPHONE_X_Xs_XsMax_Xr)
				sizeMultiplier = 0.8;
			else if (deviceType == IPAD_1_2_3_4_5_AIR1_2_PRO_97)
				sizeMultiplier = 1.3;
			else if (deviceType == IPAD_PRO_105)
				sizeMultiplier = 1.5;
			else if (deviceType == IPAD_PRO_129)
				sizeMultiplier = 1.7;
			else if (deviceType == IPAD_MINI_1_2_3_4)
				sizeMultiplier = 1.15;
			else 
				sizeMultiplier = 1.25;
			
			return sizeMultiplier;
		}
		
		public static function isTablet():Boolean
		{
			var internalHypotenuse:Number = getHypotenuse();
			
			return Constants.deviceModel == IPAD_1_2_3_4_5_AIR1_2_PRO_97 || Constants.deviceModel == IPAD_PRO_105 || Constants.deviceModel == IPAD_PRO_129 || Constants.deviceModel == IPAD_MINI_1_2_3_4 || internalHypotenuse >= 9.7;
		}
		
		public static function isIpad():Boolean
		{
			return Constants.deviceModel == IPAD_1_2_3_4_5_AIR1_2_PRO_97 || Constants.deviceModel == IPAD_PRO_105 || Constants.deviceModel == IPAD_PRO_129 || Constants.deviceModel == IPAD_MINI_1_2_3_4;
		}
		
		public static function isIphone7SE():Boolean
		{
			var isIphone7SEModel:Boolean = false;
			
			if(Capabilities.cpuArchitecture == "ARM") 
			{
				var deviceSpecs:String = Capabilities.os;
				
				if (deviceSpecs.indexOf("iPhone9,1") != -1 || deviceSpecs.indexOf("iPhone9,3") != -1 || deviceSpecs.indexOf("iPhone9,2") != -1 || deviceSpecs.indexOf("iPhone9,4") != -1 || deviceSpecs.indexOf("iPhone8,4") != -1)
					isIphone7SEModel = true;
			}
			
			return isIphone7SEModel;
		}
		
		public static function isSmallScreenDevice():Boolean
		{
			return Constants.deviceModel == IPHONE_2G_3G_3GS_4_4S_ITOUCH_2_3_4 || Constants.deviceModel == IPHONE_5_5S_5C_SE_ITOUCH_5_6;
		}
		
		public static function isPhone():Boolean
		{
			return Constants.deviceModel == IPHONE_2G_3G_3GS_4_4S_ITOUCH_2_3_4 || Constants.deviceModel == IPHONE_5_5S_5C_SE_ITOUCH_5_6 || Constants.deviceModel == IPHONE_6_6S_7_8 || Constants.deviceModel == IPHONE_6PLUS_6SPLUS_7PLUS_8PLUS || Constants.deviceModel == IPHONE_X_Xs_XsMax_Xr;
		}
	}
}