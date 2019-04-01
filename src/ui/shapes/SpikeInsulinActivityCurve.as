package ui.shapes
{
	import flash.display.StageOrientation;
	
	import feathers.controls.Label;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalAlign;
	
	import starling.display.Sprite;
	
	import ui.screens.display.LayoutFactory;
	
	import utils.Constants;
	import utils.DeviceInfo;

	/**
	 * Plots insulin activity curve for OpenAPS bilinear and exponential as well as Nightscout bilinear
	 */
	public class SpikeInsulinActivityCurve extends Sprite
	{
		//Constants
		public static const EXPONENTIAL_OPENAPS_MODEL:String = "exponentialOpenAPSModel";
		public static const BILINEAR_OPENAPS_MODEL:String = "bilinearOpenAPSModel";
		public static const NIGHTSCOUT_MODEL:String = "nightscoutModel";
		
		//Properties
		private var labelsList:Array = [];
		private var insulinCurve:SpikeLine;
		private var xAxisLine:SpikeLine;
		private var yAxisLine:SpikeLine;
		
		public function SpikeInsulinActivityCurve(type:String, dia:Number = Number.NaN, peak:Number = Number.NaN)
		{
			if (type == EXPONENTIAL_OPENAPS_MODEL)
			{
				plotOpenAPSExponential(dia, peak);
			}
			else if (type == BILINEAR_OPENAPS_MODEL)
			{
				plotOpenAPSBilinear(dia);
			}
			else if (type == NIGHTSCOUT_MODEL)
			{
				plotNightscout(dia);
			}
		}
		
		/**
		 * Plot UI Functions
		 */
		private function plotNightscout(dia:Number):void
		{
			//Common variables/constants
			var DESIRED_WIDTH:int = Constants.stageWidth - 60;
			if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr && !Constants.isPortrait)
			{
				if (Constants.currentOrientation == StageOrientation.ROTATED_RIGHT)
				{
					DESIRED_WIDTH -= 20;
				}
				else if (Constants.currentOrientation == StageOrientation.ROTATED_LEFT)
				{
					DESIRED_WIDTH -= 30;
				}
			}
			const DESIRED_HEIGHT:int = Constants.stageHeight / 5;
			const DURATION:Number = dia * 60;
			var i:int = 0;
			
			//Calculate data points (x, y)
			var xArray:Array = [];	
			for (i = 0; i <= DURATION; i++)
			{
				xArray.push(i);
			}
			var numberOfX:uint = xArray.length;
			var xPlotMultiplier:Number = DESIRED_WIDTH / DURATION;
			
			var yArray:Array = [];
			for (i = 0; i < numberOfX; i++)
			{
				yArray.push(scalableNightscoutIA(dia, xArray[i]));
			}
			
			//Determine max y value
			var tempYArray:Array = yArray.concat();
			tempYArray.sort(Array.NUMERIC | Array.DESCENDING);
			
			var maxYValue:Number = tempYArray[0];
			var yPlotMultiplier:Number = DESIRED_HEIGHT / maxYValue;
			
			//Draw insulin action curve
			insulinCurve = new SpikeLine();
			insulinCurve.touchable = false;
			insulinCurve.lineStyle(2, 0x0086FF, 1);
			insulinCurve.moveTo(0, 0);
			
			for (i = 1; i < numberOfX; i++)
			{
				insulinCurve.lineTo(xArray[i] * xPlotMultiplier, -yArray[i] * yPlotMultiplier);
				insulinCurve.moveTo(xArray[i] * xPlotMultiplier, -yArray[i] * yPlotMultiplier);
			}
			
			//Rescale
			insulinCurve.width = DESIRED_WIDTH;
			insulinCurve.height = DESIRED_HEIGHT;
			
			//Reposition curve
			insulinCurve.y += insulinCurve.height;
			
			//Add curve to display list
			addChild(insulinCurve);
			
			//First X Label
			var firstXLabel:Label = LayoutFactory.createLabel("0", HorizontalAlign.LEFT, VerticalAlign.TOP, 8, true);
			firstXLabel.validate();
			firstXLabel.x = -firstXLabel.width / 2;
			firstXLabel.y = insulinCurve.height + 4;
			firstXLabel.validate();
			labelsList.push(firstXLabel);
			addChild(firstXLabel);
			
			//Last X Label
			var lastXLabel:Label = LayoutFactory.createLabel(String(Math.round(DURATION)), HorizontalAlign.LEFT, VerticalAlign.TOP, 8, true);
			lastXLabel.validate();
			lastXLabel.x = insulinCurve.x + insulinCurve.width - lastXLabel.width;
			lastXLabel.y = insulinCurve.height + 4;
			lastXLabel.validate();
			labelsList.push(lastXLabel);
			addChild(lastXLabel);
			
			//Intermediate X Labels
			var numberOfXLabels:Number = Math.floor(DURATION / 30);
			var xLabelMultiplier:Number = (30 * DESIRED_WIDTH) / DURATION;
			var lastIntermediateXLabel:Label;
			var previousIntermediateXLabel:Label;
			for (i = 1; i <= numberOfXLabels; i++)
			{
				var xLabel:Label = LayoutFactory.createLabel(String(i * 30), HorizontalAlign.LEFT, VerticalAlign.TOP, 8, true);
				xLabel.validate();
				xLabel.x = (i * xLabelMultiplier) - (xLabel.width / 2);
				xLabel.y = insulinCurve.height + 4;
				xLabel.validate();
				labelsList.push(xLabel);
				
				if (i == numberOfXLabels)
				{
					lastIntermediateXLabel = xLabel;
				}
				
				if (i == numberOfXLabels - 1)
				{
					previousIntermediateXLabel = xLabel;
				}
				
				addChild(xLabel);
			}
			
			//Check Last and Previous Intermediate X Labels Intersects
			if (lastIntermediateXLabel.x + lastIntermediateXLabel.width > lastXLabel.x - 3)
			{
				lastIntermediateXLabel.removeFromParent(true);
				lastIntermediateXLabel = null;
			}
			
			if (previousIntermediateXLabel.x + previousIntermediateXLabel.width > lastXLabel.x - 3)
			{
				previousIntermediateXLabel.removeFromParent(true);
				previousIntermediateXLabel = null;
			}
			
			//First Y Label
			var firstYLabel:Label = LayoutFactory.createLabel("0", HorizontalAlign.RIGHT, VerticalAlign.TOP, 8, true);
			firstYLabel.validate();
			firstYLabel.x = -firstYLabel.width - 6;
			firstYLabel.y = insulinCurve.height - (firstYLabel.height / 2);
			firstYLabel.validate();
			labelsList.push(firstYLabel);
			addChild(firstYLabel);
			
			//Last Y Label
			var roundedMaxYValue:Number = Math.round((maxYValue * 100) * 100) / 100;
			var lastYLabel:Label = LayoutFactory.createLabel(String(roundedMaxYValue), HorizontalAlign.RIGHT, VerticalAlign.TOP, 8, true);
			lastYLabel.validate();
			lastYLabel.x = -lastYLabel.width - 6;
			lastYLabel.y = -(lastYLabel.height / 2) + 2;
			lastYLabel.validate();
			labelsList.push(lastYLabel);
			addChild(lastYLabel);
			
			//Intermediate Y Labels
			var numberOfYLabels:Number = Math.floor(roundedMaxYValue / 0.1); //0.1 increments
			var yLabelMultiplier:Number = (0.1 * DESIRED_HEIGHT) / roundedMaxYValue;
			var lastIntermediateYLabel:Label;
			for (i = 1; i <= numberOfYLabels; i++)
			{
				var yLabel:Label = LayoutFactory.createLabel(String(Math.round(i * 0.1 * 100) / 100), HorizontalAlign.RIGHT, VerticalAlign.TOP, 8, true);
				yLabel.validate();
				yLabel.x = -yLabel.width - 6;
				yLabel.y =  insulinCurve.height - (yLabel.height / 2) - (i * yLabelMultiplier);
				yLabel.validate();
				labelsList.push(yLabel);
				
				if (i == 1)
				{
					if (!yLabel.bounds.intersects(firstYLabel.bounds))
					{
						lastIntermediateYLabel = yLabel;
						addChild(yLabel);
					}
				}
				else if (lastIntermediateYLabel == null || (yLabel.y - yLabel.height > lastYLabel.y && !yLabel.bounds.intersects(lastIntermediateYLabel.bounds)))
				{
					lastIntermediateYLabel = yLabel;
					addChild(yLabel);
				}
			}
			
			//X Axis
			xAxisLine = new SpikeLine();
			xAxisLine.touchable = false;
			xAxisLine.lineStyle(1, 0xEEEEEE, 1);
			xAxisLine.moveTo(-1, insulinCurve.height + 1);
			xAxisLine.lineTo(insulinCurve.width - 1, insulinCurve.height + 1);
			addChild(xAxisLine);
			
			//Y Axis
			yAxisLine = new SpikeLine();
			yAxisLine.touchable = false;
			yAxisLine.lineStyle(1, 0xEEEEEE, 1);
			yAxisLine.moveTo(-1, insulinCurve.height + 1);
			yAxisLine.lineTo(-1, 1);
			addChild(yAxisLine);
		}
		
		private function plotOpenAPSBilinear(dia:Number):void
		{
			//Common variables/constants
			var DESIRED_WIDTH:int = Constants.stageWidth - 60;
			if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr && !Constants.isPortrait)
			{
				if (Constants.currentOrientation == StageOrientation.ROTATED_RIGHT)
				{
					DESIRED_WIDTH -= 20;
				}
				else if (Constants.currentOrientation == StageOrientation.ROTATED_LEFT)
				{
					DESIRED_WIDTH -= 30;
				}
			}
			const DESIRED_HEIGHT:int = Constants.stageHeight / 5;
			const DURATION:Number = dia * 60;
			var i:int = 0;
			
			//Calculate data points (x, y)
			var xArray:Array = [];	
			for (i = 0; i <= DURATION; i++)
			{
				xArray.push(i);
			}
			var numberOfX:uint = xArray.length;
			var xPlotMultiplier:Number = DESIRED_WIDTH / DURATION;
			
			var yArray:Array = [];
			for (i = 0; i < numberOfX; i++)
			{
				yArray.push(scalableBilinearIA(dia, xArray[i]));
			}
			
			//Determine max y value
			var tempYArray:Array = yArray.concat();
			tempYArray.sort(Array.NUMERIC | Array.DESCENDING);
			
			var maxYValue:Number = tempYArray[0];
			var yPlotMultiplier:Number = DESIRED_HEIGHT / maxYValue;
			
			//Draw insulin action curve
			insulinCurve = new SpikeLine();
			insulinCurve.touchable = false;
			insulinCurve.lineStyle(2, 0x0086FF, 1);
			insulinCurve.moveTo(0, 0);
			
			for (i = 1; i < numberOfX; i++)
			{
				insulinCurve.lineTo(xArray[i] * xPlotMultiplier, -yArray[i] * yPlotMultiplier);
				insulinCurve.moveTo(xArray[i] * xPlotMultiplier, -yArray[i] * yPlotMultiplier);
			}
			
			//Rescale
			insulinCurve.width = DESIRED_WIDTH;
			insulinCurve.height = DESIRED_HEIGHT;
			
			//Reposition curve
			insulinCurve.y += insulinCurve.height;
			
			//Add curve to display list
			addChild(insulinCurve);
			
			//First X Label
			var firstXLabel:Label = LayoutFactory.createLabel("0", HorizontalAlign.LEFT, VerticalAlign.TOP, 8, true);
			firstXLabel.validate();
			firstXLabel.x = -firstXLabel.width / 2;
			firstXLabel.y = insulinCurve.height + 4;
			firstXLabel.validate();
			labelsList.push(firstXLabel);
			addChild(firstXLabel);
			
			//Last X Label
			var lastXLabel:Label = LayoutFactory.createLabel(String(Math.round(DURATION)), HorizontalAlign.LEFT, VerticalAlign.TOP, 8, true);
			lastXLabel.validate();
			lastXLabel.x = insulinCurve.x + insulinCurve.width - lastXLabel.width;
			lastXLabel.y = insulinCurve.height + 4;
			lastXLabel.validate();
			labelsList.push(lastXLabel);
			addChild(lastXLabel);
			
			//Intermediate X Labels
			var numberOfXLabels:Number = Math.floor(DURATION / 30);
			var xLabelMultiplier:Number = (30 * DESIRED_WIDTH) / DURATION;
			var lastIntermediateXLabel:Label;
			var previousIntermediateXLabel:Label;
			for (i = 1; i <= numberOfXLabels; i++)
			{
				var xLabel:Label = LayoutFactory.createLabel(String(i * 30), HorizontalAlign.LEFT, VerticalAlign.TOP, 8, true);
				xLabel.validate();
				xLabel.x = (i * xLabelMultiplier) - (xLabel.width / 2);
				xLabel.y = insulinCurve.height + 4;
				xLabel.validate();
				labelsList.push(xLabel);
				
				if (i == numberOfXLabels)
				{
					lastIntermediateXLabel = xLabel;
				}
				
				if (i == numberOfXLabels - 1)
				{
					previousIntermediateXLabel = xLabel;
				}
				
				addChild(xLabel);
			}
			
			//Check Last and Previous Intermediate X Labels Intersects
			if (lastIntermediateXLabel.x + lastIntermediateXLabel.width > lastXLabel.x - 3)
			{
				lastIntermediateXLabel.removeFromParent(true);
				lastIntermediateXLabel = null;
			}
			
			if (previousIntermediateXLabel.x + previousIntermediateXLabel.width > lastXLabel.x - 3)
			{
				previousIntermediateXLabel.removeFromParent(true);
				previousIntermediateXLabel = null;
			}
			
			//First Y Label
			var firstYLabel:Label = LayoutFactory.createLabel("0", HorizontalAlign.RIGHT, VerticalAlign.TOP, 8, true);
			firstYLabel.validate();
			firstYLabel.x = -firstYLabel.width - 6;
			firstYLabel.y = insulinCurve.height - (firstYLabel.height / 2);
			firstYLabel.validate();
			labelsList.push(firstYLabel);
			addChild(firstYLabel);
			
			//Last Y Label
			var roundedMaxYValue:Number = Math.round((maxYValue * 100) * 100) / 100;
			var lastYLabel:Label = LayoutFactory.createLabel(String(roundedMaxYValue), HorizontalAlign.RIGHT, VerticalAlign.TOP, 8, true);
			lastYLabel.validate();
			lastYLabel.x = -lastYLabel.width - 6;
			lastYLabel.y = -(lastYLabel.height / 2) + 2;
			lastYLabel.validate();
			labelsList.push(lastYLabel);
			addChild(lastYLabel);
			
			//Intermediate Y Labels
			var numberOfYLabels:Number = Math.floor(roundedMaxYValue / 0.1); //0.1 increments
			var yLabelMultiplier:Number = (0.1 * DESIRED_HEIGHT) / roundedMaxYValue;
			var lastIntermediateYLabel:Label;
			for (i = 1; i <= numberOfYLabels; i++)
			{
				var yLabel:Label = LayoutFactory.createLabel(String(Math.round(i * 0.1 * 100) / 100), HorizontalAlign.RIGHT, VerticalAlign.TOP, 8, true);
				yLabel.validate();
				yLabel.x = -yLabel.width - 6;
				yLabel.y =  insulinCurve.height - (yLabel.height / 2) - (i * yLabelMultiplier);
				yLabel.validate();
				labelsList.push(yLabel);
				
				if (i == 1)
				{
					if (!yLabel.bounds.intersects(firstYLabel.bounds))
					{
						lastIntermediateYLabel = yLabel;
						addChild(yLabel);
					}
				}
				else if (lastIntermediateYLabel == null || (yLabel.y - yLabel.height > lastYLabel.y && !yLabel.bounds.intersects(lastIntermediateYLabel.bounds)))
				{
					lastIntermediateYLabel = yLabel;
					addChild(yLabel);
				}
			}
			
			//X Axis
			xAxisLine = new SpikeLine();
			xAxisLine.touchable = false;
			xAxisLine.lineStyle(1, 0xEEEEEE, 1);
			xAxisLine.moveTo(-1, insulinCurve.height + 1);
			xAxisLine.lineTo(insulinCurve.width - 1, insulinCurve.height + 1);
			addChild(xAxisLine);
			
			//Y Axis
			yAxisLine = new SpikeLine();
			yAxisLine.touchable = false;
			yAxisLine.lineStyle(1, 0xEEEEEE, 1);
			yAxisLine.moveTo(-1, insulinCurve.height + 1);
			yAxisLine.lineTo(-1, 1);
			addChild(yAxisLine);
		}
		
		private function plotOpenAPSExponential(dia:Number, peak:Number):void
		{
			//Common variables/constants
			var DESIRED_WIDTH:int = Constants.stageWidth - 60;
			if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr && !Constants.isPortrait)
			{
				if (Constants.currentOrientation == StageOrientation.ROTATED_RIGHT)
				{
					DESIRED_WIDTH -= 20;
				}
				else if (Constants.currentOrientation == StageOrientation.ROTATED_LEFT)
				{
					DESIRED_WIDTH -= 30;
				}
			}
			const DESIRED_HEIGHT:int = Constants.stageHeight / 5;
			const TD:Number = dia * 60; //Duration in Minuutes
			const TP:Number = peak; //Activity peak (in minutes)
			var i:int = 0;
			
			//Calculate data points (x, y)
			var xArray:Array = [];	
			for (i = 0; i <= TD; i++)
			{
				xArray.push(i);
			}
			var numberOfX:uint = xArray.length;
			var xPlotMultiplier:Number = DESIRED_WIDTH / TD;
			
			var yArray:Array = [];
			for (i = 0; i < numberOfX; i++)
			{
				yArray.push(scalableExponentialIA(xArray[i], TP, TD));
			}
			
			//Determine max y value
			var tempYArray:Array = yArray.concat();
			tempYArray.sort(Array.NUMERIC | Array.DESCENDING);
			
			var maxYValue:Number = tempYArray[0];
			var yPlotMultiplier:Number = DESIRED_HEIGHT / maxYValue;
			
			//Draw insulin action curve
			insulinCurve = new SpikeLine();
			insulinCurve.touchable = false;
			insulinCurve.lineStyle(2, 0x0086FF, 1);
			insulinCurve.moveTo(0, 0);
			
			for (i = 1; i < numberOfX; i++)
			{
				insulinCurve.lineTo(xArray[i] * xPlotMultiplier, -yArray[i] * yPlotMultiplier);
				insulinCurve.moveTo(xArray[i] * xPlotMultiplier, -yArray[i] * yPlotMultiplier);
			}
			
			//Reposition curve
			insulinCurve.y += insulinCurve.height;
			
			//Add curve to display list
			addChild(insulinCurve);
			
			//First X Label
			var firstXLabel:Label = LayoutFactory.createLabel("0", HorizontalAlign.LEFT, VerticalAlign.TOP, 8, true);
			firstXLabel.validate();
			firstXLabel.x = -firstXLabel.width / 2;
			firstXLabel.y = insulinCurve.height + 4;
			firstXLabel.validate();
			labelsList.push(firstXLabel);
			addChild(firstXLabel);
			
			//Last X Label
			var lastXLabel:Label = LayoutFactory.createLabel(String(Math.round(TD)), HorizontalAlign.LEFT, VerticalAlign.TOP, 8, true);
			lastXLabel.validate();
			lastXLabel.x = insulinCurve.x + insulinCurve.width - lastXLabel.width;
			lastXLabel.y = insulinCurve.height + 4;
			lastXLabel.validate();
			labelsList.push(lastXLabel);
			addChild(lastXLabel);
			
			//Intermediate X Labels
			var numberOfXLabels:Number = Math.floor(TD / 30);
			var xLabelMultiplier:Number = (30 * DESIRED_WIDTH) / TD;
			var lastIntermediateXLabel:Label;
			var previousIntermediateXLabel:Label;
			for (i = 1; i <= numberOfXLabels; i++)
			{
				var xLabel:Label = LayoutFactory.createLabel(String(i * 30), HorizontalAlign.LEFT, VerticalAlign.TOP, 8, true);
				xLabel.validate();
				xLabel.x = (i * xLabelMultiplier) - (xLabel.width / 2);
				xLabel.y = insulinCurve.height + 4;
				xLabel.validate();
				labelsList.push(xLabel);
				
				if (i == numberOfXLabels)
				{
					lastIntermediateXLabel = xLabel;
				}
				
				if (i == numberOfXLabels - 1)
				{
					previousIntermediateXLabel = xLabel;
				}
				
				addChild(xLabel);
			}
			
			//Check Last and Previous Intermediate X Labels Intersects
			if (lastIntermediateXLabel.x + lastIntermediateXLabel.width > lastXLabel.x - 3)
			{
				lastIntermediateXLabel.removeFromParent(true);
				lastIntermediateXLabel = null;
			}
			
			if (previousIntermediateXLabel.x + previousIntermediateXLabel.width > lastXLabel.x - 3)
			{
				previousIntermediateXLabel.removeFromParent(true);
				previousIntermediateXLabel = null;
			}
			
			//First Y Label
			var firstYLabel:Label = LayoutFactory.createLabel("0", HorizontalAlign.RIGHT, VerticalAlign.TOP, 8, true);
			firstYLabel.validate();
			firstYLabel.x = -firstYLabel.width - 6;
			firstYLabel.y = insulinCurve.height - (firstYLabel.height / 2);
			firstYLabel.validate();
			labelsList.push(firstYLabel);
			addChild(firstYLabel);
			
			//Last Y Label
			var roundedMaxYValue:Number = Math.round((maxYValue * 100) * 100) / 100;
			var lastYLabel:Label = LayoutFactory.createLabel(String(roundedMaxYValue), HorizontalAlign.RIGHT, VerticalAlign.TOP, 8, true);
			lastYLabel.validate();
			lastYLabel.x = -lastYLabel.width - 6;
			lastYLabel.y = -(lastYLabel.height / 2) + 2;
			lastYLabel.validate();
			labelsList.push(lastYLabel);
			addChild(lastYLabel);
			
			//Intermediate Y Labels
			var numberOfYLabels:Number = Math.floor(roundedMaxYValue / 0.1); //0.1 increments
			var yLabelMultiplier:Number = (0.1 * DESIRED_HEIGHT) / roundedMaxYValue;
			var lastIntermediateYLabel:Label;
			for (i = 1; i <= numberOfYLabels; i++)
			{
				var yLabel:Label = LayoutFactory.createLabel(String(Math.round(i * 0.1 * 100) / 100), HorizontalAlign.RIGHT, VerticalAlign.TOP, 8, true);
				yLabel.validate();
				yLabel.x = -yLabel.width - 6;
				yLabel.y =  insulinCurve.height - (yLabel.height / 2) - (i * yLabelMultiplier);
				yLabel.validate();
				labelsList.push(yLabel);
				
				if (i == 1)
				{
					if (!yLabel.bounds.intersects(firstYLabel.bounds))
					{
						lastIntermediateYLabel = yLabel;
						addChild(yLabel);
					}
				}
				else if (lastIntermediateYLabel == null || (yLabel.y - yLabel.height > lastYLabel.y && !yLabel.bounds.intersects(lastIntermediateYLabel.bounds)))
				{
					lastIntermediateYLabel = yLabel;
					addChild(yLabel);
				}
			}
			
			//X Axis
			xAxisLine = new SpikeLine();
			xAxisLine.touchable = false;
			xAxisLine.lineStyle(1, 0xEEEEEE, 1);
			xAxisLine.moveTo(-1, insulinCurve.height + 1);
			xAxisLine.lineTo(insulinCurve.width - 1, insulinCurve.height + 1);
			addChild(xAxisLine);
			
			//Y Axis
			yAxisLine = new SpikeLine();
			yAxisLine.touchable = false;
			yAxisLine.lineStyle(1, 0xEEEEEE, 1);
			yAxisLine.moveTo(-1, insulinCurve.height + 1);
			yAxisLine.lineTo(-1, 1);
			addChild(yAxisLine);
		}
		
		/**
		 * Plot Calculation Functions
		 */
		private function scalableNightscoutIA(dia:Number, minsAgo:Number):Number
		{
			//Nightscout
			const INSULIN_PEAK:uint = 75;
			var insulinScaleFactor:Number = 3 / dia;
			var minAgo:Number = insulinScaleFactor * minsAgo;
			var activity:Number = 0;
			
			if (minAgo < INSULIN_PEAK) 
			{
				activity = (2 / dia / 60 / INSULIN_PEAK) * minAgo;
			} 
			else if (minAgo < 180) 
			{
				activity = (2 / dia / 60 - (minAgo - INSULIN_PEAK) * 2 / dia / 60 / (60 * 3 - INSULIN_PEAK));
			}
			
			return activity;
		}
		
		private function scalableBilinearIA(dia:Number, minsAgo:Number):Number
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
			
			// Calc percent of insulin activity at peak, and slopes up to and down from peak
			// Based on area of triangle, because area under the insulin action "curve" must sum to 1
			// (length * height) / 2 = area of triangle (1), therefore height (activityPeak) = 2 / length (which in this case is dia, in minutes)
			// activityPeak scales based on user's dia even though peak and end remain fixed
			var activityPeak:Number = 2 / (dia * 60);
			var slopeUp:Number = activityPeak / peak;
			var slopeDown:Number = -1 * (activityPeak / (end - peak));
			var activity:Number = 0;
			
			if (scaled_minsAgo < peak) 
			{	
				activity = slopeUp * scaled_minsAgo;
			} 
			else if (scaled_minsAgo < end) 
			{
				var minsPastPeak:Number = scaled_minsAgo - peak;
				activity = activityPeak + (slopeDown * minsPastPeak);
			}
			
			return activity;
		}
		
		private function scalableExponentialIA(t:Number, tp:Number, td:Number):Number
		{
			var tau:Number = tp * (1 - tp/td) / (1- 2*tp/td);
			var a:Number = 2 * (tau/td);
			var S:Number = 1 / (1-a + (1+a) * Math.exp(-td/tau));
			
			return (S / Math.pow(tau,2)) * t * (1-t / td) * Math.exp(-t/tau);
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			var numberOfLabels:uint = labelsList.length
			for (var i:int = 0; i < numberOfLabels; i++) 
			{
				var label:Label = labelsList[i];
				if (label != null)
				{
					label.removeFromParent();
					label.dispose();
					label = null;
				}
			}
			labelsList.length = 0;
			labelsList = null;
			
			if (insulinCurve != null)
			{
				insulinCurve.removeFromParent();
				insulinCurve.dispose();
				insulinCurve = null;
			}
			
			if (xAxisLine != null)
			{
				xAxisLine.removeFromParent();
				xAxisLine.dispose();
				xAxisLine = null;
			}
			
			if (yAxisLine != null)
			{
				yAxisLine.removeFromParent();
				yAxisLine.dispose();
				yAxisLine = null;
			}
			
			super.dispose();
		}
	}
}