package ui.chart
{
	import flash.display.BitmapData;
	
	import database.CommonSettings;
	
	import feathers.controls.Label;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalAlign;
	
	import starling.core.Starling;
	import starling.display.Canvas;
	import starling.display.DisplayObject;
	import starling.display.Image;
	import starling.display.Quad;
	import starling.display.Shape;
	import starling.display.Sprite;
	import starling.textures.Texture;
	
	import treatments.Treatment;
	
	import ui.screens.display.LayoutFactory;
	import ui.shapes.SpikeDisplayObject;
	
	public class InsulinMarker extends ChartTreatment
	{
		/* Display Objects */
		private var label:Label;
		private var insulinMarker:Canvas;
		private var stroke:SpikeDisplayObject;
		
		/* Properties */
		private var fontSize:Number = 11;
		private var backgroundColor:uint;
		private var strokeColor:uint;
		private var initialRadius:Number = 8;
		private var chartTimeline:Number;
		
		public function InsulinMarker(treatment:Treatment, timeline:Number)
		{
			this.treatment = treatment;
			backgroundColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_INSULIN_MARKER_COLOR));
			strokeColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_STROKE_COLOR));
			
			chartTimeline = timeline;
			
			draw();
		}
		
		private function draw():void
		{
			//OpenAPS/Loop support
			if (treatment.insulinAmount <= 1.2)
				initialRadius = 6;
			
			//Radius
			this.radius = initialRadius + treatment.insulinAmount;
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
			
			//OpenAPS/Loop support
			if (treatment.insulinAmount < 1)
				fontSize -= 1.5;
			
			//Background
			insulinMarker = new Canvas();
			insulinMarker.beginFill(backgroundColor);
			insulinMarker.drawCircle(radius / 3, radius + radius/4, radius);
			addChild(insulinMarker);
			
			//Stroke
			var strokeShape:Shape = new Shape();
			strokeShape.graphics.lineStyle(0.8, strokeColor, 1);
			strokeShape.graphics.drawCircle(radius, radius, radius);
			
			stroke = GraphLayoutFactory.createImageFromShape(strokeShape);
			stroke.y = radius/4;
			stroke.x = -radius/1.5;
			addChild(stroke);
			
			//Label
			label = LayoutFactory.createLabel(treatment.insulinAmount + "U", HorizontalAlign.CENTER, VerticalAlign.TOP, fontSize, true);
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
			
			if (insulinMarker != null)
			{
				insulinMarker.removeFromParent();
				insulinMarker.dispose();
				insulinMarker = null;
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