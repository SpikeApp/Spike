package treatments
{
	import com.freshplanet.ane.AirBackgroundFetch.BackgroundFetch;
	
	import flash.events.EventDispatcher;
	
	import database.BgReading;
	import database.CommonSettings;
	import database.Database;
	
	import events.TreatmentsEvent;
	
	import feathers.controls.Alert;
	import feathers.controls.Button;
	import feathers.controls.DateTimeSpinner;
	import feathers.controls.LayoutGroup;
	import feathers.controls.PickerList;
	import feathers.controls.TextInput;
	import feathers.controls.popups.DropDownPopUpContentManager;
	import feathers.data.ArrayCollection;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalLayout;
	
	import model.ModelLocator;
	
	import starling.animation.Transitions;
	import starling.animation.Tween;
	import starling.core.Starling;
	import starling.display.Sprite;
	import starling.events.Event;
	
	import ui.AppInterface;
	import ui.popups.AlertManager;
	import ui.screens.Screens;
	import ui.screens.display.LayoutFactory;

	public class TreatmentsManager extends EventDispatcher
	{
		/* Constants */
		private static const TIME_24_HOURS:int = 24 * 60 * 60 * 1000;
		public static const TREATMENT_TYPE_BOLUS:String = "bolus";
		
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
		
		public static function getTotalIOB(time:Number):Number
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
						totalIOB += treatment.calculateIOB(time);
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
		
		public static function addTreatment(type:String):void
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
			if (type == Treatment.TYPE_BOLUS || type == Treatment.TYPE_CORRECTION_BOLUS || type == Treatment.TYPE_MEAL_BOLUS)
			{
				//Logical
				var canAddInsulin:Boolean = true;
				
				//Insulin Amout
				var insulinTextInput:TextInput = LayoutFactory.createTextInput(false, false, 159, HorizontalAlign.CENTER, true);
				insulinTextInput.maxChars = 5;
				if (type == Treatment.TYPE_MEAL_BOLUS)
					insulinTextInput.prompt = "Insulin";
				displayContainer.addChild(insulinTextInput);
				var insulinSpacer:Sprite = new Sprite();
				insulinSpacer.height = 10;
				displayContainer.addChild(insulinSpacer);
			}
			
			if (type == Treatment.TYPE_GLUCOSE_CHECK)
			{
				//Glucose Amout
				var glucoseTextInput:TextInput = LayoutFactory.createTextInput(false, false, 159, HorizontalAlign.CENTER, true);
				glucoseTextInput.maxChars = 3;
				displayContainer.addChild(glucoseTextInput);
				var glucoseSpacer:Sprite = new Sprite();
				glucoseSpacer.height = 10;
				displayContainer.addChild(glucoseSpacer);
			}
			
			if (type == Treatment.TYPE_CARBS_CORRECTION || type == Treatment.TYPE_MEAL_BOLUS)
			{
				//Glucose Amout
				var carbsTextInput:TextInput = LayoutFactory.createTextInput(false, false, 159, HorizontalAlign.CENTER, true);
				carbsTextInput.maxChars = 4;
				if (type == Treatment.TYPE_MEAL_BOLUS)
					carbsTextInput.prompt = "Carbs";
				displayContainer.addChild(carbsTextInput);
				var carbSpacer:Sprite = new Sprite();
				carbSpacer.height = 10;
				displayContainer.addChild(carbSpacer);
			}
			
			//Treatment Time
			var treatmentTime:DateTimeSpinner = new DateTimeSpinner();
			treatmentTime.minimum = new Date(now - TIME_24_HOURS);
			treatmentTime.maximum = new Date(now);
			treatmentTime.value = new Date();
			treatmentTime.height = 30;
			displayContainer.addChild(treatmentTime);
			treatmentTime.validate();
			var treatmentSpacer:Sprite = new Sprite();
			treatmentSpacer.height = 10;
			displayContainer.addChild(treatmentSpacer);
			
			if (type == Treatment.TYPE_BOLUS || type == Treatment.TYPE_CORRECTION_BOLUS || type == Treatment.TYPE_MEAL_BOLUS)
				insulinTextInput.width = treatmentTime.width;
			if (type == Treatment.TYPE_GLUCOSE_CHECK)
				glucoseTextInput.width = treatmentTime.width;
			if (type == Treatment.TYPE_CARBS_CORRECTION || type == Treatment.TYPE_MEAL_BOLUS)
				carbsTextInput.width = treatmentTime.width;
			
			//Other Fields constainer
			var otherFieldsLayout:VerticalLayout = new VerticalLayout();
			otherFieldsLayout.horizontalAlign = HorizontalAlign.CENTER
			otherFieldsLayout.gap = 10;
			var otherFieldsConstainer:LayoutGroup = new LayoutGroup();
			otherFieldsConstainer.layout = otherFieldsLayout;
			otherFieldsConstainer.width = treatmentTime.width;
			displayContainer.addChild(otherFieldsConstainer);
			
			if (type == Treatment.TYPE_BOLUS || type == Treatment.TYPE_CORRECTION_BOLUS || type == Treatment.TYPE_MEAL_BOLUS)
			{
				//Insulin Type
				if (ProfileManager.insulinsList != null && ProfileManager.insulinsList.length > 0)
				{
					var insulinList:PickerList = LayoutFactory.createPickerList();
					var insulinDataProvider:ArrayCollection = new ArrayCollection();
					var numInsulins:int = ProfileManager.insulinsList.length
					for (var i:int = 0; i < numInsulins; i++) 
					{
						var insulin:Insulin = ProfileManager.insulinsList[i];
						insulinDataProvider.push( { label:insulin.name, id: insulin.ID } );
					}
					insulinList.dataProvider = insulinDataProvider;
					insulinList.popUpContentManager = new DropDownPopUpContentManager();
					otherFieldsConstainer.addChild(insulinList);
				}
				else
				{
					var createInsulinButton:Button = LayoutFactory.createButton("Configure Insulins");
					createInsulinButton.addEventListener(Event.TRIGGERED, onConfigureInsulins);
					otherFieldsConstainer.addChild(createInsulinButton);
					canAddInsulin = false;
				}
			}
			
			var notes:TextInput = LayoutFactory.createTextInput(false, false, treatmentTime.width, HorizontalAlign.CENTER);
			notes.prompt = "Note";
			notes.maxChars = 50;
			otherFieldsConstainer.addChild(notes);
			
			//Action Buttons
			var actionFunction:Function;
			if (type == Treatment.TYPE_BOLUS)
				actionFunction = onInsulinEntered;
			else if (type == Treatment.TYPE_NOTE)
				actionFunction = onNoteEntered;
			else if (type == Treatment.TYPE_GLUCOSE_CHECK)
				actionFunction = onBGCheckEntered;
			else if (type == Treatment.TYPE_CARBS_CORRECTION)
				actionFunction = onCarbsEntered;
			else if (type == Treatment.TYPE_MEAL_BOLUS)
				actionFunction = onMealEntered;
			
			var actionButtons:Array = [];
			actionButtons.push( { label: "CANCEL" } );
			if (((type == Treatment.TYPE_BOLUS || type == Treatment.TYPE_MEAL_BOLUS) && canAddInsulin) || type == Treatment.TYPE_NOTE || type == Treatment.TYPE_GLUCOSE_CHECK || type == Treatment.TYPE_CARBS_CORRECTION)
				actionButtons.push( { label: "ADD", triggered: actionFunction } );
			
			//Popup
			var treatmentTitle:String;
			if (type == Treatment.TYPE_BOLUS)
				treatmentTitle = "Enter Units";
			else if (type == Treatment.TYPE_NOTE)
				treatmentTitle = "Enter Note";
			else if (type == Treatment.TYPE_GLUCOSE_CHECK)
				treatmentTitle = "Enter Blood Glucose";
			else if (type == Treatment.TYPE_CARBS_CORRECTION)
				treatmentTitle = "Enter Grams";
			else if (type == Treatment.TYPE_MEAL_BOLUS)
				treatmentTitle = "Enter Meal";
				
			var treatmentPopup:Alert = AlertManager.showActionAlert
				(
					treatmentTitle,
					"",
					Number.NaN,
					actionButtons,
					HorizontalAlign.JUSTIFY,
					displayContainer
				);
			treatmentPopup.gap = 5;
			treatmentPopup.headerProperties.maxHeight = 30;
			treatmentPopup.buttonGroupProperties.paddingTop = -10;
			treatmentPopup.buttonGroupProperties.gap = 10;
			treatmentPopup.buttonGroupProperties.horizontalAlign = HorizontalAlign.CENTER;
			
			//Keyboard Focus
			if (type == Treatment.TYPE_BOLUS || type == Treatment.TYPE_CORRECTION_BOLUS || type == Treatment.TYPE_MEAL_BOLUS)
				insulinTextInput.setFocus();
			else if (type == Treatment.TYPE_NOTE)
				notes.setFocus();
			else if (type == Treatment.TYPE_GLUCOSE_CHECK)
				glucoseTextInput.setFocus();
			else if (type == Treatment.TYPE_CARBS_CORRECTION)
				carbsTextInput.setFocus();
			
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
						addTreatment(type);
					}
				}
				else
				{
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
					);
					
					//Add to list
					treatmentsList.push(treatment);
					
					//Notify listeners
					_instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.TREATMENT_ADDED, false, false, treatment));
					
					//Insert in DB
					Database.insertTreatmentSynchronous(treatment);
				}
			}
			
			function onCarbsEntered (e:Event):void
			{
				if (carbsTextInput == null || carbsTextInput.text == null || !BackgroundFetch.appIsInForeground())
					return;
				
				var carbsValue:Number = Number((carbsTextInput.text as String).replace(",","."));
				if (isNaN(carbsValue) || carbsTextInput.text == "") 
				{
					AlertManager.showSimpleAlert
					(
						"Alert",
						"Carbs amount needs to be numeric!",
						Number.NaN,
						onAskNewCarbs
					);
					
					function onAskNewCarbs():void
					{
						addTreatment(type);
					}
				}
				else
				{
					var treatment:Treatment = new Treatment
					(
						Treatment.TYPE_CARBS_CORRECTION,
						treatmentTime.value.valueOf(),
						0,
						"",
						carbsValue,
						0,
						getEstimatedGlucose(treatmentTime.value.valueOf()),
						notes.text
					);
					
					//Add to list
					treatmentsList.push(treatment);
					
					//Notify listeners
					_instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.TREATMENT_ADDED, false, false, treatment));
					
					//Insert in DB
					Database.insertTreatmentSynchronous(treatment);
				}
			}
			
			function onMealEntered (e:Event):void
			{
				if (insulinTextInput == null || insulinTextInput.text == null || carbsTextInput == null || carbsTextInput.text == null ||!BackgroundFetch.appIsInForeground())
					return;
				
				var insulinValue:Number = Number((insulinTextInput.text as String).replace(",","."));
				var carbsValue:Number = Number((carbsTextInput.text as String).replace(",","."));
				
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
						addTreatment(type);
					}
				}
				else if (isNaN(carbsValue) || carbsTextInput.text == "") 
				{
					AlertManager.showSimpleAlert
						(
							"Alert",
							"Carbs amount needs to be numeric!",
							Number.NaN,
							onAskNewCarbs
						);
					
					function onAskNewCarbs():void
					{
						addTreatment(type);
					}
				}
				else
				{
					var treatment:Treatment = new Treatment
						(
							Treatment.TYPE_MEAL_BOLUS,
							treatmentTime.value.valueOf(),
							insulinValue,
							insulinList.selectedItem.id,
							carbsValue,
							0,
							getEstimatedGlucose(treatmentTime.value.valueOf()),
							notes.text
						);
					
					//Add to list
					treatmentsList.push(treatment);
					
					//Notify listeners
					_instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.TREATMENT_ADDED, false, false, treatment));
					
					//Insert in DB
					Database.insertTreatmentSynchronous(treatment);
				}
			}
			
			function onBGCheckEntered (e:Event):void
			{
				if (glucoseTextInput == null || glucoseTextInput.text == null || !BackgroundFetch.appIsInForeground())
					return;
				
				var glucoseValue:Number = Number((glucoseTextInput.text as String).replace(",","."));
				if (isNaN(glucoseValue) || glucoseTextInput.text == "") 
				{
					AlertManager.showSimpleAlert
						(
							"Alert",
							"Glucose amount needs to be numeric!",
							Number.NaN,
							onAskNewGlucose
						);
					
					function onAskNewGlucose():void
					{
						addTreatment(type);
					}
				}
				else
				{
					
					var glucoseValueToAdd:Number;
					if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true")
						glucoseValueToAdd = glucoseValue;
					else
						glucoseValueToAdd = Math.round(BgReading.mmolToMgdl(glucoseValue))
					
					var treatment:Treatment = new Treatment
					(
						Treatment.TYPE_GLUCOSE_CHECK,
						treatmentTime.value.valueOf(),
						0,
						"",
						0,
						glucoseValueToAdd,
						glucoseValueToAdd,
						notes.text
					);
					
					//Add to list
					treatmentsList.push(treatment);
					
					//Notify listeners
					_instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.TREATMENT_ADDED, false, false, treatment));
					
					//Insert in DB
					Database.insertTreatmentSynchronous(treatment);
				}
			}
			
			function onNoteEntered (e:Event):void
			{
				if (notes == null || notes.text == null || !BackgroundFetch.appIsInForeground())
					return;
				
				if (notes.text == "")
				{
					AlertManager.showSimpleAlert
						(
							"Alert",
							"Note cannot be empty!",
							Number.NaN,
							onAskNewNote
						);
					
					function onAskNewNote():void
					{
						addTreatment(type);
					}
				}
				else
				{
					var treatment:Treatment = new Treatment
						(
							Treatment.TYPE_NOTE,
							treatmentTime.value.valueOf(),
							0,
							"",
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
			
			function onConfigureInsulins(e:Event):void
			{
				AppInterface.instance.navigator.pushScreen( Screens.SETTINGS_PROFILE );
				
				var popupTween:Tween=new Tween(treatmentPopup, 0.3, Transitions.LINEAR);
				popupTween.fadeTo(0);
				popupTween.onComplete = function():void
				{
					treatmentPopup.removeFromParent(true);
				}
				Starling.juggler.add(popupTween);
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