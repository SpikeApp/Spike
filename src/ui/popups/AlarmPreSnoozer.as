package ui.popups
{	
	import flash.errors.IllegalOperationError;
	import flash.events.TimerEvent;
	
	import feathers.controls.Button;
	import feathers.controls.Callout;
	import feathers.controls.Label;
	import feathers.controls.LayoutGroup;
	import feathers.controls.PickerList;
	import feathers.core.PopUpManager;
	import feathers.data.ArrayCollection;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.HorizontalLayout;
	import feathers.layout.VerticalLayout;
	
	import model.ModelLocator;
	
	import services.AlarmService;
	
	import starling.core.Starling;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.EventDispatcher;
	
	import ui.screens.display.LayoutFactory;
	
	import utils.Constants;

	[ResourceBundle("globaltranslations")]
	[ResourceBundle("alarmsettingsscreen")]
	
	public class AlarmPreSnoozer extends EventDispatcher
	{
		/* Constants */
		public static const CANCELLED:String = "onCancelled";
		public static const CLOSED:String = "onClosed";
		
		/* Display Objects */
		private static var snoozePickerList:PickerList;
		private static var snoozeCallout:Callout;
		private static var titleLabel:Label;
		
		/* Properties */
		private static var firstRun:Boolean = true;
		private static var _instance:AlarmPreSnoozer;
		private static var dataProvider:ArrayCollection;
		private static var selectedSnoozeIndex:int = 0;
		private static var snoozeLabels:Array;
		private static var snoozeTitle:String = "";
		private static var unSnoozeAction:Function = null;
		private static var snoozeAction:Function = null;
		private static var isOpened:Boolean = false;

		private static var mainContainer:LayoutGroup;

		private static var actionButtonsContainer:LayoutGroup;

		private static var alarmTypesPicker:PickerList;

		private static var actionButton:Button;

		private static var snoozeStatusLabel:Label;
		
		public function AlarmPreSnoozer()
		{
			//Don't allow class to be instantiated
			if (_instance != null)
				throw new IllegalOperationError("AlarmSnoozer class is not meant to be instantiated!");
		}
		
		/**
		 * Functionality
		 */
		public static function displaySnoozer(title:String, labels:Array):void
		{
			//Update internal variables
			if (snoozeLabels == null) snoozeLabels = labels;
			snoozeTitle = title;
			
			if (_instance == null)
				_instance = new AlarmPreSnoozer();
				
			//Create objects
			createDisplayObjects();
			
			/* Display Callout */
			if (!isOpened)
				displayCallout();
		}
		
		private static function displayCallout():void
		{
			if (isOpened)
				return;
			
			//Close the callout
			if (PopUpManager.isPopUp(snoozeCallout))
				PopUpManager.removePopUp(snoozeCallout);
			
			//Display callout
			PopUpManager.addPopUp(snoozeCallout, false, false);
			
			isOpened = true;
		}
		
		private static function createDisplayObjects():void
		{
			/* Alarm Selector Container */
			/*var alarmSelectorLayout:VerticalLayout = new VerticalLayout();
			alarmSelectorLayout.horizontalAlign = HorizontalAlign.CENTER;
			alarmSelectorLayout.gap = 10;
			
			var alarmSelectorContainer:LayoutGroup = new LayoutGroup();
			alarmSelectorContainer.layout = alarmSelectorLayout;*/
			
			if (mainContainer != null)
				mainContainer.removeChildren();
			
			/* Main Container */
			var mainLayout:VerticalLayout = new VerticalLayout();
			mainLayout.horizontalAlign = HorizontalAlign.CENTER;
			mainLayout.gap = 10;
			
			mainContainer = new LayoutGroup();
			mainContainer.layout = mainLayout;
			
			/* Title */
			titleLabel = LayoutFactory.createSectionLabel(snoozeTitle, false, HorizontalAlign.CENTER);
			mainContainer.addChild(titleLabel);
			
			/* First Phase */
			createFirstPhase();
			
			/* Action Buttons */
			var actionButtonsLayout:HorizontalLayout = new HorizontalLayout();
			actionButtonsLayout.gap = 5;
			
			actionButtonsContainer = new LayoutGroup();
			actionButtonsContainer.layout = actionButtonsLayout;
			mainContainer.addChild(actionButtonsContainer);
			
			//Cancel Button
			var cancelButton:Button = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('globaltranslations',"cancel_button_label"));
			cancelButton.addEventListener(Event.TRIGGERED, onCancel);
			actionButtonsContainer.addChild(cancelButton);
			
			//Action Button
			actionButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('globaltranslations',"ok_alert_button_label"));
			
			snoozeStatusLabel = LayoutFactory.createLabel("", HorizontalAlign.CENTER);
			
			/* Callout Position Helper Creation */
			var positionHelper:Sprite = new Sprite();
			positionHelper.x = Constants.stageWidth / 2;
			positionHelper.y = 70;
			Starling.current.stage.addChild(positionHelper);
			
			/* Callout Creation */
			snoozeCallout = new Callout();
			//snoozeCallout.content = mainContainer;
			snoozeCallout.content = mainContainer;
			snoozeCallout.origin = positionHelper;
			snoozeCallout.minWidth = 240;
		}
		
		private static function createFirstPhase():void
		{
			/* Alarm Selector */
			var alarmTypesLabels:Array = ModelLocator.resourceManagerInstance.getString('alarmsettingsscreen',"pre_snoozer_alarm_list").split(",");
			var alarmTypesDataProvider:ArrayCollection = new ArrayCollection();
			var numAlarmTypesLabels:uint = alarmTypesLabels.length;
			for (var i:int = 0; i < numAlarmTypesLabels; i++) 
			{
				alarmTypesDataProvider.push( { label: alarmTypesLabels[i] } );
			}
			alarmTypesPicker = LayoutFactory.createPickerList();
			alarmTypesPicker.prompt = "Select";
			alarmTypesPicker.dataProvider = alarmTypesDataProvider;
			alarmTypesPicker.selectedIndex = -1;
			alarmTypesPicker.addEventListener(Event.CHANGE, onAlarmChosen);
			mainContainer.addChild(alarmTypesPicker);
		}
		
		private static function onAlarmChosen(e:Event):void
		{
			var selectedAlarmIndex:int = alarmTypesPicker.selectedIndex;
			mainContainer.removeChild(snoozeStatusLabel);
			mainContainer.removeChild(snoozePickerList);
			
			if (selectedAlarmIndex == 0)
			{
				//Urgent High Alarm
				if (AlarmService.veryHighAlertSnoozed())
				{
					snoozeStatusLabel.text = "Snoozed for " + AlarmService.veryHighAlertSnoozeAsString();
					mainContainer.addChildAt(snoozeStatusLabel, 2);
					unSnoozeAction = AlarmService.resetVeryHighAlert;
					actionButton.label = "Unsnooze";
					actionButtonsContainer.addChild(actionButton);
					actionButton.addEventListener(Event.TRIGGERED, unSnoozeAlarm);
				}
				else
				{
					actionButton.label = "PreSnooze";
					actionButtonsContainer.addChild(actionButton);
					actionButton.addEventListener(Event.TRIGGERED, onClose);
					createSecondPhase();
				}
			}
			else if (selectedAlarmIndex == 1)
			{
				//High Alarm
				if (AlarmService.highAlertSnoozed())
				{
					snoozeStatusLabel.text = "Snoozed for " + AlarmService.highAlertSnoozeAsString();
					mainContainer.addChildAt(snoozeStatusLabel, 2);
					unSnoozeAction = AlarmService.resetHighAlert;
					actionButton.label = "Unsnooze";
					actionButtonsContainer.addChild(actionButton);
					actionButton.addEventListener(Event.TRIGGERED, unSnoozeAlarm);
				}
				else
				{
					actionButton.label = "PreSnooze";
					actionButtonsContainer.addChild(actionButton);
					actionButton.addEventListener(Event.TRIGGERED, onClose);
				}
			}
			else if (selectedAlarmIndex == 2)
			{
				//Low Alarm
				if (AlarmService.lowAlertSnoozed())
				{
					snoozeStatusLabel.text = "Snoozed for " + AlarmService.lowAlertSnoozeAsString();
					mainContainer.addChildAt(snoozeStatusLabel, 2);
					unSnoozeAction = AlarmService.resetLowAlert;
					actionButton.label = "Unsnooze";
					actionButtonsContainer.addChild(actionButton);
					actionButton.addEventListener(Event.TRIGGERED, unSnoozeAlarm);
				}
				else
				{
					actionButton.label = "PreSnooze";
					actionButtonsContainer.addChild(actionButton);
					actionButton.addEventListener(Event.TRIGGERED, onClose);
				}
			}
			else if (selectedAlarmIndex == 3)
			{
				//Urgent Low Alarm
				if (AlarmService.veryLowAlertSnoozed())
				{
					snoozeStatusLabel.text = "Snoozed for " + AlarmService.veryLowAlertSnoozeAsString();
					mainContainer.addChildAt(snoozeStatusLabel, 2);
					unSnoozeAction = AlarmService.resetVeryLowAlert;
					actionButton.label = "Unsnooze";
					actionButtonsContainer.addChild(actionButton);
					actionButton.addEventListener(Event.TRIGGERED, unSnoozeAlarm);
				}
				else
				{
					actionButton.label = "PreSnooze";
					actionButtonsContainer.addChild(actionButton);
					actionButton.addEventListener(Event.TRIGGERED, onClose);
				}
			}
			else if (selectedAlarmIndex == 4)
			{
				//Missed Readings
				if (AlarmService.missedReadingAlertSnoozed())
				{
					snoozeStatusLabel.text = "Snoozed for " + AlarmService.missedReadingAlertSnoozeAsString();
					mainContainer.addChildAt(snoozeStatusLabel, 2);
					unSnoozeAction = AlarmService.resetMissedReadingAlert;
					actionButton.label = "Unsnooze";
					actionButtonsContainer.addChild(actionButton);
					actionButton.addEventListener(Event.TRIGGERED, unSnoozeAlarm);
				}
				else
				{
					actionButton.label = "PreSnooze";
					actionButtonsContainer.addChild(actionButton);
					actionButton.addEventListener(Event.TRIGGERED, onClose);
				}
			}
			else if (selectedAlarmIndex == 5)
			{
				//Muted
				if (AlarmService.phoneMutedAlertSnoozed())
				{
					snoozeStatusLabel.text = "Snoozed for " + AlarmService.phoneMutedAlertSnoozeAsString();
					mainContainer.addChildAt(snoozeStatusLabel, 2);
					unSnoozeAction = AlarmService.resetPhoneMutedAlert;
					actionButton.label = "Unsnooze";
					actionButtonsContainer.addChild(actionButton);
					actionButton.addEventListener(Event.TRIGGERED, unSnoozeAlarm);
				}
				else
				{
					actionButton.label = "PreSnooze";
					actionButtonsContainer.addChild(actionButton);
					actionButton.addEventListener(Event.TRIGGERED, onClose);
				}
			}
			
			snoozeCallout.invalidate();
			snoozeCallout.validate();
		}
		
		private static function snoozeAlarm(e:Event):void
		{
			
		}
		
		private static function unSnoozeAlarm(e:Event):void
		{
			
		}
		
		private static function createSecondPhase():void
		{
			/* Snoozer Picker List */
			snoozePickerList = LayoutFactory.createPickerList();
			dataProvider = new ArrayCollection();
			
			var numLabels:uint = snoozeLabels.length;
			for (var i:int = 0; i < numLabels; i++) 
			{
				dataProvider.push( { label: snoozeLabels[i] } );
			}
			
			snoozePickerList.dataProvider = dataProvider;
			snoozePickerList.selectedIndex = selectedSnoozeIndex;
			mainContainer.addChildAt(snoozePickerList, 2);
		}
		
		public static function closeCallout(e:TimerEvent = null):void
		{
			if (!isOpened)
				return;
			
			//Close the callout
			if (PopUpManager.isPopUp(snoozeCallout))
				PopUpManager.removePopUp(snoozeCallout);
			else if(snoozeCallout != null)
					snoozeCallout.close();
			
			isOpened = false;
		}
		
		/**
		 * Event Listeners
		 */
		private static function onClose(e:Event):void
		{
			_instance.dispatchEventWith(CLOSED, false, { index: snoozePickerList.selectedIndex });
			
			closeCallout();
		}
		
		private static function onCancel(e:Event):void
		{
			closeCallout();
			_instance.dispatchEventWith(CANCELLED);
		}

		/**
		 * Getters & Setters
		 */
		public static function get instance():AlarmPreSnoozer
		{
			if (_instance == null)
				_instance = new AlarmPreSnoozer();
				
			return _instance;
		}
	}
}