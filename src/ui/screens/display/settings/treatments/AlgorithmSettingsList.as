package ui.screens.display.settings.treatments
{
	import database.CommonSettings;
	
	import feathers.controls.Button;
	import feathers.controls.Label;
	import feathers.controls.PickerList;
	import feathers.controls.popups.DropDownPopUpContentManager;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.data.ArrayCollection;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalLayout;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import starling.events.Event;
	import starling.events.ResizeEvent;
	
	import treatments.Profile;
	import treatments.ProfileManager;
	
	import ui.popups.AlertManager;
	import ui.screens.display.LayoutFactory;
	import ui.screens.display.SpikeList;
	
	import utils.Constants;
	import utils.DeviceInfo;
	
	[ResourceBundle("profilesettingsscreen")]
	[ResourceBundle("globaltranslations")]
	
	public class AlgorithmSettingsList extends SpikeList 
	{
		/* Display Objects */
		private var defaultAlgorithmPicker:PickerList;
		private var algorithmDescription:Label;
		private var detailsButton:Button;
		
		/* Properties */
		private var algorithmValue:String;
		private var showDetails:Boolean = false;	
		
		public function AlgorithmSettingsList()
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
			algorithmValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEFAULT_IOB_COB_ALGORITHM);
		}
		
		private function setupContent():void
		{	
			//Carb absorption time
			
			defaultAlgorithmPicker = LayoutFactory.createPickerList();
			
			var algorithmList:ArrayCollection = new ArrayCollection();
			algorithmList.push( { label: "Nightscout", id: "nightscout" } );
			algorithmList.push( { label: "OpenAPS (oref0)", id: "openaps" } );
			
			defaultAlgorithmPicker.popUpContentManager = new DropDownPopUpContentManager();
			defaultAlgorithmPicker.dataProvider = algorithmList;
			
			if (algorithmValue == "nightscout")
				defaultAlgorithmPicker.selectedIndex = 0;
			else if (algorithmValue == "openaps")
				defaultAlgorithmPicker.selectedIndex = 1;
				
			defaultAlgorithmPicker.itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "label";
				return itemRenderer;
			}
			defaultAlgorithmPicker.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Description Button
			detailsButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','show_details_button_label'));
			detailsButton.addEventListener(Event.TRIGGERED, onShowHideDetails);
			
			//Description Label
			algorithmDescription = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','algorithms_description_label'), HorizontalAlign.JUSTIFY);
			algorithmDescription.wordWrap = true;
			algorithmDescription.width = width;
			algorithmDescription.paddingTop = algorithmDescription.paddingBottom = 10;
			
			//Set screen content
			refreshContent();
		}
		
		private function refreshContent():void
		{
			var data:Array = [];
			data.push( { label: ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','iob_cob_algorithm_selector_label'), accessory: defaultAlgorithmPicker } );
			if (showDetails)
				data.push( { label: "", accessory: algorithmDescription } );
			data.push( { label: "", accessory: detailsButton } );
			dataProvider = new ArrayCollection(data);
		}
		
		/**
		 * Event Listeners
		 */
		private function onShowHideDetails(e:Event):void
		{
			showDetails = !showDetails;
			detailsButton.label = showDetails == false ? ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','show_details_button_label') : ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','hide_details_button_label');
			detailsButton.validate();
			
			refreshContent();
			
			if (!showDetails)
			{
				dispatchEventWith(Event.CLOSE);
			}
		}
		
		private function onSettingsChanged(e:Event):void
		{
			algorithmValue = defaultAlgorithmPicker.selectedItem.id;
			
			if (algorithmValue == "openaps")
			{
				//Check if all user profiles are complete
				var issueFound:Boolean = false;
				var numberOfProfiles:uint = ProfileManager.profilesList.length;
				for (var i:int = 0; i < numberOfProfiles; i++) 
				{
					var userProfile:Profile = ProfileManager.profilesList[i];
					if (userProfile != null)
					{
						
						if (userProfile.insulinSensitivityFactors == "" || userProfile.insulinToCarbRatios == "")
						{
							issueFound = true;
						}
					}
				}
				
				if (issueFound)
				{
					//Revert to Nightscout algorithm
					algorithmValue = "nightscout";
					defaultAlgorithmPicker.selectedIndex = 0;
					
					//Warn user
					AlertManager.showSimpleAlert
					(
						ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
						ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','incomplete_profile_warning')
					);
				}
			}
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEFAULT_IOB_COB_ALGORITHM) != algorithmValue)
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_DEFAULT_IOB_COB_ALGORITHM, algorithmValue);
		}
		
		override protected function onStarlingResize(event:ResizeEvent):void 
		{
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
			
			if (algorithmDescription != null)
			{
				if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr && !Constants.isPortrait)
					algorithmDescription.width = width - 30;
				else
					algorithmDescription.width = width;
			}
			
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
			if (defaultAlgorithmPicker != null)
			{
				defaultAlgorithmPicker.removeEventListener(Event.CHANGE, onSettingsChanged);
				defaultAlgorithmPicker.removeFromParent();
				defaultAlgorithmPicker.dispose();
				defaultAlgorithmPicker = null;
			}
			
			if (algorithmDescription != null)
			{
				algorithmDescription.removeFromParent();
				algorithmDescription.dispose();
				algorithmDescription = null;
			}
			
			if (detailsButton != null)
			{
				detailsButton.removeEventListener(Event.TRIGGERED, onShowHideDetails);
				detailsButton.removeFromParent();
				detailsButton.dispose();
				detailsButton = null;
			}
			
			super.dispose();
		}
	}
}