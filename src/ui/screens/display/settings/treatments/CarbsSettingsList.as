package ui.screens.display.settings.treatments
{
	import com.adobe.utils.StringUtil;
	
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	
	import database.CommonSettings;
	
	import feathers.controls.Button;
	import feathers.controls.Label;
	import feathers.controls.LayoutGroup;
	import feathers.controls.NumericStepper;
	import feathers.controls.PickerList;
	import feathers.controls.popups.DropDownPopUpContentManager;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.data.ArrayCollection;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.HorizontalLayout;
	import feathers.layout.VerticalLayout;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import starling.events.Event;
	import starling.events.ResizeEvent;
	
	import treatments.Profile;
	import treatments.ProfileManager;
	
	import ui.screens.display.LayoutFactory;
	import ui.screens.display.SpikeList;
	
	import utils.Constants;
	import utils.DeviceInfo;
	
	[ResourceBundle("profilesettingsscreen")]
	[ResourceBundle("globaltranslations")]
	
	public class CarbsSettingsList extends SpikeList 
	{
		/* Display Objects */
		private var carbAbsorptionRateStepper:NumericStepper;
		private var carbAbsorptionRateDescription:Label;
		private var actionContainer:LayoutGroup;
		private var guide:Button;
		private var fastAbsorptionTime:NumericStepper;
		private var mediumAbsorptionTime:NumericStepper;
		private var slowAbsorptionTime:NumericStepper;
		private var defaultCarbAbsorptionTime:PickerList;
		private var carbAbsorptionTimeDescription:Label;
		
		/* Properties */
		private var userProfiles:Array;
		private var currentProfile:Profile;
		public var needsSave:Boolean;
		private var fastAbsortionTimeValue:Number;
		private var mediumAbsortionTimeValue:Number;
		private var slowAbsortionTimeValue:Number;
		private var defaultAbsortionTimeValue:Number;
		
		public function CarbsSettingsList()
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
			userProfiles = ProfileManager.profilesList;
			currentProfile = userProfiles[0];
			if (currentProfile == null || isNaN(currentProfile.carbsAbsorptionRate))
			{
				ProfileManager.createDefaultProfile();
				userProfiles = ProfileManager.profilesList;
				currentProfile = userProfiles[0];
			}
			
			fastAbsortionTimeValue = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CARB_FAST_ABSORTION_TIME));
			mediumAbsortionTimeValue = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CARB_MEDIUM_ABSORTION_TIME));
			slowAbsortionTimeValue = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CARB_SLOW_ABSORTION_TIME));
			defaultAbsortionTimeValue = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEFAULT_CARB_ABSORTION_TIME));
		}
		
		private function setupContent():void
		{	
			//Carb absorption time
			fastAbsorptionTime = LayoutFactory.createNumericStepper(1, 120, fastAbsortionTimeValue, 1);
			fastAbsorptionTime.addEventListener(Event.CHANGE, onSettingsChanged);
			mediumAbsorptionTime = LayoutFactory.createNumericStepper(1, 120, mediumAbsortionTimeValue, 1);
			mediumAbsorptionTime.addEventListener(Event.CHANGE, onSettingsChanged);
			slowAbsorptionTime = LayoutFactory.createNumericStepper(1, 120, slowAbsortionTimeValue, 1);
			slowAbsorptionTime.addEventListener(Event.CHANGE, onSettingsChanged);
			
			defaultCarbAbsorptionTime = LayoutFactory.createPickerList();
			defaultCarbAbsorptionTime.prompt = ModelLocator.resourceManagerInstance.getString('globaltranslations','picker_select')
			var carbTypesNamesList:Array = ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','all_carb_types_list').split(",");
			var carbTypeList:ArrayCollection = new ArrayCollection();
			for (var i:int = 0; i < carbTypesNamesList.length; i++) 
			{
				carbTypeList.push({label: StringUtil.trim(carbTypesNamesList[i]), id: i});
			}
			carbTypesNamesList.length = 0;
			carbTypesNamesList = null;
			defaultCarbAbsorptionTime.popUpContentManager = new DropDownPopUpContentManager();
			defaultCarbAbsorptionTime.dataProvider = carbTypeList;
			
			if (defaultAbsortionTimeValue == fastAbsortionTimeValue)
				defaultCarbAbsorptionTime.selectedIndex = 0;
			else if (defaultAbsortionTimeValue == mediumAbsortionTimeValue)
				defaultCarbAbsorptionTime.selectedIndex = 1;
			else if (defaultAbsortionTimeValue == slowAbsortionTimeValue)
				defaultCarbAbsorptionTime.selectedIndex = 2;
			else
				defaultCarbAbsorptionTime.selectedIndex = -1;
				
			defaultCarbAbsorptionTime.itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "label";
				return itemRenderer;
			}
			defaultCarbAbsorptionTime.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Description
			carbAbsorptionTimeDescription = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','carb_absorption_time_description_label'), HorizontalAlign.JUSTIFY);
			carbAbsorptionTimeDescription.wordWrap = true;
			carbAbsorptionTimeDescription.width = width;
			carbAbsorptionTimeDescription.paddingTop = carbAbsorptionTimeDescription.paddingBottom = 10;
			
			//Carb absorption rate stepper
			carbAbsorptionRateStepper = LayoutFactory.createNumericStepper(0.5, 500, currentProfile.carbsAbsorptionRate, 0.5);
			carbAbsorptionRateStepper.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Description
			carbAbsorptionRateDescription = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','carb_absorption_rate_description'), HorizontalAlign.JUSTIFY);
			carbAbsorptionRateDescription.wordWrap = true;
			carbAbsorptionRateDescription.width = width;
			carbAbsorptionRateDescription.paddingTop = carbAbsorptionRateDescription.paddingBottom = 10;
			
			//Guide
			var actionLayout:HorizontalLayout = new HorizontalLayout();
			actionLayout.horizontalAlign = HorizontalAlign.CENTER;
			actionContainer = new LayoutGroup();
			actionContainer.layout = actionLayout;
			actionContainer.width = width;
			
			guide = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','guide_button_label'));
			guide.addEventListener(Event.TRIGGERED, onGuide);
			actionContainer.addChild(guide);
			
			//Set screen content
			var data:Array = [];
			data.push( { label: ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','absorption_time_label') } );
			data.push( { label: ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','fast_absorption_time_label'), accessory: fastAbsorptionTime } );
			data.push( { label: ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','medium_absorption_time_label'), accessory: mediumAbsorptionTime } );
			data.push( { label: ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','slow_absorption_time_label'), accessory: slowAbsorptionTime } );
			data.push( { label: ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','default_carb_type_label'), accessory: defaultCarbAbsorptionTime } );
			data.push( { label: "", accessory: carbAbsorptionTimeDescription } );
			data.push( { label: ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','absorption_rate_label') } );
			data.push( { label: ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','carb_absorption_rate_label'), accessory: carbAbsorptionRateStepper } );
			data.push( { label: "", accessory: carbAbsorptionRateDescription } );
			data.push( { label: "", accessory: actionContainer } );
			dataProvider = new ArrayCollection(data);
		}
		
		public function save():void
		{
			if (carbAbsorptionRateStepper.value != currentProfile.carbsAbsorptionRate)
			{
				currentProfile.carbsAbsorptionRate = carbAbsorptionRateStepper.value;
				ProfileManager.updateProfile(currentProfile);
			}
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CARB_FAST_ABSORTION_TIME) != String(fastAbsortionTimeValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_CARB_FAST_ABSORTION_TIME, String(fastAbsortionTimeValue));
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CARB_MEDIUM_ABSORTION_TIME) != String(mediumAbsortionTimeValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_CARB_MEDIUM_ABSORTION_TIME, String(mediumAbsortionTimeValue));
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CARB_SLOW_ABSORTION_TIME) != String(slowAbsortionTimeValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_CARB_SLOW_ABSORTION_TIME, String(slowAbsortionTimeValue));
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEFAULT_CARB_ABSORTION_TIME) != String(defaultAbsortionTimeValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_DEFAULT_CARB_ABSORTION_TIME, String(defaultAbsortionTimeValue));
			
			needsSave = false;
		}
		
		/**
		 * Event Listeners
		 */
		private function onSettingsChanged(e:Event):void
		{
			fastAbsortionTimeValue = fastAbsorptionTime.value;
			mediumAbsortionTimeValue = mediumAbsorptionTime.value;
			slowAbsortionTimeValue = slowAbsorptionTime.value;
			
			if (defaultCarbAbsorptionTime.selectedIndex == 0)
				defaultAbsortionTimeValue = fastAbsortionTimeValue;
			else if (defaultCarbAbsorptionTime.selectedIndex == 1)
				defaultAbsortionTimeValue = mediumAbsortionTimeValue;
			else if (defaultCarbAbsorptionTime.selectedIndex == 2)
				defaultAbsortionTimeValue = slowAbsortionTimeValue;
			
			needsSave = true;
		}
		
		private function onGuide(e:Event):void
		{
			navigateToURL(new URLRequest("https://diyps.org/2014/05/29/determining-your-carbohydrate-absorption-rate-diyps-lessons-learned/"));
		}
		
		override protected function onStarlingResize(event:ResizeEvent):void 
		{
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
			
			if (carbAbsorptionRateDescription != null)
			{
				if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr && !Constants.isPortrait)
					carbAbsorptionRateDescription.width = width - 30;
				else
					carbAbsorptionRateDescription.width = width;
			}
			
			if (carbAbsorptionTimeDescription != null)
			{
				if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr && !Constants.isPortrait)
					carbAbsorptionTimeDescription.width = width - 30;
				else
					carbAbsorptionTimeDescription.width = width;
			}
			
			if (actionContainer != null)
				actionContainer.width = width;
			
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
			if (carbAbsorptionRateStepper != null)
			{
				carbAbsorptionRateStepper.removeEventListener(Event.CHANGE, onSettingsChanged);
				carbAbsorptionRateStepper.dispose();
				carbAbsorptionRateStepper = null;
			}
			
			if (carbAbsorptionRateDescription != null)
			{
				carbAbsorptionRateDescription.dispose();
				carbAbsorptionRateDescription = null;
			}
			
			if (guide != null)
			{
				guide.removeFromParent();
				guide.removeEventListener(Event.TRIGGERED, onGuide);
				guide.dispose();
				guide = null;
			}
			
			if (actionContainer != null)
			{
				actionContainer.dispose();
				actionContainer = null; 
			}
			
			if (fastAbsorptionTime != null)
			{
				fastAbsorptionTime.removeEventListener(Event.CHANGE, onSettingsChanged);
				fastAbsorptionTime.dispose();
				fastAbsorptionTime = null;
			}
			
			if (mediumAbsorptionTime != null)
			{
				mediumAbsorptionTime.removeEventListener(Event.CHANGE, onSettingsChanged);
				mediumAbsorptionTime.dispose();
				mediumAbsorptionTime = null;
			}
			
			if (slowAbsorptionTime != null)
			{
				slowAbsorptionTime.removeEventListener(Event.CHANGE, onSettingsChanged);
				slowAbsorptionTime.dispose();
				slowAbsorptionTime = null;
			}
			
			if (defaultCarbAbsorptionTime != null)
			{
				defaultCarbAbsorptionTime.removeEventListener(Event.CHANGE, onSettingsChanged);
				defaultCarbAbsorptionTime.dispose();
				defaultCarbAbsorptionTime = null;
			}
			
			if (carbAbsorptionTimeDescription != null)
			{
				carbAbsorptionTimeDescription.dispose();
				carbAbsorptionTimeDescription = null;
			}
			
			super.dispose();
		}
	}
}