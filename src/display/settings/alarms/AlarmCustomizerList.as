package display.settings.alarms
{
	import display.LayoutFactory;
	
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
	import starling.events.Event;
	
	import utils.Constants;

	public class AlarmCustomizerList extends List 
	{
		public function AlarmCustomizerList()
		{
			super();
		}
		override protected function initialize():void 
		{
			super.initialize();
			
			/* Properties */
			clipContent = false;
			isSelectable = false;
			autoHideBackground = true;
			hasElasticEdges = false;
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
			
			/* Controls */
			var enableAlarm:ToggleSwitch = LayoutFactory.createToggleSwitch(true);
			var treshold:TextInput = LayoutFactory.createTextInput(false, true, 40, HorizontalAlign.RIGHT);
			var enableSnoozeInNotification:Check = LayoutFactory.createCheckMark(true);
			var snoozeMinutes:TextInput = LayoutFactory.createTextInput(false, true, 40, HorizontalAlign.RIGHT);
			var enableRepeat:Check = LayoutFactory.createCheckMark(true);
			var enableVibration:Check = LayoutFactory.createCheckMark(true);
			var soundList:PickerList = LayoutFactory.createPickerList();
			
			/* Content */
			soundList.dataProvider = new ArrayCollection(
				[
					{ label: "No Sound", accessory: createPlayButton(), soundFile: "" },
					{ label: "Better WakeUp", accessory: createPlayButton(), soundFile: "" },
					{ label: "Bruteforce", accessory: createPlayButton(), soundFile: "" },
					{ label: "Default iOS", accessory: createPlayButton(), soundFile: "" },
					{ label: "Modern Alarm #1", accessory: createPlayButton(), soundFile: "" },
					{ label: "Modern Alarm #2", accessory: createPlayButton(), soundFile: "" },
					{ label: "Nightscout", accessory: createPlayButton(), soundFile: "" },
					{ label: "Short Low #1", accessory: createPlayButton(), soundFile: "" },
					{ label: "Short Low #2", accessory: createPlayButton(), soundFile: "" },
					{ label: "Short Low #3", accessory: createPlayButton(), soundFile: "" },
					{ label: "Short Low #4", accessory: createPlayButton(), soundFile: "" },
					{ label: "Short High #1", accessory: createPlayButton(), soundFile: "" },
					{ label: "Short High #2", accessory: createPlayButton(), soundFile: "" },
					{ label: "Short High #3", accessory: createPlayButton(), soundFile: "" },
					{ label: "Short High #4", accessory: createPlayButton(), soundFile: "" },
					{ label: "Spaceship", accessory: createPlayButton(), soundFile: "" },
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
			
			/* Data */
			dataProvider = new ListCollection(
				[
					{ label: "Enabled", accessory: enableAlarm },
					{ label: "Treshold", accessory: treshold },
					{ label: "Snooze From Notification", accessory: enableSnoozeInNotification },
					{ label: "Default Snooze (Min)", accessory: snoozeMinutes },
					{ label: "Repeat", accessory: enableRepeat },
					{ label: "Sound", accessory: soundList },
					{ label: "Vibration Enabled", accessory: enableVibration }
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
		
		private function createPlayButton():Button
		{
			var button:Button = new Button();
			button.iconOffsetX = 0.1;
			button.iconOffsetY = -0.1;
			button.styleNameList.add(Button.ALTERNATE_STYLE_NAME_CALL_TO_ACTION_BUTTON);
			button.defaultIcon = new Image(MaterialDeepGreyAmberMobileThemeIcons.playOutlineTexture);
			button.width = button.height = 20;
			button.addEventListener(Event.TRIGGERED, onPlaySound);
			
			return button;
		}
		
		private function onPlaySound(e:Event):void
		{
			var selectedItemData:Object = DefaultListItemRenderer(Button(e.currentTarget).parent).data;
			trace("SoundFile:", selectedItemData.soundFile);
		}
	}
}