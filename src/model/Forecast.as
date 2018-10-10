package model
{
	import flash.utils.getTimer;
	import flash.utils.setInterval;
	import flash.utils.setTimeout;
	
	import mx.utils.ObjectUtil;
	
	import database.BgReading;
	import database.CGMBlueToothDevice;
	import database.CommonSettings;
	
	import starling.utils.SystemUtil;
	
	import treatments.CobCalcTotals;
	import treatments.IOBCalcTotals;
	import treatments.Profile;
	import treatments.ProfileManager;
	import treatments.Treatment;
	import treatments.TreatmentsManager;
	
	import utils.TimeSpan;

	public class Forecast
	{
		public function Forecast()
		{
		}
		
		public static function init():void
		{
			//setInterval(test, 15000);
			
			setTimeout( function():void 
			{
				
				var timer:int = getTimer();
				
				trace("TESTE", ObjectUtil.toString(getLastGlucose()));
				
				trace("took", (getTimer() - timer) / 1000);
				
			}, 10000 );
			
			
		}
		
		private static function PredicBG(minutes:uint):Object
		{
			var glucose_status:Object = getLastGlucose();
			if (!glucose_status.is_valid)
			{
				// Not enough glucose data for predictions!
				return null;
			}
			
			//Define common variables
			var five_min_blocks:Number = Math.ceil(minutes / 5);
			var now:Number = new Date().valueOf();
			var i:int;
			
			var bgTime:Number = glucose_status.date;
			var minAgo:Number = round( (now - bgTime) / TimeSpan.TIME_1_MINUTE ,1);
			
			var bg:Number = glucose_status.glucose;
			var noise:Number = glucose_status.noise;
			
			var currentProfile:Profile = ProfileManager.getProfileByTime(now);
			var target_bg:Number = Number(currentProfile.targetGlucoseRates);
			var min_bg:Number = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_LOW_MARK));
			var max_bg:Number = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_HIGH_MARK));
			
			if (target_bg == 0 || currentProfile.targetGlucoseRates == "")
			{
				trace("No profile set, let's set Target BG to the average of high and low thresholds");
				
				target_bg = (min_bg + max_bg) / 2;
			}
			
			var nowIOB:IOBCalcTotals = TreatmentsManager.getTotalIOB(now);
			var iob_data:Object = { iob: nowIOB.iob, activity: nowIOB.activity };
			var iobArray:Array = [iob_data]; //THIS DOESN'T SEEM RIGHT. SHOULD HAVE MORE DATA POINTS?????
			
			for (i = 1; i < five_min_blocks; i++) 
			{
				var futureIOB:IOBCalcTotals = TreatmentsManager.getTotalIOB(now + (i * TimeSpan.TIME_5_MINUTES));
				iobArray.push( { iob: futureIOB.iob, activity: futureIOB.activity } );
			}
			
			var tick:Number;
			if (glucose_status.delta > -0.5) 
				tick = Math.abs(round(glucose_status.delta,0));
			else
				tick = round(glucose_status.delta,0);
			
			var minDelta:Number = Math.min(glucose_status.delta, glucose_status.short_avgdelta);
			var minAvgDelta:Number = Math.min(glucose_status.short_avgdelta, glucose_status.long_avgdelta);
			var maxDelta:Number = Math.max(glucose_status.delta, glucose_status.short_avgdelta, glucose_status.long_avgdelta);
			
			var sens:Number;
			if (currentProfile.insulinSensitivityFactors != "")
			{
				sens = Number(currentProfile.insulinSensitivityFactors);
			}
			else
			{
				//User has not yet set a profile, let's dfault it to 50
				sens = 50;
			}
			
			//calculate BG impact: the amount BG "should" be rising or falling based on insulin activity alone
			var bgi:Number = round(( -iob_data.activity * sens * 5 ), 2);
			
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
				trace("Error: could not calculate eventualBG." );
				
				return null;
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
			
			// carb impact and duration are 0 unless changed below
			var ci:Number = 0;
			var cid:Number = 0;
			
			// calculate current carb absorption rate, and how long to absorb all carbs
			// CI = current carb impact on BG in mg/dL/5m
			ci = round((minDelta - bgi),1);
			var uci:Number = round((minDelta - bgi),1);
			
			// ISF (mg/dL/U) / CR (g/U) = CSF (mg/dL/g)
			var carb_ratio:Number = currentProfile.insulinToCarbRatios != "" ? Number(currentProfile.insulinToCarbRatios) : 10; //If no i:C is set by the user we default to 10
			var csf:Number = sens / carb_ratio; 
			
			var maxCarbAbsorptionRate:Number = ProfileManager.getCarbAbsorptionRate(); // g/h; maximum rate to assume carbs will absorb if no CI observed
			
			// limit Carb Impact to maxCarbAbsorptionRate * csf in mg/dL per 5m
			var maxCI:Number = round(maxCarbAbsorptionRate*csf*5/60, 1)
			if (ci > maxCI) {
				trace("Limiting carb impact from " + ci + " to " + maxCI + "mg/dL/5m (" + maxCarbAbsorptionRate + "g/h )");
				ci = maxCI;
			}
			
			var remainingCATimeMin:Number = 3; // h; duration of expected not-yet-observed carb absorption
			var assumedCarbAbsorptionRate:Number = 20; // g/h; maximum rate to assume carbs will absorb if no CI observed
			var remainingCATime:Number = remainingCATimeMin;
			
			// 20 g/h means that anything <= 60g will get a remainingCATimeMin, 80g will get 4h, and 120g 6h
			// when actual absorption ramps up it will take over from remainingCATime
			var assumedCarbAbsorptionRate = 20; // g/h; maximum rate to assume carbs will absorb if no CI observed
			var remainingCATime = remainingCATimeMin;
			
			var nowCOB:CobCalcTotals = TreatmentsManager.getTotalCOB(now);
			if (nowCOB.carbs > 0) 
			{
				// if carbs * assumedCarbAbsorptionRate > remainingCATimeMin, raise it
				// so <= 90g is assumed to take 3h, and 120g=4h
				remainingCATimeMin = Math.max(remainingCATimeMin, nowCOB.cob / assumedCarbAbsorptionRate);
				var lastCarbAge:Number = round(( now - nowCOB.lastCarbTime ) / 60000);
				
				var fractionCOBAbsorbed:Number = ( nowCOB.carbs - nowCOB.cob ) / nowCOB.carbs;
				remainingCATime = remainingCATimeMin + 1.5 * lastCarbAge/60;
				remainingCATime = round(remainingCATime,1);
				
				trace("Last carbs",lastCarbAge,"minutes ago; remainingCATime:",remainingCATime,"hours;",round(fractionCOBAbsorbed*100)+"% carbs absorbed");
			}
			
			// calculate the number of carbs absorbed over remainingCATime hours at current CI
			// CI (mg/dL/5m) * (5m)/5 (m) * 60 (min/hr) * 4 (h) / 2 (linear decay factor) = total carb impact (mg/dL)
			var totalCI:Number = Math.max(0, ci / 5 * 60 * remainingCATime / 2);
			
			// totalCI (mg/dL) / CSF (mg/dL/g) = total carbs absorbed (g)
			var totalCA:Number = totalCI / csf;
			var remainingCarbsCap:Number = 90; // default to 90
			var remainingCarbsFraction:Number = 1;
			var remainingCarbsIgnore:Number = 1 - remainingCarbsFraction;
			var remainingCarbs:Number = Math.max(0, nowCOB.cob - totalCA - nowCOB.carbs*remainingCarbsIgnore);
			remainingCarbs = Math.min(remainingCarbsCap,remainingCarbs);
			// assume remainingCarbs will absorb in a /\ shaped bilinear curve
			// peaking at remainingCATime / 2 and ending at remainingCATime hours
			// area of the /\ triangle is the same as a remainingCIpeak-height rectangle out to remainingCATime/2
			// remainingCIpeak (mg/dL/5m) = remainingCarbs (g) * CSF (mg/dL/g) * 5 (m/5m) * 1h/60m / (remainingCATime/2) (h)
			var remainingCIpeak:Number = remainingCarbs * csf * 5 / 60 / (remainingCATime/2);
			
			// calculate peak deviation in last hour, and slope from that to current deviation
			var slopeFromMaxDeviation = round(nowCOB.slopeFromMaxDeviation,2);
			// calculate lowest deviation in last hour, and slope from that to current deviation
			var slopeFromMinDeviation = round(meal_data.slopeFromMinDeviation,2);
			// assume deviations will drop back down at least at 1/3 the rate they ramped up
			var slopeFromDeviations = Math.min(slopeFromMaxDeviation,-slopeFromMinDeviation/3);
			
			//Setting both to default values but will need to correct this by implementing OpenAPS COB algo
			var slopeFromMaxDeviation:Number = 0;
			var slopeFromMinDeviation:Number = 999;
			
			
			// calculate peak deviation in last hour, and slope from that to current deviation
			slopeFromMaxDeviation = round(slopeFromMaxDeviation,2);
			// calculate lowest deviation in last hour, and slope from that to current deviation
			var slopeFromMinDeviationber:Number = round(slopeFromMinDeviation,2);
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
				cid = Math.min(remainingCATime*60/5/2,Math.max(0, currentCOB * csf / ci ));
			}
			
			var acid:Number = Math.max(0, currentCOB * csf / aci );
			// duration (hours) = duration (5m) * 5 / 60 * 2 (to account for linear decay)
			trace("Carb Impact:",ci,"mg/dL per 5m; CI Duration:",round(cid*5/60*2,1),"hours; remaining CI (~2h peak):",round(remainingCIpeak,1),"mg/dL per 5m");
			
			
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
		
			iobArray.forEach(function(iobTick:Object, i:int, theArray:Array):void {
				//console.error(iobTick);
				predBGI = round(( -iobTick.activity * sens * 5 ), 2);
				predZTBGI = round(( -iobTick.activity * sens * 5 ), 2);
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
				if ( IOBpredBGs.length < 48) { IOBpredBGs.push(IOBpredBG); }
				if ( COBpredBGs.length < 48) { COBpredBGs.push(COBpredBG); }
				if ( aCOBpredBGs.length < 48) { aCOBpredBGs.push(aCOBpredBG); }
				if ( UAMpredBGs.length < 48) { UAMpredBGs.push(UAMpredBG); }
				if ( ZTpredBGs.length < 48) { ZTpredBGs.push(ZTpredBG); }
				// calculate minGuardBGs without a wait from COB, UAM, IOB predBGs
				if ( COBpredBG < minCOBGuardBG ) { minCOBGuardBG = round(COBpredBG); }
				if ( UAMpredBG < minUAMGuardBG ) { minUAMGuardBG = round(UAMpredBG); }
				if ( IOBpredBG < minIOBGuardBG ) { minIOBGuardBG = round(IOBpredBG); }
				if ( ZTpredBG < minZTGuardBG ) { minZTGuardBG = round(ZTpredBG); }
					
				// set minPredBGs starting when currently-dosed insulin activity will peak
				// look ahead 60m (regardless of insulin type) so as to be less aggressive on slower insulins
				insulinPeakTime = 60;
				// add 30m to allow for insluin delivery (SMBs or temps)
				//insulinPeakTime = 90;
				insulinPeak5m = (insulinPeakTime/60)*12;
				//console.error(insulinPeakTime, insulinPeak5m, profile.insulinPeakTime, profile.curve);
					
				// wait 90m before setting minIOBPredBG
				if ( IOBpredBGs.length > insulinPeak5m && (IOBpredBG < minIOBPredBG) ) { minIOBPredBG = round(IOBpredBG); }
				if ( IOBpredBG > maxIOBPredBG ) { maxIOBPredBG = IOBpredBG; }
				// wait 85-105m before setting COB and 60m for UAM minPredBGs
				if ( (cid || remainingCIpeak > 0) && COBpredBGs.length > insulinPeak5m && (COBpredBG < minCOBPredBG) ) { minCOBPredBG = round(COBpredBG); }
				if ( (cid || remainingCIpeak > 0) && COBpredBG > maxIOBPredBG ) { maxCOBPredBG = COBpredBG; }
			});
			
			if (currentCOB > 0) {
				trace("predCIs (mg/dL/5m):",predCIs.join(" "));
				trace("remainingCIs:      ",remainingCIs.join(" "));
			}
			
			var predBGs:Object = {};
			IOBpredBGs.forEach(function(p:Number, i:int, theArray:Array):void {
				theArray[i] = round(Math.min(401,Math.max(39,p)));
			});
			
			for (i = IOBpredBGs.length-1; i > 12; i--) 
			{
				if (IOBpredBGs[i-1] != IOBpredBGs[i]) { break; }
				else { IOBpredBGs.pop(); }
			}
			
			predBGs.IOB = IOBpredBGs;
			lastIOBpredBG = round(IOBpredBGs[IOBpredBGs.length-1]);
			ZTpredBGs.forEach(function(p:Number, i:int, theArray:Array):void {
				theArray[i] = round(Math.min(401,Math.max(39,p)));
			});
			for (i = ZTpredBGs.length-1; i > 6; i--) {
				// stop displaying ZTpredBGs once they're rising and above target
				if (ZTpredBGs[i-1] >= ZTpredBGs[i] || ZTpredBGs[i] <= target_bg) { break; }
				else { ZTpredBGs.pop(); }
			}
			
			predBGs.ZT = ZTpredBGs;
			lastZTpredBG = round(ZTpredBGs[ZTpredBGs.length-1]);
			if (currentCOB > 0) {
				aCOBpredBGs.forEach(function(p:Number, i:int, theArray:Array):void {
					theArray[i] = round(Math.min(401,Math.max(39,p)));
				});
				for (i = aCOBpredBGs.length-1; i > 12; i--) {
					if (aCOBpredBGs[i-1] != aCOBpredBGs[i]) { break; }
					else { aCOBpredBGs.pop(); }
				}
			}
			
			if (currentCOB > 0 && ( ci > 0 || remainingCIpeak > 0 )) {
				COBpredBGs.forEach(function(p:Number, i:int, theArray:Array):void {
					theArray[i] = round(Math.min(401,Math.max(39,p)));
				});
				for (i = COBpredBGs.length-1; i > 12; i--) {
					if (COBpredBGs[i-1] != COBpredBGs[i]) { break; }
					else { COBpredBGs.pop(); }
				}
				predBGs.COB = COBpredBGs;
				lastCOBpredBG = round(COBpredBGs[COBpredBGs.length-1]);
				eventualBG = Math.max(eventualBG, round(COBpredBGs[COBpredBGs.length-1]) );
			}
			
			trace("UAM Impact:",uci,"mg/dL per 5m; UAM Duration:",UAMduration,"hours");
			
			minIOBPredBG = Math.max(39,minIOBPredBG);
			minCOBPredBG = Math.max(39,minCOBPredBG);
			minUAMPredBG = Math.max(39,minUAMPredBG);
			minPredBG = round(minIOBPredBG);
			
			var fractionCarbsLeft:Number = currentCOB/activeCarbs.carbs;
			// if we have COB and UAM is enabled, average both
			if ( minUAMPredBG < 999 && minCOBPredBG < 999 ) {
				// weight COBpredBG vs. UAMpredBG based on how many carbs remain as COB
				avgPredBG = round( (1-fractionCarbsLeft)*UAMpredBG + fractionCarbsLeft*COBpredBG );
				// if UAM is disabled, average IOB and COB
			} else if ( minCOBPredBG < 999 ) {
				avgPredBG = round( (IOBpredBG + COBpredBG)/2 );
				// if we have UAM but no COB, average IOB and UAM
			} else if ( minUAMPredBG < 999 ) {
				avgPredBG = round( (IOBpredBG + UAMpredBG)/2 );
			} else {
				avgPredBG = round( IOBpredBG );
			}
			// if avgPredBG is below minZTGuardBG, bring it up to that level
			if ( minZTGuardBG > avgPredBG ) {
				avgPredBG = minZTGuardBG;
			}
			
			
			// if we have both minCOBGuardBG and minUAMGuardBG, blend according to fractionCarbsLeft
			var enableUAM:Boolean = false //We set to false because this is not relevant to Spike
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
			if (activeCarbs.carbs) {
				
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
			
			trace("minPredBG: "+minPredBG+" minIOBPredBG: "+minIOBPredBG+" minZTGuardBG: "+minZTGuardBG);
			if (minCOBPredBG < 999) {
				trace(" minCOBPredBG: "+minCOBPredBG);
			}
			if (minUAMPredBG < 999) {
				trace(" minUAMPredBG: "+minUAMPredBG);
			}
			trace(" avgPredBG:",avgPredBG,"COB:",currentCOB,"/",activeCarbs.carbs);
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
			if (currentCOB > 0 && ( ci > 0 || remainingCIpeak > 0 )) {
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
				trace("BG projected to remain above", threshold,"for",minutesAboveThreshold,"minutes");
			}
			
			
			
			
			
			trace("COBpredBGs", ObjectUtil.toString(COBpredBGs));
			trace("aCOBpredBGs", ObjectUtil.toString(aCOBpredBGs));
			trace("IOBpredBGs", ObjectUtil.toString(IOBpredBGs));
			trace("UAMpredBGs", ObjectUtil.toString(UAMpredBGs));
			trace("ZTpredBGs", ObjectUtil.toString(ZTpredBGs));
		
		}
		
		/**
		 * Helper Functions
		 */
		
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
			var glucoseList:Array = BgReading.latest(16, CGMBlueToothDevice.isFollower());
			var numReadings:int = glucoseList.length;
			if (numReadings == 0)
			{
				//User has no readings
				return {
					delta: 0,
					glucose: 0,
					noise: 0,
					short_avgdelta: 0,
					long_avgdelta: 0,
					date: 0
				};
			}
			
			var nowGlucose:BgReading = glucoseList[0];
			if (nowGlucose == null)
			{
				//Last BG Reading is invalid
				return {
					delta: 0,
					glucose: 0,
					noise: 0,
					short_avgdelta: 0,
					long_avgdelta: 0,
					date: 0
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
				noise: 1,
				short_avgdelta: Math.round( short_avgdelta * 100 ) / 100,
				long_avgdelta: Math.round( long_avgdelta * 100 ) / 100,
				date: now_date,
				is_valid = true
			};
		}
	}
}
