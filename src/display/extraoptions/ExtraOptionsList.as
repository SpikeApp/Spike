package display.extraoptions
{
	import com.freshplanet.ane.AirBackgroundFetch.BackgroundFetch;
	
	import flash.desktop.NativeApplication;
	import flash.desktop.SystemIdleMode;
	import flash.events.Event;
	import flash.system.System;
	
	import Utilities.Trace;
	
	import databaseclasses.CommonSettings;
	
	import events.IosXdripReaderEvent;
	
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
	
	import screens.Screens;
	
	import starling.display.Image;
	import starling.events.Event;
	import starling.text.TextFormat;
	import starling.textures.Texture;
	
	import ui.AppInterface;
	
	import utils.Constants;
	
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
		private var selectedFontTxtFormat:TextFormat;
		private var unselectedFontTxtFormat:TextFormat;
		
		/* Properties */
		private var speechEnabled:Boolean;
		private var listTextRenderers:Array;
		
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
		}
		
		private function setupInitialState():void
		{
			/* Get Speech Setting from Database */
			speechEnabled = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SPEAK_READINGS_ON) == "true";
			
			//Skin Speech Icon Accordingly
			buildSpeechIcon();
			
			//Skin No Lock Icon Accordingly
			buildNoLockIcon();
			
			//Build Menu Content
			setupContent();
			
			//Event Listeners
			this.addEventListener(FeathersEventType.CREATION_COMPLETE, onCreationComplete);
			iOSDrip.instance.addEventListener(IosXdripReaderEvent.APP_IN_FOREGROUND, onApplicationActivated);
		}
		
		private function setupContent():void
		{
			//Setup Fullscreen Icon 
			fullScreenIconTexture = MaterialDeepGreyAmberMobileThemeIcons.fullscreenTexture;
			fullScreenIconImage = new Image(fullScreenIconTexture);
			
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
			
			//Build Menu
			buildListLayout();
			
			//Event Listeners
			addEventListener( starling.events.Event.CHANGE, onMenuChanged );
		}
		
		private function buildListLayout():void
		{
			dataProvider = new ListCollection(
				[
					{ label: ModelLocator.resourceManagerInstance.getString('chartscreen','full_screen_button_title'), icon: fullScreenIconImage, id: 0, action: "showFullScreen" },
					{ label: ModelLocator.resourceManagerInstance.getString('chartscreen','no_lock_button_title'), icon: noLockIconImage, id: 1, action: "enableNoLock" },
					{ label: ModelLocator.resourceManagerInstance.getString('chartscreen','speech_button_title'), icon: speechIconImage, id: 2, action: "enableSpeech" }
				]);
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
						
						//Activate Keep Awake
						NativeApplication.nativeApplication.systemIdleMode = SystemIdleMode.NORMAL;
						Trace.myTrace("ExtraOptionsList.as", "In onMenuChanged, setting systemIdleMode = SystemIdleMode.NORMAL");
					}
					
					//Build No Lock Icon
					buildNoLockIcon();
					
					//Refresh Layout
					buildListLayout();
					
					//Vibrate Device
					BackgroundFetch.vibrate();
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
		
		private function onEnterCalibration(event:starling.events.Event):void
		{
			//TODO: Apply calibration
			//trace("Calibration Value:", calibrationValue.text);
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
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
			
			System.pauseForGCIfCollectionImminent(0);
			
			super.dispose();
		}
	}
}