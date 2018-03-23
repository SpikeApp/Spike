package ui.chart
{
	import feathers.controls.Label;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalAlign;
	
	import starling.display.Shape;
	import starling.display.graphics.NGon;
	
	import treatments.Treatment;
	
	import ui.screens.display.LayoutFactory;
	
	public class InsulinMarker extends ChartTreatment
	{
		public function InsulinMarker(treatment:Treatment)
		{
			this.treatment = treatment;
			
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
			insulinMarker.color = 0x0086ff;
			addChild(insulinMarker);
			
			//Stroke
			var stroke:Shape = new Shape();
			stroke.graphics.lineStyle(0.8, 0xEEEEEE, 1);
			stroke.graphics.drawCircle(radius, radius, radius);
			stroke.y = radius/4;
			stroke.x = -radius/1.5;
			addChild(stroke);
			
			//Label
			var label:Label = LayoutFactory.createLabel(treatment.insulinAmount + " U", HorizontalAlign.CENTER, VerticalAlign.TOP, 9, true);
			label.validate();
			label.x = radius/3 - (label.width / 2);
			label.y = radius * 2 + 3;
			addChild(label);
		}		
	}
}