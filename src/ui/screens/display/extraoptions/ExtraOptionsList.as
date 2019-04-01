package ui.screens.display.extraoptions
{
	import com.spikeapp.spike.airlibrary.SpikeANE;
	
	import flash.desktop.NativeApplication;
	import flash.desktop.SystemIdleMode;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.media.StageWebView;
	import flash.utils.Timer;
	
	import database.CGMBlueToothDevice;
	import database.CommonSettings;
	
	import events.SpikeEvent;
	
	import feathers.controls.List;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.data.ListCollection;
	import feathers.events.FeathersEventType;
	import feathers.layout.AnchorLayoutData;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalAlign;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.ModelLocator;
	
	import services.AlarmService;
	import services.NightscoutService;
	
	import starling.display.Image;
	import starling.events.Event;
	import starling.text.TextFormat;
	import starling.textures.Texture;
	import starling.utils.SystemUtil;
	
	import ui.AppInterface;
	import ui.InterfaceController;
	import ui.popups.AlarmPreSnoozer;
	import ui.screens.Screens;
	
	import utils.Constants;
	import utils.Trace;
	
	[ResourceBundle("chartscreen")]

	public class ExtraOptionsList extends List 
	{
		public static const CLOSE:String = "close";
		
		/* Display Objects */
		private var fullScreenIconTexture:Texture;
		private var fullScreenIconImage:Image;
		private var speechIconTexture:Texture;
		private var speechIconImage:Image;
		private var noLockIconTexture:Texture;
		private var noLockIconImage:Image;
		private var nightscoutScreenIconTexture:Texture;
		private var nightscoutScreenIconImage:Image;
		private var glucoseScreenIconTexture:Texture;
		private var glucoseScreenIconImage:Image;
		private var selectedFontTxtFormat:TextFormat;
		private var unselectedFontTxtFormat:TextFormat;
		private var preSnoozeScreenIconTexture:Texture;
		private var preSnoozeScreenIconImage:Image;
		private var readingOnDemandIconTexture:Texture;
		private var readingOnDemandIconImage:Image;
		private var noRotationIconTexture:Texture;
		private var noRotationIconImage:Image;
		
		/* Properties */
		private var speechEnabled:Boolean;
		private var listTextRenderers:Array;
		private var timeoutTimer:Timer;
		private var nightscoutEnabled:Boolean;
		private var preventRotationEnabled:Boolean;
		
		public function ExtraOptionsList()
		{
			super();
		}
		
		override protected function initialize():void 
		{
			super.initialize();
			
			setupProperties();
			setupInitialState();
		}
		
		/**
		 * Functinality
		 */
		private function setupProperties():void
		{
			/* Menu Properties */
			clipContent = false;
			isSelectable = true;
			autoHideBackground = true;
			hasElasticEdges = false;
			
			/* Internal Properties */
			selectedFontTxtFormat = new TextFormat("Roboto", 14, 0x0086ff, HorizontalAlign.LEFT, VerticalAlign.TOP);
			unselectedFontTxtFormat = new TextFormat("Roboto", 14, 15658734, HorizontalAlign.LEFT, VerticalAlign.TOP);
			timeoutTimer = new Timer(5 * 1000);
			timeoutTimer.addEventListener(TimerEvent.TIMER, onTimeoutActivated, false, 0, true);
		}
		
		private function setupInitialState():void
		{
			/* Get Speech Setting from Database */
			speechEnabled = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SPEAK_READINGS_ON) == "true";
			
			/* Get Rotation Setting from Database */
			preventRotationEnabled = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PREVENT_SCREEN_ROTATION_ON) == "true";
			
			/* Get Nightscout Setting from Database */
			nightscoutEnabled = (NightscoutService.serviceActive || (NightscoutService.followerModeEnabled && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FOLLOWER_MODE) == "Nightscout")) && StageWebView.isSupported ? true : false;
			
			//Skin Speech Icon Accordingly
			buildSpeechIcon();
			
			//Skin No Lock Icon Accordingly
			buildNoLockIcon();
			
			//Skin No Rotation Icon Accordingly
			buildNoRotationIcon();
			
			//Build Menu Content
			setupContent();
			
			//Event Listeners
			addEventListener(FeathersEventType.CREATION_COMPLETE, onCreationComplete);
			Spike.instance.addEventListener(SpikeEvent.APP_IN_FOREGROUND, onApplicationActivated, false, 0, true);
		}
		
		private function setupContent():void
		{
			//Glucose Management  Icon 
			glucoseScreenIconTexture = MaterialDeepGreyAmberMobileThemeIcons.readingsTexture;
			glucoseScreenIconImage = new Image(glucoseScreenIconTexture);
			
			//Setup Fullscreen Icon 
			fullScreenIconTexture = MaterialDeepGreyAmberMobileThemeIcons.fullscreenTexture;
			fullScreenIconImage = new Image(fullScreenIconTexture);
			
			//Nightscout Icon
			nightscoutScreenIconTexture = MaterialDeepGreyAmberMobileThemeIcons.nightscoutTexture;
			nightscoutScreenIconImage = new Image(nightscoutScreenIconTexture);
			
			//Pre-snooze Icon
			preSnoozeScreenIconTexture = MaterialDeepGreyAmberMobileThemeIcons.snoozeTexture;
			preSnoozeScreenIconImage = new Image(preSnoozeScreenIconTexture);
			
			//Reading On-Demand Icon
			readingOnDemandIconTexture = MaterialDeepGreyAmberMobileThemeIcons.readingOnDemandTexture;
			readingOnDemandIconImage = new Image(readingOnDemandIconTexture);
			
			//Build Menu
			buildListLayout();
			
			//Define Menu Renderer
			listTextRenderers = [];
			itemRendererFactory = function():IListItemRenderer 
			{
				var item:DefaultListItemRenderer = new DefaultListItemRenderer();
				item.labelField = "label";
				item.iconField = "icon";
				item.gap = 5;
				item.paddingLeft = 8;
				item.paddingRight = 14;
				item.isQuickHitAreaEnabled = true;
				
				//Save for later (needed to change label's color on the fly
				listTextRenderers.push(item);
				
				return item;
			};
			layoutData = new AnchorLayoutData( 0, 0, 0, 0 );
			
			//Event Listeners
			addEventListener( starling.events.Event.CHANGE, onMenuChanged );
		}
		
		private function buildListLayout():void
		{
			var menuItems:Array = [];
			menuItems.push({ label: ModelLocator.resourceManagerInstance.getString('chartscreen','manage_readings_button_title'), icon: glucoseScreenIconImage, id: menuItems.length, action: "manageGlucose" });
			if (nightscoutEnabled) menuItems.push({ label: ModelLocator.resourceManagerInstance.getString('chartscreen','nightscout_button_title'), icon: nightscoutScreenIconImage, id: menuItems.length, action: "nightscoutView" });
			menuItems.push({ label: ModelLocator.resourceManagerInstance.getString('chartscreen','full_screen_button_title'), icon: fullScreenIconImage, id: menuItems.length, action: "showFullScreen" });
			menuItems.push({ label: ModelLocator.resourceManagerInstance.getString('chartscreen','snoozer_button_title'), icon: preSnoozeScreenIconImage, id: menuItems.length, action: "preSnooze" });
			menuItems.push({ label: ModelLocator.resourceManagerInstance.getString('chartscreen','no_lock_button_title'), icon: noLockIconImage, id: menuItems.length, action: "enableNoLock" });
			menuItems.push({ label: ModelLocator.resourceManagerInstance.getString('chartscreen','no_rotation_button_title'), icon: noRotationIconImage, id: menuItems.length, action: "enableNoRotation" });
			menuItems.push({ label: ModelLocator.resourceManagerInstance.getString('chartscreen','speech_button_title'), icon: speechIconImage, id: menuItems.length, action: "enableSpeech" });
			if (CGMBlueToothDevice.isMiaoMiao() && CGMBlueToothDevice.known() && InterfaceController.peripheralConnected) menuItems.push({ label: ModelLocator.resourceManagerInstance.getString('chartscreen','readings_on_demand_button_title'), icon: readingOnDemandIconImage, id: menuItems.length, action: "readingOnDemand" });
			
			dataProvider = new ListCollection(menuItems);
		}
		
		private function buildSpeechIcon():void
		{
			if(speechIconTexture != null)
			{
				speechIconTexture.dispose();
				speechIconTexture = null;
			}
			
			if (speechEnabled)
				speechIconTexture = MaterialDeepGreyAmberMobileThemeIcons.phoneSpeakerEnabledTexture;
			else
				speechIconTexture = MaterialDeepGreyAmberMobileThemeIcons.phoneSpeakerTexture;
			
			speechIconImage = new Image(speechIconTexture);
		}
		
		private function buildNoLockIcon():void
		{
			if(noLockIconTexture != null)
			{
				noLockIconTexture.dispose();
				noLockIconTexture = null;
			}
			
			if (Constants.noLockEnabled)
				noLockIconTexture = MaterialDeepGreyAmberMobileThemeIcons.iPhoneLockEnabledTexture;
			else
				noLockIconTexture = MaterialDeepGreyAmberMobileThemeIcons.iPhoneLockDisabledTexture;
			
			noLockIconImage = new Image(noLockIconTexture);
		}
		
		private function buildNoRotationIcon():void
		{
			//No Roation
			if(noRotationIconTexture != null)
			{
				noRotationIconTexture.dispose();
				noRotationIconTexture = null;
			}
			
			if (preventRotationEnabled)
				noRotationIconTexture = MaterialDeepGreyAmberMobileThemeIcons.noRotationEnabledTexture;
			else
				noRotationIconTexture = MaterialDeepGreyAmberMobileThemeIcons.noRotationDisabledTexture;
			
			noRotationIconImage = new Image(noRotationIconTexture);
		}
		
		/**
		 * Event Handlers
		 */
		private function onCreationComplete():void
		{
			var menuItem:Object;
			var i:int = 0
			
			//Skin Speech Label
			if(speechEnabled)
			{
				for (i = 0; i < dataProvider.length; i++) 
				{
					menuItem = dataProvider.getItemAt(i);
					if (menuItem.action == "enableSpeech")
					{
						(listTextRenderers[i] as DefaultListItemRenderer).fontStyles = selectedFontTxtFormat;
						break;
					}
				}	
			}
			
			//Skin No Lock Label
			if(Constants.noLockEnabled)
			{
				for (i = 0; i < dataProvider.length; i++) 
				{
					menuItem = dataProvider.getItemAt(i);
					if (menuItem.action == "enableNoLock")
					{
						(listTextRenderers[i] as DefaultListItemRenderer).fontStyles = selectedFontTxtFormat;
						break;
					}
				}	
			}
			
			//Skin Rotation Label
			if(preventRotationEnabled)
			{
				for (i = 0; i < dataProvider.length; i++) 
				{
					menuItem = dataProvider.getItemAt(i);
					if (menuItem.action == "enableNoRotation")
					{
						(listTextRenderers[i] as DefaultListItemRenderer).fontStyles = selectedFontTxtFormat;
						break;
					}
				}	
			}
		}
		
		private function onMenuChanged(e:starling.events.Event):void 
		{
			if(selectedItem != null)
			{
				const itemID:Number = selectedItem.id as Number;
				const itemAction:String = selectedItem.action as String;
				
				if ( itemAction == "showFullScreen" ) 
				{
					dispatchEventWith(CLOSE); //Close Menu
					
					AppInterface.instance.navigator.pushScreen( Screens.FULLSCREEN_GLUCOSE ); //Push Fullscreen Glucose Screen
				}
				else if ( itemAction == "enableSpeech" ) //Speech
				{
					if (!speechEnabled)
					{
						speechEnabled = true;
						
						//Skin Label
						(listTextRenderers[itemID] as DefaultListItemRenderer).fontStyles = selectedFontTxtFormat;
						
						//Update Database
						CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_SPEAK_READINGS_ON, "true");
					}
					else if (speechEnabled)
					{
						speechEnabled = false;
						
						//Skin Label
						(listTextRenderers[itemID] as DefaultListItemRenderer).fontStyles = unselectedFontTxtFormat;
						
						//Update Database
						CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_SPEAK_READINGS_ON, "false");
					}
					
					//Build Speech Icon
					buildSpeechIcon();
					
					//Refresh Layout
					buildListLayout();
					
					//Activate the close timer
					if (timeoutTimer.running)
						timeoutTimer.stop();
					timeoutTimer.start();
				}
				else if ( itemAction == "enableNoLock" ) //Lock
				{	
					if (!Constants.noLockEnabled)
					{
						Constants.noLockEnabled = true;
						
						//Skin Label
						(listTextRenderers[itemID] as DefaultListItemRenderer).fontStyles = selectedFontTxtFormat;
						
						//Activate Keep Awake
						NativeApplication.nativeApplication.systemIdleMode = SystemIdleMode.KEEP_AWAKE;
						Trace.myTrace("ExtraOptionsList.as", "In onMenuChanged, setting systemIdleMode = SystemIdleMode.KEEP_AWAKE");
					}
					else if (Constants.noLockEnabled)
					{
						Constants.noLockEnabled = false;
						
						//Skin Label
						(listTextRenderers[itemID] as DefaultListItemRenderer).fontStyles = unselectedFontTxtFormat;
						
						//Deactivate Keep Awake
						NativeApplication.nativeApplication.systemIdleMode = SystemIdleMode.NORMAL;
						Trace.myTrace("ExtraOptionsList.as", "In onMenuChanged, setting systemIdleMode = SystemIdleMode.NORMAL");
					}
					
					//Build No Lock Icon
					buildNoLockIcon();
					
					//Refresh Layout
					buildListLayout();
					
					//Vibrate Device
					SpikeANE.vibrate();
					
					//Activate the close timer
					if (timeoutTimer.running)
						timeoutTimer.stop();
					timeoutTimer.start();
				}
				else if ( itemAction == "enableNoRotation" ) //Rotation
				{	
					preventRotationEnabled = !preventRotationEnabled;
					
					//Skin Label
					(listTextRenderers[itemID] as DefaultListItemRenderer).fontStyles = preventRotationEnabled ? selectedFontTxtFormat : unselectedFontTxtFormat;
					
					Constants.appStage.autoOrients = !preventRotationEnabled;
					
					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_PREVENT_SCREEN_ROTATION_ON, String(preventRotationEnabled));
					
					//Build No Lock Icon
					buildNoRotationIcon();
					
					//Refresh Layout
					buildListLayout();
					
					//Activate the close timer
					if (timeoutTimer.running)
						timeoutTimer.stop();
					timeoutTimer.start();
				}
				else if ( itemAction == "nightscoutView" ) 
				{
					dispatchEventWith(CLOSE); //Close Menu
					
					AppInterface.instance.navigator.pushScreen( Screens.NIGHTSCOUT_VIEW ); //Push Fullscreen Glucose Screen
				}
				else if ( itemAction == "manageGlucose" ) 
				{
					dispatchEventWith(CLOSE); //Close Menu
					
					AppInterface.instance.navigator.pushScreen( Screens.GLUCOSE_MANAGEMENT ); //Push Glucose Management
				}
				else if ( itemAction == "preSnooze" ) 
				{	
					dispatchEventWith(CLOSE); //Close Menu
					
					AlarmPreSnoozer.displaySnoozer(ModelLocator.resourceManagerInstance.getString('chartscreen','snoozer_popup_title'), AlarmService.snoozeValueStrings);	
				}
				else if ( itemAction == "readingOnDemand" ) 
				{	
					if (CGMBlueToothDevice.isMiaoMiao() && CGMBlueToothDevice.known() && InterfaceController.peripheralConnected)
						SpikeANE.sendStartReadingCommmandToMiaoMia();
					
					dispatchEventWith(CLOSE); //Close Menu
				}
			}
		}
		
		private function onApplicationActivated(e:flash.events.Event):void
		{
			//If the menu was opened when the app resumed and the no lock button was activated, we deactivate it.
			//Reset the icon color
			buildNoLockIcon();
			
			//Reset the label color
			try
			{
				var menuItem:Object;
				for (var i:int = 0; i < dataProvider.length; i++) 
				{
					menuItem = dataProvider.getItemAt(i);
					if (menuItem.action == "enableNoLock")
					{
						(listTextRenderers[i] as DefaultListItemRenderer).fontStyles = unselectedFontTxtFormat;
						break;
					}
				}	
			} catch(error:Error) {}
			
			//Refresh menu layout
			buildListLayout();
		}
		
		private function onTimeoutActivated(e:TimerEvent):void
		{
			dispatchEventWith(CLOSE);
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			removeEventListener(FeathersEventType.CREATION_COMPLETE, onCreationComplete);
			Spike.instance.removeEventListener(SpikeEvent.APP_IN_FOREGROUND, onApplicationActivated);
			removeEventListener( starling.events.Event.CHANGE, onMenuChanged );
			
			if (timeoutTimer != null)
			{
				timeoutTimer.stop();
				timeoutTimer.removeEventListener(TimerEvent.TIMER, onTimeoutActivated);
				timeoutTimer = null;
			}
			
			if (!SpikeANE.appIsInForeground() || !Constants.appInForeground || !SystemUtil.isApplicationActive)
			{
				return;
			}
			
			if (fullScreenIconTexture != null)
			{
				fullScreenIconTexture.dispose();
				fullScreenIconTexture = null;
			}
			
			if (fullScreenIconImage != null)
			{
				if (fullScreenIconImage.texture != null)
					fullScreenIconImage.texture.dispose();
				fullScreenIconImage.dispose();
				fullScreenIconImage = null;
			}
			
			if (speechIconTexture != null)
			{
				speechIconTexture.dispose();
				speechIconTexture = null;
			}
			
			if (speechIconImage != null)
			{
				if (speechIconImage.texture != null)
					speechIconImage.texture.dispose();
				speechIconImage.dispose();
				speechIconImage = null;
			}
			
			if (noLockIconTexture != null)
			{
				noLockIconTexture.dispose();
				noLockIconTexture = null;
			}
			
			if (noLockIconImage != null)
			{
				if (noLockIconImage.texture != null)
					noLockIconImage.texture.dispose();
				noLockIconImage.dispose();
				noLockIconImage = null;
			}
			
			if (nightscoutScreenIconTexture != null)
			{
				nightscoutScreenIconTexture.dispose();
				nightscoutScreenIconTexture = null;
			}
			
			if (nightscoutScreenIconImage != null)
			{
				if (nightscoutScreenIconImage.texture != null)
					nightscoutScreenIconImage.texture.dispose();
				nightscoutScreenIconImage.dispose();
				nightscoutScreenIconImage = null;
			}
			
			if (glucoseScreenIconTexture != null)
			{
				glucoseScreenIconTexture.dispose();
				glucoseScreenIconTexture = null;
			}
			
			if (glucoseScreenIconImage != null)
			{
				if (glucoseScreenIconImage.texture != null)
					glucoseScreenIconImage.texture.dispose();
				glucoseScreenIconImage.dispose();
				glucoseScreenIconImage = null;
			}
			
			if (preSnoozeScreenIconTexture != null)
			{
				preSnoozeScreenIconTexture.dispose();
				preSnoozeScreenIconTexture = null;
			}
			
			if (preSnoozeScreenIconImage != null)
			{
				if (preSnoozeScreenIconImage.texture != null)
					preSnoozeScreenIconImage.texture.dispose();
				preSnoozeScreenIconImage.dispose();
				preSnoozeScreenIconImage = null;
			}
			
			if (readingOnDemandIconTexture != null)
			{
				readingOnDemandIconTexture.dispose();
				readingOnDemandIconTexture = null;
			}
			
			if (readingOnDemandIconImage != null)
			{
				if (readingOnDemandIconImage.texture != null)
					readingOnDemandIconImage.texture.dispose();
				readingOnDemandIconImage.dispose();
				readingOnDemandIconImage = null;
			}
			
			if (noRotationIconImage != null)
			{
				if (noRotationIconImage.texture != null)
					noRotationIconImage.texture.dispose();
				noRotationIconImage.dispose();
				noRotationIconImage = null;
			}
			
			if (noRotationIconTexture != null)
			{
				noRotationIconTexture.dispose();
				noRotationIconTexture = null;
			}
			
			super.dispose();
		}
	}
}