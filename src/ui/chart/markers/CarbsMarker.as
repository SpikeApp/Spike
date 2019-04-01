package ui.chart.markers
{
	import database.CommonSettings;
	
	import feathers.controls.Label;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalAlign;
	
	import treatments.Treatment;
	
	import ui.screens.display.LayoutFactory;
	import ui.shapes.SpikeNGon;
	
	import utils.Constants;
	import utils.DeviceInfo;
	import ui.chart.visualcomponents.ChartTreatment;
	import ui.chart.GlucoseChart;
	
	public class CarbsMarker extends ChartTreatment
	{
		/* Display Objects */
		private var label:Label;
		private var carbsMarker:SpikeNGon;
		private var stroke:SpikeNGon;
		
		/* Properties */
		private var fontSize:int = 11;
		private var backgroundColor:uint;
		private var strokeColor:uint;
		private var initialRadius:Number = 6;
		private var chartTimeline:Number;
		private var numSides:int = 30;
		private const strokeThickness:Number = 0.8;
		
		public function CarbsMarker(treatment:Treatment, timeline:Number)
		{
			this.treatment = treatment;
			backgroundColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_CARBS_MARKER_COLOR));
			strokeColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_STROKE_COLOR));
			if (Constants.deviceModel == DeviceInfo.IPHONE_2G_3G_3GS_4_4S_ITOUCH_2_3_4)
				numSides = 20;
			
			chartTimeline = timeline;
			
			draw();
		}
		
		private function draw():void
		{
			//Radius
			this.radius = initialRadius + (treatment.carbs / 6);
			if (radius > 15)
				radius = 15;
			
			if (chartTimeline == GlucoseChart.TIMELINE_6H)
			{
				radius *= 0.8;
				fontSize *= 0.8;
			}
			else if (chartTimeline == GlucoseChart.TIMELINE_12H)
			{
				radius *= 0.65;
				fontSize *= 0.7;
			}
			else if (chartTimeline == GlucoseChart.TIMELINE_24H)
			{
				radius *= 0.5;
				fontSize *= 0.6;
			}
			
			//Stroke
			stroke = new SpikeNGon(radius + strokeThickness, numSides, 0, 360, strokeColor);
			stroke.x = radius / 3;
			stroke.y = radius + radius/4;
			addChild(stroke);
			
			//Background
			carbsMarker = new SpikeNGon(radius, numSides, 0, 360, backgroundColor);
			carbsMarker.x = radius / 3;
			carbsMarker.y = radius + radius/4;
			addChild(carbsMarker);
			
			//Label
			label = LayoutFactory.createLabel(treatment.carbs + "g", HorizontalAlign.CENTER, VerticalAlign.TOP, fontSize, true);
			label.validate();
			label.x = radius/3 - (label.width / 2);
			label.y = radius * 2 + 4;
			addChild(label);
		}	
		
		override public function labelUp():void
		{
			if (label != null)
				label.y = -label.height;
		}
		
		override public function labelDown():void
		{
			if (label != null)
				label.y = radius * 2 + 4;
		}
		
		override public function updateMarker(treatment:Treatment):void
		{
			this.treatment = treatment;
			
			removeChildren(0, -1, true);
			
			draw();
		}
		
		override public function dispose():void
		{
			if (label != null)
			{
				label.removeFromParent();
				label.dispose();
				label = null;
			}
			
			if (carbsMarker != null)
			{
				carbsMarker.removeFromParent();
				carbsMarker.dispose();
				carbsMarker = null;
			}
			
			if (stroke != null)
			{
				stroke.removeFromParent();
				stroke.dispose();
				stroke = null;
			}
			
			super.dispose();
		}
	}
}