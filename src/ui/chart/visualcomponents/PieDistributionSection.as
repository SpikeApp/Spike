package ui.chart.visualcomponents
{
	import feathers.controls.Label;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalAlign;
	
	import starling.display.Quad;
	import starling.display.Sprite;
	
	import ui.screens.display.LayoutFactory;
	import ui.shapes.SpikeLine;
	
	import utils.Constants;
	import utils.DeviceInfo;
	
	public class PieDistributionSection extends Sprite
	{
		/* Display Objects */
		public var title:Label;
		public var message:Label;
		private var border:SpikeLine;
		private var background:Quad;
		private var titleBackground:Quad;
		
		public function PieDistributionSection(width:Number, height:Number, backgroundColor:uint, fontColor:uint = Number.NaN, borderColor:Number = Number.NaN)
		{
			super();
			
			//Properties
			var topPadding:int = 3;
			var titleFontSize:Number;
			var messageFontSize:Number;
			
			if (Constants.deviceModel == DeviceInfo.IPHONE_2G_3G_3GS_4_4S_ITOUCH_2_3_4 || Constants.deviceModel == DeviceInfo.IPHONE_5_5S_5C_SE_ITOUCH_5_6)
			{
				titleFontSize = 9;
				messageFontSize = 9;
			}
			else if (Constants.deviceModel == DeviceInfo.IPHONE_6_6S_7_8)
			{
				titleFontSize = 12;
				messageFontSize = 12;
			}
			else if (Constants.deviceModel == DeviceInfo.IPHONE_6PLUS_6SPLUS_7PLUS_8PLUS || Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr)
			{
				titleFontSize = 11;
				messageFontSize = 11;
			}
			else if (Constants.deviceModel == DeviceInfo.IPAD_MINI_1_2_3_4)
			{
				titleFontSize = 13;
				messageFontSize = 13;
			}
			else if (Constants.deviceModel == DeviceInfo.IPAD_1_2_3_4_5_AIR1_2_PRO_97 || Constants.deviceModel == DeviceInfo.IPAD_PRO_105)
			{
				titleFontSize = 17;
				messageFontSize = 17;
			}
			else if (Constants.deviceModel == DeviceInfo.IPAD_PRO_129)
			{
				titleFontSize = 20;
				messageFontSize = 20;
			}
			else
			{
				titleFontSize = 11;
				messageFontSize = 11;
			}
			
			//Background
			background = new Quad(width, height, backgroundColor);
			background.touchable = false;
			background.name = "background";
			addChild(background);
			
			//Title Background
			titleBackground = new Quad(width, height / 2, 0xEEEEEE);
			titleBackground.touchable = false;
			titleBackground.alpha = 0.05;
			addChild(titleBackground);
			
			//Title
			title = LayoutFactory.createLabel("", HorizontalAlign.CENTER, VerticalAlign.TOP, titleFontSize, true, fontColor);
			title.touchable = false;
			title.name = "title";
			title.text = "Title";
			title.validate();
			title.y = ((height / 2) - title.height) / 2;
			title.width = width;
			title.text = "";
			addChild(title);
			
			//Message
			var availableVerticalSpace:Number = height - titleBackground.height;
			message = LayoutFactory.createLabel("", HorizontalAlign.CENTER, VerticalAlign.TOP, messageFontSize, false, fontColor);
			message.touchable = false;
			message.name = "message";
			message.width = width;
			message.text = "Message";
			message.validate();
			message.text = "";
			message.y = titleBackground.y + titleBackground.height + ((availableVerticalSpace - message.height) / 2);
			addChild(message);
			
			//Border
			if (!isNaN(borderColor))
			{
				border = new SpikeLine();
				border.lineStyle(1, borderColor);
				border.moveTo(0, 0.5);
				border.lineTo(width, 0.5);
				border.touchable = false;
				
				addChild(border);
			}
		}
		
		override public function dispose():void
		{
			if (title != null)
			{
				title.removeFromParent();
				title.dispose();
				title = null;
			}
			
			if (message != null)
			{
				message.removeFromParent();
				message.dispose();
				message = null;
			}
			
			if (border != null)
			{
				border.removeFromParent();
				border.dispose();
				border = null;
			}
			
			if (background != null)
			{
				background.removeFromParent();
				background.dispose();
				background = null;
			}
			
			super.dispose();
		}
	}
}