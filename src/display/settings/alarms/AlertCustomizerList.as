package display.settings.alarms
{
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.net.URLRequest;
	import flash.system.System;
	
	import database.AlertType;
	
	import display.LayoutFactory;
	
	import feathers.controls.Alert;
	import feathers.controls.Button;
	import feathers.controls.Check;
	import feathers.controls.List;
	import feathers.controls.PickerList;
	import feathers.controls.TextInput;
	import feathers.controls.ToggleSwitch;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.data.ArrayCollection;
	import feathers.data.ListCollection;
	import feathers.layout.AnchorLayoutData;
	import feathers.layout.HorizontalAlign;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.events.Event;
	
	import utils.Constants;

	public class AlertCustomizerList extends List 
	{
		public static const SAVED:String = "saved";
		public static const CHANGED:String = "changed";
		private const fiveMinutesInMs:int = 5 * 60 * 1000 - 10000;

		/* Display Objects */
		private var alertName:TextInput;
		private var enableSnoozeInNotification:Check;
		private var snoozeMinutes:TextInput;
		private var enableRepeat:Check;
		private var enableVibration:Check;
		private var soundList:PickerList;
		private var saveAlert:Button;
		private var alertEnabled:ToggleSwitch;
		
		/* Properties */
		private var soundName:String;
		private var repeatInMinutes:int = 0;
		private var soundChannel:SoundChannel = new SoundChannel();
		private var playButtonsList:Array;
		
		public function AlertCustomizerList()
		{
			super();
		}
		
		override protected function initialize():void 
		{
			super.initialize();
			
			playButtonsList = [];
			
			/* Properties */
			clipContent = false;
			isSelectable = false;
			autoHideBackground = true;
			hasElasticEdges = false;
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
			
			/* Controls */
			alertEnabled = LayoutFactory.createToggleSwitch(true);
			alertEnabled.addEventListener(Event.CHANGE, onEnableChanged);
			alertName = LayoutFactory.createTextInput(false, true, 140, HorizontalAlign.RIGHT);
			alertName.addEventListener(Event.CHANGE, onNameChanged);
			enableSnoozeInNotification = LayoutFactory.createCheckMark(true);
			enableSnoozeInNotification.addEventListener(Event.CHANGE, onEnableSnoozeInNotificationChanged);
			snoozeMinutes = LayoutFactory.createTextInput(false, true, 3, HorizontalAlign.RIGHT);
			snoozeMinutes.maxChars = 4;
			snoozeMinutes.addEventListener(Event.CHANGE, onSnoozeMinutesChanged);
			enableRepeat = LayoutFactory.createCheckMark(true);
			enableRepeat.addEventListener(Event.CHANGE, onEnableRepeatChanged);
			enableVibration = LayoutFactory.createCheckMark(true);
			enableVibration.addEventListener(Event.CHANGE, onEnableVibrationChanged);
			soundList = LayoutFactory.createPickerList();
			soundList.addEventListener(Event.CLOSE, onSoundListClose);
			saveAlert = LayoutFactory.createButton("Save");
			saveAlert.addEventListener(Event.TRIGGERED, onSave);
			
			/* Content */
			soundList.dataProvider = new ArrayCollection(
				[
					{ label: "No Sound", accessory: new Sprite(), soundFile: "" },
					{ label: "Better WakeUp", accessory: createPlayButton(), soundFile: "../assets/sounds/betterwakeup.mp3" },
					{ label: "Bruteforce", accessory: createPlayButton(), soundFile: "../assets/sounds/bruteforce.mp3" },
					{ label: "Default iOS", accessory: createPlayButton(), soundFile: "" },
					{ label: "Modern Alarm #1", accessory: createPlayButton(), soundFile: "../assets/sounds/modernalarm1.mp3" },
					{ label: "Modern Alarm #2", accessory: createPlayButton(), soundFile: "../assets/sounds/modernalarm2.mp3" },
					{ label: "Nightscout", accessory: createPlayButton(), soundFile: "../assets/sounds/nightscout.mp3" },
					{ label: "Short Low #1", accessory: createPlayButton(), soundFile: "../assets/sounds/shortlow1.mp3" },
					{ label: "Short Low #2", accessory: createPlayButton(), soundFile: "../assets/sounds/shortlow2.mp3" },
					{ label: "Short Low #3", accessory: createPlayButton(), soundFile: "../assets/sounds/shortlow3.mp3" },
					{ label: "Short Low #4", accessory: createPlayButton(), soundFile: "../assets/sounds/shortlow4.mp3" },
					{ label: "Short High #1", accessory: createPlayButton(), soundFile: "../assets/sounds/shorthigh1.mp3" },
					{ label: "Short High #2", accessory: createPlayButton(), soundFile: "../assets/sounds/shorthigh2.mp3" },
					{ label: "Short High #3", accessory: createPlayButton(), soundFile: "../assets/sounds/shorthigh3.mp3" },
					{ label: "Short High #4", accessory: createPlayButton(), soundFile: "../assets/sounds/shorthigh4.mp3" },
					{ label: "Spaceship", accessory: createPlayButton(), soundFile: "../assets/sounds/spaceship.mp3" },
				]);
			soundList.labelField = "label";
			soundList.itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "label";
				itemRenderer.accessoryField = "accessory";
				itemRenderer.accessoryOffsetX = -20;
				itemRenderer.labelOffsetX = 20;
				
				return itemRenderer;
			}
			soundList.addEventListener(Event.CHANGE, onSoundChanged);
			
			/* Data */
			dataProvider = new ListCollection(
				[
					{ label: "Enabled", accessory: alertEnabled },
					{ label: "Name", accessory: alertName },
					{ label: "Snooze From Notification", accessory: enableSnoozeInNotification },
					{ label: "Default Snooze (Min)", accessory: snoozeMinutes },
					{ label: "Repeat", accessory: enableRepeat },
					{ label: "Sound", accessory: soundList },
					{ label: "Vibration Enabled", accessory: enableVibration },
					{ label: "", accessory: saveAlert }
				]);
			
			/* Renderer */
			itemRendererFactory = function():IListItemRenderer 
			{
				const item:DefaultListItemRenderer = new DefaultListItemRenderer();
				item.labelField = "label";
				item.accessoryField = "accessory";
				return item;
			};
			
			/* Layout */
			layoutData = new AnchorLayoutData( 0, 0, 0, 0 );
		}
		
		private function onSoundListClose():void
		{
			soundChannel.stop();
		}
		
		/**
		 * Functionality
		 */
		public function save():Boolean
		{
			if(alertName.text == "" || snoozeMinutes.text == "")
			{
				var alertTitle:String = "Warning";
				var alertMessage:String;
				if (alertName.text == "" && snoozeMinutes.text == "")
					alertMessage = "You need to define a name and a default snooze time for this alert!"
				else if (alertName.text == "")
					alertMessage = "You need to define a name for this alert!";
				else if (snoozeMinutes.text == "")
					alertMessage = "You need to define a default snooze time for this alert!"; 
					
				var alert:Alert = Alert.show(
					alertMessage,
					alertTitle,
					new ListCollection(
						[
							{ label: "Try Again" }
						]
					)
				);
				
				return false;
			}
			else
			{
				//New Alert (Still need to implement database retrieve/save and if alert already exists (in that case we need to update the alertt in database)
				var alertType:AlertType = new AlertType(
					null, //UniqueID
					Number.NaN, //Last Modified Timestamp 
					alertName.text, //Alert Name
					false, //Enable Lights (android Only)
					enableVibration.isSelected, //Enable Vibration
					enableSnoozeInNotification.isSelected, //Snooze From Notification
					alertEnabled.isSelected, //Alert Enabled
					false, //Override silent mode
					soundName,//Sound
					int(snoozeMinutes.text), //Default Snooze Period (Minutes)
					repeatInMinutes); //Default Repeat Interval (Minutes)
				//Database.insertAlertTypeSychronous(neworExistingAlertType);
				dispatchEventWith(SAVED);
				
				return true;
			}
		}
		
		/**
		 * Event Handlers
		 */
		private function onSoundChanged():void
		{
			dispatchEventWith(CHANGED);
		}
		
		private function onEnableVibrationChanged():void
		{
			dispatchEventWith(CHANGED);
		}
		
		private function onEnableRepeatChanged():void
		{
			repeatInMinutes = fiveMinutesInMs;
			dispatchEventWith(CHANGED);
		}
		
		private function onSnoozeMinutesChanged():void
		{
			dispatchEventWith(CHANGED);
		}
		
		private function onEnableSnoozeInNotificationChanged():void
		{
			dispatchEventWith(CHANGED);
		}
		
		private function onNameChanged(e:Event):void
		{
			dispatchEventWith(CHANGED);
		}
		
		private function onEnableChanged():void
		{
			dispatchEventWith(CHANGED);
		}
		
		private function onSave(e:Event):void
		{
			save();
		}
		
		private function onPlaySound(e:Event):void
		{
			var selectedItemData:Object = DefaultListItemRenderer(Button(e.currentTarget).parent).data;
			var soundFile:String = selectedItemData.soundFile;
			if(soundFile != "")
			{
				trace("Playing", soundFile);
				//BackgroundFetch.init();
				//BackgroundFetch.setAvAudioSessionCategory(true);
				//BackgroundFetch.playSound(String(selectedItemData.soundFile));
				soundChannel.stop();
				var soundPlayer:Sound = new Sound();
				soundPlayer.load(new URLRequest(soundFile));
				soundChannel = soundPlayer.play();
			}
		}
		
		/**
		 * Layout Factories
		 */
		private function createPlayButton():Button
		{
			var button:Button = new Button();
			button.iconOffsetX = 0.1;
			button.iconOffsetY = -0.1;
			button.styleNameList.add(Button.ALTERNATE_STYLE_NAME_CALL_TO_ACTION_BUTTON);
			button.defaultIcon = new Image(MaterialDeepGreyAmberMobileThemeIcons.playOutlineTexture);
			button.width = button.height = 20;
			button.addEventListener(Event.TRIGGERED, onPlaySound);
			
			playButtonsList.push(button);
			
			return button;
		}
		
		override public function dispose():void
		{
			if(playButtonsList != null && playButtonsList.length > 0)
			{
				var length:int = playButtonsList.length;
				for (var i:int = 0; i < length; i++) 
				{
					trace(i);
					var btn:Button = playButtonsList[i] as Button;
					btn.dispose();
					btn = null;
				}
				playButtonsList = null;
			}
			
			if(alertEnabled != null)
			{
				alertEnabled.dispose();
				alertEnabled = null;
			}
			if (alertName != null)
			{
				alertName.dispose();
				alertName = null;
			}
			if(enableSnoozeInNotification != null)
			{
				enableSnoozeInNotification.dispose();
				enableSnoozeInNotification = null;
			}
			if (snoozeMinutes != null)
			{
				snoozeMinutes.dispose();
				snoozeMinutes = null;
			}
			if(enableRepeat != null)
			{
				enableRepeat.dispose();
				enableRepeat = null;
			}
			if(enableVibration != null)
			{
				enableVibration.dispose();
				enableVibration = null;
			}
			if(soundList != null)
			{
				soundList.dispose();
				soundList = null;
			}
			if(saveAlert != null)
			{
				saveAlert.dispose();
				saveAlert = null;
			}
			
			System.pauseForGCIfCollectionImminent(0);
			
			super.dispose();
		}
	}
}