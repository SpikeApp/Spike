package ui.screens
{
	import flash.system.Capabilities;
	import flash.system.System;
	
	import spark.formatters.DateTimeFormatter;
	
	import database.CGMBlueToothDevice;
	import database.CommonSettings;
	import database.LocalSettings;
	import database.Sensor;
	
	import feathers.controls.Alert;
	import feathers.controls.Button;
	import feathers.controls.DateTimeSpinner;
	import feathers.controls.LayoutGroup;
	import feathers.controls.ScrollPolicy;
	import feathers.events.FeathersEventType;
	import feathers.layout.AnchorLayout;
	import feathers.layout.AnchorLayoutData;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalAlign;
	import feathers.layout.VerticalLayout;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.ModelLocator;
	
	import services.TutorialService;
	
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.events.Event;
	import starling.events.ResizeEvent;
	
	import ui.AppInterface;
	import ui.popups.AlertManager;
	import ui.screens.display.LayoutFactory;
	
	import utils.Constants;
	import utils.DeviceInfo;
	
	[ResourceBundle("sensorscreen")]

	public class SensorStartScreen extends BaseSubScreen
	{
		/* Display Objects */
		private var dateSpinner:DateTimeSpinner;
		private var startButton:Button;
		private var container:LayoutGroup;
		
		/* Internal Variables */
		private var initialAlertShowed:Boolean = false;

		public function SensorStartScreen() 
		{
			super();
			
			setupHeader();
		}
		
		override protected function initialize():void 
		{
			super.initialize();
			
			Starling.current.stage.addEventListener(starling.events.Event.RESIZE, onStarlingResize);
			
			/* Display Initial Alert */
			if( !TutorialService.isActive && !TutorialService.ninethStepActive )
				Starling.juggler.delayCall(showInitialAlert, 1.25);
			
			/* Setup Content and Adjust Main Menu */
			setupContent();
			adjustMainMenu();
			setupEventListeners();
			
			this.horizontalScrollPolicy = ScrollPolicy.OFF;
		}
		
		/**
		 * Functionality
		 */
		private function setupHeader():void
		{
			/* Set Header Title */
			title = ModelLocator.resourceManagerInstance.getString('sensorscreen','sensor_start_screen_title');
			
			/* Set Header Icon */
			icon = getScreenIcon(MaterialDeepGreyAmberMobileThemeIcons.sensorTexture);
			iconContainer = new <DisplayObject>[icon];
			headerProperties.rightItems = iconContainer;
		}
		
		private function showInitialAlert():void
		{
			initialAlertShowed = true;
			
			var alert:Alert = AlertManager.showSimpleAlert(
				ModelLocator.resourceManagerInstance.getString('sensorscreen','sensor_start_alert_title'),
				ModelLocator.resourceManagerInstance.getString('sensorscreen','sensor_start_alert_message')
			);
			if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr)
			{
				alert.maxWidth = 270;
				alert.height = 320;
			}
		}
		
		private function setupContent():void
		{
			/* Parent Class Layout */
			layout = new AnchorLayout(); 
			
			/* Create Display Object's Container and Corresponding Vertical Layout and Centered LayoutData */
			container = new LayoutGroup();
			var containerLayout:VerticalLayout = new VerticalLayout();
			containerLayout.gap = 20;
			containerLayout.horizontalAlign = HorizontalAlign.CENTER;
			containerLayout.verticalAlign = VerticalAlign.MIDDLE;
			container.layout = containerLayout;
			var containerLayoutData:AnchorLayoutData = new AnchorLayoutData();
			containerLayoutData.horizontalCenter = 0;
			containerLayoutData.verticalCenter = 0;
			container.layoutData = containerLayoutData;
			this.addChild( container );
			
			/* Create DateSpinner */
			dateSpinner = new DateTimeSpinner();
			dateSpinner.locale = Constants.getUserLocale(true);
			dateSpinner.height = 155;
			dateSpinner.maximum = new Date();
			
			container.addChild( dateSpinner );
			
			/* Create Start Button */
			startButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('sensorscreen','start_button_extended_label'));
			startButton.addEventListener(Event.TRIGGERED, onSensorStarted);
			container.addChild(startButton);
		}
		
		private function adjustMainMenu():void
		{
			AppInterface.instance.menu.selectedIndex = Constants.isPortrait ? 2 : 1;
		}
		
		private function setupEventListeners():void
		{
			if( TutorialService.isActive && TutorialService.ninethStepActive)
				addEventListener(FeathersEventType.TRANSITION_IN_COMPLETE, onScreenIn);
		}
		
		/**
		 * Event Handlers
		 */
		private function onScreenIn(e:Event):void
		{
			removeEventListener(FeathersEventType.TRANSITION_IN_COMPLETE, onScreenIn);
			
			if( TutorialService.isActive && TutorialService.ninethStepActive)
			{
				Starling.juggler.delayCall(TutorialService.tenthStep, .2, startButton);
				TutorialService.instance.addEventListener(TutorialService.TUTORIAL_FINISHED, onTutorialFinished);	
			}
		}
		
		private function onTutorialFinished(e:Event):void
		{
			Starling.juggler.delayCall(determineIfAlertNeedsToBeShown, .75);
		}
		
		private function determineIfAlertNeedsToBeShown():void
		{
			if ( !initialAlertShowed && AppInterface.instance.navigator.activeScreenID == Screens.SENSOR_START )
				showInitialAlert();
		}
		
		private function onSensorStarted(e:Event):void
		{
			/* Calculate Sensor Insertion Time */
			var sensorStartTime:Number = dateSpinner.value.valueOf();
			Sensor.startSensor(sensorStartTime);
			
			/* Calculate Time Till Next Calibration */
			var actualTime:Number = (new Date()).valueOf();
			var timeOfCalibration:Number = !CGMBlueToothDevice.isTypeLimitter() ? 2 * 3600 * 1000 - (actualTime - sensorStartTime) : 3600 * 1000 - (actualTime - sensorStartTime);
			
			/* Define Date Formater Helper */
			var dateFormatterForSensorStartWarning:DateTimeFormatter = new DateTimeFormatter();
			dateFormatterForSensorStartWarning.dateTimePattern = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_DATE_FORMAT).slice(0,2) == "24" ? "HH:mm" : "K:mm a";
			dateFormatterForSensorStartWarning.useUTC = false;
			dateFormatterForSensorStartWarning.setStyle("locale",Constants.getUserLocale());
			
			/* Define Alert Message */
			var alertMessage:String;
			if (timeOfCalibration > 0 && !CGMBlueToothDevice.knowsFSLAge() && LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_REMOVE_SENSOR_WARMUP_ENABLED) != "true") {
				alertMessage = ModelLocator.resourceManagerInstance.getString('sensorscreen',"sensor_start_alert_message_wait_prefix");
				alertMessage += " " + dateFormatterForSensorStartWarning.format(new Date(actualTime + timeOfCalibration)) + " ";
				alertMessage += ModelLocator.resourceManagerInstance.getString('sensorscreen',"sensor_start_alert_message_wait_suffix");
			} else {
				alertMessage = ModelLocator.resourceManagerInstance.getString('sensorscreen',"sensor_start_alert_message_no_wait");
			}
			
			/* Display Alert */
			var alert:Alert = AlertManager.showSimpleAlert
			(
				ModelLocator.resourceManagerInstance.getString('sensorscreen',"sensor_started_alert_title"),
				alertMessage,
				Number.NaN,
				onBackButtonTriggered
			);
			alert.height = 425;
			if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr)
			{
				alert.maxWidth = 270;
				alert.height = 490;
			}
			
			alert.addEventListener(Event.CLOSE, onClose);
			
			function onClose(e:Event):void
			{
				if ((TutorialService.isActive || TutorialService.eleventhStepActive) && (CGMBlueToothDevice.isDexcomG5() || CGMBlueToothDevice.isDexcomG6()))
					TutorialService.eleventhStep();
			}
		}	
		
		private function onStarlingResize(event:ResizeEvent):void 
		{
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
		}
		
		override protected function onTransitionInComplete(e:Event):void
		{
			//Swipe to pop functionality
			AppInterface.instance.navigator.isSwipeToPopEnabled = true;
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			Starling.current.stage.removeEventListener(starling.events.Event.RESIZE, onStarlingResize);
			
			if( TutorialService.isActive && TutorialService.ninethStepActive)
			{
				removeEventListener(FeathersEventType.TRANSITION_IN_COMPLETE, onScreenIn)
				TutorialService.instance.removeEventListener(TutorialService.TUTORIAL_FINISHED, onTutorialFinished);
			}
			
			if (dateSpinner != null)
			{
				dateSpinner.removeFromParent();
				dateSpinner.dispose();
				dateSpinner = null;
			}
			
			if (startButton != null)
			{
				startButton.removeEventListener(Event.TRIGGERED, onSensorStarted);
				startButton.removeFromParent();
				startButton.dispose();
				startButton = null;
			}
			
			if (container != null)
			{
				container.removeFromParent();
				container.dispose();
				container = null;
			}
			
			super.dispose();
			
			System.pauseForGCIfCollectionImminent(0);
		}
		
		override protected function draw():void 
		{
			super.draw();
			icon.x = Constants.stageWidth - icon.width - BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding;
		}
	}
}