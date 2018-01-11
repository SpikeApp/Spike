package ui.chart
{
	import feathers.controls.Label;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalAlign;
	
	import starling.display.Quad;
	import starling.display.Shape;
	import starling.display.Sprite;
	
	import ui.screens.display.LayoutFactory;
	
	import utilities.DeviceInfo;
	
	public class PieDistributionSection extends Sprite
	{
		/* Display Objects */
		public var title:Label;
		public var message:Label;
		private var border:Shape;
		private var background:Quad;

		private var titleBackground:Quad;
		
		public function PieDistributionSection(width:Number, height:Number, backgroundColor:uint, fontColor:uint = Number.NaN, borderColor:Number = Number.NaN)
		{
			super();
			
			//Properties
			var topPadding:int = 3;
			var titleFontSize:Number;
			var messageFontSize:Number;
			
			if (DeviceInfo.getDeviceType() == DeviceInfo.IPHONE_2G_3G_3GS_4_4S_ITOUCH_2_3_4)
			{
				titleFontSize = 9;
				messageFontSize = 9;
			}
			else if (DeviceInfo.getDeviceType() == DeviceInfo.IPHONE_5_5S_5C_SE_ITOUCH_5_6)
			{
				titleFontSize = 8;
				messageFontSize = 8;
			}
			else if (DeviceInfo.getDeviceType() == DeviceInfo.IPHONE_6_6S_7_8)
			{
				titleFontSize = 12;
				messageFontSize = 12;
			}
			else if (DeviceInfo.getDeviceType() == DeviceInfo.IPHONE_6PLUS_6SPLUS_7PLUS_8PLUS)
			{
				titleFontSize = 11;
				messageFontSize = 11;
			}
			else if (DeviceInfo.getDeviceType() == DeviceInfo.IPHONE_X)
			{
				titleFontSize = 8.5;
				messageFontSize = 8.5;
			}
			else if (DeviceInfo.getDeviceType() == DeviceInfo.IPAD_1_2_3_4_5_AIR1_2_PRO_97 || DeviceInfo.getDeviceType() == DeviceInfo.IPAD_PRO_105 || DeviceInfo.getDeviceType() == DeviceInfo.IPAD_PRO_129)
			{
				titleFontSize = 14;
				messageFontSize = 14;
			}
			else
			{
				titleFontSize = 11;
				messageFontSize = 11;
			}
			
			//Background
			background = new Quad(width, height, backgroundColor);
			background.name = "background";
			addChild(background);
			
			//Title
			title = LayoutFactory.createLabel("", HorizontalAlign.CENTER, VerticalAlign.TOP, titleFontSize, true, fontColor);
			title.name = "title";
			title.y = topPadding;
			title.width = width;
			title.text = "Title";
			title.validate();
			title.text = "";
			addChild(title);
			
			//Title Background
			titleBackground = new Quad(width, (topPadding * 2) + title.height, 0xEEEEEE);
			titleBackground.alpha = 0.05;
			addChild(titleBackground);
			
			//Message
			var availableVerticalSpace:Number = height - titleBackground.height;
			message = LayoutFactory.createLabel("", HorizontalAlign.CENTER, VerticalAlign.TOP, messageFontSize, false, fontColor);
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
				var borderLineThickness:uint = 1;
				border = new Shape();
				border.graphics.lineStyle(borderLineThickness, borderColor, 1);
				border.graphics.moveTo(0, 0);
				border.graphics.lineTo(width, 0);
				border.graphics.endFill();
				border.y = borderLineThickness / 2;
				
				addChild(border);
			}
		}
		
		override public function dispose():void
		{
			if (title != null)
			{
				title.dispose();
				title = null;
			}
			
			if (message != null)
			{
				message.dispose();
				message = null;
			}
			
			if (border != null)
			{
				border.dispose();
				border = null;
			}
			
			if (background != null)
			{
				background.dispose();
				background = null;
			}
			
			super.dispose();
		}
	}
}