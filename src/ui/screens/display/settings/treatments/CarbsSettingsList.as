package ui.screens.display.settings.treatments
{
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	
	import feathers.controls.Button;
	import feathers.controls.Label;
	import feathers.controls.LayoutGroup;
	import feathers.controls.NumericStepper;
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
	
	public class CarbsSettingsList extends SpikeList 
	{
		/* Display Objects */
		private var carbAbsorptionRateStepper:NumericStepper;
		private var carbAbsorptionRateDescription:Label;
		private var actionContainer:LayoutGroup;
		private var guide:Button;
		
		/* Properties */
		private var userProfiles:Array;
		private var currentProfile:Profile;
		public var needsSave:Boolean;
		
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
		}
		
		private function setupContent():void
		{	
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
		}
		
		/**
		 * Event Listeners
		 */
		private function onSettingsChanged(e:Event):void
		{
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
				if (Constants.deviceModel == DeviceInfo.IPHONE_X && !Constants.isPortrait)
					carbAbsorptionRateDescription.width = width - 30;
				else
					carbAbsorptionRateDescription.width = width;
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
			
			super.dispose();
		}
	}
}