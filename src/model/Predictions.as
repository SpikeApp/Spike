package model
{
	import flash.utils.setInterval;
	import flash.utils.setTimeout;
	
	import mx.utils.ObjectUtil;
	
	import database.BgReading;
	
	import treatments.Profile;
	import treatments.ProfileManager;
	import treatments.TreatmentsManager;
	
	import utils.BgGraphBuilder;
	import utils.TimeSpan;

	public class Predictions
	{
		public function Predictions()
		{
		}
		
		public static function init():void
		{
			setInterval(test, 1000);
		}
		
		private static function test():void
		{
			//trace(BgGraphBuilder.unitizedDeltaString(false, true));
			
			var now:Number = new Date().valueOf();
			var i:int;
			
			var currentBgReading:BgReading = BgReading.lastWithCalculatedValue();
			if (currentBgReading == null || currentBgReading.calculatedValue < 39)
			{
				trace("invalid bg reading");
				return;
			}
			
			var currentProfile:Profile = ProfileManager.getProfileByTime(now);
			
			var target_bg:Number = Number(currentProfile.targetGlucoseRates);
			var min_bg:Number = 70;
			var threshold:Number = min_bg - 0.5*(min_bg-50);
			
			var iobArray:Array = [];
			
			//60 minutes
			for (i = 0; i < 6; i++) 
			{
				var tempIOB:Number = TreatmentsManager.getTotalIOB(now + (i * TimeSpan.TIME_5_MINUTES));
				var tempActivity:Number = TreatmentsManager.totalActivity;
				
				iobArray.push( { iob: tempIOB, activity: tempActivity } );
			}
			
			var iob_data:Object = iobArray[0];
			
			var glucose_status:Object = new Object();
			glucose_status.delta = Number(BgGraphBuilder.unitizedDeltaString(false, true));
			glucose_status.glucose = Math.round(currentBgReading.calculatedValue);
			glucose_status.long_avgdelta =  Number(BgGraphBuilder.unitizedDeltaString(false, true));
			glucose_status.short_avgdelta =  Number(BgGraphBuilder.unitizedDeltaString(false, true));
			
			var bg:Number = glucose_status.glucose;
			
			var minDelta:Number = Math.min(glucose_status.delta, glucose_status.short_avgdelta, glucose_status.long_avgdelta);
			var minAvgDelta:Number = Math.min(glucose_status.short_avgdelta, glucose_status.long_avgdelta);
			
			var sens:Number = Number(currentProfile.insulinSensitivityFactors);
			
			//calculate BG impact: the amount BG "should" be rising or falling based on insulin activity alone
			var bgi:Number = round(( -iob_data.activity * sens * 5 ), 2);
			trace("bgi", bgi);
			
			// project deviations for 30 minutes
			var deviation:Number = Math.round( 30 / 5 * ( minDelta - bgi ) );
			// don't overreact to a big negative delta: use minAvgDelta if deviation is negative
			if (deviation < 0) 
			{
				deviation = Math.round( (30 / 5) * ( minAvgDelta - bgi ) );
			}
			trace("deviation", deviation);
			
			// calculate the naive (bolus calculator math) eventual BG based on net IOB and sensitivity
			var naive_eventualBG:Number = 0;
			if (iob_data.iob >= 0) 
			{
				naive_eventualBG = Math.round( bg - (iob_data.iob * sens) );
			}
			trace("naive_eventualBG", naive_eventualBG);
			
			// and adjust it for the deviation above
			var eventualBG:Number = naive_eventualBG + deviation;
			trace("eventualBG", eventualBG);
			
			var expectedDelta:Number = calculate_expected_delta(2, target_bg, eventualBG, bgi);
			trace("expectedDelta", expectedDelta);
			
			if (isNaN(eventualBG))
			{
				trace("abort, can't calculate eventualBG");
				return;
			}
			
			var basaliob:Number = iob_data.iob;
			
			// generate predicted future BGs based on IOB, COB, and current absorption rate
			var COBpredBGs:Array = [];
			var aCOBpredBGs:Array = [];
			var IOBpredBGs:Array = [];
			COBpredBGs.push(bg);
			aCOBpredBGs.push(bg);
			IOBpredBGs.push(bg);
			
			// carb impact and duration are 0 unless changed below
			var ci:Number = 0;
			var cid:Number = 0;
			
			// calculate current carb absorption rate, and how long to absorb all carbs
			// CI = current carb impact on BG in mg/dL/5m
			ci = Math.round((minDelta - bgi)*10)/10;
			//if (meal_data.mealCOB * 2 > meal_data.carbs) {
				// set ci to a minimum of 3mg/dL/5m (default) if less than half of carbs have absorbed
				//ci = Math.max(profile.min_5m_carbimpact, ci);
			//}
			
			var aci:Number = 10;
			
			//5m data points = g * (1U/10g) * (40mg/dL/1U) / (mg/dL/5m)
			cid = TreatmentsManager.getTotalCOB(now) * ( sens / Number(currentProfile.insulinToCarbRatios) ) / ci;
			var acid:Number = TreatmentsManager.getTotalCOB(now) * ( sens / Number(currentProfile.insulinToCarbRatios) ) / aci;
			
			trace("Carb Impact:",ci,"mg/dL per 5m; CI Duration:",Math.round(10*cid/6)/10,"hours");
			trace("Accel. Carb Impact:",aci,"mg/dL per 5m; ACI Duration:",Math.round(10*acid/6)/10,"hours");
			
			var minPredBG:Number = 999;
			var maxPredBG:Number = bg;
			var eventualPredBG:Number = bg;
			
			/*for (var j:int = 0; j < iobArray.length; j++) 
			{
				var iobTick:Object = iobArray[j];
				
				var predBGI:Number = round(( -iobTick.activity * sens * 5 ), 2);
				// predicted deviation impact drops linearly from current deviation down to zero
				// over 60 minutes (data points every 5m)
				var predDev:Number = ci * ( 1 - Math.min(1,IOBpredBGs.length/(60/5)) );
				var IOBpredBG:Number = IOBpredBGs[IOBpredBGs.length-1] + predBGI + predDev;
				//IOBpredBG = IOBpredBGs[IOBpredBGs.length-1] + predBGI;
				// predicted carb impact drops linearly from current carb impact down to zero
				// eventually accounting for all carbs (if they can be absorbed over DIA)
				var predCI:Number = Math.max(0, ci * ( 1 - COBpredBGs.length/Math.max(cid*2,1) ) );
				var predACI:Number = Math.max(0, aci * ( 1 - COBpredBGs.length/Math.max(acid*2,1) ) );
				var COBpredBG:Number = COBpredBGs[COBpredBGs.length-1] + predBGI + Math.min(0,predDev) + predCI;
				var aCOBpredBG:Number = aCOBpredBGs[aCOBpredBGs.length-1] + predBGI + Math.min(0,predDev) + predACI;
				//console.error(predBGI, predCI, predBG);
				IOBpredBGs.push(IOBpredBG);
				COBpredBGs.push(COBpredBG);
				aCOBpredBGs.push(aCOBpredBG);
				// wait 45m before setting minPredBG
				if ( COBpredBGs.length > 9 && (COBpredBG < minPredBG) ) { minPredBG = COBpredBG; }
				if ( COBpredBG > maxPredBG ) { maxPredBG = COBpredBG; }
			}*/
			
			iobArray.forEach(function(iobTick:Object, i:int, theArray:Array):void {
				//console.error(iobTick);
				var predBGI:Number = round(( -iobTick.activity * sens * 5 ), 2);
				// predicted deviation impact drops linearly from current deviation down to zero
				// over 60 minutes (data points every 5m)
				var predDev:Number = ci * ( 1 - Math.min(1,IOBpredBGs.length/(60/5)) );
				var IOBpredBG:Number = IOBpredBGs[IOBpredBGs.length-1] + predBGI + predDev;
				//IOBpredBG = IOBpredBGs[IOBpredBGs.length-1] + predBGI;
				// predicted carb impact drops linearly from current carb impact down to zero
				// eventually accounting for all carbs (if they can be absorbed over DIA)
				var predCI:Number = Math.max(0, ci * ( 1 - COBpredBGs.length/Math.max(cid*2,1) ) );
				var predACI:Number = Math.max(0, aci * ( 1 - COBpredBGs.length/Math.max(acid*2,1) ) );
				var COBpredBG:Number = COBpredBGs[COBpredBGs.length-1] + predBGI + Math.min(0,predDev) + predCI;
				var aCOBpredBG:Number = aCOBpredBGs[aCOBpredBGs.length-1] + predBGI + Math.min(0,predDev) + predACI;
				//console.error(predBGI, predCI, predBG);
				IOBpredBGs.push(IOBpredBG);
				COBpredBGs.push(COBpredBG);
				aCOBpredBGs.push(aCOBpredBG);
				// wait 45m before setting minPredBG
				if ( COBpredBGs.length > 9 && (COBpredBG < minPredBG) ) { minPredBG = COBpredBG; }
				if ( COBpredBG > maxPredBG ) { maxPredBG = COBpredBG; }
			});

			
			IOBpredBGs.forEach(function(p:Number, i:int, theArray:Array):void {
				theArray[i] = Math.round(Math.min(401,Math.max(39,p)));
			});
			for (i = IOBpredBGs.length-1; i > 12; i--) {
				if (IOBpredBGs[i-1] != IOBpredBGs[i]) { break; }
				else { IOBpredBGs.pop(); }
			}
			
			trace("IOBpredBGs", ObjectUtil.toString(IOBpredBGs));
			trace("COBpredBGs", ObjectUtil.toString(COBpredBGs));
			trace("aCOBpredBGs", ObjectUtil.toString(aCOBpredBGs));
		}
		
		// Rounds value to 'digits' decimal places
		private static function round(value:Number, digits:Number):Number
		{
			var scale:Number = Math.pow(10, digits);
			
			return Math.round(value * scale) / scale;
		}
		
		// we expect BG to rise or fall at the rate of BGI,
		// adjusted by the rate at which BG would need to rise /
		// fall to get eventualBG to target over DIA/2 hours
		private static function calculate_expected_delta(dia:Number, target_bg:Number, eventual_bg:Number, bgi:Number):Number {
			// (hours * mins_per_hour) / 5 = how many 5 minute periods in dia/2
			var dia_in_5min_blocks:Number = (dia/2 * 60) / 5;
			var target_delta:Number  = target_bg- eventual_bg;
			var expectedDelta:Number = round(bgi + (target_delta / dia_in_5min_blocks), 1);
			return expectedDelta;
		}
		
	}
}








