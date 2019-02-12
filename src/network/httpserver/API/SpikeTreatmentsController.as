package network.httpserver.API
{
	import flash.net.URLVariables;
	
	import mx.utils.ObjectUtil;
	
	import database.BgReading;
	import database.CGMBlueToothDevice;
	import database.CommonSettings;
	
	import model.ModelLocator;
	
	import network.httpserver.ActionController;
	
	import treatments.Insulin;
	import treatments.ProfileManager;
	import treatments.Treatment;
	import treatments.TreatmentsManager;
	
	import utils.Trace;
	
	public class SpikeTreatmentsController extends ActionController
	{
		public function SpikeTreatmentsController(path:String)
		{
			super(path);
		}
		
		/**
		 * Functionality
		 */
		public function AddTreatment(params:URLVariables):String
		{
			Trace.myTrace("SpikeTreatmentsController.as", "AddTreatment endpoint called!");
			
			if (CGMBlueToothDevice.isFollower() && (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_URL) == "" || CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_API_SECRET) == "" || CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FOLLOWER_MODE) != "Nightscout"))
				return responseSuccess("Follower doesn't have enough privileges to add treatments!");
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_ENABLED) != "true")
				return responseSuccess("Treatments are not enabled in Spike!");
			
			var response:String = "OK";
			var treatmentType:String = "";
			try
			{
				if (params != null)
				{
					trace("params");
					trace(ObjectUtil.toString(params));
					
					//Define initial treatment properties
					var treatmentTimestamp:Number = new Date().valueOf();
					treatmentType = String(params.type);
					var treatmentInsulinAmount:Number = 0;
					var treatmentInsulinID:String = "";
					var treatmentCarbs:Number = 0;
					var treatmentGlucose:Number = 0;
					var treatmentNote:String = "";
					var treatmentCarbDelayTime:Number = 20;
					var treatmentDuration:Number = Number.NaN;
					var treatmentExerciseIntensity:String = Treatment.EXERCISE_INTENSITY_MODERATE;
					var basalAmount:Number = 0;
					var basalDuration:Number = 30;
					var isBasalAbsolute:Boolean = false;
					var isBasalRelative:Boolean = false;
					var isTempBasalEnd:Boolean = false;
					
					if (treatmentType == Treatment.TYPE_CORRECTION_BOLUS || treatmentType == Treatment.TYPE_BOLUS)
					{
						if (params.insulin != null && Number(params.insulin) != 0)
							treatmentInsulinAmount = Number(String(params.insulin).replace(",", "."));
						else
							response = "ERROR";
						
						treatmentInsulinID = ProfileManager.getDefaultInsulinID();
					}
					else if (treatmentType == Treatment.TYPE_MEAL_BOLUS)
					{
						if (params.insulin != null && params.carbs != null && Number(params.carbs) == 0 && Number(params.insulin) == 0)
							response = "ERROR";
						else if (params.insulin == null || params.carbs == null)
							response = "ERROR";
						else
						{
							treatmentInsulinAmount = Number(String(params.insulin).replace(",", "."));
							treatmentInsulinID = ProfileManager.getDefaultInsulinID();
							treatmentCarbs = Number(String(params.carbs).replace(",", "."));
						}
						
						if (params.carbtype != null)
						{
							if (params.carbtype == "fast")
								treatmentCarbDelayTime = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CARB_FAST_ABSORTION_TIME));
							else if (params.carbtype == "medium")
								treatmentCarbDelayTime = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CARB_MEDIUM_ABSORTION_TIME));
							else if (params.carbtype == "slow")
								treatmentCarbDelayTime = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CARB_SLOW_ABSORTION_TIME));
						}
					}
					else if (treatmentType == Treatment.TYPE_CARBS_CORRECTION)
					{
						if (params.carbs != null && Number(params.carbs) != 0)
							treatmentCarbs = Number(String(params.carbs).replace(",", "."));
						else
							response = "ERROR";
						
						if (params.carbtype != null)
						{
							if (params.carbtype == "fast")
								treatmentCarbDelayTime = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CARB_FAST_ABSORTION_TIME));
							else if (params.carbtype == "medium")
								treatmentCarbDelayTime = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CARB_MEDIUM_ABSORTION_TIME));
							else if (params.carbtype == "slow")
								treatmentCarbDelayTime = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CARB_SLOW_ABSORTION_TIME));
						}
					}
					else if (treatmentType == Treatment.TYPE_GLUCOSE_CHECK)
					{
						if (params.glucose != null && Number(params.glucose) != 0)
							treatmentGlucose = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true" ? Number(String(params.glucose).replace(",", ".")) : Math.round(BgReading.mmolToMgdl(Number(String(params.glucose).replace(",", "."))));
						else
							response = "ERROR";
					}
					else if (treatmentType == Treatment.TYPE_NOTE)
					{
						if (params.note != null && String(params.note) != "")
							treatmentNote = String(params.note);
						else
							response = "ERROR";
					}
					else if (treatmentType == Treatment.TYPE_EXERCISE)
					{
						if (params.duration != null && !isNaN(params.duration))
							treatmentDuration = Number(params.duration);
						else
							response = "ERROR";
						
						if (params.exerciseIntensity != null)
						{
							var selectedExerciseIntensity:Number = Number(params.exerciseIntensity);
							if (selectedExerciseIntensity == 1)
							{
								treatmentExerciseIntensity = Treatment.EXERCISE_INTENSITY_LOW;
							}
							else if (selectedExerciseIntensity == 2)
							{
								treatmentExerciseIntensity = Treatment.EXERCISE_INTENSITY_MODERATE;
							}
							else if (selectedExerciseIntensity == 3)
							{
								treatmentExerciseIntensity = Treatment.EXERCISE_INTENSITY_HIGH;
							}
						}
					}
					else if (treatmentType == Treatment.TYPE_TEMP_BASAL)
					{
						if (params.duration != null && !isNaN(params.duration))
							basalDuration = Number(params.duration);
						else
							response = "ERROR";
						
						if (params.amount != null && !isNaN(params.amount))
							basalAmount = Number(params.amount);
						else
							response = "ERROR";
						
						if (params.basalType != null && String(params.basalType) != "")
						{
							if (String(params.basalType) == "absolute")
								isBasalAbsolute = true;
							else if (String(params.basalType) == "relative")
								isBasalRelative = true;
							
							if (!isBasalAbsolute && !isBasalRelative)
								isTempBasalEnd = true;
						}
						else
							response = "ERROR";
					}
					else if (treatmentType == Treatment.TYPE_MDI_BASAL)
					{
						var basalInsulin:Insulin = ProfileManager.getBasalInsulin();
						if (basalInsulin != null)
						{
							treatmentInsulinID = basalInsulin.ID;
							basalDuration = basalInsulin.dia * 60;
							
							if (params.amount != null && !isNaN(params.amount))
								basalAmount = Number(params.amount);
							else
								response = "ERROR";
							
							isBasalAbsolute = true;
							isBasalRelative = false;
							isTempBasalEnd = false;
						}
						else
						{
							response = "ERROR";
						}
					}
					else if (treatmentType == Treatment.TYPE_TEMP_BASAL_END)
					{
						basalAmount = 0;
						basalDuration = 30;
						isBasalAbsolute = false;
						isBasalRelative = false;
						isTempBasalEnd = true;
						
						treatmentType = Treatment.TYPE_TEMP_BASAL;
					}
					
					if 
					(
						(
							treatmentType == Treatment.TYPE_BOLUS 
							||
							treatmentType == Treatment.TYPE_CORRECTION_BOLUS 
							|| 
							treatmentType == Treatment.TYPE_MEAL_BOLUS 
							|| 
							treatmentType == Treatment.TYPE_CARBS_CORRECTION 
							|| 
							treatmentType == Treatment.TYPE_GLUCOSE_CHECK 
							||
							treatmentType == Treatment.TYPE_NOTE
							||
							treatmentType == Treatment.TYPE_EXERCISE
							||
							treatmentType == Treatment.TYPE_INSULIN_CARTRIDGE_CHANGE
							||
							treatmentType == Treatment.TYPE_PUMP_BATTERY_CHANGE
							||
							treatmentType == Treatment.TYPE_PUMP_SITE_CHANGE
							||
							treatmentType == Treatment.TYPE_TEMP_BASAL
							||
							treatmentType == Treatment.TYPE_MDI_BASAL
							||
							treatmentType == Treatment.TYPE_TEMP_BASAL_END
						) 
						&& 
						response == "OK"
					)
					{
						var treatment:Treatment = new Treatment
						(
							treatmentType,
							treatmentTimestamp,
							treatmentInsulinAmount,
							treatmentInsulinID,
							treatmentCarbs,
							treatmentGlucose,
							treatmentType != Treatment.TYPE_GLUCOSE_CHECK ? TreatmentsManager.getEstimatedGlucose(treatmentTimestamp) : treatmentGlucose,
							treatmentNote,
							null,
							treatmentCarbDelayTime
						);
						
						if (treatmentType == Treatment.TYPE_EXERCISE)
						{
							treatment.duration = treatmentDuration;
							treatment.exerciseIntensity = treatmentExerciseIntensity;
						}
						
						if (treatmentType == Treatment.TYPE_TEMP_BASAL || treatmentType == Treatment.TYPE_MDI_BASAL || treatmentType == Treatment.TYPE_TEMP_BASAL_END)
						{
							if (isBasalAbsolute)
							{
								treatment.basalAbsoluteAmount = basalAmount;
								treatment.basalPercentAmount = 0;
							}
							else if (isBasalRelative)
							{
								treatment.basalAbsoluteAmount = 0;
								treatment.basalPercentAmount = basalAmount;
							}
							else if (isTempBasalEnd)
							{
								treatment.basalAbsoluteAmount = 0;
								treatment.basalPercentAmount = 0;
							}
							
							treatment.basalDuration = basalDuration;
							treatment.isBasalAbsolute = isBasalAbsolute;
							treatment.isBasalRelative = isBasalRelative;
							treatment.isTempBasalEnd = isTempBasalEnd;
						}
						
						if (treatmentType == Treatment.TYPE_INSULIN_CARTRIDGE_CHANGE)
						{
							CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_LAST_INSULIN_CARTRIDGE_CHANGE, String(treatmentTimestamp), true, false);
						}
						else if (treatmentType == Treatment.TYPE_PUMP_BATTERY_CHANGE)
						{
							CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_LAST_PUMP_BATTERY_CHANGE, String(treatmentTimestamp), true, false);
						}
						else if (treatmentType == Treatment.TYPE_PUMP_SITE_CHANGE)
						{
							CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_LAST_PUMP_SITE_CHANGE, String(treatmentTimestamp), true, false);
						}
						
						TreatmentsManager.addExternalTreatment(treatment);
					}
					else
						response = "ERROR";
				}
				else
					response = "ERROR";
			} 
			catch(error:Error) 
			{
				response = "ERROR";
			}
			
			Trace.myTrace("SpikeTreatmentsController.as", "Treatment Type: " + treatmentType + ", Result: " + response);
			
			return responseSuccess(response);
		}
	}
}