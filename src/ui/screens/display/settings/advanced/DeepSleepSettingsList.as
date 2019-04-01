package ui.screens.display.settings.advanced
{
	import com.adobe.utils.StringUtil;
	
	import flash.display.StageOrientation;
	
	import database.CommonSettings;
	
	import feathers.controls.Check;
	import feathers.controls.Label;
	import feathers.controls.PickerList;
	import feathers.controls.ToggleSwitch;
	import feathers.controls.popups.DropDownPopUpContentManager;
	import feathers.controls.text.HyperlinkTextFieldTextRenderer;
	import feathers.core.ITextRenderer;
	import feathers.data.ArrayCollection;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalAlign;
	import feathers.layout.VerticalLayout;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import starling.events.Event;
	import starling.events.ResizeEvent;
	
	import ui.screens.display.LayoutFactory;
	import ui.screens.display.SpikeList;
	
	import utils.Constants;
	import utils.DeviceInfo;
	
	[ResourceBundle("advancedsettingsscreen")]

	public class DeepSleepSettingsList extends SpikeList 
	{
		/* Display Objects */
		private var manageSuspensionToggle:ToggleSwitch;
		private var suspensionModePicker:PickerList;
		private var instructionsTitleLabel:Label;
		private var instructionsDescriptionLabel:Label;
		private var alternativeMethod1Check:Check;
		private var alternativeMethod2Check:Check;
		
		/* Properties */
		public var needsSave:Boolean = false;
		private var userManagesSuspension:Boolean;
		private var suspensionMode:int;
		private var alternativeMode1Active:Boolean;
		private var alternativeMode2Active:Boolean;
		
		public function DeepSleepSettingsList()
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
			userManagesSuspension = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEEP_SLEEP_SELF_MANAGEMENT_ON) == "true";
			suspensionMode = int(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEEP_SLEEP_MODE));
			alternativeMode1Active = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEEP_SLEEP_ALTERNATIVE_MODE) == "true";
			alternativeMode2Active = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEEP_SLEEP_ALTERNATIVE_MODE_2) == "true";
		}
		
		private function setupContent():void
		{
			//On/Off toggle
			manageSuspensionToggle = LayoutFactory.createToggleSwitch(userManagesSuspension);
			manageSuspensionToggle.pivotX = 5;
			manageSuspensionToggle.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Suspension Mode Picker
			suspensionModePicker = LayoutFactory.createPickerList();
			
			/* Set Picker Data */
			var suspensionModeLabelsList:Array = ModelLocator.resourceManagerInstance.getString('advancedsettingsscreen','suspension_modes').split(",");
			var suspensionModeList:ArrayCollection = new ArrayCollection();
			for (var i:int = 0; i < suspensionModeLabelsList.length; i++) 
			{
				suspensionModeList.push({label: StringUtil.trim(suspensionModeLabelsList[i]), id: i});
			}
			suspensionModeLabelsList.length = 0;
			suspensionModeLabelsList = null;
			suspensionModePicker.labelField = "label";
			suspensionModePicker.popUpContentManager = new DropDownPopUpContentManager();
			suspensionModePicker.dataProvider = suspensionModeList;
			suspensionModePicker.selectedIndex = suspensionMode;
			suspensionModePicker.addEventListener(Event.CHANGE, onSuspensionModeChanged);
			
			//Alternative method #1
			alternativeMethod1Check = LayoutFactory.createCheckMark(alternativeMode1Active);
			alternativeMethod1Check.addEventListener(Event.CHANGE, onAlternativeMethod1Changed);
			
			//Alternative method #2
			alternativeMethod2Check = LayoutFactory.createCheckMark(alternativeMode2Active);
			alternativeMethod2Check.addEventListener(Event.CHANGE, onAlternativeMethod2Changed);
			
			//Instructions Title Label
			instructionsTitleLabel = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('advancedsettingsscreen','instructions_title_label'), HorizontalAlign.CENTER, VerticalAlign.TOP, 17, true);
			instructionsTitleLabel.width = width;
			
			//Instructions Description Label
			instructionsDescriptionLabel = new Label();
			instructionsDescriptionLabel.text = ModelLocator.resourceManagerInstance.getString('advancedsettingsscreen','suspension_instructions');
			instructionsDescriptionLabel.width = width;
			instructionsDescriptionLabel.wordWrap = true;
			instructionsDescriptionLabel.paddingTop = instructionsDescriptionLabel.paddingBottom = 10;
			instructionsDescriptionLabel.isQuickHitAreaEnabled = false;
			instructionsDescriptionLabel.textRendererFactory = function():ITextRenderer 
			{
				var textRenderer:HyperlinkTextFieldTextRenderer = new HyperlinkTextFieldTextRenderer();
				textRenderer.wordWrap = true;
				textRenderer.isHTML = true;
				textRenderer.pixelSnapping = true;
				
				return textRenderer;
			};
			
			refreshContent();
		}
		
		private function refreshContent():void
		{
			var content:Array = [];
			content.push( { label: ModelLocator.resourceManagerInstance.getString('advancedsettingsscreen','user_defined_label'), accessory: manageSuspensionToggle } );
			if (userManagesSuspension)
			{
				content.push( { label: ModelLocator.resourceManagerInstance.getString('advancedsettingsscreen','mode_label'), accessory: suspensionModePicker } );
				content.push( { label: ModelLocator.resourceManagerInstance.getString('advancedsettingsscreen','alternative_method_1'), accessory: alternativeMethod1Check } );
				content.push( { label: ModelLocator.resourceManagerInstance.getString('advancedsettingsscreen','alternative_method_2'), accessory: alternativeMethod2Check } );
				content.push({ label: "", accessory: instructionsTitleLabel });
				content.push({ label: "", accessory: instructionsDescriptionLabel });
			}
			
			dataProvider = new ArrayCollection(content);
		}
		
		public function save():void
		{
			//User manages suspension
			var userManagesSuspensionValueToSave:String;
			if (userManagesSuspension) userManagesSuspensionValueToSave = "true";
			else userManagesSuspensionValueToSave = "false";
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEEP_SLEEP_SELF_MANAGEMENT_ON) != userManagesSuspensionValueToSave)
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_DEEP_SLEEP_SELF_MANAGEMENT_ON, userManagesSuspensionValueToSave);
			
			//Suspension Mode
			var suspensionModeValueToSave:String = String(suspensionModePicker.selectedIndex)
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEEP_SLEEP_MODE) != suspensionModeValueToSave)
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_DEEP_SLEEP_MODE, suspensionModeValueToSave);
			
			//Alternative method # 1
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEEP_SLEEP_ALTERNATIVE_MODE) != String(alternativeMode1Active))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_DEEP_SLEEP_ALTERNATIVE_MODE, String(alternativeMode1Active));
			
			//Alternative method # 2
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEEP_SLEEP_ALTERNATIVE_MODE_2) != String(alternativeMode2Active))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_DEEP_SLEEP_ALTERNATIVE_MODE_2, String(alternativeMode2Active));
			
			needsSave = false;
		}
		
		/**
		 * Event Listeners
		 */
		private function onSuspensionModeChanged(e:Event):void
		{
			//Update internal variables
			suspensionMode = suspensionModePicker.selectedIndex;
			needsSave = true;
		}
		
		private function onSettingsChanged(e:Event):void
		{
			userManagesSuspension = manageSuspensionToggle.isSelected;
			needsSave = true;
			
			//Refresh screen content
			refreshContent();
		}
		
		private function onAlternativeMethod1Changed(e:Event):void
		{
			alternativeMode1Active = alternativeMethod1Check.isSelected;
			
			needsSave = true;
		}
		
		private function onAlternativeMethod2Changed(e:Event):void
		{
			alternativeMode2Active = alternativeMethod2Check.isSelected;
			
			needsSave = true;
		}
		
		override protected function onStarlingResize(event:ResizeEvent):void 
		{
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
			
			if (instructionsTitleLabel != null)
				instructionsTitleLabel.width = width;
			
			if (instructionsDescriptionLabel != null)
			{
				if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr && !Constants.isPortrait)
				{
					if (Constants.currentOrientation == StageOrientation.ROTATED_RIGHT)
						instructionsDescriptionLabel.width = width - 30;
					if (Constants.currentOrientation == StageOrientation.ROTATED_LEFT)
						instructionsDescriptionLabel.width = width - 40;
				}
				else
					instructionsDescriptionLabel.width = width;
			}
			
			setupRenderFactory();
		}
		
		/**
		 * Utility
		 */
		override protected function draw():void
		{
			(layout as VerticalLayout).hasVariableItemDimensions = true;
			super.draw();
		}
		
		override public function dispose():void
		{
			if (suspensionModePicker != null)
			{
				suspensionModePicker.removeEventListener(Event.CHANGE, onSuspensionModeChanged);
				suspensionModePicker.dispose();
				suspensionModePicker = null;
			}
			
			if (manageSuspensionToggle != null)
			{
				manageSuspensionToggle.removeEventListener(Event.CHANGE, onSettingsChanged);
				manageSuspensionToggle.dispose();
				manageSuspensionToggle = null;
			}
			
			if (alternativeMethod1Check != null)
			{
				alternativeMethod1Check.removeEventListener(Event.CHANGE, onAlternativeMethod1Changed);
				alternativeMethod1Check.dispose();
				alternativeMethod1Check = null;
			}
			
			if (alternativeMethod2Check != null)
			{
				alternativeMethod2Check.removeEventListener(Event.CHANGE, onAlternativeMethod2Changed);
				alternativeMethod2Check.dispose();
				alternativeMethod2Check = null;
			}
			
			super.dispose();
		}
	}
}