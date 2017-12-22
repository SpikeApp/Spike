package display.sensor
{
	import flash.system.Capabilities;
	import flash.system.System;
	
	import spark.formatters.DateTimeFormatter;
	
	import databaseclasses.BlueToothDevice;
	import databaseclasses.CommonSettings;
	import databaseclasses.Sensor;
	
	import display.LayoutFactory;
	
	import feathers.controls.Button;
	import feathers.controls.GroupedList;
	import feathers.controls.Label;
	import feathers.controls.renderers.DefaultGroupedListItemRenderer;
	import feathers.controls.renderers.IGroupedListItemRenderer;
	import feathers.data.HierarchicalCollection;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalLayoutData;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import screens.Screens;
	
	import services.NotificationService;
	
	import starling.events.Event;
	
	import ui.AppInterface;
	
	import utils.AlertManager;
	import utils.Constants;
	import utils.TimeSpan;
	
	[ResourceBundle("sensorscreen")]

	public class SensorStartStopList extends GroupedList 
	{
		/* Display Objects */
		private var actionButton:Button;
		private var sensorStartDateLabel:Label;
		private var sensorAgeLabel:Label;
		
		/* Properties */
		private var dateFormatterForSensorStartTimeAndDate:DateTimeFormatter;
		private var sensorStartDateValue:String;
		private var sensorAgeValue:String;
		
		public function SensorStartStopList()
		{
			super();
		}
		
		override protected function initialize():void 
		{
			super.initialize();
			
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
			dateFormatterForSensorStartTimeAndDate = new DateTimeFormatter();
			dateFormatterForSensorStartTimeAndDate.dateTimePattern = ModelLocator.resourceManagerInstance.getString('sensorscreen','datetimepatternforstatusinfo');
			dateFormatterForSensorStartTimeAndDate.useUTC = false;
			dateFormatterForSensorStartTimeAndDate.setStyle("locale",Capabilities.language.substr(0,2));
		}
		
		private function setupInitialState():void
		{
			/* Sensor Start Date */
			if (Sensor.getActiveSensor() != null)
			{
				//Set sensor start time
				var sensorStartDate:Date = new Date(Sensor.getActiveSensor().startedAt)
				sensorStartDateValue =  dateFormatterForSensorStartTimeAndDate.format(sensorStartDate);
				
				//Calculate Sensor Age
				var sensorDays:String;
				var sensorHours:String;
				
				if (BlueToothDevice.isBluKon() || BlueToothDevice.isBlueReader()) 
				{
					var sensorAgeInMinutes:String = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FSL_SENSOR_AGE);
					
					if (sensorAgeInMinutes == "0") 
						sensorAgeValue = ModelLocator.resourceManagerInstance.getString('sensorscreen', "sensor_age_not_applicable");
					else 
					{
						sensorDays = TimeSpan.fromMinutes(Number(sensorAgeInMinutes)).days.toString();
						sensorHours = TimeSpan.fromMinutes(Number(sensorAgeInMinutes)).hours.toString();
						
						sensorAgeValue = sensorDays + "d" + sensorHours + "h";
					}
				}
				else
				{
					var nowDate:Date = new Date();
					sensorDays = TimeSpan.fromDates(sensorStartDate, nowDate).days.toString();
					sensorHours = TimeSpan.fromDates(sensorStartDate, nowDate).hours.toString();
					
					if (sensorDays.length == 1)
						sensorDays = "0" + sensorDays;
					if (sensorHours.length == 1)
						sensorHours = "0" + sensorHours;
					
					sensorAgeValue = sensorDays + "d" + sensorHours + "h";
				}
			}
			else
			{
				sensorStartDateValue = ModelLocator.resourceManagerInstance.getString('sensorscreen', "not_started_label");
				sensorAgeValue = ModelLocator.resourceManagerInstance.getString('sensorscreen', "sensor_age_not_applicable");
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
			
			//Create Sensor Age Lavel
			sensorAgeLabel =  LayoutFactory.createLabel("", HorizontalAlign.RIGHT);
			
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
		}
		
		private function activateStopButton():void
		{
			if(actionButton != null)
				actionButton.removeEventListeners(Event.TRIGGERED);
			
			actionButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('sensorscreen','stop_button_label'));
			actionButton.addEventListener(Event.TRIGGERED, onStopSensor);
		}
		
		private function activateStartButton():void
		{
			if(actionButton != null)
				actionButton.removeEventListeners(Event.TRIGGERED);
			
			actionButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('sensorscreen','start_button_label'));
			actionButton.addEventListener(Event.TRIGGERED, onStartSensor);
		}
		
		private function setDataProvider():void
		{
			/* Populate List Content */
			sensorStartDateLabel.text = sensorStartDateValue;
			sensorAgeLabel.text = sensorAgeValue;
			
			dataProvider = new HierarchicalCollection(
				[
					{
						header  : { label: ModelLocator.resourceManagerInstance.getString('sensorscreen','info_section_label') },
						children: [
							{ label: ModelLocator.resourceManagerInstance.getString('sensorscreen','sensor_start_label'), accessory: sensorStartDateLabel },
							{ label: ModelLocator.resourceManagerInstance.getString('sensorscreen','sensor_age_lavel'), accessory: sensorAgeLabel },
							{ label: "", accessory: actionButton },
						]
					}
				]
			);
		}
		
		/**
		 * Event Handlers
		 */
		private function onStopSensor(e:Event):void
		{
			AlertManager.showActionAlert(
				ModelLocator.resourceManagerInstance.getString('sensorscreen','stop_sensor_alert_title'),
				ModelLocator.resourceManagerInstance.getString('sensorscreen','stop_sensor_alert_message'),
				60,
				[
					{ label: ModelLocator.resourceManagerInstance.getString('sensorscreen','cancel_alert_button_label') },
					{ label: ModelLocator.resourceManagerInstance.getString('sensorscreen','stop_alert_button_label'), triggered: onStopSensorTriggered }
				]
			);
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
			setDataProvider();
		}
		
		private function onStartSensor(e:Event):void
		{
			/* Navigate to the Start Sensor Screen */
			AppInterface.instance.navigator.pushScreen( Screens.SENSOR_START );
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			/* Dispose Controls */
			if(actionButton != null)
			{
				actionButton.dispose();
				actionButton = null;
			}
			
			if(sensorStartDateLabel != null)
			{
				sensorStartDateLabel.dispose();
				sensorStartDateLabel = null;
			}
			
			System.pauseForGCIfCollectionImminent(0);
			
			/* Dispose Component */
			super.dispose();
		}
	}
}