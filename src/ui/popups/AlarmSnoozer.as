package ui.popups
{	
	import flash.errors.IllegalOperationError;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	import events.AlarmServiceEvent;
	
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
	import starling.events.ResizeEvent;
	import starling.utils.SystemUtil;
	
	import ui.screens.display.LayoutFactory;
	
	import utils.Constants;

	[ResourceBundle("globaltranslations")]
	[ResourceBundle("alarmservice")]
	
	public class AlarmSnoozer extends EventDispatcher
	{
		/* Constants */
		public static const CANCELLED:String = "onCancelled";
		public static const CLOSED:String = "onClosed";
		private static const TIME_4_MINUTES:int = 4 * 60 * 1000;
		
		/* Display Objects */
		private static var snoozePickerList:PickerList;
		private static var snoozeCallout:Callout;
		private static var titleLabel:Label;
		private static var positionHelper:Sprite;
		
		/* Properties */
		private static var firstRun:Boolean = true;
		private static var _instance:AlarmSnoozer;
		private static var dataProvider:ArrayCollection;
		private static var selectedSnoozeIndex:int = 0;
		private static var snoozeLabels:Array;
		private static var snoozeTitle:String = "";
		private static var closeTimeout:int = -1;
		
		public function AlarmSnoozer()
		{
			//Don't allow class to be instantiated
			if (_instance != null)
				throw new IllegalOperationError("AlarmSnoozer class is not meant to be instantiated!");
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
				Starling.current.stage.addEventListener(starling.events.Event.RESIZE, onStarlingResize);
				
				//Inantiate internal variables
				firstRun = false;
				if (_instance == null)
					_instance = new AlarmSnoozer();
				
				//Create objects
				SystemUtil.executeWhenApplicationIsActive( createDisplayObjects );
			}
			else
			{
				//Update title
				titleLabel.text = title;
				snoozePickerList.selectedIndex = selectedSnoozeIndex;
			}
			
			/* Stop the close timer in case it's running */
			clearTimeout(closeTimeout);
			
			/* Display Callout When Spike is in the Foreground */
			SystemUtil.executeWhenApplicationIsActive( calculatePositionHelper );
			SystemUtil.executeWhenApplicationIsActive( displayCallout );
		}
		
		private static function displayCallout():void
		{
			//Close the callout in case it was already opened
			if (PopUpManager.isPopUp(snoozeCallout))
				SystemUtil.executeWhenApplicationIsActive(PopUpManager.removePopUp, snoozeCallout);
			else if (snoozeCallout != null)
				SystemUtil.executeWhenApplicationIsActive( snoozeCallout.close );
			
			//Display callout
			SystemUtil.executeWhenApplicationIsActive( PopUpManager.addPopUp, snoozeCallout, true, false );
			
			//Create close timer
			closeTimeout = setTimeout(closeCallout, TIME_4_MINUTES);
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
			var subitleLabel:Label = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString("alarmservice","select_snooze_time_title"), HorizontalAlign.CENTER);
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
			calculatePositionHelper();
			
			/* Callout Creation */
			snoozeCallout = new Callout();
			snoozeCallout.content = mainContainer;
			snoozeCallout.origin = positionHelper;
			snoozeCallout.minWidth = 240;
		}
		
		private static function calculatePositionHelper():void
		{
			if (positionHelper == null)
			{
				positionHelper = new Sprite();
				Starling.current.stage.addChild(positionHelper);
			}
			
			positionHelper.x = Constants.stageWidth / 2;
			positionHelper.y = 70;
		}
		
		public static function closeCallout():void
		{
			//Stop the timer
			clearTimeout(closeTimeout);
			
			//Close the callout
			if (PopUpManager.isPopUp(snoozeCallout))
				SystemUtil.executeWhenApplicationIsActive (PopUpManager.removePopUp, snoozeCallout );
			else if(snoozeCallout != null)
				SystemUtil.executeWhenApplicationIsActive (snoozeCallout.close );
		}
		
		/**
		 * Event Listeners
		 */
		private static function onClose(e:Event):void
		{
			
			_instance.dispatchEventWith(CLOSED, false, { index: snoozePickerList.selectedIndex });
			
			SystemUtil.executeWhenApplicationIsActive (closeCallout );
			
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
			SystemUtil.executeWhenApplicationIsActive (closeCallout );
			
			_instance.dispatchEventWith(CANCELLED);
		}
		
		private static function onStarlingResize(event:ResizeEvent):void 
		{
			SystemUtil.executeWhenApplicationIsActive( calculatePositionHelper );
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