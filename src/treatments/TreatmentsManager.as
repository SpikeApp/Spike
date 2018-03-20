package treatments
{
	import com.freshplanet.ane.AirBackgroundFetch.BackgroundFetch;
	
	import flash.events.EventDispatcher;
	
	import mx.utils.ObjectUtil;
	
	import database.BgReading;
	import database.Database;
	
	import events.TreatmentsEvent;
	
	import feathers.controls.Alert;
	import feathers.controls.DateTimeSpinner;
	import feathers.controls.LayoutGroup;
	import feathers.controls.PickerList;
	import feathers.controls.TextArea;
	import feathers.controls.TextInput;
	import feathers.controls.popups.DropDownPopUpContentManager;
	import feathers.data.ArrayCollection;
	import feathers.events.FeathersEventType;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.HorizontalLayout;
	import feathers.layout.RelativePosition;
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
		
		public static function init():void
		{
			var now:Number = new Date().valueOf();
			var dbTreatments:Array = Database.getTreatmentsSynchronous(now - TIME_24_HOURS, now);
			
			if (dbTreatments != null && dbTreatments.length > 0)
			{
				for (var i:int = 0; i < dbTreatments.length; i++) 
				{
					var dbTreatment:Object = dbTreatments[i] as Object;
					if (dbTreatment == null)
						continue;
					
					var treatment:Treatment = new Treatment
					(
						dbTreatment.type,
						dbTreatment.lastmodifiedtimestamp,
						dbTreatment.insulinamount,
						dbTreatment.insulinid,
						dbTreatment.carbs,
						dbTreatment.glucose,
						dbTreatment.glucoseestimated,
						dbTreatment.note
					);
					treatment.ID = dbTreatment.id;
					
					treatmentsList.push(treatment);
				}
			}
		}
		
		public static function getTotalIOB():Number
		{
			var totalIOB:Number = 0;
			
			if (treatmentsList != null && treatmentsList.length > 0)
			{
				var loopLength:int = treatmentsList.length;
				for (var i:int = 0; i < loopLength; i++) 
				{
					var treatment:Treatment = treatmentsList[i];
					if (treatment != null && (treatment.type == Treatment.TYPE_BOLUS || treatment.type == Treatment.TYPE_CORRECTION_BOLUS || treatment.type == Treatment.TYPE_MEAL_BOLUS))
					{
						totalIOB += treatment.calculateIOB();
					}
				}
			}
			
			totalIOB = Math.floor(totalIOB * 100) / 100;
			
			if (isNaN(totalIOB))
				totalIOB = 0;
			
			return totalIOB;
		}
		
		public static function deleteTreatment(treatment:Treatment):void
		{
			//Delete from Spike
			for(var i:int = treatmentsList.length - 1 ; i >= 0; i--)
			{
				var spikeTreatment:Treatment = treatmentsList[i] as Treatment;
				if (treatment.ID == spikeTreatment.ID)
				{
					treatmentsList.removeAt(i);
					spikeTreatment = null;
					break;
				}
			}
			
			//Delete from databse
			Database.deleteTreatmentSynchronous(treatment);
		}
		
		public static function updateTreatment(treatment:Treatment):void
		{
			//Update in Database
			Database.updateTreatmentSynchronous(treatment);
		}
		
		public static function addInsulin():void
		{
			//Logical
			var canAddInsulin:Boolean = true;
			
			//Time
			var now:Number = new Date().valueOf();
			
			//Display Container
			var displayLayout:VerticalLayout = new VerticalLayout();
			displayLayout.horizontalAlign = HorizontalAlign.LEFT;
			displayLayout.gap = 10;
			
			var displayContainer:LayoutGroup = new LayoutGroup();
			displayContainer.layout = displayLayout;
			
			//Fields
			//Insulin Amout
			var insulinTextInput:TextInput = LayoutFactory.createTextInput(false, false, 159, HorizontalAlign.CENTER, true);
			insulinTextInput.maxChars = 5;
			displayContainer.addChild(insulinTextInput);
			
			//Insulin Time
			var treatmentTime:DateTimeSpinner = new DateTimeSpinner();
			treatmentTime.minimum = new Date(now - TIME_24_HOURS);
			treatmentTime.maximum = new Date(now);
			treatmentTime.value = new Date();
			treatmentTime.height = 30;
			//treatmentTime.width = 100;
			displayContainer.addChild(treatmentTime);
			treatmentTime.validate();
			insulinTextInput.width = treatmentTime.width;
			
			//Other Fields constainer
			var otherFieldsLayout:VerticalLayout = new VerticalLayout();
			otherFieldsLayout.horizontalAlign = HorizontalAlign.CENTER
			otherFieldsLayout.gap = 10;
			var otherFieldsConstainer:LayoutGroup = new LayoutGroup();
			otherFieldsConstainer.layout = otherFieldsLayout;
			otherFieldsConstainer.width = insulinTextInput.width;
			displayContainer.addChild(otherFieldsConstainer);
			
			//Insulin Type
			var insulinList:PickerList = LayoutFactory.createPickerList();
			var insulinDataProvider:ArrayCollection = new ArrayCollection();
			if (ProfileManager.insulinsList != null && ProfileManager.insulinsList.length > 0)
			{
				var numInsulins:int = ProfileManager.insulinsList.length
				for (var i:int = 0; i < numInsulins; i++) 
				{
					var insulin:Insulin = ProfileManager.insulinsList[i];
					insulinDataProvider.push( { label:insulin.name, id: insulin.ID } );
				}
			}
			else
			{
				insulinList.prompt = "No available insulins";
				insulinList.selectedIndex = -1;
				canAddInsulin = false;
			}
			insulinList.dataProvider = insulinDataProvider;
			insulinList.popUpContentManager = new DropDownPopUpContentManager();
			otherFieldsConstainer.addChild(insulinList);
			
			var notes:TextInput = LayoutFactory.createTextInput(false, false, treatmentTime.width, HorizontalAlign.CENTER);
			notes.prompt = "Notes";
			otherFieldsConstainer.addChild(notes);
			
			//Action Buttons
			var actionButtons:Array = [];
			actionButtons.push( { label: "CANCEL" } );
			if (canAddInsulin)
				actionButtons.push( { label: "ADD", triggered: onInsulinEntered } );
			
			var insulinPopup:Alert = AlertManager.showActionAlert
				(
					"Enter Units",
					"",
					Number.NaN,
					actionButtons,
					HorizontalAlign.JUSTIFY,
					displayContainer
				);
			insulinPopup.gap = 0;
			insulinPopup.headerProperties.maxHeight = 30;
			insulinPopup.buttonGroupProperties.paddingTop = -10;
			insulinPopup.buttonGroupProperties.gap = 10;
			insulinPopup.buttonGroupProperties.horizontalAlign = HorizontalAlign.CENTER;
			insulinTextInput.setFocus();
			
			treatmentTime.addEventListener(FeathersEventType.CREATION_COMPLETE, onCreationComplete);
			function onCreationComplete(e:Event):void
			{
				insulinPopup.validate();
			}
			
			function onInsulinEntered (e:Event):void
			{
				if (insulinTextInput == null || insulinTextInput.text == null || !BackgroundFetch.appIsInForeground())
					return;
				
				var insulinValue:Number = Number((insulinTextInput.text as String).replace(",","."));
				if (isNaN(insulinValue) || insulinTextInput.text == "") 
				{
					AlertManager.showSimpleAlert
						(
							"Alert",
							"Insulin amount needs to be numeric!",
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
					trace("insulinList.selectedItem.id", insulinList.selectedItem.id);
					
					var treatment:Treatment = new Treatment
					(
						Treatment.TYPE_BOLUS,
						treatmentTime.value.valueOf(),
						insulinValue,
						insulinList.selectedItem.id,
						0,
						0,
						getEstimatedGlucose(treatmentTime.value.valueOf()),
						notes.text
					)
					
					//Add to list
					treatmentsList.push(treatment);
					
					//Notify listeners
					_instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.TREATMENT_ADDED, false, false, treatment));
					
					//Insert in DB
					Database.insertTreatmentSynchronous(treatment);
				}
			}
		}
		
		public static function getEstimatedGlucose(timestamp:Number):Number
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