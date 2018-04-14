package ui.chart
{
	import database.CommonSettings;
	
	import feathers.controls.Label;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalAlign;
	
	import starling.display.Shape;
	import starling.display.graphics.NGon;
	
	import treatments.Treatment;
	
	import ui.screens.display.LayoutFactory;
	
	public class InsulinMarker extends ChartTreatment
	{
		/* Constants */
		private const FONT_SIZE:int = 11;
		
		/* Display Objects */
		private var label:Label;
		
		/* Properties */
		private var backgroundColor:uint;
		private var strokeColor:uint;
		
		public function InsulinMarker(treatment:Treatment)
		{
			this.treatment = treatment;
			backgroundColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_INSULIN_MARKER_COLOR));
			strokeColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_STROKE_COLOR));
			
			draw();
		}
		
		private function draw():void
		{
			//Radius
			this.radius = 8 + treatment.insulinAmount;
			if (radius > 15)
				radius = 15;
			
			//Background
			var insulinMarker:NGon = new NGon(radius, 20, 0, 0, 360);
			insulinMarker.x = radius / 3;
			insulinMarker.y = radius + radius/4;
			insulinMarker.color = backgroundColor;
			addChild(insulinMarker);
			
			//Stroke
			var stroke:Shape = new Shape();
			stroke.graphics.lineStyle(0.8, strokeColor, 1);
			stroke.graphics.drawCircle(radius, radius, radius);
			stroke.y = radius/4;
			stroke.x = -radius/1.5;
			addChild(stroke);
			
			//Label
			label = LayoutFactory.createLabel(treatment.insulinAmount + "U", HorizontalAlign.CENTER, VerticalAlign.TOP, FONT_SIZE, true);
			label.validate();
			label.x = radius/3 - (label.width / 2);
			label.y = radius * 2 + 4;
			addChild(label);
		}
		
		override public function labelUp():void
		{
			if (label != null)
				label.y = -label.height + 3;
		}
		
		override public function labelDown():void
		{
			if (label != null)
				label.y = radius * 2 + 3;
		}
		
		override public function updateMarker(treatment:Treatment):void
		{
			this.treatment = treatment;
			
			removeChildren(0, 10, true);
			
			draw();
		}
	}
}