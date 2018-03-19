package treatments
{
	import com.freshplanet.ane.AirBackgroundFetch.BackgroundFetch;
	
	import flash.events.EventDispatcher;
	
	import database.BgReading;
	
	import events.TreatmentsEvent;
	
	import feathers.controls.Alert;
	import feathers.controls.DateTimeSpinner;
	import feathers.controls.LayoutGroup;
	import feathers.controls.TextInput;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalLayout;
	
	import model.ModelLocator;
	
	import starling.events.Event;
	
	import ui.popups.AlertManager;
	import ui.screens.display.LayoutFactory;

	public class TreatmentsManager extends EventDispatcher
	{
		/* Constants */
		private static const TIME_24_HOURS:int = 24 * 60 * 60 * 1000;
		
		/* Instance */
		private static var _instance:TreatmentsManager = new TreatmentsManager();
		
		/* Internal variables/objects */
		public static var treatmentsList:Array = [];
		
		public function TreatmentsManager()
		{
			if (_instance != null)
				throw new Error("TreatmentsManager is not meant to be instantiated!");
		}
		
		public static function addInsulin():void
		{
			//Time
			var now:Number = new Date().valueOf();
			
			//Display Container
			var displayLayout:VerticalLayout = new VerticalLayout();
			displayLayout.horizontalAlign = HorizontalAlign.LEFT;
			displayLayout.gap = 10;
			
			var displayContainer:LayoutGroup = new LayoutGroup();
			displayContainer.layout = displayLayout;
			
			//Fields
			var insulinTextInput:TextInput = LayoutFactory.createTextInput(false, false, 159, HorizontalAlign.CENTER, true);
			insulinTextInput.maxChars = 5;
			displayContainer.addChild(insulinTextInput);
			
			var treatmentTime:DateTimeSpinner = new DateTimeSpinner();
			treatmentTime.minimum = new Date(now - TIME_24_HOURS);
			treatmentTime.maximum = new Date(now);
			treatmentTime.value = new Date();
			treatmentTime.height = 30;
			treatmentTime.width = 100;
			displayContainer.addChild(treatmentTime);
			
			var insulinPopup:Alert = AlertManager.showActionAlert
				(
					"Enter Units",
					"",
					Number.NaN,
					[
						{ label: "CANCEL" },
						{ label: "ADD", triggered: onInsulinEntered }
					],
					HorizontalAlign.JUSTIFY,
					displayContainer
				);
			insulinPopup.validate();
			insulinTextInput.width = insulinPopup.width - 20;
			insulinPopup.gap = 0;
			insulinPopup.headerProperties.maxHeight = 30;
			insulinPopup.buttonGroupProperties.paddingTop = -10;
			insulinPopup.buttonGroupProperties.gap = 10;
			insulinPopup.buttonGroupProperties.horizontalAlign = HorizontalAlign.CENTER;
			insulinTextInput.setFocus();
			
			function onInsulinEntered (e:Event):void
			{
				if (insulinTextInput == null || insulinTextInput.text == "" || insulinTextInput.text == null || !BackgroundFetch.appIsInForeground())
					return;
				
				var insulinValue:Number = Number((insulinTextInput.text as String).replace(",","."));
				if (isNaN(insulinValue)) 
				{
					AlertManager.showSimpleAlert
						(
							"Alert",
							"Bolus amount needs to be numeric!",
							Number.NaN,
							onAskNewBolus
						);
					
					function onAskNewBolus():void
					{
						addInsulin();
					}
				}
				else
				{
					var treatment:Treatment = new Treatment
					(
						Treatment.TYPE_BOLUS,
						treatmentTime.value.valueOf(),
						insulinValue,
						2,
						0,
						0,
						getEstimatedGlucose(treatmentTime.value.valueOf()),
						""
					)
					
					//Add to list
					treatmentsList.push(treatment);
					
					//Notify listeners
					_instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.TREATMENT_ADDED, false, false, treatment));
				}
			}
		}
		
		private static function getEstimatedGlucose(timestamp:Number):Number
		{
			var estimatedGlucose:Number = 100;
			
			if (ModelLocator.bgReadings != null && ModelLocator.bgReadings.length > 0)
			{
				for(var i:int = ModelLocator.bgReadings.length - 1 ; i >= 0; i--)
				{
					var reading:BgReading = ModelLocator.bgReadings[i];
					if (reading.timestamp <= timestamp)
					{
						estimatedGlucose = reading.calculatedValue != 0 ? reading.calculatedValue : 100;
						break;
					}
				}
			}
			
			return estimatedGlucose;
		}

		public static function get instance():TreatmentsManager
		{
			return _instance;
		}

	}
}