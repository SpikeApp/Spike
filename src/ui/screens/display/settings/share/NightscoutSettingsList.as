package ui.screens.display.settings.share
{
	import database.CommonSettings;
	
	import feathers.controls.Button;
	import feathers.controls.List;
	import feathers.controls.TextInput;
	import feathers.controls.ToggleSwitch;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.data.ArrayCollection;
	import feathers.events.FeathersEventType;
	import feathers.layout.HorizontalAlign;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import services.NightscoutService;
	
	import starling.core.Starling;
	import starling.events.Event;
	import starling.events.ResizeEvent;
	import starling.utils.SystemUtil;
	
	import ui.screens.display.LayoutFactory;
	
	import utils.Constants;
	import utils.DeviceInfo;
	
	[ResourceBundle("sharesettingsscreen")]
	[ResourceBundle("globaltranslations")]

	public class NightscoutSettingsList extends List 
	{
		/* Display Objects */
		private var nsToggle:ToggleSwitch;
		private var nsURL:TextInput;
		private var nsAPISecret:TextInput;
		private var nsLogin:Button;
		
		/* Properties */
		public var needsSave:Boolean = false;
		private var isNSEnabled:Boolean;
		private var selectedURL:String;
		private var selectedAPISecret:String;
		
		public function NightscoutSettingsList()
		{
			super();
		}
		override protected function initialize():void 
		{
			super.initialize();
			
			Starling.current.stage.addEventListener(starling.events.Event.RESIZE, onStarlingResize);
			
			setupProperties();
			setupInitialState();
			setupContent();
		}
		
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
			/* Get data from database */
			isNSEnabled = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_ON) == "true";
			selectedURL = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_AZURE_WEBSITE_NAME);
			selectedAPISecret = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_API_SECRET);
		}
		
		private function setupContent():void
		{
			//On/Off Toggle
			nsToggle = LayoutFactory.createToggleSwitch(isNSEnabled);
			nsToggle.addEventListener( Event.CHANGE, onNightscoutOnOff );
			
			//URL
			nsURL = LayoutFactory.createTextInput(false, false, Constants.deviceModel == DeviceInfo.IPHONE_X ? 190 : 220, HorizontalAlign.RIGHT);
			if (!Constants.isPortrait)
				nsURL.width += 100;
			nsURL.text = selectedURL;
			nsURL.prompt = "yoursite.example.com";
			nsURL.addEventListener( FeathersEventType.ENTER, onTextInputEnter );
			nsURL.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//API Secret
			nsAPISecret = LayoutFactory.createTextInput(true, false, Constants.deviceModel == DeviceInfo.IPHONE_X ? 120 : 140, HorizontalAlign.RIGHT);
			if (!Constants.isPortrait)
				nsAPISecret.width += 100;
			nsAPISecret.text = selectedAPISecret;
			nsAPISecret.addEventListener( FeathersEventType.ENTER, onTextInputEnter );
			nsAPISecret.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Login
			nsLogin = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','login_button_label'));
			nsLogin.pivotX = -3;
			nsLogin.addEventListener(Event.TRIGGERED, onNightscoutLogin);
			
			//Set Item Renderer
			itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "label";
				itemRenderer.accessoryField = "accessory";
				return itemRenderer;
			};
			
			//Define Nightscout Settings Data
			reloadNightscoutSettings(nsToggle.isSelected);
		}
		
		public function save():void
		{
			if (needsSave)
			{
				var needsCredentialRechek:Boolean = false;
				
				//Nightscout
				var nsEnabledValue:String;
				
				if (isNSEnabled) nsEnabledValue = "true";
				else nsEnabledValue = "false";
				
				if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_ON) != nsEnabledValue)
					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_ON, nsEnabledValue);
				
				//API Secret
				if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_API_SECRET) != selectedAPISecret)
				{
					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_API_SECRET, selectedAPISecret);
					needsCredentialRechek = true;
				}
				
				//URL
				if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_AZURE_WEBSITE_NAME) != selectedURL)
				{
					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_AZURE_WEBSITE_NAME, selectedURL);
					needsCredentialRechek = true;
				}
				
				//Credentials Recheck
				if (needsCredentialRechek)
					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_URL_AND_API_SECRET_TESTED, "false");
				
				needsSave = false;
			}
		}
		
		private function onSettingsChanged():void
		{
			selectedAPISecret = nsAPISecret.text.replace(" ", "");
			nsURL.text = nsURL.text.replace(" ", "");
			selectedURL = nsURL.text.replace(" ", "");
			
			needsSave = true;
		}
		
		private function onNightscoutOnOff(event:Event):void
		{
			isNSEnabled = nsToggle.isSelected;
			
			reloadNightscoutSettings(isNSEnabled);
			
			needsSave = true;
		}
		
		private function reloadNightscoutSettings(fullDisplay:Boolean):void
		{
			if(fullDisplay)
			{
				dataProvider = new ArrayCollection(
					[
						{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations','enabled_label'), accessory: nsToggle },
						{ label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','nightscout_url_label'), accessory: nsURL },
						{ label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','nightscout_api_label'), accessory: nsAPISecret },
						{ label: "", accessory: nsLogin },
					]);
			}
			else
			{
				dataProvider = new ArrayCollection(
					[
						{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations','enabled_label'), accessory: nsToggle },
					]);
			}
		}
		
		private function onTextInputEnter(event:Event):void
		{
			//Clear focus to dismiss the keyboard
			nsURL.clearFocus();
			nsAPISecret.clearFocus();
		}
		
		private function onNightscoutLogin(event:Event):void
		{
			//Workaround so the NightscoutService doesn't test credentials twice
			NightscoutService.ignoreSettingsChanged = true;
			
			//Save values to database
			save();
			
			//Test Credentials
			NightscoutService.testNightscoutCredentials(true);
			NightscoutService.ignoreSettingsChanged = false;
		}
		
		private function onStarlingResize(event:ResizeEvent):void 
		{
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
			
			if (nsURL != null)
			{
				SystemUtil.executeWhenApplicationIsActive( nsURL.clearFocus );
				nsURL.width = Constants.deviceModel == DeviceInfo.IPHONE_X ? 190 : 220;
				if (!Constants.isPortrait)
					nsURL.width += 100;
			}
			
			if (nsAPISecret != null)
			{
				SystemUtil.executeWhenApplicationIsActive( nsAPISecret.clearFocus );
				nsAPISecret.width = Constants.deviceModel == DeviceInfo.IPHONE_X ? 120 : 140;
				if (!Constants.isPortrait)
					nsAPISecret.width += 100;
			}
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			Starling.current.stage.removeEventListener(starling.events.Event.RESIZE, onStarlingResize);
			
			if(nsToggle != null)
			{
				nsToggle.removeEventListener( Event.CHANGE, onNightscoutOnOff );
				nsToggle.dispose();
				nsToggle = null;
			}
			if(nsURL != null)
			{
				nsURL.removeEventListener( FeathersEventType.ENTER, onTextInputEnter );
				nsURL.removeEventListener(Event.CHANGE, onSettingsChanged);
				nsURL.dispose();
				nsURL = null;
			}
			if(nsAPISecret != null)
			{
				nsAPISecret.removeEventListener( FeathersEventType.ENTER, onTextInputEnter );
				nsAPISecret.removeEventListener(Event.CHANGE, onSettingsChanged);
				nsAPISecret.dispose();
				nsAPISecret = null;
			}
			if(nsLogin != null)
			{
				nsLogin.removeEventListener(Event.TRIGGERED, onNightscoutLogin);
				nsLogin.dispose();
				nsLogin = null;
			}
			
			super.dispose();
		}
	}
}