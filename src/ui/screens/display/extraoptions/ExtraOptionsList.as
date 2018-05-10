package ui.screens.display.extraoptions
{
	import com.freshplanet.ane.AirBackgroundFetch.BackgroundFetch;
	
	import flash.desktop.NativeApplication;
	import flash.desktop.SystemIdleMode;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.media.StageWebView;
	import flash.utils.Timer;
	
	import database.BlueToothDevice;
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
		
		/* Properties */
		private var speechEnabled:Boolean;
		private var listTextRenderers:Array;
		private var timeoutTimer:Timer;
		private var nightscoutEnabled:Boolean;
		
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
			
			/* Get Nightscout Setting from Database */
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_ON) == "true" && 
				CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_AZURE_WEBSITE_NAME) != "" && 
				CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_AZURE_WEBSITE_NAME) != "YOUR_SITE.azurewebsites.net" &&
				StageWebView.isSupported)
			{
				nightscoutEnabled = true;
			}
			else
				nightscoutEnabled = false;
			
			//Skin Speech Icon Accordingly
			buildSpeechIcon();
			
			//Skin No Lock Icon Accordingly
			buildNoLockIcon();
			
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
			menuItems.push({ label: ModelLocator.resourceManagerInstance.getString('chartscreen','speech_button_title'), icon: speechIconImage, id: menuItems.length, action: "enableSpeech" });
			if (BlueToothDevice.isMiaoMiao() && BlueToothDevice.known() && InterfaceController.peripheralConnected) menuItems.push({ label: "On-Demand", icon: readingOnDemandIconImage, id: menuItems.length, action: "readingOnDemand" });
			
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
				else if ( itemAction == "enableNoLock" ) //Speech
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
					BackgroundFetch.vibrate();
					
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
					if (BlueToothDevice.isMiaoMiao() && BlueToothDevice.known() && InterfaceController.peripheralConnected)
						BackgroundFetch.sendStartReadingCommmandToMiaoMia();
					
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
			
			if (!BackgroundFetch.appIsInForeground() || !Constants.appInForeground || !SystemUtil.isApplicationActive)
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
				noLockIconImage.dispose();
				noLockIconImage = null;
			}
			
			if (nightscoutScreenIconTexture != null)
			{
				nightscoutScreenIconTexture.dispose();
				nightscoutScreenIconTexture = null;;
			}
			
			if (nightscoutScreenIconImage != null)
			{
				nightscoutScreenIconImage.dispose();
				nightscoutScreenIconImage = null;;
			}
			
			if (glucoseScreenIconImage != null)
			{
				glucoseScreenIconImage.dispose();
				glucoseScreenIconImage = null;;
			}
			
			if (glucoseScreenIconTexture != null)
			{
				glucoseScreenIconTexture.dispose();
				glucoseScreenIconTexture = null;;
			}
			
			if (preSnoozeScreenIconImage != null)
			{
				preSnoozeScreenIconImage.dispose();
				preSnoozeScreenIconImage = null;;
			}
			
			if (preSnoozeScreenIconTexture != null)
			{
				preSnoozeScreenIconTexture.dispose();
				preSnoozeScreenIconTexture = null;;
			}
			
			if (readingOnDemandIconTexture != null)
			{
				readingOnDemandIconTexture.dispose();
				readingOnDemandIconTexture = null;;
			}
			
			if (readingOnDemandIconImage != null)
			{
				readingOnDemandIconImage.dispose();
				readingOnDemandIconImage = null;;
			}
			
			super.dispose();
		}
	}
}