package ui.chart
{
	import database.CommonSettings;
	
	import feathers.controls.Label;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalAlign;
	
	import starling.display.Canvas;
	import starling.display.Shape;
	
	import treatments.Treatment;
	
	import ui.screens.display.LayoutFactory;
	import ui.shapes.SpikeDisplayObject;
	
	public class CarbsMarker extends ChartTreatment
	{
		/* Display Objects */
		private var label:Label;
		private var carbsMarker:Canvas;
		private var stroke:SpikeDisplayObject;
		
		/* Properties */
		private var fontSize:int = 11;
		private var backgroundColor:uint;
		private var strokeColor:uint;
		private var initialRadius:Number = 4;
		private var chartTimeline:Number;
		
		public function CarbsMarker(treatment:Treatment, timeline:Number)
		{
			this.treatment = treatment;
			backgroundColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_CARBS_MARKER_COLOR));
			strokeColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_STROKE_COLOR));
			
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
			
			//Background
			carbsMarker = new Canvas();
			carbsMarker.beginFill(backgroundColor);
			carbsMarker.drawCircle(radius / 3, radius + radius/4, radius);
			addChild(carbsMarker);
			
			//Stroke
			var strokeShape:Shape = new Shape();
			strokeShape.graphics.lineStyle(0.8, strokeColor, 1);
			strokeShape.graphics.drawCircle(radius, radius, radius);
			
			stroke = GraphLayoutFactory.createImageFromShape(strokeShape);
			stroke.y = radius/4;
			stroke.x = -radius/1.5;
			addChild(stroke);
			
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
				label.y = -label.height + 6;
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