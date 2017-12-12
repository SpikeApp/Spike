package screens
{
	import flash.system.System;
	
	import display.LayoutFactory;
	
	import feathers.controls.Label;
	import feathers.controls.LayoutGroup;
	import feathers.layout.AnchorLayout;
	import feathers.layout.AnchorLayoutData;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.HorizontalLayout;
	import feathers.layout.VerticalAlign;
	import feathers.layout.VerticalLayout;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import starling.display.DisplayObject;
	
	import ui.AppInterface;
	
	import utils.Constants;
	import utils.DeviceInfo;

	public class FullScreenGlucoseScreen extends BaseSubScreen
	{
		/* Display Objects */
		private var glucoseDisplay:Label;
		private var deltaDisplay:Label;
		private var infoDisplay:Label;
		private var container:LayoutGroup;

		/* Properties */
		private var glucoseFontSize:Number;
		private var infoFontSize:Number;
		private var deltaFontSize:Number;
		private var glucoseValue:String;
		
		public function FullScreenGlucoseScreen() 
		{
			super();
			styleNameList.add( BaseMaterialDeepGreyAmberMobileTheme.THEME_STYLE_NAME_HEADER_WITH_SHADOW );
		}
		
		override protected function initialize():void 
		{
			super.initialize();
			
			/* Set Header Title */
			title = "Fullscreen Display";
			
			/* Set Header Icon */
			icon = getScreenIcon(MaterialDeepGreyAmberMobileThemeIcons.fullscreenTexture);
			iconContainer = new <DisplayObject>[icon];
			headerProperties.rightItems = iconContainer;
			
			/* Create Centered Layout */
			setupLayout();
			
			/* Create Content */
			setupContent();
			
			/* Adjust Menu */
			adjustMainMenu();
		}
		
		private function setupContent():void
		{
			/* Determine Font Sizes */
			glucoseValue = "84.7";
			calculateFontSize();
			
			/* Glucose Display Label */
			glucoseDisplay = LayoutFactory.createLabel(glucoseValue, HorizontalAlign.CENTER, VerticalAlign.MIDDLE, glucoseFontSize, true);
			glucoseDisplay.fontStyles.color = 0x00ff00;
			container.addChild(glucoseDisplay);
			
			/* Info Display Layout */
			var infoLayoutGroup:LayoutGroup = new LayoutGroup();
			infoLayoutGroup.width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
			var infoLayout:HorizontalLayout = new HorizontalLayout();
			infoLayout.horizontalAlign = HorizontalAlign.CENTER;
			infoLayout.verticalAlign = VerticalAlign.MIDDLE;
			infoLayoutGroup.layout = infoLayout;
			addChild(infoLayoutGroup);
			
			/* Info Display Label */
			infoDisplay = LayoutFactory.createLabel("3 minutes ago, -1.4 mg/dl, ", HorizontalAlign.CENTER, VerticalAlign.MIDDLE, infoFontSize, true);
			infoLayoutGroup.addChild(infoDisplay);
			
			/* Delta Display Label */
			deltaDisplay = LayoutFactory.createLabel("\u2192", HorizontalAlign.CENTER, VerticalAlign.MIDDLE, deltaFontSize, false);
			infoLayoutGroup.addChild(deltaDisplay);
		}
		
		private function setupLayout():void
		{
			/* Parent Class Layout */
			layout = new AnchorLayout(); 
			
			/* Create Display Object's Container and Corresponding Vertical Layout and Centered LayoutData */
			container = new LayoutGroup();
			var containerLayout:VerticalLayout = new VerticalLayout();
			containerLayout.gap = -50;
			containerLayout.horizontalAlign = HorizontalAlign.CENTER;
			containerLayout.verticalAlign = VerticalAlign.MIDDLE;
			container.layout = containerLayout;
			var containerLayoutData:AnchorLayoutData = new AnchorLayoutData();
			containerLayoutData.horizontalCenter = 0;
			containerLayoutData.verticalCenter = 0;
			container.layoutData = containerLayoutData;
			this.addChild( container );
		}
		
		private function adjustMainMenu():void
		{
			AppInterface.instance.menu.selectedIndex = -1;
		}
		
		private function calculateFontSize ():void
		{
			var deviceType:String = DeviceInfo.getDeviceType();

			if(deviceType == DeviceInfo.IPHONE_4_4S || deviceType == DeviceInfo.IPHONE_5_5S_5C_SE)
			{
				if(glucoseValue.length == 2) glucoseFontSize = 260;	
				else if(glucoseValue.length == 3) glucoseFontSize = 175;
				else if(glucoseValue.length == 4) glucoseFontSize = 150;
				else if(glucoseValue.length == 5) glucoseFontSize = 120;
				
				infoFontSize = 14;
				deltaFontSize = 28;
			}
			else if(deviceType == DeviceInfo.IPHONE_6_6S_7_8)
			{
				if(glucoseValue.length == 2) glucoseFontSize = 310;	
				else if(glucoseValue.length == 3) glucoseFontSize = 210;
				else if(glucoseValue.length == 4) glucoseFontSize = 175;
				else if(glucoseValue.length == 5) glucoseFontSize = 140;
				
				infoFontSize = 16;
				deltaFontSize = 32;
			}
			else if(deviceType == DeviceInfo.IPHONE_6PLUS_6SPLUS_7PLUS_8PLUS)
			{
				if(glucoseValue.length == 2) glucoseFontSize = 300;	
				else if(glucoseValue.length == 3) glucoseFontSize = 200;
				else if(glucoseValue.length == 4) glucoseFontSize = 170;
				else if(glucoseValue.length == 5) glucoseFontSize = 135;
				
				infoFontSize = 16;
				deltaFontSize = 32;
			}
			else if(deviceType == DeviceInfo.IPHONE_X || deviceType == DeviceInfo.TABLET)
			{
				if(glucoseValue.length == 2) glucoseFontSize = 230;	
				else if(glucoseValue.length == 3) glucoseFontSize = 155;
				else if(glucoseValue.length == 4) glucoseFontSize = 135;
				else if(glucoseValue.length == 5) glucoseFontSize = 105;
				
				infoFontSize = 14;
				deltaFontSize = 28;
			}
		}
		
		override protected function draw():void 
		{
			super.draw();
			if(deltaDisplay.text == "\u2197") deltaDisplay.y = -4;
			else deltaDisplay.y = -1;
			icon.x = Constants.stageWidth - icon.width - BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding;
		}
		
		override public function dispose():void
		{
			if(glucoseDisplay != null)
			{
				glucoseDisplay.dispose();
				glucoseDisplay = null;
			}
			if(deltaDisplay != null)
			{
				deltaDisplay.dispose();
				deltaDisplay = null;
			}
			if(infoDisplay != null)
			{
				infoDisplay.dispose();
				infoDisplay = null;
			}
			if(container != null)
			{
				container.dispose();
				container = null;
			}
			
			System.pauseForGCIfCollectionImminent(0);
			
			super.dispose();
		}
	}
}