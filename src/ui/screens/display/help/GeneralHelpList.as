package ui.screens.display.help
{
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	
	import database.CGMBlueToothDevice;
	
	import feathers.controls.Button;
	import feathers.controls.Label;
	import feathers.controls.text.HyperlinkTextFieldTextRenderer;
	import feathers.core.ITextRenderer;
	import feathers.data.ArrayCollection;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalAlign;
	import feathers.layout.VerticalLayout;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import starling.core.Starling;
	import starling.events.Event;
	import starling.events.ResizeEvent;
	import starling.utils.SystemUtil;
	
	import ui.screens.display.LayoutFactory;
	import ui.screens.display.SpikeList;
	
	import utils.Constants;
	import utils.DeviceInfo;
	
	[ResourceBundle("globaltranslations")]
	[ResourceBundle("helpscreen")]

	public class GeneralHelpList extends SpikeList 
	{
		/* Display Objects */
		private var missedReadingsDescriptionLabel:Label;
		private var wikiButton:Button;
		private var missedReadingsTitleLabel:Label;
		
		public function GeneralHelpList()
		{
			super();
		}
		
		override protected function initialize():void 
		{
			super.initialize();
			
			Starling.current.stage.addEventListener(starling.events.Event.RESIZE, onStarlingResize);
			
			setupProperties();
			setupContent();
		}
		
		/**
		 * Functionality
		 */
		private function setupProperties():void
		{
			//Set Properties
			clipContent = false;
			isSelectable = false;
			autoHideBackground = true;
			hasElasticEdges = false;
			paddingBottom = 5;
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
		}
		
		private function setupContent():void
		{	
			//Wiki Button
			wikiButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('helpscreen','wiki_button_label'));
			wikiButton.addEventListener(starling.events.Event.TRIGGERED, onWikiPressed);
			
			//Missed Readings Title Label
			missedReadingsTitleLabel = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('helpscreen','missed_readings_label'), HorizontalAlign.CENTER, VerticalAlign.TOP, 14, true);
			missedReadingsTitleLabel.width = width - 20;
			
			//Missed Readings Description Label
			missedReadingsDescriptionLabel = new Label();
			missedReadingsDescriptionLabel.text = !CGMBlueToothDevice.isFollower() ? ModelLocator.resourceManagerInstance.getString('helpscreen','missed_readings_description') : ModelLocator.resourceManagerInstance.getString('helpscreen','missed_readings_description_follower');
			missedReadingsDescriptionLabel.width = width - 20;
			missedReadingsDescriptionLabel.wordWrap = true;
			missedReadingsDescriptionLabel.paddingTop = 10;
			missedReadingsDescriptionLabel.isQuickHitAreaEnabled = false;
			missedReadingsDescriptionLabel.textRendererFactory = function():ITextRenderer 
			{
				var textRenderer:HyperlinkTextFieldTextRenderer = new HyperlinkTextFieldTextRenderer();
				textRenderer.wordWrap = true;
				textRenderer.isHTML = true;
				textRenderer.pixelSnapping = true;
				
				return textRenderer;
			};
			
			if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr && !Constants.isPortrait)
			{
				if (missedReadingsDescriptionLabel != null)
					missedReadingsDescriptionLabel.width = width - 40;
			}
			else if (missedReadingsDescriptionLabel != null)
				missedReadingsDescriptionLabel.width = width - 20;
			
			//Define Notifications Settings Data
			dataProvider = new ArrayCollection(
			[
				{ label: ModelLocator.resourceManagerInstance.getString('helpscreen','general_help_label'), accessory: wikiButton },
				{ label: "", accessory: missedReadingsTitleLabel },
				{ label: "", accessory: missedReadingsDescriptionLabel }
			]);
			
			(layout as VerticalLayout).hasVariableItemDimensions = true;
		}
		
		/**
		 * Event Handlers
		 */
		private function onWikiPressed(e:Event):void
		{
			navigateToURL(new URLRequest("https://github.com/SpikeApp/Spike/wiki"));
		}
		
		override protected function onStarlingResize(event:ResizeEvent):void 
		{
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
			setupRenderFactory();
			SystemUtil.executeWhenApplicationIsActive( setupContent );
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			Starling.current.stage.removeEventListener(starling.events.Event.RESIZE, onStarlingResize);
			
			if (wikiButton != null)
			{
				wikiButton.removeEventListener(starling.events.Event.TRIGGERED, onWikiPressed);
				wikiButton.removeFromParent();
				wikiButton.dispose();
				wikiButton = null;
			}
			
			if (missedReadingsTitleLabel != null)
			{
				missedReadingsTitleLabel.removeFromParent();
				missedReadingsTitleLabel.dispose();
				missedReadingsTitleLabel = null;
			}
			
			if (missedReadingsDescriptionLabel != null)
			{
				missedReadingsDescriptionLabel.removeFromParent();
				missedReadingsDescriptionLabel.dispose();
				missedReadingsDescriptionLabel = null;
			}
			
			super.dispose();
		}
	}
}