package ui.screens.display.settings.advanced
{
	import mx.messaging.messages.CommandMessage;
	
	import database.CommonSettings;
	
	import feathers.controls.Check;
	import feathers.controls.Label;
	import feathers.controls.List;
	import feathers.controls.PickerList;
	import feathers.controls.ToggleSwitch;
	import feathers.controls.popups.DropDownPopUpContentManager;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.controls.text.HyperlinkTextFieldTextRenderer;
	import feathers.core.ITextRenderer;
	import feathers.data.ArrayCollection;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalAlign;
	import feathers.layout.VerticalLayout;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import starling.events.Event;
	
	import ui.screens.display.LayoutFactory;
	
	import utils.Constants;
	
	[ResourceBundle("advancedsettingsscreen")]

	public class DeepSleepSettingsList extends List 
	{
		/* Display Objects */
		private var manageSuspensionToggle:ToggleSwitch;
		private var suspensionModePicker:PickerList;
		private var instructionsTitleLabel:Label;
		private var instructionsDescriptionLabel:Label;
		private var alternativeMethodCheck:Check;
		
		/* Properties */
		public var needsSave:Boolean = false;
		private var userManagesSuspension:Boolean;
		private var suspensionMode:int;
		private var alternativeModeActive:Boolean;
		
		public function DeepSleepSettingsList()
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
			userManagesSuspension = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEEP_SLEEP_SELF_MANAGEMENT_ON) == "true";
			suspensionMode = int(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEEP_SLEEP_MODE));
			alternativeModeActive = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEEP_SLEEP_ALTERNATIVE_MODE) == "true";
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
				suspensionModeList.push({label: suspensionModeLabelsList[i], id: i});
			}
			suspensionModeLabelsList.length = 0;
			suspensionModeLabelsList = null;
			suspensionModePicker.labelField = "label";
			suspensionModePicker.popUpContentManager = new DropDownPopUpContentManager();
			suspensionModePicker.dataProvider = suspensionModeList;
			suspensionModePicker.selectedIndex = suspensionMode;
			suspensionModePicker.addEventListener(Event.CHANGE, onSuspensionModeChanged);
			
			//Alternative method
			alternativeMethodCheck = LayoutFactory.createCheckMark(alternativeModeActive);
			alternativeMethodCheck.addEventListener(Event.CHANGE, onAlternativeMethodChanged);
			
			/* Set Item Renderer */
			itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "text";
				itemRenderer.accessoryField = "accessory";
				itemRenderer.paddingRight = 0;
				return itemRenderer;
			};
			
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
			content.push( { text: ModelLocator.resourceManagerInstance.getString('advancedsettingsscreen','user_defined_label'), accessory: manageSuspensionToggle } );
			if (userManagesSuspension)
			{
				content.push( { text: ModelLocator.resourceManagerInstance.getString('advancedsettingsscreen','mode_label'), accessory: suspensionModePicker } );
				content.push( { text: "Alternative Method:", accessory: alternativeMethodCheck } );
				content.push({ text: "", accessory: instructionsTitleLabel });
				content.push({ text: "", accessory: instructionsDescriptionLabel });
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
			
			//Alternative method
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEEP_SLEEP_ALTERNATIVE_MODE) != String(alternativeModeActive))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_DEEP_SLEEP_ALTERNATIVE_MODE, String(alternativeModeActive));
			
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
		
		private function onAlternativeMethodChanged(e:Event):void
		{
			alternativeModeActive = alternativeMethodCheck.isSelected
			needsSave = true;
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
			
			if (alternativeMethodCheck != null)
			{
				alternativeMethodCheck.removeEventListener(Event.CHANGE, onAlternativeMethodChanged);
				alternativeMethodCheck.dispose();
				alternativeMethodCheck = null;
			}
			
			super.dispose();
		}
	}
}