package ui
{	
	import flash.errors.IllegalOperationError;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import display.LayoutFactory;
	
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
	
	import starling.core.Starling;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.EventDispatcher;
	
	import utils.Constants;

	[ResourceBundle("globaltranslations")]
	
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
			if (snoozeLabels == null)
				snoozeLabels = labels;
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
			displayCallout();
		}
		
		private static function displayCallout():void
		{
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
		}
		
		private static function createDisplayObjects():void
		{
			/* Main Container */
			var mainLayout:VerticalLayout = new VerticalLayout();
			mainLayout.horizontalAlign = HorizontalAlign.CENTER;
			mainLayout.gap = 10;
			
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
			actionButtonsLayout.gap = 5;
			
			var actionButtonsContainer:LayoutGroup = new LayoutGroup();
			actionButtonsContainer.layout = actionButtonsLayout;
			mainContainer.addChild(actionButtonsContainer);
			
			//Cancel Button
			var cancelButton:Button = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('globaltranslations',"cancel_button_label"));
			cancelButton.addEventListener(Event.TRIGGERED, onCancel);
			actionButtonsContainer.addChild(cancelButton);
			
			//Ok Button
			var okButton:Button = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('globaltranslations',"ok_alert_button_label"));
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
		
		private static function closeCallout(e:TimerEvent = null):void
		{
			//Stop the timer
			if (closeTimer != null && closeTimer.running)
				closeTimer.stop();
			
			//Close the callout
			if (PopUpManager.isPopUp(snoozeCallout))
				PopUpManager.removePopUp(snoozeCallout);
			else
				snoozeCallout.close();
		}
		
		/**
		 * Event Listeners
		 */
		private static function onClose(e:Event):void
		{
			closeCallout();
			_instance.dispatchEventWith(CLOSED, false, { index: snoozePickerList.selectedIndex });
		}
		
		private static function onCancel(e:Event):void
		{
			closeCallout();
			_instance.dispatchEventWith(CANCELLED);
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