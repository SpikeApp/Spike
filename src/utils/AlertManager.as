package utils
{
	import flash.errors.IllegalOperationError;
	import flash.events.TimerEvent;
	import flash.text.engine.LineJustification;
	import flash.text.engine.SpaceJustifier;
	import flash.utils.Timer;
	
	import feathers.controls.Alert;
	import feathers.controls.ScrollBarDisplayMode;
	import feathers.controls.text.TextBlockTextRenderer;
	import feathers.core.ITextRenderer;
	import feathers.core.PopUpManager;
	import feathers.data.ListCollection;
	import feathers.layout.HorizontalAlign;
	
	import model.ModelLocator;
	
	import starling.display.DisplayObject;
	import starling.events.Event;
	
	[ResourceBundle("general")]

	public class AlertManager
	{
		private static var _instance:AlertManager = new AlertManager();
		private static var alertQueue:Array = [];
		private static var activeAlertsCount:int = 0;
		private static var timeoutTimer:Timer;
		private static var activeAlert:Alert;
		
		public function AlertManager()
		{
			//Don't allow class to be instantiated
			if (_instance != null)
				throw new IllegalOperationError("AlertManager class is not meant to be instantiated!");				
		}
		
		/**
		 * Public Methods
		 */
		public static function showSimpleAlert (alertTitle:String, alertMessage:String, timeoutDuration:Number = Number.NaN, eventHandlerFunct:Function = null, textAlign:String = HorizontalAlign.JUSTIFY, icon:DisplayObject = null):Alert
		{
			var alert:Alert = processAlert(alertTitle, alertMessage, timeoutDuration, eventHandlerFunct, null, textAlign, icon);
			return alert;
		}
		
		public static function showActionAlert (alertTitle:String, alertMessage:String, timeoutDuration:Number = Number.NaN, buttonGroup:Array = null, textAlign:String = HorizontalAlign.JUSTIFY, icon:DisplayObject = null):Alert
		{
			var alert:Alert = processAlert(alertTitle, alertMessage, timeoutDuration, null, buttonGroup, textAlign, icon);
			return alert;
		}
		
		/*public static function showCustomAlert (alert:Alert, timeoutDuration:Number = Number.NaN):void
		{
			
		}*/
		
		/**
		 * Functionality
		 */
		private static function processAlert(alertTitle:String, alertMessage:String, timeoutDuration:Number = Number.NaN, eventHandlerFunct:Function = null, buttonGroup:Array = null, textAlign:String = HorizontalAlign.JUSTIFY, icon:DisplayObject = null):Alert
		{
			var alert:Alert = new Alert();
			
			/* Define Alert Buttons */
			var buttonCollection:ListCollection
			if	(buttonGroup != null)
				buttonCollection = new ListCollection(buttonGroup);
			else
				buttonCollection = new ListCollection(
					[
						{ label: ModelLocator.resourceManagerInstance.getString('general','ok'), triggered: eventHandlerFunct }
					]
				);
			
			/* Define Text Renderer */
			alert.messageFactory = function():ITextRenderer
			{
				var messageRenderer:TextBlockTextRenderer = new TextBlockTextRenderer();
				if (textAlign == HorizontalAlign.JUSTIFY)
					messageRenderer.textJustifier = new SpaceJustifier( "en", LineJustification.ALL_BUT_MANDATORY_BREAK);
				else
					messageRenderer.textAlign = textAlign;
				
				return messageRenderer;
			};
			
			/* Define Properties */
			alert.title = alertTitle;
			alert.message = alertMessage;
			alert.buttonsDataProvider = buttonCollection;
			alert.icon = icon;
			alert.scrollBarDisplayMode = ScrollBarDisplayMode.NONE;
			
			/* Define Event Listeners */
			alert.addEventListener(Event.CLOSE, onAlertClosed );
			
			/* Display/Queue Alert */
			if (activeAlertsCount == 0) //If no alerts are being currently displayed, let's display this one */
			{
				//Update internal variables
				activeAlertsCount += 1;
				activeAlert = alert;
				
				//Activate alert timeout timer
				if (!isNaN(timeoutDuration ))
					processAlertTimer(timeoutDuration);
				
				//Show alert
				PopUpManager.addPopUp(alert);
			}
			else //There's currently one alert being displayed, let's add this one to the queue */
				alertQueue.push({ alert: alert, timeout: timeoutDuration});
			
			return alert; //Return the alert in case we need to do further customization to it outside this class
		}
		
		private static function processQueue():void
		{
			/* Clean Up */
			if (activeAlert != null)
			{
				if (PopUpManager.isPopUp(activeAlert))
					PopUpManager.removePopUp(activeAlert);
				else
					PopUpManager.removeAllPopUps();
				
				activeAlert.dispose();
				activeAlert = null;
			}
			
			/* Update Counter */
			activeAlertsCount -= 1;
			if (activeAlertsCount < 0)
				activeAlertsCount = 0;
			
			if (alertQueue.length > 0)
			{
				/* Show Next Alert */
				if (!isNaN((alertQueue[0] as Object).timeout))
					processAlertTimer(Number((alertQueue[0] as Object).timeout));
				
				activeAlert = Alert((alertQueue[0] as Object).alert);
				PopUpManager.addPopUp(activeAlert);
				
				/* Update Counter & Queue */
				alertQueue.shift();
				activeAlertsCount += 1;
			}
		}
		
		private static function processAlertTimer(timerDuration:Number):void
		{
			if (timeoutTimer == null)
				timeoutTimer = new Timer(timerDuration * 1000, 1);
			
			timeoutTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onAlertTimedOut);
			timeoutTimer.start();
		}
		
		/**
		 * Event Handlers
		 */
		private static function onAlertTimedOut(event:TimerEvent):void
		{
			/* Cleanup Timeout Timer */
			timeoutTimer.stop();
			timeoutTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, onAlertTimedOut);
			timeoutTimer = null;
			
			/* Process Internal Queue */
			processQueue();
		}

		private static function onAlertClosed(e:Event):void
		{
			processQueue();
		}
		
		/**
		 * Getters & Setters
		 */
		public static function get instance():AlertManager
		{
			return _instance;
		}
	}
}