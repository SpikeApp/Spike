package ui.popups
{	
	import flash.errors.IllegalOperationError;
	
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
	[ResourceBundle("alarmpresnoozer")]
	
	public class AlarmPreSnoozer extends EventDispatcher
	{
		/* Constants */
		public static const CANCELLED:String = "onCancelled";
		public static const CLOSED:String = "onClosed";
		
		/* Display Objects */
		private static var snoozePickerList:PickerList;
		private static var snoozeCallout:Callout;
		private static var titleLabel:Label;
		private static var mainContainer:LayoutGroup;
		private static var actionButtonsContainer:LayoutGroup;
		private static var alarmTypesPicker:PickerList;
		private static var actionButton:Button;
		private static var snoozeStatusLabel:Label;
		
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

		private static var cancelButton:Button;
		
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
			/* Main Container */
			if (mainContainer != null)
				mainContainer.removeChildren();
			
			var mainLayout:VerticalLayout = new VerticalLayout();
			mainLayout.horizontalAlign = HorizontalAlign.CENTER;
			mainLayout.gap = 15;
			
			mainContainer = new LayoutGroup();
			mainContainer.layout = mainLayout;
			
			/* Title */
			titleLabel = LayoutFactory.createSectionLabel(snoozeTitle, false, HorizontalAlign.CENTER);
			mainContainer.addChild(titleLabel);
			
			/* First Phase */
			createFirstPhase();
			
			/* Action Buttons */
			var actionButtonsLayout:HorizontalLayout = new HorizontalLayout();
			actionButtonsLayout.gap = 10;
			
			actionButtonsContainer = new LayoutGroup();
			actionButtonsContainer.layout = actionButtonsLayout;
			mainContainer.addChild(actionButtonsContainer);
			
			//Cancel Button
			cancelButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('globaltranslations',"cancel_button_label").toUpperCase());
			cancelButton.addEventListener(Event.TRIGGERED, onCancel);
			actionButtonsContainer.addChild(cancelButton);
			
			//Action Button
			actionButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('globaltranslations',"ok_alert_button_label").toUpperCase());
			
			snoozeStatusLabel = LayoutFactory.createLabel("", HorizontalAlign.CENTER);
			
			/* Callout Position Helper Creation */
			var positionHelper:Sprite = new Sprite();
			positionHelper.x = Constants.stageWidth / 2;
			positionHelper.y = 70;
			Starling.current.stage.addChild(positionHelper);
			
			/* Callout Creation */
			snoozeCallout = new Callout();
			snoozeCallout.content = mainContainer;
			snoozeCallout.origin = positionHelper;
			snoozeCallout.minWidth = 240;
		}
		
		private static function createFirstPhase():void
		{
			/* Alarm Selector */
			var alarmTypesLabels:Array = ModelLocator.resourceManagerInstance.getString('alarmpresnoozer',"pre_snoozer_alarm_list").split(",");
			var alarmTypesDataProvider:ArrayCollection = new ArrayCollection();
			var numAlarmTypesLabels:uint = alarmTypesLabels.length;
			for (var i:int = 0; i < numAlarmTypesLabels; i++) 
			{
				alarmTypesDataProvider.push( { label: alarmTypesLabels[i] } );
			}
			alarmTypesPicker = LayoutFactory.createPickerList();
			alarmTypesPicker.prompt = ModelLocator.resourceManagerInstance.getString('globaltranslations',"picker_select");
			alarmTypesPicker.dataProvider = alarmTypesDataProvider;
			alarmTypesPicker.selectedIndex = -1;
			alarmTypesPicker.addEventListener(Event.CHANGE, onAlarmChosen);
			mainContainer.addChild(alarmTypesPicker);
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
		
		public static function closeCallout():void
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
		private static function onAlarmChosen(e:Event):void
		{
			var selectedAlarmIndex:int = alarmTypesPicker.selectedIndex;
			mainContainer.removeChild(snoozeStatusLabel);
			mainContainer.removeChild(snoozePickerList);
			
			if (selectedAlarmIndex == 0)
			{
				//All Alarm
				if (AlarmService.veryHighAlertSnoozed() ||
					AlarmService.highAlertSnoozed() ||
					AlarmService.lowAlertSnoozed() ||
					AlarmService.veryLowAlertSnoozed() ||
					AlarmService.missedReadingAlertSnoozed() ||
					AlarmService.phoneMutedAlertSnoozed() 
					)
				{
					actionButton.label = ModelLocator.resourceManagerInstance.getString('alarmpresnoozer',"unsnooze_button_label").toUpperCase();
					actionButtonsContainer.addChild(actionButton);
					actionButton.addEventListener(Event.TRIGGERED, unSnoozeAllAlarms);
				}
				else
				{
					actionButton.label = ModelLocator.resourceManagerInstance.getString('alarmpresnoozer',"presnooze_button_label").toUpperCase();
					actionButtonsContainer.addChild(actionButton);
					actionButton.addEventListener(Event.TRIGGERED, snoozeAllAlarms);
					createSecondPhase();
				}
			}
			else if (selectedAlarmIndex == 1)
			{
				//Urgent High Alarm
				if (AlarmService.veryHighAlertSnoozed())
				{
					snoozeStatusLabel.text = ModelLocator.resourceManagerInstance.getString('alarmpresnoozer',"snoozed_for") + " " + AlarmService.veryHighAlertSnoozeAsString();
					mainContainer.addChildAt(snoozeStatusLabel, 2);
					unSnoozeAction = AlarmService.resetVeryHighAlert;
					actionButton.label = ModelLocator.resourceManagerInstance.getString('alarmpresnoozer',"unsnooze_button_label").toUpperCase();
					actionButtonsContainer.addChild(actionButton);
					actionButton.addEventListener(Event.TRIGGERED, unSnoozeAlarm);
				}
				else
				{
					actionButton.label = ModelLocator.resourceManagerInstance.getString('alarmpresnoozer',"presnooze_button_label").toUpperCase();
					actionButtonsContainer.addChild(actionButton);
					actionButton.addEventListener(Event.TRIGGERED, snoozeAlarm);
					createSecondPhase();
					snoozeAction = AlarmService.snoozeVeryHighAlert
				}
			}
			else if (selectedAlarmIndex == 2)
			{
				//High Alarm
				if (AlarmService.highAlertSnoozed())
				{
					snoozeStatusLabel.text = ModelLocator.resourceManagerInstance.getString('alarmpresnoozer',"snoozed_for") + " " + AlarmService.highAlertSnoozeAsString();
					mainContainer.addChildAt(snoozeStatusLabel, 2);
					unSnoozeAction = AlarmService.resetHighAlert;
					actionButton.label = ModelLocator.resourceManagerInstance.getString('alarmpresnoozer',"unsnooze_button_label").toUpperCase();
					actionButtonsContainer.addChild(actionButton);
					actionButton.addEventListener(Event.TRIGGERED, unSnoozeAlarm);
				}
				else
				{
					actionButton.label = ModelLocator.resourceManagerInstance.getString('alarmpresnoozer',"presnooze_button_label").toUpperCase();
					actionButtonsContainer.addChild(actionButton);
					actionButton.addEventListener(Event.TRIGGERED, snoozeAlarm);
					createSecondPhase();
					snoozeAction = AlarmService.snoozeHighAlert;
				}
			}
			else if (selectedAlarmIndex == 3)
			{
				//Low Alarm
				if (AlarmService.lowAlertSnoozed())
				{
					snoozeStatusLabel.text = ModelLocator.resourceManagerInstance.getString('alarmpresnoozer',"snoozed_for") + " " + AlarmService.lowAlertSnoozeAsString();
					mainContainer.addChildAt(snoozeStatusLabel, 2);
					unSnoozeAction = AlarmService.resetLowAlert;
					actionButton.label = ModelLocator.resourceManagerInstance.getString('alarmpresnoozer',"unsnooze_button_label").toUpperCase();
					actionButtonsContainer.addChild(actionButton);
					actionButton.addEventListener(Event.TRIGGERED, unSnoozeAlarm);
				}
				else
				{
					actionButton.label = ModelLocator.resourceManagerInstance.getString('alarmpresnoozer',"presnooze_button_label").toUpperCase();
					actionButtonsContainer.addChild(actionButton);
					actionButton.addEventListener(Event.TRIGGERED, snoozeAlarm);
					createSecondPhase();
					snoozeAction = AlarmService.snoozeLowAlert;
				}
			}
			else if (selectedAlarmIndex == 4)
			{
				//Urgent Low Alarm
				if (AlarmService.veryLowAlertSnoozed())
				{
					snoozeStatusLabel.text = ModelLocator.resourceManagerInstance.getString('alarmpresnoozer',"snoozed_for") + " " + AlarmService.veryLowAlertSnoozeAsString();
					mainContainer.addChildAt(snoozeStatusLabel, 2);
					unSnoozeAction = AlarmService.resetVeryLowAlert;
					actionButton.label = ModelLocator.resourceManagerInstance.getString('alarmpresnoozer',"unsnooze_button_label").toUpperCase();
					actionButtonsContainer.addChild(actionButton);
					actionButton.addEventListener(Event.TRIGGERED, unSnoozeAlarm);
				}
				else
				{
					actionButton.label = ModelLocator.resourceManagerInstance.getString('alarmpresnoozer',"presnooze_button_label").toUpperCase();
					actionButtonsContainer.addChild(actionButton);
					actionButton.addEventListener(Event.TRIGGERED, snoozeAlarm);
					createSecondPhase();
					snoozeAction = AlarmService.snoozeVeyLowAlert;
				}
			}
			else if (selectedAlarmIndex == 5)
			{
				//Missed Readings
				if (AlarmService.missedReadingAlertSnoozed())
				{
					snoozeStatusLabel.text = ModelLocator.resourceManagerInstance.getString('alarmpresnoozer',"snoozed_for") + " " + AlarmService.missedReadingAlertSnoozeAsString();
					mainContainer.addChildAt(snoozeStatusLabel, 2);
					unSnoozeAction = AlarmService.resetMissedReadingAlert;
					actionButton.label = ModelLocator.resourceManagerInstance.getString('alarmpresnoozer',"unsnooze_button_label").toUpperCase();
					actionButtonsContainer.addChild(actionButton);
					actionButton.addEventListener(Event.TRIGGERED, unSnoozeAlarm);
				}
				else
				{
					actionButton.label = ModelLocator.resourceManagerInstance.getString('alarmpresnoozer',"presnooze_button_label").toUpperCase();
					actionButtonsContainer.addChild(actionButton);
					actionButton.addEventListener(Event.TRIGGERED, snoozeAlarm);
					createSecondPhase();
					snoozeAction = AlarmService.snoozeMissedReadingAlert;
				}
			}
			else if (selectedAlarmIndex == 6)
			{
				//Muted
				if (AlarmService.phoneMutedAlertSnoozed())
				{
					snoozeStatusLabel.text = ModelLocator.resourceManagerInstance.getString('alarmpresnoozer',"snoozed_for") + " " + AlarmService.phoneMutedAlertSnoozeAsString();
					mainContainer.addChildAt(snoozeStatusLabel, 2);
					unSnoozeAction = AlarmService.resetPhoneMutedAlert;
					actionButton.label = ModelLocator.resourceManagerInstance.getString('alarmpresnoozer',"unsnooze_button_label").toUpperCase();
					actionButtonsContainer.addChild(actionButton);
					actionButton.addEventListener(Event.TRIGGERED, unSnoozeAlarm);
				}
				else
				{
					actionButton.label = ModelLocator.resourceManagerInstance.getString('alarmpresnoozer',"presnooze_button_label").toUpperCase();
					actionButtonsContainer.addChild(actionButton);
					actionButton.addEventListener(Event.TRIGGERED, snoozeAlarm);
					createSecondPhase();
					snoozeAction = AlarmService.snoozePhoneMutedAlert;
				}
			}
			
			snoozeCallout.invalidate();
			snoozeCallout.validate();
		}
		
		private static function snoozeAlarm(e:Event):void
		{
			if (snoozeAction != null)
			{
				snoozeAction.call(null, snoozePickerList.selectedIndex);
				snoozeAction = null;
				closeCallout();
			}
		}
		
		private static function snoozeAllAlarms(e:Event):void
		{
			AlarmService.snoozeVeryHighAlert(snoozePickerList.selectedIndex);
			AlarmService.snoozeHighAlert(snoozePickerList.selectedIndex);
			AlarmService.snoozeLowAlert(snoozePickerList.selectedIndex);
			AlarmService.snoozeVeyLowAlert(snoozePickerList.selectedIndex);
			AlarmService.snoozeMissedReadingAlert(snoozePickerList.selectedIndex);
			AlarmService.snoozePhoneMutedAlert(snoozePickerList.selectedIndex);
			
			closeCallout();
		}
		
		private static function unSnoozeAlarm(e:Event):void
		{
			if (unSnoozeAction != null)
			{
				unSnoozeAction.call();
				unSnoozeAction = null;
				closeCallout();
			}
		}
		
		private static function unSnoozeAllAlarms(e:Event):void
		{
			if (AlarmService.veryHighAlertSnoozed())
				AlarmService.resetVeryHighAlert();
			
			if (AlarmService.highAlertSnoozed())
				AlarmService.resetHighAlert();
				
			if (AlarmService.lowAlertSnoozed())
				AlarmService.resetLowAlert();
				
			if (AlarmService.veryLowAlertSnoozed())
				AlarmService.resetVeryLowAlert();
				
			if (AlarmService.missedReadingAlertSnoozed())
				AlarmService.resetMissedReadingAlert();
				
			if (AlarmService.phoneMutedAlertSnoozed())
				AlarmService.resetPhoneMutedAlert();
			
			closeCallout();
		}
		
		private static function onCancel(e:Event):void
		{
			closeCallout();
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