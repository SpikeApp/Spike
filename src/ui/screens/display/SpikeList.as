package ui.screens.display
{
	import flash.display.StageOrientation;
	
	import feathers.controls.List;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.events.FeathersEventType;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import starling.core.Starling;
	import starling.events.Event;
	import starling.events.ResizeEvent;
	
	import utils.Constants;
	import utils.DeviceInfo;
	
	public class SpikeList extends List
	{
		protected var noRightPadding:Boolean = false;
		
		public function SpikeList(removeRightPadding:Boolean = false)
		{
			super();
			
			noRightPadding = removeRightPadding;
			setupEventHandlers();
		}
		
		/**
		 * Functionality
		 */
		private function setupEventHandlers():void
		{
			Starling.current.stage.addEventListener(starling.events.Event.RESIZE, onStarlingResize);
			addEventListener(FeathersEventType.CREATION_COMPLETE, onCreationComplete);
		}
		
		protected function setupRenderFactory():void
		{
			/* List Item Renderer */
			itemRendererFactory = function():IListItemRenderer 
			{
				const item:DefaultListItemRenderer = new DefaultListItemRenderer();
				item.labelField = "label";
				item.accessoryField = "accessory";
				item.iconSourceField = "icon";
				item.accessoryLabelProperties.wordWrap = true;
				item.defaultLabelProperties.wordWrap = true;
				item.paddingTop = item.paddingBottom = 10;
				
				if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr && !Constants.isPortrait)
				{
					if (Constants.currentOrientation == StageOrientation.ROTATED_RIGHT)
					{
						item.paddingLeft = 30;
						if (noRightPadding) item.paddingRight = 0;
					}
					else if (Constants.currentOrientation == StageOrientation.ROTATED_LEFT)
						item.paddingRight = 30;
				}
				else
					if (noRightPadding) item.paddingRight = 0;
				
				return item;
			};
		}
		
		/**
		 * Event Listeners
		 */
		protected function onStarlingResize(event:ResizeEvent):void 
		{
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
			setupRenderFactory();
		}
		
		protected function onCreationComplete(e:Event):void
		{
			onStarlingResize(null);
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			Starling.current.stage.removeEventListener(starling.events.Event.RESIZE, onStarlingResize);
			removeEventListener(FeathersEventType.CREATION_COMPLETE, onCreationComplete);
			
			super.dispose();
		}
	}
}