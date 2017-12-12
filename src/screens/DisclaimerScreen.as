package screens
{
	import display.LayoutFactory;
	
	import feathers.controls.Label;
	import feathers.events.FeathersEventType;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import starling.display.DisplayObject;
	import starling.events.Event;
	
	import ui.AppInterface;
	
	import utils.Constants;

	public class DisclaimerScreen extends BaseSubScreen
	{
		public function DisclaimerScreen() 
		{
			super();
			styleNameList.add( BaseMaterialDeepGreyAmberMobileTheme.THEME_STYLE_NAME_HEADER_WITH_SHADOW );
		}
		
		override protected function initialize():void 
		{
			super.initialize();
			
			/* Set Header Title */
			title = "Disclaimer";
			
			/* Set Header Icon */
			icon = getScreenIcon(MaterialDeepGreyAmberMobileThemeIcons.disclaimerTexture);
			iconContainer = new <DisplayObject>[icon];
			headerProperties.rightItems = iconContainer;
			
			/* Create Content */
			addEventListener(FeathersEventType.CREATION_COMPLETE, setupContent);
			
			/* Adjust Menu */
			adjustMainMenu();
		}
		
		private function setupContent(event:Event):void
		{
			/* License */
			var licenseTitleLabel:Label = LayoutFactory.createSectionLabel("License");
			screenRenderer.addChild(licenseTitleLabel);
			
			var licenseContentLabel:Label = LayoutFactory.createContentLabel( "This program is free software distributed under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version.\n\nSee http://www.gnu.org/licenses/gpl.txt for more details.", this.width - (BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding * 2));
			screenRenderer.addChild(licenseContentLabel);
			
			/* Disclaimer */
			var disclaimerTitleLabel:Label = LayoutFactory.createSectionLabel("Disclaimer");
			screenRenderer.addChild(disclaimerTitleLabel);
			
			var disclaimerContentLabel:Label = LayoutFactory.createContentLabel( "This software must not be used to make medical decisions. It is a research tool only and is provided \"as is\" without warranty of any kind, either expressed or implied, including, but not limited to, the implied warranties of merchantability and fitness for a particular purpose. The entire risk as to the quality and performance of the program is with you. Should the program prove defective, you assume the cost of all necessary servicing, repair or correction.", this.width - (BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding * 2));
			screenRenderer.addChild(disclaimerContentLabel);
			
			/* Notice */
			var noticeTitleLabel:Label = LayoutFactory.createSectionLabel("Important Notice");
			screenRenderer.addChild(noticeTitleLabel);
			
			var noticeContentLabel:Label = LayoutFactory.createContentLabel( "Do NOT use or rely on this software or any associated materials for any medical purpose or decision.\n\nDo NOT rely on this system for any real-time alarms or time critical data.\n\nDo NOT use or rely on this system for treatment decisions or use as a substitute for professional healthcare judgement.\n\nAll software and materials have been provided for informational purposes only as a proof of concept to assist possibilities for further research.\n\nNo claims at all are made about fitness for any purpose and everything is provided \"AS IS\". Any part of the system can fail at any time.\n\nAlways seek the advice of a qualified healthcare professional for any medical questions.\n\nAlways follow your glucose-sensor manufacturers\' instructions when using any equipment; do not discontinue use of accompanying reader or receiver, other than as advised by your doctor.\n\nThis software is not associated with or endorsed by any equipment manufacturer and all trademarks are those of their respective owners.\n\nYour use of this software is entirely at your own risk.\n\nNo charge has been made by the developers for the use of this software.\n\nThis is an open-source project which has been created by volunteers. The source code is published free and open-source for you to inspect and evaluate.\n\nBy using this software and/or website you agree that you are over 18 years of age and have read, understood and agree to all of the above.", this.width - (BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding * 2), true, false);
			screenRenderer.addChild(noticeContentLabel);
			
			/* Acknowledgements */
			var acknowledgmentsTitleLabel:Label = LayoutFactory.createSectionLabel("Acknowledgments");
			screenRenderer.addChild(acknowledgmentsTitleLabel);
			
			var acknowledgmentsContentLabel:Label = LayoutFactory.createContentLabel( "We would like to thank the following people for contributing to this project:\n\nThe xDrip/xDrip+ team from who we ported code to this project.\n\nThe FreshPlanet team who's code served as the base for our BackgroundFetch Native Extension.\n\nMarcel Piestansky who kindly donated his work that served as the base for the app's theme.", this.width - (BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding * 2));
			screenRenderer.addChild(acknowledgmentsContentLabel);
			
			/* Developers */
			var developersTitleLabel:Label = LayoutFactory.createSectionLabel("Developers");
			screenRenderer.addChild(developersTitleLabel);
			
			var developersContentLabel:Label = LayoutFactory.createContentLabel( "Johan Degraeve (@JohanDegraeve)\nMiguel Kennedy (@miguelkennedy)", this.width - (BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding * 2), true, true);
			screenRenderer.addChild(developersContentLabel);
		}
		
		private function adjustMainMenu():void
		{
			AppInterface.instance.menu.selectedIndex = 4;
		}
		
		override protected function draw():void 
		{
			var layoutInvalid:Boolean = isInvalid( INVALIDATION_FLAG_LAYOUT );
			super.draw();
			icon.x = Constants.stageWidth - icon.width - BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding;
		}
	}
}

/*
var acknowledgmentsContentLabel:Label = LayoutFactory.createContentLabel( "", this.width - (BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding * 2), false);
acknowledgmentsContentLabel.textRendererFactory = function():ITextRenderer 
{	
var textFormat:TextFormat = new TextFormat("Roboto", 10, 0xEEEEEE);
textFormat.align = TextFormatAlign.JUSTIFY;
var textRenderer:TextFieldTextRenderer = new TextFieldTextRenderer();
textRenderer.isHTML = true;
textRenderer.textFormat = textFormat;
return textRenderer;
};
acknowledgmentsContentLabel.text = "We would like to thank the following people for contributing to this project:<br><br><ul><li>The xDrip/xDrip+ team from who we ported code to this project.<br></li><li>The FreshPlanet team who's code served as the base for our BackgroundFetch Native Extension.<br></li><li>Marcel Piestansky who kindly donated his work that served as the base for this app's theme.</li></ul>";
*/