package ui.screens.display.settings.treatments
{
	import database.CommonSettings;
	
	import feathers.controls.PickerList;
	import feathers.controls.popups.DropDownPopUpContentManager;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.data.ArrayCollection;
	import feathers.layout.VerticalLayout;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import starling.events.Event;
	import starling.events.ResizeEvent;
	
	import treatments.ProfileManager;
	import treatments.TreatmentsManager;
	
	import ui.screens.display.LayoutFactory;
	import ui.screens.display.SpikeList;
	
	import utils.Constants;
	
	[ResourceBundle("profilesettingsscreen")]
	[ResourceBundle("globaltranslations")]
	
	public class UserTypeSettingsList extends SpikeList 
	{
		/* Display Objects */
		private var userTypePicker:PickerList;
		
		/* Properties */
		private var userTypeValue:String;
		
		public function UserTypeSettingsList()
		{
			super(true);
			
			setupProperties();
			setupInitialContent();	
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
		
		private function setupInitialContent():void
		{
			/* Get Values From Database */
			userTypeValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_USER_TYPE_PUMP_OR_MDI);
		}
		
		private function setupContent():void
		{	
			//User Type
			userTypePicker = LayoutFactory.createPickerList();
			
			var userTypeList:ArrayCollection = new ArrayCollection();
			userTypeList.push( { label: ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','multiple_daily_injections_aka_pen_user_label'), id: "mdi" } );
			userTypeList.push( { label: ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','pump_user_label'), id: "pump" } );
			
			userTypePicker.popUpContentManager = new DropDownPopUpContentManager();
			userTypePicker.dataProvider = userTypeList;
			
			if (userTypeValue == "mdi")
				userTypePicker.selectedIndex = 0;
			else if (userTypeValue == "pump")
				userTypePicker.selectedIndex = 1;
				
			userTypePicker.itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "label";
				return itemRenderer;
			}
			
			userTypePicker.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Set screen content
			refreshContent();
		}
		
		private function refreshContent():void
		{
			var data:Array = [];
			data.push( { label: ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','pump_or_pen_user_mode'), accessory: userTypePicker } );
			dataProvider = new ArrayCollection(data);
		}
		
		/**
		 * Event Listeners
		 */
		private function onSettingsChanged(e:Event):void
		{
			userTypeValue = userTypePicker.selectedItem.id;
			
			TreatmentsManager.clearAllBasals();
			ProfileManager.clearAllBasalRates();
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_USER_TYPE_PUMP_OR_MDI) != userTypeValue)
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_USER_TYPE_PUMP_OR_MDI, userTypeValue);
		}
		
		override protected function onStarlingResize(event:ResizeEvent):void 
		{
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
			
			setupRenderFactory();
		}
		
		/**
		 * Utility
		 */	
		override protected function draw():void
		{
			if ((layout as VerticalLayout) != null)
				(layout as VerticalLayout).hasVariableItemDimensions = true;
			
			super.draw();
		}
		
		override public function dispose():void
		{
			if (userTypePicker != null)
			{
				userTypePicker.removeEventListener(Event.CHANGE, onSettingsChanged);
				userTypePicker.removeFromParent();
				userTypePicker.dispose();
				userTypePicker = null;
			}
			
			super.dispose();
		}
	}
}