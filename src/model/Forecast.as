package model
{
	import flash.events.EventDispatcher;
	import flash.utils.ByteArray;
	
	import database.BgReading;
	import database.CGMBlueToothDevice;
	import database.Calibration;
	import database.CommonSettings;
	
	import events.PredictionEvent;
	
	import treatments.Profile;
	import treatments.ProfileManager;
	import treatments.Treatment;
	import treatments.TreatmentsManager;
	
	import ui.chart.GlucoseChart;
	
	import utils.BgGraphBuilder;
	import utils.TimeSpan;

	public class Forecast extends EventDispatcher
	{
		//Instance
		private static var _instance:Forecast = new Forecast();
		
		//Properties
		private static var internalCache:Object = {};
		private static var apsPredictions:Object = null;
		public static var externalLoopAPS:Boolean = false;
		public static var lastExternalPredictionFetchTimestamp:Number = 0;
		
		public function Forecast()
		{
			if (_instance != null) 
			{
				throw new Error("Forecast is not meant to be instantiated!");
			}
		}
		
		/**
		 * Glucose Predictions
		 */
		public static function predictBGs(minutes:uint, forceNewIOBCOB:Boolean = false, ignoreIOBCOB:Boolean = false):Object
		{
			try
			{
				if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_LOOP_OPENAPS_USER_ENABLED) == "true")
				{
					return apsPredictions;
				}
				else
				{
					externalLoopAPS = false;
				}
				
				if (isNaN(minutes))
				{
					return null;
				}
				
				var glucose_status:Object = getLastGlucose();
				if (glucose_status == null || glucose_status.is_valid == null || glucose_status.is_valid == false || glucose_status.date == null || glucose_status.glucose == null || glucose_status.delta == null || glucose_status.short_avgdelta == null || glucose_status.long_avgdelta == null)
				{
					// Not enough glucose data for predictions!
					return null;
				}
				
				if (CGMBlueToothDevice.isDexcomFollower())
				{
					//Disable IOB/COB for Dexcom follower
					ignoreIOBCOB = true;
				}
				
				var currentTime:Number = new Date().valueOf();
				var now:Number = !isNaN(glucose_status.date) && currentTime - glucose_status.date < TimeSpan.TIME_16_MINUTES && !forceNewIOBCOB ? glucose_status.date : currentTime;
				if (isNaN(now))
				{
					now = currentTime;
				}
				
				//Sort Treatments
				var treatmentsList:Array = [];
				if (TreatmentsManager.treatmentsList != null)
				{
					treatmentsList = TreatmentsManager.treatmentsList;
					treatmentsList.sortOn(["timestamp"], Array.NUMERIC);
				}
				
				//Create cache hash
				var treatmentsBytes:ByteArray = new ByteArray();
				treatmentsBytes.writeObject(treatmentsList);
				var cacheHash:String = treatmentsBytes.toString() + forceNewIOBCOB.toString() + ignoreIOBCOB.toString() + CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEFAULT_IOB_COB_ALGORITHM);
				
				//Check cache
				if (!forceNewIOBCOB)
				{
					if (internalCache[now] != null && internalCache[now].cacheHash != null && internalCache[now].cacheHash == cacheHash && internalCache[now].minutes != null && internalCache[now].minutes == minutes)
					{
						//Cache found!
						return internalCache[now];
					}
				}
				
				//Define common variables
				var five_min_blocks:Number = Math.floor(minutes / 5);
				var i:int;
				var status:String = "";
				var incompleteProfile:Boolean = false;
				
				var bg:Number = glucose_status.glucose;
				
				var currentProfile:Profile = ProfileManager.getProfileByTime(now);
				var target_bg:Number = currentProfile != null ? Number(currentProfile.targetGlucoseRates) : Number.NaN;
				var min_bg:Number = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_LOW_MARK));
				var max_bg:Number = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_HIGH_MARK));
				
				if (isNaN(target_bg) || target_bg == 0 || currentProfile == null || currentProfile.targetGlucoseRates == "")
				{
					target_bg = (min_bg + max_bg) / 2;
					status += "No default profile set!. Setting BG target to the average of high and low thresholds: " + (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true" ? target_bg : Math.round(BgReading.mgdlToMmol(target_bg) * 10) / 10) + "\n"
				}
				
				var iobArray:Array = []; //Will hold all present/future IOB data points used for calculating predictions
				for (i = 0; i < five_min_blocks; i++) 
				{
					var projectedIOB:Object = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_GLUCOSE_PREDICTIONS_INCLUDE_IOB_COB) == "true" && ignoreIOBCOB == false ? TreatmentsManager.getTotalIOB(now + (i * TimeSpan.TIME_5_MINUTES)) : { iob: 0, activityForecast: 0 };
					if (projectedIOB == null || projectedIOB.iob == null || projectedIOB.activityForecast == null || isNaN(projectedIOB.iob) || isNaN(projectedIOB.activityForecast))
					{
						//Abort
						return null;
					}
					
					iobArray.push( { iob: projectedIOB.iob, activityForecast: projectedIOB.activityForecast } );
				}
				
				var iob_data:Object = iobArray[0];
				if (iob_data == null)
				{
					return null;
				}
				
				var minDelta:Number = Math.min(glucose_status.delta, glucose_status.short_avgdelta);
				var minAvgDelta:Number = Math.min(glucose_status.short_avgdelta, glucose_status.long_avgdelta);
				var maxDelta:Number = Math.max(glucose_status.delta, glucose_status.short_avgdelta, glucose_status.long_avgdelta);
				if (isNaN(minDelta) || isNaN(minAvgDelta) || isNaN(maxDelta))
				{
					return null;
				}
				
				var sens:Number;
				if (currentProfile != null && currentProfile.insulinSensitivityFactors != "")
				{
					sens = Number(currentProfile.insulinSensitivityFactors);
				}
				else
				{
					//User has not yet set a profile, let's default it to 50
					sens = 50;
					incompleteProfile = true;
					status += "No ISF has been set. Defaulting to: " + (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true" ? 50 : Math.round(BgReading.mgdlToMmol(50) * 10) / 10) + "\n";
				}
				
				//calculate BG impact: the amount BG "should" be rising or falling based on insulin activity alone
				var bgi:Number = round(( -iob_data.activityForecast * sens * 5 ), 2);
				
				// project deviations for 30 minutes
				var deviation:Number = round( 30 / 5 * ( minDelta - bgi ) );
				
				// don't overreact to a big negative delta: use minAvgDelta if deviation is negative
				if (deviation < 0) 
				{
					deviation = round( (30 / 5) * ( minAvgDelta - bgi ) );
					
					// and if deviation is still negative, use long_avgdelta
					if (deviation < 0) 
					{
						deviation = round( (30 / 5) * ( glucose_status.long_avgdelta - bgi ) );
					}
				}
				
				// calculate the naive (bolus calculator math) eventual BG based on net IOB and sensitivity
				var naive_eventualBG:Number = round( bg - (iob_data.iob * sens) );
				
				// and adjust it for the deviation above
				var eventualBG:Number = naive_eventualBG + deviation;
				
				var expectedDelta:Number = calculate_expected_delta(target_bg, eventualBG, bgi);
				if (isNaN(eventualBG))
				{
					status += "Error: Could not correctly calculate eventual BG.\n";
					
					eventualBG = bg;
				}
				
				var threshold:Number = min_bg - 0.5*(min_bg-40);
				
				// generate predicted future BGs based on IOB, COB, and current absorption rate
				var COBpredBGs:Array = [];
				var aCOBpredBGs:Array = [];
				var IOBpredBGs:Array = [];
				var UAMpredBGs:Array = [];
				var ZTpredBGs:Array = [];
				COBpredBGs.push(bg);
				aCOBpredBGs.push(bg);
				IOBpredBGs.push(bg);
				ZTpredBGs.push(bg);
				UAMpredBGs.push(bg);
				
				//UAM
				var enableUAM:Boolean = true;
				
				// carb impact and duration are 0 unless changed below
				var ci:Number = 0;
				var cid:Number = 0;
				
				// calculate current carb absorption rate, and how long to absorb all carbs
				// CI = current carb impact on BG in mg/dL/5m
				ci = round((minDelta - bgi),1);
				
				var uci:Number = round((minDelta - bgi),1);
				
				// ISF (mg/dL/U) / CR (g/U) = CSF (mg/dL/g)
				var carb_ratio:Number;
				if (currentProfile != null && currentProfile.insulinToCarbRatios != "")
				{
					carb_ratio = Number(currentProfile.insulinToCarbRatios);
				}
				else
				{
					status += "Can't determine I:C. Defaulting to 10" + "\n";
					carb_ratio = 10; //If no i:C is set by the user we default to 10
					incompleteProfile = true;
				}
				
				var csf:Number = sens / carb_ratio; 
				
				var maxCarbAbsorptionRate:Number = ProfileManager.getCarbAbsorptionRate(); // g/h; maximum rate to assume carbs will absorb if no CI observed
				if (isNaN(maxCarbAbsorptionRate) || maxCarbAbsorptionRate == 0)
				{
					status += "Can't determine carbs absorption rate. Defaulting to 30g/h" + "\n";
					maxCarbAbsorptionRate = 30;
					incompleteProfile = true;
				}
				
				// limit Carb Impact to maxCarbAbsorptionRate * csf in mg/dL per 5m
				var maxCI:Number = round(maxCarbAbsorptionRate*csf*5/60, 1)
				if (ci > maxCI) {
					status += "Limiting carb impact from " + ci + " to " + maxCI + "mg/dL/5m (" + maxCarbAbsorptionRate + "g/h )" + "\n";
					ci = maxCI;
				}
				
				var remainingCATimeMin:Number = 3; // h; duration of expected not-yet-observed carb absorption
				
				// 20 g/h means that anything <= 60g will get a remainingCATimeMin, 80g will get 4h, and 120g 6h
				// when actual absorption ramps up it will take over from remainingCATime
				var assumedCarbAbsorptionRate:Number = 20; // g/h; maximum rate to assume carbs will absorb if no CI observed
				var remainingCATime:Number = remainingCATimeMin;
				
				//Determine COB
				var COBObject:Object;
				if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_GLUCOSE_PREDICTIONS_INCLUDE_IOB_COB) == "true" && ignoreIOBCOB == false)
				{
					COBObject = TreatmentsManager.getTotalCOB(now, false, true);
				}
				else
				{
					COBObject = {
						time: now,
						cob: 0,
						carbs: 0,
						lastCarbTime: 0,
						firstCarbTime: now,
						carbsAbsorbed: 0,
						currentDeviation: Number.NaN,
							maxDeviation: 0,
							minDeviation: 999,
							slopeFromMaxDeviation: 0,
							slopeFromMinDeviation: 999,
							allDeviations: null
					};
					
					var deviations:Object = TreatmentsManager.calcDeviations(now);
					if (deviations != null)
					{
						COBObject.currentDeviation = deviations.currentDeviation;
						COBObject.maxDeviation = deviations.maxDeviation;
						COBObject.minDeviation = deviations.minDeviation;
						COBObject.slopeFromMaxDeviation = deviations.slopeFromMaxDeviation;
						COBObject.slopeFromMinDeviation = deviations.slopeFromMinDeviation;
						COBObject.allDeviations = deviations.allDeviations;
					}
				}
				
				var meal_data:Object = COBObject;
				if (meal_data == null || meal_data.carbs == null || meal_data.cob == null || meal_data.lastCarbTime == null)
				{
					return null;
				}
				
				if (meal_data.carbs > 0) 
				{
					// if carbs * assumedCarbAbsorptionRate > remainingCATimeMin, raise it
					// so <= 90g is assumed to take 3h, and 120g=4h
					remainingCATimeMin = Math.max(remainingCATimeMin, meal_data.cob / assumedCarbAbsorptionRate);
					var lastCarbAge:Number = round(( now - meal_data.lastCarbTime ) / 60000);
					
					var fractionCOBAbsorbed:Number = ( meal_data.carbs - meal_data.cob ) / meal_data.carbs;
					remainingCATime = remainingCATimeMin + 1.5 * lastCarbAge/60;
					remainingCATime = round(remainingCATime,1);
					
					status += "Last carbs: " + lastCarbAge + " minutes ago; remainingCATime: " + remainingCATime + " hours; " + round(fractionCOBAbsorbed*100) + "% carbs absorbed." + "\n";
				}
				
				// calculate the number of carbs absorbed over remainingCATime hours at current CI
				// CI (mg/dL/5m) * (5m)/5 (m) * 60 (min/hr) * 4 (h) / 2 (linear decay factor) = total carb impact (mg/dL)
				var totalCI:Number = Math.max(0, ci / 5 * 60 * remainingCATime / 2);
				
				// totalCI (mg/dL) / CSF (mg/dL/g) = total carbs absorbed (g)
				var totalCA:Number = totalCI / csf;
				var remainingCarbsCap:Number = 90; // default to 90
				var remainingCarbsFraction:Number = 1;
				var remainingCarbsIgnore:Number = 1 - remainingCarbsFraction;
				var remainingCarbs:Number = Math.max(0, meal_data.cob - totalCA - meal_data.carbs*remainingCarbsIgnore);
				remainingCarbs = Math.min(remainingCarbsCap,remainingCarbs);
				// assume remainingCarbs will absorb in a /\ shaped bilinear curve
				// peaking at remainingCATime / 2 and ending at remainingCATime hours
				// area of the /\ triangle is the same as a remainingCIpeak-height rectangle out to remainingCATime/2
				// remainingCIpeak (mg/dL/5m) = remainingCarbs (g) * CSF (mg/dL/g) * 5 (m/5m) * 1h/60m / (remainingCATime/2) (h)
				var remainingCIpeak:Number = remainingCarbs * csf * 5 / 60 / (remainingCATime/2);
				
				// calculate peak deviation in last hour, and slope from that to current deviation
				var slopeFromMaxDeviation:Number = meal_data.slopeFromMaxDeviation != null && !isNaN(meal_data.slopeFromMaxDeviation) ? round(meal_data.slopeFromMaxDeviation,2) : 0; 
				// calculate lowest deviation in last hour, and slope from that to current deviation
				var slopeFromMinDeviation:Number = meal_data.slopeFromMinDeviation != null && !isNaN(meal_data.slopeFromMinDeviation) ? round(meal_data.slopeFromMinDeviation,2) : 999;
				// assume deviations will drop back down at least at 1/3 the rate they ramped up
				var slopeFromDeviations:Number = Math.min(slopeFromMaxDeviation,-slopeFromMinDeviation/3);
				
				var aci:Number = 10;
				//5m data points = g * (1U/10g) * (40mg/dL/1U) / (mg/dL/5m)
				// duration (in 5m data points) = COB (g) * CSF (mg/dL/g) / ci (mg/dL/5m)
				// limit cid to remainingCATime hours: the reset goes to remainingCI
				if (ci == 0) 
				{
					// avoid divide by zero
					cid = 0;
				} else 
				{
					cid = Math.min(remainingCATime*60/5/2,Math.max(0, meal_data.cob * csf / ci ));
				}
				
				var acid:Number = Math.max(0, meal_data.cob * csf / aci );
				// duration (hours) = duration (5m) * 5 / 60 * 2 (to account for linear decay)
				status += "Carb Impact: " + ci + "mg/dL per 5m; CI Duration: " + round(cid*5/60*2,1) + "hours; remaining CI (~2h peak): " + round(remainingCIpeak,1)+ "mg/dL per 5m" + "\n";
				
				
				var minIOBPredBG:Number = 999;
				var minCOBPredBG:Number = 999;
				var minUAMPredBG:Number = 999;
				var minGuardBG:Number = bg;
				var minCOBGuardBG:Number = 999;
				var minUAMGuardBG:Number = 999;
				var minIOBGuardBG:Number = 999;
				var minZTGuardBG:Number = 999;
				var minPredBG:Number;
				var avgPredBG:Number;
				var IOBpredBG:Number = eventualBG;
				var maxIOBPredBG:Number = bg;
				var maxCOBPredBG:Number = bg;
				var maxUAMPredBG:Number = bg;
				var eventualPredBG:Number = bg;
				var lastIOBpredBG:Number;
				var lastCOBpredBG:Number;
				var lastUAMpredBG:Number;
				var lastZTpredBG:Number;
				var UAMduration:Number = 0;
				var remainingCItotal:Number = 0;
				var remainingCIs:Array = [];
				var predCIs:Array = [];
				
				var predBGI:Number = 0;
				var predZTBGI:Number = 0;
				var predDev:Number = 0;
				var ZTpredBG:Number = 0;
				var predCI:Number = 0;
				var predACI:Number = 0;
				var intervals:Number = 0;
				var remainingCI:Number = 0;
				var COBpredBG:Number = 0;
				var aCOBpredBG:Number = 0;
				var predUCIslope:Number = 0;
				var predUCImax:Number = 0;
				var predUCI:Number = 0;
				var UAMpredBG:Number = 0;
				var insulinPeakTime:Number = 0;
				var insulinPeak5m:Number = 0;
				
				var numberOfIOBs:int = iobArray.length;
				for (i = 0; i < numberOfIOBs; i++) 
				{
					var iobTick:Object = iobArray[i];
					if (iobTick == null || iobTick.activityForecast == null)
					{
						continue;
					}
					
					predBGI = round(( -iobTick.activityForecast * sens * 5 ), 2);
					predZTBGI = round(( -iobTick.activityForecast * sens * 5 ), 2);
					// for IOBpredBGs, predicted deviation impact drops linearly from current deviation down to zero
					// over 60 minutes (data points every 5m)
					predDev = ci * ( 1 - Math.min(1,IOBpredBGs.length/(60/5)) );
					
					IOBpredBG = IOBpredBGs[IOBpredBGs.length-1] + predBGI + predDev;
					// calculate predBGs with long zero temp without deviations
					ZTpredBG = ZTpredBGs[ZTpredBGs.length-1] + predZTBGI;
					// for COBpredBGs, predicted carb impact drops linearly from current carb impact down to zero
					// eventually accounting for all carbs (if they can be absorbed over DIA)
					predCI = Math.max(0, Math.max(0,ci) * ( 1 - COBpredBGs.length/Math.max(cid*2,1) ) );
					predACI = Math.max(0, Math.max(0,aci) * ( 1 - COBpredBGs.length/Math.max(acid*2,1) ) );
					// if any carbs aren't absorbed after remainingCATime hours, assume they'll absorb in a /\ shaped
					// bilinear curve peaking at remainingCIpeak at remainingCATime/2 hours (remainingCATime/2*12 * 5m)
					// and ending at remainingCATime h (remainingCATime*12 * 5m intervals)
					intervals = Math.min( COBpredBGs.length, (remainingCATime*12)-COBpredBGs.length );
					remainingCI = Math.max(0, intervals / (remainingCATime/2*12) * remainingCIpeak );
					remainingCItotal += predCI+remainingCI;
					remainingCIs.push(round(remainingCI,0));
					predCIs.push(round(predCI,0));
					//process.stderr.write(round(predCI,1)+"+"+round(remainingCI,1)+" ");
					COBpredBG = COBpredBGs[COBpredBGs.length-1] + predBGI + Math.min(0,predDev) + predCI + remainingCI;
					aCOBpredBG = aCOBpredBGs[aCOBpredBGs.length-1] + predBGI + Math.min(0,predDev) + predACI;
					// for UAMpredBGs, predicted carb impact drops at slopeFromDeviations
					// calculate predicted CI from UAM based on slopeFromDeviations
					predUCIslope = Math.max(0, uci + ( UAMpredBGs.length*slopeFromDeviations ) );
					// if slopeFromDeviations is too flat, predicted deviation impact drops linearly from
					// current deviation down to zero over 3h (data points every 5m)
					predUCImax = Math.max(0, uci * ( 1 - UAMpredBGs.length/Math.max(3*60/5,1) ) );
					//console.error(predUCIslope, predUCImax);
					// predicted CI from UAM is the lesser of CI based on deviationSlope or DIA
					predUCI = Math.min(predUCIslope, predUCImax);
					
					
					if(predUCI>0) {
						//console.error(UAMpredBGs.length,slopeFromDeviations, predUCI);
						UAMduration=round((UAMpredBGs.length+1)*5/60,1);
					}
					UAMpredBG = UAMpredBGs[UAMpredBGs.length-1] + predBGI + Math.min(0, predDev) + predUCI;
					//console.error(predBGI, predCI, predUCI);
					// truncate all BG predictions at 4 hours
					if ( IOBpredBGs.length <= 48) { IOBpredBGs.push(IOBpredBG); }
					if ( COBpredBGs.length <= 48) { COBpredBGs.push(COBpredBG); }
					if ( aCOBpredBGs.length <= 48) { aCOBpredBGs.push(aCOBpredBG); }
					if ( UAMpredBGs.length <= 48) { UAMpredBGs.push(UAMpredBG); }
					if ( ZTpredBGs.length <= 48) { ZTpredBGs.push(ZTpredBG); }
					// calculate minGuardBGs without a wait from COB, UAM, IOB predBGs
					if ( COBpredBG < minCOBGuardBG ) { minCOBGuardBG = round(COBpredBG); }
					if ( UAMpredBG < minUAMGuardBG ) { minUAMGuardBG = round(UAMpredBG); }
					if ( IOBpredBG < minIOBGuardBG ) { minIOBGuardBG = round(IOBpredBG); }
					if ( ZTpredBG < minZTGuardBG ) { minZTGuardBG = round(ZTpredBG); }
					
					// set minPredBGs starting when currently-dosed insulin activity will peak
					// look ahead 60m (regardless of insulin type) so as to be less aggressive on slower insulins
					insulinPeakTime = 60;
					// add 30m to allow for insluin delivery (SMBs or temps)
					insulinPeakTime = 90;
					insulinPeak5m = (insulinPeakTime/60)*12;
					//console.error(insulinPeakTime, insulinPeak5m, profile.insulinPeakTime, profile.curve);
					
					// wait 90m before setting minIOBPredBG
					if ( IOBpredBGs.length > insulinPeak5m && (IOBpredBG < minIOBPredBG) ) { minIOBPredBG = round(IOBpredBG); }
					if ( IOBpredBG > maxIOBPredBG ) { maxIOBPredBG = IOBpredBG; }
					// wait 85-105m before setting COB and 60m for UAM minPredBGs
					if ( (cid || remainingCIpeak > 0) && COBpredBGs.length > insulinPeak5m && (COBpredBG < minCOBPredBG) ) { minCOBPredBG = round(COBpredBG); }
					if ( (cid || remainingCIpeak > 0) && COBpredBG > maxIOBPredBG ) { maxCOBPredBG = COBpredBG; }
					if ( enableUAM && UAMpredBGs.length > 12 && (UAMpredBG < minUAMPredBG) ) { minUAMPredBG = round(UAMpredBG); }
					if ( enableUAM && UAMpredBG > maxIOBPredBG ) { maxUAMPredBG = UAMpredBG; }
				}
				
				var predBGs:Object = {};
				var numberOfIOBPredicts:int = IOBpredBGs.length;
				for (i = 0; i < numberOfIOBPredicts; i++) 
				{
					//IOBpredBGs[i] = round(Math.min(401,Math.max(39,IOBpredBGs[i])));
					IOBpredBGs[i] = Math.min(401,Math.max(39,IOBpredBGs[i]));
				}
				/*for (i = IOBpredBGs.length-1; i > 12; i--) 
				{
				if (IOBpredBGs[i-1] != IOBpredBGs[i]) { break; }
				else { IOBpredBGs.pop(); }
				}*/
				
				predBGs.IOB = IOBpredBGs;
				lastIOBpredBG = round(IOBpredBGs[IOBpredBGs.length-1]);
				
				var numberOfZTPredicts:int = ZTpredBGs.length;
				for (i = 0; i < numberOfZTPredicts; i++) 
				{
					ZTpredBGs[i] = round(Math.min(401,Math.max(39,ZTpredBGs[i])));
				}
				/*for (i = ZTpredBGs.length-1; i > 6; i--) {
				// stop displaying ZTpredBGs once they're rising and above target
				if (ZTpredBGs[i-1] >= ZTpredBGs[i] || ZTpredBGs[i] <= target_bg) { break; }
				else { ZTpredBGs.pop(); }
				}*/
				
				//predBGs.ZT = ZTpredBGs;
				lastZTpredBG = round(ZTpredBGs[ZTpredBGs.length-1]);
				
				if (meal_data.cob > 0) 
				{
					var numberOfACOBPredicts:int = aCOBpredBGs.length;
					for (i = 0; i < numberOfACOBPredicts; i++) 
					{
						aCOBpredBGs[i] = round(Math.min(401,Math.max(39,aCOBpredBGs[i])));
					}
					
					/*for (i = aCOBpredBGs.length-1; i > 12; i--) {
					if (aCOBpredBGs[i-1] != aCOBpredBGs[i]) { break; }
					else { aCOBpredBGs.pop(); }
					}*/
				}
				
				if (meal_data.cob > 0 && ( ci > 0 || remainingCIpeak > 0 )) 
				{
					var numberOfCOBPredicts:int = COBpredBGs.length;
					for (i = 0; i < numberOfCOBPredicts; i++) 
					{
						//COBpredBGs[i] = round(Math.min(401,Math.max(39,COBpredBGs[i])));
						COBpredBGs[i] = Math.min(401,Math.max(39,COBpredBGs[i]));
					}
					
					/*for (i = COBpredBGs.length-1; i > 12; i--) {
					if (COBpredBGs[i-1] != COBpredBGs[i]) { break; }
					else { COBpredBGs.pop(); }
					}*/
					
					predBGs.COB = COBpredBGs;
					lastCOBpredBG = round(COBpredBGs[COBpredBGs.length-1]);
					eventualBG = Math.max(eventualBG, round(COBpredBGs[COBpredBGs.length-1]) );
				}
				
				if (ci > 0 || remainingCIpeak > 0) 
				{
					if (enableUAM) 
					{
						var numberOfUAMPredicts:int = UAMpredBGs.length;
						for (i = 0; i < numberOfUAMPredicts; i++) 
						{
							UAMpredBGs[i] = round(Math.min(401,Math.max(39,UAMpredBGs[i])));
						}
						
						/*for (var i=UAMpredBGs.length-1; i > 12; i--) {
						if (UAMpredBGs[i-1] != UAMpredBGs[i]) { break; }
						else { UAMpredBGs.pop(); }
						}*/
						
						predBGs.UAM = UAMpredBGs;
						lastUAMpredBG = round(UAMpredBGs[UAMpredBGs.length-1]);
						if (UAMpredBGs[UAMpredBGs.length-1]) 
						{
							eventualBG = Math.max(eventualBG, round(UAMpredBGs[UAMpredBGs.length-1]) );
						}
					}
				}
				
				//trace("UAM Impact:",uci,"mg/dL per 5m; UAM Duration:",UAMduration,"hours");
				
				minIOBPredBG = Math.max(39,minIOBPredBG);
				minCOBPredBG = Math.max(39,minCOBPredBG);
				minUAMPredBG = Math.max(39,minUAMPredBG);
				minPredBG = round(minIOBPredBG);
				
				var fractionCarbsLeft:Number = meal_data.cob / meal_data.carbs;
				// if we have COB and UAM is enabled, average both
				if ( minUAMPredBG < 999 && minCOBPredBG < 999 ) 
				{
					// weight COBpredBG vs. UAMpredBG based on how many carbs remain as COB
					avgPredBG = round( (1-fractionCarbsLeft)*UAMpredBG + fractionCarbsLeft*COBpredBG );
				} 
				else if ( minCOBPredBG < 999 ) 
				{
					// if UAM is disabled, average IOB and COB
					avgPredBG = round( (IOBpredBG + COBpredBG)/2 );
				} 
				else if ( minUAMPredBG < 999 ) 
				{
					// if we have UAM but no COB, average IOB and UAM
					avgPredBG = round( (IOBpredBG + UAMpredBG)/2 );
				} 
				else 
				{
					avgPredBG = round( IOBpredBG );
				}
				
				// if avgPredBG is below minZTGuardBG, bring it up to that level
				if ( minZTGuardBG > avgPredBG ) 
				{
					avgPredBG = minZTGuardBG;
				}
				
				// if we have both minCOBGuardBG and minUAMGuardBG, blend according to fractionCarbsLeft
				if ( (cid || remainingCIpeak > 0) ) {
					if ( enableUAM ) {
						minGuardBG = fractionCarbsLeft*minCOBGuardBG + (1-fractionCarbsLeft)*minUAMGuardBG;
					} else {
						minGuardBG = minCOBGuardBG;
					}
				} else if ( enableUAM ) {
					minGuardBG = minUAMGuardBG;
				} else {
					minGuardBG = minIOBGuardBG;
				}
				minGuardBG = round(minGuardBG);
				
				var minZTUAMPredBG:Number = minUAMPredBG;
				// if minZTGuardBG is below threshold, bring down any super-high minUAMPredBG by averaging
				// this helps prevent UAM from giving too much insulin in case absorption falls off suddenly
				if ( minZTGuardBG < threshold ) {
					minZTUAMPredBG = (minUAMPredBG + minZTGuardBG) / 2;
					// if minZTGuardBG is between threshold and target, blend in the averaging
				} else if ( minZTGuardBG < target_bg ) {
					// target 100, threshold 70, minZTGuardBG 85 gives 50%: (85-70) / (100-70)
					var blendPct:Number = (minZTGuardBG-threshold) / (target_bg-threshold);
					var blendedMinZTGuardBG:Number = minUAMPredBG*blendPct + minZTGuardBG*(1-blendPct);
					minZTUAMPredBG = (minUAMPredBG + blendedMinZTGuardBG) / 2;
					//minZTUAMPredBG = minUAMPredBG - target_bg + minZTGuardBG;
					// if minUAMPredBG is below minZTGuardBG, bring minUAMPredBG up by averaging
					// this allows more insulin if lastUAMPredBG is below target, but minZTGuardBG is still high
				} else if ( minZTGuardBG > minUAMPredBG ) {
					minZTUAMPredBG = (minUAMPredBG + minZTGuardBG) / 2;
				}
				minZTUAMPredBG = round(minZTUAMPredBG);
				
				// if any carbs have been entered recently
				if (meal_data.carbs) {
					
					// if UAM is disabled, use max of minIOBPredBG, minCOBPredBG
					if ( ! enableUAM && minCOBPredBG < 999 ) {
						minPredBG = round(Math.max(minIOBPredBG, minCOBPredBG));
						// if we have COB, use minCOBPredBG, or blendedMinPredBG if it's higher
					} else if ( minCOBPredBG < 999 ) {
						// calculate blendedMinPredBG based on how many carbs remain as COB
						var blendedMinPredBG:Number = fractionCarbsLeft*minCOBPredBG + (1-fractionCarbsLeft)*minZTUAMPredBG;
						// if blendedMinPredBG > minCOBPredBG, use that instead
						minPredBG = round(Math.max(minIOBPredBG, minCOBPredBG, blendedMinPredBG));
						// if carbs have been entered, but have expired, use minUAMPredBG
					} else {
						minPredBG = minZTUAMPredBG;
					}
					// in pure UAM mode, use the higher of minIOBPredBG,minUAMPredBG
				} else if ( enableUAM ) {
					minPredBG = round(Math.max(minIOBPredBG,minZTUAMPredBG));
				}
				
				// make sure minPredBG isn't higher than avgPredBG
				minPredBG = Math.min( minPredBG, avgPredBG );
				
				status += "avgPredBG: " + avgPredBG + ", COB: " + meal_data.cob + " / " + meal_data.carbs + "\n";
				
				// But if the COB line falls off a cliff, don't trust UAM too much:
				// use maxCOBPredBG if it's been set and lower than minPredBG
				if ( maxCOBPredBG > bg ) {
					minPredBG = Math.min(minPredBG, maxCOBPredBG);
				}
				
				// use naive_eventualBG if above 40, but switch to minGuardBG if both eventualBGs hit floor of 39
				var carbsReqBG:Number = naive_eventualBG;
				if ( carbsReqBG < 40 ) {
					carbsReqBG = Math.min( minGuardBG, carbsReqBG );
				}
				
				var bgUndershoot:Number = threshold - carbsReqBG;
				// calculate how long until COB (or IOB) predBGs drop below min_bg
				var minutesAboveMinBG:Number = 240;
				var minutesAboveThreshold:Number = 240;
				if (meal_data.cob > 0 && ( ci > 0 || remainingCIpeak > 0 )) {
					for (i = 0; i<COBpredBGs.length; i++) {
						//console.error(COBpredBGs[i], min_bg);
						if ( COBpredBGs[i] < min_bg ) {
							minutesAboveMinBG = 5*i;
							break;
						}
					}
					for (i = 0; i<COBpredBGs.length; i++) {
						//console.error(COBpredBGs[i], threshold);
						if ( COBpredBGs[i] < threshold ) {
							minutesAboveThreshold = 5*i;
							break;
						}
					}
				} else {
					for (i = 0; i<IOBpredBGs.length; i++) {
						//console.error(IOBpredBGs[i], min_bg);
						if ( IOBpredBGs[i] < min_bg ) {
							minutesAboveMinBG = 5*i;
							break;
						}
					}
					for (i = 0; i<IOBpredBGs.length; i++) {
						//console.error(IOBpredBGs[i], threshold);
						if ( IOBpredBGs[i] < threshold ) {
							minutesAboveThreshold = 5*i;
							break;
						}
					}
				}
				
				if ( minutesAboveThreshold < 240 || minutesAboveMinBG < 60 ) {
					status += "BG projected to remain above " + threshold + " for " + minutesAboveThreshold + " minutes." + "\n";
				}
				
				// include at least minutesAboveThreshold worth of zero temps in calculating carbsReq
				// always include at least 30m worth of zero temp (carbs to 80, low temp up to target)
				var zeroTempDuration:Number = minutesAboveThreshold;
				// BG undershoot, minus effect of zero temps until hitting min_bg, converted to grams, minus COB
				var zeroTempEffect:Number = 0*sens*zeroTempDuration/60;
				// don't count the last 25% of COB against carbsReq
				var COBforCarbsReq:Number = Math.max(0, meal_data.cob - 0.25*meal_data.carbs);
				var carbsReq:Number = (bgUndershoot - zeroTempEffect) / csf - COBforCarbsReq;
				zeroTempEffect = round(zeroTempEffect);
				carbsReq = round(carbsReq);
				
				// calculate 30m low-temp required to get projected BG up to target
				// multiply by 2 to low-temp faster for increased hypo safety
				var insulinReq:Number = 2 * Math.min(0, (eventualBG - target_bg) / sens);
				insulinReq = round( insulinReq , 2);
				
				// calculate naiveInsulinReq based on naive_eventualBG
				var naiveInsulinReq:Number = Math.min(0, (naive_eventualBG - target_bg) / sens);
				naiveInsulinReq = round( naiveInsulinReq , 2);
				
				if (minDelta < 0 && minDelta > expectedDelta) {
					// if we're barely falling, newinsulinReq should be barely negative
					var newinsulinReq:Number = round(( insulinReq * (minDelta / expectedDelta) ), 2);
					//console.error("Increasing insulinReq from " + insulinReq + " to " + newinsulinReq);
					insulinReq = newinsulinReq;
				}
				
				//Add relevant info
				predBGs.bg = bg;
				predBGs.isf = sens;
				predBGs.cr = carb_ratio;
				predBGs.incompleteProfile = incompleteProfile;
				predBGs.bgImpact = bgi;
				predBGs.carbImpact = ci;
				predBGs.deviation = deviation;
				predBGs.eventualBG = eventualBG;
				predBGs.minPredBG = minPredBG;
				predBGs.minGuardBG = minGuardBG;
				predBGs.COBpredBG = COBpredBG;
				predBGs.IOBpredBG = IOBpredBG;
				predBGs.UAMpredBG = UAMpredBG;
				predBGs.COBValue = meal_data.cob;
				predBGs.IOBValue = iob_data.iob;
				predBGs.status = status;
				predBGs.carbsReq = carbsReq;
				predBGs.naiveInsulinReq = naiveInsulinReq;
				predBGs.cacheHash = cacheHash;
				predBGs.minutes = minutes;
				
				//Save cache
				if (!forceNewIOBCOB)
				{
					internalCache[now] = predBGs;
				}
				
				//Return predictions
				return predBGs;
			} 
			catch(error:Error) 
			{
				return null;
			}
			
			return null;
		}
		
		public static function getLastPredictiveBG(duration:Number = Number.NaN):Number
		{
			var finalPrediction:Number =  Number.NaN;
			var predictionsDuration:Number = isNaN(duration) ? getCurrentPredictionsDuration() : duration;
			var lastTreatment:Treatment = TreatmentsManager.getLastTreatment();
			var lastBgReading:BgReading = BgReading.lastWithCalculatedValue();
			var lastTreatmentIsCarbs:Boolean = lastTreatment != null && lastTreatment.carbs > 0 && lastBgReading != null && lastTreatment.timestamp > lastBgReading.timestamp;
			var predictionData:Object = predictBGs(predictionsDuration, lastTreatmentIsCarbs);
			if (predictionData == null)
			{
				return Number.NaN;
			}
			
			var maxNumberOfPredictions:Number = Math.floor(predictionsDuration / 5);
			var predictionsFound:Boolean = false;
			var preferredPrediction:String = "";
			var unformattedIOBPredictionsList:Array = [];
			var unformattedCOBPredictionsList:Array = [];
			var unformattedUAMPredictionsList:Array = [];
			
			//UAM Predictions
			if (predictionData.UAM != null)
			{
				unformattedUAMPredictionsList = predictionData.UAM.concat();
				unformattedUAMPredictionsList.shift();
				
				if (unformattedUAMPredictionsList.length > maxNumberOfPredictions)
				{
					unformattedUAMPredictionsList = unformattedUAMPredictionsList.slice(0, maxNumberOfPredictions);
				}
			}
			
			//COB Predictions
			if (predictionData.COB != null)
			{
				unformattedCOBPredictionsList = predictionData.COB.concat();
				unformattedCOBPredictionsList.shift();
				
				if (unformattedCOBPredictionsList.length > maxNumberOfPredictions)
				{
					unformattedCOBPredictionsList = unformattedCOBPredictionsList.slice(0, maxNumberOfPredictions);
				}
			}
			
			//IOB Predictions
			if (predictionData.IOB != null)
			{
				unformattedIOBPredictionsList = predictionData.IOB.concat();
				unformattedIOBPredictionsList.shift();
				
				if (unformattedIOBPredictionsList.length > maxNumberOfPredictions)
				{
					unformattedIOBPredictionsList = unformattedIOBPredictionsList.slice(0, maxNumberOfPredictions);
				}
			}
			
			//Determine default prediction
			preferredPrediction = determineDefaultPredictionCurve(predictionData);
			if (predictionData != "")
			{
				predictionsFound = true;
			}
			
			//Validate
			if (!predictionsFound)
			{
				//If no predictions are available return not a number
				return Number.NaN;
			}
			
			//Check which prediction to return
			if (preferredPrediction == "COB")
			{
				finalPrediction = unformattedCOBPredictionsList[unformattedCOBPredictionsList.length - 1];
			}
			else if (preferredPrediction == "UAM")
			{
				finalPrediction = unformattedUAMPredictionsList[unformattedUAMPredictionsList.length - 1];
			}
			else if (preferredPrediction == "IOB")
			{
				finalPrediction = unformattedIOBPredictionsList[unformattedIOBPredictionsList.length - 1];
			}
			
			return finalPrediction;
		}
		
		public static function determineDefaultPredictionCurve(predictionData:Object):String
		{
			if (predictionData == null)
			{
				return "";
			}
			
			var defaultPredictionCurve:String = "";
			
			var now:Number = new Date().valueOf();
			var	predictedIOBBG:Number = predictionData.IOBpredBG != null ? predictionData.IOBpredBG : Number.NaN;
			var	predictedUAMBG:Number = predictionData.UAMpredBG != null ? predictionData.UAMpredBG : Number.NaN;
			var predictedCOBBG:Number = predictionData.COBpredBG != null ? predictionData.COBpredBG : Number.NaN;
			var currentIOB:Number = predictionData.IOBValue != null ? predictionData.IOBValue : Number.NaN;
			var currentBG:Number = predictionData.bg != null ? predictionData.bg : Number.NaN;
			
			if (isNaN(currentIOB))
			{
				currentIOB = TreatmentsManager.getTotalIOB(now).iob;
			}
			
			//UAM Predictions
			if (predictionData.UAM != null)
			{
				defaultPredictionCurve = "UAM";
			}
			
			//COB Predictions
			if (predictionData.COB != null)
			{
				if (defaultPredictionCurve == "" || 
					(!isNaN(predictedUAMBG) && !isNaN(predictedCOBBG) && predictedCOBBG > predictedUAMBG)
				)
				{
					defaultPredictionCurve = "COB";
				}
			}
			
			//IOB Predictions
			if (predictionData.IOB != null)
			{
				if (defaultPredictionCurve == "")
				{
					defaultPredictionCurve = "IOB";
				}
				
				if (defaultPredictionCurve == "UAM")
				{
					//Deviation vs Delta Comparisson
					var predictedBGI:Number = predictionData.bgImpact != null ? predictionData.bgImpact : Number.NaN;
					if (!isNaN(predictedBGI))
					{
						var currentDelta:Number = Number(BgGraphBuilder.unitizedDeltaString(false, true));
						if (!isNaN(currentDelta))
						{
							if(Math.abs(predictedBGI - currentDelta) < 1.5)
							{
								defaultPredictionCurve = "IOB";
							}
						}
					}
				}
				
				if (defaultPredictionCurve == "UAM")
				{
					//IOB Zero
					if (!isNaN(currentIOB) && isNaN(predictedIOBBG) && !isNaN(predictedUAMBG) && currentIOB <= 0 && predictedIOBBG > predictedUAMBG)
					{
						defaultPredictionCurve = "IOB";
					}
				}
				
				if (defaultPredictionCurve == "UAM")
				{
					if (!isNaN(predictedIOBBG) && !isNaN(predictedUAMBG) && predictionData.IOB.length > 1 && !isNaN(predictionData.IOB[1]) && predictionData.UAM.length > 1 && !isNaN(predictionData.UAM[1]) && predictedIOBBG >= predictedUAMBG && predictionData.IOB[1] >= predictionData.UAM[1])
					{
						defaultPredictionCurve = "IOB";
					}
				}
				
				if (defaultPredictionCurve == "COB")
				{
					if (!isNaN(predictedIOBBG) && !isNaN(predictedCOBBG) && predictionData.IOB.length > 1 && !isNaN(predictionData.IOB[1]) && predictionData.COB.length > 1 && !isNaN(predictionData.COB[1]) && predictedIOBBG >= predictedCOBBG && predictionData.IOB[1] >= predictionData.COB[1])
					{
						defaultPredictionCurve = "IOB";
					}
				}
					
				//Calibration Especial Case
				if (defaultPredictionCurve != "IOB")
				{
					var lastCalibration:Calibration = Calibration.last();
					if (lastCalibration != null && now - lastCalibration.timestamp < TimeSpan.TIME_10_SECONDS)
					{
						defaultPredictionCurve = "IOB";
					}
				}
				
				//COB
				if (defaultPredictionCurve == "COB")
				{
					if (
						(isNaN(predictedIOBBG) && !isNaN(predictedCOBBG) && predictionData.IOB.length > 1 && !isNaN(predictionData.IOB[1]) && predictionData.COB.length > 1 && !isNaN(predictionData.COB[1]) && predictedIOBBG >= predictedCOBBG && predictionData.IOB[1] >= predictionData.COB[1])
						|| 
						(!isNaN(predictedCOBBG) && !isNaN(predictedIOBBG) && predictionData.IOB.length > 1 && !isNaN(predictionData.IOB[1]) && predictionData.COB.length > 1 && !isNaN(predictionData.COB[1]) && predictionData.IOB[1] > predictionData.COB[1] && !isNaN(currentBG) && currentBG > 40)
					)
					{
						defaultPredictionCurve = "IOB";
					}
				}
				
				
				
				/*var currentDelta:Number = Number(BgGraphBuilder.unitizedDeltaString(false, true));
				
				if (defaultPredictionCurve == "" || 
					(!isNaN(predictedUAMBG) && !isNaN(predictedIOBBG) && predictedIOBBG > predictedUAMBG && !isNaN(currentDelta) && currentDelta <= 3 && defaultPredictionCurve != "COB") || 
					(lastCalibration != null && now - lastCalibration.timestamp < TimeSpan.TIME_10_SECONDS && defaultPredictionCurve != "COB") ||
					(currentIOB <= 0 && !isNaN(currentDelta) && currentDelta <= 3 && defaultPredictionCurve != "COB")
				) 
				{
					defaultPredictionCurve = "IOB";
				}*/
			}
			
			//ZT Predictions
			if (predictionData.ZT != null)
			{
				if (defaultPredictionCurve == "")
				{
					defaultPredictionCurve = "ZTM";
				}
				
				if (defaultPredictionCurve == "IOB")
				{
					if (predictionData.ZT.length > predictionData.IOB.length)
					{
						defaultPredictionCurve = "ZTM";
					}
				}
				
				if (defaultPredictionCurve == "UAM")
				{
					if (predictionData.ZT.length > predictionData.UAM.length)
					{
						defaultPredictionCurve = "ZTM";
					}
				}
				
				if (defaultPredictionCurve == "COB")
				{
					if (predictionData.ZT.length > predictionData.COB.length)
					{
						defaultPredictionCurve = "ZTM";
					}
				}
			}
			
			return defaultPredictionCurve;
		}
		
		// Rounds value to 'digits' decimal places
		private static function round(value:Number, digits:Number = 0):Number
		{
			var scale:Number = Math.pow(10, digits);
			
			return Math.round(value * scale) / scale;
		}
		
		// We expect BG to rise or fall at the rate of BGI,
		// Adjusted by the rate at which BG would need to rise / fall to get eventualBG to target over 2 hours
		private static function calculate_expected_delta(target_bg:Number, eventual_bg:Number, bgi:Number):Number
		{
			// (hours * mins_per_hour) / 5 = how many 5 minute periods in 2h = 24
			var five_min_blocks:Number = 24; //(2 * 60) / 5
			var target_delta:Number = target_bg - eventual_bg;
			var expectedDelta:Number = round(bgi + (target_delta / five_min_blocks), 1);
			
			return expectedDelta;
		}
		
		// Returns latest glucose and delta data (current and averages)
		private static function getLastGlucose():Object
		{
			var glucoseList:Array = BgReading.latest(12, CGMBlueToothDevice.isFollower());
			var numReadings:int = glucoseList.length;
			if (numReadings < 4)
			{
				//User has no readings
				return {
					delta: 0,
					glucose: 0,
					short_avgdelta: 0,
					long_avgdelta: 0,
					date: 0,
					is_valid: false
				};
			}
			
			var nowGlucose:BgReading = glucoseList[0];
			if (nowGlucose == null)
			{
				//Last BG Reading is invalid
				return {
					delta: 0,
					glucose: 0,
					short_avgdelta: 0,
					long_avgdelta: 0,
					date: 0,
					is_valid: false
				};
			}
			
			var now:Object = { glucose: nowGlucose._calculatedValue };
			var now_date:Number = nowGlucose._timestamp;
			var change:Number;
			var last_deltas:Array = [];
			var short_deltas:Array = [];
			var long_deltas:Array = [];
			var i:int;
			
			for (i = 1; i < numReadings; i++) 
			{
				var then:BgReading = glucoseList[i];
				
				if (then != null ) 
				{
					var thenGlucose:Number = then._calculatedValue;
					if (thenGlucose > 38)
					{
						var then_date:Number = then._timestamp;
						var avgdelta:Number = 0;
						var minutesago:Number = Math.round( (now_date - then_date) / TimeSpan.TIME_1_MINUTE );
						change = now.glucose - thenGlucose;
						avgdelta = change/minutesago * 5;
						
						// Use the average of all data points in the last 2.5m for all further "now" calculations
						if (-2 < minutesago && minutesago < 2.5) 
						{
							now.glucose = ( now.glucose + thenGlucose ) / 2;
							now_date = ( now_date + then_date ) / 2;
						} 
						else if (2.5 < minutesago && minutesago < 17.5) // short_deltas are calculated from everything ~5-15 minutes ago
						{
							short_deltas.push(avgdelta);
							
							// last_deltas are calculated from everything ~5 minutes ago
							if (2.5 < minutesago && minutesago < 7.5) 
							{
								last_deltas.push(avgdelta);
							}
						} 
						else if (17.5 < minutesago && minutesago < 42.5) 
						{
							// long_deltas are calculated from everything ~20-40 minutes ago
							long_deltas.push(avgdelta);
						}
					}
				}
			}
			
			var last_delta:Number = 0;
			var short_avgdelta:Number = 0;
			var long_avgdelta:Number = 0;
			
			var numLastDeltas:int = last_deltas.length;
			if (numLastDeltas > 0) 
			{
				for (i = 0; i < numLastDeltas; i++) 
				{
					last_delta += last_deltas[i];
				}
				
				last_delta = last_delta / numLastDeltas;
			}
			
			var numShortDeltas:int = short_deltas.length;
			if (numShortDeltas > 0)
			{
				for (i = 0; i < numShortDeltas; i++) 
				{
					short_avgdelta += short_deltas[i];
				}
				
				short_avgdelta = short_avgdelta / numShortDeltas;
			}
			
			var numLongDeltas:int = long_deltas.length;
			if (numLongDeltas > 0) 
			{
				for (i = 0; i < numLongDeltas; i++) 
				{
					long_avgdelta += long_deltas[i];
				}
				
				long_avgdelta = long_avgdelta / numLongDeltas;
			}
			
			//Populate final calculations and return them as an object
			return {
				delta: Math.round( last_delta * 100 ) / 100,
				glucose: Math.round( now.glucose * 100 ) / 100,
				short_avgdelta: Math.round( short_avgdelta * 100 ) / 100,
				long_avgdelta: Math.round( long_avgdelta * 100 ) / 100,
				date: now_date,
				is_valid: true
			};
		}
		
		/**
		 * Predicted Treatmets Outcome
		 */
		public static function predictOutcome():Number
		{
			//Common properties
			var now:Number = new Date().valueOf();
			var isMgDl:Boolean = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true";
			var insulinPrecision:Number = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BOLUS_WIZARD_INSULIN_PRECISION));
			
			//Get active profile
			var currentProfile:Profile = ProfileManager.getProfileByTime(now);
			
			//Latest glucose
			var latestGlucose:BgReading = BgReading.lastWithCalculatedValue();
			
			//Validation
			if (latestGlucose == null || currentProfile == null || currentProfile.insulinSensitivityFactors == "" || currentProfile.insulinToCarbRatios == "" || currentProfile.targetGlucoseRates == "")
			{
				//We don't have enough profile/glucose data. 
				return Number.NaN;
			}
			
			//Calculation Variables
			var targetBG:Number = Number(currentProfile.targetGlucoseRates);
			var isf:Number = Number(currentProfile.insulinSensitivityFactors);
			var ic:Number = Number(currentProfile.insulinToCarbRatios);
			var bg:Number = Math.round(latestGlucose._calculatedValue);
			var iob:Number = TreatmentsManager.getTotalIOB(now).iob;
			var cob:Number = TreatmentsManager.getTotalCOB(now).cob;;
			var insulincob:Number = Math.round(roundTo(cob / ic, insulinPrecision) * 100) / 100;
			
			//Projected Outcome
			var outcome:Number = bg - (iob * isf) + (insulincob * isf);
			outcome = isMgDl ? Math.round(outcome) : Math.round(BgReading.mgdlToMmol(outcome) * 10) / 10;
			
			return outcome;
		}
		
		private static function roundTo (x:Number, step:Number):Number
		{
			return Math.round(x / step) * step;
		}
		
		public static function getCurrentPredictionsDuration():Number
		{
			var predictionsLengthInMinutes:Number = Number.NaN;
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_GLUCOSE_PREDICTIONS_ENABLED) == "true")
			{
				var timelineRange:Number = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_SELECTED_TIMELINE_RANGE));
				
				if (timelineRange == GlucoseChart.TIMELINE_1H)
					predictionsLengthInMinutes = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_GLUCOSE_PREDICTIONS_MINUTES_FOR_1_HOUR));
				else if (timelineRange == GlucoseChart.TIMELINE_3H)
					predictionsLengthInMinutes = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_GLUCOSE_PREDICTIONS_MINUTES_FOR_3_HOURS));
				else if (timelineRange == GlucoseChart.TIMELINE_6H)
					predictionsLengthInMinutes = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_GLUCOSE_PREDICTIONS_MINUTES_FOR_6_HOURS));
				else if (timelineRange == GlucoseChart.TIMELINE_12H)
					predictionsLengthInMinutes = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_GLUCOSE_PREDICTIONS_MINUTES_FOR_12_HOURS));
				else if (timelineRange == GlucoseChart.TIMELINE_24H)
					predictionsLengthInMinutes = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_GLUCOSE_PREDICTIONS_MINUTES_FOR_24_HOURS));
			}
				
			return predictionsLengthInMinutes;
		}
		
		/**
		 * Helpers
		 */
		public static function clearAllCaches():void
		{
			internalCache = {};
		}
		
		/**
		 * Getters & Setters
		 */
		public static function setAPSPredictions(predictions:Object):void
		{
			apsPredictions = predictions;
			lastExternalPredictionFetchTimestamp = new Date().valueOf();
			
			_instance.dispatchEvent(new PredictionEvent(PredictionEvent.APS_RETRIEVED));
		}

		public static function get instance():Forecast
		{
			return _instance;
		}

	}
}
