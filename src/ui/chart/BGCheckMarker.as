package ui.chart
{
	import database.BgReading;
	import database.CommonSettings;
	
	import feathers.controls.Label;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalAlign;
	
	import starling.display.Shape;
	import starling.display.graphics.NGon;
	
	import treatments.Treatment;
	
	import ui.screens.display.LayoutFactory;
	
	public class BGCheckMarker extends ChartTreatment
	{
		/* Display Objects */
		private var label:Label;
		private var BGMarker:NGon;
		private var stroke:Shape;
		
		/* Properties */
		private var fontSize:int = 11;
		private var backgroundColor:uint;
		private var strokeColor:uint;
		private var chartTimeline:Number;
		
		public function BGCheckMarker(treatment:Treatment, timeline:Number)
		{
			this.treatment = treatment;
			backgroundColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_BGCHECK_MARKER_COLOR));
			strokeColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_STROKE_COLOR));
			
			chartTimeline = timeline;
			
			draw();
		}
		
		private function draw():void
		{
			//Radius
			this.radius = 6;
			
			//Font
			if (chartTimeline == GlucoseChart.TIMELINE_6H)
				fontSize *= 0.8;
			else if (chartTimeline == GlucoseChart.TIMELINE_12H)
				fontSize *= 0.7;
			else if (chartTimeline == GlucoseChart.TIMELINE_24H)
				fontSize *= 0.6;
			
			//Background
			BGMarker = new NGon(radius, 20, 0, 0, 360);
			BGMarker.x = radius / 3;
			BGMarker.y = radius + radius/4;
			BGMarker.color = backgroundColor;
			addChild(BGMarker);
			
			//Stroke
			stroke = new Shape();
			stroke.graphics.lineStyle(0.8, strokeColor, 1);
			stroke.graphics.drawCircle(radius, radius, radius);
			stroke.y = radius/4;
			stroke.x = -radius/1.5;
			addChild(stroke);
			
			//Label
			var glucoseValue:Number;
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true")
				glucoseValue = treatment.glucose;
			else
				glucoseValue = Math.round(((BgReading.mgdlToMmol((treatment.glucose))) * 10)) / 10;
			
			label = LayoutFactory.createLabel(String(glucoseValue), HorizontalAlign.CENTER, VerticalAlign.TOP, fontSize, true);
			label.validate();
			label.x = radius/3 - (label.width / 2);
			label.y = radius * 2 + 4;
			addChild(label);
		}	
		
		override public function labelUp():void
		{
			if (label != null)
				label.y = -label.height + 4;
		}
		
		override public function labelDown():void
		{
			if (label != null)
				label.y = radius * 2 + 4;
		}
		
		override public function updateMarker(treatment:Treatment):void
		{
			this.treatment = treatment;
			
			removeChildren(0, 10, true);
			
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
			
			if (BGMarker != null)
			{
				BGMarker.removeFromParent();
				BGMarker.dispose();
				BGMarker = null;
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