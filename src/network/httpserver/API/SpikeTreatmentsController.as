package network.httpserver.API
{
	import flash.net.URLVariables;
	
	import database.BgReading;
	import database.CGMBlueToothDevice;
	import database.CommonSettings;
	
	import network.httpserver.ActionController;
	
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
					//Define initial treatment properties
					var treatmentTimestamp:Number = new Date().valueOf();
					treatmentType = String(params.type);
					var treatmentInsulinAmount:Number = 0;
					var treatmentInsulinID:String = "";
					var treatmentCarbs:Number = 0;
					var treatmentGlucose:Number = 0;
					var treatmentNote:String = "";
					var treatmentCarbDelayTime:Number = 20;
					
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
					
					if ((treatmentType == Treatment.TYPE_BOLUS || treatmentType == Treatment.TYPE_CORRECTION_BOLUS || treatmentType == Treatment.TYPE_MEAL_BOLUS || treatmentType == Treatment.TYPE_CARBS_CORRECTION || treatmentType == Treatment.TYPE_GLUCOSE_CHECK || treatmentType == Treatment.TYPE_NOTE) && response == "OK")
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