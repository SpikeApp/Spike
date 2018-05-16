package ui.screens.display.sensor
{
	import flash.system.Capabilities;
	import flash.utils.clearInterval;
	import flash.utils.setInterval;
	
	import spark.formatters.DateTimeFormatter;
	
	import database.BlueToothDevice;
	import database.Calibration;
	import database.CommonSettings;
	import database.Database;
	import database.Sensor;
	
	import feathers.controls.Alert;
	import feathers.controls.Button;
	import feathers.controls.GroupedList;
	import feathers.controls.Label;
	import feathers.controls.LayoutGroup;
	import feathers.controls.renderers.DefaultGroupedListItemRenderer;
	import feathers.controls.renderers.IGroupedListItemRenderer;
	import feathers.data.HierarchicalCollection;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.HorizontalLayout;
	import feathers.layout.VerticalLayoutData;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import services.NightscoutService;
	import services.NotificationService;
	
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.events.Event;
	import starling.events.ResizeEvent;
	import starling.utils.SystemUtil;
	
	import treatments.TreatmentsManager;
	
	import ui.AppInterface;
	import ui.popups.AlertManager;
	import ui.screens.Screens;
	import ui.screens.display.LayoutFactory;
	
	import utils.Constants;
	import utils.DeviceInfo;
	import utils.MathHelper;
	import utils.TimeSpan;
	
	[ResourceBundle("sensorscreen")]
	[ResourceBundle("globaltranslations")]

	public class SensorStartStopList extends GroupedList 
	{
		/* Constants */
		private const TIME_2_HOURS:int = 2 * 60 * 60 * 1000;
		private const TIME_1_HOUR:int = 1 * 60 * 60 * 1000;
		
		/* Display Objects */
		private var actionButton:Button;
		private var sensorStartDateLabel:Label;
		private var sensorAgeLabel:Label;
		private var totalCalibrationsLabel:Label;
		private var lastCalibrationDateLabel:Label;
		private var deleteAllCalibrationsButton:Button;
		private var deleteLastCalibrationButton:Button;
		private var calibrationActionsContainer:LayoutGroup;
		private var sensorCountdownLabel:Label;
		
		/* Properties */
		private var dateFormatter:DateTimeFormatter;
		private var sensorStartDateValue:String;
		private var sensorAgeValue:String;
		private var lastCalibrationDateValue:String;
		private var numberOfCalibrations:String;
		private var inSensorCountdown:Boolean = false;
		private var intervalID:int = -1;
		private var warmupTime:Number;
		
		public function SensorStartStopList()
		{
			super();
		}
		
		override protected function initialize():void 
		{
			super.initialize();
			
			Starling.current.stage.addEventListener(starling.events.Event.RESIZE, onStarlingResize);
			
			setupProperties();
			setupInitialState();
			setupContent();
		}
		
		/**
		 * Functionality
		 */
		private function setupProperties():void
		{
			/* Set Properties */
			clipContent = false;
			isSelectable = false;
			autoHideBackground = true;
			hasElasticEdges = false;
			paddingBottom = 5;
			layoutData = new VerticalLayoutData( 100 );
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
			
			/* Set Internal Variables/Objects */
			dateFormatter = new DateTimeFormatter();
			dateFormatter.dateTimePattern = ModelLocator.resourceManagerInstance.getString('sensorscreen','datetimepatternforstatusinfo');
			dateFormatter.useUTC = false;
			dateFormatter.setStyle("locale",Capabilities.language.substr(0,2));
		}
		
		private function setupInitialState():void
		{
			/* Warmup Time */
			warmupTime = BlueToothDevice.isTypeLimitter() ? TIME_1_HOUR : TIME_2_HOURS;
			
			/* Sensor Start Date */
			if (Sensor.getActiveSensor() != null)
			{
				//Set sensor start time
				var sensorStartDate:Date = new Date(Sensor.getActiveSensor().startedAt)
				sensorStartDateValue =  dateFormatter.format(sensorStartDate);
				
				//Calculate Sensor Age
				var sensorDays:String;
				var sensorHours:String;
				
				if (BlueToothDevice.isBluKon() || BlueToothDevice.isTransmiter_PL() || BlueToothDevice.isMiaoMiao()) 
				{
					var sensorAgeInMinutes:String = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FSL_SENSOR_AGE);
					
					if (sensorAgeInMinutes == "0") 
						sensorAgeValue = ModelLocator.resourceManagerInstance.getString('sensorscreen', "sensor_age_not_applicable");
					else if ((new Number(sensorAgeInMinutes)) > 14.5 * 24 * 60) 
					{
						sensorAgeValue = ModelLocator.resourceManagerInstance.getString('sensorscreen','sensor_expired');
					}
					else 
					{
						sensorDays = TimeSpan.fromMinutes(Number(sensorAgeInMinutes)).days.toString();
						sensorHours = TimeSpan.fromMinutes(Number(sensorAgeInMinutes)).hours.toString();
						
						sensorAgeValue = sensorDays + "d " + sensorHours + "h";
					}
				}
				else
				{
					var nowDate:Date = new Date();
					sensorDays = TimeSpan.fromDates(sensorStartDate, nowDate).days.toString();
					sensorHours = TimeSpan.fromDates(sensorStartDate, nowDate).hours.toString();
					
					/*if (sensorDays.length == 1)
						sensorDays = "0" + sensorDays;
					if (sensorHours.length == 1)
						sensorHours = "0" + sensorHours;*/
					
					sensorAgeValue = sensorDays + "d " + sensorHours + "h";
				}
				
				//Calculate number of calibrations
				var allCalibrations:Array = Calibration.allForSensor();
				numberOfCalibrations = String(allCalibrations.length > 0 ? allCalibrations.length - 1 : 0); //Compatibility with new method of only one initial calibration
				
				//Calculate Last Calibration Time
				if (allCalibrations.length > 0)
				{
					var lastCalibrationDate:Date = new Date(Calibration.last().timestamp);
					lastCalibrationDateValue = dateFormatter.format(lastCalibrationDate);
				}
				else
					lastCalibrationDateValue = ModelLocator.resourceManagerInstance.getString('sensorscreen', "sensor_age_not_applicable");
				
				//Sensor countdown
				if (new Date().valueOf() - Sensor.getActiveSensor().startedAt < warmupTime)
					inSensorCountdown = true;
			}
			else
			{
				sensorStartDateValue = ModelLocator.resourceManagerInstance.getString('sensorscreen', "not_started_label");
				sensorAgeValue = ModelLocator.resourceManagerInstance.getString('sensorscreen', "sensor_age_not_applicable");
				numberOfCalibrations = "0";
				lastCalibrationDateValue = ModelLocator.resourceManagerInstance.getString('sensorscreen', "sensor_age_not_applicable");
			}
		}
		
		private function setupContent():void
		{
			/* Set Controls */
			//Activate Stop/Start Button
			if (sensorStartDateValue != ModelLocator.resourceManagerInstance.getString('sensorscreen', "not_started_label"))
				activateStopButton();
			else
				activateStartButton();
			
			//Create Sensor Start Date Label
			sensorStartDateLabel = LayoutFactory.createLabel("", HorizontalAlign.RIGHT);
			
			//Create Sensor Age Label
			sensorAgeLabel =  LayoutFactory.createLabel("", HorizontalAlign.RIGHT);
			
			//Sensor countdown label
			sensorCountdownLabel = LayoutFactory.createLabel("", HorizontalAlign.RIGHT);
			if (inSensorCountdown)
			{
				var sensor:Sensor = Sensor.getActiveSensor();
				if (sensor != null)
				{
					var sensorReady:Number = sensor.startedAt + warmupTime;
					var now:Number = new Date().valueOf();
					
					if (now < sensorReady)
					{
						var timeSpan:TimeSpan = TimeSpan.fromMilliseconds(sensorReady - new Date().valueOf());
						sensorCountdownLabel.text = MathHelper.formatNumberToString(timeSpan.hours) + "h" + MathHelper.formatNumberToString(timeSpan.minutes) + "m" + MathHelper.formatNumberToString(timeSpan.seconds) + "s";
					}
				}
			}
			
			//Create Total Calibrations Label
			totalCalibrationsLabel =  LayoutFactory.createLabel("", HorizontalAlign.RIGHT);
			
			//Create Last Calibration Date Label
			lastCalibrationDateLabel =  LayoutFactory.createLabel("", HorizontalAlign.RIGHT);
			
			//Delete all calibrations button
			deleteAllCalibrationsButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('sensorscreen', "delete_all_calibrations_button_label"));
			deleteAllCalibrationsButton.isEnabled = false;
			deleteAllCalibrationsButton.addEventListener(Event.TRIGGERED, onDeleteAllCalibrations);
			
			//Delete last calibration button
			deleteLastCalibrationButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('sensorscreen', "delete_last_calibration_button_label"));
			deleteLastCalibrationButton.isEnabled = false;
			deleteLastCalibrationButton.addEventListener(Event.TRIGGERED, onDeleteLastCalibration);
			
			//Calibrations Actions Container
			var calibrationsLayout:HorizontalLayout = new HorizontalLayout();
			calibrationsLayout.gap = 5;
			calibrationActionsContainer = new LayoutGroup();
			calibrationActionsContainer.layout = calibrationsLayout;
			calibrationActionsContainer.pivotX = -11;
			calibrationActionsContainer.addChild(deleteAllCalibrationsButton);
			calibrationActionsContainer.addChild(deleteLastCalibrationButton);
			
			/* Create Screen Data */
			setDataProvider()
			
			/* Set Content Renderer */
			this.itemRendererFactory = function ():IGroupedListItemRenderer {
				const item:DefaultGroupedListItemRenderer = new DefaultGroupedListItemRenderer();
				item.labelField = "label";
				item.iconField = "icon";
				item.accessoryField = "accessory";
				return item;
			};
			
			if (inSensorCountdown)
				intervalID = setInterval(refreshCountDown, 1000);
		}
		
		private function activateStopButton():void
		{
			if(actionButton != null)
				actionButton.removeEventListeners(Event.TRIGGERED);
			
			actionButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('sensorscreen','stop_button_label'));
			actionButton.pivotX = -11;
			actionButton.addEventListener(Event.TRIGGERED, onStopSensor);
		}
		
		private function activateStartButton():void
		{
			if(actionButton != null)
				actionButton.removeEventListeners(Event.TRIGGERED);
			
			actionButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('sensorscreen','start_button_label'));
			actionButton.pivotX = -11;
			actionButton.addEventListener(Event.TRIGGERED, onStartSensor);
		}
		
		private function setDataProvider():void
		{
			/* Populate List Content */
			sensorStartDateLabel.text = sensorStartDateValue;
			sensorAgeLabel.text = sensorAgeValue;
			totalCalibrationsLabel.text = numberOfCalibrations;
			lastCalibrationDateLabel.text = lastCalibrationDateValue;
			
			var sensorChildrenContent:Array = [];
			sensorChildrenContent.push({ label: ModelLocator.resourceManagerInstance.getString('sensorscreen','sensor_start_label'), accessory: sensorStartDateLabel });
			sensorChildrenContent.push({ label: ModelLocator.resourceManagerInstance.getString('sensorscreen','sensor_age_lavel'), accessory: sensorAgeLabel });
			if (inSensorCountdown)
				sensorChildrenContent.push({ label: ModelLocator.resourceManagerInstance.getString('sensorscreen','warmup_countdown'), accessory: sensorCountdownLabel });
			if (!BlueToothDevice.knowsFSLAge() && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PERIPHERAL_TYPE) != "")
				sensorChildrenContent.push({ label: "", accessory: actionButton });
			
			dataProvider = new HierarchicalCollection(
				[
					{	
						header  : { label: ModelLocator.resourceManagerInstance.getString('sensorscreen','info_section_label') },
						children: sensorChildrenContent
					},
					{
						header  : { label: ModelLocator.resourceManagerInstance.getString('sensorscreen','calibrations_section_label') },
						children: [
							{ label: ModelLocator.resourceManagerInstance.getString('sensorscreen','total'), accessory: totalCalibrationsLabel },
							{ label: ModelLocator.resourceManagerInstance.getString('sensorscreen','last'), accessory: lastCalibrationDateLabel },
							{ label: "", accessory: calibrationActionsContainer },
						]
					}
				]
			);
		}
		
		private function refreshCountDown():void
		{
			var sensor:Sensor = Sensor.getActiveSensor();
			if (sensor == null || !inSensorCountdown)
			{
				finishCountdown();
				return;
			}
			
			var sensorReady:Number = sensor.startedAt + warmupTime;
			var now:Number = new Date().valueOf();
			
			if (now >= sensorReady)
			{
				finishCountdown();
				return;
			}
			
			var timeSpan:TimeSpan = TimeSpan.fromMilliseconds(sensorReady - new Date().valueOf());
			
			sensorCountdownLabel.text = MathHelper.formatNumberToString(timeSpan.hours) + "h" + MathHelper.formatNumberToString(timeSpan.minutes) + "m" + MathHelper.formatNumberToString(timeSpan.seconds) + "s";
		}
		
		private function finishCountdown():void
		{
			clearInterval(intervalID);
			inSensorCountdown = false;
			setDataProvider();
		}
		
		/**
		 * Event Handlers
		 */
		private function onStopSensor(e:Event):void
		{
			var alert:Alert = AlertManager.showActionAlert(
				ModelLocator.resourceManagerInstance.getString('sensorscreen','stop_sensor_alert_title'),
				ModelLocator.resourceManagerInstance.getString('sensorscreen','stop_sensor_alert_message'),
				60,
				[
					{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations','cancel_button_label').toUpperCase() },
					{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations','stop_alert_button_label'), triggered: onStopSensorTriggered }
				]
			);
			if (Constants.deviceModel == DeviceInfo.IPHONE_X)
				alert.maxWidth = 270;
		}
		
		private function onStopSensorTriggered(e:Event):void
		{
			/* Stop the Sensor */
			Sensor.stopSensor();
			NotificationService.updateBgNotification(null);
			
			/* Redraw Content */
			activateStartButton();
			sensorStartDateValue = ModelLocator.resourceManagerInstance.getString('sensorscreen', "not_started_label");
			sensorAgeValue = ModelLocator.resourceManagerInstance.getString('sensorscreen', "sensor_age_not_applicable");
			if (inSensorCountdown)
				finishCountdown();
			setupInitialState();
			setupContent();
		}
		
		private function onStartSensor(e:Event):void
		{
			/* Navigate to the Start Sensor Screen */
			AppInterface.instance.navigator.pushScreen( Screens.SENSOR_START );
		}
		
		private function onDeleteAllCalibrations(e:Event):void
		{
			var alert:Alert = AlertManager.showActionAlert
				(
					ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
					ModelLocator.resourceManagerInstance.getString('globaltranslations','cant_be_undone'),
					Number.NaN,
					[
						{ label: ModelLocator.resourceManagerInstance.getString("globaltranslations","no_uppercase") },
						{ label: ModelLocator.resourceManagerInstance.getString("globaltranslations","yes_uppercase"), triggered: deleteAllCalibrations }
					],
					HorizontalAlign.CENTER
				);
			alert.buttonGroupProperties.gap = 10;
			alert.buttonGroupProperties.horizontalAlign = HorizontalAlign.CENTER;
			
			function deleteAllCalibrations(e:Event):void
			{
				//Delete from treatments
				var allCalibrations:Array = Calibration.allForSensor();
				for (var i:int = 0; i < allCalibrations.length; i++) 
				{
					var calibration:Calibration = allCalibrations[i] as Calibration;
					TreatmentsManager.deleteInternalCalibration(calibration.timestamp);
				}
				
				//Restart the sensor (this will reset all current calibrations)
				var currentSensorTimestamp:Number = Sensor.getActiveSensor().startedAt;
				Sensor.stopSensor();
				NightscoutService.uploadSensorStart = false;
				Sensor.startSensor(currentSensorTimestamp);
				NightscoutService.uploadSensorStart = true;
				setupInitialState();
				setupContent();
			}
		}
		
		private function onDeleteLastCalibration(e:Event):void
		{
			var alert:Alert = AlertManager.showActionAlert
			(
				ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
				ModelLocator.resourceManagerInstance.getString('globaltranslations','cant_be_undone'),
				Number.NaN,
				[
					{ label: ModelLocator.resourceManagerInstance.getString("globaltranslations","no_uppercase") },
					{ label: ModelLocator.resourceManagerInstance.getString("globaltranslations","yes_uppercase"), triggered: deleteLastCalibration }
				],
				HorizontalAlign.CENTER
			);
			alert.buttonGroupProperties.gap = 10;
			alert.buttonGroupProperties.horizontalAlign = HorizontalAlign.CENTER;
			
			function deleteLastCalibration(e:Event):void
			{
				var lastCalibration:Calibration = Calibration.last();
				Database.deleteCalibrationSynchronous(lastCalibration);
				TreatmentsManager.deleteInternalCalibration(lastCalibration.timestamp);
				setupInitialState();
				setupContent();
			}
		}
		
		private function onStarlingResize(event:ResizeEvent):void 
		{
			SystemUtil.executeWhenApplicationIsActive( AppInterface.instance.navigator.replaceScreen, Screens.SENSOR_STATUS, noTransition );
			
			function noTransition( oldScreen:DisplayObject, newScreen:DisplayObject, completeCallback:Function ):void
			{
				completeCallback();
			};
		}
		
		/**
		 * Utility
		 */
		override protected function draw():void
		{
			super.draw();
			
			if (Number(numberOfCalibrations) > 0 && deleteAllCalibrationsButton != null)
				deleteAllCalibrationsButton.isEnabled = true;
			
			if (Number(numberOfCalibrations) > 1 && deleteLastCalibrationButton != null)
				deleteLastCalibrationButton.isEnabled = true;
		}
		
		override public function dispose():void
		{
			clearInterval(intervalID);
			
			Starling.current.stage.removeEventListener(starling.events.Event.RESIZE, onStarlingResize);
			
			/* Dispose Controls */
			if(actionButton != null)
			{
				actionButton.removeEventListener(Event.TRIGGERED, onStopSensor);
				actionButton.removeEventListener(Event.TRIGGERED, onStartSensor);
				actionButton.removeFromParent();
				actionButton.dispose();
				actionButton = null;
			}
			
			if(sensorStartDateLabel != null)
			{
				sensorStartDateLabel.removeFromParent();
				sensorStartDateLabel.dispose();
				sensorStartDateLabel = null;
			}
			
			if(totalCalibrationsLabel != null)
			{
				totalCalibrationsLabel.removeFromParent();
				totalCalibrationsLabel.dispose();
				totalCalibrationsLabel = null;
			}
			
			if(lastCalibrationDateLabel != null)
			{
				lastCalibrationDateLabel.removeFromParent();
				lastCalibrationDateLabel.dispose();
				lastCalibrationDateLabel = null;
			}
			
			if(deleteAllCalibrationsButton != null)
			{
				deleteAllCalibrationsButton.removeEventListener(Event.TRIGGERED, onDeleteAllCalibrations);
				deleteAllCalibrationsButton.removeFromParent();
				deleteAllCalibrationsButton.dispose();
				deleteAllCalibrationsButton = null;
			}
			
			if(deleteLastCalibrationButton != null)
			{
				deleteLastCalibrationButton.removeEventListener(Event.TRIGGERED, onDeleteLastCalibration);
				deleteLastCalibrationButton.removeFromParent();
				deleteLastCalibrationButton.dispose();
				deleteLastCalibrationButton = null;
			}
			
			if(calibrationActionsContainer != null)
			{
				calibrationActionsContainer.removeFromParent();
				calibrationActionsContainer.dispose();
				calibrationActionsContainer = null;
			}
			
			if(sensorCountdownLabel != null)
			{
				sensorCountdownLabel.removeFromParent();
				sensorCountdownLabel.dispose();
				sensorCountdownLabel = null;
			}
			
			super.dispose();
		}
	}
}