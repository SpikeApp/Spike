package screens
{
	import flash.text.engine.LineJustification;
	import flash.text.engine.SpaceJustifier;
	
	import display.LayoutFactory;
	
	import feathers.controls.Alert;
	import feathers.controls.Button;
	import feathers.controls.DateTimeSpinner;
	import feathers.controls.LayoutGroup;
	import feathers.controls.text.TextBlockTextRenderer;
	import feathers.core.ITextRenderer;
	import feathers.data.ListCollection;
	import feathers.layout.AnchorLayout;
	import feathers.layout.AnchorLayoutData;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalAlign;
	import feathers.layout.VerticalLayout;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.events.Event;
	
	import ui.AppInterface;
	
	import utils.Constants;

	public class SensorStartScreen extends BaseSubScreen
	{
		private var dateSpinner:DateTimeSpinner;
		
		public function SensorStartScreen() 
		{
			super();
			
			/* Set Header Title */
			title = "Start Sensor";
			
			/* Set Header Icon */
			icon = getScreenIcon(MaterialDeepGreyAmberMobileThemeIcons.sensorTexture);
			iconContainer = new <DisplayObject>[icon];
			headerProperties.rightItems = iconContainer;
		}
		
		override protected function initialize():void 
		{
			super.initialize();
			
			Starling.juggler.delayCall(showInitialAlert, 1.25);
			setupContent();
			adjustMainMenu();
		}
		
		private function showInitialAlert():void
		{
			var alert:Alert = Alert.show(
				"You need to set the date and time the sensor was inserted. It's important that you set them as accurately as possible otherwise you might compromisse the accuracy of the readings.",
				"Start Sensor",
				new ListCollection(
					[
						{ label: "OK" }
					]
				)
			);
			alert.messageFactory = function():ITextRenderer
			{
				var messageRenderer:TextBlockTextRenderer = new TextBlockTextRenderer();
				messageRenderer.textJustifier = new SpaceJustifier( "en", LineJustification.ALL_BUT_MANDATORY_BREAK);
				return messageRenderer;
			}
		}
		
		private function setupContent():void
		{
			/* Parent Class Layout */
			layout = new AnchorLayout(); 
			
			/* Create Display Object's Container and Corresponding Vertical Layout and Centered LayoutData */
			var container:LayoutGroup = new LayoutGroup();
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
			dateSpinner.maximum = new Date();
			container.addChild( dateSpinner );
			
			/* Create Start Button */
			var startButton:Button = LayoutFactory.createButton("Start Sensor");
			startButton.addEventListener(Event.TRIGGERED, onSensorStarted);
			container.addChild(startButton);
		}
		
		private function onSensorStarted(e:Event):void
		{
			/* Start Sensor */
			var sensorInsertionDate:Date = dateSpinner.value;
			trace(sensorInsertionDate);
			
			/* Alert */
			var now:Date = new Date();
			var millisecondsTillCalibration:Number = 1000 * 60 * 60 * 2;
			var sum:Number = millisecondsTillCalibration + now.getTime();
			var calibrationDate:Date = new Date(sum);
			
			var alert:Alert = Alert.show(
				"You'll need to wait till " + calibrationDate.toLocaleTimeString() + " before you can input your initial calibrations. Calibration will be done in 2 steps. When the time comes, you will receive a notification for the first 2 readings. You must calibrate in each of these 2 notifications (total of 2 calibrations in a 10 minute span). Keep your device with you and be on the look out for the initial calibration notifications.",
				"Sensor Started!",
				new ListCollection(
					[
						{ label: "OK", triggered: onBackButtonTriggered }
					]
				)
			);
			alert.messageFactory = function():ITextRenderer
			{
				var messageRenderer:TextBlockTextRenderer = new TextBlockTextRenderer();
				messageRenderer.textJustifier = new SpaceJustifier( "en", LineJustification.ALL_BUT_MANDATORY_BREAK);
				return messageRenderer;
			}
			alert.height = 425;
		}	
		
		private function adjustMainMenu():void
		{
			AppInterface.instance.menu.selectedIndex = 3;
		}
		
		override protected function draw():void 
		{
			var layoutInvalid:Boolean = isInvalid( INVALIDATION_FLAG_LAYOUT );
			super.draw();
			icon.x = Constants.stageWidth - icon.width - BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding;
		}
	}
}