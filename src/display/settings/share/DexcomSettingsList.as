package display.settings.share
{
	import flash.system.System;
	
	import databaseclasses.CommonSettings;
	
	import display.LayoutFactory;
	
	import feathers.controls.Button;
	import feathers.controls.List;
	import feathers.controls.PickerList;
	import feathers.controls.TextInput;
	import feathers.controls.ToggleSwitch;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.data.ArrayCollection;
	import feathers.events.FeathersEventType;
	import feathers.layout.HorizontalAlign;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import services.DexcomShareService;
	
	import starling.events.Event;
	
	import utils.Constants;
	
	[ResourceBundle("sharesettingsscreen")]

	public class DexcomSettingsList extends List 
	{
		/* Display Objects */
		private var dsUsername:TextInput;
		private var dsPassword:TextInput;
		private var dsLogin:Button;
		private var dsServer:PickerList;
		private var dsToggle:ToggleSwitch;
		
		/* Properties */
		public var needsSave:Boolean = false;
		private var isDexcomEnabled:Boolean;
		private var selectedUsername:String;
		private var selectedPassword:String;
		private var selectedServerCode:String;
		private var selectedServerIndex:int;
		
		public function DexcomSettingsList()
		{
			super();
		}
		override protected function initialize():void 
		{
			super.initialize();
			
			setupProperties();
			setupIntitialState();
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
		
		private function setupIntitialState():void
		{
			/* Get data from database */
			isDexcomEnabled = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEXCOM_SHARE_ON) == "true";
			selectedUsername = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEXCOM_SHARE_ACCOUNTNAME);
			selectedPassword = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEXCOM_SHARE_PASSWORD);
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEXCOM_SHARE_US_URL) == "true")
				selectedServerCode = "us";
			else
				selectedServerCode = "non-us"
		}
		
		public function save():void
		{
			//Dexcom Share
			var dexcomEnabledValue:String;
			
			if (isDexcomEnabled) dexcomEnabledValue = "true";
			else dexcomEnabledValue = "false";
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEXCOM_SHARE_ON) != isDexcomEnabled)
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_DEXCOM_SHARE_ON, dexcomEnabledValue);
			
			//Username
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEXCOM_SHARE_ACCOUNTNAME) != selectedUsername)
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_DEXCOM_SHARE_ACCOUNTNAME, selectedUsername);
			
			//Password
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEXCOM_SHARE_PASSWORD) != selectedPassword)
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_DEXCOM_SHARE_PASSWORD, selectedPassword);
			
			//Server
			var dexcomServerValue:String;
			
			if (selectedServerCode == "us") dexcomServerValue = "true";
			else dexcomServerValue = "false";
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEXCOM_SHARE_US_URL) != dexcomServerValue)
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_DEXCOM_SHARE_US_URL, dexcomServerValue);
			
			needsSave = false;
		}
		
		private function setupContent():void
		{
			//On/Off Toggle
			dsToggle = LayoutFactory.createToggleSwitch(isDexcomEnabled);
			dsToggle.addEventListener( Event.CHANGE, onDexcomShareOnOff );
			
			//Username
			dsUsername = LayoutFactory.createTextInput(false, false, 140, HorizontalAlign.RIGHT);
			dsUsername.text = selectedUsername;
			dsUsername.addEventListener( FeathersEventType.ENTER, onTextInputEnter );
			dsUsername.addEventListener(Event.CHANGE, onTextInputChanged);
			
			//Password
			dsPassword = LayoutFactory.createTextInput(true, false, 140, HorizontalAlign.RIGHT);
			dsPassword.text = selectedPassword;
			dsPassword.addEventListener( FeathersEventType.ENTER, onTextInputEnter );
			dsPassword.addEventListener(Event.CHANGE, onTextInputChanged);
			
			/* Server */
			dsServer = LayoutFactory.createPickerList();
			
			//Temp Data Objects
			var serversLabelsList:Array = ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','dexcom_share_server_name_list').split(",");
			var serversCodeList:Array = ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','dexcom_share_server_code_list').split(",");
			var dsServerList:ArrayCollection = new ArrayCollection();
			var dataLength:int = serversLabelsList.length;
			for (var i:int = 0; i < dataLength; i++) 
			{
				dsServerList.push({ label: serversLabelsList[i], code: serversCodeList[i] });
				if (selectedServerCode == serversCodeList[i])
					selectedServerIndex = i;
			}
			
			dsServer.labelField = "label";
			dsServer.dataProvider = dsServerList;
			dsServer.selectedIndex = selectedServerIndex;
			dsServer.addEventListener(Event.CHANGE, onServerChanged);
			
			//Login
			dsLogin = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','login_button_label'));
			dsLogin.addEventListener( Event.TRIGGERED, onDexcomShareLogin );
			
			//Set Item Renderer
			itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "label";
				itemRenderer.accessoryField = "accessory";
				return itemRenderer;
			};
			
			//Define Dexcom Share Settings Data
			reloadDexcomShareSettings(isDexcomEnabled);
		}
		
		private function onTextInputChanged(e:Event):void
		{
			//Update internal values
			selectedUsername = dsUsername.text;
			selectedPassword = dsPassword.text;
			
			needsSave = true;
		}
		
		private function onServerChanged(e:Event):void
		{
			selectedServerCode = dsServer.selectedItem.code;
			
			needsSave = true;
		}
		
		private function onTextInputEnter(event:Event):void
		{
			//Clear focus to dismiss the keyboard
			dsUsername.clearFocus();
			dsPassword.clearFocus();
		}
		
		private function onDexcomShareOnOff(event:Event):void
		{
			isDexcomEnabled = dsToggle.isSelected;
			
			reloadDexcomShareSettings(isDexcomEnabled);
			
			needsSave = true;
		}
		
		private function reloadDexcomShareSettings(fullDisplay:Boolean):void
		{
			if(fullDisplay)
			{
				dataProvider = new ArrayCollection(
					[
						{ label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','enabled_label'), accessory: dsToggle },
						{ label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','dexcom_share_username_label'), accessory: dsUsername },
						{ label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','dexcom_share_password_label'), accessory: dsPassword },
						{ label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','dexcom_share_server_label'), accessory: dsServer },
						{ label: "", accessory: dsLogin }
					]);
			}
			else
			{
				dataProvider = new ArrayCollection(
					[
						{ label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','enabled_label'), accessory: dsToggle }
					]);
			}
		}
		
		private function onDexcomShareLogin(event:Event):void
		{
			//Save values to database
			save();
			
			//Test Credentials
			DexcomShareService.testCredentials();
		}
		
		override public function dispose():void
		{
			if(dsUsername != null)
			{
				dsUsername.dispose();
				dsUsername = null;
			}
			if(dsPassword != null)
			{
				dsPassword.dispose();
				dsPassword = null;
			}
			if(dsLogin != null)
			{
				dsLogin.dispose();
				dsLogin = null;
			}
			if(dsServer != null)
			{
				dsServer.dispose();
				dsServer = null;
			}
			if(dsToggle != null)
			{
				dsToggle.dispose();
				dsToggle = null;
			}
			
			System.pauseForGCIfCollectionImminent(0);
			
			super.dispose();
		}
	}
}