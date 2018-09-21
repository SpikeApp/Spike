package ui.screens.display.settings.general
{
	import com.adobe.utils.StringUtil;
	
	import flash.display.StageOrientation;
	
	import cryptography.Keys;
	
	import database.CommonSettings;
	
	import feathers.controls.Button;
	import feathers.controls.Label;
	import feathers.controls.NumericStepper;
	import feathers.controls.PickerList;
	import feathers.controls.TextInput;
	import feathers.controls.popups.DropDownPopUpContentManager;
	import feathers.data.ArrayCollection;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalLayout;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import network.NetworkConnector;
	
	import services.NightscoutService;
	
	import starling.events.Event;
	import starling.events.ResizeEvent;
	
	import treatments.TreatmentsManager;
	
	import ui.AppInterface;
	import ui.screens.display.LayoutFactory;
	import ui.screens.display.SpikeList;
	
	import utils.Constants;
	import utils.Cryptography;
	import utils.DeviceInfo;
	
	[ResourceBundle("generalsettingsscreen")]
	[ResourceBundle("sharesettingsscreen")]

	public class DataCollectionSettingsList extends SpikeList 
	{
		/* Display Objects */
		private var collectionModePicker:PickerList;
		private var nightscoutURLInput:TextInput;
		private var nightscoutOffsetStepper:NumericStepper;
		private var nightscoutAPISecretTextInput:TextInput;
		private var nightscoutAPIDescription:Label;
		private var nsLogin:Button;
		
		/* Properties */
		public var needsSave:Boolean = false;
		private var collectionMode:String;		
		private var followNSURL:String;
		private var nightscoutOffset:Number;
		private var nightscoutAPISecretValue:String;
		
		public function DataCollectionSettingsList()
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
			collectionMode = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_MODE);
			followNSURL = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_URL);
			nightscoutOffset = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_OFFSET));
			nightscoutAPISecretValue = Cryptography.decryptStringLight(Keys.STRENGTH_256_BIT, CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_API_SECRET));
		}
		
		private function setupContent():void
		{
			//Collection Picker List
			collectionModePicker = LayoutFactory.createPickerList();
			
			/* Set DateFormatPicker Data */
			var collectionModesLabelsList:Array = ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','collection_list').split(",");
			var collectionModestList:ArrayCollection = new ArrayCollection();
			for (var i:int = 0; i < collectionModesLabelsList.length; i++) 
			{
				collectionModestList.push({label: StringUtil.trim(collectionModesLabelsList[i]), id: i});
			}
			collectionModesLabelsList.length = 0;
			collectionModesLabelsList = null;
			collectionModePicker.labelField = "label";
			collectionModePicker.popUpContentManager = new DropDownPopUpContentManager();
			collectionModePicker.dataProvider = collectionModestList;
			var selectedModeIndex:int;
			if (collectionMode == "Host")
				selectedModeIndex = 0;
			else if (collectionMode == "Follower")
				selectedModeIndex = 1;
			collectionModePicker.selectedIndex = selectedModeIndex;
			collectionModePicker.addEventListener(Event.CHANGE, onCollectionModeChanged);
			
			//Nightscout URL
			nightscoutURLInput = LayoutFactory.createTextInput(false, false, Constants.isPortrait ? 140 : 240, HorizontalAlign.RIGHT, false, false, true);
			if (DeviceInfo.isTablet()) nightscoutURLInput.width += 100;
			nightscoutURLInput.fontStyles.size = 10;
			nightscoutURLInput.text = followNSURL;
			nightscoutURLInput.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Nightscout Offset Stepper
			nightscoutOffsetStepper = LayoutFactory.createNumericStepper(-10000, 10000, nightscoutOffset, 5); 
			nightscoutOffsetStepper.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//API Secret
			nightscoutAPISecretTextInput = LayoutFactory.createTextInput(true, false, Constants.isPortrait ? 140 : 240, HorizontalAlign.RIGHT);
			nightscoutAPISecretTextInput.text = nightscoutAPISecretValue;
			if (DeviceInfo.isTablet()) nightscoutAPISecretTextInput.width += 100;
			nightscoutAPISecretTextInput.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//NS Login
			nsLogin = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','login_button_label'))
			nsLogin.addEventListener(Event.TRIGGERED, onNightscoutLogin);
			
			//API Secret Description
			nightscoutAPIDescription = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','api_secret_description'), HorizontalAlign.JUSTIFY);
			nightscoutAPIDescription.wordWrap = true;
			nightscoutAPIDescription.width = width;
			nightscoutAPIDescription.paddingTop = nightscoutAPIDescription.paddingBottom = 10;
			
			refreshContent();
		}
		
		private function refreshContent():void
		{
			var data:Array = [];
			data.push( { label: ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','mode_label'), accessory: collectionModePicker } );
			if (collectionMode == "Follower")
			{
				data.push( { label: ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','follower_ns_url'), accessory: nightscoutURLInput } );
				data.push( { label: ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','time_offset'), accessory: nightscoutOffsetStepper } );
				data.push( { label: ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','api_secret'), accessory: nightscoutAPISecretTextInput } );
				data.push( { label: "", accessory: nsLogin } );
				data.push( { label:"", accessory: nightscoutAPIDescription } );
			}
			
			dataProvider = new ArrayCollection(data);
		}
		
		public function save():void
		{
			//Update Database
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_MODE) != collectionMode)
			{
				//Reset Nightscout eTag to force refresh
				NetworkConnector.nightscoutTreatmentsLastModifiedHeader = "";
				TreatmentsManager.nightscoutTreatmentsLastModifiedHeader = "";
					
				//Update Database
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_MODE, collectionMode);
				if (collectionMode == "Follower")
					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_PERIPHERAL_TYPE, "Follow");
				else if (collectionMode == "Host")
				{
					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_PERIPHERAL_TYPE, "");
					
					//Force fetching readings and treatments from database for master.
					ModelLocator.getMasterReadings();
					TreatmentsManager.fetchAllTreatmentsFromDatabase();
				}
			}
			
			//URL Validation
			if (followNSURL.substr(-1) == "/")
			{
				followNSURL = followNSURL.slice(0, -1);
				nightscoutURLInput.text = followNSURL;
			}
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_URL) != followNSURL)
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_URL, followNSURL);
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_OFFSET) != String(nightscoutOffset))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_OFFSET, String(nightscoutOffset));
			
			var apiSecretToSave:String = Cryptography.encryptStringLight(Keys.STRENGTH_256_BIT, String(nightscoutAPISecretValue));
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_API_SECRET) != apiSecretToSave)
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_API_SECRET, apiSecretToSave);
			
			//Refresh main menu. Menu items are different for hosts and followers
			AppInterface.instance.menu.refreshContent();
			
			needsSave = false;
		}
		
		/**
		 * Event Listeners
		 */
		private function onCollectionModeChanged(e:Event):void
		{
			//Update internal variables
			if (collectionModePicker.selectedIndex == 0)
				collectionMode = "Host";
			else if (collectionModePicker.selectedIndex == 1)
				collectionMode = "Follower";
			
			needsSave = true;
			
			refreshContent();
		}
		
		private function onSettingsChanged(e:Event):void
		{
			followNSURL = nightscoutURLInput.text.replace(" ", "");
			nightscoutOffset = nightscoutOffsetStepper.value;
			nightscoutAPISecretValue = nightscoutAPISecretTextInput.text.replace(" ", "");
			nsLogin.isEnabled = nightscoutAPISecretValue.length == 0 ? false : true;
			
			needsSave = true;
		}
		
		private function onNightscoutLogin(event:Event):void
		{
			//Workaround so the NightscoutService doesn't test credentials twice
			NightscoutService.ignoreSettingsChanged = true;
			
			//Save values to database
			save();
			
			//Test Credentials
			NightscoutService.testNightscoutCredentialsFollower();
			NightscoutService.ignoreSettingsChanged = false;
			
			//Clear URL so it forces a save again and restart service
			CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_URL, "");
			needsSave = true;
		}
		
		/**
		 * Utility
		 */
		override protected function draw():void
		{
			super.draw();
			
			if ((layout as VerticalLayout) != null)
				(layout as VerticalLayout).hasVariableItemDimensions = true;
			
			if (nsLogin != null && nightscoutAPISecretTextInput != null)
				nsLogin.isEnabled = nightscoutAPISecretTextInput.text.length == 0 ? false : true;
		}
		
		/**
		 * Event Listeners
		 */
		override protected function onStarlingResize(event:ResizeEvent):void 
		{
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
			
			if (nightscoutURLInput != null)
			{
				nightscoutURLInput.width = Constants.isPortrait ? 140 : 240;
				if (DeviceInfo.isTablet()) nightscoutURLInput.width += 100;
			}
			
			if (nightscoutAPISecretTextInput != null)
			{
				nightscoutAPISecretTextInput.width = Constants.isPortrait ? 140 : 240;
				if (DeviceInfo.isTablet()) nightscoutAPISecretTextInput.width += 100;
			}
			
			if (nightscoutAPIDescription != null)
			{
				if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr && !Constants.isPortrait)
					nightscoutAPIDescription.width = width - (Constants.currentOrientation == StageOrientation.ROTATED_RIGHT ? 30 : 40);
				else
					nightscoutAPIDescription.width = width;
			}
			
			setupRenderFactory();
		}
		
		override public function dispose():void
		{
			if (collectionModePicker != null)
			{
				collectionModePicker.removeEventListener(Event.CHANGE, onCollectionModeChanged);
				collectionModePicker.dispose();
				collectionModePicker = null;
			}
			
			if (nightscoutURLInput != null)
			{
				nightscoutURLInput.removeEventListener(Event.CHANGE, onSettingsChanged);
				nightscoutURLInput.dispose();
				nightscoutURLInput = null;
			}
			
			if (nightscoutOffsetStepper != null)
			{
				nightscoutOffsetStepper.removeEventListener(Event.CHANGE, onSettingsChanged);
				nightscoutOffsetStepper.dispose();
				nightscoutOffsetStepper = null;
			}
			
			if (nightscoutAPISecretTextInput != null)
			{
				nightscoutAPISecretTextInput.removeEventListener(Event.CHANGE, onSettingsChanged);
				nightscoutAPISecretTextInput.dispose();
				nightscoutAPISecretTextInput = null;
			}
			
			if (nsLogin != null)
			{
				nsLogin.removeEventListener(Event.TRIGGERED, onNightscoutLogin);
				nsLogin.dispose();
				nsLogin = null;
			}
			
			if (nightscoutAPIDescription != null)
			{
				nightscoutAPIDescription.dispose();
				nightscoutAPIDescription = null;
			}
			
			super.dispose();
		}
	}
}