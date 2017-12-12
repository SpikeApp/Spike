package display.sensor
{
	import flash.system.System;
	
	import display.LayoutFactory;
	
	import feathers.controls.Alert;
	import feathers.controls.Button;
	import feathers.controls.GroupedList;
	import feathers.controls.Label;
	import feathers.controls.renderers.DefaultGroupedListItemRenderer;
	import feathers.controls.renderers.IGroupedListItemRenderer;
	import feathers.data.HierarchicalCollection;
	import feathers.data.ListCollection;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalLayoutData;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import screens.Screens;
	
	import starling.events.Event;
	
	import ui.AppInterface;
	
	import utils.Constants;

	public class SensorStartStopList extends GroupedList 
	{
		/* Display Objects */
		private var actionButton:Button;
		private var sensorStartDateLabel:Label;
		
		public function SensorStartStopList()
		{
			super();
		}
		
		override protected function initialize():void 
		{
			super.initialize();
			
			/* Set Properties */
			clipContent = false;
			isSelectable = false;
			autoHideBackground = true;
			hasElasticEdges = false;
			paddingBottom = 5;
			layoutData = new VerticalLayoutData( 100 );
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
			
			/* Set Controls */
			activateStopButton();
			sensorStartDateLabel = LayoutFactory.createLabel("", HorizontalAlign.RIGHT);
			
			/* Set Data */
			setDataProvider("04 Dec 22:30")
			
			/* Set Content Renderer */
			this.itemRendererFactory = function ():IGroupedListItemRenderer {
				const item:DefaultGroupedListItemRenderer = new DefaultGroupedListItemRenderer();
				item.labelField = "label";
				item.iconField = "icon";
				item.accessoryField = "accessory";
				return item;
			};
		}
		
		private function onStopSensor(e:Event):void
		{
			Alert.show(
				"Are you sure you want to stop the sensor? This action can not be undone.",
				"Stop Sensor",
				new ListCollection(
					[
						{ label: "CANCEL" },
						{ label: "STOP", triggered: onStopSensorTriggered }
					]
				)
			);
		}
		
		private function onStartSensor(e:Event):void
		{
			AppInterface.instance.navigator.pushScreen( Screens.SENSOR_START );
		}
		
		private function onStopSensorTriggered(e:Event):void
		{
			activateStartButton();
			setDataProvider("Not Started");
		}
		
		private function activateStopButton():Button
		{
			if(actionButton != null)
				actionButton.removeEventListeners(Event.TRIGGERED);
			
			actionButton = LayoutFactory.createButton("Stop");
			actionButton.addEventListener(Event.TRIGGERED, onStopSensor);
			
			return actionButton;
		}
		
		private function activateStartButton():Button
		{
			if(actionButton != null)
				actionButton.removeEventListeners(Event.TRIGGERED);
			
			actionButton = LayoutFactory.createButton("Start");
			actionButton.addEventListener(Event.TRIGGERED, onStartSensor);
			
			return actionButton;
		}
		
		private function setDataProvider(sensorStartDate:String):void
		{
			sensorStartDateLabel.text = sensorStartDate;
			
			dataProvider = new HierarchicalCollection(
				[
					{
						header  : { label: "Info" },
						children: [
							{ label: "Sensor Start", accessory: sensorStartDateLabel },
							{ label: "", accessory: actionButton },
						]
					}
				]
			);
		}
		
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