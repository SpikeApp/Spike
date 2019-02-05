package ui.screens
{
	import flash.display.StageOrientation;
	import flash.system.System;
	
	import database.CommonSettings;
	
	import events.SettingsServiceEvent;
	
	import feathers.controls.DragGesture;
	import feathers.controls.Label;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.ModelLocator;
	
	import starling.display.DisplayObject;
	import starling.events.Event;
	import starling.events.ResizeEvent;
	
	import ui.AppInterface;
	import ui.screens.display.LayoutFactory;
	import ui.screens.display.settings.treatments.AlgorithmSettingsList;
	import ui.screens.display.settings.treatments.BasalRatesSettingsList;
	import ui.screens.display.settings.treatments.CarbsSettingsList;
	import ui.screens.display.settings.treatments.InsulinsSettingsList;
	import ui.screens.display.settings.treatments.ProfileSettingsList;
	import ui.screens.display.settings.treatments.UserTypeSettingsList;
	
	import utils.Constants;
	import utils.DeviceInfo;
	
	[ResourceBundle("profilesettingsscreen")]

	public class ProfileSettingsScreen extends BaseSubScreen
	{
		/* Display Objects */
		private var insulinsSettings:InsulinsSettingsList;
		private var insulinsLabel:Label;
		private var carbsLabel:Label;
		private var carbsSettings:CarbsSettingsList;
		private var profileSettings:ProfileSettingsList;
		private var profileLabel:Label;
		private var algorithmLabel:Label;
		private var algorithmsSetting:AlgorithmSettingsList;
		private var basalsLabel:Label;
		private var basalsSettings:BasalRatesSettingsList;
		private var userTypeLabel:Label;
		private var userTypeSettings:UserTypeSettingsList;
		
		public function ProfileSettingsScreen() 
		{
			super();
			
			setupHeader();	
		}
		override protected function initialize():void 
		{
			super.initialize();
			
			setupContent();
			
			CommonSettings.instance.addEventListener(SettingsServiceEvent.SETTING_CHANGED, onSettingChanged);
		}
		
		/**
		 * Functionality
		 */
		private function setupHeader():void
		{
			/* Set Header Title */
			title = ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','screen_title');
			
			/* Set Header Icon */
			icon = getScreenIcon(MaterialDeepGreyAmberMobileThemeIcons.profileTexture);
			iconContainer = new <DisplayObject>[icon];
			headerProperties.rightItems = iconContainer;
		}
		
		private function setupContent():void
		{
			//Deactivate menu drag gesture 
			AppInterface.instance.drawers.openGesture = DragGesture.NONE;
			
			//User Type Section Label
			userTypeLabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','user_type_section_title'), true);
			screenRenderer.addChild(userTypeLabel);
			
			//Algorithms Settings
			userTypeSettings = new UserTypeSettingsList();
			screenRenderer.addChild(userTypeSettings);
			
			//Algorithms Section Label
			algorithmLabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','iob_cob_algorithm_label'), true);
			screenRenderer.addChild(algorithmLabel);
			
			//Algorithms Settings
			algorithmsSetting = new AlgorithmSettingsList();
			algorithmsSetting.addEventListener(Event.CLOSE, onResetVerticalScroll);
			screenRenderer.addChild(algorithmsSetting);
			
			//Insulins Section Label
			insulinsLabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','insulins_label'), true);
			screenRenderer.addChild(insulinsLabel);
			
			//Insulins Settings
			insulinsSettings = new InsulinsSettingsList();
			insulinsSettings.addEventListener(Event.CLOSE, onResetVerticalScroll);
			screenRenderer.addChild(insulinsSettings);
			
			//Carbs Section Label
			carbsLabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','carbs_label'), true);
			screenRenderer.addChild(carbsLabel);
			
			//Carbs Settings
			carbsSettings = new CarbsSettingsList();
			screenRenderer.addChild(carbsSettings);
			
			//ISF Section Label
			profileLabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','insulin_sensitivity_factor_short_label') + " / " + ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','insulin_to_carb_ratio_short_label') + " / " + ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','target_glucose_label') + " / " + ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','glucose_trends_label'), true);
			screenRenderer.addChild(profileLabel);
			
			//ISF Settings
			profileSettings = new ProfileSettingsList();
			screenRenderer.addChild(profileSettings);
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_USER_TYPE_PUMP_OR_MDI) == "pump")
			{
				showBasalRates();
			}
		}
		
		private function showBasalRates():void
		{
			//Validation
			if (screenRenderer == null)
			{
				return;
			}
			
			//Basals Section Label
			if (basalsLabel == null || basalsLabel.parent == null)
			{
				if (basalsLabel == null)
				{
					basalsLabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','basal_settings_section_label'), true);
				}
				screenRenderer.addChild(basalsLabel);
			}
			
			//Basals Section Settings
			if (basalsSettings == null || basalsSettings.parent == null)
			{
				if (basalsSettings == null)
				{
					basalsSettings = new BasalRatesSettingsList();
				}
				screenRenderer.addChild(basalsSettings);
			}
		}
		
		private function removeBasalRates():void
		{
			if (basalsLabel != null)
			{
				basalsLabel.removeFromParent();
			}
			
			if (basalsSettings != null)
			{
				basalsSettings.removeFromParent();
			}
		}
		
		/**
		 * Event Handlers
		 */
		private function onResetVerticalScroll(e:Event):void
		{
			verticalScrollPosition = 0;
		}
		
		override protected function onBackButtonTriggered(event:Event):void
		{
			if (carbsSettings != null && carbsSettings.needsSave)
				carbsSettings.save();
			
			//Activate menu drag gesture
			AppInterface.instance.drawers.openGesture = DragGesture.EDGE;
			
			//Pop Screen
			dispatchEventWith(Event.COMPLETE);
		}
		
		override protected function onTransitionInComplete(e:Event):void
		{
			//Swipe to pop functionality
			AppInterface.instance.navigator.isSwipeToPopEnabled = true;
		}
		
		private function onSettingChanged(e:SettingsServiceEvent):void
		{
			if (e.data == CommonSettings.COMMON_SETTING_USER_TYPE_PUMP_OR_MDI) 
			{
				if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_USER_TYPE_PUMP_OR_MDI) == "pump")
				{
					showBasalRates();
				}
				else
				{
					removeBasalRates();
				}
			}
		}
		
		override protected function onStarlingBaseResize(e:ResizeEvent):void 
		{
			if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr && !Constants.isPortrait && Constants.currentOrientation == StageOrientation.ROTATED_RIGHT)
			{
				if (userTypeLabel != null) userTypeLabel.paddingLeft = 30;
				if (algorithmLabel != null) algorithmLabel.paddingLeft = 30;
				if (insulinsLabel != null) insulinsLabel.paddingLeft = 30;
				if (carbsLabel != null) carbsLabel.paddingLeft = 30;
				if (profileLabel != null) carbsLabel.paddingLeft = 30;
				if (basalsLabel != null) basalsLabel.paddingLeft = 30;
			}
			else
			{
				if (userTypeLabel != null) userTypeLabel.paddingLeft = 0;
				if (algorithmLabel != null) algorithmLabel.paddingLeft = 0;
				if (insulinsLabel != null) insulinsLabel.paddingLeft = 0;
				if (carbsLabel != null) carbsLabel.paddingLeft = 0;
				if (profileLabel != null) carbsLabel.paddingLeft = 0;
				if (basalsLabel != null) basalsLabel.paddingLeft = 0;
			}
			
			setupHeaderSize();
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			CommonSettings.instance.removeEventListener(SettingsServiceEvent.SETTING_CHANGED, onSettingChanged);
			
			if (algorithmLabel != null)
			{
				algorithmLabel.removeFromParent();
				algorithmLabel.dispose();
				algorithmLabel = null;
			}
			
			if (algorithmsSetting != null)
			{
				algorithmsSetting.removeEventListener(Event.CLOSE, onResetVerticalScroll);
				algorithmsSetting.removeFromParent();
				algorithmsSetting.dispose();
				algorithmsSetting = null;
			}
			
			if (insulinsLabel != null)
			{
				insulinsLabel.removeFromParent();
				insulinsLabel.dispose();
				insulinsLabel = null;
			}
			
			if (insulinsSettings != null)
			{
				insulinsSettings.removeEventListener(Event.CLOSE, onResetVerticalScroll);
				insulinsSettings.removeFromParent();
				insulinsSettings.dispose();
				insulinsSettings = null;
			}
			
			if (carbsLabel != null)
			{
				carbsLabel.removeFromParent();
				carbsLabel.dispose();
				carbsLabel = null;
			}
			
			if (carbsSettings != null)
			{
				carbsSettings.removeFromParent();
				carbsSettings.dispose();
				carbsSettings = null;
			}
			
			if (profileLabel != null)
			{
				profileLabel.removeFromParent();
				profileLabel.dispose();
				profileLabel = null;
			}
			
			if (profileSettings != null)
			{
				profileSettings.removeFromParent();
				profileSettings.dispose();
				profileSettings = null;
			}
			
			if (basalsLabel != null)
			{
				basalsLabel.removeFromParent();
				basalsLabel.dispose();
				basalsLabel = null;
			}
			
			if (basalsSettings != null)
			{
				basalsSettings.removeFromParent();
				basalsSettings.dispose();
				basalsSettings = null;
			}
			
			if (userTypeLabel != null)
			{
				userTypeLabel.removeFromParent();
				userTypeLabel.dispose();
				userTypeLabel = null;
			}
			
			if (userTypeSettings != null)
			{
				userTypeSettings.removeFromParent();
				userTypeSettings.dispose();
				userTypeSettings = null;
			}
			
			super.dispose();
			
			System.pauseForGCIfCollectionImminent(0);
		}
		
		override protected function draw():void 
		{
			super.draw();
			icon.x = Constants.stageWidth - icon.width - BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding;
		}
	}
}