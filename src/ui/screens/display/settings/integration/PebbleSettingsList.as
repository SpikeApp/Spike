package ui.screens.display.settings.integration
{	
	import flash.display.StageOrientation;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	
	import database.CGMBlueToothDevice;
	import database.CommonSettings;
	
	import feathers.controls.Button;
	import feathers.controls.GroupedList;
	import feathers.controls.Label;
	import feathers.controls.renderers.DefaultGroupedListHeaderOrFooterRenderer;
	import feathers.controls.renderers.DefaultGroupedListItemRenderer;
	import feathers.controls.renderers.IGroupedListHeaderRenderer;
	import feathers.controls.renderers.IGroupedListItemRenderer;
	import feathers.data.HierarchicalCollection;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalAlign;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import starling.core.Starling;
	import starling.events.Event;
	import starling.events.ResizeEvent;
	
	import ui.screens.display.LayoutFactory;
	
	import utils.Constants;
	import utils.DeviceInfo;
	
	[ResourceBundle("pebblesettingsscreen")]
	[ResourceBundle("treatments")]

	public class PebbleSettingsList extends GroupedList 
	{
		/* Display Objects */
		private var carePortal53Button:Button;
		private var carePortal54Button:Button;
		private var pinItButton:Button;
		private var instructionsLabel:Label;
		
		public function PebbleSettingsList()
		{
			super();
			
			setupProperties();
			setupEventListeners();
			setupContent();
		}
		
		/**
		 * Functionality
		 */
		private function setupProperties():void
		{
			/* Set Properties */
			clipContent = false;
			isSelectable = false;
			autoHideBackground = true;
			hasElasticEdges = false;
			paddingBottom = 5;
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
		}
		
		private function setupEventListeners():void
		{
			Starling.current.stage.addEventListener(starling.events.Event.RESIZE, onStarlingResize);
		}
		
		private function setupContent():void
		{
			//Treatments
			pinItButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString("pebblesettingsscreen","get_pebble_app"));
			pinItButton.addEventListener(Event.TRIGGERED, onPinitTriggered);
			
			carePortal53Button = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString("pebblesettingsscreen","get_pebble_app"));
			carePortal53Button.addEventListener(Event.TRIGGERED, onCarePortal53Triggered);
			
			carePortal54Button = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString("pebblesettingsscreen","get_pebble_app"));
			carePortal54Button.addEventListener(Event.TRIGGERED, onCarePortal54Triggered);
			
			instructionsLabel = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString("pebblesettingsscreen","pebble_instructions_body"), HorizontalAlign.JUSTIFY, VerticalAlign.TOP);
			instructionsLabel.wordWrap = true;
			instructionsLabel.width = width - 20;
			if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr && !Constants.isPortrait)
			{
				instructionsLabel.width -= 20;
			}
			
			refreshContent();
		}
		
		private function refreshContent():void
		{
			var screenDataContent:Array = [];
			
			//Treatments
			if ((CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_ENABLED) == "true" && (!CGMBlueToothDevice.isFollower() || (CGMBlueToothDevice.isFollower() && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_URL) != "" && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_API_SECRET) != "" && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FOLLOWER_MODE) == "Nightscout")))) 
			{
				var treatmentsSection:Object = {};
				treatmentsSection.header = { label: ModelLocator.resourceManagerInstance.getString("treatments","treatments_screen_title") };
				
				var treatmentsSectionChildren:Array = [];
				treatmentsSectionChildren.push( { label: "PinIt", accessory: pinItButton } );
				treatmentsSectionChildren.push( { label: "CGM CarePortal 5.3", accessory: carePortal53Button } );
				treatmentsSectionChildren.push( { label: "CGM CarePortal 5.4", accessory: carePortal54Button } );
				
				treatmentsSection.children = treatmentsSectionChildren;
				screenDataContent.push(treatmentsSection);
			}
			else
			{
				var errorSection:Object = {};
				errorSection.header = { label: ModelLocator.resourceManagerInstance.getString("treatments","treatments_screen_title") };
				
				var errorSectionChildren:Array = [];
				errorSectionChildren.push( { label: "You don't have enough privileges to add treatments to Spike." } );
				
				errorSection.children = treatmentsSectionChildren;
				screenDataContent.push(errorSection);
			}
			
			//Instructions
			var instructionsSection:Object = {};
			instructionsSection.header = { label: ModelLocator.resourceManagerInstance.getString("pebblesettingsscreen","pebble_instructions_title") };
			
			var instructionsSectionChildren:Array = [];
			instructionsSectionChildren.push( { label: "", accessory: instructionsLabel } );
			
			instructionsSection.children = instructionsSectionChildren;
			screenDataContent.push(instructionsSection);
			
			dataProvider = new HierarchicalCollection(screenDataContent);
			setupRenderFactory();
		}
		
		private function setupRenderFactory():void
		{
			itemRendererFactory = function():IGroupedListItemRenderer
			{
				var itemRenderer:DefaultGroupedListItemRenderer = new DefaultGroupedListItemRenderer();
				itemRenderer.labelField = "label";
				itemRenderer.iconSourceField = "accessory";
				itemRenderer.paddingLeft = -5;
				itemRenderer.paddingTop = itemRenderer.paddingBottom = 10;
				itemRenderer.accessoryLabelProperties.wordWrap = true;
				itemRenderer.defaultLabelProperties.wordWrap = true;
				
				if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr && !Constants.isPortrait)
				{
					if (Constants.currentOrientation == StageOrientation.ROTATED_RIGHT)
					{
						itemRenderer.paddingLeft = 25;
					}
					else if (Constants.currentOrientation == StageOrientation.ROTATED_LEFT)
					{
						itemRenderer.paddingRight = 30;
					}
				}
				
				return itemRenderer;
			};
			
			headerRendererFactory = function():IGroupedListHeaderRenderer
			{
				var headerRenderer:DefaultGroupedListHeaderOrFooterRenderer = new DefaultGroupedListHeaderOrFooterRenderer();
				headerRenderer.contentLabelField = "label";
				
				if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr && !Constants.isPortrait)
				{
					if (Constants.currentOrientation == StageOrientation.ROTATED_RIGHT)
					{
						headerRenderer.paddingLeft = 30;
					}
				}
				
				return headerRenderer;
			};
		}
		
		/**
		 * Event Listeners
		 */
		private function onPinitTriggered(e:Event):void
		{
			navigateToURL(new URLRequest("https://apps.rebble.io/en_US/application/571c0848c2ab00c513000025"));
		}
		
		private function onCarePortal53Triggered(e:Event):void
		{
			navigateToURL(new URLRequest("https://apps.rebble.io/en_US/application/568fb97705f633b362000045"));
		}
		
		private function onCarePortal54Triggered(e:Event):void
		{
			navigateToURL(new URLRequest("https://apps.rebble.io/en_US/application/57472250ab434df47b00000a"));
		}
		
		protected function onStarlingResize(event:ResizeEvent):void 
		{
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
			
			if (instructionsLabel != null)
			{
				instructionsLabel.width = width - 20;
				if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr && !Constants.isPortrait)
				{
					instructionsLabel.width -= 20;
				}
			}
			
			setupRenderFactory();
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			Starling.current.stage.removeEventListener(starling.events.Event.RESIZE, onStarlingResize);
			
			if (pinItButton != null)
			{
				pinItButton.removeEventListener(Event.TRIGGERED, onPinitTriggered);
				pinItButton.removeFromParent();
				pinItButton.dispose();
				pinItButton = null;
			}
			
			if (carePortal53Button != null)
			{
				carePortal53Button.removeEventListener(Event.TRIGGERED, onCarePortal53Triggered);
				carePortal53Button.removeFromParent();
				carePortal53Button.dispose();
				carePortal53Button = null;
			}
			
			if (carePortal54Button != null)
			{
				carePortal54Button.removeEventListener(Event.TRIGGERED, onCarePortal54Triggered);
				carePortal54Button.removeFromParent();
				carePortal54Button.dispose();
				carePortal54Button = null;
			}
			
			super.dispose();
		}
	}
}