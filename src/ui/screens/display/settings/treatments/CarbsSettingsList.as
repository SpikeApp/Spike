package ui.screens.display.settings.treatments
{
	import feathers.controls.List;
	import feathers.controls.NumericStepper;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.data.ArrayCollection;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import starling.events.Event;
	
	import treatments.Profile;
	import treatments.ProfileManager;
	
	import ui.screens.display.LayoutFactory;
	
	import utils.Constants;
	
	[ResourceBundle("profilesettingsscreen")]
	
	public class CarbsSettingsList extends List 
	{
		/* Display Objects */
		private var carbAbsorptionRateStepper:NumericStepper;
		
		/* Properties */
		private var userProfiles:Array;
		private var currentProfile:Profile;
		public var needsSave:Boolean;
		
		public function CarbsSettingsList()
		{
			super();
			
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
		}
		
		private function setupContent():void
		{	
			//Carb absorption rate stepper
			carbAbsorptionRateStepper = LayoutFactory.createNumericStepper(0.5, 500, currentProfile.carbsAbsorptionRate, 0.5);
			carbAbsorptionRateStepper.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Set screen content
			var data:Array = [];
			data.push( { text: ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','carb_absorption_rate_label'), accessory: carbAbsorptionRateStepper } );
			dataProvider = new ArrayCollection(data);
			
			/* Set Item Renderer */
			itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "text";
				itemRenderer.accessoryField = "accessory";
				itemRenderer.paddingRight = 0;
				return itemRenderer;
			};
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
		
		/**
		 * Utility
		 */	
		override public function dispose():void
		{
			if (carbAbsorptionRateStepper != null)
			{
				carbAbsorptionRateStepper.removeEventListener(Event.CHANGE, onSettingsChanged);
				carbAbsorptionRateStepper.dispose();
				carbAbsorptionRateStepper = null;
			}
			
			super.dispose();
		}
	}
}