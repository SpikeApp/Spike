package ui.chart
{	
	import feathers.controls.Label;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalAlign;
	
	import starling.display.Shape;
	import starling.display.graphics.NGon;
	
	import treatments.Treatment;
	
	import ui.screens.display.LayoutFactory;
	
	public class MealMarker extends ChartTreatment
	{

		private var insulinLabel:Label;

		private var carbsLabel:Label;

		private var mainLabel:Label;
		public function MealMarker(treatment:Treatment)
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
			var insulinMarker:NGon = new NGon(radius, 20, 0, 90, 270);
			insulinMarker.x = radius / 3;
			insulinMarker.y = radius + radius/4;
			insulinMarker.color = 0x0086ff;
			addChild(insulinMarker);
			
			var carbsMarker:NGon = new NGon(radius, 20, 0, -90, 90);
			carbsMarker.x = radius / 3;
			carbsMarker.y = radius + radius/4;
			carbsMarker.color = 0xf8a246;
			addChild(carbsMarker);
			
			//Stroke
			var stroke:Shape = new Shape();
			stroke.graphics.lineStyle(0.8, 0xEEEEEE, 1);
			stroke.graphics.drawCircle(radius, radius, radius);
			stroke.y = radius/4;
			stroke.x = -radius/1.5;
			addChild(stroke);
			
			//Label
			insulinLabel = LayoutFactory.createLabel(treatment.insulinAmount + "U", HorizontalAlign.CENTER, VerticalAlign.TOP, 9, true);
			insulinLabel.validate();
			insulinLabel.x = radius/3 - (insulinLabel.width / 2);
			insulinLabel.y = radius * 2 + 4;
			addChild(insulinLabel);
			
			carbsLabel = LayoutFactory.createLabel(treatment.carbs + "g", HorizontalAlign.CENTER, VerticalAlign.TOP, 9, true);
			carbsLabel.validate();
			carbsLabel.x = radius/3 - (carbsLabel.width / 2);
			carbsLabel.y = -carbsLabel.height + 4;
			addChild(carbsLabel);
			
			mainLabel = LayoutFactory.createLabel("", HorizontalAlign.CENTER, VerticalAlign.TOP, 9, true);
			mainLabel.y = carbsLabel.y;
			mainLabel.visible = false;
			addChild(mainLabel);
		}	
		
		override public function labelUp():void
		{
			if (mainLabel != null)
			{
				insulinLabel.visible = false;
				carbsLabel.visible = false;
				mainLabel.text = insulinLabel.text + " / " + carbsLabel.text;
				mainLabel.validate();
				mainLabel.y = carbsLabel.y;
				mainLabel.x = radius/3 - (mainLabel.width / 2);
				mainLabel.visible = true;
			}
		}
		
		override public function labelDown():void
		{
			insulinLabel.visible = true;
			carbsLabel.visible = true;
			mainLabel.visible = false;
		}
	}
}