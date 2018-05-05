package treatments
{
	import com.adobe.utils.DateUtil;
	import com.freshplanet.ane.AirBackgroundFetch.BackgroundFetch;
	
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;
	
	import database.BgReading;
	import database.BlueToothDevice;
	import database.Calibration;
	import database.CommonSettings;
	import database.Database;
	import database.Sensor;
	
	import events.CalibrationServiceEvent;
	import events.SettingsServiceEvent;
	import events.TreatmentsEvent;
	
	import feathers.controls.Alert;
	import feathers.controls.Button;
	import feathers.controls.DateTimeSpinner;
	import feathers.controls.LayoutGroup;
	import feathers.controls.PickerList;
	import feathers.controls.TextInput;
	import feathers.controls.popups.DropDownPopUpContentManager;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.data.ArrayCollection;
	import feathers.events.FeathersEventType;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalLayout;
	
	import model.ModelLocator;
	
	import services.CalibrationService;
	import services.NightscoutService;
	
	import starling.animation.Transitions;
	import starling.animation.Tween;
	import starling.core.Starling;
	import starling.display.Sprite;
	import starling.events.Event;
	
	import ui.AppInterface;
	import ui.popups.AlertManager;
	import ui.screens.Screens;
	import ui.screens.display.LayoutFactory;
	
	import utils.Trace;
	import utils.UniqueId;
	
	[ResourceBundle("treatments")]
	[ResourceBundle("globaltranslations")]

	public class TreatmentsManager extends EventDispatcher
	{
		/* Constants */
		private static const TIME_24_HOURS:int = 24 * 60 * 60 * 1000;
		
		/* Instance */
		private static var _instance:TreatmentsManager = new TreatmentsManager();
		
		/* Internal objects */
		public static var treatmentsList:Array = [];
		private static var treatmentsMap:Dictionary = new Dictionary();
		
		/* Internal Properties */
		public static var pumpIOB:Number = 0;
		public static var pumpCOB:Number = 0;
		
		public function TreatmentsManager()
		{
			if (_instance != null)
				throw new Error("TreatmentsManager is not meant to be instantiated!");
		}
		
		public static function init():void
		{
			Trace.myTrace("TreatmentsManager.as", "init called!");
			
			//Event Listeners
			CalibrationService.instance.addEventListener(CalibrationServiceEvent.INITIAL_CALIBRATION_EVENT, onCalibrationReceived);
			CalibrationService.instance.addEventListener(CalibrationServiceEvent.NEW_CALIBRATION_EVENT, onCalibrationReceived);
			CommonSettings.instance.addEventListener(SettingsServiceEvent.SETTING_CHANGED, onSettingChanged);
			
			//Fetch Data From Database
			if (!BlueToothDevice.isFollower() || ModelLocator.INTERNAL_TESTING)
			{
				Trace.myTrace("TreatmentsManager.as", "Fetching treatments from database...");
				
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
						treatmentsMap[treatment.ID] = treatment;
					}
				}
				
				Trace.myTrace("TreatmentsManager.as", "Fetched " + treatmentsList.length + " treatment(s)");
			}
		}
		
		private static function onSettingChanged(e:SettingsServiceEvent):void
		{
			if (e.data == CommonSettings.COMMON_SETTING_CURRENT_SENSOR && Sensor.getActiveSensor() != null && !NightscoutService.serviceActive )
			{
				addInternalSensorStartTreatment(Sensor.getActiveSensor().startedAt, UniqueId.createEventId());
			}
		}
		
		private static function onCalibrationReceived(e:CalibrationServiceEvent):void 
		{
			//Ensures compatibility with the new method of only one initial calibration
			if (Calibration.allForSensor().length == 1) 
				return;
			
			//No need to do anything. Nightscout service will take care of it
			if (NightscoutService.serviceActive) 
				return;
			
			Trace.myTrace("TreatmentsManager.as", "onCalibrationReceived called! Creating new calibration treatment.");
			
			//Add calibration treatment to Spike
			var lastCalibration:Calibration = Calibration.last();
			TreatmentsManager.addInternalCalibrationTreatment(lastCalibration.bg, lastCalibration.timestamp, UniqueId.createEventId());
		}
		
		public static function getTotalIOB(time:Number):Number
		{
			//OpenAPS/Loop Support. Return value fetched from NS.
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_LOOP_OPENAPS_USER_ENABLED) == "true")
				return pumpIOB;
			
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
		
		public static function setPumpIOB(value:Number):void
		{
			if (isNaN(value))
				value = 0;
			
			pumpIOB = value;
		}
		
		public static function notifyIOBCOB():void
		{
			_instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.IOB_COB_UPDATED));
		}
		
		public static function getTotalCOB(time:Number):Number 
		{
			//OpenAPS/Loop Support. Return value fetched from NS.
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_LOOP_OPENAPS_USER_ENABLED) == "true")
				return pumpCOB;
			
			var carbsAbsorptionRate:Number = ProfileManager.getCarbAbsorptionRate();
			var now:Number = new Date().valueOf();
			
			// TODO: figure out the liverSensRatio that gives the most accurate purple line predictions
			var liverSensRatio:int = 8;
			var totalCOB:Number = 0;
			var lastCarbs:Treatment;
			
			var isDecaying:Number = 0;
			var lastDecayedBy:Number = 0;
			
			if (treatmentsList != null && treatmentsList.length > 0)
			{
				var loopLength:int = treatmentsList.length;
				for (var i:int = 0; i < loopLength; i++) 
				{
					var treatment:Treatment = treatmentsList[i];
					if (treatment != null && (treatment.type == Treatment.TYPE_CARBS_CORRECTION || treatment.type == Treatment.TYPE_MEAL_BOLUS) && time >= treatment.timestamp)
					{
						var cCalc:CobCalc = treatment.calculateCOB(lastDecayedBy, time);
						if (cCalc != null)
						{
							var decaysin_hr:Number = (cCalc.decayedBy - time) / 1000 / 60 / 60;
							
							if (decaysin_hr > -10) 
							{
								// units: BG
								//var actStart = iob.calcTotal(treatments, devicestatus, profile, lastDecayedBy, spec_profile).activity;
								//var actEnd = iob.calcTotal(treatments, devicestatus, profile, cCalc.decayedBy, spec_profile).activity;
								//var avgActivity = (actStart + actEnd) / 2;
								
								// units:  g     =       BG      *      scalar     /          BG / U                           *     g / U
								//var delayedCarbs = ( avgActivity *  liverSensRatio / profile.getSensitivity(treatment.mills, spec_profile) ) * profile.getCarbRatio(treatment.mills, spec_profile);
								//var delayMinutes = Math.round(delayedCarbs / profile.getCarbAbsorptionRate(treatment.mills, spec_profile) * 60);
								//if (delayMinutes > 0) {
								//cCalc.decayedBy.setMinutes(cCalc.decayedBy.getMinutes() + delayMinutes);
								//decaysin_hr = (cCalc.decayedBy - time) / 1000 / 60 / 60;
								//}
								
							}
							
							if (cCalc) 
							{
								//lastDecayedBy = cCalc.decayedBy;
							}
							
							if (decaysin_hr > 0) 
							{
								var treatmentCOB:Number = Math.min(Number(treatment.carbs), decaysin_hr * carbsAbsorptionRate);
								if (isNaN(treatmentCOB))
									treatmentCOB = 0;
								totalCOB += treatmentCOB;
								isDecaying = cCalc.isDecaying;
							} 
							else 
								totalCOB += 0;
						}
						else
							totalCOB += 0;
					}
				}
			}
			
			if (totalCOB < 0)
				totalCOB = 0;
			
			return Math.round(totalCOB * 10) / 10;
			
			/*
			XDRIP
			time = new Date().valueOf(); //MAKE DYNAMIC
			var carbsAbsorptionRate:Number = 30;
			var liverSensRatio:Number = 2;
			
			if (treatmentsList != null && treatmentsList.length > 0)
			{
				var loopLength:int = treatmentsList.length;
				for (var i:int = 0; i < loopLength; i++) 
				{
					var treatment:Treatment = treatmentsList[i];
					if (treatment != null && (treatment.type == Treatment.TYPE_CARBS_CORRECTION || treatment.type == Treatment.TYPE_MEAL_BOLUS))
					{
						if (!isNaN(treatment.carbs) && treatment.carbs > 0)
						{
							var step_minutes:Number = 5;
							var stepms:Number = step_minutes * 60 * 1000; // 600s = 10 mins
							var tendtime:Number = time;
							var dontLookThisFar:Number = 10 * 60 * 60 * 1000; // 10 hours max look
							var carb_delay_minutes:Number = 15; // not likely a time dependent parameter
							var carb_delay_ms_stepped:Number = (carb_delay_minutes / step_minutes) * step_minutes * (60 * 1000);
							
							var mytime:Number = (treatment.timestamp / stepms) * stepms; // effects of treatment occur only after it is given / fit to slot time
							tendtime = mytime + dontLookThisFar;
							
							var cob_time:Number = mytime + carb_delay_ms_stepped;
							var stomachDiff:Number = ((carbsAbsorptionRate * stepms) / (60 * 60 * 1000)); // initial value
							var newdelayedCarbs:Number = 0;
							var cob_remain:Number = treatment.carbs;
							
							while ((cob_remain > 0) && (stomachDiff > 0) && (cob_time < tendtime)) {
								
								//if (cob_time >= time) {
									//timesliceCarbWriter(timeslices, cob_time, cob_remain);
								//}
								cob_time += stepms;
								
								stomachDiff = ((carbsAbsorptionRate * stepms) / (60 * 60 * 1000));
								cob_remain -= stomachDiff;
								
								//newdelayedCarbs = (timesliceIactivityAtTime(timeslices, cob_time) * Profile.getLiverSensRatio(cob_time) / Profile.getSensitivity(cob_time)) * Profile.getCarbRatio(cob_time);
								//newdelayedCarbs = 0 * liverSensRatio / Profile.getSensitivity(cob_time)) * Profile.getCarbRatio(cob_time);
								
								//if (newdelayedCarbs > 0) {
									//final double maximpact = stomachDiff * Profile.maxLiverImpactRatio(cob_time);
									//if (newdelayedCarbs > maximpact) newdelayedCarbs = maximpact;
									//cob_remain += newdelayedCarbs; // add back on liverfactor adjustment
								//}
								
								//counter++;
								
							}
						}
					}
				}
			}*/
		}
		
		public static function setPumpCOB(value:Number):void
		{
			if (isNaN(value))
				value = 0;
			
			pumpCOB = value;
		}
		
		public static function deleteTreatment(treatment:Treatment, updateNightscout:Boolean = true):void
		{
			Trace.myTrace("TreatmentsManager.as", "deleteTreatment called!");
			
			if (treatmentsMap[treatment.ID] != null) //treatment exists
			{
				//Delete from Spike
				for(var i:int = treatmentsList.length - 1 ; i >= 0; i--)
				{
					var spikeTreatment:Treatment = treatmentsList[i] as Treatment;
					if (treatment.ID == spikeTreatment.ID)
					{
						Trace.myTrace("TreatmentsManager.as", "Treatment deleted. Type: " + spikeTreatment.type);
						
						treatmentsList.removeAt(i);
						spikeTreatment = null;
						break;
					}
				}
				treatmentsMap[treatment.ID] = null;
				
				//Notify listeners
				_instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.TREATMENT_DELETED, false, false, treatment));
				
				//Delete from Nightscout
				if (updateNightscout && NightscoutService.serviceActive)
					NightscoutService.deleteTreatment(treatment);
				
				//Delete from databse
				if (!BlueToothDevice.isFollower() || ModelLocator.INTERNAL_TESTING)
					Database.deleteTreatmentSynchronous(treatment);
			}
		}
		
		public static function updateTreatment(treatment:Treatment, updateNightscout:Boolean = true):void
		{
			Trace.myTrace("TreatmentsManager.as", "updateTreatment called! Treatment type: " + treatment.type);
			
			//Notify listeners
			_instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.TREATMENT_UPDATED, false, false, treatment));
			
			//Update in Database
			if (!BlueToothDevice.isFollower() || ModelLocator.INTERNAL_TESTING)
				Database.updateTreatmentSynchronous(treatment);
			
			//Update Nightscout
			if (updateNightscout)
				NightscoutService.uploadTreatment(treatment);
		}
		
		public static function addNightscoutTreatment(treatment:Treatment, uploadToNightscout:Boolean = false):void
		{	
			Trace.myTrace("TreatmentsManager.as", "addNightscoutTreatment called! Treatment type: " + treatment.type);
			
			//Insert in Database
			if (!BlueToothDevice.isFollower() || ModelLocator.INTERNAL_TESTING)
			{
				if (treatmentsMap[treatment.ID] == null) //new treatment
					Database.insertTreatmentSynchronous(treatment);
			}
			
			if (treatmentsMap[treatment.ID] == null) //new treatment
			{
				Trace.myTrace("TreatmentsManager.as", "Adding treatment to Spike...");
				
				//Add treatment to Spike
				treatmentsList.push(treatment);
				treatmentsMap[treatment.ID] = treatment;
				
				//Notify listeners
				_instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.TREATMENT_ADDED, false, false, treatment));
				
				//Upload to Nightscout
				if (uploadToNightscout)
					NightscoutService.uploadTreatment(treatment);
			}
		}
		
		public static function deleteInternalCalibration(timestamp:Number):void
		{
			Trace.myTrace("TreatmentsManager.as", "deleteInternalCalibration called!");
			
			for (var i:int = 0; i < treatmentsList.length; i++) 
			{
				var treatment:Treatment = treatmentsList[i] as Treatment;
				if (treatment.timestamp == timestamp && treatment.type == Treatment.TYPE_GLUCOSE_CHECK && treatment.note == ModelLocator.resourceManagerInstance.getString('treatments','sensor_calibration_note'))
				{
					Trace.myTrace("TreatmentsManager.as", "Calibration found. Deleting...");
					deleteTreatment(treatment);
					break;
				}
			}
		}
		
		public static function addTreatment(type:String):void
		{	
			Trace.myTrace("TreatmentsManager.as", "addTreatment called!");
			
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
				insulinTextInput.addEventListener(FeathersEventType.ENTER, onClearFocus);
				insulinTextInput.maxChars = 5;
				if (type == Treatment.TYPE_MEAL_BOLUS)
					insulinTextInput.prompt = ModelLocator.resourceManagerInstance.getString('treatments','insulin_text_input_prompt');
				displayContainer.addChild(insulinTextInput);
				var insulinSpacer:Sprite = new Sprite();
				insulinSpacer.height = 10;
				displayContainer.addChild(insulinSpacer);
			}
			
			if (type == Treatment.TYPE_GLUCOSE_CHECK)
			{
				//Glucose Amout
				var glucoseTextInput:TextInput = LayoutFactory.createTextInput(false, false, 159, HorizontalAlign.CENTER, true);
				glucoseTextInput.addEventListener(FeathersEventType.ENTER, onClearFocus);
				glucoseTextInput.maxChars = 4;
				displayContainer.addChild(glucoseTextInput);
				var glucoseSpacer:Sprite = new Sprite();
				glucoseSpacer.height = 10;
				displayContainer.addChild(glucoseSpacer);
			}
			
			if (type == Treatment.TYPE_CARBS_CORRECTION || type == Treatment.TYPE_MEAL_BOLUS)
			{
				//Glucose Amout
				var carbsTextInput:TextInput = LayoutFactory.createTextInput(false, false, 159, HorizontalAlign.CENTER, true);
				carbsTextInput.addEventListener(FeathersEventType.ENTER, onClearFocus);
				carbsTextInput.maxChars = 4;
				if (type == Treatment.TYPE_MEAL_BOLUS)
					carbsTextInput.prompt = ModelLocator.resourceManagerInstance.getString('treatments','carbs_text_input_prompt');
				displayContainer.addChild(carbsTextInput);
				var carbSpacer:Sprite = new Sprite();
				carbSpacer.height = 10;
				displayContainer.addChild(carbSpacer);
			}
			
			if (type == Treatment.TYPE_NOTE)
			{
				var noteSpacer:Sprite = new Sprite();
				noteSpacer.height = 10;
				displayContainer.addChild(noteSpacer);
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
				var askForInsulinConfiguration:Boolean = true;
				if (ProfileManager.insulinsList != null && ProfileManager.insulinsList.length > 0)
				{
					var insulinList:PickerList = LayoutFactory.createPickerList();
					var insulinDataProvider:ArrayCollection = new ArrayCollection();
					var userInsulins:Array = sortInsulinsByDefault(ProfileManager.insulinsList.concat());
					var numInsulins:int = userInsulins.length
					for (var i:int = 0; i < numInsulins; i++) 
					{
						var insulin:Insulin = userInsulins[i];
						if (insulin.name.indexOf("Nightscout") == -1)
						{
							insulinDataProvider.push( { label:insulin.name, id: insulin.ID } );
							askForInsulinConfiguration = false;
						}
					}
					insulinList.dataProvider = insulinDataProvider;
					insulinList.popUpContentManager = new DropDownPopUpContentManager();
					insulinList.itemRendererFactory = function():IListItemRenderer
					{
						var renderer:DefaultListItemRenderer = new DefaultListItemRenderer();
						renderer.paddingRight = renderer.paddingLeft = 15;
						return renderer;
					};
					
					if (!askForInsulinConfiguration)
						otherFieldsConstainer.addChild(insulinList);
				}
				
				if (askForInsulinConfiguration)
				{
					var createInsulinButton:Button = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('treatments','configure_insulins_button_label'));
					createInsulinButton.addEventListener(Event.TRIGGERED, onConfigureInsulins);
					otherFieldsConstainer.addChild(createInsulinButton);
					canAddInsulin = false;
				}
			}
			
			var notes:TextInput = LayoutFactory.createTextInput(false, false, treatmentTime.width, HorizontalAlign.CENTER);
			notes.addEventListener(FeathersEventType.ENTER, onClearFocus);
			notes.prompt = ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_note');
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
			actionButtons.push( { label: ModelLocator.resourceManagerInstance.getString('globaltranslations','cancel_button_label').toUpperCase() } );
			if (((type == Treatment.TYPE_BOLUS || type == Treatment.TYPE_MEAL_BOLUS) && canAddInsulin) || type == Treatment.TYPE_NOTE || type == Treatment.TYPE_GLUCOSE_CHECK || type == Treatment.TYPE_CARBS_CORRECTION)
				actionButtons.push( { label: ModelLocator.resourceManagerInstance.getString('globaltranslations','add_button_label').toUpperCase(), triggered: actionFunction } );
			
			//Popup
			var treatmentTitle:String;
			if (type == Treatment.TYPE_BOLUS)
				treatmentTitle = ModelLocator.resourceManagerInstance.getString('treatments','enter_units_label');
			else if (type == Treatment.TYPE_NOTE)
				treatmentTitle = ModelLocator.resourceManagerInstance.getString('treatments','enter_note_label');
			else if (type == Treatment.TYPE_GLUCOSE_CHECK)
				treatmentTitle = ModelLocator.resourceManagerInstance.getString('treatments','enter_bg_label');
			else if (type == Treatment.TYPE_CARBS_CORRECTION)
				treatmentTitle = ModelLocator.resourceManagerInstance.getString('treatments','enter_grams_label');
			else if (type == Treatment.TYPE_MEAL_BOLUS)
				treatmentTitle = ModelLocator.resourceManagerInstance.getString('treatments','enter_meal_label');
				
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
				
				insulinTextInput.text = insulinTextInput.text.replace(" ", "");
				var insulinValue:Number = Number((insulinTextInput.text as String).replace(",","."));
				if (isNaN(insulinValue) || insulinTextInput.text == "") 
				{
					AlertManager.showSimpleAlert
					(
						ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
						ModelLocator.resourceManagerInstance.getString('treatments','non_numeric_insulin'),
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
					treatmentsMap[treatment.ID] = treatment;
					
					Trace.myTrace("TreatmentsManager.as", "Added treatment to Spike. Type: " + treatment.type);
					
					//Notify listeners
					_instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.TREATMENT_ADDED, false, false, treatment));
					
					//Insert in DB
					if (!BlueToothDevice.isFollower() || ModelLocator.INTERNAL_TESTING)
						Database.insertTreatmentSynchronous(treatment);
					
					//Upload to Nightscout
					NightscoutService.uploadTreatment(treatment);
				}
			}
			
			function onCarbsEntered (e:Event):void
			{
				if (carbsTextInput == null || carbsTextInput.text == null || !BackgroundFetch.appIsInForeground())
					return;
				
				carbsTextInput.text = carbsTextInput.text.replace(" ", "");
				var carbsValue:Number = Number((carbsTextInput.text as String).replace(",","."));
				if (isNaN(carbsValue) || carbsTextInput.text == "") 
				{
					AlertManager.showSimpleAlert
					(
						ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
						ModelLocator.resourceManagerInstance.getString('treatments','non_numeric_carbs'),
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
					treatmentsMap[treatment.ID] = treatment;
					
					Trace.myTrace("TreatmentsManager.as", "Added treatment to Spike. Type: " + treatment.type);
					
					//Notify listeners
					_instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.TREATMENT_ADDED, false, false, treatment));
					
					//Insert in DB
					if (!BlueToothDevice.isFollower() || ModelLocator.INTERNAL_TESTING)
						Database.insertTreatmentSynchronous(treatment);
					
					//Upload to Nightscout
					NightscoutService.uploadTreatment(treatment);
				}
			}
			
			function onMealEntered (e:Event):void
			{
				if (insulinTextInput == null || insulinTextInput.text == null || carbsTextInput == null || carbsTextInput.text == null ||!BackgroundFetch.appIsInForeground())
					return;
				
				insulinTextInput.text = insulinTextInput.text.replace(" ", "");
				carbsTextInput.text = carbsTextInput.text.replace(" ", "");
				var insulinValue:Number = Number((insulinTextInput.text as String).replace(",","."));
				var carbsValue:Number = Number((carbsTextInput.text as String).replace(",","."));
				
				if (isNaN(insulinValue) || insulinTextInput.text == "") 
				{
					AlertManager.showSimpleAlert
					(
						ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
						ModelLocator.resourceManagerInstance.getString('treatments','non_numeric_insulin'),
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
						ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
						ModelLocator.resourceManagerInstance.getString('treatments','non_numeric_carbs'),
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
					treatmentsMap[treatment.ID] = treatment;
					
					Trace.myTrace("TreatmentsManager.as", "Added treatment to Spike. Type: " + treatment.type);
					
					//Notify listeners
					_instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.TREATMENT_ADDED, false, false, treatment));
					
					//Insert in DB
					if (!BlueToothDevice.isFollower() || ModelLocator.INTERNAL_TESTING)
						Database.insertTreatmentSynchronous(treatment);
					
					//Upload to Nightscout
					NightscoutService.uploadTreatment(treatment);
				}
			}
			
			function onBGCheckEntered (e:Event):void
			{
				if (glucoseTextInput == null || glucoseTextInput.text == null || !BackgroundFetch.appIsInForeground())
					return;
				
				glucoseTextInput.text = glucoseTextInput.text.replace(" ", "");
				var glucoseValue:Number = Number((glucoseTextInput.text as String).replace(",","."));
				if (isNaN(glucoseValue) || glucoseTextInput.text == "") 
				{
					AlertManager.showSimpleAlert
						(
							ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
							ModelLocator.resourceManagerInstance.getString('treatments','non_numeric_glucose'),
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
					treatmentsMap[treatment.ID] = treatment;
					
					Trace.myTrace("TreatmentsManager.as", "Added treatment to Spike. Type: " + treatment.type);
					
					//Notify listeners
					_instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.TREATMENT_ADDED, false, false, treatment));
					
					//Insert in DB
					if (!BlueToothDevice.isFollower() || ModelLocator.INTERNAL_TESTING)
						Database.insertTreatmentSynchronous(treatment);
					
					//Upload to Nightscout
					NightscoutService.uploadTreatment(treatment);
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
							ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
							ModelLocator.resourceManagerInstance.getString('treatments','empty_note'),
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
					treatmentsMap[treatment.ID] = treatment;
					
					Trace.myTrace("TreatmentsManager.as", "Added treatment to Spike. Type: " + treatment.type);
					
					//Notify listeners
					_instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.TREATMENT_ADDED, false, false, treatment));
					
					//Insert in DB
					if (!BlueToothDevice.isFollower() || ModelLocator.INTERNAL_TESTING)
						Database.insertTreatmentSynchronous(treatment);
					
					//Upload to Nightscout
					NightscoutService.uploadTreatment(treatment);
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
			
			function onClearFocus(e:Event):void
			{
				if (insulinTextInput != null)
					insulinTextInput.clearFocus();
				
				if (carbsTextInput != null)
					carbsTextInput.clearFocus();
				
				if (glucoseTextInput != null)
					glucoseTextInput.clearFocus();
				
				if (notes != null)
					notes.clearFocus();
			}
		}
		
		private static function sortInsulinsByDefault(insulins:Array):Array
		{
			insulins.sortOn(["name"], Array.CASEINSENSITIVE);
			
			for (var i:int = 0; i < insulins.length; i++) 
			{
				var insulin:Insulin = insulins[i];
				if (insulin.isDefault)
				{
					//Remove it from the array
					insulins.removeAt(i);
					
					//Add it to the beginning
					insulins.unshift(insulin);
					
					break;
				}
			}
			
			return insulins;
		}
		
		public static function addExternalTreatment(treatment:Treatment):void
		{
			Trace.myTrace("TreatmentsManager.as", "addExternalTreatment called! Type: " + treatment.type);
			
			//Insert in DB
			if (!BlueToothDevice.isFollower() || ModelLocator.INTERNAL_TESTING)
			{
				if (treatmentsMap[treatment.ID] == null) //new treatment
					Database.insertTreatmentSynchronous(treatment);
			}
			
			if (treatmentsMap[treatment.ID] == null) //new treatment
			{
				//Add to list
				treatmentsList.push(treatment);
				treatmentsMap[treatment.ID] = treatment;
				
				//Notify listeners
				_instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.TREATMENT_ADDED, false, false, treatment));
				
				//Upload to Nightscout
				NightscoutService.uploadTreatment(treatment);
				
				Trace.myTrace("TreatmentsManager.as", "Treatment added to Spike");
			}
		}
		
		public static function addInternalCalibrationTreatment(glucoseValue:Number, timestamp:Number, treatmentID:String):void
		{
			Trace.myTrace("TreatmentsManager.as", "addInternalCalibrationTreatment called!");
			
			var treatment:Treatment = new Treatment
			(
				Treatment.TYPE_GLUCOSE_CHECK,
				timestamp,
				0,
				"",
				0,
				glucoseValue,
				glucoseValue,
				ModelLocator.resourceManagerInstance.getString('treatments','sensor_calibration_note'),
				treatmentID
			);
			
			if (treatmentsMap[treatment.ID] == null) //New treatment
			{
				//Insert in DB
				Database.insertTreatmentSynchronous(treatment);
				
				//Add to list
				treatmentsList.push(treatment);
				treatmentsMap[treatment.ID] = treatment;
				
				//Notify listeners
				_instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.TREATMENT_ADDED, false, false, treatment));
				
				Trace.myTrace("TreatmentsManager.as", "Added internal calibration to Spike!");
			}
		}
		
		public static function addInternalSensorStartTreatment(timestamp:Number, treatmentID:String):void
		{
			Trace.myTrace("TreatmentsManager.as", "addInternalSensorStartTreatment called!");
			
			var treatment:Treatment = new Treatment
				(
					Treatment.TYPE_SENSOR_START,
					timestamp,
					0,
					"",
					0,
					0,
					getEstimatedGlucose(timestamp),
					"",
					treatmentID
				);
			
			if (treatmentsMap[treatment.ID] == null) //New treatment
			{
				//Insert in DB
				Database.insertTreatmentSynchronous(treatment);
				
				//Add to list
				treatmentsList.push(treatment);
				treatmentsMap[treatment.ID] = treatment;
				
				//Notify listeners
				_instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.TREATMENT_ADDED, false, false, treatment));
				
				Trace.myTrace("TreatmentsManager.as", "Added sensor start to Spike!");
			}
		}
		
		public static function processNightscoutTreatments(nsTreatments:Array):void
		{
			Trace.myTrace("TreatmentsManager.as", "processNightscoutTreatments called!");
			
			var nightscoutTreatmentsMap:Dictionary = new Dictionary();
			var numNightscoutTreatments:int = nsTreatments.length;
			var firstReadingTimestamp:Number;
			var lastReadingTimestamp:Number;
			if (ModelLocator.bgReadings != null && ModelLocator.bgReadings.length > 0)
			{
				firstReadingTimestamp = (ModelLocator.bgReadings[0] as BgReading).timestamp;
				lastReadingTimestamp = new Date().valueOf();
			}
			else
			{
				//There's still no readings in Spike. Abort!
				return
			}
				
			for(var i:int = nsTreatments.length - 1 ; i >= 0; i--)
			{
				//Define initial treatment properties
				var nsTreatment:Object = nsTreatments[i];
				var treatmentTimestamp:Number = DateUtil.parseW3CDTF(nsTreatment.created_at).valueOf();
				var treatmentID:String = nsTreatment._id;
				nightscoutTreatmentsMap[treatmentID] = nsTreatment;
				var treatmentEventType:String = nsTreatment.eventType;
				var treatmentType:String = "";
				var treatmentInsulinAmount:Number = 0;
				var treatmentInsulinID:String = "";
				var treatmentCarbs:Number = 0;
				var treatmentGlucose:Number = 0;
				var treatmentNote:String = "";
				
				if (treatmentTimestamp < firstReadingTimestamp || treatmentTimestamp > lastReadingTimestamp)
				{
					//Treatment is outside timespan of first/last bg readings in spike. Let's ignore it
					continue;
				}
				
				if (nsTreatment.note == ModelLocator.resourceManagerInstance.getString('treatments','sensor_calibration_note') && treatmentEventType == "BG Check")
				{
					//Don't process sensor calibrations
					continue;
				}
				
				if (treatmentEventType == "Correction Bolus" || treatmentEventType == "Bolus" || treatmentEventType == "Correction")
				{
					treatmentType = Treatment.TYPE_BOLUS;
					if (nsTreatment.insulin != null)
						treatmentInsulinAmount = Number(nsTreatment.insulin);
					treatmentInsulinID = "000000";
				}
				else if (treatmentEventType == "Meal Bolus" || treatmentEventType == "Snack Bolus")
				{
					treatmentType = Treatment.TYPE_MEAL_BOLUS;
					if (nsTreatment.insulin != null)
						treatmentInsulinAmount = Number(nsTreatment.insulin);
					treatmentInsulinID = "000000";
					if (nsTreatment.carbs != null)
						treatmentCarbs = Number(nsTreatment.carbs);
				}
				else if (treatmentEventType == "Carb Correction" || treatmentEventType == "Carbs")
				{
					treatmentType = Treatment.TYPE_CARBS_CORRECTION;
					if (nsTreatment.carbs != null)
						treatmentCarbs = Number(nsTreatment.carbs);
				}
				else if (treatmentEventType == "Note")
					treatmentType = Treatment.TYPE_NOTE;
				else if (treatmentEventType == "Sensor Start")
					treatmentType = Treatment.TYPE_SENSOR_START;
				else if (treatmentEventType == "BG Check")
				{
					treatmentType = Treatment.TYPE_GLUCOSE_CHECK;
					var glucoseValue:Number = Number(nsTreatment.glucose);
					if (glucoseValue < 25) //It's mmol
						glucoseValue = Math.round(BgReading.mmolToMgdl(glucoseValue));
					
					treatmentGlucose = glucoseValue;
				}
				
				if (nsTreatment.foodType != null && nsTreatment.foodType != "")
					treatmentNote += nsTreatment.foodType;
				
				if (nsTreatment.notes != null && nsTreatment.notes != "")
					treatmentNote += (treatmentNote != "" ? "\n" : "") + nsTreatment.notes;
				
				//Check if treatment is supported by Spike
				if (treatmentType != "")
				{
					//Check if treatment already exists in Spike
					if (treatmentsMap[treatmentID] == null)
					{
						//It's a new treatment. Let's create it
						var treatment:Treatment = new Treatment
						(
							treatmentType,
							treatmentTimestamp,
							treatmentInsulinAmount,
							treatmentInsulinID,
							treatmentCarbs,
							treatmentGlucose,
							treatmentEventType != "BG Check" ? getEstimatedGlucose(treatmentTimestamp) : treatmentGlucose,
							treatmentNote,
							treatmentID
						);
						
						//Add treatment to Spike and Databse
						addNightscoutTreatment(treatment);
						
						Trace.myTrace("TreatmentsManager.as", "Added nightscout treatment. Type: " + treatmentType);
					}
					else
					{
						//Treatment exists... Lets check if it was modified
						var wasTreatmentModified:Boolean = false;
						var spikeTreatment:Treatment = treatmentsMap[treatmentID];
						if (!isNaN(treatmentCarbs) && spikeTreatment.carbs != treatmentCarbs)
						{
							spikeTreatment.carbs = treatmentCarbs;
							wasTreatmentModified = true;
						}
						if (!isNaN(treatmentGlucose) && Math.abs(spikeTreatment.glucose - treatmentGlucose) >= 1) //Nightscout rounds values so we just check if the glucose value differnce is bigger than 1 to avoid triggering this on every treatment
						{
							spikeTreatment.glucose = treatmentGlucose;
							wasTreatmentModified = true;
						}
						if (!isNaN(treatmentInsulinAmount) && spikeTreatment.insulinAmount != treatmentInsulinAmount)
						{
							spikeTreatment.insulinAmount = treatmentInsulinAmount;
							wasTreatmentModified = true;
						}
						if (spikeTreatment.note != treatmentNote)
						{
							spikeTreatment.note = treatmentNote;
							wasTreatmentModified = true;
						}
						if (Math.abs(spikeTreatment.timestamp - treatmentTimestamp) > 1000) //parseW3CDTF ignores ms so we just check if the time difference is bigger than 1 sec to determine if the user changed the treatment type. This avoids triggering this on every treatment.
						{
							spikeTreatment.timestamp = treatmentTimestamp;
							spikeTreatment.glucoseEstimated = treatmentType != Treatment.TYPE_GLUCOSE_CHECK ? getEstimatedGlucose(treatmentTimestamp) : spikeTreatment.glucose;
							wasTreatmentModified = true;
						}
						
						if (wasTreatmentModified)
						{
							//Treatment was modified. Update Spike and notify listeners
							updateTreatment(spikeTreatment, false);
							_instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.TREATMENT_EXTERNALLY_MODIFIED, false, false, spikeTreatment));
							
							Trace.myTrace("TreatmentsManager.as", "Updated nightscout treatment. Type: " + spikeTreatment.type);
						}
					}
				}
			}
			
			//Check for deleted treatments in Nightscout
			var numSpikeTreatments:int = treatmentsList.length;
			if (numNightscoutTreatments < numSpikeTreatments)
			{
				for (var j:int = 0; j <numSpikeTreatments; j++) 
				{
					var internalTreatment:Treatment = treatmentsList[j];
					
					if (internalTreatment.type == Treatment.TYPE_GLUCOSE_CHECK && internalTreatment.note == ModelLocator.resourceManagerInstance.getString('treatments','sensor_calibration_note'))
					{
						//Don't delete calibration treatments
						continue;
					}
					
					if (nightscoutTreatmentsMap[internalTreatment.ID] == null)
					{
						Trace.myTrace("TreatmentsManager.as", "User deleted treatment in Nightscout. Deleting in Spike as well. Type: " + internalTreatment.type);
						
						//Notify Listeners
						_instance.dispatchEvent(new TreatmentsEvent(TreatmentsEvent.TREATMENT_EXTERNALLY_DELETED, false, false, internalTreatment));
						
						//Treatment is not present in Nightscout. User has deleted it
						deleteTreatment(internalTreatment, false);
					}
				}
			}
			
			//Sort treatments
			treatmentsList.sortOn(["timestamp"], Array.NUMERIC);
		}
		
		public static function removeTreatmentFromMemory(treatment:Treatment):void
		{
			Trace.myTrace("TreatmentsManager.as", "removeTreatmentFromMemory called!");
			
			//Validation
			if (treatment == null)
				return;
			
			//Remove from list
			for (var i:int = 0; i < treatmentsList.length; i++) 
			{
				var internalTreatment:Treatment = treatmentsList[i];
				if (internalTreatment != null && internalTreatment.ID == treatment.ID)
				{
					Trace.myTrace("TreatmentsManager.as", "Removed expired treatment. Type: " + internalTreatment.type);
					treatmentsList.removeAt(i);
					break;
				}
			}
			
			//Remove from map
			treatmentsMap[treatment.ID] = null;
			
			//Dispose
			treatment = null;
		}
		
		public static function removeAllTreatmentsFromMemory():void
		{
			treatmentsList.length = 0;
			treatmentsMap = new Dictionary();
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