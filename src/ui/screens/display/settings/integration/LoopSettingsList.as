package ui.screens.display.settings.integration
{
	import database.LocalSettings;
	
	import feathers.controls.Label;
	import feathers.controls.List;
	import feathers.controls.TextInput;
	import feathers.controls.ToggleSwitch;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.controls.text.HyperlinkTextFieldTextRenderer;
	import feathers.core.ITextRenderer;
	import feathers.data.ArrayCollection;
	import feathers.events.FeathersEventType;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalAlign;
	import feathers.layout.VerticalLayout;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import starling.events.Event;
	
	import ui.screens.display.LayoutFactory;
	
	import utils.Constants;
	
	[ResourceBundle("globaltranslations")]
	[ResourceBundle("loopsettingsscreen")]

	public class LoopSettingsList extends List 
	{
		/* Display Objects */
		private var loopOfflineToggle:ToggleSwitch;
		private var instructionsTitleLabel:Label;
		private var instructionsDescriptionLabel:Label;
		private var userNameTextInput:TextInput;
		private var passwordTextInput:TextInput;
		
		/* Properties */
		public var needsSave:Boolean = false;
		private var loopServiceEnabled:Boolean;
		private var serverUsername:String;
		private var serverPassword:String;

		public function LoopSettingsList()
		{
			super();
		}
		override protected function initialize():void 
		{
			super.initialize();
			
			setupProperties();
			setupInitialState();
			setupContent();
		}
		
		/**
		 * Functionality
		 */
		private function setupProperties():void
		{
			//Set Properties
			clipContent = false;
			isSelectable = false;
			autoHideBackground = true;
			hasElasticEdges = false;
			paddingBottom = 5;
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
		}
		
		private function setupInitialState():void
		{
			loopServiceEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_LOOP_SERVER_ON) == "true";
			serverUsername = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_LOOP_SERVER_USERNAME);
			serverPassword = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_LOOP_SERVER_PASSWORD);
		}
		
		private function setupContent():void
		{
			//Loop Offline On/Off Toggle
			loopOfflineToggle = LayoutFactory.createToggleSwitch(loopServiceEnabled);
			loopOfflineToggle.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//UserneName TextInput
			userNameTextInput = LayoutFactory.createTextInput(false, false, 140, HorizontalAlign.RIGHT);
			userNameTextInput.text = serverUsername;
			userNameTextInput.addEventListener(FeathersEventType.ENTER, onEnterPressed);
			userNameTextInput.addEventListener(Event.CHANGE, onUpdateSaveStatus);
			userNameTextInput.addEventListener(FeathersEventType.FOCUS_OUT, onFocusOut);
			
			//Password TextInput
			passwordTextInput = LayoutFactory.createTextInput(true, false, 140, HorizontalAlign.RIGHT);
			passwordTextInput.text = serverPassword;
			passwordTextInput.addEventListener(FeathersEventType.ENTER, onEnterPressed);
			passwordTextInput.addEventListener(Event.CHANGE, onUpdateSaveStatus);
			passwordTextInput.addEventListener(FeathersEventType.FOCUS_OUT, onFocusOut);
			
			//Instructions Title Label
			instructionsTitleLabel = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('loopsettingsscreen','instructions_title_label'), HorizontalAlign.CENTER, VerticalAlign.TOP, 17, true);
			instructionsTitleLabel.width = width - 20;
			
			//Instructions Description Label
			instructionsDescriptionLabel = new Label();
			instructionsDescriptionLabel.text = ModelLocator.resourceManagerInstance.getString('loopsettingsscreen','instructions_description_label');
			instructionsDescriptionLabel.width = width - 20;
			instructionsDescriptionLabel.wordWrap = true;
			instructionsDescriptionLabel.paddingTop = 10;
			instructionsDescriptionLabel.isQuickHitAreaEnabled = false;
			instructionsDescriptionLabel.textRendererFactory = function():ITextRenderer 
			{
				var textRenderer:HyperlinkTextFieldTextRenderer = new HyperlinkTextFieldTextRenderer();
				textRenderer.wordWrap = true;
				textRenderer.isHTML = true;
				textRenderer.pixelSnapping = true;
					
				return textRenderer;
			};
			
			//Set Item Renderer
			itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "text";
				itemRenderer.accessoryField = "accessory";
				
				return itemRenderer;
			};
			
			(layout as VerticalLayout).hasVariableItemDimensions = true;
			
			refreshContent();
		}
		
		private function refreshContent():void
		{
			var content:Array = [];
			content.push({ text: ModelLocator.resourceManagerInstance.getString('globaltranslations','enabled'), accessory: loopOfflineToggle });
			if (loopServiceEnabled)
			{
				content.push({ text: ModelLocator.resourceManagerInstance.getString('loopsettingsscreen','username_label_title'), accessory: userNameTextInput });
				content.push({ text: ModelLocator.resourceManagerInstance.getString('loopsettingsscreen','password_label_title'), accessory: passwordTextInput });
				content.push({ text: "", accessory: instructionsTitleLabel });
				content.push({ text: "", accessory: instructionsDescriptionLabel });
			}
			
			dataProvider = new ArrayCollection(content);
		}
		
		public function save():void
		{
			if (userNameTextInput.text == "" && passwordTextInput.text == "" && loopOfflineToggle.isSelected || !needsSave)
				return
			
			//Feature On/Off
			var loopServiceValueToSave:String;
			if(loopServiceEnabled) loopServiceValueToSave = "true";
			else loopServiceValueToSave = "false";
				
			if(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_LOOP_SERVER_ON) != loopServiceValueToSave)
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_LOOP_SERVER_ON, loopServiceValueToSave);
				
			//Username
			if(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_LOOP_SERVER_USERNAME) != userNameTextInput.text)
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_LOOP_SERVER_USERNAME, userNameTextInput.text);
				
			//Password
			if(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_LOOP_SERVER_PASSWORD) != passwordTextInput.text)
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_LOOP_SERVER_PASSWORD, passwordTextInput.text);
			
			needsSave = false;
		}
		
		/**
		 * Event Handlers
		 */

		private function onSettingsChanged(e:Event):void
		{
			loopServiceEnabled = loopOfflineToggle.isSelected;
			
			refreshContent();
			
			needsSave = true;
		}
		
		private function onUpdateSaveStatus(e:Event):void
		{
			needsSave = true;
		}
		
		private function onEnterPressed(e:Event):void
		{
			userNameTextInput.clearFocus();
			passwordTextInput.clearFocus();
			
			if (needsSave)
				save();
		}
		
		private function onFocusOut(e:Event):void
		{
			if (needsSave)
				save();
		}
		
		/**
		 * Utility
		 */		
		override public function dispose():void
		{
			if(loopOfflineToggle != null)
			{
				loopOfflineToggle.removeEventListener(Event.CHANGE, onSettingsChanged);
				loopOfflineToggle.dispose();
				loopOfflineToggle = null;
			}
			
			if (instructionsTitleLabel != null)
			{
				instructionsTitleLabel.dispose();
				instructionsTitleLabel = null;
			}
			
			if (instructionsDescriptionLabel != null)
			{
				instructionsDescriptionLabel.dispose();
				instructionsDescriptionLabel = null;
			}
			
			if (userNameTextInput != null)
			{
				userNameTextInput.removeEventListener(Event.CHANGE, onUpdateSaveStatus);
				userNameTextInput.removeEventListener(FeathersEventType.FOCUS_OUT, onFocusOut);
				userNameTextInput.removeEventListener(FeathersEventType.ENTER, onEnterPressed);
				userNameTextInput.dispose();
				userNameTextInput = null;
			}
			
			if (passwordTextInput != null)
			{
				passwordTextInput.removeEventListener(Event.CHANGE, onUpdateSaveStatus);
				passwordTextInput.removeEventListener(FeathersEventType.FOCUS_OUT, onFocusOut);
				passwordTextInput.removeEventListener(FeathersEventType.ENTER, onEnterPressed);
				passwordTextInput.dispose();
				passwordTextInput = null;
			}
			
			super.dispose();
		}
	}
}