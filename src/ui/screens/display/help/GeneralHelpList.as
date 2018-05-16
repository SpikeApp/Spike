package ui.screens.display.help
{
	import feathers.controls.Label;
	import feathers.controls.List;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.controls.text.HyperlinkTextFieldTextRenderer;
	import feathers.core.ITextRenderer;
	import feathers.data.ArrayCollection;
	import feathers.layout.VerticalLayout;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import starling.core.Starling;
	import starling.events.Event;
	import starling.events.ResizeEvent;
	import starling.utils.SystemUtil;
	
	import utils.Constants;
	
	[ResourceBundle("globaltranslations")]
	[ResourceBundle("helpscreen")]

	public class GeneralHelpList extends List 
	{
		/* Display Objects */
		private var missedReadingsDescriptionLabel:Label;
		
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
			//Missed Readings Description Label
			missedReadingsDescriptionLabel = new Label();
			missedReadingsDescriptionLabel.text = ModelLocator.resourceManagerInstance.getString('helpscreen','missed_readings_ldescription');
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
			
			//Define Notifications Settings Data
			dataProvider = new ArrayCollection(
				[
					{ label: ModelLocator.resourceManagerInstance.getString('helpscreen','missed_readings_label') },
					{ label: "", accessory: missedReadingsDescriptionLabel}
				]);
			
			//Set Item Renderer
			itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "label";
				itemRenderer.accessoryField = "accessory";
				return itemRenderer;
			};
			
			(layout as VerticalLayout).hasVariableItemDimensions = true;
		}
		
		/**
		 * Event Handlers
		 */
		
		private function onStarlingResize(event:ResizeEvent):void 
		{
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
			SystemUtil.executeWhenApplicationIsActive( setupContent );
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			Starling.current.stage.removeEventListener(starling.events.Event.RESIZE, onStarlingResize);
			
			if (missedReadingsDescriptionLabel != null)
			{
				missedReadingsDescriptionLabel.dispose();
				missedReadingsDescriptionLabel = null;
			}
			
			super.dispose();
		}
	}
}