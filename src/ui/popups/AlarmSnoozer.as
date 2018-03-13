package ui.popups
{	
	import flash.errors.IllegalOperationError;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import events.AlarmServiceEvent;
	import events.SpikeEvent;
	
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
	[ResourceBundle("alarmservice")]
	
	public class AlarmSnoozer extends EventDispatcher
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
		private static var _instance:AlarmSnoozer;
		private static var dataProvider:ArrayCollection;
		private static var closeTimer:Timer;
		private static var selectedSnoozeIndex:int = 0;
		private static var snoozeLabels:Array;
		private static var snoozeTitle:String = "";
		private static var queuedAction:Function = null;
		private static var isOpened:Boolean = false;
		
		public function AlarmSnoozer()
		{
			//Don't allow class to be instantiated
			if (_instance != null)
				throw new IllegalOperationError("AlarmSnoozer class is not meant to be instantiated!");
		}
		
		public static function init():void
		{
			//Event Listenes
			Spike.instance.addEventListener(SpikeEvent.APP_IN_FOREGROUND, onSpikeInForeground);
		}
		
		/**
		 * Functionality
		 */
		public static function displaySnoozer(title:String, labels:Array, selectedIndex:int):void
		{
			//Update internal variables
			if (snoozeLabels == null) snoozeLabels = labels;
			selectedSnoozeIndex = selectedIndex;
			snoozeTitle = title;
			
			if (firstRun)
			{
				//Inantiate internal variables
				firstRun = false;
				if (_instance == null)
					_instance = new AlarmSnoozer();
				
				//Create objects
				createDisplayObjects();
				createCloseTimer();
			}
			else
			{
				//Update title
				titleLabel.text = title;
				snoozePickerList.selectedIndex = selectedSnoozeIndex;
			}
			
			/* Display Callout */
			if (Constants.appInForeground)
			{
				if (!isOpened)
					displayCallout();
			}
			else
			{
				//Queue the popup so it shows as soon as Spike is brought to the foreground.
				if (!isOpened)
				{
					queuedAction = displayCallout;
					if (closeTimer != null && closeTimer.running)
						closeTimer.stop();
				}
			}
		}
		
		private static function displayCallout():void
		{
			if (isOpened)
				return;
			
			if (!Constants.appInForeground)
			{
				if (closeTimer != null && closeTimer.running)
					closeTimer.stop();
				
				queuedAction = displayCallout;
				
				return;
			}
			
			//Close the callout
			if (PopUpManager.isPopUp(snoozeCallout))
				PopUpManager.removePopUp(snoozeCallout);
			
			//Display callout
			PopUpManager.addPopUp(snoozeCallout, false, false);
			
			//Manage timer
			if (closeTimer != null)
			{
				if (closeTimer.running)
					closeTimer.stop();
				
				closeTimer.start();
			}
			
			isOpened = true;
		}
		
		private static function createDisplayObjects():void
		{
			/* Main Container */
			var mainLayout:VerticalLayout = new VerticalLayout();
			mainLayout.horizontalAlign = HorizontalAlign.CENTER;
			mainLayout.gap = 15;
			
			var mainContainer:LayoutGroup = new LayoutGroup();
			mainContainer.layout = mainLayout;
			
			/* Title */
			titleLabel = LayoutFactory.createSectionLabel(snoozeTitle, false, HorizontalAlign.CENTER);
			mainContainer.addChild(titleLabel);
			
			/* Subtitle */
			var subitleLabel:Label = LayoutFactory.createLabel("Select Snooze Time", HorizontalAlign.CENTER);
			mainContainer.addChild(subitleLabel);
			
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
			mainContainer.addChild(snoozePickerList);
			
			/* Action Buttons */
			var actionButtonsLayout:HorizontalLayout = new HorizontalLayout();
			actionButtonsLayout.gap = 10;
			
			var actionButtonsContainer:LayoutGroup = new LayoutGroup();
			actionButtonsContainer.layout = actionButtonsLayout;
			mainContainer.addChild(actionButtonsContainer);
			
			//Cancel Button
			var cancelButton:Button = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('globaltranslations',"cancel_button_label").toUpperCase());
			cancelButton.addEventListener(Event.TRIGGERED, onCancel);
			actionButtonsContainer.addChild(cancelButton);
			
			//Ok Button
			var okButton:Button = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('globaltranslations',"ok_alert_button_label").toUpperCase());
			okButton.addEventListener(Event.TRIGGERED, onClose);
			actionButtonsContainer.addChild(okButton);
			
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
		
		private static function createCloseTimer():void
		{
			closeTimer = new Timer( 4 * 60 * 1000, 1); //4 minutes
			closeTimer.addEventListener(TimerEvent.TIMER, closeCallout);
			closeTimer.start();
		}
		
		public static function closeCallout(e:TimerEvent = null):void
		{
			if (!isOpened)
				return;
			
			//Stop the timer
			if (closeTimer != null && closeTimer.running)
				closeTimer.stop();
			
			if (!Constants.appInForeground)
			{
				queuedAction = closeCallout;
				return;
			}
			
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
			
			//Notify Services (ex: IFTTT)
			if (snoozeTitle.indexOf(ModelLocator.resourceManagerInstance.getString("alarmservice","snooze_text_low_alert")) != -1)
				AlarmService.instance.dispatchEvent(new AlarmServiceEvent(AlarmServiceEvent.LOW_GLUCOSE_SNOOZED, false, false, { type: ModelLocator.resourceManagerInstance.getString("alarmservice","snooze_text_low_alert"), time: AlarmService.snoozeValueMinutes[snoozePickerList.selectedIndex] }));
			else if (snoozeTitle.indexOf(ModelLocator.resourceManagerInstance.getString("alarmservice","snooze_text_high_alert")) != -1)
				AlarmService.instance.dispatchEvent(new AlarmServiceEvent(AlarmServiceEvent.HIGH_GLUCOSE_SNOOZED, false, false, { type: ModelLocator.resourceManagerInstance.getString("alarmservice","snooze_text_high_alert"), time: AlarmService.snoozeValueMinutes[snoozePickerList.selectedIndex] }));
			else if (snoozeTitle.indexOf(ModelLocator.resourceManagerInstance.getString("alarmservice","snooze_text_very_low_alert")) != -1)
				AlarmService.instance.dispatchEvent(new AlarmServiceEvent(AlarmServiceEvent.URGENT_LOW_GLUCOSE_SNOOZED, false, false, { type: ModelLocator.resourceManagerInstance.getString("alarmservice","snooze_text_very_low_alert"), time: AlarmService.snoozeValueMinutes[snoozePickerList.selectedIndex] }));
			else if (snoozeTitle.indexOf(ModelLocator.resourceManagerInstance.getString("alarmservice","snooze_text_very_high_alert")) != -1)
				AlarmService.instance.dispatchEvent(new AlarmServiceEvent(AlarmServiceEvent.URGENT_HIGH_GLUCOSE_SNOOZED, false, false, { type: ModelLocator.resourceManagerInstance.getString("alarmservice","snooze_text_very_high_alert"), time: AlarmService.snoozeValueMinutes[snoozePickerList.selectedIndex] }));
			else if (snoozeTitle.indexOf(ModelLocator.resourceManagerInstance.getString("alarmservice","snooze_text_missed_reading_alert")) != -1)
				AlarmService.instance.dispatchEvent(new AlarmServiceEvent(AlarmServiceEvent.MISSED_READINGS_SNOOZED, false, false, { type: ModelLocator.resourceManagerInstance.getString("alarmservice","snooze_text_missed_reading_alert"), time: AlarmService.snoozeValueMinutes[snoozePickerList.selectedIndex] }));
			else if (snoozeTitle.indexOf(ModelLocator.resourceManagerInstance.getString("alarmservice","snooze_text_phone_muted_alert")) != -1)
				AlarmService.instance.dispatchEvent(new AlarmServiceEvent(AlarmServiceEvent.PHONE_MUTED_SNOOZED, false, false, { type: ModelLocator.resourceManagerInstance.getString("alarmservice","snooze_text_phone_muted_alert"), time: AlarmService.snoozeValueMinutes[snoozePickerList.selectedIndex] }));
			else if (snoozeTitle.indexOf(ModelLocator.resourceManagerInstance.getString("alarmservice","snooze_text_battery_alert")) != -1)
				AlarmService.instance.dispatchEvent(new AlarmServiceEvent(AlarmServiceEvent.TRANSMITTER_LOW_BATTERY_SNOOZED, false, false, { type: ModelLocator.resourceManagerInstance.getString("alarmservice","snooze_text_battery_alert"), time: AlarmService.snoozeValueMinutes[snoozePickerList.selectedIndex] }));
			else if (snoozeTitle.indexOf(ModelLocator.resourceManagerInstance.getString("alarmservice","calibration_request_alert_notification_alert_title")) != -1)
				AlarmService.instance.dispatchEvent(new AlarmServiceEvent(AlarmServiceEvent.CALIBRATION_SNOOZED, false, false, { type: ModelLocator.resourceManagerInstance.getString("alarmservice","calibration_request_alert_notification_alert_title"), time: AlarmService.snoozeValueMinutes[snoozePickerList.selectedIndex] }));
		}
		
		private static function onCancel(e:Event):void
		{
			closeCallout();
			_instance.dispatchEventWith(CANCELLED);
		}
		
		private static function onSpikeInForeground(e:SpikeEvent):void
		{
			if (queuedAction != null)
			{
				Starling.juggler.delayCall(queuedAction, 0.5);
				queuedAction = null;
			}
		}

		/**
		 * Getters & Setters
		 */
		public static function get instance():AlarmSnoozer
		{
			if (_instance == null)
				_instance = new AlarmSnoozer();
				
			return _instance;
		}
	}
}