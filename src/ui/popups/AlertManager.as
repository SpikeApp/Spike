package ui.popups
{
	import flash.errors.IllegalOperationError;
	import flash.events.TimerEvent;
	import flash.text.engine.LineJustification;
	import flash.text.engine.SpaceJustifier;
	import flash.utils.Timer;
	
	import events.SpikeEvent;
	
	import feathers.controls.Alert;
	import feathers.controls.ScrollBarDisplayMode;
	import feathers.controls.text.TextBlockTextRenderer;
	import feathers.core.ITextRenderer;
	import feathers.core.PopUpManager;
	import feathers.data.ListCollection;
	import feathers.layout.HorizontalAlign;
	
	import model.ModelLocator;
	
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.events.Event;
	import starling.utils.SystemUtil;
	
	import utils.Constants;
	import utils.Trace;
	
	[ResourceBundle("globaltranslations")]
	[ResourceBundle("calibrationservice")]

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
		public static function init():void
		{
			Trace.myTrace("AlertManager.as", "Service started!");
			
			Spike.instance.addEventListener(SpikeEvent.APP_IN_FOREGROUND, onAppInForeground, false, 0, true);
		}
		
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
		
		/**
		 * Functionality
		 */
		private static function processAlert(alertTitle:String, alertMessage:String, timeoutDuration:Number = Number.NaN, eventHandlerFunct:Function = null, buttonGroup:Array = null, textAlign:String = HorizontalAlign.JUSTIFY, icon:DisplayObject = null):Alert
		{
			if (activeAlert != null && activeAlert.title == alertTitle && activeAlert.message == alertMessage)
			{
				return activeAlert;
			}
			
			var alert:Alert = new Alert();
			
			/* Define Alert Buttons */
			var buttonCollection:ListCollection
			if	(buttonGroup != null)
				buttonCollection = new ListCollection(buttonGroup);
			else
				buttonCollection = new ListCollection(
					[
						{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations','ok_alert_button_label'), triggered: eventHandlerFunct }
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
			if (PopUpManager.popUpCount == 0)
				activeAlertsCount = 0;
			
			if (
				(activeAlertsCount == 0 || 
				alertTitle == ModelLocator.resourceManagerInstance.getString('calibrationservice','enter_first_calibration_title') || 
				alertTitle == ModelLocator.resourceManagerInstance.getString('calibrationservice','enter_second_calibration_title') || 
				alertTitle == ModelLocator.resourceManagerInstance.getString('calibrationservice','enter_calibration_title') || 
				alertTitle == ModelLocator.resourceManagerInstance.getString('calibrationservice','enter_calibration_title_with_override') ||
				alertTitle == ModelLocator.resourceManagerInstance.getString('calibrationservice','enter_calibration_title_sub_optimal')
				) && 
				Constants.appInForeground) //If no alerts are being currently displayed and app is in foreground, let's display this one 
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
			else
			{
				//There's currently one alert being displayed or app is in background, let's add this one to the queue
				removeDuplicate(alertTitle, alertMessage);
				alertQueue.push({ alert: alert, timeout: timeoutDuration});
			}
			
			return alert; //Return the alert in case we need to do further customization to it outside this class
		}
		
		private static function removeDuplicate(title:String, message:String):void
		{
			if (alertQueue == null || alertQueue.length == 0)
				return;
			
			for(var i:int = alertQueue.length - 1 ; i >= 0; i--)
			{
				var queuedObject:Object = alertQueue[i];
				if (queuedObject != null && queuedObject.alert != null)
				{
					var queuedAlert:Alert = queuedObject.alert as Alert;
					if (queuedAlert.title == title && queuedAlert.message == message)
					{
						//Found duplicate. Remove it!
						queuedAlert.removeEventListeners();
						alertQueue.removeAt(i);
						SystemUtil.executeWhenApplicationIsActive( queuedAlert.removeFromParent, true );
						queuedObject = null;
					}
				}
			}
		}
		
		private static function processQueue(closeActivePopup:Boolean = true):void
		{
			if (!Constants.appInForeground)
				return;
			
			/* Clean Up */
			if (activeAlert != null && closeActivePopup)
			{
				if (PopUpManager.isPopUp(activeAlert))
					PopUpManager.removePopUp(activeAlert);
				else
					activeAlert.removeFromParent();
				
				activeAlert.dispose();
				activeAlert = null;
					
				/* Update Counter */
				activeAlertsCount -= 1;
				if (activeAlertsCount < 0)
					activeAlertsCount = 0;
			}
			
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
			if (timeoutTimer != null)
			{
				timeoutTimer.stop();
				timeoutTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, onAlertTimedOut);
				timeoutTimer = null;
			}
			
			/* Process Internal Queue */
			if (Constants.appInForeground)
				processQueue();
		}

		private static function onAlertClosed(e:Event):void
		{
			onAlertTimedOut(null);
		}
		
		private static function onAppInForeground (e:SpikeEvent):void
		{
			Starling.juggler.delayCall(processQueue, 0.5, false);
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