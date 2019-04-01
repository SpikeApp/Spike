package treatments
{
	import database.CommonSettings;
	
	import utils.UniqueId;

	public class Treatment
	{
		/* Public Constants */
		public static const TYPE_MEAL_BOLUS:String = "mealBolus";
		public static const TYPE_BOLUS:String = "bolus";
		public static const TYPE_CORRECTION_BOLUS:String = "correctionBolus";
		public static const TYPE_CARBS_CORRECTION:String = "carbCorrection";
		public static const TYPE_GLUCOSE_CHECK:String = "glucoseCheck";
		public static const TYPE_NOTE:String = "note";
		public static const TYPE_SENSOR_START:String = "sensorStart";
		public static const TYPE_EXTENDED_COMBO_BOLUS_PARENT:String = "extendedComboBolusParent";
		public static const TYPE_EXTENDED_COMBO_MEAL_PARENT:String = "extendedComboMealParent";
		public static const TYPE_EXTENDED_COMBO_BOLUS_CHILD:String = "extendedComboBolusChild";
		public static const TYPE_EXERCISE:String = "exercise";
		public static const TYPE_PUMP_SITE_CHANGE:String = "pumpSiteChange";
		public static const TYPE_PUMP_BATTERY_CHANGE:String = "pumpBatteryChange";
		public static const TYPE_INSULIN_CARTRIDGE_CHANGE:String = "insulinCartridgeChange";
		public static const TYPE_TEMP_BASAL:String = "tempBasal";
		public static const TYPE_TEMP_BASAL_END:String = "tempBasalEnd";
		public static const TYPE_MDI_BASAL:String = "mdiBasal";
		public static const EXERCISE_INTENSITY_LOW:String = "low";
		public static const EXERCISE_INTENSITY_MODERATE:String = "moderate";
		public static const EXERCISE_INTENSITY_HIGH:String = "high";
		
		/* Internal Constants */
		private static const INSULIN_PEAK:uint = 75;
		
		/* Properties */
		public var type:String;
		public var insulinAmount:Number;
		public var insulinID:String = "";
		private var _dia:Number = 3;
		public var carbs:Number;
		public var glucose:Number;
		public var glucoseEstimated:Number;
		public var note:String;
		public var timestamp:Number;
		public var ID:String;
		private var insulinScaleFactor:Number;
		public var needsAdjustment:Boolean = false;
		public var carbDelayTime:Number = 20;
		public var preBolus:Number = Number.NaN;
		public var childTreatments:Array = [];
		public var duration:Number = Number.NaN;
		public var exerciseIntensity:String = "";
		
		/* Basal */
		public var basalDuration:Number = 0;
		public var basalAbsoluteAmount:Number = 0;
		public var isBasalAbsolute:Boolean = false;
		public var basalPercentAmount:Number = 0;
		public var isBasalRelative:Boolean = false;
		public var isTempBasalEnd:Boolean = false;
		
		public function Treatment(type:String, timestamp:Number, insulin:Number = 0, insulinID:String = "", carbs:Number = 0, glucose:Number = 100, glucoseEstimated:Number = 100, note:String = "", treatmentID:String = null, carbDelayTime:Number = Number.NaN)
		{
			this.type = type;
			this.insulinAmount = insulin;
			if (insulinID != "")
			{
				var insulinMatch:Insulin = ProfileManager.getInsulin(insulinID);
				if (insulinMatch != null && !isNaN(insulinMatch.dia))
					this.dia = insulinMatch.dia;
			}
			this.insulinID = insulinID;
			this.carbs = carbs;
			this.glucose = glucose;
			this.glucoseEstimated = glucoseEstimated;
			this.note = note;
			this.timestamp = timestamp;
			this.insulinScaleFactor = 3 / dia;
			this.ID = treatmentID == null ? UniqueId.createEventId() : treatmentID;
			this.carbDelayTime = isNaN(carbDelayTime) ? Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEFAULT_CARB_ABSORTION_TIME)) : carbDelayTime;
		}
		
		/**
		 * IOB Calculation Algorithms (Nightscout & OpenAPS)
		 */
		public function calculateIOBNightscout(time:Number, isf:Number = Number.NaN):Object
		{
			//Nightscout
			var minAgo:Number = insulinScaleFactor * (time - timestamp) / 1000 / 60;
			var iob:Number = 0;
			var activityForecast:Number = 0;
			var activity:Number = 0;
			
			if (minAgo < INSULIN_PEAK) 
			{
				var x1:Number = minAgo / 5 + 1;
				iob = insulinAmount * (1 - 0.001852 * x1 * x1 + 0.001852 * x1);
				activityForecast = insulinAmount * (2 / dia / 60 / INSULIN_PEAK) * minAgo;
				
				if (!isNaN(isf))
					activity = isf * activityForecast;
			} 
			else if (minAgo < 180) 
			{
				var x2:Number = (minAgo - 75) / 5;
				iob = insulinAmount * (0.001323 * x2 * x2 - 0.054233 * x2 + 0.55556);
				activityForecast = insulinAmount * (2 / dia / 60 - (minAgo - INSULIN_PEAK) * 2 / dia / 60 / (60 * 3 - INSULIN_PEAK));
				
				if (!isNaN(isf))
					activity = isf * activityForecast;
			}
			
			if (iob < 0.001 || isNaN(iob)) iob = 0;
			
			var result:Object =
				{
					activityContrib: activity,
					activityForecast:  activityForecast,
					iobContrib: iob
				}
			
			return result;
		}
		
		public function calculateIOBOpenAPS(time:Number):Object
		{
			// iobCalc returns two variables:
			//   activityContrib = units of treatment.insulin used in previous minute
			//   iobContrib = units of treatment.insulin still remaining at a given point in time
			// ("Contrib" is used because these are the amounts contributed from pontentially multiple treatment.insulin dosages -- totals are calculated in TreatmentsManager.getTotalIOBOpenAPS() )
			//
			// Variables can be calculated using either:
			//   A bilinear insulin action curve (which only takes duration of insulin activity (dia) as an input parameter) or
			//   An exponential insulin action curve (which takes both a dia and a peak parameter)
			// (which functional form to use is specified in the user's profile)
			
			var insulin:Insulin = ProfileManager.getInsulin(insulinID);
			if (insulin != null) //Check if treatment has insulin
			{
				// Calc minutes since bolus (minsAgo)
				var bolusTime:Number = timestamp;
				var minsAgo:Number = Math.round((time - bolusTime) / 1000 / 60);
				var curve:String = insulin.curve;
				
				if (curve == 'bilinear') 
					return calculateIOBBilinear(minsAgo, dia);
				else 
					return calculateIOBExponential(minsAgo, dia, insulin.peak);
			} 
			else 
			{ 
				// empty return if treatment doesn't contain insuln
				return { 
					activityContrib: 0,
					activityForecast:  0,
					iobContrib: 0 
				};
			}    
		}
		
		private function calculateIOBBilinear(minsAgo:Number, dia:Number):Object
		{
			// No user-specified peak with this model
			const default_dia:Number = 3 // assumed duration of insulin activity, in hours
			const peak:Number = 75;      // assumed peak insulin activity, in minutes
			const end:Number = 180;      // assumed end of insulin activity, in minutes
			
			// Scale minsAgo by the ratio of the default dia / the user's dia 
			// so the calculations for activityContrib and iobContrib work for 
			// other dia values (while using the constants specified above)
			var timeScalar:Number = default_dia / dia; 
			var scaled_minsAgo:Number = timeScalar * minsAgo;
			
			
			var activityContrib:Number = 0;  
			var iobContrib:Number = 0;       
			
			// Calc percent of insulin activity at peak, and slopes up to and down from peak
			// Based on area of triangle, because area under the insulin action "curve" must sum to 1
			// (length * height) / 2 = area of triangle (1), therefore height (activityPeak) = 2 / length (which in this case is dia, in minutes)
			// activityPeak scales based on user's dia even though peak and end remain fixed
			var activityPeak:Number = 2 / (dia * 60);
			var slopeUp:Number = activityPeak / peak;
			var slopeDown:Number = -1 * (activityPeak / (end - peak));
			
			if (scaled_minsAgo < peak) 
			{	
				activityContrib = insulinAmount * (slopeUp * scaled_minsAgo);
				
				var x1:Number = (scaled_minsAgo / 5) + 1;  // scaled minutes since bolus, pre-peak; divided by 5 to work with coefficients estimated based on 5 minute increments
				iobContrib = insulinAmount * ( (-0.001852*x1*x1) + (0.001852*x1) + 1.000000 );
			} 
			else if (scaled_minsAgo < end) 
			{
				var minsPastPeak:Number = scaled_minsAgo - peak;
				activityContrib = insulinAmount * (activityPeak + (slopeDown * minsPastPeak));
				
				var x2:Number = ((scaled_minsAgo - peak) / 5);  // scaled minutes past peak; divided by 5 to work with coefficients estimated based on 5 minute increments
				iobContrib = insulinAmount * ( (0.001323*x2*x2) + (-0.054233*x2) + 0.555560 );
			}
			
			var results:Object = 
			{ 
				activityContrib: activityContrib,
				activityForecast:  activityContrib,
				iobContrib: iobContrib 
			};
			
			return results;
		}
		
		private function calculateIOBExponential(minsAgo:Number, dia:Number, peak:Number):Object 
		{
			var end:Number = dia * 60;  // end of insulin activity, in minutes
			var activityContrib:Number = 0;  
			var iobContrib:Number = 0;       
			
			if (minsAgo < end) 
			{
				// Formula source: https://github.com/LoopKit/Loop/issues/388#issuecomment-317938473
				// Mapping of original source variable names to those used here:
				var tau:Number = peak * (1 - peak / end) / (1 - 2 * peak / end);  // time constant of exponential decay
				var a:Number = 2 * tau / end;                                     // rise time factor
				var S:Number = 1 / (1 - a + (1 + a) * Math.exp(-end / tau));      // auxiliary scale factor
				
				activityContrib = insulinAmount * (S / Math.pow(tau, 2)) * minsAgo * (1 - minsAgo / end) * Math.exp(-minsAgo / tau);
				iobContrib = insulinAmount * (1 - S * (1 - a) * ((Math.pow(minsAgo, 2) / (tau * end * (1 - a)) - minsAgo / tau - 1) * Math.exp(-minsAgo / tau) + 1));
			}
			
			var results:Object = 
			{ 
				activityContrib: activityContrib,
				activityForecast:  activityContrib,
				iobContrib: iobContrib 
			};
			
			return results;
		}
		
		/**
		 * COB Nightscout Calculation Algorithm
		 */
		public function calculateCOB(lastDecayedBy:Number, time:Number):CobCalc
		{
			var absorptionRate:int = ProfileManager.getCarbAbsorptionRate();
			var delay:int = int(carbDelayTime);
			var isDecaying:int = 0;
			
			if (carbs > 0)
			{
				var thisCobCalc:CobCalc = new CobCalc();
				thisCobCalc.carbTime = this.timestamp;
				
				var carbs_hr:Number = absorptionRate;
				var carbs_min:Number = carbs_hr / 60;
				
				thisCobCalc.decayedBy = thisCobCalc.carbTime;
				
				var minutesleft:Number = (lastDecayedBy - thisCobCalc.carbTime) / 1000 / 60;
				
				thisCobCalc.decayedBy += (Math.max(delay, minutesleft) + carbs / carbs_min) * 60 * 1000;
				
				
				if (delay > minutesleft) {
					thisCobCalc.initialCarbs = carbs;
				}
				else 
				{
					thisCobCalc.initialCarbs = carbs + minutesleft * carbs_min;
				}
				
				var startDecay:Number = thisCobCalc.carbTime;
				startDecay += (thisCobCalc.carbTime + delay) * 60 * 1000
				
				if (time < lastDecayedBy || time > startDecay) 
				{
					thisCobCalc.isDecaying = 1;
				}
				else 
				{
					thisCobCalc.isDecaying = 0;
				}
				
				return thisCobCalc;
			}
			else 
			{
				return null;
			}
		}
		
		public function parseChildren(children:String):void
		{
			if (children == null || children.length == 0)
				return;
			
			childTreatments = children.split(",");
		}
		
		public function extractChildren():String
		{
			return childTreatments.join(",");
		}
		
		public function getTotalInsulin(onlyChildren:Boolean = false):Number
		{
			if ((type != TYPE_EXTENDED_COMBO_BOLUS_PARENT && type != TYPE_EXTENDED_COMBO_MEAL_PARENT) || childTreatments.length == 0)
			{
				return insulinAmount;
			}
			
			var parentInsulinAmount:Number = onlyChildren ? 0 : insulinAmount;
			var numberOfChildren:uint = childTreatments.length;
			for (var i:int = 0; i < numberOfChildren; i++) 
			{
				var childTreatment:Treatment = TreatmentsManager.getTreatmentByID(String(childTreatments[i]));
				if (childTreatment != null)
				{
					parentInsulinAmount += childTreatment.insulinAmount;
				}
			}
			
			return parentInsulinAmount;
		}

		/**
		 * Getters & Setters
		 */
		public function get dia():Number
		{
			return _dia;
		}

		public function set dia(value:Number):void
		{
			_dia = value;
			this.insulinScaleFactor = 3 / _dia;
		}
	}
}